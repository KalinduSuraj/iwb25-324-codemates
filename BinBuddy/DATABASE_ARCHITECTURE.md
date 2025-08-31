# BinBuddy Database Architecture 🗄️

## Database Overview
- **Database Type**: MySQL
- **Schema Name**: `binbuddy_db`
- **Architecture Pattern**: Relational Database with normalized structure
- **Total Tables**: 9 core tables + 1 system table

---

## 📊 Entity Relationship Diagram (ERD)

```
┌─────────────────┐    ┌─────────────────────┐    ┌─────────────────────┐
│     USERS       │    │  CUSTOMER_PROFILES  │    │ COLLECTOR_PROFILES  │
├─────────────────┤    ├─────────────────────┤    ├─────────────────────┤
│ id (PK)         │◄───┤ user_id (FK)        │    │ user_id (FK)        ├───┐
│ email (UNIQUE)  │    │ address             │    │ vehicle_type        │   │
│ password        │    │ latitude            │    │ vehicle_number      │   │
│ user_type       │    │ longitude           │    │ license_number      │   │
│ full_name       │    │ location_pin_name   │    │ service_area        │   │
│ phone           │    │ subscription_type   │    │ current_latitude    │   │
│ profile_image   │    └─────────────────────┘    │ current_longitude   │   │
│ is_active       │                               │ is_available        │   │
│ created_at      │                               │ rating              │   │
│ updated_at      │                               │ total_collections   │   │
└─────────────────┘                               └─────────────────────┘   │
         │                                                  │                │
         │                                                  │                │
         ▼                                                  ▼                │
┌─────────────────────┐                            ┌─────────────────────┐   │
│ COLLECTION_REQUESTS │                            │    FEEDBACK         │   │
├─────────────────────┤                            ├─────────────────────┤   │
│ id (PK)             │                            │ id (PK)             │   │
│ customer_id (FK)    │─────────────────────────┐  │ request_id (FK)     │   │
│ collector_id (FK)   │◄─────────────────────────┼──┤ customer_id (FK)    │   │
│ request_type        │                          │  │ collector_id (FK)   │◄──┘
│ scheduled_date      │                          │  │ rating              │
│ pickup_address      │                          │  │ comment             │
│ pickup_latitude     │                          │  │ created_at          │
│ pickup_longitude    │                          │  └─────────────────────┘
│ waste_type          │                          │
│ estimated_weight    │                          │
│ special_instructions│                          │
│ status              │                          │
│ price               │                          │
│ created_at          │                          │
│ accepted_at         │                          │
│ started_at          │                          │
│ completed_at        │                          │
└─────────────────────┘                          │
         │                                       │
         ▼                                       │
┌─────────────────────┐                          │
│ COLLECTION_TRACKING │                          │
├─────────────────────┤                          │
│ id (PK)             │                          │
│ request_id (FK)     │                          │
│ collector_latitude  │                          │
│ collector_longitude │                          │
│ status_update       │                          │
│ updated_at          │                          │
└─────────────────────┘                          │
                                                 │
┌─────────────────────┐                          │
│     PAYMENTS        │                          │
├─────────────────────┤                          │
│ id (PK)             │                          │
│ request_id (FK)     │◄─────────────────────────┘
│ customer_id (FK)    │
│ amount              │
│ payment_method      │
│ transaction_id      │
│ status              │
│ created_at          │
└─────────────────────┘

┌─────────────────────┐
│   NOTIFICATIONS     │
├─────────────────────┤
│ id (PK)             │
│ user_id (FK)        │
│ request_id (FK)     │
│ title               │
│ message             │
│ type                │
│ is_read             │
│ created_at          │
└─────────────────────┘

┌─────────────────────┐
│  SYSTEM_REPORTS     │
├─────────────────────┤
│ id (PK)             │
│ report_type         │
│ report_data (JSON)  │
│ generated_by (FK)   │
│ created_at          │
└─────────────────────┘
```

---

## 📋 Table Specifications

### 1. **USERS** (Central Authentication)
**Purpose**: Central user management for all user types
```sql
├─ id (INT, PK, AUTO_INCREMENT)
├─ email (VARCHAR(255), UNIQUE, NOT NULL)
├─ password (VARCHAR(255), NOT NULL)
├─ user_type (ENUM: 'customer', 'collector', 'admin')
├─ full_name (VARCHAR(255), NOT NULL)
├─ phone (VARCHAR(20))
├─ profile_image (VARCHAR(500))
├─ is_active (BOOLEAN, DEFAULT TRUE)
├─ created_at (TIMESTAMP, DEFAULT CURRENT_TIMESTAMP)
└─ updated_at (TIMESTAMP, AUTO UPDATE)
```

