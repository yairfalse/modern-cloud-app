package main

import (
	"database/sql"
	"log"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	_ "github.com/mattn/go-sqlite3"
)

// BlogPost represents a blog post in the system.
type BlogPost struct {
	CreatedAt time.Time `json:"created_at"`
	Title     string    `json:"title" binding:"required"`
	Content   string    `json:"content" binding:"required"`
	Author    string    `json:"author" binding:"required"`
	ID        int       `json:"id"`
}

var db *sql.DB

func initDB() {
	var err error
	db, err = sql.Open("sqlite3", "./blog.db")
	if err != nil {
		log.Fatal("Failed to open database:", err)
	}

	createTableSQL := `
	CREATE TABLE IF NOT EXISTS posts (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		title TEXT NOT NULL,
		content TEXT NOT NULL,
		author TEXT NOT NULL,
		created_at DATETIME DEFAULT CURRENT_TIMESTAMP
	);`

	if _, err := db.Exec(createTableSQL); err != nil {
		log.Fatal("Failed to create table:", err)
	}
	log.Println("Database initialized successfully")
}

func healthCheck(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"status": "healthy"})
}

func getPosts(c *gin.Context) {
	log.Println("GET /posts")
	rows, err := db.Query("SELECT id, title, content, author, created_at FROM posts ORDER BY created_at DESC")
	if err != nil {
		log.Printf("Error fetching posts: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch posts"})

		return
	}
	defer rows.Close()

	var posts []BlogPost
	for rows.Next() {
		var post BlogPost
		if err := rows.Scan(&post.ID, &post.Title, &post.Content, &post.Author, &post.CreatedAt); err != nil {
			log.Printf("Error scanning post: %v", err)

			continue
		}
		posts = append(posts, post)
	}

	if err := rows.Err(); err != nil {
		log.Printf("Error iterating posts: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch posts"})

		return
	}

	c.JSON(http.StatusOK, posts)
}

func createPost(c *gin.Context) {
	log.Println("POST /posts")
	var post BlogPost
	if err := c.ShouldBindJSON(&post); err != nil {
		log.Printf("Invalid request body: %v", err)
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})

		return
	}

	result, err := db.Exec("INSERT INTO posts (title, content, author) VALUES (?, ?, ?)",
		post.Title, post.Content, post.Author)
	if err != nil {
		log.Printf("Error creating post: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create post"})

		return
	}

	id, err := result.LastInsertId()
	if err != nil {
		log.Printf("Error getting last insert ID: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get post ID"})

		return
	}
	post.ID = int(id)
	post.CreatedAt = time.Now()
	c.JSON(http.StatusCreated, post)
}

func updatePost(c *gin.Context) {
	id := c.Param("id")
	log.Printf("PUT /posts/%s", id)

	var post BlogPost
	if err := c.ShouldBindJSON(&post); err != nil {
		log.Printf("Invalid request body: %v", err)
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})

		return
	}

	result, err := db.Exec("UPDATE posts SET title = ?, content = ?, author = ? WHERE id = ?",
		post.Title, post.Content, post.Author, id)
	if err != nil {
		log.Printf("Error updating post: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update post"})

		return
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		log.Printf("Error getting rows affected: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update post"})

		return
	}
	if rowsAffected == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "Post not found"})

		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Post updated successfully"})
}

func deletePost(c *gin.Context) {
	id := c.Param("id")
	log.Printf("DELETE /posts/%s", id)

	result, err := db.Exec("DELETE FROM posts WHERE id = ?", id)
	if err != nil {
		log.Printf("Error deleting post: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete post"})

		return
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		log.Printf("Error getting rows affected: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete post"})

		return
	}
	if rowsAffected == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "Post not found"})

		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Post deleted successfully"})
}

func main() {
	initDB()
	defer db.Close()

	router := gin.Default()

	router.GET("/health", healthCheck)
	router.GET("/posts", getPosts)
	router.POST("/posts", createPost)
	router.PUT("/posts/:id", updatePost)
	router.DELETE("/posts/:id", deletePost)

	log.Println("Starting server on :8080")
	if err := router.Run(":8080"); err != nil {
		log.Printf("Failed to start server: %v", err)
		db.Close()

		return
	}
}
