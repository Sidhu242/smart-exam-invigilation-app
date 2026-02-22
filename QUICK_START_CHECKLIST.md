# Smart Exam Invigilation System - Quick Start Checklist

## ✅ PRE-INSTALLATION CHECKLIST

### System Requirements
- [ ] Windows 10+ / Mac / Linux
- [ ] 4GB+ RAM available
- [ ] 5GB+ free disk space
- [ ] Administrator access

### Software Prerequisites
- [ ] Node.js 18+ installed
  - Download from: https://nodejs.org/
  - Verify: `node -v`
- [ ] MySQL 8.0+ installed
  - Download from: https://www.mysql.com/downloads/mysql/
  - Verify: `mysql --version`
- [ ] Flutter 3.13+ installed
  - Download from: https://flutter.dev/
  - Verify: `flutter --version`

### Internet & Ports
- [ ] Internet connection available
- [ ] Port 5000 not in use (backend)
- [ ] Port 3306 not in use (MySQL)
- [ ] Firewall allows connections

---

## 📥 INSTALLATION STEPS

### Step 1: Set Up Database (5 minutes)

```bash
[ ] Start MySQL service
    Windows: Services → MySQL → Start
    Mac: brew services start mysql@8.0
    Linux: sudo service mysql start

[ ] Create database
    mysql -u root -p < backend-nodejs/schema.sql

[ ] Verify
    mysql -u root -p -e "USE smart_exam_invigilation; SHOW TABLES;"
    Should show: 6 tables
```

### Step 2: Set Up Backend (10 minutes)

```bash
[ ] Navigate to backend folder
    cd backend-nodejs

[ ] Install dependencies
    npm install

[ ] Copy environment file
    cp .env.example .env

[ ] Edit .env with your MySQL credentials
    DB_HOST=localhost
    DB_USER=root
    DB_PASSWORD=your_mysql_password

[ ] Start server
    npm run dev

[ ] Test server
    Open: http://localhost:5000/api/health
    Should return: {"status":"success",...}
```

### Step 3: Set Up Frontend (10 minutes)

```bash
[ ] Navigate to frontend folder
    cd frontend

[ ] Get dependencies
    flutter pub get

[ ] Find your computer's IP address
    Windows: Command Prompt → ipconfig
    Mac/Linux: Terminal → ifconfig

[ ] Update API base URL
    Edit: lib/services/api_service.dart
    Change baseUrl to: http://YOUR_IP:5000/api
    For Android Emulator use: http://10.0.2.2:5000/api

[ ] Start Flutter app
    flutter run
    or select device: flutter run -d <device_id>

[ ] Verify app loads
    Should see login screen
```

---

## 🔐 FIRST TIME LOGIN

### Test Accounts Available

**Teacher Account:**
```
Email: john@school.com
Password: password123
```

**Student Account:**
```
Email: alice@student.com
Password: password123
```

### Login Flow
```
[ ] Open Flutter app
[ ] See login screen
[ ] Enter teacher credentials
[ ] Tap "Sign In"
[ ] Should redirect to teacher dashboard
[ ] Log out
[ ] Try student account
[ ] Should redirect to student dashboard
```

---

## 🧪 BASIC FUNCTIONALITY TEST (30 minutes)

### Teacher Flow
```
[ ] Login as teacher (john@school.com)
[ ] Tap "Create New Exam"
[ ] Fill exam details:
    - Title: Test Exam
    - Duration: 30 minutes
    - Passing Score: 60
[ ] Save exam
[ ] Add questions:
    - Add 5 multiple choice questions
    - Fill all 4 options
    - Select correct answer
[ ] Save questions
[ ] Publish exam
```

### Student Flow
```
[ ] Login as student (alice@student.com)
[ ] See "Test Exam" in available exams
[ ] Tap "Start Exam"
[ ] Answer all questions
[ ] Review answers
[ ] Submit exam
[ ] See score and results
[ ] Review answers with correct indicators
```

---

## 📁 PROJECT STRUCTURE CHECK

Verify all files are in place:

