# TP11 — Infraestructura como Código con Terraform

Levanta la misma app de notas, pero con Terraform y el provider
`kreuzwerker/docker` en vez de `docker compose`: redes, volúmenes y
contenedores manejados como código, en tres módulos (`network`, `storage`,
`app`).

## Requisitos

- Terraform >= 1.6 y Docker.

## Recursos creados

| Recurso | Tipo | Módulo |
|---|---|---|
| Red app (`*-app-dev`) | `docker_network` | network |
| Red monitoring (`*-monitoring-dev`) | `docker_network` | network |
| Volumen Postgres | `docker_volume` | storage |
| Volumen Grafana | `docker_volume` | storage |
| Volumen Prometheus | `docker_volume` | storage |
| Contenedor Postgres | `docker_container` | app |
| Contenedor Backend (×N) | `docker_container` | app |
| Contenedor Frontend | `docker_container` | app |

## Uso

Ejecutar en bash
# Copiar y editar variables
cp terraform.tfvars.example terraform.tfvars

# Ciclo completo
terraform init
terraform validate
terraform plan
terraform apply

# Ver outputs
terraform output

# Destruir
terraform destroy
Multi-entorno
# Desarrollo (defaults)
terraform apply

# Producción
terraform apply -var-file=envs/prod/terraform.tfvars
Estructura de módulos
modules/
├── network/   → redes Docker con subnets dedicadas
├── storage/   → volúmenes persistentes con labels
└── app/       → contenedores con healthchecks y dependencias

## Notas

- El `terraform.tfvars` real (con contraseñas) nunca se sube a git —
  `.gitignore` sólo deja pasar `terraform.tfvars.example`. Cada quien
  copia el ejemplo y lo completa localmente.
- `frontend_port` en `terraform.tfvars.example` es 8080, no 80: pensado
  para poder correr TP11 sin chocar con el puerto que usan TP06/TP07/TP08
  si los tenés levantados al mismo tiempo con Docker Compose.
- **Limitación real del ejercicio, ya probada**: el módulo `app` usa
  `python:3.12-slim` como imagen del backend (`var.backend_image`) tal
  como lo define el Word, sin `command` ni código de la app copiado
  adentro. Un contenedor así arranca y se cierra solo en un par de
  segundos (lo probé con `docker run python:3.12-slim`: termina en 3
  segundos porque no tiene nada que ejecutar), y con
  `restart = "unless-stopped"` queda reiniciándose en loop. El
  `healthcheck` de ese contenedor (`curl -f
  http://localhost:$PORT/health`) nunca va a pasar, y
  `scripts/verificar.sh` va a marcar el contenedor `backend` como
  `[FAIL]`. `terraform apply` igual va a terminar bien — Terraform no
  depende de que el healthcheck pase para dar por creado el recurso — y
  las redes, los volúmenes y el contenedor de Postgres sí quedan
  operativos y correctos. Este TP está pensado para practicar el ciclo de
  Terraform en sí (`init`/`plan`/`apply`/`state`/`destroy`, módulos,
  variables, outputs), no para dejar la Notes App completa funcionando
  end-to-end — para eso están TP06 a TP10.
