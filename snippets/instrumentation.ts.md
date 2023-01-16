```
import { metrics } from "@opentelemetry/api"
import { NodeSDK } from "@opentelemetry/sdk-node"
import { getNodeAutoInstrumentations } from "@opentelemetry/auto-instrumentations-node"
import { Resource } from "@opentelemetry/resources"
import { SemanticResourceAttributes } from "@opentelemetry/semantic-conventions"
import { OTLPTraceExporter } from "@opentelemetry/exporter-trace-otlp-http"
import { MeterProvider, PeriodicExportingMetricReader } from "@opentelemetry/sdk-metrics"
import { OTLPMetricExporter } from "@opentelemetry/exporter-metrics-otlp-http"

const resource = Resource.default().merge(
  new Resource({
    [SemanticResourceAttributes.SERVICE_NAME]: process.env.SERVICE_NAME,
  })
)

const traceExporter = new OTLPTraceExporter({
  url: `${process.env.OTEL_COLLECTOR ? process.env.OTEL_COLLECTOR + "/v1/traces" : "http://localhost:4318/v1/traces"}`,
  headers: {},
})

const metricExporter = new OTLPMetricExporter({
  url: `${process.env.OTEL_COLLECTOR + "/v1/metrics" || "http://localhost:4318/v1/metrics"}`,
  concurrencyLimit: 1,
})

const meterProvider = new MeterProvider({
  resource: resource,
})

const metricReader = new PeriodicExportingMetricReader({
  exporter: metricExporter,

  // Default is 60000ms (60 seconds). Set to 3 seconds for demonstrative purposes only.
  exportIntervalMillis: 3000,
})

meterProvider.addMetricReader(metricReader)

// Set this MeterProvider to be global to the app being instrumented.
metrics.setGlobalMeterProvider(meterProvider)

export function getMeter() {
  return metrics.getMeter(process.env.SERVICE_NAME || "")
}

const sdk = new NodeSDK({
  resource,
  traceExporter,
  instrumentations: [getNodeAutoInstrumentations()],
})

// initialize the SDK and register with the OpenTelemetry API
// this enables the API to record telemetry
sdk
  .start()
  .then(() => console.log("Tracing initialized"))
  .catch((error) => console.log("Error initializing tracing", error))

// gracefully shut down the SDK on process exit
process.on("SIGTERM", () => {
  sdk
    .shutdown()
    .then(() => console.log("Tracing terminated"))
    .catch((error) => console.log("Error terminating tracing", error))
    .finally(() => process.exit(0))
})
```
