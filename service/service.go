package service

import (
	"encoding/json"
	"fmt"
	findb "github.com/gictorbit/mabna/db"
	"github.com/gorilla/mux"
	"go.uber.org/zap"
	"net"
	"net/http"
	"time"
)

type FinanceServer struct {
	Router *mux.Router
	dbConn findb.FinanceDatabase
	log    *zap.Logger
	env    *FinanceEnvConfig
}

func NewFinanceServer(logger *zap.Logger, dbConn findb.FinanceDatabase, finEnv *FinanceEnvConfig) *FinanceServer {
	server := &FinanceServer{
		Router: mux.NewRouter(),
		log:    logger,
		dbConn: dbConn,
		env:    finEnv,
	}
	server.InitializeRoutes()
	return server
}

func (is *FinanceServer) Run(host string, port uint) error {
	is.log.Info("running http server",
		zap.String("addr", net.JoinHostPort(host, fmt.Sprintf("%d", port))),
	)
	srv := &http.Server{
		Addr:         net.JoinHostPort(host, fmt.Sprintf("%d", port)),
		WriteTimeout: time.Second * 15,
		ReadTimeout:  time.Second * 15,
		IdleTimeout:  time.Second * 60,
		Handler:      is.Router,
	}
	if err := srv.ListenAndServe(); err != nil {
		return err
	}
	return nil
}

func (is *FinanceServer) InitializeRoutes() {
	is.Router.HandleFunc("/api/v1/trades", is.GetTrades).Methods("GET")
}

func respondWithError(w http.ResponseWriter, code int, message string) {
	respondWithJSON(w, code, map[string]any{"message": message, "code": code})
}

func respondWithJSON(w http.ResponseWriter, code int, payload any) {
	response, _ := json.Marshal(payload)
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)
	w.Write(response)
}
