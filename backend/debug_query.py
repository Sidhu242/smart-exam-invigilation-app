#!/usr/bin/env python3
import psycopg2
from psycopg2.extras import RealDictCursor
import os
from dotenv import load_dotenv

load_dotenv()
DATABASE_URL = os.environ.get("DATABASE_URL")

conn = psycopg2.connect(DATABASE_URL)
conn.autocommit = True
c = conn.cursor(cursor_factory=RealDictCursor)

# Test the exact query from server.py
c.execute(
    'SELECT id, name, role, institution FROM users WHERE id = %s AND password = %s',
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
    conn = psycopg2.connect(DATABASE_URL)
    c = conn.cursor(cursor_factory=RealDictCursor)
    c.execute('SELECT id, name, password, role FROM users WHERE id = %s', ('t1',))
    debug_user = c.fetchone()
    conn.close()
    
    if debug_user:
        print(f"  Found user with ID t1: {dict(debug_user)}")
    else:
        print("  No user found with ID t1")
