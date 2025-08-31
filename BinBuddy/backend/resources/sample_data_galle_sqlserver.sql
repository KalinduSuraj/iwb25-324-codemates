-- BinBuddy Sample Data for Galle, Sri Lanka (SQL Server Version)
-- Created: 2025-08-31
-- Location: Galle District, Southern Province, Sri Lanka
-- Database: SQL Server 2022

-- Use existing testconnect database
USE testconnect;
GO

-- ==============================================
-- USERS DATA (Customers, Collectors, Admin)
-- ==============================================

-- Admin Users
INSERT INTO users (email, password, user_type, full_name, phone, is_active) VALUES
('admin.galle@binbuddy.lk', '$2a$10$hashedpassword1', 'admin', 'Galle Regional Manager', '+94912234567', 1),
('supervisor.galle@binbuddy.lk', '$2a$10$hashedpassword2', 'admin', 'Kamal Perera', '+94912234568', 1);

-- Customer Users (Galle residents)
INSERT INTO users (email, password, user_type, full_name, phone, is_active) VALUES
('nimal.silva@gmail.com', '$2a$10$hashedpassword3', 'customer', 'Nimal Silva', '+94701234567', 1),
('kumari.fernando@gmail.com', '$2a$10$hashedpassword4', 'customer', 'Kumari Fernando', '+94701234568', 1),
('asanka.rajapaksha@gmail.com', '$2a$10$hashedpassword5', 'customer', 'Asanka Rajapaksha', '+94701234569', 1),
('sandani.perera@gmail.com', '$2a$10$hashedpassword6', 'customer', 'Sandani Perera', '+94701234570', 1),
('rohan.wickramasinghe@gmail.com', '$2a$10$hashedpassword7', 'customer', 'Rohan Wickramasinghe', '+94701234571', 1),
('malini.gunasekara@gmail.com', '$2a$10$hashedpassword8', 'customer', 'Malini Gunasekara', '+94701234572', 1),
('chaminda.de.silva@gmail.com', '$2a$10$hashedpassword9', 'customer', 'Chaminda De Silva', '+94701234573', 1),
('priyanka.jayawardana@gmail.com', '$2a$10$hashedpassword10', 'customer', 'Priyanka Jayawardana', '+94701234574', 1),
('thilak.bandara@gmail.com', '$2a$10$hashedpassword11', 'customer', 'Thilak Bandara', '+94701234575', 1),
('menaka.wijesinghe@gmail.com', '$2a$10$hashedpassword12', 'customer', 'Menaka Wijesinghe', '+94701234576', 1);

-- Collector Users (Waste collectors in Galle)
INSERT INTO users (email, password, user_type, full_name, phone, is_active) VALUES
('sunil.collector@binbuddy.lk', '$2a$10$hashedpassword13', 'collector', 'Sunil Amarasinghe', '+94771234567', 1),
('lasith.collector@binbuddy.lk', '$2a$10$hashedpassword14', 'collector', 'Lasith Kumara', '+94771234568', 1),
('dinesh.collector@binbuddy.lk', '$2a$10$hashedpassword15', 'collector', 'Dinesh Madusanka', '+94771234569', 1),
('ranjan.collector@binbuddy.lk', '$2a$10$hashedpassword16', 'collector', 'Ranjan Dissanayake', '+94771234570', 1),
('gayan.collector@binbuddy.lk', '$2a$10$hashedpassword17', 'collector', 'Gayan Senaratne', '+94771234571', 1);

-- ==============================================
-- CUSTOMER PROFILES (Galle Locations)
-- ==============================================

INSERT INTO customer_profiles (user_id, address, latitude, longitude, location_pin_name, subscription_type) VALUES
-- Galle Fort area customers
(3, 'No. 15, Church Street, Galle Fort, Galle', 6.0329, 80.2168, 'Galle Fort - Church Street', 'premium'),
(4, 'No. 42, Rampart Street, Galle Fort, Galle', 6.0315, 80.2155, 'Galle Fort - Rampart Street', 'basic'),
(5, 'No. 78, Lighthouse Street, Galle Fort, Galle', 6.0344, 80.2189, 'Galle Fort - Near Lighthouse', 'premium'),

