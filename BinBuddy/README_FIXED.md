# BinBuddy Waste Management System 🗑️♻️

A comprehensive waste collection and management system built with Ballerina, featuring separate microservices for customers, collectors, and administrators.

## 🏗️ Architecture

The system uses a **microservices architecture** with independent services:

- **Customer Service** (Port 8081): Handle customer registration, requests, tracking
- **Collector Service** (Port 8082): Manage collector operations, route optimization  
- **Admin Service** (Port 8083): System administration, analytics, user management
- **Main Service** (Port 8084): API documentation and health checks

## 🚀 Quick Start

### Prerequisites

- Ballerina 2201.10.0 or later
- MySQL 8.0 or later
- Java 21 or later

### 1. Database Setup

```sql
-- Create database
CREATE DATABASE binbuddy_db;

-- Import schema
mysql -u root -p binbuddy_db < backend/resources/db_schema.sql
```

### 2. Configuration

Edit `Config.toml` with your database credentials:

```toml
[binbuddy.database]
host = "localhost"
port = 3306
name = "binbuddy_db"
username = "your_username"
password = "your_password"
```

### 3. Install Dependencies

```bash
cd BinBuddy
bal build
```

### 4. Run Services

#### Option A: Run All Services
```bash
bal run
```

#### Option B: Run Individual Services
```bash
# Customer Service
bal run backend/services/customer_service.bal

# Collector Service  
bal run backend/services/collector_service.bal

# Admin Service
bal run backend/services/admin_service.bal

# Main Service (Documentation)
bal run main_service.bal
```

#### Option C: Use PowerShell Script
```powershell
.\run_services.ps1
```

## 📖 API Documentation

Once services are running, access the API documentation:
- **Main Documentation**: http://localhost:8084/docs
- **System Health**: http://localhost:8084/health

### Service Health Checks
- Customer: http://localhost:8081/api/customer/health
- Collector: http://localhost:8082/api/collector/health  
- Admin: http://localhost:8083/api/admin/health

## 🎯 Use Case Scenarios

### 1. Customer Scenario

**Purpose**: Request and track garbage collection

**Flow**:
1. Register with personal details and location (Google Maps pin)
2. Login to dashboard
3. Request collection ("Collect Now" or schedule)
4. View home location on map
5. Track collector in real-time
6. Receive notifications about collection status
7. Provide feedback after completion

**Key Endpoints**:
```http
POST /api/customer/register
POST /api/customer/login
POST /api/customer/{customerId}/requests
GET /api/customer/{customerId}/requests/{requestId}/track
POST /api/customer/{customerId}/requests/{requestId}/feedback
```

### 2. Collector Scenario

**Purpose**: Manage and complete collection requests

**Flow**:
1. Login to collector dashboard
2. View assigned requests on map
3. Accept/reject requests
4. Navigate using Google Maps directions
5. Update status (In Progress → Completed)
6. Communicate with customers if needed

**Key Endpoints**:
```http
POST /api/collector/login
GET /api/collector/{collectorId}/requests/available
PUT /api/collector/{collectorId}/requests/{requestId}/action
PUT /api/collector/{collectorId}/location
GET /api/collector/{collectorId}/dashboard
```

### 3. Admin Scenario

**Purpose**: System management and monitoring

**Flow**:
1. Login to admin panel
2. Monitor all requests on city map with status colors:
   - 🔴 Red = Pending
   - 🔵 Blue = In Progress  
   - 🟢 Green = Completed
3. Generate reports (daily/weekly/monthly)
4. Manage users (approve/deactivate)
5. View performance analytics and heatmaps

**Key Endpoints**:
```http
POST /api/admin/login
GET /api/admin/dashboard
GET /api/admin/users
GET /api/admin/requests
GET /api/admin/analytics/{reportType}
GET /api/admin/export/{dataType}
```

## 🗺️ Google Maps Integration

The system is ready for Google Maps integration:

### Required APIs
- **Maps JavaScript API**: Display locations and tracking
- **Geocoding API**: Convert addresses to coordinates
- **Directions API**: Route optimization for collectors
- **Places API**: Address suggestions (optional)

### Configuration
Add your API key to `backend/config/google_maps_config.toml`:
```toml
[google_maps]
api_key = "YOUR_API_KEY_HERE"
enabled = true
```

