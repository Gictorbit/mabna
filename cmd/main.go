package main

import (
	"github.com/gictorbit/mabna/db"
	"github.com/gictorbit/mabna/service"
	"github.com/urfave/cli/v2"
	"go.uber.org/zap"
	"log"
	"os"
	"os/signal"
	"syscall"
)

func main() {
	app := &cli.App{
		Name:  "finance",
		Usage: "finance service",
		Commands: []*cli.Command{
			{
				Name:  "api",
				Usage: "runs finance api",
				Action: func(ctx *cli.Context) error {
					finEnv, err := service.ReadFinanceEnvironment()
					if err != nil {
						return err
					}
					loggerConfig := zap.NewProductionConfig()
					if finEnv.DebugMode {
						loggerConfig.Level = zap.NewAtomicLevelAt(zap.DebugLevel)
					}
					logger, err := loggerConfig.Build()
					if err != nil {
						return err
					}

					userDB, err := db.NewFinanceWithURL(finEnv.FinanceDatabase)
					if err != nil {
						return err
					}

					httpserver := service.NewFinanceServer(logger, userDB, finEnv)
					go func() {
						if e := httpserver.Run(finEnv.Host, finEnv.Port); e != nil {
							logger.Error("failed to start user http", zap.Error(e))
						}
					}()

					sigs := make(chan os.Signal, 1)
					signal.Notify(sigs, syscall.SIGINT, syscall.SIGTERM)
					<-sigs
					logger.Info("stop http server")
					return nil
				},
			},
		},
	}

	if e := app.Run(os.Args); e != nil {
		logger, err := zap.NewProduction()
		if err != nil {
			log.Fatalf("create new logger failed:%v\n", err)
		}
		logger.Error("failed to run app", zap.Error(e))
	}
}
