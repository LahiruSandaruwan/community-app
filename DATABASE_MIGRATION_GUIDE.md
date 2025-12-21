# PocketBase Database Migration & Seeding Guide

This guide explains how to use the automated database migration and seeding system for EduConnect.

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Migrations](#migrations)
- [Seeders](#seeders)
- [Troubleshooting](#troubleshooting)
- [Advanced Usage](#advanced-usage)

## Overview

The migration system automates the setup of your PocketBase database schema and test data, eliminating manual configuration through the admin UI.

### What's Included

**Migrations:** Automated schema creation
- `001_update_users_collection.sh` - Adds custom fields to users (role, phoneNumber, etc.)
- `002_create_communities_collection.sh` - Creates communities collection
- `003_create_groupchats_collection.sh` - Creates groupChats collection
- `004_create_messages_collection.sh` - Creates messages collection
- `005_create_additional_collections.sh` - Creates polls, assignments, bookmarks, etc.

**Seeders:** Sample test data
- `001_seed_users.sh` - Creates 3 tutors and 8 students
- `002_seed_communities.sh` - Creates 3 sample communities

## Quick Start

### Prerequisites

1. PocketBase server must be running
2. Admin account must be created (first-time setup only)

### Step 1: Start PocketBase

```bash
cd pocketbase
./pocketbase serve
```

### Step 2: Create Admin Account (First Time Only)

1. Open browser: `http://127.0.0.1:8090/_/`
2. Create admin account (e.g., `admin@local.com` / `password123`)

### Step 3: Run Migrations

```bash
cd pocketbase
./migrate.sh
```

When prompted, enter your admin credentials.

### Step 4: Seed Test Data (Optional)

```bash
cd pocketbase
./seed.sh
```

This creates sample users and communities for testing.

## Migrations

### Running All Migrations

```bash
cd pocketbase
./migrate.sh
```

### Running Individual Migrations

```bash
cd pocketbase/migrations
./001_update_users_collection.sh
```

### Using Environment Variables

Set these to avoid repeated credential prompts:

```bash
export POCKETBASE_URL="http://127.0.0.1:8090"
export POCKETBASE_ADMIN_EMAIL="admin@local.com"
export POCKETBASE_ADMIN_PASSWORD="your_password"

./migrate.sh
```

### What Gets Created

After running migrations, you'll have these collections:

| Collection | Description |
|-----------|-------------|
| `users` | User accounts with role (tutor/student) |
| `communities` | Learning communities created by tutors |
| `groupChats` | Group chats within communities |
| `messages` | Chat messages with multiple types |
| `polls` | Interactive polls for engagement |
| `assignments` | Homework assignments with submissions |
| `bookmarks` | Saved messages |
| `attendanceSessions` | Attendance tracking |
| `userStats` | Gamification points and achievements |
| `resources` | File uploads and resources |
| `typing` | Real-time typing indicators |

## Seeders

### Running All Seeders

```bash
cd pocketbase
./seed.sh
```

### Running Individual Seeders

```bash
cd pocketbase/seeders
./001_seed_users.sh
./002_seed_communities.sh
```

### Test Data Created

**Users:**
- 3 Tutors:
  - `tutor1@educonnect.com` / `password123`
  - `tutor2@educonnect.com` / `password123`
  - `tutor3@educonnect.com` / `password123`

- 8 Students:
  - `student1@educonnect.com` / `password123`
  - `student2@educonnect.com` / `password123`
  - ... (student3 through student8)

**Communities:**
- Mathematics 101 (Code: `MATH101`)
- Physics Advanced (Code: `PHYS201`)
- Coding Bootcamp (Code: `CODE301`)

### Using Test Data

1. Open the EduConnect app
2. Login as tutor: `tutor1@educonnect.com` / `password123`
3. Or login as student: `student1@educonnect.com` / `password123`
4. Students can join communities using invite codes

## Troubleshooting

### PocketBase Not Running

**Error:** `PocketBase is not running at http://127.0.0.1:8090`

**Solution:**
```bash
cd pocketbase
./pocketbase serve
```

### Authentication Failed

**Error:** `Authentication failed. Please check your credentials.`

**Solution:**
1. Verify admin account exists at `http://127.0.0.1:8090/_/`
2. Use correct email/password
3. Create admin account if first-time setup

### Collection Already Exists

**Warning:** `Collection already exists, skipping...`

**This is normal!** Migrations skip existing collections. To reset:

```bash
# Stop PocketBase
# Delete database
rm -rf pocketbase/pb_data

# Restart PocketBase
./pocketbase serve

# Create admin account again
# Run migrations
./migrate.sh
```

### Migration Failed

**Error:** `Migration failed`

**Solution:**
1. Check PocketBase logs for detailed errors
2. Verify PocketBase version compatibility
3. Ensure admin has proper permissions
4. Try running individual migration to isolate issue

### Seeder Created Duplicate Users

**Error:** `User already exists`

**This is expected!** Seeders skip existing records. To reset test data:

```bash
# Delete pb_data and rerun migrations + seeders
rm -rf pocketbase/pb_data
./pocketbase serve
# Then run migrate.sh and seed.sh
```

## Advanced Usage

### Fresh Database Reset

Complete reset for development:

```bash
# 1. Stop PocketBase (Ctrl+C)

# 2. Delete database
rm -rf pocketbase/pb_data

# 3. Start PocketBase
cd pocketbase
./pocketbase serve

# 4. Create admin (in browser: http://127.0.0.1:8090/_/)

# 5. Run migrations
./migrate.sh

# 6. Seed test data
./seed.sh
```

### CI/CD Integration

For automated environments:

```bash
# Set credentials in environment
export POCKETBASE_ADMIN_EMAIL="ci@educonnect.com"
export POCKETBASE_ADMIN_PASSWORD="$SECURE_PASSWORD"

# Run migrations
cd pocketbase
./migrate.sh

# Optionally seed (only for test environments)
./seed.sh
```

### Custom Migration Port

```bash
export POCKETBASE_URL="http://localhost:9090"
./migrate.sh
```

### Production Deployment

**⚠️ WARNING:** Never run seeders in production!

```bash
# Production: Only run migrations
export POCKETBASE_URL="https://api.yourdomain.com"
export POCKETBASE_ADMIN_EMAIL="admin@yourdomain.com"
export POCKETBASE_ADMIN_PASSWORD="$SECURE_PASSWORD"

./migrate.sh
# DO NOT run seed.sh in production
```

## Migration Workflow

### Development Workflow

```bash
# Day 1: Initial setup
./migrate.sh
./seed.sh

# Day 2+: Fresh start each day (optional)
rm -rf pb_data
./pocketbase serve  # Create admin
./migrate.sh
./seed.sh
```

### Team Workflow

When pulling latest code:

```bash
git pull origin development

# If migrations were added:
cd pocketbase
./migrate.sh  # Run new migrations
```

### Creating New Migrations

1. Create new file: `pocketbase/migrations/006_your_migration.sh`
2. Follow existing migration pattern
3. Make it idempotent (safe to run multiple times)
4. Test locally before committing

Example template:

```bash
#!/bin/bash

MIGRATION_NAME="006_your_migration"
# ... authentication code ...

# Your migration logic here
COLLECTION_SCHEMA='{
  "name": "your_collection",
  "type": "base",
  "schema": [...]
}'

# Create collection
RESPONSE=$(curl -s -X POST "$BASE_URL/api/collections" ...)
```

## Best Practices

1. **Always run migrations before seeders**
   ```bash
   ./migrate.sh  # First
   ./seed.sh     # Second
   ```

2. **Don't edit existing migrations** - Create new ones instead

3. **Use environment variables** in CI/CD

4. **Test migrations locally** before pushing

5. **Never commit admin credentials** to git

6. **Document schema changes** in migration files

## Files Structure

```
pocketbase/
├── migrate.sh                   # Master migration runner
├── seed.sh                      # Master seeder runner
├── migrations/
│   ├── 001_update_users_collection.sh
│   ├── 002_create_communities_collection.sh
│   ├── 003_create_groupchats_collection.sh
│   ├── 004_create_messages_collection.sh
│   └── 005_create_additional_collections.sh
└── seeders/
    ├── 001_seed_users.sh
    └── 002_seed_communities.sh
```

## Support

If you encounter issues:

1. Check PocketBase logs
2. Verify admin credentials
3. Review [PocketBase API docs](https://pocketbase.io/docs/)
4. Check this guide's troubleshooting section
5. Delete `pb_data` and start fresh if needed

---

**Last Updated:** December 2025
**PocketBase Version:** 0.20+
**EduConnect Version:** 1.0.0
