# TP06 — Docker Compose: Notes App

Aplicación multicontenedor con frontend Nginx, API Flask/Gunicorn y PostgreSQL persistente. Es la base sobre la que se construyen el resto de las guías (TP07 en adelante).

## Requisitos

- Docker y Docker Compose.

## Cómo levantarla

```bash
cp .env.example .env
docker compose up -d --build
./scripts/verificar.sh
```

`docker-compose.override.yml` se aplica automáticamente junto con
`docker-compose.yml` y habilita hot-reload del backend (montaje del código
como volumen) más el puerto 5432 de Postgres expuesto al host, para poder
conectarse con un cliente SQL. Para levantar sólo la definición productiva,
sin el override:

```bash
docker compose -f docker-compose.yml up -d --build
```

## Probarla

```bash
curl http://localhost/health
curl http://localhost/api/notes
curl -X POST http://localhost/api/notes -H "Content-Type: application/json" -d '{"title":"Primera nota","content":"Docker Compose funciona"}'
curl http://localhost/api/notes
```

Servicios: frontend en `${FRONTEND_PORT:-80}` (por defecto 80), backend interno en `5000`, PostgreSQL interno en `5432`.

```bash
docker compose down -v
```

## Notas

- `POST /api/notes` sin `title` devuelve un error de servidor si se usa el
  Flask de testing (`app.config['TESTING']=True`): el código de TP06 no
  valida el campo antes de usarlo. En uso normal (`docker compose up`, sin
  modo testing) el error se ve reflejado igual, pero como página de error
  genérica de Flask en vez de un JSON prolijo. No afecta el resto del
  ejercicio.
