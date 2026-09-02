# DevOps Portfolio — TP0 7: CI/CD

![CI/CD Pipeline](https://github.com/TU_USUARIO/devops-TP06/actions/workflows/cicd.yml/badge.svg)

App de notas con pipeline CI/CD completo usando GitHub Actions. Parte de la
app de TP06 y le agrega tests (`backend/tests/`) y dos workflows:
`cicd.yml` (lint → test → build/push → deploy) y `pr-check.yml`.

## Levantarla local (sin GitHub)

```bash
cp .env.example .env
docker compose up -d --build
curl http://localhost/health
```

## Pipeline

|   Stage    |       Trigger   | Qué hace                           |
|-         --|-              --|--                                 -|
| lint       | todo push       | flake8 en Python, yamllint en YAML |
| test       | después de lint | pytest con reporte de cobertura    |
| build-push | main y develop  | docker buildx, push a Docker Hub   |
| deploy     | solo main       | SSH al servidor, compose pull + up |

## 4 Secrets requeridos

    • DOCKERHUB_USERNAME, 
    • DOCKERHUB_TOKEN DEPLOY_HOST, 
    • DEPLOY_USER, 
    • DEPLOY_SSH_KEY

## Correr tests localmente

Ejecutar en bash
cd backend
pip install -r requirements.txt
pytest tests/ -v --cov=. --cov-report=term-missing
Estructura del pipeline
feature/* → lint → test
develop   → lint → test → build → push
main      → lint → test → build → push → deploy

## Notas

- Sin los 5 secrets configurados en el repo de GitHub, `lint` y `test`
  corren igual (no los necesitan); `build-push` necesita
  `DOCKERHUB_USERNAME`/`DOCKERHUB_TOKEN`, y `deploy` necesita los 3
  restantes. Si no tenés un servidor propio para el `deploy`, es normal
  que ese job falle — alcanza con que los otros tres queden en verde.
- El pipeline corre `flake8` con `--max-line-length=100` sobre `backend/`:
  el código del backend ya está formateado para pasar esa regla (imports
  en líneas separadas, dos líneas en blanco antes de `if __name__`).

