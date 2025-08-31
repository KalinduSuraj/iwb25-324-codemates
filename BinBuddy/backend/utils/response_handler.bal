import ballerina/http;
import ballerina/log;
import ballerina/time;

# Response handler utility for BinBuddy
# Provides standardized response formats and error handling

# Standard API response structure
public type ApiResponse record {|
    # Response status
    boolean success;
    # Response message
    string message;
    # Response data
    json? data;
    # Response timestamp
    string timestamp;
    # Error details (if any)
    string? errorCode;
    # Additional metadata
    record {}? meta;
|};

# Pagination metadata
public type PaginationMeta record {|
    # Current page number
    int page;
    # Items per page
    int pageLimit;
    # Total number of items
    int total;
    # Total number of pages
    int totalPages;
    # Has next page
    boolean hasNext;
    # Has previous page
    boolean hasPrevious;
|};

# Create success response
public function createSuccessResponse(string message, json? data = (), record {}? meta = ()) returns ApiResponse {
    return {
        success: true,
        message: message,
        data: data,
        timestamp: time:utcToString(time:utcNow()),
        errorCode: (),
        meta: meta
    };
}

# Create error response
public function createErrorResponse(string message, string? errorCode = (), json? data = ()) returns ApiResponse {
    return {
        success: false,
        message: message,
        data: data,
        timestamp: time:utcToString(time:utcNow()),
        errorCode: errorCode,
        meta: ()
    };
}

# Create paginated response
public function createPaginatedResponse(
    string message, 
    json data, 
    int page, 
    int pageSize, 
    int total
) returns ApiResponse {
    int totalPages = (total + pageSize - 1) / pageSize; // Ceiling division
    
    PaginationMeta paginationMeta = {
        page: page,
        pageLimit: pageSize,
        total: total,
        totalPages: totalPages,
        hasNext: page < totalPages,
        hasPrevious: page > 1
    };
    
    return {
        success: true,
        message: message,
        data: data,
        timestamp: time:utcToString(time:utcNow()),
        errorCode: (),
        meta: paginationMeta
    };
}

# Send HTTP response with standard format
public function sendResponse(http:Caller caller, int statusCode, ApiResponse response) returns error? {
    http:Response httpResponse = new;
    httpResponse.statusCode = statusCode;
    httpResponse.setJsonPayload(response.toJson());
    httpResponse.setHeader("Content-Type", "application/json");
    
    check caller->respond(httpResponse);
    
    log:printInfo(string `Response sent: ${statusCode} - ${response.message}`);
}

# Send success response (200 OK)
public function sendSuccessResponse(http:Caller caller, string message, json? data = ()) returns error? {
    ApiResponse response = createSuccessResponse(message, data);
    check sendResponse(caller, 200, response);
}

# Send created response (201 Created)
public function sendCreatedResponse(http:Caller caller, string message, json? data = ()) returns error? {
    ApiResponse response = createSuccessResponse(message, data);
    check sendResponse(caller, 201, response);
}

# Send bad request response (400 Bad Request)
public function sendBadRequestResponse(http:Caller caller, string message, json? data = ()) returns error? {
    ApiResponse response = createErrorResponse(message, "BAD_REQUEST", data);
    check sendResponse(caller, 400, response);
}

# Send unauthorized response (401 Unauthorized)
public function sendUnauthorizedResponse(http:Caller caller, string message = "Unauthorized access") returns error? {
    ApiResponse response = createErrorResponse(message, "UNAUTHORIZED");
    check sendResponse(caller, 401, response);
}

# Send forbidden response (403 Forbidden)
public function sendForbiddenResponse(http:Caller caller, string message = "Access forbidden") returns error? {
    ApiResponse response = createErrorResponse(message, "FORBIDDEN");
    check sendResponse(caller, 403, response);
}

# Send not found response (404 Not Found)
public function sendNotFoundResponse(http:Caller caller, string message = "Resource not found") returns error? {
    ApiResponse response = createErrorResponse(message, "NOT_FOUND");
    check sendResponse(caller, 404, response);
}

# Send internal server error response (500 Internal Server Error)
public function sendInternalErrorResponse(http:Caller caller, string message = "Internal server error", error? err = ()) returns error? {
    if err is error {
        log:printError("Internal server error", err);
    }
    
    ApiResponse response = createErrorResponse(message, "INTERNAL_ERROR");
    check sendResponse(caller, 500, response);
}

# Send paginated response
public function sendPaginatedResponse(
    http:Caller caller, 
    string message, 
    json data, 
    int page, 
    int pageSize, 
    int total
) returns error? {
    ApiResponse response = createPaginatedResponse(message, data, page, pageSize, total);
    check sendResponse(caller, 200, response);
}

# Validate required fields in JSON payload
public function validateRequiredFields(json payload, string[] requiredFields) returns string? {
    map<json> payloadMap = <map<json>>payload;
    foreach string fieldName in requiredFields {
        if !payloadMap.hasKey(fieldName) || payloadMap[fieldName] is () {
            return string `Missing required field: ${fieldName}`;
        }
    }
    return ();
}

# Extract pagination parameters from query params
public function extractPaginationParams(map<string[]> queryParams) returns [int, int] {
    int page = 1;
    int pageSize = 10;
    
    if queryParams.hasKey("page") {
        string[]? pageArray = queryParams["page"];
        if pageArray is string[] && pageArray.length() > 0 {
            int|error pageNum = int:fromString(pageArray[0]);
            if pageNum is int && pageNum > 0 {
                page = pageNum;
            }
        }
    }
    
    if queryParams.hasKey("limit") {
        string[]? limitArray = queryParams["limit"];
        if limitArray is string[] && limitArray.length() > 0 {
            int|error limitNum = int:fromString(limitArray[0]);
            if limitNum is int && limitNum > 0 && limitNum <= 100 {
                pageSize = limitNum;
            }
        }
    }
    
    return [page, pageSize];
}
