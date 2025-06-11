package main

import (
	"bytes"
	"database/sql"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"os"
	"testing"
	"time"

	"github.com/gin-gonic/gin"
	_ "github.com/mattn/go-sqlite3"
)

func setupTestDB() (*sql.DB, error) {
	db, err := sql.Open("sqlite3", ":memory:")
	if err != nil {
		return nil, err
	}

	createTableSQL := `
	CREATE TABLE posts (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		title TEXT NOT NULL,
		content TEXT NOT NULL,
		author TEXT NOT NULL,
		created_at DATETIME DEFAULT CURRENT_TIMESTAMP
	);`

	_, err = db.Exec(createTableSQL)
	if err != nil {
		return nil, err
	}

	return db, nil
}

func setupTestRouter(db *sql.DB) *gin.Engine {
	gin.SetMode(gin.TestMode)
	r := gin.Default()

	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "healthy"})
	})

	r.GET("/posts", func(c *gin.Context) {
		rows, err := db.Query("SELECT id, title, content, author, created_at FROM posts ORDER BY created_at DESC")
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to retrieve posts"})
			return
		}
		defer rows.Close()

		posts := []BlogPost{}
		for rows.Next() {
			var post BlogPost
			err := rows.Scan(&post.ID, &post.Title, &post.Content, &post.Author, &post.CreatedAt)
			if err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to scan post"})
				return
			}
			posts = append(posts, post)
		}

		c.JSON(http.StatusOK, posts)
	})

	r.POST("/posts", func(c *gin.Context) {
		var post BlogPost
		if err := c.ShouldBindJSON(&post); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		result, err := db.Exec("INSERT INTO posts (title, content, author) VALUES (?, ?, ?)",
			post.Title, post.Content, post.Author)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create post"})
			return
		}

		id, _ := result.LastInsertId()
		post.ID = int(id)
		post.CreatedAt = time.Now()

		c.JSON(http.StatusCreated, post)
	})

	r.PUT("/posts/:id", func(c *gin.Context) {
		id := c.Param("id")
		var post BlogPost
		if err := c.ShouldBindJSON(&post); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		result, err := db.Exec("UPDATE posts SET title = ?, content = ?, author = ? WHERE id = ?",
			post.Title, post.Content, post.Author, id)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update post"})
			return
		}

		rowsAffected, _ := result.RowsAffected()
		if rowsAffected == 0 {
			c.JSON(http.StatusNotFound, gin.H{"error": "Post not found"})
			return
		}

		c.JSON(http.StatusOK, gin.H{"message": "Post updated successfully"})
	})

	r.DELETE("/posts/:id", func(c *gin.Context) {
		id := c.Param("id")

		result, err := db.Exec("DELETE FROM posts WHERE id = ?", id)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete post"})
			return
		}

		rowsAffected, _ := result.RowsAffected()
		if rowsAffected == 0 {
			c.JSON(http.StatusNotFound, gin.H{"error": "Post not found"})
			return
		}

		c.JSON(http.StatusOK, gin.H{"message": "Post deleted successfully"})
	})

	return r
}

func TestMain(m *testing.M) {
	code := m.Run()
	os.Exit(code)
}

func TestHealthEndpoint(t *testing.T) {
	db, err := setupTestDB()
	if err != nil {
		t.Fatalf("Failed to setup test database: %v", err)
	}
	defer db.Close()

	router := setupTestRouter(db)

	w := httptest.NewRecorder()
	req, _ := http.NewRequest("GET", "/health", nil)
	router.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Errorf("Expected status code %d, got %d", http.StatusOK, w.Code)
	}

	var response map[string]string
	json.Unmarshal(w.Body.Bytes(), &response)

	if response["status"] != "healthy" {
		t.Errorf("Expected status 'healthy', got '%s'", response["status"])
	}
}

