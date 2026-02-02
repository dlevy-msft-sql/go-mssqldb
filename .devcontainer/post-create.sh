#!/bin/bash
set -e

echo "=== go-mssqldb Development Container Setup ==="

# Download Go dependencies
echo "📦 Downloading Go dependencies..."
cd /workspaces/go-mssqldb
go mod download

# Verify build works
echo "🔨 Verifying build..."
go build ./...

# Wait for SQL Server to be ready (health check should have done this, but let's verify)
echo "🔄 Verifying SQL Server connection using go-sqlcmd (uses this driver!)..."
max_attempts=30
attempt=1
while [ $attempt -le $max_attempts ]; do
    if sqlcmd -S localhost -U sa -P "${SQLPASSWORD}" -C -Q "SELECT 1" > /dev/null 2>&1; then
        echo "✅ SQL Server is ready!"
        break
    fi
    echo "   Waiting for SQL Server... (attempt $attempt/$max_attempts)"
    sleep 2
    attempt=$((attempt + 1))
done

if [ $attempt -gt $max_attempts ]; then
    echo "⚠️  Warning: Could not verify SQL Server connection. Tests may fail."
fi

# Run initial setup SQL if it exists
if [ -f ".devcontainer/mssql/setup.sql" ]; then
    echo "📋 Running setup.sql..."
    sqlcmd -S localhost -U sa -P "${SQLPASSWORD}" -C -i .devcontainer/mssql/setup.sql
fi

# Create useful aliases
echo "🔧 Setting up helpful aliases..."
cat >> ~/.bashrc << 'EOF'

# go-mssqldb development aliases
alias gtest='go test ./...'
alias gtest-unit='go test ./msdsn ./internal/... ./integratedauth ./azuread -v'
alias gtest-short='go test -short ./...'
alias gbuild='go build ./...'
alias gfmt='go fmt ./...'
alias gvet='go vet ./...'
alias glint='golangci-lint run'

# sqlcmd alias using go-sqlcmd (which uses this driver!)
alias sql='sqlcmd -S localhost -U sa -P "$SQLPASSWORD" -C'

# Quick test connection
alias test-db='sqlcmd -S localhost -U sa -P "$SQLPASSWORD" -C -Q "SELECT @@VERSION"'

EOF

echo ""
echo "=== Setup Complete! ==="
echo ""
echo "📖 Quick Reference:"
echo "   gtest        - Run all tests"
echo "   gtest-unit   - Run unit tests only (no SQL Server required)"
echo "   gtest-short  - Run short tests"
echo "   gbuild       - Build all packages"
echo "   gfmt         - Format code"
echo "   gvet         - Run go vet"
echo "   glint        - Run golangci-lint"
echo "   test-db      - Test database connection"
echo "   sql          - Connect to SQL Server (go-sqlcmd)"
echo ""
echo "🔧 go-sqlcmd is installed and uses THIS driver (dogfooding!)"
echo ""
echo "🔗 SQL Server Connection:"
echo "   Server: localhost,1433"
echo "   User: sa"
echo "   Password: MssqlDriver@2025!"
echo "   Database: master"
echo ""
echo "🧪 Environment variables are pre-configured for tests."
echo "   Run 'go test ./...' to execute the full test suite."
echo ""
