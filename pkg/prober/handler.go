package prober

import (
	"net/http"
	"time"

	"github.com/fernandonogueira/statuspage-exporter/pkg/config"

	"github.com/fernandonogueira/statuspage-exporter/pkg/engines"
	"github.com/labstack/echo/v4"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

func createMetrics() (*prometheus.GaugeVec, *prometheus.GaugeVec, *prometheus.GaugeVec) {
	componentStatus := prometheus.NewGaugeVec(
		prometheus.GaugeOpts{
			Name: "statuspage_component",
			Help: "Status of a service component. " +
				"0 - Unknown, 1 - Operational, 2 - Planned Maintenance, " +
				"3 - Degraded Performance, 4 - Partial Outage, 5 - Major Outage, 6 - Security Issue",
		},
		[]string{"service", "status_page_url", "component", "status"},
	)
	overallStatus := prometheus.NewGaugeVec(
		prometheus.GaugeOpts{
			Name: "statuspage_overall",
			Help: "Overall status of a service. " +
				"0 - Unknown, 1 - Operational, 2 - Planned Maintenance, " +
				"3 - Degraded Performance, 4 - Partial Outage, 5 - Major Outage, 6 - Security Issue",
		},
		[]string{"service", "status_page_url", "status"},
	)
	serviceStatusDurationGauge := prometheus.NewGaugeVec(
		prometheus.GaugeOpts{
			Name: "service_status_fetch_duration_seconds",
			Help: "Returns how long the service status fetch took to complete in seconds",
		},
		[]string{"status_page_url"},
	)

	return componentStatus, overallStatus, serviceStatusDurationGauge
}

// Handler returns a http handler for /probe endpoint.
func Handler(config *config.ExporterConfig) echo.HandlerFunc {
	return func(ctx echo.Context) error {
		targetURL := ctx.QueryParam("target")
		if targetURL == "" {
			return ctx.String(http.StatusBadRequest, "target is required")
		}

		start := time.Now()
		componentStatus, overallStatus, serviceStatusDurationGauge := createMetrics()
		registry := prometheus.NewRegistry()
		registry.MustRegister(componentStatus)
		registry.MustRegister(overallStatus)
		registry.MustRegister(serviceStatusDurationGauge)

		err := engines.FetchStatus(config, targetURL, componentStatus, overallStatus)
		if err != nil {
			return ctx.String(http.StatusInternalServerError, err.Error())
		}

		duration := time.Since(start).Seconds()

		serviceStatusDurationGauge.WithLabelValues(targetURL).Set(duration)

		h := echo.WrapHandler(
			promhttp.HandlerFor(registry, promhttp.HandlerOpts{}),
		)

		return h(ctx)
	}
}
