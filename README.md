# TP14 — Threagile (Modelado de Amenazas)

Vas a integrar Threagile en el pipeline de CI/CD de la Notes App. Threagile
es una herramienta de modelado de amenazas ágil: en vez de dibujar
diagramas que se pierden, describís la arquitectura (servidores, base de
datos, conexiones) en un archivo YAML, y la herramienta genera un reporte
de riesgos y un diagrama de flujo de datos. Integrado al pipeline, cada
push que cambie la infraestructura dispara ese análisis automáticamente.

## Antes de arrancar

- Docker instalado y corriendo.
- `guia-06/` y `guia-08/` a `guia-12/`: las guías anteriores, cada una en
  su propia carpeta, tal como las armaste en TP06 a TP12.
- `devops-TP06/`: tu proyecto de TP06 con el pipeline de CI/CD que le
  agregaste en TP07 (por eso se llama así, en vez de "guia-07": TP07 se
  trabaja sobre la misma carpeta de TP06, no arma una carpeta nueva).
- El pipeline de CI/CD (`.github/workflows/cicd.yml`, con los jobs
  `lint`, `test` y `build-push` — `deploy` está comentado porque no hay
  un servidor real donde desplegar) es el que vas a modificar en este
  TP, y está en la **raíz de esta carpeta**
  (`guia-14-para-alumnos/.github/`), no adentro de `devops-TP06/`:
  GitHub Actions sólo reconoce `.github/workflows/` si está en la raíz
  del repositorio.

Primero entrá a `devops-TP06/` — ahí vas a hacer los Pasos 1 a 4:

```bash
cd guia-14-para-alumnos/devops-TP06
ls
```

Deberías ver `backend/`, `frontend/`, `docker-compose.yml` y `README.md`.
Todavía no hay ningún `threagile.yaml` — es justamente lo que vas a
crear.

> **Nota sobre la arquitectura completa.** `devops-TP06/` sólo levanta 3
> contenedores (`db`, `backend`, `frontend`). Los otros 4 que vas a
> describir en `threagile.yaml` — Prometheus, Grafana, Node Exporter y
> cAdvisor — no corren acá: están en `guia-08/` (mismo backend, con
> métricas agregadas). Si en algún momento no te acordás algún puerto o
> nombre de servicio mientras escribís el modelo (Paso 3), es un buen
> lugar para consultar, junto con el `k8s/` de `guia-09/` y el
> `terraform/` de `guia-11/`. No hace falta levantar nada de eso para
> hacer el TP14 — Threagile describe la arquitectura en un YAML, no
> necesita los contenedores corriendo. Es sólo una referencia, no un paso
> a seguir.

## Paso 1 — Generar el modelo inicial (stub)

Threagile trae un generador de plantillas para no escribir el modelo desde
cero:

```bash
docker run --rm -it -v "$(pwd)":/app/work threagile/threagile --create-stub-model --output /app/work
```

Este comando baja la imagen oficial de Threagile y la corre una vez; el
resultado es un archivo `threagile-stub-model.yaml` en la carpeta actual,
con la estructura básica y ejemplos de cada sección.

```bash
ls -la threagile-stub-model.yaml
```

## Paso 2 — Renombrarlo

```bash
mv threagile-stub-model.yaml threagile.yaml
```

`threagile.yaml` es el nombre que va a buscar tanto Threagile como el
pipeline de CI/CD, así que tiene que quedar exactamente así, en la raíz del
proyecto (junto a `docker-compose.yml`).

## Paso 3 — Adaptar el modelo a la arquitectura de la Notes App

Abrí el archivo con nano:

```bash
nano threagile.yaml
```

Borrá todo el contenido de la plantilla y pegá esto. Describe los 7
contenedores, el cliente web, el volumen de Postgres y el registro de
Docker Hub:

