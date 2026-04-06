import requests

# Updated URL to match server.py routes
API_URL = "http://localhost:7860" 

def test_signup():
    print("Testing Signup...")
    # Updated payload to use correct fields: id, name, password, role, institution
    payload = {
        "id": "test_user_001",
        "name": "Test Student",
        "password": "Password123!",
        "role": "Student",
        "institution": "Jain University"
    }
    response = requests.post(f"{API_URL}/signup", json=payload)
    print(f"Status: {response.status_code}")
    print(f"Body: {response.json()}")
    if response.status_code == 201:
        return payload['id']
    return None

def test_login(user_id):
    print(f"Testing Login with {user_id}...")
    # Updated payload to use correct field: id
    payload = {
        "id": user_id,
        "password": "Password123!"
    }
    response = requests.post(f"{API_URL}/login", json=payload)
    print(f"Status: {response.status_code}")
    print(f"Body: {response.json()}")

if __name__ == "__main__":
    user_id = test_signup()
    if user_id:
        test_login(user_id)
