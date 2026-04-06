import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()
DATABASE_URL = os.getenv('DATABASE_URL')

def check_roles_precise():
    try:
        conn = psycopg2.connect(DATABASE_URL)
        cur = conn.cursor()
        
        cur.execute("SELECT DISTINCT role, length(role), ascii(left(role,1)) FROM users")
        roles = cur.fetchall()
        print(f"ROLES PRECISE: {roles}")
        
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    check_roles_precise()
