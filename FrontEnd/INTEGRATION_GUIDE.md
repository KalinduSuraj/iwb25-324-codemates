# BinBuddy Frontend-Backend Integration Guide

## Overview

This document explains how to integrate the BinBuddy frontend with the consolidated backend API running on port 8084. The integration uses separate files to maintain clean architecture and enable future flexibility.

## File Structure

```
FrontEnd/
├── index-enhanced.html          # Enhanced landing page with real API integration
├── customer-dashboard.html      # Customer dashboard with real data
├── collector-dashboard.html     # Collector dashboard with real data  
├── admin-dashboard.html         # Admin dashboard with real data
├── js/
│   └── auth-api.js             # API integration layer (authentication & data)
├── assets/
│   ├── css/
│   │   └── style.css
│   ├── images/
│   └── js/
│       └── navbar.js
└── (original files remain unchanged)
```

## Key Integration Files

### 1. auth-api.js
**Purpose:** Central API integration layer that handles all communication with the backend
**Features:**
- Authentication for customers, collectors, and admins
- Data fetching for dashboards
- Request and subscription management
- Centralized error handling
- Token management

**Key Functions:**
```javascript
// Authentication
BinBuddyAuth.registerCustomer(customerData)
BinBuddyAuth.loginCustomer(email, password)
BinBuddyAuth.registerCollector(collectorData)
BinBuddyAuth.loginCollector(email, password)
BinBuddyAuth.loginAdmin(email, password)
BinBuddyAuth.logout()

// Data Operations
BinBuddyAuth.getCustomerDashboard()
BinBuddyAuth.getCustomerRequests()
BinBuddyAuth.createServiceRequest(requestData)
BinBuddyAuth.getCollectorRequests()
BinBuddyAuth.updateRequestStatus(requestId, updateData)
BinBuddyAuth.getAdminDashboard()
BinBuddyAuth.assignCollector(requestId, assignmentData)
```

### 2. Enhanced HTML Files
**Purpose:** Improved versions of existing pages with real API integration
**Changes:**
- Added real authentication flows
- Integrated with actual backend data
- Enhanced UI/UX with loading states and error handling
- Responsive design improvements

## API Endpoints Used

All endpoints point to `http://localhost:8084` and include the following:

### Customer Service Endpoints
- `POST /customer/register` - Customer registration
- `POST /customer/login` - Customer login
- `GET /customer/dashboard` - Customer dashboard data
- `GET /customer/requests` - Customer service requests
- `POST /customer/requests` - Create service request
- `GET /customer/subscriptions` - Customer subscriptions
- `POST /customer/subscriptions` - Create subscription

### Collector Service Endpoints
- `POST /collector/register` - Collector registration
- `POST /collector/login` - Collector login
- `GET /collector/dashboard` - Collector dashboard data
- `GET /collector/requests` - Assigned requests
- `PUT /collector/requests/{id}/status` - Update request status

### Admin Service Endpoints
- `POST /admin/login` - Admin login
- `GET /admin/dashboard` - Admin dashboard data
- `GET /admin/requests` - All requests
- `GET /admin/customers` - All customers
- `GET /admin/collectors` - All collectors
- `POST /admin/requests/{id}/assign` - Assign collector
- `GET /admin/analytics` - System analytics

## Authentication Flow

### 1. User Registration/Login
```javascript
// Example: Customer registration
const customerData = {
    full_name: "John Doe",
    email: "john@example.com", 
    password: "password123"
};

const response = await BinBuddyAuth.registerCustomer(customerData);
if (response.success) {
    // Registration successful
    // User can now login
}
```

### 2. Automatic Login Detection
```javascript
// Check if user is already logged in
if (BinBuddyAuth.isAuthenticated()) {
    const userInfo = BinBuddyAuth.getStoredUserInfo();
    // Redirect to appropriate dashboard
    redirectToDashboard(userInfo.role);
}
```

### 3. Token Management
- Tokens are automatically stored in localStorage
- Automatic token inclusion in API requests
- Token expiration handling
- Automatic logout on token expiry

## Dashboard Integration

### Customer Dashboard Features
- **Statistics:** Total requests, active subscriptions, pending/completed requests
- **Service Requests:** View all requests, create new requests, track status
- **Subscriptions:** Manage recurring services
- **Real-time Updates:** Live data from backend

