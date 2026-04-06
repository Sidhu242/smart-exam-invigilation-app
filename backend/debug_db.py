import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()
DATABASE_URL = os.getenv('DATABASE_URL')

def check_users():
    try:
        conn = psycopg2.connect(DATABASE_URL)
        cur = conn.cursor()
        
        cur.execute("SELECT id, name, role FROM users LIMIT 5")
        users = cur.fetchall()
        print(f"Users in DB: {users}")
        
        # Also check for check constraints
        cur.execute("""
            SELECT conname, pg_get_constraintdef(oid) 
            FROM pg_constraint 
            WHERE conrelid = 'users'::regclass AND contype = 'c';
        """)
        constraints = cur.fetchall()
        print(f"Constraints: {constraints}")

        cur.close()
        conn.close()
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    check_users()