### 2. **CUSTOMER_PROFILES** (Customer-specific data)
**Purpose**: Extended customer information and preferences
```sql
├─ id (INT, PK, AUTO_INCREMENT)
├─ user_id (INT, FK → users.id, UNIQUE)
├─ address (TEXT, NOT NULL)
├─ latitude (DECIMAL(10,8), NOT NULL)
├─ longitude (DECIMAL(11,8), NOT NULL)
├─ location_pin_name (VARCHAR(255))
└─ subscription_type (ENUM: 'basic', 'premium', DEFAULT 'basic')
```

### 3. **COLLECTOR_PROFILES** (Collector-specific data)
**Purpose**: Collector operational details and status
```sql
├─ id (INT, PK, AUTO_INCREMENT)
├─ user_id (INT, FK → users.id, UNIQUE)
├─ vehicle_type (VARCHAR(100))
├─ vehicle_number (VARCHAR(50))
├─ license_number (VARCHAR(100))
├─ service_area (TEXT) -- JSON array of service areas
├─ current_latitude (DECIMAL(10,8))
├─ current_longitude (DECIMAL(11,8))
├─ is_available (BOOLEAN, DEFAULT TRUE)
├─ rating (DECIMAL(3,2), DEFAULT 0.00)
└─ total_collections (INT, DEFAULT 0)
```

### 4. **COLLECTION_REQUESTS** (Core business entity)
**Purpose**: Waste collection requests and lifecycle management
```sql
├─ id (INT, PK, AUTO_INCREMENT)
├─ customer_id (INT, FK → users.id, NOT NULL)
├─ collector_id (INT, FK → users.id)
├─ request_type (ENUM: 'immediate', 'scheduled')
├─ scheduled_date (DATETIME)
├─ pickup_address (TEXT, NOT NULL)
├─ pickup_latitude (DECIMAL(10,8), NOT NULL)
├─ pickup_longitude (DECIMAL(11,8), NOT NULL)
├─ waste_type (VARCHAR(100))
├─ estimated_weight (DECIMAL(5,2))
├─ special_instructions (TEXT)
├─ status (ENUM: 'pending', 'accepted', 'in_progress', 'completed', 'cancelled')
├─ price (DECIMAL(8,2))
├─ created_at (TIMESTAMP, DEFAULT CURRENT_TIMESTAMP)
├─ accepted_at (TIMESTAMP, NULL)
├─ started_at (TIMESTAMP, NULL)
└─ completed_at (TIMESTAMP, NULL)
```

### 5. **COLLECTION_TRACKING** (Real-time tracking)
**Purpose**: GPS tracking and status updates during collection
```sql
├─ id (INT, PK, AUTO_INCREMENT)
├─ request_id (INT, FK → collection_requests.id, NOT NULL)
├─ collector_latitude (DECIMAL(10,8), NOT NULL)
├─ collector_longitude (DECIMAL(11,8), NOT NULL)
├─ status_update (VARCHAR(255))
└─ updated_at (TIMESTAMP, DEFAULT CURRENT_TIMESTAMP)
```

### 6. **FEEDBACK** (Quality assurance)
**Purpose**: Customer feedback and collector ratings
```sql
├─ id (INT, PK, AUTO_INCREMENT)
├─ request_id (INT, FK → collection_requests.id, NOT NULL)
├─ customer_id (INT, FK → users.id, NOT NULL)
├─ collector_id (INT, FK → users.id, NOT NULL)
├─ rating (INT, CHECK: 1-5, NOT NULL)
├─ comment (TEXT)
└─ created_at (TIMESTAMP, DEFAULT CURRENT_TIMESTAMP)
```

### 7. **NOTIFICATIONS** (Communication system)
**Purpose**: System notifications and alerts
```sql
├─ id (INT, PK, AUTO_INCREMENT)
├─ user_id (INT, FK → users.id, NOT NULL)
├─ request_id (INT, FK → collection_requests.id)
├─ title (VARCHAR(255), NOT NULL)
├─ message (TEXT, NOT NULL)
├─ type (ENUM: 'request_update', 'system', 'promotion')
├─ is_read (BOOLEAN, DEFAULT FALSE)
└─ created_at (TIMESTAMP, DEFAULT CURRENT_TIMESTAMP)
```

