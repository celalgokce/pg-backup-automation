--
-- PostgreSQL database dump
--

\restrict g7gIGKilnY1cGRvUXrxBAcBAGGg4gWMxnR8MXLfntnOlmnaGUKUBHBaG4UHGsxf

-- Dumped from database version 16.13 (Debian 16.13-1.pgdg13+1)
-- Dumped by pg_dump version 16.13 (Debian 16.13-1.pgdg13+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: backup_alerts; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.backup_alerts (
    alert_id integer NOT NULL,
    alert_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    severity character varying(10),
    message text NOT NULL,
    backup_id integer,
    acknowledged boolean DEFAULT false
);


ALTER TABLE public.backup_alerts OWNER TO admin;

--
-- Name: backup_alerts_alert_id_seq; Type: SEQUENCE; Schema: public; Owner: admin
--

CREATE SEQUENCE public.backup_alerts_alert_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.backup_alerts_alert_id_seq OWNER TO admin;

--
-- Name: backup_alerts_alert_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: admin
--

ALTER SEQUENCE public.backup_alerts_alert_id_seq OWNED BY public.backup_alerts.alert_id;


--
-- Name: backup_history; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.backup_history (
    backup_id integer NOT NULL,
    backup_type character varying(20) NOT NULL,
    file_name character varying(200) NOT NULL,
    file_size_bytes bigint,
    start_time timestamp without time zone NOT NULL,
    end_time timestamp without time zone,
    duration_seconds integer,
    status character varying(20) DEFAULT 'running'::character varying,
    error_message text,
    tables_count integer,
    rows_count bigint,
    database_name character varying(50) DEFAULT 'autodb'::character varying
);


ALTER TABLE public.backup_history OWNER TO admin;

--
-- Name: backup_history_backup_id_seq; Type: SEQUENCE; Schema: public; Owner: admin
--

CREATE SEQUENCE public.backup_history_backup_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.backup_history_backup_id_seq OWNER TO admin;

--
-- Name: backup_history_backup_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: admin
--

ALTER SEQUENCE public.backup_history_backup_id_seq OWNED BY public.backup_history.backup_id;


--
-- Name: backup_policy; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.backup_policy (
    policy_id integer NOT NULL,
    policy_name character varying(50) NOT NULL,
    backup_type character varying(20) NOT NULL,
    schedule character varying(50),
    retention_days integer DEFAULT 7,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.backup_policy OWNER TO admin;

--
-- Name: backup_policy_policy_id_seq; Type: SEQUENCE; Schema: public; Owner: admin
--

CREATE SEQUENCE public.backup_policy_policy_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.backup_policy_policy_id_seq OWNER TO admin;

--
-- Name: backup_policy_policy_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: admin
--

ALTER SEQUENCE public.backup_policy_policy_id_seq OWNED BY public.backup_policy.policy_id;


--
-- Name: employees; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.employees (
    emp_id integer NOT NULL,
    name character varying(100),
    department character varying(50),
    salary numeric(10,2),
    hire_date date DEFAULT CURRENT_DATE
);


ALTER TABLE public.employees OWNER TO admin;

--
-- Name: employees_emp_id_seq; Type: SEQUENCE; Schema: public; Owner: admin
--

CREATE SEQUENCE public.employees_emp_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.employees_emp_id_seq OWNER TO admin;

--
-- Name: employees_emp_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: admin
--

ALTER SEQUENCE public.employees_emp_id_seq OWNED BY public.employees.emp_id;


--
-- Name: projects; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.projects (
    project_id integer NOT NULL,
    name character varying(100),
    budget numeric(12,2),
    start_date date,
    status character varying(20) DEFAULT 'active'::character varying
);


ALTER TABLE public.projects OWNER TO admin;

--
-- Name: projects_project_id_seq; Type: SEQUENCE; Schema: public; Owner: admin
--

CREATE SEQUENCE public.projects_project_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.projects_project_id_seq OWNER TO admin;

--
-- Name: projects_project_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: admin
--

ALTER SEQUENCE public.projects_project_id_seq OWNED BY public.projects.project_id;


--
-- Name: tasks; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.tasks (
    task_id integer NOT NULL,
    project_id integer,
    assigned_to integer,
    title character varying(200),
    priority character varying(10),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.tasks OWNER TO admin;

--
-- Name: tasks_task_id_seq; Type: SEQUENCE; Schema: public; Owner: admin
--

CREATE SEQUENCE public.tasks_task_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tasks_task_id_seq OWNER TO admin;

--
-- Name: tasks_task_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: admin
--

ALTER SEQUENCE public.tasks_task_id_seq OWNED BY public.tasks.task_id;


--
-- Name: backup_alerts alert_id; Type: DEFAULT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.backup_alerts ALTER COLUMN alert_id SET DEFAULT nextval('public.backup_alerts_alert_id_seq'::regclass);


--
-- Name: backup_history backup_id; Type: DEFAULT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.backup_history ALTER COLUMN backup_id SET DEFAULT nextval('public.backup_history_backup_id_seq'::regclass);


--
-- Name: backup_policy policy_id; Type: DEFAULT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.backup_policy ALTER COLUMN policy_id SET DEFAULT nextval('public.backup_policy_policy_id_seq'::regclass);


--
-- Name: employees emp_id; Type: DEFAULT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.employees ALTER COLUMN emp_id SET DEFAULT nextval('public.employees_emp_id_seq'::regclass);


--
-- Name: projects project_id; Type: DEFAULT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.projects ALTER COLUMN project_id SET DEFAULT nextval('public.projects_project_id_seq'::regclass);


--
-- Name: tasks task_id; Type: DEFAULT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.tasks ALTER COLUMN task_id SET DEFAULT nextval('public.tasks_task_id_seq'::regclass);


--
-- Name: backup_alerts backup_alerts_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.backup_alerts
    ADD CONSTRAINT backup_alerts_pkey PRIMARY KEY (alert_id);


--
-- Name: backup_history backup_history_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.backup_history
    ADD CONSTRAINT backup_history_pkey PRIMARY KEY (backup_id);


--
-- Name: backup_policy backup_policy_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.backup_policy
    ADD CONSTRAINT backup_policy_pkey PRIMARY KEY (policy_id);


--
-- Name: employees employees_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT employees_pkey PRIMARY KEY (emp_id);


--
-- Name: projects projects_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_pkey PRIMARY KEY (project_id);


--
-- Name: tasks tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT tasks_pkey PRIMARY KEY (task_id);


--
-- Name: backup_alerts backup_alerts_backup_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.backup_alerts
    ADD CONSTRAINT backup_alerts_backup_id_fkey FOREIGN KEY (backup_id) REFERENCES public.backup_history(backup_id);


--
-- Name: tasks tasks_assigned_to_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT tasks_assigned_to_fkey FOREIGN KEY (assigned_to) REFERENCES public.employees(emp_id);


--
-- Name: tasks tasks_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT tasks_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(project_id);


--
-- PostgreSQL database dump complete
--

\unrestrict g7gIGKilnY1cGRvUXrxBAcBAGGg4gWMxnR8MXLfntnOlmnaGUKUBHBaG4UHGsxf

