package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type PostStatus string

const (
	PostStatusDraft     PostStatus = "draft"
	PostStatusPublished PostStatus = "published"
	PostStatusArchived  PostStatus = "archived"
)

type Post struct {
	ID            uuid.UUID      `gorm:"type:uuid;default:gen_random_uuid();primaryKey" json:"id"`
	Title         string         `gorm:"not null" json:"title"`
	Slug          string         `gorm:"uniqueIndex;not null" json:"slug"`
	Content       string         `gorm:"type:text;not null" json:"content"`
	Excerpt       string         `gorm:"type:text" json:"excerpt"`
	FeaturedImage string         `json:"featured_image"`
	Status        PostStatus     `gorm:"default:'draft'" json:"status"`
	AuthorID      uuid.UUID      `gorm:"type:uuid;not null" json:"author_id"`
	Author        *User          `gorm:"foreignKey:AuthorID" json:"author,omitempty"`
	PublishedAt   *time.Time     `json:"published_at"`
	ViewCount     int            `gorm:"default:0" json:"view_count"`
	LikeCount     int            `gorm:"default:0" json:"like_count"`
	CommentCount  int            `gorm:"default:0" json:"comment_count"`
	CreatedAt     time.Time      `json:"created_at"`
	UpdatedAt     time.Time      `json:"updated_at"`
	DeletedAt     gorm.DeletedAt `gorm:"index" json:"-"`

	Comments []Comment `gorm:"foreignKey:PostID" json:"comments,omitempty"`
	Tags     []Tag     `gorm:"many2many:post_tags;" json:"tags,omitempty"`
	Likes    []Like    `gorm:"foreignKey:PostID" json:"likes,omitempty"`
}

func (p *Post) BeforeCreate(tx *gorm.DB) error {
	if p.ID == uuid.Nil {
		p.ID = uuid.New()
	}
	return nil
}

func (p *Post) BeforeUpdate(tx *gorm.DB) error {
	if p.Status == PostStatusPublished && p.PublishedAt == nil {
		now := time.Now()
		p.PublishedAt = &now
	}
	return nil
}
