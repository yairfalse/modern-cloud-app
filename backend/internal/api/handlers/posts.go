package handlers

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"

	"github.com/yairfalse/modern-cloud-app/backend/internal/api/middleware"
	"github.com/yairfalse/modern-cloud-app/backend/internal/database/models"
)

type PostHandler struct {
	db *gorm.DB
}

type CreatePostRequest struct {
	Title         string   `json:"title" binding:"required,min=1,max=255"`
	Content       string   `json:"content" binding:"required"`
	Excerpt       string   `json:"excerpt"`
	FeaturedImage string   `json:"featured_image"`
	Status        string   `json:"status"`
	Tags          []string `json:"tags"`
}

type UpdatePostRequest struct {
	Title         string   `json:"title"`
	Content       string   `json:"content"`
	Excerpt       string   `json:"excerpt"`
	FeaturedImage string   `json:"featured_image"`
	Status        string   `json:"status"`
	Tags          []string `json:"tags"`
}

type PostsQuery struct {
	Page     int    `form:"page,default=1"`
	Limit    int    `form:"limit,default=10"`
	Status   string `form:"status"`
	AuthorID string `form:"author_id"`
	Tag      string `form:"tag"`
	Search   string `form:"search"`
}

func NewPostHandler(db *gorm.DB) *PostHandler {
	return &PostHandler{db: db}
}

func (h *PostHandler) CreatePost(c *gin.Context) {
	userID, exists := middleware.GetUserID(c)
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "User not authenticated",
		})
		return
	}

	var req CreatePostRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Invalid request data",
			"details": err.Error(),
		})
		return
	}

	slug := generateSlug(req.Title)

	var existingPost models.Post
	if err := h.db.Where("slug = ?", slug).First(&existingPost).Error; err == nil {
		slug = slug + "-" + uuid.New().String()[:8]
	}

	status := models.PostStatusDraft
	if req.Status != "" {
		status = models.PostStatus(req.Status)
	}

	post := models.Post{
		Title:         req.Title,
		Slug:          slug,
		Content:       req.Content,
		Excerpt:       req.Excerpt,
		FeaturedImage: req.FeaturedImage,
		Status:        status,
		AuthorID:      userID,
	}

	if err := h.db.Create(&post).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Failed to create post",
		})
		return
	}

	if len(req.Tags) > 0 {
		if err := h.associateTags(&post, req.Tags); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{
				"error": "Failed to associate tags",
			})
			return
		}
	}

	if err := h.db.Preload("Author").Preload("Tags").First(&post, post.ID).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Failed to load post",
		})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"post": post,
	})
}

func (h *PostHandler) GetPosts(c *gin.Context) {
	var query PostsQuery
	if err := c.ShouldBindQuery(&query); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Invalid query parameters",
		})
		return
	}

	if query.Limit > 50 {
		query.Limit = 50
	}

	offset := (query.Page - 1) * query.Limit

	db := h.db.Model(&models.Post{}).
		Preload("Author").
		Preload("Tags")

	if query.Status != "" {
		db = db.Where("status = ?", query.Status)
	} else {
		db = db.Where("status = ?", models.PostStatusPublished)
	}

	if query.AuthorID != "" {
		if authorUUID, err := uuid.Parse(query.AuthorID); err == nil {
			db = db.Where("author_id = ?", authorUUID)
		}
	}

	if query.Search != "" {
		searchTerm := "%" + query.Search + "%"
		db = db.Where("title ILIKE ? OR content ILIKE ?", searchTerm, searchTerm)
	}

	if query.Tag != "" {
		db = db.Joins("JOIN post_tags ON posts.id = post_tags.post_id").
			Joins("JOIN tags ON post_tags.tag_id = tags.id").
			Where("tags.slug = ?", query.Tag)
	}

	var total int64
	db.Count(&total)

	var posts []models.Post
	if err := db.Order("created_at DESC").
		Offset(offset).
		Limit(query.Limit).
		Find(&posts).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Failed to fetch posts",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"posts": posts,
		"pagination": gin.H{
			"page":  query.Page,
			"limit": query.Limit,
			"total": total,
			"pages": (total + int64(query.Limit) - 1) / int64(query.Limit),
		},
	})
}

