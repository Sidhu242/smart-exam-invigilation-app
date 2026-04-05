import psycopg2
from psycopg2.extras import RealDictCursor
import json
import os
from dotenv import load_dotenv
from flask import Flask, request, jsonify
from flask_cors import CORS
from datetime import datetime, timedelta
import base64
import numpy as np
import cv2

from flask_sock import Sock

load_dotenv()
DATABASE_URL = os.environ.get("DATABASE_URL")

# Initialize Flask app
app = Flask(__name__)
CORS(app, resources={r"/*": {"origins": "*"}})
sock = Sock(app)

live_flags = {} # {exam_id: set(teacher_sockets)}
live_monitors = {} # {exam_id: set(teacher_sockets)}

@sock.route('/ws/flags/<exam_id>')
def flags_websocket(ws, exam_id):
    if exam_id not in live_flags:
        live_flags[exam_id] = set()
    live_flags[exam_id].add(ws)
    try:
        while True:
            msg = ws.receive()
    except Exception:
        pass
    finally:
        live_flags[exam_id].remove(ws)
        if not live_flags[exam_id]:
            del live_flags[exam_id]

@sock.route('/ws/live_monitor/<exam_id>')
def live_monitor_websocket(ws, exam_id):
    if exam_id not in live_monitors:
        live_monitors[exam_id] = set()
    live_monitors[exam_id].add(ws)
    try:
        while True:
            msg = ws.receive()
    except Exception:
        pass
    finally:
        live_monitors[exam_id].remove(ws)
        if not live_monitors[exam_id]:
            del live_monitors[exam_id]

@sock.route('/ws/student_feed/<exam_id>/<student_id>')
def student_feed_websocket(ws, exam_id, student_id):
    try:
        while True:
            frame_data = ws.receive()
            if frame_data and exam_id in live_monitors:
                # Payload: {student_id, student_name, frame (base64)}
                # For brevity, we just relay what student sends
                dead_sockets = set()
                for monitor_ws in live_monitors[exam_id]:
                    try:
                        monitor_ws.send(frame_data)
                    except Exception:
                        dead_sockets.add(monitor_ws)
                
                for dead in dead_sockets:
                    live_monitors[exam_id].discard(dead)
    except Exception:
        pass

# Database Helper
def get_db_connection():
    return psycopg2.connect(DATABASE_URL)

# =====================================================
# DATABASE INITIALIZATION
# =====================================================

