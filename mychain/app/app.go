package app

import (
	"path/filepath"

	dbm "github.com/cosmos/cosmos-db"

	clienthelpers "cosmossdk.io/client/v2/helpers"
	"cosmossdk.io/log/v2"
	"cosmossdk.io/simapp"
	"github.com/cosmos/cosmos-sdk/baseapp"

	servertypes "github.com/cosmos/cosmos-sdk/server/types"
)

const Name = "MyChain"

// DefaultNodeHome is the default data directory for the custom chain binary.
var DefaultNodeHome string

func init() {
	var err error
	DefaultNodeHome, err = clienthelpers.GetNodeHomeDirectory(filepath.Join(".", ".mychain"))
	if err != nil {
		panic(err)
	}
}

// App is a thin alias around simapp so the chain can evolve behind its own package.
type App = simapp.SimApp

// New creates the custom chain application.
func New(
	logger log.Logger,
	db dbm.DB,
	loadLatest bool,
	appOpts servertypes.AppOptions,
	baseAppOptions ...func(*baseapp.BaseApp),
) *App {
	return simapp.NewSimApp(logger, db, loadLatest, appOpts, baseAppOptions...)
}
