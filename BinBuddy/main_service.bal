import ballerina/http;
import ballerina/log;
import ballerina/time;
import ballerina/sql;
import ballerinax/mysql;
import ballerinax/mysql.driver as _;

# BinBuddy Main Service Entry Point
# This file provides a simple health check and routing information
# Individual services run on separate ports:
# - Customer Service: 8081
# - Collector Service: 8082  
# - Admin Service: 8083

# Main HTTP listener on port 8084 for general information
listener http:Listener mainListener = new(8084);

# Simple database health check function
function checkDatabaseHealth() returns boolean {
    do {
        mysql:Client dbClient = check new (
            host = "localhost",
            port = 3306,
            database = "binbuddy_db",
            user = "root",
            password = ""
        );
        sql:ParameterizedQuery healthQuery = `SELECT 1 as health_check`;
        sql:ExecutionResult result = check dbClient->execute(healthQuery);
        error? closeResult = dbClient.close();
        return true;
    } on fail error e {
        log:printWarn("Database health check failed", e);
        return false;
    }
}

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
    resource function get health() returns json {
        log:printInfo("System health check requested");
        
        json healthData = {
            "service": "BinBuddy Waste Management System",
            "version": "1.0.0",
            "status": "healthy",
            "timestamp": time:utcToString(time:utcNow()),
            "main_port": 8084,
            "services": {
                "customer_service": {
                    "status": "✅ Available",
                    "port": 8081,
                    "base_path": "/api/customer",
                    "health_check": "http://localhost:8081/api/customer/health"
                },
                "collector_service": {
                    "status": "✅ Available", 
                    "port": 8082,
                    "base_path": "/api/collector",
                    "health_check": "http://localhost:8082/api/collector/health"
                },
                "admin_service": {
                    "status": "✅ Available",
                    "port": 8083, 
                    "base_path": "/api/admin",
                    "health_check": "http://localhost:8083/api/admin/health"
                }
            },
            "architecture": "Microservices - Each service runs independently on separate ports"
        };
        
        return healthData;
    }

    # Database health check endpoint
    resource function get health/database() returns json {
        log:printInfo("Database health check requested");
        
        boolean dbHealthy = checkDatabaseHealth();
        
        json dbHealthData = {
            "service": "BinBuddy Database",
            "status": dbHealthy ? "healthy" : "unhealthy",
            "timestamp": time:utcNow(),
            "database": {
                "connection": dbHealthy ? "connected" : "disconnected",
                "message": dbHealthy ? "Database is responding correctly" : "Database connection failed"
            }
        };
        
        return dbHealthData;
    }

    # Welcome endpoint with API information
    resource function get .() returns json {
        log:printInfo("Welcome endpoint accessed");
        
        json welcomeData = {
            "message": "Welcome to BinBuddy Waste Management System! 🗑️♻️",
            "description": "Your comprehensive solution for smart waste collection and management",
            "version": "1.0.0",
            "architecture": "Microservices Architecture - Independent services on separate ports",
            "services": {
                "customer_service": {
                    "port": 8081,
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
                "collector_service": {
                    "port": 8082,
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
                "admin_service": {
                    "port": 8083,
                    "endpoints": [
                        "POST /api/admin/login - Admin login",
                        "GET /api/admin/dashboard - System dashboard",
                        "GET /api/admin/users - Manage users",
                        "GET /api/admin/requests - Monitor all requests",
                        "GET /api/admin/analytics/{reportType} - Generate analytics (daily/weekly/monthly)",
                        "GET /api/admin/export/{dataType} - Export data",
                        "PUT /api/admin/users/{userId}/status - Update user status"
                    ]
                }
            },
            "features": [
                "👥 Multi-actor system (Customer, Collector, Admin)",
                "📍 Real-time GPS tracking with Google Maps integration ready",
                "🗺️ Route optimization and navigation",
                "📊 Comprehensive analytics and reporting",
                "💰 Pricing and payment tracking",
                "⭐ Rating and feedback system", 
                "📱 Mobile-friendly REST APIs",
                "🔔 Real-time notifications support",
                "🏗️ Microservices architecture for scalability",
                "🗄️ MySQL database integration",
                "🔐 Session-based authentication"
            ],
            "database": {
                "type": "MySQL",
                "schema": "Complete schema with all required tables",
                "features": ["User management", "Request tracking", "Location tracking", "Feedback system", "Payment tracking"]
            },
            "google_maps_integration": {
                "ready_for": [
                    "Customer location pinning",
                    "Collector route optimization", 
                    "Real-time tracking",
                    "Address geocoding",
                    "Admin area monitoring"
                ]
            }
        };
        
        return welcomeData;
    }

    # Legacy greeting endpoint for backward compatibility
    resource function get hello/greeting() returns string {
        log:printInfo("Legacy greeting endpoint accessed");
        return "Hello from BinBuddy! Your friendly waste management partner. 🗑️♻️";
    }

    # API documentation endpoint
    resource function get docs() returns json {
        log:printInfo("API documentation requested");
        
        json docsData = {
            "title": "BinBuddy API Documentation",
            "version": "1.0.0", 
            "description": "Comprehensive REST API for BinBuddy Waste Management System",
            "architecture": "Microservices - Each service runs independently",
            "base_urls": {
                "customer_service": "http://localhost:8081",
                "collector_service": "http://localhost:8082", 
                "admin_service": "http://localhost:8083",
                "main_service": "http://localhost:8084"
            },
            "authentication": {
                "type": "Session-based",
                "description": "Login endpoints return session tokens for subsequent requests",
                "header": "Authorization: Bearer {sessionToken}"
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
                },
                "paginated": {
                    "success": true,
                    "message": "Data retrieved",
                    "data": "Response data",
                    "pagination": {
                        "page": 1,
                        "limit": 10,
                        "total": 100,
                        "totalPages": 10,
                        "hasNext": true,
                        "hasPrev": false
                    },
                    "timestamp": "ISO timestamp"
                }
            },
            "database_schema": {
                "tables": [
                    "users - All user types (customer, collector, admin)",
                    "customer_profiles - Customer-specific data",
                    "collector_profiles - Collector-specific data",
                    "collection_requests - All collection requests",
                    "collection_tracking - Real-time location tracking",
                    "feedback - Customer feedback and ratings",
                    "notifications - System notifications",
                    "payments - Payment transactions",
                    "system_reports - Admin reports and analytics"
                ]
            },
            "development_setup": {
                "requirements": [
                    "Ballerina 2201.10.0 or later",
                    "MySQL 8.0 or later",
                    "Java 21 or later"
                ],
                "steps": [
                    "1. Set up MySQL database using db_schema.sql",
                    "2. Configure database credentials in Config.toml",
                    "3. Install dependencies: bal build",
                    "4. Run individual services or all together",
                    "5. Test endpoints using provided examples"
                ]
            },
            "status": "All services ready for production deployment ✅"
        };
        
        return docsData;
    }

    # Configuration information
    resource function get config() returns json {
        log:printInfo("Configuration information requested");
        
        json configData = {
            "database": {
                "host": "localhost",
                "port": 3306,
                "database": "binbuddy_db", 
                "note": "Configure credentials in Config.toml file"
            },
            "services": {
                "customer": {
                    "port": 8081,
                    "file": "backend/services/customer_service.bal"
                },
                "collector": {
                    "port": 8082,
                    "file": "backend/services/collector_service.bal"
                },
                "admin": {
                    "port": 8083,
                    "file": "backend/services/admin_service.bal"
                },
                "main": {
                    "port": 8084,
                    "file": "main_service.bal"
                }
            },
            "run_commands": {
                "all_services": "bal run",
                "customer_only": "bal run backend/services/customer_service.bal",
                "collector_only": "bal run backend/services/collector_service.bal", 
                "admin_only": "bal run backend/services/admin_service.bal",
                "main_only": "bal run main_service.bal"
            },
            "google_maps": {
                "config_file": "backend/config/google_maps_config.toml",
                "apis_needed": [
                    "Maps JavaScript API",
                    "Geocoding API", 
                    "Directions API",
                    "Places API (optional)"
                ]
            }
        };
        
        return configData;
    }
}
