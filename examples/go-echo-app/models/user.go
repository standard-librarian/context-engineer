package models

import "gorm.io/gorm"

// User represents a user in the system
type User struct {
	gorm.Model
	Name  string `json:"name" gorm:"not null"`
	Email string `json:"email" gorm:"unique;not null"`
	Role  string `json:"role" gorm:"default:'user'"`
}
