/**
 * BinBuddy Authentication API Integration
 * This file provides functions to interact with the consolidated BinBuddy API on port 8084
 * Created: August 31, 2025
 */

// =================================================================================
// API CONFIGURATION
// =================================================================================

const API_CONFIG = {
    BASE_URLS: {
        customer: 'http://localhost:8081',
        collector: 'http://localhost:8082',
        admin: 'http://localhost:8083',
        main: 'http://localhost:8084'
    },
    ENDPOINTS: {
        // Customer endpoints
        CUSTOMER_REGISTER: '/api/customer/register',
        CUSTOMER_LOGIN: '/api/customer/login',
        CUSTOMER_DASHBOARD: '/api/customer/{customerId}/dashboard',
        CUSTOMER_REQUESTS: '/api/customer/{customerId}/requests',
        CUSTOMER_TRACK: '/api/customer/{customerId}/requests/{requestId}/track',

        // Collector endpoints
        COLLECTOR_REGISTER: '/api/collector/register',
        COLLECTOR_LOGIN: '/api/collector/login',
        COLLECTOR_DASHBOARD: '/api/collector/{collectorId}/dashboard',
        COLLECTOR_AVAILABLE: '/api/collector/{collectorId}/requests/available',
        COLLECTOR_ASSIGNED: '/api/collector/{collectorId}/requests/assigned',

        // Admin endpoints
        ADMIN_LOGIN: '/api/admin/login',
        ADMIN_DASHBOARD: '/api/admin/dashboard',
        ADMIN_USERS: '/api/admin/users',
        ADMIN_REQUESTS: '/api/admin/requests',
        ADMIN_ANALYTICS: '/api/admin/analytics/{reportType}',

        // System endpoints (main service)
        HEALTH: '/health',
        DOCS: '/docs',
        CONFIG: '/config'
    },
    HEADERS: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
    }
};

// =================================================================================
// UTILITY FUNCTIONS
// =================================================================================

/**
 * Makes HTTP requests to the BinBuddy API
 * @param {string} endpoint - API endpoint
 * @param {object} options - Request options
 * @returns {Promise<object>} API response
 */
// Enhanced API request to support different base URLs per user type
async function apiRequest(endpoint, options = {}, userType = 'main') {
    // Pick base URL based on userType
    const baseUrl = API_CONFIG.BASE_URLS[userType] || API_CONFIG.BASE_URLS.main;
    const url = `${baseUrl}${endpoint}`;

    const defaultOptions = {
        headers: {...API_CONFIG.HEADERS },
        credentials: 'same-origin'
    };

    // Add authorization token if available
    const token = localStorage.getItem('authToken');
    if (token) {
        defaultOptions.headers['Authorization'] = `Bearer ${token}`;
    }

    const finalOptions = {
        ...defaultOptions,
        ...options,
        headers: {
            ...defaultOptions.headers,
            ...options.headers
        }
    };

    try {
        console.log(`API Request: ${options.method || 'GET'} ${url}`);
        const response = await fetch(url, finalOptions);

        let data;
        try {
            data = await response.json();
        } catch (parseError) {
            throw new Error('Invalid JSON response from server');
        }

        if (!response.ok) {
            throw new Error(data.message || `HTTP ${response.status}: ${response.statusText}`);
        }

        console.log('API Response:', data);
        return data;

    } catch (error) {
        console.error('API Error:', error);
        throw error;
    }
}

/**
 * Stores authentication token and user info
 * @param {string} token - JWT token
 * @param {object} userInfo - User information
 */
function storeAuthData(token, userInfo) {
    localStorage.setItem('authToken', token);
    localStorage.setItem('userInfo', JSON.stringify(userInfo));
    console.log('Auth data stored successfully');
}

/**
 * Clears authentication data
 */
function clearAuthData() {
    localStorage.removeItem('authToken');
    localStorage.removeItem('userInfo');
    console.log('Auth data cleared');
}

/**
 * Gets stored user information
 * @returns {object|null} User information or null
 */
function getStoredUserInfo() {
    const userInfo = localStorage.getItem('userInfo');
    return userInfo ? JSON.parse(userInfo) : null;
}

