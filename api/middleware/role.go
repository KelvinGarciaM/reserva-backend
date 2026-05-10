package middleware

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

func RoleMiddleware(allowedRoles ...string) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Obtener rol del contexto (lo puso AuthMiddleware)
		role, exists := c.Get("role")
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "rol no encontrado"})
			c.Abort()
			return
		}

		userRole := role.(string)

		// Verificar si el rol está permitido
		for _, allowed := range allowedRoles {
			if userRole == allowed {
				c.Next()
				return
			}
		}

		c.JSON(http.StatusForbidden, gin.H{"error": "no tienes permiso para acceder a este recurso"})
		c.Abort()
	}
}
