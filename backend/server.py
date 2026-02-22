import sqlite3
import json
import os
from flask import Flask, request, jsonify
from flask_cors import CORS
from datetime import datetime, timedelta
import base64
import numpy as np
import cv2

# Initialize Flask app
app = Flask(__name__)
CORS(app, resources={r"/*": {"origins": "*"}})

# Database
DATABASE = 'exam_system.db'

# =====================================================
# DATABASE INITIALIZATION
# =====================================================

def init_db():
    """Initialize SQLite database with required tables"""
    conn = sqlite3.connect(DATABASE)
    c = conn.cursor()
    
    # Users table
    c.execute('''
        CREATE TABLE IF NOT EXISTS users (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            password TEXT NOT NULL,
            role TEXT NOT NULL,
            institution TEXT NOT NULL,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    # Exams table
    c.execute('''
        CREATE TABLE IF NOT EXISTS exams (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            exam_datetime TEXT,
            institution TEXT NOT NULL,
            published INTEGER DEFAULT 0,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    # Questions table
    c.execute('''
        CREATE TABLE IF NOT EXISTS questions (
            id TEXT PRIMARY KEY,
            exam_id TEXT NOT NULL,
            question_text TEXT NOT NULL,
            question_type TEXT NOT NULL,
            options TEXT,
            correct_answer TEXT,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (exam_id) REFERENCES exams(id)
        )
    ''')
    
    # Student Answers table
    c.execute('''
        CREATE TABLE IF NOT EXISTS student_answers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            student_id TEXT NOT NULL,
            exam_id TEXT NOT NULL,
            question_id TEXT NOT NULL,
            answer_text TEXT,
            submitted_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            UNIQUE(student_id, exam_id, question_id)
        )
    ''')
    
    # Warnings/Violations table
    c.execute('''
        CREATE TABLE IF NOT EXISTS warnings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            student_id TEXT NOT NULL,
            exam_id TEXT NOT NULL,
            message TEXT NOT NULL,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    # Exam Results table
    c.execute('''
        CREATE TABLE IF NOT EXISTS exam_results (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            student_id TEXT NOT NULL,
            exam_id TEXT NOT NULL,
            score REAL,
            total_questions INTEGER,
            correct_answers INTEGER,
            submitted_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    conn.commit()
    conn.close()

# Call init before first request
init_db()

# =====================================================
# AUTHENTICATION ROUTES
# =====================================================

@app.route('/login', methods=['POST'])
def login():
    """User login"""
    try:
        data = request.get_json()
        if not data:
            return jsonify({'status': 'error', 'message': 'Invalid JSON'}), 400
        
        user_id = data.get('id', '').strip()
        password = data.get('password', '').strip()
        
        if not user_id or not password:
            return jsonify({'status': 'error', 'message': 'ID and password required'}), 400
        
        conn = sqlite3.connect(DATABASE)
        conn.row_factory = sqlite3.Row
        c = conn.cursor()
        
        c.execute(
            'SELECT id, name, role, institution FROM users WHERE id = ? AND password = ?',
            (user_id, password)
        )
        user = c.fetchone()
        conn.close()
        
        if user:
            return jsonify({
                'status': 'success',
                'id': user['id'],
                'name': user['name'],
                'role': user['role'],
                'institution': user['institution']
            }), 200
        else:
            return jsonify({'status': 'error', 'message': 'Invalid credentials'}), 401
            
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500

@app.route('/signup', methods=['POST'])
def signup():
    """User registration"""
    try:
        data = request.get_json()
        if not data:
            return jsonify({'status': 'error', 'message': 'Invalid JSON'}), 400
        
        user_id = data.get('id', '').strip()
        name = data.get('name', '').strip()
        password = data.get('password', '').strip()
        role = data.get('role', '').strip()
        institution = data.get('institution', '').strip()
        
        if not all([user_id, name, password, role, institution]):
            return jsonify({'status': 'error', 'message': 'All fields required'}), 400
        
        conn = sqlite3.connect(DATABASE)
        c = conn.cursor()
        
        try:
            c.execute(
                'INSERT INTO users (id, name, password, role, institution) VALUES (?, ?, ?, ?, ?)',
                (user_id, name, password, role, institution)
            )
            conn.commit()
            return jsonify({'status': 'success', 'message': 'Account created'}), 201
        except sqlite3.IntegrityError:
            return jsonify({'status': 'error', 'message': 'User already exists'}), 409
        finally:
            conn.close()
            
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500

# =====================================================
# EXAM ROUTES
# =====================================================

@app.route('/create_exam', methods=['POST'])
def create_exam():
    """Create new exam"""
    try:
        data = request.get_json()
        exam_id = data.get('id')
        name = data.get('name')
        exam_datetime = data.get('exam_datetime')
        institution = data.get('institution')
        
        if not all([exam_id, name, institution]):
            return jsonify({'status': 'error', 'message': 'Missing fields'}), 400
        
        conn = sqlite3.connect(DATABASE)
        c = conn.cursor()
        
        try:
            c.execute(
                'INSERT INTO exams (id, name, exam_datetime, institution) VALUES (?, ?, ?, ?)',
                (exam_id, name, exam_datetime, institution)
            )
            conn.commit()
            return jsonify({'status': 'success', 'message': 'Exam created'}), 201
        except sqlite3.IntegrityError:
            return jsonify({'status': 'error', 'message': 'Exam ID exists'}), 409
        finally:
            conn.close()
            
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500

@app.route('/get_exams', methods=['GET'])
def get_exams():
    """Get all exams (published ones for students)"""
    try:
        institution = request.args.get('institution', '')
        published = request.args.get('published', '1')
        
        conn = sqlite3.connect(DATABASE)
        conn.row_factory = sqlite3.Row
        c = conn.cursor()
        
        c.execute(
            'SELECT * FROM exams WHERE institution = ? AND published = ?',
            (institution, int(published))
        )
        exams = [dict(row) for row in c.fetchall()]
        conn.close()
        
        return jsonify({'status': 'success', 'exams': exams}), 200
        
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500

@app.route('/publish_exam', methods=['POST'])
def publish_exam():
    """Publish exam"""
    try:
        data = request.get_json()
        exam_id = data.get('exam_id')
        
        conn = sqlite3.connect(DATABASE)
        c = conn.cursor()
        c.execute('UPDATE exams SET published = 1 WHERE id = ?', (exam_id,))
        conn.commit()
        conn.close()
        
        return jsonify({'status': 'success', 'message': 'Exam published'}), 200
        
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500

@app.route('/delete_exam/<exam_id>', methods=['DELETE'])
def delete_exam(exam_id):
    """Delete exam"""
    try:
        conn = sqlite3.connect(DATABASE)
        c = conn.cursor()
        c.execute('DELETE FROM exams WHERE id = ?', (exam_id,))
        conn.commit()
        conn.close()
        
        return jsonify({'status': 'success', 'message': 'Exam deleted'}), 200
        
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500

# =====================================================
# QUESTION ROUTES
# =====================================================

@app.route('/add_question', methods=['POST'])
def add_question():
    """Add question to exam"""
    try:
        data = request.get_json()
        if not data:
            return jsonify({'status': 'error', 'message': 'Invalid JSON'}), 400
        
        q_id = data.get('id')
        exam_id = data.get('exam_id')
        question_text = data.get('question_text')
        question_type = data.get('question_type')
        
        if not all([q_id, exam_id, question_text, question_type]):
            return jsonify({'status': 'error', 'message': 'Missing fields'}), 400
        
        conn = sqlite3.connect(DATABASE)
        c = conn.cursor()
        
        try:
            if question_type == 'mcq':
                options = data.get('options')
                correct_answer = data.get('correct_answer')
                if not options or not correct_answer:
                    return jsonify({'status': 'error', 'message': 'MCQ requires options'}), 400
                
                c.execute(
                    'INSERT INTO questions (id, exam_id, question_text, question_type, options, correct_answer) VALUES (?, ?, ?, ?, ?, ?)',
                    (q_id, exam_id, question_text, 'mcq', json.dumps(options), correct_answer)
                )
            else:
                c.execute(
                    'INSERT INTO questions (id, exam_id, question_text, question_type) VALUES (?, ?, ?, ?)',
                    (q_id, exam_id, question_text, 'essay')
                )
            
            conn.commit()
            return jsonify({'status': 'success', 'message': 'Question added'}), 201
            
        except sqlite3.IntegrityError:
            return jsonify({'status': 'error', 'message': 'Question ID exists'}), 409
        finally:
            conn.close()
            
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500

@app.route('/get_questions/<exam_id>', methods=['GET'])
def get_questions(exam_id):
    """Get all questions for exam"""
    try:
        conn = sqlite3.connect(DATABASE)
        conn.row_factory = sqlite3.Row
        c = conn.cursor()
        
        c.execute('SELECT * FROM questions WHERE exam_id = ?', (exam_id,))
        questions = []
        
        for row in c.fetchall():
            q = dict(row)
            if q['options']:
                try:
                    q['options'] = json.loads(q['options'])
                except:
                    q['options'] = []
            questions.append(q)
        
        conn.close()
        return jsonify({'status': 'success', 'questions': questions}), 200
        
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500

# =====================================================
# ANSWER SUBMISSION ROUTES
# =====================================================

@app.route('/submit_answer', methods=['POST'])
def submit_answer():
    """Submit a single answer"""
    try:
        data = request.get_json()
        student_id = data.get('student_id')
        exam_id = data.get('exam_id')
        question_id = data.get('question_id')
        answer_text = data.get('answer_text')
        
        if not all([student_id, exam_id, question_id]):
            return jsonify({'status': 'error', 'message': 'Missing fields'}), 400
        
        conn = sqlite3.connect(DATABASE)
        c = conn.cursor()
        
        c.execute(
            'INSERT OR REPLACE INTO student_answers (student_id, exam_id, question_id, answer_text) VALUES (?, ?, ?, ?)',
            (student_id, exam_id, question_id, answer_text)
        )
        conn.commit()
        conn.close()
        
        return jsonify({'status': 'success', 'message': 'Answer saved'}), 200
        
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500

@app.route('/submit_exam', methods=['POST'])
def submit_exam():
    """Submit entire exam"""
    try:
        data = request.get_json()
        student_id = data.get('student_id')
        exam_id = data.get('exam_id')
        answers = data.get('answers', {})
        
        if not student_id or not exam_id:
            return jsonify({'status': 'error', 'message': 'Missing student or exam ID'}), 400
        
        conn = sqlite3.connect(DATABASE)
        conn.row_factory = sqlite3.Row
        c = conn.cursor()
        
        # Get all questions
        c.execute('SELECT * FROM questions WHERE exam_id = ?', (exam_id,))
        questions = c.fetchall()
        
        total = len(questions)
        correct = 0
        
        # Check answers
        for q in questions:
            q_id = q['id']
            correct_ans = q['correct_answer']
            student_ans = answers.get(q_id, '').strip()
            
            if q['question_type'] == 'mcq' and correct_ans:
                if student_ans == correct_ans:
                    correct += 1
        
        score = (correct / total * 100) if total > 0 else 0
        
        # Save result
        c.execute(
            'INSERT INTO exam_results (student_id, exam_id, score, total_questions, correct_answers) VALUES (?, ?, ?, ?, ?)',
            (student_id, exam_id, score, total, correct)
        )
        conn.commit()
        conn.close()
        
        return jsonify({
            'status': 'success',
            'message': 'Exam submitted',
            'score': score,
            'correct_answers': correct,
            'total_questions': total
        }), 200
        
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500

# =====================================================
# INVIGILATION ROUTES
# =====================================================

@app.route('/log_tab_switch', methods=['POST'])
def log_tab_switch():
    """Log app/tab switch"""
    try:
        data = request.get_json()
        student_id = data.get('student_id')
        exam_id = data.get('exam_id')
        
        conn = sqlite3.connect(DATABASE)
        c = conn.cursor()
        c.execute(
            'INSERT INTO warnings (student_id, exam_id, message) VALUES (?, ?, ?)',
            (student_id, exam_id, 'Tab/App switch detected')
        )
        conn.commit()
        conn.close()
        
        return jsonify({'status': 'success'}), 200
        
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500

@app.route('/get_warnings/<exam_id>', methods=['GET'])
def get_warnings(exam_id):
    """Get warnings for exam"""
    try:
        student_id = request.args.get('student_id')
        
        conn = sqlite3.connect(DATABASE)
        conn.row_factory = sqlite3.Row
        c = conn.cursor()
        
        if student_id:
            c.execute(
                'SELECT * FROM warnings WHERE exam_id = ? AND student_id = ?',
                (exam_id, student_id)
            )
        else:
            c.execute('SELECT * FROM warnings WHERE exam_id = ?', (exam_id,))
        
        warnings = [dict(row) for row in c.fetchall()]
        conn.close()
        
        return jsonify({'status': 'success', 'warnings': warnings}), 200
        
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500

# =====================================================
# RESULTS ROUTES
# =====================================================

@app.route('/get_exam_results/<exam_id>', methods=['GET'])
def get_exam_results(exam_id):
    """Get results for exam"""
    try:
        conn = sqlite3.connect(DATABASE)
        conn.row_factory = sqlite3.Row
        c = conn.cursor()
        
        c.execute(
            'SELECT * FROM exam_results WHERE exam_id = ? ORDER BY submitted_at DESC',
            (exam_id,)
        )
        results = [dict(row) for row in c.fetchall()]
        conn.close()
        
        return jsonify({'status': 'success', 'results': results}), 200
        
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500

@app.route('/get_summary/<student_id>', methods=['GET'])
def get_summary(student_id):
    """Get student performance summary"""
    try:
        conn = sqlite3.connect(DATABASE)
        conn.row_factory = sqlite3.Row
        c = conn.cursor()
        
        # Get user info
        c.execute('SELECT institution FROM users WHERE id = ?', (student_id,))
        user = c.fetchone()
        
        if not user:
            return jsonify({'status': 'error', 'message': 'User not found'}), 404
        
        institution = user['institution']
        
        # Completed exams
        c.execute(
            'SELECT COUNT(DISTINCT exam_id) as count FROM exam_results WHERE student_id = ?',
            (student_id,)
        )
        completed = c.fetchone()['count'] or 0
        
        # Warnings
        c.execute(
            'SELECT COUNT(*) as count FROM warnings WHERE student_id = ?',
            (student_id,)
        )
        warnings = c.fetchone()['count'] or 0
        
        # Accuracy
        c.execute(
            'SELECT AVG(score) as avg_score FROM exam_results WHERE student_id = ?',
            (student_id,)
        )
        accuracy = c.fetchone()['avg_score']
        
        # Upcoming exams
        c.execute(
            'SELECT id, name, exam_datetime FROM exams WHERE institution = ? AND exam_datetime IS NOT NULL AND published = 1 ORDER BY exam_datetime ASC',
            (institution,)
        )
        exams = c.fetchall()
        upcoming_text = "No upcoming exams"
        
        if exams:
            for e in exams:
                try:
                    dt = datetime.strptime(e['exam_datetime'], '%Y-%m-%d %H:%M')
                    if dt > datetime.now():
                        upcoming_text = f"{e['name']} - {e['exam_datetime']}"
                        break
                except:
                    pass
        
        conn.close()
        
        return jsonify({
            'status': 'success',
            'summary': {
                'completed_exams': completed,
                'warnings': warnings,
                'accuracy': round(accuracy) if accuracy else None,
                'upcoming': upcoming_text
            }
        }), 200
        
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500

# =====================================================
# ERROR HANDLER
# =====================================================

@app.errorhandler(404)
def not_found(e):
    return jsonify({'status': 'error', 'message': 'Endpoint not found'}), 404

@app.errorhandler(500)
def server_error(e):
    return jsonify({'status': 'error', 'message': 'Internal server error'}), 500

# =====================================================
# RUN
# =====================================================

if __name__ == '__main__':
    app.run(host='127.0.0.1', port=5000, debug=True)