package main

import (
	"database/sql"
	"fmt"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/joho/godotenv"
	"github.com/pocketbase/dbx"
	"github.com/pocketbase/pocketbase"
	"github.com/pocketbase/pocketbase/apis"
	"github.com/pocketbase/pocketbase/core"
	"github.com/pocketbase/pocketbase/plugins/ghupdate"
	"github.com/pocketbase/pocketbase/plugins/jsvm"
	"github.com/pocketbase/pocketbase/plugins/migratecmd"
	"github.com/pocketbase/pocketbase/tools/hook"
	"github.com/tursodatabase/go-libsql"
	// "github.com/pocketbase/pocketbase/tools/security"
	// _ "github.com/tursodatabase/libsql-client-go/libsql"
)

// register the libsql driver to use the same query builder
// implementation as the already existing sqlite3 builder
func init() {
	dbx.BuilderFuncMap["libsql"] = dbx.BuilderFuncMap["sqlite3"]
}

func Open(driverName, dsn string) (*dbx.DB, error) {
	primaryUrl := os.Getenv("TURSO_URL")
	authToken := os.Getenv("TURSO_AUTH_TOKEN")
	if strings.Contains(primaryUrl, "libsql") {
		if authToken == "" {
			return nil, fmt.Errorf("TURSO_AUTH_TOKEN must not be empty when TURSO_URL is from the turso platform")
		}
	}

	// use sqlite driver when TURSO_URL is not set
	if primaryUrl == "" {
		fmt.Println("using sqlite driver")
		db, err := sql.Open("libsql", "file:"+dsn)
		if err != nil {
			return nil, err
		}
		return dbx.NewFromDB(db, driverName), nil
	}

	// ensure TURSO_URL is reachable
	toHTTP := strings.Replace(primaryUrl, "libsql", "http", 1)
	_, err := http.Get(toHTTP + "/health")
	if err != nil {
		return nil, err
	}

	syncInterval := time.Second
	if authToken == "" || strings.Contains(primaryUrl, "http") {
		fmt.Println("connecting to libsql replica")
		connector, err := libsql.NewEmbeddedReplicaConnector(dsn, primaryUrl,
			libsql.WithSyncInterval(syncInterval))
		if err != nil {
			return nil, err
		}
		sqlDB := sql.OpenDB(connector)

		return dbx.NewFromDB(sqlDB, driverName), nil
	}

	fmt.Println("connecting to turso replica")
	connector, err := libsql.NewEmbeddedReplicaConnector(dsn, primaryUrl,
		libsql.WithAuthToken(authToken),
		libsql.WithSyncInterval(syncInterval))
	if err != nil {
		return nil, err
	}

	sqlDB := sql.OpenDB(connector)

	return dbx.NewFromDB(sqlDB, driverName), nil
}

func main() {
	err := godotenv.Load()
	if err != nil {
		log.Fatal("Error loading .env file")
	}

	godotenv.Read()

	app := pocketbase.NewWithConfig(pocketbase.Config{
		DBConnect: func(dbPath string) (*dbx.DB, error) {
			if strings.Contains(dbPath, "data.db") {
				return Open("sqlite3", dbPath)
			}
			// optionally for the logs (aka. pb_data/auxiliary.db) use the default local filesystem driver
			return core.DefaultDBConnect(dbPath)
		},
	})


	// ---------------------------------------------------------------
	// Optional plugin flags:
	// ---------------------------------------------------------------

	var hooksDir string
	app.RootCmd.PersistentFlags().StringVar(
		&hooksDir,
		"hooksDir",
		"",
		"the directory with the JS app hooks",
	)

	var hooksWatch bool
	app.RootCmd.PersistentFlags().BoolVar(
		&hooksWatch,
		"hooksWatch",
		true,
		"auto restart the app on pb_hooks file change",
	)

	var hooksPool int
	app.RootCmd.PersistentFlags().IntVar(
		&hooksPool,
		"hooksPool",
		15,
		"the total prewarm goja.Runtime instances for the JS app hooks execution",
	)

	var migrationsDir string
	app.RootCmd.PersistentFlags().StringVar(
		&migrationsDir,
		"migrationsDir",
		"",
		"the directory with the user defined migrations",
	)

	var automigrate bool
	app.RootCmd.PersistentFlags().BoolVar(
		&automigrate,
		"automigrate",
		true,
		"enable/disable auto migrations",
	)

	var publicDir string
	app.RootCmd.PersistentFlags().StringVar(
		&publicDir,
		"publicDir",
		defaultPublicDir(),
		"the directory to serve static files",
	)

	var indexFallback bool
	app.RootCmd.PersistentFlags().BoolVar(
		&indexFallback,
		"indexFallback",
		true,
		"fallback the request to index.html on missing static path (eg. when pretty urls are used with SPA)",
	)

	app.RootCmd.ParseFlags(os.Args[1:])
	// ---------------------------------------------------------------
	// Plugins and hooks:
	// ---------------------------------------------------------------

	// load jsvm (pb_hooks and pb_migrations)
	jsvm.MustRegister(app, jsvm.Config{
		MigrationsDir: migrationsDir,
		HooksDir:      hooksDir,
		HooksWatch:    hooksWatch,
		HooksPoolSize: hooksPool,
	})

	// migrate command (with js templates)
	migratecmd.MustRegister(app, app.RootCmd, migratecmd.Config{
		TemplateLang: migratecmd.TemplateLangJS,
		Automigrate:  automigrate,
		Dir:          migrationsDir,
	})

	// GitHub self update
	ghupdate.MustRegister(app, app.RootCmd, ghupdate.Config{})

	// static route to serves files from the provided public dir
	// (if publicDir exists and the route path is not already defined)
	app.OnServe().Bind(&hook.Handler[*core.ServeEvent]{
		Func: func(e *core.ServeEvent) error {
			if !e.Router.HasRoute(http.MethodGet, "/{path...}") {
				e.Router.GET("/{path...}", apis.Static(os.DirFS(publicDir), indexFallback))
			}

			return e.Next()
		},
		Priority: 999, // execute as latest as possible to allow users to provide their own route
	})

	if err := app.Start(); err != nil {
		log.Fatal(err)
	}
}

// the default pb_public dir location is relative to the executable
func defaultPublicDir() string {
	if strings.HasPrefix(os.Args[0], os.TempDir()) {
		// most likely ran with go run
		return "./pb_public"
	}

	return filepath.Join(os.Args[0], "../pb_public")
}
