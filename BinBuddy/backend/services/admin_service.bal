# Admin Service for BinBuddy
# Handles all admin-related operations including user management, system monitoring, and analytics

import ballerina/http;
import ballerina/log;
import ballerina/sql;
import ballerina/time;
import ballerina/uuid;
import ballerinax/mysql;
import ballerinax/mysql.driver as _;

# Database configuration
configurable string DB_HOST = "localhost";
configurable int DB_PORT = 3306;
configurable string DB_NAME = "binbuddy_db";
configurable string DB_USERNAME = "root";
configurable string DB_PASSWORD = "";

# Database client
mysql:Client? dbClient = ();

# Initialize database connection
function initDatabase() returns error? {
    try {
        log:printInfo("Initializing admin service database connection...");
        
        mysql:Client mysqlClient = check new (
            host = DB_HOST,
            port = DB_PORT,
            database = DB_NAME,
            user = DB_USERNAME,
            password = DB_PASSWORD
        );
        
        dbClient = mysqlClient;
        log:printInfo("Admin service database connection established");
        return;
    } catch (error e) {
        log:printError("Failed to initialize admin service database", e);
        return e;
    }
}

# Get database client
function getDbClient() returns mysql:Client|error {
    if dbClient is mysql:Client {
        return dbClient;
    }
    return error("Database client not initialized. Call initDatabase() first.");
}

# Execute parameterized query
function executeQuery(sql:ParameterizedQuery query) returns sql:ExecutionResult|error {
    mysql:Client client = check getDbClient();
    sql:ExecutionResult result = check client->execute(query);
    return result;
}

# Execute SELECT query and return stream
function queryDatabase(sql:ParameterizedQuery query) returns stream<record {}, error?>|error {
    mysql:Client client = check getDbClient();
    stream<record {}, error?> resultStream = client->query(query);
    return resultStream;
}

# Response helper functions
function sendSuccessResponse(http:Caller caller, string message, json data = {}) returns error? {
    json response = {
        "success": true,
        "message": message,
        "data": data,
        "timestamp": time:utcToString(time:utcNow())
    };
    check caller->respond(response);
}

function sendErrorResponse(http:Caller caller, int statusCode, string message) returns error? {
    json response = {
        "success": false,
        "message": message,
        "timestamp": time:utcToString(time:utcNow())
    };
    http:Response res = new;
    res.statusCode = statusCode;
    res.setJsonPayload(response);
    check caller->respond(res);
}

function sendBadRequestResponse(http:Caller caller, string message) returns error? {
    return sendErrorResponse(caller, 400, message);
}

function sendUnauthorizedResponse(http:Caller caller, string message) returns error? {
    return sendErrorResponse(caller, 401, message);
}

function sendForbiddenResponse(http:Caller caller, string message) returns error? {
    return sendErrorResponse(caller, 403, message);
}

function sendNotFoundResponse(http:Caller caller, string message) returns error? {
    return sendErrorResponse(caller, 404, message);
}

function sendInternalErrorResponse(http:Caller caller, string message, error? err = ()) returns error? {
    if err is error {
        log:printError("Internal server error", err);
    }
    return sendErrorResponse(caller, 500, message);
}

function sendCreatedResponse(http:Caller caller, string message, json data = {}) returns error? {
    json response = {
        "success": true,
        "message": message,
        "data": data,
        "timestamp": time:utcToString(time:utcNow())
    };
    http:Response res = new;
    res.statusCode = 201;
    res.setJsonPayload(response);
    check caller->respond(res);
}

function validateRequiredFields(json payload, string[] requiredFields) returns string? {
    map<json> payloadMap = <map<json>>payload;
    foreach string fieldName in requiredFields {
        if !payloadMap.hasKey(fieldName) || payloadMap[fieldName] is () {
            return string `Missing required field: ${fieldName}`;
        }
    }
    return ();
}

function extractPaginationParams(map<string[]> queryParams) returns [int, int] {
    int page = 1;
    int pageLimit = 10;
    
    if queryParams.hasKey("page") {
        string[]? pageValues = queryParams["page"];
        if pageValues is string[] && pageValues.length() > 0 {
            int|error pageResult = int:fromString(pageValues[0]);
            if pageResult is int && pageResult > 0 {
                page = pageResult;
            }
        }
    }
    
    if queryParams.hasKey("limit") {
        string[]? limitValues = queryParams["limit"];
        if limitValues is string[] && limitValues.length() > 0 {
            int|error limitResult = int:fromString(limitValues[0]);
            if limitResult is int && limitResult > 0 && limitResult <= 100 {
                pageLimit = limitResult;
            }
        }
    }
    
    return [page, pageLimit];
}

