package main

import (
	"context"
	"log"
	"net"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
)

func main() {
	// Configure logging with timestamps
	log.SetFlags(log.LstdFlags | log.Lshortfile)

	// Set Gin mode based on environment
	ginMode := os.Getenv("GIN_MODE")
	if ginMode == "" {
		ginMode = gin.DebugMode
	}
	gin.SetMode(ginMode)

	// Create gin router
	var r *gin.Engine
	if ginMode == gin.ReleaseMode {
		r = gin.New()
		r.Use(gin.Logger())
		r.Use(gin.Recovery())
	} else {
		r = gin.Default()
	}

	// Configure trusted proxies
	if ginMode == gin.ReleaseMode {
		// In production, configure based on your infrastructure
		// For now, we'll trust no proxies for security
		if err := r.SetTrustedProxies(nil); err != nil {
			log.Printf("Warning: Failed to set trusted proxies: %v", err)
		}
	} else {
		// In development, trust localhost
		if err := r.SetTrustedProxies([]string{"127.0.0.1", "::1"}); err != nil {
			log.Printf("Warning: Failed to set trusted proxies: %v", err)
		}
	}

	// Configure CORS
	corsConfig := cors.DefaultConfig()
	if ginMode == gin.ReleaseMode {
		// In production, be more restrictive
		corsConfig.AllowOrigins = []string{os.Getenv("FRONTEND_URL")}
		if len(corsConfig.AllowOrigins) == 0 || corsConfig.AllowOrigins[0] == "" {
			corsConfig.AllowOrigins = []string{"http://localhost:5173"}
		}
	} else {
		// In development, allow React dev server
		corsConfig.AllowOrigins = []string{"http://localhost:5173"}
	}
	corsConfig.AllowMethods = []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"}
	corsConfig.AllowHeaders = []string{"Origin", "Content-Type", "Accept", "Authorization"}
	corsConfig.AllowCredentials = true

	r.Use(cors.New(corsConfig))

	// Register routes
	r.GET("/", handleRoot)
	r.GET("/health", handleHealth)

	// Get port from environment
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	// Create server
	srv := &http.Server{
		Addr:         ":" + port,
		Handler:      r,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	// Start server in a goroutine
	go func() {
		log.Printf("Server starting on port %s (mode: %s)", port, ginMode)

		// Listen and serve with better error handling
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			// Check if it's a port conflict
			if opErr, ok := err.(*net.OpError); ok {
				if opErr.Op == "listen" {
					log.Fatalf("Failed to start server - port %s may already be in use: %v", port, err)
				}
			}
			log.Fatalf("Failed to start server: %v", err)
		}
	}()

	// Wait for interrupt signal to gracefully shutdown the server
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Println("Shutting down server...")

	// Create context with timeout for shutdown
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	// Attempt graceful shutdown
	if err := srv.Shutdown(ctx); err != nil {
		log.Printf("Server forced to shutdown: %v", err)
	}

	log.Println("Server exited")
}

func handleRoot(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"message": "Welcome to ModernBlog API",
		"version": "1.0.0",
		"mode":    gin.Mode(),
		"time":    time.Now().UTC().Format(time.RFC3339),
	})
}

func handleHealth(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"status":    "healthy",
		"timestamp": time.Now().UTC().Format(time.RFC3339),
	})
}
