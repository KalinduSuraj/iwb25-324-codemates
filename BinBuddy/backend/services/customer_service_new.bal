# Customer Service for BinBuddy
# Handles all customer-related operations including registration, collection requests, and tracking

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
        log:printInfo("Initializing customer service database connection...");
        
        mysql:Client mysqlClient = check new (
            host = DB_HOST,
            port = DB_PORT,
            database = DB_NAME,
            user = DB_USERNAME,
            password = DB_PASSWORD
        );
        
        dbClient = mysqlClient;
        log:printInfo("Customer service database connection established");
        return;
    } catch (error e) {
        log:printError("Failed to initialize customer service database", e);
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

# HTTP listener for customer service
listener http:Listener customerListener = new(8081);

# Customer Service Configuration
@http:ServiceConfig {
    cors: {
        allowOrigins: ["*"],
        allowCredentials: true,
        allowHeaders: ["Content-Type", "Authorization"],
        allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    }
}
service /api/customer on customerListener {

    # Service initialization
    function init() returns error? {
        error? initResult = initDatabase();
        if initResult is error {
            log:printWarn("Customer service started without database connection", initResult);
        }
    }

    # Health check
    resource function get health() returns json {
        return {
            "service": "Customer Service",
            "status": "healthy",
            "timestamp": time:utcToString(time:utcNow()),
            "port": 8081
        };
    }

    # Customer registration
    resource function post register(http:Caller caller, http:Request req) returns error? {
        log:printInfo("Customer registration request received");
        
        json|error payload = req.getJsonPayload();
        if payload is error {
            check sendBadRequestResponse(caller, "Invalid JSON payload");
            return;
        }
        
        string[] requiredFields = ["fullName", "email", "password", "address", "latitude", "longitude"];
        string? validationError = validateRequiredFields(payload, requiredFields);
        if validationError is string {
            check sendBadRequestResponse(caller, validationError);
            return;
        }
        
        try {
            # Check if customer already exists
            sql:ParameterizedQuery checkQuery = `SELECT id FROM users WHERE email = ${payload.email.toString()}`;
            stream<record {}, error?> existingUser = check queryDatabase(checkQuery);
            
            record {}|error? existing = existingUser.next();
            check existingUser.close();
            
            if existing is record {} {
                check sendBadRequestResponse(caller, "Customer already exists with this email");
                return;
            }
            
            # Create user account
            sql:ParameterizedQuery userQuery = `
                INSERT INTO users (email, password, user_type, full_name, phone, is_active) 
                VALUES (${payload.email.toString()}, ${payload.password.toString()}, 'customer', 
                        ${payload.fullName.toString()}, ${payload.phone.toString()}, true)`;
            
            sql:ExecutionResult userResult = check executeQuery(userQuery);
            int|string? userId = userResult.lastInsertId;
            
            if userId is () {
                check sendInternalErrorResponse(caller, "Failed to create user account");
                return;
            }
            
            # Create customer profile
            sql:ParameterizedQuery profileQuery = `
                INSERT INTO customer_profiles (user_id, address, latitude, longitude, 
                                             location_pin_name, subscription_type) 
                VALUES (${userId}, ${payload.address.toString()}, ${payload.latitude}, 
                        ${payload.longitude}, ${payload.locationPinName.toString()}, 'basic')`;
            
            sql:ExecutionResult profileResult = check executeQuery(profileQuery);
            
            json responseData = {
                "customerId": userId,
                "email": payload.email,
                "fullName": payload.fullName,
                "message": "Registration successful! Welcome to BinBuddy!"
            };
            
            check sendCreatedResponse(caller, "Customer registered successfully", responseData);
            log:printInfo(string `Customer registered: ${payload.email.toString()}`);
            
        } catch (error e) {
            log:printError("Customer registration failed", e);
            check sendInternalErrorResponse(caller, "Registration failed", e);
        }
    }

    # Customer login
    resource function post login(http:Caller caller, http:Request req) returns error? {
        log:printInfo("Customer login request received");
        
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
            # Authenticate user
            sql:ParameterizedQuery authQuery = `
                SELECT u.id, u.email, u.full_name, u.phone, u.is_active,
                       cp.address, cp.latitude, cp.longitude, cp.location_pin_name, cp.subscription_type
                FROM users u
                LEFT JOIN customer_profiles cp ON u.id = cp.user_id
                WHERE u.email = ${payload.email.toString()} 
                AND u.password = ${payload.password.toString()} 
                AND u.user_type = 'customer'`;
            
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
                    "customerId": userRecord["id"],
                    "email": userRecord["email"],
                    "fullName": userRecord["full_name"],
                    "phone": userRecord["phone"],
                    "address": userRecord["address"],
                    "latitude": userRecord["latitude"],
                    "longitude": userRecord["longitude"],
                    "locationPinName": userRecord["location_pin_name"],
                    "subscriptionType": userRecord["subscription_type"],
                    "sessionToken": sessionToken
                };
                
                check sendSuccessResponse(caller, "Login successful", responseData);
                log:printInfo(string `Customer logged in: ${payload.email.toString()}`);
            }
            
        } catch (error e) {
            log:printError("Customer login failed", e);
            check sendInternalErrorResponse(caller, "Login failed", e);
        }
    }

    # Create collection request
    resource function post [int customerId]/requests(http:Caller caller, http:Request req) returns error? {
        log:printInfo(string `Collection request from customer: ${customerId}`);
        
        json|error payload = req.getJsonPayload();
        if payload is error {
            check sendBadRequestResponse(caller, "Invalid JSON payload");
            return;
        }
        
        string[] requiredFields = ["requestType", "pickupAddress", "pickupLatitude", "pickupLongitude"];
        string? validationError = validateRequiredFields(payload, requiredFields);
        if validationError is string {
            check sendBadRequestResponse(caller, validationError);
            return;
        }
        
        try {
            string requestType = payload.requestType.toString();
            if requestType != "immediate" && requestType != "scheduled" {
                check sendBadRequestResponse(caller, "Request type must be 'immediate' or 'scheduled'");
                return;
            }
            
            string? scheduledDate = ();
            if requestType == "scheduled" {
                if payload.scheduledDate is () {
                    check sendBadRequestResponse(caller, "Scheduled date is required for scheduled requests");
                    return;
                }
                scheduledDate = payload.scheduledDate.toString();
            }
            
            decimal estimatedPrice = 10.00;
            if payload.estimatedWeight is decimal {
                estimatedPrice = <decimal>payload.estimatedWeight * 2.0;
            }
            
            sql:ParameterizedQuery requestQuery = `
                INSERT INTO collection_requests (
                    customer_id, request_type, scheduled_date, pickup_address, 
                    pickup_latitude, pickup_longitude, waste_type, estimated_weight, 
                    special_instructions, status, price
                ) VALUES (
                    ${customerId}, ${requestType}, ${scheduledDate}, 
                    ${payload.pickupAddress.toString()}, ${payload.pickupLatitude}, 
                    ${payload.pickupLongitude}, ${payload.wasteType.toString()}, 
                    ${payload.estimatedWeight}, ${payload.specialInstructions.toString()}, 
                    'pending', ${estimatedPrice}
                )`;
            
            sql:ExecutionResult result = check executeQuery(requestQuery);
            int|string? requestId = result.lastInsertId;
            
            if requestId is () {
                check sendInternalErrorResponse(caller, "Failed to create collection request");
                return;
            }
            
            json responseData = {
                "requestId": requestId,
                "status": "pending",
                "estimatedPrice": estimatedPrice,
                "message": "Collection request created successfully"
            };
            
            check sendCreatedResponse(caller, "Collection request submitted", responseData);
            log:printInfo(string `Collection request created: ${requestId.toString()}`);
            
        } catch (error e) {
            log:printError("Failed to create collection request", e);
            check sendInternalErrorResponse(caller, "Failed to create collection request", e);
        }
    }

    # Get customer's collection requests
    resource function get [int customerId]/requests(http:Caller caller, http:Request req) returns error? {
        log:printInfo(string `Fetching requests for customer: ${customerId}`);
        
        try {
            map<string[]> queryParams = req.getQueryParams();
            [int page, int limit] = extractPaginationParams(queryParams);
            int offset = (page - 1) * limit;
            
            sql:ParameterizedQuery countQuery = `
                SELECT COUNT(*) as total FROM collection_requests WHERE customer_id = ${customerId}`;
            
            stream<record {}, error?> countStream = check queryDatabase(countQuery);
            record {}|error? countRecord = countStream.next();
            check countStream.close();
            
            int total = 0;
            if countRecord is record {} {
                total = <int>countRecord["total"];
            }
            
            sql:ParameterizedQuery requestsQuery = `
                SELECT cr.*, u.full_name as collector_name
                FROM collection_requests cr
                LEFT JOIN users u ON cr.collector_id = u.id
                WHERE cr.customer_id = ${customerId}
                ORDER BY cr.created_at DESC
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
            
            check sendPaginatedResponse(caller, "Requests fetched successfully", 
                                      requests.toJson(), page, limit, total);
            
        } catch (error e) {
            log:printError("Failed to fetch customer requests", e);
            check sendInternalErrorResponse(caller, "Failed to fetch requests", e);
        }
    }

    # Track collection request
    resource function get [int customerId]/requests/[int requestId]/track(http:Caller caller, http:Request req) returns error? {
        log:printInfo(string `Tracking request ${requestId} for customer ${customerId}`);
        
        try {
            sql:ParameterizedQuery trackQuery = `
                SELECT cr.*, u.full_name as collector_name, u.phone as collector_phone,
                       cp.current_latitude, cp.current_longitude
                FROM collection_requests cr
                LEFT JOIN users u ON cr.collector_id = u.id
                LEFT JOIN collector_profiles cp ON u.id = cp.user_id
                WHERE cr.id = ${requestId} AND cr.customer_id = ${customerId}`;
            
            stream<record {}, error?> trackStream = check queryDatabase(trackQuery);
            record {}|error? trackRecord = trackStream.next();
            check trackStream.close();
            
            if trackRecord is () {
                check sendNotFoundResponse(caller, "Collection request not found");
                return;
            }
            
            if trackRecord is record {} {
                sql:ParameterizedQuery updatesQuery = `
                    SELECT * FROM collection_tracking 
                    WHERE request_id = ${requestId} 
                    ORDER BY updated_at DESC LIMIT 10`;
                
                stream<record {}, error?> updatesStream = check queryDatabase(updatesQuery);
                json[] trackingUpdates = [];
                
                error? e = updatesStream.forEach(function(record {} update) {
                    trackingUpdates.push(update.toJson());
                });
                check updatesStream.close();
                
                json responseData = {
                    "request": trackRecord.toJson(),
                    "trackingUpdates": trackingUpdates.toJson()
                };
                
                check sendSuccessResponse(caller, "Tracking information retrieved", responseData);
            }
            
        } catch (error e) {
            log:printError("Failed to track collection request", e);
            check sendInternalErrorResponse(caller, "Failed to get tracking information", e);
        }
    }

    # Submit feedback
    resource function post [int customerId]/requests/[int requestId]/feedback(http:Caller caller, http:Request req) returns error? {
        log:printInfo(string `Feedback submission for request ${requestId} by customer ${customerId}`);
        
        json|error payload = req.getJsonPayload();
        if payload is error {
            check sendBadRequestResponse(caller, "Invalid JSON payload");
            return;
        }
        
        string[] requiredFields = ["rating"];
        string? validationError = validateRequiredFields(payload, requiredFields);
        if validationError is string {
            check sendBadRequestResponse(caller, validationError);
            return;
        }
        
        try {
            int rating = <int>payload.rating;
            if rating < 1 || rating > 5 {
                check sendBadRequestResponse(caller, "Rating must be between 1 and 5");
                return;
            }
            
            sql:ParameterizedQuery checkQuery = `
                SELECT collector_id FROM collection_requests 
                WHERE id = ${requestId} AND customer_id = ${customerId} AND status = 'completed'`;
            
            stream<record {}, error?> checkStream = check queryDatabase(checkQuery);
            record {}|error? requestRecord = checkStream.next();
            check checkStream.close();
            
            if requestRecord is () {
                check sendNotFoundResponse(caller, "Completed collection request not found");
                return;
            }
            
            if requestRecord is record {} {
                int collectorId = <int>requestRecord["collector_id"];
                
                sql:ParameterizedQuery feedbackQuery = `
                    INSERT INTO feedback (request_id, customer_id, collector_id, rating, comment)
                    VALUES (${requestId}, ${customerId}, ${collectorId}, ${rating}, ${payload.comment.toString()})`;
                
                sql:ExecutionResult result = check executeQuery(feedbackQuery);
                
                check sendCreatedResponse(caller, "Feedback submitted successfully", 
                                         {"feedbackId": result.lastInsertId});
                log:printInfo(string `Feedback submitted for request ${requestId}`);
            }
            
        } catch (error e) {
            log:printError("Failed to submit feedback", e);
            check sendInternalErrorResponse(caller, "Failed to submit feedback", e);
        }
    }

    # Get customer dashboard data
    resource function get [int customerId]/dashboard(http:Caller caller, http:Request req) returns error? {
        log:printInfo(string `Fetching dashboard data for customer: ${customerId}`);
        
        try {
            sql:ParameterizedQuery statsQuery = `
                SELECT 
                    COUNT(*) as total_requests,
                    COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed_requests,
                    COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_requests,
                    COUNT(CASE WHEN status = 'in_progress' THEN 1 END) as active_requests,
                    COALESCE(SUM(CASE WHEN status = 'completed' THEN price END), 0) as total_spent
                FROM collection_requests 
                WHERE customer_id = ${customerId}`;
            
            stream<record {}, error?> statsStream = check queryDatabase(statsQuery);
            record {}|error? statsRecord = statsStream.next();
            check statsStream.close();
            
            sql:ParameterizedQuery recentQuery = `
                SELECT cr.*, u.full_name as collector_name
                FROM collection_requests cr
                LEFT JOIN users u ON cr.collector_id = u.id
                WHERE cr.customer_id = ${customerId}
                ORDER BY cr.created_at DESC
                LIMIT 5`;
            
            stream<record {}, error?> recentStream = check queryDatabase(recentQuery);
            json[] recentRequests = [];
            
            error? e = recentStream.forEach(function(record {} req) {
                recentRequests.push(req.toJson());
            });
            check recentStream.close();
            
            json dashboardData = {
                "statistics": statsRecord is record {} ? statsRecord.toJson() : {},
                "recentRequests": recentRequests.toJson()
            };
            
            check sendSuccessResponse(caller, "Dashboard data retrieved", dashboardData);
            
        } catch (error e) {
            log:printError("Failed to fetch dashboard data", e);
            check sendInternalErrorResponse(caller, "Failed to fetch dashboard data", e);
        }
    }

    # Cancel collection request
    resource function put [int customerId]/requests/[int requestId]/cancel(http:Caller caller, http:Request req) returns error? {
        log:printInfo(string `Cancelling request ${requestId} for customer ${customerId}`);
        
        try {
            sql:ParameterizedQuery checkQuery = `
                SELECT status FROM collection_requests 
                WHERE id = ${requestId} AND customer_id = ${customerId}`;
            
            stream<record {}, error?> checkStream = check queryDatabase(checkQuery);
            record {}|error? requestRecord = checkStream.next();
            check checkStream.close();
            
            if requestRecord is () {
                check sendNotFoundResponse(caller, "Collection request not found");
                return;
            }
            
            if requestRecord is record {} {
                string status = requestRecord["status"].toString();
                
                if status != "pending" && status != "accepted" {
                    check sendBadRequestResponse(caller, "Request cannot be cancelled at this stage");
                    return;
                }
                
                sql:ParameterizedQuery cancelQuery = `
                    UPDATE collection_requests 
                    SET status = 'cancelled' 
                    WHERE id = ${requestId} AND customer_id = ${customerId}`;
                
                sql:ExecutionResult result = check executeQuery(cancelQuery);
                
                check sendSuccessResponse(caller, "Collection request cancelled successfully");
                log:printInfo(string `Request ${requestId} cancelled by customer ${customerId}`);
            }
            
        } catch (error e) {
            log:printError("Failed to cancel collection request", e);
            check sendInternalErrorResponse(caller, "Failed to cancel request", e);
        }
    }
}
