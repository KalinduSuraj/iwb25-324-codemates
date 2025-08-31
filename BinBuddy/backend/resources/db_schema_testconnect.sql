-- BinBuddy Waste Management Database Schema (SQL Server Version)
-- Created: 2025-08-31
-- Database: SQL Server 2022
-- Using existing database: testconnect

USE testconnect;
GO

-- Drop tables if they exist (in correct order due to foreign keys)
IF OBJECT_ID('system_reports', 'U') IS NOT NULL DROP TABLE system_reports;
IF OBJECT_ID('payments', 'U') IS NOT NULL DROP TABLE payments;
IF OBJECT_ID('notifications', 'U') IS NOT NULL DROP TABLE notifications;
IF OBJECT_ID('feedback', 'U') IS NOT NULL DROP TABLE feedback;
IF OBJECT_ID('collection_tracking', 'U') IS NOT NULL DROP TABLE collection_tracking;
IF OBJECT_ID('collection_requests', 'U') IS NOT NULL DROP TABLE collection_requests;
IF OBJECT_ID('collector_profiles', 'U') IS NOT NULL DROP TABLE collector_profiles;
IF OBJECT_ID('customer_profiles', 'U') IS NOT NULL DROP TABLE customer_profiles;
IF OBJECT_ID('users', 'U') IS NOT NULL DROP TABLE users;

-- Users table (for all user types)
CREATE TABLE users (
    id INT PRIMARY KEY IDENTITY(1,1),
    email NVARCHAR(255) UNIQUE NOT NULL,
    password NVARCHAR(255) NOT NULL,
    user_type NVARCHAR(50) CHECK (user_type IN ('customer', 'collector', 'admin')) NOT NULL,
    full_name NVARCHAR(255) NOT NULL,
    phone NVARCHAR(20),
    profile_image NVARCHAR(500),
    is_active BIT DEFAULT 1,
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE()
);

-- Customer profiles
CREATE TABLE customer_profiles (
    id INT PRIMARY KEY IDENTITY(1,1),
    user_id INT UNIQUE,
    address NTEXT NOT NULL,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    location_pin_name NVARCHAR(255),
    subscription_type NVARCHAR(50) CHECK (subscription_type IN ('basic', 'premium')) DEFAULT 'basic',
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Collector profiles
CREATE TABLE collector_profiles (
    id INT PRIMARY KEY IDENTITY(1,1),
    user_id INT UNIQUE,
    vehicle_type NVARCHAR(100),
    vehicle_number NVARCHAR(50),
    license_number NVARCHAR(100),
    service_area NTEXT, -- JSON array of areas they serve
    current_latitude DECIMAL(10, 8),
    current_longitude DECIMAL(11, 8),
    is_available BIT DEFAULT 1,
    rating DECIMAL(3, 2) DEFAULT 0.00,
    total_collections INT DEFAULT 0,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Collection requests
CREATE TABLE collection_requests (
    id INT PRIMARY KEY IDENTITY(1,1),
    customer_id INT NOT NULL,
    collector_id INT,
    request_type NVARCHAR(50) CHECK (request_type IN ('immediate', 'scheduled')) NOT NULL,
    scheduled_date DATETIME2,
    pickup_address NTEXT NOT NULL,
    pickup_latitude DECIMAL(10, 8) NOT NULL,
    pickup_longitude DECIMAL(11, 8) NOT NULL,
    waste_type NVARCHAR(100), -- e.g., 'general', 'recyclable', 'organic'
    estimated_weight DECIMAL(5, 2),
    special_instructions NTEXT,
    status NVARCHAR(50) CHECK (status IN ('pending', 'accepted', 'in_progress', 'completed', 'cancelled')) DEFAULT 'pending',
    price DECIMAL(8, 2),
    created_at DATETIME2 DEFAULT GETDATE(),
    accepted_at DATETIME2 NULL,
    started_at DATETIME2 NULL,
    completed_at DATETIME2 NULL
);

-- Collection tracking (real-time location updates)
CREATE TABLE collection_tracking (
    id INT PRIMARY KEY IDENTITY(1,1),
    request_id INT NOT NULL,
    collector_latitude DECIMAL(10, 8) NOT NULL,
    collector_longitude DECIMAL(11, 8) NOT NULL,
    status_update NVARCHAR(255),
    updated_at DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (request_id) REFERENCES collection_requests(id) ON DELETE CASCADE
);

-- Feedback and ratings
CREATE TABLE feedback (
    id INT PRIMARY KEY IDENTITY(1,1),
    request_id INT NOT NULL,
    customer_id INT NOT NULL,
    collector_id INT NOT NULL,
    rating INT CHECK (rating >= 1 AND rating <= 5),
    comment NTEXT,
    created_at DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (request_id) REFERENCES collection_requests(id),
    FOREIGN KEY (customer_id) REFERENCES users(id),
    FOREIGN KEY (collector_id) REFERENCES users(id)
);

-- Notifications
CREATE TABLE notifications (
    id INT PRIMARY KEY IDENTITY(1,1),
    user_id INT NOT NULL,
    request_id INT,
    title NVARCHAR(255) NOT NULL,
    message NTEXT NOT NULL,
    type NVARCHAR(50) CHECK (type IN ('request_update', 'system', 'promotion')) NOT NULL,
    is_read BIT DEFAULT 0,
    created_at DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (request_id) REFERENCES collection_requests(id) ON DELETE SET NULL
);

-- Payment transactions
CREATE TABLE payments (
    id INT PRIMARY KEY IDENTITY(1,1),
    request_id INT NOT NULL,
    customer_id INT NOT NULL,
    amount DECIMAL(8, 2) NOT NULL,
    payment_method NVARCHAR(50) CHECK (payment_method IN ('cash', 'card', 'digital_wallet')) NOT NULL,
    transaction_id NVARCHAR(255),
    status NVARCHAR(50) CHECK (status IN ('pending', 'completed', 'failed', 'refunded')) DEFAULT 'pending',
    created_at DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (request_id) REFERENCES collection_requests(id),
    FOREIGN KEY (customer_id) REFERENCES users(id)
);

-- Admin reports and analytics
CREATE TABLE system_reports (
    id INT PRIMARY KEY IDENTITY(1,1),
    report_type NVARCHAR(100) NOT NULL,
    report_data NVARCHAR(MAX), -- JSON data
    generated_by INT,
    created_at DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (generated_by) REFERENCES users(id)
);

-- Indexes for better performance
CREATE INDEX idx_collection_requests_customer ON collection_requests(customer_id);
CREATE INDEX idx_collection_requests_collector ON collection_requests(collector_id);
CREATE INDEX idx_collection_requests_status ON collection_requests(status);
CREATE INDEX idx_collection_requests_date ON collection_requests(scheduled_date);
CREATE INDEX idx_feedback_request ON feedback(request_id);
CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_tracking_request ON collection_tracking(request_id);

-- Insert default admin user
INSERT INTO users (email, password, user_type, full_name, phone) 
VALUES ('admin@binbuddy.com', 'admin123', 'admin', 'System Administrator', '+1234567890');

PRINT 'BinBuddy database schema created successfully in testconnect database!';
GO
