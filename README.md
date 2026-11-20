# RefCard 05 – React + Vite Frontend auf AWS (ECR, ECS)

Frontend der BusinessTrips-Applikation (Trip-Liste + Wishlist). Teil der CI/CD-Übungssequenz
**RefCard 02–05** (siehe [`docs/future/RefCard-03-RefCard-05-own-repos.md`](docs/future/RefCard-03-RefCard-05-own-repos.md))
— dieses Repository ist der **Frontend-Teil von RefCard 05**: statischer Vite-Build, ausgeliefert
von nginx in einem Container auf ECS Fargate.

Das Backend liegt im eigenen Repo
[`refcard-08-springboot-backend`](https://github.com/Koetbullar-Droide/refcard-08-springboot-backend),
die lokale Gesamtumgebung (Frontend + Backend + MariaDB) im Ordner `refcard-05-compose`.

## Lokal entwickeln

```bash
npm install
npm run dev      # http://localhost:5173, Backend muss auf http://localhost:8080 laufen
npm test         # Vitest
```

Die Backend-URL kommt aus `VITE_API_BASE_URL` (`.env`, Default `http://localhost:8080/`).

## Docker-Image

Multi-Stage-Build: Node baut `dist/` → nur nginx + statische Dateien im finalen Image
([`nginx.conf`](nginx.conf) mit SPA-Fallback auf `index.html`).
`VITE_API_BASE_URL` wird als **Build-Arg** übergeben, weil Vite den Wert beim Build fest ins JS einkompiliert.

```bash
docker build --build-arg VITE_API_BASE_URL=http://localhost:8080/ -t biztrips-frontend .
docker run --rm -p 3000:80 biztrips-frontend   # → http://localhost:3000
```

## Deployment auf AWS (RefCard 05)

```
Browser ─► ALB refcard05-frontend-alb :80 ─► Target Group (ip, :80, /) ─► ECS-Service (Fargate, nginx)
   └── JS ruft auf ─► ALB refcard05-backend-alb ─► Backend-Service (siehe Backend-Repo) ─► RDS
```

| Ressource | Name |
| --- | --- |
| ECR-Repository | `react-vite-frontend` |
| ECS-Cluster / Service | `biztripsFrontend` / `biztrips-frontend-service` |
| Task Definition | `biztrips-frontend` ([`task-definition.json`](task-definition.json)) |
| Load Balancer | `refcard05-frontend-alb` → http://refcard05-frontend-alb-321770531.us-east-1.elb.amazonaws.com |

- **Pipeline** ([`.github/workflows/deploy.yml`](.github/workflows/deploy.yml)): `test` → `build` → `deploy-ecs`
  (Image mit Tags `<commit-sha>` und `latest` nach ECR, Task Definition rendern, ECS-Service rolling aktualisieren).
  `deploy-ecs` läuft nur bei Push auf `main`.
- **Repository-Variable** `VITE_API_BASE_URL` = URL des Backend-Load-Balancers (mit `/` am Ende).
- **Secrets** `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`: temporäre
  Learner-Lab-Credentials (kein OIDC im Learner Lab). Nach jedem Lab-Neustart mit
  `scripts/set-aws-secrets.sh` im **Backend-Repo** erneuern — das Skript setzt sie in beiden Repos.
- Die Infrastruktur für beide Services beschreibt `scripts/aws-setup.sh` im Backend-Repo.
