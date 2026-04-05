#!/usr/bin/env python3
import psycopg2
import os
from dotenv import load_dotenv

load_dotenv()
DATABASE_URL = os.environ.get("DATABASE_URL")

conn = psycopg2.connect(DATABASE_URL)
c = conn.cursor()

# Delete existing users and recreate
print("\nDeleting existing users...")
c.execute("DELETE FROM users")

# Insert fresh users
print("Inserting fresh users...")
c.execute("INSERT INTO users (id, name, password, role, institution) VALUES (%s, %s, %s, %s, %s)",
          ('s1', 'Alice', 'pass123', 'student', 'Test School'))
c.execute("INSERT INTO users (id, name, password, role, institution) VALUES (%s, %s, %s, %s, %s)",
          ('t1', 'Mr. John', 'pass123', 'teacher', 'Test School'))
conn.commit()

# Verify
c.execute("SELECT id, name, password, role FROM users ORDER BY id")
users = c.fetchall()
print("\nUsers after reset:")
for user in users:
    print(f"  ID: {user[0]}, Name: {user[1]}, Password: {user[2]}, Role: {user[3]}")

conn.close()
print("\n✓ Database reset successful!")
