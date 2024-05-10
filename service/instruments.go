package service

import (
	"go.uber.org/zap"
	"net/http"
)

// GetTrades returns instruments and their latest trades
func (is *FinanceServer) GetTrades(resp http.ResponseWriter, request *http.Request) {
	trades, err := is.dbConn.GetLatestTrades(request.Context())
	if err != nil {
		is.log.Error("failed to get trades", zap.Error(err))
		respondWithError(resp, http.StatusInternalServerError, "Failed to get trades")
		return
	}
	is.log.Info("get trades successfully", zap.Any("trades", trades))
	respondWithJSON(resp, http.StatusOK, trades)
	return
}
