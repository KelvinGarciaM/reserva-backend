package security

import "time"

type Builder interface {
	CreateToken(userID int32, email, role, name, image string, duration time.Duration) (string, error)
	VerifyToken(token string) (*Payload, error)
}
