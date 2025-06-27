package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type Like struct {
	ID        uuid.UUID  `gorm:"type:uuid;default:gen_random_uuid();primaryKey" json:"id"`
	UserID    uuid.UUID  `gorm:"type:uuid;not null" json:"user_id"`
	User      *User      `gorm:"foreignKey:UserID" json:"user,omitempty"`
	PostID    *uuid.UUID `gorm:"type:uuid" json:"post_id,omitempty"`
	Post      *Post      `gorm:"foreignKey:PostID" json:"post,omitempty"`
	CommentID *uuid.UUID `gorm:"type:uuid" json:"comment_id,omitempty"`
	Comment   *Comment   `gorm:"foreignKey:CommentID" json:"comment,omitempty"`
	CreatedAt time.Time  `json:"created_at"`
}

func (l *Like) BeforeCreate(tx *gorm.DB) error {
	if l.ID == uuid.Nil {
		l.ID = uuid.New()
	}
	return nil
}

func (l *Like) AfterCreate(tx *gorm.DB) error {
	if l.PostID != nil {
		return tx.Model(&Post{}).Where("id = ?", l.PostID).
			UpdateColumn("like_count", gorm.Expr("like_count + ?", 1)).Error
	}
	if l.CommentID != nil {
		return tx.Model(&Comment{}).Where("id = ?", l.CommentID).
			UpdateColumn("like_count", gorm.Expr("like_count + ?", 1)).Error
	}
	return nil
}

func (l *Like) AfterDelete(tx *gorm.DB) error {
	if l.PostID != nil {
		return tx.Model(&Post{}).Where("id = ?", l.PostID).
			UpdateColumn("like_count", gorm.Expr("like_count - ?", 1)).Error
	}
	if l.CommentID != nil {
		return tx.Model(&Comment{}).Where("id = ?", l.CommentID).
			UpdateColumn("like_count", gorm.Expr("like_count - ?", 1)).Error
	}
	return nil
}
