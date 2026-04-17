package mssql

import (
	"database/sql"
	"testing"
)

// TestXactAbortSurfacesError verifies that when XACT_ABORT ON causes a
// server-side transaction rollback, the driver surfaces the error from
// the query that triggered the abort, and subsequent operations on the
// transaction also fail. Regression test for
// https://github.com/microsoft/go-mssqldb/issues/244
func TestXactAbortSurfacesError(t *testing.T) {
	connector, err := NewConnector(makeConnStr(t).String())
	if err != nil {
		t.Fatal(err)
	}
	connector.SessionInitSQL = "SET XACT_ABORT ON"
	db := sql.OpenDB(connector)
	defer db.Close()

	// Create test tables
	_, err = db.Exec(`
		IF OBJECT_ID('dbo.xact_test_users', 'U') IS NOT NULL DROP TABLE dbo.xact_test_users;
		CREATE TABLE dbo.xact_test_users (
			id INT IDENTITY(1,1) PRIMARY KEY,
			username VARCHAR(50),
			code VARCHAR(50)
		)`)
	if err != nil {
		t.Fatal("failed to create xact_test_users table:", err)
	}
	defer db.Exec("DROP TABLE IF EXISTS dbo.xact_test_users")

	_, err = db.Exec(`
		IF OBJECT_ID('dbo.xact_test_orders', 'U') IS NOT NULL DROP TABLE dbo.xact_test_orders;
		CREATE TABLE dbo.xact_test_orders (
			id INT IDENTITY(1,1) PRIMARY KEY,
			order_desc VARCHAR(100)
		)`)
	if err != nil {
		t.Fatal("failed to create xact_test_orders table:", err)
	}
	defer db.Exec("DROP TABLE IF EXISTS dbo.xact_test_orders")

	// Insert seed data: one castable code and one non-castable code
	_, err = db.Exec(
		"INSERT INTO dbo.xact_test_users (username, code) VALUES (@p1, @p2)",
		"some_user", "12345",
	)
	if err != nil {
		t.Fatal("failed to insert user:", err)
	}
	_, err = db.Exec(
		"INSERT INTO dbo.xact_test_users (username, code) VALUES (@p1, @p2)",
		"some_other_user", "not_castable_to_int",
	)
	if err != nil {
		t.Fatal("failed to insert second user:", err)
	}

	// Start a transaction
	tx, err := db.Begin()
	if err != nil {
		t.Fatal("failed to begin transaction:", err)
	}
	defer tx.Rollback()

	// First INSERT succeeds
	_, err = tx.Exec("INSERT INTO dbo.xact_test_orders (order_desc) VALUES (@p1)", "First order")
	if err != nil {
		t.Fatal("first insert should succeed:", err)
	}

	// This SELECT causes an implicit conversion error for the
	// "not_castable_to_int" row. With XACT_ABORT ON, the server
	// rolls back the transaction. The driver MUST surface this error.
	var username string
	err = tx.QueryRow(
		"SELECT username FROM dbo.xact_test_users WHERE code = @p1", 12345,
	).Scan(&username)
	if err == nil {
		t.Error("expected error from QueryRow().Scan() due to XACT_ABORT rollback, got nil")
	} else {
		t.Logf("correctly got error from QueryRow: %v", err)
	}

	// Even if the above error was missed, subsequent operations on the
	// dead transaction should fail.
	_, execErr := tx.Exec("INSERT INTO dbo.xact_test_orders (order_desc) VALUES (@p1)", "Second order")
	if execErr == nil {
		t.Error("expected error from Exec on aborted transaction, got nil")
	} else {
		t.Logf("correctly got error from Exec on dead transaction: %v", execErr)
	}

	// Verify: no orders should be in the table (transaction was rolled back)
	var count int
	err = db.QueryRow("SELECT COUNT(*) FROM dbo.xact_test_orders").Scan(&count)
	if err != nil {
		t.Fatal("failed to count orders:", err)
	}
	if count != 0 {
		t.Errorf("expected 0 orders in table (transaction should have been rolled back), got %d", count)
	}
}
