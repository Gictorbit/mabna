package db

import (
	"context"
	"github.com/jackc/pgx/v5/pgxpool"
	"time"
)

//go:generate mockgen -source=$GOFILE -destination=mock_db/conn.go -package=$GOPACKAG
type FinanceDatabase interface {
	GetPgConn() *pgxpool.Pool
	GetLatestTrades(ctx context.Context) ([]Instrument, error)
}

var _ FinanceDatabase = &FinanceDB{}

type FinanceDB struct {
	postgresConn *pgxpool.Pool
}

func (fdb *FinanceDB) GetPgConn() *pgxpool.Pool {
	return fdb.postgresConn
}

func NewFinanceDB(rawConn *pgxpool.Pool) *FinanceDB {
	return &FinanceDB{
		postgresConn: rawConn,
	}
}

func NewFinanceWithURL(databaseURL string) (*FinanceDB, error) {
	pgxPool, err := ConnectToFinanceDB(databaseURL)
	if err != nil {
		return nil, err
	}
	return NewFinanceDB(pgxPool), nil
}

func ConnectToFinanceDB(databaseURL string) (*pgxpool.Pool, error) {
	ctx, cancel := context.WithTimeout(context.Background(), time.Second*10)
	defer cancel()
	rawConn, err := pgxpool.New(ctx, databaseURL)
	if err != nil {
		return nil, err
	}
	return rawConn, nil
}
