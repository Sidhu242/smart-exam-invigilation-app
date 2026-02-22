# Smart Exam Invigilation - Developer Reference

## Quick Commands

### Backend

```bash
# Install dependencies
npm install

# Start development server (with hot reload)
npm run dev

# Start production server
npm start

# Run tests
npm test
```

### Frontend

```bash
# Get dependencies
flutter pub get

# Run on default device
flutter run

# Run on specific device
flutter run -d <device-id>

# Build APK
flutter build apk --release

# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

---

## Project Architecture

### Backend Flow

```
Request Arrives
    ↓
Router (in routes/)
    ↓
Middleware (auth, role check)
    ↓
Controller (business logic)
    ↓
Database Query
    ↓
Response Sent Back
```

### Frontend Flow

```
User Action
    ↓
UI Page
    ↓
Provider (state management)
    ↓
ApiService (HTTP call)
    ↓
Backend API
    ↓
Update UI
```

---

## Key Files & Their Purpose

### Backend

| File | Purpose |
|------|---------|
| `server.js` | Entry point, starts Express server |
| `src/app.js` | Express configuration, middleware setup |
| `src/config/database.js` | MySQL connection pool |
| `src/middleware/authMiddleware.js` | JWT verification |
| `src/controllers/*.js` | Business logic for each feature |
| `src/routes/*.js` | API endpoint definitions |
| `.env` | Configuration & secrets |

### Frontend

| File | Purpose |
|------|---------|
| `lib/main.dart` | App entry point, routing setup |
| `lib/services/api_service.dart` | HTTP client (Dio) |
| `lib/providers/*.dart` | State management (Provider pattern) |
| `lib/pages/` | UI screens |
| `lib/utils/theme.dart` | App styling & colors |

---

## Database Schema Overview

```
Users
├── id, email, password, name, role
├── created_at, updated_at

Exams
├── id, teacher_id (FK Users), title, description
├── duration, total_questions, passing_score
├── is_published, created_at

Questions
├── id, exam_id (FK Exams)
├── question_text, option_a-d, correct_option
├── marks, created_at

Submissions
├── id, exam_id (FK Exams), student_id (FK Users)
├── total_score, is_submitted
├── submitted_at

Answers
├── id, submission_id (FK Submissions)
├── question_id (FK Questions)
├── selected_option, is_correct
├── marks_obtained

Violations
├── id, exam_id (FK Exams), student_id (FK Users)
├── violation_type, severity, description
├── logged_at
```

---

## Common Tasks

### Add a New API Endpoint

1. Create method in controller (`src/controllers/someController.js`)
2. Add route in routes file (`src/routes/someRoutes.js`)
3. Add middleware if needed (auth, roleValidator)
4. Test with Postman/curl

**Example:**
```javascript
// Controller
exports.getExample = async (req, res, next) => {
  try {
    const result = await db.query('SELECT * FROM table');
    res.json({ success: true, data: result });
  } catch (error) {
    next(error);
  }
};

// Route
router.get('/example', authMiddleware, exampleController.getExample);
```

### Update Flutter API Call

1. Add method in `ApiService` class
2. Use in Provider's method
3. Trigger from UI page

**Example:**
```dart
// In ApiService
Future<Map<String, dynamic>> getExample() async {
  final response = await dio.get('/endpoint');
  return response.data;
}

// In Provider
void fetchExample() {
  final result = await apiService.getExample();
  notifyListeners();
}

// In Page
Consumer<ExampleProvider>(
  builder: (context, provider, _) {
    return Text(provider.example);
  },
)
```

### Add Form Validation

**Backend (Joi):**
```javascript
const schema = Joi.object({
  email: Joi.string().email().required(),
  password: Joi.string().min(6).required(),
});
const { error, value } = schema.validate(data);
if (error) throw error;
```

**Frontend (Dart):**
```dart
String? validateEmail(String? value) {
  if (value == null || value.isEmpty) return 'Email required';
  if (!value.contains('@')) return 'Invalid email';
  return null;
}
```

---

## Debug Techniques

### Backend Debugging

```bash
# Enable detailed logging
DEBUG=* npm run dev

# Check database directly
mysql -u root -p smart_exam_invigilation
SELECT * FROM users;

# Test API with curl
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"pass"}'
```

### Frontend Debugging

```dart
// Add debug output
print('Data received: $data');
debugPrint('Error: $error');

// Check state
consumer(
  builder: (context, provider, _) {
    debugPrint('Provider state: ${provider.toString()}');
    return Text(provider.data.toString());
  }
)

// Network debugging
// Check DioException in api_service.dart
```

---

## Error Handling

### Backend Responses

**Success:** `{ "success": true, "data": {...} }`
**Error:** `{ "success": false, "error": "message", "code": 400 }`

**Status Codes:**
- 200: OK
- 201: Created
- 400: Bad Request
- 401: Unauthorized
- 403: Forbidden
- 404: Not Found
- 409: Conflict
- 500: Server Error

### Frontend Error Handling

```dart
try {
  final result = await apiService.someCall();
  // Handle success
} on DioException catch (e) {
  if (e.response?.statusCode == 401) {
    // Handle unauthorized
  } else {
    // Handle other errors
  }
}
```

---

## Performance Tips

### Backend
- Use database indexes (included in schema.sql)
- Pagination for large result sets
- Cache frequently accessed data
- Use connection pooling (already configured)

### Frontend
- Use `const` constructors for widgets
- Implement FutureCache for API responses
- Lazy load lists with ListView.builder
- Use Provider.select() to rebuild only necessary widgets

---

## Testing

### Manual API Testing

Use the provided test credentials:
- **Student:** alice@student.com / password123
- **Teacher:** john@school.com / password123

**Flow to test:**
1. Login → Get JWT token
2. Create exam (as teacher)
3. View exams (as student)
4. Start exam
5. Submit answers
6. Check results

### Automated Testing

```bash
# Backend
npm test

# Frontend
flutter test
```

---

## Deployment Checklist

- [ ] Update all environment variables
- [ ] Change JWT_SECRET to strong value
- [ ] Enable HTTPS/SSL
- [ ] Configure firewall rules
- [ ] Set database backups
- [ ] Enable logging & monitoring
- [ ] Test all endpoints
- [ ] Verify email notifications (if any)
- [ ] Check CORS settings
- [ ] Review security headers

---

## Useful Resources

- **Node.js Docs:** https://nodejs.org/docs/
- **Express Docs:** https://expressjs.com/
- **Flutter Docs:** https://flutter.dev/docs
- **MySQL Docs:** https://dev.mysql.com/doc/
- **JWT Intro:** https://jwt.io/introduction

---

## Getting Help

1. Check error logs first
2. Search database schema for table structure
3. Review API endpoint documentation
4. Check provider state in Flutter DevTools
5. Use debugger/breakpoints
6. Add console.log/print statements

---

**Last Updated:** February 2026  
**Version:** 1.0.0
