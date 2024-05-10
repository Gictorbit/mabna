package db

import (
	"context"
	"github.com/shopspring/decimal"
	"time"
)

type Trade struct {
	Date                   time.Time       `json:"latestTradeDate"`
	Open, High, Low, Close decimal.Decimal `json:"open, high, low, close"`
}

type Instrument struct {
	Id          int    `json:"instrumentId"`
	Name        string `json:"instrumentName"`
	LatestTrade Trade  `json:"latestTrade"`
}

const getLatestTradesQuery = `
	SELECT i.Id AS InstrumentId, i.Name AS InstrumentName, t.DateEn AS LatestTradeDate, t.Open, t.High, t.Low, t.Close
			FROM Instrument i
			LEFT JOIN (
				SELECT InstrumentId, DateEn, Open, High, Low, Close
				FROM Trade t1
				WHERE DateEn = (
					SELECT MAX(DateEn)
					FROM Trade t2
					WHERE t1.InstrumentId = t2.InstrumentId
				)
			) t ON i.Id = t.InstrumentId;
`

func (fdb *FinanceDB) GetLatestTrades(ctx context.Context) ([]Instrument, error) {
	rows, err := fdb.postgresConn.Query(ctx, getLatestTradesQuery)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var instruments []Instrument
	for rows.Next() {
		var instrument Instrument
		var latestTradeDate time.Time
		var open, high, low, closed decimal.Decimal

		err = rows.Scan(&instrument.Id, &instrument.Name, &latestTradeDate, &open, &high, &low, &closed)
		if err != nil {
			return nil, err
		}

		instrument.LatestTrade = Trade{
			Date:  latestTradeDate,
			Open:  open,
			High:  high,
			Low:   low,
			Close: closed,
		}

		instruments = append(instruments, instrument)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}
	return instruments, nil
}
