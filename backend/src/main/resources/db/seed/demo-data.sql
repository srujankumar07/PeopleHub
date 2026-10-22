-- PeopleHub demo data
--   12 departments, 100,000 employees, leave balances, 30,000 leave requests, 5,000 HR cases.
-- Run once on an empty database. DemoDataSeeder checks that for you and runs it in one transaction.
-- Demo login for every employee: Password@123  (demo only)
--   hr.admin@peoplehub.dev   -> HR_ADMIN   (employee id 1)
--   manager@peoplehub.dev    -> MANAGER    (employee id 21)
--   employee@peoplehub.dev   -> EMPLOYEE   (employee id 5021)

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ------------------------------------------------------------ departments
INSERT INTO department (id, code, name) VALUES
    (1,  'ENG', 'Engineering'),
    (2,  'PRD', 'Product'),
    (3,  'DES', 'Design'),
    (4,  'HR',  'Human Resources'),
    (5,  'FIN', 'Finance'),
    (6,  'SAL', 'Sales'),
    (7,  'MKT', 'Marketing'),
    (8,  'OPS', 'Operations'),
    (9,  'SUP', 'Customer Support'),
    (10, 'LEG', 'Legal'),
    (11, 'IT',  'IT Services'),
    (12, 'PMO', 'Program Management');

SELECT setval(pg_get_serial_sequence('department', 'id'), 12);

-- ------------------------------------------------------------ employees
-- ids 1-20: HR admins, 21-5020: managers, 5021-100000: employees.
-- The bcrypt hash is computed once (MATERIALIZED) because hashing 100k times would take hours.
WITH pw AS MATERIALIZED (
    SELECT crypt('Password@123', gen_salt('bf', 10)) AS hash
),
base AS (
    SELECT
        n,
        CASE n
            WHEN 1    THEN 'Priya'
            WHEN 21   THEN 'Rohan'
            WHEN 5021 THEN 'Ananya'
            ELSE (ARRAY['Aarav','Vivaan','Aditya','Arjun','Sai','Reyansh','Krishna','Ishaan','Rohan','Karthik',
                        'Ananya','Diya','Priya','Kavya','Meera','Saanvi','Isha','Neha','Pooja','Sneha',
                        'Liam','Noah','Emma','Olivia','Lucas','Sofia','Mei','Wei','Yuki','Omar'])[1 + (n * 7) % 30]
        END AS first_name,
        CASE n
            WHEN 1    THEN 'Sharma'
            WHEN 21   THEN 'Mehta'
            WHEN 5021 THEN 'Iyer'
            ELSE (ARRAY['Sharma','Verma','Iyer','Reddy','Nair','Patel','Gupta','Singh','Mehta','Kapoor',
                        'Rao','Joshi','Khan','Das','Chatterjee','Menon','Pillai','Bose','Agarwal','Malhotra',
                        'Smith','Johnson','Brown','Garcia','Miller','Chen','Tanaka','Kim','Silva','Haddad'])[1 + (n * 11) % 30]
        END AS last_name
    FROM generate_series(1, 100000) AS n
)
INSERT INTO employee (id, employee_code, first_name, last_name, email, phone, password_hash, role, status,
                      job_title, location, hire_date, department_id, manager_id)
SELECT
    b.n,
    'EMP' || lpad(b.n::text, 6, '0'),
    b.first_name,
    b.last_name,
    CASE b.n
        WHEN 1    THEN 'hr.admin@peoplehub.dev'
        WHEN 21   THEN 'manager@peoplehub.dev'
        WHEN 5021 THEN 'employee@peoplehub.dev'
        ELSE lower(b.first_name || '.' || b.last_name || '.' || b.n) || '@peoplehub.dev'
    END,
    '+91' || (9000000000 + (b.n::bigint * 7919) % 999999999)::text,
    pw.hash,
    CASE WHEN b.n <= 20 THEN 'HR_ADMIN' WHEN b.n <= 5020 THEN 'MANAGER' ELSE 'EMPLOYEE' END,
    CASE WHEN b.n % 100 < 95 THEN 'ACTIVE' WHEN b.n % 100 < 98 THEN 'ON_LEAVE' ELSE 'INACTIVE' END,
    CASE
        WHEN b.n <= 20   THEN 'HR Business Partner'
        WHEN b.n <= 5020 THEN (ARRAY['Team Manager','Engineering Manager','Program Manager','Operations Manager','Delivery Manager'])[1 + b.n % 5]
        ELSE (ARRAY['Associate','Analyst','Software Engineer','Senior Software Engineer','Business Analyst',
                    'Specialist','Coordinator','Consultant','Executive','Team Lead'])[1 + (b.n * 13) % 10]
    END,
    (ARRAY['Hyderabad','Bengaluru','Pune','Chennai','Mumbai','Delhi','London','Singapore'])[1 + (b.n * 5) % 8],
    DATE '2017-01-01' + ((b.n * 37) % 3200),
    CASE WHEN b.n <= 20 THEN 4 ELSE 1 + (b.n * 31) % 12 END,
    CASE
        WHEN b.n <= 20   THEN NULL
        WHEN b.n <= 5020 THEN 1 + b.n % 20
        ELSE 21 + b.n % 5000
    END
FROM base b
CROSS JOIN pw;

SELECT setval(pg_get_serial_sequence('employee', 'id'), 100000);

