import psycopg2
import os
from dotenv import load_dotenv

load_dotenv()
DATABASE_URL = os.environ.get("DATABASE_URL")

conn = psycopg2.connect(DATABASE_URL)
c = conn.cursor()

# Users table
c.execute("""
CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    password TEXT NOT NULL,
    role TEXT NOT NULL,
    institution TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)
""")

# Exams table
c.execute("""
CREATE TABLE IF NOT EXISTS exams (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    exam_datetime TEXT,
    institution TEXT NOT NULL,
    published INTEGER DEFAULT 0,
    status TEXT DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)
""")

# Questions table
c.execute("""
CREATE TABLE IF NOT EXISTS questions (
    id TEXT PRIMARY KEY,
    exam_id TEXT NOT NULL,
    question_text TEXT NOT NULL,
    question_type TEXT NOT NULL,
    options TEXT,
    correct_answer TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (exam_id) REFERENCES exams(id)
)
""")

# Student Answers table
c.execute("""
CREATE TABLE IF NOT EXISTS student_answers (
    id SERIAL PRIMARY KEY,
    student_id TEXT NOT NULL,
    exam_id TEXT NOT NULL,
    question_id TEXT NOT NULL,
    answer_text TEXT,
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(student_id, exam_id, question_id)
)
""")

# Warnings table
c.execute("""
CREATE TABLE IF NOT EXISTS warnings (
    id SERIAL PRIMARY KEY,
    student_id TEXT NOT NULL,
    exam_id TEXT NOT NULL,
    message TEXT NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)
""")

# Exam Results table
c.execute("""
CREATE TABLE IF NOT EXISTS exam_results (
    id SERIAL PRIMARY KEY,
    student_id TEXT NOT NULL,
    exam_id TEXT NOT NULL,
    score REAL,
    total_questions INTEGER,
    correct_answers INTEGER,
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)
""")


def create_violation_table():
    vconn = psycopg2.connect(DATABASE_URL)
    vcursor = vconn.cursor()

    vcursor.execute("""
    CREATE TABLE IF NOT EXISTS violations (
        id SERIAL PRIMARY KEY,
        student_id TEXT NOT NULL,
        exam_id TEXT NOT NULL,
        violation_type TEXT NOT NULL,
        confidence REAL DEFAULT 1.0,
        screenshot TEXT,
        timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
    """)
    vconn.commit()
    vconn.close()
   

# Dummy users
c.execute("INSERT INTO users (id, name, password, role, institution) VALUES ('s1','Alice','pass123','student','Test School') ON CONFLICT DO NOTHING")
c.execute("INSERT INTO users (id, name, password, role, institution) VALUES ('t1','Mr. John','pass123','teacher','Test School') ON CONFLICT DO NOTHING")

# Dummy exams
c.execute("INSERT INTO exams (id, name, exam_datetime, institution, published) VALUES ('e1','Math Exam','2026-02-16 10:00:00','Test School',1) ON CONFLICT DO NOTHING")

# Dummy questions
c.execute("""
INSERT INTO questions (id, exam_id, question_text, question_type, options, correct_answer) VALUES 
('q1','e1','2 + 2 = ?','mcq','["2","3","4","5"]','4'),
('q2','e1','3 * 3 = ?','mcq','["6","9","12","8"]','9')
ON CONFLICT DO NOTHING
""")

conn.commit()
conn.close()
print("Database created and initialized!")

create_violation_table()