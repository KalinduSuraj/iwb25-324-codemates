import ballerina/http;
import ballerina/log;
import ballerina/time;
import ballerina/uuid;

# BinBuddy Main Service Entry Point - All Services Merged
# Comprehensive service with all customer, collector, and admin functionality

# Main HTTP listener for all services on port 8084
listener http:Listener mainListener = new(8084);

# ====================================
# SHARED UTILITY FUNCTIONS
# ====================================

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

# Placeholder database functions (for now)
function queryDatabase(string query) returns json[] {
    // Placeholder - return empty results
    return [];
}

function executeQuery(string query) returns json {
    // Placeholder - return success
    return {"success": true, "lastInsertId": 1};
}

# Main service for health checks and all API endpoints
@http:ServiceConfig {
    cors: {
        allowOrigins: ["*"],
        allowCredentials: true,
        allowHeaders: ["Content-Type", "Authorization"],
        allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    }
}
service / on mainListener {

    # ====================================
    # SYSTEM HEALTH AND INFO ENDPOINTS
    # ====================================

    # System health check endpoint
    resource function get health() returns json {
        log:printInfo("System health check requested");
        
        json healthData = {
            "service": "BinBuddy Waste Management System",
            "version": "1.0.0",
            "status": "healthy",
            "timestamp": time:utcToString(time:utcNow()),
            "port": 8084,
            "services": {
                "customer_service": "✅ Available at /api/customer",
                "collector_service": "✅ Available at /api/collector",
                "admin_service": "✅ Available at /api/admin"
            },
            "message": "All BinBuddy services running on single port 8084"
        };
        
        return healthData;
    }

    # Welcome endpoint with API information
    resource function get .() returns json {
        log:printInfo("Welcome endpoint accessed");
        
        json welcomeData = {
            "message": "Welcome to BinBuddy Waste Management System! 🗑️♻️",
            "description": "Your comprehensive solution for smart waste collection and management",
            "version": "1.0.0",
            "architecture": "All services merged on port 8084",
            "services": {
                "customer_endpoints": "/api/customer/*",
                "collector_endpoints": "/api/collector/*",
                "admin_endpoints": "/api/admin/*"
            },
            "features": [
                "👥 Multi-actor system (Customer, Collector, Admin)",
                "📍 Real-time GPS tracking",
                "🗺️ Google Maps integration ready",
                "📊 Analytics and reporting",
                "💰 Pricing and payment tracking",
                "⭐ Rating and feedback system",
                "📱 Mobile-friendly APIs",
                "🔔 Real-time notifications",
                "🏗️ Unified architecture on single port"
            ]
        };
        
        return welcomeData;
    }

    # Legacy greeting endpoint for backward compatibility
    resource function get hello/greeting() returns string {
        log:printInfo("Legacy greeting endpoint accessed");
        return "Hello from BinBuddy! Your friendly waste management partner. 🗑️♻️";
    }

    # ====================================
    # CUSTOMER SERVICE ENDPOINTS
    # ====================================

    # Customer registration
    resource function post api/customer/register(http:Caller caller, http:Request req) returns error? {
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
        
        // Extract values safely
        json emailValue = check payload.email;
        json fullNameValue = check payload.fullName;
        
        // Simulate registration success
        json responseData = {
            "customerId": 1,
            "email": emailValue,
            "fullName": fullNameValue,
            "message": "Registration successful! Welcome to BinBuddy!"
        };
        
        check sendCreatedResponse(caller, "Customer registered successfully", responseData);
        log:printInfo(string `Customer registered: ${emailValue.toString()}`);
    }

    # Customer login
    resource function post api/customer/login(http:Caller caller, http:Request req) returns error? {
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
        
        // Extract email safely
        json emailValue = check payload.email;
        
        // Generate session token
        string sessionToken = uuid:createType1AsString();
        
        json responseData = {
            "customerId": 1,
            "email": emailValue,
            "fullName": "John Customer",
            "sessionToken": sessionToken
        };
        
        check sendSuccessResponse(caller, "Login successful", responseData);
        log:printInfo(string `Customer logged in: ${emailValue.toString()}`);
    }

    # Create collection request
    resource function post api/customer/[int customerId]/requests(http:Caller caller, http:Request req) returns error? {
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
        
        json responseData = {
            "requestId": 1,
            "status": "pending",
            "estimatedPrice": 25.00,
            "message": "Collection request created successfully"
        };
        
        check sendCreatedResponse(caller, "Collection request submitted", responseData);
        log:printInfo(string `Collection request created for customer ${customerId}`);
    }

    # Get customer requests
    resource function get api/customer/[int customerId]/requests(http:Caller caller, http:Request req) returns error? {
        log:printInfo(string `Fetching requests for customer: ${customerId}`);
        
        json[] sampleRequests = [
            {
                "id": 1,
                "requestType": "immediate",
                "pickupAddress": "123 Main St, Galle",
                "status": "pending",
                "price": 25.00,
                "createdAt": time:utcToString(time:utcNow())
            }
        ];
        
        check sendSuccessResponse(caller, "Requests fetched successfully", {"requests": sampleRequests});
    }

    # Track collection request
    resource function get api/customer/[int customerId]/requests/[int requestId]/track(http:Caller caller, http:Request req) returns error? {
        log:printInfo(string `Tracking request ${requestId} for customer ${customerId}`);
        
        json trackingData = {
            "request": {
                "id": requestId,
                "status": "in_progress",
                "collectorName": "John Collector",
                "collectorPhone": "+94771234567"
            },
            "trackingUpdates": [
                {
                    "timestamp": time:utcToString(time:utcNow()),
                    "status": "Collector en route",
                    "location": {"lat": 6.0329, "lng": 80.2168}
                }
            ]
        };
        
        check sendSuccessResponse(caller, "Tracking information retrieved", trackingData);
    }

    # Submit feedback
    resource function post api/customer/[int customerId]/requests/[int requestId]/feedback(http:Caller caller, http:Request req) returns error? {
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
        
        check sendCreatedResponse(caller, "Feedback submitted successfully", {"feedbackId": 1});
        log:printInfo(string `Feedback submitted for request ${requestId}`);
    }

    # Customer dashboard
    resource function get api/customer/[int customerId]/dashboard(http:Caller caller, http:Request req) returns error? {
        log:printInfo(string `Fetching dashboard data for customer: ${customerId}`);
        
        json dashboardData = {
            "statistics": {
                "totalRequests": 5,
                "completedRequests": 3,
                "pendingRequests": 1,
                "activeRequests": 1,
                "totalSpent": 75.00
            },
            "recentRequests": [
                {
                    "id": 1,
                    "status": "completed",
                    "completedAt": time:utcToString(time:utcNow()),
                    "price": 25.00
                }
            ]
        };
        
        check sendSuccessResponse(caller, "Dashboard data retrieved", dashboardData);
    }

    # Cancel collection request
    resource function put api/customer/[int customerId]/requests/[int requestId]/cancel(http:Caller caller, http:Request req) returns error? {
        log:printInfo(string `Cancelling request ${requestId} for customer ${customerId}`);
        
        check sendSuccessResponse(caller, "Collection request cancelled successfully");
        log:printInfo(string `Request ${requestId} cancelled by customer ${customerId}`);
    }

    # ====================================
    # COLLECTOR SERVICE ENDPOINTS
    # ====================================

    # Collector registration
    resource function post api/collector/register(http:Caller caller, http:Request req) returns error? {
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
        
        // Extract values safely
        json emailValue = check payload.email;
        json fullNameValue = check payload.fullName;
        
        json responseData = {
            "collectorId": 1,
            "email": emailValue,
            "fullName": fullNameValue,
            "message": "Collector registration successful"
        };
        
        check sendCreatedResponse(caller, "Collector registered successfully", responseData);
        log:printInfo("Collector registration processed");
    }

    # Collector login
    resource function post api/collector/login(http:Caller caller, http:Request req) returns error? {
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
        
        // Extract email safely
        json emailValue = check payload.email;
        string sessionToken = uuid:createType1AsString();
        
        json responseData = {
            "collectorId": 1,
            "email": emailValue,
            "fullName": "John Collector",
            "sessionToken": sessionToken
        };
        
        check sendSuccessResponse(caller, "Login successful", responseData);
        log:printInfo("Collector login processed");
    }

    # Get available collection requests
    resource function get api/collector/[int collectorId]/requests/available(http:Caller caller, http:Request req) returns error? {
        log:printInfo(string `Fetching available requests for collector: ${collectorId}`);
        
        json[] sampleRequests = [
            {
                "id": 1,
                "customerName": "Jane Customer",
                "customerPhone": "+94701234567",
                "customerAddress": "No. 15, Church Street, Galle Fort",
                "wasteType": "general",
                "pickupDate": "2025-09-01",
                "status": "pending",
                "price": 750.00
            },
            {
                "id": 2,
                "customerName": "Bob Customer",
                "customerPhone": "+94701234568",
                "customerAddress": "No. 23, Beach Road, Unawatuna",
                "wasteType": "organic",
                "pickupDate": "2025-09-01",
                "status": "pending",
                "price": 620.00
            }
        ];
        
        json responseData = {
            "requests": sampleRequests,
            "total": 2,
            "page": 1
        };
        
        check sendSuccessResponse(caller, "Available requests retrieved", responseData);
    }

    # Get collector's assigned requests
    resource function get api/collector/[int collectorId]/requests/assigned(http:Caller caller, http:Request req) returns error? {
        log:printInfo(string `Fetching assigned requests for collector: ${collectorId}`);
        
        json[] sampleRequests = [
            {
                "id": 3,
                "customerName": "Alice Customer",
                "customerPhone": "+94701234569",
                "customerAddress": "No. 78, Lighthouse Street, Galle Fort",
                "wasteType": "general",
                "pickupDate": "2025-09-01",
                "status": "accepted",
                "price": 600.00,
                "acceptedAt": time:utcToString(time:utcNow())
            }
        ];
        
        json responseData = {
            "requests": sampleRequests,
            "total": 1,
            "page": 1
        };
        
        check sendSuccessResponse(caller, "Assigned requests retrieved", responseData);
    }

    # Accept or reject collection request
    resource function put api/collector/[int collectorId]/requests/[int requestId]/action(http:Caller caller, http:Request req) returns error? {
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
        
        // Extract action safely
        json actionValue = check payload.action;
        string action = actionValue.toString();
        
        if action != "accept" && action != "reject" && action != "start" && action != "complete" {
            check sendBadRequestResponse(caller, "Invalid action. Use: accept, reject, start, complete");
            return;
        }
        
        json responseData = {
            "requestId": requestId,
            "collectorId": collectorId,
            "action": action,
            "newStatus": action == "accept" ? "accepted" : action == "start" ? "in_progress" : action == "complete" ? "completed" : "pending",
            "message": string `Request ${action} processed successfully`
        };
        
        check sendSuccessResponse(caller, string `Request ${action} successful`, responseData);
        log:printInfo(string `Request ${requestId} ${action} by collector ${collectorId}`);
    }

    # Update collector location
    resource function put api/collector/[int collectorId]/location(http:Caller caller, http:Request req) returns error? {
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
        
        // Extract location safely
        json latValue = check payload.latitude;
        json lngValue = check payload.longitude;
        
        json responseData = {
            "collectorId": collectorId,
            "latitude": latValue,
            "longitude": lngValue,
            "timestamp": time:utcToString(time:utcNow())
        };
        
        check sendSuccessResponse(caller, "Location updated successfully", responseData);
    }

    # Update availability status
    resource function put api/collector/[int collectorId]/availability(http:Caller caller, http:Request req) returns error? {
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
        
        // Extract availability safely
        json availabilityValue = check payload.isAvailable;
        boolean isAvailable = <boolean>availabilityValue;
        string statusMessage = isAvailable ? "now available for new requests" : "temporarily unavailable";
        
        json responseData = {
            "collectorId": collectorId,
            "isAvailable": isAvailable,
            "message": string `Collector is ${statusMessage}`
        };
        
        check sendSuccessResponse(caller, string `Collector is ${statusMessage}`, responseData);
        log:printInfo(string `Collector ${collectorId} availability: ${isAvailable}`);
    }

    # Collector dashboard
    resource function get api/collector/[int collectorId]/dashboard(http:Caller caller, http:Request req) returns error? {
        log:printInfo(string `Fetching dashboard data for collector: ${collectorId}`);
        
        json dashboardData = {
            "statistics": {
                "totalRequests": 15,
                "completedRequests": 12,
                "acceptedRequests": 2,
                "activeRequests": 1,
                "totalEarnings": 9450.00,
                "rating": 4.8,
                "totalCollections": 12,
                "isAvailable": true
            },
            "recentRequests": [
                {
                    "id": 3,
                    "customerName": "Alice Customer",
                    "customerAddress": "No. 78, Lighthouse Street, Galle Fort",
                    "status": "completed",
                    "completedAt": time:utcToString(time:utcNow()),
                    "price": 600.00
                }
            ],
            "todayEarnings": {
                "todayEarnings": 1250.00
            }
        };
        
        check sendSuccessResponse(caller, "Dashboard data retrieved", dashboardData);
    }

    # Collector earnings report
    resource function get api/collector/[int collectorId]/earnings(http:Caller caller, http:Request req) returns error? {
        log:printInfo(string `Fetching earnings for collector: ${collectorId}`);
        
        json responseData = {
            "dailyEarnings": [
                {
                    "date": "2025-08-31",
                    "collectionsCount": 3,
                    "dailyEarnings": 1250.00
                },
                {
                    "date": "2025-08-30",
                    "collectionsCount": 2,
                    "dailyEarnings": 870.00
                }
            ],
            "summary": {
                "totalCollections": 12,
                "totalEarnings": 9450.00,
                "avgEarningsPerCollection": 787.50
            }
        };
        
        check sendSuccessResponse(caller, "Earnings data retrieved", responseData);
    }

    # ====================================
    # ADMIN SERVICE ENDPOINTS
    # ====================================

    # Admin login
    resource function post api/admin/login(http:Caller caller, http:Request req) returns error? {
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
        
        // Extract email safely
        json emailValue = check payload.email;
        string sessionToken = uuid:createType1AsString();
        
        json responseData = {
            "adminId": 1,
            "email": emailValue,
            "fullName": "System Administrator",
            "sessionToken": sessionToken,
            "permissions": ["user_management", "system_monitoring", "analytics", "reports"]
        };
        
        check sendSuccessResponse(caller, "Admin login successful", responseData);
        log:printInfo("Admin login processed");
    }

    # Admin dashboard
    resource function get api/admin/dashboard(http:Caller caller, http:Request req) returns error? {
        log:printInfo("Admin dashboard requested");
        
        json dashboardData = {
            "systemStats": {
                "totalUsers": 25,
                "totalCustomers": 18,
                "totalCollectors": 6,
                "totalRequests": 45,
                "completedRequests": 38,
                "pendingRequests": 4,
                "activeRequests": 3,
                "totalRevenue": 28750.00
            },
            "recentActivity": [
                {
                    "timestamp": time:utcToString(time:utcNow()),
                    "type": "request_completed",
                    "description": "Collection completed in Galle Fort area",
                    "amount": 750.00
                }
            ],
            "topCollectors": [
                {
                    "name": "Sunil Amarasinghe",
                    "rating": 4.8,
                    "totalCollections": 156,
                    "earnings": 8950.00
                }
            ]
        };
        
        check sendSuccessResponse(caller, "Admin dashboard data retrieved", dashboardData);
    }

    # User management
    resource function get api/admin/users(http:Caller caller, http:Request req) returns error? {
        log:printInfo("Admin user management requested");
        
        json[] users = [
            {
                "id": 1,
                "fullName": "Nimal Silva",
                "email": "nimal.silva@gmail.com",
                "userType": "customer",
                "isActive": true,
                "createdAt": "2025-08-25T10:00:00Z"
            },
            {
                "id": 2,
                "fullName": "Sunil Amarasinghe",
                "email": "sunil.collector@binbuddy.lk",
                "userType": "collector",
                "isActive": true,
                "createdAt": "2025-08-20T09:00:00Z"
            }
        ];
        
        check sendSuccessResponse(caller, "Users retrieved", {"users": users, "total": 25});
    }

    # Monitor all requests
    resource function get api/admin/requests(http:Caller caller, http:Request req) returns error? {
        log:printInfo("Admin monitoring all requests");
        
        json[] requests = [
            {
                "id": 1,
                "customerName": "Nimal Silva",
                "collectorName": "Sunil Amarasinghe",
                "pickupAddress": "No. 15, Church Street, Galle Fort",
                "status": "completed",
                "price": 750.00,
                "createdAt": "2025-08-30T08:00:00Z",
                "completedAt": "2025-08-30T08:25:00Z"
            }
        ];
        
        check sendSuccessResponse(caller, "All requests retrieved", {"requests": requests, "total": 45});
    }

    # Generate analytics
    resource function get api/admin/analytics/[string reportType](http:Caller caller, http:Request req) returns error? {
        log:printInfo(string `Admin analytics requested: ${reportType}`);
        
        json analyticsData = {};
        
        if reportType == "daily" {
            analyticsData = {
                "date": "2025-08-31",
                "totalCollections": 8,
                "totalRevenue": 4250.00,
                "avgRating": 4.6,
                "topArea": "Galle Fort",
                "collectorsActive": 5
            };
        } else if reportType == "weekly" {
            analyticsData = {
                "weekEnding": "2025-08-31",
                "totalCollections": 42,
                "totalRevenue": 28750.00,
                "customerSatisfaction": 4.6,
                "topCollector": "Sunil Amarasinghe",
                "busiestArea": "Galle Fort"
            };
        } else if reportType == "monthly" {
            analyticsData = {
                "month": "August 2025",
                "totalCollections": 156,
                "totalRevenue": 124500.00,
                "newCustomers": 8,
                "newCollectors": 2,
                "avgResponseTime": "15 minutes"
            };
        } else {
            check sendBadRequestResponse(caller, "Invalid report type. Use: daily, weekly, monthly");
            return;
        }
        
        check sendSuccessResponse(caller, string `${reportType} analytics retrieved`, analyticsData);
    }

    # Export data
    resource function get api/admin/export/[string dataType](http:Caller caller, http:Request req) returns error? {
        log:printInfo(string `Admin data export requested: ${dataType}`);
        
        json exportData = {
            "exportType": dataType,
            "timestamp": time:utcToString(time:utcNow()),
            "recordCount": 100,
            "downloadUrl": string `https://binbuddy.lk/exports/${dataType}_${time:utcToString(time:utcNow())}.csv`,
            "expiresAt": time:utcToString(time:utcNow())
        };
        
        check sendSuccessResponse(caller, string `${dataType} export prepared`, exportData);
    }

    # ====================================
    # API DOCUMENTATION ENDPOINT
    # ====================================

    # API documentation endpoint
    resource function get docs() returns json {
        log:printInfo("API documentation requested");
        
        json docsData = {
            "title": "BinBuddy API Documentation",
            "version": "1.0.0",
            "description": "Comprehensive REST API for BinBuddy Waste Management System",
            "architecture": "All services unified on port 8084",
            "baseUrl": "http://localhost:8084",
            "customer_apis": {
                "base_path": "/api/customer",
                "endpoints": [
                    "POST /api/customer/register - Customer registration",
                    "POST /api/customer/login - Customer login",
                    "POST /api/customer/{customerId}/requests - Create collection request",
                    "GET /api/customer/{customerId}/requests - Get customer requests",
                    "GET /api/customer/{customerId}/requests/{requestId}/track - Track collection",
                    "POST /api/customer/{customerId}/requests/{requestId}/feedback - Submit feedback",
                    "GET /api/customer/{customerId}/dashboard - Customer dashboard",
                    "PUT /api/customer/{customerId}/requests/{requestId}/cancel - Cancel request"
                ]
            },
            "collector_apis": {
                "base_path": "/api/collector",
                "endpoints": [
                    "POST /api/collector/register - Collector registration",
                    "POST /api/collector/login - Collector login",
                    "GET /api/collector/{collectorId}/requests/available - Get available requests",
                    "GET /api/collector/{collectorId}/requests/assigned - Get assigned requests",
                    "PUT /api/collector/{collectorId}/requests/{requestId}/action - Accept/reject/start/complete request",
                    "PUT /api/collector/{collectorId}/location - Update location",
                    "PUT /api/collector/{collectorId}/availability - Update availability",
                    "GET /api/collector/{collectorId}/dashboard - Collector dashboard",
                    "GET /api/collector/{collectorId}/earnings - Earnings report"
                ]
            },
            "admin_apis": {
                "base_path": "/api/admin",
                "endpoints": [
                    "POST /api/admin/login - Admin login",
                    "GET /api/admin/dashboard - System dashboard",
                    "GET /api/admin/users - Manage users",
                    "GET /api/admin/requests - Monitor all requests",
                    "GET /api/admin/analytics/{reportType} - Generate analytics",
                    "GET /api/admin/export/{dataType} - Export data"
                ]
            },
            "response_format": {
                "success": {
                    "success": true,
                    "message": "Operation successful",
                    "data": "Response data",
                    "timestamp": "ISO timestamp"
                },
                "error": {
                    "success": false,
                    "message": "Error description",
                    "timestamp": "ISO timestamp"
                }
            },
            "authentication": {
                "type": "Session-based",
                "description": "Login endpoints return session tokens for subsequent requests"
            },
            "status": "All services unified on single port 8084 ✅"
        };
        
        return docsData;
    }
}
