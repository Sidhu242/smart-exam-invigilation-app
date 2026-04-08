import os
import random
import datetime
import jwt
import bcrypt
import sys
from flask import Flask, request, jsonify
from flask_cors import CORS
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
import psycopg2
from psycopg2.extras import RealDictCursor
from dotenv import load_dotenv

# Load variables from .env file
load_dotenv()

DATABASE_URL = os.getenv('DATABASE_URL')
JWT_SECRET = os.getenv('JWT_SECRET', 'your_jwt_secret_here')
DEBUG_MODE = os.getenv('DEBUG_MODE', 'true').lower() == 'true'

if not DATABASE_URL:
    raise RuntimeError('DATABASE_URL not set in environment')

app = Flask(__name__)
CORS(app)

# Security: Rate Limiting
limiter = Limiter(
    get_remote_address,
    app=app,
    default_limits=["500 per day", "100 per hour"],
    storage_uri="memory://"
)

# ---------------------------------------------------------------------------
# Logging & Response System
# ---------------------------------------------------------------------------

def log_event(level, message, details=None):
    """
    Custom logging for API requests and database queries.
    Prints to terminal if DEBUG_MODE is enabled.
    """
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    # Clean, readable logs similar to Firebase console
    indicator = "[SUCCESS]" if level == "SUCCESS" else f"[{level}]"
    formatted_msg = f"{indicator} {message}"
    if details:
        formatted_msg += f" | {details}"
    
    if DEBUG_MODE:
        print(f"[{timestamp}] {formatted_msg}")

def app_response(success, message, data=None, status_code=200):
    """
    Standardizes API responses: {success, message, data}
    """
    response = {
        "success": success,
        "message": message,
        "data": data or {}
    }
    return jsonify(response), status_code

# ---------------------------------------------------------------------------
# Database helper
# ---------------------------------------------------------------------------

def get_db_connection():
    try:
        conn = psycopg2.connect(DATABASE_URL)
        return conn
    except Exception as e:
        log_event("DB_ERROR", "Failed to connect to database", str(e))
        raise

# ---------------------------------------------------------------------------
# Authentication Endpoints
# ---------------------------------------------------------------------------

@app.route('/signup', methods=['POST'])
def signup():
    """Register a new user.
    Flutter payload: {id, name, password, role, institution}
    Actual DB Schema: {id, name, password, role, institution}
    """
    log_event("REQUEST", "POST /signup")
    try:
        data = request.get_json()
        if not data:
            return app_response(False, 'Invalid JSON payload', None, 400)

        # Correct field mapping to match requested schema
        user_id = data.get('id', '').strip()
        name = data.get('name', '').strip()
        password_text = data.get('password', '').strip()
        role = data.get('role', '').strip().capitalize()
        institution = data.get('institution', '').strip()

        if not (user_id and name and password_text and role and institution):
            log_event("ERROR", "Missing required fields")
            return app_response(False, 'Required fields missing: id, name, password, role, institution', None, 400)

        # Hash password (keep hashing logic as requested, store in "password" column)
        salt = bcrypt.gensalt()
        password_hash = bcrypt.hashpw(password_text.encode('utf-8'), salt).decode('utf-8')

        conn = get_db_connection()
        cur = conn.cursor()
        
        # Check if user already exists
        check_query = "SELECT 1 FROM users WHERE id = %s"
        log_event("DB QUERY", check_query, f"id={user_id}")
        cur.execute(check_query, (user_id,))
        if cur.fetchone():
            log_event("DB RESPONSE", "User already exists", f"id={user_id}")
            cur.close()
            conn.close()
            return app_response(False, f'User with ID {user_id} already exists', None, 409)

        # Fixed column names: id, name, password, role, institution
        insert_query = """
            INSERT INTO users (id, name, password, role, institution)
            VALUES (%s, %s, %s, %s, %s)
        """
        log_event("DB QUERY", insert_query, f"id={user_id}, name={name}")
        cur.execute(insert_query, (user_id, name, password_hash, role, institution))
        
        conn.commit()
        cur.close()
        conn.close()
        
        log_event("SUCCESS", "User created successfully", f"id={user_id}")
        return app_response(True, 'Account created successfully', {'id': user_id}, 201)
        
    except Exception as e:
        log_event("ERROR", "Signup process failed", str(e))
        return app_response(False, f"Server error: {str(e)}", None, 500)