### Features Ready for Maps
- Customer location pinning
- Collector route optimization
- Real-time tracking display
- Address geocoding
- Admin area monitoring with heatmaps

## 🗄️ Database Schema

Complete MySQL schema with tables:
- `users` - All user types (customer, collector, admin)
- `customer_profiles` - Customer-specific data
- `collector_profiles` - Collector-specific data  
- `collection_requests` - All collection requests
- `collection_tracking` - Real-time location updates
- `feedback` - Customer ratings and comments
- `notifications` - System notifications
- `payments` - Payment transactions
- `system_reports` - Analytics data

## 🔐 Authentication

Session-based authentication:
1. Login endpoints return session tokens
2. Include token in subsequent requests:
   ```http
   Authorization: Bearer {sessionToken}
   ```

## 📱 API Response Format

### Success Response
```json
{
  "success": true,
  "message": "Operation successful",
  "data": {...},
  "timestamp": "2025-08-31T10:30:00Z"
}
```

### Error Response  
```json
{
  "success": false,
  "message": "Error description",
  "timestamp": "2025-08-31T10:30:00Z"
}
```

### Paginated Response
```json
{
  "success": true,
  "message": "Data retrieved",
  "data": [...],
  "pagination": {
    "page": 1,
    "limit": 10,
    "total": 100,
    "totalPages": 10,
    "hasNext": true,
    "hasPrev": false
  },
  "timestamp": "2025-08-31T10:30:00Z"
}
```

## 🧪 Testing the APIs

### Example: Customer Registration
```bash
curl -X POST http://localhost:8081/api/customer/register \
  -H "Content-Type: application/json" \
  -d '{
    "fullName": "John Doe",
    "email": "john@example.com", 
    "password": "password123",
    "address": "123 Main St, Galle",
    "latitude": 6.0329,
    "longitude": 80.2168,
    "phone": "+94771234567"
  }'
```

### Example: Create Collection Request
```bash
curl -X POST http://localhost:8081/api/customer/1/requests \
  -H "Content-Type: application/json" \
  -d '{
    "requestType": "immediate",
    "pickupAddress": "123 Main St, Galle",
    "pickupLatitude": 6.0329,
    "pickupLongitude": 80.2168,
    "wasteType": "general",
    "estimatedWeight": 5.0
  }'
```

### Example: Collector Accept Request
```bash
curl -X PUT http://localhost:8082/api/collector/1/requests/1/action \
  -H "Content-Type: application/json" \
  -d '{
    "action": "accept"
  }'
```

## 🏃‍♂️ Development

### Project Structure
```
BinBuddy/
├── backend/
│   ├── services/
│   │   ├── customer_service.bal     # Customer APIs
│   │   ├── collector_service.bal    # Collector APIs
│   │   └── admin_service.bal        # Admin APIs
│   ├── utils/
│   │   ├── db_connection.bal        # Database utilities
│   │   └── response_handler.bal     # Response helpers
│   ├── config/
│   │   └── google_maps_config.toml  # Maps configuration
│   └── resources/
│       └── db_schema.sql            # Database schema
├── main_service.bal                 # Main service entry point
├── Config.toml                      # Configuration file
├── run_services.ps1                 # PowerShell runner script
└── README.md                        # This file
```

### Adding New Features
1. Each service is independent - modify as needed
2. Database changes: Update `db_schema.sql`
3. Add new endpoints following existing patterns
4. Update API documentation in main service

## 🚀 Deployment

### Production Considerations
- Use environment variables for sensitive configuration
- Set up proper database connection pooling
- Implement JWT tokens instead of simple session tokens
- Add rate limiting and request validation
- Set up monitoring and logging
- Use HTTPS in production

### Docker Deployment (Future)
```dockerfile
# Example Dockerfile structure
FROM ballerina/ballerina:2201.10.0
COPY . /app
WORKDIR /app
RUN bal build
EXPOSE 8081 8082 8083 8084
CMD ["bal", "run"]
```

## 🤝 Contributing

1. Each service should remain independent
2. Follow Ballerina best practices
3. Add proper error handling
4. Update documentation for new features
5. Test all endpoints before committing

## 📄 License

This project is licensed under the MIT License.

---

**BinBuddy Team** 🗑️♻️  
*Making waste management smart and efficient!*
