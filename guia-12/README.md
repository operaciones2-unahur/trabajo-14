# TP12 — Portfolio final

No es una guía técnica: arma el repositorio de presentación
(`devops-portfolio`) con links a todos los TPs anteriores y un workflow
que valida periódicamente que esos repos sigan existiendo y que el README
tenga todas las secciones.

Todo el contenido real está en `portfolio/`:

- `portfolio/README.md` — el README principal, con la tabla de stack
  tecnológico y los links a cada TP.
- `portfolio/docs/profile-readme.md` — el README que va en el perfil de
  GitHub del usuario (`github.com/TU_USUARIO`), separado del portfolio.
- `portfolio/.github/workflows/portfolio-check.yml` — corre cada lunes a
  las 9am (y en cada push, y manualmente) y valida: que los repos
  `devops-TP01` a `devops-TP11` existan, y que el README tenga las
  secciones `Stack tecnológico`, `Proyectos por TP`, `1 al 4`, `5 al 8`,
  `9 al 12` y `Plataformas usadas`.

## Cómo usarlo

```bash
cd portfolio
git init
git add .
git commit -m "portfolio: README final con 12 TPs de Operaciones1"
git branch -M main
git remote add origin https://github.com/TU_USUARIO/devops-portfolio.git
git push -u origin main
```

Antes de subirlo, reemplazá todos los `TU_USUARIO` de `README.md` y
`docs/profile-readme.md` por tu usuario real de GitHub, si no los links
quedan rotos.

## Notas

- El workflow busca en el README las secciones `1 al 4`, `5 al 8` y
  `9 al 12` (los encabezados reales que usa `README.md`). Si les cambiás
  el texto a esos encabezados, actualizá también el array `SECCIONES` de
  `portfolio-check.yml`, o el job `lint-readme` va a fallar siempre.
- `check-repos` necesita que los 10 repos (`devops-TP01`...`devops-TP11`,
  sin TP07 porque comparte repo con TP06) ya existan en GitHub para pasar.
  Si todavía no subiste alguno, ese job va a fallar hasta que lo subas.
