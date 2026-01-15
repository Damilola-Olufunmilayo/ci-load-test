# CI Load Test Project

Automated CI/CD pipeline for Kubernetes load testing with multi-node cluster provisioning and performance validation.

## Overview

This project implements an automated load testing workflow that:
- Provisions a multi-node Kubernetes cluster on CI runners
- Deploys multiple HTTP echo services with ingress routing
- Executes randomized load tests across services
- Reports performance metrics directly in pull requests

## Architecture

### Components
- **KinD (Kubernetes in Docker)**: Multi-node local cluster (1 control-plane + 2 workers)
- **Nginx Ingress Controller**: Routes traffic based on hostname
- **HTTP Echo Services**: Two deployments serving "foo" and "bar" responses
- **k6**: Modern load testing tool for performance validation

### Traffic Flow
```
GitHub PR → CI Trigger → KinD Cluster → Ingress → foo/bar Services → Load Test → PR Comment
```

## Technical Decisions

### Why KinD?
- Lightweight and fast for CI environments
- Native multi-node support
- Excellent ingress integration
- Minimal resource overhead

### Why k6?
- Modern, developer-friendly scripting (JavaScript)
- Rich metrics and thresholds
- Better performance than alternatives (JMeter, Locust)
- Native Prometheus integration for stretch goal

### Why Nginx Ingress?
- Industry standard
- Robust host-based routing
- Well-documented for KinD
- Production-parity in CI

## Getting Started

### Prerequisites
- GitHub account
- Repository with PR permissions

### Setup
1. Create a new repository
2. Copy all files maintaining the directory structure
3. Push to GitHub
4. Create a pull request to trigger the workflow

### Local Testing
```bash
# Setup cluster
./scripts/setup-cluster.sh

# Deploy apps
./scripts/deploy-apps.sh

# Run load test
./scripts/run-load-test.sh
```

## Workflow Steps

1. **Cluster Provisioning** (60-90s)
   - Creates 3-node KinD cluster
   - Installs Nginx ingress controller
   - Waits for readiness

2. **Application Deployment** (30-60s)
   - Applies foo/bar deployments (2 replicas each)
   - Configures ingress routing
   - Validates health checks

3. **Load Testing** (2m)
   - Ramps to 50 concurrent users
   - Randomizes traffic between hosts
   - Captures performance metrics

4. **Result Reporting**
   - Posts formatted metrics to PR
   - Includes p95/p99 latencies
   - Shows success rates

## Configuration

### Scaling
Modify `k8s/*-deployment.yaml` replicas:
```yaml
spec:
  replicas: 3  # Increase for more pods
```

### Load Test Intensity
Edit `/tmp/load-test.js` in `run-load-test.sh`:
```javascript
stages: [
  { duration: '1m', target: 100 },  # More users
]
```

## Monitoring (Stretch Goal)

To add Prometheus monitoring:

1. Deploy Prometheus operator
2. Add ServiceMonitor for echo services
3. Capture CPU/Memory during load test
4. Include metrics in PR report

See `docs/monitoring-setup.md` for implementation.

## Troubleshooting

### Ingress Not Ready
```bash
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller
```

### Pods CrashLooping
```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

### Load Test Failures
Check connectivity:
```bash
curl -H "Host: foo.localhost" http://localhost/
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes with clear commits
4. Open PR to see automated testing in action

## License

MIT
