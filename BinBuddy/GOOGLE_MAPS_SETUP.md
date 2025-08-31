# Google Maps API Setup Guide for BinBuddy 🗺️

## 📋 **Step-by-Step Setup Instructions**

### **1. Create Google Cloud Project**
1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Click "Create Project" or select existing project
3. Name your project: `BinBuddy-Galle-WasteManagement`
4. Note your Project ID

### **2. Enable Required APIs**
Navigate to "APIs & Services" > "Library" and enable:
- ✅ **Maps JavaScript API** (for frontend maps)
- ✅ **Geocoding API** (for address conversion)
- ✅ **Directions API** (for route calculation)
- ✅ **Places API** (for location search)
- ✅ **Geolocation API** (for real-time tracking)

### **3. Create API Credentials**
1. Go to "APIs & Services" > "Credentials"
2. Click "Create Credentials" > "API Key"
3. Copy the generated API key
4. **IMPORTANT**: Restrict the API key immediately for security

### **4. Configure API Key Restrictions**

#### **For Frontend (Maps JavaScript API)**:
- **Application restrictions**: HTTP referrers
- **Website restrictions**: Add your domains:
  ```
  localhost:*
  127.0.0.1:*
  your-domain.com/*
  *.your-domain.com/*
  ```
- **API restrictions**: Maps JavaScript API

#### **For Backend (Server-side APIs)**:
- **Application restrictions**: IP addresses
- **IP restrictions**: Add your server IPs
- **API restrictions**: Geocoding API, Directions API, Places API

### **5. Set Up Billing**
⚠️ **Required for production use**
1. Go to "Billing" > "Link a billing account"
2. Add payment method
3. Set up budget alerts
4. Configure quotas to control costs

---

## 🔑 **API Keys Configuration**

### **Method 1: Environment Variables (Recommended)**
Create a `.env` file in your project root:
```bash
# Google Maps API Keys
GOOGLE_MAPS_JS_API_KEY=AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
GOOGLE_GEOCODING_API_KEY=AIzaSyYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY
GOOGLE_DIRECTIONS_API_KEY=AIzaSyZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ
GOOGLE_PLACES_API_KEY=AIzaSyAAAAAAAAAAAAAAAAAAAAAAAAA

# Galle Location Defaults
DEFAULT_LAT=6.0329
DEFAULT_LNG=80.2168
REGION=LK
LANGUAGE=en
```

### **Method 2: Ballerina Config File**
Update `Config.toml`:
```toml
[google_maps]
js_api_key = "YOUR_MAPS_JAVASCRIPT_API_KEY"
geocoding_api_key = "YOUR_GEOCODING_API_KEY" 
directions_api_key = "YOUR_DIRECTIONS_API_KEY"
places_api_key = "YOUR_PLACES_API_KEY"

[location_defaults]
region = "LK"
language = "en"
default_lat = 6.0329
default_lng = 80.2168
```

### **Method 3: Direct Configuration**
Update `backend/utils/google_maps_service.bal`:
```ballerina
configurable string GOOGLE_GEOCODING_API_KEY = "AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX";
configurable string GOOGLE_DIRECTIONS_API_KEY = "AIzaSyYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY";
configurable string GOOGLE_PLACES_API_KEY = "AIzaSyZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";
```

---

## 🏝️ **Galle-Specific Configuration**

### **Geographic Bounds for Galle District**:
```ballerina
# Galle district boundaries
decimal GALLE_NORTH = 6.5;    # Northern boundary
decimal GALLE_SOUTH = 5.9;    # Southern boundary  
decimal GALLE_EAST = 80.4;    # Eastern boundary
decimal GALLE_WEST = 79.8;    # Western boundary

# Major Galle locations
decimal GALLE_FORT_LAT = 6.0329;
decimal GALLE_FORT_LNG = 80.2168;
decimal UNAWATUNA_LAT = 6.0094;
decimal UNAWATUNA_LNG = 80.2503;
decimal HIKKADUWA_LAT = 6.1408;
decimal HIKKADUWA_LNG = 80.1031;
```