func (h *PostHandler) GetPost(c *gin.Context) {
	id := c.Param("id")

	var post models.Post
	var err error

	if uuid, parseErr := uuid.Parse(id); parseErr == nil {
		err = h.db.Preload("Author").Preload("Tags").Preload("Comments.User").
			Where("id = ? AND status = ?", uuid, models.PostStatusPublished).
			First(&post).Error
	} else {
		err = h.db.Preload("Author").Preload("Tags").Preload("Comments.User").
			Where("slug = ? AND status = ?", id, models.PostStatusPublished).
			First(&post).Error
	}

	if err != nil {
		if err == gorm.ErrRecordNotFound {
			c.JSON(http.StatusNotFound, gin.H{
				"error": "Post not found",
			})
		} else {
			c.JSON(http.StatusInternalServerError, gin.H{
				"error": "Failed to fetch post",
			})
		}
		return
	}

	h.db.Model(&post).UpdateColumn("view_count", gorm.Expr("view_count + ?", 1))

	c.JSON(http.StatusOK, gin.H{
		"post": post,
	})
}

func (h *PostHandler) UpdatePost(c *gin.Context) {
	userID, exists := middleware.GetUserID(c)
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "User not authenticated",
		})
		return
	}

	id := c.Param("id")
	postUUID, err := uuid.Parse(id)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Invalid post ID",
		})
		return
	}

	var post models.Post
	if err := h.db.Where("id = ? AND author_id = ?", postUUID, userID).First(&post).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			c.JSON(http.StatusNotFound, gin.H{
				"error": "Post not found or not authorized",
			})
		} else {
			c.JSON(http.StatusInternalServerError, gin.H{
				"error": "Failed to fetch post",
			})
		}
		return
	}

	var req UpdatePostRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Invalid request data",
		})
		return
	}

	updates := make(map[string]interface{})

	if req.Title != "" {
		updates["title"] = req.Title
		updates["slug"] = generateSlug(req.Title)
	}
	if req.Content != "" {
		updates["content"] = req.Content
	}
	if req.Excerpt != "" {
		updates["excerpt"] = req.Excerpt
	}
	if req.FeaturedImage != "" {
		updates["featured_image"] = req.FeaturedImage
	}
	if req.Status != "" {
		updates["status"] = req.Status
	}

	if err := h.db.Model(&post).Updates(updates).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Failed to update post",
		})
		return
	}

	if len(req.Tags) > 0 {
		if err := h.associateTags(&post, req.Tags); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{
				"error": "Failed to associate tags",
			})
			return
		}
	}

	if err := h.db.Preload("Author").Preload("Tags").First(&post, post.ID).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Failed to load updated post",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"post": post,
	})
}

func (h *PostHandler) DeletePost(c *gin.Context) {
	userID, exists := middleware.GetUserID(c)
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "User not authenticated",
		})
		return
	}

	id := c.Param("id")
	postUUID, err := uuid.Parse(id)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Invalid post ID",
		})
		return
	}

	result := h.db.Where("id = ? AND author_id = ?", postUUID, userID).Delete(&models.Post{})
	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Failed to delete post",
		})
		return
	}

	if result.RowsAffected == 0 {
		c.JSON(http.StatusNotFound, gin.H{
			"error": "Post not found or not authorized",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Post deleted successfully",
	})
}

func (h *PostHandler) associateTags(post *models.Post, tagNames []string) error {
	if err := h.db.Model(post).Association("Tags").Clear(); err != nil {
		return err
	}

	for _, tagName := range tagNames {
		tagName = strings.TrimSpace(tagName)
		if tagName == "" {
			continue
		}

		var tag models.Tag
		tagSlug := generateSlug(tagName)

		if err := h.db.Where("slug = ?", tagSlug).First(&tag).Error; err != nil {
			tag = models.Tag{
				Name: tagName,
				Slug: tagSlug,
			}
			h.db.Create(&tag)
		}

		if err := h.db.Model(post).Association("Tags").Append(&tag); err != nil {
			return err
		}
	}
	return nil
}

func generateSlug(title string) string {
	slug := strings.ToLower(title)
	slug = strings.ReplaceAll(slug, " ", "-")
	slug = strings.ReplaceAll(slug, "_", "-")

	allowedChars := "abcdefghijklmnopqrstuvwxyz0123456789-"
	var result strings.Builder

	for _, char := range slug {
		if strings.ContainsRune(allowedChars, char) {
			result.WriteRune(char)
		}
	}

	return strings.Trim(result.String(), "-")
}