@app.route('/login', methods=['POST'])
@limiter.limit("20 per minute")
def login():
    """Authenticate a user.
    Flutter payload: {id, password}
    """
    log_event("REQUEST", "POST /login")
    try:
        data = request.get_json()
        if not data:
            return app_response(False, 'Invalid JSON payload', None, 400)

        user_id = data.get('id', '').strip()
        password_text = data.get('password', '').strip()
        
        if not user_id or not password_text:
            return app_response(False, 'ID and password are required', None, 400)

        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        # Fixed query: use correct column names
        select_query = "SELECT id, name, password, role, institution FROM users WHERE id = %s"
        log_event("DB QUERY", select_query, f"id={user_id}")
        cur.execute(select_query, (user_id,))
        user = cur.fetchone()
        cur.close()
        conn.close()

        if not user:
            log_event("ERROR", "User not found", f"id={user_id}")
            return app_response(False, 'Invalid ID or password', None, 401)

        # Verify password (with fallback for legacy plaintext passwords)
        try:
            is_valid = bcrypt.checkpw(password_text.encode('utf-8'), user['password'].encode('utf-8'))
        except (ValueError, TypeError, Exception):
            # Fallback for legacy plaintext passwords
            is_valid = (password_text == user['password'])

        if not is_valid:
            log_event("ERROR", "Invalid password", f"id={user_id}")
            return app_response(False, 'Invalid ID or password', None, 401)

        # Generate JWT Token (expires in 24 hours)
        payload = {
            'user_id': user['id'],
            'role': user['role'],
            'exp': datetime.datetime.utcnow() + datetime.timedelta(hours=24)
        }
        token = jwt.encode(payload, JWT_SECRET, algorithm='HS256')

        user_info = {
            'id': user['id'],
            'name': user['name'],
            'role': user['role'],
            'institution': user['institution'],
            'token': token
        }
        
        log_event("SUCCESS", "Login successful", f"id={user_id}")
        return app_response(True, 'Authentication successful', user_info, 200)
        
    except Exception as e:
        log_event("ERROR", "Login process failed", str(e))
        return app_response(False, f"Server error: {str(e)}", None, 500)

@app.route('/api/auth/health', methods=['GET'])
def health():
    return app_response(True, "Server is healthy")

# ---------------------------------------------------------------------------
# JWT Auth Decorator
# ---------------------------------------------------------------------------

from functools import wraps

def token_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        token = None
        auth_header = request.headers.get('Authorization', '')
        if auth_header.startswith('Bearer '):
            token = auth_header.split(' ')[1]
        if not token:
            return app_response(False, 'Authentication token required', None, 401)
        try:
            data = jwt.decode(token, JWT_SECRET, algorithms=['HS256'])
            current_user_id = data['user_id']
        except jwt.ExpiredSignatureError:
            return app_response(False, 'Token has expired', None, 401)
        except jwt.InvalidTokenError:
            return app_response(False, 'Invalid token', None, 401)
        return f(current_user_id, *args, **kwargs)
    return decorated

# ---------------------------------------------------------------------------
# Global Error Handling
# ---------------------------------------------------------------------------

@app.errorhandler(404)
def not_found(e):
    return app_response(False, "Endpoint not found", None, 404)

@app.errorhandler(429)
def rate_limited(e):
    return app_response(False, "Too many requests. Please try again later.", None, 429)

@app.errorhandler(Exception)
def handle_exception(e):
    log_event("ERROR", "Unhandled Exception", str(e))
    return app_response(False, "An unexpected internal error occurred", {"details": str(e)}, 500)

# ---------------------------------------------------------------------------
# Exam Management Endpoints
# ---------------------------------------------------------------------------

