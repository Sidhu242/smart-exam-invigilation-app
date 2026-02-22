#!/usr/bin/env python3
import sqlite3

db_path = "exam_system.db"

conn = sqlite3.connect(db_path)
conn.row_factory = sqlite3.Row
c = conn.cursor()

# Test the exact query from server.py
c.execute(
    'SELECT id, name, role, institution FROM users WHERE id = ? AND password = ?',
    ('t1', 'pass123')
)
user = c.fetchone()
conn.close()

if user:
    print("✓ Teacher query returned a result!")
    print(f"  User data: {dict(user)}")
else:
    print("✗ Teacher query returned no results")
    
    # Debug: Check with just ID
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    c = conn.cursor()
    c.execute('SELECT id, name, password, role FROM users WHERE id = ?', ('t1',))
    debug_user = c.fetchone()
    conn.close()
    
    if debug_user:
        print(f"  Found user with ID t1: {dict(debug_user)}")
    else:
        print("  No user found with ID t1")
