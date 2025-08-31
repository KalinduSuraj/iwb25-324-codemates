import ballerina/http;
import ballerina/log;
import ballerina/time;
import ballerina/uuid;

# Collector service HTTP listener
listener http:Listener collectorListener = new(8082);

# Collector Service for BinBuddy
# Handles all collector-related operations including registration, request management, and tracking

# Simple response helper functions
# + caller - HTTP caller object
# + message - Success message
# + data - Response data (optional)
# + return - Error if response sending fails
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

function sendInternalErrorResponse(http:Caller caller, string message) returns error? {
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

# Collector data types
public type CollectorProfile record {|
    # Collector ID
    int id?;
    # User ID reference
    int userId?;
    # Full name
    string fullName;
    # Email address
    string email;
    # Phone number
    string? phone;
    # Vehicle information
    string? vehicleType;
    # Vehicle registration number
    string? vehicleNumber;
    # License information
    string? licenseNumber;
    # Service areas (JSON array)
    string? serviceArea;
    # Current location
    decimal? currentLatitude;
    # Current longitude coordinate
    decimal? currentLongitude;
    # Availability status
    boolean isAvailable;
    # Performance metrics
    decimal rating;
    # Total number of completed collections
    int totalCollections;
    # Profile image
    string? profileImage;
    # Account status
    boolean isActive;
    # Creation timestamp
    string? createdAt?;
|};

public type CollectorRegistration record {|
    # Personal details
    string fullName;
    string email;
    string password;
    string? phone?;
    # Vehicle details
    string vehicleType;
    string vehicleNumber;
    string licenseNumber;
    # Service areas
    string[] serviceAreas;
    # Profile image
    string? profileImage?;
|};

public type LocationUpdate record {|
    # Current latitude
    decimal latitude;
    # Current longitude
    decimal longitude;
    # Optional status message
    string? statusMessage?;
|};

public type RequestAction record {|
    # Action type: accept, reject, start, complete
    string action;
    # Optional message
    string? message?;
    # Location update (for start/complete actions)
    decimal? latitude?;
    decimal? longitude?;
|};

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

    # Collector registration
    # + caller - HTTP caller object
    # + req - HTTP request object  
    # + return - Error if registration fails
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
        
        map<json> payloadMap = <map<json>>payload;
        json responseData = {
            "message": "Collector registration received",
            "email": payloadMap["email"],
            "fullName": payloadMap["fullName"],
            "status": "Registration endpoint is ready - connect to database for full functionality"
        };
        
        check sendCreatedResponse(caller, "Collector registration endpoint working", responseData);
        log:printInfo("Collector registration processed");
    }

    # Collector login
    # + caller - HTTP caller object
    # + req - HTTP request object
    # + return - Error if login fails
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
        
        // Generate session token
        string sessionToken = uuid:createType1AsString();
        
        map<json> payloadMap = <map<json>>payload;
        json responseData = {
            "collectorId": 1,
            "email": payloadMap["email"],
            "fullName": "Test Collector",
            "sessionToken": sessionToken,
            "status": "Login endpoint is ready - connect to database for authentication"
        };
        
        check sendSuccessResponse(caller, "Login endpoint working", responseData);
        log:printInfo("Collector login processed");
    }

    # Get available collection requests
    # + collectorId - Collector ID
    # + caller - HTTP caller object
    # + req - HTTP request object
    # + return - Error if request fails
    resource function get [int collectorId]/requests/available(http:Caller caller, http:Request req) returns error? {
        log:printInfo(string `Fetching available requests for collector: ${collectorId}`);
        
        json[] sampleRequests = [
            {
                "id": 1,
                "customer_name": "John Doe",
                "customer_phone": "+1234567890",
                "customer_address": "123 Main St, City",
                "waste_type": "household",
                "pickup_date": "2025-09-01",
                "status": "pending",
                "price": 25.00
            },
            {
                "id": 2,
                "customer_name": "Jane Smith", 
                "customer_phone": "+1234567891",
                "customer_address": "456 Oak Ave, City",
                "waste_type": "recyclable",
                "pickup_date": "2025-09-02", 
                "status": "pending",
                "price": 30.00
            }
        ];
        
        json responseData = {
            "requests": sampleRequests,
            "total": 2,
            "page": 1,
            "status": "Available requests endpoint is ready - connect to database for real data"
        };
        
        check sendSuccessResponse(caller, "Available requests retrieved", responseData);
    }

    # Get collector's assigned requests
    # + collectorId - Collector ID
    # + caller - HTTP caller object
    # + req - HTTP request object
    # + return - Error if request fails
    resource function get [int collectorId]/requests/assigned(http:Caller caller, http:Request req) returns error? {
        log:printInfo(string `Fetching assigned requests for collector: ${collectorId}`);
        
        json[] sampleRequests = [
            {
                "id": 3,
                "customer_name": "Bob Johnson",
                "customer_phone": "+1234567892",
                "customer_address": "789 Pine St, City",
                "waste_type": "organic",
                "pickup_date": "2025-09-01",
                "status": "accepted",
                "price": 20.00,
                "accepted_at": "2025-08-31T10:00:00Z"
            }
        ];
        
        json responseData = {
            "requests": sampleRequests,
            "total": 1,
            "page": 1,
            "status": "Assigned requests endpoint is ready - connect to database for real data"
        };
        
        check sendSuccessResponse(caller, "Assigned requests retrieved", responseData);
    }

    # Accept or reject collection request
    # + collectorId - Collector ID
    # + requestId - Request ID
    # + caller - HTTP caller object
    # + req - HTTP request object
    # + return - Error if action fails
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
        
        map<json> payloadMap = <map<json>>payload;
        string action = payloadMap["action"].toString();
        
        if action != "accept" && action != "reject" && action != "start" && action != "complete" {
            check sendBadRequestResponse(caller, "Invalid action. Use: accept, reject, start, complete");
            return;
        }
        
        json responseData = {
            "requestId": requestId,
            "collectorId": collectorId,
            "action": action,
            "newStatus": action == "accept" ? "accepted" : action == "start" ? "in_progress" : action == "complete" ? "completed" : "pending",
            "message": string `Request ${action} processed successfully`,
            "status": "Action endpoint is ready - connect to database for real functionality"
        };
        
        check sendSuccessResponse(caller, string `Request ${action} successful`, responseData);
        log:printInfo(string `Request ${requestId} ${action} by collector ${collectorId}`);
    }

    # Update collector location
    # + collectorId - Collector ID
    # + caller - HTTP caller object
    # + req - HTTP request object
    # + return - Error if update fails
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
        
        map<json> payloadMap = <map<json>>payload;
        json responseData = {
            "collectorId": collectorId,
            "latitude": payloadMap["latitude"],
            "longitude": payloadMap["longitude"],
            "timestamp": time:utcToString(time:utcNow()),
            "status": "Location update endpoint is ready - connect to database for real tracking"
        };
        
        check sendSuccessResponse(caller, "Location updated successfully", responseData);
    }

    # Update availability status
    # + collectorId - Collector ID
    # + caller - HTTP caller object
    # + req - HTTP request object
    # + return - Error if update fails
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
        
        map<json> payloadMap = <map<json>>payload;
        boolean isAvailable = <boolean>payloadMap["isAvailable"];
        string statusMessage = isAvailable ? "now available for new requests" : "temporarily unavailable";
        
        json responseData = {
            "collectorId": collectorId,
            "isAvailable": isAvailable,
            "message": string `Collector is ${statusMessage}`,
            "status": "Availability update endpoint is ready - connect to database for real functionality"
        };
        
        check sendSuccessResponse(caller, string `Collector is ${statusMessage}`, responseData);
        log:printInfo(string `Collector ${collectorId} availability: ${isAvailable}`);
    }

    # Get collector dashboard data
    # + collectorId - Collector ID
    # + caller - HTTP caller object
    # + req - HTTP request object
    # + return - Error if fetch fails
    resource function get [int collectorId]/dashboard(http:Caller caller, http:Request req) returns error? {
        log:printInfo(string `Fetching dashboard data for collector: ${collectorId}`);
        
        json dashboardData = {
            "statistics": {
                "total_requests": 5,
                "completed_requests": 3,
                "accepted_requests": 1,
                "active_requests": 1,
                "total_earnings": 75.00,
                "rating": 4.5,
                "total_collections": 3,
                "is_available": true
            },
            "recentRequests": [
                {
                    "id": 3,
                    "customer_name": "Bob Johnson",
                    "customer_address": "789 Pine St, City", 
                    "status": "completed",
                    "completed_at": "2025-08-30T15:30:00Z",
                    "price": 20.00
                }
            ],
            "todayEarnings": {
                "today_earnings": 45.00
            },
            "status": "Dashboard endpoint is ready - connect to database for real data"
        };
        
        check sendSuccessResponse(caller, "Dashboard data retrieved", dashboardData);
    }

    # Get collector earnings report
    # + collectorId - Collector ID
    # + caller - HTTP caller object
    # + req - HTTP request object
    # + return - Error if fetch fails
    resource function get [int collectorId]/earnings(http:Caller caller, http:Request req) returns error? {
        log:printInfo(string `Fetching earnings for collector: ${collectorId}`);
        
        json responseData = {
            "dailyEarnings": [
                {
                    "date": "2025-08-31",
                    "collections_count": 2,
                    "daily_earnings": 45.00
                },
                {
                    "date": "2025-08-30", 
                    "collections_count": 1,
                    "daily_earnings": 20.00
                }
            ],
            "summary": {
                "total_collections": 3,
                "total_earnings": 75.00
            },
            "status": "Earnings endpoint is ready - connect to database for real data"
        };
        
        check sendSuccessResponse(caller, "Earnings data retrieved", responseData);
    }
}
