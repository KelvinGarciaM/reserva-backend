package handlers

import (
	"context"
	"errors"
	"net/http"
	"sync"
	"time"

	"reserva-backend/repository"

	"github.com/gin-gonic/gin"
)

const tiempoMaxRespaldo = 10 * time.Minute

type RespaldoHandler struct {
	repository *repository.RespaldoRepository
	ocupado    sync.Mutex
}

func NewRespaldoHandler(repository *repository.RespaldoRepository) *RespaldoHandler {
	return &RespaldoHandler{repository: repository}
}

type restaurarRespaldoRequest struct {
	Nombre string `json:"nombre" binding:"required"`
}

func respaldoError(c *gin.Context, status int, mensaje string) {
	c.JSON(status, gin.H{"error": mensaje, "mensaje": mensaje})
}

func contextoLargo(c *gin.Context) (context.Context, context.CancelFunc) {
	return context.WithTimeout(
		context.WithoutCancel(c.Request.Context()),
		tiempoMaxRespaldo,
	)
}

// Listar godoc
// @Summary Listar respaldos
// @Tags respaldos
// @Produce json
// @Security BearerAuth
// @Success 200 {array} repository.Respaldo
// @Router /respaldos [get]
func (h *RespaldoHandler) Listar(c *gin.Context) {
	ctx, cancel := context.WithTimeout(c.Request.Context(), time.Minute)
	defer cancel()

	respaldos, err := h.repository.Listar(ctx)
	if err != nil {
		respaldoError(c, http.StatusInternalServerError, err.Error())
		return
	}

	c.JSON(http.StatusOK, respaldos)
}

// Crear godoc
// @Summary Crear respaldo completo
// @Tags respaldos
// @Produce json
// @Security BearerAuth
// @Success 201 {object} repository.RespaldoResultado
// @Router /respaldos [post]
func (h *RespaldoHandler) Crear(c *gin.Context) {
	if !h.ocupado.TryLock() {
		respaldoError(c, http.StatusConflict,
			"Ya hay un respaldo o una restauración en curso. Espera a que termine.")
		return
	}
	defer h.ocupado.Unlock()

	ctx, cancel := contextoLargo(c)
	defer cancel()

	resultado, err := h.repository.Crear(ctx)
	if err != nil {
		respaldoError(c, http.StatusInternalServerError, err.Error())
		return
	}

	c.JSON(http.StatusCreated, resultado)
}

// Restaurar godoc
// @Summary Restaurar respaldo
// @Tags respaldos
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param request body restaurarRespaldoRequest true "Nombre del respaldo"
// @Success 200 {object} repository.RespaldoResultado
// @Router /respaldos/restaurar [post]
func (h *RespaldoHandler) Restaurar(c *gin.Context) {
	var req restaurarRespaldoRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		respaldoError(c, http.StatusBadRequest, "Debes indicar el nombre del respaldo.")
		return
	}

	if !h.ocupado.TryLock() {
		respaldoError(c, http.StatusConflict,
			"Ya hay un respaldo o una restauración en curso. Espera a que termine.")
		return
	}
	defer h.ocupado.Unlock()

	ctx, cancel := contextoLargo(c)
	defer cancel()

	resultado, err := h.repository.Restaurar(ctx, req.Nombre)
	if err != nil {
		if errors.Is(err, repository.ErrRespaldoNoEncontrado) {
			respaldoError(c, http.StatusNotFound, err.Error())
			return
		}
		respaldoError(c, http.StatusInternalServerError, err.Error())
		return
	}

	c.JSON(http.StatusOK, resultado)
}
