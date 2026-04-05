import psycopg2
import os
from dotenv import load_dotenv

load_dotenv()
DATABASE_URL = os.environ.get("DATABASE_URL")

def reset_all_data():
    conn = psycopg2.connect(DATABASE_URL)
    c = conn.cursor()

    print("Resetting all exam data...")
    
    # Tables to clear
    tables = ['exams', 'questions', 'student_answers', 'warnings', 'exam_results', 'violations']
    
    for table in tables:
        try:
            c.execute(f"DELETE FROM {table} CASCADE")
            print(f"  - Cleared table: {table}")
        except Exception as e:
            conn.rollback()
            print(f"  - skip: {table} (not found or error: {e})")

    conn.commit()
    conn.close()
    print("\n✓ Database exam data cleared successfully!")

if __name__ == '__main__':
    reset_all_data()
