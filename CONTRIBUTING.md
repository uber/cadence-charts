# CONTRIBUTING

## Build and generate template yml locally

```
helm package ./charts/cadence
helm template cadence-release cadencechart-0.1.0.tgz > template_out.yaml
```

## Build and deploy to a k8s cluster

```
helm package ./charts/cadence
helm upgrade --install cadence-release cadencechart-0.1.0.tgz \
    -n cadencetest \
    --create-namespace
```

Port forward to check the UI
```
kubectl port-forward svc/cadence-web-service 8088:8088 -n cadencetest
```

Port forward frontend service to run CLI commands
```
kubectl port-forward svc/cadence-frontend 7933:7933 -n cadencetest
```

Register domain:
```
cadence --address localhost:7933 \
    --env development \
    --domain samples-domain domain register
```

Run samples:
1. Clone https://github.com/uber-common/cadence-samples

2. Change host in config/development.yaml
```
host: "localhost:7833"
```

3. Port forward to frontend on 7833
```
kubectl port-forward svc/cadence-frontend-headless 7833:7833 -n cadencetest
```

4. Run sample worker (run at samples repo root)
```
./bin/helloworld -m worker
```

5. Trigger a workflow  (run at samples repo root)
```
./bin/helloworld -m trigger
```

Visit localhost:8088 and validate the new workflow exists!

## Generate helmdocs

Install [helm-docs](https://github.com/norwoodj/helm-docs):
```
go install github.com/norwoodj/helm-docs/cmd/helm-docs@latest
```

Run it
```
helm-docs
```

cadencechart/README.md file should be updated.


## Publish chart

Cadence chart is hosted on github pages and automation is done using [Chart Releaser Action](https://helm.sh/docs/howto/chart_releaser_action/).
