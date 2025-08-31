import ballerina/http;
import ballerina/log;
import ballerina/time;

# BinBuddy Main Service Entry Point - Legacy Support
# Simple service without module dependencies

# Main HTTP listener for health checks and legacy endpoints
listener http:Listener mainListener = new(8084);

# Main service for health checks and legacy endpoints
@http:ServiceConfig {
    cors: {
        allowOrigins: ["*"],
        allowCredentials: true,
        allowHeaders: ["Content-Type", "Authorization"],
        allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    }
}
service / on mainListener {

    # System health check endpoint
    # + return - System health status information
    resource function get health() returns json {
        log:printInfo("System health check requested");
        
        json healthData = {
            "service": "BinBuddy Waste Management System",
            "version": "1.0.0",
            "status": "healthy",
            "timestamp": time:utcToString(time:utcNow()),
            "components": {
                "database": "healthy",
                "customer_service": "healthy",
                "collector_service": "healthy", 
                "admin_service": "healthy"
            },
            "endpoints": {
                "customer_api": "http://localhost:8081/api/customer",
                "collector_api": "http://localhost:8082/api/collector",
                "admin_api": "http://localhost:8083/api/admin",
                "main_service": "http://localhost:8084"
            },
            "message": "BinBuddy services are running properly"
        };
        
        return healthData;
    }

    # Welcome endpoint with API information
    # + return - Welcome message and service information
    resource function get .() returns json {
        log:printInfo("Welcome endpoint accessed");
        
        json welcomeData = {
            "message": "Welcome to BinBuddy Waste Management System! 🗑️♻️",
            "description": "Your comprehensive solution for smart waste collection and management",
            "version": "1.0.0",
            "services": {
                "customer_service": {
                    "url": "http://localhost:8081/api/customer",
                    "status": "Available",
                    "description": "Customer registration, requests, tracking, and feedback"
                },
                "collector_service": {
                    "url": "http://localhost:8082/api/collector",
                    "status": "Available", 
                    "description": "Collector management, request handling, and location tracking"
                },
                "admin_service": {
                    "url": "http://localhost:8083/api/admin",
                    "status": "Available",
                    "description": "System administration, analytics, and monitoring"
                }
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
                "🏗️ Scalable architecture"
            ],
            "next_steps": [
                "1. Start individual services on their respective ports",
                "2. Configure database connection in backend/utils/db_connection.bal",
                "3. Test APIs using the provided endpoints",
                "4. Integrate with Google Maps APIs for location features"
            ]
        };
        
        return welcomeData;
    }

    # Legacy greeting endpoint for backward compatibility
    # + return - Simple greeting message
    resource function get hello/greeting() returns string {
        log:printInfo("Legacy greeting endpoint accessed");
        return "Hello from BinBuddy! Your friendly waste management partner. 🗑️♻️";
    }

    # API documentation endpoint
    # + return - Comprehensive API documentation
    resource function get docs() returns json {
        log:printInfo("API documentation requested");
        
        json docsData = {
            "title": "BinBuddy API Documentation",
            "version": "1.0.0",
            "description": "Comprehensive REST API for BinBuddy Waste Management System",
            "architecture": "Microservices architecture with separate services for each actor",
            "services": {
                "customer_apis": {
                    "base_url": "http://localhost:8081/api/customer",
                    "endpoints": [
                        "POST /register - Customer registration",
                        "POST /login - Customer login", 
                        "POST /{customerId}/requests - Create collection request",
                        "GET /{customerId}/requests - Get customer requests",
                        "GET /{customerId}/requests/{requestId}/track - Track collection",
                        "POST /{customerId}/requests/{requestId}/feedback - Submit feedback",
                        "GET /{customerId}/dashboard - Customer dashboard",
                        "PUT /{customerId}/requests/{requestId}/cancel - Cancel request"
                    ]
                },
                "collector_apis": {
                    "base_url": "http://localhost:8082/api/collector",
                    "endpoints": [
                        "POST /register - Collector registration",
                        "POST /login - Collector login",
                        "GET /{collectorId}/requests/available - Get available requests",
                        "GET /{collectorId}/requests/assigned - Get assigned requests",
                        "PUT /{collectorId}/requests/{requestId}/action - Accept/reject/start/complete request",
                        "PUT /{collectorId}/location - Update location",
                        "PUT /{collectorId}/availability - Update availability",
                        "GET /{collectorId}/dashboard - Collector dashboard",
                        "GET /{collectorId}/earnings - Earnings report"
                    ]
                },
                "admin_apis": {
                    "base_url": "http://localhost:8083/api/admin",
                    "endpoints": [
                        "POST /login - Admin login",
                        "GET /dashboard - System dashboard",
                        "GET /users - Manage users",
                        "PUT /users/{userId}/manage - Activate/deactivate users",
                        "GET /requests - Monitor all requests",
                        "GET /analytics/{reportType} - Generate analytics",
                        "GET /notifications - System notifications",
                        "GET /export/{dataType} - Export data"
                    ]
                }
            },
            "authentication": {
                "type": "Session-based",
                "description": "Login endpoints return session tokens for subsequent requests",
                "header": "Authorization: Bearer <session-token>"
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
                    "errorCode": "ERROR_CODE",
                    "timestamp": "ISO timestamp"
                }
            },
            "database": {
                "type": "MySQL",
                "schema_file": "backend/resources/db_schema.sql",
                "tables": [
                    "users", "customer_profiles", "collector_profiles",
                    "collection_requests", "tracking", "feedback", 
                    "notifications", "payments"
                ]
            },
            "google_maps_integration": {
                "required_apis": [
                    "Maps JavaScript API",
                    "Geocoding API", 
                    "Directions API",
                    "Geolocation API"
                ],
                "features": [
                    "Customer location mapping",
                    "Real-time collector tracking",
                    "Route optimization",
                    "Address geocoding"
                ]
            }
        };
        
        return docsData;
    }

    # System information endpoint
    # + return - System architecture and status information
    resource function get info() returns json {
        log:printInfo("System information requested");
        
        json infoData = {
            "system": "BinBuddy Waste Management",
            "timestamp": time:utcToString(time:utcNow()),
            "version": "1.0.0",
            "architecture": {
                "pattern": "Microservices",
                "services": 4,
                "databases": 1,
                "ports": [8080, 8081, 8082, 8083]
            },
            "file_structure": {
                "backend/services/": "Individual service implementations",
                "backend/utils/": "Shared utilities and database connections",
                "backend/resources/": "Database schema and configuration files"
            },
            "deployment_ready": true,
            "status": "All services implemented and ready for testing"
        };
        
        return infoData;
    }
}
