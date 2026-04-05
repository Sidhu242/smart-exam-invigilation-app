import psycopg2
from psycopg2.extras import RealDictCursor
import os
from dotenv import load_dotenv

load_dotenv()
DATABASE_URL = os.environ.get("DATABASE_URL")

def get_connection():
    conn = psycopg2.connect(DATABASE_URL)
    return conn

# --- STUDENTS ---
def get_student(student_id, password):
    conn = get_connection()
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    cursor.execute("SELECT * FROM students WHERE id=%s AND password=%s", (student_id, password))
    result = cursor.fetchone()
    conn.close()
    return dict(result) if result else None

# --- TEACHERS ---
def get_teacher(teacher_id, password):
    conn = get_connection()
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    cursor.execute("SELECT * FROM teachers WHERE id=%s AND password=%s", (teacher_id, password))
    result = cursor.fetchone()
    conn.close()
    return dict(result) if result else None

# --- EXAMS ---
def get_exams():
    conn = get_connection()
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    cursor.execute("SELECT * FROM exams")
    result = cursor.fetchall()
    conn.close()
    return [dict(r) for r in result]

# --- QUESTIONS ---
def get_questions(exam_id, limit=10):
    conn = get_connection()
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    cursor.execute("SELECT * FROM questions WHERE exam_id=%s ORDER BY RANDOM() LIMIT %s", (exam_id, limit))
    result = cursor.fetchall()
    conn.close()
    return [dict(r) for r in result]

# --- SUBMIT EXAM ---
def save_exam_submission(student_id, exam_id, answers):
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("INSERT INTO submissions(student_id, exam_id, answers) VALUES(%s, %s, %s)",
                   (student_id, exam_id, str(answers)))
    conn.commit()
    conn.close()