func TestCreateBlogPost(t *testing.T) {
	db, err := setupTestDB()
	if err != nil {
		t.Fatalf("Failed to setup test database: %v", err)
	}
	defer db.Close()

	router := setupTestRouter(db)

	tests := []struct {
		name         string
		payload      BlogPost
		expectedCode int
		checkResult  bool
	}{
		{
			name: "Valid post",
			payload: BlogPost{
				Title:   "Test Post",
				Content: "This is a test post content",
				Author:  "Test Author",
			},
			expectedCode: http.StatusCreated,
			checkResult:  true,
		},
		{
			name: "Missing title",
			payload: BlogPost{
				Content: "This is a test post content",
				Author:  "Test Author",
			},
			expectedCode: http.StatusBadRequest,
			checkResult:  false,
		},
		{
			name: "Missing content",
			payload: BlogPost{
				Title:  "Test Post",
				Author: "Test Author",
			},
			expectedCode: http.StatusBadRequest,
			checkResult:  false,
		},
		{
			name: "Missing author",
			payload: BlogPost{
				Title:   "Test Post",
				Content: "This is a test post content",
			},
			expectedCode: http.StatusBadRequest,
			checkResult:  false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			body, _ := json.Marshal(tt.payload)
			w := httptest.NewRecorder()
			req, _ := http.NewRequest("POST", "/posts", bytes.NewBuffer(body))
			req.Header.Set("Content-Type", "application/json")
			router.ServeHTTP(w, req)

			if w.Code != tt.expectedCode {
				t.Errorf("Expected status code %d, got %d", tt.expectedCode, w.Code)
			}

			if tt.checkResult && w.Code == http.StatusCreated {
				var response BlogPost
				json.Unmarshal(w.Body.Bytes(), &response)

				if response.ID == 0 {
					t.Error("Expected non-zero ID")
				}
				if response.Title != tt.payload.Title {
					t.Errorf("Expected title '%s', got '%s'", tt.payload.Title, response.Title)
				}
				if response.Content != tt.payload.Content {
					t.Errorf("Expected content '%s', got '%s'", tt.payload.Content, response.Content)
				}
				if response.Author != tt.payload.Author {
					t.Errorf("Expected author '%s', got '%s'", tt.payload.Author, response.Author)
				}
				if response.CreatedAt.IsZero() {
					t.Error("Expected non-zero created_at")
				}
			}
		})
	}
}

func TestGetBlogPosts(t *testing.T) {
	db, err := setupTestDB()
	if err != nil {
		t.Fatalf("Failed to setup test database: %v", err)
	}
	defer db.Close()

	router := setupTestRouter(db)

	// Insert test data with explicit timestamps to ensure ordering
	baseTime := time.Now()
	testPosts := []struct {
		post      BlogPost
		createdAt time.Time
	}{
		{BlogPost{Title: "First Post", Content: "First content", Author: "Author 1"}, baseTime},
		{BlogPost{Title: "Second Post", Content: "Second content", Author: "Author 2"}, baseTime.Add(1 * time.Hour)},
		{BlogPost{Title: "Third Post", Content: "Third content", Author: "Author 3"}, baseTime.Add(2 * time.Hour)},
	}

	for _, tp := range testPosts {
		_, err := db.Exec("INSERT INTO posts (title, content, author, created_at) VALUES (?, ?, ?, ?)",
			tp.post.Title, tp.post.Content, tp.post.Author, tp.createdAt)
		if err != nil {
			t.Fatalf("Failed to insert test data: %v", err)
		}
	}

	// Test GET /posts
	w := httptest.NewRecorder()
	req, _ := http.NewRequest("GET", "/posts", nil)
	router.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Errorf("Expected status code %d, got %d", http.StatusOK, w.Code)
	}

	var response []BlogPost
	json.Unmarshal(w.Body.Bytes(), &response)

	if len(response) != len(testPosts) {
		t.Errorf("Expected %d posts, got %d", len(testPosts), len(response))
	}

	// Check that posts are ordered by created_at DESC (newest first)
	// Since we're using SQLite's CURRENT_TIMESTAMP with limited precision,
	// we need to check the order differently
	foundTitles := make([]string, len(response))
	for i, post := range response {
		foundTitles[i] = post.Title
	}
	
	// The posts should be in reverse order of insertion
	if foundTitles[0] != "Third Post" || foundTitles[1] != "Second Post" || foundTitles[2] != "First Post" {
		t.Errorf("Posts are not ordered correctly. Got: %v", foundTitles)
	}
}

