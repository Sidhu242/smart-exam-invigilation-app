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
# Global Error Handling
# ---------------------------------------------------------------------------

@app.errorhandler(404)
def not_found(e):
    return app_response(False, "Endpoint not found", None, 404)

@app.errorhandler(Exception)
def handle_exception(e):
    log_event("ERROR", "Unhandled Exception", str(e))
    return app_response(False, "An unexpected internal error occurred", {"details": str(e)}, 500)

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