@app.route('/create_exam', methods=['POST'])
def create_exam():
    """Create a new exam."""
    log_event("REQUEST", "POST /create_exam")
    try:
        data = request.get_json()
        if not data:
            return app_response(False, 'Invalid JSON payload', None, 400)

        exam_id = data.get('id', '').strip()
        name = data.get('name', '').strip()
        exam_datetime = data.get('exam_datetime', '').strip()
        institution = data.get('institution', '').strip()

        if not (exam_id and name and institution):
            return app_response(False, 'Required fields: id, name, institution', None, 400)

        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("SELECT 1 FROM exams WHERE id = %s", (exam_id,))
        if cur.fetchone():
            cur.close()
            conn.close()
            return app_response(False, 'Exam with this ID already exists', None, 409)

        cur.execute(
            """INSERT INTO exams (id, name, exam_datetime, institution, published, status)
               VALUES (%s, %s, %s, %s, 0, 'draft')""",
            (exam_id, name, exam_datetime or None, institution)
        )
        conn.commit()
        cur.close()
        conn.close()

        log_event("SUCCESS", "Exam created", f"id={exam_id}")
        return app_response(True, 'Exam created successfully', {'id': exam_id}, 201)
    except Exception as e:
        log_event("ERROR", "create_exam failed", str(e))
        return app_response(False, f"Server error: {str(e)}", None, 500)


@app.route('/get_exams', methods=['GET'])
def get_exams():
    """Get all published exams for an institution."""
    log_event("REQUEST", "GET /get_exams")
    try:
        institution = request.args.get('institution', '').strip()
        published = request.args.get('published', '1')

        if not institution:
            return app_response(False, 'institution parameter required', None, 400)

        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)

        if published == '1':
            cur.execute(
                "SELECT * FROM exams WHERE institution = %s AND published = 1 ORDER BY created_at DESC",
                (institution,)
            )
        else:
            cur.execute(
                "SELECT * FROM exams WHERE institution = %s ORDER BY created_at DESC",
                (institution,)
            )

        exams = [dict(r) for r in cur.fetchall()]
        cur.close()
        conn.close()

        log_event("SUCCESS", "Exams fetched", f"institution={institution}, count={len(exams)}")
        return app_response(True, 'Exams retrieved successfully', {'exams': exams})
    except Exception as e:
        log_event("ERROR", "get_exams failed", str(e))
        return app_response(False, f"Server error: {str(e)}", None, 500)


@app.route('/get_all_exams', methods=['GET'])
def get_all_exams():
    """Get all exams (published + unpublished) for an institution — teacher use."""
    log_event("REQUEST", "GET /get_all_exams")
    try:
        institution = request.args.get('institution', '').strip()
        if not institution:
            return app_response(False, 'institution parameter required', None, 400)

        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute(
            "SELECT * FROM exams WHERE institution = %s ORDER BY created_at DESC",
            (institution,)
        )
        exams = [dict(r) for r in cur.fetchall()]
        cur.close()
        conn.close()

        log_event("SUCCESS", "All exams fetched", f"institution={institution}, count={len(exams)}")
        return app_response(True, 'All exams retrieved', {'exams': exams})
    except Exception as e:
        log_event("ERROR", "get_all_exams failed", str(e))
        return app_response(False, f"Server error: {str(e)}", None, 500)


@app.route('/publish_exam', methods=['POST'])
def publish_exam():
    """Publish an exam so students can see it."""
    log_event("REQUEST", "POST /publish_exam")
    try:
        data = request.get_json()
        if not data:
            return app_response(False, 'Invalid JSON payload', None, 400)

        exam_id = data.get('exam_id', '').strip()
        if not exam_id:
            return app_response(False, 'exam_id required', None, 400)

        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("SELECT 1 FROM exams WHERE id = %s", (exam_id,))
        if not cur.fetchone():
            cur.close()
            conn.close()
            return app_response(False, 'Exam not found', None, 404)

        cur.execute("UPDATE exams SET published = 1, status = 'active' WHERE id = %s", (exam_id,))
        conn.commit()
        cur.close()
        conn.close()

        log_event("SUCCESS", "Exam published", f"id={exam_id}")
        return app_response(True, 'Exam published successfully')
    except Exception as e:
        log_event("ERROR", "publish_exam failed", str(e))
        return app_response(False, f"Server error: {str(e)}", None, 500)


@app.route('/close_exam', methods=['POST'])
def close_exam():
    """Close an exam (set status to closed)."""
    log_event("REQUEST", "POST /close_exam")
    try:
        data = request.get_json()
        if not data:
            return app_response(False, 'Invalid JSON payload', None, 400)

        exam_id = data.get('exam_id', '').strip()
        if not exam_id:
            return app_response(False, 'exam_id required', None, 400)

        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("SELECT 1 FROM exams WHERE id = %s", (exam_id,))
        if not cur.fetchone():
            cur.close()
            conn.close()
            return app_response(False, 'Exam not found', None, 404)

        cur.execute("UPDATE exams SET status = 'closed' WHERE id = %s", (exam_id,))
        conn.commit()
        cur.close()
        conn.close()

        log_event("SUCCESS", "Exam closed", f"id={exam_id}")
        return app_response(True, 'Exam closed successfully')
    except Exception as e:
        log_event("ERROR", "close_exam failed", str(e))
        return app_response(False, f"Server error: {str(e)}", None, 500)


