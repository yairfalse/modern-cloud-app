package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type Comment struct {
	ID         uuid.UUID      `gorm:"type:uuid;default:gen_random_uuid();primaryKey" json:"id"`
	PostID     uuid.UUID      `gorm:"type:uuid;not null" json:"post_id"`
	Post       *Post          `gorm:"foreignKey:PostID" json:"post,omitempty"`
	UserID     uuid.UUID      `gorm:"type:uuid;not null" json:"user_id"`
	User       *User          `gorm:"foreignKey:UserID" json:"user,omitempty"`
	ParentID   *uuid.UUID     `gorm:"type:uuid" json:"parent_id"`
	Parent     *Comment       `gorm:"foreignKey:ParentID" json:"parent,omitempty"`
	Content    string         `gorm:"type:text;not null" json:"content"`
	IsApproved bool           `gorm:"default:false" json:"is_approved"`
	LikeCount  int            `gorm:"default:0" json:"like_count"`
	CreatedAt  time.Time      `json:"created_at"`
	UpdatedAt  time.Time      `json:"updated_at"`
	DeletedAt  gorm.DeletedAt `gorm:"index" json:"-"`

	Replies []Comment `gorm:"foreignKey:ParentID" json:"replies,omitempty"`
	Likes   []Like    `gorm:"foreignKey:CommentID" json:"likes,omitempty"`
}

func (c *Comment) BeforeCreate(tx *gorm.DB) error {
	if c.ID == uuid.Nil {
		c.ID = uuid.New()
	}
	return nil
}

func (c *Comment) AfterCreate(tx *gorm.DB) error {
	return tx.Model(&Post{}).Where("id = ?", c.PostID).
		UpdateColumn("comment_count", gorm.Expr("comment_count + ?", 1)).Error
}

func (c *Comment) AfterDelete(tx *gorm.DB) error {
	return tx.Model(&Post{}).Where("id = ?", c.PostID).
		UpdateColumn("comment_count", gorm.Expr("comment_count - ?", 1)).Error
}
