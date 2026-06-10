-- =====================================================
-- BLM4522 Proje 7: Veritabanı ve Yedekleme İzleme Tabloları
-- =====================================================

-- İş veritabanı tabloları
CREATE TABLE employees (
    emp_id SERIAL PRIMARY KEY,
    name VARCHAR(100), department VARCHAR(50),
    salary DECIMAL(10,2), hire_date DATE DEFAULT CURRENT_DATE
);

CREATE TABLE projects (
    project_id SERIAL PRIMARY KEY,
    name VARCHAR(100), budget DECIMAL(12,2),
    start_date DATE, status VARCHAR(20) DEFAULT 'active'
);

CREATE TABLE tasks (
    task_id SERIAL PRIMARY KEY,
    project_id INTEGER REFERENCES projects(project_id),
    assigned_to INTEGER REFERENCES employees(emp_id),
    title VARCHAR(200), priority VARCHAR(10),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Veri üret
INSERT INTO employees (name, department, salary)
SELECT 'Çalışan_' || i,
    (ARRAY['IT','HR','Finans','Pazarlama','Satış'])[1+(i%5)],
    (random()*30000+20000)::decimal(10,2)
FROM generate_series(1, 500) AS i;

INSERT INTO projects (name, budget, start_date, status)
SELECT 'Proje_' || i, (random()*500000+10000)::decimal(12,2),
    CURRENT_DATE - (random()*365)::integer,
    (ARRAY['active','completed','paused'])[1+(i%3)]
FROM generate_series(1, 100) AS i;

INSERT INTO tasks (project_id, assigned_to, title, priority)
SELECT (random()*99+1)::integer, (random()*499+1)::integer,
    'Görev_' || i, (ARRAY['high','medium','low'])[1+(i%3)]
FROM generate_series(1, 5000) AS i;

-- =====================================================
-- YEDEKLEME İZLEME TABLOLARI
-- =====================================================

-- Yedekleme geçmişi
CREATE TABLE backup_history (
    backup_id SERIAL PRIMARY KEY,
    backup_type VARCHAR(20) NOT NULL,    -- 'full', 'schema', 'table'
    file_name VARCHAR(200) NOT NULL,
    file_size_bytes BIGINT,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP,
    duration_seconds INTEGER,
    status VARCHAR(20) DEFAULT 'running', -- 'success', 'failed', 'running'
    error_message TEXT,
    tables_count INTEGER,
    rows_count BIGINT,
    database_name VARCHAR(50) DEFAULT 'autodb'
);

-- Yedekleme politikası
CREATE TABLE backup_policy (
    policy_id SERIAL PRIMARY KEY,
    policy_name VARCHAR(50) NOT NULL,
    backup_type VARCHAR(20) NOT NULL,
    schedule VARCHAR(50),                -- cron ifadesi
    retention_days INTEGER DEFAULT 7,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Uyarı tablosu
CREATE TABLE backup_alerts (
    alert_id SERIAL PRIMARY KEY,
    alert_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    severity VARCHAR(10),                -- 'INFO', 'WARNING', 'CRITICAL'
    message TEXT NOT NULL,
    backup_id INTEGER REFERENCES backup_history(backup_id),
    acknowledged BOOLEAN DEFAULT false
);

-- Politikaları ekle
INSERT INTO backup_policy (policy_name, backup_type, schedule, retention_days) VALUES
('Günlük Full Backup', 'full', '0 2 * * *', 7),
('Haftalık Schema Backup', 'schema', '0 3 * * 0', 30),
('Saatlik Tablo Backup', 'table', '0 * * * *', 1);

\echo 'Veritabanı oluşturuldu:'
SELECT 'employees' AS tablo, COUNT(*) AS kayit FROM employees
UNION ALL SELECT 'projects', COUNT(*) FROM projects
UNION ALL SELECT 'tasks', COUNT(*) FROM tasks;

\echo ''
\echo 'Yedekleme politikaları:'
SELECT policy_name, backup_type, schedule, retention_days || ' gün' AS saklama FROM backup_policy;
