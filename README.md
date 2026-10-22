# PeopleHub

A mini HR portal built to learn the Spring Boot + React stack in one week. It is a scaled-down slice of an enterprise HR system: roles, leave approvals, attendance, HR cases with SLAs, bulk CSV import, a dashboard, and an audit trail, tested against 100,000 seeded employees.

**Status: Day 1 of 7 (foundation).** Day-by-day plan is at the bottom.

## Stack

| Layer | Tech |
|---|---|
| Backend | Java 21, Spring Boot 3.5, Spring Web, Spring Data JPA, JdbcTemplate |
| Database | PostgreSQL 16, Flyway migrations, `pg_trgm` for fast text search |
| Cache | Redis 7 through Spring Cache |
| Frontend | React 19, TypeScript, Vite, MUI, TanStack Query, React Router, Axios |
| Infra | Docker Compose (Postgres + Redis) |

## What exists after Day 1

- `docker-compose.yml` with PostgreSQL and Redis
- Flyway migration `V1__init_schema.sql`: 8 tables (`department`, `employee`, `leave_balance`, `leave_request`, `attendance`, `hr_case`, `audit_log`) with constraints and indexes
- Demo data script: 12 departments, **100,000 employees**, 300k leave balances, 30k leave requests, 5k HR cases
- Backend endpoints: `GET /api/departments` (cached in Redis), `GET /api/summary`, `GET /actuator/health`
- React app with sidebar layout, routing, and a dashboard that calls the backend

## Prerequisites

- JDK 21 and Maven 3.9+ (or open `backend/` in IntelliJ, which bundles Maven)
- Node.js 20.19+ or 22+
- Docker Desktop

## Run it

**1. Start PostgreSQL and Redis** (from the project root)

```
docker compose up -d
```

**2. Start the backend with demo data** (first run only needs the `seed` profile; it loads 100k employees in a few seconds and skips itself if data already exists)

```
cd backend
mvn spring-boot:run -Dspring-boot.run.profiles=seed
```

Later runs can use plain `mvn spring-boot:run`.

**3. Start the frontend**

```
cd frontend
npm install
npm run dev
```

Open http://localhost:5173. You should see the dashboard with 100,000 employees and a headcount bar per department.

### Quick checks

- http://localhost:8080/actuator/health returns `{"status":"UP"}`
- http://localhost:8080/api/summary returns the dashboard numbers
- http://localhost:8080/api/departments returns 12 departments. Call it twice and check Redis: `docker exec -it peoplehub-redis redis-cli keys "*"` shows a `peoplehub::departments` key.
- Database shell: `docker exec -it peoplehub-postgres psql -U peoplehub -d peoplehub`

## Demo accounts (used from Day 2)

Password for every employee: `Password@123`

| Email | Role |
|---|---|
| hr.admin@peoplehub.dev | HR_ADMIN |
| manager@peoplehub.dev | MANAGER |
| employee@peoplehub.dev | EMPLOYEE |

## Project layout

```
peoplehub/
  docker-compose.yml
  backend/
    pom.xml
    src/main/resources/
      application.yml            config (DB, Redis, cache TTL)
      application-seed.yml       turns the seeder on
      db/migration/              Flyway migrations (V1__init_schema.sql)
      db/seed/demo-data.sql      100k-employee demo data
    src/main/java/com/peoplehub/
      department/                entity, repository, service (cached), controller
      dashboard/                 summary endpoint (SQL aggregates)
      seed/DemoDataSeeder.java   runs the seed script once, in one transaction
      config/CacheConfig.java
  frontend/
    vite.config.ts               dev proxy: /api -> localhost:8080
    src/
      api/                       axios client + typed API calls
      components/Layout.tsx      app bar + sidebar
      pages/                     DashboardPage, ComingSoonPage
```

## Concepts to understand on Day 1

Spend your learning time here; each one is a common interview question.

1. **Flyway:** migrations are versioned and immutable. Change the schema by adding `V2__...sql`, never by editing `V1`.
2. **`ddl-auto: validate`:** Flyway owns the schema, Hibernate only verifies that entities match it.
3. **`open-in-view: false`:** no lazy loading in controllers, so you return DTOs from services.
4. **Indexes you can explain:** a partial index (`idx_leave_approver_pending`) for the manager inbox, and a trigram GIN index for `ILIKE '%text%'` search. Run `EXPLAIN ANALYZE` on a search query and see which one is used.
5. **`@Cacheable`:** see `DepartmentService`. Why are cached DTOs `Serializable`? What would happen without a TTL?
6. **Vite proxy:** why the browser needs no CORS setup in development.
7. **TanStack Query:** `useQuery` gives loading, error and retry states without writing `useEffect` by hand.

## Day 2 note: employee search

The name search index is built on the expression `(first_name || ' ' || last_name)`. Day 2's search query must use exactly that expression with `ILIKE`, otherwise PostgreSQL cannot use the index. Verify with `EXPLAIN`.

## 7-day plan

1. **Foundation** (this commit)
2. Auth (JWT, roles) and employee directory with search, filters, pagination
3. Leave workflow: apply, approve/reject, balances, bulk approve, audit entries
4. Attendance and HR cases with SLA flagging job
5. Bulk CSV import (preview, async commit, progress) and Redis caching on the dashboard
6. Dashboard charts, integration tests (Testcontainers), polish
7. Dockerfiles, GitHub Actions CI, deployment, README screenshots and demo video
