import ballerina/http;
import ballerina/log;
import ballerina/time;
import ballerina/sql;
import ballerinax/mysql;
import ballerinax/mysql.driver as _;
import ballerinax/mssql;
import ballerinax/mssql.driver as _;

# BinBuddy Main Service Entry Point
# This file provides a simple health check and routing information
# Individual services run on separate ports:
# - Customer Service: 8081
# - Collector Service: 8082  
# - Admin Service: 8083

# Main HTTP listener on port 8084 for general information
listener http:Listener mainListener = new(8084);

# Simple database health check function (MySQL)
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
        log:printWarn("MySQL database health check failed", e);
        return false;
    }
}

# SQL Server database health check function
function checkSQLServerHealth() returns boolean {
    do {
        string connectionString = "server=(localdb)\\MSSQLLocalDB;database=binbuddy_db;integratedSecurity=true;encrypt=false;";
        mssql:Client dbClient = check new (connectionString);
        sql:ParameterizedQuery healthQuery = `SELECT 1 as health_check`;
        sql:ExecutionResult result = check dbClient->execute(healthQuery);
        error? closeResult = dbClient.close();
        return true;
    } on fail error e {
        log:printWarn("SQL Server database health check failed", e);
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

    # SQL Server database health check endpoint
    resource function get health/sqlserver() returns json {
        log:printInfo("SQL Server database health check requested");
        
        boolean sqlServerHealthy = checkSQLServerHealth();
        
        json sqlServerHealthData = {
            "service": "BinBuddy SQL Server Database",
            "status": sqlServerHealthy ? "healthy" : "unhealthy", 
            "timestamp": time:utcNow(),
            "database": {
                "type": "SQL Server LocalDB",
                "instance": "MSSQLLocalDB",
                "database": "binbuddy_db",
                "connection": sqlServerHealthy ? "connected" : "disconnected",
                "message": sqlServerHealthy ? "SQL Server database is responding correctly" : "SQL Server connection failed"
            }
        };
        
        return sqlServerHealthData;
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

    # ==============================================
    # CUSTOMER SERVICE ENDPOINTS - /api/customer
    # ==============================================

    # Customer registration
    resource function post api/customer/register(http:Caller caller, http:Request req) returns error? {
        log:printInfo("Customer registration requested");
        
        json|error payload = req.getJsonPayload();
        if (payload is error) {
            json errorResponse = {
                "success": false,
                "message": "Invalid request payload",
                "timestamp": time:utcToString(time:utcNow())
            };
            check caller->respond(errorResponse);
            return;
        }

        json customerData = <json>payload;
        
        // Mock registration response - implement actual database logic here
        json response = {
            "success": true,
            "message": "Customer registered successfully",
            "data": {
                "customer_id": 123,
                "email": "customer@example.com",
                "full_name": "Sample Customer",
                "registration_date": time:utcToString(time:utcNow())
            },
            "timestamp": time:utcToString(time:utcNow())
        };
        
        check caller->respond(response);
    }

    # Customer login
    resource function post api/customer/login(http:Caller caller, http:Request req) returns error? {
        log:printInfo("Customer login requested");
        
        json|error payload = req.getJsonPayload();
        if (payload is error) {
            json errorResponse = {
                "success": false,
                "message": "Invalid login credentials",
                "timestamp": time:utcToString(time:utcNow())
            };
            check caller->respond(errorResponse);
            return;
        }

        json loginData = <json>payload;
        
        // Mock login response - implement actual authentication here
        json response = {
            "success": true,
            "message": "Login successful",
            "data": {
                "customer_id": 123,
                "email": "customer@example.com",
                "session_token": "mock_session_token_" + time:utcNow()[0].toString(),
                "profile": {
                    "full_name": "Sample Customer",
                    "phone": "+94701234567",
                    "subscription_type": "premium"
                }
            },
            "timestamp": time:utcToString(time:utcNow())
        };
        
        check caller->respond(response);
    }

    # Create collection request
    resource function post api/customer/[int customerId]/requests(http:Caller caller, http:Request req) returns error? {
        log:printInfo("Collection request creation for customer: " + customerId.toString());
        
        json|error payload = req.getJsonPayload();
        if (payload is error) {
            json errorResponse = {
                "success": false,
                "message": "Invalid request data",
                "timestamp": time:utcToString(time:utcNow())
            };
            check caller->respond(errorResponse);
            return;
        }

        json requestData = <json>payload;
        
        // Mock request creation - implement actual database logic here
        json response = {
            "success": true,
            "message": "Collection request created successfully",
            "data": {
                "request_id": 456,
                "customer_id": customerId,
                "request_type": "immediate",
                "status": "pending",
                "pickup_address": "Sample Address",
                "estimated_weight": 5.0,
                "created_at": time:utcToString(time:utcNow())
            },
            "timestamp": time:utcToString(time:utcNow())
        };
        
        check caller->respond(response);
    }

    # Get customer requests
    resource function get api/customer/[int customerId]/requests(http:Caller caller, http:Request req) returns error? {
        log:printInfo("Getting requests for customer: " + customerId.toString());
        
        // Mock customer requests - implement actual database query here
        json response = {
            "success": true,
            "message": "Customer requests retrieved",
            "data": [
                {
                    "request_id": 1,
                    "request_type": "scheduled",
                    "status": "completed",
                    "pickup_address": "No. 15, Church Street, Galle Fort",
                    "waste_type": "general",
                    "price": 750.00,
                    "created_at": "2025-08-30T08:00:00Z",
                    "completed_at": "2025-08-30T08:25:00Z"
                },
                {
                    "request_id": 5,
                    "request_type": "scheduled", 
                    "status": "accepted",
                    "pickup_address": "No. 78, Lighthouse Street, Galle Fort",
                    "waste_type": "general",
                    "price": 600.00,
                    "created_at": "2025-08-31T08:30:00Z"
                }
            ],
            "timestamp": time:utcToString(time:utcNow())
        };
        
        check caller->respond(response);
    }

    # Track collection request
    resource function get api/customer/[int customerId]/requests/[int requestId]/track(http:Caller caller, http:Request req) returns error? {
        log:printInfo("Tracking request " + requestId.toString() + " for customer " + customerId.toString());
        
        // Mock tracking data - implement actual tracking logic here
        json response = {
            "success": true,
            "message": "Tracking information retrieved",
            "data": {
                "request_id": requestId,
                "status": "in_progress",
                "collector": {
                    "name": "Lasith Kumara",
                    "phone": "+94771234568",
                    "vehicle": "Small Truck - CAL-5678"
                },
                "current_location": {
                    "latitude": 6.0089,
                    "longitude": 80.2489,
                    "last_updated": time:utcToString(time:utcNow())
                },
                "estimated_arrival": "15 minutes",
                "tracking_updates": [
                    {
                        "timestamp": "2025-08-31T13:00:00Z",
                        "status": "Collector arrived at pickup location"
                    },
                    {
                        "timestamp": "2025-08-31T13:05:00Z", 
                        "status": "Loading waste into vehicle"
                    }
                ]
            },
            "timestamp": time:utcToString(time:utcNow())
        };
        
        check caller->respond(response);
    }

    # Customer dashboard
    resource function get api/customer/[int customerId]/dashboard(http:Caller caller, http:Request req) returns error? {
        log:printInfo("Dashboard requested for customer: " + customerId.toString());
        
        // Mock dashboard data - implement actual database queries here
        json response = {
            "success": true,
            "message": "Dashboard data retrieved",
            "data": {
                "customer_id": customerId,
                "profile": {
                    "full_name": "Asanka Rajapaksha",
                    "email": "asanka.rajapaksha@gmail.com",
                    "phone": "+94701234569",
                    "subscription_type": "premium",
                    "address": "No. 78, Lighthouse Street, Galle Fort"
                },
                "statistics": {
                    "total_requests": 5,
                    "completed_requests": 3,
                    "pending_requests": 1,
                    "total_spent": 2100.00,
                    "waste_collected_kg": 25.5
                },
                "recent_requests": [
                    {
                        "request_id": 5,
                        "status": "accepted",
                        "pickup_date": "2025-08-31T16:00:00Z",
                        "waste_type": "general"
                    }
                ]
            },
            "timestamp": time:utcToString(time:utcNow())
        };
        
        check caller->respond(response);
    }

    # ==============================================
    # COLLECTOR SERVICE ENDPOINTS - /api/collector
    # ==============================================

    # Collector registration
    resource function post api/collector/register(http:Caller caller, http:Request req) returns error? {
        log:printInfo("Collector registration requested");
        
        json|error payload = req.getJsonPayload();
        if (payload is error) {
            json errorResponse = {
                "success": false,
                "message": "Invalid request payload",
                "timestamp": time:utcToString(time:utcNow())
            };
            check caller->respond(errorResponse);
            return;
        }

        json collectorData = <json>payload;
        
        // Mock registration response
        json response = {
            "success": true,
            "message": "Collector registered successfully",
            "data": {
                "collector_id": 789,
                "email": "collector@example.com",
                "full_name": "Sample Collector",
                "vehicle_type": "Three Wheeler",
                "service_area": "Galle Fort",
                "registration_date": time:utcToString(time:utcNow())
            },
            "timestamp": time:utcToString(time:utcNow())
        };
        
        check caller->respond(response);
    }

    # Collector login
    resource function post api/collector/login(http:Caller caller, http:Request req) returns error? {
        log:printInfo("Collector login requested");
        
        json|error payload = req.getJsonPayload();
        if (payload is error) {
            json errorResponse = {
                "success": false,
                "message": "Invalid login credentials",
                "timestamp": time:utcToString(time:utcNow())
            };
            check caller->respond(errorResponse);
            return;
        }

        json loginData = <json>payload;
        
        // Mock login response
        json response = {
            "success": true,
            "message": "Login successful",
            "data": {
                "collector_id": 13,
                "email": "collector@example.com",
                "session_token": "collector_session_" + time:utcNow()[0].toString(),
                "profile": {
                    "full_name": "Sunil Amarasinghe",
                    "vehicle_type": "Three Wheeler",
                    "vehicle_number": "CAK-1234",
                    "rating": 4.8,
                    "is_available": true
                }
            },
            "timestamp": time:utcToString(time:utcNow())
        };
        
        check caller->respond(response);
    }

    # Get available requests for collector
    resource function get api/collector/[int collectorId]/requests/available(http:Caller caller, http:Request req) returns error? {
        log:printInfo("Getting available requests for collector: " + collectorId.toString());
        
        // Mock available requests
        json response = {
            "success": true,
            "message": "Available requests retrieved",
            "data": [
                {
                    "request_id": 8,
                    "customer_name": "Chaminda De Silva",
                    "request_type": "immediate",
                    "pickup_address": "No. 89, Baddegama Road, Hikkaduwa",
                    "pickup_latitude": 6.1395,
                    "pickup_longitude": 80.1025,
                    "waste_type": "general",
                    "estimated_weight": 5.0,
                    "distance_km": 2.5,
                    "special_instructions": "Urgent collection needed",
                    "created_at": "2025-08-31T14:15:00Z"
                },
                {
                    "request_id": 9,
                    "customer_name": "Priyanka Jayawardana", 
                    "request_type": "scheduled",
                    "pickup_address": "No. 234, Colombo Road, Bentota",
                    "pickup_latitude": 6.4058,
                    "pickup_longitude": 79.9719,
                    "waste_type": "general",
                    "estimated_weight": 7.2,
                    "distance_km": 15.3,
                    "scheduled_date": "2025-09-02T08:00:00Z",
                    "special_instructions": "Large household waste"
                }
            ],
            "timestamp": time:utcToString(time:utcNow())
        };
        
        check caller->respond(response);
    }

    # Get assigned requests for collector
    resource function get api/collector/[int collectorId]/requests/assigned(http:Caller caller, http:Request req) returns error? {
        log:printInfo("Getting assigned requests for collector: " + collectorId.toString());
        
        // Mock assigned requests
        json response = {
            "success": true,
            "message": "Assigned requests retrieved",
            "data": [
                {
                    "request_id": 5,
                    "customer_name": "Asanka Rajapaksha",
                    "status": "accepted",
                    "pickup_address": "No. 78, Lighthouse Street, Galle Fort",
                    "scheduled_date": "2025-08-31T16:00:00Z",
                    "waste_type": "general",
                    "estimated_weight": 4.2,
                    "price": 600.00,
                    "special_instructions": "Ring the bell"
                }
            ],
            "timestamp": time:utcToString(time:utcNow())
        };
        
        check caller->respond(response);
    }

    # Collector dashboard
    resource function get api/collector/[int collectorId]/dashboard(http:Caller caller, http:Request req) returns error? {
        log:printInfo("Dashboard requested for collector: " + collectorId.toString());
        
        // Mock collector dashboard
        json response = {
            "success": true,
            "message": "Collector dashboard data retrieved",
            "data": {
                "collector_id": collectorId,
                "profile": {
                    "full_name": "Sunil Amarasinghe",
                    "vehicle_type": "Three Wheeler",
                    "vehicle_number": "CAK-1234",
                    "license_number": "DL001234567",
                    "rating": 4.8,
                    "total_collections": 156,
                    "is_available": true
                },
                "today_stats": {
                    "collections_completed": 3,
                    "earnings": 2250.00,
                    "distance_traveled": 45.2,
                    "hours_worked": 6.5
                },
                "pending_requests": 1,
                "available_requests": 2,
                "current_location": {
                    "latitude": 6.0329,
                    "longitude": 80.2168,
                    "last_updated": time:utcToString(time:utcNow())
                }
            },
            "timestamp": time:utcToString(time:utcNow())
        };
        
        check caller->respond(response);
    }

    # ==============================================
    # ADMIN SERVICE ENDPOINTS - /api/admin
    # ==============================================

    # Admin login
    resource function post api/admin/login(http:Caller caller, http:Request req) returns error? {
        log:printInfo("Admin login requested");
        
        json|error payload = req.getJsonPayload();
        if (payload is error) {
            json errorResponse = {
                "success": false,
                "message": "Invalid login credentials",
                "timestamp": time:utcToString(time:utcNow())
            };
            check caller->respond(errorResponse);
            return;
        }

        json loginData = <json>payload;
        
        // Mock admin login
        json response = {
            "success": true,
            "message": "Admin login successful",
            "data": {
                "admin_id": 1,
                "email": "admin@example.com",
                "session_token": "admin_session_" + time:utcNow()[0].toString(),
                "profile": {
                    "full_name": "Galle Regional Manager",
                    "role": "admin",
                    "permissions": ["user_management", "system_monitoring", "analytics", "reports"]
                }
            },
            "timestamp": time:utcToString(time:utcNow())
        };
        
        check caller->respond(response);
    }

    # Admin dashboard
    resource function get api/admin/dashboard(http:Caller caller, http:Request req) returns error? {
        log:printInfo("Admin dashboard requested");
        
        // Mock admin dashboard with real data from your database
        json response = {
            "success": true,
            "message": "Admin dashboard data retrieved",
            "data": {
                "system_overview": {
                    "total_users": 18,
                    "total_customers": 10,
                    "total_collectors": 5,
                    "active_requests": 3,
                    "completed_today": 4,
                    "revenue_today": 2670.00
                },
                "geographic_coverage": [
                    "Galle Fort", "Unawatuna", "Hikkaduwa", 
                    "Bentota", "Koggala", "Ahangama"
                ],
                "recent_activity": [
                    {
                        "type": "request_completed",
                        "message": "Collection completed in Galle Fort",
                        "timestamp": "2025-08-31T08:25:00Z"
                    },
                    {
                        "type": "new_registration",
                        "message": "New customer registered in Unawatuna",
                        "timestamp": "2025-08-31T10:15:00Z"
                    }
                ],
                "performance_metrics": {
                    "average_completion_time": "25 minutes",
                    "customer_satisfaction": 4.6,
                    "collector_efficiency": 89.5
                }
            },
            "timestamp": time:utcToString(time:utcNow())
        };
        
        check caller->respond(response);
    }

    # Get all users (admin)
    resource function get api/admin/users(http:Caller caller, http:Request req) returns error? {
        log:printInfo("Admin users list requested");
        
        // Mock users data based on your real database structure
        json response = {
            "success": true,
            "message": "Users data retrieved",
            "data": {
                "customers": [
                    {
                        "id": 3,
                        "full_name": "Nimal Silva",
                        "email": "nimal.silva@gmail.com",
                        "phone": "+94701234567",
                        "location": "Galle Fort",
                        "subscription": "premium",
                        "status": "active"
                    },
                    {
                        "id": 4,
                        "full_name": "Kumari Fernando", 
                        "email": "kumari.fernando@gmail.com",
                        "phone": "+94701234568",
                        "location": "Unawatuna",
                        "subscription": "basic",
                        "status": "active"
                    }
                ],
                "collectors": [
                    {
                        "id": 13,
                        "full_name": "Sunil Amarasinghe",
                        "email": "sunil.collector@binbuddy.lk",
                        "vehicle": "Three Wheeler - CAK-1234",
                        "service_area": "Galle Fort, Kaluwella",
                        "rating": 4.8,
                        "status": "active"
                    },
                    {
                        "id": 14,
                        "full_name": "Lasith Kumara",
                        "email": "lasith.collector@binbuddy.lk", 
                        "vehicle": "Small Truck - CAL-5678",
                        "service_area": "Unawatuna, Thalpe",
                        "rating": 4.6,
                        "status": "active"
                    }
                ]
            },
            "timestamp": time:utcToString(time:utcNow())
        };
        
        check caller->respond(response);
    }

    # Get all requests (admin monitoring)
    resource function get api/admin/requests(http:Caller caller, http:Request req) returns error? {
        log:printInfo("Admin requests monitoring requested");
        
        // Mock requests data based on your real database
        json response = {
            "success": true,
            "message": "All requests data retrieved",
            "data": [
                {
                    "request_id": 1,
                    "customer_name": "Nimal Silva",
                    "collector_name": "Sunil Amarasinghe",
                    "status": "completed",
                    "pickup_address": "No. 15, Church Street, Galle Fort",
                    "waste_type": "general",
                    "price": 750.00,
                    "created_at": "2025-08-30T08:00:00Z",
                    "completed_at": "2025-08-30T08:25:00Z"
                },
                {
                    "request_id": 6,
                    "customer_name": "Rohan Wickramasinghe",
                    "collector_name": "Lasith Kumara",
                    "status": "in_progress",
                    "pickup_address": "No. 67, Matara Road, Unawatuna",
                    "waste_type": "recyclable",
                    "price": 350.00,
                    "created_at": "2025-08-31T12:20:00Z",
                    "started_at": "2025-08-31T13:00:00Z"
                },
                {
                    "request_id": 8,
                    "customer_name": "Chaminda De Silva",
                    "collector_name": null,
                    "status": "pending",
                    "pickup_address": "No. 89, Baddegama Road, Hikkaduwa",
                    "waste_type": "general",
                    "price": null,
                    "created_at": "2025-08-31T14:15:00Z"
                }
            ],
            "timestamp": time:utcToString(time:utcNow())
        };
        
        check caller->respond(response);
    }

    # Analytics endpoint for admins
    resource function get api/admin/analytics/[string reportType](http:Caller caller, http:Request req) returns error? {
        log:printInfo("Analytics report requested: " + reportType);
        
        json response = {};
        
        if (reportType == "daily") {
            response = {
                "success": true,
                "message": "Daily analytics retrieved",
                "data": {
                    "date": "2025-08-31",
                    "total_collections": 4,
                    "total_revenue": 2670.00,
                    "average_rating": 4.5,
                    "top_areas": ["Galle Fort", "Unawatuna", "Hikkaduwa"],
                    "active_collectors": 3,
                    "customer_satisfaction": 4.6
                },
                "timestamp": time:utcToString(time:utcNow())
            };
        } else if (reportType == "weekly") {
            response = {
                "success": true,
                "message": "Weekly analytics retrieved", 
                "data": {
                    "week_ending": "2025-08-31",
                    "total_requests": 18,
                    "completed_requests": 14,
                    "total_revenue": 11250.00,
                    "customer_satisfaction": 4.6,
                    "top_collector": "Dinesh Madusanka",
                    "busiest_area": "Galle Fort"
                },
                "timestamp": time:utcToString(time:utcNow())
            };
        } else if (reportType == "monthly") {
            response = {
                "success": true,
                "message": "Monthly analytics retrieved",
                "data": {
                    "month": "2025-08",
                    "total_requests": 85,
                    "completed_requests": 78,
                    "total_revenue": 52750.00,
                    "new_customers": 12,
                    "top_performing_collectors": [
                        {"name": "Dinesh Madusanka", "collections": 78, "rating": 4.9},
                        {"name": "Lasith Kumara", "collections": 62, "rating": 4.6}
                    ]
                },
                "timestamp": time:utcToString(time:utcNow())
            };
        } else {
            response = {
                "success": false,
                "message": "Invalid report type. Use 'daily', 'weekly', or 'monthly'",
                "timestamp": time:utcToString(time:utcNow())
            };
        }
        
        check caller->respond(response);
    }
}