-- Unawatuna area customers
(6, 'No. 23, Beach Road, Unawatuna, Galle', 6.0094, 80.2503, 'Unawatuna Beach Road', 'basic'),
(7, 'No. 67, Matara Road, Unawatuna, Galle', 6.0089, 80.2489, 'Unawatuna - Main Road', 'premium'),

-- Hikkaduwa area customers
(8, 'No. 145, Galle Road, Hikkaduwa, Galle', 6.1408, 80.1031, 'Hikkaduwa Beach Front', 'basic'),
(9, 'No. 89, Baddegama Road, Hikkaduwa, Galle', 6.1395, 80.1025, 'Hikkaduwa - Baddegama Road', 'basic'),

-- Bentota area customers
(10, 'No. 234, Colombo Road, Bentota, Galle', 6.4058, 79.9719, 'Bentota - Colombo Road', 'premium'),

-- Koggala area customers
(11, 'No. 56, Airport Road, Koggala, Galle', 5.9947, 80.3283, 'Koggala - Near Airport', 'basic'),

-- Ahangama area customers
(12, 'No. 128, Matara Road, Ahangama, Galle', 5.9711, 80.3686, 'Ahangama - Main Road', 'basic');

-- ==============================================
-- COLLECTOR PROFILES (Galle Service Areas)
-- ==============================================

INSERT INTO collector_profiles (user_id, vehicle_type, vehicle_number, license_number, service_area, current_latitude, current_longitude, is_available, rating, total_collections) VALUES
-- Collector 1: Galle Fort and surrounding areas
(13, 'Three Wheeler', 'CAK-1234', 'DL001234567', '["Galle Fort", "Kaluwella", "Dadalla", "Magalle"]', 6.0329, 80.2168, 1, 4.8, 156),

-- Collector 2: Unawatuna and coastal areas
(14, 'Small Truck', 'CAL-5678', 'DL001234568', '["Unawatuna", "Thalpe", "Koggala", "Ahangama"]', 6.0094, 80.2503, 1, 4.6, 203),

-- Collector 3: Hikkaduwa and northern areas
(15, 'Three Wheeler', 'CAM-9012', 'DL001234569', '["Hikkaduwa", "Dodanduwa", "Boossa", "Bentota"]', 6.1408, 80.1031, 0, 4.9, 289),

-- Collector 4: Southern Galle areas
(16, 'Motorcycle', 'CAN-3456', 'DL001234570', '["Habaraduwa", "Koggala", "Kataluwa", "Midigama"]', 5.9947, 80.3283, 1, 4.7, 134),

-- Collector 5: Central Galle areas
(17, 'Small Truck', 'CAP-7890', 'DL001234571', '["Galle City", "Wakwella", "Bope", "Poddala"]', 6.0535, 80.2210, 1, 4.5, 178);

-- ==============================================
-- COLLECTION REQUESTS (Current and Historical)
-- ==============================================

INSERT INTO collection_requests (customer_id, collector_id, request_type, scheduled_date, pickup_address, pickup_latitude, pickup_longitude, waste_type, estimated_weight, special_instructions, status, price, created_at, accepted_at, started_at, completed_at) VALUES

-- Completed requests
(3, 13, 'scheduled', '2025-08-30 08:00:00', 'No. 15, Church Street, Galle Fort, Galle', 6.0329, 80.2168, 'general', 5.50, 'Please collect from front gate', 'completed', 750.00, '2025-08-29 10:15:00', '2025-08-29 11:30:00', '2025-08-30 08:00:00', '2025-08-30 08:25:00'),

(4, 13, 'immediate', NULL, 'No. 42, Rampart Street, Galle Fort, Galle', 6.0315, 80.2155, 'recyclable', 3.20, 'Paper and plastic only', 'completed', 450.00, '2025-08-30 14:20:00', '2025-08-30 14:35:00', '2025-08-30 15:00:00', '2025-08-30 15:15:00'),

(6, 14, 'scheduled', '2025-08-31 07:30:00', 'No. 23, Beach Road, Unawatuna, Galle', 6.0094, 80.2503, 'organic', 4.80, 'Kitchen waste only', 'completed', 620.00, '2025-08-30 16:45:00', '2025-08-30 17:20:00', '2025-08-31 07:30:00', '2025-08-31 07:50:00'),

