# Customer Service for BinBuddy
# Handles all customer-related operations including registration, collection requests, and tracking

import ballerina/http;
import ballerina/log;
import ballerina/sql;
import ballerina/time;
import ballerina/uuid;
import BinBuddy.backend.utils.db_connection as db;
import BinBuddy.backend.utils.response_handler as response;

# Customer service HTTP listener
listener http:Listener customerListener = new(8081);

# Customer data types
public type CustomerProfile record {|
    # Customer ID
    int id?;
    # User ID reference
    int userId?;
    # Full name
    string fullName;
    # Email address
    string email;
    # Phone number
    string? phone?;
    # Home address
    string address;
    # GPS coordinates
    decimal latitude;
    decimal longitude;
    # Location pin name
    string? locationPinName?;
    # Subscription type
    string subscriptionType?;
    # Profile image
    string? profileImage?;
    # Account status
    boolean isActive?;
    # Creation timestamp
    string? createdAt?;
|};

public type CollectionRequest record {|
    # Request ID
    int id?;
    # Customer ID
    int customerId;
    # Collector ID (assigned)
    int? collectorId?;
    # Request type: immediate or scheduled
    string requestType;
    # Scheduled date/time
    string? scheduledDate?;
    # Pickup address
    string pickupAddress;
    # Pickup coordinates
    decimal pickupLatitude;
    decimal pickupLongitude;
    # Type of waste
    string? wasteType?;
    # Estimated weight in kg
    decimal? estimatedWeight?;
    # Special instructions
    string? specialInstructions?;
    # Request status
    string status?;
    # Service price
    decimal? price?;
    # Timestamps
    string? createdAt?;
    string? acceptedAt?;
    string? startedAt?;
    string? completedAt?;
|};

public type CustomerRegistration record {|
    # Personal details
    string fullName;
    string email;
    string password;
    string? phone?;
    # Address details
    string address;
    decimal latitude;
    decimal longitude;
    string? locationPinName?;
    # Profile image
    string? profileImage?;
|};

public type CollectionRequestPayload record {|
    # Request type
    string requestType;
    # Scheduled date (for scheduled requests)
    string? scheduledDate?;
    # Pickup details
    string pickupAddress;
    decimal pickupLatitude;
    decimal pickupLongitude;
    # Waste details
    string? wasteType?;
    decimal? estimatedWeight?;
    string? specialInstructions?;
|};