@app.route('/delete_exam/<exam_id>', methods=['DELETE'])
def delete_exam(exam_id):
    """Delete an exam and its associated questions, answers, results, and warnings."""
    log_event("REQUEST", "DELETE /delete_exam")
    try:
        if not exam_id:
            return app_response(False, 'exam_id required', None, 400)

        conn = get_db_connection()
        cur = conn.cursor()

        # Delete associated questions first (foreign key)
        cur.execute("DELETE FROM questions WHERE exam_id = %s", (exam_id,))
        # Delete associated warnings, results, and answers
        cur.execute("DELETE FROM warnings WHERE exam_id = %s", (exam_id,))
        cur.execute("DELETE FROM exam_results WHERE exam_id = %s", (exam_id,))
        cur.execute("DELETE FROM student_answers WHERE exam_id = %s", (exam_id,))
        # Delete the exam itself
        cur.execute("DELETE FROM exams WHERE id = %s", (exam_id,))

        conn.commit()
        cur.close()
        conn.close()

        log_event("SUCCESS", "Exam deleted", f"id={exam_id}")
        return app_response(True, 'Exam deleted successfully')
    except Exception as e:
        log_event("ERROR", "delete_exam failed", str(e))
        return app_response(False, f"Server error: {str(e)}", None, 500)


# ---------------------------------------------------------------------------
# Question Management Endpoints
# ---------------------------------------------------------------------------

@app.route('/add_question', methods=['POST'])
def add_question():
    """Add a question to an exam."""
    log_event("REQUEST", "POST /add_question")
    try:
        data = request.get_json()
        if not data:
            return app_response(False, 'Invalid JSON payload', None, 400)

        question_id = data.get('id', '').strip()
        exam_id = data.get('exam_id', '').strip()
        question_text = data.get('question_text', '').strip()
        question_type = data.get('question_type', '').strip()
        options = data.get('options')  # can be a list or None
        correct_answer = data.get('correct_answer', '').strip()

        if not (question_id and exam_id and question_text and question_type):
            return app_response(False, 'Required fields: id, exam_id, question_text, question_type', None, 400)

        # Convert options list to JSON string if needed
        options_str = None
        if options and isinstance(options, list):
            import json
            options_str = json.dumps(options)

        conn = get_db_connection()
        cur = conn.cursor()

        # Verify exam exists
        cur.execute("SELECT 1 FROM exams WHERE id = %s", (exam_id,))
        if not cur.fetchone():
            cur.close()
            conn.close()
            return app_response(False, 'Exam not found', None, 404)

        cur.execute(
            """INSERT INTO questions (id, exam_id, question_text, question_type, options, correct_answer)
               VALUES (%s, %s, %s, %s, %s, %s)""",
            (question_id, exam_id, question_text, question_type, options_str, correct_answer or None)
        )
        conn.commit()
        cur.close()
        conn.close()

        log_event("SUCCESS", "Question added", f"question_id={question_id}")
        return app_response(True, 'Question added successfully', {'id': question_id}, 201)
    except Exception as e:
        log_event("ERROR", "add_question failed", str(e))
        return app_response(False, f"Server error: {str(e)}", None, 500)


@app.route('/get_questions/<exam_id>', methods=['GET'])
def get_questions(exam_id):
    """Get all questions for an exam (excluding correct_answer for students)."""
    log_event("REQUEST", "GET /get_questions")
    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute(
            "SELECT id, exam_id, question_text, question_type, options FROM questions WHERE exam_id = %s",
            (exam_id,)
        )
        questions = [dict(r) for r in cur.fetchall()]

        # Parse options JSON strings back into lists
        import json
        for q in questions:
            if q.get('options'):
                try:
                    q['options'] = json.loads(q['options'])
                except (json.JSONDecodeError, TypeError):
                    q['options'] = []

        cur.close()
        conn.close()

        log_event("SUCCESS", "Questions fetched", f"exam_id={exam_id}, count={len(questions)}")
        return app_response(True, 'Questions retrieved successfully', {'questions': questions})
    except Exception as e:
        log_event("ERROR", "get_questions failed", str(e))
        return app_response(False, f"Server error: {str(e)}", None, 500)


