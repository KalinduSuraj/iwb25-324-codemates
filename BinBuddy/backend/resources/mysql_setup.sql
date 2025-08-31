-- BinBuddy Waste Management Database Setup for MySQL
-- Drop and recreate database for clean setup
DROP DATABASE IF EXISTS binbuddy_db;
CREATE DATABASE binbuddy_db;
USE binbuddy_db;

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
    completed_at TIMESTAMP NULL,
    FOREIGN KEY (customer_id) REFERENCES users(id) ON DELETE CASCADE
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

-- Insert test data
-- Default admin user
INSERT INTO users (email, password, user_type, full_name, phone) 
VALUES ('admin@binbuddy.com', 'admin123', 'admin', 'System Administrator', '+1234567890');

-- Sample customers (Galle area)
INSERT INTO users (email, password, user_type, full_name, phone) VALUES
('john.silva@email.com', 'password123', 'customer', 'John Silva', '+94771234567'),
('mary.fernando@email.com', 'password123', 'customer', 'Mary Fernando', '+94772345678'),
('david.perera@email.com', 'password123', 'customer', 'David Perera', '+94773456789'),
('sarah.jayasinghe@email.com', 'password123', 'customer', 'Sarah Jayasinghe', '+94774567890'),
('michael.rajapaksa@email.com', 'password123', 'customer', 'Michael Rajapaksa', '+94775678901');

-- Sample collectors
INSERT INTO users (email, password, user_type, full_name, phone) VALUES
('collector1@binbuddy.com', 'collector123', 'collector', 'Ravi Gunasekara', '+94776789012'),
('collector2@binbuddy.com', 'collector123', 'collector', 'Nimal Wijesinghe', '+94777890123'),
('collector3@binbuddy.com', 'collector123', 'collector', 'Sunil Mendis', '+94778901234');

-- Customer profiles (Galle locations)
INSERT INTO customer_profiles (user_id, address, latitude, longitude, location_pin_name, subscription_type) VALUES
(2, '123 Main Street, Galle Fort, Galle', 6.0328, 80.2170, 'Galle Fort Area', 'premium'),
(3, '456 Hospital Road, Karapitiya, Galle', 6.0535, 80.2210, 'Karapitiya Hospital Area', 'basic'),
(4, '789 Matara Road, Akmeemana, Galle', 6.0891, 80.2456, 'Akmeemana Junction', 'basic'),
(5, '321 Richmond Hill Road, Galle', 6.0367, 80.2142, 'Richmond Hill', 'premium'),
(6, '654 Wakwella Road, Galle', 6.0789, 80.2543, 'Wakwella Area', 'basic');

-- Collector profiles
INSERT INTO collector_profiles (user_id, vehicle_type, vehicle_number, license_number, service_area, current_latitude, current_longitude, is_available, rating, total_collections) VALUES
(7, 'Pickup Truck', 'CAR-1234', 'DL12345', '["Galle Fort", "Karapitiya", "Akmeemana"]', 6.0328, 80.2170, TRUE, 4.5, 150),
(8, 'Mini Truck', 'CAR-5678', 'DL23456', '["Richmond Hill", "Wakwella", "Bope-Poddala"]', 6.0367, 80.2142, TRUE, 4.2, 120),
(9, 'Van', 'CAR-9012', 'DL34567', '["Galle Central", "Hirimbura", "Dadalla"]', 6.0270, 80.2167, FALSE, 4.8, 200);

-- Sample collection requests
INSERT INTO collection_requests (customer_id, collector_id, request_type, scheduled_date, pickup_address, pickup_latitude, pickup_longitude, waste_type, estimated_weight, special_instructions, status, price, accepted_at, started_at, completed_at) VALUES
(2, 7, 'immediate', NULL, '123 Main Street, Galle Fort, Galle', 6.0328, 80.2170, 'general', 15.50, 'Please collect from front gate', 'completed', 500.00, '2025-08-30 09:15:00', '2025-08-30 10:30:00', '2025-08-30 11:00:00'),
(3, 8, 'scheduled', '2025-09-01 14:00:00', '456 Hospital Road, Karapitiya, Galle', 6.0535, 80.2210, 'recyclable', 8.00, 'Separate plastic and paper', 'accepted', 300.00, '2025-08-30 15:20:00', NULL, NULL),
(4, NULL, 'immediate', NULL, '789 Matara Road, Akmeemana, Galle', 6.0891, 80.2456, 'organic', 12.00, 'Garden waste collection', 'pending', NULL, NULL, NULL, NULL),
(5, 9, 'scheduled', '2025-09-02 10:00:00', '321 Richmond Hill Road, Galle', 6.0367, 80.2142, 'general', 20.00, 'Heavy items included', 'in_progress', 750.00, '2025-08-31 08:00:00', '2025-08-31 10:00:00', NULL);

-- Sample collection tracking
INSERT INTO collection_tracking (request_id, collector_latitude, collector_longitude, status_update) VALUES
(1, 6.0320, 80.2165, 'On the way to pickup location'),
(1, 6.0328, 80.2170, 'Arrived at pickup location'),
(1, 6.0328, 80.2170, 'Collection completed'),
(2, 6.0400, 80.2180, 'Heading to scheduled pickup'),
(4, 6.0350, 80.2160, 'En route to pickup location');

-- Sample feedback
INSERT INTO feedback (request_id, customer_id, collector_id, rating, comment) VALUES
(1, 2, 7, 5, 'Excellent service! Very punctual and professional.'),
(1, 2, 7, 4, 'Good service but could be faster next time.');

-- Sample notifications
INSERT INTO notifications (user_id, request_id, title, message, type, is_read) VALUES
(2, 1, 'Collection Completed', 'Your waste collection request has been completed successfully.', 'request_update', TRUE),
(3, 2, 'Collector Assigned', 'A collector has been assigned to your request.', 'request_update', FALSE),
(4, 3, 'Request Received', 'Your collection request has been received and is pending assignment.', 'request_update', FALSE),
(7, 1, 'Payment Received', 'Payment for collection request #1 has been processed.', 'system', TRUE);

-- Sample payments
INSERT INTO payments (request_id, customer_id, amount, payment_method, transaction_id, status) VALUES
(1, 2, 500.00, 'digital_wallet', 'TXN123456789', 'completed'),
(2, 3, 300.00, 'cash', NULL, 'pending'),
(4, 5, 750.00, 'card', 'TXN987654321', 'completed');

-- Sample system reports
INSERT INTO system_reports (report_type, report_data, generated_by) VALUES
('daily_collections', '{"total_requests": 4, "completed": 1, "pending": 1, "in_progress": 1, "revenue": 1250.00}', 1),
('collector_performance', '{"collector_id": 7, "rating": 4.5, "total_collections": 150, "revenue_generated": 75000.00}', 1);

-- Display summary
SELECT 'Database setup completed successfully!' as message;
SELECT COUNT(*) as total_users FROM users;
SELECT COUNT(*) as total_customers FROM customer_profiles;
SELECT COUNT(*) as total_collectors FROM collector_profiles;
SELECT COUNT(*) as total_requests FROM collection_requests;
