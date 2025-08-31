# Admin Service for BinBuddy
# Handles all administrative operations including user management, analytics, and system monitoring

import ballerina/http;
import ballerina/log;
import ballerina/sql;
import ballerina/time;
import ballerina/uuid;
import BinBuddy.backend.utils.db_connection as db;
import BinBuddy.backend.utils.response_handler as response;

# Admin service HTTP listener
listener http:Listener adminListener = new(8083);rvice for BinBuddy
# Handles all administrative operations including user management, monitoring, and analytics

import ballerina/http;
import ballerina/log;
import ballerina/sql;
import ballerina/time;
import ballerina/uuid;
import BinBuddy.backend.utils.db_connection as db;
import BinBuddy.backend.utils.response_handler as response;

# Admin data types
public type AdminProfile record {|
    # Admin ID
    int id?;
    # Full name
    string fullName;
    # Email address
    string email;
    # Phone number
    string? phone?;
    # Role/permissions level
    string role?;
    # Account status
    boolean isActive?;
    # Creation timestamp
    string? createdAt?;
|};

public type UserManagementAction record {|
    # Action type: activate, deactivate, approve, reject
    string action;
    # Reason for action
    string? reason?;
|};

public type SystemReport record {|
    # Report type
    string reportType;
    # Date range
    string? startDate?;
    string? endDate?;
    # Filters
    record {}? filters?;
|};

public type SystemStats record {|
    # User statistics
    record {|
        int totalCustomers;
        int totalCollectors;
        int activeCustomers;
        int activeCollectors;
        int newRegistrationsToday;
    |} users;
    # Request statistics
    record {|
        int totalRequests;
        int pendingRequests;
        int inProgressRequests;
        int completedRequests;
        int cancelledRequests;
        decimal totalRevenue;
        decimal todayRevenue;
    |} requests;
    # Performance metrics
    record {|
        decimal averageRating;
        decimal averageResponseTime;
        decimal completionRate;
    |} performance;
|};

