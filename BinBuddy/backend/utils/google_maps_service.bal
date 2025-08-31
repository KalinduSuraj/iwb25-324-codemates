import ballerina/http;
import ballerina/log;
import ballerina/url;

# Google Maps API Integration for BinBuddy
# Provides geocoding, directions, and places functionality

# Google Maps API Configuration
configurable string GOOGLE_GEOCODING_API_KEY = "YOUR_GEOCODING_API_KEY_HERE";
configurable string GOOGLE_DIRECTIONS_API_KEY = "YOUR_DIRECTIONS_API_KEY_HERE";
configurable string GOOGLE_PLACES_API_KEY = "YOUR_PLACES_API_KEY_HERE";

# Google Maps API endpoints
const string GEOCODING_API_URL = "https://maps.googleapis.com/maps/api/geocode/json";
const string DIRECTIONS_API_URL = "https://maps.googleapis.com/maps/api/directions/json";
const string PLACES_API_URL = "https://maps.googleapis.com/maps/api/place/textsearch/json";

# HTTP client for Google Maps APIs
http:Client googleMapsClient = check new("https://maps.googleapis.com");

# Geocoding response types
public type GeocodeResult record {
    string formatted_address;
    record {
        decimal lat;
        decimal lng;
    } geometry_location;
    string place_id;
    string[] types;
};

public type GeocodeResponse record {
    GeocodeResult[] results;
    string status;
    string? error_message;
};

# Directions response types
public type DirectionsLeg record {
    record {
        string text;
        int value;
    } distance;
    record {
        string text;
        int value;
    } duration;
    string start_address;
    string end_address;
};

public type DirectionsRoute record {
    DirectionsLeg[] legs;
    string summary;
    record {
        string text;
        int value;
    } distance;
    record {
        string text;
        int value;
    } duration;
};

public type DirectionsResponse record {
    DirectionsRoute[] routes;
    string status;
    string? error_message;
};

# Places response types
public type PlaceResult record {
    string name;
    string formatted_address;
    record {
        decimal lat;
        decimal lng;
    } geometry_location;
    string place_id;
    decimal? rating;
    string[] types;
};

public type PlacesResponse record {
    PlaceResult[] results;
    string status;
    string? error_message;
};

# Geocode an address to get coordinates
public function geocodeAddress(string address) returns GeocodeResponse|error {
    log:printInfo("Geocoding address: " + address);
    
    // URL encode the address
    string encodedAddress = check url:encode(address, "UTF-8");
    
    // Build the API URL
    string apiUrl = GEOCODING_API_URL + "?address=" + encodedAddress + 
                   "&key=" + GOOGLE_GEOCODING_API_KEY + "&region=LK";
    
    // Make the API call
    http:Response response = check googleMapsClient->get(apiUrl);
    
    if (response.statusCode == 200) {
        json responseBody = check response.getJsonPayload();
        GeocodeResponse geocodeResponse = check responseBody.cloneWithType(GeocodeResponse);
        
        if (geocodeResponse.status == "OK") {
            log:printInfo("Geocoding successful for: " + address);
            return geocodeResponse;
        } else {
            log:printError("Geocoding failed: " + geocodeResponse.status);
            return error("Geocoding failed: " + geocodeResponse.status);
        }
    } else {
        log:printError("Google Maps API error: " + response.statusCode.toString());
        return error("Google Maps API error: " + response.statusCode.toString());
    }
}

# Reverse geocode coordinates to get address
public function reverseGeocode(decimal lat, decimal lng) returns GeocodeResponse|error {
    log:printInfo("Reverse geocoding coordinates: " + lat.toString() + "," + lng.toString());
    
    // Build the API URL
    string apiUrl = GEOCODING_API_URL + "?latlng=" + lat.toString() + "," + lng.toString() + 
                   "&key=" + GOOGLE_GEOCODING_API_KEY + "&region=LK";
    
    // Make the API call
    http:Response response = check googleMapsClient->get(apiUrl);
    
    if (response.statusCode == 200) {
        json responseBody = check response.getJsonPayload();
        GeocodeResponse geocodeResponse = check responseBody.cloneWithType(GeocodeResponse);
        
        if (geocodeResponse.status == "OK") {
            log:printInfo("Reverse geocoding successful");
            return geocodeResponse;
        } else {
            log:printError("Reverse geocoding failed: " + geocodeResponse.status);
            return error("Reverse geocoding failed: " + geocodeResponse.status);
        }
    } else {
        log:printError("Google Maps API error: " + response.statusCode.toString());
        return error("Google Maps API error: " + response.statusCode.toString());
    }
}