```yaml
threagile_version: 1.0.0

title: Notes App - Amenazas (TP14)
date: 2026-08-30
author:
  name: Equipo DevOps - Notes App
  homepage: https://github.com/TU_USUARIO/devops-TP06

business_criticality: important

data_assets:
  credenciales-usuario:
    id: credenciales-usuario
    description: Credenciales usadas para autenticar operaciones administrativas sobre la API de notas.
    usage: business
    quantity: few
    confidentiality: confidential
    integrity: critical
    availability: operational
    justification_cia_rating: Comprometer credenciales permite manipular o borrar notas de otros usuarios.

  contenido-notas:
    id: contenido-notas
    description: Título y contenido de las notas creadas por los usuarios de la aplicación.
    usage: business
    quantity: many
    confidentiality: internal
    integrity: important
    availability: operational
    justification_cia_rating: Es el dato de negocio principal de la aplicación; su pérdida afecta a los usuarios.

  credenciales-bd:
    id: credenciales-bd
    description: Usuario y contraseña de PostgreSQL utilizados por el backend para conectarse a la base de datos.
    usage: business
    quantity: few
    confidentiality: strictly-confidential
    integrity: critical
    availability: operational
    justification_cia_rating: Su exposición permite acceso directo no autorizado a toda la base de datos.

  metricas-monitoreo:
    id: metricas-monitoreo
    description: Series de tiempo de métricas de aplicación, host y contenedores recolectadas por Prometheus.
    usage: devops
    quantity: many
    confidentiality: internal
    integrity: operational
    availability: operational
    justification_cia_rating: Son datos operativos de bajo impacto directo sobre el negocio, pero relevantes para observabilidad.

technical_assets:

  cliente-web:
    id: cliente-web
    title: Navegador Web (Usuario Externo)
    description: El cliente HTTP (navegador) en el dispositivo del usuario que inicia el acceso a la Notes App a través de internet de forma pública.
    type: external-entity
    usage: business
    used_as_client_by_human: true
    size: component
    technology: browser
    internet: true
    machine: physical
    encryption: none
    owner: Usuario externo
    confidentiality: internal
    integrity: operational
    availability: operational
    justification_cia_rating: Es un dispositivo fuera del control del equipo DevOps.
    multi_tenant: false
    redundant: false
    custom_developed_parts: false
    data_assets_processed:
      - contenido-notas
    communication_links:
      peticiones_usuario:
        target: nginx
        title: Envío de Peticiones de Usuario
        description: Tráfico HTTP entrante originado por el usuario para navegar por la interfaz y operar con la API en el puerto 80.
        protocol: http
        authentication: none
        authorization: none
        usage: business
        data_assets_sent:
          - contenido-notas

  nginx:
    id: nginx
    title: Proxy Reverso Nginx
    description: Contenedor Nginx que sirve el frontend estático y redirige las llamadas API (/api) al backend.
    type: process
    usage: business
    size: component
    technology: reverse-proxy
    internet: true
    machine: container
    encryption: none
    owner: Equipo DevOps
    confidentiality: internal
    integrity: important
    availability: important
    justification_cia_rating: Es la única puerta de entrada pública hacia la Notes App.
    multi_tenant: false
    redundant: false
    custom_developed_parts: false
    data_assets_processed:
      - contenido-notas
    communication_links:
      redireccion_al_backend:
        target: backend
        title: Redirección de llamadas API
        description: Redirecciona de forma interna peticiones de backend mediante HTTP al puerto 5000.
        protocol: http
        authentication: none
        authorization: none
        usage: business
        data_assets_sent:
          - contenido-notas

  backend:
    id: backend
    title: Backend Flask/Gunicorn (WSGI)
    description: Servidor de aplicación que gestiona la lógica de las notas y expone métricas internas para Prometheus.
    type: process
    usage: business
    size: component
    technology: web-service-rest
    internet: false
    machine: container
    encryption: none
    owner: Equipo DevOps
    confidentiality: confidential
    integrity: critical
    availability: important
    justification_cia_rating: Procesa las credenciales de base de datos y toda la lógica de negocio de las notas.
    multi_tenant: false
    redundant: false
    custom_developed_parts: true
    data_assets_processed:
      - contenido-notas
      - credenciales-bd
    data_formats_accepted:
      - json
    communication_links:
      conexion_base_datos:
        target: postgres
        title: Conexión de Base de Datos (psycopg2)
        description: Conexión de red activa iniciada por la app de Flask para realizar consultas de inserción y lectura en PostgreSQL.
        protocol: jdbc
        authentication: credentials
        authorization: technical-user
        usage: business
        data_assets_sent:
          - contenido-notas
          - credenciales-bd

  postgres:
    id: postgres
    title: Base de Datos PostgreSQL
    description: Base de datos relacional PostgreSQL encargada de resguardar los datos de las notas de forma persistente.
    type: datastore
    usage: business
    size: component
    technology: database
    internet: false
    machine: container
    encryption: none
    owner: Equipo DevOps
    confidentiality: confidential
    integrity: critical
    availability: important
    justification_cia_rating: Almacena de forma persistente todas las notas y depende de ella toda la aplicación.
    multi_tenant: false
    redundant: false
    custom_developed_parts: false
    data_assets_processed:
      - contenido-notas
      - credenciales-bd
    data_assets_stored:
      - contenido-notas
      - credenciales-bd

  prometheus:
    id: prometheus
    title: Servidor Metricas Prometheus
    description: Sistema de monitoreo que recopila (scrapes) las métricas de rendimiento del ecosistema de la Notes App.
    type: process
    usage: devops
    size: component
    technology: monitoring
    internet: false
    machine: container
    encryption: none
    owner: Equipo DevOps
    confidentiality: internal
    integrity: operational
    availability: operational
    justification_cia_rating: Consolida métricas operativas; no almacena datos de negocio de los usuarios.
    multi_tenant: false
    redundant: false
    custom_developed_parts: false
    data_assets_processed:
      - metricas-monitoreo
    communication_links:
      scrape_backend:
        target: backend
        title: Recolección de métricas de App
        description: Peticiones de scraping HTTP GET periódicas hacia el endpoint /metrics del Backend de Flask.
        protocol: http
        authentication: none
        authorization: none
        usage: devops
        readonly: true
        data_assets_sent:
          - metricas-monitoreo
      scrape_node_exporter:
        target: node-exporter
        title: Recolección de métricas de Host
        description: Peticiones HTTP periódicas hacia el contenedor Node Exporter en el puerto 9100.
        protocol: http
        authentication: none
        authorization: none
        usage: devops
        readonly: true
        data_assets_sent:
          - metricas-monitoreo
      scrape_cadvisor:
        target: cadvisor
        title: Recolección de métricas de Contenedores
        description: Peticiones HTTP periódicas al agente cAdvisor en el puerto 8080 para monitorear Docker.
        protocol: http
        authentication: none
        authorization: none
        usage: devops
        readonly: true
        data_assets_sent:
          - metricas-monitoreo

  grafana:
    id: grafana
    title: Visualizador Grafana
    description: Plataforma web interactiva para visualizar dashboards basados en las métricas consolidadas.
    type: process
    usage: devops
    size: component
    technology: monitoring
    internet: false
    machine: container
    encryption: none
    owner: Equipo DevOps
    confidentiality: internal
    integrity: operational
    availability: operational
    justification_cia_rating: Solo visualiza métricas ya consolidadas por Prometheus.
    multi_tenant: false
    redundant: false
    custom_developed_parts: false
    data_assets_processed:
      - metricas-monitoreo
    communication_links:
      consulta_datos_prometheus:
        target: prometheus
        title: Consulta de Métricas de Monitoreo
        description: Peticiones HTTP periódicas dirigidas al puerto 9090 para obtener la información de los gráficos en tiempo real.
        protocol: http
        authentication: none
        authorization: none
        usage: devops
        readonly: true
        data_assets_sent:
          - metricas-monitoreo

  node-exporter:
    id: node-exporter
    title: Agente NodeExporter
    description: Contenedor encargado de exponer de forma pasiva las métricas del hardware de la máquina física o virtual host.
    type: process
    usage: devops
    size: component
    technology: monitoring
    internet: false
    machine: container
    encryption: none
    owner: Equipo DevOps
    confidentiality: internal
    integrity: operational
    availability: operational
    justification_cia_rating: Expone métricas de solo lectura del host, sin datos de negocio.
    multi_tenant: false
    redundant: false
    custom_developed_parts: false
    data_assets_processed:
      - metricas-monitoreo

  cadvisor:
    id: cadvisor
    title: Agente cAdvisor
    description: Contenedor encargado de exponer de forma pasiva las métricas de rendimiento internas de los contenedores Docker.
    type: process
    usage: devops
    size: component
    technology: monitoring
    internet: false
    machine: container
    encryption: none
    owner: Equipo DevOps
    confidentiality: internal
    integrity: operational
    availability: operational
    justification_cia_rating: Expone métricas de solo lectura de contenedores, sin datos de negocio.
    multi_tenant: false
    redundant: false
    custom_developed_parts: false
    data_assets_processed:
      - metricas-monitoreo

  volumen-postgres:
    id: volumen-postgres
    title: Volumen de Datos Postgres
    description: Volumen persistente de Docker/PVC donde PostgreSQL guarda físicamente los archivos de la base de datos.
    type: datastore
    usage: business
    size: component
    technology: local-file-system
    internet: false
    machine: container
    encryption: none
    owner: Equipo DevOps
    confidentiality: confidential
    integrity: critical
    availability: important
    justification_cia_rating: Es el almacenamiento físico final de todos los datos de la base; su pérdida es irreversible.
    multi_tenant: false
    redundant: false
    custom_developed_parts: false
    data_assets_stored:
      - contenido-notas
      - credenciales-bd

  docker-registry:
    id: docker-registry
    title: Registro Docker Hub
    description: Registro de contenedores públicos (Docker Hub) donde el pipeline de CI/CD publica las imágenes de backend y frontend.
    type: process
    usage: devops
    size: component
    technology: artifact-registry
    internet: true
    machine: serverless
    encryption: none
    owner: Docker Hub (terceros)
    confidentiality: internal
    integrity: important
    availability: operational
    justification_cia_rating: Un push accidental o no controlado a un registro público expondría las imágenes de la aplicación.
    multi_tenant: true
    redundant: false
    custom_developed_parts: false

trust_boundaries:
  red-docker-compose:
    id: red-docker-compose
    description: Red interna 'app-network' de Docker Compose / Kubernetes que aísla a los 7 contenedores de la Notes App y su volumen de datos del resto de internet.
    type: network-cloud-provider
    technical_assets_inside:
      - nginx
      - backend
      - postgres
      - prometheus
      - grafana
      - node-exporter
      - cadvisor
      - volumen-postgres

risk_tracking: {}
```

