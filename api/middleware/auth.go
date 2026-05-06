package middleware

import (
	"net/http"
	"strings"

	"reserva-backend/security"

	"github.com/gin-gonic/gin"
)

func AuthMiddleware(builder security.Builder) gin.HandlerFunc {
	return func(c *gin.Context) {

		authHeader := c.GetHeader("Authorization")
		if len(authHeader) == 0 {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "token requerido"})
			return
		}

		fields := strings.Fields(authHeader)

		if len(fields) < 2 {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "formato inválido"})
			return
		}

		if strings.ToLower(fields[0]) != "bearer" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "tipo de autorización no soportado"})
			return
		}

		token := fields[1]

		payload, err := builder.VerifyToken(token)
		if err != nil {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
			return
		}

		// Guardar en contexto
		c.Set("user_id", payload.UserID)
		c.Set("email", payload.Email)
		c.Set("role", payload.Role)

		c.Next()
	}
}
