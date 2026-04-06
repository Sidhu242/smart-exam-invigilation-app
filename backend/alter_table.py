import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()
DATABASE_URL = os.getenv('DATABASE_URL')

def alter_table():
    try:
        print(f"Connecting to: {DATABASE_URL[:20]}...")
        conn = psycopg2.connect(DATABASE_URL)
        cur = conn.cursor()
        
        print("Adding 'email' column to 'users' table...")
        # Add column if it doesn't exist
        cur.execute('''
            ALTER TABLE users 
            ADD COLUMN IF NOT EXISTS email TEXT UNIQUE;
        ''')
        
        conn.commit()
        print("✅ Database migration completed successfully!")
        
    except Exception as e:
        print(f"❌ Error during migration: {e}")
        if conn:
            conn.rollback()
    finally:
        if cur:
            cur.close()
        if conn:
            conn.close()

if __name__ == "__main__":
    alter_table()
