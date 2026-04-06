import os
import random
import datetime
import jwt
import bcrypt
import uuid
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

if not DATABASE_URL:
    raise RuntimeError('DATABASE_URL not set in environment')

app = Flask(__name__)

# Security: CORS
CORS(app)

# Security: Rate Limiting
limiter = Limiter(
    get_remote_address,
    app=app,
    default_limits=["500 per day", "100 per hour"],
    storage_uri="memory://"
)

# ---------------------------------------------------------------------------
# Database helper
# ---------------------------------------------------------------------------

def get_db_connection():
    return psycopg2.connect(DATABASE_URL)

# ---------------------------------------------------------------------------
# Authentication Endpoints (Synchronized with Flutter App)
# ---------------------------------------------------------------------------

@app.route('/signup', methods=['POST'])
def signup():
    """Register a new user.
    Flutter payload: {id, name, password, role, institution}
    """
    try:
        data = request.get_json()
        if not data:
            return jsonify({'status': 'error', 'message': 'Invalid JSON'}), 400

        user_id = data.get('id', '').strip()
        name = data.get('name', '').strip()
        password = data.get('password', '').strip()
        role = data.get('role', '').strip().capitalize()
        institution = data.get('institution', '').strip()

        if not (user_id and name and password and role and institution):
            return jsonify({'status': 'error', 'message': 'Missing required fields'}), 400

        # Hash password with bcrypt
        salt = bcrypt.gensalt()
        password_hash = bcrypt.hashpw(password.encode('utf-8'), salt).decode('utf-8')

        conn = get_db_connection()
        cur = conn.cursor()
        
        # Check if user already exists
        cur.execute("SELECT 1 FROM users WHERE user_id = %s OR email = %s", (user_id, user_id))
        if cur.fetchone():
            cur.close()
            conn.close()
            return jsonify({'status': 'error', 'message': 'User ID or Email already registered'}), 409

        cur.execute(
            """
            INSERT INTO users (id, user_id, full_name, password_hash, role, university, email)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            """,
            (str(uuid.uuid4()), user_id, name, password_hash, role, institution, user_id)
        )
        conn.commit()
        cur.close()
        conn.close()
        
        return jsonify({
            'status': 'success',
            'user_id': user_id,
            'message': 'Account created successfully'
        }), 201
        
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500

@app.route('/login', methods=['POST'])
@limiter.limit("20 per minute")
def login():
    """Authenticate a user.
    Flutter payload: {id, password}
    """
    try:
        data = request.get_json()
        if not data:
            return jsonify({'status': 'error', 'message': 'Invalid JSON'}), 400

        user_id = data.get('id', '').strip()
        password = data.get('password', '').strip()
        
        if not user_id or not password:
            return jsonify({'status': 'error', 'message': 'ID and password required'}), 400

        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute(
            "SELECT id, full_name, password_hash, role, institution FROM users WHERE id = %s OR email = %s",
            (user_id, user_id)
        )
        user = cur.fetchone()
        cur.close()
        conn.close()

        if not user:
            return jsonify({'status': 'error', 'message': 'Invalid ID or password'}), 401

        # Verify bcrypt hash
        if not bcrypt.checkpw(password.encode('utf-8'), user['password_hash'].encode('utf-8')):
            return jsonify({'status': 'error', 'message': 'Invalid ID or password'}), 401

        # Generate JWT Token (expires in 24 hours)
        payload = {
            'user_id': user['id'],
            'role': user['role'],
            'exp': datetime.datetime.utcnow() + datetime.timedelta(hours=24)
        }
        token = jwt.encode(payload, JWT_SECRET, algorithm='HS256')

        return jsonify({
            'status': 'success',
            'token': token,
            'user': {
                'user_id': user['id'],
                'full_name': user['full_name'],
                'role': user['role'],
                'university': user['institution']
            }
        }), 200
        
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500

@app.route('/api/auth/health', methods=['GET'])
def health():
    return jsonify({'status': 'ok'}), 200

# ---------------------------------------------------------------------------
# APPLICATION ENTRYPOINT
# ---------------------------------------------------------------------------

if __name__ == '__main__':
    port = int(os.getenv('PORT', 7860))
    app.run(host='0.0.0.0', port=port, debug=False)