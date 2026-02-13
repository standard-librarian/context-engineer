package handlers

import (
	"fmt"
	"net/http"
	"strconv"

	"github.com/example/go-echo-app/context"
	"github.com/example/go-echo-app/models"
	"github.com/labstack/echo/v4"
	"gorm.io/gorm"
)

type UserHandler struct {
	db      *gorm.DB
	context *context.Client
}

func NewUserHandler(db *gorm.DB, contextClient *context.Client) *UserHandler {
	return &UserHandler{
		db:      db,
		context: contextClient,
	}
}

func (h *UserHandler) GetUsers(c echo.Context) error {
	var users []models.User
	if err := h.db.Find(&users).Error; err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{
			"error": "Failed to fetch users",
		})
	}
	return c.JSON(http.StatusOK, users)
}

func (h *UserHandler) GetUser(c echo.Context) error {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": "Invalid user ID",
		})
	}

	var user models.User
	if err := h.db.First(&user, id).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return c.JSON(http.StatusNotFound, map[string]string{
				"error": "User not found",
			})
		}
		return c.JSON(http.StatusInternalServerError, map[string]string{
			"error": "Failed to fetch user",
		})
	}

	return c.JSON(http.StatusOK, user)
}

func (h *UserHandler) CreateUser(c echo.Context) error {
	user := new(models.User)
	if err := c.Bind(user); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": "Invalid request body",
		})
	}

	ctx, err := h.context.Query(context.QueryRequest{
		Query:   "user management validation email",
		Domains: []string{"validation", "users"},
	})
	if err == nil && len(ctx.KeyDecisions) > 0 {
		fmt.Printf("📚 Context check: Found %d relevant decisions\n", len(ctx.KeyDecisions))
		for _, dec := range ctx.KeyDecisions {
			fmt.Printf("  - %s: %s\n", dec.ID, dec.Title)
		}
	}

	if err := h.db.Create(user).Error; err != nil {
		_ = h.context.RecordFailure(context.FailureRequest{
			Title:      "User Creation Failed",
			RootCause:  fmt.Sprintf("Database error: %v", err),
			Symptoms:   "POST /users returned 500",
			Impact:     "User registration blocked",
			Resolution: "Investigating...",
			Severity:   "medium",
			Pattern:    "database_error",
			Tags:       []string{"users", "database"},
		})

		return c.JSON(http.StatusInternalServerError, map[string]string{
			"error": "Failed to create user",
		})
	}

	return c.JSON(http.StatusCreated, user)
}

func (h *UserHandler) UpdateUser(c echo.Context) error {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": "Invalid user ID",
		})
	}

	var user models.User
	if err := h.db.First(&user, id).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return c.JSON(http.StatusNotFound, map[string]string{
				"error": "User not found",
			})
		}
		return c.JSON(http.StatusInternalServerError, map[string]string{
			"error": "Failed to fetch user",
		})
	}

	updates := new(models.User)
	if err := c.Bind(updates); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": "Invalid request body",
		})
	}

	if err := h.db.Model(&user).Updates(updates).Error; err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{
			"error": "Failed to update user",
		})
	}

	return c.JSON(http.StatusOK, user)
}

func (h *UserHandler) DeleteUser(c echo.Context) error {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": "Invalid user ID",
		})
	}

	if err := h.db.Delete(&models.User{}, id).Error; err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{
			"error": "Failed to delete user",
		})
	}

	return c.JSON(http.StatusOK, map[string]string{
		"message": "User deleted successfully",
	})
}