def init_db():
    """Initialize PostgreSQL database with required tables"""
    conn = get_db_connection()
    c = conn.cursor()
    
    # Users table
    c.execute('''
        CREATE TABLE IF NOT EXISTS users (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            password TEXT NOT NULL,
            role TEXT NOT NULL,
            institution TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
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
            status TEXT DEFAULT 'active',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
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
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (exam_id) REFERENCES exams(id)
        )
    ''')
    
    # Student Answers table
    c.execute('''
        CREATE TABLE IF NOT EXISTS student_answers (
            id SERIAL PRIMARY KEY,
            student_id TEXT NOT NULL,
            exam_id TEXT NOT NULL,
            question_id TEXT NOT NULL,
            answer_text TEXT,
            submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE(student_id, exam_id, question_id)
        )
    ''')
    
    # Warnings/Violations table
    c.execute('''
        CREATE TABLE IF NOT EXISTS warnings (
            id SERIAL PRIMARY KEY,
            student_id TEXT NOT NULL,
            exam_id TEXT NOT NULL,
            message TEXT NOT NULL,
            timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    # Exam Results table
    c.execute('''
        CREATE TABLE IF NOT EXISTS exam_results (
            id SERIAL PRIMARY KEY,
            student_id TEXT NOT NULL,
            exam_id TEXT NOT NULL,
            score REAL,
            total_questions INTEGER,
            correct_answers INTEGER,
            submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    conn.commit()
    conn.close()

# Call init before first request
init_db()

# =====================================================
# AUTHENTICATION ROUTES
# =====================================================

@app.route('/students', methods=['GET'])
def get_students():
    conn = get_db_connection()
    c = conn.cursor(cursor_factory=RealDictCursor)
    c.execute("SELECT id, name, institution FROM users WHERE role = 'student'")
    students = [{"id": r["id"], "name": r["name"], "institution": r["institution"]} for r in c.fetchall()]
    conn.close()
    return jsonify(students)

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
        
        conn = get_db_connection()
        c = conn.cursor(cursor_factory=RealDictCursor)
        
        c.execute(
            'SELECT id, name, role, institution FROM users WHERE id = %s AND password = %s',
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
        
        conn = get_db_connection()
        c = conn.cursor()
        
        try:
            c.execute(
                'INSERT INTO users (id, name, password, role, institution) VALUES (%s, %s, %s, %s, %s)',
                (user_id, name, password, role, institution)
            )
            conn.commit()
            return jsonify({'status': 'success', 'message': 'Account created'}), 201
        except psycopg2.IntegrityError:
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
        
        conn = get_db_connection()
        c = conn.cursor()
        
        try:
            c.execute(
                'INSERT INTO exams (id, name, exam_datetime, institution, status) VALUES (%s, %s, %s, %s, %s)',
                (exam_id, name, exam_datetime, institution, 'active')
            )
            conn.commit()
            return jsonify({'status': 'success', 'message': 'Exam created'}), 201
        except psycopg2.IntegrityError:
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
        
        conn = get_db_connection()
        c = conn.cursor(cursor_factory=RealDictCursor)
        
        institution_clean = institution.strip()
        c.execute(
            'SELECT * FROM exams WHERE UPPER(TRIM(institution)) = UPPER(%s) AND published = %s',
            (institution_clean, int(published))
        )
        exams = [dict(row) for row in c.fetchall()]
        conn.close()
        
        return jsonify({'status': 'success', 'exams': exams}), 200
        
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500

@app.route('/debug_exams', methods=['GET'])
def debug_exams():
    """Debug: list all exams in the database (remove in production)"""
    try:
        conn = get_db_connection()
        c = conn.cursor(cursor_factory=RealDictCursor)
        c.execute("SELECT id, name, institution, published FROM exams")
        exams = [dict(row) for row in c.fetchall()]
        conn.close()
        return jsonify({'status': 'success', 'exams': exams, 'count': len(exams)}), 200
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500

@app.route('/get_all_exams', methods=['GET'])
def get_all_exams():
    """Get ALL exams for an institution (both published and unpublished) - for teacher view"""
    try:
        institution = request.args.get('institution', '').strip()
        conn = get_db_connection()
        c = conn.cursor(cursor_factory=RealDictCursor)
        c.execute(
            'SELECT * FROM exams WHERE UPPER(TRIM(institution)) = UPPER(%s)',
            (institution,)
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
        
        conn = get_db_connection()
        c = conn.cursor()
        c.execute('UPDATE exams SET published = 1 WHERE id = %s', (exam_id,))
        conn.commit()
        conn.close()
        
        return jsonify({'status': 'success', 'message': 'Exam published'}), 200
        
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500

@app.route('/close_exam', methods=['POST'])
def close_exam():
    """Manually close an active exam"""
    try:
        data = request.get_json()
        exam_id = data.get('exam_id')
        
        if not exam_id:
            return jsonify({'status': 'error', 'message': 'Exam ID required'}), 400
            
        conn = get_db_connection()
        c = conn.cursor()
        c.execute("UPDATE exams SET status = 'finished' WHERE id = %s", (exam_id,))
        conn.commit()
        conn.close()
        return jsonify({'status': 'success', 'message': 'Exam closed'}), 200
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500

@app.route('/delete_exam/<exam_id>', methods=['DELETE'])
def delete_exam(exam_id):
    """Delete exam"""
    try:
        conn = get_db_connection()
        c = conn.cursor()
        c.execute('DELETE FROM exams WHERE id = %s', (exam_id,))
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
        
        conn = get_db_connection()
        c = conn.cursor()
        
        try:
            if question_type == 'mcq':
                options = data.get('options')
                correct_answer = data.get('correct_answer')
                if not options or not correct_answer:
                    return jsonify({'status': 'error', 'message': 'MCQ requires options'}), 400
                
                c.execute(
                    'INSERT INTO questions (id, exam_id, question_text, question_type, options, correct_answer) VALUES (%s, %s, %s, %s, %s, %s)',
                    (q_id, exam_id, question_text, 'mcq', json.dumps(options), correct_answer)
                )
            else:
                c.execute(
                    'INSERT INTO questions (id, exam_id, question_text, question_type) VALUES (%s, %s, %s, %s)',
                    (q_id, exam_id, question_text, 'essay')
                )
            
            conn.commit()
            return jsonify({'status': 'success', 'message': 'Question added'}), 201
            
        except psycopg2.IntegrityError:
            return jsonify({'status': 'error', 'message': 'Question ID exists'}), 409
        finally:
            conn.close()
            
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500

@app.route('/get_questions/<exam_id>', methods=['GET'])
def get_questions(exam_id):
    """Get all questions for exam"""
    try:
        conn = get_db_connection()
        c = conn.cursor(cursor_factory=RealDictCursor)
        
        c.execute('SELECT * FROM questions WHERE exam_id = %s', (exam_id,))
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
        
        conn = get_db_connection()
        c = conn.cursor()
        
        c.execute(
            '''INSERT INTO student_answers (student_id, exam_id, question_id, answer_text) 
               VALUES (%s, %s, %s, %s)
               ON CONFLICT (student_id, exam_id, question_id) 
               DO UPDATE SET answer_text = EXCLUDED.answer_text, submitted_at = CURRENT_TIMESTAMP''',
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
        
        conn = get_db_connection()
        c = conn.cursor(cursor_factory=RealDictCursor)
        
        # Get all questions
        c.execute('SELECT * FROM questions WHERE exam_id = %s', (exam_id,))
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
            'INSERT INTO exam_results (student_id, exam_id, score, total_questions, correct_answers) VALUES (%s, %s, %s, %s, %s)',
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
        
        conn = get_db_connection()
        c = conn.cursor()
        c.execute(
            'INSERT INTO warnings (student_id, exam_id, message) VALUES (%s, %s, %s)',
            (student_id, exam_id, 'Tab/App switch detected')
        )
        conn.commit()
        conn.close()
        
        return jsonify({'status': 'success'}), 200
        
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500

@app.route('/log_violation', methods=['POST'])
def log_violation():
    """Log any violation and broadcast via WebSockets"""
    try:
        data = request.get_json()
        student_id = data.get('student_id')
        exam_id = data.get('exam_id')
        violation_type = data.get('violation_type', 'Unknown Constraint')
        
        conn = get_db_connection()
        c = conn.cursor(cursor_factory=RealDictCursor)
        c.execute(
            'INSERT INTO warnings (student_id, exam_id, message) VALUES (%s, %s, %s)',
            (student_id, exam_id, violation_type)
        )
        
        # Get student name to send via websocket
        c.execute('SELECT name FROM users WHERE id = %s', (student_id,))
        user_row = c.fetchone()
        student_name = user_row['name'] if user_row else student_id
        
        conn.commit()
        conn.close()
        
        # Broadcast flag to live teachers
        alert = {
            'student_id': student_id,
            'student_name': student_name,
            'violation_type': violation_type,
            'timestamp': datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        }
        
        if exam_id in live_flags:
            dead_sockets = set()
            for monitor_ws in live_flags[exam_id]:
                try:
                    monitor_ws.send(json.dumps(alert))
                except Exception:
                    dead_sockets.add(monitor_ws)
                    
            for dead in dead_sockets:
                live_flags[exam_id].discard(dead)
        
        return jsonify({'status': 'success'}), 200
        
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500

@app.route('/get_warnings/<exam_id>', methods=['GET'])
def get_warnings(exam_id):
    """Get warnings for exam"""
    try:
        student_id = request.args.get('student_id')
        
        conn = get_db_connection()
        c = conn.cursor(cursor_factory=RealDictCursor)
        
        if student_id:
            c.execute(
                'SELECT * FROM warnings WHERE exam_id = %s AND student_id = %s',
                (exam_id, student_id)
            )
        else:
            c.execute('SELECT * FROM warnings WHERE exam_id = %s', (exam_id,))
        
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
        conn = get_db_connection()
        c = conn.cursor(cursor_factory=RealDictCursor)
        
        c.execute(
            'SELECT * FROM exam_results WHERE exam_id = %s ORDER BY submitted_at DESC',
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
        conn = get_db_connection()
        c = conn.cursor(cursor_factory=RealDictCursor)
        
        # Get user info
        c.execute('SELECT institution FROM users WHERE id = %s', (student_id,))
        user = c.fetchone()
        
        if not user:
            return jsonify({'status': 'error', 'message': 'User not found'}), 404
        
        institution = user['institution']
        
        # Completed exams
        c.execute(
            'SELECT COUNT(DISTINCT exam_id) as count FROM exam_results WHERE student_id = %s',
            (student_id,)
        )
        completed = c.fetchone()['count'] or 0
        
        # Warnings
        c.execute(
            'SELECT COUNT(*) as count FROM warnings WHERE student_id = %s',
            (student_id,)
        )
        warnings = c.fetchone()['count'] or 0
        
        # Accuracy
        c.execute(
            'SELECT AVG(score) as avg_score FROM exam_results WHERE student_id = %s',
            (student_id,)
        )
        accuracy = c.fetchone()['avg_score']
        
        # Upcoming exams
        c.execute(
            'SELECT id, name, exam_datetime FROM exams WHERE institution = %s AND exam_datetime IS NOT NULL AND published = 1 ORDER BY exam_datetime ASC',
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
    port = int(os.environ.get("PORT", 5000))
    # Bind to 0.0.0.0 and dynamically assign Port for cloud deployments
    app.run(host='0.0.0.0', port=port, debug=False)