# ---------------------------------------------------------------------------
# Submission Endpoints
# ---------------------------------------------------------------------------

@app.route('/submit_answer', methods=['POST'])
def submit_answer():
    """Submit a single answer during an exam."""
    log_event("REQUEST", "POST /submit_answer")
    try:
        data = request.get_json()
        if not data:
            return app_response(False, 'Invalid JSON payload', None, 400)

        student_id = data.get('student_id', '').strip()
        exam_id = data.get('exam_id', '').strip()
        question_id = data.get('question_id', '').strip()
        answer_text = data.get('answer_text', '').strip()

        if not (student_id and exam_id and question_id):
            return app_response(False, 'Required fields: student_id, exam_id, question_id', None, 400)

        conn = get_db_connection()
        cur = conn.cursor()

        # Upsert: update if already exists, insert if not
        cur.execute(
            """INSERT INTO student_answers (student_id, exam_id, question_id, answer_text)
               VALUES (%s, %s, %s, %s)
               ON CONFLICT (student_id, exam_id, question_id)
               DO UPDATE SET answer_text = %s, submitted_at = CURRENT_TIMESTAMP""",
            (student_id, exam_id, question_id, answer_text or '', answer_text or '')
        )
        conn.commit()
        cur.close()
        conn.close()

        log_event("SUCCESS", "Answer submitted", f"student={student_id}, question={question_id}")
        return app_response(True, 'Answer saved successfully')
    except Exception as e:
        log_event("ERROR", "submit_answer failed", str(e))
        return app_response(False, f"Server error: {str(e)}", None, 500)


@app.route('/submit_exam', methods=['POST'])
def submit_exam():
    """Submit all answers for an exam and compute score."""
    log_event("REQUEST", "POST /submit_exam")
    try:
        data = request.get_json()
        if not data:
            return app_response(False, 'Invalid JSON payload', None, 400)

        student_id = data.get('student_id', '').strip()
        exam_id = data.get('exam_id', '').strip()
        answers = data.get('answers', {})  # {question_id: answer_text}

        if not (student_id and exam_id):
            return app_response(False, 'Required fields: student_id, exam_id', None, 400)

        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)

        # Save all answers
        import json
        for question_id, answer_text in answers.items():
            cur.execute(
                """INSERT INTO student_answers (student_id, exam_id, question_id, answer_text)
                   VALUES (%s, %s, %s, %s)
                   ON CONFLICT (student_id, exam_id, question_id)
                   DO UPDATE SET answer_text = %s, submitted_at = CURRENT_TIMESTAMP""",
                (student_id, exam_id, question_id, str(answer_text), str(answer_text))
            )

        # Calculate score
        correct = 0
        total = 0
        for question_id, answer_text in answers.items():
            cur.execute("SELECT correct_answer FROM questions WHERE id = %s", (question_id,))
            q = cur.fetchone()
            if q and q['correct_answer']:
                total += 1
                if str(answer_text).strip().lower() == str(q['correct_answer']).strip().lower():
                    correct += 1

        score = round((correct / total * 100) if total > 0 else 0, 2)

        # Save exam result
        cur.execute(
            """INSERT INTO exam_results (student_id, exam_id, score, total_questions, correct_answers)
               VALUES (%s, %s, %s, %s, %s)""",
            (student_id, exam_id, score, total, correct)
        )
        conn.commit()
        cur.close()
        conn.close()

        log_event("SUCCESS", "Exam submitted", f"student={student_id}, score={score}%")
        return app_response(True, 'Exam submitted successfully', {
            'score': score,
            'total_questions': total,
            'correct_answers': correct
        })
    except Exception as e:
        log_event("ERROR", "submit_exam failed", str(e))
        return app_response(False, f"Server error: {str(e)}", None, 500)


# ---------------------------------------------------------------------------
# Results & Summary Endpoints
# ---------------------------------------------------------------------------

