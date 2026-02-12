package main

import (
	"log"
	"os"

	"github.com/example/go-echo-app/context"
	"github.com/example/go-echo-app/handlers"
	"github.com/example/go-echo-app/models"
	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func main() {
	db, err := gorm.Open(sqlite.Open("users.db"), &gorm.Config{})
	if err != nil {
		log.Fatal("Failed to connect to database:", err)
	}

	if err := db.AutoMigrate(&models.User{}); err != nil {
		log.Fatal("Failed to migrate database:", err)
	}

	contextURL := os.Getenv("CONTEXT_API_URL")
	if contextURL == "" {
		contextURL = "http://localhost:4000/api"
	}
	contextClient := context.NewClient(contextURL)

	_ = contextClient.CreateADR(context.ADRRequest{
		Title:    "Use Echo Framework for Go REST API",
		Decision: "Selected Echo as the web framework for its simplicity and performance",
		Context:  "Need lightweight HTTP router with middleware support for REST API",
		OptionsConsidered: map[string][]string{
			"Echo": {
				"Fast and lightweight",
				"Good middleware ecosystem",
				"Simple routing",
			},
			"Gin": {
				"Also fast but more opinionated",
				"Larger community",
			},
		},
		Tags:         []string{"golang", "web-framework", "rest-api"},
		Stakeholders: []string{"backend-team"},
	})

	e := echo.New()

	e.Use(middleware.Logger())
	e.Use(middleware.Recover())
	e.Use(middleware.CORS())

	userHandler := handlers.NewUserHandler(db, contextClient)

	e.GET("/health", func(c echo.Context) error {
		return c.JSON(200, map[string]string{"status": "ok"})
	})

	e.GET("/users", userHandler.GetUsers)
	e.GET("/users/:id", userHandler.GetUser)
	e.POST("/users", userHandler.CreateUser)
	e.PUT("/users/:id", userHandler.UpdateUser)
	e.DELETE("/users/:id", userHandler.DeleteUser)

	e.POST("/context/query", func(c echo.Context) error {
		var req context.QueryRequest
		if err := c.Bind(&req); err != nil {
			return c.JSON(400, map[string]string{"error": "Invalid request"})
		}

		result, err := contextClient.Query(req)
		if err != nil {
			return c.JSON(500, map[string]string{"error": err.Error()})
		}

		return c.JSON(200, result)
	})

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("🚀 Server starting on :%s", port)
	log.Printf("📚 Context Engineering at: %s", contextURL)
	log.Fatal(e.Start(":" + port))
}