```
backend-nodejs/
├── src/
│   ├── config/
│   │   └── database.js           [ ]
│   ├── middleware/
│   │   ├── authMiddleware.js     [ ]
│   │   ├── roleValidator.js      [ ]
│   │   └── errorHandler.js       [ ]
│   ├── controllers/
│   │   ├── authController.js     [ ]
│   │   ├── examController.js     [ ]
│   │   ├── questionController.js [ ]
│   │   ├── submissionController.js [ ]
│   │   └── violationController.js  [ ]
│   ├── routes/
│   │   ├── authRoutes.js         [ ]
│   │   ├── examRoutes.js         [ ]
│   │   ├── questionRoutes.js     [ ]
│   │   ├── submissionRoutes.js   [ ]
│   │   └── violationRoutes.js    [ ]
│   └── app.js                    [ ]
├── server.js                     [ ]
├── package.json                  [ ]
├── .env                          [ ]
├── .env.example                  [ ]
└── schema.sql                    [ ]

frontend/
├── lib/
│   ├── main.dart                 [ ]
│   ├── services/
│   │   └── api_service.dart      [ ]
│   ├── providers/
│   │   ├── auth_provider.dart    [ ]
│   │   └── exam_provider.dart    [ ]
│   ├── pages/
│   │   ├── auth/                 [ ] (pages to be created)
│   │   ├── student/              [ ] (pages to be created)
│   │   └── teacher/              [ ] (pages to be created)
│   ├── widgets/                  [ ] (to be created)
│   ├── utils/
│   │   └── theme.dart            [ ]
│   └── models/                   [ ] (to be created)
└── pubspec.yaml                  [ ]
```

---

## 🔧 COMMON CONFIGURATIONS

### Change Backend Port
```bash
Edit: backend-nodejs/.env
OLD: PORT=5000
NEW: PORT=8080

Then edit: frontend/lib/services/api_service.dart
OLD: static const String baseUrl = 'http://...5000/api';
NEW: static const String baseUrl = 'http://...8080/api';
```

### Change MySQL Password
```bash
# Update .env
Edit: backend-nodejs/.env
DB_PASSWORD=YourNewPassword

# MySQL CLI
mysql -u root -p
ALTER USER 'root'@'localhost' IDENTIFIED BY 'NewPassword';
FLUSH PRIVILEGES;
```

### Change JWT Secret
```bash
Edit: backend-nodejs/.env
JWT_SECRET=YourVeryLongSecretKeyHere
```

### Enable CORS for Different Origin
```bash
Edit: backend-nodejs/.env
CORS_ORIGIN=https://yourdomain.com
```

---

## 📝 DAILY STARTUP PROCEDURE

### Opening Session

```bash
# Terminal 1: Start MySQL
[ ] Start MySQL (Windows Services)

# Terminal 2: Start Backend
[ ] cd backend-nodejs
[ ] npm run dev
[ ] Verify: curl http://localhost:5000/api/health

# Terminal 3: Start Flutter
[ ] cd frontend
[ ] flutter run
[ ] Select device when prompted

# All Running?
[ ] Backend terminal shows "Server running on port 5000"
[ ] Flutter terminal shows "app started - "
[ ] App appears on device/emulator
```

### Closing Session

```bash
[ ] Close Flutter app (q in terminal or close window)
[ ] Stop backend server (Ctrl+C in terminal)
[ ] Stop MySQL
[ ] Close all terminals
```

---

## 🐛 QUICK TROUBLESHOOTING

### Backend won't start
```bash
[ ] MySQL running?              → Start MySQL
[ ] Port 5000 in use?           → netstat -ano | findstr :5000
[ ] .env file present?          → cp .env.example .env
[ ] Dependencies installed?     → npm install
[ ] npm run dev                 → Try again
```

### Flutter can't connect
```bash
[ ] Backend running?            → Check Terminal 2
[ ] Correct IP in api_service.dart?
    Emulator: 10.0.2.2:5000
    Device: YOUR_IP:5000
    Web: localhost:5000
[ ] Firewall allowing port 5000? → Check Windows Firewall
[ ] Try: flutter run -v         → See full error
```

### Database not found
```bash
[ ] MySQL running?              → Start service
[ ] Database created?           → mysql -e "SHOW DATABASES;"
[ ] Schema imported?            → mysql -u root -p < schema.sql
```

---

## 📊 VERIFICATION CHECKLIST

### Backend Verification

```bash
[ ] npm install completed without errors
[ ] npm run dev shows "Server running on port 5000"
[ ] curl http://localhost:5000/api/health returns JSON
[ ] MySQL connection successful (check console)
[ ] No "EADDRINUSE" errors
[ ] No "connection refused" errors
```

### Database Verification

```bash
[ ] mysql connection works
[ ] Database "smart_exam_invigilation" exists
[ ] All 6 tables created
[ ] Sample data loaded
[ ] No missing tables error
```

### Frontend Verification

```bash
[ ] flutter pub get completed
[ ] flutter run shows device selection
[ ] App loads on device/emulator
[ ] Login screen appears
[ ] No connection errors in logs
```

---

## 📱 DEVICE TESTING CHECKLIST