# Admin Service Configuration
@http:ServiceConfig {
    cors: {
        allowOrigins: ["*"],
        allowCredentials: true,
        allowHeaders: ["Content-Type", "Authorization"],
        allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    }
}
service /api/admin on adminListener {

    # Admin login
    # Authenticate admin user
    resource function post login(http:Caller caller, http:Request req) returns error? {
        log:printInfo("Admin login request received");
        
        json|error payload = req.getJsonPayload();
        if payload is error {
            check response:sendBadRequestResponse(caller, "Invalid JSON payload");
            return;
        }
        
        string[] requiredFields = ["email", "password"];
        string? validationError = response:validateRequiredFields(payload, requiredFields);
        if validationError is string {
            check response:sendBadRequestResponse(caller, validationError);
            return;
        }
        
        try {
            // Authenticate admin
            sql:ParameterizedQuery authQuery = `
                SELECT id, email, full_name, phone, is_active
                FROM users 
                WHERE email = ${payload.email.toString()} 
                AND password = ${payload.password.toString()} 
                AND user_type = 'admin'`;
            
            stream<record {}, error?> userStream = check db:queryDatabase(authQuery);
            record {}|error? userRecord = userStream.next();
            check userStream.close();
            
            if userRecord is () {
                check response:sendUnauthorizedResponse(caller, "Invalid admin credentials");
                return;
            }
            
            if userRecord is record {} {
                if userRecord["is_active"] == false {
                    check response:sendForbiddenResponse(caller, "Admin account is deactivated");
                    return;
                }
                
                // Generate admin session token
                string sessionToken = uuid:createType1AsString();
                
                json responseData = {
                    "adminId": userRecord["id"],
                    "email": userRecord["email"],
                    "fullName": userRecord["full_name"],
                    "phone": userRecord["phone"],
                    "sessionToken": sessionToken,
                    "permissions": ["user_management", "system_monitoring", "reports", "settings"]
                };
                
                check response:sendSuccessResponse(caller, "Admin login successful", responseData);
                log:printInfo(string `Admin logged in: ${payload.email.toString()}`);
            }
            
        } catch (error e) {
            log:printError("Admin login failed", e);
            check response:sendInternalErrorResponse(caller, "Login failed", e);
        }
    }

    # Get system dashboard statistics
    # Overview of the entire BinBuddy system
    resource function get dashboard(http:Caller caller, http:Request req) returns error? {
        log:printInfo("Fetching admin dashboard statistics");
        
        try {
            // User statistics
            sql:ParameterizedQuery userStatsQuery = `
                SELECT 
                    COUNT(CASE WHEN user_type = 'customer' THEN 1 END) as total_customers,
                    COUNT(CASE WHEN user_type = 'collector' THEN 1 END) as total_collectors,
                    COUNT(CASE WHEN user_type = 'customer' AND is_active = true THEN 1 END) as active_customers,
                    COUNT(CASE WHEN user_type = 'collector' AND is_active = true THEN 1 END) as active_collectors,
                    COUNT(CASE WHEN DATE(created_at) = CURDATE() THEN 1 END) as new_registrations_today
                FROM users
                WHERE user_type IN ('customer', 'collector')`;
            
            stream<record {}, error?> userStatsStream = check db:queryDatabase(userStatsQuery);
            record {}|error? userStats = userStatsStream.next();
            check userStatsStream.close();
            
            // Request statistics
            sql:ParameterizedQuery requestStatsQuery = `
                SELECT 
                    COUNT(*) as total_requests,
                    COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_requests,
                    COUNT(CASE WHEN status = 'in_progress' THEN 1 END) as in_progress_requests,
                    COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed_requests,
                    COUNT(CASE WHEN status = 'cancelled' THEN 1 END) as cancelled_requests,
                    COALESCE(SUM(CASE WHEN status = 'completed' THEN price END), 0) as total_revenue,
                    COALESCE(SUM(CASE WHEN status = 'completed' AND DATE(completed_at) = CURDATE() THEN price END), 0) as today_revenue
                FROM collection_requests`;
            
            stream<record {}, error?> requestStatsStream = check db:queryDatabase(requestStatsQuery);
            record {}|error? requestStats = requestStatsStream.next();
            check requestStatsStream.close();
            
            // Performance metrics
            sql:ParameterizedQuery performanceQuery = `
                SELECT 
                    COALESCE(AVG(f.rating), 0) as average_rating,
                    COALESCE(AVG(TIMESTAMPDIFF(MINUTE, cr.created_at, cr.accepted_at)), 0) as average_response_time,
                    CASE 
                        WHEN COUNT(*) > 0 THEN (COUNT(CASE WHEN cr.status = 'completed' THEN 1 END) * 100.0 / COUNT(*))
                        ELSE 0 
                    END as completion_rate
                FROM collection_requests cr
                LEFT JOIN feedback f ON cr.id = f.request_id
                WHERE cr.status != 'pending'`;
            
            stream<record {}, error?> performanceStream = check db:queryDatabase(performanceQuery);
            record {}|error? performanceStats = performanceStream.next();
            check performanceStream.close();
            
            // Recent activity (last 10 activities)
            sql:ParameterizedQuery activityQuery = `
                SELECT 
                    'request' as activity_type,
                    cr.id as activity_id,
                    CONCAT('Request ', cr.status, ' - ', u.full_name) as description,
                    cr.created_at as timestamp
                FROM collection_requests cr
                JOIN users u ON cr.customer_id = u.id
                ORDER BY cr.created_at DESC
                LIMIT 10`;
            
            stream<record {}, error?> activityStream = check db:queryDatabase(activityQuery);
            json[] recentActivity = [];
            
            error? e = activityStream.forEach(function(record {} activity) {
                recentActivity.push(activity.toJson());
            });
            check activityStream.close();
            
            json dashboardData = {
                "userStatistics": userStats is record {} ? userStats.toJson() : {},
                "requestStatistics": requestStats is record {} ? requestStats.toJson() : {},
                "performanceMetrics": performanceStats is record {} ? performanceStats.toJson() : {},
                "recentActivity": recentActivity.toJson()
            };
            
            check response:sendSuccessResponse(caller, "Dashboard data retrieved", dashboardData);
            
        } catch (error e) {
            log:printError("Failed to fetch dashboard data", e);
            check response:sendInternalErrorResponse(caller, "Failed to fetch dashboard data", e);
        }
    }

    # Get all users with management options
    # Retrieve customers and collectors for admin management
    resource function get users(http:Caller caller, http:Request req) returns error? {
        log:printInfo("Fetching users for admin management");
        
        try {
            map<string[]> queryParams = req.getQueryParams();
            [int page, int limit] = response:extractPaginationParams(queryParams);
            int offset = (page - 1) * limit;
            
            // Filter by user type
            string userTypeFilter = "";
            string[]? typeArray = queryParams["type"];
            if typeArray is string[] && typeArray.length() > 0 {
                userTypeFilter = string ` AND u.user_type = '${typeArray[0]}'`;
            }
            
            // Filter by status
            string statusFilter = "";
            string[]? statusArray = queryParams["status"];
            if statusArray is string[] && statusArray.length() > 0 {
                boolean isActive = statusArray[0] == "active";
                statusFilter = string ` AND u.is_active = ${isActive}`;
            }
            
            // Get total count
            sql:ParameterizedQuery countQuery = sql:queryConcat(`
                SELECT COUNT(*) as total FROM users u
                WHERE u.user_type IN ('customer', 'collector')`, userTypeFilter, statusFilter);
            
            stream<record {}, error?> countStream = check db:queryDatabase(countQuery);
            record {}|error? countRecord = countStream.next();
            check countStream.close();
            
            int total = 0;
            if countRecord is record {} {
                total = <int>countRecord["total"];
            }
            
            // Get users with additional profile information
            sql:ParameterizedQuery usersQuery = sql:queryConcat(`
                SELECT 
                    u.id, u.email, u.user_type, u.full_name, u.phone, u.is_active, u.created_at,
                    CASE 
                        WHEN u.user_type = 'customer' THEN cp.address
                        WHEN u.user_type = 'collector' THEN colp.vehicle_number
                        ELSE NULL
                    END as additional_info,
                    CASE 
                        WHEN u.user_type = 'collector' THEN colp.rating
                        ELSE NULL
                    END as rating,
                    CASE 
                        WHEN u.user_type = 'collector' THEN colp.total_collections
                        ELSE (SELECT COUNT(*) FROM collection_requests WHERE customer_id = u.id)
                    END as total_requests
                FROM users u
                LEFT JOIN customer_profiles cp ON u.id = cp.user_id AND u.user_type = 'customer'
                LEFT JOIN collector_profiles colp ON u.id = colp.user_id AND u.user_type = 'collector'
                WHERE u.user_type IN ('customer', 'collector')`, userTypeFilter, statusFilter, `
                ORDER BY u.created_at DESC
                LIMIT ${limit} OFFSET ${offset}`);
            
            stream<record {}, error?> usersStream = check db:queryDatabase(usersQuery);
            json[] users = [];
            
            error? e = usersStream.forEach(function(record {} user) {
                users.push(user.toJson());
            });
            check usersStream.close();
            
            if e is error {
                check response:sendInternalErrorResponse(caller, "Failed to fetch users", e);
                return;
            }
            
            check response:sendPaginatedResponse(caller, "Users retrieved successfully", 
                                              users.toJson(), page, limit, total);
            
        } catch (error e) {
            log:printError("Failed to fetch users", e);
            check response:sendInternalErrorResponse(caller, "Failed to fetch users", e);
        }
    }

    # Manage user account (activate/deactivate)
    # Admin can activate or deactivate user accounts
    resource function put users/[int userId]/manage(http:Caller caller, http:Request req) returns error? {
        log:printInfo(string `Managing user account: ${userId}`);
        
        json|error payload = req.getJsonPayload();
        if payload is error {
            check response:sendBadRequestResponse(caller, "Invalid JSON payload");
            return;
        }
        
        string[] requiredFields = ["action"];
        string? validationError = response:validateRequiredFields(payload, requiredFields);
        if validationError is string {
            check response:sendBadRequestResponse(caller, validationError);
            return;
        }
        
        try {
            string action = payload.action.toString();
            
            if action != "activate" && action != "deactivate" {
                check response:sendBadRequestResponse(caller, "Invalid action. Use: activate, deactivate");
                return;
            }
            
            boolean isActive = action == "activate";
            
            // Check if user exists
            sql:ParameterizedQuery checkQuery = `
                SELECT email, user_type, full_name FROM users WHERE id = ${userId}`;
            
            stream<record {}, error?> checkStream = check db:queryDatabase(checkQuery);
            record {}|error? userRecord = checkStream.next();
            check checkStream.close();
            
            if userRecord is () {
                check response:sendNotFoundResponse(caller, "User not found");
                return;
            }
            
            // Update user status
            sql:ParameterizedQuery updateQuery = `
                UPDATE users SET is_active = ${isActive} WHERE id = ${userId}`;
            
            sql:ExecutionResult result = check db:executeQuery(updateQuery);
            
            if userRecord is record {} {
                // Create notification for user
                string notificationTitle = isActive ? "Account Activated" : "Account Deactivated";
                string notificationMessage = isActive ? 
                    "Your account has been activated by admin" : 
                    "Your account has been deactivated. Contact support for details.";
                
                sql:ParameterizedQuery notificationQuery = `
                    INSERT INTO notifications (user_id, title, message, type)
                    VALUES (${userId}, ${notificationTitle}, ${notificationMessage}, 'system')`;
                
                _ = check db:executeQuery(notificationQuery);
                
                json responseData = {
                    "userId": userId,
                    "email": userRecord["email"],
                    "action": action,
                    "newStatus": isActive ? "active" : "inactive"
                };
                
                check response:sendSuccessResponse(caller, string `User ${action}d successfully`, responseData);
                log:printInfo(string `User ${userId} ${action}d by admin`);
            }
            
        } catch (error e) {
            log:printError("Failed to manage user account", e);
            check response:sendInternalErrorResponse(caller, "Failed to manage user account", e);
        }
    }

    # Get all collection requests for monitoring
    # Admin can view all collection requests with filters
    resource function get requests(http:Caller caller, http:Request req) returns error? {
        log:printInfo("Fetching all collection requests for admin monitoring");
        
        try {
            map<string[]> queryParams = req.getQueryParams();
            [int page, int limit] = response:extractPaginationParams(queryParams);
            int offset = (page - 1) * limit;
            
            // Status filter
            string statusFilter = "";
            string[]? statusArray = queryParams["status"];
            if statusArray is string[] && statusArray.length() > 0 {
                statusFilter = string ` AND cr.status = '${statusArray[0]}'`;
            }
            
            // Date range filter
            string dateFilter = "";
            string[]? startDateArray = queryParams["startDate"];
            string[]? endDateArray = queryParams["endDate"];
            if startDateArray is string[] && startDateArray.length() > 0 {
                dateFilter = string ` AND DATE(cr.created_at) >= '${startDateArray[0]}'`;
            }
            if endDateArray is string[] && endDateArray.length() > 0 {
                dateFilter = dateFilter + string ` AND DATE(cr.created_at) <= '${endDateArray[0]}'`;
            }
            
            // Get total count
            sql:ParameterizedQuery countQuery = sql:queryConcat(`
                SELECT COUNT(*) as total FROM collection_requests cr
                WHERE 1=1`, statusFilter, dateFilter);
            
            stream<record {}, error?> countStream = check db:queryDatabase(countQuery);
            record {}|error? countRecord = countStream.next();
            check countStream.close();
            
            int total = 0;
            if countRecord is record {} {
                total = <int>countRecord["total"];
            }
            
            // Get requests with customer and collector details
            sql:ParameterizedQuery requestsQuery = sql:queryConcat(`
                SELECT 
                    cr.*,
                    cu.full_name as customer_name,
                    cu.email as customer_email,
                    cu.phone as customer_phone,
                    cp.address as customer_address,
                    colu.full_name as collector_name,
                    colu.email as collector_email,
                    colu.phone as collector_phone,
                    colp.vehicle_number,
                    colp.rating as collector_rating
                FROM collection_requests cr
                JOIN users cu ON cr.customer_id = cu.id
                JOIN customer_profiles cp ON cu.id = cp.user_id
                LEFT JOIN users colu ON cr.collector_id = colu.id
                LEFT JOIN collector_profiles colp ON colu.id = colp.user_id
                WHERE 1=1`, statusFilter, dateFilter, `
                ORDER BY cr.created_at DESC
                LIMIT ${limit} OFFSET ${offset}`);
            
            stream<record {}, error?> requestsStream = check db:queryDatabase(requestsQuery);
            json[] requests = [];
            
            error? e = requestsStream.forEach(function(record {} req) {
                requests.push(req.toJson());
            });
            check requestsStream.close();
            
            if e is error {
                check response:sendInternalErrorResponse(caller, "Failed to fetch requests", e);
                return;
            }
            
            check response:sendPaginatedResponse(caller, "Requests retrieved successfully", 
                                              requests.toJson(), page, limit, total);
            
        } catch (error e) {
            log:printError("Failed to fetch requests", e);
            check response:sendInternalErrorResponse(caller, "Failed to fetch requests", e);
        }
    }

    # Get system analytics and reports
    # Generate various analytical reports
    resource function get analytics/[string reportType](http:Caller caller, http:Request req) returns error? {
        log:printInfo(string `Generating analytics report: ${reportType}`);
        
        try {
            map<string[]> queryParams = req.getQueryParams();
            
            // Date range
            string startDate = "DATE_SUB(CURDATE(), INTERVAL 30 DAY)";
            string endDate = "CURDATE()";
            
            string[]? startArray = queryParams["startDate"];
            if startArray is string[] && startArray.length() > 0 {
                startDate = string `'${startArray[0]}'`;
            }
            
            string[]? endArray = queryParams["endDate"];
            if endArray is string[] && endArray.length() > 0 {
                endDate = string `'${endArray[0]}'`;
            }
            
            json reportData = {};
            
            match reportType {
                "requests" => {
                    // Request analytics
                    sql:ParameterizedQuery requestAnalyticsQuery = sql:queryConcat(`
                        SELECT 
                            DATE(created_at) as date,
                            COUNT(*) as total_requests,
                            COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed_requests,
                            COUNT(CASE WHEN status = 'cancelled' THEN 1 END) as cancelled_requests,
                            AVG(price) as average_price
                        FROM collection_requests 
                        WHERE DATE(created_at) BETWEEN `, startDate, ` AND `, endDate, `
                        GROUP BY DATE(created_at)
                        ORDER BY date`);
                    
                    stream<record {}, error?> analyticsStream = check db:queryDatabase(requestAnalyticsQuery);
                    json[] dailyData = [];
                    
                    error? e = analyticsStream.forEach(function(record {} data) {
                        dailyData.push(data.toJson());
                    });
                    check analyticsStream.close();
                    
                    reportData = {"dailyRequestAnalytics": dailyData.toJson()};
                }
                "revenue" => {
                    // Revenue analytics
                    sql:ParameterizedQuery revenueQuery = sql:queryConcat(`
                        SELECT 
                            DATE(completed_at) as date,
                            COUNT(*) as completed_collections,
                            SUM(price) as daily_revenue,
                            AVG(price) as average_price_per_collection
                        FROM collection_requests 
                        WHERE status = 'completed' 
                        AND DATE(completed_at) BETWEEN `, startDate, ` AND `, endDate, `
                        GROUP BY DATE(completed_at)
                        ORDER BY date`);
                    
                    stream<record {}, error?> revenueStream = check db:queryDatabase(revenueQuery);
                    json[] revenueData = [];
                    
                    error? e = revenueStream.forEach(function(record {} data) {
                        revenueData.push(data.toJson());
                    });
                    check revenueStream.close();
                    
                    reportData = {"dailyRevenueAnalytics": revenueData.toJson()};
                }
                "performance" => {
                    // Performance analytics
                    sql:ParameterizedQuery performanceQuery = sql:queryConcat(`
                        SELECT 
                            colu.full_name as collector_name,
                            colp.rating,
                            colp.total_collections,
                            COUNT(cr.id) as requests_in_period,
                            AVG(TIMESTAMPDIFF(MINUTE, cr.accepted_at, cr.completed_at)) as avg_completion_time,
                            SUM(cr.price) as total_earnings
                        FROM users colu
                        JOIN collector_profiles colp ON colu.id = colp.user_id
                        LEFT JOIN collection_requests cr ON colu.id = cr.collector_id 
                            AND cr.status = 'completed' 
                            AND DATE(cr.completed_at) BETWEEN `, startDate, ` AND `, endDate, `
                        WHERE colu.user_type = 'collector'
                        GROUP BY colu.id, colu.full_name, colp.rating, colp.total_collections
                        ORDER BY colp.rating DESC, colp.total_collections DESC`);
                    
                    stream<record {}, error?> performanceStream = check db:queryDatabase(performanceQuery);
                    json[] performanceData = [];
                    
                    error? e = performanceStream.forEach(function(record {} data) {
                        performanceData.push(data.toJson());
                    });
                    check performanceStream.close();
                    
                    reportData = {"collectorPerformance": performanceData.toJson()};
                }
                "geographic" => {
                    // Geographic distribution
                    sql:ParameterizedQuery geoQuery = sql:queryConcat(`
                        SELECT 
                            cp.address,
                            COUNT(cr.id) as request_count,
                            AVG(cr.pickup_latitude) as avg_latitude,
                            AVG(cr.pickup_longitude) as avg_longitude
                        FROM collection_requests cr
                        JOIN customer_profiles cp ON cr.customer_id = cp.user_id
                        WHERE DATE(cr.created_at) BETWEEN `, startDate, ` AND `, endDate, `
                        GROUP BY cp.address
                        HAVING request_count > 0
                        ORDER BY request_count DESC
                        LIMIT 50`);
                    
                    stream<record {}, error?> geoStream = check db:queryDatabase(geoQuery);
                    json[] geoData = [];
                    
                    error? e = geoStream.forEach(function(record {} data) {
                        geoData.push(data.toJson());
                    });
                    check geoStream.close();
                    
                    reportData = {"geographicDistribution": geoData.toJson()};
                }
                _ => {
                    check response:sendBadRequestResponse(caller, "Invalid report type. Available: requests, revenue, performance, geographic");
                    return;
                }
            }
            
            check response:sendSuccessResponse(caller, string `${reportType} analytics generated`, reportData);
            
        } catch (error e) {
            log:printError("Failed to generate analytics", e);
            check response:sendInternalErrorResponse(caller, "Failed to generate analytics", e);
        }
    }

    # Get system notifications and alerts
    # Admin notifications for system issues, high-priority items
    resource function get notifications(http:Caller caller, http:Request req) returns error? {
        log:printInfo("Fetching admin notifications");
        
        try {
            map<string[]> queryParams = req.getQueryParams();
            [int page, int limit] = response:extractPaginationParams(queryParams);
            int offset = (page - 1) * limit;
            
            // System alerts (high priority items)
            sql:ParameterizedQuery alertsQuery = `
                SELECT 
                    'long_pending_request' as alert_type,
                    CONCAT('Request #', cr.id, ' pending for over 2 hours') as message,
                    cr.created_at as timestamp,
                    'high' as priority
                FROM collection_requests cr
                WHERE cr.status = 'pending' 
                AND cr.created_at < DATE_SUB(NOW(), INTERVAL 2 HOUR)
                
                UNION ALL
                
                SELECT 
                    'inactive_collector' as alert_type,
                    CONCAT('Collector ', u.full_name, ' has no activity for 24 hours') as message,
                    colp.current_latitude as timestamp,
                    'medium' as priority
                FROM users u
                JOIN collector_profiles colp ON u.id = colp.user_id
                LEFT JOIN collection_requests cr ON u.id = cr.collector_id 
                    AND cr.created_at > DATE_SUB(NOW(), INTERVAL 24 HOUR)
                WHERE u.user_type = 'collector' 
                AND u.is_active = true 
                AND cr.id IS NULL
                
                UNION ALL
                
                SELECT 
                    'low_rating' as alert_type,
                    CONCAT('Collector ', u.full_name, ' has rating below 3.0') as message,
                    NOW() as timestamp,
                    'medium' as priority
                FROM users u
                JOIN collector_profiles colp ON u.id = colp.user_id
                WHERE u.user_type = 'collector' 
                AND colp.rating < 3.0 
                AND colp.total_collections > 5
                
                ORDER BY timestamp DESC
                LIMIT ${limit} OFFSET ${offset}`;
            
            stream<record {}, error?> alertsStream = check db:queryDatabase(alertsQuery);
            json[] alerts = [];
            
            error? e = alertsStream.forEach(function(record {} alert) {
                alerts.push(alert.toJson());
            });
            check alertsStream.close();
            
            // Get count of total alerts
            sql:ParameterizedQuery countQuery = `
                SELECT COUNT(*) as total FROM (
                    SELECT 1 FROM collection_requests 
                    WHERE status = 'pending' AND created_at < DATE_SUB(NOW(), INTERVAL 2 HOUR)
                    UNION ALL
                    SELECT 1 FROM users u
                    JOIN collector_profiles colp ON u.id = colp.user_id
                    LEFT JOIN collection_requests cr ON u.id = cr.collector_id 
                        AND cr.created_at > DATE_SUB(NOW(), INTERVAL 24 HOUR)
                    WHERE u.user_type = 'collector' AND u.is_active = true AND cr.id IS NULL
                    UNION ALL
                    SELECT 1 FROM users u
                    JOIN collector_profiles colp ON u.id = colp.user_id
                    WHERE u.user_type = 'collector' AND colp.rating < 3.0 AND colp.total_collections > 5
                ) as all_alerts`;
            
            stream<record {}, error?> countStream = check db:queryDatabase(countQuery);
            record {}|error? countRecord = countStream.next();
            check countStream.close();
            
            int total = 0;
            if countRecord is record {} {
                total = <int>countRecord["total"];
            }
            
            check response:sendPaginatedResponse(caller, "Admin notifications retrieved", 
                                              alerts.toJson(), page, limit, total);
            
        } catch (error e) {
            log:printError("Failed to fetch admin notifications", e);
            check response:sendInternalErrorResponse(caller, "Failed to fetch notifications", e);
        }
    }

    # Export data for external analysis
    # Export various data sets in different formats
    resource function get export/[string dataType](http:Caller caller, http:Request req) returns error? {
        log:printInfo(string `Exporting data: ${dataType}`);
        
        try {
            map<string[]> queryParams = req.getQueryParams();
            
            // Date range
            string startDate = "DATE_SUB(CURDATE(), INTERVAL 30 DAY)";
            string endDate = "CURDATE()";
            
            string[]? startArray = queryParams["startDate"];
            if startArray is string[] && startArray.length() > 0 {
                startDate = string `'${startArray[0]}'`;
            }
            
            string[]? endArray = queryParams["endDate"];
            if endArray is string[] && endArray.length() > 0 {
                endDate = string `'${endArray[0]}'`;
            }
            
            json exportData = {};
            
            match dataType {
                "requests" => {
                    sql:ParameterizedQuery exportQuery = sql:queryConcat(`
                        SELECT 
                            cr.*,
                            cu.full_name as customer_name,
                            cu.email as customer_email,
                            colu.full_name as collector_name,
                            colu.email as collector_email
                        FROM collection_requests cr
                        JOIN users cu ON cr.customer_id = cu.id
                        LEFT JOIN users colu ON cr.collector_id = colu.id
                        WHERE DATE(cr.created_at) BETWEEN `, startDate, ` AND `, endDate, `
                        ORDER BY cr.created_at DESC`);
                    
                    stream<record {}, error?> exportStream = check db:queryDatabase(exportQuery);
                    json[] data = [];
                    
                    error? e = exportStream.forEach(function(record {} record) {
                        data.push(record.toJson());
                    });
                    check exportStream.close();
                    
                    exportData = {"requests": data.toJson()};
                }
                "users" => {
                    sql:ParameterizedQuery userExportQuery = sql:queryConcat(`
                        SELECT 
                            u.*,
                            CASE 
                                WHEN u.user_type = 'customer' THEN cp.address
                                WHEN u.user_type = 'collector' THEN colp.vehicle_number
                                ELSE NULL
                            END as additional_info
                        FROM users u
                        LEFT JOIN customer_profiles cp ON u.id = cp.user_id AND u.user_type = 'customer'
                        LEFT JOIN collector_profiles colp ON u.id = colp.user_id AND u.user_type = 'collector'
                        WHERE u.user_type IN ('customer', 'collector')
                        AND DATE(u.created_at) BETWEEN `, startDate, ` AND `, endDate, `
                        ORDER BY u.created_at DESC`);
                    
                    stream<record {}, error?> exportStream = check db:queryDatabase(userExportQuery);
                    json[] data = [];
                    
                    error? e = exportStream.forEach(function(record {} record) {
                        data.push(record.toJson());
                    });
                    check exportStream.close();
                    
                    exportData = {"users": data.toJson()};
                }
                "feedback" => {
                    sql:ParameterizedQuery feedbackExportQuery = sql:queryConcat(`
                        SELECT 
                            f.*,
                            cu.full_name as customer_name,
                            colu.full_name as collector_name,
                            cr.pickup_address
                        FROM feedback f
                        JOIN users cu ON f.customer_id = cu.id
                        JOIN users colu ON f.collector_id = colu.id
                        JOIN collection_requests cr ON f.request_id = cr.id
                        WHERE DATE(f.created_at) BETWEEN `, startDate, ` AND `, endDate, `
                        ORDER BY f.created_at DESC`);
                    
                    stream<record {}, error?> exportStream = check db:queryDatabase(feedbackExportQuery);
                    json[] data = [];
                    
                    error? e = exportStream.forEach(function(record {} record) {
                        data.push(record.toJson());
                    });
                    check exportStream.close();
                    
                    exportData = {"feedback": data.toJson()};
                }
                _ => {
                    check response:sendBadRequestResponse(caller, "Invalid export type. Available: requests, users, feedback");
                    return;
                }
            }
            
            // Add export metadata
            json responseData = {
                "exportType": dataType,
                "dateRange": {
                    "startDate": startDate,
                    "endDate": endDate
                },
                "exportedAt": time:utcToString(time:utcNow()),
                "data": exportData
            };
            
            check response:sendSuccessResponse(caller, string `${dataType} data exported successfully`, responseData);
            
        } catch (error e) {
            log:printError("Failed to export data", e);
            check response:sendInternalErrorResponse(caller, "Failed to export data", e);
        }
    }

    # System health check
    # Check overall system health and component status
    resource function get health(http:Caller caller, http:Request req) returns error? {
        log:printInfo("Performing system health check");
        
        try {
            // Database health
            boolean dbHealth = db:isDatabaseHealthy();
            
            // Check for critical issues
            sql:ParameterizedQuery criticalQuery = `
                SELECT 
                    COUNT(CASE WHEN status = 'pending' AND created_at < DATE_SUB(NOW(), INTERVAL 4 HOUR) THEN 1 END) as critical_pending,
                    COUNT(CASE WHEN status = 'in_progress' AND started_at < DATE_SUB(NOW(), INTERVAL 6 HOUR) THEN 1 END) as stale_in_progress,
                    COUNT(CASE WHEN user_type = 'collector' AND is_active = true THEN 1 END) as active_collectors
                FROM collection_requests cr
                RIGHT JOIN users u ON true
                WHERE u.user_type = 'collector' OR cr.id IS NOT NULL`;
            
            stream<record {}, error?> healthStream = check db:queryDatabase(criticalQuery);
            record {}|error? healthRecord = healthStream.next();
            check healthStream.close();
            
            json healthData = {
                "database": {
                    "status": dbHealth ? "healthy" : "unhealthy",
                    "connected": dbHealth
                },
                "services": {
                    "customer_service": "healthy",
                    "collector_service": "healthy",
                    "admin_service": "healthy"
                },
                "metrics": healthRecord is record {} ? healthRecord.toJson() : {},
                "timestamp": time:utcToString(time:utcNow())
            };
            
            if dbHealth {
                check response:sendSuccessResponse(caller, "System health check completed", healthData);
            } else {
                check response:sendInternalErrorResponse(caller, "System health issues detected", ());
            }
            
        } catch (error e) {
            log:printError("Health check failed", e);
            check response:sendInternalErrorResponse(caller, "Health check failed", e);
        }
    }
}
