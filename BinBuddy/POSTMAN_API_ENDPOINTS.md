# BinBuddy API Endpoints for Postman Testing 🚀

## Base URLs
- **Main Service**: `http://localhost:8084`
- **Customer Service**: `http://localhost:8081` (Individual service - needs separate startup)
- **Collector Service**: `http://localhost:8082` (Individual service - needs separate startup)
- **Admin Service**: `http://localhost:8083` (Individual service - needs separate startup)

---

## 📍 Main Service Endpoints (Port 8084) - **CURRENTLY RUNNING**

### 1. System Health Check
```
GET http://localhost:8084/health
```
**Description**: Check overall system health
**Expected Response**: JSON with system status

### 2. Welcome & Service Info
```
GET http://localhost:8084/
```
**Description**: Welcome message and service information
**Expected Response**: JSON with welcome message and API info

### 3. API Documentation
```
GET http://localhost:8084/docs
```
**Description**: Complete API documentation
**Expected Response**: JSON with detailed API documentation

### 4. Legacy Greeting
```
GET http://localhost:8084/hello/greeting
```
**Description**: Simple greeting endpoint for backward compatibility
**Expected Response**: Plain text greeting message

### 5. System Information
```
GET http://localhost:8084/info
```
**Description**: System architecture and deployment information
**Expected Response**: JSON with system details

---

## 👤 Customer Service Endpoints (Port 8081) - **INDIVIDUAL SERVICE**

### 1. Customer Registration
```
POST http://localhost:8081/api/customer/register
Content-Type: application/json

{
    "fullName": "John Doe",
    "email": "john.doe@example.com",
    "password": "securepassword123",
    "phone": "+1234567890",
    "address": "123 Main Street, City, Country"
}
```

### 2. Customer Login
```
POST http://localhost:8081/api/customer/login
Content-Type: application/json

{
    "email": "john.doe@example.com",
    "password": "securepassword123"
}
```

### 3. Create Collection Request
```
POST http://localhost:8081/api/customer/{customerId}/requests
Content-Type: application/json

{
    "wasteType": "organic",
    "quantity": "2 bags",
    "pickupAddress": "123 Main Street",
    "latitude": 40.7128,
    "longitude": -74.0060,
    "preferredTime": "morning",
    "notes": "Please ring doorbell"
}
```

### 4. Get Customer Requests
```
GET http://localhost:8081/api/customer/{customerId}/requests
```

### 5. Track Collection Request
```
GET http://localhost:8081/api/customer/{customerId}/requests/{requestId}/track
```

### 6. Submit Feedback
```
POST http://localhost:8081/api/customer/{customerId}/requests/{requestId}/feedback
Content-Type: application/json

{
    "rating": 5,
    "comment": "Excellent service!",
    "serviceQuality": 5,
    "timeliness": 4
}
```

### 7. Customer Dashboard
```
GET http://localhost:8081/api/customer/{customerId}/dashboard
```

### 8. Cancel Request
```
PUT http://localhost:8081/api/customer/{customerId}/requests/{requestId}/cancel
Content-Type: application/json

{
    "reason": "No longer needed"
}
```

---

## 🚛 Collector Service Endpoints (Port 8082) - **INDIVIDUAL SERVICE**

### 1. Collector Registration
```
POST http://localhost:8082/api/collector/register
Content-Type: application/json

{
    "fullName": "Mike Collector",
    "email": "mike.collector@example.com",
    "password": "securepassword123",
    "phone": "+1234567890",
    "vehicleType": "truck",
    "vehicleNumber": "ABC-1234",
    "licenseNumber": "DL123456789"
}
```

### 2. Collector Login
```
POST http://localhost:8082/api/collector/login
Content-Type: application/json

{
    "email": "mike.collector@example.com",
    "password": "securepassword123"
}
```

### 3. Get Available Requests
```
GET http://localhost:8082/api/collector/{collectorId}/requests/available
```

### 4. Get Assigned Requests
```
GET http://localhost:8082/api/collector/{collectorId}/requests/assigned
```