(8, 15, 'immediate', NULL, 'No. 145, Galle Road, Hikkaduwa, Galle', 6.1408, 80.1031, 'general', 6.70, 'Large bags, need assistance', 'completed', 850.00, '2025-08-30 11:10:00', '2025-08-30 12:00:00', '2025-08-30 13:30:00', '2025-08-30 14:00:00'),

-- Active/In-progress requests
(5, 13, 'scheduled', '2025-08-31 16:00:00', 'No. 78, Lighthouse Street, Galle Fort, Galle', 6.0344, 80.2189, 'general', 4.20, 'Ring the bell', 'accepted', 600.00, '2025-08-31 08:30:00', '2025-08-31 09:15:00', NULL, NULL),

(7, 14, 'immediate', NULL, 'No. 67, Matara Road, Unawatuna, Galle', 6.0089, 80.2489, 'recyclable', 2.10, 'Bottles and cans', 'in_progress', 350.00, '2025-08-31 12:20:00', '2025-08-31 12:45:00', '2025-08-31 13:00:00', NULL),

(11, 16, 'scheduled', '2025-09-01 09:00:00', 'No. 56, Airport Road, Koggala, Galle', 5.9947, 80.3283, 'organic', 3.50, 'Garden waste included', 'accepted', 480.00, '2025-08-31 10:00:00', '2025-08-31 11:30:00', NULL, NULL),

-- Pending requests
(9, NULL, 'immediate', NULL, 'No. 89, Baddegama Road, Hikkaduwa, Galle', 6.1395, 80.1025, 'general', 5.00, 'Urgent collection needed', 'pending', NULL, '2025-08-31 14:15:00', NULL, NULL, NULL),

(10, NULL, 'scheduled', '2025-09-02 08:00:00', 'No. 234, Colombo Road, Bentota, Galle', 6.4058, 79.9719, 'general', 7.20, 'Large household waste', 'pending', NULL, '2025-08-31 15:30:00', NULL, NULL, NULL),

(12, NULL, 'scheduled', '2025-09-01 15:00:00', 'No. 128, Matara Road, Ahangama, Galle', 5.9711, 80.3686, 'recyclable', 2.80, 'E-waste included', 'pending', NULL, '2025-08-31 16:00:00', NULL, NULL, NULL);

-- ==============================================
-- COLLECTION TRACKING (Real-time GPS Data)
-- ==============================================

INSERT INTO collection_tracking (request_id, collector_latitude, collector_longitude, status_update, updated_at) VALUES
-- Tracking for in-progress request (ID: 6)
(6, 6.0089, 80.2489, 'Collector arrived at pickup location', '2025-08-31 13:00:00'),
(6, 6.0089, 80.2489, 'Loading waste into vehicle', '2025-08-31 13:05:00'),
(6, 6.0095, 80.2495, 'En route to disposal facility', '2025-08-31 13:10:00'),

-- Historical tracking for completed requests
(1, 6.0329, 80.2168, 'Collector arrived', '2025-08-30 08:00:00'),
(1, 6.0329, 80.2168, 'Collection completed', '2025-08-30 08:25:00'),
(2, 6.0315, 80.2155, 'Immediate pickup started', '2025-08-30 15:00:00'),
(2, 6.0315, 80.2155, 'Collection finished', '2025-08-30 15:15:00');

-- ==============================================
-- FEEDBACK AND RATINGS
-- ==============================================

INSERT INTO feedback (request_id, customer_id, collector_id, rating, comment, created_at) VALUES
(1, 3, 13, 5, 'Excellent service! Very punctual and professional. Sunil was very courteous.', '2025-08-30 09:00:00'),
(2, 4, 13, 4, 'Good service, but could be a bit faster. Overall satisfied with the collection.', '2025-08-30 16:00:00'),
(3, 6, 14, 5, 'Perfect timing and very clean collection. Lasith explained the recycling process.', '2025-08-31 08:30:00'),
(4, 8, 15, 4, 'Helper was needed as mentioned, service was good. Dinesh was very helpful.', '2025-08-30 15:00:00');

