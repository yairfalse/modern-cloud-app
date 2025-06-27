package routes

import (
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"

	"github.com/yairfalse/modern-cloud-app/backend/internal/api/handlers"
	"github.com/yairfalse/modern-cloud-app/backend/internal/api/middleware"
	"github.com/yairfalse/modern-cloud-app/backend/internal/config"
	"github.com/yairfalse/modern-cloud-app/backend/pkg/auth"
)

func Setup(router *gin.Engine, db *gorm.DB, cfg *config.Config) {
	jwtManager := auth.NewJWTManager(
		cfg.JWT.Secret,
		cfg.JWT.AccessTokenTTL,
		cfg.JWT.RefreshTokenTTL,
	)

	authMiddleware := middleware.NewAuthMiddleware(jwtManager)

	authHandler := handlers.NewAuthHandler(db, jwtManager)
	postHandler := handlers.NewPostHandler(db)
	commentHandler := handlers.NewCommentHandler(db)

	api := router.Group("/api/v1")

	setupAuthRoutes(api, authHandler, authMiddleware)
	setupPostRoutes(api, postHandler, authMiddleware)
	setupCommentRoutes(api, commentHandler, authMiddleware)
}

func setupAuthRoutes(api *gin.RouterGroup, handler *handlers.AuthHandler, authMw *middleware.AuthMiddleware) {
	auth := api.Group("/auth")
	{
		auth.POST("/register", handler.Register)
		auth.POST("/login", handler.Login)
		auth.POST("/refresh", handler.Refresh)
		auth.GET("/profile", authMw.RequireAuth(), handler.Profile)
		auth.DELETE("/logout", authMw.RequireAuth(), handler.Logout)
	}
}

func setupPostRoutes(api *gin.RouterGroup, handler *handlers.PostHandler, authMw *middleware.AuthMiddleware) {
	posts := api.Group("/posts")
	{
		posts.GET("", handler.GetPosts)
		posts.GET("/:id", handler.GetPost)
		posts.POST("", authMw.RequireAuth(), handler.CreatePost)
		posts.PUT("/:id", authMw.RequireAuth(), handler.UpdatePost)
		posts.DELETE("/:id", authMw.RequireAuth(), handler.DeletePost)
	}
}

func setupCommentRoutes(api *gin.RouterGroup, handler *handlers.CommentHandler, authMw *middleware.AuthMiddleware) {
	comments := api.Group("/comments")
	{
		comments.GET("", handler.GetComments) // Use query param ?post_id=
		comments.POST("", authMw.RequireAuth(), handler.CreateComment)
		comments.PUT("/:id", authMw.RequireAuth(), handler.UpdateComment)
		comments.DELETE("/:id", authMw.RequireAuth(), handler.DeleteComment)
	}
}
