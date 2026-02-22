# Smart Exam Invigilation - Troubleshooting & FAQ

## Common Issues & Solutions

---

## 🔴 BACKEND ISSUES

### Issue: Backend won't start - "connect ECONNREFUSED"

**Error Message:**
```
Error: connect ECONNREFUSED 127.0.0.1:3306
```

**Causes:**
- MySQL is not running
- Wrong MySQL connection details in `.env`
- MySQL port is different (default: 3306)

**Solutions:**
```bash
# 1. Check if MySQL is running on Windows
tasklist /FI "IMAGENAME eq mysqld.exe"

# 2. Start MySQL if not running
# Windows: Search for "Services" → Start "MySQL"
# Mac: brew services start mysql@8.0
# Linux: sudo service mysql start

# 3. Verify connection details
# Edit backend-nodejs/.env
DB_HOST=localhost      # or 127.0.0.1
DB_PORT=3306          # default port
DB_USER=root          # your username
DB_PASSWORD=          # your password

# 4. Test connection directly
mysql -h localhost -u root -p -e "SHOW DATABASES;"
```

---

### Issue: "npm: command not found"

**Error Message:**
```
npm: command not found
```

**Solution:**
- Node.js is not installed or not in PATH
- Download from https://nodejs.org/
- Restart terminal after installation
- Verify: `node --version` and `npm --version`

---

### Issue: "SyntaxError: Unexpected token"

**Likely Cause:**
- Invalid JSON in `.env` file or request body

**Solution:**
```bash
# Backup your .env
cp backend-nodejs/.env backend-nodejs/.env.backup

# Regenerate from template
cp backend-nodejs/.env.example backend-nodejs/.env

# Manually edit with careful attention to:
# - No quotes around values
# - No trailing commas
# - Valid structure
```

---

### Issue: "Table 'smart_exam_invigilation.users' doesn't exist"

**Error Message:**
```
Table 'smart_exam_invigilation.users' doesn't exist
```

**Solutions:**
```bash
# 1. Verify database exists
mysql -u root -p -e "SHOW DATABASES;"

# 2. Run schema script
mysql -u root -p smart_exam_invigilation < backend-nodejs/schema.sql

# 3. Verify tables were created
mysql -u root -p -e "USE smart_exam_invigilation; SHOW TABLES;"
```

---

### Issue: "Port 5000 already in use"

**Error Message:**
```
Error: listen EADDRINUSE :::5000
```

**Solutions:**
```bash
# Windows: Find process using port 5000
netstat -ano | findstr :5000
# Kill process
taskkill /PID <PID> /F

# Mac/Linux: Find process
lsof -i :5000
# Kill process
kill -9 <PID>

# Alternative: Use different port
# Edit server.js or .env to use PORT=5001
```

---

### Issue: "ValidationError: email is required"

**Possible Cause:**
- Missing or invalid request body
- Wrong Content-Type header

**Solution (Testing with curl):**
```bash
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"password123"}'
```

**Ensure:**
- `Content-Type: application/json` header
- Valid JSON in body
- All required fields present

---

### Issue: "401 Unauthorized - Invalid token"

**Error Message:**
```
{
  "error": "Invalid token or token expired"
}
```

**Solutions:**
```bash
# 1. Login first to get token
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"john@school.com","password":"password123"}'

# 2. Copy the token from response
# 3. Use token in Authorization header
curl -X GET http://localhost:5000/api/exams \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

---

### Issue: "CORS error - blocked by browser"

**Error in Browser Console:**
```
Access to XMLHttpRequest has been blocked by CORS policy
```

**Solution:**
```javascript
// Check CORS configuration in src/app.js
// Should already be configured as:
app.use(cors({
  origin: '*',  // Allow all origins
  credentials: true
}));

// If issues persist, update CORS_ORIGIN in .env
CORS_ORIGIN=http://localhost:3000

// For production, specify exact origin:
CORS_ORIGIN=https://yourdomain.com
```

---

## 🔴 FRONTEND (FLUTTER) ISSUES

### Issue: "Could not connect to backend"

**Error in Flutter:**
```
Connection refused / Failed to connect to backend
```

**Solutions:**

```dart
// Check API_SERVICE base URL
// file: lib/services/api_service.dart

// For Emulator (Android):
static const String baseUrl = 'http://10.0.2.2:5000/api';
// 10.0.2.2 is special alias for host machine

// For Physical Device:
static const String baseUrl = 'http://192.168.1.100:5000/api';
// Replace with your computer's actual IP

// For Web/Chrome:
static const String baseUrl = 'http://localhost:5000/api';

