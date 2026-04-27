package middleware

import (
	"net/http"
	"strings"

	"reserva-backend/security"

	"github.com/gin-gonic/gin"
)

func AuthMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {

		header := c.GetHeader("Authorization")

		if header == "" {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "token requerido"})
			c.Abort()
			return
		}

		token := strings.TrimPrefix(header, "Bearer ")

		payload, err := security.VerifyToken(token)
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "token inválido"})
			c.Abort()
			return
		}

		// guardar en contexto
		c.Set("user_id", payload.UserID)
		c.Set("email", payload.Email)

		c.Next()
	}
}
