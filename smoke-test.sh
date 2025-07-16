#!/bin/bash

# Smoke Test Script for Flask Application
# This script performs basic health checks on the deployed application

set -e

APP_URL=${1:-"http://localhost:8080"}
TIMEOUT=${2:-30}

echo "🧪 Starting smoke tests for Flask application"
echo "📍 Target URL: $APP_URL"
echo "⏱️  Timeout: ${TIMEOUT}s"

# Function to check HTTP response
check_http_response() {
    local url=$1
    local expected_code=$2
    local description=$3
    
    echo "🔍 Testing: $description"
    
    response=$(curl -s -o /dev/null -w "%{http_code}" --max-time $TIMEOUT "$url")
    
    if [ "$response" = "$expected_code" ]; then
        echo "✅ PASS: $description (HTTP $response)"
        return 0
    else
        echo "❌ FAIL: $description (Expected: $expected_code, Got: $response)"
        return 1
    fi
}

# Function to check response content
check_content() {
    local url=$1
    local expected_content=$2
    local description=$3
    
    echo "🔍 Testing: $description"
    
    content=$(curl -s --max-time $TIMEOUT "$url")
    
    if [[ "$content" == *"$expected_content"* ]]; then
        echo "✅ PASS: $description"
        return 0
    else
        echo "❌ FAIL: $description"
        echo "   Expected: $expected_content"
        echo "   Got: $content"
        return 1
    fi
}

# Test 1: Basic connectivity
echo ""
echo "🚀 Test 1: Basic Connectivity"
check_http_response "$APP_URL" "200" "Application responds to GET /"

# Test 2: Content verification
echo ""
echo "🚀 Test 2: Content Verification"
check_content "$APP_URL" "Hello, World!" "Application returns expected content"

# Test 3: Response time check
echo ""
echo "🚀 Test 3: Response Time Check"
response_time=$(curl -s -o /dev/null -w "%{time_total}" --max-time $TIMEOUT "$APP_URL")
response_time_ms=$(echo "$response_time * 1000" | bc)

if (( $(echo "$response_time < 2.0" | bc -l) )); then
    echo "✅ PASS: Response time acceptable (${response_time_ms}ms)"
else
    echo "⚠️  WARN: Response time slow (${response_time_ms}ms)"
fi

echo ""
echo "🎉 Smoke tests completed successfully!"
echo "📊 All critical tests passed"