#!/usr/bin/env python3
import sqlite3
import os

db_path = "exam_system.db"

# Check file modification time
if os.path.exists(db_path):
    stat = os.stat(db_path)
    print(f"Database file last modified: {stat.st_mtime}")
else:
    print("Database file does not exist!")
    exit(1)

conn = sqlite3.connect(db_path)
c = conn.cursor()

# Delete existing users and recreate
print("\nDeleting existing users...")
c.execute("DELETE FROM users")

# Insert fresh users
print("Inserting fresh users...")
c.execute("INSERT INTO users (id, name, password, role, institution) VALUES (?, ?, ?, ?, ?)",
          ('s1', 'Alice', 'pass123', 'student', 'Test School'))
c.execute("INSERT INTO users (id, name, password, role, institution) VALUES (?, ?, ?, ?, ?)",
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
