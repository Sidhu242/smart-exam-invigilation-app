#!/usr/bin/env python3
import sqlite3

db_path = "exam_system.db"

try:
    conn = sqlite3.connect(db_path)
    c = conn.cursor()
    
    # Check all users with passwords
    c.execute("SELECT id, name, password, role FROM users")
    users = c.fetchall()
    print("Users in database:")
    for user in users:
        print(f"  ID: {user[0]}, Name: {user[1]}, Password: {user[2]}, Role: {user[3]}")
    
    conn.close()
    
except Exception as e:
    print(f"Error: {e}")
