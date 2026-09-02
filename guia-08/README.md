# TP08 — Monitoreo con Prometheus y Grafana

Toma la app de TP06 y le agrega instrumentación con `prometheus_client`
(endpoint `/metrics` en el backend) más un stack completo de monitoreo:
Prometheus, Grafana, Node Exporter y cAdvisor, todo en el mismo
`docker-compose.yml`.

## Requisitos

- Docker y Docker Compose.
- Puertos 80, 3000 y 9090 libres en el host.

## Stack completo

| Servicio | Puerto | Función |
|---|---|---|
| App Flask | :5000 (interno) | Expone `/metrics` con prometheus_client |
| Prometheus | :9090 | Scrape cada 15s, retención 15 días |
| Grafana | :3000 | Dashboards + provisioning automático |
| Node Exporter | :9100 (interno) | CPU, RAM, disco, red del host |
| cAdvisor | :8080 (interno) | Métricas de contenedores Docker |

## Acceso

Ejecutar en bash
docker compose up -d
# Grafana: http://localhost:3000  →  admin / devops123
# Prometheus: http://localhost:9090
Dashboard: 8 paneles
    • Requests por segundo (stat)
    • Latencia p50 (stat)
    • Total notas en DB (stat)
    • Tasa de errores 5xx (stat)
    • Requests por endpoint (timeseries)
    • Latencia p50/p95/p99 (timeseries)
    • CPU del host (timeseries)
    • Memoria del host (timeseries)
Alertas configuradas
    • AppDown — backend caído por más de 1 minuto
    • HighCPU — CPU > 80% por 2 minutos
    • HighErrorRate — errores 5xx > 5% por 1 minuto
    • DiskSpaceLow — disco > 85% por 5 minutos
Métricas propias de la app
app_requests_total          # contador por método/endpoint/status
app_request_duration_seconds # histograma de latencia
app_notes_total              # gauge: notas en la DB
app_db_errors_total          # contador de errores de DB
app_info                     # versión y entorno

## Generar tráfico y verificar

```bash
bash scripts/generar-trafico.sh &
bash scripts/verificar-monitoreo.sh
```

`generar-trafico.sh` pega contra `http://localhost` (el puerto del
frontend) durante 2 minutos para que los paneles de Grafana tengan datos.
`verificar-monitoreo.sh` chequea que los 5 servicios estén corriendo, que
Prometheus/Grafana/Node-Exporter respondan, y lista el estado de los
targets configurados en Prometheus.

## Notas

- Sin el override de desarrollo de TP06, `docker compose up -d` levanta la
  imagen productiva del backend (gunicorn), no el hot-reload.
- Si Prometheus o Grafana no arrancan por "port is already allocated",
  revisá que no tengas otro proceso u otro proyecto usando los puertos
  9090 o 3000.
