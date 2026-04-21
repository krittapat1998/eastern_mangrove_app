#!/bin/bash

# Test Login API
echo "🧪 Testing Login API..."
echo ""

# Test 1: Login with username
echo "Test 1: Login with username 'admin'"
curl -X POST https://eastern-mangrove-app.onrender.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "admin",
    "password": "admin123"
  }' | jq '.'

echo ""
echo "---"
echo ""

# Test 2: Check if email still works (should fail)
echo "Test 2: Login with email (should fail)"
curl -X POST https://eastern-mangrove-app.onrender.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@example.com",
    "password": "admin123"
  }' | jq '.'

echo ""
echo "---"
echo ""

# Test 3: Check database schema
echo "Test 3: Check if username column exists"
echo "Run this in your PostgreSQL:"
echo "SELECT column_name, data_type, is_nullable FROM information_schema.columns WHERE table_schema = 'eastern_mangrove_communities' AND table_name = 'users';"