@app.route('/get_exam_results/<exam_id>', methods=['GET'])
def get_exam_results(exam_id):
    """Get all results for an exam."""
    log_event("REQUEST", "GET /get_exam_results")
    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute(
            """SELECT er.student_id, u.name as student_name, er.score,
                      er.total_questions, er.correct_answers, er.submitted_at
               FROM exam_results er
               JOIN users u ON er.student_id = u.id
               WHERE er.exam_id = %s
               ORDER BY er.score DESC""",
            (exam_id,)
        )
        results = [dict(r) for r in cur.fetchall()]
        cur.close()
        conn.close()

        log_event("SUCCESS", "Results fetched", f"exam_id={exam_id}, count={len(results)}")
        return app_response(True, 'Results retrieved successfully', {'results': results})
    except Exception as e:
        log_event("ERROR", "get_exam_results failed", str(e))
        return app_response(False, f"Server error: {str(e)}", None, 500)


@app.route('/get_summary/<student_id>', methods=['GET'])
def get_summary(student_id):
    """Get performance summary for a student across all exams."""
    log_event("REQUEST", "GET /get_summary")
    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)

        cur.execute(
            """SELECT er.exam_id, e.name as exam_name, er.score,
                      er.total_questions, er.correct_answers, er.submitted_at
               FROM exam_results er
               JOIN exams e ON er.exam_id = e.id
               WHERE er.student_id = %s
               ORDER BY er.submitted_at DESC""",
            (student_id,)
        )
        exams = [dict(r) for r in cur.fetchall()]

        # Calculate overall stats
        total_exams = len(exams)
        if total_exams > 0:
            avg_score = round(sum(e['score'] for e in exams) / total_exams, 2)
            best_score = max(e['score'] for e in exams)
            worst_score = min(e['score'] for e in exams)
        else:
            avg_score = best_score = worst_score = 0

        summary = {
            'student_id': student_id,
            'total_exams_taken': total_exams,
            'average_score': avg_score,
            'best_score': best_score,
            'worst_score': worst_score,
            'exams': exams
        }
        cur.close()
        conn.close()

        log_event("SUCCESS", "Summary fetched", f"student_id={student_id}")
        return app_response(True, 'Summary retrieved successfully', {'summary': summary})
    except Exception as e:
        log_event("ERROR", "get_summary failed", str(e))
        return app_response(False, f"Server error: {str(e)}", None, 500)


# ---------------------------------------------------------------------------
# Warnings & Violations Endpoints
# ---------------------------------------------------------------------------

@app.route('/log_tab_switch', methods=['POST'])
def log_tab_switch():
    """Log a tab switch violation."""
    log_event("REQUEST", "POST /log_tab_switch")
    try:
        data = request.get_json()
        if not data:
            return app_response(False, 'Invalid JSON payload', None, 400)

        student_name = data.get('student_name', '').strip()
        exam_id = data.get('exam_id', '').strip()

        if not (student_name and exam_id):
            return app_response(False, 'Required fields: student_name, exam_id', None, 400)

        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)

        # Get student_id from users table
        cur.execute("SELECT id FROM users WHERE name = %s", (student_name,))
        student = cur.fetchone()
        student_id = student['id'] if student else student_name

        cur.execute(
            "INSERT INTO warnings (student_id, exam_id, message) VALUES (%s, %s, %s)",
            (student_id, exam_id, f"Tab switch detected")
        )
        conn.commit()
        cur.close()
        conn.close()

        log_event("SUCCESS", "Tab switch logged", f"student={student_name}")
        return app_response(True, 'Tab switch logged successfully')
    except Exception as e:
        log_event("ERROR", "log_tab_switch failed", str(e))
        return app_response(False, f"Server error: {str(e)}", None, 500)