public type FeedbackPayload record {|
    # Request ID
    int requestId;
    # Rating (1-5)
    int rating;
    # Comment
    string? comment?;
|};

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

    # Customer registration
    # Register a new customer with profile details and location
    resource function post register(http:Caller caller, http:Request req) returns error? {
        log:printInfo("Customer registration request received");
        
        json|error payload = req.getJsonPayload();
        if payload is error {
            check response:sendBadRequestResponse(caller, "Invalid JSON payload");
            return;
        }
        
        // Validate required fields
        string[] requiredFields = ["fullName", "email", "password", "address", "latitude", "longitude"];
        string? validationError = response:validateRequiredFields(payload, requiredFields);
        if validationError is string {
            check response:sendBadRequestResponse(caller, validationError);
            return;
        }
        
        try {
            // Check if customer already exists
            sql:ParameterizedQuery checkQuery = `SELECT id FROM users WHERE email = ${payload.email.toString()}`;
            stream<record {}, error?> existingUser = check db:queryDatabase(checkQuery);
            
            record {}|error? existing = existingUser.next();
            check existingUser.close();
            
            if existing is record {} {
                check response:sendBadRequestResponse(caller, "Customer already exists with this email");
                return;
            }
            
            // Create user account
            sql:ParameterizedQuery userQuery = `
                INSERT INTO users (email, password, user_type, full_name, phone, is_active) 
                VALUES (${payload.email.toString()}, ${payload.password.toString()}, 'customer', 
                        ${payload.fullName.toString()}, ${payload.phone.toString()}, true)`;
            
            sql:ExecutionResult userResult = check db:executeQuery(userQuery);
            int|string? userId = userResult.lastInsertId;
            
            if userId is () {
                check response:sendInternalErrorResponse(caller, "Failed to create user account");
                return;
            }
            
            // Create customer profile
            sql:ParameterizedQuery profileQuery = `
                INSERT INTO customer_profiles (user_id, address, latitude, longitude, 
                                             location_pin_name, subscription_type) 
                VALUES (${userId}, ${payload.address.toString()}, ${payload.latitude}, 
                        ${payload.longitude}, ${payload.locationPinName.toString()}, 'basic')`;
            
            sql:ExecutionResult profileResult = check db:executeQuery(profileQuery);
            
            // Prepare response data
            json responseData = {
                "customerId": userId,
                "email": payload.email,
                "fullName": payload.fullName,
                "message": "Registration successful! Welcome to BinBuddy!"
            };
            
            check response:sendCreatedResponse(caller, "Customer registered successfully", responseData);
            log:printInfo(string `Customer registered: ${payload.email.toString()}`);
            
        } catch (error e) {
            log:printError("Customer registration failed", e);
            check response:sendInternalErrorResponse(caller, "Registration failed", e);
        }
    }

    # Customer login
    # Authenticate customer and return profile information
    resource function post login(http:Caller caller, http:Request req) returns error? {
        log:printInfo("Customer login request received");
        
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
            // Authenticate user
            sql:ParameterizedQuery authQuery = `
                SELECT u.id, u.email, u.full_name, u.phone, u.is_active,
                       cp.address, cp.latitude, cp.longitude, cp.location_pin_name, cp.subscription_type
                FROM users u
                LEFT JOIN customer_profiles cp ON u.id = cp.user_id
                WHERE u.email = ${payload.email.toString()} 
                AND u.password = ${payload.password.toString()} 
                AND u.user_type = 'customer'`;
            
            stream<record {}, error?> userStream = check db:queryDatabase(authQuery);
            record {}|error? userRecord = userStream.next();
            check userStream.close();
            
            if userRecord is () {
                check response:sendUnauthorizedResponse(caller, "Invalid email or password");
                return;
            }
            
            if userRecord is record {} {
                if userRecord["is_active"] == false {
                    check response:sendForbiddenResponse(caller, "Account is deactivated");
                    return;
                }
                
                // Generate session token (in production, use JWT)
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
                
                check response:sendSuccessResponse(caller, "Login successful", responseData);
                log:printInfo(string `Customer logged in: ${payload.email.toString()}`);
            }
            
        } catch (error e) {
            log:printError("Customer login failed", e);
            check response:sendInternalErrorResponse(caller, "Login failed", e);
        }
    }

    # Create collection request
    # Customer can request immediate or scheduled garbage collection
    resource function post [int customerId]/requests(http:Caller caller, http:Request req) returns error? {
        log:printInfo(string `Collection request from customer: ${customerId}`);
        
        json|error payload = req.getJsonPayload();
        if payload is error {
            check response:sendBadRequestResponse(caller, "Invalid JSON payload");
            return;
        }
        
        string[] requiredFields = ["requestType", "pickupAddress", "pickupLatitude", "pickupLongitude"];
        string? validationError = response:validateRequiredFields(payload, requiredFields);
        if validationError is string {
            check response:sendBadRequestResponse(caller, validationError);
            return;
        }
        
        try {
            // Validate request type
            string requestType = payload.requestType.toString();
            if requestType != "immediate" && requestType != "scheduled" {
                check response:sendBadRequestResponse(caller, "Request type must be 'immediate' or 'scheduled'");
                return;
            }
            
            // For scheduled requests, validate date
            string? scheduledDate = ();
            if requestType == "scheduled" {
                if payload.scheduledDate is () {
                    check response:sendBadRequestResponse(caller, "Scheduled date is required for scheduled requests");
                    return;
                }
                scheduledDate = payload.scheduledDate.toString();
            }
            
            // Calculate estimated price based on waste type and weight
            decimal estimatedPrice = 10.00; // Base price
            if payload.estimatedWeight is decimal {
                estimatedPrice = <decimal>payload.estimatedWeight * 2.0; // $2 per kg
            }
            
            // Create collection request
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
            
            sql:ExecutionResult result = check db:executeQuery(requestQuery);
            int|string? requestId = result.lastInsertId;
            
            if requestId is () {
                check response:sendInternalErrorResponse(caller, "Failed to create collection request");
                return;
            }
            
            // Create notification for customer
            sql:ParameterizedQuery notificationQuery = `
                INSERT INTO notifications (user_id, request_id, title, message, type)
                VALUES (${customerId}, ${requestId}, 'Collection Request Created', 
                        'Your collection request has been submitted successfully', 'request_update')`;
            
            _ = check db:executeQuery(notificationQuery);
            
            json responseData = {
                "requestId": requestId,
                "status": "pending",
                "estimatedPrice": estimatedPrice,
                "message": "Collection request created successfully"
            };
            
            check response:sendCreatedResponse(caller, "Collection request submitted", responseData);
            log:printInfo(string `Collection request created: ${requestId.toString()}`);
            
        } catch (error e) {
            log:printError("Failed to create collection request", e);
            check response:sendInternalErrorResponse(caller, "Failed to create collection request", e);
        }
    }

    # Get customer's collection requests
    # Retrieve all collection requests for a specific customer
    resource function get [int customerId]/requests(http:Caller caller, http:Request req) returns error? {
        log:printInfo(string `Fetching requests for customer: ${customerId}`);
        
        try {
            map<string[]> queryParams = req.getQueryParams();
            [int page, int limit] = response:extractPaginationParams(queryParams);
            int offset = (page - 1) * limit;
            
            // Get total count
            sql:ParameterizedQuery countQuery = `
                SELECT COUNT(*) as total FROM collection_requests WHERE customer_id = ${customerId}`;
            
            stream<record {}, error?> countStream = check db:queryDatabase(countQuery);
            record {}|error? countRecord = countStream.next();
            check countStream.close();
            
            int total = 0;
            if countRecord is record {} {
                total = <int>countRecord["total"];
            }
            
            // Get requests with pagination
            sql:ParameterizedQuery requestsQuery = `
                SELECT cr.*, u.full_name as collector_name
                FROM collection_requests cr
                LEFT JOIN users u ON cr.collector_id = u.id
                WHERE cr.customer_id = ${customerId}
                ORDER BY cr.created_at DESC
                LIMIT ${limit} OFFSET ${offset}`;
            
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
            
            check response:sendPaginatedResponse(caller, "Requests fetched successfully", 
                                              requests.toJson(), page, limit, total);
            
        } catch (error e) {
            log:printError("Failed to fetch customer requests", e);
            check response:sendInternalErrorResponse(caller, "Failed to fetch requests", e);
        }
    }

    # Track collection request
    # Get real-time tracking information for a collection request
    resource function get [int customerId]/requests/[int requestId]/track(http:Caller caller, http:Request req) returns error? {
        log:printInfo(string `Tracking request ${requestId} for customer ${customerId}`);
        
        try {
            // Get request details with collector info
            sql:ParameterizedQuery trackQuery = `
                SELECT cr.*, u.full_name as collector_name, u.phone as collector_phone,
                       cp.current_latitude, cp.current_longitude
                FROM collection_requests cr
                LEFT JOIN users u ON cr.collector_id = u.id
                LEFT JOIN collector_profiles cp ON u.id = cp.user_id
                WHERE cr.id = ${requestId} AND cr.customer_id = ${customerId}`;
            
            stream<record {}, error?> trackStream = check db:queryDatabase(trackQuery);
            record {}|error? trackRecord = trackStream.next();
            check trackStream.close();
            
            if trackRecord is () {
                check response:sendNotFoundResponse(caller, "Collection request not found");
                return;
            }
            
            if trackRecord is record {} {
                // Get latest tracking updates
                sql:ParameterizedQuery updatesQuery = `
                    SELECT * FROM collection_tracking 
                    WHERE request_id = ${requestId} 
                    ORDER BY updated_at DESC LIMIT 10`;
                
                stream<record {}, error?> updatesStream = check db:queryDatabase(updatesQuery);
                json[] trackingUpdates = [];
                
                error? e = updatesStream.forEach(function(record {} update) {
                    trackingUpdates.push(update.toJson());
                });
                check updatesStream.close();
                
                json responseData = {
                    "request": trackRecord.toJson(),
                    "trackingUpdates": trackingUpdates.toJson()
                };
                
                check response:sendSuccessResponse(caller, "Tracking information retrieved", responseData);
            }
            
        } catch (error e) {
            log:printError("Failed to track collection request", e);
            check response:sendInternalErrorResponse(caller, "Failed to get tracking information", e);
        }
    }

    # Submit feedback
    # Customer can provide feedback and rating after collection completion
    resource function post [int customerId]/requests/[int requestId]/feedback(http:Caller caller, http:Request req) returns error? {
        log:printInfo(string `Feedback submission for request ${requestId} by customer ${customerId}`);
        
        json|error payload = req.getJsonPayload();
        if payload is error {
            check response:sendBadRequestResponse(caller, "Invalid JSON payload");
            return;
        }
        
        string[] requiredFields = ["rating"];
        string? validationError = response:validateRequiredFields(payload, requiredFields);
        if validationError is string {
            check response:sendBadRequestResponse(caller, validationError);
            return;
        }
        
        try {
            // Validate rating
            int rating = <int>payload.rating;
            if rating < 1 || rating > 5 {
                check response:sendBadRequestResponse(caller, "Rating must be between 1 and 5");
                return;
            }
            
            // Check if request exists and is completed
            sql:ParameterizedQuery checkQuery = `
                SELECT collector_id FROM collection_requests 
                WHERE id = ${requestId} AND customer_id = ${customerId} AND status = 'completed'`;
            
            stream<record {}, error?> checkStream = check db:queryDatabase(checkQuery);
            record {}|error? requestRecord = checkStream.next();
            check checkStream.close();
            
            if requestRecord is () {
                check response:sendNotFoundResponse(caller, "Completed collection request not found");
                return;
            }
            
            if requestRecord is record {} {
                int collectorId = <int>requestRecord["collector_id"];
                
                // Insert feedback
                sql:ParameterizedQuery feedbackQuery = `
                    INSERT INTO feedback (request_id, customer_id, collector_id, rating, comment)
                    VALUES (${requestId}, ${customerId}, ${collectorId}, ${rating}, ${payload.comment.toString()})`;
                
                sql:ExecutionResult result = check db:executeQuery(feedbackQuery);
                
                // Update collector's rating
                sql:ParameterizedQuery updateRatingQuery = `
                    UPDATE collector_profiles SET 
                    rating = (SELECT AVG(rating) FROM feedback WHERE collector_id = ${collectorId})
                    WHERE user_id = ${collectorId}`;
                
                _ = check db:executeQuery(updateRatingQuery);
                
                check response:sendCreatedResponse(caller, "Feedback submitted successfully", 
                                                 {"feedbackId": result.lastInsertId});
                log:printInfo(string `Feedback submitted for request ${requestId}`);
            }
            
        } catch (error e) {
            log:printError("Failed to submit feedback", e);
            check response:sendInternalErrorResponse(caller, "Failed to submit feedback", e);
        }
    }

    # Get customer dashboard data
    # Retrieve dashboard information including recent requests, statistics
    resource function get [int customerId]/dashboard(http:Caller caller, http:Request req) returns error? {
        log:printInfo(string `Fetching dashboard data for customer: ${customerId}`);
        
        try {
            // Get customer stats
            sql:ParameterizedQuery statsQuery = `
                SELECT 
                    COUNT(*) as total_requests,
                    COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed_requests,
                    COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_requests,
                    COUNT(CASE WHEN status = 'in_progress' THEN 1 END) as active_requests,
                    COALESCE(SUM(CASE WHEN status = 'completed' THEN price END), 0) as total_spent
                FROM collection_requests 
                WHERE customer_id = ${customerId}`;
            
            stream<record {}, error?> statsStream = check db:queryDatabase(statsQuery);
            record {}|error? statsRecord = statsStream.next();
            check statsStream.close();
            
            // Get recent requests (last 5)
            sql:ParameterizedQuery recentQuery = `
                SELECT cr.*, u.full_name as collector_name
                FROM collection_requests cr
                LEFT JOIN users u ON cr.collector_id = u.id
                WHERE cr.customer_id = ${customerId}
                ORDER BY cr.created_at DESC
                LIMIT 5`;
            
            stream<record {}, error?> recentStream = check db:queryDatabase(recentQuery);
            json[] recentRequests = [];
            
            error? e = recentStream.forEach(function(record {} req) {
                recentRequests.push(req.toJson());
            });
            check recentStream.close();
            
            // Get unread notifications
            sql:ParameterizedQuery notificationsQuery = `
                SELECT * FROM notifications 
                WHERE user_id = ${customerId} AND is_read = false 
                ORDER BY created_at DESC LIMIT 10`;
            
            stream<record {}, error?> notificationsStream = check db:queryDatabase(notificationsQuery);
            json[] notifications = [];
            
            error? ne = notificationsStream.forEach(function(record {} notification) {
                notifications.push(notification.toJson());
            });
            check notificationsStream.close();
            
            json dashboardData = {
                "statistics": statsRecord is record {} ? statsRecord.toJson() : {},
                "recentRequests": recentRequests.toJson(),
                "notifications": notifications.toJson()
            };
            
            check response:sendSuccessResponse(caller, "Dashboard data retrieved", dashboardData);
            
        } catch (error e) {
            log:printError("Failed to fetch dashboard data", e);
            check response:sendInternalErrorResponse(caller, "Failed to fetch dashboard data", e);
        }
    }

    # Cancel collection request
    # Customer can cancel pending collection requests
    resource function put [int customerId]/requests/[int requestId]/cancel(http:Caller caller, http:Request req) returns error? {
        log:printInfo(string `Cancelling request ${requestId} for customer ${customerId}`);
        
        try {
            // Check if request can be cancelled
            sql:ParameterizedQuery checkQuery = `
                SELECT status FROM collection_requests 
                WHERE id = ${requestId} AND customer_id = ${customerId}`;
            
            stream<record {}, error?> checkStream = check db:queryDatabase(checkQuery);
            record {}|error? requestRecord = checkStream.next();
            check checkStream.close();
            
            if requestRecord is () {
                check response:sendNotFoundResponse(caller, "Collection request not found");
                return;
            }
            
            if requestRecord is record {} {
                string status = requestRecord["status"].toString();
                
                if status != "pending" && status != "accepted" {
                    check response:sendBadRequestResponse(caller, "Request cannot be cancelled at this stage");
                    return;
                }
                
                // Update request status
                sql:ParameterizedQuery cancelQuery = `
                    UPDATE collection_requests 
                    SET status = 'cancelled' 
                    WHERE id = ${requestId} AND customer_id = ${customerId}`;
                
                sql:ExecutionResult result = check db:executeQuery(cancelQuery);
                
                // Create notification
                sql:ParameterizedQuery notificationQuery = `
                    INSERT INTO notifications (user_id, request_id, title, message, type)
                    VALUES (${customerId}, ${requestId}, 'Request Cancelled', 
                            'Your collection request has been cancelled', 'request_update')`;
                
                _ = check db:executeQuery(notificationQuery);
                
                check response:sendSuccessResponse(caller, "Collection request cancelled successfully");
                log:printInfo(string `Request ${requestId} cancelled by customer ${customerId}`);
            }
            
        } catch (error e) {
            log:printError("Failed to cancel collection request", e);
            check response:sendInternalErrorResponse(caller, "Failed to cancel request", e);
        }
    }
}