// To find your IP on Windows:
// Command Prompt:
ipconfig
// Look for IPv4 Address (usually 192.168.x.x)
```

---

### Issue: "flutter: command not found"

**Solution:**
- Flutter SDK not installed
- Download from https://flutter.dev/
- Add to PATH
- Verify: `flutter --version`

---

### Issue: "No devices found"

**Error:**
```
No connected devices
```

**Solutions:**

```bash
# 1. List available devices
flutter devices

# 2. Start Android emulator
flutter emulators --launch Pixel_3_API_30

# 3. Or connect physical device
# Enable USB Debugging → Connect via USB
# Give permission when prompted

# 4. Verify device is connected
flutter devices
```

---

### Issue: "Gradle build failed"

**For Android:**
```bash
# 1. Clean project
flutter clean

# 2. Get dependencies
flutter pub get

# 3. Rebuild
flutter run

# If still fails:
# cd frontend/android
# ./gradlew clean
# cd ../..
# flutter run
```

---

### Issue: "Compilation error in Dart code"

**General Solution:**
```bash
# 1. Analyze code for errors
flutter analyze

# 2. Get latest dependencies
flutter pub get

# 3. Run with detailed error message
flutter run -v  # Verbose mode shows full error

# 4. Check specific file
dart analyze lib/pages/your_page.dart
```

---

### Issue: "Token not stored / Always logged out"

**Problem:**
- Token not persisting between app restarts
- Always redirected to login

**Solution:**

```dart
// Check FlutterSecureStorage is working
// File: lib/providers/auth_provider.dart

// Verify this code is present:
final storage = FlutterSecureStorage();

// In login:
await storage.write(
  key: 'auth_token',
  value: token
);

// In initialization:
final token = await storage.read(key: 'auth_token');
if (token != null) {
  // User is logged in
}
```

---

### Issue: "Null safety errors"

**Error Example:**
```
A value of type 'String?' can't be assigned to a variable of type 'String'
```

**Solution:**
```dart
// Add null check operator:
String email = userEmail!;  // Use ! when sure not null

// Or use null coalescing:
String email = userEmail ?? "";

// Or check before using:
if (userEmail != null) {
  print(userEmail);
}
```

---

### Issue: "Hot reload not working"

**Solutions:**
```bash
# 1. Stop and restart app
# Press 'q' to quit
# Run again: flutter run

# 2. Force full restart
flutter run --verbose

# 3. Clear build cache
flutter clean
flutter pub get
flutter run

# 4. Rebuild on code change
# Ctrl+S in your editor (or :r in flutter run terminal)
```

---

## 🔴 DATABASE ISSUES

### Issue: "Duplicate entry '...'"

**Error:**
```
Duplicate entry 'email@test.com' for key 'users.email'
```

**Cause:**
- User with that email already exists
- Unique constraint violated

**Solution:**

```bash
# 1. Delete duplicate user
mysql -u root -p smart_exam_invigilation
DELETE FROM users WHERE email='email@test.com';

# 2. Or use different email
# Or check if user already exists
SELECT * FROM users WHERE email='email@test.com';
```

---

### Issue: "Foreign key constraint failed"

**Error:**
```
Cannot add or update a child row: a foreign key constraint fails
```

**Cause:**
- Trying to reference non-existent parent record
- Exam doesn't exist when creating submission

**Solution:**

```bash
# Verify parent record exists
SELECT * FROM exams WHERE id=1;

# Check foreign key relationships
SELECT CONSTRAINT_NAME FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE TABLE_NAME='submissions';
```

---

### Issue: "Lost connection to MySQL server"

**Error:**
```
Lost connection to MySQL server during query
```

**Solutions:**

```bash
# 1. Check if MySQL is still running
tasklist /FI "IMAGENAME eq mysqld.exe"

# 2. Check connection limit
# Edit backend-nodejs/src/config/database.js
// Increase connectionLimit if needed:
const pool = mysql.createPool({
  connectionLimit: 20,  // Increase from 10
  // ...
});

# 3. Increase MySQL max_connections
SET GLOBAL max_connections = 1000;
```

---

## 🟢 QUICK FIXES CHECKLIST

Before troubleshooting further:

- [ ] MySQL is running: `tasklist /FI "IMAGENAME eq mysqld.exe"`
- [ ] Backend is running: `curl http://localhost:5000/api/health`
- [ ] `.env` has correct DB credentials
- [ ] DB schema is imported: `mysql -e "SHOW TABLES;" -u root -p smart_exam_invigilation`
- [ ] Backend dependencies installed: `backend-nodejs/node_modules/` exists
- [ ] Frontend dependencies installed: `frontend/.dart_tool/` exists
- [ ] Firewall allows port 5000
- [ ] No other app using port 5000

---

