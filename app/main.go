// infra-lab demo-app: a tiny HTTP service that exposes Prometheus metrics and
// reports Postgres connectivity. Endpoints: / , /healthz , /metrics.
package main

import (
	"context"
	"database/sql"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"github.com/prometheus/client_golang/prometheus/promhttp"

	_ "github.com/lib/pq"
)

// version is overridden at build time via -ldflags "-X main.version=<sha>".
var version = "dev"

var (
	httpRequests = promauto.NewCounterVec(prometheus.CounterOpts{
		Name: "demoapp_http_requests_total",
		Help: "Total HTTP requests by path and status.",
	}, []string{"path", "status"})

	httpDuration = promauto.NewHistogramVec(prometheus.HistogramOpts{
		Name:    "demoapp_http_request_duration_seconds",
		Help:    "HTTP request latency in seconds by path.",
		Buckets: prometheus.DefBuckets,
	}, []string{"path"})
)

// statusRecorder captures the response status code for metrics.
type statusRecorder struct {
	http.ResponseWriter
	status int
}

func (r *statusRecorder) WriteHeader(code int) {
	r.status = code
	r.ResponseWriter.WriteHeader(code)
}

// instrument records request count + latency for a handler.
func instrument(path string, h http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		rec := &statusRecorder{ResponseWriter: w, status: http.StatusOK}
		h(rec, r)
		httpDuration.WithLabelValues(path).Observe(time.Since(start).Seconds())
		httpRequests.WithLabelValues(path, fmt.Sprintf("%d", rec.status)).Inc()
	}
}

func dbStatus(db *sql.DB) string {
	if db == nil {
		return "not configured"
	}
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()
	if err := db.PingContext(ctx); err != nil {
		return "error: " + err.Error()
	}
	return "connected"
}

func main() {
	addr := envOr("LISTEN_ADDR", ":8080")

	var db *sql.DB
	if dsn := os.Getenv("DATABASE_URL"); dsn != "" {
		var err error
		db, err = sql.Open("postgres", dsn)
		if err != nil {
			log.Printf("db open: %v", err)
		} else {
			db.SetMaxOpenConns(5)
		}
	}

	mux := http.NewServeMux()
	mux.HandleFunc("/", instrument("/", func(w http.ResponseWriter, _ *http.Request) {
		fmt.Fprintf(w, "infra-lab demo-app\nversion: %s\ndb: %s\n", version, dbStatus(db))
	}))
	mux.HandleFunc("/healthz", instrument("/healthz", func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusOK)
		fmt.Fprintln(w, "ok")
	}))
	mux.Handle("/metrics", promhttp.Handler())

	log.Printf("demo-app %s listening on %s", version, addr)
	srv := &http.Server{
		Addr:              addr,
		Handler:           mux,
		ReadHeaderTimeout: 5 * time.Second,
	}
	log.Fatal(srv.ListenAndServe())
}

func envOr(k, def string) string {
	if v := os.Getenv(k); v != "" {
		return v
	}
	return def
}
