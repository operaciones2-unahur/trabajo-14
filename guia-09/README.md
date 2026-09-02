# TP09 — Kubernetes: Pods, Deployments y Services

Despliega la app de notas de TP06 en un cluster de Kubernetes: namespace
propio, Secret y ConfigMap para la configuración, PVC para Postgres, y
Deployments con probes para backend y frontend.

## Requisitos

- Un cluster de Kubernetes accesible con `kubectl` (Killercoda, k3d, KinD
  o minikube).
- Las imágenes `backend` y `frontend` publicadas en un registro público
  (Docker Hub), con el pipeline de TP07 ya corrido al menos una vez.

## Antes de aplicar los manifiestos

`manifests/backend/deployment.yml` y `manifests/frontend/deployment.yml`
usan `image: TU_USUARIO/devops-portfolio:latest` y
`TU_USUARIO/devops-frontend:latest`. Reemplazá `TU_USUARIO` por tu usuario
real de Docker Hub antes de aplicar — si no, los pods quedan en
`InvalidImageName` (Kubernetes no acepta mayúsculas en nombres de
repositorio, así que el placeholder literal ni siquiera llega a intentar
el pull).

## Arquitectura

Namespace: devops-portfolio 
├── Deployment: postgres (1 réplica) ← ClusterIP :5432 
├── Deployment: backend (2 réplicas) ← ClusterIP :5000 
└── Deployment: frontend (2 réplicas) ← NodePort :30080

## Recursos Kubernetes usados

|         Recurso         |               Para qué sirve             |
|-                      --|-                                       --|
| `Namespace`             | Aislar todos los recursos del proyecto   |
| `Secret`                | Credenciales de Postgres en base64       |
| `ConfigMap`             | Variables de entorno no sensibles        |
| `PersistentVolumeClaim` | Almacenamiento persistente para DB       |
| `Deployment`            | Gestión declarativa de pods y réplicas   |
| `Service ClusterIP`    | Comunicación interna entre pods           |
| `Service NodePort`    | Exposición al exterior del cluster         |
| `initContainer`      | Esperar a que Postgres esté listo           |
| `readinessProbe`    | Verificar que el pod está listo para tráfico |
| `livenessProbe`     | Reiniciar pod si está colgado                |
| `resources`         | Límites de CPU y memoria por pod             |

## Deploy

Ejecutar en bash
bash scripts/deploy.sh
Verificar
bash scripts/verificar.sh
kubectl get all -n devops-portfolio
Comandos útiles
# Escalar backend a 3 réplicas
kubectl scale deployment backend --replicas=3 -n devops-portfolio

# Ver logs en tiempo real
kubectl logs -l app=backend -n devops-portfolio -f

# Entrar a un pod
kubectl exec -it <pod-name> -n devops-portfolio -- /bin/bash

# Rollback
kubectl rollout undo deployment/backend -n devops-portfolio

## Notas

- `deploy.sh` aplica `base/`, espera a Postgres, aplica `db/` en paralelo
  a lo declarado, después `backend/` y por último `frontend/`. Si
  Postgres tarda en arrancar (primera vez que Kubernetes baja la imagen
  `postgres:16-alpine` puede tardar más de un minuto en clusters lentos),
  el script puede cortar por timeout en `kubectl rollout status` — volver
  a correrlo alcanza, porque `kubectl apply` es idempotente.
- El Secret trae credenciales en base64 (`postgres` / `devops123`), el
  mismo valor que usa `.env.example` en el resto de las guías: es un
  placeholder de laboratorio, no una contraseña real.