@app.route('/get_warnings', methods=['GET'])
@app.route('/get_warnings/<exam_id>', methods=['GET'])
def get_warnings(exam_id=None):
    """Get warnings for a student in an exam, or all warnings for an exam."""
    log_event("REQUEST", "GET /get_warnings")
    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)

        if exam_id:
            # Get all warnings for a specific exam
            cur.execute(
                """SELECT w.id, w.student_id, u.name as student_name, w.message, w.timestamp
                   FROM warnings w
                   LEFT JOIN users u ON w.student_id = u.id
                   WHERE w.exam_id = %s
                   ORDER BY w.timestamp DESC""",
                (exam_id,)
            )
        else:
            # Get warnings for specific student and exam
            student_name = request.args.get('student_name', '').strip()
            if not student_name:
                cur.close()
                conn.close()
                return app_response(False, 'student_name parameter required', None, 400)

            cur.execute("SELECT id FROM users WHERE name = %s", (student_name,))
            student = cur.fetchone()
            student_id = student['id'] if student else None

            if not student_id:
                cur.close()
                conn.close()
                return app_response(True, 'No warnings found', {'warnings': []})

            exam_param = request.args.get('exam_id', '').strip()
            if exam_param:
                cur.execute(
                    "SELECT * FROM warnings WHERE student_id = %s AND exam_id = %s ORDER BY timestamp DESC",
                    (student_id, exam_param)
                )
            else:
                cur.execute(
                    "SELECT * FROM warnings WHERE student_id = %s ORDER BY timestamp DESC",
                    (student_id,)
                )

        warnings = [dict(r) for r in cur.fetchall()]
        cur.close()
        conn.close()

        log_event("SUCCESS", "Warnings fetched", f"count={len(warnings)}")
        return app_response(True, 'Warnings retrieved successfully', {'warnings': warnings})
    except Exception as e:
        log_event("ERROR", "get_warnings failed", str(e))
        return app_response(False, f"Server error: {str(e)}", None, 500)


@app.route('/log_violation', methods=['POST'])
def log_violation():
    """Log a proctoring violation from ML monitoring."""
    log_event("REQUEST", "POST /log_violation")
    try:
        data = request.get_json()
        if not data:
            return app_response(False, 'Invalid JSON payload', None, 400)

        student_id = data.get('student_id', '').strip()
        exam_id = data.get('exam_id', '').strip()
        violation_type = data.get('violation_type', '').strip()
        confidence = data.get('confidence', 1.0)
        screenshot = data.get('screenshot', '')

        if not (student_id and exam_id and violation_type):
            return app_response(False, 'Required fields: student_id, exam_id, violation_type', None, 400)

        conn = get_db_connection()
        cur = conn.cursor()

        # Log in both violations and warnings tables
        cur.execute(
            """INSERT INTO violations (student_id, exam_id, violation_type, confidence, screenshot)
               VALUES (%s, %s, %s, %s, %s)""",
            (student_id, exam_id, violation_type, confidence, screenshot or None)
        )
        cur.execute(
            "INSERT INTO warnings (student_id, exam_id, message) VALUES (%s, %s, %s)",
            (student_id, exam_id, f"Violation: {violation_type}")
        )
        conn.commit()
        cur.close()
        conn.close()

        log_event("SUCCESS", "Violation logged", f"type={violation_type}, student={student_id}")
        return app_response(True, 'Violation logged successfully')
    except Exception as e:
        log_event("ERROR", "log_violation failed", str(e))
        return app_response(False, f"Server error: {str(e)}", None, 500)


# ---------------------------------------------------------------------------
# Flags Endpoint (used by MLService)
# ---------------------------------------------------------------------------

@app.route('/api/flags', methods=['POST'])
def create_flag():
    """Create a proctoring flag/violation record."""
    log_event("REQUEST", "POST /api/flags")
    try:
        data = request.get_json()
        if not data:
            return app_response(False, 'Invalid JSON payload', None, 400)

        student_id = str(data.get('student_id', '')).strip()
        exam_id = str(data.get('exam_id', '')).strip()
        violation_type = data.get('violation_type', '').strip()
        confidence = data.get('confidence', 1.0)
        screenshot = data.get('screenshot', '')

        if not (student_id and exam_id and violation_type):
            return app_response(False, 'Required: student_id, exam_id, violation_type', None, 400)

        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute(
            """INSERT INTO violations (student_id, exam_id, violation_type, confidence, screenshot)
               VALUES (%s, %s, %s, %s, %s)""",
            (student_id, exam_id, violation_type, confidence, screenshot or None)
        )
        cur.execute(
            "INSERT INTO warnings (student_id, exam_id, message) VALUES (%s, %s, %s)",
            (student_id, exam_id, f"Violation: {violation_type}")
        )
        conn.commit()
        cur.close()
        conn.close()

        log_event("SUCCESS", "Flag created", f"type={violation_type}")
        return app_response(True, 'Flag created successfully', {'student_id': student_id})
    except Exception as e:
        log_event("ERROR", "create_flag failed", str(e))
        return app_response(False, f"Server error: {str(e)}", None, 500)


