#!/bin/bash

set -uo pipefail
NS="devops-portfolio"
ERRORS=0
ok()   { echo "  [OK]   $1"; }
fail() { echo "  [FAIL] $1"; ERRORS=$((ERRORS+1)); }

echo "=== Verificación Kubernetes — TP09 ==="
echo ""

echo "--- Nodos del cluster ---"
kubectl get nodes --no-headers | while read line; do
    NAME=$(echo $line | awk '{print $1}')
    STATUS=$(echo $line | awk '{print $2}')
    [ "$STATUS" = "Ready" ] && ok "Nodo $NAME → $STATUS" || fail "Nodo $NAME → $STATUS"
done

echo ""
echo "--- Pods (deben estar Running) ---"
kubectl get pods -n $NS --no-headers 2>/dev/null | while read line; do
    NAME=$(echo $line   | awk '{print $1}')
    READY=$(echo $line  | awk '{print $2}')
    STATUS=$(echo $line | awk '{print $3}')
    [ "$STATUS" = "Running" ] && ok "$NAME → $STATUS ($READY)" || fail "$NAME → $STATUS"
done

echo ""
echo "--- Deployments ---"
kubectl get deployments -n $NS --no-headers 2>/dev/null | while read line; do
    NAME=$(echo $line    | awk '{print $1}')
    READY=$(echo $line   | awk '{print $2}')
    DESIRED=$(echo $line | awk '{print $4}')
    [ "$READY" = "$DESIRED/$DESIRED" ] && \
      ok "$NAME → $READY réplicas listas" || \
      fail "$NAME → $READY (esperado $DESIRED/$DESIRED)"
done

echo ""
echo "--- Services ---"
kubectl get svc -n $NS --no-headers 2>/dev/null | while read line; do
    NAME=$(echo $line | awk '{print $1}')
    TYPE=$(echo $line | awk '{print $2}')
    PORT=$(echo $line | awk '{print $5}')
    ok "$NAME → $TYPE ($PORT)"
done

echo ""
echo "--- PVC (debe estar Bound) ---"
kubectl get pvc -n $NS --no-headers 2>/dev/null | while read line; do
    NAME=$(echo $line   | awk '{print $1}')
    STATUS=$(echo $line | awk '{print $2}')
    SIZE=$(echo $line   | awk '{print $4}')
    [ "$STATUS" = "Bound" ] && ok "$NAME → $STATUS ($SIZE)" || fail "$NAME → $STATUS"
done

echo ""
echo "--- Healthcheck HTTP ---"
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}' 2>/dev/null)
CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "http://$NODE_IP:30080/" 2>/dev/null || echo "000")
[ "$CODE" = "200" ] && ok "http://$NODE_IP:30080 → HTTP $CODE" || fail "http://$NODE_IP:30080 → HTTP $CODE"

echo ""
[ "$ERRORS" -eq 0 ] && echo "Cluster OK — todos los checks pasaron" || echo "$ERRORS checks fallaron"