# Get directions between two points
public function getDirections(string origin, string destination) returns DirectionsResponse|error {
    log:printInfo("Getting directions from: " + origin + " to: " + destination);
    
    // URL encode addresses
    string encodedOrigin = check url:encode(origin, "UTF-8");
    string encodedDestination = check url:encode(destination, "UTF-8");
    
    // Build the API URL
    string apiUrl = DIRECTIONS_API_URL + "?origin=" + encodedOrigin + 
                   "&destination=" + encodedDestination + 
                   "&key=" + GOOGLE_DIRECTIONS_API_KEY + 
                   "&region=LK&units=metric";
    
    // Make the API call
    http:Response response = check googleMapsClient->get(apiUrl);
    
    if (response.statusCode == 200) {
        json responseBody = check response.getJsonPayload();
        DirectionsResponse directionsResponse = check responseBody.cloneWithType(DirectionsResponse);
        
        if (directionsResponse.status == "OK") {
            log:printInfo("Directions retrieved successfully");
            return directionsResponse;
        } else {
            log:printError("Directions failed: " + directionsResponse.status);
            return error("Directions failed: " + directionsResponse.status);
        }
    } else {
        log:printError("Google Maps API error: " + response.statusCode.toString());
        return error("Google Maps API error: " + response.statusCode.toString());
    }
}

# Search for places near a location
public function searchPlacesNearby(decimal lat, decimal lng, string query, int radius = 5000) returns PlacesResponse|error {
    log:printInfo("Searching places near: " + lat.toString() + "," + lng.toString() + " for: " + query);
    
    // URL encode the query
    string encodedQuery = check url:encode(query, "UTF-8");
    
    // Build the API URL
    string apiUrl = PLACES_API_URL + "?query=" + encodedQuery + 
                   "&location=" + lat.toString() + "," + lng.toString() + 
                   "&radius=" + radius.toString() + 
                   "&key=" + GOOGLE_PLACES_API_KEY + "&region=LK";
    
    // Make the API call
    http:Response response = check googleMapsClient->get(apiUrl);
    
    if (response.statusCode == 200) {
        json responseBody = check response.getJsonPayload();
        PlacesResponse placesResponse = check responseBody.cloneWithType(PlacesResponse);
        
        if (placesResponse.status == "OK") {
            log:printInfo("Places search successful");
            return placesResponse;
        } else {
            log:printError("Places search failed: " + placesResponse.status);
            return error("Places search failed: " + placesResponse.status);
        }
    } else {
        log:printError("Google Maps API error: " + response.statusCode.toString());
        return error("Google Maps API error: " + response.statusCode.toString());
    }
}

# Calculate distance between two coordinates (simplified formula)
public function calculateDistance(decimal lat1, decimal lng1, decimal lat2, decimal lng2) returns decimal {
    // Simplified distance calculation for nearby points (suitable for Galle district)
    decimal latDiff = lat1 - lat2;
    decimal lngDiff = lng1 - lng2;
    
    // Convert to absolute values
    if (latDiff < 0.0d) {
        latDiff = latDiff * -1.0d;
    }
    if (lngDiff < 0.0d) {
        lngDiff = lngDiff * -1.0d;
    }
    
    // Approximate distance calculation (1 degree ≈ 111 km)
    decimal latDistance = latDiff * 111.0d;
    decimal lngDistance = lngDiff * 111.0d;
    
    // Simple Pythagorean approximation for short distances
    decimal distance = (latDistance * latDistance + lngDistance * lngDistance);
    
    // Approximate square root for decimal (simplified)
    decimal i = 1.0d;
    while (i * i < distance) {
        i = i + 0.1d;
    }
    
    return i; // Approximate distance in kilometers
}

# Validate Galle area coordinates
public function isWithinGalleArea(decimal lat, decimal lng) returns boolean {
    // Define Galle district boundaries (approximate)
    decimal GALLE_NORTH = 6.5;
    decimal GALLE_SOUTH = 5.9;
    decimal GALLE_EAST = 80.4;
    decimal GALLE_WEST = 79.8;
    
    return lat >= GALLE_SOUTH && lat <= GALLE_NORTH && 
           lng >= GALLE_WEST && lng <= GALLE_EAST;
}

# Get optimized route for multiple collection points
public function optimizeCollectionRoute(string[] addresses) returns string[]|error {
    log:printInfo("Optimizing route for " + addresses.length().toString() + " collection points");
    
    // For now, return addresses as-is
    // In production, implement route optimization algorithm
    // using Google Maps Directions API with waypoints
    
    return addresses;
}

# Format address for Sri Lankan context
public function formatSriLankanAddress(string address) returns string {
    // Add "Sri Lanka" if not present
    if (!address.toLowerAscii().includes("sri lanka")) {
        return address + ", Sri Lanka";
    }
    return address;
}

# Health check for Google Maps API connectivity
public function checkGoogleMapsHealth() returns boolean {
    log:printInfo("Checking Google Maps API connectivity");
    
    // Test with a simple geocoding request for Galle Fort
    GeocodeResponse|error result = geocodeAddress("Galle Fort, Sri Lanka");
    
    if (result is GeocodeResponse) {
        return result.status == "OK";
    } else {
        log:printError("Google Maps API health check failed");
        return false;
    }
}
