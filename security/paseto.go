package security

import (
	"time"

	"github.com/o1egl/paseto"
)

var pasetoMaker = paseto.NewV2()
var secretKey = []byte("12345678901234567890123456789012") // 32 bytes

type Payload struct {
	UserID int32  `json:"user_id"`
	Email  string `json:"email"`
	Exp    int64  `json:"exp"`
}

func CreateToken(userID int32, email string) (string, error) {
	payload := Payload{
		UserID: userID,
		Email:  email,
		Exp:    time.Now().Add(24 * time.Hour).Unix(),
	}

	return pasetoMaker.Encrypt(secretKey, payload, nil)
}
func VerifyToken(token string) (*Payload, error) {
	var payload Payload

	err := pasetoMaker.Decrypt(token, secretKey, &payload, nil)
	if err != nil {
		return nil, err
	}

	// validar expiración
	if payload.Exp < time.Now().Unix() {
		return nil, err
	}

	return &payload, nil
}
