#!/usr/bin/env python3
import sqlite3

# Test the database connection and schema
db_path = "exam_system.db"

try:
    conn = sqlite3.connect(db_path)
    c = conn.cursor()
    
    # Check users table schema
    c.execute("PRAGMA table_info(users)")
    users_columns = c.fetchall()
    print("Users table columns:")
    for col in users_columns:
        print(f"  - {col[1]} ({col[2]})")
    
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
