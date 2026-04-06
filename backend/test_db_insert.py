import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()
DATABASE_URL = os.getenv('DATABASE_URL')

def test_insert_fixed():
    try:
        conn = psycopg2.connect(DATABASE_URL)
        cur = conn.cursor()
        
        # Using CORRECT column names: id, name, password, role, institution
        # 'id' is the primary key provided by the user/application
        cur.execute("""
            INSERT INTO users (id, name, password, role, institution) 
            VALUES ('debug_fixed_1', 'Debug User', 'hashed_pass', 'Student', 'Smart University')
        """)
        conn.commit()
        print("SUCCESS: Direct DB insert with correct columns worked!")
        
        cur.close()
        conn.close()
    except Exception as e:
        print(f"FAILURE: Direct DB insert failed: {e}")

if __name__ == "__main__":
    test_insert_fixed()
