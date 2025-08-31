# 🚀 BinBuddy API Endpoints Documentation

## 📍 Service Overview

BinBuddy uses a **microservices architecture** with independent services on separate ports:

- **Main Service**: `http://localhost:8084` - System information and health checks
- **Customer Service**: `http://localhost:8081` - Customer operations  
- **Collector Service**: `http://localhost:8082` - Collector operations
- **Admin Service**: `http://localhost:8083` - Admin operations

---

## 🏠 Main Service (Port 8084)

### System Information
- **GET** `/` - Welcome and system overview
- **GET** `/health` - System health check
- **GET** `/health/database` - MySQL database health
- **GET** `/health/sqlserver` - SQL Server database health
- **GET** `/docs` - API documentation
- **GET** `/config` - Configuration information
- **GET** `/hello/greeting` - Legacy greeting endpoint

### Sample Requests:
```bash
# System health
curl http://localhost:8084/health

# API documentation
curl http://localhost:8084/docs

# Welcome message
curl http://localhost:8084/
```

---

## 👥 Customer Service (Port 8081)

### Authentication
- **POST** `/api/customer/register` - Customer registration
- **POST** `/api/customer/login` - Customer login

### Collection Requests
- **POST** `/api/customer/{customerId}/requests` - Create collection request
- **GET** `/api/customer/{customerId}/requests` - Get customer's requests
- **PUT** `/api/customer/{customerId}/requests/{requestId}/cancel` - Cancel request

### Tracking & Feedback
- **GET** `/api/customer/{customerId}/requests/{requestId}/track` - Track collection
- **POST** `/api/customer/{customerId}/requests/{requestId}/feedback` - Submit feedback

### Dashboard
- **GET** `/api/customer/{customerId}/dashboard` - Customer dashboard

### Sample Requests:
```bash
# Register new customer
curl -X POST http://localhost:8081/api/customer/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "password": "password123",
    "full_name": "John Doe",
    "phone": "+94701234567",
    "address": "123 Main St, Colombo",
    "latitude": 6.9271,
    "longitude": 79.8612
  }'

# Create collection request
curl -X POST http://localhost:8081/api/customer/1/requests \
  -H "Content-Type: application/json" \
  -d '{
    "request_type": "immediate",
    "pickup_address": "123 Main St, Colombo",
    "pickup_latitude": 6.9271,
    "pickup_longitude": 79.8612,
    "waste_type": "general",
    "estimated_weight": 5.5,
    "special_instructions": "Ring the bell"
  }'
```

---

## 🚛 Collector Service (Port 8082)

### Authentication
- **POST** `/api/collector/register` - Collector registration
- **POST** `/api/collector/login` - Collector login

### Request Management
- **GET** `/api/collector/{collectorId}/requests/available` - Get available requests
- **GET** `/api/collector/{collectorId}/requests/assigned` - Get assigned requests
- **PUT** `/api/collector/{collectorId}/requests/{requestId}/action` - Accept/reject/start/complete

### Location & Availability
- **PUT** `/api/collector/{collectorId}/location` - Update location
- **PUT** `/api/collector/{collectorId}/availability` - Update availability

### Dashboard & Earnings
- **GET** `/api/collector/{collectorId}/dashboard` - Collector dashboard
- **GET** `/api/collector/{collectorId}/earnings` - Earnings report

### Sample Requests:
```bash
# Register collector
curl -X POST http://localhost:8082/api/collector/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "collector@example.com",
    "password": "password123",
    "full_name": "Sam Collector",
    "phone": "+94771234567",
    "vehicle_type": "Three Wheeler",
    "vehicle_number": "CAB-1234",
    "license_number": "DL001234567",
    "service_area": ["Colombo", "Dehiwala"]
  }'

# Accept collection request
curl -X PUT http://localhost:8082/api/collector/1/requests/5/action \
  -H "Content-Type: application/json" \
  -d '{"action": "accept", "estimated_price": 750.00}'

# Update location
curl -X PUT http://localhost:8082/api/collector/1/location \
  -H "Content-Type: application/json" \
  -d '{
    "latitude": 6.9271,
    "longitude": 79.8612,
    "status_update": "En route to pickup location"
  }'
```

---