Guardá con `Ctrl+O`, `Enter`, salí con `Ctrl+X`.

Un par de convenciones a tener en cuenta para que el archivo compile con
Threagile (motor 1.0.0): la conexión entre dos activos se declara con
`communication_links`, la exposición a internet es el campo `internet`, y
los valores de `technology` para el cliente, el backend y la base de
datos son `browser`, `web-service-rest` y `database`. Los `id` sólo
aceptan letras, números y guion medio, sin guion bajo — por eso
`cliente-web` y no `cliente_web`. El bloque de arriba ya está escrito
así.

### Qué representa cada activo

| id | title | type | usage | technology | internet |
|---|---|---|---|---|---|
| `cliente-web` | Navegador Web (Usuario Externo) | external-entity | business | browser | true |
| `nginx` | Proxy Reverso Nginx | process | business | reverse-proxy | true |
| `backend` | Backend Flask/Gunicorn (WSGI) | process | business | web-service-rest | false |
| `postgres` | Base de Datos PostgreSQL | datastore | business | database | false |
| `prometheus` | Servidor Métricas Prometheus | process | devops | monitoring | false |
| `grafana` | Visualizador Grafana | process | devops | monitoring | false |
| `node-exporter` | Agente NodeExporter | process | devops | monitoring | false |
| `cadvisor` | Agente cAdvisor | process | devops | monitoring | false |
| `volumen-postgres` | Volumen de Datos Postgres | datastore | business | local-file-system | false |
| `docker-registry` | Registro Docker Hub | process | devops | artifact-registry | true |

