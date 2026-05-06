package security

import (
	"errors"
	"time"
)

var (
	ErrorInvalidToken = errors.New("token inválido")
	ErrorExpiredToken = errors.New("token expirado")
)

type Payload struct {
	UserID    int32     `json:"user_id"`
	Email     string    `json:"email"`
	Role      string    `json:"role"`
	Name      string    `json:"name"`
	Image     string    `json:"image"`
	IssuedAt  time.Time `json:"issued_at"`
	ExpiredAt time.Time `json:"expired_at"`
}

func NewPayload(userID int32, email, role, name, image string, duration time.Duration) (*Payload, error) {
	return &Payload{
		UserID:    userID,
		Email:     email,
		Role:      role,
		Name:      name,
		Image:     image,
		IssuedAt:  time.Now(),
		ExpiredAt: time.Now().Add(duration),
	}, nil
}

func (p *Payload) Valid() error {
	if time.Now().After(p.ExpiredAt) {
		return ErrorExpiredToken
	}
	return nil
}
