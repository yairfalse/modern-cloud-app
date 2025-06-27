package logger

import (
	"fmt"
	"log"
	"os"
	"time"

	"github.com/gin-gonic/gin"
)

type Logger struct {
	*log.Logger
}

func NewLogger(environment string) *Logger {
	flags := log.LstdFlags
	if environment == "development" {
		flags |= log.Lshortfile
	}

	return &Logger{
		Logger: log.New(os.Stdout, "", flags),
	}
}

func (l *Logger) Info(v ...interface{}) {
	logger := log.New(l.Writer(), "[INFO] ", l.Flags())
	_ = logger.Output(2, fmt.Sprint(v...))
}

func (l *Logger) Error(v ...interface{}) {
	logger := log.New(l.Writer(), "[ERROR] ", l.Flags())
	_ = logger.Output(2, fmt.Sprint(v...))
}

func (l *Logger) Debug(v ...interface{}) {
	logger := log.New(l.Writer(), "[DEBUG] ", l.Flags())
	_ = logger.Output(2, fmt.Sprint(v...))
}

func (l *Logger) Fatal(v ...interface{}) {
	logger := log.New(l.Writer(), "[FATAL] ", l.Flags())
	_ = logger.Output(2, fmt.Sprint(v...))
	os.Exit(1)
}

func GinLogger(logger *Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()
		path := c.Request.URL.Path
		raw := c.Request.URL.RawQuery

		c.Next()

		latency := time.Since(start)
		clientIP := c.ClientIP()
		method := c.Request.Method
		statusCode := c.Writer.Status()
		errorMessage := c.Errors.ByType(gin.ErrorTypePrivate).String()

		if raw != "" {
			path = path + "?" + raw
		}

		message := fmt.Sprintf("%s | %3d | %13v | %15s | %-7s %s",
			time.Now().Format("2006/01/02 - 15:04:05"),
			statusCode,
			latency,
			clientIP,
			method,
			path,
		)

		if errorMessage != "" {
			message = fmt.Sprintf("%s | %s", message, errorMessage)
		}

		switch {
		case statusCode >= 500:
			logger.Error(message)
		case statusCode >= 400:
			logger.Info(message)
		default:
			logger.Info(message)
		}
	}
}