- **type**: `process` para lo que ejecuta lógica (Flask, Nginx,
  Prometheus...), `datastore` para Postgres y el volumen, `external-entity`
  para el cliente web.
- **usage**: `business` para lo que forma parte de la experiencia del
  usuario (cliente, nginx, backend, postgres, volumen), `devops` para las
  herramientas de soporte (prometheus, grafana, node-exporter, cadvisor,
  registro).
- **technology**: indica qué reglas de seguridad aplica Threagile según la
  pila tecnológica.
- **internet**: `true` sólo para lo que está expuesto públicamente — el
  cliente, nginx (única puerta de entrada) y el registro de Docker Hub por
  ser un servicio público de terceros. El resto queda en `false`.
- Un `communication_link` es la conexión entre dos activos: quién le habla
  a quién, con qué `protocol`, y qué mecanismos de `authentication` y
  `authorization` usa.

Las cinco secciones del archivo son: `data_assets` (qué información
protegemos), `technical_assets` (dónde corre cada pieza y cómo se
comunican), `trust_boundaries` (cómo se agrupan dentro de la red interna),
y `risk_tracking`, que se completa en el paso siguiente.

## Paso 4 — Correr Threagile localmente

```bash
docker run --rm -it -v "$(pwd)":/app/work threagile/threagile --verbose --model /app/work/threagile.yaml --output /app/work
```

