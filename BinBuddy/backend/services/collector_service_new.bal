# Collector Service for BinBuddy
# Handles all collector-related operations including registration, request management, and tracking

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
        log:printInfo("Initializing collector service database connection...");
        
        mysql:Client mysqlClient = check new (
            host = DB_HOST,
            port = DB_PORT,
            database = DB_NAME,
            user = DB_USERNAME,
            password = DB_PASSWORD
        );
        
        dbClient = mysqlClient;
        log:printInfo("Collector service database connection established");
        return;
    } catch (error e) {
        log:printError("Failed to initialize collector service database", e);
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

# HTTP listener for collector service
listener http:Listener collectorListener = new(8082);

# Collector Service Configuration
@http:ServiceConfig {
    cors: {
        allowOrigins: ["*"],
        allowCredentials: true,
        allowHeaders: ["Content-Type", "Authorization"],
        allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    }
}
service /api/collector on collectorListener {

    # Service initialization
    function init() returns error? {
        error? initResult = initDatabase();
        if initResult is error {
            log:printWarn("Collector service started without database connection", initResult);
        }
    }

    # Health check
    resource function get health() returns json {
        return {
            "service": "Collector Service",
            "status": "healthy",
            "timestamp": time:utcToString(time:utcNow()),
            "port": 8082
        };
    }

    # Collector registration
    resource function post register(http:Caller caller, http:Request req) returns error? {
        log:printInfo("Collector registration request received");
        
        json|error payload = req.getJsonPayload();
        if payload is error {
            check sendBadRequestResponse(caller, "Invalid JSON payload");
            return;
        }
        
        string[] requiredFields = ["fullName", "email", "password", "vehicleType", "vehicleNumber", "licenseNumber"];
        string? validationError = validateRequiredFields(payload, requiredFields);
        if validationError is string {
            check sendBadRequestResponse(caller, validationError);
            return;
        }
        
        try {
            # Check if collector already exists
            sql:ParameterizedQuery checkQuery = `SELECT id FROM users WHERE email = ${payload.email.toString()}`;
            stream<record {}, error?> existingUser = check queryDatabase(checkQuery);
            
            record {}|error? existing = existingUser.next();
            check existingUser.close();
            
            if existing is record {} {
                check sendBadRequestResponse(caller, "Collector already exists with this email");
                return;
            }
            
            # Create user account
            sql:ParameterizedQuery userQuery = `
                INSERT INTO users (email, password, user_type, full_name, phone, is_active) 
                VALUES (${payload.email.toString()}, ${payload.password.toString()}, 'collector', 
                        ${payload.fullName.toString()}, ${payload.phone.toString()}, true)`;
            
            sql:ExecutionResult userResult = check executeQuery(userQuery);
            int|string? userId = userResult.lastInsertId;
            
            if userId is () {
                check sendInternalErrorResponse(caller, "Failed to create user account");
                return;
            }
            
            # Create collector profile
            sql:ParameterizedQuery profileQuery = `
                INSERT INTO collector_profiles (user_id, vehicle_type, vehicle_number, license_number, 
                                              service_area, is_available, rating, total_collections) 
                VALUES (${userId}, ${payload.vehicleType.toString()}, ${payload.vehicleNumber.toString()}, 
                        ${payload.licenseNumber.toString()}, ${payload.serviceAreas.toString()}, 
                        true, 0.00, 0)`;
            
            sql:ExecutionResult profileResult = check executeQuery(profileQuery);
            
            json responseData = {
                "collectorId": userId,
                "email": payload.email,
                "fullName": payload.fullName,
                "message": "Collector registration successful! Welcome to BinBuddy!"
            };
            
            check sendCreatedResponse(caller, "Collector registered successfully", responseData);
            log:printInfo(string `Collector registered: ${payload.email.toString()}`);
            
        } catch (error e) {
            log:printError("Collector registration failed", e);
            check sendInternalErrorResponse(caller, "Registration failed", e);
        }
    }

    # Collector login
    resource function post login(http:Caller caller, http:Request req) returns error? {
        log:printInfo("Collector login request received");
        
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
            # Authenticate collector
            sql:ParameterizedQuery authQuery = `
                SELECT u.id, u.email, u.full_name, u.phone, u.is_active,
                       cp.vehicle_type, cp.vehicle_number, cp.is_available, cp.rating, cp.total_collections
                FROM users u
                LEFT JOIN collector_profiles cp ON u.id = cp.user_id
                WHERE u.email = ${payload.email.toString()} 
                AND u.password = ${payload.password.toString()} 
                AND u.user_type = 'collector'`;
            
            stream<record {}, error?> userStream = check queryDatabase(authQuery);
            record {}|error? userRecord = userStream.next();
            check userStream.close();
            
            if userRecord is () {
                check sendUnauthorizedResponse(caller, "Invalid email or password");
                return;
            }
            
            if userRecord is record {} {
                if userRecord["is_active"] == false {
                    check sendForbiddenResponse(caller, "Account is deactivated");
                    return;
                }
                
                string sessionToken = uuid:createType1AsString();
                
                json responseData = {
                    "collectorId": userRecord["id"],
                    "email": userRecord["email"],
                    "fullName": userRecord["full_name"],
                    "phone": userRecord["phone"],
                    "vehicleType": userRecord["vehicle_type"],
                    "vehicleNumber": userRecord["vehicle_number"],
                    "isAvailable": userRecord["is_available"],
                    "rating": userRecord["rating"],
                    "totalCollections": userRecord["total_collections"],
                    "sessionToken": sessionToken
                };
                
                check sendSuccessResponse(caller, "Login successful", responseData);
                log:printInfo(string `Collector logged in: ${payload.email.toString()}`);
            }
            
        } catch (error e) {
            log:printError("Collector login failed", e);
            check sendInternalErrorResponse(caller, "Login failed", e);
        }
    }

    # Get available collection requests
    resource function get [int collectorId]/requests/available(http:Caller caller, http:Request req) returns error? {
        log:printInfo(string `Fetching available requests for collector: ${collectorId}`);
        
        try {
            map<string[]> queryParams = req.getQueryParams();
            [int page, int limit] = extractPaginationParams(queryParams);
            int offset = (page - 1) * limit;
            
            # Get total count
            sql:ParameterizedQuery countQuery = `
                SELECT COUNT(*) as total FROM collection_requests 
                WHERE status = 'pending' AND collector_id IS NULL`;
            
            stream<record {}, error?> countStream = check queryDatabase(countQuery);
            record {}|error? countRecord = countStream.next();
            check countStream.close();
            
            int total = 0;
            if countRecord is record {} {
                total = <int>countRecord["total"];
            }
            
            # Get available requests
            sql:ParameterizedQuery requestsQuery = `
                SELECT cr.*, u.full_name as customer_name, u.phone as customer_phone,
                       cp.address as customer_address
                FROM collection_requests cr
                LEFT JOIN users u ON cr.customer_id = u.id
                LEFT JOIN customer_profiles cp ON u.id = cp.user_id
                WHERE cr.status = 'pending' AND cr.collector_id IS NULL
                ORDER BY cr.created_at ASC
                LIMIT ${limit} OFFSET ${offset}`;
            
            stream<record {}, error?> requestsStream = check queryDatabase(requestsQuery);
            json[] requests = [];
            
            error? e = requestsStream.forEach(function(record {} req) {
                requests.push(req.toJson());
            });
            check requestsStream.close();
            
            if e is error {
                check sendInternalErrorResponse(caller, "Failed to fetch requests", e);
                return;
            }
            
            check sendPaginatedResponse(caller, "Available requests retrieved", 
                                      requests.toJson(), page, limit, total);
            
        } catch (error e) {
            log:printError("Failed to fetch available requests", e);
            check sendInternalErrorResponse(caller, "Failed to fetch available requests", e);
        }
    }

    # Get collector's assigned requests
    resource function get [int collectorId]/requests/assigned(http:Caller caller, http:Request req) returns error? {
        log:printInfo(string `Fetching assigned requests for collector: ${collectorId}`);
        
        try {
            map<string[]> queryParams = req.getQueryParams();
            [int page, int limit] = extractPaginationParams(queryParams);
            int offset = (page - 1) * limit;
            
            # Get total count
            sql:ParameterizedQuery countQuery = `
                SELECT COUNT(*) as total FROM collection_requests 
                WHERE collector_id = ${collectorId} AND status IN ('accepted', 'in_progress')`;
            
            stream<record {}, error?> countStream = check queryDatabase(countQuery);
            record {}|error? countRecord = countStream.next();
            check countStream.close();
            
            int total = 0;
            if countRecord is record {} {
                total = <int>countRecord["total"];
            }
            
            # Get assigned requests
            sql:ParameterizedQuery requestsQuery = `
                SELECT cr.*, u.full_name as customer_name, u.phone as customer_phone,
                       cp.address as customer_address
                FROM collection_requests cr
                LEFT JOIN users u ON cr.customer_id = u.id
                LEFT JOIN customer_profiles cp ON u.id = cp.user_id
                WHERE cr.collector_id = ${collectorId} AND cr.status IN ('accepted', 'in_progress')
                ORDER BY cr.accepted_at ASC
                LIMIT ${limit} OFFSET ${offset}`;
            
            stream<record {}, error?> requestsStream = check queryDatabase(requestsQuery);
            json[] requests = [];
            
            error? e = requestsStream.forEach(function(record {} req) {
                requests.push(req.toJson());
            });
            check requestsStream.close();
            
            if e is error {
                check sendInternalErrorResponse(caller, "Failed to fetch requests", e);
                return;
            }
            
            check sendPaginatedResponse(caller, "Assigned requests retrieved", 
                                      requests.toJson(), page, limit, total);
            
        } catch (error e) {
            log:printError("Failed to fetch assigned requests", e);
            check sendInternalErrorResponse(caller, "Failed to fetch assigned requests", e);
        }
    }

    # Accept, reject, start, or complete collection request
    resource function put [int collectorId]/requests/[int requestId]/action(http:Caller caller, http:Request req) returns error? {
        log:printInfo(string `Action on request ${requestId} by collector ${collectorId}`);
        
        json|error payload = req.getJsonPayload();
        if payload is error {
            check sendBadRequestResponse(caller, "Invalid JSON payload");
            return;
        }
        
        string[] requiredFields = ["action"];
        string? validationError = validateRequiredFields(payload, requiredFields);
        if validationError is string {
            check sendBadRequestResponse(caller, validationError);
            return;
        }
        
        try {
            string action = payload.action.toString();
            
            if action != "accept" && action != "reject" && action != "start" && action != "complete" {
                check sendBadRequestResponse(caller, "Invalid action. Use: accept, reject, start, complete");
                return;
            }
            
            # Check if request exists and is in valid state
            sql:ParameterizedQuery checkQuery = `
                SELECT status, collector_id FROM collection_requests WHERE id = ${requestId}`;
            
            stream<record {}, error?> checkStream = check queryDatabase(checkQuery);
            record {}|error? requestRecord = checkStream.next();
            check checkStream.close();
            
            if requestRecord is () {
                check sendNotFoundResponse(caller, "Collection request not found");
                return;
            }
            
            if requestRecord is record {} {
                string currentStatus = requestRecord["status"].toString();
                int? currentCollectorId = <int?>requestRecord["collector_id"];
                
                # Validate action based on current status
                if action == "accept" && currentStatus != "pending" {
                    check sendBadRequestResponse(caller, "Request is not available for acceptance");
                    return;
                }
                
                if action == "start" && (currentStatus != "accepted" || currentCollectorId != collectorId) {
                    check sendBadRequestResponse(caller, "Request is not ready to start or not assigned to you");
                    return;
                }
                
                if action == "complete" && (currentStatus != "in_progress" || currentCollectorId != collectorId) {
                    check sendBadRequestResponse(caller, "Request is not in progress or not assigned to you");
                    return;
                }
                
                # Update request based on action
                string newStatus;
                string updateColumn;
                
                if action == "accept" {
                    newStatus = "accepted";
                    updateColumn = "accepted_at";
                    
                    sql:ParameterizedQuery updateQuery = `
                        UPDATE collection_requests 
                        SET status = ${newStatus}, collector_id = ${collectorId}, ${updateColumn} = NOW() 
                        WHERE id = ${requestId}`;
                    
                    _ = check executeQuery(updateQuery);
                    
                } else if action == "reject" {
                    newStatus = "pending";
                    
                    sql:ParameterizedQuery updateQuery = `
                        UPDATE collection_requests 
                        SET status = ${newStatus}, collector_id = NULL 
                        WHERE id = ${requestId}`;
                    
                    _ = check executeQuery(updateQuery);
                    
                } else if action == "start" {
                    newStatus = "in_progress";
                    updateColumn = "started_at";
                    
                    sql:ParameterizedQuery updateQuery = `
                        UPDATE collection_requests 
                        SET status = ${newStatus}, ${updateColumn} = NOW() 
                        WHERE id = ${requestId}`;
                    
                    _ = check executeQuery(updateQuery);
                    
                    # Add location tracking if provided
                    if payload.latitude is decimal && payload.longitude is decimal {
                        sql:ParameterizedQuery trackingQuery = `
                            INSERT INTO collection_tracking (request_id, collector_latitude, collector_longitude, status_update)
                            VALUES (${requestId}, ${payload.latitude}, ${payload.longitude}, 'Collection started')`;
                        
                        _ = check executeQuery(trackingQuery);
                    }
                    
                } else if action == "complete" {
                    newStatus = "completed";
                    updateColumn = "completed_at";
                    
                    sql:ParameterizedQuery updateQuery = `
                        UPDATE collection_requests 
                        SET status = ${newStatus}, ${updateColumn} = NOW() 
                        WHERE id = ${requestId}`;
                    
                    _ = check executeQuery(updateQuery);
                    
                    # Update collector's total collections
                    sql:ParameterizedQuery collectorUpdateQuery = `
                        UPDATE collector_profiles 
                        SET total_collections = total_collections + 1 
                        WHERE user_id = ${collectorId}`;
                    
                    _ = check executeQuery(collectorUpdateQuery);
                    
                    # Add final tracking update
                    if payload.latitude is decimal && payload.longitude is decimal {
                        sql:ParameterizedQuery trackingQuery = `
                            INSERT INTO collection_tracking (request_id, collector_latitude, collector_longitude, status_update)
                            VALUES (${requestId}, ${payload.latitude}, ${payload.longitude}, 'Collection completed')`;
                        
                        _ = check executeQuery(trackingQuery);
                    }
                }
                
                json responseData = {
                    "requestId": requestId,
                    "collectorId": collectorId,
                    "action": action,
                    "newStatus": newStatus,
                    "message": string `Request ${action} processed successfully`
                };
                
                check sendSuccessResponse(caller, string `Request ${action} successful`, responseData);
                log:printInfo(string `Request ${requestId} ${action} by collector ${collectorId}`);
            }
            
        } catch (error e) {
            log:printError("Failed to process request action", e);
            check sendInternalErrorResponse(caller, "Failed to process request action", e);
        }
    }

    # Update collector location
    resource function put [int collectorId]/location(http:Caller caller, http:Request req) returns error? {
        log:printInfo(string `Location update for collector: ${collectorId}`);
        
        json|error payload = req.getJsonPayload();
        if payload is error {
            check sendBadRequestResponse(caller, "Invalid JSON payload");
            return;
        }
        
        string[] requiredFields = ["latitude", "longitude"];
        string? validationError = validateRequiredFields(payload, requiredFields);
        if validationError is string {
            check sendBadRequestResponse(caller, validationError);
            return;
        }
        
        try {
            # Update collector's current location
            sql:ParameterizedQuery updateQuery = `
                UPDATE collector_profiles 
                SET current_latitude = ${payload.latitude}, current_longitude = ${payload.longitude} 
                WHERE user_id = ${collectorId}`;
            
            sql:ExecutionResult result = check executeQuery(updateQuery);
            
            json responseData = {
                "collectorId": collectorId,
                "latitude": payload.latitude,
                "longitude": payload.longitude,
                "timestamp": time:utcToString(time:utcNow())
            };
            
            check sendSuccessResponse(caller, "Location updated successfully", responseData);
            log:printInfo(string `Location updated for collector ${collectorId}`);
            
        } catch (error e) {
            log:printError("Failed to update location", e);
            check sendInternalErrorResponse(caller, "Failed to update location", e);
        }
    }

    # Update availability status
    resource function put [int collectorId]/availability(http:Caller caller, http:Request req) returns error? {
        log:printInfo(string `Availability update for collector: ${collectorId}`);
        
        json|error payload = req.getJsonPayload();
        if payload is error {
            check sendBadRequestResponse(caller, "Invalid JSON payload");
            return;
        }
        
        string[] requiredFields = ["isAvailable"];
        string? validationError = validateRequiredFields(payload, requiredFields);
        if validationError is string {
            check sendBadRequestResponse(caller, validationError);
            return;
        }
        
        try {
            boolean isAvailable = <boolean>payload.isAvailable;
            
            # Update collector availability
            sql:ParameterizedQuery updateQuery = `
                UPDATE collector_profiles 
                SET is_available = ${isAvailable} 
                WHERE user_id = ${collectorId}`;
            
            sql:ExecutionResult result = check executeQuery(updateQuery);
            
            string statusMessage = isAvailable ? "now available for new requests" : "temporarily unavailable";
            
            json responseData = {
                "collectorId": collectorId,
                "isAvailable": isAvailable,
                "message": string `Collector is ${statusMessage}`
            };
            
            check sendSuccessResponse(caller, string `Collector is ${statusMessage}`, responseData);
            log:printInfo(string `Collector ${collectorId} availability: ${isAvailable}`);
            
        } catch (error e) {
            log:printError("Failed to update availability", e);
            check sendInternalErrorResponse(caller, "Failed to update availability", e);
        }
    }

    # Get collector dashboard data
    resource function get [int collectorId]/dashboard(http:Caller caller, http:Request req) returns error? {
        log:printInfo(string `Fetching dashboard data for collector: ${collectorId}`);
        
        try {
            # Get collector statistics
            sql:ParameterizedQuery statsQuery = `
                SELECT 
                    COUNT(*) as total_requests,
                    COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed_requests,
                    COUNT(CASE WHEN status = 'accepted' THEN 1 END) as accepted_requests,
                    COUNT(CASE WHEN status = 'in_progress' THEN 1 END) as active_requests,
                    COALESCE(SUM(CASE WHEN status = 'completed' THEN price END), 0) as total_earnings
                FROM collection_requests 
                WHERE collector_id = ${collectorId}`;
            
            stream<record {}, error?> statsStream = check queryDatabase(statsQuery);
            record {}|error? statsRecord = statsStream.next();
            check statsStream.close();
            
            # Get collector profile info
            sql:ParameterizedQuery profileQuery = `
                SELECT cp.rating, cp.total_collections, cp.is_available
                FROM collector_profiles cp
                WHERE cp.user_id = ${collectorId}`;
            
            stream<record {}, error?> profileStream = check queryDatabase(profileQuery);
            record {}|error? profileRecord = profileStream.next();
            check profileStream.close();
            
            # Get recent requests
            sql:ParameterizedQuery recentQuery = `
                SELECT cr.*, u.full_name as customer_name
                FROM collection_requests cr
                LEFT JOIN users u ON cr.customer_id = u.id
                WHERE cr.collector_id = ${collectorId}
                ORDER BY cr.created_at DESC
                LIMIT 5`;
            
            stream<record {}, error?> recentStream = check queryDatabase(recentQuery);
            json[] recentRequests = [];
            
            error? e = recentStream.forEach(function(record {} req) {
                recentRequests.push(req.toJson());
            });
            check recentStream.close();
            
            # Get today's earnings
            sql:ParameterizedQuery todayQuery = `
                SELECT COALESCE(SUM(price), 0) as today_earnings
                FROM collection_requests 
                WHERE collector_id = ${collectorId} 
                AND status = 'completed' 
                AND DATE(completed_at) = CURDATE()`;
            
            stream<record {}, error?> todayStream = check queryDatabase(todayQuery);
            record {}|error? todayRecord = todayStream.next();
            check todayStream.close();
            
            json dashboardData = {
                "statistics": statsRecord is record {} ? 
                    {
                        "total_requests": statsRecord["total_requests"],
                        "completed_requests": statsRecord["completed_requests"],
                        "accepted_requests": statsRecord["accepted_requests"],
                        "active_requests": statsRecord["active_requests"],
                        "total_earnings": statsRecord["total_earnings"],
                        "rating": profileRecord is record {} ? profileRecord["rating"] : 0.0,
                        "total_collections": profileRecord is record {} ? profileRecord["total_collections"] : 0,
                        "is_available": profileRecord is record {} ? profileRecord["is_available"] : false
                    } : {},
                "recentRequests": recentRequests.toJson(),
                "todayEarnings": {
                    "today_earnings": todayRecord is record {} ? todayRecord["today_earnings"] : 0.0
                }
            };
            
            check sendSuccessResponse(caller, "Dashboard data retrieved", dashboardData);
            
        } catch (error e) {
            log:printError("Failed to fetch dashboard data", e);
            check sendInternalErrorResponse(caller, "Failed to fetch dashboard data", e);
        }
    }

    # Get collector earnings report
    resource function get [int collectorId]/earnings(http:Caller caller, http:Request req) returns error? {
        log:printInfo(string `Fetching earnings for collector: ${collectorId}`);
        
        try {
            # Get daily earnings for the last 30 days
            sql:ParameterizedQuery dailyQuery = `
                SELECT 
                    DATE(completed_at) as date,
                    COUNT(*) as collections_count,
                    SUM(price) as daily_earnings
                FROM collection_requests 
                WHERE collector_id = ${collectorId} 
                AND status = 'completed'
                AND completed_at >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
                GROUP BY DATE(completed_at)
                ORDER BY DATE(completed_at) DESC`;
            
            stream<record {}, error?> dailyStream = check queryDatabase(dailyQuery);
            json[] dailyEarnings = [];
            
            error? e = dailyStream.forEach(function(record {} earning) {
                dailyEarnings.push(earning.toJson());
            });
            check dailyStream.close();
            
            # Get summary statistics
            sql:ParameterizedQuery summaryQuery = `
                SELECT 
                    COUNT(*) as total_collections,
                    COALESCE(SUM(price), 0) as total_earnings,
                    COALESCE(AVG(price), 0) as avg_earnings_per_collection
                FROM collection_requests 
                WHERE collector_id = ${collectorId} AND status = 'completed'`;
            
            stream<record {}, error?> summaryStream = check queryDatabase(summaryQuery);
            record {}|error? summaryRecord = summaryStream.next();
            check summaryStream.close();
            
            json responseData = {
                "dailyEarnings": dailyEarnings.toJson(),
                "summary": summaryRecord is record {} ? summaryRecord.toJson() : {}
            };
            
            check sendSuccessResponse(caller, "Earnings data retrieved", responseData);
            
        } catch (error e) {
            log:printError("Failed to fetch earnings data", e);
            check sendInternalErrorResponse(caller, "Failed to fetch earnings data", e);
        }
    }
}