### Android Emulator
```bash
[ ] Android Studio installed
[ ] Emulator created
[ ] flutter emulators --launch Pixel_3_API_30
[ ] flutter devices shows emulator
[ ] flutter run selects emulator
[ ] App runs on emulator
```

### iOS Simulator (Mac only)
```bash
[ ] Xcode installed
[ ] flutter devices shows simulator
[ ] flutter run selects simulator
[ ] App runs on simulator
```

### Physical Device
```bash
[ ] USB cable connected
[ ] Developer mode enabled
[ ] USB Debugging enabled
[ ] Trust computer prompt accepted
[ ] flutter devices shows device
[ ] flutter run selects device
[ ] App runs on device
```

---

## 💾 BACKUP CHECKLIST

### Before Making Changes
```bash
[ ] Backup database
    mysqldump -u root -p smart_exam_invigilation > backup.sql

[ ] Backup .env file
    cp backend-nodejs/.env backend-nodejs/.env.backup

[ ] Backup frontend API service
    cp frontend/lib/services/api_service.dart api_service.dart.backup
```

### Restore from Backup
```bash
# Database
mysql -u root -p smart_exam_invigilation < backup.sql

# .env
cp backend-nodejs/.env.backup backend-nodejs/.env

# Files
# Manual copy/paste from backup files
```

---

## 🚀 DEPLOYMENT PREPARATION

### Before Production
```bash
[ ] Change JWT_SECRET to strong random value
[ ] Update CORS_ORIGIN to production domain
[ ] Change NODE_ENV to production
[ ] Update database credentials
[ ] Review security settings
[ ] Enable HTTPS
[ ] Set up SSL certificates
[ ] Configure firewall rules
[ ] Set up database backups
[ ] Test all endpoints
[ ] Monitor application logs
```

### Production Build
```bash
[ ] Backend: npm start
[ ] Frontend: flutter build apk --release
[ ] Upload to app store (if desired)
[ ] Set up monitoring/alerting
```

---

## 📞 HELP RESOURCES

| Issue | Resource |
|-------|----------|
| Backend errors | TROUBLESHOOTING_FAQ.md |
| Frontend errors | TROUBLESHOOTING_FAQ.md |
| API reference | DEVELOPER_REFERENCE.md |
| Setup help | COMPLETE_SETUP_GUIDE.md |
| Architecture | IMPLEMENTATION_SUMMARY.md |

---

## ✨ EXPECTED BEHAVIOR

### When Everything Works Correctly

✅ **Backend**
- Server starts without errors
- Health check returns JSON
- No console errors
- Database queries work

✅ **Frontend**
- App loads on device
- Login screen appears (no errors)
- Navigation works
- API calls succeed

✅ **User Flow**
- Teacher can create exams
- Students can take exams
- Scores calculate automatically
- Results display correctly

---

## 📋 SIGN-OFF CHECKLIST

System is ready when all items are checked:

```
SETUP COMPLETE
[ ] Database running and populated
[ ] Backend server running
[ ] Frontend app running
[ ] Login works for both roles
[ ] Teacher can create exam
[ ] Student can take exam
[ ] Results display correctly
[ ] No errors in consoles

READY FOR DEVELOPMENT
[ ] All systems documented
[ ] Quick start guide understood
[ ] Troubleshooting reference available
[ ] Backup procedures established
[ ] Development workflow clear
```

---

## 🎯 NEXT STEPS

After completing this checklist:

1. **Immediate (Today)**
   - [ ] Complete all checklists above
   - [ ] Test login for both roles
   - [ ] Create test exam and submit

2. **This Week**
   - [ ] Build remaining UI pages
   - [ ] Test complete workflows
   - [ ] Fix any integration issues

3. **Next Week**
   - [ ] Add invigilation features
   - [ ] Implement custom widgets
   - [ ] Performance optimization

4. **Before Deployment**
   - [ ] Load testing
   - [ ] Security audit
   - [ ] Final user testing
   - [ ] Documentation review

---

## 📞 EMERGENCY CONTACTS

**When everything breaks:**

```bash
# Full system reset
1. Stop all services (Ctrl+C in terminals)
2. Kill any stuck processes: netstat -ano
3. Restart MySQL
4. Delete backend node_modules: rm -rf backend-nodejs/node_modules
5. Reinstall: cd backend-nodejs && npm install
6. Restart backend: npm run dev
7. flutter clean
8. flutter pub get
9. flutter run
```

---

**Created:** February 2026  
**Version:** 1.0.0  
**Status:** ✅ READY TO USE

Print this checklist and check off items as you progress through setup!