-- ==============================================
-- NOTIFICATIONS
-- ==============================================

INSERT INTO notifications (user_id, request_id, title, message, type, is_read, created_at) VALUES
-- Customer notifications
(5, 5, 'Collection Accepted', 'Your waste collection request has been accepted by Sunil. Scheduled for today at 4:00 PM.', 'request_update', 0, '2025-08-31 09:15:00'),
(7, 6, 'Collector En Route', 'Lasith is on the way to your location. Estimated arrival: 5 minutes.', 'request_update', 0, '2025-08-31 12:55:00'),
(9, 8, 'New Request Submitted', 'Your immediate collection request has been submitted. Looking for available collectors in Hikkaduwa.', 'request_update', 1, '2025-08-31 14:15:00'),

-- Collector notifications
(13, 5, 'New Collection Request', 'New scheduled collection in Galle Fort area. Customer: Asanka Rajapaksha', 'request_update', 1, '2025-08-31 08:30:00'),
(14, 6, 'Collection Started', 'You have started collection for Rohan Wickramasinghe in Unawatuna.', 'request_update', 1, '2025-08-31 13:00:00'),
(15, NULL, 'Weekly Earnings Update', 'You earned Rs. 12,450 this week. Great job, Dinesh!', 'system', 0, '2025-08-31 06:00:00'),

-- System notifications
(3, NULL, 'Premium Subscription Benefits', 'Enjoy priority collection and 20% discount on all services!', 'promotion', 0, '2025-08-31 10:00:00'),
(8, NULL, 'Recycling Tips', 'Did you know? Proper waste segregation helps us serve you better!', 'system', 1, '2025-08-31 08:00:00');

-- ==============================================
-- PAYMENT TRANSACTIONS
-- ==============================================

INSERT INTO payments (request_id, customer_id, amount, payment_method, transaction_id, status, created_at) VALUES
(1, 3, 750.00, 'digital_wallet', 'TXN_GF_001_20250830', 'completed', '2025-08-30 08:30:00'),
(2, 4, 450.00, 'cash', NULL, 'completed', '2025-08-30 15:20:00'),
(3, 6, 620.00, 'card', 'TXN_UN_002_20250831', 'completed', '2025-08-31 08:00:00'),
(4, 8, 850.00, 'digital_wallet', 'TXN_HK_003_20250830', 'completed', '2025-08-30 14:05:00'),
(6, 7, 350.00, 'cash', NULL, 'pending', '2025-08-31 13:15:00');

-- ==============================================
-- SYSTEM REPORTS (Analytics Data)
-- ==============================================

INSERT INTO system_reports (report_type, report_data, generated_by, created_at) VALUES
('daily_collections_galle', 
'{"date": "2025-08-30", "total_collections": 4, "total_revenue": 2670.00, "avg_rating": 4.5, "top_areas": ["Galle Fort", "Unawatuna", "Hikkaduwa"], "collectors_active": 3}', 
1, '2025-08-31 06:00:00'),

('weekly_performance_galle', 
'{"week_ending": "2025-08-31", "total_requests": 18, "completed_requests": 14, "customer_satisfaction": 4.6, "revenue": 11250.00, "top_collector": "Dinesh Madusanka", "busiest_area": "Galle Fort"}', 
1, '2025-08-31 07:00:00'),

('collector_earnings_august', 
'{"month": "2025-08", "collector_earnings": [{"name": "Sunil Amarasinghe", "earnings": 8950.00, "collections": 45}, {"name": "Lasith Kumara", "earnings": 12450.00, "collections": 62}, {"name": "Dinesh Madusanka", "earnings": 15670.00, "collections": 78}]}', 
2, '2025-08-31 08:00:00');

PRINT 'Sample data for Galle, Sri Lanka has been successfully inserted!';
PRINT 'Database: binbuddy_db';
PRINT 'Records inserted: Users, Customer Profiles, Collector Profiles, Collection Requests, Tracking, Feedback, Notifications, Payments, Reports';
PRINT 'Geographic Coverage: Galle Fort, Unawatuna, Hikkaduwa, Bentota, Koggala, Ahangama';

GO