### 5. Handle Request Actions
```
PUT http://localhost:8082/api/collector/{collectorId}/requests/{requestId}/action
Content-Type: application/json

{
    "action": "accept"
}
```
**Actions**: `accept`, `reject`, `start`, `complete`

### 6. Update Location
```
PUT http://localhost:8082/api/collector/{collectorId}/location
Content-Type: application/json

{
    "latitude": 40.7128,
    "longitude": -74.0060
}
```

### 7. Update Availability
```
PUT http://localhost:8082/api/collector/{collectorId}/availability
Content-Type: application/json

{
    "isAvailable": true
}
```

### 8. Collector Dashboard
```
GET http://localhost:8082/api/collector/{collectorId}/dashboard
```

### 9. Earnings Report
```
GET http://localhost:8082/api/collector/{collectorId}/earnings
```

---

## 👨‍💼 Admin Service Endpoints (Port 8083) - **INDIVIDUAL SERVICE**

### 1. Admin Login
```
POST http://localhost:8083/api/admin/login
Content-Type: application/json

{
    "email": "admin@binbuddy.com",
    "password": "adminpassword123"
}
```

### 2. System Dashboard
```
GET http://localhost:8083/api/admin/dashboard
```

### 3. User Management
```
GET http://localhost:8083/api/admin/users
```

### 4. Manage User Status
```
PUT http://localhost:8083/api/admin/users/{userId}/manage
Content-Type: application/json

{
    "action": "activate"
}
```
**Actions**: `activate`, `deactivate`, `suspend`

### 5. Monitor All Requests
```
GET http://localhost:8083/api/admin/requests
```

### 6. Generate Analytics
```
GET http://localhost:8083/api/admin/analytics/{reportType}
```
**Report Types**: `daily`, `weekly`, `monthly`, `yearly`

### 7. System Notifications
```
GET http://localhost:8083/api/admin/notifications
```

### 8. Export Data
```
GET http://localhost:8083/api/admin/export/{dataType}
```
**Data Types**: `users`, `requests`, `payments`, `analytics`

---

## 🧪 Testing Instructions

### **Currently Available (Port 8084)**
The main service is **RUNNING** and you can test these endpoints immediately:
- ✅ `GET http://localhost:8084/health`
- ✅ `GET http://localhost:8084/`
- ✅ `GET http://localhost:8084/docs`
- ✅ `GET http://localhost:8084/hello/greeting`
- ✅ `GET http://localhost:8084/info`

### **Individual Services (Ports 8081, 8082, 8083)**
To test these endpoints, you need to start each service separately:

```bash
# Terminal 1 - Customer Service
cd "d:\my\ballerina\iwb25-324-codemates\BinBuddy"
bal run backend/services/customer_service.bal

# Terminal 2 - Collector Service  
cd "d:\my\ballerina\iwb25-324-codemates\BinBuddy"
bal run backend/services/collector_service.bal

# Terminal 3 - Admin Service
cd "d:\my\ballerina\iwb25-324-codemates\BinBuddy"
bal run backend/services/admin_service.bal
```

---

## 📝 Postman Collection Setup

### Headers for All Requests:
```
Content-Type: application/json
Authorization: Bearer {session-token}  // After login
```

### Sample Response Format:
```json
{
    "success": true,
    "message": "Operation successful",
    "data": { ... },
    "timestamp": "2025-08-31T11:28:11.693Z"
}
```

### Error Response Format:
```json
{
    "success": false,
    "message": "Error description",
    "errorCode": "ERROR_CODE",
    "timestamp": "2025-08-31T11:28:11.693Z"
}
```

---

## 🔍 Testing Workflow

1. **Start with Main Service** (Already running on 8084)
2. **Test Health and Info endpoints**
3. **Start individual services** as needed
4. **Test Registration/Login flows**
5. **Test functional endpoints** with valid data
6. **Test error scenarios** with invalid data

---

## 🚀 Quick Test Commands

**Test Main Service Health:**
```bash
curl http://localhost:8084/health
```

**Test Welcome Endpoint:**
```bash
curl http://localhost:8084/
```

**Test API Documentation:**
```bash
curl http://localhost:8084/docs
```

All endpoints are ready for testing! The main service (8084) is currently running and responsive. 🎯
