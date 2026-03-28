import sqlite3
import os

DATABASE = 'exam_system.db'

def reset_all_data():
    if not os.path.exists(DATABASE):
        print(f"Error: {DATABASE} not found.")
        return

    conn = sqlite3.connect(DATABASE)
    c = conn.cursor()

    print("Resetting all exam data...")
    
    # Tables to clear
    tables = ['exams', 'questions', 'student_answers', 'warnings', 'exam_results']
    
    for table in tables:
        try:
            c.execute(f"DELETE FROM {table}")
            print(f"  - Cleared table: {table}")
        except sqlite3.OperationalError as e:
            print(f"  - skip: {table} (not found or error: {e})")

    conn.commit()
    conn.close()
    print("\n✓ Database exam data cleared successfully!")

if __name__ == '__main__':
    reset_all_data()
