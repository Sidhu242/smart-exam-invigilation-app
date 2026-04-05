#!/usr/bin/env python3
import psycopg2
from psycopg2.extras import RealDictCursor
import urllib.request
import urllib.error
import json
import sys
import time
import os
from dotenv import load_dotenv

load_dotenv()
DATABASE_URL = os.environ.get("DATABASE_URL")

print("="*50)
print("COMPREHENSIVE LOGIN TEST")
print("="*50)

# Step 1: Verify database
print("\n[1] Checking database...")
conn = psycopg2.connect(DATABASE_URL)
c = conn.cursor(cursor_factory=RealDictCursor)

c.execute("SELECT id, password, role FROM users WHERE id IN ('s1', 't1') ORDER BY id")
users = c.fetchall()
print(f"  Found {len(users)} users")
for user in users:
    print(f"    - {user['id']}: role={user['role']}, password={user['password']}")
conn.close()

# Step 2: Test SQL query directly
print("\n[2] Testing SQL query directly...")
try:
    conn = psycopg2.connect(DATABASE_URL)
    c = conn.cursor(cursor_factory=RealDictCursor)
    
    # Try both students
    for user_id in ['s1', 't1']:
        c.execute("SELECT id, name, role FROM users WHERE id = %s AND password = %s", (user_id, 'pass123'))
        result = c.fetchone()
        if result:
            print(f"  ✓ Direct query for {user_id}: SUCCESS - {dict(result)}")
        else:
            print(f"  ✗ Direct query for {user_id}: NO RESULT")
    conn.close()
except Exception as e:
    print(f"  ✗ Error: {e}")

# Step 3: Test via HTTP
print("\n[3] Testing via HTTP endpoints...")
url = "http://localhost:5000/login"

for user_id in ['s1', 't1']:
    test_data = {"id": user_id, "password": "pass123"}
    try:
        req = urllib.request.Request(url, 
                                    data=json.dumps(test_data).encode('utf-8'),
                                    headers={'Content-Type': 'application/json'})
        with urllib.request.urlopen(req, timeout=5) as response:
            status_code = response.status
            response_data = json.loads(response.read().decode('utf-8'))
            print(f"  ✓ {user_id}: HTTP {status_code} - SUCCESS")
    except urllib.error.HTTPError as e:
        response_data = json.loads(e.read().decode('utf-8'))
        print(f"  ✗ {user_id}: HTTP {e.code} - {response_data['message']}")
    except Exception as e:
        print(f"  ✗ {user_id}: ERROR - {str(e)}")

print("\n" + "="*50)
