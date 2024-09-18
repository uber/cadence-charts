# Cadence Charts

This repo contains Cadence helm chart maintained by original Cadence team @Uber.
This is an early version with known gaps and not production ready yet. Please create an issue explaining your use case and what you would want us to prioritize.

**What is included:**
- Cadence backend services as separate deployments: frontend, history, matching, worker
- An ephemeral Cassandra instance

**What is missing:**
- Support for advanced visibility store such as Elasticsearch/Pinot
- Support for databases other than Cassandra
- Metrics integration with Prometheus
- Custom annotations/labels/tolerations/security context etc.
- Support for ingress

## Usage

[Helm](https://helm.sh) must be installed to use the charts.  Please refer to
Helm's [documentation](https://helm.sh/docs) to get started.

Once Helm has been set up correctly, add the repo as follows:

  helm repo add cadence https://uber.github.io/cadence-charts

If you had already added this repo earlier, run `helm repo update` to retrieve
the latest versions of the packages.  You can then run `helm search repo
cadence` to see the charts.

To install the cadence chart:

    helm install my-cadence cadence/cadence

To uninstall the chart:

    helm delete my-cadence
