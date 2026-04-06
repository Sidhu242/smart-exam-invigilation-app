import os
import psycopg2
from dotenv import load_dotenv

# Load variables from .env
load_dotenv()

DATABASE_URL = os.getenv('DATABASE_URL')
if not DATABASE_URL:
    raise RuntimeError('DATABASE_URL not set in environment')

def setup_database():
    try:
        print(f"Connecting to: {DATABASE_URL[:20]}...")
        conn = psycopg2.connect(DATABASE_URL)
        cur = conn.cursor()
        
        # Step 1: Enable pgcrypto for gen_random_uuid()
        print("Enabling pgcrypto extension...")
        cur.execute('CREATE EXTENSION IF NOT EXISTS "pgcrypto";')
        
        # Step 2: Drop existing users table
        print("Dropping existing users table...")
        cur.execute('DROP TABLE IF EXISTS users CASCADE;')
        
        # Step 3: Create the new users table with the CORRECT schema
        print("Creating new users table with correct columns...")
        cur.execute('''
            CREATE TABLE users (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              password TEXT NOT NULL,
              role TEXT NOT NULL CHECK (role IN (
                'Student', 'Teacher', 'Administrator', 'Researcher'
              )),
              institution TEXT NOT NULL,
              created_at TIMESTAMP DEFAULT NOW()
            );
        ''')
        
        conn.commit()
        print("✅ Database setup completed successfully!")
        
    except Exception as e:
        print(f"❌ Error setting up database: {e}")
        if conn:
            conn.rollback()
    finally:
        if cur:
            cur.close()
        if conn:
            conn.close()

if __name__ == "__main__":
    setup_database()
