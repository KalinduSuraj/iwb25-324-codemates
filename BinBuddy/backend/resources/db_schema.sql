-- BinBuddy Waste Management Database Schema
-- Created: 2025-08-31

-- Users table (for all user types)
CREATE TABLE users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    user_type ENUM('customer', 'collector', 'admin') NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    profile_image VARCHAR(500),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Customer profiles
CREATE TABLE customer_profiles (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT UNIQUE,
    address TEXT NOT NULL,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    location_pin_name VARCHAR(255),
    subscription_type ENUM('basic', 'premium') DEFAULT 'basic',
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Collector profiles
CREATE TABLE collector_profiles (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT UNIQUE,
    vehicle_type VARCHAR(100),
    vehicle_number VARCHAR(50),
    license_number VARCHAR(100),
    service_area TEXT, -- JSON array of areas they serve
    current_latitude DECIMAL(10, 8),
    current_longitude DECIMAL(11, 8),
    is_available BOOLEAN DEFAULT TRUE,
    rating DECIMAL(3, 2) DEFAULT 0.00,
    total_collections INT DEFAULT 0,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Collection requests
CREATE TABLE collection_requests (
    id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    collector_id INT,
    request_type ENUM('immediate', 'scheduled') NOT NULL,
    scheduled_date DATETIME,
    pickup_address TEXT NOT NULL,
    pickup_latitude DECIMAL(10, 8) NOT NULL,
    pickup_longitude DECIMAL(11, 8) NOT NULL,
    waste_type VARCHAR(100), -- e.g., 'general', 'recyclable', 'organic'
    estimated_weight DECIMAL(5, 2),
    special_instructions TEXT,
    status ENUM('pending', 'accepted', 'in_progress', 'completed', 'cancelled') DEFAULT 'pending',
    price DECIMAL(8, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    accepted_at TIMESTAMP NULL,
    started_at TIMESTAMP NULL,
    completed_at TIMESTAMP NULL
);

-- Collection tracking (real-time location updates)
CREATE TABLE collection_tracking (
    id INT PRIMARY KEY AUTO_INCREMENT,
    request_id INT NOT NULL,
    collector_latitude DECIMAL(10, 8) NOT NULL,
    collector_longitude DECIMAL(11, 8) NOT NULL,
    status_update VARCHAR(255),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (request_id) REFERENCES collection_requests(id) ON DELETE CASCADE
);

-- Feedback and ratings
CREATE TABLE feedback (
    id INT PRIMARY KEY AUTO_INCREMENT,
    request_id INT NOT NULL,
    customer_id INT NOT NULL,
    collector_id INT NOT NULL,
    rating INT CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (request_id) REFERENCES collection_requests(id),
    FOREIGN KEY (customer_id) REFERENCES users(id),
    FOREIGN KEY (collector_id) REFERENCES users(id)
);

-- Notifications
CREATE TABLE notifications (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    request_id INT,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    type ENUM('request_update', 'system', 'promotion') NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (request_id) REFERENCES collection_requests(id) ON DELETE SET NULL
);

-- Payment transactions
CREATE TABLE payments (
    id INT PRIMARY KEY AUTO_INCREMENT,
    request_id INT NOT NULL,
    customer_id INT NOT NULL,
    amount DECIMAL(8, 2) NOT NULL,
    payment_method ENUM('cash', 'card', 'digital_wallet') NOT NULL,
    transaction_id VARCHAR(255),
    status ENUM('pending', 'completed', 'failed', 'refunded') DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (request_id) REFERENCES collection_requests(id),
    FOREIGN KEY (customer_id) REFERENCES users(id)
);

-- Admin reports and analytics
CREATE TABLE system_reports (
    id INT PRIMARY KEY AUTO_INCREMENT,
    report_type VARCHAR(100) NOT NULL,
    report_data JSON,
    generated_by INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
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