Si el archivo está bien, genera varios archivos de reporte en la carpeta
actual: `report.pdf`, `risks.xlsx`, `tags.xlsx`, `data-flow-diagram.png`,
`data-asset-diagram.png`, `risks.json`, `stats.json` y
`technical-assets.json`.

```bash
ls -la report.pdf data-flow-diagram.png risks.json
```

En esta primera corrida vas a ver un aviso de `Risk tracking references
unknown risk...` para cada categoría — es esperable, porque `risk_tracking`
todavía está vacío (`{}`). Sirve para confirmar que el modelo compila; el
`risk_tracking` real se completa a continuación.

### Completar `risk_tracking`

Abrí `risks.json` (o `risks.xlsx`) y buscá las filas de categoría
`unencrypted-communication` y `unchecked-deployment`. Vas a encontrar estos
dos identificadores:

- `unencrypted-communication@backend>conexion-base-datos@backend@postgres`
- `unchecked-deployment@docker-registry`

Vamos a trackear estas dos decisiones de seguridad, usando los
identificadores reales que acabás de encontrar: la conexión de base de
datos sin cifrar se registra sobre `unencrypted-communication` de arriba
(es la conexión backend→postgres), y el push a un registro público sobre
`unchecked-deployment@docker-registry`.

Volvé a abrir el archivo (`nano threagile.yaml`) y reemplazá la línea
`risk_tracking: {}` por:

```yaml
risk_tracking:
  # Riesgo aceptado: conexión de base de datos sin cifrar.
  unencrypted-communication@backend>conexion-base-datos@backend@postgres:
    status: accepted
    justification: >-
      Riesgo aceptado. La conexión backend-postgres (psycopg2) viaja sin TLS,
      pero permanece siempre dentro de la red interna privada y aislada de
      Docker Compose / Kubernetes, sin salida a internet.
    ticket: TP14-02
    date: 2026-08-30
    checked_by: Equipo DevOps

  # Riesgo mitigado: push a un registro público.
  unchecked-deployment@docker-registry:
    status: mitigated
    justification: >-
      Mitigado protegiendo el acceso al registro mediante secretos cifrados
      (DOCKERHUB_USERNAME / DOCKERHUB_TOKEN) en GitHub Actions y restringiendo
      el push a la rama main del repositorio controlado.
    ticket: TP14-03
    date: 2026-08-30
    checked_by: Equipo DevOps
```

Hay una tercera decisión de seguridad: el cifrado del tráfico en general
queda mitigado por el Ingress con TLS de TP10. Esa decisión no genera una
entrada propia de `risk_tracking` en este modelo: el único tramo real de
la categoría `unencrypted-communication` es backend→postgres, ya
trackeado arriba. El tramo cliente→nginx no entra en esa categoría porque
el cliente es `external-entity`, y el tramo nginx→backend cae bajo otra
categoría (`missing-authentication`). La mitigación por TLS del Ingress
sigue siendo válida a nivel de arquitectura; simplemente no le corresponde
una fila propia en `risk_tracking`, para no inventar un ID que Threagile
reportaría como huérfano.

Guardá y volvé a correr el comando del paso 4. Esta vez no debería aparecer
ningún aviso de `Risk tracking references unknown risk`.

### Validar la sintaxis rápido

```bash
python3 -c "import yaml; yaml.safe_load(open('threagile.yaml'))"
```

Si no imprime nada, el YAML es válido.

## Paso 5 — Agregar el job al pipeline

El pipeline no está adentro de `devops-TP06/`: está un nivel arriba, en la
raíz de tu repositorio (junto con las carpetas de las otras guías), porque
GitHub Actions sólo reconoce `.github/workflows/` si está en la raíz del
repo. Subí un nivel:

```bash
cd ..
nano .github/workflows/cicd.yml
```

A partir de acá los comandos se ejecutan en esta carpeta (la raíz del
repo), no en `devops-TP06/`.

