#!/usr/bin/env python3
import psycopg2
import os
from dotenv import load_dotenv

load_dotenv()
DATABASE_URL = os.environ.get("DATABASE_URL")

# Test the database connection and schema
try:
    conn = psycopg2.connect(DATABASE_URL)
    c = conn.cursor()
    
    # Check users table schema
    c.execute("SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'users'")
    users_columns = c.fetchall()
    print("Users table columns:")
    for col in users_columns:
        print(f"  - {col[0]} ({col[1]})")
    
    # Check if dummy users exist
    c.execute("SELECT id, name, role, institution FROM users")
    users = c.fetchall()
    print(f"\nUsers in database: {len(users)}")
    for user in users:
        print(f"  - {user}")
    
    conn.close()
    print("\n✓ Database is properly configured!")
    
except Exception as e:
    print(f"✗ Error: {e}")
