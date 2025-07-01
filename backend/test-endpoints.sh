#!/bin/bash

echo "Testing Backend Endpoints..."
echo "================================"

# Test root endpoint
echo "1. Testing root endpoint (/):"
curl -s http://localhost:8080/ | jq . || echo "Backend not running or jq not installed"
echo ""

# Test health endpoint
echo "2. Testing health endpoint (/health):"
curl -s http://localhost:8080/health | jq . || echo "Backend not running or jq not installed"
echo ""

echo "If you see JSON responses above, the backend is working!"
echo "If not, run: go run cmd/server/main.go"
echo ""
echo "For frontend, run: cd ../frontend && npm run dev"