/**
 * Checks if user is authenticated
 * @returns {boolean} Authentication status
 */
function isAuthenticated() {
    const token = localStorage.getItem('authToken');
    if (!token) return false;

    try {
        // Basic token validation (without signature verification)
        const payload = JSON.parse(atob(token.split('.')[1]));
        const isExpired = payload.exp * 1000 < Date.now();

        if (isExpired) {
            clearAuthData();
            return false;
        }

        return true;
    } catch (error) {
        console.error('Token validation error:', error);
        clearAuthData();
        return false;
    }
}

// =================================================================================
// AUTHENTICATION FUNCTIONS
// =================================================================================

/**
 * Register a new customer
 * @param {object} customerData - Customer registration data
 * @returns {Promise<object>} Registration response
 */
async function registerCustomer(customerData) {
    const response = await fetch('http://localhost:8084/api/customer/register', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json'
        },
        body: JSON.stringify({
            full_name: customerData.full_name,
            email: customerData.email,
            password: customerData.password,
            phone: customerData.phone || '',
            address: customerData.address || ''
        })
    });

    const data = await response.json();
    return data;
}
/**
 * Login as customer
 * @param {string} email - Customer email
 * @param {string} password - Customer password
 * @returns {Promise<object>} Login response
 */
async function loginCustomer(email, password) {
    const response = await apiRequest(
        API_CONFIG.ENDPOINTS.CUSTOMER_LOGIN, {
            method: 'POST',
            body: JSON.stringify({ email, password })
        },
        'customer'
    );

    if (response.success && response.data) {
        // Store auth data for future requests
        const token = response.data.session_token || response.data.sessionToken;
        const userInfo = {
            id: response.data.customer_id || response.data.customerId,
            email: response.data.email,
            role: 'customer',
            profile: response.data.profile
        };

        storeAuthData(token, userInfo);
    }

    return response;
}

/**
 * Register a new collector
 * @param {object} collectorData - Collector registration data
 * @returns {Promise<object>} Registration response
 */
async function registerCollector(collectorData) {
    const response = await apiRequest(
        API_CONFIG.ENDPOINTS.COLLECTOR_REGISTER, {
            method: 'POST',
            body: JSON.stringify({
                full_name: collectorData.full_name,
                email: collectorData.email,
                password: collectorData.password,
                phone: collectorData.phone || '',
                vehicle_type: collectorData.vehicle_type,
                vehicle_number: collectorData.vehicle_number,
                license_number: collectorData.license_number,
                service_area: collectorData.service_area
            })
        },
        'collector'
    );
    return response;
}

/**
 * Login as collector
 * @param {string} email - Collector email
 * @param {string} password - Collector password
 * @returns {Promise<object>} Login response
 */
async function loginCollector(email, password) {
    const response = await apiRequest(
        API_CONFIG.ENDPOINTS.COLLECTOR_LOGIN, {
            method: 'POST',
            body: JSON.stringify({ email, password })
        },
        'collector'
    );

    if (response.success && response.data) {
        const token = response.data.session_token || response.data.sessionToken;
        const userInfo = {
            id: response.data.collector_id || response.data.collectorId,
            email: response.data.email,
            role: 'collector',
            profile: response.data.profile
        };

        storeAuthData(token, userInfo);
    }

    return response;
}

/**
 * Login as admin
 * @param {string} email - Admin email
 * @param {string} password - Admin password
 * @returns {Promise<object>} Login response
 */
async function loginAdmin(email, password) {
    const response = await apiRequest(
        API_CONFIG.ENDPOINTS.ADMIN_LOGIN, {
            method: 'POST',
            body: JSON.stringify({ email, password })
        },
        'admin'
    );

    if (response.success && response.data) {
        const token = response.data.session_token || response.data.sessionToken;
        const userInfo = {
            id: response.data.admin_id || response.data.adminId,
            email: response.data.email,
            role: 'admin',
            profile: response.data.profile
        };

        storeAuthData(token, userInfo);
    }

    return response;
}

/**
 * Logout user
 */
function logout() {
    clearAuthData();
    // Redirect to home page
    window.location.href = 'index.html';
}

