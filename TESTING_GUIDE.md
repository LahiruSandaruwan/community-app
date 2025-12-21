# Testing Guide - Migration System & Role Fix

## 🎯 Purpose

This guide helps you test the new automated migration system and verify that the tutor/student role issue is fixed.

## 📋 Pre-Test Checklist

- [ ] PocketBase server is stopped
- [ ] Flutter app is closed
- [ ] You're on the `development` branch

```bash
git checkout development
git pull origin development
```

## 🧪 Test 1: Fresh Database Setup

### Goal
Verify migrations create complete database schema automatically.

### Steps

1. **Clean slate**:
   ```bash
   cd pocketbase
   rm -rf pb_data
   ```

2. **Start PocketBase**:
   ```bash
   ./pocketbase serve
   ```

3. **Create admin account** (in browser):
   - Go to: `http://127.0.0.1:8090/_/`
   - Email: `admin@test.local`
   - Password: `admin123456`
   - Click "Create"

4. **Run migrations**:
   ```bash
   # In a new terminal
   cd pocketbase
   ./migrate.sh
   ```

5. **Expected output**:
   ```
   ╔════════════════════════════════════════════════╗
   ║  EduConnect PocketBase Migration Runner       ║
   ╚════════════════════════════════════════════════╝

   🔍 Checking if PocketBase is running...
   ✅ PocketBase is running

   🔄 Running migration: 001_update_users_collection
   ✅ Migration 001_update_users_collection completed successfully

   🔄 Running migration: 002_create_communities_collection
   ✅ Migration 002_create_communities_collection completed successfully

   ... (continues for all migrations)

   ╔════════════════════════════════════════════════╗
   ║           Migration Summary                    ║
   ╠════════════════════════════════════════════════╣
   ║  Total migrations: 5                           ║
   ║  Successful: 5                                 ║
   ║  Failed: 0                                     ║
   ╚════════════════════════════════════════════════╝

   🎉 All migrations completed successfully!
   ```

6. **Verify in Admin UI**:
   - Go to: `http://127.0.0.1:8090/_/`
   - Click "Collections"
   - Verify these collections exist:
     - [ ] users (click and check "role" field exists)
     - [ ] communities
     - [ ] groupChats
     - [ ] messages
     - [ ] polls
     - [ ] assignments
     - [ ] bookmarks
     - [ ] attendanceSessions
     - [ ] userStats
     - [ ] resources
     - [ ] typing

7. **Check role field specifically**:
   - Click "users" collection
   - Click "Fields" tab
   - Verify "role" field:
     - [ ] Type: Select
     - [ ] Options: student, tutor
     - [ ] Required: Yes

### ✅ Test 1 Pass Criteria

- All 5 migrations completed successfully
- All 11 collections exist
- Users collection has "role" field as Select type
- No errors in migration output

---

## 🧪 Test 2: Seeders (Test Data)

### Goal
Verify seeders populate database with sample data.

### Steps

1. **Run seeders**:
   ```bash
   cd pocketbase
   ./seed.sh
   ```

2. **Expected output**:
   ```
   🌱 Running seeders...

   🌱 Running seeder: 001_seed_users
   👥 Creating sample users...
   Creating tutors...
     ✅ Created tutor: Dr. Sarah Johnson (tutor1@educonnect.com)
     ✅ Created tutor: Prof. Michael Chen (tutor2@educonnect.com)
     ✅ Created tutor: Ms. Emily Davis (tutor3@educonnect.com)

   Creating students...
     ✅ Created student: John Smith (student1@educonnect.com)
     ... (continues for all students)

   ✅ Seeder 001_seed_users completed

   🌱 Running seeder: 002_seed_communities
   ... (creates communities)

   🎉 All seeders completed successfully!
   ```

3. **Verify in Admin UI**:
   - Go to: `http://127.0.0.1:8090/_/`
   - Click "users" collection
   - Verify:
     - [ ] 11 users total (3 tutors + 8 students)
     - [ ] tutor1@educonnect.com has role = "tutor"
     - [ ] student1@educonnect.com has role = "student"

4. **Check communities**:
   - Click "communities" collection
   - Verify:
     - [ ] 3 communities exist
     - [ ] Mathematics 101 has inviteCode = "MATH101"

### ✅ Test 2 Pass Criteria

- All seeders completed successfully
- 11 users created with correct roles
- 3 communities created with invite codes
- No errors in seeder output

---

## 🧪 Test 3: Role Field Fix (THE MAIN FIX!)

### Goal
Verify tutor accounts can be created correctly in the Flutter app.

### Steps

1. **Start the Flutter app**:
   ```bash
   # In project root
   flutter run
   ```

2. **Test tutor registration**:
   - In the app, click "Create Account"
   - Fill in form:
     - Name: `Test Tutor`
     - Email: `testtutor@test.com`
     - Phone: `1234567890`
     - **Select "Tutor" role** ⭐ (This is the critical test!)
     - Password: `testpass123`
     - Confirm Password: `testpass123`
   - Click "Create Account"

