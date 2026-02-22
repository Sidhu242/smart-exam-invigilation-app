#!/usr/bin/env python3
import urllib.request
import urllib.error
import json

# Test the login endpoint
url = "http://localhost:5000/login"

# Test with valid credentials
test_data = {
    "id": "s1",
    "password": "pass123"
}

try:
    req = urllib.request.Request(url, 
                                data=json.dumps(test_data).encode('utf-8'),
                                headers={'Content-Type': 'application/json'})
    with urllib.request.urlopen(req, timeout=5) as response:
        status_code = response.status
        response_data = json.loads(response.read().decode('utf-8'))
        print(f"Status Code: {status_code}")
        print(f"Response: {json.dumps(response_data, indent=2)}")
        
        if status_code == 200:
            print("\n✓ Login endpoint is working!")
        
except urllib.error.HTTPError as e:
    print(f"Status Code: {e.code}")
    response_data = json.loads(e.read().decode('utf-8'))
    print(f"Response: {json.dumps(response_data, indent=2)}")
    
except Exception as e:
    print(f"✗ Error: {e}")
