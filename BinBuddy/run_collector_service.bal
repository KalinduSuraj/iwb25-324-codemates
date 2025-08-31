// import ballerina/log;
// import BinBuddy.backend.services.collector_service;

// # Collector Service Runner
// # Starts the collector service on port 8082

// function init() {
//     log:printInfo("🚛 Starting BinBuddy Collector Service...");
//     log:printInfo("📍 Port: 8082");
//     log:printInfo("🌐 Base URL: http://localhost:8082/api/collector");
//     log:printInfo("📚 API Documentation: http://localhost:8084/api-docs/collector");
// }

// public function main() {
//     log:printInfo("✅ BinBuddy Collector Service is running on port 8082");
//     log:printInfo("🔍 Health check: http://localhost:8082/api/collector/health");
//     log:printInfo("📊 Available endpoints:");
//     log:printInfo("   POST /api/collector/register");
//     log:printInfo("   POST /api/collector/login");
//     log:printInfo("   GET  /api/collector/requests/pending");
//     log:printInfo("   PUT  /api/collector/requests/{requestId}/accept");
//     log:printInfo("   PUT  /api/collector/requests/{requestId}/start");
//     log:printInfo("   PUT  /api/collector/requests/{requestId}/complete");
//     log:printInfo("   PUT  /api/collector/location");
//     log:printInfo("   PUT  /api/collector/availability");
//     log:printInfo("   GET  /api/collector/earnings/{collectorId}");
// }