-- ------------------------------------------------------------ leave balances (current year)
INSERT INTO leave_balance (employee_id, leave_type, year, total_days, used_days)
SELECT e.id, t.leave_type, EXTRACT(YEAR FROM CURRENT_DATE)::int, t.total_days, 0
FROM employee e
CROSS JOIN (VALUES ('ANNUAL', 18.0), ('SICK', 10.0), ('CASUAL', 7.0)) AS t(leave_type, total_days);

-- ------------------------------------------------------------ leave requests
-- Spread from 180 days ago to 59 days ahead. Recent and future ones are mostly PENDING,
-- so managers have something to approve on Day 3.
WITH base AS (
    SELECT
        k,
        e.id AS employee_id,
        e.manager_id,
        ((k * 17) % 240 - 180) AS off,
        (1 + k % 5) AS days,
        (ARRAY['ANNUAL','SICK','CASUAL','ANNUAL','ANNUAL'])[1 + k % 5] AS leave_type,
        (ARRAY['Family function','Medical appointment','Vacation','Personal work','Festival travel'])[1 + k % 5] AS reason
    FROM generate_series(1, 30000) AS k
    JOIN employee e ON e.id = 5021 + (k * 13) % 94980
),
shaped AS (
    SELECT
        b.*,
        CASE
            WHEN b.off < -14 THEN CASE WHEN b.k % 10 = 0 THEN 'REJECTED' ELSE 'APPROVED' END
            ELSE CASE WHEN b.k % 10 < 7 THEN 'PENDING' WHEN b.k % 10 < 9 THEN 'APPROVED' ELSE 'REJECTED' END
        END AS status,
        LEAST(now() - interval '1 hour', (CURRENT_DATE + b.off - 10)::timestamptz) AS created_at
    FROM base b
)
INSERT INTO leave_request (employee_id, approver_id, leave_type, start_date, end_date, days, reason,
                           status, decision_note, decided_at, created_at)
SELECT
    s.employee_id,
    s.manager_id,
    s.leave_type,
    CURRENT_DATE + s.off,
    CURRENT_DATE + s.off + (s.days - 1),
    s.days,
    s.reason,
    s.status,
    CASE WHEN s.status = 'REJECTED' THEN 'Team capacity is limited in this period' END,
    CASE WHEN s.status <> 'PENDING' THEN LEAST(now() - interval '30 minutes', s.created_at + interval '2 days') END,
    s.created_at
FROM shaped s;

-- Make balances consistent with approved requests of the current year
UPDATE leave_balance lb
SET used_days = LEAST(lb.total_days, u.used)
FROM (
    SELECT employee_id, leave_type, EXTRACT(YEAR FROM start_date)::int AS yr, SUM(days) AS used
    FROM leave_request
    WHERE status = 'APPROVED'
    GROUP BY employee_id, leave_type, EXTRACT(YEAR FROM start_date)::int
) u
WHERE lb.employee_id = u.employee_id
  AND lb.leave_type  = u.leave_type
  AND lb.year        = u.yr;

-- ------------------------------------------------------------ HR cases
-- SLA hours by priority: URGENT 4, HIGH 24, MEDIUM 72, LOW 120.
WITH base AS (
    SELECT
        k,
        5021 + (k * 11) % 94980 AS requester_id,
        (ARRAY['PAYROLL','BENEFITS','LEAVE','ONBOARDING','POLICY','OTHER'])[1 + k % 6] AS category,
        (ARRAY['Payslip discrepancy','Insurance claim query','Leave balance correction',
               'Laptop and ID card pending','Clarification on WFH policy','General HR query'])[1 + k % 6] AS subject,
        (ARRAY['LOW','MEDIUM','MEDIUM','HIGH','URGENT'])[1 + (k / 3) % 5] AS priority,
        (ARRAY['OPEN','IN_PROGRESS','RESOLVED','CLOSED','RESOLVED','OPEN'])[1 + (k / 7) % 6] AS status,
        now() - (k % 45) * interval '1 day' - (k % 24) * interval '1 hour' AS created_at
    FROM generate_series(1, 5000) AS k
),
timed AS (
    SELECT
        b.*,
        b.created_at + (CASE b.priority WHEN 'LOW' THEN 120 WHEN 'MEDIUM' THEN 72 WHEN 'HIGH' THEN 24 ELSE 4 END) * interval '1 hour' AS sla_due_at,
        CASE WHEN b.status IN ('RESOLVED', 'CLOSED')
             THEN LEAST(now(), b.created_at + ((b.k % 100) + 1) * interval '1 hour')
        END AS resolved_at
    FROM base b
)
INSERT INTO hr_case (case_number, requester_id, assignee_id, category, priority, status, subject, description,
                     sla_due_at, sla_breached, created_at, resolved_at)
SELECT
    'HR-' || lpad(t.k::text, 6, '0'),
    t.requester_id,
    CASE WHEN t.status = 'OPEN' AND t.k % 2 = 0 THEN NULL ELSE 1 + t.k % 20 END,
    t.category,
    t.priority,
    t.status,
    t.subject,
    'Demo case generated by the seed script.',
    t.sla_due_at,
    CASE WHEN t.resolved_at IS NOT NULL THEN t.resolved_at > t.sla_due_at ELSE t.sla_due_at < now() END,
    t.created_at,
    t.resolved_at
FROM timed t;

-- Refresh planner statistics so the first queries use the new indexes
ANALYZE;