### **Sri Lankan Address Formatting**:
- Always append ", Sri Lanka" to addresses
- Use postal codes when available
- Include district and province information

---

## 🔧 **Integration Points in BinBuddy**

### **1. Customer Service Integration**:
```ballerina
# In customer_service.bal
import binbuddy.utils.google_maps_service as maps;

# Validate customer address during registration
GeocodeResponse geocodeResult = check maps:geocodeAddress(customerAddress);
if (geocodeResult.results.length() > 0) {
    // Save validated coordinates
    decimal lat = geocodeResult.results[0].geometry_location.lat;
    decimal lng = geocodeResult.results[0].geometry_location.lng;
}
```

### **2. Collector Service Integration**:
```ballerina
# Calculate route to customer location
DirectionsResponse directions = check maps:getDirections(
    collectorLocation, 
    customerAddress
);
```

### **3. Frontend Integration (HTML)**:
```html
<!-- In your HTML file -->
<script async defer
    src="https://maps.googleapis.com/maps/api/js?key=YOUR_MAPS_JS_API_KEY&callback=initMap&region=LK">
</script>
```

### **4. Real-time Tracking**:
```javascript
// Track collector location
navigator.geolocation.watchPosition(function(position) {
    updateCollectorLocation(position.coords.latitude, position.coords.longitude);
});
```

---

## 💰 **Pricing and Quotas**

### **Free Tier Limits (per month)**:
- **Maps JavaScript API**: $200 credit = ~28,000 map loads
- **Geocoding API**: $200 credit = ~40,000 requests  
- **Directions API**: $200 credit = ~40,000 requests
- **Places API**: $200 credit = ~100,000 requests

### **Cost Optimization Tips**:
1. **Enable API restrictions** to prevent unauthorized usage
2. **Set daily quotas** to control costs
3. **Cache geocoding results** to reduce API calls
4. **Use client-side Maps API** for map display
5. **Batch API requests** when possible

### **Monitoring Usage**:
1. Set up billing alerts in Google Cloud Console
2. Monitor API usage in APIs & Services dashboard
3. Implement logging in your Ballerina services

---

## 🔒 **Security Best Practices**

### **API Key Security**:
- ❌ **Never** commit API keys to version control
- ✅ Use environment variables for production
- ✅ Implement HTTP referrer restrictions
- ✅ Set up IP address restrictions for server keys
- ✅ Regularly rotate API keys

### **Frontend Security**:
- ✅ Use separate API key for client-side calls
- ✅ Restrict to specific domains only
- ✅ Implement rate limiting in your backend
- ✅ Validate all API responses

---

## 🧪 **Testing Configuration**

### **Test Locations in Galle**:
```ballerina
# Test geocoding with Galle addresses
string[] testAddresses = [
    "Galle Fort, Galle, Sri Lanka",
    "Unawatuna Beach, Galle, Sri Lanka", 
    "Hikkaduwa Beach, Galle, Sri Lanka",
    "Dutch Hospital, Galle Fort, Sri Lanka"
];
```

### **Health Check Endpoint**:
```ballerina
# Add to your service
resource function get maps/health() returns json {
    boolean isHealthy = maps:checkGoogleMapsHealth();
    return {
        "status": isHealthy ? "healthy" : "unhealthy",
        "timestamp": time:utcNow(),
        "service": "Google Maps API"
    };
}
```

---

## 📞 **Support and Troubleshooting**

### **Common Issues**:
1. **"API key not valid"** → Check API restrictions
2. **"Quota exceeded"** → Monitor usage in Cloud Console
3. **"Request denied"** → Verify billing is enabled
4. **"ZERO_RESULTS"** → Check address formatting

### **Support Resources**:
- [Google Maps Platform Documentation](https://developers.google.com/maps/documentation)
- [Google Maps Platform Support](https://developers.google.com/maps/support)
- [Stack Overflow - Google Maps](https://stackoverflow.com/questions/tagged/google-maps)

---

**🎯 Ready to integrate? Provide your API keys and I'll help you configure them in the BinBuddy system!**
