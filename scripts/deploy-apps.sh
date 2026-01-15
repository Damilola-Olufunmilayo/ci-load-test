#!/bin/bash
set -euo pipefail

echo "======================================"
echo "🚀 Deploying Applications"
echo "======================================"

# Apply all Kubernetes manifests
echo "Applying foo deployment..."
kubectl apply -f k8s/foo-deployment.yaml

echo "Applying bar deployment..."
kubectl apply -f k8s/bar-deployment.yaml

echo "Applying ingress configuration..."
kubectl apply -f k8s/ingress.yaml

echo ""
echo "⏳ Waiting for deployments to be ready..."

# Wait for deployments to be available
echo "Waiting for foo-echo deployment..."
kubectl wait --for=condition=available --timeout=180s deployment/foo-echo || {
  echo "❌ foo-echo deployment failed to become ready"
  kubectl describe deployment foo-echo
  kubectl get pods -l app=foo-echo
  exit 1
}

echo "Waiting for bar-echo deployment..."
kubectl wait --for=condition=available --timeout=180s deployment/bar-echo || {
  echo "❌ bar-echo deployment failed to become ready"
  kubectl describe deployment bar-echo
  kubectl get pods -l app=bar-echo
  exit 1
}

# Wait for all pods to be ready
echo "Waiting for all foo-echo pods to be ready..."
kubectl wait --for=condition=ready pod -l app=foo-echo --timeout=180s || {
  echo "❌ foo-echo pods failed to become ready"
  kubectl get pods -l app=foo-echo
  kubectl logs -l app=foo-echo --tail=50
  exit 1
}

echo "Waiting for all bar-echo pods to be ready..."
kubectl wait --for=condition=ready pod -l app=bar-echo --timeout=180s || {
  echo "❌ bar-echo pods failed to become ready"
  kubectl get pods -l app=bar-echo
  kubectl logs -l app=bar-echo --tail=50
  exit 1
}

# Wait for ingress to be configured
echo ""
echo "⏳ Waiting for ingress to be configured..."
sleep 15

# Verify ingress exists
kubectl get ingress echo-ingress -o wide || {
  echo "❌ Ingress not found"
  exit 1
}

echo ""
echo "======================================"
echo "🔍 Testing Connectivity"
echo "======================================"

# Test connectivity with retries
max_attempts=30
attempt=0
foo_ready=false
bar_ready=false

while [ $attempt -lt $max_attempts ]; do
  echo "Test attempt $((attempt + 1))/$max_attempts..."
  
  # Test foo endpoint
  foo_response=$(curl -s -H "Host: foo.localhost" http://localhost/ || echo "error")
  if echo "$foo_response" | grep -q "foo"; then
    foo_ready=true
    echo "✅ foo.localhost is responding correctly"
  fi
  
  # Test bar endpoint
  bar_response=$(curl -s -H "Host: bar.localhost" http://localhost/ || echo "error")
  if echo "$bar_response" | grep -q "bar"; then
    bar_ready=true
    echo "✅ bar.localhost is responding correctly"
  fi
  
  # Check if both are ready
  if [ "$foo_ready" = true ] && [ "$bar_ready" = true ]; then
    echo ""
    echo "======================================"
    echo "✅ All Applications Healthy!"
    echo "======================================"
    break
  fi
  
  attempt=$((attempt + 1))
  sleep 2
done

# Final check
if [ "$foo_ready" = false ] || [ "$bar_ready" = false ]; then
  echo ""
  echo "❌ Endpoints did not become ready in time"
  echo "Foo ready: $foo_ready"
  echo "Bar ready: $bar_ready"
  echo ""
  echo "Debugging information:"
  kubectl get pods -o wide
  kubectl get svc
  kubectl get ingress
  kubectl describe ingress echo-ingress
  kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller --tail=50
  exit 1
fi

# Show final status
echo ""
echo "Deployment Status:"
kubectl get deployments
echo ""
echo "Pod Status:"
kubectl get pods -o wide
echo ""
echo "Service Status:"
kubectl get svc
echo ""
echo "Ingress Status:"
kubectl get ingress
echo ""
echo "======================================"
