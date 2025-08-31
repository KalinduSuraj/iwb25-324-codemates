import ballerina/log;
import BinBuddy.backend.services.customer_service;

# Customer Service Runner
# Starts the customer service on port 8081

function init() {
    log:printInfo("🎯 Starting BinBuddy Customer Service...");
    log:printInfo("📍 Port: 8081");
    log:printInfo("🌐 Base URL: http://localhost:8081/api/customer");
    log:printInfo("📚 API Documentation: http://localhost:8084/api-docs/customer");
}

public function main() {
    log:printInfo("✅ BinBuddy Customer Service is running on port 8081");
    log:printInfo("🔍 Health check: http://localhost:8081/api/customer/health");
    log:printInfo("📊 Available endpoints:");
    log:printInfo("   POST /api/customer/register");
    log:printInfo("   POST /api/customer/login");
    log:printInfo("   POST /api/customer/requests");
    log:printInfo("   GET  /api/customer/requests/{customerId}");
    log:printInfo("   GET  /api/customer/tracking/{requestId}");
    log:printInfo("   POST /api/customer/feedback");
    log:printInfo("   GET  /api/customer/dashboard/{customerId}");
    log:printInfo("   DELETE /api/customer/requests/{requestId}");
}