### Collector Dashboard Features  
- **Statistics:** Assigned requests, in-progress items, completed today, ratings
- **Request Management:** View assigned requests, update status
- **Collection History:** Past completed collections
- **Status Updates:** Mark requests as in-progress or completed

### Admin Dashboard Features
- **System Overview:** Total users, requests, pending items, active collectors
- **Request Management:** View all requests, assign collectors
- **User Management:** Monitor customers and collectors
- **Analytics:** Performance metrics and trends
- **Assignment System:** Assign requests to available collectors

## Error Handling

### API Error Responses
All API functions return standardized responses:
```javascript
{
    success: boolean,
    message: string,
    data: any,
    error?: string
}
```

### Frontend Error Display
- Form validation errors shown inline
- Network errors displayed in modals
- Success messages with auto-dismiss
- Loading states during API calls

## Security Features

### Authentication Security
- Password-based authentication
- Token-based session management
- Role-based access control
- Automatic logout on token expiry

### Data Protection
- All API calls use proper headers
- User data stored securely in localStorage
- Role validation on all protected routes
- CORS handling for cross-origin requests

## Usage Instructions

### 1. Starting the System
```bash
# Start the backend service
cd BinBuddy
bal run

# Backend will be available at http://localhost:8084
```

### 2. Accessing the Frontend
```bash
# Open the enhanced landing page
open index-enhanced.html

# Or open specific dashboards directly
open customer-dashboard.html
open collector-dashboard.html  
open admin-dashboard.html
```

### 3. Test Accounts
Use these credentials for testing:

**Customer:**
- Email: customer@test.com
- Password: password123

**Collector:** 
- Email: collector@test.com
- Password: password123

**Admin:**
- Email: admin@binbuddy.lk
- Password: admin123

## Development Guidelines

### 1. Adding New Features
- Add API functions to `auth-api.js`
- Update dashboard components as needed
- Maintain separation of concerns
- Follow existing error handling patterns

### 2. API Integration Pattern
```javascript
// Standard API call pattern
async function callAPI() {
    try {
        showLoading();
        const response = await BinBuddyAuth.apiFunction(data);
        if (response.success) {
            handleSuccess(response.data);
        } else {
            handleError(response.message);
        }
    } catch (error) {
        handleError(error.message);
    } finally {
        hideLoading();
    }
}
```

### 3. State Management
- Use local state objects for component data
- Update UI through render functions
- Maintain data consistency across components
- Handle loading and error states properly

## Testing

### 1. Authentication Testing
- Test registration for all user types
- Verify login/logout functionality
- Test role-based redirections
- Validate token management

### 2. Dashboard Testing
- Verify data loading from API
- Test all CRUD operations
- Check error handling
- Validate user permissions

### 3. Cross-browser Testing
- Test on Chrome, Firefox, Safari, Edge
- Verify responsive design
- Check mobile compatibility
- Test offline behavior

## Troubleshooting

### Common Issues

**1. API Connection Failed**
- Ensure backend is running on port 8084
- Check network connectivity
- Verify CORS settings

**2. Authentication Issues**
- Clear localStorage to reset tokens
- Check user credentials
- Verify user role permissions

**3. Data Not Loading**
- Check browser console for errors
- Verify API endpoints are correct
- Ensure user is authenticated

### Debug Mode
Enable debug mode in `auth-api.js`:
```javascript
const DEBUG_MODE = true; // Set to true for debugging
```

This will log all API calls and responses to the console.

## Future Enhancements

### Planned Features
1. **Real-time Notifications:** WebSocket integration for live updates
2. **Offline Support:** Service worker for offline functionality  
3. **Mobile App:** React Native or Flutter mobile application
4. **Advanced Analytics:** Charts and graphs for better insights
5. **Multi-language Support:** Internationalization features

### Architecture Improvements
1. **State Management:** Consider Redux or similar for complex state
2. **Component Framework:** Migrate to React/Vue for better maintainability
3. **TypeScript:** Add type safety for better development experience
4. **Testing Framework:** Unit and integration tests
5. **Performance Optimization:** Code splitting and lazy loading

## Conclusion

This integration provides a solid foundation for the BinBuddy application with:
- Clean separation between frontend and backend
- Robust authentication and authorization
- Comprehensive data management
- Scalable architecture for future enhancements
- User-friendly interface with real-time data

The separate file approach ensures that future modifications can be made without disrupting existing functionality, making the system maintainable and extensible.
