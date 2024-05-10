package service

import (
	"github.com/caarlos0/env/v10"
	"github.com/joho/godotenv"
	"os"
)

type FinanceEnvConfig struct {
	FinanceDatabase string `env:"FINANCE_POSTGRES,notEmpty"`
	DebugMode       bool   `env:"DEBUG_MODE" envDefault:"false"`
	Host            string `env:"HOST" envDefault:"0.0.0.0"`
	Port            uint   `env:"PORT" envDefault:"3000"`
	Address         string `env:"ADDRESS,expand" envDefault:"$HOST:$PORT"`
	LogRequests     bool   `env:"LOG_REQUESTS" envDefault:"false"`
}

func ReadFinanceEnvironment() (*FinanceEnvConfig, error) {
	envFilePath := "finance.env"
	if CheckFileExists(envFilePath) {
		if err := godotenv.Load(envFilePath); err != nil {
			return nil, err
		}
	}
	cfg := &FinanceEnvConfig{}
	err := env.Parse(cfg)
	if err != nil {
		return nil, err
	}
	return cfg, nil
}

func CheckFileExists(filePath string) bool {
	_, err := os.Stat(filePath)
	if os.IsNotExist(err) {
		return false
	}
	return true
}
