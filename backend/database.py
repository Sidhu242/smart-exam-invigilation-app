import sqlite3

DB_NAME = "exam.db"

def get_connection():
    conn = sqlite3.connect(DB_NAME)
    conn.row_factory = sqlite3.Row
    return conn

# --- STUDENTS ---
def get_student(student_id, password):
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM students WHERE id=? AND password=?", (student_id, password))
    result = cursor.fetchone()
    conn.close()
    return dict(result) if result else None

# --- TEACHERS ---
def get_teacher(teacher_id, password):
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM teachers WHERE id=? AND password=?", (teacher_id, password))
    result = cursor.fetchone()
    conn.close()
    return dict(result) if result else None

# --- EXAMS ---
def get_exams():
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM exams")
    result = cursor.fetchall()
    conn.close()
    return [dict(r) for r in result]

# --- QUESTIONS ---
def get_questions(exam_id, limit=10):
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM questions WHERE exam_id=? ORDER BY RANDOM() LIMIT ?", (exam_id, limit))
    result = cursor.fetchall()
    conn.close()
    return [dict(r) for r in result]

# --- SUBMIT EXAM ---
def save_exam_submission(student_id, exam_id, answers):
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("INSERT INTO submissions(student_id, exam_id, answers) VALUES(?, ?, ?)",
                   (student_id, exam_id, str(answers)))
    conn.commit()
    conn.close()
