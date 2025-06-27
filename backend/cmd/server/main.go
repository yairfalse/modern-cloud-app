package main

import (
	"context"
	"net"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/yairfalse/modern-cloud-app/backend/internal/api/routes"
	"github.com/yairfalse/modern-cloud-app/backend/internal/config"
	"github.com/yairfalse/modern-cloud-app/backend/internal/database"
	"github.com/yairfalse/modern-cloud-app/backend/pkg/logger"
)

func main() {
	cfg := config.Load()
	log := logger.NewLogger(cfg.Environment)

	db, err := database.Connect(cfg.Database)
	if err != nil {
		log.Fatal("Failed to connect to database:", err)
	}

	if err := database.Migrate(db); err != nil {
		log.Fatal("Failed to run migrations:", err)
	}

	gin.SetMode(gin.ReleaseMode)
	if cfg.Environment == "development" {
		gin.SetMode(gin.DebugMode)
	}

	r := gin.New()
	r.Use(gin.Recovery())
	r.Use(logger.GinLogger(log))

	// Configure CORS
	corsConfig := cors.DefaultConfig()
	if cfg.Environment == "production" {
		corsConfig.AllowOrigins = []string{os.Getenv("FRONTEND_URL")}
		if len(corsConfig.AllowOrigins) == 0 || corsConfig.AllowOrigins[0] == "" {
			corsConfig.AllowOrigins = []string{"http://localhost:5173"}
		}
	} else {
		corsConfig.AllowOrigins = []string{"http://localhost:5173", "http://localhost:3000"}
	}
	corsConfig.AllowMethods = []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"}
	corsConfig.AllowHeaders = []string{"Origin", "Content-Type", "Accept", "Authorization"}
	corsConfig.AllowCredentials = true

	r.Use(cors.New(corsConfig))

	// Health check routes
	r.GET("/", handleRoot)
	r.GET("/health", handleHealth)

	// API routes
	routes.Setup(r, db, cfg)

	// Create server
	srv := &http.Server{
		Addr:         ":" + cfg.Server.Port,
		Handler:      r,
		ReadTimeout:  cfg.Server.ReadTimeout,
		WriteTimeout: cfg.Server.WriteTimeout,
		IdleTimeout:  60 * time.Second,
	}

	// Start server in a goroutine
	go func() {
		log.Info("Server starting on port " + cfg.Server.Port)

		// Listen and serve with better error handling
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			// Check if it's a port conflict
			if opErr, ok := err.(*net.OpError); ok {
				if opErr.Op == "listen" {
					log.Fatal("Failed to start server - port may already be in use:", err)
				}
			}
			log.Fatal("Failed to start server:", err)
		}
	}()

	// Wait for interrupt signal to gracefully shutdown the server
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Info("Shutting down server...")

	// Create context with timeout for shutdown
	ctx, cancel := context.WithTimeout(context.Background(), cfg.Server.ShutdownTimeout)
	defer cancel()

	// Attempt graceful shutdown
	if err := srv.Shutdown(ctx); err != nil {
		log.Error("Server forced to shutdown:", err)
	}

	log.Info("Server exited")
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
