package middleware

import (
	"net/http"
	"strings"

	"reserva-backend/conexion"
	"reserva-backend/security"

	"github.com/gin-gonic/gin"
)

// AuthMiddleware valida el token y la sesión en CADA petición protegida.
// Deja en el contexto la conexión del usuario, para que todas las consultas
// se ejecuten con sus permisos del motor.

func AuthMiddleware(token security.Builder, sessions *security.SessionStore) gin.HandlerFunc {
	return func(c *gin.Context) {
		cabecera := c.GetHeader("Authorization")
		partes := strings.SplitN(cabecera, " ", 2)

		if len(partes) != 2 || !strings.EqualFold(partes[0], "Bearer") {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "token requerido"})
			return
		}

		payload, err := token.VerifyToken(partes[1])
		if err != nil {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
			return
		}

		// ---- SESIÓN ----
		sess, ok := sessions.Get(payload.SessionID)
		if !ok {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{
				"error": "la sesión expiró, inicia sesión de nuevo",
			})
			return
		}

		c.Set("payload", payload)
		c.Set("session_id", payload.SessionID)
		c.Set("role", sess.Role)
		c.Request = c.Request.WithContext(
			conexion.WithDB(c.Request.Context(), sess.DB),
		)
		// ----------------

		c.Next()
	}
}

// RequireRole bloquea la ruta si el rol de la sesión no está permitido.
// Es una segunda barrera: aunque se saltaran esto, el motor igual negaría el
// permiso. Sirve para dar un mensaje claro en lugar de un error de SQL.
func RequireRole(roles ...string) gin.HandlerFunc {
	return func(c *gin.Context) {
		rolAny, _ := c.Get("role")
		rol, _ := rolAny.(string)

		for _, permitido := range roles {
			if rol == permitido {
				c.Next()
				return
			}
		}

		c.AbortWithStatusJSON(http.StatusForbidden, gin.H{
			"error": "No tienes permiso para realizar esta acción",
		})
	}
}