function sendPaginatedResponse(http:Caller caller, string message, json data, int page, int pageLimit, int total) returns error? {
    int totalPages = (total + pageLimit - 1) / pageLimit;
    
    json paginatedResponse = {
        "success": true,
        "message": message,
        "data": data,
        "pagination": {
            "page": page,
            "limit": pageLimit,
            "total": total,
            "totalPages": totalPages,
            "hasNext": page < totalPages,
            "hasPrev": page > 1
        },
        "timestamp": time:utcToString(time:utcNow())
    };
    
    check caller->respond(paginatedResponse);
}

# HTTP listener for admin service
listener http:Listener adminListener = new(8083);

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

    # Service initialization
    function init() returns error? {
        error? initResult = initDatabase();
        if initResult is error {
            log:printWarn("Admin service started without database connection", initResult);
        }
    }

    # Health check
    resource function get health() returns json {
        return {
            "service": "Admin Service",
            "status": "healthy",
            "timestamp": time:utcToString(time:utcNow()),
            "port": 8083
        };
    }

    # Admin login
    resource function post login(http:Caller caller, http:Request req) returns error? {
        log:printInfo("Admin login request received");
        
        json|error payload = req.getJsonPayload();
        if payload is error {
            check sendBadRequestResponse(caller, "Invalid JSON payload");
            return;
        }
        
        string[] requiredFields = ["email", "password"];
        string? validationError = validateRequiredFields(payload, requiredFields);
        if validationError is string {
            check sendBadRequestResponse(caller, validationError);
            return;
        }
        
        try {
            # Authenticate admin
            sql:ParameterizedQuery authQuery = `
                SELECT id, email, full_name, phone, is_active
                FROM users 
                WHERE email = ${payload.email.toString()} 
                AND password = ${payload.password.toString()} 
                AND user_type = 'admin'`;
            
            stream<record {}, error?> userStream = check queryDatabase(authQuery);
            record {}|error? userRecord = userStream.next();
            check userStream.close();
            
            if userRecord is () {
                check sendUnauthorizedResponse(caller, "Invalid admin credentials");
                return;
            }
            
            if userRecord is record {} {
                if userRecord["is_active"] == false {
                    check sendForbiddenResponse(caller, "Admin account is deactivated");
                    return;
                }
                
                string sessionToken = uuid:createType1AsString();
                
                json responseData = {
                    "adminId": userRecord["id"],
                    "email": userRecord["email"],
                    "fullName": userRecord["full_name"],
                    "phone": userRecord["phone"],
                    "sessionToken": sessionToken,
                    "permissions": ["user_management", "system_monitoring", "analytics", "reports"]
                };
                
                check sendSuccessResponse(caller, "Admin login successful", responseData);
                log:printInfo(string `Admin logged in: ${payload.email.toString()}`);
            }
            
        } catch (error e) {
            log:printError("Admin login failed", e);
            check sendInternalErrorResponse(caller, "Login failed", e);
        }
    }

    # Admin dashboard
    resource function get dashboard(http:Caller caller, http:Request req) returns error? {
        log:printInfo("Admin dashboard requested");
        
        try {
            # Get system statistics
            sql:ParameterizedQuery systemStatsQuery = `
                SELECT 
                    (SELECT COUNT(*) FROM users) as total_users,
                    (SELECT COUNT(*) FROM users WHERE user_type = 'customer') as total_customers,
                    (SELECT COUNT(*) FROM users WHERE user_type = 'collector') as total_collectors,
                    (SELECT COUNT(*) FROM collection_requests) as total_requests,
                    (SELECT COUNT(*) FROM collection_requests WHERE status = 'completed') as completed_requests,
                    (SELECT COUNT(*) FROM collection_requests WHERE status = 'pending') as pending_requests,
                    (SELECT COUNT(*) FROM collection_requests WHERE status = 'in_progress') as active_requests,
                    (SELECT COALESCE(SUM(price), 0) FROM collection_requests WHERE status = 'completed') as total_revenue`;
            
            stream<record {}, error?> statsStream = check queryDatabase(systemStatsQuery);
            record {}|error? statsRecord = statsStream.next();
            check statsStream.close();
            
            # Get recent activity
            sql:ParameterizedQuery activityQuery = `
                SELECT 
                    cr.id,
                    cr.status,
                    cr.price,
                    cr.created_at,
                    cr.completed_at,
                    u1.full_name as customer_name,
                    u2.full_name as collector_name
                FROM collection_requests cr
                LEFT JOIN users u1 ON cr.customer_id = u1.id
                LEFT JOIN users u2 ON cr.collector_id = u2.id
                ORDER BY cr.created_at DESC
                LIMIT 10`;
            
            stream<record {}, error?> activityStream = check queryDatabase(activityQuery);
            json[] recentActivity = [];
            
            error? e1 = activityStream.forEach(function(record {} activity) {
                recentActivity.push(activity.toJson());
            });
            check activityStream.close();
            
            # Get top collectors
            sql:ParameterizedQuery topCollectorsQuery = `
                SELECT 
                    u.full_name as name,
                    cp.rating,
                    cp.total_collections,
                    COALESCE(SUM(cr.price), 0) as earnings
                FROM users u
                LEFT JOIN collector_profiles cp ON u.id = cp.user_id
                LEFT JOIN collection_requests cr ON u.id = cr.collector_id AND cr.status = 'completed'
                WHERE u.user_type = 'collector'
                GROUP BY u.id, u.full_name, cp.rating, cp.total_collections
                ORDER BY cp.total_collections DESC, cp.rating DESC
                LIMIT 5`;
            
            stream<record {}, error?> collectorsStream = check queryDatabase(topCollectorsQuery);
            json[] topCollectors = [];
            
            error? e2 = collectorsStream.forEach(function(record {} collector) {
                topCollectors.push(collector.toJson());
            });
            check collectorsStream.close();
            
            json dashboardData = {
                "systemStats": statsRecord is record {} ? statsRecord.toJson() : {},
                "recentActivity": recentActivity.toJson(),
                "topCollectors": topCollectors.toJson()
            };
            
            check sendSuccessResponse(caller, "Admin dashboard data retrieved", dashboardData);
            
        } catch (error e) {
            log:printError("Failed to fetch admin dashboard data", e);
            check sendInternalErrorResponse(caller, "Failed to fetch dashboard data", e);
        }
    }

    # User management - Get all users
    resource function get users(http:Caller caller, http:Request req) returns error? {
        log:printInfo("Admin user management requested");
        
        try {
            map<string[]> queryParams = req.getQueryParams();
            [int page, int limit] = extractPaginationParams(queryParams);
            int offset = (page - 1) * limit;
            
            # Get user type filter
            string? userType = ();
            if queryParams.hasKey("type") {
                string[]? typeValues = queryParams["type"];
                if typeValues is string[] && typeValues.length() > 0 {
                    userType = typeValues[0];
                }
            }
            
            # Build query with optional user type filter
            sql:ParameterizedQuery countQuery;
            sql:ParameterizedQuery usersQuery;
            
            if userType is string && (userType == "customer" || userType == "collector") {
                countQuery = `SELECT COUNT(*) as total FROM users WHERE user_type = ${userType}`;
                usersQuery = `
                    SELECT u.*, 
                           CASE 
                               WHEN u.user_type = 'customer' THEN cp.address
                               WHEN u.user_type = 'collector' THEN colp.vehicle_type
                               ELSE NULL
                           END as additional_info
                    FROM users u
                    LEFT JOIN customer_profiles cp ON u.id = cp.user_id AND u.user_type = 'customer'
                    LEFT JOIN collector_profiles colp ON u.id = colp.user_id AND u.user_type = 'collector'
                    WHERE u.user_type = ${userType}
                    ORDER BY u.created_at DESC
                    LIMIT ${limit} OFFSET ${offset}`;
            } else {
                countQuery = `SELECT COUNT(*) as total FROM users WHERE user_type != 'admin'`;
                usersQuery = `
                    SELECT u.*, 
                           CASE 
                               WHEN u.user_type = 'customer' THEN cp.address
                               WHEN u.user_type = 'collector' THEN colp.vehicle_type
                               ELSE NULL
                           END as additional_info
                    FROM users u
                    LEFT JOIN customer_profiles cp ON u.id = cp.user_id AND u.user_type = 'customer'
                    LEFT JOIN collector_profiles colp ON u.id = colp.user_id AND u.user_type = 'collector'
                    WHERE u.user_type != 'admin'
                    ORDER BY u.created_at DESC
                    LIMIT ${limit} OFFSET ${offset}`;
            }
            
            # Get total count
            stream<record {}, error?> countStream = check queryDatabase(countQuery);
            record {}|error? countRecord = countStream.next();
            check countStream.close();
            
            int total = 0;
            if countRecord is record {} {
                total = <int>countRecord["total"];
            }
            
            # Get users
            stream<record {}, error?> usersStream = check queryDatabase(usersQuery);
            json[] users = [];
            
            error? e = usersStream.forEach(function(record {} user) {
                users.push(user.toJson());
            });
            check usersStream.close();
            
            if e is error {
                check sendInternalErrorResponse(caller, "Failed to fetch users", e);
                return;
            }
            
            check sendPaginatedResponse(caller, "Users retrieved successfully", 
                                      users.toJson(), page, limit, total);
            
        } catch (error e) {
            log:printError("Failed to fetch users", e);
            check sendInternalErrorResponse(caller, "Failed to fetch users", e);
        }
    }

    # Monitor all requests
    resource function get requests(http:Caller caller, http:Request req) returns error? {
        log:printInfo("Admin monitoring all requests");
        
        try {
            map<string[]> queryParams = req.getQueryParams();
            [int page, int limit] = extractPaginationParams(queryParams);
            int offset = (page - 1) * limit;
            
            # Get status filter
            string? status = ();
            if queryParams.hasKey("status") {
                string[]? statusValues = queryParams["status"];
                if statusValues is string[] && statusValues.length() > 0 {
                    status = statusValues[0];
                }
            }
            
            # Build query with optional status filter
            sql:ParameterizedQuery countQuery;
            sql:ParameterizedQuery requestsQuery;
            
            if status is string && (status == "pending" || status == "accepted" || status == "in_progress" || status == "completed" || status == "cancelled") {
                countQuery = `SELECT COUNT(*) as total FROM collection_requests WHERE status = ${status}`;
                requestsQuery = `
                    SELECT cr.*, 
                           u1.full_name as customer_name, 
                           u1.phone as customer_phone,
                           u2.full_name as collector_name,
                           u2.phone as collector_phone,
                           cp.address as customer_address
                    FROM collection_requests cr
                    LEFT JOIN users u1 ON cr.customer_id = u1.id
                    LEFT JOIN users u2 ON cr.collector_id = u2.id
                    LEFT JOIN customer_profiles cp ON u1.id = cp.user_id
                    WHERE cr.status = ${status}
                    ORDER BY cr.created_at DESC
                    LIMIT ${limit} OFFSET ${offset}`;
            } else {
                countQuery = `SELECT COUNT(*) as total FROM collection_requests`;
                requestsQuery = `
                    SELECT cr.*, 
                           u1.full_name as customer_name, 
                           u1.phone as customer_phone,
                           u2.full_name as collector_name,
                           u2.phone as collector_phone,
                           cp.address as customer_address
                    FROM collection_requests cr
                    LEFT JOIN users u1 ON cr.customer_id = u1.id
                    LEFT JOIN users u2 ON cr.collector_id = u2.id
                    LEFT JOIN customer_profiles cp ON u1.id = cp.user_id
                    ORDER BY cr.created_at DESC
                    LIMIT ${limit} OFFSET ${offset}`;
            }
            
            # Get total count
            stream<record {}, error?> countStream = check queryDatabase(countQuery);
            record {}|error? countRecord = countStream.next();
            check countStream.close();
            
            int total = 0;
            if countRecord is record {} {
                total = <int>countRecord["total"];
            }
            
            # Get requests
            stream<record {}, error?> requestsStream = check queryDatabase(requestsQuery);
            json[] requests = [];
            
            error? e = requestsStream.forEach(function(record {} request) {
                requests.push(request.toJson());
            });
            check requestsStream.close();
            
            if e is error {
                check sendInternalErrorResponse(caller, "Failed to fetch requests", e);
                return;
            }
            
            check sendPaginatedResponse(caller, "All requests retrieved successfully", 
                                      requests.toJson(), page, limit, total);
            
        } catch (error e) {
            log:printError("Failed to fetch requests", e);
            check sendInternalErrorResponse(caller, "Failed to fetch requests", e);
        }
    }

    # Generate analytics
    resource function get analytics/[string reportType](http:Caller caller, http:Request req) returns error? {
        log:printInfo(string `Admin analytics requested: ${reportType}`);
        
        try {
            json analyticsData = {};
            
            if reportType == "daily" {
                sql:ParameterizedQuery dailyQuery = `
                    SELECT 
                        DATE(completed_at) as date,
                        COUNT(*) as total_collections,
                        SUM(price) as total_revenue,
                        AVG(price) as avg_price,
                        COUNT(DISTINCT collector_id) as collectors_active
                    FROM collection_requests 
                    WHERE status = 'completed' 
                    AND DATE(completed_at) = CURDATE()
                    GROUP BY DATE(completed_at)`;
                
                stream<record {}, error?> dailyStream = check queryDatabase(dailyQuery);
                record {}|error? dailyRecord = dailyStream.next();
                check dailyStream.close();
                
                # Get average rating for today
                sql:ParameterizedQuery ratingQuery = `
                    SELECT AVG(rating) as avg_rating
                    FROM feedback f
                    JOIN collection_requests cr ON f.request_id = cr.id
                    WHERE DATE(cr.completed_at) = CURDATE()`;
                
                stream<record {}, error?> ratingStream = check queryDatabase(ratingQuery);
                record {}|error? ratingRecord = ratingStream.next();
                check ratingStream.close();
                
                analyticsData = {
                    "date": time:utcToString(time:utcNow())[0..9], # Extract date part
                    "total_collections": dailyRecord is record {} ? dailyRecord["total_collections"] : 0,
                    "total_revenue": dailyRecord is record {} ? dailyRecord["total_revenue"] : 0.0,
                    "avg_rating": ratingRecord is record {} ? ratingRecord["avg_rating"] : 0.0,
                    "collectors_active": dailyRecord is record {} ? dailyRecord["collectors_active"] : 0
                };
                
            } else if reportType == "weekly" {
                sql:ParameterizedQuery weeklyQuery = `
                    SELECT 
                        COUNT(*) as total_collections,
                        SUM(price) as total_revenue,
                        AVG(price) as avg_price,
                        COUNT(DISTINCT collector_id) as collectors_active,
                        COUNT(DISTINCT customer_id) as customers_served
                    FROM collection_requests 
                    WHERE status = 'completed' 
                    AND completed_at >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)`;
                
                stream<record {}, error?> weeklyStream = check queryDatabase(weeklyQuery);
                record {}|error? weeklyRecord = weeklyStream.next();
                check weeklyStream.close();
                
                # Get top collector for the week
                sql:ParameterizedQuery topCollectorQuery = `
                    SELECT u.full_name as collector_name, COUNT(*) as collections
                    FROM collection_requests cr
                    JOIN users u ON cr.collector_id = u.id
                    WHERE cr.status = 'completed' 
                    AND cr.completed_at >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
                    GROUP BY cr.collector_id, u.full_name
                    ORDER BY collections DESC
                    LIMIT 1`;
                
                stream<record {}, error?> topCollectorStream = check queryDatabase(topCollectorQuery);
                record {}|error? topCollectorRecord = topCollectorStream.next();
                check topCollectorStream.close();
                
                analyticsData = {
                    "week_ending": time:utcToString(time:utcNow())[0..9],
                    "total_collections": weeklyRecord is record {} ? weeklyRecord["total_collections"] : 0,
                    "total_revenue": weeklyRecord is record {} ? weeklyRecord["total_revenue"] : 0.0,
                    "customers_served": weeklyRecord is record {} ? weeklyRecord["customers_served"] : 0,
                    "top_collector": topCollectorRecord is record {} ? topCollectorRecord["collector_name"] : "N/A",
                    "collectors_active": weeklyRecord is record {} ? weeklyRecord["collectors_active"] : 0
                };
                
            } else if reportType == "monthly" {
                sql:ParameterizedQuery monthlyQuery = `
                    SELECT 
                        COUNT(*) as total_collections,
                        SUM(price) as total_revenue,
                        AVG(price) as avg_price,
                        COUNT(DISTINCT collector_id) as collectors_active,
                        COUNT(DISTINCT customer_id) as customers_served
                    FROM collection_requests 
                    WHERE status = 'completed' 
                    AND MONTH(completed_at) = MONTH(CURDATE()) 
                    AND YEAR(completed_at) = YEAR(CURDATE())`;
                
                stream<record {}, error?> monthlyStream = check queryDatabase(monthlyQuery);
                record {}|error? monthlyRecord = monthlyStream.next();
                check monthlyStream.close();
                
                # Get new customers and collectors this month
                sql:ParameterizedQuery newUsersQuery = `
                    SELECT 
                        COUNT(CASE WHEN user_type = 'customer' THEN 1 END) as new_customers,
                        COUNT(CASE WHEN user_type = 'collector' THEN 1 END) as new_collectors
                    FROM users 
                    WHERE MONTH(created_at) = MONTH(CURDATE()) 
                    AND YEAR(created_at) = YEAR(CURDATE())`;
                
                stream<record {}, error?> newUsersStream = check queryDatabase(newUsersQuery);
                record {}|error? newUsersRecord = newUsersStream.next();
                check newUsersStream.close();
                
                analyticsData = {
                    "month": time:utcToString(time:utcNow())[0..6], # Extract year-month
                    "total_collections": monthlyRecord is record {} ? monthlyRecord["total_collections"] : 0,
                    "total_revenue": monthlyRecord is record {} ? monthlyRecord["total_revenue"] : 0.0,
                    "new_customers": newUsersRecord is record {} ? newUsersRecord["new_customers"] : 0,
                    "new_collectors": newUsersRecord is record {} ? newUsersRecord["new_collectors"] : 0,
                    "customers_served": monthlyRecord is record {} ? monthlyRecord["customers_served"] : 0
                };
                
            } else {
                check sendBadRequestResponse(caller, "Invalid report type. Use: daily, weekly, monthly");
                return;
            }
            
            check sendSuccessResponse(caller, string `${reportType} analytics retrieved`, analyticsData);
            
        } catch (error e) {
            log:printError("Failed to generate analytics", e);
            check sendInternalErrorResponse(caller, "Failed to generate analytics", e);
        }
    }

    # Export data
    resource function get export/[string dataType](http:Caller caller, http:Request req) returns error? {
        log:printInfo(string `Admin data export requested: ${dataType}`);
        
        try {
            # Validate data type
            if dataType != "users" && dataType != "requests" && dataType != "feedback" && dataType != "earnings" {
                check sendBadRequestResponse(caller, "Invalid data type. Use: users, requests, feedback, earnings");
                return;
            }
            
            # For now, return export metadata (in production, generate actual file)
            json exportData = {
                "export_type": dataType,
                "timestamp": time:utcToString(time:utcNow()),
                "status": "prepared",
                "download_url": string `https://binbuddy.lk/exports/${dataType}_${time:utcToString(time:utcNow())}.csv`,
                "expires_at": time:utcToString(time:utcNow()), # In production, add expiry time
                "record_count": 100, # In production, get actual count
                "file_size": "2.5 MB" # In production, calculate actual size
            };
            
            check sendSuccessResponse(caller, string `${dataType} export prepared successfully`, exportData);
            
        } catch (error e) {
            log:printError("Failed to prepare export", e);
            check sendInternalErrorResponse(caller, "Failed to prepare export", e);
        }
    }

    # Update user status (activate/deactivate)
    resource function put users/[int userId]/status(http:Caller caller, http:Request req) returns error? {
        log:printInfo(string `Admin updating status for user: ${userId}`);
        
        json|error payload = req.getJsonPayload();
        if payload is error {
            check sendBadRequestResponse(caller, "Invalid JSON payload");
            return;
        }
        
        string[] requiredFields = ["isActive"];
        string? validationError = validateRequiredFields(payload, requiredFields);
        if validationError is string {
            check sendBadRequestResponse(caller, validationError);
            return;
        }
        
        try {
            boolean isActive = <boolean>payload.isActive;
            
            # Update user status
            sql:ParameterizedQuery updateQuery = `
                UPDATE users 
                SET is_active = ${isActive} 
                WHERE id = ${userId} AND user_type != 'admin'`;
            
            sql:ExecutionResult result = check executeQuery(updateQuery);
            
            if result.affectedRowCount == 0 {
                check sendNotFoundResponse(caller, "User not found or cannot modify admin user");
                return;
            }
            
            string statusMessage = isActive ? "activated" : "deactivated";
            
            json responseData = {
                "userId": userId,
                "isActive": isActive,
                "message": string `User ${statusMessage} successfully`
            };
            
            check sendSuccessResponse(caller, string `User ${statusMessage} successfully`, responseData);
            log:printInfo(string `User ${userId} ${statusMessage} by admin`);
            
        } catch (error e) {
            log:printError("Failed to update user status", e);
            check sendInternalErrorResponse(caller, "Failed to update user status", e);
        }
    }
}
