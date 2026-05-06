package handlers

import (
	"database/sql"
	"errors"
	"net/http"
	"strconv"

	"reserva-backend/dto"

	"github.com/gin-gonic/gin"
)

type RecepcionistaHandler struct {
	q *dto.Queries
}

func NewRecepcionistaHandler(q *dto.Queries) *RecepcionistaHandler {
	return &RecepcionistaHandler{q}
}

/* =========================
   REQUESTS
========================= */

type createRecepcionistaRequest struct {
	Cedula    int32  `json:"cedula" binding:"required"`
	Nombre    string `json:"nombre" binding:"required"`
	Apellidos string `json:"apellidos" binding:"required"`
	Telefono  string `json:"telefono" binding:"required"`
	Correo    string `json:"correo" binding:"required"`
}

type updateRecepcionistaRequest struct {
	Cedula    int32  `json:"cedula" binding:"required"`
	Nombre    string `json:"nombre" binding:"required"`
	Apellidos string `json:"apellidos" binding:"required"`
	Telefono  string `json:"telefono" binding:"required"`
	Correo    string `json:"correo" binding:"required"`
	Estado    int8   `json:"estado" binding:"required"`
}

type recepcionistaCedulaRequest struct {
	Cedula int32 `json:"cedula" binding:"required"`
}

/* =========================
   CREATE
========================= */

func (h *RecepcionistaHandler) CreateRecepcionista(c *gin.Context) {
	var req createRecepcionistaRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "datos inválidos"})
		return
	}

	result, err := h.q.CreateRecepcionista(c.Request.Context(), dto.CreateRecepcionistaParams{
		Cedula:    req.Cedula,
		Nombre:    req.Nombre,
		Apellidos: req.Apellidos,
		Telefono:  req.Telefono,
		Correo:    req.Correo,
	})

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "error creando recepcionista"})
		return
	}

	rows, _ := result.RowsAffected()
	if rows == 0 {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "no se creó el recepcionista"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "recepcionista creado"})
}

/* =========================
   GET
========================= */

func (h *RecepcionistaHandler) GetRecepcionistas(c *gin.Context) {
	data, err := h.q.GetRecepcionistas(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "error obteniendo recepcionistas"})
		return
	}

	c.JSON(http.StatusOK, data)
}

func (h *RecepcionistaHandler) GetRecepcionistaByCedula(c *gin.Context) {
	param := c.Param("cedula")

	cedula, err := strconv.Atoi(param)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "cédula inválida"})
		return
	}

	data, err := h.q.GetRecepcionistaByCedula(c.Request.Context(), int32(cedula))
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			c.JSON(http.StatusNotFound, gin.H{"error": "no existe"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": "error"})
		return
	}

	c.JSON(http.StatusOK, data)
}

func (h *RecepcionistaHandler) SearchRecepcionistas(c *gin.Context) {
	query := c.Query("q")

	if query == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "q requerido"})
		return
	}

	data, err := h.q.SearchRecepcionistas(
		c.Request.Context(),
		dto.SearchRecepcionistasParams{
			CONCAT:   query,
			CONCAT_2: query,
			CONCAT_3: query,
			CONCAT_4: query,
			CONCAT_5: query,
		},
	)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "error buscando"})
		return
	}

	c.JSON(http.StatusOK, data)
}

/* =========================
   UPDATE
========================= */

func (h *RecepcionistaHandler) UpdateRecepcionista(c *gin.Context) {
	var req updateRecepcionistaRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "datos inválidos"})
		return
	}

	result, err := h.q.UpdateRecepcionista(c.Request.Context(), dto.UpdateRecepcionistaParams{
		Nombre:    req.Nombre,
		Apellidos: req.Apellidos,
		Telefono:  req.Telefono,
		Correo:    req.Correo,
		Estado:    req.Estado,
		Cedula:    req.Cedula,
	})

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "error actualizando"})
		return
	}

	rows, _ := result.RowsAffected()
	if rows == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "no existe"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "actualizado"})
}

/* =========================
   DELETE / TOGGLE
========================= */

func (h *RecepcionistaHandler) DeleteRecepcionista(c *gin.Context) {
	var req recepcionistaCedulaRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "datos inválidos"})
		return
	}

	result, err := h.q.DeleteRecepcionista(c.Request.Context(), req.Cedula)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "error"})
		return
	}

	rows, _ := result.RowsAffected()
	if rows == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "no existe"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "desactivado"})
}

func (h *RecepcionistaHandler) ToggleRecepcionistaEstado(c *gin.Context) {
	var req recepcionistaCedulaRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "datos inválidos"})
		return
	}

	result, err := h.q.ToggleRecepcionistaEstado(c.Request.Context(), req.Cedula)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "error"})
		return
	}

	rows, _ := result.RowsAffected()
	if rows == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "no existe"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "estado actualizado"})
}
