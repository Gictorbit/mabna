package main

import (
	"context"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/shopspring/decimal"
	"go.uber.org/zap"
	"math/rand"
	"time"
)

func ImportRandomRows(conn *pgxpool.Pool, numRows uint, logger *zap.Logger) error {
	// Get the list of available instrument IDs
	instrumentIDs := []int{1, 2}

	// Generate random trades and insert them into the Trade table
	for i := uint(0); i < numRows; i++ {
		// Randomly select an instrument ID
		instrumentID := instrumentIDs[rand.Intn(len(instrumentIDs))]

		// Generate a random date
		date := time.Now().AddDate(0, 0, -rand.Intn(365))

		// Generate random trade values
		open := decimal.NewFromInt(int64(rand.Intn(10000)))
		high := open.Add(decimal.NewFromInt(int64(rand.Intn(1000))))
		low := open.Sub(decimal.NewFromInt(int64(rand.Intn(1000))))
		closed := low.Add(decimal.NewFromInt(int64(rand.Intn(2000))))
		logger.Info("import row",
			zap.Any("row", map[string]any{
				"open": open, "high": high, "low": low, "closed": closed,
			}),
		)
		// Insert the trade into the Trade table
		_, err := conn.Exec(context.Background(), `
			INSERT INTO Trade (InstrumentId, DateEn, Open, High, Low, Close) 
			VALUES ($1, $2, $3, $4, $5, $6)
		`, instrumentID, date, open, high, low, closed)
		if err != nil {
			return err
		}
	}

	return nil
}
