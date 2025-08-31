# 🚀 BinBuddy API Endpoints Documentation

## 📍 Service Overview

BinBuddy now uses a **monolithic architecture** with all services consolidated on a single port for simplified deployment:

- **All Services**: `http://localhost:8084` - Complete BinBuddy API

---

## 🏠 Main Service & System Information (Port 8084)

### System Health & Documentation
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
```

---

## 👤 Customer Service (Port 8084 - /api/customer)

### Authentication
- **POST** `/api/customer/register` - Register new customer
- **POST** `/api/customer/login` - Customer login

### Collection Requests
- **POST** `/api/customer/{customerId}/requests` - Create collection request
- **GET** `/api/customer/{customerId}/requests` - Get customer requests
- **GET** `/api/customer/{customerId}/requests/{requestId}/track` - Track specific request

### Dashboard & Profile  
- **GET** `/api/customer/{customerId}/dashboard` - Customer dashboard

### Sample Requests:
```bash
# Customer registration
curl -X POST http://localhost:8084/api/customer/register \
  -H "Content-Type: application/json" \
  -d '{
    "full_name": "John Doe",
    "email": "john@email.com", 
    "password": "password123",
    "phone": "+94701234567",
    "address": "123 Main St, Galle"
  }'

# Customer login
curl -X POST http://localhost:8084/api/customer/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@email.com",
    "password": "password123"
  }'

# Create collection request
curl -X POST http://localhost:8084/api/customer/123/requests \
  -H "Content-Type: application/json" \
  -d '{
    "request_type": "immediate",
    "pickup_address": "123 Main St, Galle",
    "waste_type": "general",
    "estimated_weight": 5.0,
    "special_instructions": "Ring the bell"
  }'

# Get customer requests
curl http://localhost:8084/api/customer/123/requests

# Track request
curl http://localhost:8084/api/customer/123/requests/456/track

# Customer dashboard
curl http://localhost:8084/api/customer/123/dashboard
```

---

## 🚛 Collector Service (Port 8084 - /api/collector)

### Authentication
- **POST** `/api/collector/register` - Register new collector
- **POST** `/api/collector/login` - Collector login

### Request Management
- **GET** `/api/collector/{collectorId}/requests/available` - Get available requests
- **GET** `/api/collector/{collectorId}/requests/assigned` - Get assigned requests

### Dashboard & Profile
- **GET** `/api/collector/{collectorId}/dashboard` - Collector dashboard

### Sample Requests:
```bash
# Collector registration  
curl -X POST http://localhost:8084/api/collector/register \
  -H "Content-Type: application/json" \
  -d '{
    "full_name": "Collector Name",
    "email": "collector@email.com",
    "password": "password123", 
    "phone": "+94701234567",
    "vehicle_type": "Three Wheeler",
    "vehicle_number": "CAK-1234",
    "license_number": "DL001234567",
    "service_area": "Galle Fort"
  }'

# Collector login
curl -X POST http://localhost:8084/api/collector/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "collector@email.com",
    "password": "password123"
  }'

# Get available requests
curl http://localhost:8084/api/collector/789/requests/available

# Get assigned requests
curl http://localhost:8084/api/collector/789/requests/assigned

# Collector dashboard
curl http://localhost:8084/api/collector/789/dashboard
```

---

## 🔧 Admin Service (Port 8084 - /api/admin)

### Authentication
- **POST** `/api/admin/login` - Admin login

### User Management
- **GET** `/api/admin/users` - Get all users (customers and collectors)

### Request Monitoring
- **GET** `/api/admin/requests` - Get all requests across the system

### Analytics & Reports
- **GET** `/api/admin/dashboard` - Admin dashboard
- **GET** `/api/admin/analytics/{reportType}` - Analytics reports (daily/weekly/monthly)

### Sample Requests:
```bash
# Admin login
curl -X POST http://localhost:8084/api/admin/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@binbuddy.lk",
    "password": "admin123"
  }'

# Admin dashboard
curl http://localhost:8084/api/admin/dashboard

# Get all users
curl http://localhost:8084/api/admin/users

# Get all requests
curl http://localhost:8084/api/admin/requests

# Get analytics
curl http://localhost:8084/api/admin/analytics/daily
curl http://localhost:8084/api/admin/analytics/weekly  
curl http://localhost:8084/api/admin/analytics/monthly
```

---

## 📊 Database Integration

BinBuddy integrates with both MySQL and SQL Server databases:

- **MySQL**: Used for application data and user management
- **SQL Server**: Used for analytics and reporting
- **LocalDB**: `(localdb)\\MSSQLLocalDB` with database `binbuddy_db`

### Database Health Checks:
```bash
# Check MySQL connection
curl http://localhost:8084/health/database

# Check SQL Server connection  
curl http://localhost:8084/health/sqlserver

# Overall system health
curl http://localhost:8084/health
```

---

## 🌍 Geographic Coverage

BinBuddy serves the Galle district with coverage in:
- Galle Fort
- Unawatuna  
- Hikkaduwa
- Bentota
- Koggala
- Ahangama
- Kaluwella
- Thalpe

---

## 🔄 Response Format

All API responses follow this standard format:

```json
{
  "success": true,
  "message": "Operation completed successfully", 
  "data": { /* Response data */ },
  "timestamp": "2025-08-31T15:30:00Z"
}
```

### Error Response:
```json
{
  "success": false,
  "message": "Error description",
  "timestamp": "2025-08-31T15:30:00Z"
}
```

---

## 🚀 Getting Started

1. **Start the Service:**
   ```bash
   cd BinBuddy
   bal run main_service.bal
   ```

2. **Test System Health:**
   ```bash
   curl http://localhost:8084/health
   ```

3. **Explore API Documentation:**
   ```bash
   curl http://localhost:8084/docs
   ```

4. **Access the Web Interface:**
   Open `FrontEnd/index.html` in your browser

---

## 📝 Notes

- All services are now consolidated on port **8084** for simplified deployment
- Session-based authentication is implemented across all endpoints  
- CORS is enabled for frontend integration
- Real database integration with SQL Server LocalDB
- Comprehensive error handling and logging
- Geographic data for Galle district service coverage

---

*Last Updated: August 31, 2025*
*Service Architecture: Monolithic (Single Port 8084)*
