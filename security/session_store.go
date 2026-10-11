package security

import (
	"database/sql"
	"sync"
	"time"

	"github.com/google/uuid"
)

// Session representa a un usuario del motor con la sesión abierta.
// La contraseña NO se guarda: solo queda la conexión ya autenticada.
type Session struct {
	DB        *sql.DB
	Username  string
	Role      string
	ExpiresAt time.Time
}

// SessionStore guarda las sesiones activas en memoria (id -> sesión).
type SessionStore struct {
	mu    sync.RWMutex
	items map[string]*Session
}

func NewSessionStore() *SessionStore {
	s := &SessionStore{items: make(map[string]*Session)}
	go s.limpiarVencidas()
	return s
}

// Create registra la sesión y devuelve su identificador (va dentro del token).
func (s *SessionStore) Create(sess *Session) string {
	id := uuid.NewString()

	s.mu.Lock()
	s.items[id] = sess
	s.mu.Unlock()

	return id
}

// Get devuelve la sesión si existe y no ha vencido.
func (s *SessionStore) Get(id string) (*Session, bool) {
	s.mu.RLock()
	sess, ok := s.items[id]
	s.mu.RUnlock()

	if !ok || time.Now().After(sess.ExpiresAt) {
		return nil, false
	}
	return sess, true
}

// Delete cierra la conexión del usuario y elimina la sesión.
func (s *SessionStore) Delete(id string) {
	s.mu.Lock()
	sess, ok := s.items[id]
	delete(s.items, id)
	s.mu.Unlock()

	if ok && sess.DB != nil {
		_ = sess.DB.Close()
	}
}

func (s *SessionStore) limpiarVencidas() {
	ticker := time.NewTicker(10 * time.Minute)
	defer ticker.Stop()

	for range ticker.C {
		ahora := time.Now()
		var vencidas []string

		s.mu.RLock()
		for id, sess := range s.items {
			if ahora.After(sess.ExpiresAt) {
				vencidas = append(vencidas, id)
			}
		}
		s.mu.RUnlock()

		for _, id := range vencidas {
			s.Delete(id)
		}
	}
}
