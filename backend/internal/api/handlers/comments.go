package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"

	"github.com/yairfalse/modern-cloud-app/backend/internal/api/middleware"
	"github.com/yairfalse/modern-cloud-app/backend/internal/database/models"
)

type CommentHandler struct {
	db *gorm.DB
}

type CreateCommentRequest struct {
	Content  string     `json:"content" binding:"required,min=1"`
	ParentID *uuid.UUID `json:"parent_id"`
}

type UpdateCommentRequest struct {
	Content string `json:"content" binding:"required,min=1"`
}

func NewCommentHandler(db *gorm.DB) *CommentHandler {
	return &CommentHandler{db: db}
}

func (h *CommentHandler) GetComments(c *gin.Context) {
	postID := c.Param("post_id")
	postUUID, err := uuid.Parse(postID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Invalid post ID",
		})
		return
	}

	var comments []models.Comment
	if err := h.db.Where("post_id = ? AND parent_id IS NULL", postUUID).
		Preload("User").
		Preload("Replies.User").
		Order("created_at ASC").
		Find(&comments).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Failed to fetch comments",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"comments": comments,
	})
}

func (h *CommentHandler) CreateComment(c *gin.Context) {
	userID, exists := middleware.GetUserID(c)
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "User not authenticated",
		})
		return
	}

	postID := c.Param("post_id")
	postUUID, err := uuid.Parse(postID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Invalid post ID",
		})
		return
	}

	var post models.Post
	if err := h.db.Where("id = ? AND status = ?", postUUID, models.PostStatusPublished).First(&post).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"error": "Post not found",
		})
		return
	}

	var req CreateCommentRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Invalid request data",
			"details": err.Error(),
		})
		return
	}

	if req.ParentID != nil {
		var parentComment models.Comment
		if err := h.db.Where("id = ? AND post_id = ?", req.ParentID, postUUID).First(&parentComment).Error; err != nil {
			c.JSON(http.StatusBadRequest, gin.H{
				"error": "Parent comment not found",
			})
			return
		}
	}

	comment := models.Comment{
		PostID:   postUUID,
		UserID:   userID,
		ParentID: req.ParentID,
		Content:  req.Content,
	}

	if err := h.db.Create(&comment).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Failed to create comment",
		})
		return
	}

	if err := h.db.Preload("User").First(&comment, comment.ID).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Failed to load comment",
		})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"comment": comment,
	})
}

func (h *CommentHandler) UpdateComment(c *gin.Context) {
	userID, exists := middleware.GetUserID(c)
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "User not authenticated",
		})
		return
	}

	commentID := c.Param("id")
	commentUUID, err := uuid.Parse(commentID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Invalid comment ID",
		})
		return
	}

	var comment models.Comment
	if err := h.db.Where("id = ? AND user_id = ?", commentUUID, userID).First(&comment).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			c.JSON(http.StatusNotFound, gin.H{
				"error": "Comment not found or not authorized",
			})
		} else {
			c.JSON(http.StatusInternalServerError, gin.H{
				"error": "Failed to fetch comment",
			})
		}
		return
	}

	var req UpdateCommentRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Invalid request data",
		})
		return
	}

	if err := h.db.Model(&comment).Update("content", req.Content).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Failed to update comment",
		})
		return
	}

	if err := h.db.Preload("User").First(&comment, comment.ID).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Failed to load updated comment",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"comment": comment,
	})
}

func (h *CommentHandler) DeleteComment(c *gin.Context) {
	userID, exists := middleware.GetUserID(c)
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "User not authenticated",
		})
		return
	}

	commentID := c.Param("id")
	commentUUID, err := uuid.Parse(commentID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Invalid comment ID",
		})
		return
	}

	result := h.db.Where("id = ? AND user_id = ?", commentUUID, userID).Delete(&models.Comment{})
	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Failed to delete comment",
		})
		return
	}

	if result.RowsAffected == 0 {
		c.JSON(http.StatusNotFound, gin.H{
			"error": "Comment not found or not authorized",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Comment deleted successfully",
	})
}