## 🔧 Admin Service (Port 8083)

### Authentication
- **POST** `/api/admin/login` - Admin login

### Dashboard & Monitoring
- **GET** `/api/admin/dashboard` - System dashboard
- **GET** `/api/admin/users` - Manage users
- **GET** `/api/admin/requests` - Monitor all requests

### Analytics & Reports
- **GET** `/api/admin/analytics/{reportType}` - Generate analytics
  - `{reportType}`: `daily`, `weekly`, `monthly`
- **GET** `/api/admin/export/{dataType}` - Export data
  - `{dataType}`: `users`, `requests`, `payments`, `feedback`

### User Management
- **PUT** `/api/admin/users/{userId}/status` - Update user status

### Sample Requests:
```bash
# Admin login
curl -X POST http://localhost:8083/api/admin/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@binbuddy.com",
    "password": "admin123"
  }'

# Get daily analytics
curl http://localhost:8083/api/admin/analytics/daily

# Export user data
curl http://localhost:8083/api/admin/export/users
```

---

## 📊 Response Formats

### Success Response
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { /* response data */ },
  "timestamp": "2025-08-31T14:30:00Z"
}
```

### Error Response
```json
{
  "success": false,
  "message": "Error description",
  "timestamp": "2025-08-31T14:30:00Z"
}
```

### Paginated Response
```json
{
  "success": true,
  "message": "Data retrieved",
  "data": [ /* array of items */ ],
  "pagination": {
    "page": 1,
    "limit": 10,
    "total": 100,
    "totalPages": 10,
    "hasNext": true,
    "hasPrev": false
  },
  "timestamp": "2025-08-31T14:30:00Z"
}
```

---

## 🔐 Authentication

### Session-Based Authentication
1. Login via appropriate service endpoint
2. Receive session token in response
3. Include token in subsequent requests:
   ```
   Authorization: Bearer {sessionToken}
   ```

### User Types
- **Customer**: Register/login via Customer Service
- **Collector**: Register/login via Collector Service  
- **Admin**: Login via Admin Service (pre-created accounts)

---

## 🗄️ Database Schema

### Main Tables
- **users** - All user types (customer, collector, admin)
- **customer_profiles** - Customer-specific data
- **collector_profiles** - Collector-specific data
- **collection_requests** - All collection requests
- **collection_tracking** - Real-time location tracking
- **feedback** - Customer feedback and ratings
- **notifications** - System notifications
- **payments** - Payment transactions
- **system_reports** - Admin reports and analytics

---

## 🚀 Quick Start

### Start All Services
```bash
cd "d:\my\ballerina\iwb25-324-codemates\BinBuddy"
bal run
```

### Start Individual Services
```bash
# Customer service only
bal run backend/services/customer_service.bal

# Collector service only
bal run backend/services/collector_service.bal

# Admin service only
bal run backend/services/admin_service.bal
```

### Test Endpoints
```bash
# Test if services are running
curl http://localhost:8084/health
curl http://localhost:8081/api/customer/health
curl http://localhost:8082/api/collector/health
curl http://localhost:8083/api/admin/health
```

---

## 📍 Real-World Test Data

Your database is populated with realistic data for **Galle District, Sri Lanka**:

- **18 Users**: 2 admins, 10 customers, 5 collectors
- **Geographic Coverage**: Galle Fort, Unawatuna, Hikkaduwa, Bentota, Koggala, Ahangama
- **10 Collection Requests**: Various stages (pending, in-progress, completed)
- **Sample Data**: Realistic names, addresses, and scenarios

### Test with Real Data
```bash
# Get sample customer requests
curl http://localhost:8081/api/customer/3/requests

# Get available requests for collectors
curl http://localhost:8082/api/collector/13/requests/available

# View admin dashboard
curl http://localhost:8083/api/admin/dashboard
```

---

## 🎯 Next Steps

1. **Frontend Integration**: Use these APIs with your React/HTML frontend
2. **Mobile App**: Connect mobile applications to these REST endpoints
3. **Google Maps**: Integrate with Google Maps API for real-time tracking
4. **Payment Gateway**: Add payment processing integration
5. **Notifications**: Implement real-time push notifications

Your **BinBuddy API is fully operational and ready for development!** 🚀