func TestUpdateBlogPost(t *testing.T) {
	db, err := setupTestDB()
	if err != nil {
		t.Fatalf("Failed to setup test database: %v", err)
	}
	defer db.Close()

	router := setupTestRouter(db)

	// Insert a test post
	_, err = db.Exec("INSERT INTO posts (title, content, author) VALUES (?, ?, ?)",
		"Original Title", "Original Content", "Original Author")
	if err != nil {
		t.Fatalf("Failed to insert test data: %v", err)
	}

	tests := []struct {
		name         string
		postID       string
		payload      BlogPost
		expectedCode int
	}{
		{
			name:   "Valid update",
			postID: "1",
			payload: BlogPost{
				Title:   "Updated Title",
				Content: "Updated Content",
				Author:  "Updated Author",
			},
			expectedCode: http.StatusOK,
		},
		{
			name:   "Non-existent post",
			postID: "999",
			payload: BlogPost{
				Title:   "Updated Title",
				Content: "Updated Content",
				Author:  "Updated Author",
			},
			expectedCode: http.StatusNotFound,
		},
		{
			name:   "Invalid payload",
			postID: "1",
			payload: BlogPost{
				Title: "Updated Title",
				// Missing required fields
			},
			expectedCode: http.StatusBadRequest,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			body, _ := json.Marshal(tt.payload)
			w := httptest.NewRecorder()
			req, _ := http.NewRequest("PUT", "/posts/"+tt.postID, bytes.NewBuffer(body))
			req.Header.Set("Content-Type", "application/json")
			router.ServeHTTP(w, req)

			if w.Code != tt.expectedCode {
				t.Errorf("Expected status code %d, got %d", tt.expectedCode, w.Code)
			}
		})
	}
}

func TestDeleteBlogPost(t *testing.T) {
	db, err := setupTestDB()
	if err != nil {
		t.Fatalf("Failed to setup test database: %v", err)
	}
	defer db.Close()

	router := setupTestRouter(db)

	// Insert test posts
	for i := 0; i < 3; i++ {
		_, err := db.Exec("INSERT INTO posts (title, content, author) VALUES (?, ?, ?)",
			"Test Title", "Test Content", "Test Author")
		if err != nil {
			t.Fatalf("Failed to insert test data: %v", err)
		}
	}

	tests := []struct {
		name         string
		postID       string
		expectedCode int
	}{
		{
			name:         "Valid delete",
			postID:       "1",
			expectedCode: http.StatusOK,
		},
		{
			name:         "Non-existent post",
			postID:       "999",
			expectedCode: http.StatusNotFound,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			w := httptest.NewRecorder()
			req, _ := http.NewRequest("DELETE", "/posts/"+tt.postID, nil)
			router.ServeHTTP(w, req)

			if w.Code != tt.expectedCode {
				t.Errorf("Expected status code %d, got %d", tt.expectedCode, w.Code)
			}

			// Verify the post was actually deleted
			if tt.expectedCode == http.StatusOK {
				var count int
				err := db.QueryRow("SELECT COUNT(*) FROM posts WHERE id = ?", tt.postID).Scan(&count)
				if err != nil {
					t.Fatalf("Failed to check deletion: %v", err)
				}
				if count != 0 {
					t.Error("Post was not actually deleted from database")
				}
			}
		})
	}
}

func TestEmptyPostsList(t *testing.T) {
	db, err := setupTestDB()
	if err != nil {
		t.Fatalf("Failed to setup test database: %v", err)
	}
	defer db.Close()

	router := setupTestRouter(db)

	w := httptest.NewRecorder()
	req, _ := http.NewRequest("GET", "/posts", nil)
	router.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Errorf("Expected status code %d, got %d", http.StatusOK, w.Code)
	}

	var response []BlogPost
	json.Unmarshal(w.Body.Bytes(), &response)

	if response == nil {
		t.Error("Expected empty array, got nil")
	}

	if len(response) != 0 {
		t.Errorf("Expected 0 posts, got %d", len(response))
	}
}