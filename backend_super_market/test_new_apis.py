"""
Quick test script for new API endpoints
Run this after starting the Django server with: python manage.py runserver
"""
import requests
from pprint import pprint

BASE_URL = "http://127.0.0.1:8000/api/v1"

def test_endpoint(name, url, method="GET", data=None):
    """Test an API endpoint"""
    print(f"\n{'='*60}")
    print(f"Testing: {name}")
    print(f"URL: {url}")
    print(f"Method: {method}")
    
    try:
        if method == "GET":
            response = requests.get(url)
        elif method == "POST":
            response = requests.post(url, json=data)
        
        print(f"Status Code: {response.status_code}")
        
        if response.status_code < 400:
            print("✅ Success!")
            if response.content:
                try:
                    pprint(response.json()[:2] if isinstance(response.json(), list) else response.json())
                except Exception:
                    print(response.text[:200])
        else:
            print("❌ Failed!")
            print(response.text[:500])
            
    except Exception as e:
        print(f"❌ Error: {str(e)}")

def main():
    print("="*60)
    print("Testing New API Endpoints")
    print("="*60)
    
    # Test Smart Pricing APIs
    test_endpoint("Smart Pricing - List Pricing Rules", f"{BASE_URL}/smart-pricing/pricing-rules/")
    test_endpoint("Smart Pricing - List Dynamic Prices", f"{BASE_URL}/smart-pricing/dynamic-prices/")
    test_endpoint("Smart Pricing - Price History", f"{BASE_URL}/smart-pricing/price-history/")
    test_endpoint("Smart Pricing - Competitor Prices", f"{BASE_URL}/smart-pricing/competitor-prices/")
    test_endpoint("Smart Pricing - Price Elasticity", f"{BASE_URL}/smart-pricing/price-elasticity/")
    
    # Test IoT APIs
    test_endpoint("IoT - List Devices", f"{BASE_URL}/iot-devices/")
    test_endpoint("IoT - Sensor Readings", f"{BASE_URL}/iot-devices/sensor-readings/")
    test_endpoint("IoT - Temperature Monitoring", f"{BASE_URL}/iot-devices/temperature-monitoring/")
    test_endpoint("IoT - Smart Shelf Events", f"{BASE_URL}/iot-devices/smart-shelf-events/")
    test_endpoint("IoT - Traffic Analytics", f"{BASE_URL}/iot-devices/traffic-analytics/")
    test_endpoint("IoT - Alerts", f"{BASE_URL}/iot-devices/alerts/")
    
    # Test Supplier APIs
    test_endpoint("Suppliers - Enhanced Suppliers", f"{BASE_URL}/enhanced-suppliers/")
    test_endpoint("Suppliers - Performance", f"{BASE_URL}/enhanced-supplier-performance/")
    test_endpoint("Suppliers - Contracts", f"{BASE_URL}/enhanced-supplier-contracts/")
    test_endpoint("Suppliers - Automated Reorders", f"{BASE_URL}/automated-reorders/")
    test_endpoint("Suppliers - Communications", f"{BASE_URL}/supplier-communications/")
    test_endpoint("Suppliers - Reviews", f"{BASE_URL}/supplier-reviews/")
    
    # Test Sustainability APIs
    test_endpoint("Sustainability - Metrics", f"{BASE_URL}/sustainability-metrics/")
    test_endpoint("Sustainability - Carbon Footprint", f"{BASE_URL}/product-carbon-footprint/")
    test_endpoint("Sustainability - Waste Records", f"{BASE_URL}/waste-records/")
    test_endpoint("Sustainability - Initiatives", f"{BASE_URL}/sustainability-initiatives/")
    test_endpoint("Sustainability - Green Suppliers", f"{BASE_URL}/green-supplier-ratings/")
    
    print("\n" + "="*60)
    print("Testing Complete!")
    print("="*60)

if __name__ == "__main__":
    main()
