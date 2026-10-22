-- PeopleHub schema, version 1
-- Flyway runs this once, in order. Never edit it after it has run; add V2__..., V3__... instead.

CREATE EXTENSION IF NOT EXISTS pg_trgm;  -- fast ILIKE '%text%' search for the employee directory

-- ---------------------------------------------------------------- departments
CREATE TABLE department (
    id          BIGSERIAL PRIMARY KEY,
    code        VARCHAR(10)  NOT NULL UNIQUE,
    name        VARCHAR(100) NOT NULL UNIQUE,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------- employees
CREATE TABLE employee (
    id             BIGSERIAL PRIMARY KEY,
    employee_code  VARCHAR(20)  NOT NULL UNIQUE,
    first_name     VARCHAR(80)  NOT NULL,
    last_name      VARCHAR(80)  NOT NULL,
    email          VARCHAR(160) NOT NULL UNIQUE,
    phone          VARCHAR(30),
    password_hash  VARCHAR(100) NOT NULL,              -- used from Day 2 (login)
    role           VARCHAR(20)  NOT NULL DEFAULT 'EMPLOYEE',
    status         VARCHAR(20)  NOT NULL DEFAULT 'ACTIVE',
    job_title      VARCHAR(100) NOT NULL,
    location       VARCHAR(80)  NOT NULL,
    hire_date      DATE         NOT NULL,
    department_id  BIGINT       NOT NULL REFERENCES department (id),
    manager_id     BIGINT       REFERENCES employee (id),
    created_at     TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at     TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT chk_employee_role   CHECK (role   IN ('EMPLOYEE', 'MANAGER', 'HR_ADMIN')),
    CONSTRAINT chk_employee_status CHECK (status IN ('ACTIVE', 'INACTIVE', 'ON_LEAVE'))
);

-- Directory filters and joins
CREATE INDEX idx_employee_department ON employee (department_id);
CREATE INDEX idx_employee_manager    ON employee (manager_id);
CREATE INDEX idx_employee_status     ON employee (status);
CREATE INDEX idx_employee_location   ON employee (location);
-- Substring search on name and email (the "search box" on the directory page)
CREATE INDEX idx_employee_name_trgm  ON employee USING gin ((first_name || ' ' || last_name) gin_trgm_ops);
CREATE INDEX idx_employee_email_trgm ON employee USING gin (email gin_trgm_ops);

-- ---------------------------------------------------------------- leave
CREATE TABLE leave_balance (
    id           BIGSERIAL PRIMARY KEY,
    employee_id  BIGINT        NOT NULL REFERENCES employee (id),
    leave_type   VARCHAR(20)   NOT NULL,
    year         INT           NOT NULL,
    total_days   NUMERIC(5, 1) NOT NULL,
    used_days    NUMERIC(5, 1) NOT NULL DEFAULT 0,
    CONSTRAINT uq_leave_balance UNIQUE (employee_id, leave_type, year),
    CONSTRAINT chk_balance_type CHECK (leave_type IN ('ANNUAL', 'SICK', 'CASUAL', 'UNPAID')),
    CONSTRAINT chk_balance_used CHECK (used_days >= 0 AND used_days <= total_days)
);

CREATE TABLE leave_request (
    id           BIGSERIAL PRIMARY KEY,
    employee_id  BIGINT        NOT NULL REFERENCES employee (id),
    approver_id  BIGINT        REFERENCES employee (id),
    leave_type   VARCHAR(20)   NOT NULL,
    start_date   DATE          NOT NULL,
    end_date     DATE          NOT NULL,
    days         NUMERIC(5, 1) NOT NULL,
    reason       VARCHAR(500),
    status       VARCHAR(20)   NOT NULL DEFAULT 'PENDING',
    decision_note VARCHAR(500),
    decided_at   TIMESTAMPTZ,
    created_at   TIMESTAMPTZ   NOT NULL DEFAULT now(),
    CONSTRAINT chk_leave_type   CHECK (leave_type IN ('ANNUAL', 'SICK', 'CASUAL', 'UNPAID')),
    CONSTRAINT chk_leave_status CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED', 'CANCELLED')),
    CONSTRAINT chk_leave_dates  CHECK (end_date >= start_date)
);

CREATE INDEX idx_leave_employee ON leave_request (employee_id, start_date);
-- The manager's approval inbox: "pending requests for me"
CREATE INDEX idx_leave_approver_pending ON leave_request (approver_id) WHERE status = 'PENDING';

-- ---------------------------------------------------------------- attendance
CREATE TABLE attendance (
    id           BIGSERIAL PRIMARY KEY,
    employee_id  BIGINT      NOT NULL REFERENCES employee (id),
    work_date    DATE        NOT NULL,
    check_in     TIMESTAMPTZ NOT NULL,
    check_out    TIMESTAMPTZ,
    CONSTRAINT uq_attendance_day UNIQUE (employee_id, work_date),  -- one row per person per day
    CONSTRAINT chk_attendance_times CHECK (check_out IS NULL OR check_out >= check_in)
);

CREATE INDEX idx_attendance_date ON attendance (work_date);

-- ---------------------------------------------------------------- HR cases (helpdesk)
CREATE TABLE hr_case (
    id           BIGSERIAL PRIMARY KEY,
    case_number  VARCHAR(20)  NOT NULL UNIQUE,
    requester_id BIGINT       NOT NULL REFERENCES employee (id),
    assignee_id  BIGINT       REFERENCES employee (id),
    category     VARCHAR(30)  NOT NULL,
    priority     VARCHAR(10)  NOT NULL DEFAULT 'MEDIUM',
    status       VARCHAR(20)  NOT NULL DEFAULT 'OPEN',
    subject      VARCHAR(200) NOT NULL,
    description  TEXT,
    sla_due_at   TIMESTAMPTZ  NOT NULL,
    sla_breached BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at   TIMESTAMPTZ  NOT NULL DEFAULT now(),
    resolved_at  TIMESTAMPTZ,
    CONSTRAINT chk_case_category CHECK (category IN ('PAYROLL', 'BENEFITS', 'LEAVE', 'ONBOARDING', 'POLICY', 'OTHER')),
    CONSTRAINT chk_case_priority CHECK (priority IN ('LOW', 'MEDIUM', 'HIGH', 'URGENT')),
    CONSTRAINT chk_case_status   CHECK (status IN ('OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED'))
);

CREATE INDEX idx_case_requester ON hr_case (requester_id);
CREATE INDEX idx_case_assignee  ON hr_case (assignee_id) WHERE status IN ('OPEN', 'IN_PROGRESS');
-- The scheduled SLA-breach job scans only unresolved, not-yet-flagged cases
CREATE INDEX idx_case_sla_scan  ON hr_case (sla_due_at) WHERE status IN ('OPEN', 'IN_PROGRESS') AND sla_breached = FALSE;

-- ---------------------------------------------------------------- audit trail
CREATE TABLE audit_log (
    id           BIGSERIAL PRIMARY KEY,
    actor_id     BIGINT,
    entity_type  VARCHAR(40) NOT NULL,
    entity_id    BIGINT      NOT NULL,
    action       VARCHAR(40) NOT NULL,
    old_value    JSONB,
    new_value    JSONB,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_audit_entity  ON audit_log (entity_type, entity_id);
CREATE INDEX idx_audit_created ON audit_log (created_at DESC);
