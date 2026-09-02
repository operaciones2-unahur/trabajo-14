# TP 10 — Kubernetes avanzado: Helm + Ingress

Empaqueta el mismo despliegue de TP09 como chart de Helm parametrizable,
con Ingress y HPA opcional.

## Requisitos

- Un cluster de Kubernetes con Ingress Controller instalado:

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace --set controller.service.type=NodePort --set controller.service.nodePorts.http=30080
```

- Las imágenes `backend`/`frontend` publicadas en Docker Hub (igual que
  en TP09): reemplazar `TU_USUARIO` en `values.yaml` por tu usuario real
  antes de instalar, o los pods quedan en `InvalidImageName`.

## Estructura del Chart

```
devops-portfolio/
├── Chart.yaml           # metadata del chart
├── values.yaml           # valores por defecto
├── values-dev.yaml       # override para desarrollo
├── values-prod.yaml      # override para producción
└── templates/
    ├── _helpers.tpl       # funciones reutilizables
    ├── namespace.yaml
    ├── secret.yaml
    ├── configmap.yaml
    ├── postgres.yaml      # PVC + Deployment + Service
    ├── backend.yaml       # Deployment + HPA + Service
    ├── frontend.yaml      # Deployment + Service
    ├── ingress.yaml       # Ingress con rutas
    └── NOTES.txt          # mensaje post-instalación
```

## Comandos principales

```bash
# Validar el chart
helm lint devops-portfolio/

# Ver manifests generados
helm template mi-app devops-portfolio/ --values values-dev.yaml

# Instalar
helm install mi-app devops-portfolio/ --values values-dev.yaml

# Actualizar
helm upgrade mi-app devops-portfolio/ --values values-dev.yaml

# Rollback
helm rollback mi-app 1

# Desinstalar
helm uninstall mi-app
```

## Ingress: routing por paths

| Path | Servicio destino |
|---|---|
| `/` | frontend-service :80 |
| `/api/*` | backend-service :5000 |
| `/health` | backend-service :5000 |

## Multi-entorno

```bash
helm install mi-app devops-portfolio/ --values values-dev.yaml   # dev
helm install mi-app devops-portfolio/ --values values-prod.yaml  # prod
```

## Notas

- No uses `helm install ... --create-namespace`: el chart ya define su
  propio `templates/namespace.yaml`, y si Helm crea el namespace antes con
  ese flag, la instalación falla con `namespaces "devops-portfolio"
  already exists`. Instalando sin el flag (como en los comandos de
  arriba), Helm guarda el release en el namespace de tu contexto actual,
  y los recursos igual quedan en `devops-portfolio` porque cada template
  lo declara de forma explícita en su `metadata.namespace`.
- Para acceder por el Ingress hace falta un `/etc/hosts` apuntando
  `devops-portfolio.dev` (o `.local`, según el `values.yaml` que uses) a
  la IP del nodo:

```bash
echo "$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}') devops-portfolio.dev" | sudo tee -a /etc/hosts
```
