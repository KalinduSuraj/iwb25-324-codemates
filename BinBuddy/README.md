# BinBuddy - Waste Management System 🗑️♻️

A comprehensive waste management system built with **Ballerina** that connects customers, collectors, and administrators in a smart waste collection ecosystem.

## 🏗️ System Architecture

BinBuddy follows a **microservices architecture** with separate services for each actor:

### Services Overview
- **Main Service** (Port 8084): Health checks, documentation, and legacy support
- **Customer Service** (Port 8081): Customer registration, requests, tracking, feedback
- **Collector Service** (Port 8082): Collector management, request handling, location tracking  
- **Admin Service** (Port 8083): System administration, analytics, monitoring

### File Structure
```
BinBuddy/
├── service.bal                     # Main service entry point
├── backend/
│   ├── services/
│   │   ├── customer_service.bal    # Customer API endpoints
│   │   ├── collector_service.bal   # Collector API endpoints
│   │   └── admin_service.bal       # Admin API endpoints
│   ├── utils/
│   │   ├── db_connection.bal       # Database utilities
│   │   └── response_handler.bal    # API response utilities
│   └── resources/
│       └── db_schema.sql           # Database schema
├── Ballerina.toml                  # Project configuration
└── README.md                       # This file
```

## 🚀 Getting Started

### Prerequisites
- **Ballerina**: Latest version installed
- **MySQL**: Database server running
- **Java**: For running compiled services

### Running the System

1. **Build the project:**
   ```bash
   bal build
   ```

2. **Start the main service:**
   ```bash
   bal run
   ```
   Main service will be available at: http://localhost:8084

3. **Start individual services** (in separate terminals):
   ```bash
   # Customer Service (Port 8081)
   bal run backend/services/customer_service.bal
   
   # Collector Service (Port 8082)  
   bal run backend/services/collector_service.bal
   
   # Admin Service (Port 8083)
   bal run backend/services/admin_service.bal
   ```

### Testing the Services

**Health Check:**
```bash
curl http://localhost:8084/health
```

**Welcome Message:**
```bash
curl http://localhost:8084/
```

**API Documentation:**
```bash
curl http://localhost:8084/docs
```

**Legacy Greeting:**
```bash
curl http://localhost:8084/hello/greeting
```

## 👥 User Scenarios

### 🛒 Customer Workflow
1. **Register/Login** - Create account and authenticate
2. **Request Collection** - Schedule waste pickup with location
3. **Track Collection** - Real-time tracking of collector
4. **Provide Feedback** - Rate service and provide comments
5. **Dashboard** - View request history and account details

### 🚛 Collector Workflow  
1. **Register/Login** - Create collector profile
2. **View Available Requests** - Browse nearby collection requests
3. **Accept/Reject Requests** - Manage assigned collections
4. **Update Location** - Real-time GPS tracking
5. **Complete Collections** - Update status and earnings
6. **Dashboard** - View statistics and earnings

### 👨‍💼 Admin Workflow
1. **System Login** - Admin authentication
2. **User Management** - Activate/deactivate users
3. **Monitor Requests** - Oversee all collection activities
4. **Analytics** - Generate reports and insights
5. **Notifications** - System-wide announcements
6. **Data Export** - Export system data

## 📊 Database Schema

The system uses **MySQL** with the following tables:
- `users` - User authentication and basic info
- `customer_profiles` - Customer-specific details
- `collector_profiles` - Collector-specific details  
- `collection_requests` - Waste collection requests
- `tracking` - Real-time location tracking
- `feedback` - Customer feedback and ratings
- `notifications` - System notifications
- `payments` - Payment tracking

## 🗺️ Google Maps Integration

Ready for integration with:
- **Maps JavaScript API** - Interactive maps
- **Geocoding API** - Address to coordinates conversion
- **Directions API** - Route optimization
- **Geolocation API** - Real-time location tracking

## 🔗 API Endpoints

### Customer Service (Port 8081)
- `POST /api/customer/register` - Customer registration
- `POST /api/customer/login` - Customer login
- `POST /api/customer/{id}/requests` - Create collection request
- `GET /api/customer/{id}/requests` - Get customer requests
- `GET /api/customer/{id}/requests/{requestId}/track` - Track collection
- `POST /api/customer/{id}/requests/{requestId}/feedback` - Submit feedback
- `GET /api/customer/{id}/dashboard` - Customer dashboard
- `PUT /api/customer/{id}/requests/{requestId}/cancel` - Cancel request

### Collector Service (Port 8082)
- `POST /api/collector/register` - Collector registration
- `POST /api/collector/login` - Collector login
- `GET /api/collector/{id}/requests/available` - Available requests
- `GET /api/collector/{id}/requests/assigned` - Assigned requests
- `PUT /api/collector/{id}/requests/{requestId}/action` - Request actions
- `PUT /api/collector/{id}/location` - Update location
- `PUT /api/collector/{id}/availability` - Update availability
- `GET /api/collector/{id}/dashboard` - Collector dashboard
- `GET /api/collector/{id}/earnings` - Earnings report

### Admin Service (Port 8083)
- `POST /api/admin/login` - Admin login
- `GET /api/admin/dashboard` - System dashboard
- `GET /api/admin/users` - User management
- `PUT /api/admin/users/{userId}/manage` - User actions
- `GET /api/admin/requests` - Monitor requests
- `GET /api/admin/analytics/{reportType}` - Analytics
- `GET /api/admin/notifications` - Notifications
- `GET /api/admin/export/{dataType}` - Data export

## ✅ Features Implemented

- ✅ **Multi-actor system** with Customer, Collector, and Admin roles
- ✅ **RESTful API design** with proper HTTP methods and status codes
- ✅ **Database integration** with MySQL support
- ✅ **CORS configuration** for cross-origin requests
- ✅ **Standardized responses** with success/error handling
- ✅ **Session-based authentication** for all user types
- ✅ **Real-time tracking** capabilities
- ✅ **Comprehensive documentation** with API specs
- ✅ **Scalable architecture** with microservices pattern
- ✅ **Error handling** and validation

## 🔧 Configuration

### Database Configuration
Update `backend/utils/db_connection.bal` with your MySQL credentials:
```ballerina
// Database configuration
configurable string DB_HOST = "localhost";
configurable int DB_PORT = 3306;
configurable string DB_NAME = "binbuddy";
configurable string DB_USER = "your_username";
configurable string DB_PASSWORD = "your_password";
```

### Google Maps API
Add your Google Maps API keys to the frontend configuration for:
- Maps display and interaction
- Address geocoding
- Route optimization
- Real-time tracking

## 🚀 Next Steps

1. **Database Setup**: Import `backend/resources/db_schema.sql` to MySQL
2. **Configuration**: Update database credentials in utilities
3. **Testing**: Test all API endpoints with sample data
4. **Frontend Integration**: Connect with your HTML/CSS frontend
5. **Google Maps**: Integrate Maps APIs for location features
6. **Deployment**: Deploy services to production environment

## 📝 Notes

- All services are **production-ready** with proper error handling
- **CORS** is configured for web frontend integration
- **Session management** is implemented for authentication
- **Database connections** use connection pooling for performance
- **API responses** follow consistent JSON format
- **Documentation** is embedded in service endpoints

## 🎯 Project Status

**✅ COMPLETE** - All backend APIs implemented according to the three-actor requirements!

The BinBuddy waste management system is ready for frontend integration and deployment. All customer, collector, and admin scenarios have been implemented with comprehensive API coverage.
