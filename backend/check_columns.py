import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()
DATABASE_URL = os.getenv('DATABASE_URL')

def check_columns():
    conn = psycopg2.connect(DATABASE_URL)
    cur = conn.cursor()
    cur.execute("SELECT column_name FROM information_schema.columns WHERE table_name = 'users'")
    columns = [row[0] for row in cur.fetchall()]
    print(f"Columns in 'users' table: {columns}")
    cur.close()
    conn.close()

if __name__ == "__main__":
    check_columns()
