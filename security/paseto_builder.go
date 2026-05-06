package security

import (
	"fmt"
	"time"

	"github.com/aead/chacha20poly1305"
	"github.com/o1egl/paseto"
)

type PasetoBuilder struct {
	paseto       *paseto.V2
	symmetricKey []byte
}

func NewPasetoBuilder(key string) (Builder, error) {
	if len(key) != chacha20poly1305.KeySize {
		return nil, fmt.Errorf("la llave debe tener %d caracteres", chacha20poly1305.KeySize)
	}

	return &PasetoBuilder{
		paseto:       paseto.NewV2(),
		symmetricKey: []byte(key),
	}, nil
}

func (b *PasetoBuilder) CreateToken(userID int32, email, role, name, image string, duration time.Duration) (string, error) {
	payload, err := NewPayload(userID, email, role, name, image, duration)
	if err != nil {
		return "", err
	}

	return b.paseto.Encrypt(b.symmetricKey, payload, nil)
}

func (b *PasetoBuilder) VerifyToken(token string) (*Payload, error) {
	payload := &Payload{}

	err := b.paseto.Decrypt(token, b.symmetricKey, payload, nil)
	if err != nil {
		return nil, ErrorInvalidToken
	}

	if err := payload.Valid(); err != nil {
		return nil, err
	}

	return payload, nil
}