3. **Expected behavior**:
   - [ ] No error message appears
   - [ ] Account created successfully
   - [ ] App navigates to home screen
   - [ ] Check terminal logs for DEBUG messages:
     ```
     DEBUG: Registration screen - Selected role: tutor
     [DEBUG] Creating user with data: name=Test Tutor, email=testtutor@test.com, role=tutor
     [DEBUG] Record role field: tutor
     [DEBUG] UserModel created with role: tutor
     ```

4. **Verify in PocketBase Admin**:
   - Go to: `http://127.0.0.1:8090/_/`
   - Click "users" collection
   - Find `testtutor@test.com`
   - Verify:
     - [ ] **role = "tutor"** (NOT student!)
     - [ ] name = "Test Tutor"
     - [ ] phoneNumber = "1234567890"

5. **Test student registration**:
   - Logout from app
   - Create new account:
     - Name: `Test Student`
     - Email: `teststudent@test.com`
     - **Select "Student" role**
     - Password: `testpass123`
   - Verify in Admin UI:
     - [ ] role = "student"

### ✅ Test 3 Pass Criteria

- Tutor account created with role = "tutor" ⭐
- Student account created with role = "student"
- No error messages in app
- Debug logs show correct role throughout signup process
- **THE BUG IS FIXED!** 🎉

---

## 🧪 Test 4: Login with Test Accounts

### Goal
Verify test accounts from seeders work correctly.

### Steps

1. **Login as tutor**:
   - Email: `tutor1@educonnect.com`
   - Password: `password123`
   - [ ] Login successful
   - [ ] No errors

2. **Verify tutor permissions**:
   - [ ] Can see "Create Community" option (if implemented)
   - [ ] Profile shows role as Tutor

3. **Logout and login as student**:
   - Email: `student1@educonnect.com`
   - Password: `password123`
   - [ ] Login successful
   - [ ] Profile shows role as Student

4. **Test community join**:
   - As student, try joining community with code: `MATH101`
   - [ ] Successfully joins "Mathematics 101" community

### ✅ Test 4 Pass Criteria

- Can login with seeded tutor account
- Can login with seeded student account
- Roles are correctly displayed
- Community join works

---

## 🧪 Test 5: Idempotency (Re-running Migrations)

### Goal
Verify migrations can be safely run multiple times.

### Steps

1. **Run migrations again**:
   ```bash
   cd pocketbase
   ./migrate.sh
   ```

2. **Expected output**:
   ```
   ⚠️  Collection already exists, skipping...
   ```
   (Multiple times for each collection)

3. **Verify**:
   - [ ] No errors occurred
   - [ ] No duplicate collections created
   - [ ] Existing data not lost

### ✅ Test 5 Pass Criteria

- Migrations complete without errors
- No duplicate collections
- Existing data preserved
- Script shows "already exists" warnings (expected)

---

## 📊 Final Verification Checklist

After completing all tests:

- [ ] All 5 tests passed
- [ ] Tutor role field works correctly ⭐
- [ ] Student role field works correctly
- [ ] Migrations are idempotent
- [ ] Seeders create test data
- [ ] Can login with test accounts
- [ ] No errors in PocketBase logs
- [ ] No errors in Flutter logs

## 🐛 If Tests Fail

### Migration Fails

**Check**:
1. PocketBase is running
2. Admin credentials are correct
3. No firewall blocking localhost:8090

**Fix**:
```bash
# Reset everything
cd pocketbase
rm -rf pb_data
./pocketbase serve
# Create admin again
./migrate.sh
```

### Role Still Shows as Student

**Check**:
1. Did migrations run successfully?
2. Is role field in users collection?
3. Check terminal DEBUG logs

**Fix**:
```bash
# Hot restart the app
# Press 'R' in Flutter terminal
```

### Cannot Login with Test Accounts

**Check**:
1. Did seeders run?
2. Check users in Admin UI

**Fix**:
```bash
cd pocketbase
./seed.sh
```

## 📝 Test Report Template

Copy this and fill in your results:

```
## Test Results

**Date**: [Date]
**Tester**: [Your Name]
**Branch**: development

### Test 1: Fresh Database Setup
- Status: [ ] Pass [ ] Fail
- Notes:

### Test 2: Seeders
- Status: [ ] Pass [ ] Fail
- Notes:

### Test 3: Role Field Fix
- Status: [ ] Pass [ ] Fail
- Notes:

### Test 4: Login with Test Accounts
- Status: [ ] Pass [ ] Fail
- Notes:

### Test 5: Idempotency
- Status: [ ] Pass [ ] Fail
- Notes:

### Overall Result
- [ ] All tests passed ✅
- [ ] Some tests failed ❌

### Issues Found
[List any issues]

### Screenshots
[Attach relevant screenshots]
```

---

**Created**: December 21, 2025
**Branch**: development
**Purpose**: Verify automated migration system and role field fix