@app.route('/api/flags', methods=['GET'])
def get_flags():
    """Get all flags for an exam."""
    log_event("REQUEST", "GET /api/flags")
    try:
        exam_id = request.args.get('exam_id', '').strip()
        if not exam_id:
            return app_response(False, 'exam_id parameter required', None, 400)

        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute(
            """SELECT v.id, v.student_id, u.name as student_name, v.exam_id,
                      v.violation_type, v.confidence, v.screenshot, v.timestamp
               FROM violations v
               LEFT JOIN users u ON v.student_id = u.id
               WHERE v.exam_id = %s
               ORDER BY v.timestamp DESC""",
            (exam_id,)
        )
        flags = [dict(r) for r in cur.fetchall()]
        cur.close()
        conn.close()

        log_event("SUCCESS", "Flags fetched", f"exam_id={exam_id}, count={len(flags)}")
        return jsonify(flags)
    except Exception as e:
        log_event("ERROR", "get_flags failed", str(e))
        return app_response(False, f"Server error: {str(e)}", None, 500)


# ---------------------------------------------------------------------------
# Logout Endpoint
# ---------------------------------------------------------------------------

@app.route('/logout', methods=['POST'])
@token_required
def logout(current_user_id):
    """Logout endpoint (client-side token revocation)."""
    log_event("REQUEST", "POST /logout", f"user_id={current_user_id}")
    return app_response(True, 'Logged out successfully')


# ---------------------------------------------------------------------------
# WebSocket Support (via Flask-Sock)
# ---------------------------------------------------------------------------

from flask_sock import Sock
sock = Sock(app)


@sock.route('/ws/flags/<int:exam_id>')
def ws_flags(ws, exam_id):
    """WebSocket endpoint for real-time flag streaming for an exam."""
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=RealDictCursor)

    # Send existing flags first
    cur.execute(
        """SELECT v.id, v.student_id, u.name as student_name,
                  v.violation_type, v.confidence, v.timestamp
           FROM violations v
           LEFT JOIN users u ON v.student_id = u.id
           WHERE v.exam_id = %s
           ORDER BY v.timestamp DESC LIMIT 100""",
        (exam_id,)
    )
    flags = [dict(r) for r in cur.fetchall()]
    import json as _json
    for flag in flags:
        # Convert datetime to string for JSON serialization
        if hasattr(flag.get('timestamp'), 'isoformat'):
            flag['timestamp'] = flag['timestamp'].isoformat()
        ws.send(_json.dumps(flag))

    # Long-poll for new violations
    import time
    last_id = flags[0]['id'] if flags else 0
    conn.close()

    try:
        while True:
            new_conn = get_db_connection()
            new_cur = new_conn.cursor(cursor_factory=RealDictCursor)
            new_cur.execute(
                """SELECT v.id, v.student_id, u.name as student_name,
                          v.violation_type, v.confidence, v.timestamp
                   FROM violations v
                   LEFT JOIN users u ON v.student_id = u.id
                   WHERE v.exam_id = %s AND v.id > %s
                   ORDER BY v.timestamp ASC""",
                (exam_id, last_id)
            )
            new_flags = new_cur.fetchall()
            new_cur.close()
            new_conn.close()

            if new_flags:
                for flag in new_flags:
                    if hasattr(flag.get('timestamp'), 'isoformat'):
                        flag['timestamp'] = flag['timestamp'].isoformat()
                    ws.send(_json.dumps(flag))
                last_id = new_flags[-1]['id']
            else:
                time.sleep(2)  # poll every 2 seconds
    except Exception:
        pass

# ---------------------------------------------------------------------------
# APPLICATION ENTRYPOINT
# ---------------------------------------------------------------------------

if __name__ == '__main__':
    port = int(os.getenv('PORT', 7860))
    print(f"\n{'='*60}")
    print(f" SMART EXAM INVIGILATION BACKEND - STARTING...")
    print(f" Port: {port}")
    print(f" Debug Mode: {'ENABLED' if DEBUG_MODE else 'DISABLED'}")
    print(f"{'='*60}\n")
    app.run(host='0.0.0.0', port=port, debug=False)