## ❓ FREQUENTLY ASKED QUESTIONS

### Q: How do I reset the database?

**A:**
```bash
# 1. Drop and recreate database
mysql -u root -p
DROP DATABASE smart_exam_invigilation;
CREATE DATABASE smart_exam_invigilation;
USE smart_exam_invigilation;
source backend-nodejs/schema.sql;

# Or in one command:
mysql -u root -p < backend-nodejs/schema.sql
```

---

### Q: How do I create a test user?

**A:**
```bash
# Use login endpoint to create accounts
curl -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Student",
    "email": "test@student.com",
    "password": "password123",
    "role": "student"
  }'
```

---

### Q: How do I backup my database?

**A:**
```bash
# Backup to file
mysqldump -u root -p smart_exam_invigilation > backup.sql

# Restore from backup
mysql -u root -p smart_exam_invigilation < backup.sql

# Backup all databases
mysqldump -u root -p --all-databases > full_backup.sql
```

---

### Q: How do I change the JWT secret?

**A:**
```bash
# Edit backend-nodejs/.env
JWT_SECRET=your-new-secret-key-here

# Restart backend server
# Kill current process and:
npm run dev
```

---

### Q: Why am I always logged out?

**A:**
- JWT token expired (default: 7 days)
- Token not stored properly
- Clear app cache: `flutter clean`
- Re-login

---

### Q: How do I test the API without Flutter?

**A:**
Use Postman or curl:

```bash
# 1. Login
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"john@school.com","password":"password123"}'

# 2. Copy token from response
# 3. Use in next requests:
curl -X GET http://localhost:5000/api/exams \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Or use Postman:**
1. Create new POST request
2. URL: `http://localhost:5000/api/auth/login`
3. Body → raw → JSON
4. Input credentials
5. Send
6. Copy token from response

---

### Q: Can I change the database from MySQL to SQLite?

**A:**
Not easily without code changes. MySQL is used throughout. To use SQLite:
- Rewrite schema.sql for SQLite syntax
- Change database config in `src/config/database.js`
- Update connection method
- Not recommended for production

---

### Q: How do I enable HTTPS?

**A:**
```javascript
// In server.js, use https module:
const https = require('https');
const fs = require('fs');

const options = {
  key: fs.readFileSync('path/to/key.pem'),
  cert: fs.readFileSync('path/to/cert.pem')
};

https.createServer(options, app).listen(5000);
```

---

### Q: How do I add more test data?

**A:**
```sql
-- Add more exams
INSERT INTO exams (teacher_id, title, description, duration, total_questions, passing_score)
VALUES (1, 'Physics Test', 'Test your physics knowledge', 45, 10, 60);

-- Add more questions
INSERT INTO questions (exam_id, question_text, option_a, option_b, option_c, option_d, correct_option, marks)
VALUES (1, 'What is the speed of light?', '3e8', '3e7', '3e9', '3e6', 'a', 1);

-- Connect via MySQL CLI:
mysql -u root -p smart_exam_invigilation < your_data.sql
```

---

### Q: How do I add authentication requirements?

**A:**
It's already implemented! All endpoints except `/login` and `/register` require JWT token in `Authorization` header.

---

### Q: Can I run this on a phone without WiFi?

**A:**
No, the app needs to connect to backend server. Options:
1. Use same WiFi network
2. Expose backend to internet (not recommended for dev)
3. Use tunneling service (ngrok)

---

### Q: How do I increase request timeout?

**A:**
```javascript
// In src/app.js
app.use(express.json({ 
  // increase timeout
  limit: '50mb'
}));

// In flutter/lib/services/api_service.dart
dio.options.connectTimeout = Duration(seconds: 30);
dio.options.receiveTimeout = Duration(seconds: 30);
```

---

## 📞 Getting Additional Help

If none of these solutions work:

1. **Check log files:**
   - Backend: Check terminal output for errors
   - Frontend: Run with `flutter run -v` for verbose output

2. **Enable debug logging:**
   - Backend: `DEBUG=* npm run dev`
   - Frontend: Add `print()` statements in code

3. **Verify all prerequisites:**
   - Node.js 18+
   - MySQL 8.0+
   - Flutter 3.13+
   - Internet connection

4. **Ask for help:**
   - Check DEVELOPER_REFERENCE.md
   - Review code comments
   - Check official documentation for each tool

---

## 🔧 System Requirements

**Minimum:**
- 4GB RAM
- 2 CPU cores
- 1GB free disk space
- Windows 10/Mac/Linux

**Recommended:**
- 8GB+ RAM
- 4+ CPU cores
- 5GB free disk space
- Latest OS version

---

**Last Updated:** February 2026  
**Version:** 1.0.0
