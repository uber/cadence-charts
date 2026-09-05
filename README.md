# Cadence Charts

This repository contains the Helm chart for [Cadence](https://cadenceworkflow.io/), maintained by the Cadence Community. The chart deploys the Cadence server components and the Cadence Web UI on Kubernetes.

## What is included

- **Cadence backend services** as separate deployments: frontend, history, matching, worker.
- **Fully customizable service configuration** via `values.yaml` with complete Cadence server settings support.
- **Customizable replica counts** and resource limits, plus optional HorizontalPodAutoscalers, PodDisruptionBudgets, NetworkPolicies and RBAC.
- **Customizable dynamic config** as a ConfigMap.
- **Multiple database options**: Cassandra, PostgreSQL and MySQL, either deployed as Bitnami chart dependencies or pointed at your own external database. Only Cassandra is deployed by default (`cassandra.enabled: true`); PostgreSQL and MySQL are opt-in.
- **Advanced visibility**: Elasticsearch (v6/v7) or OpenSearch (v2), with Kafka available for async visibility processing.
- **Automatic schema setup jobs**: auto-detection of database versions with configurable schema initialization for:
  - Primary databases (Cassandra, PostgreSQL, MySQL) — enabled by default (`schema.serverJob.enabled: true`)
  - Elasticsearch/OpenSearch for advanced visibility — opt-in (`schema.elasticSearchJob.enabled: false`)
- **Prometheus metrics**: metrics are exposed by default (`metrics.enabled: true`), with optional `ServiceMonitor` (Prometheus Operator) and `PodMonitoring` (Google Cloud Managed Service for Prometheus) resources.
- **TLS support** for database and service connections — see [docs/TLS.md](charts/cadence/docs/TLS.md).
- **Cloud SQL support** on GKE, including the Cloud SQL Proxy as a native sidecar — see [docs/gcp/deploying-with-cloud-sql.md](charts/cadence/docs/gcp/deploying-with-cloud-sql.md).
- **Cadence Web UI**: web interface for workflow visualization and management.

## Prerequisites

- Kubernetes 1.29+ (the chart sets `kubeVersion: ">=1.29.0-0"`; native sidecar init containers, used by the Cloud SQL Proxy integration, require 1.29)
- Helm 3.2.0+
- PV provisioner support in the underlying infrastructure (if persistence is enabled for databases)

## Installation

[Helm](https://helm.sh) must be installed to use the charts. Please refer to
Helm's [documentation](https://helm.sh/docs) to get started.

### Add Helm Repository

Once Helm has been set up correctly, add the repo as follows:

```bash
helm repo add cadence https://cadence-workflow.github.io/cadence-charts
```

If you had already added this repo earlier, run `helm repo update` to retrieve
the latest versions of the packages:

```bash
helm repo update
```

You can then run `helm search repo cadence` to see the charts.

### Install Chart Dependencies for local Chart

To edit the chart files locally, you need to update the chart dependencies (Cassandra, PostgreSQL, MySQL, Elasticsearch, OpenSearch, Kafka):

```bash
# Download the chart
helm pull cadence/cadence --untar

# Navigate to the chart directory
cd cadence

# Update dependencies
helm dependency update

# After that you can install using local directory
```

This will download the required subcharts based on your configuration.

### Install Cadence

To install the cadence chart with default settings (includes Cassandra):

```bash
helm install cadence-release -n cadencetest cadence/cadence
```

The chart will automatically:
- Deploy the selected database (Cassandra by default)
- Run schema setup jobs to initialize the database
- Deploy all Cadence services (frontend, history, matching, worker)
- Deploy the Cadence Web UI

To install with custom values:

```bash
helm install cadence-release cadence/cadence -f custom-values.yaml
```

### Install with Different Database

To use PostgreSQL instead of Cassandra:

```bash
helm install cadence-release cadence/cadence \
  --set cassandra.enabled=false \
  --set postgresql.enabled=true \
  --set config.persistence.database.driver="postgres" \
  --set config.persistence.database.sql.user="cadence" \
  --set config.persistence.database.sql.password="<password>"
```

To use MySQL instead of Cassandra:

```bash
helm install cadence-release cadence/cadence \
  --set cassandra.enabled=false \
  --set mysql.enabled=true \
  --set config.persistence.database.driver="mysql" \
  --set config.persistence.database.sql.user="cadence" \
  --set config.persistence.database.sql.password="<password>"
```

When the corresponding subchart is enabled, `config.persistence.database.sql.hosts` is generated automatically as
`{release-name}-{postgresql|mysql}.{namespace}.svc.cluster.local`. Set it explicitly to point at an external database.

Ready-made examples for these setups live in
[charts/cadence/examples](charts/cadence/examples) (`values.postgres.yaml`, `values.mysql.yaml`,
`values.cassandra.pvc.yaml`, `values.mysql-cloudsql.yaml`, `values.podmonitoring.yaml` and more).

### Enable Advanced Visibility

Advanced visibility can be backed by either Elasticsearch or OpenSearch. Both use Kafka to write visibility
records asynchronously, and both need the Elasticsearch schema job plus the matching dynamic config values.

With Elasticsearch (see [values.postgres-es7.yaml](charts/cadence/examples/values.postgres-es7.yaml)):

```yaml
elasticsearch:
  enabled: true
kafka:
  enabled: true

config:
  persistence:
    elasticsearch:
      enabled: true
      # v6, or v7 for v7 and higher; os2 for OpenSearch 2.x
      version: "v7"
  kafka:
    enabled: true

schema:
  elasticSearchJob:
    enabled: true

dynamicConfig:
  values:
    system.writeVisibilityStoreName:
      - value: "es"
    system.readVisibilityStoreName:
      - value: "es"
```

For OpenSearch, set `opensearch.enabled: true`, `elasticsearch.enabled: false` and
`config.persistence.elasticsearch.version: "os2"` instead. A complete example is in
[values.postgres-os2.yaml](charts/cadence/examples/values.postgres-os2.yaml).

### Enable Metrics Scraping

Metrics are exposed on port `9090` by default. To have them scraped, enable the resource that matches your
monitoring stack:

```bash
# Prometheus Operator
helm install cadence-release cadence/cadence \
  --set metrics.serviceMonitor.enabled=true

# Google Cloud Managed Service for Prometheus
helm install cadence-release cadence/cadence \
  --set metrics.podMonitoring.enabled=true
```

See [values.podmonitoring.yaml](charts/cadence/examples/values.podmonitoring.yaml) for target labels and
metric relabeling options, and [examples/grafana](examples/grafana) for a sample Grafana setup.

### Verify Installation

Check the status of your deployment:

```bash
# Check all pods
kubectl get pods -l app.kubernetes.io/instance=cadence-release

# Check schema setup jobs
kubectl get jobs -l app.kubernetes.io/component=schema-server

# Check service status
kubectl get svc -l app.kubernetes.io/instance=cadence-release
```

Wait for all pods to be in `Running` state and schema jobs to complete successfully.

## Configuration

See the chart [values.yaml](charts/cadence/values.yaml) file for configuration options, and the generated
[chart README](charts/cadence/README.md) for the full table of values with defaults and descriptions. You can
override any value using the `--set` flag or by providing a custom values file.

### Common Configuration Examples

```bash
# Set custom replica counts
helm install cadence-release cadence/cadence -n cadencetest \
  --set frontend.replicas=3 \
  --set history.replicas=3

# Use external database
helm install cadence-release cadence/cadence -n cadencetest \
  --set cassandra.enabled=false \
  --set config.persistence.database.cassandra.hosts=my-cassandra.example.com

# Disable automatic schema setup (if managing schemas externally)
helm install cadence-release cadence/cadence -n cadencetest \
  --set schema.serverJob.enabled=false
```

### TLS

TLS can be enabled independently for Cassandra, PostgreSQL, MySQL, Elasticsearch/OpenSearch and Kafka
connections, with certificates supplied through `global.tls.volumes` / `global.tls.volumeMounts`. See
[docs/TLS.md](charts/cadence/docs/TLS.md) for per-service configuration, certificate formats, file
permissions and troubleshooting.

### Cloud SQL on GKE

The chart can run the Cloud SQL Proxy as a native sidecar init container (`cloudSqlProxy.enabled=true`),
including IAM database authentication and Workload Identity. See
[docs/gcp/deploying-with-cloud-sql.md](charts/cadence/docs/gcp/deploying-with-cloud-sql.md) for the four
supported connection options.

### Full Server Configuration

All Cadence server configuration options are available through values.yaml under `config`. This includes:
- Persistence settings
- Service-specific configurations
- Clustering options
- Authentication and authorization
- Archival configuration
- And more...

Refer to the [Cadence server documentation](https://cadenceworkflow.io/docs/operation-guide/setup/) for detailed configuration options.

## Uninstallation

To uninstall/delete the chart:

```bash
helm delete cadence-release -n cadencetest
```

This will remove all Kubernetes components associated with the chart and delete the release.

## Upgrading

To upgrade an existing release:

```bash
# Update repository
helm repo update

# Upgrade release
helm upgrade cadence-release cadence/cadence -n cadencetest

# Upgrade with new values
helm upgrade cadence-release cadence/cadence -n cadencetest -f custom-values.yaml
```

## Troubleshooting

### Schema Jobs Failing

If schema setup jobs fail, check the logs:
```bash
kubectl logs job/cadence-release-schema-server
kubectl logs job/cadence-release-schema-elasticsearch
```

### Services Not Starting

Ensure schema jobs have completed successfully before services start:
```bash
kubectl get jobs
```

### Version Compatibility

The schema jobs automatically detect versions, but ensure your Cadence server version is compatible with your database version.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for instructions on how to contribute, run samples, and more. The chart
README under `charts/cadence` is generated with [helm-docs](https://github.com/norwoodj/helm-docs); run
`helm-docs` after changing `values.yaml` so it stays in sync.

## Community & Support

- **Documentation**: [Cadence Documentation](https://cadenceworkflow.io/docs/)
- **Community Chat**: Join our [CNCF Slack](https://communityinviter.com/apps/cloud-native/cncf) and find us in the `#cadence` channel
- **Contributing**: See [CONTRIBUTING.md](CONTRIBUTING.md) for instructions on how to contribute, run samples etc.
- **Issues**: Report bugs and request features via [GitHub Issues](https://github.com/cadence-workflow/cadence-charts/issues)