### 8. **PAYMENTS** (Financial transactions)
**Purpose**: Payment processing and transaction history
```sql
├─ id (INT, PK, AUTO_INCREMENT)
├─ request_id (INT, FK → collection_requests.id, NOT NULL)
├─ customer_id (INT, FK → users.id, NOT NULL)
├─ amount (DECIMAL(8,2), NOT NULL)
├─ payment_method (ENUM: 'cash', 'card', 'digital_wallet')
├─ transaction_id (VARCHAR(255))
├─ status (ENUM: 'pending', 'completed', 'failed', 'refunded')
└─ created_at (TIMESTAMP, DEFAULT CURRENT_TIMESTAMP)
```

### 9. **SYSTEM_REPORTS** (Analytics and reporting)
**Purpose**: Admin analytics and system reports
```sql
├─ id (INT, PK, AUTO_INCREMENT)
├─ report_type (VARCHAR(100), NOT NULL)
├─ report_data (JSON)
├─ generated_by (INT, FK → users.id)
└─ created_at (TIMESTAMP, DEFAULT CURRENT_TIMESTAMP)
```

---

## 🔗 Relationships and Constraints

### **Primary Foreign Key Relationships**:
1. **customer_profiles.user_id** → **users.id** (1:1)
2. **collector_profiles.user_id** → **users.id** (1:1)
3. **collection_requests.customer_id** → **users.id** (1:Many)
4. **collection_requests.collector_id** → **users.id** (1:Many)
5. **collection_tracking.request_id** → **collection_requests.id** (1:Many)
6. **feedback.request_id** → **collection_requests.id** (1:1)
7. **feedback.customer_id** → **users.id** (1:Many)
8. **feedback.collector_id** → **users.id** (1:Many)
9. **notifications.user_id** → **users.id** (1:Many)
10. **payments.request_id** → **collection_requests.id** (1:1)

### **Cascade Rules**:
- **users** deletion → CASCADE to profiles
- **collection_requests** deletion → CASCADE to tracking
- **users** deletion → SET NULL for optional references

---

## 📈 Performance Optimization

### **Indexes Created**:
```sql
-- Performance indexes
CREATE INDEX idx_collection_requests_customer ON collection_requests(customer_id);
CREATE INDEX idx_collection_requests_collector ON collection_requests(collector_id);
CREATE INDEX idx_collection_requests_status ON collection_requests(status);
CREATE INDEX idx_collection_requests_date ON collection_requests(scheduled_date);
CREATE INDEX idx_feedback_request ON feedback(request_id);
CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_tracking_request ON collection_tracking(request_id);
```

### **Query Optimization Strategy**:
- Customer requests: Indexed by customer_id and status
- Collector assignments: Indexed by collector_id and status
- Real-time tracking: Indexed by request_id
- Notification delivery: Indexed by user_id
- Analytics queries: Optimized with date indexes

---

## 🔐 Security Features

### **Data Protection**:
- **Password Hashing**: All passwords stored as hashed values
- **Email Uniqueness**: Enforced at database level
- **User Type Validation**: ENUM constraints prevent invalid user types
- **Referential Integrity**: Foreign key constraints maintain data consistency

### **Access Control**:
- **Admin Users**: Full system access
- **Customer Users**: Own data access only
- **Collector Users**: Assigned requests and profile access

---

## 📊 Business Intelligence

### **Analytics Capabilities**:
1. **Customer Analytics**: Request patterns, satisfaction scores
2. **Collector Performance**: Completion rates, ratings, earnings
3. **System Metrics**: Request volumes, response times
4. **Financial Reports**: Revenue tracking, payment analytics
5. **Geographic Analysis**: Service area coverage, demand mapping

### **Real-time Data**:
- **Live Tracking**: GPS coordinates with timestamps
- **Status Updates**: Request lifecycle tracking
- **Availability Status**: Collector availability monitoring

---

## 🚀 Scalability Considerations

### **Horizontal Scaling**:
- **Read Replicas**: For analytics and reporting
- **Partitioning**: By geographic regions or date ranges
- **Caching**: Redis for frequently accessed data

### **Data Archival**:
- **Completed Requests**: Archive after 1 year
- **Old Tracking Data**: Compress after 6 months
- **System Reports**: Long-term storage for compliance

---

## 💾 Sample Data Structure

### **Users Table Sample**:
```json
{
  "id": 1,
  "email": "john.doe@example.com",
  "user_type": "customer",
  "full_name": "John Doe",
  "phone": "+1234567890",
  "is_active": true
}
```

### **Collection Request Sample**:
```json
{
  "id": 101,
  "customer_id": 1,
  "collector_id": 5,
  "request_type": "scheduled",
  "pickup_address": "123 Main St, City",
  "waste_type": "organic",
  "status": "in_progress",
  "price": 25.00
}
```

This database architecture supports all the BinBuddy system requirements with proper normalization, indexing, and scalability considerations! 🎯