No borres nada de lo que ya está — los jobs `lint`, `test` y `build-push`
se mantienen igual (`deploy` está comentado porque no hay un servidor
real donde desplegar; si en algún momento tenés uno, lo descomentás y
cargás los secrets que pide). Andá hasta el final del archivo, al mismo
nivel de indentación que esos jobs, y pegá:

```yaml
  threat-modeling:
    name: Threat Model Analysis
    runs-on: ubuntu-latest
    steps:
      # Paso 1: Descargar el código de nuestro repositorio en el runner
      - name: Checkout Workspace
        uses: actions/checkout@v4

      # Paso 2: Ejecutar el análisis automático de Threagile
      - name: Run Threagile
        id: threagile
        uses: threagile/run-threagile-action@v1
        with:
          model-file: 'threagile.yaml'

      # Paso 3: Guardar el PDF y el Diagrama generados como artefactos de GitHub Actions
      - name: Archive Results
        uses: actions/upload-artifact@v4
        with:
          name: threagile-report
          path: threagile/output
```

Guardá con `Ctrl+O`, `Enter`, `Ctrl+X`.

`threat-modeling` es el nombre del job. `actions/checkout@v4` baja el
código al runner. `threagile/run-threagile-action@v1` es la acción oficial
que corre el análisis sobre el `threagile.yaml` de la raíz del repo.
`actions/upload-artifact@v4` toma lo que Threagile deja en
`threagile/output` (el PDF y el diagrama) y lo deja descargable desde la
pestaña Actions.

Verificá que el YAML siga siendo válido y que quedaron los 5 jobs:

```bash
python3 -c "import yaml; d=list(yaml.safe_load_all(open('.github/workflows/cicd.yml'))); print(list(d[0]['jobs'].keys()))"
```

Tiene que imprimir `['lint', 'test', 'build-push', 'threat-modeling']`
(sin `deploy`, que quedó comentado).

## Paso 6 — Subir los cambios

Seguís en la raíz del repo (donde quedaste al final del Paso 5):

```bash
git status
git add devops-TP06/threagile.yaml
git add .github/workflows/cicd.yml
git status
git commit -m "TP14: Integración del análisis automático de amenazas con Threagile"
git push origin main
```

Si esta carpeta todavía no es un repositorio de git (no hiciste `git
init` antes), hacelo antes del `git add`, y agregá el remoto con `git
remote add origin https://github.com/TU_USUARIO/NOMBRE-DE-TU-REPO.git`
antes del `git push` (reemplazando por el nombre real del repo que
creaste en GitHub para esta entrega — puede ser `devops-TP06` si subís
esa carpeta sola, o el nombre que le hayas puesto si subís todo junto
desde acá).

## Paso 7 — Verificar en GitHub

1. Entrá al repositorio en github.com.
2. Pestaña **Actions**.
3. Abrí la última corrida ("TP14: Integración del análisis...").
4. El job **Threat Model Analysis** tiene que quedar en verde.
5. Al pie de la corrida, en **Artifacts**, descargá **threagile-report**:
   contiene el PDF con el reporte de riesgos y el diagrama de flujo de
   datos generado a partir de tu `threagile.yaml`. Adjuntalo a la entrega
   del TP14.

## Errores comunes

**Error de sintaxis o indentación en el YAML.** El job falla en "Run
Threagile" diciendo que no puede leer el archivo. YAML es estricto con los
espacios: usá siempre 2 espacios por nivel, nunca tabs. Para encontrar la
línea exacta del error:

```bash
python3 -c "import yaml; yaml.safe_load(open('threagile.yaml'))"
```

**Archivo del modelo no encontrado.** El pipeline dice que no encuentra
`threagile.yaml`. Revisá que quedó con ese nombre exacto (no
`threagile-stub-model.yaml`) y en la raíz del repo, junto a
`docker-compose.yml`:

```bash
ls -la threagile.yaml
```

**`unknown 'technology' value` o `invalid id syntax`.** Se usó un valor de
`technology` que no existe en el catálogo real, o un `id` con guion bajo.
Usá los valores del bloque de arriba, o consultá el catálogo completo con
`docker run --rm -it threagile/threagile --list-types`.

**`Risk tracking references unknown risk`.** Una entrada de
`risk_tracking` no coincide con ningún riesgo real generado por el modelo.
Corré primero con `risk_tracking: {}`, mirá `risks.json` para copiar el ID
exacto (con el `@` y los activos involucrados), y recién ahí completá
`risk_tracking`.