// =================================================================================
// DATA FETCHING FUNCTIONS
// =================================================================================

/**
 * Get customer dashboard data
 * @param {number} customerId - Customer ID
 * @returns {Promise<object>} Dashboard data
 */
async function getCustomerDashboard(customerId) {
    const endpoint = API_CONFIG.ENDPOINTS.CUSTOMER_DASHBOARD.replace('{customerId}', customerId);
    return await apiRequest(endpoint);
}

/**
 * Get customer requests
 * @param {number} customerId - Customer ID
 * @returns {Promise<object>} Customer requests
 */
async function getCustomerRequests(customerId) {
    const endpoint = API_CONFIG.ENDPOINTS.CUSTOMER_REQUESTS.replace('{customerId}', customerId);
    return await apiRequest(endpoint);
}

/**
 * Create collection request
 * @param {number} customerId - Customer ID
 * @param {object} requestData - Request data
 * @returns {Promise<object>} Created request
 */
async function createCollectionRequest(customerId, requestData) {
    const endpoint = API_CONFIG.ENDPOINTS.CUSTOMER_REQUESTS.replace('{customerId}', customerId);
    return await apiRequest(endpoint, {
        method: 'POST',
        body: JSON.stringify(requestData)
    });
}

/**
 * Track collection request
 * @param {number} customerId - Customer ID
 * @param {number} requestId - Request ID
 * @returns {Promise<object>} Tracking info
 */
async function trackCollectionRequest(customerId, requestId) {
    const endpoint = API_CONFIG.ENDPOINTS.CUSTOMER_TRACK
        .replace('{customerId}', customerId)
        .replace('{requestId}', requestId);
    return await apiRequest(endpoint);
}

/**
 * Get collector dashboard data
 * @param {number} collectorId - Collector ID
 * @returns {Promise<object>} Dashboard data
 */
async function getCollectorDashboard(collectorId) {
    const endpoint = API_CONFIG.ENDPOINTS.COLLECTOR_DASHBOARD.replace('{collectorId}', collectorId);
    return await apiRequest(endpoint);
}

/**
 * Get admin dashboard data
 * @returns {Promise<object>} Dashboard data
 */
async function getAdminDashboard() {
    return await apiRequest(API_CONFIG.ENDPOINTS.ADMIN_DASHBOARD);
}

/**
 * Get all users (admin only)
 * @returns {Promise<object>} Users data
 */
async function getAllUsers() {
    return await apiRequest(API_CONFIG.ENDPOINTS.ADMIN_USERS);
}

/**
 * Get all requests (admin only)
 * @returns {Promise<object>} Requests data
 */
async function getAllRequests() {
    return await apiRequest(API_CONFIG.ENDPOINTS.ADMIN_REQUESTS);
}

/**
 * Get analytics report
 * @param {string} reportType - Report type (daily, weekly, monthly)
 * @returns {Promise<object>} Analytics data
 */
async function getAnalytics(reportType) {
    const endpoint = API_CONFIG.ENDPOINTS.ADMIN_ANALYTICS.replace('{reportType}', reportType);
    return await apiRequest(endpoint);
}

/**
 * Check system health
 * @returns {Promise<object>} Health status
 */
async function checkSystemHealth() {
    return await apiRequest(API_CONFIG.ENDPOINTS.HEALTH);
}

// =================================================================================
// EXPORT FUNCTIONS (for use in other scripts)
// =================================================================================

// Make functions globally available
window.BinBuddyAuth = {
    // Authentication
    registerCustomer,
    loginCustomer,
    registerCollector,
    loginCollector,
    loginAdmin,
    logout,

    // Utility
    isAuthenticated,
    getStoredUserInfo,
    clearAuthData,

    // Data fetching
    getCustomerDashboard,
    getCustomerRequests,
    createCollectionRequest,
    trackCollectionRequest,
    getCollectorDashboard,
    getAdminDashboard,
    getAllUsers,
    getAllRequests,
    getAnalytics,
    checkSystemHealth,

    // Config
    API_CONFIG
};

console.log('BinBuddy Auth API loaded successfully');