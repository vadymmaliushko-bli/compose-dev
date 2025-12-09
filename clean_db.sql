--
-- PostgreSQL database dump
--

\restrict jrV11hbygwNBetvgvZHBQMer4kO3yr4l8MWNOJ9ldFjQ1vd1eLxvqGohd2zZawk

-- Dumped from database version 17.7 (Debian 17.7-3.pgdg12+1)
-- Dumped by pg_dump version 17.7 (Debian 17.7-3.pgdg12+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: create_archived_operation(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.create_archived_operation() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin	
insert into archived_operations (operation_id, in_archive, update_time) values (NEW.id, false, NOW());
return NEW;
end;
$$;


--
-- Name: create_natural_norm(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.create_natural_norm() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin	
insert into natural_operations (operation_id, multiplier, update_time, natural_norm) values (NEW.id, 1, NOW(), false);
return NEW;
end;
$$;


--
-- Name: create_worker_shift(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.create_worker_shift() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
insert into worker_shifts (worker_id, shift_id, update_time) values(NEW.telegram_id, 1, NOW());
return NEW;
end;
$$;


--
-- Name: delete_department_references(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.delete_department_references() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
delete from team_leads where department_id = OLD.id;
return OLD;
end;
$$;


--
-- Name: delete_module_if_exists(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.delete_module_if_exists() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
delete from module_operation where operation_id = NEW.operation_id;
return NEW;
end;
$$;


--
-- Name: delete_operation_permission_references(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.delete_operation_permission_references() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
delete from trusted_workers where op_permission_id = OLD.id;
return OLD;
end;
$$;


--
-- Name: delete_operation_references(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.delete_operation_references() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
if ((select count(*) from works where operation_id = OLD.id) = 0)
then delete from operation_versions where operation_id = OLD.id;
delete from archived_operations where operation_id = OLD.id;
delete from natural_operations where operation_id = OLD.id;
delete from operation_permissions where operation_id = OLD.id;
else raise 'Operation is already in use';
end if;
return OLD;
end;
$$;


--
-- Name: delete_shift_references(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.delete_shift_references() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
delete from shift_coefficients where shift_id = OLD.id;
delete from worker_shifts where shift_id = OLD.id;
delete from shift_bonuses where shift_id = OLD.id;
return OLD;
end;
$$;


--
-- Name: delete_worker_references(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.delete_worker_references() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
delete from worker_shifts where worker_id = OLD.telegram_id;
delete from calculator_avoided_workers where worker_id = OLD.telegram_id;
delete from team_leads where worker_id = OLD.telegram_id;
delete from trusted_workers where worker_id = OLD.telegram_id;
delete from work_days where worker_id = OLD.telegram_id;
return OLD;
end;
$$;


--
-- Name: delete_works_average(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.delete_works_average() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	delete from works_average where work_id = OLD.id;
	RETURN OLD;
end;
$$;


--
-- Name: delete_works_requests(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.delete_works_requests() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	delete from work_permission_requests where work_permission_requests.work_id = OLD.id;
	return OLD;
end;
$$;


--
-- Name: get_mode_from_new(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_mode_from_new(integer) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
begin
return (select distinct on (sub.operation_id) sub.average as average from "works_average"
    inner join (
    select works_average.work_id as id,works_average.average,
    sum(works_average.result) over (partition by works_average.operation_id order by works_average.average) as result_sum,
    sum(works_average.result) over (partition by works_average.operation_id) as operation_result_sum,
    works_average.operation_id as operation_id
    from "works_average"
    join works on works.id = works_average.work_id
    where works_average.average > 1 and works_average.result != 0 and works.start_time between NOW() - interval '1 month' and NOW()
    order by "works_average"."operation_id" asc, "works_average"."average" asc
    ) as "sub" on "sub"."id" = "works_average"."work_id"
    where sub.result_sum >= sub.operation_result_sum / 2 and sub.operation_id = $1
    order by sub.operation_id, sub.average asc);
end;
$_$;


--
-- Name: insert_operation_version(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.insert_operation_version() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
insert into operation_versions(operation_id, update_time, norm_duration) values (NEW.id, NOW(), NEW.time_norm);
return NEW;
end;
$$;


--
-- Name: insert_operations_average(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.insert_operations_average() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
insert into operations_average(operation_id, average_duration) values (NEW.id, 0);
return NEW;
end;
$$;


--
-- Name: insert_operations_mode(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.insert_operations_mode() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
insert into operations_mode(operation_id, mode) values (NEW.id, 0);
return NEW;
end;
$$;


--
-- Name: insert_works_average(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.insert_works_average() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ begin insert into works_average (work_id, operation_id, result, average) values(NEW.id, NEW.operation_id, NEW.result, coalesce(extract (epoch from NEW.finish_time - NEW.start_time - NEW.pause_duration * '1 sec'::interval)/nullif(NEW.result, 0), 0)); return NEW; end; $$;


--
-- Name: mode_population(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.mode_population(integer) RETURNS void
    LANGUAGE plpgsql
    AS $_$
begin
	insert into operations_mode (operation_id, mode) values ($1, (
	select distinct on (sub.operation_id) sub.average as average from "works_average" 
inner join(
	select works_average.work_id as id,works_average.average,
            sum(works_average.result) over (partition by works_average.operation_id order by works_average.average) as result_sum,
            sum(works_average.result) over (partition by works_average.operation_id) as operation_result_sum,
            works_average.operation_id as operation_id
	from "works_average" 
	inner join (
		select works.id as id, 
			works.operation_id as operation_id, 
			works.start_time as start_time, 
			works.finish_time as finish_time, 
			works.pause_duration as pause_duration, 
			works.result as result, works.work_day_id, 
			works.payment from "works" order by "start_time" desc) 
	as "sub" on "sub"."id" = "works_average"."work_id" 
	where works_average.average > 1 and works_average.result != 0 and sub.start_time between date_trunc('month', NOW()) AND NOW()
	order by "works_average"."operation_id" asc, "works_average"."average" asc
) as "sub" on "sub"."id" = "works_average"."work_id" 
where sub.result_sum >= sub.operation_result_sum / 2 and sub.operation_id = $1
order by sub.operation_id, sub.average desc
	));
end;
$_$;


--
-- Name: operation_normation(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.operation_normation() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
if ((OLD.time_norm = 0 or OLD.time_norm is null) and (select count(*) from operations where operations.id = OLD.id) = 1)
then update operation_versions set norm_duration = NEW.time_norm where operation_id = OLD.id;
end if;
return NEW;
end;
$$;


--
-- Name: truncate_tables(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.truncate_tables(username character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    statements CURSOR FOR
        SELECT tablename FROM pg_tables
        WHERE tableowner = username AND schemaname = 'public';
BEGIN
    FOR stmt IN statements LOOP
        EXECUTE 'TRUNCATE TABLE ' || quote_ident(stmt.tablename) || ' CASCADE;';
    END LOOP;
END;
$$;


--
-- Name: update_from_old_operations_average(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_from_old_operations_average() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
update operations_average set average_duration = coalesce((select extract(epoch from sum(works.finish_time - works.start_time - works.pause_duration * interval '1 sec') / nullif(sum(works.result), 0)) from works where works.operation_id = OLD.operation_id), 0) where operation_id = OLD.operation_id;
return NEW;
end;
$$;


--
-- Name: update_from_old_operations_mode(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_from_old_operations_mode() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
update operations_mode set mode = get_mode_from_new(OLD.operation_id) where operation_id = OLD.operation_id;
return OLD;
end;
$$;


--
-- Name: update_operation_version(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_operation_version() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
if (NEW.time_norm != OLD.time_norm)
then insert into operation_versions(operation_id, update_time, norm_duration) values (NEW.id, NOW(), NEW.time_norm);
end if;
return NEW;
end;
$$;


--
-- Name: update_operations_average(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_operations_average() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
update operations_average set average_duration = 
coalesce(
	(
		select extract(
			epoch from sum(
				works.finish_time - works.start_time - works.pause_duration * interval '1 sec'
				) / nullif(sum(works.result), 0)
			) from works where works.operation_id = NEW.operation_id), 0) where operation_id = NEW.operation_id;
return NEW;
end;
$$;


--
-- Name: update_operations_mode(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_operations_mode() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
update operations_mode set mode = get_mode_from_new(NEW.operation_id) where operation_id = NEW.operation_id;
return NEW;
end;
$$;


--
-- Name: update_works_average(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_works_average() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ begin update works_average set operation_id = NEW.operation_id, result = NEW.result, average = coalesce(extract (epoch from NEW.finish_time - NEW.start_time - NEW.pause_duration * '1 sec'::interval)/nullif(NEW.result, 0), 0) where work_id = NEW.id; return NEW; end; $$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: admin_config; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admin_config (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    value character varying(255) NOT NULL,
    description text,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


--
-- Name: admin_config_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.admin_config_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admin_config_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.admin_config_id_seq OWNED BY public.admin_config.id;


--
-- Name: admin_menu; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admin_menu (
    id integer NOT NULL,
    parent_id integer DEFAULT 0 NOT NULL,
    "order" integer DEFAULT 0 NOT NULL,
    title character varying(50) NOT NULL,
    icon character varying(50) NOT NULL,
    uri character varying(255),
    permission character varying(255),
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


--
-- Name: admin_menu_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.admin_menu_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admin_menu_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.admin_menu_id_seq OWNED BY public.admin_menu.id;


--
-- Name: admin_operation_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admin_operation_log (
    id integer NOT NULL,
    user_id integer NOT NULL,
    path character varying(255) NOT NULL,
    method character varying(10) NOT NULL,
    ip character varying(255) NOT NULL,
    input text NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


--
-- Name: admin_operation_log_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.admin_operation_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admin_operation_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.admin_operation_log_id_seq OWNED BY public.admin_operation_log.id;


--
-- Name: admin_permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admin_permissions (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    slug character varying(50) NOT NULL,
    http_method character varying(255),
    http_path text,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


--
-- Name: admin_permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.admin_permissions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admin_permissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.admin_permissions_id_seq OWNED BY public.admin_permissions.id;


--
-- Name: admin_role_menu; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admin_role_menu (
    role_id integer NOT NULL,
    menu_id integer NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


--
-- Name: admin_role_permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admin_role_permissions (
    role_id integer NOT NULL,
    permission_id integer NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


--
-- Name: admin_role_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admin_role_users (
    role_id integer NOT NULL,
    user_id integer NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


--
-- Name: admin_roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admin_roles (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    slug character varying(50) NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


--
-- Name: admin_roles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.admin_roles_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admin_roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.admin_roles_id_seq OWNED BY public.admin_roles.id;


--
-- Name: admin_user_permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admin_user_permissions (
    user_id integer NOT NULL,
    permission_id integer NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


--
-- Name: admin_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admin_users (
    id integer NOT NULL,
    username character varying(190) NOT NULL,
    password character varying(60) NOT NULL,
    name character varying(255) NOT NULL,
    avatar character varying(255),
    remember_token character varying(100),
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


--
-- Name: admin_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.admin_users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admin_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.admin_users_id_seq OWNED BY public.admin_users.id;


--
-- Name: admins; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admins (
    telegram_id bigint NOT NULL,
    first_name character varying(20) NOT NULL,
    last_name character varying(20) NOT NULL
);


--
-- Name: admins_telegram_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.admins_telegram_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admins_telegram_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.admins_telegram_id_seq OWNED BY public.admins.telegram_id;


--
-- Name: archived_operations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.archived_operations (
    id integer NOT NULL,
    operation_id integer NOT NULL,
    in_archive boolean NOT NULL,
    update_time timestamp without time zone NOT NULL
);


--
-- Name: archived_operations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.archived_operations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: archived_operations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.archived_operations_id_seq OWNED BY public.archived_operations.id;


--
-- Name: black_list; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.black_list (
    id integer NOT NULL,
    worker_id bigint NOT NULL
);


--
-- Name: black_list_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.black_list_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: black_list_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.black_list_id_seq OWNED BY public.black_list.id;


--
-- Name: bonuses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bonuses (
    id integer NOT NULL,
    hours real NOT NULL,
    payment real NOT NULL,
    update_time timestamp without time zone NOT NULL,
    active boolean DEFAULT true NOT NULL
);


--
-- Name: bonuses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bonuses_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bonuses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.bonuses_id_seq OWNED BY public.bonuses.id;


--
-- Name: calculator_avoided_workers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.calculator_avoided_workers (
    id integer NOT NULL,
    worker_id bigint NOT NULL,
    is_avoided boolean NOT NULL
);


--
-- Name: calculator_avoided_workers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.calculator_avoided_workers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: calculator_avoided_workers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.calculator_avoided_workers_id_seq OWNED BY public.calculator_avoided_workers.id;


--
-- Name: department_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.department_groups (
    id integer NOT NULL,
    department_id integer NOT NULL,
    group_id bigint NOT NULL,
    report_type_id integer NOT NULL
);


--
-- Name: department_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.department_groups_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: department_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.department_groups_id_seq OWNED BY public.department_groups.id;


--
-- Name: department_report_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.department_report_types (
    id integer NOT NULL,
    name text
);


--
-- Name: department_report_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.department_report_types_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: department_report_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.department_report_types_id_seq OWNED BY public.department_report_types.id;


--
-- Name: departments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.departments (
    id integer NOT NULL,
    name character varying(100),
    short_name text DEFAULT 'something'::text NOT NULL
);


--
-- Name: departments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.departments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: departments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.departments_id_seq OWNED BY public.departments.id;


--
-- Name: failed_jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.failed_jobs (
    id bigint NOT NULL,
    uuid character varying(255) NOT NULL,
    connection text NOT NULL,
    queue text NOT NULL,
    payload text NOT NULL,
    exception text NOT NULL,
    failed_at timestamp(0) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: failed_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.failed_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: failed_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.failed_jobs_id_seq OWNED BY public.failed_jobs.id;


--
-- Name: hour_payments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hour_payments (
    id integer NOT NULL,
    payment double precision NOT NULL,
    update_time timestamp without time zone NOT NULL
);


--
-- Name: hour_payments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hour_payments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hour_payments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hour_payments_id_seq OWNED BY public.hour_payments.id;


--
-- Name: migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.migrations (
    id integer NOT NULL,
    migration character varying(255) NOT NULL,
    batch integer NOT NULL
);


--
-- Name: migrations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.migrations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: migrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.migrations_id_seq OWNED BY public.migrations.id;


--
-- Name: module_operation; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.module_operation (
    id integer NOT NULL,
    operation_id integer NOT NULL,
    module_id integer NOT NULL
);


--
-- Name: module_operation_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.module_operation_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: module_operation_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.module_operation_id_seq OWNED BY public.module_operation.id;


--
-- Name: modules; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.modules (
    id integer NOT NULL,
    name text NOT NULL
);


--
-- Name: modules_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.modules_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: modules_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.modules_id_seq OWNED BY public.modules.id;


--
-- Name: natural_operations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.natural_operations (
    id integer NOT NULL,
    operation_id integer NOT NULL,
    multiplier real NOT NULL,
    update_time timestamp without time zone NOT NULL,
    natural_norm boolean NOT NULL
);


--
-- Name: natural_operations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.natural_operations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: natural_operations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.natural_operations_id_seq OWNED BY public.natural_operations.id;


--
-- Name: operation_feedstocks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.operation_feedstocks (
    id integer NOT NULL,
    operation_id integer,
    workpiece_id integer,
    amount integer NOT NULL
);


--
-- Name: operation_feedstocks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.operation_feedstocks_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: operation_feedstocks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.operation_feedstocks_id_seq OWNED BY public.operation_feedstocks.id;


--
-- Name: operation_permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.operation_permissions (
    id integer NOT NULL,
    operation_id integer NOT NULL,
    permission_type_id integer NOT NULL,
    is_description_required boolean NOT NULL
);


--
-- Name: operation_permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.operation_permissions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: operation_permissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.operation_permissions_id_seq OWNED BY public.operation_permissions.id;


--
-- Name: operation_results; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.operation_results (
    id integer NOT NULL,
    operation_id integer,
    workpiece_id integer,
    amount integer NOT NULL
);


--
-- Name: operation_results_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.operation_results_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: operation_results_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.operation_results_id_seq OWNED BY public.operation_results.id;


--
-- Name: operation_versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.operation_versions (
    id integer NOT NULL,
    operation_id integer NOT NULL,
    update_time timestamp without time zone NOT NULL,
    norm_duration integer
);


--
-- Name: operation_versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.operation_versions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: operation_versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.operation_versions_id_seq OWNED BY public.operation_versions.id;


--
-- Name: operations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.operations (
    id integer NOT NULL,
    name character varying(200) NOT NULL,
    time_norm integer DEFAULT 0,
    department_id integer NOT NULL,
    description text
);


--
-- Name: operations_average; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.operations_average (
    id integer NOT NULL,
    operation_id integer NOT NULL,
    average_duration integer NOT NULL
);


--
-- Name: operations_average_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.operations_average_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: operations_average_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.operations_average_id_seq OWNED BY public.operations_average.id;


--
-- Name: operations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.operations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: operations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.operations_id_seq OWNED BY public.operations.id;


--
-- Name: operations_mode; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.operations_mode (
    id integer NOT NULL,
    operation_id integer NOT NULL,
    mode integer
);


--
-- Name: operations_mode_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.operations_mode_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: operations_mode_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.operations_mode_id_seq OWNED BY public.operations_mode.id;


--
-- Name: password_reset_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.password_reset_tokens (
    email character varying(255) NOT NULL,
    token character varying(255) NOT NULL,
    created_at timestamp(0) without time zone
);


--
-- Name: payment_coefficients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payment_coefficients (
    id integer NOT NULL,
    multiplier real NOT NULL,
    hours real NOT NULL,
    update_time timestamp without time zone NOT NULL
);


--
-- Name: payment_coefficients_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.payment_coefficients_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: payment_coefficients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.payment_coefficients_id_seq OWNED BY public.payment_coefficients.id;


--
-- Name: permission_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.permission_types (
    id integer NOT NULL,
    name text NOT NULL
);


--
-- Name: permission_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.permission_types_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: permission_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.permission_types_id_seq OWNED BY public.permission_types.id;


--
-- Name: personal_access_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.personal_access_tokens (
    id bigint NOT NULL,
    tokenable_type character varying(255) NOT NULL,
    tokenable_id bigint NOT NULL,
    name character varying(255) NOT NULL,
    token character varying(64) NOT NULL,
    abilities text,
    last_used_at timestamp(0) without time zone,
    expires_at timestamp(0) without time zone,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


--
-- Name: personal_access_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.personal_access_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: personal_access_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.personal_access_tokens_id_seq OWNED BY public.personal_access_tokens.id;


--
-- Name: shift_bonuses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.shift_bonuses (
    id integer NOT NULL,
    shift_id integer NOT NULL,
    bonus_id integer NOT NULL
);


--
-- Name: shift_bonuses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.shift_bonuses_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: shift_bonuses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.shift_bonuses_id_seq OWNED BY public.shift_bonuses.id;


--
-- Name: shift_coefficients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.shift_coefficients (
    id integer NOT NULL,
    shift_id integer NOT NULL,
    coefficient_id integer NOT NULL
);


--
-- Name: shift_coefficients_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.shift_coefficients_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: shift_coefficients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.shift_coefficients_id_seq OWNED BY public.shift_coefficients.id;


--
-- Name: shift_hour_payments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.shift_hour_payments (
    id integer NOT NULL,
    payment_id integer NOT NULL,
    shift_id integer NOT NULL
);


--
-- Name: shift_hour_payments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.shift_hour_payments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: shift_hour_payments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.shift_hour_payments_id_seq OWNED BY public.shift_hour_payments.id;


--
-- Name: shifts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.shifts (
    id integer NOT NULL,
    name text NOT NULL,
    shift_start_time time without time zone DEFAULT '09:00:00'::time without time zone NOT NULL,
    department_id integer
);


--
-- Name: shifts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.shifts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: shifts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.shifts_id_seq OWNED BY public.shifts.id;


--
-- Name: team_leads; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.team_leads (
    worker_id integer NOT NULL,
    department_id integer,
    admin_user_id integer,
    id integer NOT NULL
);


--
-- Name: team_leads_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.team_leads_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: team_leads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.team_leads_id_seq OWNED BY public.team_leads.id;


--
-- Name: trusted_workers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trusted_workers (
    id integer NOT NULL,
    op_permission_id integer NOT NULL,
    worker_id bigint NOT NULL
);


--
-- Name: trusted_workers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.trusted_workers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trusted_workers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.trusted_workers_id_seq OWNED BY public.trusted_workers.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    email character varying(255) NOT NULL,
    email_verified_at timestamp(0) without time zone,
    password character varying(255) NOT NULL,
    remember_token character varying(100),
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: work_day_departments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.work_day_departments (
    id bigint NOT NULL,
    department_id bigint,
    work_day_id bigint NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


--
-- Name: work_day_departments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.work_day_departments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: work_day_departments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.work_day_departments_id_seq OWNED BY public.work_day_departments.id;


--
-- Name: work_days; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.work_days (
    id integer NOT NULL,
    worker_id bigint NOT NULL,
    start_time timestamp without time zone NOT NULL,
    finish_time timestamp without time zone NOT NULL,
    payment real NOT NULL,
    raw_payment real DEFAULT 0 NOT NULL,
    wd_norm integer DEFAULT 0 NOT NULL,
    bonus_id integer NOT NULL,
    in_shelter_time integer DEFAULT 0 NOT NULL
);


--
-- Name: work_days_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.work_days_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: work_days_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.work_days_id_seq OWNED BY public.work_days.id;


--
-- Name: work_departments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.work_departments (
    id bigint NOT NULL,
    department_id bigint NOT NULL,
    work_id bigint NOT NULL
);


--
-- Name: work_departments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.work_departments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: work_departments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.work_departments_id_seq OWNED BY public.work_departments.id;


--
-- Name: work_permission_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.work_permission_requests (
    id integer NOT NULL,
    work_id integer NOT NULL,
    message text NOT NULL
);


--
-- Name: work_permission_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.work_permission_requests_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: work_permission_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.work_permission_requests_id_seq OWNED BY public.work_permission_requests.id;


--
-- Name: worker_shifts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.worker_shifts (
    id integer NOT NULL,
    worker_id bigint NOT NULL,
    shift_id integer NOT NULL,
    update_time timestamp without time zone NOT NULL,
    secondary_shift_id integer
);


--
-- Name: worker_shifts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.worker_shifts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: worker_shifts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.worker_shifts_id_seq OWNED BY public.worker_shifts.id;


--
-- Name: workers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.workers (
    telegram_id bigint NOT NULL,
    first_name character varying(40) NOT NULL,
    last_name character varying(40) NOT NULL,
    start_work_time time without time zone NOT NULL,
    patronymic character varying(60) DEFAULT ''::character varying NOT NULL,
    internship_start_time timestamp(0) without time zone,
    ipn bigint,
    hurma_id character varying(255),
    internship_end_time timestamp(0) without time zone
);


--
-- Name: workers_telegram_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.workers_telegram_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: workers_telegram_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.workers_telegram_id_seq OWNED BY public.workers.telegram_id;


--
-- Name: workpieces; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.workpieces (
    id integer NOT NULL,
    name character varying(250) NOT NULL,
    amount integer NOT NULL
);


--
-- Name: workpieces_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.workpieces_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: workpieces_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.workpieces_id_seq OWNED BY public.workpieces.id;


--
-- Name: works; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.works (
    id integer NOT NULL,
    work_day_id integer NOT NULL,
    operation_id integer NOT NULL,
    start_time timestamp without time zone NOT NULL,
    finish_time timestamp without time zone NOT NULL,
    result smallint NOT NULL,
    pause_duration integer DEFAULT 0,
    payment real
);


--
-- Name: works_average; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.works_average (
    work_id integer NOT NULL,
    operation_id integer NOT NULL,
    result integer NOT NULL,
    average double precision NOT NULL
);


--
-- Name: works_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.works_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: works_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.works_id_seq OWNED BY public.works.id;


--
-- Name: admin_config id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_config ALTER COLUMN id SET DEFAULT nextval('public.admin_config_id_seq'::regclass);


--
-- Name: admin_menu id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_menu ALTER COLUMN id SET DEFAULT nextval('public.admin_menu_id_seq'::regclass);


--
-- Name: admin_operation_log id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_operation_log ALTER COLUMN id SET DEFAULT nextval('public.admin_operation_log_id_seq'::regclass);


--
-- Name: admin_permissions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_permissions ALTER COLUMN id SET DEFAULT nextval('public.admin_permissions_id_seq'::regclass);


--
-- Name: admin_roles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_roles ALTER COLUMN id SET DEFAULT nextval('public.admin_roles_id_seq'::regclass);


--
-- Name: admin_users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_users ALTER COLUMN id SET DEFAULT nextval('public.admin_users_id_seq'::regclass);


--
-- Name: archived_operations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.archived_operations ALTER COLUMN id SET DEFAULT nextval('public.archived_operations_id_seq'::regclass);


--
-- Name: black_list id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.black_list ALTER COLUMN id SET DEFAULT nextval('public.black_list_id_seq'::regclass);


--
-- Name: bonuses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bonuses ALTER COLUMN id SET DEFAULT nextval('public.bonuses_id_seq'::regclass);


--
-- Name: calculator_avoided_workers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calculator_avoided_workers ALTER COLUMN id SET DEFAULT nextval('public.calculator_avoided_workers_id_seq'::regclass);


--
-- Name: department_groups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.department_groups ALTER COLUMN id SET DEFAULT nextval('public.department_groups_id_seq'::regclass);


--
-- Name: department_report_types id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.department_report_types ALTER COLUMN id SET DEFAULT nextval('public.department_report_types_id_seq'::regclass);


--
-- Name: departments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.departments ALTER COLUMN id SET DEFAULT nextval('public.departments_id_seq'::regclass);


--
-- Name: failed_jobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.failed_jobs ALTER COLUMN id SET DEFAULT nextval('public.failed_jobs_id_seq'::regclass);


--
-- Name: hour_payments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hour_payments ALTER COLUMN id SET DEFAULT nextval('public.hour_payments_id_seq'::regclass);


--
-- Name: migrations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.migrations ALTER COLUMN id SET DEFAULT nextval('public.migrations_id_seq'::regclass);


--
-- Name: module_operation id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.module_operation ALTER COLUMN id SET DEFAULT nextval('public.module_operation_id_seq'::regclass);


--
-- Name: modules id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.modules ALTER COLUMN id SET DEFAULT nextval('public.modules_id_seq'::regclass);


--
-- Name: natural_operations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.natural_operations ALTER COLUMN id SET DEFAULT nextval('public.natural_operations_id_seq'::regclass);


--
-- Name: operation_feedstocks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operation_feedstocks ALTER COLUMN id SET DEFAULT nextval('public.operation_feedstocks_id_seq'::regclass);


--
-- Name: operation_permissions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operation_permissions ALTER COLUMN id SET DEFAULT nextval('public.operation_permissions_id_seq'::regclass);


--
-- Name: operation_results id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operation_results ALTER COLUMN id SET DEFAULT nextval('public.operation_results_id_seq'::regclass);


--
-- Name: operation_versions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operation_versions ALTER COLUMN id SET DEFAULT nextval('public.operation_versions_id_seq'::regclass);


--
-- Name: operations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operations ALTER COLUMN id SET DEFAULT nextval('public.operations_id_seq'::regclass);


--
-- Name: operations_average id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operations_average ALTER COLUMN id SET DEFAULT nextval('public.operations_average_id_seq'::regclass);


--
-- Name: operations_mode id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operations_mode ALTER COLUMN id SET DEFAULT nextval('public.operations_mode_id_seq'::regclass);


--
-- Name: payment_coefficients id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_coefficients ALTER COLUMN id SET DEFAULT nextval('public.payment_coefficients_id_seq'::regclass);


--
-- Name: permission_types id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.permission_types ALTER COLUMN id SET DEFAULT nextval('public.permission_types_id_seq'::regclass);


--
-- Name: personal_access_tokens id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.personal_access_tokens ALTER COLUMN id SET DEFAULT nextval('public.personal_access_tokens_id_seq'::regclass);


--
-- Name: shift_bonuses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shift_bonuses ALTER COLUMN id SET DEFAULT nextval('public.shift_bonuses_id_seq'::regclass);


--
-- Name: shift_coefficients id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shift_coefficients ALTER COLUMN id SET DEFAULT nextval('public.shift_coefficients_id_seq'::regclass);


--
-- Name: shift_hour_payments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shift_hour_payments ALTER COLUMN id SET DEFAULT nextval('public.shift_hour_payments_id_seq'::regclass);


--
-- Name: shifts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shifts ALTER COLUMN id SET DEFAULT nextval('public.shifts_id_seq'::regclass);


--
-- Name: team_leads id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.team_leads ALTER COLUMN id SET DEFAULT nextval('public.team_leads_id_seq'::regclass);


--
-- Name: trusted_workers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trusted_workers ALTER COLUMN id SET DEFAULT nextval('public.trusted_workers_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: work_day_departments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.work_day_departments ALTER COLUMN id SET DEFAULT nextval('public.work_day_departments_id_seq'::regclass);


--
-- Name: work_days id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.work_days ALTER COLUMN id SET DEFAULT nextval('public.work_days_id_seq'::regclass);


--
-- Name: work_departments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.work_departments ALTER COLUMN id SET DEFAULT nextval('public.work_departments_id_seq'::regclass);


--
-- Name: work_permission_requests id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.work_permission_requests ALTER COLUMN id SET DEFAULT nextval('public.work_permission_requests_id_seq'::regclass);


--
-- Name: worker_shifts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.worker_shifts ALTER COLUMN id SET DEFAULT nextval('public.worker_shifts_id_seq'::regclass);


--
-- Name: workpieces id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workpieces ALTER COLUMN id SET DEFAULT nextval('public.workpieces_id_seq'::regclass);


--
-- Name: works id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.works ALTER COLUMN id SET DEFAULT nextval('public.works_id_seq'::regclass);


--
-- Data for Name: admin_config; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.admin_config (id, name, value, description, created_at, updated_at) FROM stdin;
5	ставка за місяць	7000		2025-05-05 00:00:00	2025-05-05 00:00:00
12	Час для спуску в укриття в хв	15		2025-05-05 00:00:00	2025-05-05 00:00:00
7	id менеджера по принтерах	-4608280625ґ		2025-05-05 00:00:00	2025-05-05 00:00:00
121	Керівник виробництва	681324012	\N	2025-05-05 00:00:00	2025-11-15 11:52:00
4	id чату з звітами за день	-5070282082	\N	2025-05-05 00:00:00	2025-11-15 12:45:26
\.


--
-- Data for Name: admin_menu; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.admin_menu (id, parent_id, "order", title, icon, uri, permission, created_at, updated_at) FROM stdin;
1	0	1	Dashboard	icon-chart-bar	/	\N	\N	\N
2	0	2	Admin	icon-server		\N	\N	\N
3	2	3	Users	icon-users	auth/users	\N	\N	\N
4	2	4	Roles	icon-user	auth/roles	\N	\N	\N
5	2	5	Permission	icon-ban	auth/permissions	\N	\N	\N
6	2	6	Menu	icon-bars	auth/menu	\N	\N	\N
7	2	7	Operation log	icon-history	auth/logs	\N	\N	\N
13	0	8	Config	icon-toggle-on	config	\N	2024-01-24 12:24:01	2024-01-24 12:24:01
11	0	0	Роботи	icon-hammer	works	works	2024-01-12 17:01:44	2024-07-07 09:12:25
8	0	0	Операції	icon-stopwatch	operations	*	2024-01-12 17:00:30	2024-07-07 09:15:43
12	0	0	Робочі дні	icon-calendar-alt	work_days	*	2024-01-12 17:02:03	2024-07-07 09:18:01
9	0	0	Відділи	icon-archive	departments	*	2024-01-12 17:00:49	2024-07-07 09:25:38
14	0	0	Заготовки	icon-boxes	workpieces	*	2024-02-03 12:45:43	2024-07-07 09:28:27
10	0	0	Працівники	icon-user-friends	workers	*	2024-01-12 17:01:16	2024-07-07 09:29:31
16	0	0	Теги	icon-asterisk	modules	*	2024-10-14 11:24:18	2024-10-14 11:24:18
15	0	0	Калькулятор	icon-calculator	calculator	calculator	2024-10-14 11:14:28	2024-10-21 14:31:54
17	0	0	Зміни	icon-business-time	shifts	*	2025-04-23 11:08:32	2025-04-23 11:08:32
\.


--
-- Data for Name: admin_operation_log; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.admin_operation_log (id, user_id, path, method, ip, input, created_at, updated_at) FROM stdin;
1	1	prod7/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk	GET	94.176.198.157	[]	2025-11-14 17:07:37	2025-11-14 17:07:37
2	1	prod7/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/config	GET	94.176.198.157	[]	2025-11-14 17:07:42	2025-11-14 17:07:42
3	1	prod7/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/auth/users	GET	94.176.198.157	[]	2025-11-14 17:07:45	2025-11-14 17:07:45
4	1	prod7/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/auth/users/create	GET	94.176.198.157	[]	2025-11-14 17:07:46	2025-11-14 17:07:46
5	1	prod7/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/auth/users	GET	94.176.198.157	[]	2025-11-14 17:20:13	2025-11-14 17:20:13
6	1	prod7/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/auth/users/create	GET	94.176.198.157	[]	2025-11-14 17:20:15	2025-11-14 17:20:15
7	1	prod7/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/auth/users	POST	94.176.198.157	{"username":"zador","name":"\\u0414\\u0456\\u043c\\u0430","password":"*****-filtered-out-*****","password_confirmation":"KiarAGVi0HYTKmh9uNwkDmS0S9LMGx","roles":["1",null],"search_terms":null,"permissions":["1",null],"_token":"QuEBqAvIE50sGNb89NGte5B02hxvG0lJItbzWvA7"}	2025-11-14 17:21:19	2025-11-14 17:21:19
8	1	prod7/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/auth/users	GET	94.176.198.157	[]	2025-11-14 17:21:20	2025-11-14 17:21:20
9	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk	GET	185.155.88.55	[]	2025-11-15 11:46:39	2025-11-15 11:46:39
10	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/config	GET	185.155.88.55	[]	2025-11-15 11:51:20	2025-11-15 11:51:20
11	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/config/121/edit	GET	185.155.88.55	[]	2025-11-15 11:51:25	2025-11-15 11:51:25
12	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/config/121	PUT	185.155.88.55	{"name":"\\u041a\\u0435\\u0440\\u0456\\u0432\\u043d\\u0438\\u043a \\u0432\\u0438\\u0440\\u043e\\u0431\\u043d\\u0438\\u0446\\u0442\\u0432\\u0430","value":"681324012","description":null,"_token":"pHXj6thuug2IcKElLxkGCAlFncW61ckKJBEIy7a1","_method":"PUT"}	2025-11-15 11:52:00	2025-11-15 11:52:00
13	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/config	GET	185.155.88.55	[]	2025-11-15 11:52:00	2025-11-15 11:52:00
14	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/auth/users	GET	185.155.88.55	[]	2025-11-15 11:59:58	2025-11-15 11:59:58
15	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/auth/users/create	GET	185.155.88.55	[]	2025-11-15 12:00:03	2025-11-15 12:00:03
16	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/auth/users	POST	185.155.88.55	{"username":"artem","name":"\\u0410\\u0440\\u0442\\u0435\\u043c","password":"*****-filtered-out-*****","password_confirmation":"9ifKnZdTCi2WNs4WMbr9va50AYZe3I","roles":["1",null],"search_terms":null,"permissions":["1",null],"_token":"pHXj6thuug2IcKElLxkGCAlFncW61ckKJBEIy7a1"}	2025-11-15 12:00:42	2025-11-15 12:00:42
17	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/auth/users	GET	185.155.88.55	[]	2025-11-15 12:00:42	2025-11-15 12:00:42
18	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/config	GET	185.155.88.55	[]	2025-11-15 12:45:09	2025-11-15 12:45:09
19	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/config/4/edit	GET	185.155.88.55	[]	2025-11-15 12:45:17	2025-11-15 12:45:17
20	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/config/4	PUT	185.155.88.55	{"name":"id \\u0447\\u0430\\u0442\\u0443 \\u0437 \\u0437\\u0432\\u0456\\u0442\\u0430\\u043c\\u0438 \\u0437\\u0430 \\u0434\\u0435\\u043d\\u044c","value":"-5070282082","description":null,"_token":"pHXj6thuug2IcKElLxkGCAlFncW61ckKJBEIy7a1","_method":"PUT"}	2025-11-15 12:45:26	2025-11-15 12:45:26
21	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/config	GET	185.155.88.55	[]	2025-11-15 12:45:26	2025-11-15 12:45:26
22	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk	GET	185.155.88.55	[]	2025-11-17 06:48:18	2025-11-17 06:48:18
23	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works	GET	185.155.88.55	[]	2025-11-17 06:48:54	2025-11-17 06:48:54
24	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works	GET	185.155.88.55	[]	2025-11-17 06:48:54	2025-11-17 06:48:54
25	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works	GET	185.155.88.55	[]	2025-11-17 06:48:54	2025-11-17 06:48:54
26	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works	GET	185.155.88.55	[]	2025-11-17 06:48:55	2025-11-17 06:48:55
27	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works	GET	185.155.88.55	[]	2025-11-17 06:48:55	2025-11-17 06:48:55
28	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works	GET	185.155.88.55	[]	2025-11-17 06:48:55	2025-11-17 06:48:55
29	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works	GET	185.155.88.55	[]	2025-11-17 06:48:55	2025-11-17 06:48:55
30	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works	GET	185.155.88.55	[]	2025-11-17 06:48:55	2025-11-17 06:48:55
31	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works	GET	185.155.88.55	[]	2025-11-17 06:48:55	2025-11-17 06:48:55
32	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works	GET	185.155.88.55	[]	2025-11-17 06:48:55	2025-11-17 06:48:55
33	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works	GET	185.155.88.55	[]	2025-11-17 06:48:56	2025-11-17 06:48:56
34	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works	GET	185.155.88.55	[]	2025-11-17 06:48:56	2025-11-17 06:48:56
35	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works	GET	185.155.88.55	[]	2025-11-17 06:48:56	2025-11-17 06:48:56
36	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works	GET	185.155.88.55	[]	2025-11-17 06:48:56	2025-11-17 06:48:56
37	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works	GET	185.155.88.55	[]	2025-11-17 06:48:56	2025-11-17 06:48:56
38	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works	GET	185.155.88.55	[]	2025-11-17 06:48:56	2025-11-17 06:48:56
39	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works	GET	185.155.88.55	[]	2025-11-17 06:48:56	2025-11-17 06:48:56
40	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works	GET	185.155.88.55	[]	2025-11-17 06:48:57	2025-11-17 06:48:57
41	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works	GET	185.155.88.55	[]	2025-11-17 06:48:57	2025-11-17 06:48:57
42	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works	GET	185.155.88.55	[]	2025-11-17 06:48:57	2025-11-17 06:48:57
43	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works	GET	185.155.88.55	[]	2025-11-17 06:48:57	2025-11-17 06:48:57
44	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/shifts	GET	185.155.88.55	[]	2025-11-17 06:49:08	2025-11-17 06:49:08
45	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works	GET	185.155.88.55	[]	2025-11-17 06:49:14	2025-11-17 06:49:14
46	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works	GET	185.155.88.55	[]	2025-11-17 06:49:14	2025-11-17 06:49:14
47	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works	GET	185.155.88.55	[]	2025-11-17 06:49:15	2025-11-17 06:49:15
48	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works	GET	185.155.88.55	[]	2025-11-17 06:49:15	2025-11-17 06:49:15
49	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works	GET	185.155.88.55	[]	2025-11-17 06:49:15	2025-11-17 06:49:15
50	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works	GET	185.155.88.55	[]	2025-11-17 06:49:15	2025-11-17 06:49:15
51	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works	GET	185.155.88.55	[]	2025-11-17 06:49:15	2025-11-17 06:49:15
52	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works	GET	185.155.88.55	[]	2025-11-17 06:49:15	2025-11-17 06:49:15
53	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works	GET	185.155.88.55	[]	2025-11-17 06:49:15	2025-11-17 06:49:15
54	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works	GET	185.155.88.55	[]	2025-11-17 06:49:16	2025-11-17 06:49:16
55	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works	GET	185.155.88.55	[]	2025-11-17 06:49:16	2025-11-17 06:49:16
56	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works	GET	185.155.88.55	[]	2025-11-17 06:49:16	2025-11-17 06:49:16
57	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works	GET	185.155.88.55	[]	2025-11-17 06:49:16	2025-11-17 06:49:16
58	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works	GET	185.155.88.55	[]	2025-11-17 06:49:16	2025-11-17 06:49:16
59	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works	GET	185.155.88.55	[]	2025-11-17 06:49:16	2025-11-17 06:49:16
60	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works	GET	185.155.88.55	[]	2025-11-17 06:49:16	2025-11-17 06:49:16
61	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works	GET	185.155.88.55	[]	2025-11-17 06:49:17	2025-11-17 06:49:17
62	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works	GET	185.155.88.55	[]	2025-11-17 06:49:17	2025-11-17 06:49:17
63	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works	GET	185.155.88.55	[]	2025-11-17 06:49:17	2025-11-17 06:49:17
64	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works	GET	185.155.88.55	[]	2025-11-17 06:49:17	2025-11-17 06:49:17
65	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works	GET	185.155.88.55	[]	2025-11-17 06:49:17	2025-11-17 06:49:17
66	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	185.155.88.55	[]	2025-11-17 06:49:21	2025-11-17 06:49:21
67	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments	GET	185.155.88.55	[]	2025-11-17 06:49:34	2025-11-17 06:49:34
68	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments	GET	185.155.88.55	[]	2025-11-17 06:49:43	2025-11-17 06:49:43
69	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments/create	GET	185.155.88.55	[]	2025-11-17 07:25:04	2025-11-17 07:25:04
70	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk	GET	185.155.88.55	[]	2025-11-17 08:00:48	2025-11-17 08:00:48
71	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments	GET	185.155.88.55	[]	2025-11-17 08:00:52	2025-11-17 08:00:52
72	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments/create	GET	185.155.88.55	[]	2025-11-17 08:00:56	2025-11-17 08:00:56
73	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments	POST	185.155.88.55	{"name":"\\u0417\\u0430\\u0433\\u043e\\u0442\\u043e\\u0432\\u043a\\u0438","short_name":"MDL","chat_id":null,"report_type_id":null,"search_terms":null,"_token":"fsBgOxKLCmZdNnMzOrxxCSZueIseDd04eiuLucED"}	2025-11-17 08:01:14	2025-11-17 08:01:14
74	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments	GET	185.155.88.55	[]	2025-11-17 08:01:14	2025-11-17 08:01:14
75	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments/create	GET	185.155.88.55	[]	2025-11-17 08:01:17	2025-11-17 08:01:17
76	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments	POST	185.155.88.55	{"name":"\\u0417\\u0431\\u0456\\u0440\\u043a\\u0430 \\u0440\\u0430\\u043c\\u0438","short_name":"FR","chat_id":null,"report_type_id":null,"search_terms":null,"_token":"fsBgOxKLCmZdNnMzOrxxCSZueIseDd04eiuLucED"}	2025-11-17 08:01:38	2025-11-17 08:01:38
77	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments	GET	185.155.88.55	[]	2025-11-17 08:01:38	2025-11-17 08:01:38
78	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments/create	GET	185.155.88.55	[]	2025-11-17 08:01:41	2025-11-17 08:01:41
79	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments	POST	185.155.88.55	{"name":"ESC","short_name":"ESC","chat_id":null,"report_type_id":null,"search_terms":null,"_token":"fsBgOxKLCmZdNnMzOrxxCSZueIseDd04eiuLucED"}	2025-11-17 08:01:54	2025-11-17 08:01:54
80	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments	GET	185.155.88.55	[]	2025-11-17 08:01:54	2025-11-17 08:01:54
81	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments/create	GET	185.155.88.55	[]	2025-11-17 08:01:57	2025-11-17 08:01:57
82	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments	POST	185.155.88.55	{"name":"FC","short_name":"FC","chat_id":null,"report_type_id":null,"search_terms":null,"_token":"fsBgOxKLCmZdNnMzOrxxCSZueIseDd04eiuLucED"}	2025-11-17 08:02:07	2025-11-17 08:02:07
83	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments	GET	185.155.88.55	[]	2025-11-17 08:02:08	2025-11-17 08:02:08
84	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments/create	GET	185.155.88.55	[]	2025-11-17 08:02:09	2025-11-17 08:02:09
85	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments	POST	185.155.88.55	{"name":"\\u0424\\u0456\\u043d\\u0430\\u043b\\u044c\\u043d\\u0430 \\u0437\\u0431\\u0456\\u0440\\u043a\\u0430","short_name":"FIN","chat_id":null,"report_type_id":null,"search_terms":null,"_token":"fsBgOxKLCmZdNnMzOrxxCSZueIseDd04eiuLucED"}	2025-11-17 08:02:40	2025-11-17 08:02:40
86	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments	GET	185.155.88.55	[]	2025-11-17 08:02:40	2025-11-17 08:02:40
87	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments/create	GET	185.155.88.55	[]	2025-11-17 08:02:43	2025-11-17 08:02:43
88	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments	POST	185.155.88.55	{"name":"\\u0422\\u0435\\u0441\\u0442\\u0443\\u0432\\u0430\\u043d\\u043d\\u044f","short_name":"TST","chat_id":null,"report_type_id":null,"search_terms":null,"_token":"fsBgOxKLCmZdNnMzOrxxCSZueIseDd04eiuLucED"}	2025-11-17 08:02:57	2025-11-17 08:02:57
89	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments	GET	185.155.88.55	[]	2025-11-17 08:02:58	2025-11-17 08:02:58
90	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments/create	GET	185.155.88.55	[]	2025-11-17 08:03:01	2025-11-17 08:03:01
91	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments	POST	185.155.88.55	{"name":"\\u041e\\u0431\\u043b\\u0456\\u0442","short_name":"FLT","chat_id":null,"report_type_id":null,"search_terms":null,"_token":"fsBgOxKLCmZdNnMzOrxxCSZueIseDd04eiuLucED"}	2025-11-17 08:03:22	2025-11-17 08:03:22
92	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments	GET	185.155.88.55	[]	2025-11-17 08:03:22	2025-11-17 08:03:22
93	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments/create	GET	185.155.88.55	[]	2025-11-17 08:03:25	2025-11-17 08:03:25
94	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments	POST	185.155.88.55	{"name":"\\u041f\\u0430\\u043a\\u0443\\u0432\\u0430\\u043d\\u043d\\u044f","short_name":"PAC","chat_id":null,"report_type_id":null,"search_terms":null,"_token":"fsBgOxKLCmZdNnMzOrxxCSZueIseDd04eiuLucED"}	2025-11-17 08:03:51	2025-11-17 08:03:51
95	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments	GET	185.155.88.55	[]	2025-11-17 08:03:51	2025-11-17 08:03:51
96	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	185.155.88.55	[]	2025-11-17 08:04:04	2025-11-17 08:04:04
1030	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk	GET	82.193.98.50	[]	2025-11-27 14:47:51	2025-11-27 14:47:51
97	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	185.155.88.55	[]	2025-11-17 08:05:18	2025-11-17 08:05:18
98	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	185.155.88.55	{"name":"\\u041d\\u0430\\u043b\\u0430\\u0448\\u0442\\u0443\\u0432\\u0430\\u043d\\u043d\\u044f \\u0441\\u0435\\u0440\\u0432\\u043e.  SP","description":null,"department_id":"1","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":"0","_token":"fsBgOxKLCmZdNnMzOrxxCSZueIseDd04eiuLucED"}	2025-11-17 08:09:35	2025-11-17 08:09:35
99	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	185.155.88.55	[]	2025-11-17 08:09:35	2025-11-17 08:09:35
100	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	185.155.88.55	[]	2025-11-17 08:09:37	2025-11-17 08:09:37
101	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	185.155.88.55	{"name":"\\u0417\\u0431\\u0456\\u0440\\u043a\\u0430 \\u0433\\u0456\\u043c\\u0431\\u0430\\u043b\\u0443 SP","description":null,"department_id":"1","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":"0","_token":"fsBgOxKLCmZdNnMzOrxxCSZueIseDd04eiuLucED"}	2025-11-17 08:09:48	2025-11-17 08:09:48
102	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	185.155.88.55	[]	2025-11-17 08:09:48	2025-11-17 08:09:48
103	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	185.155.88.55	[]	2025-11-17 08:10:23	2025-11-17 08:10:23
104	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	185.155.88.55	{"name":"\\u0422\\u0435\\u0441\\u0442\\u0443\\u0432\\u0430\\u043d\\u043d\\u044f \\u0433\\u0456\\u043c\\u0431\\u0430\\u043b\\u0443 SP","description":null,"department_id":"1","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":"0","_token":"fsBgOxKLCmZdNnMzOrxxCSZueIseDd04eiuLucED"}	2025-11-17 08:10:30	2025-11-17 08:10:30
105	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	185.155.88.55	[]	2025-11-17 08:10:31	2025-11-17 08:10:31
106	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	185.155.88.55	[]	2025-11-17 08:10:58	2025-11-17 08:10:58
107	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	185.155.88.55	{"name":"\\u0417\\u0431\\u0456\\u0440\\u043a\\u0430 \\u043e\\u0431\\u0442\\u0456\\u043a\\u0430\\u0447\\u0430 SP","description":null,"department_id":"1","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":"0","_token":"fsBgOxKLCmZdNnMzOrxxCSZueIseDd04eiuLucED"}	2025-11-17 08:11:27	2025-11-17 08:11:27
108	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	185.155.88.55	[]	2025-11-17 08:11:27	2025-11-17 08:11:27
109	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	185.155.88.55	[]	2025-11-17 08:11:56	2025-11-17 08:11:56
110	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	185.155.88.55	{"name":"\\u0412\\u0441\\u0442\\u0430\\u043d\\u043e\\u0432\\u043b\\u0435\\u043d\\u043d\\u044f \\u043a\\u0440\\u0438\\u043b SP","description":null,"department_id":"1","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":"0","_token":"fsBgOxKLCmZdNnMzOrxxCSZueIseDd04eiuLucED"}	2025-11-17 08:12:03	2025-11-17 08:12:03
111	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	185.155.88.55	[]	2025-11-17 08:12:03	2025-11-17 08:12:03
112	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	185.155.88.55	[]	2025-11-17 08:12:32	2025-11-17 08:12:32
113	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	185.155.88.55	{"name":"\\u041f\\u0456\\u0434\\u0433\\u043e\\u0442\\u043e\\u0432\\u043a\\u0430 \\u043a\\u0440\\u0438\\u0448\\u043a\\u0438  SP","description":null,"department_id":"1","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":"0","_token":"fsBgOxKLCmZdNnMzOrxxCSZueIseDd04eiuLucED"}	2025-11-17 08:12:45	2025-11-17 08:12:45
114	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	185.155.88.55	[]	2025-11-17 08:12:45	2025-11-17 08:12:45
115	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	185.155.88.55	[]	2025-11-17 08:13:07	2025-11-17 08:13:07
116	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	185.155.88.55	{"name":"\\u041f\\u043e\\u043a\\u043b\\u0435\\u0439\\u043a\\u0430 \\u0441\\u0438\\u043b\\u0456\\u043a. \\u0441\\u043a\\u043e\\u0442\\u0447\\u0443 SP","description":null,"department_id":"1","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":"0","_token":"fsBgOxKLCmZdNnMzOrxxCSZueIseDd04eiuLucED"}	2025-11-17 08:13:40	2025-11-17 08:13:40
117	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	185.155.88.55	[]	2025-11-17 08:13:40	2025-11-17 08:13:40
118	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	185.155.88.55	[]	2025-11-17 08:14:04	2025-11-17 08:14:04
119	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	185.155.88.55	{"name":"\\u0412\\u0441\\u0442\\u0430\\u043d\\u043e\\u0432\\u043b\\u0435\\u043d\\u043d\\u044f \\u043a\\u0440\\u0438\\u043b SP","description":null,"department_id":"1","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":"0","_token":"fsBgOxKLCmZdNnMzOrxxCSZueIseDd04eiuLucED"}	2025-11-17 08:14:12	2025-11-17 08:14:12
120	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	185.155.88.55	[]	2025-11-17 08:14:13	2025-11-17 08:14:13
121	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/8/edit	GET	185.155.88.55	[]	2025-11-17 08:14:52	2025-11-17 08:14:52
122	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/8	DELETE	185.155.88.55	{"_method":"delete","_token":"fsBgOxKLCmZdNnMzOrxxCSZueIseDd04eiuLucED"}	2025-11-17 08:14:58	2025-11-17 08:14:58
123	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	185.155.88.55	[]	2025-11-17 08:14:59	2025-11-17 08:14:59
124	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	185.155.88.55	[]	2025-11-17 08:39:20	2025-11-17 08:39:20
125	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	185.155.88.55	{"name":"\\u0417\\u0431\\u0456\\u0440\\u043a\\u0430 \\u0440\\u0430\\u043c\\u0438 SP","description":null,"department_id":"2","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":"0","_token":"fsBgOxKLCmZdNnMzOrxxCSZueIseDd04eiuLucED"}	2025-11-17 08:39:31	2025-11-17 08:39:31
126	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	185.155.88.55	[]	2025-11-17 08:39:31	2025-11-17 08:39:31
127	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	185.155.88.55	[]	2025-11-17 08:39:49	2025-11-17 08:39:49
128	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	185.155.88.55	{"name":"\\u041a\\u0440\\u0456\\u043f\\u043b\\u0435\\u043d\\u043d\\u044f \\u0434\\u0440\\u043e\\u0442\\u0456\\u0432 \\u0456\\u0437\\u043e\\u043b\\u0435\\u043d\\u0442\\u043e\\u044e SP","description":null,"department_id":"2","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":"0","_token":"fsBgOxKLCmZdNnMzOrxxCSZueIseDd04eiuLucED"}	2025-11-17 08:40:01	2025-11-17 08:40:01
129	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	185.155.88.55	[]	2025-11-17 08:40:02	2025-11-17 08:40:02
130	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	185.155.88.55	[]	2025-11-17 08:40:22	2025-11-17 08:40:22
199	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	185.155.88.55	[]	2025-11-17 10:35:09	2025-11-17 10:35:09
131	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	185.155.88.55	{"name":"\\u041c\\u043e\\u043d\\u0442\\u0430\\u0436 \\u043c\\u043e\\u0442\\u043e\\u0440\\u0456\\u0432 SP","description":null,"department_id":"2","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":"0","_token":"fsBgOxKLCmZdNnMzOrxxCSZueIseDd04eiuLucED"}	2025-11-17 08:40:30	2025-11-17 08:40:30
132	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	185.155.88.55	[]	2025-11-17 08:40:30	2025-11-17 08:40:30
133	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	185.155.88.55	[]	2025-11-17 08:40:54	2025-11-17 08:40:54
134	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	185.155.88.55	{"name":"\\u041c\\u043e\\u043d\\u0442\\u0430\\u0436 \\u043f\\u043b\\u0430\\u0441\\u0442\\u0438\\u043a\\u0443 \\u043d\\u0430 \\u0440\\u0430\\u043c\\u0443 SP","description":null,"department_id":"2","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":"0","_token":"fsBgOxKLCmZdNnMzOrxxCSZueIseDd04eiuLucED"}	2025-11-17 08:41:01	2025-11-17 08:41:01
135	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	185.155.88.55	[]	2025-11-17 08:41:01	2025-11-17 08:41:01
136	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	185.155.88.55	[]	2025-11-17 08:42:24	2025-11-17 08:42:24
137	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	185.155.88.55	{"name":"\\u041d\\u0430\\u0440\\u0456\\u0437\\u043a\\u0430 \\u0441\\u0438\\u043b\\u043e\\u0432\\u043e\\u0433\\u043e \\u043a\\u0430\\u0431\\u0435\\u043b\\u044e","description":null,"department_id":"3","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":"0","_token":"fsBgOxKLCmZdNnMzOrxxCSZueIseDd04eiuLucED"}	2025-11-17 08:42:36	2025-11-17 08:42:36
138	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	185.155.88.55	[]	2025-11-17 08:42:36	2025-11-17 08:42:36
139	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	185.155.88.55	[]	2025-11-17 08:58:26	2025-11-17 08:58:26
140	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	185.155.88.55	{"name":"\\u041c\\u043e\\u043d\\u0442\\u0430\\u0436 ESC-12S","description":null,"department_id":"3","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":"0","_token":"fsBgOxKLCmZdNnMzOrxxCSZueIseDd04eiuLucED"}	2025-11-17 08:58:39	2025-11-17 08:58:39
141	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	185.155.88.55	[]	2025-11-17 08:58:39	2025-11-17 08:58:39
142	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	185.155.88.55	[]	2025-11-17 08:58:58	2025-11-17 08:58:58
143	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	185.155.88.55	{"name":"\\u041f\\u0430\\u0439\\u043a\\u0430 XT90","description":null,"department_id":"3","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":"0","_token":"fsBgOxKLCmZdNnMzOrxxCSZueIseDd04eiuLucED"}	2025-11-17 08:59:08	2025-11-17 08:59:08
144	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	185.155.88.55	[]	2025-11-17 08:59:08	2025-11-17 08:59:08
145	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	185.155.88.55	[]	2025-11-17 08:59:22	2025-11-17 08:59:22
146	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	185.155.88.55	{"name":"\\u041f\\u0456\\u0434\\u0433\\u043e\\u0442\\u043e\\u0432\\u043a\\u0430 ESC-12S","description":null,"department_id":"3","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":"0","_token":"fsBgOxKLCmZdNnMzOrxxCSZueIseDd04eiuLucED"}	2025-11-17 08:59:30	2025-11-17 08:59:30
147	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	185.155.88.55	[]	2025-11-17 08:59:30	2025-11-17 08:59:30
148	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	185.155.88.55	[]	2025-11-17 09:13:44	2025-11-17 09:13:44
149	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	185.155.88.55	{"name":"\\u041f\\u0456\\u0434\\u0433\\u043e\\u0442\\u043e\\u0432\\u043a\\u0430 \\u0434\\u0440\\u043e\\u0442\\u0456\\u0432 \\u043a\\u043d\\u043e\\u043f\\u043a\\u0438","description":null,"department_id":"4","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":"0","_token":"fsBgOxKLCmZdNnMzOrxxCSZueIseDd04eiuLucED"}	2025-11-17 09:14:12	2025-11-17 09:14:12
150	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	185.155.88.55	[]	2025-11-17 09:14:13	2025-11-17 09:14:13
151	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	185.155.88.55	[]	2025-11-17 09:14:14	2025-11-17 09:14:14
152	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	185.155.88.55	{"name":"\\u041f\\u0456\\u0434\\u0433\\u043e\\u0442\\u043e\\u0432\\u043a\\u0430 \\u0434\\u0440\\u043e\\u0442\\u0456\\u0432 \\u043a\\u043b\\u0435\\u043c\\u043d\\u0438\\u043a\\u0430","description":null,"department_id":"4","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":"0","_token":"fsBgOxKLCmZdNnMzOrxxCSZueIseDd04eiuLucED"}	2025-11-17 09:14:32	2025-11-17 09:14:32
153	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	185.155.88.55	[]	2025-11-17 09:14:32	2025-11-17 09:14:32
154	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	185.155.88.55	[]	2025-11-17 09:14:34	2025-11-17 09:14:34
155	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	185.155.88.55	{"name":"\\u041f\\u0456\\u0434\\u0433\\u043e\\u0442\\u043e\\u0432\\u043a\\u0430 \\u041f\\u0406 \\u0434\\u043e \\u043f\\u0430\\u0439\\u043a\\u0438","description":null,"department_id":"4","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":"0","_token":"fsBgOxKLCmZdNnMzOrxxCSZueIseDd04eiuLucED"}	2025-11-17 09:15:11	2025-11-17 09:15:11
156	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	185.155.88.55	[]	2025-11-17 09:15:11	2025-11-17 09:15:11
157	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	185.155.88.55	[]	2025-11-17 09:15:20	2025-11-17 09:15:20
158	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	185.155.88.55	{"name":"\\u041f\\u0430\\u0439\\u043a\\u0430 \\u0434\\u0440\\u043e\\u0442\\u0456\\u0432 \\u0441\\u0435\\u0440\\u0432\\u043e","description":null,"department_id":"4","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":"0","_token":"fsBgOxKLCmZdNnMzOrxxCSZueIseDd04eiuLucED"}	2025-11-17 09:15:53	2025-11-17 09:15:53
159	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	185.155.88.55	[]	2025-11-17 09:15:53	2025-11-17 09:15:53
160	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	185.155.88.55	[]	2025-11-17 09:15:55	2025-11-17 09:15:55
161	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	185.155.88.55	{"name":"\\u0413\\u0435\\u0440\\u043c\\u0435\\u0442\\u0438\\u0437\\u0430\\u0446\\u0456\\u044f \\u041f\\u0406","description":null,"department_id":"4","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":"0","_token":"fsBgOxKLCmZdNnMzOrxxCSZueIseDd04eiuLucED"}	2025-11-17 09:16:22	2025-11-17 09:16:22
162	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	185.155.88.55	[]	2025-11-17 09:16:22	2025-11-17 09:16:22
163	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	185.155.88.55	[]	2025-11-17 09:17:26	2025-11-17 09:17:26
269	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.157	[]	2025-11-18 09:56:31	2025-11-18 09:56:31
164	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	185.155.88.55	{"name":"\\u041f\\u0456\\u0434\\u043a\\u043b\\u044e\\u0447\\u0435\\u043d\\u043d\\u044f \\u0433\\u0456\\u043c\\u0431\\u0430\\u043b\\u0443","description":null,"department_id":"4","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":"0","_token":"fsBgOxKLCmZdNnMzOrxxCSZueIseDd04eiuLucED"}	2025-11-17 09:17:47	2025-11-17 09:17:47
165	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	185.155.88.55	[]	2025-11-17 09:17:47	2025-11-17 09:17:47
166	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	185.155.88.55	[]	2025-11-17 09:18:08	2025-11-17 09:18:08
167	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	185.155.88.55	{"name":"\\u041f\\u0456\\u0434\\u0433\\u043e\\u0442\\u043e\\u0432\\u043a\\u0430 \\u0456\\u0437\\u043e\\u043b\\u044f\\u0446\\u0456\\u0457","description":null,"department_id":"4","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":"0","_token":"fsBgOxKLCmZdNnMzOrxxCSZueIseDd04eiuLucED"}	2025-11-17 09:18:44	2025-11-17 09:18:44
168	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	185.155.88.55	[]	2025-11-17 09:18:44	2025-11-17 09:18:44
169	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	185.155.88.55	[]	2025-11-17 09:19:07	2025-11-17 09:19:07
170	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	185.155.88.55	{"name":"\\u041d\\u0430\\u043b\\u0430\\u0448\\u0442\\u0443\\u0432\\u0430\\u043d\\u043d\\u044f DC\\/DC","description":null,"department_id":"4","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":"0","_token":"fsBgOxKLCmZdNnMzOrxxCSZueIseDd04eiuLucED"}	2025-11-17 09:19:13	2025-11-17 09:19:13
171	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	185.155.88.55	[]	2025-11-17 09:19:13	2025-11-17 09:19:13
172	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	185.155.88.55	[]	2025-11-17 09:19:35	2025-11-17 09:19:35
173	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	185.155.88.55	{"name":"\\u041d\\u0430\\u043f\\u0430\\u0439\\u043a\\u0430 \\u0434\\u0440\\u043e\\u0441\\u0435\\u043b\\u044f VTX","description":null,"department_id":"4","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":"0","_token":"fsBgOxKLCmZdNnMzOrxxCSZueIseDd04eiuLucED"}	2025-11-17 09:20:46	2025-11-17 09:20:46
174	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	185.155.88.55	[]	2025-11-17 09:20:46	2025-11-17 09:20:46
175	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	185.155.88.55	[]	2025-11-17 09:21:01	2025-11-17 09:21:01
176	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	185.155.88.55	{"name":"\\u041f\\u0430\\u0439\\u043a\\u0430 \\u041f\\u0406 \\u0434\\u043e FC SP","description":null,"department_id":"4","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":"0","_token":"fsBgOxKLCmZdNnMzOrxxCSZueIseDd04eiuLucED"}	2025-11-17 09:21:20	2025-11-17 09:21:20
177	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	185.155.88.55	[]	2025-11-17 09:21:20	2025-11-17 09:21:20
178	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	185.155.88.55	[]	2025-11-17 09:21:40	2025-11-17 09:21:40
179	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	185.155.88.55	{"name":"\\u041f\\u0430\\u0439\\u043a\\u0430 \\u041f\\u0406 SP","description":null,"department_id":"4","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":"0","_token":"fsBgOxKLCmZdNnMzOrxxCSZueIseDd04eiuLucED"}	2025-11-17 09:21:50	2025-11-17 09:21:50
180	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	185.155.88.55	[]	2025-11-17 09:21:50	2025-11-17 09:21:50
181	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	185.155.88.55	[]	2025-11-17 09:22:31	2025-11-17 09:22:31
182	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	185.155.88.55	{"name":"\\u041f\\u0430\\u0439\\u043a\\u0430 \\u0440\\u043e\\u0437'\\u0454\\u043c\\u0443 \\u0441\\u0435\\u0440\\u0432\\u043e SP","description":null,"department_id":"4","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":"0","_token":"fsBgOxKLCmZdNnMzOrxxCSZueIseDd04eiuLucED"}	2025-11-17 09:22:47	2025-11-17 09:22:47
183	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	185.155.88.55	[]	2025-11-17 09:22:47	2025-11-17 09:22:47
184	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	185.155.88.55	[]	2025-11-17 09:23:05	2025-11-17 09:23:05
185	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	185.155.88.55	[]	2025-11-17 09:25:25	2025-11-17 09:25:25
186	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	185.155.88.55	{"name":"\\u041f\\u0430\\u0439\\u043a\\u0430 \\u0448\\u043b\\u0435\\u0439\\u0444\\u0456\\u0432 \\u0434\\u043e FC SP","description":null,"department_id":"4","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":"0","_token":"fsBgOxKLCmZdNnMzOrxxCSZueIseDd04eiuLucED"}	2025-11-17 09:26:07	2025-11-17 09:26:07
187	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	185.155.88.55	[]	2025-11-17 09:26:07	2025-11-17 09:26:07
188	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/1/edit	GET	185.155.88.55	[]	2025-11-17 09:26:19	2025-11-17 09:26:19
189	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	185.155.88.55	[]	2025-11-17 09:26:27	2025-11-17 09:26:27
190	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	185.155.88.55	[]	2025-11-17 09:26:29	2025-11-17 09:26:29
191	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	185.155.88.55	{"name":"\\u041f\\u0456\\u0434\\u0433\\u043e\\u0442\\u043e\\u0432\\u043a\\u0430 \\u0442\\u0430 \\u043f\\u0430\\u0439\\u043a\\u0430 ELRS SP","description":null,"department_id":"4","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":"0","_token":"fsBgOxKLCmZdNnMzOrxxCSZueIseDd04eiuLucED"}	2025-11-17 09:50:52	2025-11-17 09:50:52
192	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	185.155.88.55	[]	2025-11-17 09:50:53	2025-11-17 09:50:53
193	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	185.155.88.55	[]	2025-11-17 09:51:27	2025-11-17 09:51:27
194	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	185.155.88.55	{"name":"\\u041f\\u0456\\u0434\\u0433\\u043e\\u0442\\u0443\\u0432\\u0430\\u043d\\u043d\\u044f DC\\/DC SP","description":null,"department_id":"4","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":"0","_token":"fsBgOxKLCmZdNnMzOrxxCSZueIseDd04eiuLucED"}	2025-11-17 09:51:45	2025-11-17 09:51:45
195	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	185.155.88.55	[]	2025-11-17 09:51:45	2025-11-17 09:51:45
196	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	185.155.88.55	[]	2025-11-17 09:54:22	2025-11-17 09:54:22
197	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	185.155.88.55	{"name":"\\u041f\\u043e\\u0434\\u043e\\u0432\\u0436\\u0435\\u043d\\u043d\\u044f \\u0448\\u043b\\u0435\\u0439\\u0444\\u0443 \\u043a\\u0430\\u043c\\u0435\\u0440\\u0438","description":null,"department_id":"4","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":"0","_token":"fsBgOxKLCmZdNnMzOrxxCSZueIseDd04eiuLucED"}	2025-11-17 09:54:36	2025-11-17 09:54:36
198	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	185.155.88.55	[]	2025-11-17 09:54:36	2025-11-17 09:54:36
200	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	185.155.88.55	{"name":"\\u041c\\u043e\\u043d\\u0442\\u0430\\u0436 \\u0442\\u0440\\u0443\\u0431\\u043e\\u043a \\u0442\\u0430 \\u043e\\u0431\\u0442\\u0456\\u043a\\u0430\\u0447\\u0456\\u0432 \\u043f\\u0440\\u043e\\u043c. SP","description":null,"department_id":"5","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":"0","_token":"fsBgOxKLCmZdNnMzOrxxCSZueIseDd04eiuLucED"}	2025-11-17 10:35:40	2025-11-17 10:35:40
201	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	185.155.88.55	[]	2025-11-17 10:35:41	2025-11-17 10:35:41
202	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	185.155.88.55	[]	2025-11-17 10:35:53	2025-11-17 10:35:53
203	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	185.155.88.55	{"name":"\\u0411\\u0430\\u0437\\u043e\\u0432\\u0430 \\u0437\\u0431\\u0456\\u0440\\u043a\\u0430 SP","description":null,"department_id":"5","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":"0","_token":"fsBgOxKLCmZdNnMzOrxxCSZueIseDd04eiuLucED"}	2025-11-17 10:36:00	2025-11-17 10:36:00
204	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	185.155.88.55	[]	2025-11-17 10:36:00	2025-11-17 10:36:00
205	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	185.155.88.55	[]	2025-11-17 10:36:25	2025-11-17 10:36:25
206	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	185.155.88.55	{"name":"\\u041c\\u043e\\u043d\\u0442\\u0430\\u0436 \\u043d\\u0438\\u0436\\u043d\\u044c\\u043e\\u0433\\u043e \\u0442\\u0430 \\u0432\\u0435\\u0440\\u0445\\u043d\\u044c\\u043e\\u0433\\u043e \\u043e\\u0431\\u0442\\u0456\\u043a\\u0430\\u0447\\u0430 SP","description":null,"department_id":"5","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":"0","_token":"fsBgOxKLCmZdNnMzOrxxCSZueIseDd04eiuLucED"}	2025-11-17 10:36:32	2025-11-17 10:36:32
207	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	185.155.88.55	[]	2025-11-17 10:36:32	2025-11-17 10:36:32
208	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	185.155.88.55	[]	2025-11-17 10:37:16	2025-11-17 10:37:16
209	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	185.155.88.55	{"name":"\\u041c\\u043e\\u043d\\u0442\\u0430\\u0436 \\u043f\\u0440\\u043e\\u043f\\u0435\\u043b\\u0435\\u0440\\u0456\\u0432 SP","description":null,"department_id":"5","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":"0","_token":"fsBgOxKLCmZdNnMzOrxxCSZueIseDd04eiuLucED"}	2025-11-17 10:37:23	2025-11-17 10:37:23
210	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	185.155.88.55	[]	2025-11-17 10:37:24	2025-11-17 10:37:24
211	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/14/edit	GET	185.155.88.55	[]	2025-11-17 10:59:22	2025-11-17 10:59:22
212	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/14	PUT	185.155.88.55	{"name":"\\u041c\\u043e\\u043d\\u0442\\u0430\\u0436 ESC-12S SP","description":null,"department_id":"3","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":null,"_token":"fsBgOxKLCmZdNnMzOrxxCSZueIseDd04eiuLucED","_method":"PUT"}	2025-11-17 10:59:31	2025-11-17 10:59:31
213	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	185.155.88.55	[]	2025-11-17 10:59:32	2025-11-17 10:59:32
214	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/15/edit	GET	185.155.88.55	[]	2025-11-17 10:59:42	2025-11-17 10:59:42
215	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/15	PUT	185.155.88.55	{"name":"\\u041f\\u0430\\u0439\\u043a\\u0430 XT90 SP","description":null,"department_id":"3","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":null,"_token":"fsBgOxKLCmZdNnMzOrxxCSZueIseDd04eiuLucED","_method":"PUT"}	2025-11-17 10:59:50	2025-11-17 10:59:50
216	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	185.155.88.55	[]	2025-11-17 10:59:50	2025-11-17 10:59:50
217	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/16/edit	GET	185.155.88.55	[]	2025-11-17 11:00:00	2025-11-17 11:00:00
218	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/16	PUT	185.155.88.55	{"name":"\\u041f\\u0456\\u0434\\u0433\\u043e\\u0442\\u043e\\u0432\\u043a\\u0430 ESC-12S SP","description":null,"department_id":"3","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":null,"_token":"fsBgOxKLCmZdNnMzOrxxCSZueIseDd04eiuLucED","_method":"PUT"}	2025-11-17 11:00:07	2025-11-17 11:00:07
219	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	185.155.88.55	[]	2025-11-17 11:00:07	2025-11-17 11:00:07
220	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/19/edit	GET	185.155.88.55	[]	2025-11-17 11:00:21	2025-11-17 11:00:21
221	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/19	PUT	185.155.88.55	{"name":"\\u041f\\u0456\\u0434\\u0433\\u043e\\u0442\\u043e\\u0432\\u043a\\u0430 \\u041f\\u0406 \\u0434\\u043e \\u043f\\u0430\\u0439\\u043a\\u0438 SP","description":null,"department_id":"4","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":null,"_token":"fsBgOxKLCmZdNnMzOrxxCSZueIseDd04eiuLucED","_method":"PUT"}	2025-11-17 11:00:28	2025-11-17 11:00:28
222	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	185.155.88.55	[]	2025-11-17 11:00:29	2025-11-17 11:00:29
223	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/20/edit	GET	185.155.88.55	[]	2025-11-17 11:00:37	2025-11-17 11:00:37
224	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/20	PUT	185.155.88.55	{"name":"\\u041f\\u0430\\u0439\\u043a\\u0430 \\u0434\\u0440\\u043e\\u0442\\u0456\\u0432 \\u0441\\u0435\\u0440\\u0432\\u043e SP","description":null,"department_id":"4","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":null,"_token":"fsBgOxKLCmZdNnMzOrxxCSZueIseDd04eiuLucED","_method":"PUT"}	2025-11-17 11:00:49	2025-11-17 11:00:49
225	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	185.155.88.55	[]	2025-11-17 11:00:49	2025-11-17 11:00:49
226	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/22/edit	GET	185.155.88.55	[]	2025-11-17 11:01:02	2025-11-17 11:01:02
227	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/22	PUT	185.155.88.55	{"name":"\\u041f\\u0456\\u0434\\u043a\\u043b\\u044e\\u0447\\u0435\\u043d\\u043d\\u044f \\u0433\\u0456\\u043c\\u0431\\u0430\\u043b\\u0443 SP","description":null,"department_id":"4","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":null,"_token":"fsBgOxKLCmZdNnMzOrxxCSZueIseDd04eiuLucED","_method":"PUT"}	2025-11-17 11:01:08	2025-11-17 11:01:08
228	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	185.155.88.55	[]	2025-11-17 11:01:08	2025-11-17 11:01:08
229	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	185.155.88.55	[]	2025-11-17 11:07:40	2025-11-17 11:07:40
230	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	185.155.88.55	{"name":"\\u041f\\u0440\\u043e\\u0448\\u0438\\u0432\\u043a\\u0430\\/\\u0442\\u0435\\u0441\\u0442 SP","description":null,"department_id":"6","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":"0","_token":"fsBgOxKLCmZdNnMzOrxxCSZueIseDd04eiuLucED"}	2025-11-17 11:08:08	2025-11-17 11:08:08
231	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	185.155.88.55	[]	2025-11-17 11:08:08	2025-11-17 11:08:08
232	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	185.155.88.55	[]	2025-11-17 11:08:29	2025-11-17 11:08:29
233	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	185.155.88.55	{"name":"\\u041e\\u0431\\u043b\\u0456\\u0442 SP","description":null,"department_id":"7","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":"0","_token":"fsBgOxKLCmZdNnMzOrxxCSZueIseDd04eiuLucED"}	2025-11-17 11:08:47	2025-11-17 11:08:47
234	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	185.155.88.55	[]	2025-11-17 11:08:48	2025-11-17 11:08:48
235	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	185.155.88.55	[]	2025-11-17 11:08:49	2025-11-17 11:08:49
236	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	185.155.88.55	{"name":"\\u0422\\u0435\\u0441\\u0442 \\u041f\\u0406 Popcorn","description":null,"department_id":"7","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":"0","_token":"fsBgOxKLCmZdNnMzOrxxCSZueIseDd04eiuLucED"}	2025-11-17 11:09:13	2025-11-17 11:09:13
237	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	185.155.88.55	[]	2025-11-17 11:09:13	2025-11-17 11:09:13
238	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	185.155.88.55	[]	2025-11-17 11:10:01	2025-11-17 11:10:01
239	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	185.155.88.55	{"name":"\\u0417\\u043d\\u044f\\u0442\\u0442\\u044f \\u043f\\u0440\\u043e\\u043f\\u0435\\u043b\\u0435\\u0440\\u0456\\u0432","description":null,"department_id":"8","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":"0","_token":"fsBgOxKLCmZdNnMzOrxxCSZueIseDd04eiuLucED"}	2025-11-17 11:10:09	2025-11-17 11:10:09
240	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	185.155.88.55	[]	2025-11-17 11:10:09	2025-11-17 11:10:09
241	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	185.155.88.55	[]	2025-11-17 11:10:30	2025-11-17 11:10:30
242	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	185.155.88.55	{"name":"\\u0417\\u0431\\u0456\\u0440\\u043a\\u0430 \\u043a\\u043e\\u0440\\u043e\\u0431\\u043a\\u0438 SP","description":null,"department_id":"8","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":"0","_token":"fsBgOxKLCmZdNnMzOrxxCSZueIseDd04eiuLucED"}	2025-11-17 11:10:38	2025-11-17 11:10:38
243	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	185.155.88.55	[]	2025-11-17 11:10:39	2025-11-17 11:10:39
244	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	185.155.88.55	[]	2025-11-17 11:11:22	2025-11-17 11:11:22
245	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	185.155.88.55	{"name":"\\u041f\\u0435\\u0440\\u0435\\u0432\\u0456\\u0440\\u043a\\u0430 SP","description":null,"department_id":"8","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":"0","_token":"fsBgOxKLCmZdNnMzOrxxCSZueIseDd04eiuLucED"}	2025-11-17 11:11:33	2025-11-17 11:11:33
246	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	185.155.88.55	[]	2025-11-17 11:11:33	2025-11-17 11:11:33
247	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	185.155.88.55	[]	2025-11-17 11:11:54	2025-11-17 11:11:54
248	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	185.155.88.55	{"name":"\\u041f\\u0430\\u043a\\u0443\\u0432\\u0430\\u043d\\u043d\\u044f SP","description":null,"department_id":"8","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":"0","_token":"fsBgOxKLCmZdNnMzOrxxCSZueIseDd04eiuLucED"}	2025-11-17 11:12:14	2025-11-17 11:12:14
249	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	185.155.88.55	[]	2025-11-17 11:12:14	2025-11-17 11:12:14
250	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	185.155.88.55	{"_export_":"all"}	2025-11-17 11:18:09	2025-11-17 11:18:09
251	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk	GET	185.155.88.55	[]	2025-11-17 14:17:40	2025-11-17 14:17:40
252	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	185.155.88.55	[]	2025-11-17 14:17:42	2025-11-17 14:17:42
253	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	185.155.88.55	[]	2025-11-17 14:17:44	2025-11-17 14:17:44
254	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	185.155.88.55	{"name":"\\u041f\\u0430\\u0439\\u043a\\u0430 Type-C\\" SP","description":null,"department_id":"4","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":"0","_token":"Gyk6yKZmCKZlkNt20u40oQ4OikF6Cc2EJ8bGqFtK"}	2025-11-17 14:18:23	2025-11-17 14:18:23
255	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	185.155.88.55	[]	2025-11-17 14:18:23	2025-11-17 14:18:23
256	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/44/edit	GET	185.155.88.55	[]	2025-11-17 14:18:30	2025-11-17 14:18:30
257	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/44	PUT	185.155.88.55	{"name":"\\u041f\\u0430\\u0439\\u043a\\u0430 Type-C SP","description":null,"department_id":"4","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":null,"_token":"Gyk6yKZmCKZlkNt20u40oQ4OikF6Cc2EJ8bGqFtK","_method":"PUT"}	2025-11-17 14:18:36	2025-11-17 14:18:36
258	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	185.155.88.55	[]	2025-11-17 14:18:37	2025-11-17 14:18:37
259	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/20/edit	GET	185.155.88.55	[]	2025-11-17 14:19:05	2025-11-17 14:19:05
260	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/20	PUT	185.155.88.55	{"name":"\\u041f\\u0430\\u0439\\u043a\\u0430 \\u0434\\u0440\\u043e\\u0442\\u0456\\u0432 \\u0441\\u0435\\u0440\\u0432\\u043e FC SP","description":null,"department_id":"4","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":null,"_token":"Gyk6yKZmCKZlkNt20u40oQ4OikF6Cc2EJ8bGqFtK","_method":"PUT"}	2025-11-17 14:19:16	2025-11-17 14:19:16
261	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	185.155.88.55	[]	2025-11-17 14:19:16	2025-11-17 14:19:16
262	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk	GET	94.176.198.157	[]	2025-11-18 09:56:07	2025-11-18 09:56:07
263	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.157	[]	2025-11-18 09:56:09	2025-11-18 09:56:09
264	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/1/edit	GET	94.176.198.157	[]	2025-11-18 09:56:12	2025-11-18 09:56:12
265	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/1	PUT	94.176.198.157	{"name":"\\u041d\\u0430\\u043b\\u0430\\u0448\\u0442\\u0443\\u0432\\u0430\\u043d\\u043d\\u044f \\u0441\\u0435\\u0440\\u0432\\u043e.  SL","description":null,"department_id":"1","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":null,"_token":"uOwtSCuY88jHmS8AFx03SynGUgc2GctqoK86xBr1","_method":"PUT"}	2025-11-18 09:56:23	2025-11-18 09:56:23
266	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.157	[]	2025-11-18 09:56:23	2025-11-18 09:56:23
267	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/2/edit	GET	94.176.198.157	[]	2025-11-18 09:56:26	2025-11-18 09:56:26
268	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/2	PUT	94.176.198.157	{"name":"\\u0417\\u0431\\u0456\\u0440\\u043a\\u0430 \\u0433\\u0456\\u043c\\u0431\\u0430\\u043b\\u0443 SL","description":null,"department_id":"1","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":null,"_token":"uOwtSCuY88jHmS8AFx03SynGUgc2GctqoK86xBr1","_method":"PUT"}	2025-11-18 09:56:31	2025-11-18 09:56:31
270	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/3/edit	GET	94.176.198.157	[]	2025-11-18 09:56:34	2025-11-18 09:56:34
271	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/3	PUT	94.176.198.157	{"name":"\\u0422\\u0435\\u0441\\u0442\\u0443\\u0432\\u0430\\u043d\\u043d\\u044f \\u0433\\u0456\\u043c\\u0431\\u0430\\u043b\\u0443 SL","description":null,"department_id":"1","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":null,"_token":"uOwtSCuY88jHmS8AFx03SynGUgc2GctqoK86xBr1","_method":"PUT"}	2025-11-18 09:56:40	2025-11-18 09:56:40
272	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.157	[]	2025-11-18 09:56:40	2025-11-18 09:56:40
273	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/4/edit	GET	94.176.198.157	[]	2025-11-18 09:56:44	2025-11-18 09:56:44
274	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/4	PUT	94.176.198.157	{"name":"\\u0417\\u0431\\u0456\\u0440\\u043a\\u0430 \\u043e\\u0431\\u0442\\u0456\\u043a\\u0430\\u0447\\u0430 SL","description":null,"department_id":"1","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":null,"_token":"uOwtSCuY88jHmS8AFx03SynGUgc2GctqoK86xBr1","_method":"PUT"}	2025-11-18 09:56:49	2025-11-18 09:56:49
275	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.157	[]	2025-11-18 09:56:49	2025-11-18 09:56:49
276	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/5/edit	GET	94.176.198.157	[]	2025-11-18 09:56:52	2025-11-18 09:56:52
277	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/5	PUT	94.176.198.157	{"name":"\\u0412\\u0441\\u0442\\u0430\\u043d\\u043e\\u0432\\u043b\\u0435\\u043d\\u043d\\u044f \\u043a\\u0440\\u0438\\u043b SL","description":null,"department_id":"1","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":null,"_token":"uOwtSCuY88jHmS8AFx03SynGUgc2GctqoK86xBr1","_method":"PUT"}	2025-11-18 09:56:59	2025-11-18 09:56:59
278	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.157	[]	2025-11-18 09:56:59	2025-11-18 09:56:59
279	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/6/edit	GET	94.176.198.157	[]	2025-11-18 09:57:02	2025-11-18 09:57:02
280	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/6	PUT	94.176.198.157	{"name":"\\u041f\\u0456\\u0434\\u0433\\u043e\\u0442\\u043e\\u0432\\u043a\\u0430 \\u043a\\u0440\\u0438\\u0448\\u043a\\u0438  SL","description":null,"department_id":"1","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":null,"_token":"uOwtSCuY88jHmS8AFx03SynGUgc2GctqoK86xBr1","_method":"PUT"}	2025-11-18 09:57:07	2025-11-18 09:57:07
281	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.157	[]	2025-11-18 09:57:08	2025-11-18 09:57:08
282	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/7/edit	GET	94.176.198.157	[]	2025-11-18 09:57:11	2025-11-18 09:57:11
283	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/7	PUT	94.176.198.157	{"name":"\\u041f\\u043e\\u043a\\u043b\\u0435\\u0439\\u043a\\u0430 \\u0441\\u0438\\u043b\\u0456\\u043a. \\u0441\\u043a\\u043e\\u0442\\u0447\\u0443 SL","description":null,"department_id":"1","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":null,"_token":"uOwtSCuY88jHmS8AFx03SynGUgc2GctqoK86xBr1","_method":"PUT"}	2025-11-18 09:57:16	2025-11-18 09:57:16
284	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.157	[]	2025-11-18 09:57:16	2025-11-18 09:57:16
285	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/9/edit	GET	94.176.198.157	[]	2025-11-18 09:57:19	2025-11-18 09:57:19
286	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/9	PUT	94.176.198.157	{"name":"\\u0417\\u0431\\u0456\\u0440\\u043a\\u0430 \\u0440\\u0430\\u043c\\u0438 SL","description":null,"department_id":"2","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":null,"_token":"uOwtSCuY88jHmS8AFx03SynGUgc2GctqoK86xBr1","_method":"PUT"}	2025-11-18 09:57:24	2025-11-18 09:57:24
287	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.157	[]	2025-11-18 09:57:24	2025-11-18 09:57:24
288	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/10/edit	GET	94.176.198.157	[]	2025-11-18 09:57:27	2025-11-18 09:57:27
289	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/10	PUT	94.176.198.157	{"name":"\\u041a\\u0440\\u0456\\u043f\\u043b\\u0435\\u043d\\u043d\\u044f \\u0434\\u0440\\u043e\\u0442\\u0456\\u0432 \\u0456\\u0437\\u043e\\u043b\\u0435\\u043d\\u0442\\u043e\\u044e SL","description":null,"department_id":"2","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":null,"_token":"uOwtSCuY88jHmS8AFx03SynGUgc2GctqoK86xBr1","_method":"PUT"}	2025-11-18 09:57:33	2025-11-18 09:57:33
290	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.157	[]	2025-11-18 09:57:33	2025-11-18 09:57:33
291	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/11/edit	GET	94.176.198.157	[]	2025-11-18 09:57:38	2025-11-18 09:57:38
292	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/11	PUT	94.176.198.157	{"name":"\\u041c\\u043e\\u043d\\u0442\\u0430\\u0436 \\u043c\\u043e\\u0442\\u043e\\u0440\\u0456\\u0432 SL","description":null,"department_id":"2","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":null,"_token":"uOwtSCuY88jHmS8AFx03SynGUgc2GctqoK86xBr1","_method":"PUT"}	2025-11-18 09:57:42	2025-11-18 09:57:42
293	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.157	[]	2025-11-18 09:57:42	2025-11-18 09:57:42
294	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/12/edit	GET	94.176.198.157	[]	2025-11-18 09:57:48	2025-11-18 09:57:48
295	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/12	PUT	94.176.198.157	{"name":"\\u041c\\u043e\\u043d\\u0442\\u0430\\u0436 \\u043f\\u043b\\u0430\\u0441\\u0442\\u0438\\u043a\\u0443 \\u043d\\u0430 \\u0440\\u0430\\u043c\\u0443 SL","description":null,"department_id":"2","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":null,"_token":"uOwtSCuY88jHmS8AFx03SynGUgc2GctqoK86xBr1","_method":"PUT"}	2025-11-18 09:57:52	2025-11-18 09:57:52
296	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.157	[]	2025-11-18 09:57:53	2025-11-18 09:57:53
297	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/14/edit	GET	94.176.198.157	[]	2025-11-18 09:57:59	2025-11-18 09:57:59
298	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/14	PUT	94.176.198.157	{"name":"\\u041c\\u043e\\u043d\\u0442\\u0430\\u0436 ESC-12S SL","description":null,"department_id":"3","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":null,"_token":"uOwtSCuY88jHmS8AFx03SynGUgc2GctqoK86xBr1","_method":"PUT"}	2025-11-18 09:58:04	2025-11-18 09:58:04
299	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.157	[]	2025-11-18 09:58:04	2025-11-18 09:58:04
300	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/15/edit	GET	94.176.198.157	[]	2025-11-18 09:58:09	2025-11-18 09:58:09
301	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/15	PUT	94.176.198.157	{"name":"\\u041f\\u0430\\u0439\\u043a\\u0430 XT90 SL","description":null,"department_id":"3","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":null,"_token":"uOwtSCuY88jHmS8AFx03SynGUgc2GctqoK86xBr1","_method":"PUT"}	2025-11-18 09:58:13	2025-11-18 09:58:13
302	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.157	[]	2025-11-18 09:58:14	2025-11-18 09:58:14
303	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/16/edit	GET	94.176.198.157	[]	2025-11-18 09:58:19	2025-11-18 09:58:19
304	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/16	PUT	94.176.198.157	{"name":"\\u041f\\u0456\\u0434\\u0433\\u043e\\u0442\\u043e\\u0432\\u043a\\u0430 ESC-12S SL","description":null,"department_id":"3","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":null,"_token":"uOwtSCuY88jHmS8AFx03SynGUgc2GctqoK86xBr1","_method":"PUT"}	2025-11-18 09:58:24	2025-11-18 09:58:24
305	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.157	[]	2025-11-18 09:58:24	2025-11-18 09:58:24
306	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/19/edit	GET	94.176.198.157	[]	2025-11-18 09:58:28	2025-11-18 09:58:28
307	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/19	PUT	94.176.198.157	{"name":"\\u041f\\u0456\\u0434\\u0433\\u043e\\u0442\\u043e\\u0432\\u043a\\u0430 \\u041f\\u0406 \\u0434\\u043e \\u043f\\u0430\\u0439\\u043a\\u0438 SL","description":null,"department_id":"4","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":null,"_token":"uOwtSCuY88jHmS8AFx03SynGUgc2GctqoK86xBr1","_method":"PUT"}	2025-11-18 09:58:33	2025-11-18 09:58:33
308	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.157	[]	2025-11-18 09:58:33	2025-11-18 09:58:33
309	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/20/edit	GET	94.176.198.157	[]	2025-11-18 09:58:39	2025-11-18 09:58:39
310	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/20	PUT	94.176.198.157	{"name":"\\u041f\\u0430\\u0439\\u043a\\u0430 \\u0434\\u0440\\u043e\\u0442\\u0456\\u0432 \\u0441\\u0435\\u0440\\u0432\\u043e FC SL","description":null,"department_id":"4","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":null,"_token":"uOwtSCuY88jHmS8AFx03SynGUgc2GctqoK86xBr1","_method":"PUT"}	2025-11-18 09:58:44	2025-11-18 09:58:44
311	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.157	[]	2025-11-18 09:58:44	2025-11-18 09:58:44
312	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/22/edit	GET	94.176.198.157	[]	2025-11-18 09:58:50	2025-11-18 09:58:50
313	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/22	PUT	94.176.198.157	{"name":"\\u041f\\u0456\\u0434\\u043a\\u043b\\u044e\\u0447\\u0435\\u043d\\u043d\\u044f \\u0433\\u0456\\u043c\\u0431\\u0430\\u043b\\u0443 SL","description":null,"department_id":"4","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":null,"_token":"uOwtSCuY88jHmS8AFx03SynGUgc2GctqoK86xBr1","_method":"PUT"}	2025-11-18 09:58:55	2025-11-18 09:58:55
314	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.157	[]	2025-11-18 09:58:55	2025-11-18 09:58:55
315	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/26/edit	GET	94.176.198.157	[]	2025-11-18 09:59:03	2025-11-18 09:59:03
316	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/26	PUT	94.176.198.157	{"name":"\\u041f\\u0430\\u0439\\u043a\\u0430 \\u041f\\u0406 \\u0434\\u043e FC SL","description":null,"department_id":"4","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":null,"_token":"uOwtSCuY88jHmS8AFx03SynGUgc2GctqoK86xBr1","_method":"PUT"}	2025-11-18 09:59:07	2025-11-18 09:59:07
317	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.157	[]	2025-11-18 09:59:07	2025-11-18 09:59:07
318	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/28/edit	GET	94.176.198.157	[]	2025-11-18 09:59:41	2025-11-18 09:59:41
319	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/28	PUT	94.176.198.157	{"name":"\\u041f\\u0430\\u0439\\u043a\\u0430 \\u0440\\u043e\\u0437'\\u0454\\u043c\\u0443 \\u0441\\u0435\\u0440\\u0432\\u043e SL","description":null,"department_id":"4","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":null,"_token":"uOwtSCuY88jHmS8AFx03SynGUgc2GctqoK86xBr1","_method":"PUT"}	2025-11-18 09:59:47	2025-11-18 09:59:47
320	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.157	[]	2025-11-18 09:59:47	2025-11-18 09:59:47
321	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/29/edit	GET	94.176.198.157	[]	2025-11-18 09:59:51	2025-11-18 09:59:51
322	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/29	PUT	94.176.198.157	{"name":"\\u041f\\u0430\\u0439\\u043a\\u0430 \\u0448\\u043b\\u0435\\u0439\\u0444\\u0456\\u0432 \\u0434\\u043e FC SL","description":null,"department_id":"4","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":null,"_token":"uOwtSCuY88jHmS8AFx03SynGUgc2GctqoK86xBr1","_method":"PUT"}	2025-11-18 09:59:56	2025-11-18 09:59:56
323	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.157	[]	2025-11-18 09:59:56	2025-11-18 09:59:56
324	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/30/edit	GET	94.176.198.157	[]	2025-11-18 10:00:01	2025-11-18 10:00:01
325	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/30	PUT	94.176.198.157	{"name":"\\u041f\\u0456\\u0434\\u0433\\u043e\\u0442\\u043e\\u0432\\u043a\\u0430 \\u0442\\u0430 \\u043f\\u0430\\u0439\\u043a\\u0430 ELRS SL","description":null,"department_id":"4","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":null,"_token":"uOwtSCuY88jHmS8AFx03SynGUgc2GctqoK86xBr1","_method":"PUT"}	2025-11-18 10:00:05	2025-11-18 10:00:05
326	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.157	[]	2025-11-18 10:00:06	2025-11-18 10:00:06
327	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/31/edit	GET	94.176.198.157	[]	2025-11-18 10:00:11	2025-11-18 10:00:11
328	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/31	PUT	94.176.198.157	{"name":"\\u041f\\u0456\\u0434\\u0433\\u043e\\u0442\\u0443\\u0432\\u0430\\u043d\\u043d\\u044f DC\\/DC SL","description":null,"department_id":"4","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":null,"_token":"uOwtSCuY88jHmS8AFx03SynGUgc2GctqoK86xBr1","_method":"PUT"}	2025-11-18 10:00:15	2025-11-18 10:00:15
329	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.157	[]	2025-11-18 10:00:16	2025-11-18 10:00:16
330	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/33/edit	GET	94.176.198.157	[]	2025-11-18 10:00:21	2025-11-18 10:00:21
331	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/33	PUT	94.176.198.157	{"name":"\\u041c\\u043e\\u043d\\u0442\\u0430\\u0436 \\u0442\\u0440\\u0443\\u0431\\u043e\\u043a \\u0442\\u0430 \\u043e\\u0431\\u0442\\u0456\\u043a\\u0430\\u0447\\u0456\\u0432 \\u043f\\u0440\\u043e\\u043c. SL","description":null,"department_id":"5","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":null,"_token":"uOwtSCuY88jHmS8AFx03SynGUgc2GctqoK86xBr1","_method":"PUT"}	2025-11-18 10:00:30	2025-11-18 10:00:30
332	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.157	[]	2025-11-18 10:00:30	2025-11-18 10:00:30
333	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/34/edit	GET	94.176.198.157	[]	2025-11-18 10:00:35	2025-11-18 10:00:35
334	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/34	PUT	94.176.198.157	{"name":"\\u0411\\u0430\\u0437\\u043e\\u0432\\u0430 \\u0437\\u0431\\u0456\\u0440\\u043a\\u0430 SL","description":null,"department_id":"5","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":null,"_token":"uOwtSCuY88jHmS8AFx03SynGUgc2GctqoK86xBr1","_method":"PUT"}	2025-11-18 10:00:39	2025-11-18 10:00:39
335	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.157	[]	2025-11-18 10:00:40	2025-11-18 10:00:40
336	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/35/edit	GET	94.176.198.157	[]	2025-11-18 10:01:05	2025-11-18 10:01:05
337	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/35	PUT	94.176.198.157	{"name":"\\u041c\\u043e\\u043d\\u0442\\u0430\\u0436 \\u043d\\u0438\\u0436\\u043d\\u044c\\u043e\\u0433\\u043e \\u0442\\u0430 \\u0432\\u0435\\u0440\\u0445\\u043d\\u044c\\u043e\\u0433\\u043e \\u043e\\u0431\\u0442\\u0456\\u043a\\u0430\\u0447\\u0430 SL","description":null,"department_id":"5","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":null,"_token":"uOwtSCuY88jHmS8AFx03SynGUgc2GctqoK86xBr1","_method":"PUT"}	2025-11-18 10:01:11	2025-11-18 10:01:11
338	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.157	[]	2025-11-18 10:01:11	2025-11-18 10:01:11
339	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/36/edit	GET	94.176.198.157	[]	2025-11-18 10:01:29	2025-11-18 10:01:29
340	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/36	PUT	94.176.198.157	{"name":"\\u041c\\u043e\\u043d\\u0442\\u0430\\u0436 \\u043f\\u0440\\u043e\\u043f\\u0435\\u043b\\u0435\\u0440\\u0456\\u0432 SL","description":null,"department_id":"5","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":null,"_token":"uOwtSCuY88jHmS8AFx03SynGUgc2GctqoK86xBr1","_method":"PUT"}	2025-11-18 10:01:34	2025-11-18 10:01:34
341	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.157	[]	2025-11-18 10:01:34	2025-11-18 10:01:34
342	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/37/edit	GET	94.176.198.157	[]	2025-11-18 10:01:38	2025-11-18 10:01:38
343	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/37	PUT	94.176.198.157	{"name":"\\u041f\\u0440\\u043e\\u0448\\u0438\\u0432\\u043a\\u0430\\/\\u0442\\u0435\\u0441\\u0442 SL","description":null,"department_id":"6","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":null,"_token":"uOwtSCuY88jHmS8AFx03SynGUgc2GctqoK86xBr1","_method":"PUT"}	2025-11-18 10:01:43	2025-11-18 10:01:43
344	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.157	[]	2025-11-18 10:01:43	2025-11-18 10:01:43
345	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/38/edit	GET	94.176.198.157	[]	2025-11-18 10:01:47	2025-11-18 10:01:47
346	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/38	PUT	94.176.198.157	{"name":"\\u041e\\u0431\\u043b\\u0456\\u0442 SL","description":null,"department_id":"7","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":null,"_token":"uOwtSCuY88jHmS8AFx03SynGUgc2GctqoK86xBr1","_method":"PUT"}	2025-11-18 10:01:53	2025-11-18 10:01:53
347	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.157	[]	2025-11-18 10:01:53	2025-11-18 10:01:53
348	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/41/edit	GET	94.176.198.157	[]	2025-11-18 10:01:57	2025-11-18 10:01:57
349	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/41	PUT	94.176.198.157	{"name":"\\u0417\\u0431\\u0456\\u0440\\u043a\\u0430 \\u043a\\u043e\\u0440\\u043e\\u0431\\u043a\\u0438 SL","description":null,"department_id":"8","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":null,"_token":"uOwtSCuY88jHmS8AFx03SynGUgc2GctqoK86xBr1","_method":"PUT"}	2025-11-18 10:02:03	2025-11-18 10:02:03
350	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.157	[]	2025-11-18 10:02:03	2025-11-18 10:02:03
351	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/42/edit	GET	94.176.198.157	[]	2025-11-18 10:02:10	2025-11-18 10:02:10
352	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/42	PUT	94.176.198.157	{"name":"\\u041f\\u0435\\u0440\\u0435\\u0432\\u0456\\u0440\\u043a\\u0430 SL","description":null,"department_id":"8","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":null,"_token":"uOwtSCuY88jHmS8AFx03SynGUgc2GctqoK86xBr1","_method":"PUT"}	2025-11-18 10:02:15	2025-11-18 10:02:15
353	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.157	[]	2025-11-18 10:02:15	2025-11-18 10:02:15
354	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/43/edit	GET	94.176.198.157	[]	2025-11-18 10:02:20	2025-11-18 10:02:20
355	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/43	PUT	94.176.198.157	{"name":"\\u041f\\u0430\\u043a\\u0443\\u0432\\u0430\\u043d\\u043d\\u044f SL","description":null,"department_id":"8","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":null,"_token":"uOwtSCuY88jHmS8AFx03SynGUgc2GctqoK86xBr1","_method":"PUT"}	2025-11-18 10:02:25	2025-11-18 10:02:25
356	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.157	[]	2025-11-18 10:02:25	2025-11-18 10:02:25
357	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/44/edit	GET	94.176.198.157	[]	2025-11-18 10:02:28	2025-11-18 10:02:28
358	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/44	PUT	94.176.198.157	{"name":"\\u041f\\u0430\\u0439\\u043a\\u0430 Type-C SL","description":null,"department_id":"4","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":null,"_token":"uOwtSCuY88jHmS8AFx03SynGUgc2GctqoK86xBr1","_method":"PUT"}	2025-11-18 10:02:33	2025-11-18 10:02:33
359	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.157	[]	2025-11-18 10:02:33	2025-11-18 10:02:33
360	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	94.176.198.157	[]	2025-11-18 10:39:08	2025-11-18 10:39:08
361	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	94.176.198.157	{"name":"\\u041f\\u0456\\u0434\\u0433\\u043e\\u0442\\u043e\\u0432\\u043a\\u0430 \\u043f\\u043b\\u0430\\u0441\\u0442\\u0438\\u043a\\u0443 \\u0434\\u043b\\u044f \\u0440\\u0430\\u043c\\u0438 SL","description":null,"department_id":"2","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":"0","_token":"uOwtSCuY88jHmS8AFx03SynGUgc2GctqoK86xBr1"}	2025-11-18 10:39:32	2025-11-18 10:39:32
362	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.157	[]	2025-11-18 10:39:33	2025-11-18 10:39:33
363	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	94.176.198.157	[]	2025-11-18 10:39:35	2025-11-18 10:39:35
364	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.157	[]	2025-11-18 10:40:03	2025-11-18 10:40:03
365	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/41/edit	GET	94.176.198.157	[]	2025-11-18 10:46:57	2025-11-18 10:46:57
366	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/41	DELETE	94.176.198.157	{"_method":"delete","_token":"uOwtSCuY88jHmS8AFx03SynGUgc2GctqoK86xBr1"}	2025-11-18 10:47:05	2025-11-18 10:47:05
367	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.157	[]	2025-11-18 10:47:05	2025-11-18 10:47:05
368	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	94.176.198.157	[]	2025-11-18 10:47:45	2025-11-18 10:47:45
369	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	94.176.198.157	{"name":"\\u041c\\u043e\\u043d\\u0442\\u0430\\u0436 \\u0432\\u0456\\u0431\\u0440\\u043e\\u0433\\u0443\\u043c\\u043e\\u043a FC","description":null,"department_id":"1","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":"0","_token":"uOwtSCuY88jHmS8AFx03SynGUgc2GctqoK86xBr1"}	2025-11-18 10:48:15	2025-11-18 10:48:15
370	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.157	[]	2025-11-18 10:48:15	2025-11-18 10:48:15
371	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	94.176.198.157	[]	2025-11-18 10:48:28	2025-11-18 10:48:28
372	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	94.176.198.157	{"name":"\\u041c\\u043e\\u043d\\u0442\\u0430\\u0436 \\u0432\\u0456\\u0431\\u0440\\u043e\\u0433\\u0443\\u043c\\u043e\\u043a ESC","description":null,"department_id":"1","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":"0","_token":"uOwtSCuY88jHmS8AFx03SynGUgc2GctqoK86xBr1"}	2025-11-18 10:48:42	2025-11-18 10:48:42
373	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.157	[]	2025-11-18 10:48:42	2025-11-18 10:48:42
374	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	94.176.198.157	[]	2025-11-18 12:06:51	2025-11-18 12:06:51
375	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.157	[]	2025-11-18 12:07:14	2025-11-18 12:07:14
376	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.157	[]	2025-11-18 12:08:00	2025-11-18 12:08:00
377	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.157	[]	2025-11-18 12:08:18	2025-11-18 12:08:18
378	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.157	{"department_id":"1","search_terms":null,"id":null}	2025-11-18 12:08:31	2025-11-18 12:08:31
379	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.157	[]	2025-11-18 12:29:50	2025-11-18 12:29:50
380	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/38/edit	GET	94.176.198.157	[]	2025-11-18 12:30:00	2025-11-18 12:30:00
381	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/38	PUT	94.176.198.157	{"name":"\\u041e\\u0431\\u043b\\u0456\\u0442 \\u0437 \\u0430\\u0441\\u0438\\u0441\\u0442\\u0435\\u043d\\u0442\\u043e\\u043c SL","description":null,"department_id":"7","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":null,"_token":"f17NOjwKRWacUvjpO82V78MDcX2DF1OeMc9wG4C0","_method":"PUT"}	2025-11-18 12:30:27	2025-11-18 12:30:27
382	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.157	[]	2025-11-18 12:30:27	2025-11-18 12:30:27
383	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	94.176.198.157	[]	2025-11-19 09:25:27	2025-11-19 09:25:27
384	3	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk	GET	185.155.88.55	[]	2025-11-24 08:33:04	2025-11-24 08:33:04
385	3	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk	GET	185.155.88.55	[]	2025-11-24 08:33:38	2025-11-24 08:33:38
386	3	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	185.155.88.55	[]	2025-11-24 08:34:39	2025-11-24 08:34:39
387	3	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/workers	GET	185.155.88.55	[]	2025-11-24 08:34:50	2025-11-24 08:34:50
388	3	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments	GET	185.155.88.55	[]	2025-11-24 08:35:17	2025-11-24 08:35:17
389	3	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	185.155.88.55	[]	2025-11-24 08:35:39	2025-11-24 08:35:39
390	3	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	185.155.88.55	[]	2025-11-24 08:36:21	2025-11-24 08:36:21
391	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk	GET	82.193.98.50	[]	2025-11-24 09:09:14	2025-11-24 09:09:14
392	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-24 09:09:26	2025-11-24 09:09:26
393	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	82.193.98.50	[]	2025-11-24 09:09:44	2025-11-24 09:09:44
394	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk	GET	88.155.9.73	[]	2025-11-24 15:56:32	2025-11-24 15:56:32
395	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	88.155.9.73	[]	2025-11-24 15:57:13	2025-11-24 15:57:13
396	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	88.155.9.73	[]	2025-11-24 15:57:18	2025-11-24 15:57:18
397	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	88.155.9.73	[]	2025-11-24 15:57:25	2025-11-24 15:57:25
398	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	88.155.9.73	[]	2025-11-24 15:57:28	2025-11-24 15:57:28
399	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/auth/roles	GET	88.155.9.73	[]	2025-11-24 15:58:14	2025-11-24 15:58:14
400	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/auth/menu	GET	88.155.9.73	[]	2025-11-24 15:58:23	2025-11-24 15:58:23
401	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	88.155.9.73	[]	2025-11-24 15:58:27	2025-11-24 15:58:27
402	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	88.155.9.73	{"_columns_":"deflection,department,id,modules,name,time_norm_column"}	2025-11-24 15:58:56	2025-11-24 15:58:56
403	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/auth/users	GET	88.155.9.73	[]	2025-11-24 15:59:01	2025-11-24 15:59:01
404	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk	GET	193.239.153.169	[]	2025-11-24 16:27:25	2025-11-24 16:27:25
405	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	193.239.153.169	[]	2025-11-24 16:27:32	2025-11-24 16:27:32
406	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	193.239.153.169	[]	2025-11-24 16:27:34	2025-11-24 16:27:34
407	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	193.239.153.169	[]	2025-11-24 16:37:42	2025-11-24 16:37:42
408	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	193.239.153.169	[]	2025-11-24 16:40:12	2025-11-24 16:40:12
409	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	193.239.153.169	[]	2025-11-24 16:40:16	2025-11-24 16:40:16
410	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	193.239.153.169	[]	2025-11-24 16:40:20	2025-11-24 16:40:20
411	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments	GET	193.239.153.169	[]	2025-11-24 16:41:09	2025-11-24 16:41:09
412	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments/create	GET	193.239.153.169	[]	2025-11-24 16:41:13	2025-11-24 16:41:13
413	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments	POST	193.239.153.169	{"name":"\\u0406\\u043d\\u0448\\u0435","short_name":"\\u0406\\u043d\\u0448\\u0435","chat_id":null,"report_type_id":null,"search_terms":null,"_token":"EBfAKmAeJf4lBNhHSKtCaoJweR18Ied2wSDBrF8x"}	2025-11-24 16:41:26	2025-11-24 16:41:26
414	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments	GET	193.239.153.169	[]	2025-11-24 16:41:26	2025-11-24 16:41:26
415	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	193.239.153.169	[]	2025-11-24 16:41:35	2025-11-24 16:41:35
416	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	193.239.153.169	[]	2025-11-24 16:43:57	2025-11-24 16:43:57
417	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	193.239.153.169	[]	2025-11-24 16:46:08	2025-11-24 16:46:08
418	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	193.239.153.169	{"id_column":"900","name":"\\u041f\\u0435\\u0440\\u0435\\u0440\\u043e\\u0431\\u043a\\u0430","description":null,"department_id":"9","search_terms":null,"is_permitted":"1","norm_type":"1","multiplier_column":"1","in_archive":"0","_token":"EBfAKmAeJf4lBNhHSKtCaoJweR18Ied2wSDBrF8x"}	2025-11-24 16:47:54	2025-11-24 16:47:54
419	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	193.239.153.169	[]	2025-11-24 16:47:54	2025-11-24 16:47:54
420	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	193.239.153.169	[]	2025-11-24 16:47:59	2025-11-24 16:47:59
421	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	193.239.153.169	{"id_column":"901","name":"\\u0410\\u0434\\u043c\\u0456\\u043d \\u0440\\u043e\\u0431\\u043e\\u0442\\u0438","description":null,"department_id":"9","search_terms":null,"is_permitted":"1","norm_type":"1","multiplier_column":"1","in_archive":"0","_token":"EBfAKmAeJf4lBNhHSKtCaoJweR18Ied2wSDBrF8x"}	2025-11-24 16:48:15	2025-11-24 16:48:15
422	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	193.239.153.169	[]	2025-11-24 16:48:16	2025-11-24 16:48:16
423	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/auth/users	GET	193.239.153.169	[]	2025-11-24 18:12:45	2025-11-24 18:12:45
424	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/auth/users/create	GET	193.239.153.169	[]	2025-11-24 18:12:56	2025-11-24 18:12:56
425	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/auth/users	POST	193.239.153.169	{"username":"Mazur_Nika","name":"\\u041c\\u0430\\u0437\\u0443\\u0440 \\u0412\\u0456\\u043a\\u0442\\u043e\\u0440\\u0456\\u044f","password":"*****-filtered-out-*****","password_confirmation":"n762O5p65vyYrdK3vlqMijFfgArUe5","roles":["1",null],"search_terms":null,"permissions":["1",null],"_token":"EBfAKmAeJf4lBNhHSKtCaoJweR18Ied2wSDBrF8x"}	2025-11-24 18:17:13	2025-11-24 18:17:13
426	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/auth/users	GET	193.239.153.169	[]	2025-11-24 18:17:13	2025-11-24 18:17:13
427	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk	GET	95.164.41.61	[]	2025-11-24 18:18:51	2025-11-24 18:18:51
428	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	95.164.41.61	[]	2025-11-24 18:18:54	2025-11-24 18:18:54
429	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	95.164.41.61	[]	2025-11-24 18:19:07	2025-11-24 18:19:07
430	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	95.164.41.61	{"start_time":{"start":null,"end":null},"workDayDepartment":{"department_id":null},"search_terms":null,"worker_id":["959551233"]}	2025-11-24 18:19:26	2025-11-24 18:19:26
431	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	95.164.41.61	{"start_time":{"start":null,"end":null},"workDayDepartment":{"department_id":null},"search_terms":null,"worker_id":["1019196711"]}	2025-11-24 18:19:44	2025-11-24 18:19:44
432	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	95.164.41.61	{"start_time":{"start":null,"end":null},"workDayDepartment":{"department_id":null},"search_terms":null,"worker_id":["1019196711"]}	2025-11-24 18:19:46	2025-11-24 18:19:46
433	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.158	[]	2025-11-25 08:15:47	2025-11-25 08:15:47
434	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	94.176.198.158	[]	2025-11-25 08:15:49	2025-11-25 08:15:49
435	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	94.176.198.158	[]	2025-11-25 08:16:10	2025-11-25 08:16:10
436	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk	GET	94.176.198.158	[]	2025-11-25 08:26:31	2025-11-25 08:26:31
437	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.158	[]	2025-11-25 08:26:35	2025-11-25 08:26:35
438	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	94.176.198.158	[]	2025-11-25 08:26:38	2025-11-25 08:26:38
439	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk	GET	94.176.198.158	[]	2025-11-25 08:29:42	2025-11-25 08:29:42
440	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.158	[]	2025-11-25 08:29:44	2025-11-25 08:29:44
441	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	94.176.198.158	[]	2025-11-25 08:29:46	2025-11-25 08:29:46
442	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk	GET	82.193.98.50	[]	2025-11-25 09:59:46	2025-11-25 09:59:46
443	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works	GET	82.193.98.50	[]	2025-11-25 09:59:49	2025-11-25 09:59:49
444	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-25 09:59:50	2025-11-25 09:59:50
445	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk	GET	94.176.198.158	[]	2025-11-25 10:56:49	2025-11-25 10:56:49
446	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/workers	GET	94.176.198.158	[]	2025-11-25 10:57:10	2025-11-25 10:57:10
447	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/auth/users	GET	94.176.198.158	[]	2025-11-25 10:57:17	2025-11-25 10:57:17
448	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/auth/roles	GET	94.176.198.158	[]	2025-11-25 10:57:23	2025-11-25 10:57:23
449	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/auth/permissions	GET	94.176.198.158	[]	2025-11-25 10:57:27	2025-11-25 10:57:27
450	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/auth/menu	GET	94.176.198.158	[]	2025-11-25 10:57:32	2025-11-25 10:57:32
451	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/auth/users	GET	94.176.198.158	[]	2025-11-25 10:57:42	2025-11-25 10:57:42
452	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/auth/roles	GET	94.176.198.158	[]	2025-11-25 10:57:48	2025-11-25 10:57:48
453	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/auth/roles/2/edit	GET	94.176.198.158	[]	2025-11-25 10:57:52	2025-11-25 10:57:52
454	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/config	GET	94.176.198.158	[]	2025-11-25 10:58:04	2025-11-25 10:58:04
455	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/workers	GET	94.176.198.158	[]	2025-11-25 10:58:15	2025-11-25 10:58:15
456	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/workers/7495000901/edit	GET	94.176.198.158	[]	2025-11-25 10:58:23	2025-11-25 10:58:23
457	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments	GET	94.176.198.158	[]	2025-11-25 10:58:35	2025-11-25 10:58:35
458	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments/3/edit	GET	94.176.198.158	[]	2025-11-25 10:58:41	2025-11-25 10:58:41
459	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments	GET	94.176.198.158	[]	2025-11-25 10:59:32	2025-11-25 10:59:32
460	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/calculator	GET	94.176.198.158	[]	2025-11-25 10:59:45	2025-11-25 10:59:45
461	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/modules	GET	94.176.198.158	[]	2025-11-25 10:59:47	2025-11-25 10:59:47
462	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/workers	GET	94.176.198.158	[]	2025-11-25 10:59:49	2025-11-25 10:59:49
463	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/auth/roles	GET	94.176.198.158	[]	2025-11-25 10:59:56	2025-11-25 10:59:56
464	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/auth/users	GET	94.176.198.158	[]	2025-11-25 10:59:58	2025-11-25 10:59:58
465	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/auth/roles	GET	94.176.198.158	[]	2025-11-25 11:00:10	2025-11-25 11:00:10
466	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/auth/roles/2/edit	GET	94.176.198.158	[]	2025-11-25 11:00:16	2025-11-25 11:00:16
467	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/auth/roles	GET	94.176.198.158	[]	2025-11-25 11:00:21	2025-11-25 11:00:21
468	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/auth/menu	GET	94.176.198.158	[]	2025-11-25 11:00:25	2025-11-25 11:00:25
469	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.158	[]	2025-11-25 11:01:11	2025-11-25 11:01:11
470	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/workers	GET	94.176.198.158	[]	2025-11-25 11:01:37	2025-11-25 11:01:37
471	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/workers/7495000901/edit	GET	94.176.198.158	[]	2025-11-25 11:01:40	2025-11-25 11:01:40
472	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk	GET	82.193.98.50	[]	2025-11-25 11:06:26	2025-11-25 11:06:26
473	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-25 11:06:29	2025-11-25 11:06:29
474	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	82.193.98.50	[]	2025-11-25 11:11:39	2025-11-25 11:11:39
475	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	82.193.98.50	{"name":"209\\t\\u041c\\u043e\\u043d\\u0442\\u0430\\u0436 \\u043c\\u043e\\u0442\\u043e\\u0440\\u0456\\u0432 15\\"","description":null,"department_id":"2","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"370","in_archive":"0","_token":"6mQZyCKx7cHVKgrqkyqPIcYhBFK8bYQfQ45PWoAE"}	2025-11-25 11:13:47	2025-11-25 11:13:47
476	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-25 11:13:47	2025-11-25 11:13:47
477	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	82.193.98.50	[]	2025-11-25 11:14:00	2025-11-25 11:14:00
478	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	82.193.98.50	{"name":"208\\t\\u041f\\u043e\\u0432\\u043d\\u0430 \\u0437\\u0431\\u0456\\u0440\\u043a\\u0430 \\u0440\\u0430\\u043c\\u0438 15\\"","description":null,"department_id":"2","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"336","in_archive":"0","_token":"6mQZyCKx7cHVKgrqkyqPIcYhBFK8bYQfQ45PWoAE"}	2025-11-25 11:14:14	2025-11-25 11:14:14
479	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-25 11:14:14	2025-11-25 11:14:14
480	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	82.193.98.50	[]	2025-11-25 11:14:27	2025-11-25 11:14:27
481	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	82.193.98.50	{"name":"210\\t\\u041c\\u043e\\u043d\\u0442\\u0430\\u0436 \\u0441\\u0442\\u0456\\u0439\\u043e\\u043a 15\\"","description":null,"department_id":"2","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"115","in_archive":"0","_token":"6mQZyCKx7cHVKgrqkyqPIcYhBFK8bYQfQ45PWoAE"}	2025-11-25 11:14:46	2025-11-25 11:14:46
482	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-25 11:14:46	2025-11-25 11:14:46
483	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	82.193.98.50	[]	2025-11-25 11:14:48	2025-11-25 11:14:48
484	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	82.193.98.50	{"name":"317\\t\\u041f\\u0456\\u0434\\u0433\\u043e\\u0442\\u0443\\u0432\\u0430\\u043d\\u043d\\u044f \\u043c\\u043e\\u0442\\u043e\\u0440\\u0456\\u0432 15\\" \\u0431\\u0435\\u0437 \\u043a\\u0456\\u043b\\u044c\\u0446\\u044f","description":null,"department_id":"2","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"46","in_archive":"0","_token":"6mQZyCKx7cHVKgrqkyqPIcYhBFK8bYQfQ45PWoAE"}	2025-11-25 11:15:15	2025-11-25 11:15:15
485	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-25 11:15:16	2025-11-25 11:15:16
486	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	82.193.98.50	[]	2025-11-25 11:15:19	2025-11-25 11:15:19
487	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	82.193.98.50	{"name":"517\\t\\u041a\\u0440\\u0456\\u043f\\u043b\\u0435\\u043d\\u043d\\u044f \\u0434\\u0440\\u043e\\u0442\\u0456\\u0432 \\u0456\\u0437\\u043e\\u043b\\u0435\\u043d\\u0442\\u043e\\u044e 15\\"","description":null,"department_id":"2","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"220","in_archive":"0","_token":"6mQZyCKx7cHVKgrqkyqPIcYhBFK8bYQfQ45PWoAE"}	2025-11-25 11:15:42	2025-11-25 11:15:42
488	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-25 11:15:43	2025-11-25 11:15:43
489	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	82.193.98.50	[]	2025-11-25 11:15:52	2025-11-25 11:15:52
490	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	82.193.98.50	{"name":"473\\t\\u041b\\u0443\\u0434\\u0456\\u043d\\u043d\\u044f \\u043a\\u0430\\u0431\\u0435\\u043b\\u0456\\u0432","description":null,"department_id":"3","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"18","in_archive":"0","_token":"6mQZyCKx7cHVKgrqkyqPIcYhBFK8bYQfQ45PWoAE"}	2025-11-25 11:16:17	2025-11-25 11:16:17
491	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-25 11:16:17	2025-11-25 11:16:17
492	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/auth/logout	GET	82.193.98.50	[]	2025-11-25 11:19:29	2025-11-25 11:19:29
493	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk	GET	82.193.98.50	[]	2025-11-25 11:30:08	2025-11-25 11:30:08
494	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-25 11:30:12	2025-11-25 11:30:12
495	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	82.193.98.50	[]	2025-11-25 11:30:14	2025-11-25 11:30:14
496	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	82.193.98.50	{"name":"474\\t\\u041f\\u0430\\u0439\\u043a\\u0430 \\u0441\\u0438\\u043b\\u043e\\u0432\\u043e\\u0433\\u043e \\u0440\\u043e\\u0437'\\u0454\\u043c\\u0443 (\\u0431\\u0435\\u0437 \\u043b\\u0443\\u0434\\u0456\\u043d\\u043d\\u044f)","description":null,"department_id":"3","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"90","in_archive":"0","_token":"HRWvpXboCZQhASsugUdK1SEhIEblor1x4fj9hnKf"}	2025-11-25 11:30:46	2025-11-25 11:30:46
497	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-25 11:30:46	2025-11-25 11:30:46
498	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	82.193.98.50	[]	2025-11-25 11:31:00	2025-11-25 11:31:00
499	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	82.193.98.50	{"name":"62\\t\\u041d\\u0430\\u0440\\u0456\\u0437\\u043a\\u0430 \\u0441\\u0438\\u043b\\u043e\\u0432\\u043e\\u0433\\u043e \\u043a\\u0430\\u0431\\u0435\\u043b\\u044e","description":null,"department_id":"3","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"4","in_archive":"0","_token":"HRWvpXboCZQhASsugUdK1SEhIEblor1x4fj9hnKf"}	2025-11-25 11:31:16	2025-11-25 11:31:16
500	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-25 11:31:16	2025-11-25 11:31:16
501	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	82.193.98.50	[]	2025-11-25 11:31:27	2025-11-25 11:31:27
502	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	82.193.98.50	{"name":"525\\t\\u041f\\u0456\\u0434\\u0433\\u043e\\u0442\\u043e\\u0432\\u043a\\u0430 ESC-12S","description":null,"department_id":"3","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"360","in_archive":"0","_token":"HRWvpXboCZQhASsugUdK1SEhIEblor1x4fj9hnKf"}	2025-11-25 11:31:41	2025-11-25 11:31:41
503	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-25 11:31:41	2025-11-25 11:31:41
504	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	82.193.98.50	[]	2025-11-25 11:31:57	2025-11-25 11:31:57
538	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-25 11:39:45	2025-11-25 11:39:45
505	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	82.193.98.50	{"name":"526\\t15\\" \\u043c\\u043e\\u043d\\u0442\\u0430\\u0436 ESC-12S","description":null,"department_id":"3","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"660","in_archive":"0","_token":"HRWvpXboCZQhASsugUdK1SEhIEblor1x4fj9hnKf"}	2025-11-25 11:32:12	2025-11-25 11:32:12
506	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-25 11:32:12	2025-11-25 11:32:12
507	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	82.193.98.50	[]	2025-11-25 11:32:27	2025-11-25 11:32:27
508	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	82.193.98.50	{"name":"116\\t\\u041f\\u043e\\u0432\\u043d\\u0430 \\u0437\\u0431\\u0456\\u0440\\u043a\\u0430 \\u0431\\u0435\\u0437 \\u041f\\u0406","description":null,"department_id":"4","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"116","in_archive":"0","_token":"HRWvpXboCZQhASsugUdK1SEhIEblor1x4fj9hnKf"}	2025-11-25 11:32:38	2025-11-25 11:32:38
509	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-25 11:32:38	2025-11-25 11:32:38
510	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/58/edit	GET	82.193.98.50	[]	2025-11-25 11:33:04	2025-11-25 11:33:04
511	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/58	PUT	82.193.98.50	{"name":"116\\t\\u041f\\u043e\\u0432\\u043d\\u0430 \\u0437\\u0431\\u0456\\u0440\\u043a\\u0430 \\u0431\\u0435\\u0437 \\u041f\\u0406","description":null,"department_id":"4","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"271","in_archive":null,"_token":"HRWvpXboCZQhASsugUdK1SEhIEblor1x4fj9hnKf","_method":"PUT"}	2025-11-25 11:33:10	2025-11-25 11:33:10
512	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-25 11:33:10	2025-11-25 11:33:10
513	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	82.193.98.50	[]	2025-11-25 11:33:19	2025-11-25 11:33:19
514	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	82.193.98.50	{"name":"329\\t\\u041c\\u043e\\u043d\\u0442\\u0430\\u0436 \\u0432\\u0456\\u0431\\u0440\\u043e\\u0433\\u0443\\u043c\\u043e\\u043a \\u043d\\u0430 FC","description":null,"department_id":"1","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"29","in_archive":"0","_token":"HRWvpXboCZQhASsugUdK1SEhIEblor1x4fj9hnKf"}	2025-11-25 11:33:53	2025-11-25 11:33:53
515	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-25 11:33:53	2025-11-25 11:33:53
516	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	82.193.98.50	[]	2025-11-25 11:34:03	2025-11-25 11:34:03
517	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	82.193.98.50	{"name":"113\\t\\u041c\\u043e\\u043d\\u0442\\u0430\\u0436 \\u0432\\u0456\\u0431\\u0440\\u043e\\u0433\\u0443\\u043c\\u043e\\u043a \\u043d\\u0430 ESC","description":null,"department_id":"1","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"31","in_archive":"0","_token":"HRWvpXboCZQhASsugUdK1SEhIEblor1x4fj9hnKf"}	2025-11-25 11:34:20	2025-11-25 11:34:20
518	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-25 11:34:20	2025-11-25 11:34:20
519	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	82.193.98.50	[]	2025-11-25 11:34:33	2025-11-25 11:34:33
520	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-25 11:35:06	2025-11-25 11:35:06
521	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	82.193.98.50	[]	2025-11-25 11:35:08	2025-11-25 11:35:08
522	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	82.193.98.50	{"name":"252\\t\\u041c\\u043e\\u043d\\u0442\\u0430\\u0436 \\u043f\\u0440\\u043e\\u043f\\u0435\\u043b\\u0435\\u0440\\u0456\\u0432 \\u043d\\u0430 15\\"","description":null,"department_id":"5","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"281","in_archive":"0","_token":"HRWvpXboCZQhASsugUdK1SEhIEblor1x4fj9hnKf"}	2025-11-25 11:35:47	2025-11-25 11:35:47
523	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-25 11:35:47	2025-11-25 11:35:47
524	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	82.193.98.50	[]	2025-11-25 11:35:56	2025-11-25 11:35:56
525	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	82.193.98.50	{"name":"581\\t\\u0411\\u0430\\u0437\\u043e\\u0432\\u0430 \\u0437\\u0431\\u0456\\u0440\\u043a\\u0430 15\\" \\u0431\\u0435\\u0437 \\u041a\\u041c V2","description":null,"department_id":"5","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"660","in_archive":"0","_token":"HRWvpXboCZQhASsugUdK1SEhIEblor1x4fj9hnKf"}	2025-11-25 11:36:10	2025-11-25 11:36:10
526	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-25 11:36:11	2025-11-25 11:36:11
527	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	82.193.98.50	[]	2025-11-25 11:36:22	2025-11-25 11:36:22
528	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	82.193.98.50	{"name":"516\\t15\\" \\u0441\\u0442\\u0435\\u043a+\\u043a\\u0440\\u0438\\u0448\\u043a\\u0430+\\u0442\\u0435\\u043a\\u0441\\u0442\\u043e\\u043b\\u0456\\u0442","description":null,"department_id":"5","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"182","in_archive":"0","_token":"HRWvpXboCZQhASsugUdK1SEhIEblor1x4fj9hnKf"}	2025-11-25 11:36:39	2025-11-25 11:36:39
529	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-25 11:36:39	2025-11-25 11:36:39
530	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	82.193.98.50	[]	2025-11-25 11:36:55	2025-11-25 11:36:55
531	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	82.193.98.50	{"name":"253\\t\\u041f\\u0440\\u043e\\u0448\\u0438\\u0432\\u043a\\u0430\\/bind\\/\\u0442\\u0435\\u0441\\u0442 15\\"","description":null,"department_id":"6","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"378","in_archive":"0","_token":"HRWvpXboCZQhASsugUdK1SEhIEblor1x4fj9hnKf"}	2025-11-25 11:37:09	2025-11-25 11:37:09
532	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-25 11:37:10	2025-11-25 11:37:10
533	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	82.193.98.50	[]	2025-11-25 11:37:16	2025-11-25 11:37:16
534	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	82.193.98.50	{"name":"284\\t\\u0412\\u0438\\u0440\\u0456\\u0439\\/\\u0414\\u0436\\u043e\\u043d\\u043d\\u0456 15\\" \\u0437 \\u0430\\u0441\\u0438\\u0441\\u0442\\u0435\\u043d\\u0442\\u043e\\u043c","description":null,"department_id":"7","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"242","in_archive":"0","_token":"HRWvpXboCZQhASsugUdK1SEhIEblor1x4fj9hnKf"}	2025-11-25 11:39:20	2025-11-25 11:39:20
535	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-25 11:39:20	2025-11-25 11:39:20
536	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	82.193.98.50	[]	2025-11-25 11:39:32	2025-11-25 11:39:32
537	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	82.193.98.50	{"name":"487\\t\\u0423\\u043f\\u0430\\u043a\\u043e\\u0432\\u043a\\u0430 \\u0433\\u0440\\u0443\\u043f. \\u043a\\u043e\\u0440\\u043e\\u0431\\u043a\\u0438 15\\u2019\\u2019","description":null,"department_id":"8","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"220","in_archive":"0","_token":"HRWvpXboCZQhASsugUdK1SEhIEblor1x4fj9hnKf"}	2025-11-25 11:39:45	2025-11-25 11:39:45
539	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	82.193.98.50	[]	2025-11-25 11:40:03	2025-11-25 11:40:03
540	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	82.193.98.50	{"name":"411\\t\\u0414\\u0435\\u043c\\u043e\\u043d\\u0442\\u0430\\u0436 \\u043f\\u0440\\u043e\\u043f\\u0456\\u0432 15\\"","description":null,"department_id":"5","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"140","in_archive":"0","_token":"HRWvpXboCZQhASsugUdK1SEhIEblor1x4fj9hnKf"}	2025-11-25 11:40:21	2025-11-25 11:40:21
541	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-25 11:40:21	2025-11-25 11:40:21
542	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	82.193.98.50	[]	2025-11-25 11:40:49	2025-11-25 11:40:49
543	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	82.193.98.50	{"name":"452\\t\\u041c\\u043e\\u043d\\u0442\\u0430\\u0436 InfiRay 640 \\u043d\\u0430 \\u043a\\u0440\\u043e\\u043d\\u0448\\u0442\\u0435\\u0439\\u043d","description":null,"department_id":"1","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"52","in_archive":"0","_token":"HRWvpXboCZQhASsugUdK1SEhIEblor1x4fj9hnKf"}	2025-11-25 11:41:08	2025-11-25 11:41:08
544	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-25 11:41:08	2025-11-25 11:41:08
545	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	82.193.98.50	[]	2025-11-25 11:41:22	2025-11-25 11:41:22
546	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	82.193.98.50	{"name":"144\\t\\u041f\\u043e\\u0440\\u0456\\u0437\\u043a\\u0430 \\u0434\\u0440\\u043e\\u0442\\u0456\\u0432 ELRS","description":null,"department_id":"4","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"13","in_archive":"0","_token":"HRWvpXboCZQhASsugUdK1SEhIEblor1x4fj9hnKf"}	2025-11-25 11:41:35	2025-11-25 11:41:35
547	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-25 11:41:36	2025-11-25 11:41:36
548	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	82.193.98.50	[]	2025-11-25 11:41:52	2025-11-25 11:41:52
549	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	82.193.98.50	{"name":"480\\t\\u041d\\u0430\\u0440\\u0456\\u0437\\u043a\\u0430 \\u0442\\u0435\\u0440\\u043c\\u043e\\u0443\\u0441\\u0430\\u0434\\u043a\\u0438 \\u043d\\u0430 \\u0448\\u0430\\u0431\\u043b\\u043e\\u043d\\u0456","description":null,"department_id":"1","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"4","in_archive":"0","_token":"HRWvpXboCZQhASsugUdK1SEhIEblor1x4fj9hnKf"}	2025-11-25 11:42:10	2025-11-25 11:42:10
550	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-25 11:42:10	2025-11-25 11:42:10
551	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	82.193.98.50	[]	2025-11-25 11:42:28	2025-11-25 11:42:28
552	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments	GET	82.193.98.50	[]	2025-11-25 11:42:54	2025-11-25 11:42:54
553	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments/create	GET	82.193.98.50	[]	2025-11-25 11:42:59	2025-11-25 11:42:59
554	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments	POST	82.193.98.50	{"name":"\\u0410\\u043d\\u0442\\u0435\\u043d\\u0438","short_name":"Ant","chat_id":null,"report_type_id":null,"search_terms":null,"_token":"HRWvpXboCZQhASsugUdK1SEhIEblor1x4fj9hnKf"}	2025-11-25 11:43:33	2025-11-25 11:43:33
555	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments	GET	82.193.98.50	[]	2025-11-25 11:43:33	2025-11-25 11:43:33
556	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments/10/edit	GET	82.193.98.50	[]	2025-11-25 11:43:42	2025-11-25 11:43:42
557	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments/10	PUT	82.193.98.50	{"name":"\\u0410\\u043d\\u0442\\u0435\\u043d\\u0438","short_name":"ANT","chat_id":null,"report_type_id":null,"search_terms":null,"_token":"HRWvpXboCZQhASsugUdK1SEhIEblor1x4fj9hnKf","_method":"PUT"}	2025-11-25 11:43:51	2025-11-25 11:43:51
558	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments	GET	82.193.98.50	[]	2025-11-25 11:43:51	2025-11-25 11:43:51
559	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-25 11:43:54	2025-11-25 11:43:54
560	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	82.193.98.50	[]	2025-11-25 11:44:11	2025-11-25 11:44:11
561	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	82.193.98.50	{"name":"337\\t\\u0422\\u0435\\u043a\\u0441\\u0442\\u043e\\u043b\\u0456\\u0442\\u043e\\u0432\\u0456 \\u0430\\u043d\\u0442\\u0435\\u043d\\u0438","description":null,"department_id":"10","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"30","in_archive":"0","_token":"HRWvpXboCZQhASsugUdK1SEhIEblor1x4fj9hnKf"}	2025-11-25 11:44:24	2025-11-25 11:44:24
562	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-25 11:44:24	2025-11-25 11:44:24
563	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	82.193.98.50	[]	2025-11-25 11:44:33	2025-11-25 11:44:33
564	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	82.193.98.50	{"name":"39\\t\\u041f\\u0440\\u043e\\u0437\\u0432\\u043e\\u043d \\u0430\\u043d\\u0442\\u0435\\u043d\\u0438","description":null,"department_id":"10","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"10","in_archive":"0","_token":"HRWvpXboCZQhASsugUdK1SEhIEblor1x4fj9hnKf"}	2025-11-25 11:44:49	2025-11-25 11:44:49
565	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-25 11:44:49	2025-11-25 11:44:49
566	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	82.193.98.50	[]	2025-11-25 11:44:58	2025-11-25 11:44:58
567	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	82.193.98.50	{"name":"482\\t\\u041c\\u043e\\u043d\\u0442\\u0430\\u0436 \\u0445\\u043e\\u043b\\u0434\\u0435\\u0440\\u0443 \\u043d\\u0430 \\u0442\\u0435\\u043a\\u0441\\u0442\\u043e\\u043b\\u0456\\u0442\\u043e\\u0432\\u0443 \\u0430\\u043d\\u0442\\u0435\\u043d\\u0443 V2","description":null,"department_id":"10","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"15","in_archive":"0","_token":"HRWvpXboCZQhASsugUdK1SEhIEblor1x4fj9hnKf"}	2025-11-25 11:45:09	2025-11-25 11:45:09
568	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-25 11:45:09	2025-11-25 11:45:09
569	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	82.193.98.50	[]	2025-11-25 11:45:29	2025-11-25 11:45:29
570	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	82.193.98.50	{"name":"25\\t\\u041c\\u043e\\u043d\\u0442\\u0430\\u0436 \\u0430\\u043d\\u0442\\u0435\\u043d\\u0438 \\u043d\\u0430 \\u043c\\u043e\\u0434\\u0443\\u043b\\u044c ERLS","description":null,"department_id":"5","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"40","in_archive":"0","_token":"HRWvpXboCZQhASsugUdK1SEhIEblor1x4fj9hnKf"}	2025-11-25 11:45:41	2025-11-25 11:45:41
571	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-25 11:45:41	2025-11-25 11:45:41
572	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	82.193.98.50	[]	2025-11-25 11:45:54	2025-11-25 11:45:54
605	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	82.193.98.50	[]	2025-11-25 11:57:51	2025-11-25 11:57:51
682	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments	GET	94.176.198.158	[]	2025-11-25 13:14:52	2025-11-25 13:14:52
573	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	82.193.98.50	{"name":"231\\t\\u041f\\u0430\\u0439\\u043a\\u0430 \\u043f\\u043e\\u0434\\u0432\\u0456\\u0439\\u043d\\u0438\\u0445 \\u0434\\u0440\\u043e\\u0442\\u0456\\u0432 \\u0434\\u043e \\u041f\\u0406","description":null,"department_id":"4","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"112","in_archive":"0","_token":"HRWvpXboCZQhASsugUdK1SEhIEblor1x4fj9hnKf"}	2025-11-25 11:46:11	2025-11-25 11:46:11
574	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-25 11:46:12	2025-11-25 11:46:12
575	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	82.193.98.50	[]	2025-11-25 11:46:23	2025-11-25 11:46:23
576	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	82.193.98.50	{"name":"80\\t\\u041f\\u0430\\u0439\\u043a\\u0430 \\u041f\\u0406 \\u0434\\u043e \\u043b\\u044c\\u043e\\u0442\\u043d\\u043e\\u0433\\u043e \\u043a\\u043e\\u043d\\u0442\\u0440\\u043e\\u043b\\u0435\\u0440\\u0430","description":null,"department_id":"4","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"53","in_archive":"0","_token":"HRWvpXboCZQhASsugUdK1SEhIEblor1x4fj9hnKf"}	2025-11-25 11:46:42	2025-11-25 11:46:42
577	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-25 11:46:42	2025-11-25 11:46:42
578	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	82.193.98.50	[]	2025-11-25 11:47:02	2025-11-25 11:47:02
579	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	82.193.98.50	{"name":"394\\t\\u0414\\u043e\\u0433\\u0435\\u0440\\u043c\\u0435\\u0442\\u0438\\u0437\\u0430\\u0446\\u0456\\u044f \\u041f\\u0406","description":null,"department_id":"4","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"40","in_archive":"0","_token":"HRWvpXboCZQhASsugUdK1SEhIEblor1x4fj9hnKf"}	2025-11-25 11:47:18	2025-11-25 11:47:18
580	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-25 11:47:19	2025-11-25 11:47:19
581	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	82.193.98.50	[]	2025-11-25 11:47:30	2025-11-25 11:47:30
582	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	82.193.98.50	{"name":"67\\t\\u041d\\u0430\\u0440\\u0456\\u0437\\u043a\\u0430 \\u043a\\u043e\\u043d\\u0442\\u0430\\u043a\\u0442\\u043d\\u043e\\u0433\\u043e \\u043f\\u0440\\u0443\\u0442\\u0430","description":null,"department_id":"1","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"4","in_archive":"0","_token":"HRWvpXboCZQhASsugUdK1SEhIEblor1x4fj9hnKf"}	2025-11-25 11:47:47	2025-11-25 11:47:47
583	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-25 11:47:47	2025-11-25 11:47:47
584	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	82.193.98.50	[]	2025-11-25 11:48:03	2025-11-25 11:48:03
585	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	82.193.98.50	{"name":"52\\t\\u041f\\u0456\\u0434\\u0433\\u043e\\u0442\\u043e\\u0432\\u043a\\u0430 \\u043a\\u043e\\u043d\\u0442\\u0430\\u043a\\u0442\\u043d\\u043e\\u0433\\u043e \\u043c\\u0435\\u0445\\u0430\\u043d\\u0456\\u0437\\u043c\\u0443","description":null,"department_id":"1","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"92","in_archive":"0","_token":"HRWvpXboCZQhASsugUdK1SEhIEblor1x4fj9hnKf"}	2025-11-25 11:48:14	2025-11-25 11:48:14
586	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-25 11:48:14	2025-11-25 11:48:14
587	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	82.193.98.50	[]	2025-11-25 11:50:18	2025-11-25 11:50:18
588	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	82.193.98.50	{"name":"476\\t\\u0422\\u0435\\u0440\\u043c\\u043e\\u0443\\u0441\\u0430\\u0434\\u043a\\u0430 \\u043d\\u0430 \\u041a\\u041c","description":null,"department_id":"1","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"476","in_archive":"0","_token":"HRWvpXboCZQhASsugUdK1SEhIEblor1x4fj9hnKf"}	2025-11-25 11:50:32	2025-11-25 11:50:32
589	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-25 11:50:33	2025-11-25 11:50:33
590	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	82.193.98.50	[]	2025-11-25 11:50:54	2025-11-25 11:50:54
591	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	82.193.98.50	{"name":"356\\t\\u0413\\u0435\\u0440\\u043c\\u0435\\u0442\\u0438\\u0437\\u0430\\u0446\\u0456\\u044f \\u041f\\u0406","description":null,"department_id":"1","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"39","in_archive":"0","_token":"HRWvpXboCZQhASsugUdK1SEhIEblor1x4fj9hnKf"}	2025-11-25 11:51:05	2025-11-25 11:51:05
592	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-25 11:51:05	2025-11-25 11:51:05
593	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	82.193.98.50	[]	2025-11-25 11:55:03	2025-11-25 11:55:03
594	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	82.193.98.50	{"name":"506\\t\\u041c\\u043e\\u043d\\u0442\\u0430\\u0436 \\u041a\\u041c 15\\"","description":null,"department_id":"5","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"240","in_archive":"0","_token":"HRWvpXboCZQhASsugUdK1SEhIEblor1x4fj9hnKf"}	2025-11-25 11:55:21	2025-11-25 11:55:21
595	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-25 11:55:21	2025-11-25 11:55:21
596	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	82.193.98.50	[]	2025-11-25 11:55:49	2025-11-25 11:55:49
597	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	82.193.98.50	{"name":"410\\t\\u041f\\u0430\\u0439\\u043a\\u0430 \\u043f\\u043e\\u0434\\u0432\\u0456\\u0439\\u043d\\u043e\\u0433\\u043e \\u041a\\u041c 15\\"","description":null,"department_id":"5","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"201","in_archive":"0","_token":"HRWvpXboCZQhASsugUdK1SEhIEblor1x4fj9hnKf"}	2025-11-25 11:56:07	2025-11-25 11:56:07
598	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-25 11:56:08	2025-11-25 11:56:08
599	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	82.193.98.50	[]	2025-11-25 11:56:14	2025-11-25 11:56:14
600	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	82.193.98.50	{"name":"301\\t\\u041d\\u0430\\u043f\\u0430\\u0439\\u043a\\u0430 \\u0434\\u0440\\u043e\\u0441\\u0435\\u043b\\u044f","description":null,"department_id":"4","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"110","in_archive":"0","_token":"HRWvpXboCZQhASsugUdK1SEhIEblor1x4fj9hnKf"}	2025-11-25 11:56:32	2025-11-25 11:56:32
601	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-25 11:56:33	2025-11-25 11:56:33
602	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	82.193.98.50	[]	2025-11-25 11:56:47	2025-11-25 11:56:47
603	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	82.193.98.50	{"name":"424\\t\\u041c\\u043e\\u043d\\u0442\\u0430\\u0436 \\u0430\\u043d\\u0442\\u0435\\u043d\\u0438 \\u043d\\u0430 \\u043a\\u0440\\u043e\\u043d\\u0448\\u0442\\u0435\\u0439\\u043d 2,1 - 2,6","description":null,"department_id":"1","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"120","in_archive":"0","_token":"HRWvpXboCZQhASsugUdK1SEhIEblor1x4fj9hnKf"}	2025-11-25 11:57:37	2025-11-25 11:57:37
604	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-25 11:57:39	2025-11-25 11:57:39
606	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	82.193.98.50	{"name":"191\\t\\u041f\\u0456\\u0434\\u0433\\u043e\\u0442\\u0443\\u0432\\u0430\\u043d\\u043d\\u044f VTX TBS UP32","description":null,"department_id":"4","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"76","in_archive":"0","_token":"HRWvpXboCZQhASsugUdK1SEhIEblor1x4fj9hnKf"}	2025-11-25 11:58:15	2025-11-25 11:58:15
607	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-25 11:58:15	2025-11-25 11:58:15
608	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk	GET	82.193.98.50	[]	2025-11-25 12:13:53	2025-11-25 12:13:53
609	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-25 12:14:05	2025-11-25 12:14:05
610	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk	GET	193.239.153.169	[]	2025-11-25 12:14:51	2025-11-25 12:14:51
611	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	193.239.153.169	[]	2025-11-25 12:14:57	2025-11-25 12:14:57
612	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	82.193.98.50	[]	2025-11-25 12:15:11	2025-11-25 12:15:11
613	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	193.239.153.169	{"start_time":{"start":"2025-11-24","end":"2025-11-25"},"workDayDepartment":{"department_id":null},"search_terms":null}	2025-11-25 12:15:12	2025-11-25 12:15:12
614	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	82.193.98.50	{"name":"523\\t\\u0411\\u0430\\u0437\\u043e\\u0432\\u0430 \\u0437\\u0431\\u0456\\u0440\\u043a\\u0430 15\\" \\u0437 \\u041a\\u041c V2","description":null,"department_id":"5","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"900","in_archive":"0","_token":"rXzfpVrIjO3Lmxkbpla9M2ZU3n82in8QiQVmMtZk"}	2025-11-25 12:15:44	2025-11-25 12:15:44
615	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-25 12:15:44	2025-11-25 12:15:44
616	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	82.193.98.50	[]	2025-11-25 12:16:00	2025-11-25 12:16:00
617	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	82.193.98.50	{"name":"580\\t\\u0411\\u0430\\u0437\\u043e\\u0432\\u0430 \\u0437\\u0431\\u0456\\u0440\\u043a\\u0430 15\\" \\u0437 \\u041a\\u041c\\/\\u041e\\u043f\\u0442\\u043e V2","description":null,"department_id":"5","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"660","in_archive":"0","_token":"rXzfpVrIjO3Lmxkbpla9M2ZU3n82in8QiQVmMtZk"}	2025-11-25 12:16:15	2025-11-25 12:16:15
618	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-25 12:16:16	2025-11-25 12:16:16
619	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	82.193.98.50	[]	2025-11-25 12:16:19	2025-11-25 12:16:19
620	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	82.193.98.50	{"name":"558\\t\\u0411\\u0430\\u0437\\u043e\\u0432\\u0430 \\u0437\\u0431\\u0456\\u0440\\u043a\\u0430 15'' V.opt\\/digital","description":null,"department_id":"5","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":"0","_token":"rXzfpVrIjO3Lmxkbpla9M2ZU3n82in8QiQVmMtZk"}	2025-11-25 12:18:18	2025-11-25 12:18:18
621	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-25 12:18:19	2025-11-25 12:18:19
622	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	82.193.98.50	[]	2025-11-25 12:36:53	2025-11-25 12:36:53
623	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	82.193.98.50	{"name":"492\\t\\u041c\\u043e\\u043d\\u0442\\u0430\\u0436 \\u043c\\u0430\\u0443\\u043d\\u0442\\u0443 \\u043d\\u0430 \\u041e\\u043f\\u0442\\u043e 15\\"","description":null,"department_id":"2","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"90","in_archive":"0","_token":"rXzfpVrIjO3Lmxkbpla9M2ZU3n82in8QiQVmMtZk"}	2025-11-25 12:37:17	2025-11-25 12:37:17
624	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-25 12:37:18	2025-11-25 12:37:18
625	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	82.193.98.50	[]	2025-11-25 12:37:39	2025-11-25 12:37:39
626	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	82.193.98.50	{"name":"544\\t\\u041a\\u0440\\u0456\\u043f\\u043b\\u0435\\u043d\\u043d\\u044f \\u0434\\u0440\\u043e\\u0442\\u0456\\u0432 \\u0456\\u0437\\u043e\\u043b\\u0435\\u043d\\u0442\\u043e\\u044e 15\\" \\u041e\\u041f\\u0422\\u041e","description":null,"department_id":"2","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"240","in_archive":"0","_token":"rXzfpVrIjO3Lmxkbpla9M2ZU3n82in8QiQVmMtZk"}	2025-11-25 12:37:58	2025-11-25 12:37:58
627	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-25 12:37:58	2025-11-25 12:37:58
628	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	82.193.98.50	[]	2025-11-25 12:38:15	2025-11-25 12:38:15
629	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	82.193.98.50	{"name":"538\\t\\u0417\\u0431\\u0456\\u0440\\u043a\\u0430 \\u0440\\u0430\\u043c\\u0438 \\u041e\\u043f\\u0442\\u043e 15\\"","description":null,"department_id":"2","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"360","in_archive":"0","_token":"rXzfpVrIjO3Lmxkbpla9M2ZU3n82in8QiQVmMtZk"}	2025-11-25 12:38:31	2025-11-25 12:38:31
630	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-25 12:38:31	2025-11-25 12:38:31
631	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	82.193.98.50	[]	2025-11-25 12:39:35	2025-11-25 12:39:35
632	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	82.193.98.50	{"name":"378\\t\\u041f\\u0430\\u0439\\u043a\\u0430 \\u0440\\u043e\\u0437'\\u0454\\u043c\\u0443 \\u0411\\u0456\\u0442\\u0430","description":null,"department_id":"4","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"112","in_archive":"0","_token":"rXzfpVrIjO3Lmxkbpla9M2ZU3n82in8QiQVmMtZk"}	2025-11-25 12:39:49	2025-11-25 12:39:49
633	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-25 12:39:49	2025-11-25 12:39:49
634	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk	GET	82.193.98.50	[]	2025-11-25 12:51:40	2025-11-25 12:51:40
635	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-25 12:51:44	2025-11-25 12:51:44
636	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	82.193.98.50	[]	2025-11-25 12:51:46	2025-11-25 12:51:46
637	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	82.193.98.50	{"name":"377\\t\\u041f\\u0456\\u0434\\u0433\\u043e\\u0442\\u043e\\u0432\\u043a\\u0430 \\u0434\\u0440\\u043e\\u0442\\u0456\\u0432 \\u0440\\u043e\\u0437'\\u0454\\u043c\\u0443 \\u0411\\u0456\\u0442\\u0430","description":null,"department_id":"4","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"54","in_archive":"0","_token":"63Z6blwEj7dDiqav5y3P4zJGyHmsgNF0GCuLZjT0"}	2025-11-25 12:52:11	2025-11-25 12:52:11
638	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-25 12:52:12	2025-11-25 12:52:12
639	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	82.193.98.50	[]	2025-11-25 12:52:35	2025-11-25 12:52:35
681	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments/6	GET	94.176.198.158	[]	2025-11-25 13:14:49	2025-11-25 13:14:49
683	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments/create	GET	193.239.153.169	[]	2025-11-25 13:15:51	2025-11-25 13:15:51
640	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	82.193.98.50	{"name":"543\\t\\u041f\\u0430\\u0439\\u043a\\u0430 \\u0448\\u043b\\u0435\\u0439\\u0444\\u0456\\u0432 F\\u0421.V.OPT \\u0431\\u0435\\u0437 \\u041f\\u0406","description":null,"department_id":"4","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"205","in_archive":"0","_token":"63Z6blwEj7dDiqav5y3P4zJGyHmsgNF0GCuLZjT0"}	2025-11-25 12:52:49	2025-11-25 12:52:49
641	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-25 12:52:49	2025-11-25 12:52:49
642	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	82.193.98.50	[]	2025-11-25 12:54:54	2025-11-25 12:54:54
643	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	82.193.98.50	{"name":"103\\t\\u0424\\u0456\\u043a\\u0441\\u0430\\u0446\\u0456\\u044f \\u0441\\u0442\\u0435\\u043a\\u0430 \\u0437 \\u043a\\u0440\\u0438\\u0448\\u043a\\u043e\\u044e","description":null,"department_id":"5","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"139","in_archive":"0","_token":"63Z6blwEj7dDiqav5y3P4zJGyHmsgNF0GCuLZjT0"}	2025-11-25 12:55:17	2025-11-25 12:55:17
644	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-25 12:55:17	2025-11-25 12:55:17
645	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	82.193.98.50	[]	2025-11-25 12:55:35	2025-11-25 12:55:35
646	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	82.193.98.50	{"name":"533\\t\\u0411\\u0430\\u0437\\u043e\\u0432\\u0430 \\u0437\\u0431\\u0456\\u0440\\u043a\\u0430 15\\" \\u0431\\u0435\\u0437 \\u041a\\u041c\\/\\u041e\\u043f\\u0442\\u043e V2","description":null,"department_id":"5","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"420","in_archive":"0","_token":"63Z6blwEj7dDiqav5y3P4zJGyHmsgNF0GCuLZjT0"}	2025-11-25 12:55:53	2025-11-25 12:55:53
647	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-25 12:55:53	2025-11-25 12:55:53
648	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	82.193.98.50	[]	2025-11-25 12:58:41	2025-11-25 12:58:41
649	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	82.193.98.50	{"name":"567\\t15\\u201d V.opt \\u0437 \\u0430\\u0441\\u0438\\u0441\\u0442\\u0435\\u043d\\u0442\\u043e\\u043c","description":null,"department_id":"7","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"210","in_archive":"0","_token":"63Z6blwEj7dDiqav5y3P4zJGyHmsgNF0GCuLZjT0"}	2025-11-25 12:59:03	2025-11-25 12:59:03
650	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-25 12:59:03	2025-11-25 12:59:03
651	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	82.193.98.50	[]	2025-11-25 13:02:43	2025-11-25 13:02:43
652	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk	GET	193.239.153.169	[]	2025-11-25 13:02:48	2025-11-25 13:02:48
653	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	193.239.153.169	[]	2025-11-25 13:02:52	2025-11-25 13:02:52
654	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	82.193.98.50	{"name":"24\\t\\u041c\\u043e\\u043d\\u0442\\u0430\\u0436 \\u043a\\u0430\\u043c\\u0435\\u0440\\u0438 \\u043d\\u0430 \\u043a\\u0440\\u043e\\u043d\\u0448\\u0442\\u0435\\u0439\\u043d","description":null,"department_id":"1","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"34","in_archive":"0","_token":"63Z6blwEj7dDiqav5y3P4zJGyHmsgNF0GCuLZjT0"}	2025-11-25 13:02:52	2025-11-25 13:02:52
655	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-25 13:02:52	2025-11-25 13:02:52
656	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	193.239.153.169	[]	2025-11-25 13:03:28	2025-11-25 13:03:28
657	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	82.193.98.50	[]	2025-11-25 13:05:27	2025-11-25 13:05:27
658	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	82.193.98.50	{"name":"562\\t15\\" \\u041f\\u043e\\u0432\\u043d\\u0430 \\u0437\\u0431\\u0456\\u0440\\u043a\\u0430 FC V.Opt\\/digital \\u0431\\u0435\\u0437 \\u041f\\u0406","description":null,"department_id":"4","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"320","in_archive":"0","_token":"63Z6blwEj7dDiqav5y3P4zJGyHmsgNF0GCuLZjT0"}	2025-11-25 13:05:46	2025-11-25 13:05:46
659	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-25 13:05:46	2025-11-25 13:05:46
660	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk	GET	94.176.198.158	[]	2025-11-25 13:12:31	2025-11-25 13:12:31
661	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments	GET	94.176.198.158	[]	2025-11-25 13:12:43	2025-11-25 13:12:43
662	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments	GET	193.239.153.169	[]	2025-11-25 13:12:51	2025-11-25 13:12:51
663	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments/1/edit	GET	94.176.198.158	[]	2025-11-25 13:12:58	2025-11-25 13:12:58
664	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments/1	PUT	94.176.198.158	{"name":"\\u0417\\u0430\\u0433\\u043e\\u0442\\u043e\\u0432\\u043a\\u0438","short_name":"MDL","chat_id":null,"report_type_id":null,"search_terms":null,"_token":"N97GqgbGPaAiLTSwBeajw0vF1I76FUFv6hg8HVOE","_method":"PUT"}	2025-11-25 13:13:08	2025-11-25 13:13:08
665	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments	GET	94.176.198.158	[]	2025-11-25 13:13:08	2025-11-25 13:13:08
666	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments/1/edit	GET	94.176.198.158	[]	2025-11-25 13:13:10	2025-11-25 13:13:10
667	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments	GET	94.176.198.158	[]	2025-11-25 13:13:28	2025-11-25 13:13:28
668	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments/create	GET	94.176.198.158	[]	2025-11-25 13:13:35	2025-11-25 13:13:35
669	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments/create	GET	193.239.153.169	[]	2025-11-25 13:13:41	2025-11-25 13:13:41
670	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments	GET	193.239.153.169	[]	2025-11-25 13:13:45	2025-11-25 13:13:45
671	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments	GET	193.239.153.169	[]	2025-11-25 13:13:57	2025-11-25 13:13:57
672	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments	GET	193.239.153.169	[]	2025-11-25 13:14:01	2025-11-25 13:14:01
673	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments	POST	94.176.198.158	{"name":"One Peace Flow","short_name":"OPF","chat_id":null,"report_type_id":null,"search_terms":null,"_token":"N97GqgbGPaAiLTSwBeajw0vF1I76FUFv6hg8HVOE"}	2025-11-25 13:14:03	2025-11-25 13:14:03
674	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments	GET	193.239.153.169	[]	2025-11-25 13:14:03	2025-11-25 13:14:03
675	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments	GET	94.176.198.158	[]	2025-11-25 13:14:03	2025-11-25 13:14:03
676	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments	GET	193.239.153.169	[]	2025-11-25 13:14:06	2025-11-25 13:14:06
677	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments/10	GET	94.176.198.158	[]	2025-11-25 13:14:10	2025-11-25 13:14:10
678	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments	GET	94.176.198.158	[]	2025-11-25 13:14:16	2025-11-25 13:14:16
679	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments/4	GET	94.176.198.158	[]	2025-11-25 13:14:21	2025-11-25 13:14:21
680	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments	GET	94.176.198.158	[]	2025-11-25 13:14:25	2025-11-25 13:14:25
684	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.158	[]	2025-11-25 13:16:05	2025-11-25 13:16:05
685	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/workers	GET	94.176.198.158	[]	2025-11-25 13:16:07	2025-11-25 13:16:07
686	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/workers/970421717/edit	GET	94.176.198.158	[]	2025-11-25 13:16:12	2025-11-25 13:16:12
687	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments	POST	193.239.153.169	{"name":"\\u0420\\u0435\\u043c\\u043e\\u043d\\u0442","short_name":"REP","chat_id":null,"report_type_id":null,"search_terms":null,"_token":"KqNBcV1HXIgABiFnxAPv3DMG8NclewZYw32ztlmS"}	2025-11-25 13:20:14	2025-11-25 13:20:14
688	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments	GET	193.239.153.169	[]	2025-11-25 13:20:15	2025-11-25 13:20:15
689	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	193.239.153.169	[]	2025-11-25 13:25:43	2025-11-25 13:25:43
690	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	193.239.153.169	[]	2025-11-25 13:25:48	2025-11-25 13:25:48
691	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	193.239.153.169	{"name":"\\u0420\\u0435\\u043c\\u043e\\u043d\\u0442","description":null,"department_id":"12","search_terms":null,"is_permitted":"0","permission_type":"4","trusted_workers":[null],"description_requirement":"0","norm_type":"1","multiplier_column":"1","in_archive":"0","_token":"KqNBcV1HXIgABiFnxAPv3DMG8NclewZYw32ztlmS"}	2025-11-25 13:26:29	2025-11-25 13:26:29
692	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	193.239.153.169	[]	2025-11-25 13:26:29	2025-11-25 13:26:29
693	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments	GET	193.239.153.169	[]	2025-11-25 13:27:45	2025-11-25 13:27:45
694	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/100/edit	GET	82.193.98.50	[]	2025-11-25 13:27:54	2025-11-25 13:27:54
695	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/100	PUT	82.193.98.50	{"name":"562\\t15\\" \\u041f\\u043e\\u0432\\u043d\\u0430 \\u0437\\u0431\\u0456\\u0440\\u043a\\u0430 FC V.Opt\\/D \\u0431\\u0435\\u0437 \\u041f\\u0406","description":null,"department_id":"4","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"320","in_archive":null,"_token":"63Z6blwEj7dDiqav5y3P4zJGyHmsgNF0GCuLZjT0","_method":"PUT"}	2025-11-25 13:28:02	2025-11-25 13:28:02
696	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-25 13:28:03	2025-11-25 13:28:03
697	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments/1/edit	GET	193.239.153.169	[]	2025-11-25 13:29:45	2025-11-25 13:29:45
698	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/15/edit	GET	82.193.98.50	[]	2025-11-25 13:37:16	2025-11-25 13:37:16
699	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/15	PUT	82.193.98.50	{"name":"\\u041f\\u0430\\u0439\\u043a\\u0430 XT90 SL","description":null,"department_id":"3","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":"on","in_archive_cb":"on","_token":"63Z6blwEj7dDiqav5y3P4zJGyHmsgNF0GCuLZjT0","_method":"PUT"}	2025-11-25 13:37:20	2025-11-25 13:37:20
700	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-25 13:37:20	2025-11-25 13:37:20
701	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments/1/edit	GET	193.239.153.169	[]	2025-11-25 13:39:20	2025-11-25 13:39:20
702	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments/1	PUT	193.239.153.169	{"name":"\\u0417\\u0430\\u0433\\u043e\\u0442\\u043e\\u0432\\u043a\\u0438","short_name":"MDL","chat_id":"-5099024714","report_type_id":"3","search_terms":null,"_token":"KqNBcV1HXIgABiFnxAPv3DMG8NclewZYw32ztlmS","_method":"PUT"}	2025-11-25 13:39:55	2025-11-25 13:39:55
703	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments	GET	193.239.153.169	[]	2025-11-25 13:39:55	2025-11-25 13:39:55
704	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments/2/edit	GET	193.239.153.169	[]	2025-11-25 13:41:06	2025-11-25 13:41:06
705	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments/2	PUT	193.239.153.169	{"name":"\\u0417\\u0431\\u0456\\u0440\\u043a\\u0430 \\u0440\\u0430\\u043c\\u0438","short_name":"FR","chat_id":"-5071885624","report_type_id":"4","search_terms":null,"_token":"KqNBcV1HXIgABiFnxAPv3DMG8NclewZYw32ztlmS","_method":"PUT"}	2025-11-25 13:41:19	2025-11-25 13:41:19
706	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments	GET	193.239.153.169	[]	2025-11-25 13:41:19	2025-11-25 13:41:19
707	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments/3/edit	GET	193.239.153.169	[]	2025-11-25 13:42:05	2025-11-25 13:42:05
708	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments/3	PUT	193.239.153.169	{"name":"ESC","short_name":"ESC","chat_id":"-5044429508","report_type_id":"4","search_terms":null,"_token":"KqNBcV1HXIgABiFnxAPv3DMG8NclewZYw32ztlmS","_method":"PUT"}	2025-11-25 13:42:09	2025-11-25 13:42:09
709	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments	GET	193.239.153.169	[]	2025-11-25 13:42:09	2025-11-25 13:42:09
710	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments/4/edit	GET	193.239.153.169	[]	2025-11-25 13:42:49	2025-11-25 13:42:49
711	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments/4	PUT	193.239.153.169	{"name":"FC","short_name":"FC","chat_id":"-4986143667","report_type_id":"4","search_terms":null,"_token":"KqNBcV1HXIgABiFnxAPv3DMG8NclewZYw32ztlmS","_method":"PUT"}	2025-11-25 13:42:53	2025-11-25 13:42:53
712	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments	GET	193.239.153.169	[]	2025-11-25 13:42:54	2025-11-25 13:42:54
713	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments/5/edit	GET	193.239.153.169	[]	2025-11-25 13:43:34	2025-11-25 13:43:34
714	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments/5	PUT	193.239.153.169	{"name":"\\u0424\\u0456\\u043d\\u0430\\u043b\\u044c\\u043d\\u0430 \\u0437\\u0431\\u0456\\u0440\\u043a\\u0430","short_name":"FIN","chat_id":"-5016743644","report_type_id":"4","search_terms":null,"_token":"KqNBcV1HXIgABiFnxAPv3DMG8NclewZYw32ztlmS","_method":"PUT"}	2025-11-25 13:43:38	2025-11-25 13:43:38
715	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments	GET	193.239.153.169	[]	2025-11-25 13:43:38	2025-11-25 13:43:38
716	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments/6/edit	GET	193.239.153.169	[]	2025-11-25 13:44:29	2025-11-25 13:44:29
717	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments/6	PUT	193.239.153.169	{"name":"\\u0422\\u0435\\u0441\\u0442\\u0443\\u0432\\u0430\\u043d\\u043d\\u044f","short_name":"TST","chat_id":"-5099005065","report_type_id":"4","search_terms":null,"_token":"KqNBcV1HXIgABiFnxAPv3DMG8NclewZYw32ztlmS","_method":"PUT"}	2025-11-25 13:44:33	2025-11-25 13:44:33
718	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments	GET	193.239.153.169	[]	2025-11-25 13:44:33	2025-11-25 13:44:33
719	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments/7/edit	GET	193.239.153.169	[]	2025-11-25 13:45:12	2025-11-25 13:45:12
720	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments/7	PUT	193.239.153.169	{"name":"\\u041e\\u0431\\u043b\\u0456\\u0442","short_name":"FLT","chat_id":"-5032127986","report_type_id":"4","search_terms":null,"_token":"KqNBcV1HXIgABiFnxAPv3DMG8NclewZYw32ztlmS","_method":"PUT"}	2025-11-25 13:45:21	2025-11-25 13:45:21
721	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments	GET	193.239.153.169	[]	2025-11-25 13:45:21	2025-11-25 13:45:21
722	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments/8/edit	GET	193.239.153.169	[]	2025-11-25 13:46:16	2025-11-25 13:46:16
723	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments/8	PUT	193.239.153.169	{"name":"\\u041f\\u0430\\u043a\\u0443\\u0432\\u0430\\u043d\\u043d\\u044f","short_name":"PAC","chat_id":"-5054828018","report_type_id":"4","search_terms":null,"_token":"KqNBcV1HXIgABiFnxAPv3DMG8NclewZYw32ztlmS","_method":"PUT"}	2025-11-25 13:46:20	2025-11-25 13:46:20
724	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments	GET	193.239.153.169	[]	2025-11-25 13:46:20	2025-11-25 13:46:20
725	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments/10/edit	GET	193.239.153.169	[]	2025-11-25 13:47:10	2025-11-25 13:47:10
726	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments/10	PUT	193.239.153.169	{"name":"\\u0410\\u043d\\u0442\\u0435\\u043d\\u0438","short_name":"ANT","chat_id":"-5084800688","report_type_id":"4","search_terms":null,"_token":"KqNBcV1HXIgABiFnxAPv3DMG8NclewZYw32ztlmS","_method":"PUT"}	2025-11-25 13:47:17	2025-11-25 13:47:17
727	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments	GET	193.239.153.169	[]	2025-11-25 13:47:17	2025-11-25 13:47:17
728	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments/11/edit	GET	193.239.153.169	[]	2025-11-25 13:47:36	2025-11-25 13:47:36
729	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments/11	PUT	193.239.153.169	{"name":"One piece flow","short_name":"OPF","chat_id":"-5002014238","report_type_id":"4","search_terms":null,"_token":"KqNBcV1HXIgABiFnxAPv3DMG8NclewZYw32ztlmS","_method":"PUT"}	2025-11-25 13:52:18	2025-11-25 13:52:18
730	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments	GET	193.239.153.169	[]	2025-11-25 13:52:18	2025-11-25 13:52:18
731	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments/12/edit	GET	193.239.153.169	[]	2025-11-25 13:53:02	2025-11-25 13:53:02
732	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments/12	PUT	193.239.153.169	{"name":"\\u0420\\u0435\\u043c\\u043e\\u043d\\u0442","short_name":"REP","chat_id":"-5068601995","report_type_id":"4","search_terms":null,"_token":"KqNBcV1HXIgABiFnxAPv3DMG8NclewZYw32ztlmS","_method":"PUT"}	2025-11-25 13:53:07	2025-11-25 13:53:07
733	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments	GET	193.239.153.169	[]	2025-11-25 13:53:07	2025-11-25 13:53:07
734	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk	GET	82.193.98.50	[]	2025-11-25 15:22:19	2025-11-25 15:22:19
735	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	82.193.98.50	[]	2025-11-25 15:22:27	2025-11-25 15:22:27
736	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	82.193.98.50	{"start_time":{"start":null,"end":null},"workDayDepartment":{"department_id":null},"search_terms":null,"worker_id":["547586388"]}	2025-11-25 15:22:43	2025-11-25 15:22:43
737	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days/29	GET	82.193.98.50	[]	2025-11-25 15:22:48	2025-11-25 15:22:48
738	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works/15/edit	GET	82.193.98.50	[]	2025-11-25 15:22:53	2025-11-25 15:22:53
739	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works/15	PUT	82.193.98.50	{"work_day_id":"29","start_time":"2025-11-25 10:00:00","finish_time":"2025-11-25 12:17:14","operation_id":"900","search_terms":null,"result":"1","pause_duration":"0","_token":"ipECTcvMlfB5jgddKV5qX8v0NwApvkXP7vyDklSy","_method":"PUT"}	2025-11-25 15:22:57	2025-11-25 15:22:57
740	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	82.193.98.50	{"search_terms":null,"start_time":{"start":null,"end":null},"workDayDepartment":{"department_id":null},"worker_id":["547586388"]}	2025-11-25 15:22:57	2025-11-25 15:22:57
741	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days/29	GET	82.193.98.50	[]	2025-11-25 15:23:01	2025-11-25 15:23:01
742	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	82.193.98.50	{"search_terms":null,"start_time":{"start":null,"end":null},"workDayDepartment":{"department_id":null},"worker_id":["547586388"]}	2025-11-25 15:35:10	2025-11-25 15:35:10
743	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days/29	GET	82.193.98.50	[]	2025-11-25 15:35:17	2025-11-25 15:35:17
744	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-25 15:35:59	2025-11-25 15:35:59
745	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	{"department_id":null,"search_terms":null,"id":"900"}	2025-11-25 15:36:09	2025-11-25 15:36:09
746	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/900/edit	GET	82.193.98.50	[]	2025-11-25 15:36:15	2025-11-25 15:36:15
747	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/900	PUT	82.193.98.50	{"name":"\\u041f\\u0435\\u0440\\u0435\\u0440\\u043e\\u0431\\u043a\\u0430","description":null,"department_id":"9","search_terms":null,"is_permitted":"0","norm_type":"1","multiplier_column":"1","in_archive":null,"_token":"ipECTcvMlfB5jgddKV5qX8v0NwApvkXP7vyDklSy","_method":"PUT"}	2025-11-25 15:36:21	2025-11-25 15:36:21
748	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/900/edit	GET	82.193.98.50	[]	2025-11-25 15:36:21	2025-11-25 15:36:21
749	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk	GET	82.193.98.50	[]	2025-11-25 15:38:18	2025-11-25 15:38:18
750	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	82.193.98.50	[]	2025-11-25 15:38:34	2025-11-25 15:38:34
751	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	82.193.98.50	{"start_time":{"start":null,"end":null},"workDayDepartment":{"department_id":null},"search_terms":null,"worker_id":["547586388"]}	2025-11-25 15:38:40	2025-11-25 15:38:40
752	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days/29	GET	82.193.98.50	[]	2025-11-25 15:38:43	2025-11-25 15:38:43
753	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works/15/edit	GET	82.193.98.50	[]	2025-11-25 15:38:46	2025-11-25 15:38:46
754	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works/15	PUT	82.193.98.50	{"work_day_id":"29","start_time":"2025-11-25 10:00:00","finish_time":"2025-11-25 12:17:14","operation_id":"900","search_terms":null,"result":"1","pause_duration":"0","_token":"WjvCH1RusQXqgQaBVMWMciODrIe5STGt5lB9ChXL","_method":"PUT"}	2025-11-25 15:38:49	2025-11-25 15:38:49
755	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	82.193.98.50	{"search_terms":null,"start_time":{"start":null,"end":null},"workDayDepartment":{"department_id":null},"worker_id":["547586388"]}	2025-11-25 15:38:49	2025-11-25 15:38:49
756	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days/29	GET	82.193.98.50	[]	2025-11-25 15:38:53	2025-11-25 15:38:53
757	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works/16/edit	GET	82.193.98.50	[]	2025-11-25 15:38:57	2025-11-25 15:38:57
758	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works/16	PUT	82.193.98.50	{"work_day_id":"29","start_time":"2025-11-25 12:17:50","finish_time":"2025-11-25 17:05:06","operation_id":"900","search_terms":null,"result":"1","pause_duration":"0","_token":"WjvCH1RusQXqgQaBVMWMciODrIe5STGt5lB9ChXL","_method":"PUT"}	2025-11-25 15:38:59	2025-11-25 15:38:59
759	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	82.193.98.50	{"search_terms":null,"start_time":{"start":null,"end":null},"workDayDepartment":{"department_id":null},"worker_id":["547586388"]}	2025-11-25 15:38:59	2025-11-25 15:38:59
760	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-25 15:39:04	2025-11-25 15:39:04
761	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	{"department_id":null,"search_terms":null,"id":"900"}	2025-11-25 15:39:11	2025-11-25 15:39:11
762	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works	GET	82.193.98.50	{"operation_filter":"900","start_time":{"start":"2025-10-26","end":"2025-11-26"}}	2025-11-25 15:39:17	2025-11-25 15:39:17
763	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/900/edit	GET	82.193.98.50	[]	2025-11-25 15:39:33	2025-11-25 15:39:33
764	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/900	PUT	82.193.98.50	{"name":"\\u041f\\u0435\\u0440\\u0435\\u0440\\u043e\\u0431\\u043a\\u0430","description":null,"department_id":"9","search_terms":null,"is_permitted":"1","norm_type":"1","multiplier_column":"1","in_archive":null,"_token":"WjvCH1RusQXqgQaBVMWMciODrIe5STGt5lB9ChXL","_method":"PUT"}	2025-11-25 15:39:43	2025-11-25 15:39:43
765	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/900/edit	GET	82.193.98.50	[]	2025-11-25 15:39:43	2025-11-25 15:39:43
766	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/900	PUT	82.193.98.50	{"name":"\\u041f\\u0435\\u0440\\u0435\\u0440\\u043e\\u0431\\u043a\\u0430","description":null,"department_id":"9","search_terms":null,"is_permitted":"0","permission_type":"2","trusted_workers":[null],"description_requirement":"1","description_requirement_cb":"on","norm_type":"1","multiplier_column":"1","in_archive":null,"_token":"WjvCH1RusQXqgQaBVMWMciODrIe5STGt5lB9ChXL","_method":"PUT"}	2025-11-25 15:39:50	2025-11-25 15:39:50
767	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/900/edit	GET	82.193.98.50	[]	2025-11-25 15:39:50	2025-11-25 15:39:50
768	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/900	PUT	82.193.98.50	{"name":"\\u041f\\u0435\\u0440\\u0435\\u0440\\u043e\\u0431\\u043a\\u0430","description":null,"department_id":"9","search_terms":null,"is_permitted":"0","permission_type":"2","trusted_workers":[null],"description_requirement":"1","description_requirement_cb":"on","norm_type":"1","multiplier_column":"1","in_archive":null,"_token":"WjvCH1RusQXqgQaBVMWMciODrIe5STGt5lB9ChXL","_method":"PUT"}	2025-11-25 15:39:52	2025-11-25 15:39:52
769	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/900/edit	GET	82.193.98.50	[]	2025-11-25 15:39:52	2025-11-25 15:39:52
770	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/900	PUT	82.193.98.50	{"name":"\\u041f\\u0435\\u0440\\u0435\\u0440\\u043e\\u0431\\u043a\\u0430","description":null,"department_id":"9","search_terms":null,"is_permitted":"0","permission_type":"2","trusted_workers":[null],"description_requirement":"1","description_requirement_cb":"on","norm_type":"1","multiplier_column":"1","in_archive":null,"_token":"WjvCH1RusQXqgQaBVMWMciODrIe5STGt5lB9ChXL","_method":"PUT"}	2025-11-25 15:40:09	2025-11-25 15:40:09
771	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/900/edit	GET	82.193.98.50	[]	2025-11-25 15:40:09	2025-11-25 15:40:09
772	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/900	PUT	82.193.98.50	{"name":"\\u041f\\u0435\\u0440\\u0435\\u0440\\u043e\\u0431\\u043a\\u0430","description":null,"department_id":"9","search_terms":null,"is_permitted":"1","norm_type":"1","multiplier_column":"1","in_archive":null,"_token":"WjvCH1RusQXqgQaBVMWMciODrIe5STGt5lB9ChXL","_method":"PUT"}	2025-11-25 15:40:15	2025-11-25 15:40:15
773	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works	GET	82.193.98.50	{"operation_filter":"900","start_time":{"start":"2025-10-26","end":"2025-11-26"}}	2025-11-25 15:40:16	2025-11-25 15:40:16
774	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-25 15:40:26	2025-11-25 15:40:26
775	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	{"department_id":null,"search_terms":null,"id":"900"}	2025-11-25 15:40:33	2025-11-25 15:40:33
776	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	82.193.98.50	[]	2025-11-25 15:40:36	2025-11-25 15:40:36
777	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	82.193.98.50	{"start_time":{"start":null,"end":null},"workDayDepartment":{"department_id":null},"search_terms":null,"worker_id":["547586388"]}	2025-11-25 15:40:43	2025-11-25 15:40:43
778	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk	GET	193.239.153.169	[]	2025-11-25 15:58:58	2025-11-25 15:58:58
779	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	193.239.153.169	[]	2025-11-25 15:59:00	2025-11-25 15:59:00
780	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days/23	GET	193.239.153.169	[]	2025-11-25 15:59:22	2025-11-25 15:59:22
781	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	193.239.153.169	[]	2025-11-25 15:59:24	2025-11-25 15:59:24
782	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days/24	GET	193.239.153.169	[]	2025-11-25 15:59:26	2025-11-25 15:59:26
783	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	193.239.153.169	[]	2025-11-25 15:59:28	2025-11-25 15:59:28
784	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	193.239.153.169	{"page":"2"}	2025-11-25 16:00:04	2025-11-25 16:00:04
785	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	193.239.153.169	{"page":"1"}	2025-11-25 16:00:08	2025-11-25 16:00:08
786	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	193.239.153.169	{"page":"1"}	2025-11-25 16:00:21	2025-11-25 16:00:21
787	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	193.239.153.169	{"start_time":{"start":null,"end":null},"workDayDepartment":{"department_id":null},"search_terms":null,"worker_id":["1809318229"]}	2025-11-25 16:01:15	2025-11-25 16:01:15
788	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	193.239.153.169	{"start_time":{"start":null,"end":null},"workDayDepartment":{"department_id":null},"search_terms":null,"worker_id":["652782105"]}	2025-11-25 16:01:28	2025-11-25 16:01:28
789	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	193.239.153.169	{"start_time":{"start":null,"end":null},"workDayDepartment":{"department_id":null},"search_terms":null,"worker_id":["1412145236"]}	2025-11-25 16:01:41	2025-11-25 16:01:41
790	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days/39	GET	193.239.153.169	[]	2025-11-25 16:01:51	2025-11-25 16:01:51
791	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	193.239.153.169	[]	2025-11-25 17:55:53	2025-11-25 17:55:53
792	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days/29	GET	193.239.153.169	[]	2025-11-25 17:56:00	2025-11-25 17:56:00
793	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	193.239.153.169	[]	2025-11-25 18:06:51	2025-11-25 18:06:51
794	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk	GET	94.176.198.158	[]	2025-11-26 07:34:40	2025-11-26 07:34:40
795	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.158	[]	2025-11-26 07:34:44	2025-11-26 07:34:44
796	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	94.176.198.158	[]	2025-11-26 07:34:48	2025-11-26 07:34:48
835	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days/19	GET	82.193.98.50	[]	2025-11-26 09:28:48	2025-11-26 09:28:48
915	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days/48	GET	94.176.198.158	[]	2025-11-26 15:13:20	2025-11-26 15:13:20
797	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	94.176.198.158	{"name":"122\\t\\u041f\\u043e\\u0432\\u043d\\u0430 \\u0437\\u0431\\u0456\\u0440\\u043a\\u0430 \\u0437 \\u043f\\u0456\\u0434\\u0433\\u043e\\u0442\\u043e\\u0432\\u043b\\u0435\\u043d\\u043e\\u044e \\u041f\\u0406","description":null,"department_id":"4","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"321","in_archive":"0","_token":"2BpxPu7jYGvd7ZnWTYRueIDPcaXVugzH7N1VWYlK"}	2025-11-26 07:35:13	2025-11-26 07:35:13
798	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.158	[]	2025-11-26 07:35:13	2025-11-26 07:35:13
799	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	94.176.198.158	[]	2025-11-26 07:36:34	2025-11-26 07:36:34
800	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	94.176.198.158	{"name":"29\\t\\u0422\\u0435\\u0441\\u0442\\u0443\\u0432\\u0430\\u043d\\u043d\\u044f \\u0434\\u0440\\u043e\\u043d\\u0430","description":null,"department_id":"5","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"20","in_archive":"0","_token":"2BpxPu7jYGvd7ZnWTYRueIDPcaXVugzH7N1VWYlK"}	2025-11-26 07:36:48	2025-11-26 07:36:48
801	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.158	[]	2025-11-26 07:36:48	2025-11-26 07:36:48
802	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/80/edit	GET	94.176.198.158	[]	2025-11-26 08:08:20	2025-11-26 08:08:20
803	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/80	PUT	94.176.198.158	{"name":"476\\t\\u0422\\u0435\\u0440\\u043c\\u043e\\u0443\\u0441\\u0430\\u0434\\u043a\\u0430 \\u043d\\u0430 \\u041a\\u041c","description":null,"department_id":"1","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"40","in_archive":null,"_token":"2BpxPu7jYGvd7ZnWTYRueIDPcaXVugzH7N1VWYlK","_method":"PUT"}	2025-11-26 08:08:27	2025-11-26 08:08:27
804	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.158	[]	2025-11-26 08:08:27	2025-11-26 08:08:27
805	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	94.176.198.158	[]	2025-11-26 08:12:31	2025-11-26 08:12:31
806	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	94.176.198.158	{"name":"535\\t\\u0423\\u043f\\u0430\\u043a\\u043e\\u0432\\u043a\\u0430 \\u0433\\u0440\\u0443\\u043f. \\u043a\\u043e\\u0440. 15\\u2019\\u2019 \\u041e\\u041f\\u0422\\u041e","description":null,"department_id":"8","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"192","in_archive":"0","_token":"2BpxPu7jYGvd7ZnWTYRueIDPcaXVugzH7N1VWYlK"}	2025-11-26 08:13:06	2025-11-26 08:13:06
807	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.158	[]	2025-11-26 08:13:06	2025-11-26 08:13:06
808	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk	GET	94.176.198.158	[]	2025-11-26 08:24:23	2025-11-26 08:24:23
809	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk	GET	94.176.198.158	[]	2025-11-26 08:26:37	2025-11-26 08:26:37
810	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.158	[]	2025-11-26 08:26:39	2025-11-26 08:26:39
811	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	94.176.198.158	[]	2025-11-26 08:26:53	2025-11-26 08:26:53
812	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	94.176.198.158	{"name":"627\\t\\u0423\\u043f\\u0430\\u043a\\u043e\\u0432\\u043a\\u0430 \\u0433\\u0440\\u0443\\u043f. \\u043a\\u043e\\u0440. 15\\u2019\\u2019 \\u0437 \\u0434\\u043e\\u043a\\u0443\\u043c\\u0435\\u043d\\u0442\\u0430\\u0446\\u0456\\u0454\\u044e","description":null,"department_id":"8","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"260","in_archive":"0","_token":"s62t4z0CJ7zoFqApcR9sYXHbKSyG9dfUYC5WnbKt"}	2025-11-26 08:27:25	2025-11-26 08:27:25
813	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.158	[]	2025-11-26 08:27:25	2025-11-26 08:27:25
814	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk	GET	82.193.98.50	[]	2025-11-26 09:18:32	2025-11-26 09:18:32
815	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	82.193.98.50	[]	2025-11-26 09:18:38	2025-11-26 09:18:38
816	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk	GET	82.193.98.50	[]	2025-11-26 09:20:30	2025-11-26 09:20:30
817	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	82.193.98.50	[]	2025-11-26 09:20:33	2025-11-26 09:20:33
818	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk	GET	82.193.98.50	[]	2025-11-26 09:26:43	2025-11-26 09:26:43
819	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	82.193.98.50	[]	2025-11-26 09:26:47	2025-11-26 09:26:47
820	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	82.193.98.50	{"start_time":{"start":null,"end":null},"workDayDepartment":{"department_id":null},"search_terms":null,"worker_id":["854336769"]}	2025-11-26 09:26:54	2025-11-26 09:26:54
821	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days/19	GET	82.193.98.50	[]	2025-11-26 09:27:31	2025-11-26 09:27:31
822	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works/create	GET	82.193.98.50	{"work_day_id":"19"}	2025-11-26 09:27:33	2025-11-26 09:27:33
823	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days/19	GET	82.193.98.50	[]	2025-11-26 09:27:45	2025-11-26 09:27:45
824	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works	POST	82.193.98.50	{"work_day_id":"19","start_time":"2025-11-24 08:00:00","finish_time":"2025-11-24 19:20:00","operation_id":"101","search_terms":null,"result":"1","pause_duration":"0","_token":"fRg988Z6RO9PBgtyz0dK05Bauuprw09mMOVRfd2H"}	2025-11-26 09:28:18	2025-11-26 09:28:18
825	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days/19	GET	82.193.98.50	[]	2025-11-26 09:28:19	2025-11-26 09:28:19
826	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works/92/edit	GET	82.193.98.50	[]	2025-11-26 09:28:25	2025-11-26 09:28:25
827	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works/92	PUT	82.193.98.50	{"work_day_id":"19","start_time":"2025-11-24 08:00:00","finish_time":"2025-11-24 19:20:00","operation_id":"101","search_terms":null,"result":"1","pause_duration":"0","_token":"fRg988Z6RO9PBgtyz0dK05Bauuprw09mMOVRfd2H","_method":"PUT"}	2025-11-26 09:28:26	2025-11-26 09:28:26
828	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works	GET	82.193.98.50	[]	2025-11-26 09:28:27	2025-11-26 09:28:27
829	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works	GET	82.193.98.50	{"start_time":{"start":null,"end":null},"workDay":{"worker_id":["854336769"]}}	2025-11-26 09:28:36	2025-11-26 09:28:36
830	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	82.193.98.50	[]	2025-11-26 09:28:38	2025-11-26 09:28:38
831	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/86/edit	GET	94.176.198.158	[]	2025-11-26 09:28:42	2025-11-26 09:28:42
832	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	82.193.98.50	{"start_time":{"start":null,"end":null},"workDayDepartment":{"department_id":null},"search_terms":null,"worker_id":["854336769"]}	2025-11-26 09:28:45	2025-11-26 09:28:45
833	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/86	PUT	94.176.198.158	{"name":"191\\t\\u041f\\u0456\\u0434\\u0433\\u043e\\u0442\\u0443\\u0432\\u0430\\u043d\\u043d\\u044f VTX TBS UP32","description":null,"department_id":"1","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"76","in_archive":null,"_token":"s62t4z0CJ7zoFqApcR9sYXHbKSyG9dfUYC5WnbKt","_method":"PUT"}	2025-11-26 09:28:47	2025-11-26 09:28:47
834	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.158	[]	2025-11-26 09:28:47	2025-11-26 09:28:47
836	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	82.193.98.50	{"start_time":{"start":null,"end":null},"workDayDepartment":{"department_id":null},"search_terms":null,"worker_id":["854336769"]}	2025-11-26 09:30:32	2025-11-26 09:30:32
837	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days/34	GET	82.193.98.50	[]	2025-11-26 09:30:33	2025-11-26 09:30:33
838	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	82.193.98.50	{"start_time":{"start":null,"end":null},"workDayDepartment":{"department_id":null},"search_terms":null,"worker_id":["854336769"]}	2025-11-26 09:31:05	2025-11-26 09:31:05
839	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days/19	GET	82.193.98.50	[]	2025-11-26 09:31:07	2025-11-26 09:31:07
840	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	82.193.98.50	{"start_time":{"start":null,"end":null},"workDayDepartment":{"department_id":null},"search_terms":null,"worker_id":["854336769"]}	2025-11-26 09:34:09	2025-11-26 09:34:09
841	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days/34	GET	82.193.98.50	[]	2025-11-26 09:34:10	2025-11-26 09:34:10
842	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works/22/edit	GET	82.193.98.50	[]	2025-11-26 09:34:13	2025-11-26 09:34:13
843	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days/34	GET	82.193.98.50	[]	2025-11-26 09:34:16	2025-11-26 09:34:16
844	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days/34/edit	GET	82.193.98.50	[]	2025-11-26 09:34:18	2025-11-26 09:34:18
845	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	82.193.98.50	[]	2025-11-26 09:38:09	2025-11-26 09:38:09
846	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	82.193.98.50	{"start_time":{"start":null,"end":null},"workDayDepartment":{"department_id":null},"search_terms":null,"worker_id":["420293854"]}	2025-11-26 09:38:18	2025-11-26 09:38:18
847	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days/59	GET	82.193.98.50	[]	2025-11-26 09:38:21	2025-11-26 09:38:21
848	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk	GET	94.176.198.158	[]	2025-11-26 11:12:01	2025-11-26 11:12:01
849	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.158	[]	2025-11-26 11:12:09	2025-11-26 11:12:09
850	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/105/edit	GET	94.176.198.158	[]	2025-11-26 11:12:16	2025-11-26 11:12:16
851	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/105	PUT	94.176.198.158	{"name":"627\\t\\u0423\\u043f\\u0430\\u043a\\u043e\\u0432\\u043a\\u0430 \\u0433\\u0440\\u0443\\u043f. \\u043a\\u043e\\u0440. 15\\u2019\\u2019 \\u0437 \\u0434\\u043e\\u043a\\u0443\\u043c\\u0435\\u043d\\u0442\\u0430\\u0446\\u0456\\u0454\\u044e","description":null,"department_id":"8","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"1300","in_archive":null,"_token":"ZA3iWFWLBgBnu5q6wejNTEoDNtwDaMhjoQcCSrVJ","_method":"PUT"}	2025-11-26 11:12:25	2025-11-26 11:12:25
852	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.158	[]	2025-11-26 11:12:25	2025-11-26 11:12:25
853	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk	GET	94.176.198.158	[]	2025-11-26 12:37:47	2025-11-26 12:37:47
854	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.158	[]	2025-11-26 12:37:57	2025-11-26 12:37:57
855	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	94.176.198.158	[]	2025-11-26 12:38:01	2025-11-26 12:38:01
856	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	94.176.198.158	{"name":"334\\t\\u0420\\u043e\\u0437\\u043f\\u0430\\u043a\\u0443\\u0432\\u0430\\u043d\\u043d\\u044f \\u043a\\u0430\\u043c\\u0435\\u0440 1","description":null,"department_id":"1","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"24","in_archive":"0","_token":"ZA3iWFWLBgBnu5q6wejNTEoDNtwDaMhjoQcCSrVJ"}	2025-11-26 12:38:28	2025-11-26 12:38:28
857	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.158	[]	2025-11-26 12:38:28	2025-11-26 12:38:28
858	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	94.176.198.158	[]	2025-11-26 12:38:47	2025-11-26 12:38:47
859	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	94.176.198.158	{"name":"355\\t\\u0420\\u043e\\u0437\\u043f\\u0430\\u043a\\u0443\\u0432\\u0430\\u043d\\u043d\\u044f \\u043a\\u0430\\u043c\\u0435\\u0440 2","description":null,"department_id":"1","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"20","in_archive":"0","_token":"ZA3iWFWLBgBnu5q6wejNTEoDNtwDaMhjoQcCSrVJ"}	2025-11-26 12:39:03	2025-11-26 12:39:03
860	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.158	[]	2025-11-26 12:39:03	2025-11-26 12:39:03
861	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	94.176.198.158	[]	2025-11-26 12:39:38	2025-11-26 12:39:38
862	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	94.176.198.158	{"name":"417\\t\\u0420\\u043e\\u0437\\u043f\\u0430\\u043a\\u043e\\u0432\\u043a\\u0430 \\u043a\\u0430\\u043c\\u0435\\u0440 3","description":null,"department_id":"1","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"25","in_archive":"0","_token":"ZA3iWFWLBgBnu5q6wejNTEoDNtwDaMhjoQcCSrVJ"}	2025-11-26 12:39:50	2025-11-26 12:39:50
863	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.158	[]	2025-11-26 12:39:50	2025-11-26 12:39:50
864	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk	GET	5.248.177.245	[]	2025-11-26 14:01:05	2025-11-26 14:01:05
865	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	5.248.177.245	[]	2025-11-26 14:01:13	2025-11-26 14:01:13
866	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	5.248.177.245	{"start_time":{"start":null,"end":null},"workDayDepartment":{"department_id":null},"search_terms":null,"worker_id":["854336769"]}	2025-11-26 14:01:50	2025-11-26 14:01:50
867	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days/19	GET	5.248.177.245	[]	2025-11-26 14:01:54	2025-11-26 14:01:54
868	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	5.248.177.245	[]	2025-11-26 14:33:19	2025-11-26 14:33:19
869	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk	GET	94.176.198.158	[]	2025-11-26 15:02:24	2025-11-26 15:02:24
870	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	94.176.198.158	[]	2025-11-26 15:02:26	2025-11-26 15:02:26
871	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	94.176.198.158	{"start_time":{"start":null,"end":null},"workDayDepartment":{"department_id":null},"search_terms":null,"worker_id":["854336769"]}	2025-11-26 15:02:41	2025-11-26 15:02:41
872	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	94.176.198.158	{"start_time":{"start":null,"end":null},"workDayDepartment":{"department_id":null},"search_terms":null,"worker_id":["854336769"]}	2025-11-26 15:02:42	2025-11-26 15:02:42
873	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days/19	GET	94.176.198.158	[]	2025-11-26 15:02:45	2025-11-26 15:02:45
874	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works/92/edit	GET	94.176.198.158	[]	2025-11-26 15:02:54	2025-11-26 15:02:54
875	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works/92	PUT	94.176.198.158	{"work_day_id":"19","start_time":"2025-11-24 08:00:00","finish_time":"2025-11-24 19:20:00","operation_id":"101","search_terms":null,"result":"1","pause_duration":"0","_token":"AVzFsvf7mwQD7hxLqy4NGPKJbp5p8JtDiId8YZ0P","_method":"PUT"}	2025-11-26 15:02:57	2025-11-26 15:02:57
876	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	94.176.198.158	{"search_terms":null,"start_time":{"start":null,"end":null},"workDayDepartment":{"department_id":null},"worker_id":["854336769"]}	2025-11-26 15:02:58	2025-11-26 15:02:58
877	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days/19	GET	94.176.198.158	[]	2025-11-26 15:03:04	2025-11-26 15:03:04
878	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	94.176.198.158	{"search_terms":null,"start_time":{"start":null,"end":null},"workDayDepartment":{"department_id":null},"worker_id":["854336769"]}	2025-11-26 15:03:13	2025-11-26 15:03:13
879	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days/34	GET	94.176.198.158	[]	2025-11-26 15:03:15	2025-11-26 15:03:15
880	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works/22/edit	GET	94.176.198.158	[]	2025-11-26 15:03:18	2025-11-26 15:03:18
881	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works/22	PUT	94.176.198.158	{"work_day_id":"34","start_time":"2025-11-25 08:18:00","finish_time":"2025-11-25 17:40:05","operation_id":"101","search_terms":null,"result":"10","pause_duration":"0","_token":"AVzFsvf7mwQD7hxLqy4NGPKJbp5p8JtDiId8YZ0P","_method":"PUT"}	2025-11-26 15:03:21	2025-11-26 15:03:21
882	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	94.176.198.158	{"search_terms":null,"start_time":{"start":null,"end":null},"workDayDepartment":{"department_id":null},"worker_id":["854336769"]}	2025-11-26 15:03:21	2025-11-26 15:03:21
883	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days/34	GET	94.176.198.158	[]	2025-11-26 15:03:24	2025-11-26 15:03:24
884	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	94.176.198.158	{"search_terms":null,"start_time":{"start":null,"end":null},"workDayDepartment":{"department_id":null},"worker_id":["854336769"]}	2025-11-26 15:03:49	2025-11-26 15:03:49
885	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days/19/edit	GET	94.176.198.158	[]	2025-11-26 15:04:07	2025-11-26 15:04:07
886	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	94.176.198.158	{"search_terms":null,"start_time":{"start":null,"end":null},"workDayDepartment":{"department_id":null},"worker_id":["854336769"]}	2025-11-26 15:04:14	2025-11-26 15:04:14
887	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days/19	GET	94.176.198.158	[]	2025-11-26 15:04:18	2025-11-26 15:04:18
888	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	94.176.198.158	[]	2025-11-26 15:06:55	2025-11-26 15:06:55
889	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	94.176.198.158	{"start_time":{"start":null,"end":null},"workDayDepartment":{"department_id":null},"search_terms":null,"worker_id":["420293854"]}	2025-11-26 15:07:46	2025-11-26 15:07:46
890	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days/59	GET	94.176.198.158	[]	2025-11-26 15:07:55	2025-11-26 15:07:55
891	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works/70/edit	GET	94.176.198.158	[]	2025-11-26 15:07:58	2025-11-26 15:07:58
892	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works/70	PUT	94.176.198.158	{"work_day_id":"59","start_time":"2025-11-25 09:05:46","finish_time":"2025-11-25 18:26:17","operation_id":"901","search_terms":null,"result":"20","pause_duration":"963","_token":"AVzFsvf7mwQD7hxLqy4NGPKJbp5p8JtDiId8YZ0P","_method":"PUT"}	2025-11-26 15:07:59	2025-11-26 15:07:59
893	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	94.176.198.158	{"search_terms":null,"start_time":{"start":null,"end":null},"workDayDepartment":{"department_id":null},"worker_id":["420293854"]}	2025-11-26 15:07:59	2025-11-26 15:07:59
894	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days/59	GET	94.176.198.158	[]	2025-11-26 15:08:02	2025-11-26 15:08:02
895	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	94.176.198.158	[]	2025-11-26 15:09:21	2025-11-26 15:09:21
896	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	94.176.198.158	{"start_time":{"start":null,"end":null},"workDayDepartment":{"department_id":null},"search_terms":null,"worker_id":["438705457"]}	2025-11-26 15:09:27	2025-11-26 15:09:27
897	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days/35	GET	94.176.198.158	[]	2025-11-26 15:09:30	2025-11-26 15:09:30
898	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days/35/edit	GET	94.176.198.158	[]	2025-11-26 15:09:38	2025-11-26 15:09:38
899	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days/35	PUT	94.176.198.158	{"worker_id":"438705457","search_terms":null,"start_time":"2025-11-25 11:52:36","finish_time":"2025-11-25 17:55:31","in_shelter_time":"0","work_day_department_selection":"7","_token":"AVzFsvf7mwQD7hxLqy4NGPKJbp5p8JtDiId8YZ0P","_method":"PUT"}	2025-11-26 15:09:43	2025-11-26 15:09:43
900	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	94.176.198.158	[]	2025-11-26 15:09:43	2025-11-26 15:09:43
901	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	94.176.198.158	{"start_time":{"start":null,"end":null},"workDayDepartment":{"department_id":null},"search_terms":null,"worker_id":["438705457"]}	2025-11-26 15:10:06	2025-11-26 15:10:06
902	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days/35	GET	94.176.198.158	[]	2025-11-26 15:10:10	2025-11-26 15:10:10
903	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works/23/edit	GET	94.176.198.158	[]	2025-11-26 15:10:17	2025-11-26 15:10:17
904	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days/35	GET	94.176.198.158	[]	2025-11-26 15:10:22	2025-11-26 15:10:22
905	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk	GET	94.176.198.158	[]	2025-11-26 15:11:29	2025-11-26 15:11:29
906	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.158	[]	2025-11-26 15:11:37	2025-11-26 15:11:37
907	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	94.176.198.158	[]	2025-11-26 15:12:21	2025-11-26 15:12:21
908	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	94.176.198.158	{"start_time":{"start":null,"end":null},"workDayDepartment":{"department_id":null},"search_terms":null,"worker_id":["689340169"]}	2025-11-26 15:12:29	2025-11-26 15:12:29
909	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days/48	GET	94.176.198.158	[]	2025-11-26 15:12:51	2025-11-26 15:12:51
910	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days/48	GET	94.176.198.158	[]	2025-11-26 15:12:51	2025-11-26 15:12:51
911	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days/48	GET	94.176.198.158	[]	2025-11-26 15:12:52	2025-11-26 15:12:52
912	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works/56/edit	GET	94.176.198.158	[]	2025-11-26 15:13:15	2025-11-26 15:13:15
913	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works/56	PUT	94.176.198.158	{"work_day_id":"48","start_time":"2025-11-25 09:38:00","finish_time":"2025-11-25 12:22:06","operation_id":"900","search_terms":null,"result":"1","pause_duration":"20","_token":"AVzFsvf7mwQD7hxLqy4NGPKJbp5p8JtDiId8YZ0P","_method":"PUT"}	2025-11-26 15:13:16	2025-11-26 15:13:16
914	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	94.176.198.158	{"search_terms":null,"start_time":{"start":null,"end":null},"workDayDepartment":{"department_id":null},"worker_id":["689340169"]}	2025-11-26 15:13:17	2025-11-26 15:13:17
916	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	94.176.198.158	[]	2025-11-26 15:17:55	2025-11-26 15:17:55
917	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	94.176.198.158	{"start_time":{"start":null,"end":null},"workDayDepartment":{"department_id":null},"search_terms":null,"worker_id":["958194770"]}	2025-11-26 15:18:00	2025-11-26 15:18:00
918	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days/65	GET	94.176.198.158	[]	2025-11-26 15:18:04	2025-11-26 15:18:04
919	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works/create	GET	94.176.198.158	{"work_day_id":"65"}	2025-11-26 15:18:56	2025-11-26 15:18:56
920	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days/65	GET	94.176.198.158	[]	2025-11-26 15:20:04	2025-11-26 15:20:04
921	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	94.176.198.158	{"start_time":{"start":null,"end":null},"workDayDepartment":{"department_id":null},"search_terms":null,"worker_id":["958194770"]}	2025-11-26 15:20:04	2025-11-26 15:20:04
922	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days/1	GET	94.176.198.158	[]	2025-11-26 15:20:12	2025-11-26 15:20:12
923	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	94.176.198.158	{"start_time":{"start":null,"end":null},"workDayDepartment":{"department_id":null},"search_terms":null,"worker_id":["958194770"]}	2025-11-26 15:21:55	2025-11-26 15:21:55
924	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days/30	GET	94.176.198.158	[]	2025-11-26 15:22:04	2025-11-26 15:22:04
925	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works/17/edit	GET	94.176.198.158	[]	2025-11-26 15:22:07	2025-11-26 15:22:07
926	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works/17	PUT	94.176.198.158	{"work_day_id":"30","start_time":"2025-11-25 09:14:25","finish_time":"2025-11-25 17:28:59","operation_id":"900","search_terms":null,"result":"1","pause_duration":"0","_token":"AVzFsvf7mwQD7hxLqy4NGPKJbp5p8JtDiId8YZ0P","_method":"PUT"}	2025-11-26 15:22:09	2025-11-26 15:22:09
927	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	94.176.198.158	{"search_terms":null,"start_time":{"start":null,"end":null},"workDayDepartment":{"department_id":null},"worker_id":["958194770"]}	2025-11-26 15:22:09	2025-11-26 15:22:09
928	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	94.176.198.158	{"start_time":{"start":null,"end":null},"workDayDepartment":{"department_id":null},"search_terms":null,"worker_id":["729610759"]}	2025-11-26 15:23:55	2025-11-26 15:23:55
929	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days/27/edit	GET	94.176.198.158	[]	2025-11-26 15:23:57	2025-11-26 15:23:57
930	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	94.176.198.158	{"start_time":{"start":null,"end":null},"workDayDepartment":{"department_id":null},"search_terms":null,"worker_id":["729610759"]}	2025-11-26 15:24:10	2025-11-26 15:24:10
931	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days/27	GET	94.176.198.158	[]	2025-11-26 15:24:14	2025-11-26 15:24:14
932	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	94.176.198.158	{"start_time":{"start":null,"end":null},"workDayDepartment":{"department_id":null},"search_terms":null,"worker_id":["729610759"]}	2025-11-26 15:24:19	2025-11-26 15:24:19
933	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days/27/edit	GET	94.176.198.158	[]	2025-11-26 15:24:27	2025-11-26 15:24:27
934	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	94.176.198.158	[]	2025-11-26 15:25:20	2025-11-26 15:25:20
935	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	94.176.198.158	{"start_time":{"start":null,"end":null},"workDayDepartment":{"department_id":null},"search_terms":null,"worker_id":["547586388"]}	2025-11-26 15:25:26	2025-11-26 15:25:26
936	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days/29	GET	94.176.198.158	[]	2025-11-26 15:25:28	2025-11-26 15:25:28
937	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works/15/edit	GET	94.176.198.158	[]	2025-11-26 15:25:30	2025-11-26 15:25:30
938	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works/15	PUT	94.176.198.158	{"work_day_id":"29","start_time":"2025-11-25 10:00:00","finish_time":"2025-11-25 12:17:14","operation_id":"900","search_terms":null,"result":"1","pause_duration":"0","_token":"AVzFsvf7mwQD7hxLqy4NGPKJbp5p8JtDiId8YZ0P","_method":"PUT"}	2025-11-26 15:25:32	2025-11-26 15:25:32
939	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	94.176.198.158	{"search_terms":null,"start_time":{"start":null,"end":null},"workDayDepartment":{"department_id":null},"worker_id":["547586388"]}	2025-11-26 15:25:32	2025-11-26 15:25:32
940	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days/29/edit	GET	94.176.198.158	[]	2025-11-26 15:25:34	2025-11-26 15:25:34
941	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	94.176.198.158	{"search_terms":null,"start_time":{"start":null,"end":null},"workDayDepartment":{"department_id":null},"worker_id":["547586388"]}	2025-11-26 15:25:36	2025-11-26 15:25:36
942	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days/29	GET	94.176.198.158	[]	2025-11-26 15:25:38	2025-11-26 15:25:38
943	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	94.176.198.158	{"search_terms":null,"start_time":{"start":null,"end":null},"workDayDepartment":{"department_id":null},"worker_id":["547586388"]}	2025-11-26 15:25:42	2025-11-26 15:25:42
944	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days/71	GET	94.176.198.158	[]	2025-11-26 15:25:43	2025-11-26 15:25:43
945	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	94.176.198.158	{"search_terms":null,"start_time":{"start":null,"end":null},"workDayDepartment":{"department_id":null},"worker_id":["547586388"]}	2025-11-26 15:25:47	2025-11-26 15:25:47
946	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/workers	GET	94.176.198.158	[]	2025-11-26 15:27:22	2025-11-26 15:27:22
947	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/workers	GET	94.176.198.158	{"first_name":"\\u044e\\u0440\\u0456\\u0439","last_name":"\\u0434\\u0443\\u043a\\u0430","start_work_time":null}	2025-11-26 15:27:35	2025-11-26 15:27:35
948	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/workers	GET	94.176.198.158	{"first_name":null,"last_name":"\\u0434\\u0443\\u043a\\u0430","start_work_time":null}	2025-11-26 15:27:39	2025-11-26 15:27:39
949	3	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk	GET	185.155.88.55	[]	2025-11-26 17:00:15	2025-11-26 17:00:15
950	3	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/workers	GET	185.155.88.55	[]	2025-11-26 17:00:20	2025-11-26 17:00:20
951	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk	GET	94.176.198.158	[]	2025-11-26 17:01:05	2025-11-26 17:01:05
952	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/workers	GET	94.176.198.158	[]	2025-11-26 17:02:31	2025-11-26 17:02:31
953	3	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/workers/7495000901	PUT	185.155.88.55	{"_method":"PUT","_edit_inline":true,"after-save":"exit","shift_column":"4"}	2025-11-26 17:02:45	2025-11-26 17:02:45
954	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk	GET	194.28.102.46	[]	2025-11-26 19:14:38	2025-11-26 19:14:38
955	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	194.28.102.46	[]	2025-11-26 19:14:41	2025-11-26 19:14:41
956	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works	GET	194.28.102.46	[]	2025-11-26 19:14:51	2025-11-26 19:14:51
957	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works	GET	194.28.102.46	[]	2025-11-26 19:14:56	2025-11-26 19:14:56
958	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works	GET	194.28.102.46	{"start_time":{"start":null,"end":null},"search_terms":null,"operation_filter":"60"}	2025-11-26 19:15:09	2025-11-26 19:15:09
959	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	194.28.102.46	[]	2025-11-26 19:15:53	2025-11-26 19:15:53
960	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/47/edit	GET	194.28.102.46	[]	2025-11-26 19:16:45	2025-11-26 19:16:45
961	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/47	PUT	194.28.102.46	{"name":"\\u041c\\u043e\\u043d\\u0442\\u0430\\u0436 \\u0432\\u0456\\u0431\\u0440\\u043e\\u0433\\u0443\\u043c\\u043e\\u043a ESC SL","description":null,"department_id":"1","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":null,"_token":"m9Z8rZtA3ouvyftnW7UxltZnbYgDYlyqAEYG92AY","_method":"PUT"}	2025-11-26 19:16:56	2025-11-26 19:16:56
962	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	194.28.102.46	[]	2025-11-26 19:16:56	2025-11-26 19:16:56
963	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk	GET	82.193.98.50	[]	2025-11-27 09:39:08	2025-11-27 09:39:08
964	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-27 09:39:11	2025-11-27 09:39:11
965	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/60/edit	GET	82.193.98.50	[]	2025-11-27 09:39:33	2025-11-27 09:39:33
966	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/60	PUT	82.193.98.50	{"name":"521\\t15\\" \\u041f\\u0456\\u0434\\u0433\\u043e\\u0442\\u0443\\u0432\\u0430\\u043d\\u043d\\u044f ESC 12S","description":null,"department_id":"1","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"70","in_archive":null,"_token":"hv6qt8mNAYsaTFHtTkOYpBdt9P8muO6bPiCGNrnP","_method":"PUT"}	2025-11-27 09:41:35	2025-11-27 09:41:35
967	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-27 09:41:35	2025-11-27 09:41:35
968	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/103/edit	GET	82.193.98.50	[]	2025-11-27 09:42:55	2025-11-27 09:42:55
969	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/103	PUT	82.193.98.50	{"name":"29\\t\\u0422\\u0435\\u0441\\u0442\\u0443\\u0432\\u0430\\u043d\\u043d\\u044f \\u0434\\u0440\\u043e\\u043d\\u0430","description":null,"department_id":"5","search_terms":null,"is_permitted":"1","norm_type":"1","multiplier_column":"1","in_archive":null,"_token":"hv6qt8mNAYsaTFHtTkOYpBdt9P8muO6bPiCGNrnP","_method":"PUT"}	2025-11-27 09:43:04	2025-11-27 09:43:04
970	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-27 09:43:04	2025-11-27 09:43:04
971	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk	GET	82.193.98.50	[]	2025-11-27 09:50:00	2025-11-27 09:50:00
972	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works	GET	82.193.98.50	[]	2025-11-27 09:50:04	2025-11-27 09:50:04
973	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works	GET	82.193.98.50	[]	2025-11-27 09:50:14	2025-11-27 09:50:14
974	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works/318/edit	GET	82.193.98.50	[]	2025-11-27 09:51:30	2025-11-27 09:51:30
975	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-27 09:51:36	2025-11-27 09:51:36
976	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/60/edit	GET	82.193.98.50	[]	2025-11-27 09:51:55	2025-11-27 09:51:55
977	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/60	PUT	82.193.98.50	{"name":"521\\t15\\" \\u041a\\u043e\\u043c\\u043f\\u043b\\u0435\\u043a\\u0442\\u0443\\u0432\\u0430\\u043d\\u043d\\u044f ESC 12S","description":null,"department_id":"1","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"70","in_archive":null,"_token":"Vr51bk2hIdEm1wn2KdFFwlU5TWIOHJWZ9iBCBDZk","_method":"PUT"}	2025-11-27 09:52:10	2025-11-27 09:52:10
978	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-27 09:52:10	2025-11-27 09:52:10
979	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/46	PUT	82.193.98.50	{"_method":"PUT","in_archive":"on","after-save":"exit"}	2025-11-27 09:54:42	2025-11-27 09:54:42
980	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-27 09:54:42	2025-11-27 09:54:42
981	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/47	PUT	82.193.98.50	{"_method":"PUT","in_archive":"on","after-save":"exit"}	2025-11-27 09:54:43	2025-11-27 09:54:43
982	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-27 09:54:43	2025-11-27 09:54:43
983	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/46/edit	GET	82.193.98.50	[]	2025-11-27 09:54:51	2025-11-27 09:54:51
984	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/46	PUT	82.193.98.50	{"name":"\\u041c\\u043e\\u043d\\u0442\\u0430\\u0436 \\u0432\\u0456\\u0431\\u0440\\u043e\\u0433\\u0443\\u043c\\u043e\\u043a FC","description":null,"department_id":"1","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":"on","in_archive_cb":"on","_token":"Vr51bk2hIdEm1wn2KdFFwlU5TWIOHJWZ9iBCBDZk","_method":"PUT"}	2025-11-27 09:54:56	2025-11-27 09:54:56
985	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-27 09:54:56	2025-11-27 09:54:56
986	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/59/edit	GET	82.193.98.50	[]	2025-11-27 09:55:11	2025-11-27 09:55:11
987	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/59	PUT	82.193.98.50	{"name":"329\\t\\u041c\\u043e\\u043d\\u0442\\u0430\\u0436 \\u0432\\u0456\\u0431\\u0440\\u043e\\u0433\\u0443\\u043c\\u043e\\u043a \\u043d\\u0430 FC","description":null,"department_id":"1","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"29","in_archive":"on","in_archive_cb":"on","_token":"Vr51bk2hIdEm1wn2KdFFwlU5TWIOHJWZ9iBCBDZk","_method":"PUT"}	2025-11-27 09:55:14	2025-11-27 09:55:14
988	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-27 09:55:14	2025-11-27 09:55:14
989	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk	GET	82.193.98.50	[]	2025-11-27 10:40:54	2025-11-27 10:40:54
990	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-27 10:40:57	2025-11-27 10:40:57
991	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/105/edit	GET	82.193.98.50	[]	2025-11-27 10:41:07	2025-11-27 10:41:07
992	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/105	PUT	82.193.98.50	{"name":"627\\t\\u0423\\u043f\\u0430\\u043a\\u043e\\u0432\\u043a\\u0430 \\u0433\\u0440\\u0443\\u043f. \\u043a\\u043e\\u0440. 15\\u2019\\u2019 \\u0437 \\u0434\\u043e\\u043a\\u0443\\u043c\\u0435\\u043d\\u0442\\u0430\\u0446\\u0456\\u0454\\u044e","description":null,"department_id":"8","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"1140","in_archive":null,"_token":"ipK46FUPnmGRENtCFM2JAwqlDyC7iMmlhmokKyrt","_method":"PUT"}	2025-11-27 10:41:26	2025-11-27 10:41:26
993	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-27 10:41:26	2025-11-27 10:41:26
994	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/104/edit	GET	82.193.98.50	[]	2025-11-27 10:41:45	2025-11-27 10:41:45
995	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/104	PUT	82.193.98.50	{"name":"535\\t\\u0423\\u043f\\u0430\\u043a\\u043e\\u0432\\u043a\\u0430 \\u0433\\u0440\\u0443\\u043f. \\u043a\\u043e\\u0440. 15\\u2019\\u2019 \\u041e\\u041f\\u0422\\u041e","description":null,"department_id":"8","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"960","in_archive":null,"_token":"ipK46FUPnmGRENtCFM2JAwqlDyC7iMmlhmokKyrt","_method":"PUT"}	2025-11-27 10:42:04	2025-11-27 10:42:04
996	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-27 10:42:04	2025-11-27 10:42:04
997	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/66/edit	GET	82.193.98.50	[]	2025-11-27 10:42:16	2025-11-27 10:42:16
998	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/66	PUT	82.193.98.50	{"name":"487\\t\\u0423\\u043f\\u0430\\u043a\\u043e\\u0432\\u043a\\u0430 \\u0433\\u0440\\u0443\\u043f. \\u043a\\u043e\\u0440\\u043e\\u0431\\u043a\\u0438 15\\u2019\\u2019","description":null,"department_id":"8","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"1100","in_archive":null,"_token":"ipK46FUPnmGRENtCFM2JAwqlDyC7iMmlhmokKyrt","_method":"PUT"}	2025-11-27 10:42:36	2025-11-27 10:42:36
999	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-27 10:42:36	2025-11-27 10:42:36
1000	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	82.193.98.50	[]	2025-11-27 10:51:15	2025-11-27 10:51:15
1001	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	82.193.98.50	{"name":"549\\t\\u041c\\u043e\\u043d\\u0442\\u0430\\u0436 VTX Peak\\t260","description":null,"department_id":"1","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"260","in_archive":"0","_token":"ipK46FUPnmGRENtCFM2JAwqlDyC7iMmlhmokKyrt"}	2025-11-27 10:51:31	2025-11-27 10:51:31
1002	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-27 10:51:31	2025-11-27 10:51:31
1003	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	82.193.98.50	[]	2025-11-27 10:55:13	2025-11-27 10:55:13
1004	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	82.193.98.50	[]	2025-11-27 10:56:10	2025-11-27 10:56:10
1005	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-27 12:10:36	2025-11-27 12:10:36
1006	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	82.193.98.50	[]	2025-11-27 12:12:10	2025-11-27 12:12:10
1007	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	82.193.98.50	{"name":"143\\t\\u041f\\u043e\\u0434\\u043e\\u0432\\u0436\\u0435\\u043d\\u043d\\u044f \\u0434\\u0440\\u043e\\u0442\\u0456\\u0432 VTX","description":null,"department_id":"4","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"210","in_archive":"0","_token":"ipK46FUPnmGRENtCFM2JAwqlDyC7iMmlhmokKyrt"}	2025-11-27 12:12:29	2025-11-27 12:12:29
1008	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-27 12:12:30	2025-11-27 12:12:30
1009	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	82.193.98.50	[]	2025-11-27 12:12:52	2025-11-27 12:12:52
1010	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	82.193.98.50	{"name":"95\\t\\u041f\\u0456\\u0434\\u0433\\u043e\\u0442\\u043e\\u0432\\u043a\\u0430 \\u0434\\u0440\\u043e\\u0442\\u0456\\u0432 \\u0434\\u043e ELRS","description":null,"department_id":"4","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"210","in_archive":"0","_token":"ipK46FUPnmGRENtCFM2JAwqlDyC7iMmlhmokKyrt"}	2025-11-27 12:13:19	2025-11-27 12:13:19
1011	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-27 12:13:20	2025-11-27 12:13:20
1012	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	82.193.98.50	[]	2025-11-27 12:14:07	2025-11-27 12:14:07
1013	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	82.193.98.50	{"name":"18\\t\\u041f\\u0456\\u0434\\u0433\\u043e\\u0442\\u043e\\u0432\\u043a\\u0430 \\u043f\\u043b\\u0430\\u0442\\u0438 ERLS","description":null,"department_id":"4","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"59","in_archive":"0","_token":"ipK46FUPnmGRENtCFM2JAwqlDyC7iMmlhmokKyrt"}	2025-11-27 12:14:32	2025-11-27 12:14:32
1014	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-27 12:14:32	2025-11-27 12:14:32
1015	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	82.193.98.50	[]	2025-11-27 12:15:01	2025-11-27 12:15:01
1016	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	82.193.98.50	{"name":"296\\t\\u041f\\u0430\\u0439\\u043a\\u0430 ELRS \\u0434\\u043e FC","description":null,"department_id":"4","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"50","in_archive":"0","_token":"ipK46FUPnmGRENtCFM2JAwqlDyC7iMmlhmokKyrt"}	2025-11-27 12:15:13	2025-11-27 12:15:13
1017	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-27 12:15:13	2025-11-27 12:15:13
1018	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	{"department_id":"1","search_terms":null,"id":null}	2025-11-27 12:19:38	2025-11-27 12:19:38
1019	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/109/edit	GET	82.193.98.50	[]	2025-11-27 12:19:49	2025-11-27 12:19:49
1020	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/109	PUT	82.193.98.50	{"name":"549\\t\\u041c\\u043e\\u043d\\u0442\\u0430\\u0436 VTX Peak","description":null,"department_id":"1","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"260","in_archive":null,"_token":"ipK46FUPnmGRENtCFM2JAwqlDyC7iMmlhmokKyrt","_method":"PUT"}	2025-11-27 12:19:54	2025-11-27 12:19:54
1021	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	{"department_id":"1","id":null,"search_terms":null}	2025-11-27 12:19:54	2025-11-27 12:19:54
1022	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk	GET	82.193.98.50	[]	2025-11-27 13:57:04	2025-11-27 13:57:04
1023	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-27 13:57:08	2025-11-27 13:57:08
1024	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	82.193.98.50	[]	2025-11-27 13:57:23	2025-11-27 13:57:23
1025	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	82.193.98.50	{"name":"548\\t\\u041c\\u043e\\u043d\\u0442\\u0430\\u0436 \\u0445\\u043e\\u043b\\u0434\\u0435\\u0440\\u0430 \\u043d\\u0430 VTX PeakFPV","description":null,"department_id":"1","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"45","in_archive":"0","_token":"HkLaALdR6py9x1ToLj13m3uPo77Qnxn2PivQDqrX"}	2025-11-27 13:57:37	2025-11-27 13:57:37
1026	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-27 13:57:37	2025-11-27 13:57:37
1027	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/111/edit	GET	82.193.98.50	[]	2025-11-27 14:13:40	2025-11-27 14:13:40
1028	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/111	PUT	82.193.98.50	{"name":"95\\t\\u041f\\u0456\\u0434\\u0433\\u043e\\u0442\\u043e\\u0432\\u043a\\u0430 \\u0434\\u0440\\u043e\\u0442\\u0456\\u0432 \\u0434\\u043e ELRS","description":null,"department_id":"4","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"25","in_archive":null,"_token":"HkLaALdR6py9x1ToLj13m3uPo77Qnxn2PivQDqrX","_method":"PUT"}	2025-11-27 14:14:23	2025-11-27 14:14:23
1029	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-27 14:14:23	2025-11-27 14:14:23
1031	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-11-27 14:47:54	2025-11-27 14:47:54
1032	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk	GET	176.100.9.245	[]	2025-11-27 16:58:50	2025-11-27 16:58:50
1033	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/workers	GET	176.100.9.245	[]	2025-11-27 16:59:12	2025-11-27 16:59:12
1034	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/workers/7054968599/edit	GET	176.100.9.245	[]	2025-11-27 16:59:46	2025-11-27 16:59:46
1035	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/workers/7054968599	PUT	176.100.9.245	{"first_name":"\\u041c\\u0438\\u0445\\u0430\\u0439\\u043b\\u043e","last_name":"\\u0413\\u0430\\u0441\\u043f\\u0435\\u0440\\u0441\\u044c\\u043a\\u0438\\u0439","patronymic":"\\u041c\\u0438\\u0445\\u0430\\u0439\\u043b\\u043e\\u0432\\u0438\\u0447","hurma_id":null,"shift_column":"1","secondary_shift_column":"-1","internship_start_time":"2025-11-24 00:00:00","internship_end_time":"2025-12-24 00:00:00","calculatorAvoidedWorker":{"is_avoided":null},"_token":"7xEGOPwyQQAiezmKdpoptpIJaY6ItQRPxioVrnAw","_method":"PUT"}	2025-11-27 16:59:53	2025-11-27 16:59:53
1036	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/workers	GET	176.100.9.245	[]	2025-11-27 16:59:53	2025-11-27 16:59:53
1037	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	176.100.9.245	[]	2025-11-27 17:49:17	2025-11-27 17:49:17
1038	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/departments	GET	176.100.9.245	[]	2025-11-27 17:57:21	2025-11-27 17:57:21
1039	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk	GET	94.176.198.158	[]	2025-11-28 08:11:53	2025-11-28 08:11:53
1040	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	94.176.198.158	[]	2025-11-28 08:12:47	2025-11-28 08:12:47
1041	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	94.176.198.158	{"start_time":{"start":null,"end":null},"workDayDepartment":{"department_id":null},"search_terms":"\\u043f\\u043e\\u043b\\u043e\\u043d\\u0447\\u0443\\u043a \\u043e\\u043b\\u0435\\u043a\\u0441\\u0456\\u0439"}	2025-11-28 08:13:04	2025-11-28 08:13:04
1042	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	94.176.198.158	{"start_time":{"start":null,"end":null},"workDayDepartment":{"department_id":null},"search_terms":null,"worker_id":["399027689"]}	2025-11-28 08:17:38	2025-11-28 08:17:38
1043	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days/149/edit	GET	94.176.198.158	[]	2025-11-28 08:17:40	2025-11-28 08:17:40
1044	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	94.176.198.158	{"start_time":{"start":null,"end":null},"workDayDepartment":{"department_id":null},"search_terms":null,"worker_id":["399027689"]}	2025-11-28 08:17:47	2025-11-28 08:17:47
1045	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days/149	GET	94.176.198.158	[]	2025-11-28 08:17:49	2025-11-28 08:17:49
1046	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works/530/edit	GET	94.176.198.158	[]	2025-11-28 08:18:55	2025-11-28 08:18:55
1047	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works/530	PUT	94.176.198.158	{"work_day_id":"149","start_time":"2025-11-27 09:30:13","finish_time":"2025-11-27 13:14:36","operation_id":"900","search_terms":null,"result":"1","pause_duration":"20","_token":"2Mr2YqlnTVcC4EqroGJvspBrAlrQinu7rv12nxNj","_method":"PUT"}	2025-11-28 08:19:02	2025-11-28 08:19:02
1048	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	94.176.198.158	{"search_terms":null,"start_time":{"start":null,"end":null},"workDayDepartment":{"department_id":null},"worker_id":["399027689"]}	2025-11-28 08:19:02	2025-11-28 08:19:02
1049	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days/149/edit	GET	94.176.198.158	[]	2025-11-28 08:19:04	2025-11-28 08:19:04
1050	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days/149	PUT	94.176.198.158	{"worker_id":"399027689","search_terms":null,"start_time":"2025-11-27 09:30:31","finish_time":"2025-11-27 18:31:54","in_shelter_time":"0","work_day_department_selection":"5","_token":"2Mr2YqlnTVcC4EqroGJvspBrAlrQinu7rv12nxNj","_method":"PUT"}	2025-11-28 08:19:11	2025-11-28 08:19:11
1051	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	94.176.198.158	{"search_terms":null,"start_time":{"start":null,"end":null},"workDayDepartment":{"department_id":null},"worker_id":["399027689"]}	2025-11-28 08:19:12	2025-11-28 08:19:12
1052	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days/149	GET	94.176.198.158	[]	2025-11-28 08:19:16	2025-11-28 08:19:16
1053	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works/530/edit	GET	94.176.198.158	[]	2025-11-28 08:19:18	2025-11-28 08:19:18
1054	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works/530	PUT	94.176.198.158	{"work_day_id":"149","start_time":"2025-11-27 09:31:13","finish_time":"2025-11-27 13:14:36","operation_id":"900","search_terms":null,"result":"1","pause_duration":"20","_token":"2Mr2YqlnTVcC4EqroGJvspBrAlrQinu7rv12nxNj","_method":"PUT"}	2025-11-28 08:19:23	2025-11-28 08:19:23
1055	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	94.176.198.158	{"search_terms":null,"start_time":{"start":null,"end":null},"workDayDepartment":{"department_id":null},"worker_id":["399027689"]}	2025-11-28 08:19:23	2025-11-28 08:19:23
1056	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	94.176.198.158	{"start_time":{"start":null,"end":null},"workDayDepartment":{"department_id":null},"search_terms":null,"worker_id":["1412145236"]}	2025-11-28 08:22:05	2025-11-28 08:22:05
1057	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days/140	GET	94.176.198.158	[]	2025-11-28 08:23:19	2025-11-28 08:23:19
1058	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works/491/edit	GET	94.176.198.158	[]	2025-11-28 08:23:45	2025-11-28 08:23:45
1059	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works/491	PUT	94.176.198.158	{"work_day_id":"140","start_time":"2025-11-27 11:29:47","finish_time":"2025-11-27 11:29:51","operation_id":"95","search_terms":null,"result":"20","pause_duration":"0","_token":"2Mr2YqlnTVcC4EqroGJvspBrAlrQinu7rv12nxNj","_method":"PUT"}	2025-11-28 08:23:51	2025-11-28 08:23:51
1060	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	94.176.198.158	{"search_terms":null,"start_time":{"start":null,"end":null},"workDayDepartment":{"department_id":null},"worker_id":["1412145236"]}	2025-11-28 08:23:52	2025-11-28 08:23:52
1061	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days/140	GET	94.176.198.158	[]	2025-11-28 08:23:54	2025-11-28 08:23:54
1062	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	94.176.198.158	[]	2025-11-28 08:25:50	2025-11-28 08:25:50
1063	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	94.176.198.158	{"start_time":{"start":null,"end":null},"workDayDepartment":{"department_id":null},"search_terms":null,"worker_id":["260972430"]}	2025-11-28 08:25:56	2025-11-28 08:25:56
1064	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days/133	GET	94.176.198.158	[]	2025-11-28 08:26:03	2025-11-28 08:26:03
1065	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days/133/edit	GET	94.176.198.158	[]	2025-11-28 08:26:09	2025-11-28 08:26:09
1066	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days/133	PUT	94.176.198.158	{"worker_id":"260972430","search_terms":null,"start_time":"2025-11-27 09:14:03","finish_time":"2025-11-27 18:03:43","in_shelter_time":"0","work_day_department_selection":"1","_token":"2Mr2YqlnTVcC4EqroGJvspBrAlrQinu7rv12nxNj","_method":"PUT"}	2025-11-28 08:26:14	2025-11-28 08:26:14
1067	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	94.176.198.158	{"search_terms":null,"start_time":{"start":null,"end":null},"workDayDepartment":{"department_id":null},"worker_id":["260972430"]}	2025-11-28 08:26:15	2025-11-28 08:26:15
1068	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	94.176.198.158	{"start_time":{"start":null,"end":null},"workDayDepartment":{"department_id":null},"search_terms":null,"worker_id":["854336769"]}	2025-11-28 08:32:13	2025-11-28 08:32:13
1069	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk	GET	94.176.198.158	[]	2025-11-28 08:47:24	2025-11-28 08:47:24
1070	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	94.176.198.158	[]	2025-11-28 08:47:27	2025-11-28 08:47:27
1071	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk	GET	94.176.198.158	[]	2025-11-28 12:15:19	2025-11-28 12:15:19
1072	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.158	[]	2025-11-28 12:15:21	2025-11-28 12:15:21
1073	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.158	{"department_id":null,"search_terms":null,"id":null,"f577b467b794c87d9a608403f2a45be9":"yes"}	2025-11-28 12:15:30	2025-11-28 12:15:30
1074	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/46	PUT	94.176.198.158	{"_method":"PUT","in_archive":"off","after-save":"exit"}	2025-11-28 12:15:43	2025-11-28 12:15:43
1075	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.158	{"department_id":null,"search_terms":null,"id":null,"f577b467b794c87d9a608403f2a45be9":"yes"}	2025-11-28 12:15:43	2025-11-28 12:15:43
1076	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/46/edit	GET	94.176.198.158	[]	2025-11-28 12:16:21	2025-11-28 12:16:21
1077	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/46	PUT	94.176.198.158	{"name":"\\u041c\\u043e\\u043d\\u0442\\u0430\\u0436 \\u0432\\u0456\\u0431\\u0440\\u043e\\u0433\\u0443\\u043c\\u043e\\u043a FC","description":null,"department_id":"1","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"29","in_archive":"off","_token":"pWcBUf8jvFgSv3xaDNPefQIrA6nbGiMgR9US55tA","_method":"PUT"}	2025-11-28 12:17:02	2025-11-28 12:17:02
1078	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.158	{"department_id":null,"f577b467b794c87d9a608403f2a45be9":"yes","id":null,"search_terms":null}	2025-11-28 12:17:02	2025-11-28 12:17:02
1079	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk	GET	94.176.198.158	[]	2025-11-29 13:04:21	2025-11-29 13:04:21
1080	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.158	[]	2025-11-29 13:04:25	2025-11-29 13:04:25
1081	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk	GET	94.176.198.158	[]	2025-11-29 15:25:07	2025-11-29 15:25:07
1082	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.158	[]	2025-11-29 15:25:11	2025-11-29 15:25:11
1083	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	94.176.198.158	[]	2025-11-29 15:25:14	2025-11-29 15:25:14
1084	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	94.176.198.158	{"name":"529\\t\\u041f\\u0440\\u043e\\u0448\\u0438\\u0432\\u043a\\u0430\\/\\u0442\\u0435\\u0441\\u0442\\/\\u0431\\u0456\\u043d\\u0434 ESC (\\u043d\\u043e\\u0432\\u0430)","description":null,"department_id":"6","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"180","in_archive":"0","_token":"n6XtVHb207omgiwSdsFNIfAGBoayCTlNuKLR0js6"}	2025-11-29 15:25:55	2025-11-29 15:25:55
1085	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.158	[]	2025-11-29 15:25:55	2025-11-29 15:25:55
1086	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	94.176.198.158	[]	2025-11-29 15:29:20	2025-11-29 15:29:20
1087	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	94.176.198.158	{"name":"579\\t\\u041f\\u0440\\u043e\\u0448\\u0438\\u0432\\u043a\\u0430\\/\\u0442\\u0435\\u0441\\u0442\\/15\\" V.opt.digital","description":null,"department_id":"6","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":"0","_token":"n6XtVHb207omgiwSdsFNIfAGBoayCTlNuKLR0js6"}	2025-11-29 15:29:36	2025-11-29 15:29:36
1088	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.158	[]	2025-11-29 15:29:36	2025-11-29 15:29:36
1089	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk	GET	82.193.98.50	[]	2025-12-01 08:59:29	2025-12-01 08:59:29
1090	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	82.193.98.50	[]	2025-12-01 08:59:31	2025-12-01 08:59:31
1091	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk	GET	94.176.198.158	[]	2025-12-01 08:59:37	2025-12-01 08:59:37
1092	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	82.193.98.50	{"start_time":{"start":null,"end":null},"workDayDepartment":{"department_id":null},"search_terms":null,"worker_id":["544740146"]}	2025-12-01 08:59:38	2025-12-01 08:59:38
1093	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.158	[]	2025-12-01 08:59:40	2025-12-01 08:59:40
1094	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	94.176.198.158	[]	2025-12-01 08:59:42	2025-12-01 08:59:42
1095	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	94.176.198.158	{"name":"446\\tCheck-up FC","description":null,"department_id":"4","search_terms":null,"is_permitted":"1","norm_type":"1","multiplier_column":"1","in_archive":"0","_token":"qPvxFYebt2Oepr8JzrZKnPeKfIO65ffxyjkeMgPa"}	2025-12-01 09:00:14	2025-12-01 09:00:14
1096	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.158	[]	2025-12-01 09:00:14	2025-12-01 09:00:14
1097	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk	GET	82.193.98.50	[]	2025-12-01 09:38:16	2025-12-01 09:38:16
1098	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	82.193.98.50	[]	2025-12-01 09:38:19	2025-12-01 09:38:19
1099	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	82.193.98.50	{"start_time":{"start":null,"end":null},"workDayDepartment":{"department_id":null},"search_terms":null,"worker_id":["544740146"]}	2025-12-01 09:38:31	2025-12-01 09:38:31
1100	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days/205/edit	GET	82.193.98.50	[]	2025-12-01 09:38:49	2025-12-01 09:38:49
1101	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days/205	PUT	82.193.98.50	{"worker_id":"544740146","search_terms":null,"start_time":"2025-11-25 09:26:00","finish_time":"2025-11-25 19:18:09","in_shelter_time":"0","work_day_department_selection":"5","_token":"aCWb91MXicxj1svcrbm8ENHrcsN8sgzK9JSleoUv","_method":"PUT"}	2025-12-01 09:39:10	2025-12-01 09:39:10
1102	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	82.193.98.50	{"search_terms":null,"start_time":{"start":null,"end":null},"workDayDepartment":{"department_id":null},"worker_id":["544740146"]}	2025-12-01 09:39:10	2025-12-01 09:39:10
1103	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days/206/edit	GET	82.193.98.50	[]	2025-12-01 09:39:15	2025-12-01 09:39:15
1104	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days/206	PUT	82.193.98.50	{"worker_id":"544740146","search_terms":null,"start_time":"2025-11-26 08:21:00","finish_time":"2025-11-26 19:35:18","in_shelter_time":"0","work_day_department_selection":"5","_token":"aCWb91MXicxj1svcrbm8ENHrcsN8sgzK9JSleoUv","_method":"PUT"}	2025-12-01 09:39:22	2025-12-01 09:39:22
1105	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	82.193.98.50	{"search_terms":null,"start_time":{"start":null,"end":null},"workDayDepartment":{"department_id":null},"worker_id":["544740146"]}	2025-12-01 09:39:22	2025-12-01 09:39:22
1106	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days/205	GET	82.193.98.50	[]	2025-12-01 09:39:27	2025-12-01 09:39:27
1107	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works/873/edit	GET	82.193.98.50	[]	2025-12-01 09:39:29	2025-12-01 09:39:29
1108	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works/873	PUT	82.193.98.50	{"work_day_id":"205","start_time":"2025-11-25 09:26:00","finish_time":"2025-11-25 19:30:00","operation_id":"900","search_terms":null,"result":"30","pause_duration":"0","_token":"aCWb91MXicxj1svcrbm8ENHrcsN8sgzK9JSleoUv","_method":"PUT"}	2025-12-01 09:39:36	2025-12-01 09:39:36
1109	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works/873/edit	GET	82.193.98.50	[]	2025-12-01 09:39:36	2025-12-01 09:39:36
1110	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works/873	PUT	82.193.98.50	{"work_day_id":"205","start_time":"2025-11-25 09:26:00","finish_time":"2025-11-25 19:30:00","operation_id":"900","search_terms":null,"result":"30","pause_duration":"0","_token":"aCWb91MXicxj1svcrbm8ENHrcsN8sgzK9JSleoUv","_method":"PUT"}	2025-12-01 09:39:45	2025-12-01 09:39:45
1111	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works/873/edit	GET	82.193.98.50	[]	2025-12-01 09:39:45	2025-12-01 09:39:45
1112	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/works/873/edit	GET	82.193.98.50	[]	2025-12-01 09:39:48	2025-12-01 09:39:48
1113	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	82.193.98.50	[]	2025-12-01 09:39:52	2025-12-01 09:39:52
1114	4	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/work_days	GET	82.193.98.50	{"start_time":{"start":null,"end":null},"workDayDepartment":{"department_id":null},"search_terms":null,"worker_id":["544740146"]}	2025-12-01 09:39:58	2025-12-01 09:39:58
1115	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk	GET	94.176.198.158	[]	2025-12-01 10:35:00	2025-12-01 10:35:00
1116	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.158	[]	2025-12-01 10:35:03	2025-12-01 10:35:03
1117	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	94.176.198.158	[]	2025-12-01 10:35:08	2025-12-01 10:35:08
1118	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	94.176.198.158	{"name":"632 \\u0411\\u0430\\u0437\\u043e\\u0432\\u0430 \\u0437\\u0431\\u0456\\u0440\\u043a\\u0430 8\\" PeakFpv \\u0437 \\u041a\\u041c","description":null,"department_id":"5","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":"0","_token":"woLxvr6lgepC5uOuNEAAogPGucpd1pBIwyWrqW45"}	2025-12-01 10:35:36	2025-12-01 10:35:36
1119	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.158	[]	2025-12-01 10:35:36	2025-12-01 10:35:36
1120	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	94.176.198.158	[]	2025-12-01 10:35:39	2025-12-01 10:35:39
1121	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	94.176.198.158	{"name":"633 \\u0411\\u0430\\u0437\\u043e\\u0432\\u0430 \\u0437\\u0431\\u0456\\u0440\\u043a\\u0430 15\\" PeakFpv \\u0437 \\u041a\\u041c","description":null,"department_id":"5","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":"0","_token":"woLxvr6lgepC5uOuNEAAogPGucpd1pBIwyWrqW45"}	2025-12-01 10:35:57	2025-12-01 10:35:57
1122	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.158	[]	2025-12-01 10:35:57	2025-12-01 10:35:57
1123	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk	GET	94.176.198.158	[]	2025-12-01 12:48:41	2025-12-01 12:48:41
1124	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/workers	GET	94.176.198.158	[]	2025-12-01 12:48:56	2025-12-01 12:48:56
1125	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/workers/970421717	PUT	94.176.198.158	{"_method":"PUT","_edit_inline":true,"after-save":"exit","shift_column":"4"}	2025-12-01 12:49:21	2025-12-01 12:49:21
1126	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/workers/711290767	PUT	94.176.198.158	{"_method":"PUT","_edit_inline":true,"after-save":"exit","shift_column":"4"}	2025-12-01 12:49:35	2025-12-01 12:49:35
1127	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk	GET	82.193.98.50	[]	2025-12-01 13:51:12	2025-12-01 13:51:12
1128	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.158	[]	2025-12-01 13:51:16	2025-12-01 13:51:16
1129	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/create	GET	94.176.198.158	[]	2025-12-01 13:51:31	2025-12-01 13:51:31
1130	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	POST	82.193.98.50	{"name":"539\\t\\u041c\\u043e\\u043d\\u0442\\u0430\\u0436 \\u043c\\u0430\\u0443\\u043d\\u0442\\u0443 \\u043d\\u0430 \\u0411\\u0456\\u0442\\u0430 15\\"","description":null,"department_id":"2","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":null,"in_archive":"0","_token":"taKw4uzCZmOsYJhLBaJTQ3YpBAGZtiyNgHjVnsrA"}	2025-12-01 13:53:13	2025-12-01 13:53:13
1131	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	82.193.98.50	[]	2025-12-01 13:53:13	2025-12-01 13:53:13
1132	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk	GET	94.176.198.158	[]	2025-12-01 14:47:40	2025-12-01 14:47:40
1133	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.158	[]	2025-12-01 14:47:46	2025-12-01 14:47:46
1134	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/120/edit	GET	94.176.198.158	[]	2025-12-01 14:47:55	2025-12-01 14:47:55
1135	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations/120	PUT	94.176.198.158	{"name":"539\\t\\u041c\\u043e\\u043d\\u0442\\u0430\\u0436 \\u043c\\u0430\\u0443\\u043d\\u0442\\u0443 \\u043d\\u0430 \\u0411\\u0456\\u0442\\u0430 15\\"","description":null,"department_id":"2","search_terms":null,"is_permitted":"1","norm_type":"0","time_norm":"210","in_archive":null,"_token":"QdgSa63YAp6DW33392X7PjceMZyisJ4jqKRbBaNr","_method":"PUT"}	2025-12-01 14:48:00	2025-12-01 14:48:00
1136	2	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/operations	GET	94.176.198.158	[]	2025-12-01 14:48:00	2025-12-01 14:48:00
1137	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk	GET	94.176.198.158	[]	2025-12-01 15:19:48	2025-12-01 15:19:48
1138	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/workers	GET	94.176.198.158	[]	2025-12-01 15:19:55	2025-12-01 15:19:55
1139	1	prod3/uYxCFa2Uz6vM8SWoAnan6nZuYxCFa2Uz6vM8SWoAnan6nZk/workers/524019468	PUT	94.176.198.158	{"_method":"PUT","_edit_inline":true,"after-save":"exit","shift_column":"4"}	2025-12-01 15:20:07	2025-12-01 15:20:07
\.


--
-- Data for Name: admin_permissions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.admin_permissions (id, name, slug, http_method, http_path, created_at, updated_at) FROM stdin;
1	All permission	*		*	\N	\N
2	Dashboard	dashboard	GET	/	\N	\N
3	Login	auth.login		/auth/login\r\n/auth/logout	\N	\N
4	User setting	auth.setting	GET,PUT	/auth/setting	\N	\N
5	Auth management	auth.management		/auth/roles\r\n/auth/permissions\r\n/auth/menu\r\n/auth/logs	\N	\N
6	Admin Config	ext.config		/config*	2024-01-24 12:24:01	2024-01-24 12:24:01
7	works permission	works		/works*	2024-04-23 12:55:20	2024-04-23 13:37:01
8	calculator permission	calculator		/calculator	2024-10-21 14:28:04	2024-10-21 14:35:09
\.


--
-- Data for Name: admin_role_menu; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.admin_role_menu (role_id, menu_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: admin_role_permissions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.admin_role_permissions (role_id, permission_id, created_at, updated_at) FROM stdin;
1	1	\N	\N
2	7	\N	\N
2	8	\N	\N
\.


--
-- Data for Name: admin_role_users; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.admin_role_users (role_id, user_id, created_at, updated_at) FROM stdin;
1	1	\N	\N
2	1	\N	\N
1	2	\N	\N
1	3	\N	\N
1	4	\N	\N
\.


--
-- Data for Name: admin_roles; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.admin_roles (id, name, slug, created_at, updated_at) FROM stdin;
1	Administrator	administrator	2024-01-12 14:54:23	2024-01-12 14:54:23
2	Тімлід	teamlead	2024-04-23 12:56:45	2024-04-23 12:56:45
\.


--
-- Data for Name: admin_user_permissions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.admin_user_permissions (user_id, permission_id, created_at, updated_at) FROM stdin;
2	1	\N	\N
3	1	\N	\N
4	1	\N	\N
\.


--
-- Data for Name: admin_users; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.admin_users (id, username, password, name, avatar, remember_token, created_at, updated_at) FROM stdin;
1	roman	$2y$12$g2V4zGWdmPOaTPIj7jC0sOvVkHf9YZU7D40ZwTTBNgG1K3tLESxBW	Roman	\N	\N	2025-11-14 17:06:34	2025-11-14 17:06:34
3	artem	$2y$12$.9zb0SkkODOJ3dgvnnz3T./48qPJJUX4VxjmOyBWAER/hxLADhczq	Артем	\N	\N	2025-11-15 12:00:42	2025-11-15 12:00:42
4	Mazur_Nika	$2y$12$Nw5rYsRfFRLK.37KQZrnMujzFB7ADdckQ3uY8WhaFwSsfmQtiEBY.	Мазур Вікторія	\N	\N	2025-11-24 18:17:13	2025-11-24 18:17:13
2	zador	$2y$12$qJvPPfDlTgRJAoj1SCe6lu0MDt7wCa3hjwo1oBU.0XU8v0aXTs8Jq	Діма	\N	5iHwpcRUyvHfdJpiSHJZes6JaxnTztYZAmoKhsFp08V44M53BTI18jgWUKQH	2025-11-14 17:21:20	2025-11-14 17:21:20
\.


--
-- Data for Name: admins; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.admins (telegram_id, first_name, last_name) FROM stdin;
\.


--
-- Data for Name: archived_operations; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.archived_operations (id, operation_id, in_archive, update_time) FROM stdin;
1	1	f	2025-11-17 10:09:35.395377
2	1	f	2025-11-17 10:09:35
3	2	f	2025-11-17 10:09:48.783577
4	2	f	2025-11-17 10:09:48
5	3	f	2025-11-17 10:10:30.957216
6	3	f	2025-11-17 10:10:30
7	4	f	2025-11-17 10:11:27.329162
8	4	f	2025-11-17 10:11:27
9	5	f	2025-11-17 10:12:03.379229
10	5	f	2025-11-17 10:12:03
11	6	f	2025-11-17 10:12:45.181554
12	6	f	2025-11-17 10:12:45
13	7	f	2025-11-17 10:13:40.395633
14	7	f	2025-11-17 10:13:40
17	9	f	2025-11-17 10:39:31.208068
18	9	f	2025-11-17 10:39:31
19	10	f	2025-11-17 10:40:02.001118
20	10	f	2025-11-17 10:40:02
21	11	f	2025-11-17 10:40:30.418467
22	11	f	2025-11-17 10:40:30
23	12	f	2025-11-17 10:41:01.796045
24	12	f	2025-11-17 10:41:01
25	13	f	2025-11-17 10:42:36.37842
26	13	f	2025-11-17 10:42:36
27	14	f	2025-11-17 10:58:39.081459
28	14	f	2025-11-17 10:58:39
29	15	f	2025-11-17 10:59:08.853381
30	15	f	2025-11-17 10:59:08
31	16	f	2025-11-17 10:59:30.371777
32	16	f	2025-11-17 10:59:30
33	17	f	2025-11-17 11:14:12.916585
34	17	f	2025-11-17 11:14:12
35	18	f	2025-11-17 11:14:32.093072
36	18	f	2025-11-17 11:14:32
37	19	f	2025-11-17 11:15:11.544779
38	19	f	2025-11-17 11:15:11
39	20	f	2025-11-17 11:15:53.749434
40	20	f	2025-11-17 11:15:53
41	21	f	2025-11-17 11:16:22.482929
42	21	f	2025-11-17 11:16:22
43	22	f	2025-11-17 11:17:47.248949
44	22	f	2025-11-17 11:17:47
45	23	f	2025-11-17 11:18:44.23894
46	23	f	2025-11-17 11:18:44
47	24	f	2025-11-17 11:19:13.508852
48	24	f	2025-11-17 11:19:13
49	25	f	2025-11-17 11:20:46.28612
50	25	f	2025-11-17 11:20:46
51	26	f	2025-11-17 11:21:20.120735
52	26	f	2025-11-17 11:21:20
53	27	f	2025-11-17 11:21:50.823023
54	27	f	2025-11-17 11:21:50
55	28	f	2025-11-17 11:22:47.457747
56	28	f	2025-11-17 11:22:47
57	29	f	2025-11-17 11:26:07.332434
58	29	f	2025-11-17 11:26:07
59	30	f	2025-11-17 11:50:53.022815
60	30	f	2025-11-17 11:50:53
61	31	f	2025-11-17 11:51:45.778806
62	31	f	2025-11-17 11:51:45
63	32	f	2025-11-17 11:54:36.74401
64	32	f	2025-11-17 11:54:36
65	33	f	2025-11-17 12:35:40.866951
66	33	f	2025-11-17 12:35:40
67	34	f	2025-11-17 12:36:00.172371
68	34	f	2025-11-17 12:36:00
69	35	f	2025-11-17 12:36:32.240673
70	35	f	2025-11-17 12:36:32
71	36	f	2025-11-17 12:37:24.025745
72	36	f	2025-11-17 12:37:24
73	37	f	2025-11-17 13:08:08.753277
74	37	f	2025-11-17 13:08:08
75	38	f	2025-11-17 13:08:47.875012
76	38	f	2025-11-17 13:08:47
77	39	f	2025-11-17 13:09:13.301871
78	39	f	2025-11-17 13:09:13
79	40	f	2025-11-17 13:10:09.419632
80	40	f	2025-11-17 13:10:09
83	42	f	2025-11-17 13:11:33.333083
84	42	f	2025-11-17 13:11:33
85	43	f	2025-11-17 13:12:14.441341
86	43	f	2025-11-17 13:12:14
87	44	f	2025-11-17 16:18:23.092222
88	44	f	2025-11-17 16:18:23
89	45	f	2025-11-18 12:39:32.957698
90	45	f	2025-11-18 12:39:32
91	46	f	2025-11-18 12:48:15.106057
92	46	f	2025-11-18 12:48:15
93	47	f	2025-11-18 12:48:42.176166
94	47	f	2025-11-18 12:48:42
95	900	f	2025-11-24 18:47:54.250913
96	900	f	2025-11-24 18:47:54
97	901	f	2025-11-24 18:48:15.966942
98	901	f	2025-11-24 18:48:15
99	48	f	2025-11-25 13:13:47.354999
100	48	f	2025-11-25 13:13:47
101	49	f	2025-11-25 13:14:14.131204
102	49	f	2025-11-25 13:14:14
103	50	f	2025-11-25 13:14:46.666758
104	50	f	2025-11-25 13:14:46
105	51	f	2025-11-25 13:15:15.874539
106	51	f	2025-11-25 13:15:15
107	52	f	2025-11-25 13:15:42.966874
108	52	f	2025-11-25 13:15:42
109	53	f	2025-11-25 13:16:17.033767
110	53	f	2025-11-25 13:16:17
111	54	f	2025-11-25 13:30:46.278202
112	54	f	2025-11-25 13:30:46
113	55	f	2025-11-25 13:31:16.15974
114	55	f	2025-11-25 13:31:16
115	56	f	2025-11-25 13:31:41.407861
116	56	f	2025-11-25 13:31:41
117	57	f	2025-11-25 13:32:12.603243
118	57	f	2025-11-25 13:32:12
119	58	f	2025-11-25 13:32:38.312567
120	58	f	2025-11-25 13:32:38
121	59	f	2025-11-25 13:33:53.672356
122	59	f	2025-11-25 13:33:53
123	60	f	2025-11-25 13:34:20.404741
124	60	f	2025-11-25 13:34:20
125	61	f	2025-11-25 13:35:47.64034
126	61	f	2025-11-25 13:35:47
127	62	f	2025-11-25 13:36:10.982331
128	62	f	2025-11-25 13:36:10
129	63	f	2025-11-25 13:36:39.528829
130	63	f	2025-11-25 13:36:39
131	64	f	2025-11-25 13:37:09.967887
132	64	f	2025-11-25 13:37:09
133	65	f	2025-11-25 13:39:20.424879
134	65	f	2025-11-25 13:39:20
135	66	f	2025-11-25 13:39:45.28646
136	66	f	2025-11-25 13:39:45
137	67	f	2025-11-25 13:40:21.120185
138	67	f	2025-11-25 13:40:21
139	68	f	2025-11-25 13:41:08.842413
140	68	f	2025-11-25 13:41:08
141	69	f	2025-11-25 13:41:35.928831
142	69	f	2025-11-25 13:41:35
143	70	f	2025-11-25 13:42:10.560985
144	70	f	2025-11-25 13:42:10
145	71	f	2025-11-25 13:44:24.248565
146	71	f	2025-11-25 13:44:24
147	72	f	2025-11-25 13:44:49.126696
148	72	f	2025-11-25 13:44:49
149	73	f	2025-11-25 13:45:09.768199
150	73	f	2025-11-25 13:45:09
151	74	f	2025-11-25 13:45:41.19978
152	74	f	2025-11-25 13:45:41
153	75	f	2025-11-25 13:46:11.992879
154	75	f	2025-11-25 13:46:12
155	76	f	2025-11-25 13:46:42.782365
156	76	f	2025-11-25 13:46:42
157	77	f	2025-11-25 13:47:18.945943
158	77	f	2025-11-25 13:47:18
159	78	f	2025-11-25 13:47:47.287573
160	78	f	2025-11-25 13:47:47
161	79	f	2025-11-25 13:48:14.066256
162	79	f	2025-11-25 13:48:14
163	80	f	2025-11-25 13:50:32.939966
164	80	f	2025-11-25 13:50:32
165	81	f	2025-11-25 13:51:05.891459
166	81	f	2025-11-25 13:51:05
167	82	f	2025-11-25 13:55:21.450269
168	82	f	2025-11-25 13:55:21
169	83	f	2025-11-25 13:56:07.855874
170	83	f	2025-11-25 13:56:07
171	84	f	2025-11-25 13:56:32.883766
172	84	f	2025-11-25 13:56:32
173	85	f	2025-11-25 13:57:37.66899
174	85	f	2025-11-25 13:57:37
175	86	f	2025-11-25 13:58:15.737341
176	86	f	2025-11-25 13:58:15
177	87	f	2025-11-25 14:15:44.10815
178	87	f	2025-11-25 14:15:44
179	88	f	2025-11-25 14:16:15.745665
180	88	f	2025-11-25 14:16:15
181	89	f	2025-11-25 14:18:18.784462
182	89	f	2025-11-25 14:18:18
183	90	f	2025-11-25 14:37:17.299693
184	90	f	2025-11-25 14:37:17
185	91	f	2025-11-25 14:37:58.234274
186	91	f	2025-11-25 14:37:58
187	92	f	2025-11-25 14:38:31.692628
188	92	f	2025-11-25 14:38:31
189	93	f	2025-11-25 14:39:49.828209
190	93	f	2025-11-25 14:39:49
191	94	f	2025-11-25 14:52:11.897389
192	94	f	2025-11-25 14:52:11
193	95	f	2025-11-25 14:52:49.852283
194	95	f	2025-11-25 14:52:49
195	96	f	2025-11-25 14:55:17.476308
196	96	f	2025-11-25 14:55:17
197	97	f	2025-11-25 14:55:53.815497
198	97	f	2025-11-25 14:55:53
199	98	f	2025-11-25 14:59:03.507593
200	98	f	2025-11-25 14:59:03
201	99	f	2025-11-25 15:02:52.400518
202	99	f	2025-11-25 15:02:52
203	100	f	2025-11-25 15:05:46.219865
204	100	f	2025-11-25 15:05:46
205	101	f	2025-11-25 15:26:29.387272
206	101	f	2025-11-25 15:26:29
207	15	t	2025-11-25 15:37:20
208	102	f	2025-11-26 09:35:13.46406
209	102	f	2025-11-26 09:35:13
210	103	f	2025-11-26 09:36:48.756456
211	103	f	2025-11-26 09:36:48
212	104	f	2025-11-26 10:13:06.228652
213	104	f	2025-11-26 10:13:06
214	105	f	2025-11-26 10:27:25.616952
215	105	f	2025-11-26 10:27:25
216	106	f	2025-11-26 14:38:28.176154
217	106	f	2025-11-26 14:38:28
218	107	f	2025-11-26 14:39:03.436478
219	107	f	2025-11-26 14:39:03
220	108	f	2025-11-26 14:39:50.204995
221	108	f	2025-11-26 14:39:50
222	46	t	2025-11-27 11:54:56
223	59	t	2025-11-27 11:55:14
224	109	f	2025-11-27 12:51:31.550831
225	109	f	2025-11-27 12:51:31
226	110	f	2025-11-27 14:12:29.970725
227	110	f	2025-11-27 14:12:29
228	111	f	2025-11-27 14:13:20.024865
229	111	f	2025-11-27 14:13:20
230	112	f	2025-11-27 14:14:32.182464
231	112	f	2025-11-27 14:14:32
232	113	f	2025-11-27 14:15:13.681592
233	113	f	2025-11-27 14:15:13
234	114	f	2025-11-27 15:57:37.151318
235	114	f	2025-11-27 15:57:37
236	902	f	2025-11-27 19:57:29.776623
237	46	f	2025-11-28 14:17:02
238	115	f	2025-11-29 17:25:55.860888
239	115	f	2025-11-29 17:25:55
240	116	f	2025-11-29 17:29:36.089538
241	116	f	2025-11-29 17:29:36
242	117	f	2025-12-01 11:00:14.047627
243	117	f	2025-12-01 11:00:14
244	118	f	2025-12-01 12:35:36.306613
245	118	f	2025-12-01 12:35:36
246	119	f	2025-12-01 12:35:57.617736
247	119	f	2025-12-01 12:35:57
248	120	f	2025-12-01 15:53:13.846405
249	120	f	2025-12-01 15:53:13
\.


--
-- Data for Name: black_list; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.black_list (id, worker_id) FROM stdin;
\.


--
-- Data for Name: bonuses; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.bonuses (id, hours, payment, update_time, active) FROM stdin;
1	0	0	2023-01-01 00:00:00	t
2	6	150	2023-01-01 00:00:00	t
4	6	150	2024-03-06 00:00:00	t
6	5.5	0	2023-01-01 00:00:00	t
7	5.5	150	2024-03-18 23:59:59	t
9	6	600	2024-10-01 00:00:00	t
10	5.5	600	2025-02-24 00:00:00	t
3	8	300	2023-01-01 00:00:00	f
5	8	150	2024-03-06 00:00:00	f
\.


--
-- Data for Name: calculator_avoided_workers; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.calculator_avoided_workers (id, worker_id, is_avoided) FROM stdin;
\.


--
-- Data for Name: department_groups; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.department_groups (id, department_id, group_id, report_type_id) FROM stdin;
1	1	-5099024714	3
2	2	-5071885624	4
3	3	-5044429508	4
4	4	-4986143667	4
5	5	-5016743644	4
6	6	-5099005065	4
7	7	-5032127986	4
8	8	-5054828018	4
9	10	-5084800688	4
10	11	-5002014238	4
11	12	-5068601995	4
\.


--
-- Data for Name: department_report_types; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.department_report_types (id, name) FROM stdin;
1	Мінімальний звіт
2	Звіт з мінімальними операціями
3	Звіт з повними операціями
4	Звіт з операціями та роботами
\.


--
-- Data for Name: departments; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.departments (id, name, short_name) FROM stdin;
1	Заготовки	MDL
2	Збірка рами	FR
3	ESC	ESC
4	FC	FC
5	Фінальна збірка	FIN
6	Тестування	TST
7	Обліт	FLT
8	Пакування	PAC
9	Інше	Інше
10	Антени	ANT
12	Ремонт	REP
11	One piece flow	OPF
\.


--
-- Data for Name: failed_jobs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.failed_jobs (id, uuid, connection, queue, payload, exception, failed_at) FROM stdin;
\.


--
-- Data for Name: hour_payments; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.hour_payments (id, payment, update_time) FROM stdin;
1	125	2023-01-01 00:00:00
2	150	2023-01-01 00:00:00
3	140	2025-08-19 13:23:45
\.


--
-- Data for Name: migrations; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.migrations (id, migration, batch) FROM stdin;
1	2014_10_12_000000_create_users_table	1
2	2014_10_12_100000_create_password_reset_tokens_table	1
3	2016_01_04_173148_create_admin_tables	2
4	2019_08_19_000000_create_failed_jobs_table	2
5	2019_12_14_000001_create_personal_access_tokens_table	2
6	2017_07_17_040159_create_config_table	3
7	2025_05_27_221216_add_internship_column	4
8	2025_07_02_030615_create_request_table	5
9	2025_07_18_152432_create_work_day_departments_table	6
10	2025_07_23_134159_alter_table_workers	6
11	2025_07_23_153157_alter_bonus_table	6
12	2025_09_23_030014_alter_worker_add_ipn	7
13	2025_10_06_211605_add_hurma_id_column	8
14	2025_10_07_155446_add_internship_end_time	8
15	2025_10_07_174730_add_teamlead_department_id_unique	9
16	2025_10_19_033350_add_worker_shift_secondary	10
17	2025_10_19_035105_add_shift_department	10
18	2025_11_05_111434_add_basic_coeff	10
19	2025_11_27_181035_create_work_department	11
\.


--
-- Data for Name: module_operation; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.module_operation (id, operation_id, module_id) FROM stdin;
\.


--
-- Data for Name: modules; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.modules (id, name) FROM stdin;
\.


--
-- Data for Name: natural_operations; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.natural_operations (id, operation_id, multiplier, update_time, natural_norm) FROM stdin;
1	1	1	2025-11-17 10:09:35.395377	f
2	1	1	2025-11-17 10:09:35	f
3	2	1	2025-11-17 10:09:48.783577	f
4	2	1	2025-11-17 10:09:48	f
5	3	1	2025-11-17 10:10:30.957216	f
6	3	1	2025-11-17 10:10:30	f
7	4	1	2025-11-17 10:11:27.329162	f
8	4	1	2025-11-17 10:11:27	f
9	5	1	2025-11-17 10:12:03.379229	f
10	5	1	2025-11-17 10:12:03	f
11	6	1	2025-11-17 10:12:45.181554	f
12	6	1	2025-11-17 10:12:45	f
13	7	1	2025-11-17 10:13:40.395633	f
14	7	1	2025-11-17 10:13:40	f
17	9	1	2025-11-17 10:39:31.208068	f
18	9	1	2025-11-17 10:39:31	f
19	10	1	2025-11-17 10:40:02.001118	f
20	10	1	2025-11-17 10:40:02	f
21	11	1	2025-11-17 10:40:30.418467	f
22	11	1	2025-11-17 10:40:30	f
23	12	1	2025-11-17 10:41:01.796045	f
24	12	1	2025-11-17 10:41:01	f
25	13	1	2025-11-17 10:42:36.37842	f
26	13	1	2025-11-17 10:42:36	f
27	14	1	2025-11-17 10:58:39.081459	f
28	14	1	2025-11-17 10:58:39	f
29	15	1	2025-11-17 10:59:08.853381	f
30	15	1	2025-11-17 10:59:08	f
31	16	1	2025-11-17 10:59:30.371777	f
32	16	1	2025-11-17 10:59:30	f
33	17	1	2025-11-17 11:14:12.916585	f
34	17	1	2025-11-17 11:14:12	f
35	18	1	2025-11-17 11:14:32.093072	f
36	18	1	2025-11-17 11:14:32	f
37	19	1	2025-11-17 11:15:11.544779	f
38	19	1	2025-11-17 11:15:11	f
39	20	1	2025-11-17 11:15:53.749434	f
40	20	1	2025-11-17 11:15:53	f
41	21	1	2025-11-17 11:16:22.482929	f
42	21	1	2025-11-17 11:16:22	f
43	22	1	2025-11-17 11:17:47.248949	f
44	22	1	2025-11-17 11:17:47	f
45	23	1	2025-11-17 11:18:44.23894	f
46	23	1	2025-11-17 11:18:44	f
47	24	1	2025-11-17 11:19:13.508852	f
48	24	1	2025-11-17 11:19:13	f
49	25	1	2025-11-17 11:20:46.28612	f
50	25	1	2025-11-17 11:20:46	f
51	26	1	2025-11-17 11:21:20.120735	f
52	26	1	2025-11-17 11:21:20	f
53	27	1	2025-11-17 11:21:50.823023	f
54	27	1	2025-11-17 11:21:50	f
55	28	1	2025-11-17 11:22:47.457747	f
56	28	1	2025-11-17 11:22:47	f
57	29	1	2025-11-17 11:26:07.332434	f
58	29	1	2025-11-17 11:26:07	f
59	30	1	2025-11-17 11:50:53.022815	f
60	30	1	2025-11-17 11:50:53	f
61	31	1	2025-11-17 11:51:45.778806	f
62	31	1	2025-11-17 11:51:45	f
63	32	1	2025-11-17 11:54:36.74401	f
64	32	1	2025-11-17 11:54:36	f
65	33	1	2025-11-17 12:35:40.866951	f
66	33	1	2025-11-17 12:35:40	f
67	34	1	2025-11-17 12:36:00.172371	f
68	34	1	2025-11-17 12:36:00	f
69	35	1	2025-11-17 12:36:32.240673	f
70	35	1	2025-11-17 12:36:32	f
71	36	1	2025-11-17 12:37:24.025745	f
72	36	1	2025-11-17 12:37:24	f
73	37	1	2025-11-17 13:08:08.753277	f
74	37	1	2025-11-17 13:08:08	f
75	38	1	2025-11-17 13:08:47.875012	f
76	38	1	2025-11-17 13:08:47	f
77	39	1	2025-11-17 13:09:13.301871	f
78	39	1	2025-11-17 13:09:13	f
79	40	1	2025-11-17 13:10:09.419632	f
80	40	1	2025-11-17 13:10:09	f
83	42	1	2025-11-17 13:11:33.333083	f
84	42	1	2025-11-17 13:11:33	f
85	43	1	2025-11-17 13:12:14.441341	f
86	43	1	2025-11-17 13:12:14	f
87	44	1	2025-11-17 16:18:23.092222	f
88	44	1	2025-11-17 16:18:23	f
89	45	1	2025-11-18 12:39:32.957698	f
90	45	1	2025-11-18 12:39:32	f
91	46	1	2025-11-18 12:48:15.106057	f
92	46	1	2025-11-18 12:48:15	f
93	47	1	2025-11-18 12:48:42.176166	f
94	47	1	2025-11-18 12:48:42	f
96	900	1	2025-11-24 18:47:54	t
98	901	1	2025-11-24 18:48:15	t
99	48	1	2025-11-25 13:13:47.354999	f
100	48	1	2025-11-25 13:13:47	f
101	49	1	2025-11-25 13:14:14.131204	f
102	49	1	2025-11-25 13:14:14	f
103	50	1	2025-11-25 13:14:46.666758	f
104	50	1	2025-11-25 13:14:46	f
105	51	1	2025-11-25 13:15:15.874539	f
106	51	1	2025-11-25 13:15:15	f
107	52	1	2025-11-25 13:15:42.966874	f
108	52	1	2025-11-25 13:15:42	f
109	53	1	2025-11-25 13:16:17.033767	f
110	53	1	2025-11-25 13:16:17	f
111	54	1	2025-11-25 13:30:46.278202	f
112	54	1	2025-11-25 13:30:46	f
113	55	1	2025-11-25 13:31:16.15974	f
114	55	1	2025-11-25 13:31:16	f
115	56	1	2025-11-25 13:31:41.407861	f
116	56	1	2025-11-25 13:31:41	f
117	57	1	2025-11-25 13:32:12.603243	f
118	57	1	2025-11-25 13:32:12	f
119	58	1	2025-11-25 13:32:38.312567	f
120	58	1	2025-11-25 13:32:38	f
121	59	1	2025-11-25 13:33:53.672356	f
122	59	1	2025-11-25 13:33:53	f
123	60	1	2025-11-25 13:34:20.404741	f
124	60	1	2025-11-25 13:34:20	f
125	61	1	2025-11-25 13:35:47.64034	f
126	61	1	2025-11-25 13:35:47	f
127	62	1	2025-11-25 13:36:10.982331	f
128	62	1	2025-11-25 13:36:11	f
129	63	1	2025-11-25 13:36:39.528829	f
130	63	1	2025-11-25 13:36:39	f
131	64	1	2025-11-25 13:37:09.967887	f
132	64	1	2025-11-25 13:37:09	f
133	65	1	2025-11-25 13:39:20.424879	f
134	65	1	2025-11-25 13:39:20	f
135	66	1	2025-11-25 13:39:45.28646	f
136	66	1	2025-11-25 13:39:45	f
137	67	1	2025-11-25 13:40:21.120185	f
138	67	1	2025-11-25 13:40:21	f
139	68	1	2025-11-25 13:41:08.842413	f
140	68	1	2025-11-25 13:41:08	f
141	69	1	2025-11-25 13:41:35.928831	f
142	69	1	2025-11-25 13:41:35	f
143	70	1	2025-11-25 13:42:10.560985	f
144	70	1	2025-11-25 13:42:10	f
145	71	1	2025-11-25 13:44:24.248565	f
146	71	1	2025-11-25 13:44:24	f
147	72	1	2025-11-25 13:44:49.126696	f
148	72	1	2025-11-25 13:44:49	f
149	73	1	2025-11-25 13:45:09.768199	f
150	73	1	2025-11-25 13:45:09	f
151	74	1	2025-11-25 13:45:41.19978	f
152	74	1	2025-11-25 13:45:41	f
153	75	1	2025-11-25 13:46:11.992879	f
154	75	1	2025-11-25 13:46:12	f
155	76	1	2025-11-25 13:46:42.782365	f
156	76	1	2025-11-25 13:46:42	f
157	77	1	2025-11-25 13:47:18.945943	f
158	77	1	2025-11-25 13:47:18	f
159	78	1	2025-11-25 13:47:47.287573	f
160	78	1	2025-11-25 13:47:47	f
161	79	1	2025-11-25 13:48:14.066256	f
162	79	1	2025-11-25 13:48:14	f
163	80	1	2025-11-25 13:50:32.939966	f
164	80	1	2025-11-25 13:50:32	f
165	81	1	2025-11-25 13:51:05.891459	f
166	81	1	2025-11-25 13:51:05	f
167	82	1	2025-11-25 13:55:21.450269	f
168	82	1	2025-11-25 13:55:21	f
169	83	1	2025-11-25 13:56:07.855874	f
170	83	1	2025-11-25 13:56:07	f
171	84	1	2025-11-25 13:56:32.883766	f
172	84	1	2025-11-25 13:56:32	f
173	85	1	2025-11-25 13:57:37.66899	f
174	85	1	2025-11-25 13:57:37	f
175	86	1	2025-11-25 13:58:15.737341	f
176	86	1	2025-11-25 13:58:15	f
177	87	1	2025-11-25 14:15:44.10815	f
178	87	1	2025-11-25 14:15:44	f
179	88	1	2025-11-25 14:16:15.745665	f
180	88	1	2025-11-25 14:16:15	f
181	89	1	2025-11-25 14:18:18.784462	f
182	89	1	2025-11-25 14:18:18	f
183	90	1	2025-11-25 14:37:17.299693	f
184	90	1	2025-11-25 14:37:17	f
185	91	1	2025-11-25 14:37:58.234274	f
186	91	1	2025-11-25 14:37:58	f
187	92	1	2025-11-25 14:38:31.692628	f
188	92	1	2025-11-25 14:38:31	f
189	93	1	2025-11-25 14:39:49.828209	f
190	93	1	2025-11-25 14:39:49	f
191	94	1	2025-11-25 14:52:11.897389	f
192	94	1	2025-11-25 14:52:11	f
193	95	1	2025-11-25 14:52:49.852283	f
194	95	1	2025-11-25 14:52:49	f
195	96	1	2025-11-25 14:55:17.476308	f
196	96	1	2025-11-25 14:55:17	f
197	97	1	2025-11-25 14:55:53.815497	f
198	97	1	2025-11-25 14:55:53	f
199	98	1	2025-11-25 14:59:03.507593	f
200	98	1	2025-11-25 14:59:03	f
201	99	1	2025-11-25 15:02:52.400518	f
202	99	1	2025-11-25 15:02:52	f
203	100	1	2025-11-25 15:05:46.219865	f
204	100	1	2025-11-25 15:05:46	f
207	900	1	2025-11-25 17:39:43	t
208	102	1	2025-11-26 09:35:13.46406	f
209	102	1	2025-11-26 09:35:13	f
210	103	1	2025-11-26 09:36:48.756456	f
211	103	1	2025-11-26 09:36:48	f
212	104	1	2025-11-26 10:13:06.228652	f
213	104	1	2025-11-26 10:13:06	f
214	105	1	2025-11-26 10:27:25.616952	f
215	105	1	2025-11-26 10:27:25	f
216	106	1	2025-11-26 14:38:28.176154	f
217	106	1	2025-11-26 14:38:29	f
218	107	1	2025-11-26 14:39:03.436478	f
219	107	1	2025-11-26 14:39:04	f
220	108	1	2025-11-26 14:39:50.204995	f
221	108	1	2025-11-26 14:39:51	f
206	101	1	2025-11-24 00:00:00	t
222	103	1	2025-11-27 11:43:05	t
223	109	1	2025-11-27 12:51:31.550831	f
224	109	1	2025-11-27 12:51:32	f
225	110	1	2025-11-27 14:12:29.970725	f
226	110	1	2025-11-27 14:12:30	f
227	111	1	2025-11-27 14:13:20.024865	f
228	111	1	2025-11-27 14:13:21	f
229	112	1	2025-11-27 14:14:32.182464	f
230	112	1	2025-11-27 14:14:33	f
231	113	1	2025-11-27 14:15:13.681592	f
232	113	1	2025-11-27 14:15:14	f
233	114	1	2025-11-27 15:57:37.151318	f
234	114	1	2025-11-27 15:57:38	f
235	902	1	2025-11-27 19:57:29.776623	f
236	902	1.52	2025-11-27 19:59:07.481405	t
237	115	1	2025-11-29 17:25:55.860888	f
238	115	1	2025-11-29 17:25:56	f
239	116	1	2025-11-29 17:29:36.089538	f
240	116	1	2025-11-29 17:29:37	f
241	117	1	2025-12-01 11:00:14.047627	f
242	117	1	2025-12-01 11:00:15	t
243	118	1	2025-12-01 12:35:36.306613	f
244	118	1	2025-12-01 12:35:37	f
245	119	1	2025-12-01 12:35:57.617736	f
246	119	1	2025-12-01 12:35:58	f
247	120	1	2025-12-01 15:53:13.846405	f
248	120	1	2025-12-01 15:53:14	f
\.


--
-- Data for Name: operation_feedstocks; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.operation_feedstocks (id, operation_id, workpiece_id, amount) FROM stdin;
\.


--
-- Data for Name: operation_permissions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.operation_permissions (id, operation_id, permission_type_id, is_description_required) FROM stdin;
2	900	2	t
3	901	2	f
4	101	4	f
8	902	2	f
\.


--
-- Data for Name: operation_results; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.operation_results (id, operation_id, workpiece_id, amount) FROM stdin;
\.


--
-- Data for Name: operation_versions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.operation_versions (id, operation_id, update_time, norm_duration) FROM stdin;
13	13	2025-11-17 10:42:36.37842	\N
17	17	2025-11-17 11:14:12.916585	\N
18	18	2025-11-17 11:14:32.093072	\N
21	21	2025-11-17 11:16:22.482929	\N
23	23	2025-11-17 11:18:44.23894	\N
24	24	2025-11-17 11:19:13.508852	\N
25	25	2025-11-17 11:20:46.28612	\N
27	27	2025-11-17 11:21:50.823023	\N
32	32	2025-11-17 11:54:36.74401	\N
115	105	2025-11-27 12:41:26.353225	1140
116	104	2025-11-27 12:42:04.447641	960
117	66	2025-11-27 12:42:36.482582	1100
118	109	2025-11-27 12:51:31.550831	260
119	110	2025-11-27 14:12:29.970725	210
120	111	2025-11-27 14:13:20.024865	210
39	39	2025-11-17 13:09:13.301871	\N
40	40	2025-11-17 13:10:09.419632	\N
121	112	2025-11-27 14:14:32.182464	59
122	113	2025-11-27 14:15:13.681592	50
1	1	2025-11-17 10:09:35.395377	\N
2	2	2025-11-17 10:09:48.783577	\N
3	3	2025-11-17 10:10:30.957216	\N
4	4	2025-11-17 10:11:27.329162	\N
5	5	2025-11-17 10:12:03.379229	\N
6	6	2025-11-17 10:12:45.181554	\N
7	7	2025-11-17 10:13:40.395633	\N
9	9	2025-11-17 10:39:31.208068	\N
10	10	2025-11-17 10:40:02.001118	\N
11	11	2025-11-17 10:40:30.418467	\N
12	12	2025-11-17 10:41:01.796045	\N
14	14	2025-11-17 10:58:39.081459	\N
15	15	2025-11-17 10:59:08.853381	\N
16	16	2025-11-17 10:59:30.371777	\N
19	19	2025-11-17 11:15:11.544779	\N
20	20	2025-11-17 11:15:53.749434	\N
22	22	2025-11-17 11:17:47.248949	\N
26	26	2025-11-17 11:21:20.120735	\N
28	28	2025-11-17 11:22:47.457747	\N
29	29	2025-11-17 11:26:07.332434	\N
30	30	2025-11-17 11:50:53.022815	\N
31	31	2025-11-17 11:51:45.778806	\N
33	33	2025-11-17 12:35:40.866951	\N
34	34	2025-11-17 12:36:00.172371	\N
35	35	2025-11-17 12:36:32.240673	\N
36	36	2025-11-17 12:37:24.025745	\N
37	37	2025-11-17 13:08:08.753277	\N
123	114	2025-11-27 15:57:37.151318	45
124	111	2025-11-27 16:14:23.168601	25
42	42	2025-11-17 13:11:33.333083	\N
43	43	2025-11-17 13:12:14.441341	\N
44	44	2025-11-17 16:18:23.092222	\N
45	45	2025-11-18 12:39:32.957698	\N
38	38	2025-11-17 13:08:47.875012	\N
48	900	2025-11-24 18:47:54.250913	0
49	901	2025-11-24 18:48:15.966942	0
50	48	2025-11-25 13:13:47.354999	370
51	49	2025-11-25 13:14:14.131204	336
52	50	2025-11-25 13:14:46.666758	115
53	51	2025-11-25 13:15:15.874539	46
54	52	2025-11-25 13:15:42.966874	220
55	53	2025-11-25 13:16:17.033767	18
56	54	2025-11-25 13:30:46.278202	90
57	55	2025-11-25 13:31:16.15974	4
58	56	2025-11-25 13:31:41.407861	360
59	57	2025-11-25 13:32:12.603243	660
60	58	2025-11-25 13:32:38.312567	116
61	58	2025-11-25 13:33:10.846445	271
62	59	2025-11-25 13:33:53.672356	29
63	60	2025-11-25 13:34:20.404741	31
64	61	2025-11-25 13:35:47.64034	281
65	62	2025-11-25 13:36:10.982331	660
66	63	2025-11-25 13:36:39.528829	182
67	64	2025-11-25 13:37:09.967887	378
68	65	2025-11-25 13:39:20.424879	242
69	66	2025-11-25 13:39:45.28646	220
70	67	2025-11-25 13:40:21.120185	140
71	68	2025-11-25 13:41:08.842413	52
72	69	2025-11-25 13:41:35.928831	13
73	70	2025-11-25 13:42:10.560985	4
74	71	2025-11-25 13:44:24.248565	30
75	72	2025-11-25 13:44:49.126696	10
76	73	2025-11-25 13:45:09.768199	15
77	74	2025-11-25 13:45:41.19978	40
78	75	2025-11-25 13:46:11.992879	112
79	76	2025-11-25 13:46:42.782365	53
80	77	2025-11-25 13:47:18.945943	40
81	78	2025-11-25 13:47:47.287573	4
82	79	2025-11-25 13:48:14.066256	92
83	80	2025-11-25 13:50:32.939966	476
84	81	2025-11-25 13:51:05.891459	39
85	82	2025-11-25 13:55:21.450269	240
86	83	2025-11-25 13:56:07.855874	201
87	84	2025-11-25 13:56:32.883766	110
88	85	2025-11-25 13:57:37.66899	120
89	86	2025-11-25 13:58:15.737341	76
90	87	2025-11-25 14:15:44.10815	900
91	88	2025-11-25 14:16:15.745665	660
92	89	2025-11-25 14:18:18.784462	\N
93	90	2025-11-25 14:37:17.299693	90
94	91	2025-11-25 14:37:58.234274	240
95	92	2025-11-25 14:38:31.692628	360
96	93	2025-11-25 14:39:49.828209	112
97	94	2025-11-25 14:52:11.897389	54
98	95	2025-11-25 14:52:49.852283	205
99	96	2025-11-25 14:55:17.476308	139
100	97	2025-11-25 14:55:53.815497	420
101	98	2025-11-25 14:59:03.507593	210
102	99	2025-11-25 15:02:52.400518	34
103	100	2025-11-25 15:05:46.219865	320
104	101	2025-11-25 15:26:29.387272	0
105	102	2025-11-26 09:35:13.46406	321
106	103	2025-11-26 09:36:48.756456	20
107	80	2025-11-26 10:08:27.350503	40
108	104	2025-11-26 10:13:06.228652	192
109	105	2025-11-26 10:27:25.616952	260
110	105	2025-11-26 13:12:25.227559	1300
111	106	2025-11-26 14:38:28.176154	24
112	107	2025-11-26 14:39:03.436478	20
113	108	2025-11-26 14:39:50.204995	25
47	47	2025-11-18 12:48:42.176166	\N
114	60	2025-11-27 11:41:35.075452	70
125	902	2025-11-27 19:57:29.776623	\N
46	46	2025-11-18 12:48:15.106057	29
126	115	2025-11-29 17:25:55.860888	180
127	116	2025-11-29 17:29:36.089538	\N
128	117	2025-12-01 11:00:14.047627	0
129	118	2025-12-01 12:35:36.306613	\N
130	119	2025-12-01 12:35:57.617736	\N
131	120	2025-12-01 15:53:13.846405	210
\.


--
-- Data for Name: operations; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.operations (id, name, time_norm, department_id, description) FROM stdin;
13	Нарізка силового кабелю	\N	3	\N
17	Підготовка дротів кнопки	\N	4	\N
18	Підготовка дротів клемника	\N	4	\N
21	Герметизація ПІ	\N	4	\N
23	Підготовка ізоляції	\N	4	\N
24	Налаштування DC/DC	\N	4	\N
25	Напайка дроселя VTX	\N	4	\N
27	Пайка ПІ SP	\N	4	\N
32	Подовження шлейфу камери	\N	4	\N
55	62\tНарізка силового кабелю	4	3	\N
56	525\tПідготовка ESC-12S	360	3	\N
57	526\t15" монтаж ESC-12S	660	3	\N
58	116\tПовна збірка без ПІ	271	4	\N
59	329\tМонтаж віброгумок на FC	29	1	\N
39	Тест ПІ Popcorn	\N	7	\N
40	Зняття пропелерів	\N	8	\N
61	252\tМонтаж пропелерів на 15"	281	5	\N
1	Налаштування серво.  SL	\N	1	\N
2	Збірка гімбалу SL	\N	1	\N
3	Тестування гімбалу SL	\N	1	\N
4	Збірка обтікача SL	\N	1	\N
5	Встановлення крил SL	\N	1	\N
6	Підготовка кришки  SL	\N	1	\N
7	Поклейка силік. скотчу SL	\N	1	\N
9	Збірка рами SL	\N	2	\N
10	Кріплення дротів ізолентою SL	\N	2	\N
11	Монтаж моторів SL	\N	2	\N
12	Монтаж пластику на раму SL	\N	2	\N
14	Монтаж ESC-12S SL	\N	3	\N
15	Пайка XT90 SL	\N	3	\N
16	Підготовка ESC-12S SL	\N	3	\N
19	Підготовка ПІ до пайки SL	\N	4	\N
20	Пайка дротів серво FC SL	\N	4	\N
22	Підключення гімбалу SL	\N	4	\N
26	Пайка ПІ до FC SL	\N	4	\N
28	Пайка роз'єму серво SL	\N	4	\N
29	Пайка шлейфів до FC SL	\N	4	\N
30	Підготовка та пайка ELRS SL	\N	4	\N
31	Підготування DC/DC SL	\N	4	\N
33	Монтаж трубок та обтікачів пром. SL	\N	5	\N
34	Базова збірка SL	\N	5	\N
35	Монтаж нижнього та верхнього обтікача SL	\N	5	\N
36	Монтаж пропелерів SL	\N	5	\N
37	Прошивка/тест SL	\N	6	\N
62	581\tБазова збірка 15" без КМ V2	660	5	\N
63	516\t15" стек+кришка+текстоліт	182	5	\N
42	Перевірка SL	\N	8	\N
43	Пакування SL	\N	8	\N
44	Пайка Type-C SL	\N	4	\N
45	Підготовка пластику для рами SL	\N	2	\N
38	Обліт з асистентом SL	\N	7	\N
900	Переробка	0	9	\N
901	Адмін роботи	0	9	\N
48	209\tМонтаж моторів 15"	370	2	\N
49	208\tПовна збірка рами 15"	336	2	\N
50	210\tМонтаж стійок 15"	115	2	\N
51	317\tПідготування моторів 15" без кільця	46	2	\N
52	517\tКріплення дротів ізолентою 15"	220	2	\N
53	473\tЛудіння кабелів	18	3	\N
54	474\tПайка силового роз'єму (без лудіння)	90	3	\N
64	253\tПрошивка/bind/тест 15"	378	6	\N
65	284\tВирій/Джонні 15" з асистентом	242	7	\N
67	411\tДемонтаж пропів 15"	140	5	\N
68	452\tМонтаж InfiRay 640 на кронштейн	52	1	\N
69	144\tПорізка дротів ELRS	13	4	\N
70	480\tНарізка термоусадки на шаблоні	4	1	\N
71	337\tТекстолітові антени	30	10	\N
72	39\tПрозвон антени	10	10	\N
73	482\tМонтаж холдеру на текстолітову антену V2	15	10	\N
74	25\tМонтаж антени на модуль ERLS	40	5	\N
75	231\tПайка подвійних дротів до ПІ	112	4	\N
76	80\tПайка ПІ до льотного контролера	53	4	\N
77	394\tДогерметизація ПІ	40	4	\N
78	67\tНарізка контактного прута	4	1	\N
79	52\tПідготовка контактного механізму	92	1	\N
81	356\tГерметизація ПІ	39	1	\N
82	506\tМонтаж КМ 15"	240	5	\N
83	410\tПайка подвійного КМ 15"	201	5	\N
84	301\tНапайка дроселя	110	4	\N
85	424\tМонтаж антени на кронштейн 2,1 - 2,6	120	1	\N
87	523\tБазова збірка 15" з КМ V2	900	5	\N
88	580\tБазова збірка 15" з КМ/Опто V2	660	5	\N
89	558\tБазова збірка 15'' V.opt/digital	\N	5	\N
90	492\tМонтаж маунту на Опто 15"	90	2	\N
91	544\tКріплення дротів ізолентою 15" ОПТО	240	2	\N
92	538\tЗбірка рами Опто 15"	360	2	\N
93	378\tПайка роз'єму Біта	112	4	\N
94	377\tПідготовка дротів роз'єму Біта	54	4	\N
95	543\tПайка шлейфів FС.V.OPT без ПІ	205	4	\N
86	191\tПідготування VTX TBS UP32	76	1	\N
47	Монтаж віброгумок ESC SL	\N	1	\N
66	487\tУпаковка груп. коробки 15’’	1100	8	\N
60	521\t15" Комплектування ESC 12S	70	1	\N
46	Монтаж віброгумок FC	29	1	\N
96	103\tФіксація стека з кришкою	139	5	\N
97	533\tБазова збірка 15" без КМ/Опто V2	420	5	\N
98	567\t15” V.opt з асистентом	210	7	\N
99	24\tМонтаж камери на кронштейн	34	1	\N
101	Ремонт	0	12	\N
100	562\t15" Повна збірка FC V.Opt/D без ПІ	320	4	\N
102	122\tПовна збірка з підготовленою ПІ	321	4	\N
103	29\tТестування дрона	20	5	\N
80	476\tТермоусадка на КМ	40	1	\N
106	334\tРозпакування камер 1	24	1	\N
107	355\tРозпакування камер 2	20	1	\N
108	417\tРозпаковка камер 3	25	1	\N
105	627\tУпаковка груп. кор. 15’’ з документацією	1140	8	\N
104	535\tУпаковка груп. кор. 15’’ ОПТО	960	8	\N
110	143\tПодовження дротів VTX	210	4	\N
112	18\tПідготовка плати ERLS	59	4	\N
113	296\tПайка ELRS до FC	50	4	\N
109	549\tМонтаж VTX Peak	260	1	\N
114	548\tМонтаж холдера на VTX PeakFPV	45	1	\N
111	95\tПідготовка дротів до ELRS	25	4	\N
902	Наставник	\N	9	\N
115	529\tПрошивка/тест/бінд ESC (нова)	180	6	\N
116	579\tПрошивка/тест/15" V.opt.digital	\N	6	\N
117	446\tCheck-up FC	0	4	\N
118	632 Базова збірка 8" PeakFpv з КМ	\N	5	\N
119	633 Базова збірка 15" PeakFpv з КМ	\N	5	\N
120	539\tМонтаж маунту на Біта 15"	210	2	\N
\.


--
-- Data for Name: operations_average; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.operations_average (id, operation_id, average_duration) FROM stdin;
1	1	0
2	2	0
3	3	0
4	4	0
5	5	0
6	6	0
7	7	0
10	10	0
11	11	0
12	12	0
17	17	0
18	18	0
19	19	0
20	20	0
22	22	0
23	23	0
24	24	0
25	25	0
26	26	0
27	27	0
28	28	0
29	29	0
30	30	0
31	31	0
32	32	0
34	34	0
35	35	0
36	36	0
37	37	0
38	38	0
39	39	0
44	44	0
45	45	0
9	9	0
21	21	21
14	14	0
97	95	145
73	71	28
15	15	72
16	16	3300
74	72	9
57	55	0
60	58	0
61	59	0
64	62	0
67	65	0
68	66	0
80	78	0
84	82	0
87	85	0
88	86	0
91	89	0
92	90	0
99	97	0
66	64	247
33	33	12
71	69	10
75	73	10
48	900	609
103	101	13045
94	92	312
112	110	158
59	57	484
49	901	4858
47	47	3068
100	98	175
95	93	81
54	52	177
51	49	279
106	104	0
119	116	0
52	50	107
108	106	0
109	107	0
120	117	0
110	108	0
121	118	0
102	100	150
78	76	35
13	13	3
98	96	112
101	99	34
123	120	0
55	53	13
82	80	36
83	81	14
46	46	44
56	54	66
81	79	71
43	43	240
76	74	49
89	87	877
70	68	81
72	70	1
122	119	824
62	60	57
40	40	83
42	42	125
116	114	50
58	56	240
111	109	259
69	67	177
107	105	807
63	61	222
50	48	272
117	902	6579
93	91	233
53	51	41
86	84	109
85	83	165
104	102	274
77	75	76
113	111	21
79	77	23
96	94	43
65	63	180
114	112	50
90	88	563
105	103	5954
118	115	140
115	113	53
\.


--
-- Data for Name: operations_mode; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.operations_mode (id, operation_id, mode) FROM stdin;
1	1	0
2	2	0
3	3	0
4	4	0
5	5	0
6	6	0
7	7	0
10	10	0
11	11	0
12	12	0
17	17	0
18	18	0
19	19	0
20	20	0
22	22	0
23	23	0
24	24	0
25	25	0
26	26	0
27	27	0
28	28	0
29	29	0
30	30	0
31	31	0
32	32	0
34	34	0
35	35	0
36	36	0
37	37	0
38	38	0
39	39	0
44	44	0
45	45	0
9	9	\N
21	21	21
71	69	9
14	14	\N
120	117	0
15	15	72
16	16	3300
121	118	0
57	55	0
60	58	0
61	59	0
64	62	0
67	65	0
68	66	0
80	78	0
84	82	0
87	85	0
88	86	0
91	89	0
92	90	0
99	97	0
33	33	\N
55	53	13
56	54	59
98	96	105
82	80	34
47	47	3068
81	79	68
46	46	41
123	120	0
58	56	236
69	67	131
107	105	857
111	109	274
50	48	297
106	104	0
117	902	7113
108	106	0
109	107	0
110	108	0
72	70	1
93	91	211
62	60	57
53	51	37
86	84	93
101	99	33
104	102	270
116	114	50
77	75	80
83	81	24
79	77	27
96	94	48
63	61	222
43	43	269
118	115	133
85	83	162
90	88	560
65	63	153
70	68	105
66	64	255
73	71	27
40	40	81
42	42	137
48	900	38
74	72	10
113	111	21
75	73	9
59	57	485
49	901	1633
97	95	150
105	103	3095
114	112	47
115	113	36
100	98	177
76	74	37
89	87	870
112	110	190
103	101	3372
94	92	280
95	93	86
54	52	175
51	49	282
102	100	150
78	76	39
119	116	0
52	50	111
122	119	858
13	13	3
\.


--
-- Data for Name: password_reset_tokens; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.password_reset_tokens (email, token, created_at) FROM stdin;
\.


--
-- Data for Name: payment_coefficients; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.payment_coefficients (id, multiplier, hours, update_time) FROM stdin;
1	1	6	2023-01-01 00:00:00
2	1.5	6	2024-03-05 00:00:00
3	1	5.5	2023-01-01 00:00:00
4	1.5	5.5	2024-03-17 23:59:59
5	1	0	2023-01-01 00:00:00
\.


--
-- Data for Name: permission_types; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.permission_types (id, name) FROM stdin;
1	Базовий доступ
2	Доступ від тімліда
3	Доступ від керівника
4	Локалький доступ тімліда
\.


--
-- Data for Name: personal_access_tokens; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.personal_access_tokens (id, tokenable_type, tokenable_id, name, token, abilities, last_used_at, expires_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: shift_bonuses; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.shift_bonuses (id, shift_id, bonus_id) FROM stdin;
1	1	1
2	1	2
3	1	3
4	1	4
5	1	5
6	2	1
9	2	6
10	2	7
11	3	1
12	3	6
13	3	7
16	4	1
19	4	9
20	5	1
21	5	10
22	6	1
23	6	10
24	7	1
25	8	1
26	9	1
27	7	2
28	8	7
29	9	7
\.


--
-- Data for Name: shift_coefficients; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.shift_coefficients (id, shift_id, coefficient_id) FROM stdin;
1	1	1
2	1	2
3	2	3
4	2	4
5	1	1
6	1	2
7	2	3
8	2	4
9	3	3
10	3	4
12	4	2
13	5	2
14	6	2
15	7	2
16	8	2
17	9	2
18	1	5
19	4	5
20	2	5
21	5	5
22	3	5
23	6	5
24	7	5
25	8	5
26	9	5
\.


--
-- Data for Name: shift_hour_payments; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.shift_hour_payments (id, payment_id, shift_id) FROM stdin;
1	1	1
2	1	2
3	1	3
5	2	4
6	2	5
7	2	6
8	3	7
11	3	8
10	3	9
\.


--
-- Data for Name: shifts; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.shifts (id, name, shift_start_time, department_id) FROM stdin;
1	Основна зміна	09:00:00	\N
4	Обльоти основна зміна	09:00:00	\N
2	Перша зміна	07:00:00	\N
5	Обльоти перша зміна	07:00:00	\N
3	Друга зміна	14:15:00	\N
6	Обльоти друга зміна	14:15:00	\N
7	Ремонти основна зміна	09:00:00	\N
8	Ремонти перша зміна	09:00:00	\N
9	Ремонти друга зміна	09:00:00	\N
\.


--
-- Data for Name: team_leads; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.team_leads (worker_id, department_id, admin_user_id, id) FROM stdin;
\.


--
-- Data for Name: trusted_workers; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.trusted_workers (id, op_permission_id, worker_id) FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.users (id, name, email, email_verified_at, password, remember_token, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: work_day_departments; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.work_day_departments (id, department_id, work_day_id, created_at, updated_at) FROM stdin;
1	3	32	2025-11-25 14:56:43	\N
2	5	33	2025-11-25 14:56:43	\N
3	7	35	2025-11-25 14:56:43	\N
4	5	36	2025-11-25 14:56:43	\N
5	4	37	2025-11-25 14:56:43	\N
6	5	38	2025-11-25 14:56:43	\N
7	4	39	2025-11-25 14:56:43	\N
8	4	40	2025-11-25 14:56:43	\N
9	3	41	2025-11-25 14:56:43	\N
10	8	42	2025-11-25 14:56:43	\N
11	3	43	2025-11-25 14:56:43	\N
12	4	44	2025-11-25 14:56:43	\N
13	4	45	2025-11-25 14:56:43	\N
14	5	47	2025-11-25 14:56:43	\N
15	3	48	2025-11-25 14:56:43	\N
16	2	50	2025-11-25 14:56:43	\N
17	2	51	2025-11-25 14:56:43	\N
18	5	53	2025-11-25 14:56:43	\N
19	2	54	2025-11-25 14:56:43	\N
20	3	55	2025-11-25 14:56:43	\N
21	5	56	2025-11-25 14:56:43	\N
22	1	58	2025-11-25 14:56:43	\N
23	1	61	2025-11-25 14:56:43	\N
24	1	62	2025-11-25 14:56:43	\N
25	2	63	2025-11-25 14:56:43	\N
26	2	64	2025-11-25 14:56:43	\N
27	3	66	2025-11-25 14:56:43	\N
28	5	67	2025-11-25 14:56:43	\N
29	1	68	2025-11-25 14:56:43	\N
30	3	69	2025-11-25 14:56:43	\N
31	4	70	2025-11-25 14:56:43	\N
32	3	71	2025-11-25 14:56:43	\N
33	2	72	2025-11-25 14:56:43	\N
34	12	73	2025-11-25 14:56:43	\N
35	4	74	2025-11-25 14:56:43	\N
36	5	75	2025-11-25 14:56:43	\N
37	4	76	2025-11-25 14:56:43	\N
38	5	77	2025-11-25 14:56:43	\N
39	3	78	2025-11-25 14:56:43	\N
40	3	79	2025-11-25 14:56:43	\N
41	5	80	2025-11-25 14:56:43	\N
42	3	81	2025-11-25 14:56:43	\N
43	4	82	2025-11-25 14:56:43	\N
44	6	83	2025-11-25 14:56:43	\N
45	1	84	2025-11-25 14:56:43	\N
46	5	85	2025-11-25 14:56:43	\N
47	5	86	2025-11-25 14:56:43	\N
48	1	87	2025-11-25 14:56:43	\N
49	7	88	2025-11-25 14:56:43	\N
50	12	89	2025-11-25 14:56:43	\N
51	2	90	2025-11-25 14:56:43	\N
52	6	91	2025-11-25 14:56:43	\N
53	3	92	2025-11-25 14:56:43	\N
54	8	93	2025-11-25 14:56:43	\N
55	3	94	2025-11-25 14:56:43	\N
56	5	95	2025-11-25 14:56:43	\N
57	2	96	2025-11-25 14:56:43	\N
58	3	99	2025-11-25 14:56:43	\N
59	5	100	2025-11-25 14:56:43	\N
60	3	101	2025-11-25 14:56:43	\N
61	5	102	2025-11-25 14:56:43	\N
62	7	103	2025-11-25 14:56:43	\N
63	7	104	2025-11-25 14:56:43	\N
64	12	105	2025-11-25 14:56:43	\N
65	7	106	2025-11-25 14:56:43	\N
66	1	107	2025-11-25 14:56:43	\N
67	2	109	2025-11-25 14:56:43	\N
68	2	110	2025-11-25 14:56:43	\N
69	4	114	2025-11-27 11:53:11	\N
70	7	116	2025-11-27 11:53:11	\N
71	3	117	2025-11-27 11:53:11	\N
72	3	118	2025-11-27 11:53:11	\N
73	6	119	2025-11-27 11:53:11	\N
74	3	120	2025-11-27 11:53:11	\N
75	3	121	2025-11-27 11:53:11	\N
76	2	122	2025-11-27 11:53:11	\N
77	1	123	2025-11-27 11:53:11	\N
78	6	124	2025-11-27 11:53:11	\N
79	3	125	2025-11-27 11:53:11	\N
80	12	126	2025-11-27 11:53:11	\N
81	12	127	2025-11-27 11:53:11	\N
82	5	128	2025-11-27 11:53:11	\N
83	5	129	2025-11-27 11:53:11	\N
84	3	130	2025-11-27 11:53:11	\N
85	3	131	2025-11-27 11:53:11	\N
86	5	132	2025-11-27 11:53:11	\N
87	1	133	2025-11-27 11:53:11	\N
88	12	134	2025-11-27 11:53:11	\N
89	5	135	2025-11-27 11:53:11	\N
90	2	136	2025-11-27 11:53:11	\N
91	1	138	2025-11-27 11:53:11	\N
92	4	139	2025-11-27 11:53:11	\N
93	4	140	2025-11-27 11:53:11	\N
94	5	141	2025-11-27 11:53:11	\N
95	4	142	2025-11-27 11:53:11	\N
96	5	143	2025-11-27 11:53:11	\N
97	5	144	2025-11-27 11:53:11	\N
98	2	145	2025-11-27 11:53:11	\N
99	7	146	2025-11-27 11:53:11	\N
100	3	147	2025-11-27 11:53:11	\N
101	7	148	2025-11-27 11:53:11	\N
102	5	149	2025-11-27 11:53:11	\N
103	7	150	2025-11-27 11:53:11	\N
104	5	151	2025-11-27 11:53:11	\N
105	2	153	2025-11-27 11:53:11	\N
106	5	154	2025-11-27 11:53:11	\N
107	1	155	2025-11-27 11:53:11	\N
108	3	156	2025-11-27 11:53:11	\N
109	2	157	2025-11-27 11:53:11	\N
110	2	158	2025-11-27 11:53:11	\N
111	3	159	2025-11-28 01:14:09	\N
112	3	162	2025-11-28 01:14:09	\N
113	3	163	2025-11-28 01:14:09	\N
114	1	164	2025-11-28 01:14:09	\N
115	4	165	2025-11-28 01:14:09	\N
116	5	166	2025-11-28 01:14:09	\N
117	5	167	2025-11-28 01:14:09	\N
118	3	170	2025-11-28 01:14:09	\N
119	5	171	2025-11-28 01:14:09	\N
120	1	172	2025-11-28 01:14:09	\N
121	5	173	2025-11-28 01:14:09	\N
122	8	174	2025-11-28 01:14:09	\N
123	5	175	2025-11-28 01:14:09	\N
124	2	176	2025-11-28 01:14:09	\N
125	5	177	2025-11-28 01:14:09	\N
126	3	178	2025-11-28 01:14:09	\N
127	12	179	2025-11-28 01:14:09	\N
128	3	180	2025-11-28 01:14:09	\N
129	2	181	2025-11-28 01:14:09	\N
130	7	182	2025-11-28 01:14:09	\N
131	12	183	2025-11-28 01:14:09	\N
132	12	184	2025-11-28 01:14:09	\N
133	3	185	2025-11-28 01:14:09	\N
134	3	186	2025-11-28 01:14:09	\N
135	2	187	2025-11-28 01:14:09	\N
136	5	189	2025-11-28 01:14:09	\N
137	7	191	2025-11-28 01:14:09	\N
138	7	192	2025-11-28 01:14:09	\N
139	3	193	2025-11-28 01:14:09	\N
140	5	194	2025-11-28 01:14:09	\N
141	6	195	2025-11-28 01:14:09	\N
142	7	196	2025-11-28 01:14:09	\N
143	7	197	2025-11-28 01:14:09	\N
144	2	198	2025-11-28 01:14:09	\N
145	1	199	2025-11-28 01:14:09	\N
146	5	200	2025-11-28 01:14:09	\N
147	7	201	2025-11-28 01:14:09	\N
148	1	202	2025-11-28 01:14:09	\N
149	5	203	2025-11-28 01:14:09	\N
150	12	204	2025-11-28 01:14:09	\N
151	5	205	2025-11-28 01:14:09	\N
152	5	206	2025-11-28 01:14:09	\N
153	2	207	2025-11-28 01:14:09	\N
154	2	208	2025-11-28 01:14:09	\N
155	3	210	2025-11-28 01:14:09	\N
156	3	211	2025-11-28 01:14:09	\N
157	3	212	2025-11-28 01:14:09	\N
158	6	213	2025-11-28 01:14:09	\N
159	3	214	2025-11-28 01:14:09	\N
160	3	215	2025-11-28 01:14:09	\N
161	1	216	2025-11-28 01:14:09	\N
162	3	217	2025-11-28 01:14:09	\N
163	5	218	2025-11-28 01:14:09	\N
164	2	219	2025-11-28 01:14:09	\N
165	1	220	2025-11-28 01:14:09	\N
166	5	221	2025-11-28 01:14:09	\N
167	5	222	2025-11-28 01:14:09	\N
168	5	223	2025-11-28 01:14:09	\N
169	2	224	2025-11-28 01:14:09	\N
170	5	225	2025-11-28 01:14:09	\N
171	1	226	2025-11-28 01:14:09	\N
172	3	227	2025-11-28 01:14:09	\N
173	5	228	2025-11-28 01:14:09	\N
174	5	229	2025-11-28 01:14:09	\N
175	5	230	2025-11-28 01:14:09	\N
176	7	231	2025-11-28 01:14:09	\N
177	7	232	2025-11-28 01:14:09	\N
178	2	233	2025-11-28 01:14:09	\N
179	7	234	2025-11-28 01:14:09	\N
180	3	235	2025-11-28 01:14:09	\N
181	7	236	2025-11-28 01:14:09	\N
182	6	237	2025-11-28 01:14:09	\N
183	8	238	2025-11-28 01:14:09	\N
184	7	239	2025-11-28 01:14:09	\N
185	5	240	2025-11-28 01:14:09	\N
186	5	241	2025-11-28 01:14:09	\N
187	12	242	2025-11-28 01:14:09	\N
188	12	243	2025-11-28 01:14:09	\N
189	2	244	2025-11-28 01:14:09	\N
190	2	245	2025-11-28 01:14:09	\N
191	3	248	2025-11-28 01:14:09	\N
192	5	249	2025-11-28 01:14:09	\N
193	2	252	2025-11-28 01:14:09	\N
194	7	253	2025-11-28 01:14:09	\N
195	5	254	2025-11-28 01:14:09	\N
196	2	255	2025-11-28 01:14:09	\N
197	7	256	2025-11-28 01:14:09	\N
198	2	257	2025-11-28 01:14:09	\N
199	2	258	2025-11-28 01:14:09	\N
200	2	259	2025-11-28 01:14:09	\N
201	5	261	2025-11-28 01:14:09	\N
202	3	262	2025-11-28 01:14:09	\N
203	3	263	2025-11-28 01:14:09	\N
204	3	264	2025-11-28 01:14:09	\N
205	3	265	2025-11-28 01:14:09	\N
206	3	266	2025-11-28 01:14:09	\N
207	3	267	2025-11-28 01:14:09	\N
208	4	268	2025-11-28 01:14:09	\N
209	3	269	2025-11-28 01:14:09	\N
210	3	270	2025-11-28 01:14:09	\N
211	5	272	2025-11-28 01:14:09	\N
212	5	273	2025-11-28 01:14:09	\N
213	4	274	2025-11-28 01:14:09	\N
214	1	276	2025-11-28 01:14:09	\N
215	5	278	2025-11-28 01:14:09	\N
216	7	280	2025-11-28 01:14:09	\N
217	8	281	2025-11-28 01:14:09	\N
218	2	282	2025-11-28 01:14:09	\N
219	2	283	2025-11-28 01:14:09	\N
220	6	284	2025-11-28 01:14:09	\N
221	5	285	2025-11-28 01:14:09	\N
222	3	286	2025-11-28 01:14:09	\N
223	4	287	2025-11-28 01:14:09	\N
224	7	288	2025-11-28 01:14:09	\N
225	6	289	2025-11-28 01:14:09	\N
226	3	290	2025-11-28 01:14:09	\N
\.


--
-- Data for Name: work_days; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.work_days (id, worker_id, start_time, finish_time, payment, raw_payment, wd_norm, bonus_id, in_shelter_time) FROM stdin;
1	958194770	2025-11-23 18:15:30	2025-11-23 18:16:56	0	0	0	1	0
2	368487569	2025-11-23 18:50:58	2025-11-23 18:51:34	0	0	0	1	0
3	368487569	2025-11-23 18:51:53	2025-11-23 18:52:57	0	0	0	1	0
4	368487569	2025-11-24 06:52:06	2025-11-24 06:52:47	0	0	0	1	0
5	833326956	2025-11-24 09:08:48	2025-11-24 09:10:54	0	0	0	1	0
6	7298707465	2025-11-24 09:33:06	2025-11-24 09:35:14	0	0	0	1	0
7	5696887952	2025-11-24 08:37:40	2025-11-24 15:19:23	0	0	0	1	0
8	1079977172	2025-11-24 15:28:50	2025-11-24 18:32:30	0	0	0	1	0
9	380830168	2025-11-24 09:11:39	2025-11-24 18:53:07	0	0	0	1	0
10	460255958	2025-11-24 09:08:53	2025-11-24 19:10:44	0	0	0	1	0
11	631343368	2025-11-24 09:38:56	2025-11-24 19:11:21	0	0	0	1	0
12	583067641	2025-11-24 16:15:21	2025-11-24 19:12:02	0	0	0	1	0
13	959551233	2025-11-24 13:58:25	2025-11-24 19:12:21	0	0	0	1	0
15	7828553391	2025-11-24 19:18:06	2025-11-24 19:21:14	0	0	0	1	0
16	1171518697	2025-11-24 09:32:58	2025-11-24 19:24:07	0	0	0	1	0
20	7298707465	2025-11-25 09:11:03	2025-11-25 09:11:20	0	0	0	1	0
21	959551233	2025-11-25 11:15:07	2025-11-25 11:15:57	0	0	0	1	0
22	959551233	2025-11-25 12:05:08	2025-11-25 12:23:41	0	0	0	1	0
23	368487569	2025-11-25 13:06:05	2025-11-25 13:06:21	0	0	0	1	0
24	368487569	2025-11-25 15:29:52	2025-11-25 15:30:07	0	0	0	1	0
26	959551233	2025-11-25 16:28:35	2025-11-25 16:35:39	0	0	0	1	0
32	480267737	2025-11-25 10:06:19	2025-11-25 17:40:55	1184.0104	1034.0104	27053	4	0
33	1403052047	2025-11-25 09:13:10	2025-11-25 17:43:07	1367.2396	1217.2396	30571	4	0
36	680950736	2025-11-25 09:04:43	2025-11-25 17:56:49	1422.0312	1272.0312	31623	4	0
37	5006100672	2025-11-25 10:21:31	2025-11-25 17:57:58	1451.4584	1301.4584	32188	4	0
38	565989951	2025-11-25 09:11:04	2025-11-25 17:59:49	1423.9584	1273.9584	31660	4	0
39	1412145236	2025-11-25 10:26:38	2025-11-25 18:00:07	1454.3229	1304.3229	32243	4	0
40	652782105	2025-11-25 10:20:45	2025-11-25 18:00:13	1461.875	1311.875	32388	4	0
41	682982694	2025-11-25 09:10:28	2025-11-25 18:00:24	1372.3959	1222.3959	30670	4	0
42	1809318229	2025-11-25 09:04:20	2025-11-25 18:00:56	663.9236	663.9236	19121	1	0
43	7896599626	2025-11-25 09:02:30	2025-11-25 18:01:03	1457.0312	1307.0312	32295	4	0
44	1626467387	2025-11-25 10:24:09	2025-11-25 18:01:38	1385.9375	1235.9375	30930	4	0
45	638532571	2025-11-25 10:24:11	2025-11-25 18:03:05	1470.7812	1320.7812	32559	4	0
46	450220248	2025-11-25 09:10:14	2025-11-25 18:03:13	1410.1041	1260.1041	31394	4	0
47	284763815	2025-11-25 08:55:09	2025-11-25 18:06:22	1450.625	1300.625	32172	4	0
49	631343368	2025-11-25 10:20:49	2025-11-25 18:09:53	0	0	0	1	0
50	496415073	2025-11-25 09:04:53	2025-11-25 18:09:53	1396.4584	1246.4584	31132	4	0
51	5234869387	2025-11-25 11:46:19	2025-11-25 18:10:47	1657.8646	1507.8646	36151	4	0
53	5759999723	2025-11-25 09:04:51	2025-11-25 18:12:01	1470.1562	1320.1562	32547	4	0
54	380830168	2025-11-25 08:46:03	2025-11-25 18:13:44	1565.8334	1415.8334	34384	4	0
55	5696887952	2025-11-25 07:56:30	2025-11-25 18:16:21	1448.125	1298.125	31001	4	3369
56	5178631798	2025-11-25 09:09:00	2025-11-25 18:18:52	1490.2084	1340.2084	32932	4	0
57	1079977172	2025-11-25 09:10:20	2025-11-25 18:22:13	0	0	0	1	0
58	260972430	2025-11-25 09:19:49	2025-11-25 18:25:20	1393.9062	1243.9062	31083	4	0
60	583067641	2025-11-25 09:10:23	2025-11-25 18:30:38	0	0	0	1	0
61	5299916972	2025-11-25 09:27:03	2025-11-25 18:32:37	1450.9896	1300.9896	32179	4	0
62	517939536	2025-11-25 08:48:09	2025-11-25 19:19:20	1581.7709	1431.7709	34690	4	0
63	1171518697	2025-11-25 07:10:14	2025-11-25 19:22:35	1986.3541	1836.3541	42458	4	0
64	460255958	2025-11-25 07:27:43	2025-11-25 19:29:58	2028.2118	1878.2118	43261	4	2
14	390934584	2025-11-24 08:32:54	2025-11-24 19:12:22	1462.5	1312.5	32400	4	0
17	450220248	2025-11-24 09:31:54	2025-11-24 19:25:18	1408.5416	1258.5416	30600	4	2292
18	682982694	2025-11-24 13:01:54	2025-11-24 19:48:38	468.75	468.75	13500	1	0
52	390934584	2025-11-25 08:08:40	2025-11-25 18:11:28	1650.7291	1500.7291	36014	4	0
48	689340169	2025-11-25 09:38:45	2025-11-25 18:07:53	1350.1041	1200.1041	30242	4	0
72	380830168	2025-11-26 07:20:01	2025-11-26 17:21:05	1646.7188	1496.7188	35937	4	0
28	273955619	2025-11-25 10:15:37	2025-11-25 17:03:17	1517.3334	1367.3334	30640	2	0
86	284763815	2025-11-26 08:08:25	2025-11-26 18:02:21	1532.6041	1382.6041	33746	4	0
35	438705457	2025-11-25 11:52:36	2025-11-25 17:55:31	1510.375	910.375	21766	9	0
29	547586388	2025-11-25 11:48:21	2025-11-25 17:05:31	1101.5625	951.5625	25470	4	0
27	729610759	2025-11-25 13:20:19	2025-11-25 16:46:58	554.30554	554.30554	15964	1	0
65	958194770	2025-11-25 21:13:54	2025-11-25 21:14:21	0	0	0	1	0
66	1575913081	2025-11-25 09:08:42	2025-11-26 08:22:19	1446.7188	1296.7188	32097	4	0
68	260972430	2025-11-26 09:34:06	2025-11-26 09:38:43	1165.6771	1015.67706	26701	4	0
69	480267737	2025-11-26 08:52:49	2025-11-26 16:03:21	1115.5729	965.57294	25739	4	0
34	854336769	2025-11-25 08:18:53	2025-11-25 17:45:04	1720.7028	1570.7028	33725	2	1204
73	273955619	2025-11-26 08:38:55	2025-11-26 17:26:37	1575.6083	1425.6083	31639	2	0
70	5006100672	2025-11-26 08:30:34	2025-11-26 16:09:53	1477.0834	1327.0834	32680	4	0
71	547586388	2025-11-26 09:44:34	2025-11-26 16:15:51	978.69794	828.69794	23111	4	0
25	587721103	2025-11-25 09:06:08	2025-11-25 16:31:01	1306.9833	1156.9833	27034	2	0
59	420293854	2025-11-25 09:05:31	2025-11-25 18:27:03	1476.4584	1326.4584	32668	4	0
67	7495000901	2025-11-25 12:11:39	2025-11-26 09:01:21	880.7917	880.7917	21139	1	0
30	958194770	2025-11-25 09:14:07	2025-11-25 17:29:23	1320.5209	1170.5209	29674	4	0
74	1626467387	2025-11-26 08:36:43	2025-11-26 17:37:03	1575	1425	34560	4	0
75	1403052047	2025-11-26 08:59:39	2025-11-26 17:38:08	1344.9479	1194.9479	30143	4	0
76	638532571	2025-11-26 08:28:45	2025-11-26 17:54:51	1717.1354	1567.1354	37289	4	0
78	682982694	2025-11-26 09:10:55	2025-11-26 17:59:30	1698.0729	1548.0729	36923	4	0
79	7896599626	2025-11-26 08:53:07	2025-11-26 17:59:33	1613.1771	1463.1771	35293	4	0
80	680950736	2025-11-26 08:51:26	2025-11-26 18:00:17	1378.6459	1228.6459	30790	4	0
81	450220248	2025-11-26 09:12:13	2025-11-26 18:00:22	1883.2812	1733.2812	40479	4	0
82	1412145236	2025-11-26 08:54:40	2025-11-26 18:00:27	1212.5	1062.5	27600	4	0
83	729610759	2025-11-26 10:09:36	2025-11-26 18:01:09	1475.625	1325.625	32652	4	0
84	5299916972	2025-11-26 09:18:53	2025-11-26 18:01:21	1187.3959	1037.3959	27118	4	0
85	5759999723	2025-11-26 08:32:09	2025-11-26 18:01:36	1766.1459	1616.1459	38230	4	0
87	260972430	2025-11-26 09:38:47	2025-11-26 18:03:06	972.76044	822.76044	22997	4	0
90	5234869387	2025-11-26 08:10:33	2025-11-26 18:03:42	1539.0104	1389.0104	33869	4	0
91	958194770	2025-11-26 09:03:39	2025-11-26 18:03:53	1760.5209	1610.5209	38122	4	0
92	5696887952	2025-11-26 08:22:14	2025-11-26 18:04:35	2368.177	2218.177	49789	4	0
93	1809318229	2025-11-26 09:08:04	2025-11-26 18:05:42	576.6667	576.6667	16608	1	0
94	1575913081	2025-11-26 08:22:28	2025-11-26 18:07:55	1666.7188	1516.7188	36321	4	0
95	420293854	2025-11-26 08:03:54	2025-11-26 18:08:23	1615.4166	1465.4166	35336	4	0
96	496415073	2025-11-26 09:09:21	2025-11-26 18:09:04	1397.0834	1247.0834	31144	4	0
77	7495000901	2025-11-26 09:01:36	2025-11-26 17:56:40	2142.25	1542.25	31876	9	0
89	587721103	2025-11-26 09:05:02	2025-11-26 18:03:26	1613.175	1463.175	32283	2	0
88	808612634	2025-11-26 09:28:41	2025-11-26 18:03:20	2040.9375	1440.9375	30255	9	0
31	970421717	2025-11-25 09:33:51	2025-11-25 17:34:30	1950	1350	28800	9	0
97	1079977172	2025-11-26 09:16:11	2025-11-26 18:16:34	0	0	0	1	0
98	583067641	2025-11-26 18:16:12	2025-11-26 18:16:51	0	0	0	1	0
99	689340169	2025-11-26 08:45:00	2025-11-26 18:17:15	1810.7291	1660.7291	39086	4	0
100	399027689	2025-11-26 08:53:26	2025-11-26 18:19:27	1565.4166	1415.4166	34376	4	0
101	390934584	2025-11-26 08:28:47	2025-11-26 18:21:39	1605.2604	1455.2604	35141	4	0
102	5178631798	2025-11-26 08:44:20	2025-11-26 18:24:53	1584.6875	1434.6875	34746	4	0
107	517939536	2025-11-26 08:39:19	2025-11-26 18:54:46	1731.4584	1581.4584	37564	4	0
108	631343368	2025-11-26 10:17:01	2025-11-26 19:22:48	0	0	0	1	0
109	1171518697	2025-11-26 07:10:32	2025-11-26 19:53:40	2106.6145	1956.6146	44767	4	0
110	460255958	2025-11-26 06:51:10	2025-11-26 20:01:06	2205.4688	2055.4688	46665	4	0
111	368487569	2025-11-26 10:16:30	2025-11-26 20:16:40	0	0	0	1	0
112	368487569	2025-11-27 13:10:28	2025-11-27 13:10:47	0	0	0	1	0
113	368487569	2025-11-27 13:28:41	2025-11-27 13:28:51	0	0	0	1	0
114	5006100672	2025-11-27 08:01:00	2025-11-27 17:00:40	1990.1041	1840.1041	42530	4	0
115	1626467387	2025-11-27 07:59:00	2025-11-27 17:02:08	1928.2291	1778.2291	41342	4	0
116	438705457	2025-11-27 10:40:00	2025-11-27 17:06:31	1578.3125	978.3125	22853	9	0
117	1575913081	2025-11-27 11:27:19	2025-11-27 17:11:01	1653.125	1503.125	36060	4	0
118	547586388	2025-11-27 11:26:17	2025-11-27 17:26:15	1336.0416	1186.0416	29972	4	0
119	729610759	2025-11-27 11:26:03	2025-11-27 17:27:03	1220.1041	1070.1041	27746	4	0
120	480267737	2025-11-27 08:35:00	2025-11-27 17:31:56	1415.625	1265.625	31500	4	0
121	7896599626	2025-11-27 11:27:23	2025-11-27 17:37:23	1893.5938	1743.5938	40677	4	0
122	833326956	2025-11-27 08:00:00	2025-11-27 17:53:24	1539.3229	1389.3229	33875	4	0
123	5299916972	2025-11-27 11:26:03	2025-11-27 17:54:26	1242.0312	1092.0312	28167	4	0
124	958194770	2025-11-27 08:00:00	2025-11-27 17:55:33	1940.625	1790.625	41580	4	0
125	682982694	2025-11-27 11:26:03	2025-11-27 17:56:55	2042.5521	1892.5521	43537	4	0
126	7054968599	2025-11-27 17:58:00	2025-11-27 17:59:04	1374.0104	1224.0104	30701	4	0
127	273955619	2025-11-27 08:40:00	2025-11-27 17:59:07	1606.2333	1456.2333	32164	2	0
128	680950736	2025-11-27 08:55:00	2025-11-27 17:59:26	1448.0729	1298.0729	32123	4	0
129	7495000901	2025-11-27 11:26:40	2025-11-27 18:01:58	2382.25	1782.25	35716	9	0
130	450220248	2025-11-27 11:27:14	2025-11-27 18:02:05	1900	1750	40800	4	0
131	390934584	2025-11-27 11:26:03	2025-11-27 18:02:26	1559.8438	1409.8438	34269	4	0
132	5759999723	2025-11-27 08:50:00	2025-11-27 18:03:26	1715.4166	1565.4166	37256	4	0
134	587721103	2025-11-27 11:27:38	2025-11-27 18:05:13	1678.8	1528.8	33408	2	0
135	284763815	2025-11-27 11:26:03	2025-11-27 18:09:00	1411.0938	1261.0938	31413	4	0
137	1809318229	2025-11-27 09:00:00	2025-11-27 18:12:43	1148.9584	998.9583	26380	4	0
138	1079977172	2025-11-27 12:41:28	2025-11-27 18:14:15	9.027778	9.027778	260	1	0
139	638532571	2025-11-27 08:50:00	2025-11-27 18:14:18	1762.3438	1612.3438	38157	4	0
141	1403052047	2025-11-27 09:00:00	2025-11-27 18:17:54	1511.3021	1361.3021	33337	4	0
142	631343368	2025-11-27 12:24:50	2025-11-27 18:19:23	0.8680556	0.8680556	25	1	0
143	503186206	2025-11-27 09:00:00	2025-11-27 18:19:59	1518.8021	1368.8021	33481	4	0
144	420293854	2025-11-27 08:05:00	2025-11-27 18:22:18	1656.4584	1506.4584	36124	4	0
145	380830168	2025-11-27 11:26:03	2025-11-27 18:22:52	2087.3438	1937.3438	44397	4	0
146	808612634	2025-11-27 09:23:00	2025-11-27 18:23:59	2170.375	1570.375	32326	9	0
147	689340169	2025-11-27 09:30:00	2025-11-27 18:26:16	2056.25	1906.25	43800	4	0
151	5178631798	2025-11-27 11:27:48	2025-11-27 18:44:30	1672.6041	1522.6041	36434	4	0
152	5234869387	2025-11-27 18:55:49	2025-11-27 18:57:09	0	0	0	1	0
153	496415073	2025-11-27 09:00:00	2025-11-27 19:04:12	1694.2709	1544.2709	36850	4	0
154	544740146	2025-11-27 09:05:00	2025-11-27 19:07:42	1300.4166	1150.4166	29288	4	0
155	517939536	2025-11-27 08:27:00	2025-11-27 19:29:03	2203.5938	2053.5938	46629	4	0
156	7828553391	2025-11-25 19:56:49	2025-11-27 20:02:26	1266.3541	1116.3541	28634	4	0
157	1171518697	2025-11-27 07:03:00	2025-11-27 20:05:35	2650	2500	55200	4	0
158	460255958	2025-11-27 11:27:28	2025-11-27 20:08:24	2272.8125	2122.8125	47958	4	0
175	7495000901	2025-11-28 08:51:21	2025-11-28 17:59:44	2148.4167	1548.4166	31506	9	1406
176	5234869387	2025-11-28 08:05:29	2025-11-28 18:02:01	2601.0938	2451.0938	53724	4	1611
149	399027689	2025-11-27 09:30:31	2025-11-27 18:31:54	1462.7084	1312.7084	32404	4	0
140	1412145236	2025-11-27 09:00:00	2025-11-27 18:17:45	1258.3334	1108.3334	28480	4	0
133	260972430	2025-11-27 09:14:03	2025-11-27 18:03:43	1837.5	1687.5	39600	4	0
19	854336769	2025-11-24 08:12:43	2025-11-24 20:13:16	2110	1960	40800	2	0
105	854336769	2025-11-26 07:52:25	2025-11-26 18:46:14	1974.8417	1824.8417	38483	2	0
106	5545338450	2025-11-26 08:55:35	2025-11-26 18:46:50	2363.75	1763.75	35420	9	0
103	438705457	2025-11-26 10:22:59	2025-11-26 18:33:59	1987.9375	1387.9375	29407	9	0
136	5234869387	2025-11-27 08:00:00	2025-11-27 18:12:21	1751.5625	1601.5625	37350	7	0
159	1575913081	2025-11-28 07:42:10	2025-11-28 17:16:46	1775.9202	1625.9202	38040	4	1133
160	5006100672	2025-11-28 08:22:41	2025-11-28 17:28:35	1969.3403	1819.3403	41713	4	1255
161	1412145236	2025-11-28 08:28:30	2025-11-28 17:32:13	1018.75	868.75	23235	4	1935
162	480267737	2025-11-28 08:38:44	2025-11-28 17:33:25	1781.007	1631.007	37800	4	2146
163	547586388	2025-11-28 09:09:37	2025-11-28 17:45:10	1501.1284	1351.1284	31200	4	5825
164	5299916972	2025-11-28 09:33:24	2025-11-28 17:50:09	1159.3577	1009.35767	26000	4	1739
165	652782105	2025-11-28 08:50:06	2025-11-28 17:51:31	1464.7916	1314.7916	31697	4	2241
166	680950736	2025-11-28 08:51:00	2025-11-28 17:54:29	1632.0312	1482.0312	35010	4	1935
167	284763815	2025-11-28 08:00:37	2025-11-28 17:55:58	1416.7534	1266.7534	30869	4	1958
168	638532571	2025-11-28 08:45:18	2025-11-28 17:56:39	1486.6666	1336.6666	32226	4	1914
169	959551233	2025-11-27 11:27:24	2025-11-28 17:57:40	0	0	0	1	0
170	7896599626	2025-11-28 08:24:26	2025-11-28 17:58:32	1894.2361	1744.2361	40260	4	1288
171	503186206	2025-11-28 08:28:05	2025-11-28 17:58:56	1422.9688	1272.9688	31005	4	1908
172	260972430	2025-11-28 09:25:51	2025-11-28 17:58:59	1540.4688	1390.4688	33260	4	1911
173	1403052047	2025-11-28 08:59:55	2025-11-28 17:59:18	1600.4688	1450.4688	34320	4	2187
174	1809318229	2025-11-28 08:42:49	2025-11-28 17:59:37	1308.3334	1158.3334	28820	4	1860
177	5759999723	2025-11-28 08:45:14	2025-11-28 18:02:22	1882.9166	1732.9166	40091	4	1143
178	390934584	2025-11-28 08:40:23	2025-11-28 18:02:25	1601.1979	1451.1979	35063	4	0
179	7054968599	2025-11-28 09:05:19	2025-11-28 18:04:12	1256.6146	1106.6146	28447	4	0
180	689340169	2025-11-28 08:48:18	2025-11-28 18:05:59	2269.2534	2119.2534	47100	4	2369
181	7298707465	2025-11-28 06:55:42	2025-11-28 18:06:31	2246.823	2096.823	46968	4	1473
182	438705457	2025-11-28 10:18:36	2025-11-28 18:06:38	1710.5416	1110.5416	24628	9	1022
183	587721103	2025-11-28 10:38:23	2025-11-28 18:07:13	1300.2167	1150.2167	26918	2	0
184	273955619	2025-11-28 08:23:23	2025-11-28 18:08:57	1702.6	1552.6	33172	2	1932
185	5696887952	2025-11-28 08:05:32	2025-11-28 18:09:04	2586.111	2436.111	53280	4	2080
186	450220248	2025-11-28 08:00:34	2025-11-28 18:09:26	1901.875	1751.875	40140	4	2088
187	380830168	2025-11-28 07:38:32	2025-11-28 18:10:02	1919.5312	1769.5312	41175	4	0
188	399027689	2025-11-28 08:46:09	2025-11-28 18:14:07	1837.6562	1687.6562	39267	4	1008
189	420293854	2025-11-28 08:03:59	2025-11-28 18:14:40	1657.6041	1507.6041	35562	4	1752
190	1626467387	2025-11-28 07:57:38	2025-11-28 18:15:10	1662.7257	1512.7257	35480	4	2293
150	970421717	2025-11-27 08:50:00	2025-11-27 18:36:48	2347.875	1747.875	35166	9	0
148	711290767	2025-11-27 12:57:45	2025-11-27 18:28:48	1709.0625	1109.0625	24945	9	0
191	970421717	2025-11-28 10:37:39	2025-11-28 18:16:51	1871.25	1271.25	27540	9	0
193	682982694	2025-11-28 08:26:43	2025-11-28 18:18:07	1904.2188	1754.2188	40200	4	2043
194	565989951	2025-11-28 09:04:52	2025-11-28 18:18:45	1213.9236	1063.9236	26982	4	1936
195	958194770	2025-11-28 09:04:56	2025-11-28 18:21:02	2200.5903	2050.5903	45932	4	1918
197	808612634	2025-11-28 09:28:50	2025-11-28 18:37:02	2440.8333	1840.8334	36275	9	1135
198	833326956	2025-11-28 08:12:36	2025-11-28 18:44:10	1838.3334	1688.3334	39470	4	438
199	1257390480	2025-11-28 09:05:47	2025-11-28 18:52:40	1348.3507	1198.3507	29560	4	1945
200	5178631798	2025-11-28 08:20:25	2025-11-28 18:54:55	1686.3716	1536.3716	36054	4	1933
201	5545338450	2025-11-28 09:01:29	2025-11-28 19:01:44	2127.8958	1527.8959	31336	9	931
202	517939536	2025-11-28 08:26:06	2025-11-28 19:08:12	2171.1284	2021.1284	44667	4	4016
203	544740146	2025-11-28 08:08:00	2025-11-28 19:09:10	2539.8438	2389.8438	52431	4	1962
204	854336769	2025-11-28 08:07:02	2025-11-28 19:10:14	2229.6152	2079.6152	42630	2	659
207	1171518697	2025-11-28 07:12:36	2025-11-28 19:54:59	2733.3333	2583.3333	56800	4	0
208	460255958	2025-11-28 07:12:33	2025-11-28 19:56:50	2160.1597	2010.1597	45424	4	1112
209	547586388	2025-11-29 08:58:43	2025-11-29 11:02:30	0	0	0	1	958
210	689340169	2025-11-29 07:23:01	2025-11-29 16:00:56	1665.243	1515.243	35880	4	1238
211	480267737	2025-11-29 08:45:07	2025-11-29 16:14:06	1275.3125	1125.3125	27900	4	2718
212	1575913081	2025-11-29 07:44:19	2025-11-29 16:39:20	1587.5521	1437.5521	34800	4	3
213	958194770	2025-11-29 09:39:13	2025-11-29 17:09:03	1940.625	1790.625	41580	4	0
214	682982694	2025-11-29 08:23:15	2025-11-29 17:34:01	1655.0173	1505.0173	35909	4	562
215	450220248	2025-11-29 08:16:56	2025-11-29 17:39:29	1713.8716	1563.8716	36902	4	973
216	260972430	2025-11-29 09:40:46	2025-11-29 17:41:29	1119.8438	969.84375	25821	4	0
217	390934584	2025-11-29 08:26:38	2025-11-29 17:42:22	1559.6354	1409.6354	34265	4	0
218	680950736	2025-11-29 09:00:26	2025-11-29 17:47:56	1522.0834	1372.0834	33000	4	1632
219	380830168	2025-11-29 08:24:09	2025-11-29 17:47:58	1831.25	1681.25	39480	4	0
220	5299916972	2025-11-29 11:04:50	2025-11-29 17:48:21	1094.6875	944.6875	25338	4	0
221	399027689	2025-11-29 08:32:28	2025-11-29 17:48:56	1535.4166	1385.4166	33800	4	0
222	1403052047	2025-11-29 09:00:50	2025-11-29 17:51:51	1429.3923	1279.3923	31104	4	1981
223	565989951	2025-11-29 10:40:56	2025-11-29 17:52:10	550	550	15840	1	0
224	7298707465	2025-11-29 06:59:47	2025-11-29 17:55:05	2587.8818	2437.8818	53240	4	2302
225	503186206	2025-11-29 09:50:14	2025-11-29 17:55:05	1046.875	896.875	24420	4	0
226	517939536	2025-11-29 08:55:44	2025-11-29 17:55:56	1300.0521	1150.0521	29281	4	0
227	5696887952	2025-11-29 09:06:22	2025-11-29 17:56:36	1840.6945	1690.6945	39058	4	1810
228	5759999723	2025-11-29 08:49:16	2025-11-29 17:56:39	2010.3125	1860.3125	42918	4	0
229	7495000901	2025-11-29 09:30:58	2025-11-29 17:56:45	2415.0625	1815.0625	36241	9	0
230	420293854	2025-11-29 09:41:43	2025-11-29 17:59:01	1382.1875	1232.1875	30858	4	0
232	808612634	2025-11-29 11:28:30	2025-11-29 18:04:33	1669.375	1069.375	24310	9	0
233	5234869387	2025-11-29 07:38:17	2025-11-29 18:07:25	2868.125	2718.125	59388	4	0
234	438705457	2025-11-29 13:51:45	2025-11-29 18:08:04	656.25	656.25	15750	1	0
235	7896599626	2025-11-29 08:26:35	2025-11-29 18:08:18	1786.0938	1636.0938	38613	4	0
237	729610759	2025-11-29 08:43:32	2025-11-29 18:10:55	2039.0625	1889.0625	43470	4	0
238	1809318229	2025-11-29 08:58:17	2025-11-29 18:11:40	1442.4827	1292.4827	31340	4	2027
239	5545338450	2025-11-29 09:15:27	2025-11-29 18:17:17	2024.2084	1424.2084	29212	9	2326
240	544740146	2025-11-29 09:13:31	2025-11-29 18:30:40	1837.3438	1687.3438	39597	4	0
241	5178631798	2025-11-29 10:10:12	2025-11-29 18:34:54	1444.4271	1294.4271	32053	4	0
242	503426024	2025-11-29 09:30:00	2025-11-29 18:41:56	1444.6875	1294.6875	32058	4	0
243	854336769	2025-11-29 08:57:30	2025-11-29 18:44:58	1882.7388	1732.7388	36274	2	1888
244	1171518697	2025-11-29 06:56:47	2025-11-29 19:13:34	2465.8855	2315.8855	51665	4	0
245	460255958	2025-11-29 07:38:36	2025-11-29 19:17:17	2192.0278	2042.0278	46406	4	1
246	368487569	2025-11-29 17:16:30	2025-11-29 19:20:03	0	0	0	1	0
247	583067641	2025-11-29 11:10:02	2025-11-29 20:10:18	0	0	0	1	0
248	5696887952	2025-11-30 08:08:03	2025-11-30 15:17:27	2109.375	1959.375	44820	4	0
249	5759999723	2025-11-30 08:38:10	2025-11-30 16:22:31	1962.5	1812.5	42000	4	0
252	833326956	2025-11-30 07:00:00	2025-11-30 17:05:37	1856.25	1706.25	39960	4	0
253	808612634	2025-11-30 09:50:20	2025-11-30 17:08:04	2013.6875	1413.6875	29819	9	0
254	680950736	2025-11-30 08:49:44	2025-11-30 17:38:02	1274.7396	1124.7396	28795	4	0
255	5234869387	2025-11-30 08:14:26	2025-11-30 18:00:24	1755.1562	1605.1562	38019	4	0
256	5545338450	2025-11-30 10:03:23	2025-11-30 18:05:11	2170.3125	1570.3125	32325	9	0
257	7298707465	2025-11-30 06:48:09	2025-11-30 18:16:38	2483.75	2333.75	52008	4	0
258	1171518697	2025-11-30 06:57:08	2025-11-30 18:27:06	2239.375	2089.375	47316	4	0
259	460255958	2025-11-30 07:11:48	2025-11-30 18:53:59	2071.1458	1921.1459	44086	4	0
260	368487569	2025-12-01 10:11:18	2025-12-01 10:11:40	0	0	0	1	0
205	544740146	2025-11-25 09:26:00	2025-11-25 19:18:09	1662.5	1512.5	36240	4	0
206	544740146	2025-11-26 08:21:00	2025-11-26 19:35:18	2177.2917	2027.2916	46124	4	0
261	325323555	2025-12-01 09:44:05	2025-12-01 15:12:51	170.13889	170.13889	4900	1	0
262	1019196711	2025-12-01 06:24:41	2025-12-01 16:14:08	1528.125	1378.125	33660	4	0
263	682982694	2025-12-01 07:03:50	2025-12-01 16:14:18	2056.25	1906.25	43800	4	0
264	5696887952	2025-12-01 08:03:58	2025-12-01 16:22:01	2256.25	2106.25	47640	4	0
265	450220248	2025-12-01 06:59:10	2025-12-01 16:28:42	2046.875	1896.875	43620	4	0
104	970421717	2025-11-26 09:17:17	2025-11-26 18:45:24	2279.4375	1679.4375	34071	9	0
196	711290767	2025-11-28 10:56:12	2025-11-28 18:36:48	1964.0834	1364.0834	28446	9	1738
192	970421717	2025-11-28 18:16:54	2025-11-28 18:17:34	2239.1875	1639.1875	33427	9	0
231	711290767	2025-11-29 09:15:07	2025-11-29 18:02:08	2167.8125	1567.8125	32285	9	0
236	970421717	2025-11-29 09:30:24	2025-11-29 18:10:53	2217.9375	1617.9375	33087	9	0
250	970421717	2025-11-30 09:52:46	2025-11-30 16:38:30	1776.0625	1176.0625	26017	9	0
251	711290767	2025-11-30 10:59:48	2025-11-30 16:55:15	1801.785	1201.785	26428	9	0
266	547586388	2025-12-01 09:22:41	2025-12-01 16:57:25	1556.25	1406.25	34200	4	0
267	1575913081	2025-12-01 07:43:34	2025-12-01 17:15:16	1840.625	1690.625	39660	4	0
268	5006100672	2025-12-01 08:26:42	2025-12-01 17:27:32	2072.3958	1922.3959	44110	4	0
269	7896599626	2025-12-01 07:27:20	2025-12-01 17:30:11	2131.25	1981.25	45240	4	0
270	480267737	2025-12-01 08:45:36	2025-12-01 17:36:31	1931.25	1781.25	41400	4	0
271	1403052047	2025-12-01 09:01:18	2025-12-01 17:46:53	588.5417	588.5417	16950	1	0
272	5759999723	2025-12-01 08:37:00	2025-12-01 17:54:23	2324.6875	2174.6875	48954	4	0
273	7495000901	2025-12-01 08:58:08	2025-12-01 17:54:31	2080.875	1480.875	30894	9	0
274	1626467387	2025-12-01 08:34:07	2025-12-01 17:56:26	2113.0208	1963.0209	44890	4	0
275	399027689	2025-12-01 09:01:59	2025-12-01 17:59:25	660.9722	660.9722	19036	1	0
276	260972430	2025-12-01 09:34:54	2025-12-01 17:59:47	1156.9791	1006.9792	26534	4	0
277	680950736	2025-12-01 08:55:40	2025-12-01 17:59:53	975	825	23040	4	0
278	5672341574	2025-12-01 09:41:14	2025-12-01 18:00:29	974.32294	824.32294	23027	4	0
279	284763815	2025-12-01 07:58:54	2025-12-01 18:00:37	509.40973	509.40973	14671	1	0
280	438705457	2025-12-01 09:43:12	2025-12-01 18:02:40	1876.125	1276.125	27618	9	0
281	1809318229	2025-12-01 08:43:57	2025-12-01 18:02:40	1546.875	1396.875	34020	4	0
282	496415073	2025-12-01 09:13:11	2025-12-01 18:02:49	1817.7084	1667.7084	39220	4	0
283	7298707465	2025-12-01 06:42:08	2025-12-01 18:03:07	2519.279	2369.279	52690	4	0
284	958194770	2025-12-01 08:52:56	2025-12-01 18:03:52	1957.2916	1807.2916	41900	4	0
285	565989951	2025-12-01 08:46:53	2025-12-01 18:06:08	994.7917	844.7917	23420	4	0
286	689340169	2025-12-01 08:54:47	2025-12-01 18:06:16	1915.625	1765.625	41100	4	0
287	1412145236	2025-12-01 08:47:09	2025-12-01 18:06:42	1287.3438	1137.3438	29037	4	0
288	970421717	2025-12-01 09:06:58	2025-12-01 18:07:15	2173.8125	1573.8125	32381	9	0
289	729610759	2025-12-01 10:17:49	2025-12-01 18:09:12	1140.3125	990.3125	26214	4	0
290	390934584	2025-12-01 08:24:32	2025-12-01 18:10:51	1652.6562	1502.6562	36051	4	0
\.


--
-- Data for Name: work_departments; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.work_departments (id, department_id, work_id) FROM stdin;
1	4	569
2	4	614
3	5	634
4	4	642
5	5	672
6	1	676
7	5	701
8	5	709
9	3	717
10	7	743
11	5	785
12	5	788
13	7	805
14	7	806
15	5	816
16	6	825
17	7	832
18	7	837
19	7	861
20	1	864
21	5	869
22	12	871
23	5	873
24	5	874
25	2	880
26	3	904
27	3	908
28	1	913
29	3	917
30	1	929
31	5	937
32	5	945
33	1	965
34	3	970
35	5	977
36	7	982
37	7	986
38	3	999
39	7	1005
40	7	1018
41	12	1027
42	2	1040
43	7	1050
44	7	1052
45	6	1057
46	7	1061
47	5	1065
48	7	1073
49	2	1082
50	5	1167
51	5	1180
52	5	1203
53	1	1212
54	5	1225
55	5	1231
56	7	1246
57	2	1256
58	6	1270
59	5	1274
60	4	1294
61	7	1305
62	6	1313
63	3	1316
\.


--
-- Data for Name: work_permission_requests; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.work_permission_requests (id, work_id, message) FROM stdin;
1	69	Термоусадка на КМ
2	77	Монтаж камери на кронштейн
3	78	Розпаковка камер 640
4	79	Монтаж InfiRay 640 на кронштейн
5	84	Підготовка КМ
6	93	Пайка 15"
7	94	Пайка 15"
8	106	Пайка 15
9	107	Пайка 15
10	108	Збірка рам 15 опто
11	129	Робота на С3
12	131	Доставляння шампурів
13	134	Маунти
14	153	нарізка кабелю
15	154	Кришки на 15
16	156	Крошка 15
17	168	Пайка 15S’
18	175	Пайка рама15
19	179	Збірка 15"
20	181	Збірка 15"
21	192	Пайка рами 15 дюймів
22	211	Робота ц3
23	213	Робота ц3
24	214	Робота ц3
25	216	Налаштування відеоформату
26	217	Розпаковка InfiRay 640
27	219	Налаштування відеоформату камери
28	222	Кришки пропи на 15
29	226	Підготовка робочого місця
30	229	Домтановка шампурів
31	231	Підготовка компонентів
32	234	Перестановка шампурів
33	236	Достановка км
34	238	Прибирання робочого місця
35	239	Загинання КМ на шаблоні
36	244	Робота
37	251	Заміна моторів 15
38	252	Робота с3
39	253	Робота с3
40	255	Робота с3
41	257	Робота с3
42	262	Пайка рами 15
43	266	Пайка рами 15
44	269	Пайка рама 15
45	272	Сортуваня стяжок
46	274	Підготовка робочогоміста
47	276	Сортування документів
48	280	Сортування документів
49	281	Робота відділ єсц
50	286	Пайка рами 15
51	289	Збірка 15"
52	294	Пайка рами 15ʼʼ
53	298	Пайка рами 15ʼʼ
54	299	Пайка рами 15ʼʼ
55	301	Облаштування робочого місця
56	303	Облаштування робочого місця
57	305	Тестування
58	306	Робота С3
59	309	Організація робочого місця
60	310	Обліт дронів
61	313	Переробка КМ
62	321	збірка рам 15 опто
63	322	Збірка рам 15
64	362	Робота С3
65	376	3д друк доопрацювання
66	377	3д друк доопрацювання
67	385	Ремонт
68	398	Корекція 3д друку
69	400	Збірка рам 15ʼ
70	406	Налаштування відеоформату
71	409	Навчання
72	414	Обрізка зд друку
73	419	Збірка 15"
74	420	Встановлення віброгумок
75	421	Записування моторів
76	422	Маунт
77	425	Перематывая моторов
78	434	Маунта
79	438	Рами
80	446	Підготовка робочого місця
81	447	Доробка замовлень 15'
82	448	Надівання віброгумки
83	449	Обмотка моторів
84	450	Обмотки моторів
85	451	Монтаж моторів 15
86	476	порізка дротів
87	483	порізка дротів
88	485	різка дротів на станку
89	503	Облаштовування робочого місця
90	504	Надівання віброгумок
91	505	Обмотка двигунів
92	507	Облаштування місця
93	508	Обмотка двигунів
94	510	Збірка рами 15 опто
95	516	Обліт 15 ʼʼ
96	517	Обліт 15
97	529	Облет
98	530	Обмотка моторів
99	531	Обмотка моторів
100	533	Тестування дрона
101	534	Тестування дрона
102	535	Підготовка моторів 15
103	536	Збірка 15"
104	543	облаштування робочого місця
105	544	одівання віброгумок
106	545	обмотуваня двигунів
107	550	Загибання КМ
108	553	test
109	556	Збірка рам 15
110	569	Розпаковувати elrs
111	614	Розпаковка ELRS
112	628	Підготовка робочого місця
113	634	Перестановка шампурів
114	642	нарізка дротів на станку
115	668	Облаштування місця
116	672	Прибирання робочого місця
117	676	Віброгумки на ФС
118	701	Рами
119	709	Рами
120	736	Робота С3
121	737	Робота С3
122	743	Робота С3
123	776	Облаштування робочого місця
124	778	Стойки
125	780	Облаштування
126	785	Мотання моторів
127	816	C3
128	825	Робота с3
129	832	Облет
130	837	Облаштування робочого місця
131	855	Облаштування робочого місця
132	861	Обмотка баток ізолентою
133	864	Загинання КМ
134	869	обматування двигуна
135	873	облаштування робочого місця
136	874	облаштування робочого місця
137	904	Допомога відділу рам
138	908	Допомога відділу рам
139	913	Сортування пластику
140	929	Розкручування антен
141	934	Обмотка моторів
142	937	Збирання маунту
143	939	Кришки пропи
144	941	Кришки пропи
145	943	Розмотування моторів
146	945	Розмотування моторів
147	963	Загинання КМ
148	965	Сортування пластику
149	970	Допомога відділу рам
150	978	Облет, обустройство рабочего места, поклейка баток
151	980	1
152	982	Обустройство облетки
153	983	Облаштування робочого місця
154	986	Облаштування робочого місця
155	999	Допомога відділу рам
156	1018	Облаштування робочого місця
157	1049	Допомога чекапу 15”
158	1052	Обустройство 2 облетки
159	1053	Чекап 15’
160	1057	Облуштування облетки
161	1061	Облаштування робочого місця
162	1065	Збірка Peak fpv 15"
163	1071	Облаштування робочого місця
164	1073	Перемотка баток ізолентою
165	1167	Нарізання термоусадки
166	1180	Маунти
167	1203	Нарізання термоусадки
168	1212	Транспортування матеріалів
169	1225	Облаштування робочого місця
170	1229	Пік фпв
171	1231	Нарізка термоусадки
172	1246	Ремонт
173	1260	Робота с3
174	1265	Робота с3
175	1266	Робота с3
176	1267	Робота с3
177	1268	Робота с3
178	1269	Робота с3
179	1270	Робота с3
180	1274	Бр582
181	1294	Розпаковка єлерес
182	1309	Ремонт
183	1313	Заміна антени на бр 582
\.


--
-- Data for Name: worker_shifts; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.worker_shifts (id, worker_id, shift_id, update_time, secondary_shift_id) FROM stdin;
1	7828553391	1	2025-11-15 14:41:28.468607	\N
2	833326956	1	2025-11-22 11:20:59.191402	\N
3	380830168	1	2025-11-22 11:21:10.204479	\N
4	460255958	1	2025-11-22 11:23:44.219447	\N
5	958194770	1	2025-11-23 18:15:22.898208	\N
6	368487569	1	2025-11-23 18:50:54.230541	\N
7	390934584	1	2025-11-23 21:03:19.171991	\N
9	5696887952	1	2025-11-24 08:37:35.753339	\N
10	7298707465	1	2025-11-24 08:39:01.842431	\N
11	496415073	1	2025-11-24 09:11:16.639907	\N
12	450220248	1	2025-11-24 09:31:52.930329	\N
13	1171518697	1	2025-11-24 09:32:04.056604	\N
14	631343368	1	2025-11-24 09:38:51.637361	\N
15	682982694	1	2025-11-24 13:01:51.682856	\N
16	959551233	1	2025-11-24 13:58:23.796911	\N
17	1019196711	1	2025-11-24 14:30:02.693173	\N
18	1079977172	1	2025-11-24 15:23:42.912833	\N
19	583067641	1	2025-11-24 16:15:17.426624	\N
20	480267737	1	2025-11-24 17:36:04.460806	\N
21	517939536	1	2025-11-25 08:48:07.358326	\N
22	284763815	1	2025-11-25 08:55:06.659095	\N
23	7896599626	1	2025-11-25 09:02:28.669123	\N
24	1809318229	1	2025-11-25 09:04:17.15865	\N
25	680950736	1	2025-11-25 09:04:39.349433	\N
26	5759999723	1	2025-11-25 09:04:40.140614	\N
27	420293854	1	2025-11-25 09:05:29.537814	\N
29	1575913081	1	2025-11-25 09:08:38.425812	\N
30	5178631798	1	2025-11-25 09:08:52.966308	\N
31	565989951	1	2025-11-25 09:11:01.632289	\N
32	1403052047	1	2025-11-25 09:13:06.015721	\N
33	260972430	1	2025-11-25 09:19:34.715289	\N
34	5299916972	1	2025-11-25 09:26:43.182229	\N
36	689340169	1	2025-11-25 09:38:43.547138	\N
38	652782105	1	2025-11-25 10:20:40.374462	\N
39	5006100672	1	2025-11-25 10:21:27.269315	\N
40	1626467387	1	2025-11-25 10:24:02.953421	\N
41	638532571	1	2025-11-25 10:24:08.724283	\N
42	1412145236	1	2025-11-25 10:26:20.178947	\N
43	5234869387	1	2025-11-25 11:46:14.832139	\N
44	547586388	1	2025-11-25 11:48:19.186106	\N
47	729610759	1	2025-11-25 13:19:18.842866	\N
49	399027689	1	2025-11-26 08:53:15.105824	\N
50	7495000901	2	2025-11-24 00:00:00	\N
46	7495000901	1	2025-11-24 00:00:00	\N
52	7495000901	4	2025-11-24 00:00:01	\N
45	438705457	4	2025-11-24 00:00:01	\N
48	5545338450	4	2025-11-24 00:00:01	\N
51	808612634	4	2025-11-24 00:00:01	\N
8	854336769	7	2025-11-24 00:00:01	\N
37	273955619	7	2025-11-24 00:00:01	\N
28	587721103	7	2025-11-24 00:00:01	\N
53	503186206	1	2025-11-27 11:27:54.216694	\N
54	7054968599	1	2025-11-27 12:07:30.642209	\N
57	5234869387	2	2025-11-27 18:55:49	\N
58	7054968599	1	2025-11-27 18:59:53	\N
59	5234869387	1	2025-11-28 08:05:29	\N
60	1257390480	1	2025-11-28 09:05:37.049889	\N
61	503426024	1	2025-11-28 16:16:41.396335	\N
63	5672341574	1	2025-12-01 09:41:05.72464	\N
64	325323555	1	2025-12-01 09:44:02.731678	\N
65	882908144	1	2025-12-01 12:46:06.804141	\N
66	970421717	4	2025-11-24 00:00:00	\N
67	711290767	4	2025-11-24 00:00:00	\N
55	544740146	1	2025-11-24 00:00:00	\N
68	711861971	1	2025-12-01 17:02:43.042786	\N
69	524019468	4	2025-11-24 00:00:00	\N
\.


--
-- Data for Name: workers; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.workers (telegram_id, first_name, last_name, start_work_time, patronymic, internship_start_time, ipn, hurma_id, internship_end_time) FROM stdin;
7828553391	Олег	Нересниця	09:00:00	Юрійович	2023-10-03 00:00:00	\N	PoO	2023-11-03 00:00:00
833326956	Андрій	Заєць	09:00:00	Олексійович	2025-04-14 00:00:00	\N	OVJ	2025-05-14 00:00:00
380830168	Микола	Дяченко	09:00:00	Олексійович	2025-04-30 00:00:00	\N	zp2	2025-05-30 00:00:00
460255958	Максим	Павлік	09:00:00	Сергійович	2025-04-23 00:00:00	\N	BjZ	2025-05-23 00:00:00
958194770	Катерина	Сирота	09:00:00	Юріївна	2025-08-25 00:00:00	\N	6eJ	2025-09-25 00:00:00
368487569	Софія	Сегінович	09:00:00	Андріївна	2025-03-26 00:00:00	\N	JNA	2025-04-26 00:00:00
390934584	Андрій	Дмитренко	09:00:00	Віталійович	2024-11-11 00:00:00	\N	m34	2024-12-11 00:00:00
854336769	Віктор	Слободян	09:00:00	Анатолійович	2025-06-02 00:00:00	\N	mw7	2025-07-02 00:00:00
7298707465	Юрій	Литвинов Юрій Вікторович	09:00:00	Вікторович	2023-09-01 00:00:00	\N	\N	2023-10-01 00:00:00
5696887952	Володимир	Удовенко	09:00:00	Борисович	2025-08-25 00:00:00	\N	7eG	2025-09-25 00:00:00
496415073	Тимур	Александров	09:00:00	Микитович	2025-06-11 00:00:00	\N	ZGG	2025-07-11 00:00:00
631343368	Роман	Недобор	09:00:00	Миколайович	2024-07-22 00:00:00	\N	18O	2024-08-22 00:00:00
682982694	Дмитро	Трояченко	09:00:00	Петрович	2025-05-09 00:00:00	\N	X6Q	2025-06-09 00:00:00
959551233	Володимир	Москалець	09:00:00	Володимирович	2024-03-11 00:00:00	\N	8vk	2024-04-11 00:00:00
1019196711	Сергій	Кашін	09:00:00	Юрійович	2024-04-08 00:00:00	\N	pKk	2024-05-08 00:00:00
583067641	Павло	Кібукевич	09:00:00	Онисійович	2025-05-26 00:00:00	\N	vw7	2025-06-26 00:00:00
1079977172	Юлія	Кулевська	09:00:00	Анатоліївна	2025-11-05 00:00:00	\N	\N	2025-12-05 00:00:00
450220248	Вадим	Гринчук Вадим	09:00:00	Миколайович	2009-11-17 00:00:00	\N	\N	2009-12-17 00:00:00
480267737	Віктор	Лисенко	09:00:00	Едуардович	2025-05-12 00:00:00	\N	dam	2025-06-13 00:00:00
1171518697	Андрей	Горбач	09:00:00	Петрович	2024-04-01 00:00:00	\N	\N	2024-05-01 00:00:00
284763815	Ростислав	Денісов	09:00:00	Віталійович	2025-09-01 00:00:00	\N	D1k	2025-10-01 00:00:00
7896599626	Олександр	Лобач	09:00:00	Миколайович	2025-01-23 00:00:00	\N	2PZ	2025-02-23 00:00:00
517939536	Денис	Митрофанов	09:00:00	Павлович	2025-02-17 00:00:00	\N	m9P	2025-03-17 00:00:00
1809318229	Ігор	Мурзаєв	09:00:00	Юрійович	2025-10-20 00:00:00	\N	0M4	2025-11-20 00:00:00
680950736	Євген	Ісаак	09:00:00	Вікторович	2025-09-01 00:00:00	\N	NjD	2025-10-01 00:00:00
5759999723	Сергій	Васильченко	09:00:00	Олександрович	2025-09-01 00:00:00	\N	XBP	2025-10-01 00:00:00
420293854	Андрій	Дуридівка	09:00:00	Вікторович	2025-05-20 00:00:00	\N	Eok	2025-06-20 00:00:00
587721103	Данііл	Шаров	09:00:00	Михайлович	2025-07-14 00:00:00	\N	G7m	2025-08-14 00:00:00
1575913081	Олександр	Руденко	09:00:00	Романович	2025-02-06 00:00:00	\N	ZXY	2025-03-06 00:00:00
5178631798	Андрій	Головатий	09:00:00	Валентинович	2025-05-27 00:00:00	\N	kwO	2025-06-27 00:00:00
565989951	Павло	Кутурій	09:00:00	Миколайович	2025-09-15 00:00:00	\N	dPj	2025-10-15 00:00:00
1403052047	Олександр	Холявчук	09:00:00	Анатолійович	2025-07-07 00:00:00	\N	ZAa	2025-08-07 00:00:00
260972430	Микита	Смірнов	09:00:00	Михайлович	2024-09-20 00:00:00	\N	mN4	2024-10-20 00:00:00
970421717	Юрій	Бабич	09:00:00	Сергійович	2024-03-12 00:00:00	\N	86o	2024-04-12 00:00:00
273955619	Дмитро	Леонтьєв	09:00:00	Валерійович	2025-10-06 00:00:00	\N	6YQ	2025-11-06 00:00:00
652782105	Владислав	Соловей	09:00:00	Валентинович	2025-02-25 00:00:00	\N	g3Q	2025-03-25 00:00:00
5006100672	Володимир	Шевченко	09:00:00	Васильович	2025-04-22 00:00:00	\N	vA6	2025-05-22 00:00:00
1626467387	Михайло	Краснопольський	09:00:00	Миколайович	2025-02-13 00:00:00	\N	z8a	2025-03-13 00:00:00
638532571	Ярослав	Білодід	09:00:00	Євгенійович	2025-02-19 00:00:00	\N	nEn	2025-03-19 00:00:00
1412145236	Катерина	Пашко	09:00:00	Вікторівна	2025-09-01 00:00:00	\N	v2j	2025-10-01 00:00:00
5234869387	Петро	Кузьменко	09:00:00	Володимирович	2025-02-06 00:00:00	\N	RlZ	2025-03-06 00:00:00
438705457	Гліб	Свиридюк	09:00:00	Іларіонович	2025-09-25 00:00:00	\N	jjy	2025-10-25 00:00:00
729610759	Ілля	Тюлькін	09:00:00	Михайлович	2025-05-30 00:00:00	\N	7lp	2025-06-30 00:00:00
547586388	Віктор	Дікасов	09:00:00	Ігоревич	2022-11-01 00:00:00	\N	\N	2022-12-01 00:00:00
7495000901	Олександр	Аксененко	09:00:00	Владимирович	2025-09-01 00:00:00	\N	\N	2025-10-01 00:00:00
689340169	Денис	Уховський	09:00:00	Анатолійович	2025-11-01 00:00:00	\N	\N	2025-12-01 00:00:00
5299916972	Тетяна	Варварчук	09:00:00	Броніславівна	2025-11-03 00:00:00	\N	\N	2025-12-03 00:00:00
5545338450	Федір	Спатар	09:00:00	Сергійович	2025-03-11 00:00:00	\N	PL9	2025-04-11 00:00:00
399027689	Олексій	Полончук	09:00:00	Русланович	2025-06-17 00:00:00	\N	55j	2025-07-17 00:00:00
808612634	Олександр	Клименко	09:00:00	Андрійович	2024-11-06 00:00:00	\N	0x4	2024-12-06 00:00:00
503186206	Микола	Поліщук	09:00:00	Миколайович	2025-06-17 00:00:00	\N	BPO	2025-07-17 00:00:00
544740146	Ігор	Козенюк	09:00:00	Миколайович	2025-01-22 00:00:00	\N	K91	2025-02-22 00:00:00
711290767	Андрей	Аксененко	09:00:00	Александрович	2024-11-15 00:00:00	\N	\N	2024-12-15 00:00:00
7054968599	Михайло	Гасперський	09:00:00	Михайлович	2025-11-24 00:00:00	\N	AvV	2025-12-25 00:00:00
1257390480	Гордій	Князєв	09:00:00	Миколайович	2025-11-26 00:00:00	\N	MBB	2025-12-26 00:00:00
503426024	Олег	Єсипчук	09:00:00	Михайлович	2025-11-03 00:00:00	\N	YJK	2025-12-03 00:00:00
5672341574	Віктор	Сторожук	09:00:00	Іванович	2025-10-20 00:00:00	\N	PO8	2025-11-20 00:00:00
325323555	Анна	Кисельова	09:00:00	Вікторівна	2025-09-01 00:00:00	\N	021	2025-10-01 00:00:00
524019468	Роман	Козак	09:00:00	Вікторович	2025-02-25 00:00:00	\N	AyO	2025-03-25 00:00:00
882908144	Павло	Ніколайчук	09:00:00	Вікторович	2025-09-01 00:00:00	\N	jgZ	2025-10-01 00:00:00
711861971	Костянтин	Франчук	09:00:00	Валерійович	2025-08-11 00:00:00	\N	GMj	\N
\.


--
-- Data for Name: workpieces; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.workpieces (id, name, amount) FROM stdin;
\.


--
-- Data for Name: works; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.works (id, work_day_id, operation_id, start_time, finish_time, result, pause_duration, payment) FROM stdin;
1	10	9	2025-11-24 19:10:36	2025-11-24 19:10:36	1	0	0
2	11	21	2025-11-24 19:10:43	2025-11-24 19:11:04	1	0	0
3	12	33	2025-11-24 19:10:46	2025-11-24 19:10:46	0	0	0
4	12	33	2025-11-24 19:10:46	2025-11-24 19:10:46	1	0	0
5	13	14	2025-11-24 19:11:13	2025-11-24 19:11:13	10	0	0
6	14	901	2025-11-24 08:30:00	2025-11-24 17:30:00	1	0	0
7	15	900	2025-11-24 19:18:15	2025-11-24 19:18:21	1	0	0
8	17	900	2025-11-24 09:00:00	2025-11-24 17:30:00	1	0	0
9	18	15	2025-11-24 13:00:00	2025-11-24 15:00:00	100	0	0
10	18	16	2025-11-24 15:05:00	2025-11-24 16:00:00	1	0	0
11	18	900	2025-11-24 09:15:00	2025-11-24 13:00:00	1	0	0
12	25	101	2025-11-25 09:00:00	2025-11-25 16:30:34	1	0	0
13	27	900	2025-11-25 12:20:00	2025-11-25 16:46:04	1	0	0
14	28	101	2025-11-25 08:30:00	2025-11-25 17:00:40	10	0	0
18	31	901	2025-11-25 09:34:06	2025-11-25 17:34:06	1	0	0
19	32	900	2025-11-25 10:06:00	2025-11-25 12:17:16	1	0	0
20	32	900	2025-11-25 12:17:48	2025-11-25 17:37:25	1	0	0
21	33	900	2025-11-25 09:13:23	2025-11-25 17:42:54	1	0	1217.2396
23	35	900	2025-11-25 11:52:00	2025-11-25 17:54:46	1	0	758.6458
24	36	900	2025-11-25 09:09:35	2025-11-25 17:56:38	1	0	1272.0312
25	37	900	2025-11-25 09:00:00	2025-11-25 17:56:28	1	0	1301.4584
26	38	900	2025-11-25 09:11:37	2025-11-25 09:12:39	5	0	0
27	38	900	2025-11-25 09:12:58	2025-11-25 17:59:36	100	0	1271.8055
28	39	900	2025-11-25 09:00:00	2025-11-25 17:57:23	1	0	1304.3229
29	40	900	2025-11-25 09:00:00	2025-11-25 17:59:48	1	0	1311.875
30	41	900	2025-11-25 09:20:00	2025-11-25 12:21:23	1	0	0
31	41	900	2025-11-25 12:21:58	2025-11-25 18:00:16	1	511	844.5139
32	42	900	2025-11-25 09:14:50	2025-11-25 10:05:26	1	0	0
33	42	40	2025-11-25 10:08:53	2025-11-25 10:16:18	5	0	0
34	42	42	2025-11-25 10:16:28	2025-11-25 10:28:21	5	0	0
35	42	43	2025-11-25 10:28:42	2025-11-25 10:52:13	5	0	0
36	42	40	2025-11-25 10:56:00	2025-11-25 11:02:36	5	0	0
37	42	42	2025-11-25 11:02:49	2025-11-25 11:14:14	5	0	0
38	42	43	2025-11-25 11:22:41	2025-11-25 11:45:04	5	0	0
39	42	40	2025-11-25 11:47:49	2025-11-25 11:49:05	1	0	0
40	42	42	2025-11-25 11:49:15	2025-11-25 11:51:34	1	0	0
41	42	43	2025-11-25 11:51:43	2025-11-25 11:55:03	1	0	0
42	42	40	2025-11-25 12:04:43	2025-11-25 12:06:41	1	0	0
43	42	42	2025-11-25 12:06:49	2025-11-25 12:14:07	1	267	0
44	42	43	2025-11-25 12:14:12	2025-11-25 12:17:02	1	0	0
45	42	40	2025-11-25 12:17:16	2025-11-25 12:18:13	1	0	0
46	42	900	2025-11-25 12:42:34	2025-11-25 15:00:32	1	1975	0
47	42	900	2025-11-25 15:03:06	2025-11-25 17:58:04	1	716	339.65277
48	43	900	2025-11-25 09:02:00	2025-11-25 12:21:32	1	0	0
49	43	900	2025-11-25 12:22:07	2025-11-25 18:00:50	1	0	891.3368
50	44	900	2025-11-25 09:00:00	2025-11-25 13:52:18	1	0	0
51	44	900	2025-11-25 14:18:15	2025-11-25 18:01:27	1	0	626.9792
52	45	900	2025-11-25 09:00:00	2025-11-25 18:02:39	1	0	1320.7812
53	46	900	2025-11-25 09:11:00	2025-11-25 12:21:00	2	0	0
54	46	900	2025-11-25 12:21:51	2025-11-25 18:02:55	1	470	864.2708
55	47	900	2025-11-25 09:08:55	2025-11-25 18:05:07	1	0	1300.625
58	50	900	2025-11-25 09:28:19	2025-11-25 18:09:36	1	145	1246.4584
59	51	900	2025-11-25 08:07:00	2025-11-25 18:09:31	1	0	1507.8646
60	52	901	2025-11-25 08:08:56	2025-11-25 18:09:10	1	0	0
61	53	900	2025-11-25 09:09:15	2025-11-25 18:11:42	1	0	1320.1562
62	54	900	2025-11-25 08:40:00	2025-11-25 18:13:04	1	0	1415.8334
63	55	900	2025-11-25 08:52:00	2025-11-25 11:40:56	1	0	0
64	55	900	2025-11-25 12:19:12	2025-11-25 18:06:57	1	0	946.18054
65	56	900	2025-11-25 09:09:30	2025-11-25 18:18:22	1	0	1340.2084
66	58	900	2025-11-25 09:20:00	2025-11-25 11:18:13	64	0	0
67	58	900	2025-11-25 11:35:26	2025-11-25 12:05:05	40	0	0
68	58	900	2025-11-25 12:05:42	2025-11-25 15:55:34	220	0	0
69	58	900	2025-11-25 16:04:47	2025-11-25 18:25:06	220	0	438.4896
71	60	33	2025-11-25 17:03:02	2025-11-25 17:03:14	0	0	0
72	61	900	2025-11-25 09:29:00	2025-11-25 10:07:13	1	0	0
73	61	900	2025-11-25 10:08:42	2025-11-25 12:42:54	80	0	0
74	61	900	2025-11-25 12:45:06	2025-11-25 13:39:23	45	0	0
75	61	900	2025-11-25 13:40:32	2025-11-25 15:21:15	40	0	0
76	61	900	2025-11-25 15:21:31	2025-11-25 15:40:13	55	0	0
77	61	900	2025-11-25 15:40:26	2025-11-25 16:46:17	100	0	0
78	61	900	2025-11-25 16:46:51	2025-11-25 17:30:22	55	0	0
79	61	900	2025-11-25 17:30:53	2025-11-25 18:31:43	40	0	190.10417
80	62	47	2025-11-25 09:16:15	2025-11-25 10:07:23	1	0	0
81	62	900	2025-11-25 09:16:00	2025-11-25 12:42:56	80	39	429.75696
82	62	900	2025-11-25 12:43:42	2025-11-25 15:27:23	115	1270	0
83	62	900	2025-11-25 15:27:43	2025-11-25 16:55:50	115	0	0
84	62	900	2025-11-25 16:56:35	2025-11-25 19:17:50	100	0	441.40625
85	63	900	2025-11-25 07:20:41	2025-11-25 19:16:48	1	509	1836.3541
86	64	900	2025-11-25 07:28:50	2025-11-25 19:29:51	1	0	1878.2118
87	66	900	2025-11-25 09:08:00	2025-11-25 12:25:43	1	0	0
88	66	900	2025-11-25 12:26:16	2025-11-25 18:24:03	1	1233	884.809
89	67	900	2025-11-25 12:12:18	2025-11-25 18:04:37	1	0	733.99304
90	68	81	2025-11-26 09:35:25	2025-11-26 09:36:01	660	0	965.625
91	68	60	2025-11-26 09:36:11	2025-11-26 09:36:15	31	0	50.052082
22	34	101	2025-11-25 08:18:00	2025-11-25 17:40:05	10	0	1402.4132
93	69	900	2025-11-26 08:53:00	2025-11-26 10:32:50	1	0	207.98611
94	69	900	2025-11-26 10:33:35	2025-11-26 16:02:44	1	0	757.5868
95	70	93	2025-11-26 08:36:32	2025-11-26 09:28:31	40	0	155.55556
96	70	95	2025-11-26 09:33:05	2025-11-26 10:18:55	20	619	142.36111
97	70	76	2025-11-26 09:47:39	2025-11-26 10:23:12	20	1305	36.805557
98	70	95	2025-11-26 10:25:46	2025-11-26 11:17:05	20	925	142.36111
99	70	76	2025-11-26 10:43:27	2025-11-26 11:19:50	20	1126	36.805557
100	70	75	2025-11-26 11:27:08	2025-11-26 12:09:34	40	0	155.55556
101	70	77	2025-11-26 12:09:55	2025-11-26 12:19:27	40	0	55.555557
102	70	94	2025-11-26 12:22:06	2025-11-26 12:42:40	40	0	100
103	70	93	2025-11-26 13:19:57	2025-11-26 14:16:58	40	0	233.33333
104	70	95	2025-11-26 14:17:26	2025-11-26 15:11:30	20	633	213.54167
105	70	76	2025-11-26 14:39:03	2025-11-26 15:14:15	20	1348	55.208332
106	71	900	2025-11-26 09:30:00	2025-11-26 10:32:53	1	0	131.00694
107	71	900	2025-11-26 10:33:32	2025-11-26 16:15:42	1	1192	697.691
70	59	901	2025-11-25 09:05:46	2025-11-25 18:26:17	20	963	1326.4584
56	48	900	2025-11-25 09:38:00	2025-11-25 12:22:06	1	20	341.18054
57	48	900	2025-11-25 12:23:16	2025-11-25 18:03:32	1	0	858.9236
17	30	900	2025-11-25 09:14:25	2025-11-25 17:28:59	1	0	1170.5209
15	29	900	2025-11-25 10:00:00	2025-11-25 12:17:14	1	0	285.90277
16	29	900	2025-11-25 12:17:50	2025-11-25 17:05:06	1	0	665.6597
92	19	101	2025-11-24 08:00:00	2025-11-24 19:20:00	1	0	1750
108	72	900	2025-11-26 07:20:46	2025-11-26 17:20:57	1	74	1496.7188
109	73	101	2025-11-26 08:39:05	2025-11-26 17:26:24	1	0	1272.8646
110	74	75	2025-11-26 08:37:15	2025-11-26 09:03:51	20	0	77.77778
111	74	77	2025-11-26 09:04:09	2025-11-26 09:15:29	20	0	27.777779
112	74	94	2025-11-26 09:16:18	2025-11-26 09:31:30	20	0	37.5
113	74	93	2025-11-26 09:31:48	2025-11-26 09:54:02	20	0	77.77778
114	74	95	2025-11-26 09:54:27	2025-11-26 10:24:30	20	0	142.36111
115	74	76	2025-11-26 10:25:14	2025-11-26 10:37:39	20	0	36.805557
116	74	75	2025-11-26 10:37:54	2025-11-26 11:03:39	20	0	77.77778
117	74	77	2025-11-26 11:03:52	2025-11-26 11:08:47	20	0	27.777779
118	74	94	2025-11-26 11:09:10	2025-11-26 11:23:28	20	0	37.5
119	74	93	2025-11-26 11:23:45	2025-11-26 11:42:36	20	0	77.77778
120	74	95	2025-11-26 11:42:57	2025-11-26 12:39:25	20	0	148.95833
121	74	75	2025-11-26 12:40:42	2025-11-26 13:05:44	20	0	116.666664
122	74	77	2025-11-26 13:05:59	2025-11-26 13:15:46	20	0	41.666668
123	74	76	2025-11-26 13:16:17	2025-11-26 13:31:33	20	0	55.208332
124	74	94	2025-11-26 13:31:53	2025-11-26 13:46:58	20	0	56.25
125	74	93	2025-11-26 13:47:15	2025-11-26 14:18:22	20	0	116.666664
126	74	95	2025-11-26 14:57:59	2025-11-26 17:03:38	20	0	213.54167
127	74	76	2025-11-26 17:04:08	2025-11-26 17:30:18	20	0	55.208332
128	75	88	2025-11-26 09:00:50	2025-11-26 09:07:27	1	0	22.916666
129	75	900	2025-11-26 09:27:23	2025-11-26 09:37:55	1	0	21.944445
130	75	88	2025-11-26 09:38:11	2025-11-26 10:06:10	3	0	68.75
131	75	900	2025-11-26 10:06:36	2025-11-26 13:27:22	1	0	418.2639
132	75	88	2025-11-26 13:27:57	2025-11-26 14:50:16	8	0	183.33333
133	75	88	2025-11-26 15:09:46	2025-11-26 16:48:37	10	0	326.35416
134	75	900	2025-11-26 16:48:53	2025-11-26 17:37:58	1	0	153.38542
135	76	95	2025-11-26 08:29:11	2025-11-26 08:42:55	5	0	35.59028
136	76	75	2025-11-26 08:43:32	2025-11-26 09:40:22	40	0	155.55556
137	76	77	2025-11-26 09:40:35	2025-11-26 09:54:05	40	0	55.555557
138	76	94	2025-11-26 09:54:22	2025-11-26 10:12:19	20	0	37.5
139	76	76	2025-11-26 10:12:31	2025-11-26 10:16:30	5	0	9.201389
140	76	93	2025-11-26 10:16:38	2025-11-26 10:45:31	20	0	77.77778
141	76	95	2025-11-26 10:46:01	2025-11-26 11:35:51	20	0	142.36111
142	76	76	2025-11-26 11:35:59	2025-11-26 11:44:36	20	0	36.805557
143	76	94	2025-11-26 11:46:07	2025-11-26 12:03:35	20	0	37.5
144	76	93	2025-11-26 12:03:41	2025-11-26 12:51:24	20	0	77.77778
145	76	95	2025-11-26 13:33:57	2025-11-26 14:26:16	20	0	171.35417
146	76	76	2025-11-26 14:26:27	2025-11-26 14:36:44	20	0	55.208332
147	76	75	2025-11-26 14:42:46	2025-11-26 15:07:34	20	0	116.666664
148	76	77	2025-11-26 15:08:00	2025-11-26 15:17:57	20	0	41.666668
149	76	94	2025-11-26 15:18:13	2025-11-26 15:34:03	20	0	56.25
150	76	93	2025-11-26 15:34:12	2025-11-26 16:09:08	20	0	116.666664
151	76	95	2025-11-26 16:09:34	2025-11-26 16:53:21	20	0	213.54167
152	76	76	2025-11-26 16:53:30	2025-11-26 17:02:41	20	0	55.208332
153	76	900	2025-11-26 17:30:37	2025-11-26 17:54:36	1	0	74.947914
154	77	900	2025-11-26 09:03:24	2025-11-26 12:13:34	1	0	396.18054
155	77	61	2025-11-26 12:13:45	2025-11-26 14:17:40	30	0	293.40277
156	77	900	2025-11-26 14:18:53	2025-11-26 15:43:39	1	0	264.89584
157	77	96	2025-11-26 15:44:00	2025-11-26 17:56:03	50	0	361.97916
158	78	57	2025-11-26 09:28:19	2025-11-26 09:44:13	2	0	45.833332
159	78	54	2025-11-26 09:56:12	2025-11-26 11:08:04	60	0	187.5
160	78	57	2025-11-26 11:27:34	2025-11-26 11:47:42	3	0	68.75
161	78	57	2025-11-26 11:58:45	2025-11-26 12:17:09	3	0	68.75
162	78	57	2025-11-26 12:33:12	2025-11-26 12:53:09	3	0	68.75
163	78	57	2025-11-26 13:39:06	2025-11-26 14:03:20	3	0	68.75
164	78	57	2025-11-26 15:22:09	2025-11-26 15:34:28	2	0	45.833332
165	78	57	2025-11-26 15:50:08	2025-11-26 15:55:10	1	0	22.916666
166	78	56	2025-11-26 16:51:10	2025-11-26 17:10:34	5	0	62.5
167	78	56	2025-11-26 17:18:45	2025-11-26 17:58:52	10	0	132.29167
168	78	900	2025-11-26 11:08:28	2025-11-26 17:58:58	1	9727	776.19794
169	79	56	2025-11-26 08:53:17	2025-11-26 10:36:20	18	0	225
170	79	57	2025-11-26 11:30:48	2025-11-26 12:01:55	3	0	68.75
171	79	57	2025-11-26 12:39:42	2025-11-26 13:07:10	3	0	68.75
172	79	57	2025-11-26 13:49:41	2025-11-26 14:17:05	3	0	68.75
173	79	57	2025-11-26 15:19:11	2025-11-26 15:37:46	2	0	45.833332
174	79	57	2025-11-26 15:50:21	2025-11-26 16:08:16	2	0	45.833332
175	79	900	2025-11-26 10:37:27	2025-11-26 16:49:24	1	7484	659.01044
176	79	56	2025-11-26 16:49:33	2025-11-26 17:59:27	15	0	281.25
177	80	88	2025-11-26 08:55:00	2025-11-26 09:34:19	5	0	114.583336
178	80	88	2025-11-26 09:38:54	2025-11-26 10:09:26	3	0	68.75
179	80	900	2025-11-26 10:09:47	2025-11-26 12:52:17	1	0	338.54166
180	80	83	2025-11-26 13:31:34	2025-11-26 14:10:11	10	0	69.791664
181	80	900	2025-11-26 14:10:22	2025-11-26 17:59:32	1	0	636.9792
182	81	56	2025-11-26 09:12:00	2025-11-26 09:35:11	5	0	62.5
183	81	57	2025-11-26 09:35:23	2025-11-26 09:47:11	2	0	45.833332
184	81	54	2025-11-26 09:47:29	2025-11-26 10:31:52	50	0	156.25
185	81	57	2025-11-26 10:42:40	2025-11-26 11:05:25	3	0	68.75
186	81	57	2025-11-26 11:49:04	2025-11-26 12:16:09	4	0	91.666664
187	81	57	2025-11-26 12:23:23	2025-11-26 12:49:01	3	0	68.75
188	81	57	2025-11-26 14:18:59	2025-11-26 14:27:23	1	0	22.916666
189	81	57	2025-11-26 15:23:54	2025-11-26 15:41:22	2	0	45.833332
190	81	57	2025-11-26 15:47:11	2025-11-26 15:54:27	1	0	22.916666
191	81	56	2025-11-26 16:51:09	2025-11-26 17:13:17	5	0	62.5
192	81	900	2025-11-26 10:35:18	2025-11-26 17:22:34	1	8017	804.11456
193	81	56	2025-11-26 17:22:41	2025-11-26 17:59:54	15	0	281.25
194	82	75	2025-11-26 08:58:58	2025-11-26 09:17:18	10	0	38.88889
195	82	77	2025-11-26 09:18:28	2025-11-26 09:24:31	10	0	13.888889
196	82	94	2025-11-26 09:25:15	2025-11-26 09:59:16	20	0	37.5
197	82	93	2025-11-26 10:00:09	2025-11-26 10:43:32	20	0	77.77778
198	82	95	2025-11-26 10:44:11	2025-11-26 11:56:37	20	0	142.36111
199	82	76	2025-11-26 11:57:16	2025-11-26 12:20:48	20	0	36.805557
200	82	75	2025-11-26 12:39:28	2025-11-26 13:17:02	20	0	77.77778
201	82	77	2025-11-26 13:17:15	2025-11-26 13:27:53	20	0	27.777779
202	82	94	2025-11-26 13:28:35	2025-11-26 14:02:23	20	0	37.5
203	82	93	2025-11-26 14:02:40	2025-11-26 14:48:36	20	0	77.77778
204	82	95	2025-11-26 14:49:30	2025-11-26 15:55:18	20	0	142.36111
205	82	76	2025-11-26 15:55:36	2025-11-26 16:15:10	20	0	36.805557
206	82	75	2025-11-26 16:22:44	2025-11-26 16:55:18	20	0	115.27778
207	82	77	2025-11-26 16:55:38	2025-11-26 17:07:32	20	0	41.666668
208	82	75	2025-11-26 17:11:23	2025-11-26 17:41:45	20	0	116.666664
209	82	77	2025-11-26 17:41:55	2025-11-26 17:50:55	20	0	41.666668
210	83	64	2025-11-26 14:01:41	2025-11-26 14:41:52	10	817	131.25
211	83	900	2025-11-26 10:09:50	2025-11-26 15:21:07	1	1657	590.9722
212	83	64	2025-11-26 16:55:27	2025-11-26 17:27:16	12	0	222.36111
213	83	900	2025-11-26 15:21:25	2025-11-26 17:33:00	1	1918	311.3021
214	83	900	2025-11-26 17:37:34	2025-11-26 17:59:53	1	0	69.739586
215	84	68	2025-11-26 09:22:08	2025-11-26 09:48:23	15	0	27.083334
216	84	900	2025-11-26 09:49:47	2025-11-26 10:57:26	200	0	140.9375
217	84	900	2025-11-26 14:01:47	2025-11-26 14:26:02	10	0	50.520832
218	84	68	2025-11-26 14:26:34	2025-11-26 14:34:14	10	0	18.055555
219	84	900	2025-11-26 14:35:19	2025-11-26 14:54:17	40	0	39.51389
220	84	99	2025-11-26 10:57:51	2025-11-26 15:57:25	447	3197	554.61804
221	84	60	2025-11-26 15:57:42	2025-11-26 17:53:15	128	0	206.66667
222	85	900	2025-11-26 08:32:50	2025-11-26 12:08:30	1	0	449.30554
223	85	61	2025-11-26 12:08:39	2025-11-26 18:01:16	90	0	1166.8403
224	86	88	2025-11-26 08:09:15	2025-11-26 09:01:38	5	0	114.583336
225	86	88	2025-11-26 09:05:19	2025-11-26 09:13:21	1	0	22.916666
226	86	900	2025-11-26 09:22:59	2025-11-26 09:40:43	1	0	36.944443
227	86	88	2025-11-26 09:40:53	2025-11-26 09:55:49	2	0	45.833332
228	86	88	2025-11-26 09:56:56	2025-11-26 10:16:12	2	0	45.833332
229	86	900	2025-11-26 10:16:22	2025-11-26 13:25:53	1	0	394.8264
230	86	88	2025-11-26 13:26:02	2025-11-26 13:37:31	1	0	22.916666
231	86	900	2025-11-26 14:01:12	2025-11-26 14:08:14	1	0	14.652778
232	86	88	2025-11-26 14:08:27	2025-11-26 14:57:55	5	0	146.12848
233	86	88	2025-11-26 15:01:31	2025-11-26 15:36:40	3	0	103.125
234	86	900	2025-11-26 15:36:54	2025-11-26 15:58:49	1	0	68.489586
235	86	88	2025-11-26 15:59:37	2025-11-26 16:21:00	2	0	68.75
236	86	900	2025-11-26 16:22:20	2025-11-26 16:23:29	1	0	3.59375
237	86	88	2025-11-26 16:24:55	2025-11-26 17:21:09	5	0	171.875
238	86	900	2025-11-26 17:22:58	2025-11-26 18:02:03	1	0	122.135414
239	87	900	2025-11-26 10:55:41	2025-11-26 11:23:54	1	0	58.78472
240	87	60	2025-11-26 09:44:17	2025-11-26 12:07:51	64	2094	68.888885
241	87	60	2025-11-26 12:29:39	2025-11-26 13:38:23	64	0	68.888885
242	87	81	2025-11-26 13:58:18	2025-11-26 16:37:30	400	0	541.6667
243	87	60	2025-11-26 16:44:57	2025-11-26 17:42:32	56	0	84.53125
244	88	900	2025-11-26 09:29:10	2025-11-26 18:03:14	4	589	1200.7812
245	89	101	2025-11-26 09:05:07	2025-11-26 18:03:10	1	0	1306.4062
246	90	48	2025-11-26 08:11:01	2025-11-26 08:40:10	5	0	64.236115
247	90	51	2025-11-26 08:40:50	2025-11-26 09:40:38	60	0	95.833336
248	90	48	2025-11-26 09:40:56	2025-11-26 11:35:18	19	0	244.09723
249	90	52	2025-11-26 11:35:46	2025-11-26 13:02:30	19	0	145.13889
250	90	52	2025-11-26 13:06:01	2025-11-26 13:36:26	10	0	76.388885
251	90	900	2025-11-26 13:37:30	2025-11-26 18:01:39	1	0	795.434
252	91	900	2025-11-26 09:04:02	2025-11-26 13:49:57	1	1	595.625
253	91	900	2025-11-26 13:54:06	2025-11-26 14:13:02	1	0	39.444443
254	91	64	2025-11-26 13:50:03	2025-11-26 14:41:36	10	1155	139.40973
255	91	900	2025-11-26 14:41:47	2025-11-26 16:30:21	1	0	339.27084
256	91	64	2025-11-26 16:30:59	2025-11-26 17:01:57	13	0	255.9375
257	91	900	2025-11-26 17:03:08	2025-11-26 17:23:30	1	0	63.645832
258	91	64	2025-11-26 17:23:46	2025-11-26 18:03:25	9	0	177.1875
259	92	56	2025-11-26 08:37:25	2025-11-26 10:01:17	20	15	250
260	92	56	2025-11-26 10:19:58	2025-11-26 11:25:53	20	0	250
261	92	57	2025-11-26 12:09:32	2025-11-26 12:37:24	1	0	22.916666
262	92	900	2025-11-26 08:23:43	2025-11-26 12:38:03	1	10847	153.22917
263	92	57	2025-11-26 12:38:16	2025-11-26 12:38:21	4	0	100.572914
264	92	57	2025-11-26 12:38:59	2025-11-26 12:49:26	1	0	34.375
265	92	57	2025-11-26 14:21:32	2025-11-26 14:44:21	3	0	103.125
266	92	900	2025-11-26 12:50:31	2025-11-26 15:23:58	2	1400	406.6146
267	92	57	2025-11-26 15:24:20	2025-11-26 15:42:16	2	0	68.75
268	92	56	2025-11-26 15:42:24	2025-11-26 16:24:02	15	0	281.25
269	92	900	2025-11-26 16:26:02	2025-11-26 16:51:11	1	0	78.59375
270	92	56	2025-11-26 16:51:18	2025-11-26 18:03:58	25	0	468.75
271	93	40	2025-11-26 09:21:47	2025-11-26 09:21:51	0	0	0
272	93	900	2025-11-26 09:09:28	2025-11-26 09:58:14	1	87	98.576385
273	93	43	2025-11-26 10:29:25	2025-11-26 10:29:28	0	0	0
274	93	900	2025-11-26 10:05:28	2025-11-26 11:05:44	1	59	123.50694
275	93	42	2025-11-26 13:01:19	2025-11-26 13:01:23	0	0	0
276	93	900	2025-11-26 11:53:04	2025-11-26 15:48:55	1	6833	254.09723
277	93	40	2025-11-26 15:56:29	2025-11-26 16:01:52	4	0	0
278	93	42	2025-11-26 16:08:55	2025-11-26 16:27:43	4	840	0
279	93	43	2025-11-26 16:32:26	2025-11-26 16:44:22	4	0	0
280	93	900	2025-11-26 16:55:03	2025-11-26 17:43:17	1	0	100.486115
281	94	900	2025-11-26 08:23:39	2025-11-26 08:30:13	1	0	13.680555
282	94	54	2025-11-26 08:30:55	2025-11-26 08:50:36	10	0	31.25
283	94	56	2025-11-26 08:50:47	2025-11-26 09:04:15	3	0	37.5
284	94	57	2025-11-26 09:04:25	2025-11-26 09:32:33	3	0	68.75
285	94	54	2025-11-26 09:45:31	2025-11-26 10:41:14	30	0	93.75
286	94	900	2025-11-26 10:42:00	2025-11-26 16:49:47	1	0	896.7882
287	94	56	2025-11-26 16:49:56	2025-11-26 18:07:31	20	0	250
288	95	901	2025-11-26 08:04:05	2025-11-26 18:08:17	20	916	1465.4166
289	96	900	2025-11-26 09:29:56	2025-11-26 18:09:00	1	0	1247.0834
290	99	57	2025-11-26 09:00:51	2025-11-26 09:42:58	5	0	114.583336
291	99	56	2025-11-26 09:43:32	2025-11-26 10:17:34	5	0	62.5
292	99	57	2025-11-26 10:17:40	2025-11-26 10:47:13	3	0	68.75
293	99	56	2025-11-26 10:47:21	2025-11-26 11:06:51	5	0	62.5
294	99	900	2025-11-26 11:07:52	2025-11-26 12:15:49	1	0	141.5625
295	99	57	2025-11-26 12:15:56	2025-11-26 12:46:42	4	0	91.666664
296	99	57	2025-11-26 12:47:12	2025-11-26 13:01:06	2	0	45.833332
297	99	57	2025-11-26 15:21:30	2025-11-26 15:27:31	1	0	22.916666
298	99	900	2025-11-26 13:01:51	2025-11-26 15:39:04	1	382	401.5625
299	99	900	2025-11-26 15:39:37	2025-11-26 16:49:15	1	0	217.60417
300	99	56	2025-11-26 16:49:28	2025-11-26 18:14:59	23	0	431.25
301	100	900	2025-11-26 08:53:48	2025-11-26 13:44:12	1	0	605
302	100	88	2025-11-26 13:44:30	2025-11-26 17:05:30	19	0	580.625
303	100	900	2025-11-26 17:05:49	2025-11-26 18:19:21	1	0	229.79167
304	101	901	2025-11-26 08:31:05	2025-11-26 18:16:46	1	0	1455.2604
305	102	900	2025-11-26 08:45:36	2025-11-26 18:24:42	1	0	1434.6875
306	103	900	2025-11-26 10:23:13	2025-11-26 18:33:20	1	0	1156.6146
307	104	901	2025-11-26 09:17:22	2025-11-26 18:45:13	1	0	1399.5312
308	105	101	2025-11-26 07:52:48	2025-11-26 18:44:11	1	600	1629.3229
309	106	900	2025-11-26 08:56:03	2025-11-26 10:03:17	1	0	140.06944
310	106	900	2025-11-26 10:03:26	2025-11-26 18:46:32	25	0	1329.7222
311	107	80	2025-11-26 08:44:00	2025-11-26 09:30:47	100	0	2104.1667
312	107	79	2025-11-26 10:12:00	2025-11-26 10:25:59	5	0	15.972222
313	107	900	2025-11-26 10:26:19	2025-11-26 11:59:47	1	0	194.72223
314	107	60	2025-11-26 09:31:46	2025-11-26 12:18:13	64	6501	68.888885
315	107	60	2025-11-26 14:20:18	2025-11-26 14:20:30	128	0	137.77777
316	107	79	2025-11-26 12:20:55	2025-11-26 14:20:45	0	6760	0
317	107	81	2025-11-26 14:20:59	2025-11-26 17:27:29	400	0	715.625
318	107	60	2025-11-26 17:27:51	2025-11-26 18:12:49	64	0	103.333336
319	107	79	2025-11-26 18:13:52	2025-11-26 18:35:26	30	0	143.75
320	107	80	2025-11-26 18:35:46	2025-11-26 18:54:40	30	0	62.5
321	109	900	2025-11-26 07:22:25	2025-11-26 19:48:32	1	0	1956.6146
322	110	900	2025-11-26 06:51:31	2025-11-26 20:00:54	1	698	2055.4688
323	114	95	2025-11-27 11:28:17	2025-11-27 11:28:21	20	0	142.36111
324	114	93	2025-11-27 11:28:34	2025-11-27 11:28:39	40	0	155.55556
325	114	94	2025-11-27 11:28:47	2025-11-27 11:28:51	40	0	75
326	114	77	2025-11-27 11:29:10	2025-11-27 11:29:18	40	0	55.555557
327	114	75	2025-11-27 11:29:28	2025-11-27 11:29:32	40	0	155.55556
328	114	76	2025-11-27 11:29:44	2025-11-27 11:29:49	20	0	36.805557
329	114	95	2025-11-27 11:31:14	2025-11-27 12:21:16	20	0	148.95833
330	114	76	2025-11-27 12:21:22	2025-11-27 12:21:26	20	0	55.208332
331	114	95	2025-11-27 12:46:16	2025-11-27 13:34:49	20	0	213.54167
332	114	76	2025-11-27 13:34:54	2025-11-27 13:34:57	20	0	55.208332
333	114	75	2025-11-27 13:35:16	2025-11-27 13:57:39	20	0	116.666664
334	114	77	2025-11-27 13:57:49	2025-11-27 14:02:26	20	0	41.666668
335	114	94	2025-11-27 14:05:35	2025-11-27 14:10:41	10	0	28.125
336	114	93	2025-11-27 14:10:48	2025-11-27 14:22:56	10	0	58.333332
337	114	95	2025-11-27 14:26:53	2025-11-27 14:55:02	10	0	106.770836
338	114	76	2025-11-27 14:55:10	2025-11-27 14:55:13	10	0	27.604166
339	114	69	2025-11-27 15:13:36	2025-11-27 15:39:16	130	0	88.020836
340	114	69	2025-11-27 15:39:54	2025-11-27 16:18:10	260	0	176.04167
341	114	71	2025-11-27 16:23:06	2025-11-27 16:31:42	16	0	25
342	114	72	2025-11-27 16:32:29	2025-11-27 16:34:10	16	0	8.333333
343	114	73	2025-11-27 16:34:43	2025-11-27 16:36:56	16	0	12.5
344	114	71	2025-11-27 16:37:03	2025-11-27 16:44:21	20	0	31.25
345	114	72	2025-11-27 16:46:06	2025-11-27 16:46:10	20	0	10.416667
346	114	73	2025-11-27 16:46:19	2025-11-27 16:48:58	20	0	15.625
347	115	75	2025-11-27 11:32:51	2025-11-27 11:33:13	40	0	155.55556
348	115	77	2025-11-27 11:33:27	2025-11-27 11:33:32	40	0	55.555557
349	115	94	2025-11-27 11:33:52	2025-11-27 11:34:00	40	0	75
350	115	93	2025-11-27 11:34:13	2025-11-27 12:09:29	40	0	155.55556
351	115	95	2025-11-27 12:10:42	2025-11-27 13:50:50	40	0	284.72223
352	115	76	2025-11-27 13:51:43	2025-11-27 14:17:55	40	0	98.611115
353	115	75	2025-11-27 14:18:11	2025-11-27 14:45:18	27	0	157.5
354	115	77	2025-11-27 14:45:30	2025-11-27 15:02:05	27	0	56.25
355	115	94	2025-11-27 15:02:33	2025-11-27 15:13:32	27	0	75.9375
356	115	93	2025-11-27 15:13:40	2025-11-27 15:28:52	27	0	157.5
357	115	95	2025-11-27 15:29:27	2025-11-27 16:17:58	27	0	288.28125
358	115	76	2025-11-27 16:18:33	2025-11-27 16:28:21	27	0	74.53125
359	115	71	2025-11-27 16:29:21	2025-11-27 16:41:03	50	0	78.125
360	115	72	2025-11-27 16:41:26	2025-11-27 16:44:35	50	0	26.041666
361	115	73	2025-11-27 16:44:46	2025-11-27 16:55:17	50	0	39.0625
362	116	900	2025-11-27 10:45:00	2025-11-27 17:05:53	1	0	978.3125
363	117	54	2025-11-27 12:00:11	2025-11-27 12:10:32	20	0	62.5
364	117	56	2025-11-27 11:33:58	2025-11-27 12:29:27	10	650	125
365	117	54	2025-11-27 12:39:54	2025-11-27 13:00:53	20	0	62.5
366	117	56	2025-11-27 12:29:48	2025-11-27 13:21:03	6	1273	75
367	117	54	2025-11-27 13:23:22	2025-11-27 13:23:33	0	0	0
368	117	57	2025-11-27 08:15:00	2025-11-27 09:15:00	6	0	137.5
369	117	56	2025-11-27 09:20:00	2025-11-27 11:30:00	24	0	306.25
370	117	54	2025-11-27 14:15:07	2025-11-27 14:58:05	42	0	196.875
371	117	56	2025-11-27 13:46:41	2025-11-27 15:20:39	10	2591	187.5
372	117	56	2025-11-27 15:20:47	2025-11-27 16:05:35	10	0	187.5
373	117	57	2025-11-27 16:06:51	2025-11-27 16:44:31	2	0	68.75
374	117	56	2025-11-27 16:44:40	2025-11-27 17:10:02	5	0	93.75
375	118	56	2025-11-27 09:30:00	2025-11-27 10:30:00	10	0	125
376	118	900	2025-11-27 10:30:00	2025-11-27 11:28:21	1	0	121.5625
377	118	900	2025-11-27 11:29:23	2025-11-27 12:06:34	1	0	77.46528
378	118	56	2025-11-27 12:06:42	2025-11-27 12:19:55	5	0	62.5
379	118	56	2025-11-27 13:14:41	2025-11-27 14:09:00	15	0	187.5
380	118	56	2025-11-27 14:25:11	2025-11-27 15:19:58	15	0	193.26389
381	118	56	2025-11-27 15:29:52	2025-11-27 16:20:01	15	0	281.25
382	118	57	2025-11-27 16:29:37	2025-11-27 17:04:28	4	0	137.5
383	119	64	2025-11-27 10:20:00	2025-11-27 14:57:26	41	0	538.125
384	119	64	2025-11-27 14:57:50	2025-11-27 15:42:44	19	0	268.125
385	119	900	2025-11-27 15:54:06	2025-11-27 17:18:32	1	0	263.85416
386	120	54	2025-11-27 10:00:00	2025-11-27 11:27:59	50	0	156.25
387	120	13	2025-11-27 09:35:00	2025-11-27 10:00:00	800	0	0
388	120	53	2025-11-27 11:28:53	2025-11-27 12:22:27	300	0	187.5
389	120	54	2025-11-27 12:22:36	2025-11-27 15:02:03	130	0	406.25
390	120	56	2025-11-27 08:35:00	2025-11-27 09:35:00	5	0	93.75
391	120	54	2025-11-27 15:12:07	2025-11-27 17:06:55	70	0	328.125
392	120	56	2025-11-27 17:07:13	2025-11-27 17:29:58	5	0	93.75
393	121	57	2025-11-27 08:15:00	2025-11-27 09:25:00	7	0	160.41667
394	121	56	2025-11-27 09:26:00	2025-11-27 11:45:03	25	0	312.5
395	121	54	2025-11-27 12:02:34	2025-11-27 12:19:32	10	0	31.25
396	121	56	2025-11-27 11:45:38	2025-11-27 13:13:55	17	1039	212.5
397	121	56	2025-11-27 13:14:15	2025-11-27 14:06:55	10	0	170.83333
398	121	900	2025-11-27 14:07:41	2025-11-27 15:11:38	1	0	199.84375
399	121	56	2025-11-27 15:11:45	2025-11-27 17:37:15	35	0	656.25
400	122	900	2025-11-27 08:00:00	2025-11-27 11:32:35	1	0	442.88196
401	122	49	2025-11-27 11:33:00	2025-11-27 12:42:31	20	0	233.33333
402	122	49	2025-11-27 13:14:45	2025-11-27 15:03:40	20	0	313.10764
403	122	92	2025-11-27 15:05:59	2025-11-27 17:19:03	20	600	375
404	122	91	2025-11-27 17:35:44	2025-11-27 17:44:46	2	0	25
405	123	60	2025-11-27 09:31:00	2025-11-27 12:38:56	128	0	311.1111
406	123	900	2025-11-27 12:40:21	2025-11-27 13:17:47	100	0	77.986115
407	123	99	2025-11-27 13:19:01	2025-11-27 14:40:24	130	0	153.47223
408	123	60	2025-11-27 14:41:16	2025-11-27 15:37:40	64	0	155.55556
409	123	900	2025-11-27 15:37:55	2025-11-27 17:52:16	20	0	393.90625
410	124	64	2025-11-27 08:00:00	2025-11-27 17:55:04	110	78	1790.625
411	125	57	2025-11-27 09:05:00	2025-11-27 09:20:00	2	0	45.833332
412	125	56	2025-11-27 09:30:00	2025-11-27 10:40:00	20	0	250
413	125	53	2025-11-27 11:29:57	2025-11-27 12:34:19	300	0	187.5
414	125	900	2025-11-27 14:42:28	2025-11-27 15:20:05	1	0	78.36806
415	125	54	2025-11-27 12:34:33	2025-11-27 17:36:54	300	2284	1312.1007
416	125	56	2025-11-27 17:38:32	2025-11-27 17:45:13	1	0	18.75
417	126	101	2025-11-27 09:00:00	2025-11-27 17:31:41	1	0	1224.0104
418	127	101	2025-11-27 08:40:00	2025-11-27 17:57:46	1	1302	1456.2333
419	128	900	2025-11-27 09:02:00	2025-11-27 13:13:11	1	4	523.1597
420	128	900	2025-11-27 13:13:56	2025-11-27 13:47:24	1	0	69.72222
421	128	900	2025-11-27 13:47:34	2025-11-27 17:58:24	1	2	705.191
422	129	900	2025-11-27 09:00:00	2025-11-27 11:31:26	1	0	378.58334
423	129	96	2025-11-27 11:32:07	2025-11-27 12:39:11	39	0	225.875
424	129	61	2025-11-27 12:39:24	2025-11-27 16:01:23	50	0	730.3542
425	129	900	2025-11-27 16:02:27	2025-11-27 18:01:46	20	0	447.4375
426	130	57	2025-11-27 11:27:55	2025-11-27 11:28:06	5	0	114.583336
427	130	56	2025-11-27 11:28:22	2025-11-27 11:28:26	10	0	125
428	130	53	2025-11-27 11:29:04	2025-11-27 12:14:33	200	0	125
429	130	54	2025-11-27 12:14:49	2025-11-27 15:26:25	200	0	744.7917
430	130	57	2025-11-27 16:06:51	2025-11-27 16:22:27	2	0	68.75
431	130	57	2025-11-27 16:59:50	2025-11-27 17:39:42	3	0	103.125
432	130	56	2025-11-27 15:26:46	2025-11-27 18:01:47	25	3348	468.75
433	131	901	2025-11-27 08:30:00	2025-11-27 18:01:09	1	0	1409.8438
434	132	900	2025-11-27 09:00:00	2025-11-27 11:28:07	1	0	308.5764
435	132	63	2025-11-27 11:29:15	2025-11-27 12:32:48	25	0	157.98611
436	132	96	2025-11-27 12:33:28	2025-11-27 13:30:22	30	0	144.79167
437	132	61	2025-11-27 13:31:07	2025-11-27 16:29:00	50	0	662.44794
438	132	900	2025-11-27 16:29:21	2025-11-27 18:02:40	1	0	291.6146
439	133	79	2025-11-27 09:10:00	2025-11-27 11:29:07	100	0	319.44446
440	133	80	2025-11-27 11:29:28	2025-11-27 12:10:57	100	0	138.88889
441	133	79	2025-11-27 12:15:19	2025-11-27 14:09:29	100	0	333.33334
442	133	80	2025-11-27 14:10:09	2025-11-27 15:15:49	100	0	208.33333
443	133	79	2025-11-27 15:30:49	2025-11-27 16:57:12	100	0	479.16666
444	133	80	2025-11-27 16:57:35	2025-11-27 18:02:36	100	0	208.33333
445	134	101	2025-11-27 08:48:00	2025-11-27 18:04:48	1	0	1528.8
446	135	900	2025-11-27 09:00:00	2025-11-27 11:28:04	1	0	308.47223
447	135	900	2025-11-27 11:28:52	2025-11-27 13:13:07	1	0	217.1875
448	135	900	2025-11-27 13:13:23	2025-11-27 14:05:44	1	0	109.0625
449	135	900	2025-11-27 14:29:31	2025-11-27 15:40:42	1	0	164.80902
450	135	900	2025-11-27 15:41:04	2025-11-27 18:08:46	1	0	461.5625
451	136	900	2025-11-27 08:00:00	2025-11-27 12:00:40	1	0	501.3889
452	136	51	2025-11-27 12:00:53	2025-11-27 13:19:13	80	0	127.77778
453	136	50	2025-11-27 13:19:44	2025-11-27 15:00:27	50	0	199.65277
454	136	50	2025-11-27 15:20:36	2025-11-27 16:08:37	30	0	119.791664
455	136	48	2025-11-27 16:09:42	2025-11-27 17:03:08	12	0	154.16667
456	136	50	2025-11-27 17:03:48	2025-11-27 17:24:25	10	0	39.930557
457	136	48	2025-11-27 17:24:50	2025-11-27 18:07:59	12	0	210.88542
458	137	67	2025-11-27 12:12:42	2025-11-27 12:13:01	20	0	97.22222
459	137	105	2025-11-27 12:14:26	2025-11-27 12:14:42	3	0	118.75
460	137	105	2025-11-27 12:20:16	2025-11-27 12:20:22	1	0	39.583332
461	137	67	2025-11-27 12:23:13	2025-11-27 12:36:35	5	0	24.305555
462	137	43	2025-11-27 12:47:56	2025-11-27 12:47:59	0	0	0
463	137	105	2025-11-27 12:36:58	2025-11-27 12:57:26	1	120	39.583332
464	137	67	2025-11-27 13:03:51	2025-11-27 13:15:51	5	0	24.305555
465	137	105	2025-11-27 13:17:24	2025-11-27 13:33:22	5	0	197.91667
466	137	105	2025-11-27 14:42:30	2025-11-27 15:28:48	3	0	118.75
467	137	67	2025-11-27 15:37:05	2025-11-27 15:49:16	5	0	24.305555
468	137	105	2025-11-27 15:49:31	2025-11-27 16:12:39	1	0	39.583332
469	137	67	2025-11-27 16:19:37	2025-11-27 16:31:48	5	0	24.305555
470	137	105	2025-11-27 16:32:06	2025-11-27 17:05:33	1	0	58.680557
471	137	67	2025-11-27 17:06:05	2025-11-27 17:16:40	5	0	36.458332
472	137	105	2025-11-27 17:19:30	2025-11-27 17:38:08	1	0	59.375
473	137	67	2025-11-27 17:39:43	2025-11-27 17:50:34	5	0	36.458332
474	137	105	2025-11-27 17:50:49	2025-11-27 18:11:37	1	0	59.375
475	138	109	2025-11-27 17:55:10	2025-11-27 18:14:06	1	0	9.027778
476	139	900	2025-11-27 08:50:00	2025-11-27 09:20:00	1	0	62.5
477	139	75	2025-11-27 09:20:00	2025-11-27 10:40:00	60	0	233.33333
478	139	77	2025-11-27 10:40:00	2025-11-27 11:06:00	60	0	83.333336
479	139	94	2025-11-27 11:06:00	2025-11-27 11:39:07	20	0	37.5
480	139	93	2025-11-27 11:39:36	2025-11-27 12:17:44	20	0	77.77778
481	139	95	2025-11-27 12:18:15	2025-11-27 13:21:49	20	0	142.36111
482	139	76	2025-11-27 13:21:56	2025-11-27 13:33:01	20	0	36.805557
483	139	900	2025-11-27 13:34:57	2025-11-27 14:00:38	1	0	53.506943
484	139	94	2025-11-27 14:19:43	2025-11-27 14:54:08	40	0	101.05903
485	139	900	2025-11-27 15:01:01	2025-11-27 15:05:17	1	0	13.333333
486	139	93	2025-11-27 14:54:27	2025-11-27 16:12:02	40	284	233.33333
487	139	95	2025-11-27 16:12:59	2025-11-27 17:50:39	40	1173	427.08334
488	139	76	2025-11-27 17:50:55	2025-11-27 18:13:22	40	0	73.611115
489	140	94	2025-11-27 11:27:58	2025-11-27 11:29:02	20	0	37.5
493	140	94	2025-11-27 11:39:54	2025-11-27 12:01:28	20	0	37.5
1225	278	900	2025-12-01 09:41:46	2025-12-01 12:24:07	1	0	338.22916
503	141	900	2025-11-27 09:00:00	2025-11-27 13:13:13	1	0	527.5347
504	141	900	2025-11-27 13:14:15	2025-11-27 13:49:32	1	0	73.50694
505	141	900	2025-11-27 13:49:52	2025-11-27 18:16:59	1	0	594.98267
506	142	111	2025-11-27 16:10:05	2025-11-27 16:10:09	1	0	7.2916665
507	143	900	2025-11-27 09:00:00	2025-11-27 13:15:46	1	0	532.8472
508	143	900	2025-11-27 13:16:57	2025-11-27 18:19:12	1	0	835.95483
509	144	901	2025-11-27 08:05:00	2025-11-27 18:21:44	50	880	1506.4584
510	145	900	2025-11-27 07:21:00	2025-11-27 11:27:57	1	0	514.4792
511	145	49	2025-11-27 11:28:32	2025-11-27 15:23:20	50	0	757.23956
512	145	49	2025-11-27 15:23:50	2025-11-27 16:15:31	10	0	175
513	145	92	2025-11-27 16:15:53	2025-11-27 17:13:23	10	0	187.5
514	145	92	2025-11-27 17:13:57	2025-11-27 17:49:56	10	0	187.5
515	145	48	2025-11-27 17:50:47	2025-11-27 18:22:47	6	0	115.625
516	146	900	2025-11-27 09:24:00	2025-11-27 18:22:44	1	0	1570.25
517	146	900	2025-11-27 18:23:22	2025-11-27 18:23:24	1	0	0.125
518	147	57	2025-11-27 11:28:27	2025-11-27 11:28:37	3	0	68.75
519	147	56	2025-11-27 11:29:07	2025-11-27 12:18:48	30	0	375
520	147	54	2025-11-27 12:23:06	2025-11-27 12:53:37	20	0	62.5
521	147	56	2025-11-27 12:19:09	2025-11-27 13:40:05	12	1860	150
522	147	56	2025-11-27 14:24:06	2025-11-27 14:34:40	10	0	140.625
523	147	56	2025-11-27 16:01:46	2025-11-27 16:26:07	20	0	375
524	147	57	2025-11-27 16:26:12	2025-11-27 16:31:35	3	0	103.125
525	147	56	2025-11-27 16:31:43	2025-11-27 17:06:19	10	0	187.5
526	147	57	2025-11-27 17:06:24	2025-11-27 17:16:52	2	0	68.75
527	147	56	2025-11-27 17:20:10	2025-11-27 17:50:38	10	0	187.5
528	147	56	2025-11-27 17:52:36	2025-11-27 18:26:03	10	0	187.5
529	148	900	2025-11-27 11:32:00	2025-11-27 18:27:45	55	0	924.21875
532	150	901	2025-11-27 08:50:00	2025-11-27 18:36:06	1	0	1456.5625
533	151	900	2025-11-27 08:35:00	2025-11-27 11:29:55	1	0	364.40973
534	151	900	2025-11-27 11:30:56	2025-11-27 13:26:28	1	0	240.69444
492	140	76	2025-11-27 11:31:34	2025-11-27 11:31:39	20	0	36.805557
531	149	900	2025-11-27 13:14:49	2025-11-27 18:31:50	1	0	848.0208
490	140	93	2025-11-27 11:29:16	2025-11-27 11:29:21	20	0	77.77778
491	140	95	2025-11-27 11:29:47	2025-11-27 11:29:51	20	0	142.36111
494	140	93	2025-11-27 12:01:42	2025-11-27 12:49:45	20	0	77.77778
495	140	95	2025-11-27 12:51:39	2025-11-27 13:57:09	20	0	142.36111
496	140	76	2025-11-27 13:57:51	2025-11-27 14:19:26	20	0	36.805557
497	140	75	2025-11-27 14:29:17	2025-11-27 15:03:52	20	0	77.77778
498	140	77	2025-11-27 15:03:59	2025-11-27 15:12:12	20	0	27.777779
500	140	93	2025-11-27 15:57:37	2025-11-27 16:37:11	20	0	107.638885
501	140	95	2025-11-27 16:37:22	2025-11-27 17:39:47	20	0	213.54167
502	140	76	2025-11-27 17:39:58	2025-11-27 18:02:43	20	0	55.208332
535	151	900	2025-11-27 13:26:52	2025-11-27 18:43:39	1	0	917.5
536	153	900	2025-11-27 09:10:00	2025-11-27 11:00:00	1	0	229.16667
537	153	50	2025-11-27 11:00:00	2025-11-27 12:44:23	60	0	239.58333
538	153	50	2025-11-27 12:57:56	2025-11-27 14:17:27	40	0	159.72223
539	153	50	2025-11-27 14:39:44	2025-11-27 15:37:00	32	0	130.90277
540	153	50	2025-11-27 15:37:22	2025-11-27 16:01:27	12	0	71.875
541	153	48	2025-11-27 16:08:12	2025-11-27 18:54:46	37	0	713.0208
542	154	83	2025-11-27 09:20:00	2025-11-27 12:30:07	30	0	209.375
543	154	900	2025-11-27 12:31:54	2025-11-27 13:13:59	1	0	87.673615
544	154	900	2025-11-27 13:14:28	2025-11-27 14:43:39	30	0	185.79861
545	154	900	2025-11-27 14:44:01	2025-11-27 19:00:23	60	0	667.56946
546	155	79	2025-11-27 08:30:00	2025-11-27 11:41:08	150	0	479.16666
547	155	80	2025-11-27 12:26:51	2025-11-27 13:31:34	150	0	208.33333
548	155	79	2025-11-27 13:31:46	2025-11-27 16:33:49	150	0	687.5
549	155	80	2025-11-27 16:34:02	2025-11-27 17:49:45	150	0	312.5
550	155	900	2025-11-27 11:42:33	2025-11-27 18:41:19	1	19417	297.34375
551	155	79	2025-11-27 18:43:24	2025-11-27 19:10:14	10	0	47.916668
552	155	80	2025-11-27 19:10:30	2025-11-27 19:28:51	10	0	20.833334
553	156	900	2025-11-25 12:00:00	2025-11-25 19:57:14	1	0	1116.3541
554	157	49	2025-11-27 07:05:00	2025-11-27 14:41:03	100	0	1375
555	157	92	2025-11-27 14:42:21	2025-11-27 19:51:04	60	0	1125
556	158	900	2025-11-27 06:55:00	2025-11-27 14:55:45	1	0	1127.3438
557	158	901	2025-11-27 14:56:20	2025-11-27 17:41:21	1	0	515.67706
558	158	901	2025-11-27 17:41:44	2025-11-27 18:23:16	1	0	129.79167
559	158	49	2025-11-27 18:23:31	2025-11-27 20:08:11	20	0	350
629	167	88	2025-11-28 09:24:12	2025-11-28 09:36:31	1	83	22.916666
630	167	88	2025-11-28 09:37:22	2025-11-28 09:56:47	3	0	68.75
530	149	900	2025-11-27 09:31:13	2025-11-27 13:14:36	1	20	464.6875
499	140	94	2025-11-27 15:37:32	2025-11-27 15:57:22	20	0	37.5
560	159	57	2025-11-28 07:42:24	2025-11-28 09:21:02	10	0	229.16667
561	159	57	2025-11-28 09:21:10	2025-11-28 11:07:49	12	0	275
562	159	57	2025-11-28 11:10:00	2025-11-28 13:19:28	12	0	309.25348
563	159	57	2025-11-28 13:20:08	2025-11-28 14:23:39	6	0	206.25
564	159	54	2025-11-28 14:50:48	2025-11-28 15:35:48	40	0	187.5
565	159	56	2025-11-28 14:27:01	2025-11-28 16:31:30	15	2716	281.25
566	159	57	2025-11-28 16:31:47	2025-11-28 17:06:04	4	0	137.5
567	160	75	2025-11-28 08:27:26	2025-11-28 08:48:43	20	0	77.77778
568	160	77	2025-11-28 08:48:55	2025-11-28 08:53:27	20	0	27.777779
569	160	900	2025-11-28 08:56:12	2025-11-28 09:31:15	1	0	73.020836
570	160	110	2025-11-28 09:31:38	2025-11-28 10:20:49	20	0	145.83333
571	160	110	2025-11-28 10:25:04	2025-11-28 11:05:58	20	0	145.83333
572	160	110	2025-11-28 11:13:53	2025-11-28 11:47:54	20	0	145.83333
573	160	110	2025-11-28 11:52:53	2025-11-28 12:47:32	20	2710	173.57639
574	160	110	2025-11-28 13:18:17	2025-11-28 13:57:50	20	0	218.75
575	160	75	2025-11-28 13:58:01	2025-11-28 14:07:18	10	0	58.333332
576	160	77	2025-11-28 14:07:25	2025-11-28 14:09:43	10	0	20.833334
577	160	71	2025-11-28 14:14:35	2025-11-28 14:31:50	50	0	78.125
578	160	72	2025-11-28 14:46:23	2025-11-28 14:56:10	50	0	26.041666
579	160	73	2025-11-28 14:56:21	2025-11-28 15:01:12	50	0	39.0625
580	160	84	2025-11-28 15:05:08	2025-11-28 15:29:49	20	0	114.583336
581	160	111	2025-11-28 15:31:11	2025-11-28 15:35:50	20	0	26.041666
582	160	112	2025-11-28 15:36:06	2025-11-28 15:47:03	20	0	61.458332
583	160	102	2025-11-28 15:47:42	2025-11-28 17:01:59	20	0	334.375
584	160	113	2025-11-28 17:02:10	2025-11-28 17:10:43	20	0	52.083332
585	161	75	2025-11-28 08:29:12	2025-11-28 09:05:55	20	0	77.77778
586	161	77	2025-11-28 09:06:05	2025-11-28 09:17:11	20	0	27.777779
587	161	71	2025-11-28 09:18:50	2025-11-28 09:40:25	21	0	21.875
588	161	72	2025-11-28 09:40:50	2025-11-28 09:48:13	21	0	7.2916665
589	161	73	2025-11-28 09:48:24	2025-11-28 09:51:16	19	0	9.895833
590	161	110	2025-11-28 10:01:58	2025-11-28 11:16:50	20	0	145.83333
591	161	110	2025-11-28 11:20:33	2025-11-28 13:00:47	20	2172	145.83333
592	161	75	2025-11-28 13:14:25	2025-11-28 13:47:04	20	0	77.77778
593	161	77	2025-11-28 13:47:12	2025-11-28 13:56:40	20	0	27.777779
594	161	71	2025-11-28 14:06:09	2025-11-28 14:31:04	50	0	52.083332
595	161	72	2025-11-28 14:37:44	2025-11-28 14:45:54	50	0	17.36111
596	161	73	2025-11-28 14:46:04	2025-11-28 14:52:08	50	0	26.041666
597	161	111	2025-11-28 15:04:11	2025-11-28 15:11:03	20	0	17.36111
598	161	112	2025-11-28 15:11:38	2025-11-28 15:36:38	20	0	47.395832
599	161	84	2025-11-28 15:39:54	2025-11-28 16:30:22	20	0	114.583336
600	161	113	2025-11-28 16:30:54	2025-11-28 17:13:25	20	0	52.083332
601	162	13	2025-11-28 08:38:51	2025-11-28 09:40:03	800	0	0
602	162	53	2025-11-28 09:40:11	2025-11-28 13:29:14	800	2153	500
603	162	54	2025-11-28 13:29:27	2025-11-28 17:32:37	260	0	1131.007
604	163	57	2025-11-28 09:14:55	2025-11-28 09:54:08	5	0	114.583336
605	163	57	2025-11-28 10:05:17	2025-11-28 10:47:54	5	0	114.583336
606	163	57	2025-11-28 11:03:48	2025-11-28 11:45:56	5	0	114.583336
607	163	57	2025-11-28 11:46:47	2025-11-28 14:03:54	5	5897	114.583336
608	163	56	2025-11-28 14:23:52	2025-11-28 14:55:26	10	0	142.79514
609	163	56	2025-11-28 15:10:22	2025-11-28 15:40:16	10	0	187.5
610	163	56	2025-11-28 15:40:56	2025-11-28 16:20:17	10	0	187.5
611	163	56	2025-11-28 16:29:38	2025-11-28 17:01:15	10	0	187.5
612	163	56	2025-11-28 17:04:40	2025-11-28 17:39:35	10	0	187.5
613	164	109	2025-11-28 09:34:43	2025-11-28 17:41:08	100	1748	1009.35767
614	165	900	2025-11-28 08:55:14	2025-11-28 09:30:31	1	0	73.50694
615	165	110	2025-11-28 09:31:02	2025-11-28 13:18:59	60	2246	437.5
616	165	75	2025-11-28 13:45:08	2025-11-28 14:35:36	40	0	155.55556
617	165	77	2025-11-28 14:35:41	2025-11-28 14:55:09	30	0	41.666668
618	165	84	2025-11-28 14:56:24	2025-11-28 15:25:30	20	0	114.583336
619	165	102	2025-11-28 15:27:15	2025-11-28 17:12:39	20	0	334.375
620	165	112	2025-11-28 17:13:25	2025-11-28 17:24:42	20	0	61.458332
621	165	111	2025-11-28 17:25:07	2025-11-28 17:28:45	20	0	26.041666
622	165	113	2025-11-28 17:29:07	2025-11-28 17:41:05	20	0	52.083332
623	166	88	2025-11-28 08:52:29	2025-11-28 10:15:00	10	0	229.16667
624	166	88	2025-11-28 10:23:49	2025-11-28 13:08:51	16	1942	366.66666
625	166	83	2025-11-28 17:30:36	2025-11-28 17:53:56	10	0	69.791664
626	166	88	2025-11-28 13:28:14	2025-11-28 17:54:01	24	2813	816.40625
627	167	88	2025-11-28 08:14:38	2025-11-28 09:04:07	5	0	114.583336
628	167	900	2025-11-28 09:05:46	2025-11-28 09:24:07	1	0	38.229168
631	167	88	2025-11-28 10:02:27	2025-11-28 10:19:25	2	0	45.833332
632	167	88	2025-11-28 10:30:21	2025-11-28 10:55:54	3	0	68.75
633	167	88	2025-11-28 10:58:26	2025-11-28 11:51:00	5	0	114.583336
634	167	900	2025-11-28 11:55:55	2025-11-28 11:57:03	1	0	2.3611112
635	167	88	2025-11-28 11:58:28	2025-11-28 13:26:52	5	2046	114.583336
636	167	88	2025-11-28 13:50:08	2025-11-28 14:19:31	3	0	68.75
637	167	88	2025-11-28 14:29:06	2025-11-28 14:52:32	2	0	57.413193
638	167	88	2025-11-28 15:08:54	2025-11-28 15:31:33	3	0	103.125
639	167	88	2025-11-28 15:33:56	2025-11-28 16:21:36	5	0	171.875
640	167	88	2025-11-28 16:30:51	2025-11-28 17:16:22	5	0	171.875
641	167	88	2025-11-28 17:18:38	2025-11-28 17:44:59	3	0	103.125
642	168	900	2025-11-28 08:47:33	2025-11-28 09:49:09	1150	0	128.33333
643	168	75	2025-11-28 09:49:18	2025-11-28 10:20:08	20	0	77.77778
644	168	77	2025-11-28 10:20:16	2025-11-28 10:28:04	20	0	27.777779
645	168	110	2025-11-28 10:28:51	2025-11-28 11:42:57	20	69	145.83333
646	168	110	2025-11-28 11:43:25	2025-11-28 12:53:37	20	1919	145.83333
647	168	75	2025-11-28 13:20:16	2025-11-28 13:49:02	20	0	77.77778
648	168	77	2025-11-28 13:54:41	2025-11-28 14:03:54	20	0	27.777779
649	168	71	2025-11-28 14:04:19	2025-11-28 14:26:39	50	0	52.083332
650	168	72	2025-11-28 14:26:51	2025-11-28 14:35:24	50	0	25.868055
651	168	73	2025-11-28 14:36:03	2025-11-28 14:43:37	50	0	39.0625
652	168	111	2025-11-28 14:45:03	2025-11-28 14:55:57	20	211	26.041666
653	168	112	2025-11-28 14:56:07	2025-11-28 15:18:56	20	81	61.458332
654	168	84	2025-11-28 15:22:38	2025-11-28 15:52:28	20	0	114.583336
655	168	102	2025-11-28 15:52:54	2025-11-28 17:16:07	20	0	334.375
656	168	113	2025-11-28 17:16:19	2025-11-28 17:31:34	20	0	52.083332
657	170	56	2025-11-28 08:24:34	2025-11-28 09:13:36	10	0	125
658	170	57	2025-11-28 09:13:48	2025-11-28 10:25:28	10	0	229.16667
659	170	57	2025-11-28 10:25:47	2025-11-28 11:48:44	7	0	160.41667
660	170	56	2025-11-28 12:24:04	2025-11-28 13:11:04	10	0	125
661	170	57	2025-11-28 11:48:54	2025-11-28 14:03:01	6	4133	173.40277
662	170	56	2025-11-28 14:03:10	2025-11-28 15:15:28	15	0	281.25
663	170	57	2025-11-28 15:46:49	2025-11-28 16:20:35	4	0	137.5
664	170	56	2025-11-28 15:15:35	2025-11-28 17:05:38	10	2047	125
665	170	57	2025-11-28 17:08:07	2025-11-28 17:24:41	4	0	137.5
666	170	56	2025-11-28 17:24:48	2025-11-28 17:58:28	10	0	187.5
667	171	88	2025-11-28 08:32:14	2025-11-28 09:15:51	4	0	91.666664
668	171	900	2025-11-28 09:16:11	2025-11-28 09:26:32	1	0	21.5625
669	171	88	2025-11-28 09:26:52	2025-11-28 10:08:37	4	0	91.666664
670	171	88	2025-11-28 10:09:26	2025-11-28 11:04:44	5	0	114.583336
671	171	88	2025-11-28 11:05:29	2025-11-28 11:10:22	1	0	22.916666
672	171	900	2025-11-28 11:11:26	2025-11-28 11:11:50	1	0	0.8333333
673	171	88	2025-11-28 11:12:11	2025-11-28 13:18:18	8	1913	183.33333
674	171	88	2025-11-28 13:43:49	2025-11-28 17:53:39	24	0	746.40625
675	172	79	2025-11-28 09:38:01	2025-11-28 13:24:58	200	1913	638.8889
676	172	900	2025-11-28 13:43:50	2025-11-28 17:57:06	400	336	751.57983
677	173	88	2025-11-28 09:02:01	2025-11-28 11:54:55	17	0	389.58334
678	173	88	2025-11-28 11:58:01	2025-11-28 13:52:16	8	2189	183.33333
679	173	88	2025-11-28 14:05:03	2025-11-28 16:47:37	19	0	602.55206
680	173	88	2025-11-28 16:47:54	2025-11-28 17:59:13	8	0	275
681	174	67	2025-11-28 09:03:19	2025-11-28 09:16:32	5	0	24.305555
682	174	105	2025-11-28 09:16:58	2025-11-28 09:37:04	1	0	39.583332
683	174	67	2025-11-28 09:39:26	2025-11-28 09:48:45	5	0	24.305555
684	174	105	2025-11-28 09:49:49	2025-11-28 10:05:10	1	0	39.583332
685	174	67	2025-11-28 10:08:04	2025-11-28 10:17:14	5	0	24.305555
686	174	105	2025-11-28 10:21:08	2025-11-28 10:36:59	1	0	39.583332
687	174	67	2025-11-28 10:41:08	2025-11-28 10:50:17	5	0	24.305555
688	174	105	2025-11-28 10:51:39	2025-11-28 11:07:34	1	0	39.583332
689	174	67	2025-11-28 11:16:37	2025-11-28 11:23:44	5	0	24.305555
690	174	105	2025-11-28 11:25:04	2025-11-28 11:46:42	1	0	39.583332
691	174	67	2025-11-28 11:48:12	2025-11-28 11:58:35	5	0	24.305555
692	174	105	2025-11-28 12:00:59	2025-11-28 12:47:11	1	1870	39.583332
693	174	67	2025-11-28 12:58:05	2025-11-28 13:08:25	5	0	24.305555
694	174	105	2025-11-28 13:10:15	2025-11-28 13:25:58	1	0	39.583332
695	174	67	2025-11-28 13:27:12	2025-11-28 13:38:08	5	0	24.305555
696	174	67	2025-11-28 13:44:32	2025-11-28 13:46:09	1	0	4.861111
697	174	105	2025-11-28 13:47:00	2025-11-28 13:59:26	1	0	39.583332
698	174	105	2025-11-28 14:02:43	2025-11-28 14:14:54	1	0	39.583332
699	174	67	2025-11-28 14:51:38	2025-11-28 14:55:39	2	0	9.722222
700	174	105	2025-11-28 14:57:14	2025-11-28 17:46:06	11	0	435.41666
701	175	900	2025-11-28 08:52:03	2025-11-28 10:09:48	1	0	194.375
702	175	61	2025-11-28 10:10:01	2025-11-28 13:42:00	51	1409	597.125
703	175	96	2025-11-28 13:42:16	2025-11-28 17:59:28	90	0	756.9167
704	176	50	2025-11-28 08:05:41	2025-11-28 08:18:53	10	0	39.930557
705	176	48	2025-11-28 08:19:10	2025-11-28 15:03:43	105	1614	1696.3716
706	176	50	2025-11-28 15:37:27	2025-11-28 15:49:48	10	0	59.895832
707	176	48	2025-11-28 15:50:06	2025-11-28 17:27:46	31	0	597.3958
708	176	51	2025-11-28 17:28:00	2025-11-28 18:01:55	24	0	57.5
709	177	900	2025-11-28 08:46:56	2025-11-28 10:39:48	1	0	235.13889
710	177	96	2025-11-28 10:39:55	2025-11-28 13:29:07	80	1148	386.1111
711	177	61	2025-11-28 13:29:17	2025-11-28 18:01:51	79	0	1111.6666
712	178	901	2025-11-28 08:40:42	2025-11-28 11:08:07	1	0	307.11804
713	178	57	2025-11-28 11:08:21	2025-11-28 11:32:27	3	0	68.75
714	178	56	2025-11-28 11:32:43	2025-11-28 12:01:41	6	0	75
715	178	901	2025-11-28 12:01:58	2025-11-28 13:45:40	1	0	216.04167
716	178	56	2025-11-28 13:45:46	2025-11-28 14:01:52	4	0	50
717	178	901	2025-11-28 14:02:04	2025-11-28 18:02:20	1	0	734.2882
718	179	101	2025-11-28 09:05:46	2025-11-28 18:03:29	1	3819	1106.4584
719	179	101	2025-11-28 18:03:51	2025-11-28 18:03:54	1	0	0.15625
720	180	57	2025-11-28 08:48:48	2025-11-28 09:33:23	6	0	137.5
721	180	57	2025-11-28 09:33:31	2025-11-28 10:42:03	12	0	275
722	180	57	2025-11-28 10:42:50	2025-11-28 12:50:36	12	2372	284.87848
723	180	57	2025-11-28 12:50:57	2025-11-28 14:07:41	10	0	343.75
724	180	56	2025-11-28 14:07:50	2025-11-28 15:15:40	15	0	281.25
725	180	57	2025-11-28 15:15:45	2025-11-28 15:29:24	2	0	68.75
726	180	56	2025-11-28 15:29:32	2025-11-28 15:46:14	5	0	93.75
727	180	57	2025-11-28 15:46:20	2025-11-28 16:05:02	3	0	103.125
728	180	57	2025-11-28 16:24:35	2025-11-28 16:53:28	5	0	171.875
729	180	56	2025-11-28 16:53:38	2025-11-28 17:14:33	5	0	93.75
730	180	57	2025-11-28 17:14:38	2025-11-28 17:45:38	5	0	171.875
731	180	56	2025-11-28 17:45:42	2025-11-28 18:04:34	5	0	93.75
732	181	52	2025-11-28 07:21:43	2025-11-28 14:00:30	125	2087	1082.8646
733	181	51	2025-11-28 14:00:44	2025-11-28 16:00:33	208	0	498.33334
734	181	52	2025-11-28 16:00:51	2025-11-28 18:02:02	45	0	515.625
735	182	98	2025-11-28 10:34:15	2025-11-28 11:13:00	16	0	140
736	182	900	2025-11-28 10:18:48	2025-11-28 11:56:10	1	4779	44.291668
737	182	900	2025-11-28 11:20:00	2025-11-28 12:00:01	1	0	100.041664
738	182	98	2025-11-28 12:20:00	2025-11-28 13:26:20	15	1146	131.25
739	182	98	2025-11-28 13:51:15	2025-11-28 14:26:16	12	0	105
740	182	98	2025-11-28 14:39:46	2025-11-28 15:23:01	13	0	113.75
741	182	98	2025-11-28 15:24:04	2025-11-28 16:17:48	14	0	122.5
742	182	98	2025-11-28 16:35:18	2025-11-28 17:48:24	20	0	212.20833
743	182	900	2025-11-28 13:28:08	2025-11-28 17:48:37	1	13365	141.5
744	183	101	2025-11-28 10:38:28	2025-11-28 18:07:06	1	0	1150.2167
745	184	101	2025-11-28 08:23:29	2025-11-28 08:23:31	1	0	0.07777778
746	184	101	2025-11-28 08:23:47	2025-11-28 18:08:51	1	1934	1552.5222
747	185	56	2025-11-28 08:06:54	2025-11-28 09:26:22	20	0	250
748	185	57	2025-11-28 09:26:27	2025-11-28 10:41:46	10	0	229.16667
749	185	56	2025-11-28 10:41:57	2025-11-28 11:13:53	10	0	125
750	185	57	2025-11-28 11:14:01	2025-11-28 13:08:27	10	3956	306.94446
751	185	57	2025-11-28 13:08:48	2025-11-28 14:13:27	8	0	275
752	185	54	2025-11-28 15:09:01	2025-11-28 15:49:00	50	0	234.375
753	185	57	2025-11-28 15:49:14	2025-11-28 16:30:55	5	0	171.875
754	185	56	2025-11-28 14:13:58	2025-11-28 18:08:51	45	4941	843.75
755	186	57	2025-11-28 08:16:32	2025-11-28 11:43:21	23	0	527.0833
756	186	56	2025-11-28 11:43:32	2025-11-28 12:44:19	5	2090	62.5
757	186	57	2025-11-28 12:44:25	2025-11-28 13:04:12	4	0	93.541664
758	186	56	2025-11-28 13:04:21	2025-11-28 13:19:50	3	0	56.25
759	186	57	2025-11-28 13:19:56	2025-11-28 14:33:43	7	0	240.625
760	186	56	2025-11-28 14:36:10	2025-11-28 15:11:32	6	0	112.5
761	186	57	2025-11-28 15:11:39	2025-11-28 15:25:37	2	0	68.75
762	186	56	2025-11-28 15:25:44	2025-11-28 15:47:53	5	0	93.75
763	186	57	2025-11-28 15:47:59	2025-11-28 16:34:24	5	0	114.583336
764	186	56	2025-11-28 16:35:18	2025-11-28 16:50:59	5	0	93.75
765	186	57	2025-11-28 16:51:28	2025-11-28 17:32:03	4	0	137.5
766	186	56	2025-11-28 17:33:17	2025-11-28 18:09:16	5	0	93.75
767	187	92	2025-11-28 07:41:50	2025-11-28 12:39:33	50	0	625
768	187	92	2025-11-28 12:39:53	2025-11-28 13:46:00	10	0	125
769	187	50	2025-11-28 13:46:39	2025-11-28 14:22:09	30	0	179.6875
770	187	92	2025-11-28 14:22:30	2025-11-28 15:22:43	10	0	187.5
771	187	92	2025-11-28 15:42:08	2025-11-28 16:38:50	10	0	187.5
772	187	50	2025-11-28 16:39:06	2025-11-28 16:53:18	15	0	89.84375
773	187	92	2025-11-28 16:53:31	2025-11-28 17:52:05	15	0	281.25
774	187	92	2025-11-28 17:52:21	2025-11-28 18:09:48	5	0	93.75
775	188	88	2025-11-28 08:50:22	2025-11-28 09:23:26	5	0	114.583336
776	188	900	2025-11-28 09:25:28	2025-11-28 09:29:55	1	0	9.270833
777	188	50	2025-11-28 09:41:56	2025-11-28 11:34:55	53	0	211.63194
778	188	900	2025-11-28 09:30:07	2025-11-28 11:50:37	1	7041	48.229168
779	188	88	2025-11-28 11:51:01	2025-11-28 13:23:30	10	1012	229.16667
780	188	900	2025-11-28 13:26:07	2025-11-28 14:13:54	1	0	99.548615
781	188	88	2025-11-28 14:14:00	2025-11-28 14:58:57	7	0	239.34027
782	188	88	2025-11-28 15:03:02	2025-11-28 15:51:43	7	0	160.41667
783	188	88	2025-11-28 17:03:20	2025-11-28 17:25:17	3	0	103.125
784	188	88	2025-11-28 17:46:17	2025-11-28 18:09:18	3	0	103.125
785	188	900	2025-11-28 15:55:59	2025-11-28 18:13:50	1	2722	289.0104
786	189	88	2025-11-28 08:24:05	2025-11-28 08:48:45	3	0	68.75
787	189	88	2025-11-28 14:01:17	2025-11-28 15:48:50	12	0	275
788	189	901	2025-11-28 08:04:45	2025-11-28 18:14:29	1	10922	1163.8541
789	190	75	2025-11-28 07:58:37	2025-11-28 08:34:20	20	0	77.77778
790	190	77	2025-11-28 08:34:29	2025-11-28 08:44:44	20	0	27.777779
791	190	71	2025-11-28 08:47:07	2025-11-28 09:22:24	50	0	52.083332
792	190	72	2025-11-28 09:22:32	2025-11-28 09:30:43	50	0	17.36111
793	190	73	2025-11-28 09:30:51	2025-11-28 09:39:39	50	0	26.041666
794	190	110	2025-11-28 09:40:25	2025-11-28 13:29:06	60	2296	437.5
795	190	75	2025-11-28 13:29:34	2025-11-28 14:06:57	20	0	100.74653
796	190	77	2025-11-28 14:07:06	2025-11-28 14:16:55	20	0	41.666668
797	190	71	2025-11-28 14:17:11	2025-11-28 14:35:47	50	0	78.125
798	190	72	2025-11-28 14:36:01	2025-11-28 14:44:38	50	0	26.041666
799	190	73	2025-11-28 14:44:44	2025-11-28 14:57:30	50	0	39.0625
800	190	84	2025-11-28 14:57:53	2025-11-28 15:50:06	20	0	114.583336
801	190	102	2025-11-28 15:50:26	2025-11-28 17:28:21	20	0	334.375
802	190	111	2025-11-28 17:28:55	2025-11-28 17:40:36	20	0	26.041666
803	190	112	2025-11-28 17:40:55	2025-11-28 17:56:43	20	0	61.458332
804	190	113	2025-11-28 17:56:54	2025-11-28 18:14:45	20	0	52.083332
805	191	901	2025-11-28 10:37:45	2025-11-28 18:16:45	1	0	1059.375
806	192	901	2025-11-28 09:00:00	2025-11-28 18:17:07	1	0	1365.9896
807	193	57	2025-11-28 08:36:00	2025-11-28 11:58:03	23	0	527.0833
808	193	57	2025-11-28 12:36:33	2025-11-28 13:05:57	5	0	114.583336
809	193	57	2025-11-28 13:15:18	2025-11-28 13:55:05	6	0	187.55208
810	193	57	2025-11-28 15:10:08	2025-11-28 15:23:06	2	0	68.75
811	193	57	2025-11-28 15:47:25	2025-11-28 16:44:41	7	0	240.625
812	193	57	2025-11-28 16:49:32	2025-11-28 17:01:40	2	0	68.75
813	193	57	2025-11-28 17:14:26	2025-11-28 17:30:53	3	0	103.125
814	193	56	2025-11-28 11:58:13	2025-11-28 17:36:50	20	15052	375
815	193	57	2025-11-28 17:37:58	2025-11-28 18:14:11	2	1057	68.75
816	194	900	2025-11-28 09:05:33	2025-11-28 10:21:15	5	0	157.70833
817	194	88	2025-11-28 10:22:06	2025-11-28 10:40:58	2	0	45.833332
818	194	88	2025-11-28 10:45:19	2025-11-28 11:40:41	5	0	114.583336
819	194	88	2025-11-28 11:42:41	2025-11-28 13:12:23	5	2006	114.583336
820	194	88	2025-11-28 13:44:16	2025-11-28 14:52:02	5	479	114.583336
821	194	88	2025-11-28 14:55:04	2025-11-28 15:46:22	5	0	114.583336
822	194	88	2025-11-28 15:49:50	2025-11-28 16:22:30	3	0	92.673615
823	194	88	2025-11-28 16:28:35	2025-11-28 17:24:29	5	0	171.875
824	194	88	2025-11-28 17:25:27	2025-11-28 18:16:19	4	411	137.5
825	195	900	2025-11-28 09:07:46	2025-11-28 12:52:00	1	1920	400.4861
826	195	64	2025-11-28 12:54:57	2025-11-28 13:58:29	17	0	223.125
827	195	64	2025-11-28 13:59:23	2025-11-28 14:44:38	14	2	245.72917
828	195	64	2025-11-28 14:45:07	2025-11-28 15:14:21	7	0	137.8125
829	195	64	2025-11-28 15:14:58	2025-11-28 16:00:11	25	0	492.1875
830	195	64	2025-11-28 16:00:44	2025-11-28 16:27:44	5	0	98.4375
831	195	64	2025-11-28 16:27:56	2025-11-28 18:13:51	23	0	452.8125
832	196	900	2025-11-28 11:00:31	2025-11-28 11:40:37	1	0	83.541664
833	196	98	2025-11-28 11:40:49	2025-11-28 15:22:58	93	1739	714.13196
834	196	98	2025-11-28 16:20:16	2025-11-28 18:36:38	31	0	339.0625
835	197	98	2025-11-28 11:52:05	2025-11-28 15:23:13	93	1138	813.75
836	197	98	2025-11-28 16:20:51	2025-11-28 18:36:38	32	0	400.52084
837	197	900	2025-11-28 09:29:42	2025-11-28 18:36:48	1	22801	626.5625
838	198	52	2025-11-28 08:12:57	2025-11-28 09:03:01	15	0	114.583336
839	198	50	2025-11-28 09:03:00	2025-11-28 10:47:00	55	0	219.61806
840	198	48	2025-11-28 10:48:16	2025-11-28 18:20:09	76	458	1294.2361
841	198	50	2025-11-28 18:22:27	2025-11-28 18:43:51	15	0	89.84375
842	199	79	2025-11-28 09:06:32	2025-11-28 11:29:29	100	3	319.44446
843	199	70	2025-11-28 11:40:58	2025-11-28 11:49:59	100	0	13.888889
844	199	80	2025-11-28 11:39:35	2025-11-28 13:33:11	100	2570	138.88889
845	199	79	2025-11-28 14:01:00	2025-11-28 16:05:58	100	0	374.04514
846	199	80	2025-11-28 16:12:13	2025-11-28 17:37:38	100	0	208.33333
847	199	79	2025-11-28 17:58:39	2025-11-28 18:52:25	30	0	143.75
848	200	103	2025-11-28 08:20:59	2025-11-28 08:37:30	1	0	34.40972
849	200	88	2025-11-28 08:37:48	2025-11-28 09:08:32	2	0	45.833332
850	200	103	2025-11-28 09:12:27	2025-11-28 13:53:35	1	1802	523.125
851	200	88	2025-11-28 13:54:08	2025-11-28 14:40:19	5	0	129.79167
852	200	103	2025-11-28 14:40:30	2025-11-28 18:06:51	4	0	644.84375
853	200	88	2025-11-28 18:07:50	2025-11-28 18:45:25	4	0	137.5
854	200	103	2025-11-28 18:45:43	2025-11-28 18:53:55	1	136	18.541666
855	201	900	2025-11-28 09:02:13	2025-11-28 10:39:07	1	0	242.25
856	201	98	2025-11-28 10:39:17	2025-11-28 13:24:27	31	4183	271.25
857	201	98	2025-11-28 13:50:35	2025-11-28 14:26:52	12	0	105
858	201	98	2025-11-28 14:39:45	2025-11-28 15:23:39	13	0	113.75
859	201	98	2025-11-28 15:23:49	2025-11-28 16:17:34	14	0	122.5
860	201	98	2025-11-28 16:34:59	2025-11-28 17:48:19	20	10	259.27084
861	201	900	2025-11-28 11:13:42	2025-11-28 18:08:19	1	18255	413.875
862	202	79	2025-11-28 08:26:51	2025-11-28 13:09:10	200	4017	653.05554
863	202	80	2025-11-28 13:09:25	2025-11-28 15:04:06	200	0	416.66666
864	202	900	2025-11-28 15:05:01	2025-11-28 16:22:48	1	0	243.07292
865	202	70	2025-11-28 17:56:17	2025-11-28 17:58:28	100	0	20.833334
866	202	79	2025-11-28 16:30:56	2025-11-28 18:19:06	100	152	479.16666
867	202	80	2025-11-28 18:19:17	2025-11-28 19:07:57	100	0	208.33333
868	203	83	2025-11-28 09:29:10	2025-11-28 19:01:51	235	1975	2119.2188
869	203	900	2025-11-28 08:08:35	2025-11-28 19:08:24	30	34393	270.625
870	204	101	2025-11-28 08:07:00	2025-11-28 14:16:29	1	600	851.00555
871	204	902	2025-11-28 14:16:38	2025-11-28 16:15:17	1	0	420.812
872	204	101	2025-11-28 16:15:35	2025-11-28 19:06:16	1	0	485.5449
873	205	900	2025-11-28 09:26:00	2025-11-28 19:30:00	30	0	1512.5
874	206	900	2025-11-28 08:21:00	2025-11-28 11:10:00	20	196	345.27777
875	206	83	2025-11-28 11:10:00	2025-11-28 19:17:00	180	96	1512.0659
876	207	92	2025-11-28 07:20:58	2025-11-28 18:30:22	145	0	2343.75
877	207	50	2025-11-28 18:31:08	2025-11-28 19:45:20	40	0	239.58333
878	208	91	2025-11-28 07:12:54	2025-11-28 11:01:35	65	0	541.6667
879	208	902	2025-11-28 11:02:05	2025-11-28 11:45:20	1	0	136.95833
880	208	901	2025-11-28 14:57:28	2025-11-28 16:26:56	1	0	240.63194
881	208	91	2025-11-28 11:45:33	2025-11-28 16:27:16	40	1200	333.33334
882	208	51	2025-11-28 16:28:24	2025-11-28 17:09:16	36	0	86.25
883	208	91	2025-11-28 17:09:30	2025-11-28 18:39:41	24	0	200
884	208	51	2025-11-28 18:53:27	2025-11-28 19:00:24	11	0	26.354166
885	208	51	2025-11-28 19:02:34	2025-11-28 19:56:41	65	0	155.72917
886	210	57	2025-11-29 07:44:26	2025-11-29 09:42:16	12	0	275
887	210	56	2025-11-29 10:44:06	2025-11-29 11:14:56	8	0	100
888	210	57	2025-11-29 10:02:15	2025-11-29 11:57:26	12	1867	275
889	210	57	2025-11-29 11:57:47	2025-11-29 13:29:02	12	0	383.99304
890	210	57	2025-11-29 13:29:26	2025-11-29 15:49:15	14	0	481.25
891	211	54	2025-11-29 09:30:34	2025-11-29 16:10:22	310	0	1125.3125
892	212	57	2025-11-29 07:44:37	2025-11-29 09:33:15	9	0	206.25
893	212	57	2025-11-29 09:33:24	2025-11-29 10:34:20	8	0	183.33333
894	212	56	2025-11-29 10:34:37	2025-11-29 11:06:57	5	0	62.5
895	212	57	2025-11-29 11:07:06	2025-11-29 13:32:25	14	0	332.34375
896	212	57	2025-11-29 13:32:41	2025-11-29 14:22:42	6	0	206.25
897	212	57	2025-11-29 14:22:59	2025-11-29 16:39:07	13	0	446.875
898	213	64	2025-11-29 09:55:58	2025-11-29 11:16:25	27	0	354.375
899	213	64	2025-11-29 11:16:35	2025-11-29 17:08:52	83	0	1436.25
900	214	57	2025-11-29 09:05:00	2025-11-29 09:27:23	3	0	68.75
901	214	57	2025-11-29 09:43:01	2025-11-29 10:05:19	4	0	91.666664
902	214	56	2025-11-29 10:05:27	2025-11-29 10:24:14	5	0	62.5
903	214	57	2025-11-29 10:24:19	2025-11-29 11:04:23	4	0	91.666664
904	214	900	2025-11-29 11:10:50	2025-11-29 16:05:29	1	730	674.809
905	214	57	2025-11-29 16:05:42	2025-11-29 17:33:53	15	0	515.625
906	215	57	2025-11-29 09:23:23	2025-11-29 09:26:13	3	0	68.75
907	215	54	2025-11-29 09:26:38	2025-11-29 11:10:33	100	0	312.5
908	215	900	2025-11-29 11:10:58	2025-11-29 16:09:05	1	545	735.7465
909	215	57	2025-11-29 16:09:32	2025-11-29 17:39:16	13	0	446.875
910	216	46	2025-11-29 09:44:18	2025-11-29 10:00:57	20	0	20.13889
911	216	80	2025-11-29 10:01:47	2025-11-29 12:29:48	200	245	277.77777
912	216	46	2025-11-29 13:10:48	2025-11-29 13:38:09	40	0	40.27778
913	216	900	2025-11-29 13:43:58	2025-11-29 15:05:39	1	0	170.17361
914	216	109	2025-11-29 15:09:18	2025-11-29 17:33:21	43	268	461.4757
915	217	901	2025-11-29 08:26:46	2025-11-29 13:51:39	1	0	676.8403
916	217	57	2025-11-29 13:51:47	2025-11-29 17:26:34	21	0	685.29517
917	217	901	2025-11-29 17:27:03	2025-11-29 17:42:15	1	0	47.5
918	218	88	2025-11-29 09:27:52	2025-11-29 12:56:04	26	0	595.8333
919	218	88	2025-11-29 13:24:51	2025-11-29 14:15:10	5	0	123.125
920	218	88	2025-11-29 14:22:08	2025-11-29 15:04:27	5	0	171.875
921	218	88	2025-11-29 15:17:47	2025-11-29 17:28:23	14	0	481.25
922	219	50	2025-11-29 08:29:52	2025-11-29 09:22:36	16	1015	63.88889
923	219	92	2025-11-29 09:23:04	2025-11-29 13:00:29	30	0	375
924	219	92	2025-11-29 13:00:37	2025-11-29 14:51:58	20	0	250
925	219	48	2025-11-29 14:52:12	2025-11-29 16:21:01	30	0	547.56946
926	219	49	2025-11-29 16:21:24	2025-11-29 16:55:44	10	0	175
927	219	48	2025-11-29 16:56:00	2025-11-29 17:47:46	14	0	269.79166
928	220	60	2025-11-29 11:06:45	2025-11-29 13:07:36	128	0	311.1111
929	220	900	2025-11-29 13:38:25	2025-11-29 15:09:23	60	0	189.51389
930	220	109	2025-11-29 15:09:45	2025-11-29 17:48:14	42	0	444.0625
931	221	88	2025-11-29 08:50:07	2025-11-29 09:26:43	5	0	114.583336
932	221	88	2025-11-29 11:28:40	2025-11-29 11:59:48	5	0	114.583336
933	221	88	2025-11-29 12:08:50	2025-11-29 12:43:15	5	0	114.583336
934	221	900	2025-11-29 08:32:49	2025-11-29 12:43:20	1	6186	307.11804
935	221	88	2025-11-29 12:46:20	2025-11-29 13:25:33	5	0	122.30903
936	221	88	2025-11-29 14:00:30	2025-11-29 14:41:14	5	0	171.875
937	221	900	2025-11-29 15:11:42	2025-11-29 16:48:37	1	0	302.8646
938	221	88	2025-11-29 16:48:42	2025-11-29 17:23:11	4	0	137.5
939	222	900	2025-11-29 09:34:13	2025-11-29 09:46:32	1	0	25.659721
940	222	88	2025-11-29 09:46:42	2025-11-29 10:25:09	5	0	114.583336
941	222	900	2025-11-29 10:42:55	2025-11-29 11:14:10	1	0	65.104164
942	222	96	2025-11-29 11:14:29	2025-11-29 12:14:29	32	0	154.44444
943	222	900	2025-11-29 12:14:58	2025-11-29 14:37:54	1	0	297.77777
944	222	88	2025-11-29 14:38:01	2025-11-29 15:12:43	4	0	125.677086
945	222	900	2025-11-29 15:13:01	2025-11-29 17:51:47	1	0	496.14584
946	223	88	2025-11-29 10:45:41	2025-11-29 11:34:31	5	0	114.583336
947	223	88	2025-11-29 12:49:57	2025-11-29 13:50:35	5	0	114.583336
948	223	88	2025-11-29 13:51:20	2025-11-29 14:15:18	2	0	45.833332
949	223	88	2025-11-29 14:16:11	2025-11-29 14:47:58	3	0	68.75
950	223	88	2025-11-29 15:23:10	2025-11-29 16:11:46	4	1712	91.666664
951	223	88	2025-11-29 16:33:14	2025-11-29 17:27:08	5	0	114.583336
952	224	51	2025-11-29 07:38:38	2025-11-29 08:45:58	192	0	306.66666
953	224	52	2025-11-29 08:46:07	2025-11-29 11:43:15	65	426	563.0903
954	224	51	2025-11-29 11:43:29	2025-11-29 12:39:55	108	0	258.75
955	224	52	2025-11-29 12:40:07	2025-11-29 13:38:06	27	0	309.375
956	224	91	2025-11-29 13:38:56	2025-11-29 17:53:07	80	250	1000
957	225	88	2025-11-29 09:50:32	2025-11-29 12:36:58	13	178	297.91666
958	225	88	2025-11-29 12:37:10	2025-11-29 13:33:01	5	0	114.583336
959	225	88	2025-11-29 13:40:59	2025-11-29 13:47:49	1	0	22.916666
960	225	88	2025-11-29 14:16:28	2025-11-29 15:17:53	7	0	160.41667
961	225	88	2025-11-29 15:28:21	2025-11-29 17:31:54	11	0	301.04166
962	226	70	2025-11-29 09:03:29	2025-11-29 09:20:53	1000	0	138.88889
963	226	900	2025-11-29 09:21:27	2025-11-29 10:36:57	1	0	157.29167
964	226	60	2025-11-29 10:37:11	2025-11-29 12:23:49	64	0	155.55556
965	226	900	2025-11-29 13:51:56	2025-11-29 14:29:17	1	0	77.8125
966	226	109	2025-11-29 12:47:05	2025-11-29 17:29:53	46	4772	512.691
967	226	114	2025-11-29 12:27:13	2025-11-29 17:48:40	46	16983	107.8125
968	227	56	2025-11-29 09:36:50	2025-11-29 10:15:23	10	0	125
969	227	57	2025-11-29 10:15:30	2025-11-29 10:47:22	5	0	114.583336
970	227	900	2025-11-29 10:47:50	2025-11-29 15:08:59	1	11	591.7361
971	227	57	2025-11-29 15:09:11	2025-11-29 17:56:27	25	0	859.375
972	228	61	2025-11-29 08:49:39	2025-11-29 17:00:18	128	0	1498.3334
973	228	96	2025-11-29 17:00:36	2025-11-29 17:56:13	50	0	361.97916
974	229	96	2025-11-29 09:32:36	2025-11-29 12:25:57	99	0	573.375
975	229	61	2025-11-29 12:42:11	2025-11-29 17:56:37	80	152	1241.6875
976	230	88	2025-11-29 15:40:11	2025-11-29 17:01:00	10	0	229.16667
977	230	901	2025-11-29 09:42:08	2025-11-29 17:58:49	10	5543	1003.0208
978	231	900	2025-11-29 09:15:38	2025-11-29 13:14:41	20	0	498.02084
979	231	98	2025-11-29 13:15:01	2025-11-29 14:01:24	20	0	145.83333
980	231	900	2025-11-29 14:49:36	2025-11-29 14:49:44	0	0	0.2777778
981	231	98	2025-11-29 14:36:00	2025-11-29 16:53:08	46	0	450.19098
982	231	900	2025-11-29 16:54:10	2025-11-29 18:02:04	20	0	212.1875
983	232	900	2025-11-29 11:30:17	2025-11-29 13:14:31	1	0	260.58334
984	232	98	2025-11-29 13:14:37	2025-11-29 14:02:11	20	0	175
985	232	98	2025-11-29 14:36:39	2025-11-29 16:53:12	46	0	402.5
986	232	900	2025-11-29 16:54:16	2025-11-29 18:04:12	1	0	231.29167
987	233	51	2025-11-29 07:38:39	2025-11-29 08:27:55	48	0	76.666664
988	233	48	2025-11-29 08:28:07	2025-11-29 09:58:44	25	0	321.18054
989	233	50	2025-11-29 09:59:03	2025-11-29 10:18:27	10	0	39.930557
990	233	48	2025-11-29 10:18:41	2025-11-29 10:26:19	10	0	128.47223
991	233	48	2025-11-29 10:26:32	2025-11-29 14:38:54	80	0	1449.7916
992	233	48	2025-11-29 15:02:39	2025-11-29 16:20:24	24	0	462.5
993	233	51	2025-11-29 16:20:36	2025-11-29 18:07:20	100	0	239.58333
994	234	98	2025-11-29 13:52:09	2025-11-29 15:22:56	25	0	218.75
995	234	98	2025-11-29 15:43:09	2025-11-29 18:07:29	50	0	437.5
996	235	57	2025-11-29 08:26:51	2025-11-29 09:19:42	5	0	114.583336
997	235	56	2025-11-29 09:19:52	2025-11-29 10:02:35	10	0	125
998	235	57	2025-11-29 10:02:43	2025-11-29 10:55:50	5	0	114.583336
999	235	900	2025-11-29 10:56:43	2025-11-29 15:10:24	1	8	594.42706
1000	235	57	2025-11-29 15:10:34	2025-11-29 15:42:28	4	0	137.5
1001	235	57	2025-11-29 15:42:35	2025-11-29 17:08:07	10	0	343.75
1002	235	57	2025-11-29 17:08:17	2025-11-29 18:08:12	6	0	206.25
1003	236	901	2025-11-29 09:30:29	2025-11-29 12:31:39	1	0	377.43054
1004	236	98	2025-11-29 12:31:48	2025-11-29 13:34:14	27	0	196.875
1005	236	901	2025-11-29 13:34:53	2025-11-29 18:10:40	1	0	773.9757
1006	237	64	2025-11-29 08:55:48	2025-11-29 09:51:21	10	1196	131.25
1007	237	64	2025-11-29 09:55:30	2025-11-29 10:06:15	5	0	65.625
1008	237	64	2025-11-29 10:18:18	2025-11-29 12:03:04	4	3090	52.5
1009	237	64	2025-11-29 12:05:49	2025-11-29 12:09:35	2	0	26.25
1010	237	64	2025-11-29 12:41:04	2025-11-29 13:08:08	17	0	241.875
1011	237	64	2025-11-29 13:37:45	2025-11-29 14:06:24	5	0	65.625
1012	237	64	2025-11-29 14:41:09	2025-11-29 18:08:05	72	0	1042.5
1013	238	105	2025-11-29 09:46:03	2025-11-29 14:35:31	17	5668	672.9167
1014	238	67	2025-11-29 14:40:11	2025-11-29 14:47:56	4	0	25.815971
1015	238	105	2025-11-29 15:30:59	2025-11-29 18:09:30	10	520	593.75
1016	239	98	2025-11-29 10:18:24	2025-11-29 11:26:38	20	0	175
1017	239	98	2025-11-29 11:56:14	2025-11-29 18:16:48	104	1019	1050.9584
1018	239	900	2025-11-29 09:55:01	2025-11-29 18:16:57	1	26944	198.25
1019	240	83	2025-11-29 09:14:04	2025-11-29 18:18:20	197	0	1687.3438
1020	241	103	2025-11-29 10:10:35	2025-11-29 16:00:17	1	0	728.5417
1021	241	88	2025-11-29 16:00:38	2025-11-29 16:56:37	7	0	229.89583
1022	241	88	2025-11-29 16:56:48	2025-11-29 17:30:20	4	0	137.5
1023	241	103	2025-11-29 17:30:30	2025-11-29 18:34:01	1	0	198.48958
1024	242	101	2025-11-29 09:30:00	2025-11-29 18:24:18	1	0	1294.6875
1025	243	101	2025-11-29 09:29:16	2025-11-29 14:34:34	1	0	712.36664
1026	243	101	2025-11-29 14:44:12	2025-11-29 16:06:46	1	0	261.87778
1027	243	902	2025-11-29 16:06:51	2025-11-29 18:05:24	1	0	630.686
1028	243	101	2025-11-29 18:05:30	2025-11-29 18:42:01	1	0	127.808334
1029	244	92	2025-11-29 07:03:00	2025-11-29 10:32:39	45	0	562.5
1030	244	50	2025-11-29 10:33:58	2025-11-29 14:02:55	125	0	654.94794
1031	244	48	2025-11-29 14:03:21	2025-11-29 18:53:59	57	0	732.2917
1032	245	51	2025-11-29 07:39:09	2025-11-29 08:27:47	72	0	115
1033	245	901	2025-11-29 10:58:35	2025-11-29 10:58:51	1	0	0.5555556
1034	245	902	2025-11-29 10:59:00	2025-11-29 13:03:40	1	0	394.77777
1035	245	901	2025-11-29 13:03:58	2025-11-29 13:04:06	1	0	0.2777778
1036	245	48	2025-11-29 08:28:09	2025-11-29 13:05:52	25	7543	321.18054
1037	245	48	2025-11-29 13:06:52	2025-11-29 14:04:57	10	0	192.70833
1038	245	48	2025-11-29 14:05:52	2025-11-29 15:22:07	15	0	289.0625
1039	245	51	2025-11-29 15:22:22	2025-11-29 18:41:05	240	0	575
1040	245	901	2025-11-29 18:41:11	2025-11-29 19:17:12	1	0	112.552086
1041	248	56	2025-11-30 10:28:10	2025-11-30 11:27:07	20	0	250
1042	248	57	2025-11-30 08:08:15	2025-11-30 15:17:16	57	3552	1709.375
1043	249	61	2025-11-30 08:38:22	2025-11-30 14:32:23	100	0	1088.5416
1044	249	96	2025-11-30 14:32:35	2025-11-30 16:22:05	100	0	723.9583
1045	250	901	2025-11-30 09:52:52	2025-11-30 12:13:05	1	0	292.11804
1046	250	115	2025-11-30 12:13:16	2025-11-30 13:06:06	20	0	125
1047	250	98	2025-11-30 13:06:35	2025-11-30 13:14:41	3	0	21.875
1048	250	115	2025-11-30 13:14:53	2025-11-30 13:51:32	15	0	93.75
1049	250	900	2025-11-30 13:51:56	2025-11-30 15:03:34	40	0	149.23611
1050	250	901	2025-11-30 15:03:40	2025-11-30 16:19:56	1	0	204.32292
1051	250	115	2025-11-30 16:20:54	2025-11-30 16:38:21	10	0	93.75
1052	251	900	2025-11-30 11:00:29	2025-11-30 11:56:37	1	0	116.94444
1053	251	900	2025-11-30 13:40:41	2025-11-30 14:09:13	30	0	59.444443
1054	251	115	2025-11-30 11:58:24	2025-11-30 14:09:21	29	2747	181.25
1055	251	115	2025-11-30 14:09:44	2025-11-30 14:38:39	15	0	93.75
1056	251	902	2025-11-30 14:38:44	2025-11-30 14:38:47	0	0	0.15833333
1057	251	900	2025-11-30 14:39:09	2025-11-30 16:37:53	1	0	247.36111
1058	251	98	2025-11-30 16:38:20	2025-11-30 16:55:10	30	0	302.57916
1059	252	48	2025-11-30 07:01:00	2025-11-30 17:01:36	108	0	1706.25
1060	253	98	2025-11-30 10:02:09	2025-11-30 17:07:52	139	879	1374.375
1061	253	900	2025-11-30 09:51:37	2025-11-30 17:08:00	1	25554	39.3125
1062	254	74	2025-11-30 09:02:53	2025-11-30 09:44:35	68	0	94.44444
1063	254	87	2025-11-30 10:52:22	2025-11-30 12:52:03	9	0	281.25
1064	254	87	2025-11-30 13:30:07	2025-11-30 17:34:27	16	748	562.8472
1065	254	900	2025-11-30 09:50:27	2025-11-30 17:34:33	1	24271	186.19792
1066	255	52	2025-11-30 08:14:52	2025-11-30 13:40:39	125	0	1057.2916
1067	255	51	2025-11-30 13:40:56	2025-11-30 14:04:25	24	0	57.5
1068	255	50	2025-11-30 14:04:34	2025-11-30 15:18:40	41	0	245.57292
1069	255	52	2025-11-30 15:46:50	2025-11-30 17:09:52	13	0	148.95833
1070	255	51	2025-11-30 17:10:44	2025-11-30 18:00:17	40	0	95.833336
1071	256	900	2025-11-30 10:05:17	2025-11-30 12:58:59	1	7865	106.541664
1072	256	98	2025-11-30 10:26:04	2025-11-30 18:04:00	139	2821	1427.6459
1073	256	900	2025-11-30 12:59:19	2025-11-30 17:09:31	4	14434	36.125
1074	257	52	2025-11-30 06:48:34	2025-11-30 07:18:15	6	1015	45.833332
1075	257	51	2025-11-30 07:18:24	2025-11-30 12:00:30	528	0	912.9167
1076	257	52	2025-11-30 12:00:00	2025-11-30 18:14:49	120	0	1375
1077	258	48	2025-11-30 07:11:52	2025-11-30 08:41:06	18	0	231.25
1078	258	49	2025-11-30 08:41:50	2025-11-30 18:16:56	121	0	1742.5
1079	259	48	2025-11-30 07:12:54	2025-11-30 08:39:31	13	0	167.01389
1080	259	51	2025-11-30 08:39:38	2025-11-30 09:19:53	48	0	76.666664
1081	259	50	2025-11-30 09:20:10	2025-11-30 12:27:39	101	0	403.2986
1082	259	901	2025-11-30 13:28:55	2025-11-30 15:18:38	1	0	291.35416
1083	259	48	2025-11-30 12:27:48	2025-11-30 18:53:23	51	6595	982.8125
1084	261	67	2025-12-01 09:45:10	2025-12-01 15:11:08	35	5116	170.13889
1085	262	57	2025-12-01 06:34:40	2025-12-01 06:52:28	2	0	45.833332
1086	262	57	2025-12-01 06:59:16	2025-12-01 07:25:20	2	0	45.833332
1087	262	57	2025-12-01 07:33:29	2025-12-01 09:02:13	12	684	275
1088	262	57	2025-12-01 09:20:08	2025-12-01 11:01:01	13	683	297.91666
1089	262	57	2025-12-01 11:14:13	2025-12-01 11:44:17	4	0	94.791664
1090	262	57	2025-12-01 12:24:09	2025-12-01 13:17:18	5	416	171.875
1091	262	57	2025-12-01 14:01:35	2025-12-01 15:03:01	9	299	309.375
1092	262	57	2025-12-01 15:35:58	2025-12-01 16:05:46	4	0	137.5
1093	263	57	2025-12-01 07:04:01	2025-12-01 12:53:56	40	0	1000
1094	263	57	2025-12-01 13:06:44	2025-12-01 13:21:28	3	0	103.125
1095	263	57	2025-12-01 14:20:53	2025-12-01 14:31:32	2	0	68.75
1096	263	57	2025-12-01 15:05:25	2025-12-01 15:15:36	2	0	68.75
1097	263	56	2025-12-01 12:54:33	2025-12-01 15:59:19	30	2171	562.5
1098	263	57	2025-12-01 15:59:26	2025-12-01 16:14:11	3	0	103.125
1099	264	56	2025-12-01 08:12:47	2025-12-01 08:57:29	10	0	125
1100	264	57	2025-12-01 08:04:10	2025-12-01 12:35:08	31	2698	753.125
1101	264	57	2025-12-01 14:29:10	2025-12-01 14:47:55	3	0	103.125
1102	264	54	2025-12-01 15:03:11	2025-12-01 15:42:50	60	0	281.25
1103	264	56	2025-12-01 12:35:14	2025-12-01 16:21:51	45	3539	843.75
1104	265	57	2025-12-01 07:04:15	2025-12-01 08:53:46	10	0	229.16667
1105	265	57	2025-12-01 08:53:56	2025-12-01 11:34:39	22	0	504.16666
1106	265	57	2025-12-01 11:34:48	2025-12-01 12:52:24	10	0	335.41666
1107	265	56	2025-12-01 12:52:34	2025-12-01 13:28:57	10	0	187.5
1108	265	57	2025-12-01 13:29:07	2025-12-01 13:42:44	1	0	34.375
1109	265	57	2025-12-01 14:12:00	2025-12-01 14:24:41	2	0	68.75
1110	265	56	2025-12-01 14:24:50	2025-12-01 15:39:00	20	0	375
1111	265	54	2025-12-01 15:39:10	2025-12-01 15:59:22	20	0	93.75
1112	265	57	2025-12-01 15:59:29	2025-12-01 16:19:55	2	0	68.75
1113	266	57	2025-12-01 09:25:46	2025-12-01 10:13:28	11	0	252.08333
1114	266	57	2025-12-01 10:22:28	2025-12-01 11:02:44	5	0	114.583336
1115	266	57	2025-12-01 11:10:58	2025-12-01 11:51:14	5	0	114.583336
1116	266	57	2025-12-01 11:57:39	2025-12-01 12:21:54	3	0	68.75
1117	266	56	2025-12-01 12:49:59	2025-12-01 13:23:11	10	0	125
1118	266	57	2025-12-01 13:30:01	2025-12-01 14:21:17	6	0	168.75
1119	266	56	2025-12-01 14:33:47	2025-12-01 15:07:04	10	0	187.5
1120	266	56	2025-12-01 15:40:51	2025-12-01 16:13:53	10	0	187.5
1121	266	56	2025-12-01 16:15:50	2025-12-01 16:47:30	10	0	187.5
1122	267	57	2025-12-01 07:43:43	2025-12-01 12:25:41	31	0	710.4167
1123	267	56	2025-12-01 12:50:32	2025-12-01 13:20:39	5	0	73.958336
1124	267	57	2025-12-01 12:25:57	2025-12-01 13:36:50	2	1821	68.75
1125	267	56	2025-12-01 13:37:00	2025-12-01 14:01:52	5	0	93.75
1126	267	57	2025-12-01 14:02:00	2025-12-01 14:23:16	3	0	103.125
1127	267	56	2025-12-01 14:23:23	2025-12-01 14:46:34	5	0	93.75
1128	267	56	2025-12-01 14:50:11	2025-12-01 15:31:31	10	0	187.5
1129	267	57	2025-12-01 15:35:03	2025-12-01 15:53:52	2	0	68.75
1130	267	56	2025-12-01 15:54:01	2025-12-01 16:27:23	5	0	93.75
1131	267	57	2025-12-01 16:27:29	2025-12-01 16:53:52	3	0	103.125
1132	267	56	2025-12-01 16:53:59	2025-12-01 17:15:00	5	0	93.75
1133	268	75	2025-12-01 08:35:45	2025-12-01 09:01:27	20	0	77.77778
1134	268	77	2025-12-01 09:01:38	2025-12-01 09:06:33	20	0	27.777779
1135	268	84	2025-12-01 09:06:41	2025-12-01 09:23:52	10	0	38.194443
1136	268	111	2025-12-01 09:25:02	2025-12-01 09:29:06	10	0	8.680555
1137	268	112	2025-12-01 09:29:15	2025-12-01 09:35:37	10	0	20.48611
1138	268	102	2025-12-01 09:35:44	2025-12-01 10:18:21	10	0	111.458336
1139	268	113	2025-12-01 10:18:28	2025-12-01 10:22:49	10	0	17.36111
1140	268	84	2025-12-01 10:27:53	2025-12-01 10:52:06	20	0	76.388885
1141	268	102	2025-12-01 10:52:12	2025-12-01 12:08:07	20	0	222.91667
1142	268	75	2025-12-01 12:09:56	2025-12-01 12:46:35	30	0	116.666664
1143	268	77	2025-12-01 12:46:46	2025-12-01 12:53:56	30	0	46.354168
1144	268	110	2025-12-01 13:17:35	2025-12-01 13:36:00	10	0	109.375
1145	268	84	2025-12-01 13:41:28	2025-12-01 14:09:46	20	0	114.583336
1146	268	102	2025-12-01 14:09:57	2025-12-01 15:19:55	20	0	334.375
1147	268	94	2025-12-01 15:20:21	2025-12-01 15:32:48	20	0	56.25
1148	268	93	2025-12-01 15:33:02	2025-12-01 16:00:20	20	0	116.666664
1149	268	75	2025-12-01 16:04:30	2025-12-01 16:26:53	20	0	116.666664
1150	268	77	2025-12-01 16:27:02	2025-12-01 16:36:09	20	0	41.666668
1151	268	95	2025-12-01 16:36:51	2025-12-01 17:19:45	20	0	213.54167
1152	268	76	2025-12-01 17:20:05	2025-12-01 17:20:08	20	0	55.208332
1153	269	57	2025-12-01 07:27:29	2025-12-01 09:09:10	11	0	252.08333
1154	269	57	2025-12-01 09:09:18	2025-12-01 10:33:18	10	0	229.16667
1155	269	57	2025-12-01 10:33:27	2025-12-01 12:08:47	11	0	252.08333
1156	269	57	2025-12-01 12:09:08	2025-12-01 12:44:38	3	0	94.791664
1157	269	57	2025-12-01 14:21:25	2025-12-01 14:42:05	3	0	103.125
1158	269	56	2025-12-01 12:44:46	2025-12-01 15:14:48	30	1254	562.5
1159	269	56	2025-12-01 15:14:58	2025-12-01 15:56:10	10	0	187.5
1160	269	57	2025-12-01 15:56:18	2025-12-01 17:01:54	6	0	137.5
1161	269	56	2025-12-01 17:07:53	2025-12-01 17:30:04	5	0	93.75
1162	270	54	2025-12-01 08:46:04	2025-12-01 10:09:02	50	0	156.25
1163	270	13	2025-12-01 10:09:19	2025-12-01 10:49:00	800	0	0
1164	270	53	2025-12-01 10:49:00	2025-12-01 13:27:51	800	0	500
1165	270	54	2025-12-01 13:28:39	2025-12-01 17:33:36	250	0	1125
1166	271	74	2025-12-01 09:12:08	2025-12-01 09:16:33	10	0	13.888889
1167	271	900	2025-12-01 09:16:54	2025-12-01 09:45:44	1	0	60.069443
1168	271	87	2025-12-01 09:46:55	2025-12-01 11:02:47	5	0	156.25
1169	271	74	2025-12-01 11:03:13	2025-12-01 11:08:21	10	0	13.888889
1170	271	87	2025-12-01 11:12:38	2025-12-01 12:27:12	5	0	156.25
1171	271	74	2025-12-01 12:27:24	2025-12-01 12:33:38	10	0	13.888889
1172	271	87	2025-12-01 12:52:36	2025-12-01 14:01:37	5	0	156.25
1173	271	74	2025-12-01 14:16:32	2025-12-01 14:22:17	10	0	13.888889
1174	271	119	2025-12-01 14:22:28	2025-12-01 16:56:06	10	0	0
1175	271	74	2025-12-01 16:56:49	2025-12-01 16:59:48	3	0	4.1666665
1176	271	119	2025-12-01 17:00:00	2025-12-01 17:44:48	3	0	0
1177	272	61	2025-12-01 08:38:44	2025-12-01 16:00:15	130	0	1527.6041
1178	272	63	2025-12-01 16:00:28	2025-12-01 17:27:55	59	0	559.2708
1179	272	61	2025-12-01 17:28:21	2025-12-01 17:53:49	6	0	87.8125
1180	273	900	2025-12-01 08:59:06	2025-12-01 17:54:18	100	1218	1480.875
1181	274	75	2025-12-01 08:40:04	2025-12-01 09:12:40	20	0	77.77778
1182	274	77	2025-12-01 09:12:54	2025-12-01 09:23:51	20	0	27.777779
1183	274	84	2025-12-01 08:35:22	2025-12-01 09:35:23	10	2667	38.194443
1184	274	102	2025-12-01 09:35:30	2025-12-01 10:20:26	10	0	111.458336
1185	274	111	2025-12-01 10:21:01	2025-12-01 10:24:55	10	0	8.680555
1186	274	112	2025-12-01 10:25:03	2025-12-01 10:33:40	10	0	20.48611
1187	274	113	2025-12-01 10:33:47	2025-12-01 10:38:20	10	0	17.36111
1188	274	84	2025-12-01 10:38:28	2025-12-01 10:53:24	10	0	38.194443
1189	274	102	2025-12-01 10:53:36	2025-12-01 11:33:48	10	0	111.458336
1190	274	84	2025-12-01 11:33:57	2025-12-01 12:09:41	20	0	76.388885
1191	274	102	2025-12-01 12:09:49	2025-12-01 13:44:52	20	0	223.26389
1192	274	75	2025-12-01 13:45:01	2025-12-01 14:12:31	20	0	116.666664
1193	274	77	2025-12-01 14:12:40	2025-12-01 14:21:05	20	0	41.666668
1194	274	110	2025-12-01 14:21:16	2025-12-01 14:42:40	10	0	109.375
1195	274	84	2025-12-01 14:42:47	2025-12-01 14:58:36	10	0	57.291668
1196	274	102	2025-12-01 14:58:47	2025-12-01 15:35:15	10	0	167.1875
1197	274	94	2025-12-01 15:35:44	2025-12-01 15:50:35	20	0	56.25
1198	274	93	2025-12-01 15:50:51	2025-12-01 16:18:17	20	0	116.666664
1199	274	75	2025-12-01 16:18:27	2025-12-01 16:40:49	20	0	116.666664
1200	274	77	2025-12-01 16:40:57	2025-12-01 16:50:41	20	0	41.666668
1201	274	100	2025-12-01 16:51:04	2025-12-01 17:40:59	20	0	333.33334
1202	274	76	2025-12-01 17:41:20	2025-12-01 17:55:40	20	0	55.208332
1203	275	900	2025-12-01 09:06:16	2025-12-01 09:38:32	1	0	67.22222
1204	275	74	2025-12-01 09:03:00	2025-12-01 09:56:37	14	1955	19.444445
1205	275	87	2025-12-01 09:57:32	2025-12-01 11:58:15	7	0	218.75
1206	275	74	2025-12-01 11:58:27	2025-12-01 12:30:53	20	0	27.777779
1207	275	87	2025-12-01 12:31:26	2025-12-01 14:51:06	10	1304	312.5
1208	275	74	2025-12-01 14:52:43	2025-12-01 15:01:26	6	0	8.333333
1209	275	119	2025-12-01 15:02:35	2025-12-01 16:28:23	6	0	0
1210	275	74	2025-12-01 16:36:57	2025-12-01 16:58:02	5	0	6.9444447
1211	275	119	2025-12-01 16:58:20	2025-12-01 17:50:56	3	0	0
1212	276	900	2025-12-01 09:57:07	2025-12-01 10:06:01	1	0	18.541666
1213	276	109	2025-12-01 09:35:03	2025-12-01 17:47:03	100	2032	988.4375
1214	277	87	2025-12-01 09:00:31	2025-12-01 10:14:35	6	0	187.5
1215	277	87	2025-12-01 10:20:40	2025-12-01 11:31:54	5	0	156.25
1216	277	74	2025-12-01 11:51:57	2025-12-01 11:59:03	10	0	13.888889
1217	277	87	2025-12-01 11:59:13	2025-12-01 13:14:02	5	40	156.25
1218	277	74	2025-12-01 13:38:56	2025-12-01 13:44:52	12	0	16.666666
1219	277	87	2025-12-01 13:44:59	2025-12-01 15:15:02	7	0	218.75
1220	277	74	2025-12-01 15:20:21	2025-12-01 15:24:19	8	0	16.319445
1221	277	87	2025-12-01 15:37:24	2025-12-01 15:42:48	0	0	0
1222	277	87	2025-12-01 16:10:32	2025-12-01 16:20:55	1	0	46.875
1223	277	74	2025-12-01 17:31:02	2025-12-01 17:34:19	6	0	12.5
1224	277	119	2025-12-01 15:43:01	2025-12-01 17:56:01	10	842	0
1226	278	63	2025-12-01 12:24:37	2025-12-01 18:00:23	73	870	486.09375
1227	279	74	2025-12-01 08:20:04	2025-12-01 08:26:18	10	0	13.888889
1228	279	87	2025-12-01 08:29:13	2025-12-01 08:54:02	1	0	31.25
1229	279	900	2025-12-01 08:55:43	2025-12-01 09:24:21	1	0	59.65278
1230	279	87	2025-12-01 09:24:34	2025-12-01 10:08:47	3	0	93.75
1231	279	900	2025-12-01 10:13:14	2025-12-01 10:21:47	1	0	17.8125
1232	279	74	2025-12-01 10:22:17	2025-12-01 10:24:40	8	0	11.111111
1233	279	87	2025-12-01 10:26:14	2025-12-01 11:35:18	4	0	125
1234	279	74	2025-12-01 11:58:43	2025-12-01 12:03:46	8	0	11.111111
1235	279	87	2025-12-01 12:04:31	2025-12-01 12:53:56	3	0	93.75
1236	279	87	2025-12-01 13:03:11	2025-12-01 13:17:58	1	0	31.25
1237	279	74	2025-12-01 13:50:27	2025-12-01 13:52:12	5	0	6.9444447
1238	279	119	2025-12-01 13:52:57	2025-12-01 14:57:16	5	0	0
1239	279	119	2025-12-01 15:04:29	2025-12-01 15:06:19	0	0	0
1240	279	74	2025-12-01 15:08:20	2025-12-01 15:12:09	5	0	6.9444447
1241	279	119	2025-12-01 15:12:20	2025-12-01 16:03:29	3	419	0
1242	279	119	2025-12-01 16:03:42	2025-12-01 16:28:39	2	0	0
1243	279	74	2025-12-01 16:55:26	2025-12-01 16:58:16	5	0	6.9444447
1244	279	119	2025-12-01 16:59:31	2025-12-01 17:53:55	5	0	0
1245	280	115	2025-12-01 10:19:10	2025-12-01 10:40:54	9	0	67.5
1246	280	900	2025-12-01 09:48:29	2025-12-01 18:00:07	1	3500	1208.625
1247	281	67	2025-12-01 09:02:56	2025-12-01 09:12:17	5	0	24.305555
1248	281	105	2025-12-01 09:16:43	2025-12-01 09:28:53	1	0	39.583332
1249	281	67	2025-12-01 09:31:02	2025-12-01 09:40:14	5	0	24.305555
1250	281	105	2025-12-01 09:54:32	2025-12-01 16:51:05	24	4414	1094.0972
1251	281	67	2025-12-01 16:54:54	2025-12-01 17:05:05	5	0	36.458332
1252	281	105	2025-12-01 17:05:18	2025-12-01 17:52:26	3	0	178.125
1253	282	48	2025-12-01 09:30:07	2025-12-01 11:02:49	24	0	308.33334
1254	282	48	2025-12-01 11:04:45	2025-12-01 12:55:15	30	0	385.41666
1255	282	48	2025-12-01 13:29:10	2025-12-01 18:02:44	52	0	973.9583
1256	283	902	2025-12-01 12:08:25	2025-12-01 14:31:28	1	0	452.99167
1257	283	51	2025-12-01 06:42:33	2025-12-01 14:55:21	574	8613	1226.7042
1258	283	91	2025-12-01 14:55:40	2025-12-01 16:55:41	36	0	450
1259	283	51	2025-12-01 16:55:50	2025-12-01 18:02:59	100	252	239.58333
1260	284	900	2025-12-01 08:54:42	2025-12-01 09:09:17	1	0	30.381945
1261	284	115	2025-12-01 09:11:26	2025-12-01 09:52:47	20	0	125
1262	284	115	2025-12-01 09:52:53	2025-12-01 10:39:23	21	0	131.25
1263	284	64	2025-12-01 10:39:29	2025-12-01 10:51:22	6	0	78.75
1264	284	64	2025-12-01 10:55:30	2025-12-01 11:19:10	4	0	52.5
1265	284	900	2025-12-01 11:19:24	2025-12-01 12:03:41	1	0	92.25694
1266	284	900	2025-12-01 12:04:21	2025-12-01 12:27:11	1	0	47.569443
1267	284	900	2025-12-01 13:16:25	2025-12-01 13:59:20	1	0	89.40972
1268	284	900	2025-12-01 12:00:00	2025-12-01 14:22:11	1	0	296.21527
1269	284	900	2025-12-01 14:24:48	2025-12-01 15:44:54	1	0	250.3125
1270	284	900	2025-12-01 15:45:18	2025-12-01 16:05:50	1	0	64.166664
1271	284	64	2025-12-01 16:06:03	2025-12-01 16:59:21	10	0	196.875
1272	284	64	2025-12-01 16:59:40	2025-12-01 17:10:49	3	0	59.0625
1273	284	64	2025-12-01 17:18:51	2025-12-01 17:56:05	10	0	196.875
1274	285	900	2025-12-01 08:51:16	2025-12-01 09:49:56	1	0	122.22222
1275	285	87	2025-12-01 09:54:09	2025-12-01 10:11:54	1	0	31.25
1276	285	87	2025-12-01 10:35:58	2025-12-01 11:48:33	3	1405	93.75
1277	285	74	2025-12-01 11:56:54	2025-12-01 12:05:25	10	0	13.888889
1278	285	87	2025-12-01 12:05:39	2025-12-01 13:41:06	5	42	156.25
1279	285	74	2025-12-01 14:18:26	2025-12-01 14:18:29	5	0	6.9444447
1280	285	87	2025-12-01 14:18:55	2025-12-01 15:28:48	5	0	156.25
1281	285	74	2025-12-01 15:57:50	2025-12-01 15:59:24	5	0	6.9444447
1282	285	87	2025-12-01 15:59:49	2025-12-01 17:21:23	5	773	156.25
1283	285	74	2025-12-01 17:25:52	2025-12-01 17:35:49	5	0	7.2916665
1284	285	87	2025-12-01 17:36:07	2025-12-01 18:05:10	2	0	93.75
1285	286	57	2025-12-01 08:58:22	2025-12-01 10:36:09	12	0	275
1286	286	57	2025-12-01 10:47:57	2025-12-01 12:34:58	13	0	297.91666
1287	286	57	2025-12-01 13:09:22	2025-12-01 13:54:31	5	0	114.583336
1288	286	56	2025-12-01 12:44:45	2025-12-01 15:10:48	30	2717	531.25
1289	286	57	2025-12-01 15:35:49	2025-12-01 15:50:12	2	0	68.75
1290	286	56	2025-12-01 15:50:28	2025-12-01 16:35:23	10	0	187.5
1291	286	57	2025-12-01 16:35:27	2025-12-01 16:54:07	3	0	103.125
1292	286	56	2025-12-01 16:54:20	2025-12-01 18:06:04	10	0	187.5
1293	287	102	2025-12-01 08:47:37	2025-12-01 10:24:27	20	0	222.91667
1294	287	900	2025-12-01 10:28:46	2025-12-01 10:54:33	100	0	53.71528
1295	287	84	2025-12-01 11:02:37	2025-12-01 11:54:18	20	0	76.388885
1296	287	102	2025-12-01 11:54:29	2025-12-01 13:58:09	20	0	222.91667
1297	287	75	2025-12-01 14:06:41	2025-12-01 14:25:35	10	0	38.88889
1298	287	77	2025-12-01 14:25:48	2025-12-01 14:30:54	10	0	13.888889
1299	287	84	2025-12-01 14:31:30	2025-12-01 14:58:40	10	0	38.194443
1300	287	102	2025-12-01 14:58:55	2025-12-01 16:02:04	10	0	125.642365
1301	287	75	2025-12-01 16:26:27	2025-12-01 17:36:50	40	0	233.33333
1302	287	77	2025-12-01 17:36:59	2025-12-01 17:55:05	40	0	83.333336
1303	287	94	2025-12-01 17:56:16	2025-12-01 18:06:08	10	0	28.125
1304	288	901	2025-12-01 09:07:13	2025-12-01 14:09:12	1	0	629.13196
1305	288	901	2025-12-01 14:09:27	2025-12-01 18:07:09	1	0	818.8542
1306	289	115	2025-12-01 10:42:07	2025-12-01 11:12:40	11	605	68.75
1307	289	64	2025-12-01 12:39:03	2025-12-01 13:10:11	7	0	91.875
1308	289	64	2025-12-01 14:08:51	2025-12-01 14:32:47	5	0	65.625
1309	289	900	2025-12-01 10:24:44	2025-12-01 15:37:35	1	6242	435.03473
1310	289	64	2025-12-01 16:01:22	2025-12-01 16:18:29	2	0	26.25
1311	289	64	2025-12-01 17:04:53	2025-12-01 17:27:00	6	0	86.892365
1312	289	64	2025-12-01 17:34:46	2025-12-01 17:54:09	0	0	0
1313	289	900	2025-12-01 15:38:03	2025-12-01 18:09:00	1	4912	215.88542
1314	290	901	2025-12-01 08:24:37	2025-12-01 10:12:50	1	0	225.45139
1315	290	57	2025-12-01 10:12:56	2025-12-01 11:14:37	7	0	160.41667
1316	290	901	2025-12-01 11:15:08	2025-12-01 18:10:46	1	0	1116.7882
\.


--
-- Data for Name: works_average; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.works_average (work_id, operation_id, result, average) FROM stdin;
1	9	1	0
2	21	1	21
3	33	0	0
4	33	1	0
5	14	10	0
6	901	1	32400
7	900	1	6
8	900	1	30600
9	15	100	72
10	16	1	3300
11	900	1	13500
12	101	1	27034
13	900	1	15964
14	101	10	3064
18	901	1	28800
19	900	1	7876
20	900	1	19177
21	900	1	30571
23	900	1	21766
24	900	1	31623
25	900	1	32188
26	900	5	12.4
27	900	100	315.98
28	900	1	32243
29	900	1	32388
30	900	1	10883
31	900	1	19787
32	900	1	3036
33	40	5	89
34	42	5	142.6
35	43	5	282.2
36	40	5	79.2
37	42	5	137
38	43	5	268.6
39	40	1	76
40	42	1	139
41	43	1	200
42	40	1	118
43	42	1	171
44	43	1	170
45	40	1	57
46	900	1	6303
47	900	1	9782
48	900	1	11972
49	900	1	20323
50	900	1	17538
51	900	1	13392
52	900	1	32559
53	900	2	5700
54	900	1	19994
55	900	1	32172
58	900	1	31132
59	900	1	36151
60	901	1	36014
61	900	1	32547
62	900	1	34384
63	900	1	10136
64	900	1	20865
65	900	1	32932
66	900	64	110.828125
67	900	40	44.475
68	900	220	62.69090909090909
69	900	220	38.268181818181816
71	33	0	0
72	900	1	2293
73	900	80	115.65
74	900	45	72.37777777777778
75	900	40	151.075
76	900	55	20.4
77	900	100	39.51
78	900	55	47.472727272727276
79	900	40	91.25
80	47	1	3068
81	900	80	154.7125
82	900	115	74.35652173913043
83	900	115	45.97391304347826
84	900	100	84.75
85	900	1	42458
86	900	1	43261
87	900	1	11863
88	900	1	20234
89	900	1	21139
90	81	660	0.05454545454545454
91	60	31	0.12903225806451613
134	900	1	2945
93	900	1	5990
94	900	1	19749
95	93	40	77.975
96	95	20	106.55
97	76	20	41.4
98	95	20	107.7
99	76	20	52.85
100	75	40	63.65
101	77	40	14.3
102	94	40	30.85
103	93	40	85.525
104	95	20	130.55
105	76	20	38.2
106	900	1	3773
107	900	1	19338
92	101	1	40800
22	101	10	3372.5
70	901	20	1633.4
56	900	1	9826
57	900	1	20416
108	900	1	35937
17	900	1	29674
15	900	1	8234
16	900	1	17236
109	101	1	31639
110	75	20	79.8
111	77	20	34
112	94	20	45.6
113	93	20	66.7
114	95	20	90.15
115	76	20	37.25
116	75	20	77.25
117	77	20	14.75
118	94	20	42.9
119	93	20	56.55
120	95	20	169.4
121	75	20	75.1
122	77	20	29.35
123	76	20	45.8
124	94	20	45.25
125	93	20	93.35
126	95	20	376.95
127	76	20	78.5
128	88	1	397
129	900	1	632
130	88	3	559.6666666666666
131	900	1	12046
132	88	8	617.375
133	88	10	593.1
135	95	5	164.8
136	75	40	85.25
137	77	40	20.25
138	94	20	53.85
139	76	5	47.8
140	93	20	86.65
141	95	20	149.5
142	76	20	25.85
143	94	20	52.4
144	93	20	143.15
145	95	20	156.95
146	76	20	30.85
147	75	20	74.4
148	77	20	29.85
149	94	20	47.5
150	93	20	104.8
151	95	20	131.35
152	76	20	27.55
153	900	1	1439
154	900	1	11410
155	61	30	247.83333333333334
156	900	1	5086
157	96	50	158.46
158	57	2	477
159	54	60	71.86666666666666
160	57	3	402.6666666666667
161	57	3	368
162	57	3	399
163	57	3	484.6666666666667
164	57	2	369.5
165	57	1	302
166	56	5	232.8
167	56	10	240.7
168	900	1	14903
169	56	18	343.5
170	57	3	622.3333333333334
171	57	3	549.3333333333334
172	57	3	548
173	57	2	557.5
174	57	2	537.5
175	900	1	14833
176	56	15	279.6
177	88	5	471.8
178	88	3	610.6666666666666
179	900	1	9750
180	83	10	231.7
181	900	1	13750
182	56	5	278.2
183	57	2	354
184	54	50	53.26
185	57	3	455
186	57	4	406.25
187	57	3	512.6666666666666
188	57	1	504
189	57	2	524
190	57	1	436
191	56	5	265.6
192	900	1	16419
193	56	15	148.86666666666667
194	75	10	110
195	77	10	36.3
196	94	20	102.05
197	93	20	130.15
198	95	20	217.3
199	76	20	70.6
200	75	20	112.7
201	77	20	31.9
202	94	20	101.4
203	93	20	137.8
204	95	20	197.4
205	76	20	58.7
206	75	20	97.7
207	77	20	35.7
208	75	20	91.1
209	77	20	27
210	64	10	159.4
211	900	1	17020
212	64	12	159.08333333333334
213	900	1	5977
214	900	1	1339
215	68	15	105
216	900	200	20.295
217	900	10	145.5
218	68	10	46
219	900	40	28.45
220	99	447	33.05816554809844
221	60	128	54.1640625
222	900	1	12940
223	61	90	235.07777777777778
224	88	5	628.6
225	88	1	482
226	900	1	1064
227	88	2	448
228	88	2	578
229	900	1	11371
230	88	1	689
231	900	1	422
232	88	5	593.6
233	88	3	703
234	900	1	1315
235	88	2	641.5
236	900	1	69
237	88	5	674.8
238	900	1	2345
239	900	1	1693
240	60	64	101.875
241	60	64	64.4375
242	81	400	23.88
243	60	56	61.69642857142857
244	900	4	7563.75
245	101	1	32283
246	48	5	349.8
247	51	60	59.8
248	48	19	361.1578947368421
249	52	19	273.89473684210526
250	52	10	182.5
251	900	1	15849
252	900	1	17154
253	900	1	1136
254	64	10	193.8
255	900	1	6514
256	64	13	142.92307692307693
257	900	1	1222
258	64	9	264.3333333333333
259	56	20	250.85
260	56	20	197.75
261	57	1	1672
262	900	1	4413
263	57	4	1.25
264	57	1	627
265	57	3	456.3333333333333
266	900	2	3903.5
267	57	2	538
268	56	15	166.53333333333333
269	900	1	1509
270	56	25	174.4
271	40	0	0
272	900	1	2839
273	43	0	0
274	900	1	3557
275	42	0	0
276	900	1	7318
277	40	4	80.75
278	42	4	72
279	43	4	179
280	900	1	2894
281	900	1	394
282	54	10	118.1
283	56	3	269.3333333333333
284	57	3	562.6666666666666
285	54	30	111.43333333333334
286	900	1	22067
287	56	20	232.75
288	901	20	1766.8
289	900	1	31144
290	57	5	505.4
291	56	5	408.4
292	57	3	591
293	56	5	234
294	900	1	4077
295	57	4	461.5
296	57	2	417
297	57	1	361
298	900	1	9051
299	900	1	4178
300	56	23	223.08695652173913
301	900	1	17424
302	88	19	634.7368421052631
303	900	1	4412
304	901	1	35141
305	900	1	34746
306	900	1	29407
307	901	1	34071
308	101	1	38483
309	900	1	4034
310	900	25	1255.44
311	80	100	28.07
312	79	5	167.8
313	900	1	5608
314	60	64	54.46875
315	60	128	0.09375
316	79	0	0
317	81	400	27.975
318	60	64	42.15625
319	79	30	43.13333333333333
320	80	30	37.8
321	900	1	44767
322	900	1	46665
323	95	20	0.2
324	93	40	0.125
325	94	40	0.1
326	77	40	0.2
327	75	40	0.1
328	76	20	0.25
329	95	20	150.1
330	76	20	0.2
331	95	20	145.65
332	76	20	0.15
333	75	20	67.15
334	77	20	13.85
335	94	10	30.6
336	93	10	72.8
337	95	10	168.9
338	76	10	0.3
339	69	130	11.846153846153847
340	69	260	8.830769230769231
341	71	16	32.25
342	72	16	6.3125
343	73	16	8.3125
344	71	20	21.9
345	72	20	0.2
346	73	20	7.95
347	75	40	0.55
348	77	40	0.125
349	94	40	0.2
350	93	40	52.9
351	95	40	150.2
352	76	40	39.3
353	75	27	60.25925925925926
354	77	27	36.851851851851855
355	94	27	24.40740740740741
356	93	27	33.77777777777778
357	95	27	107.81481481481481
358	76	27	21.77777777777778
359	71	50	14.04
360	72	50	3.78
361	73	50	12.62
362	900	1	22853
363	54	20	31.05
364	56	10	267.9
365	54	20	62.95
366	56	6	300.3333333333333
367	54	0	0
368	57	6	600
369	56	24	325
370	54	42	61.38095238095238
371	56	10	304.7
372	56	10	268.8
373	57	2	1130
374	56	5	304.4
375	56	10	360
376	900	1	3501
377	900	1	2231
378	56	5	158.6
379	56	15	217.26666666666668
380	56	15	219.13333333333333
381	56	15	200.6
382	57	4	522.75
383	64	41	406
384	64	19	141.78947368421052
385	900	1	5066
386	54	50	105.58
387	13	800	1.875
388	53	300	10.713333333333333
389	54	130	73.5923076923077
390	56	5	720
391	54	70	98.4
392	56	5	273
393	57	7	600
394	56	25	333.72
395	54	10	101.8
396	56	17	250.47058823529412
397	56	10	316
398	900	1	3837
399	56	35	249.42857142857142
400	900	1	12755
401	49	20	208.55
402	49	20	326.75
403	92	20	369.2
404	91	2	271
405	60	128	88.09375
406	900	100	22.46
407	99	130	37.56153846153846
408	60	64	52.875
409	900	20	403.05
410	64	110	323.8727272727273
411	57	2	450
412	56	20	210
413	53	300	12.873333333333333
414	900	1	2257
415	54	300	52.85666666666667
416	56	1	401
417	101	1	30701
418	101	1	32164
419	900	1	15067
420	900	1	2008
421	900	1	15048
422	900	1	9086
423	96	39	103.17948717948718
424	61	50	242.38
425	900	20	357.95
426	57	5	2.2
427	56	10	0.4
428	53	200	13.645
429	54	200	57.48
430	57	2	468
431	57	3	797.3333333333334
432	56	25	238.12
433	901	1	34269
434	900	1	8887
435	63	25	152.52
436	96	30	113.8
437	61	50	213.46
438	900	1	5599
439	79	100	83.47
440	80	100	24.89
441	79	100	68.5
442	80	100	39.4
443	79	100	51.83
444	80	100	39.01
445	101	1	33408
446	900	1	8884
447	900	1	6255
448	900	1	3141
449	900	1	4271
450	900	1	8862
451	900	1	14440
452	51	80	58.75
453	50	50	120.86
454	50	30	96.03333333333333
455	48	12	267.1666666666667
456	50	10	123.7
457	48	12	215.75
458	67	20	0.95
459	105	3	5.333333333333333
460	105	1	6
461	67	5	160.4
462	43	0	0
463	105	1	1108
464	67	5	144
465	105	5	191.6
466	105	3	926
467	67	5	146.2
468	105	1	1388
469	67	5	146.2
470	105	1	2007
471	67	5	127
472	105	1	1118
473	67	5	130.2
474	105	1	1248
475	109	1	1136
476	900	1	1800
477	75	60	80
478	77	60	26
479	94	20	99.35
480	93	20	114.4
481	95	20	190.7
482	76	20	33.25
483	900	1	1541
484	94	40	51.625
485	900	1	256
486	93	40	109.275
487	95	40	117.175
488	76	40	33.675
489	94	20	3.2
493	94	20	64.7
503	900	1	15193
504	900	1	2117
505	900	1	16027
506	111	1	4
507	900	1	15346
508	900	1	18135
509	901	50	722.48
510	900	1	14817
511	49	50	281.76
512	49	10	310.1
513	92	10	345
514	92	10	215.9
515	48	6	320
516	900	1	32324
517	900	1	2
518	57	3	3.3333333333333335
519	56	30	99.36666666666666
520	54	20	91.55
521	56	12	249.66666666666666
522	56	10	63.4
523	56	20	73.05
524	57	3	107.66666666666667
525	56	10	207.6
526	57	2	314
527	56	10	182.8
528	56	10	200.7
529	900	55	453.54545454545456
532	901	1	35166
533	900	1	10495
534	900	1	6932
535	900	1	19007
536	900	1	6600
537	50	60	104.38333333333334
538	50	40	119.275
539	50	32	107.375
540	50	12	120.41666666666667
541	48	37	270.1081081081081
542	83	30	380.23333333333335
543	900	1	2525
544	900	30	178.36666666666667
545	900	60	256.3666666666667
546	79	150	76.45333333333333
547	80	150	25.886666666666667
548	79	150	72.82
549	80	150	30.286666666666665
550	900	1	5709
551	79	10	161
552	80	10	110.1
553	900	1	28634
554	49	100	273.63
555	92	60	308.71666666666664
556	900	1	28845
557	901	1	9901
558	901	1	2492
559	49	20	314
594	71	50	29.9
595	72	50	9.8
596	73	50	7.28
597	111	20	20.6
530	900	1	13383
531	900	1	19021
598	112	20	75
490	93	20	0.25
491	95	20	0.2
492	76	20	0.25
494	93	20	144.15
495	95	20	196.5
496	76	20	64.75
497	75	20	103.75
498	77	20	24.65
499	94	20	59.5
500	93	20	118.7
501	95	20	187.25
502	76	20	68.25
560	57	10	591.8
561	57	12	533.25
562	57	12	647.3333333333334
563	57	6	635.1666666666666
564	54	40	67.5
565	56	15	316.8666666666667
566	57	4	514.25
567	75	20	63.85
568	77	20	13.6
569	900	1	2103
570	110	20	147.55
571	110	20	122.7
572	110	20	102.05
573	110	20	28.45
574	110	20	118.65
575	75	10	55.7
576	77	10	13.8
577	71	50	20.7
578	72	50	11.74
579	73	50	5.82
580	84	20	74.05
581	111	20	13.95
582	112	20	32.85
583	102	20	222.85
584	113	20	25.65
585	75	20	110.15
586	77	20	33.3
587	71	21	61.666666666666664
588	72	21	21.095238095238095
589	73	19	9.052631578947368
590	110	20	224.6
591	110	20	192.1
592	75	20	97.95
593	77	20	28.4
599	84	20	151.4
600	113	20	127.55
601	13	800	4.59
602	53	800	14.4875
603	54	260	56.11538461538461
604	57	5	470.6
605	57	5	511.4
606	57	5	505.6
607	57	5	466
608	56	10	189.4
609	56	10	179.4
610	56	10	236.1
611	56	10	189.7
612	56	10	209.5
613	109	100	274.37
614	900	1	2117
615	110	60	190.51666666666668
616	75	40	75.7
617	77	30	38.93333333333333
618	84	20	87.3
619	102	20	316.2
620	112	20	33.85
621	111	20	10.9
622	113	20	35.9
623	88	10	495.1
624	88	16	497.5
625	83	10	140
626	88	24	547.25
627	88	5	593.8
628	900	1	1101
629	88	1	656
630	88	3	388.3333333333333
631	88	2	509
632	88	3	511
633	88	5	630.8
634	900	1	68
635	88	5	651.6
636	88	3	587.6666666666666
637	88	2	703
638	88	3	453
639	88	5	572
640	88	5	546.2
641	88	3	527
642	900	1150	3.213913043478261
643	75	20	92.5
644	77	20	23.4
645	110	20	218.85
646	110	20	114.65
647	75	20	86.3
648	77	20	27.65
649	71	50	26.8
650	72	50	10.26
651	73	50	9.08
652	111	20	22.15
653	112	20	64.4
654	84	20	89.5
655	102	20	249.65
656	113	20	45.75
657	56	10	294.2
658	57	10	430
659	57	7	711
660	56	10	282
661	57	6	652.3333333333334
662	56	15	289.2
663	57	4	506.5
664	56	10	455.6
665	57	4	248.5
666	56	10	202
667	88	4	654.25
668	900	1	621
669	88	4	626.25
670	88	5	663.6
671	88	1	293
672	900	1	24
673	88	8	706.75
674	88	24	624.5833333333334
675	79	200	58.52
676	900	400	37.15
677	88	17	610.2352941176471
678	88	8	583.25
679	88	19	513.3684210526316
680	88	8	534.875
681	67	5	158.6
682	105	1	1206
683	67	5	111.8
684	105	1	921
685	67	5	110
686	105	1	951
687	67	5	109.8
688	105	1	955
689	67	5	85.4
690	105	1	1298
691	67	5	124.6
692	105	1	902
693	67	5	124
694	105	1	943
695	67	5	131.2
696	67	1	97
697	105	1	746
698	105	1	731
699	67	2	120.5
700	105	11	921.0909090909091
701	900	1	4665
702	61	51	221.76470588235293
703	96	90	171.46666666666667
704	50	10	79.2
705	48	105	215.8
706	50	10	74.1
707	48	31	189.03225806451613
708	51	24	84.79166666666667
709	900	1	6772
710	96	80	112.55
711	61	79	207.0126582278481
712	901	1	8845
713	57	3	482
714	56	6	289.6666666666667
715	901	1	6222
716	56	4	241.5
717	901	1	14416
718	101	1	28444
719	101	1	3
720	57	6	445.8333333333333
721	57	12	342.6666666666667
722	57	12	441.1666666666667
723	57	10	460.4
724	56	15	271.3333333333333
725	57	2	409.5
726	56	5	200.4
727	57	3	374
728	57	5	346.6
729	56	5	251
730	57	5	372
731	56	5	226.4
732	52	125	174.72
733	51	208	34.5625
734	52	45	161.57777777777778
735	98	16	145.3125
736	900	1	1063
737	900	1	2401
738	98	15	188.93333333333334
739	98	12	175.08333333333334
740	98	13	199.6153846153846
741	98	14	230.28571428571428
742	98	20	219.3
743	900	1	2264
744	101	1	26918
745	101	1	2
746	101	1	33170
747	56	20	238.4
748	57	10	451.9
749	56	10	191.6
750	57	10	291
751	57	8	484.875
752	54	50	47.98
753	57	5	500.2
754	56	45	203.37777777777777
755	57	23	539.5217391304348
756	56	5	311.4
757	57	4	296.75
758	56	3	309.6666666666667
759	57	7	632.4285714285714
760	56	6	353.6666666666667
761	57	2	419
762	56	5	265.8
763	57	5	557
764	56	5	188.2
765	57	4	608.75
766	56	5	431.8
767	92	50	357.26
768	92	10	396.7
769	50	30	71
770	92	10	361.3
771	92	10	340.2
772	50	15	56.8
773	92	15	234.26666666666668
774	92	5	209.4
775	88	5	396.8
776	900	1	267
777	50	53	127.90566037735849
778	900	1	1389
779	88	10	453.7
780	900	1	2867
781	88	7	385.2857142857143
782	88	7	417.2857142857143
783	88	3	439
784	88	3	460.3333333333333
785	900	1	5549
786	88	3	493.3333333333333
787	88	12	537.75
788	901	1	25662
789	75	20	107.15
790	77	20	30.75
791	71	50	42.34
792	72	50	9.82
793	73	50	10.56
794	110	60	190.41666666666666
795	75	20	112.15
796	77	20	29.45
797	71	50	22.32
798	72	50	10.34
799	73	50	15.32
800	84	20	156.65
801	102	20	293.75
802	111	20	35.05
803	112	20	47.4
804	113	20	53.55
805	901	1	27540
806	901	1	33427
807	57	23	527.0869565217391
808	57	5	352.8
809	57	6	397.8333333333333
810	57	2	389
811	57	7	490.85714285714283
812	57	2	364
813	57	3	329
814	56	20	263.25
815	57	2	558
816	900	5	908.4
817	88	2	566
818	88	5	664.4
819	88	5	675.2
820	88	5	717.4
821	88	5	615.6
822	88	3	653.3333333333334
823	88	5	670.8
824	88	4	660.25
825	900	1	11534
826	64	17	224.23529411764707
827	64	14	193.78571428571428
828	64	7	250.57142857142858
829	64	25	108.52
830	64	5	324
831	64	23	276.30434782608694
832	900	1	2406
833	98	93	124.6236559139785
834	98	31	263.93548387096774
835	98	93	123.97849462365592
836	98	32	254.59375
837	900	1	10025
838	52	15	200.26666666666668
839	50	55	113.45454545454545
840	48	76	350.7236842105263
841	50	15	85.6
842	79	100	85.74
843	70	100	5.41
844	80	100	42.46
845	79	100	74.98
846	80	100	51.25
847	79	30	107.53333333333333
848	103	1	991
849	88	2	922
850	103	1	15066
851	88	5	554.2
852	103	4	3095.25
853	88	4	563.75
854	103	1	356
855	900	1	5814
856	98	31	184.74193548387098
857	98	12	181.41666666666666
858	98	13	202.6153846153846
859	98	14	230.35714285714286
860	98	20	219.5
861	900	1	6622
862	79	200	64.61
863	80	200	34.405
864	900	1	4667
865	70	100	1.31
866	79	100	63.38
867	80	100	29.2
868	83	235	137.8127659574468
869	900	30	173.2
870	101	1	21569
871	902	1	7119
872	101	1	10241
873	900	30	1208
874	900	20	497.2
875	83	180	161.8
876	92	145	276.99310344827586
877	50	40	111.3
878	91	65	211.09230769230768
879	902	1	2595
880	901	1	5368
881	91	40	392.575
882	51	36	68.11111111111111
883	91	24	225.45833333333334
884	51	11	37.90909090909091
885	51	65	49.95384615384615
886	57	12	589.1666666666666
887	56	8	231.25
888	57	12	420.3333333333333
889	57	12	456.25
890	57	14	599.2142857142857
891	54	310	77.38064516129032
892	57	9	724.2222222222222
893	57	8	457
894	56	5	388
895	57	14	622.7857142857143
896	57	6	500.1666666666667
897	57	13	628.3076923076923
898	64	27	178.77777777777777
899	64	83	254.66265060240963
900	57	3	447.6666666666667
901	57	4	334.5
902	56	5	225.4
903	57	4	601
904	900	1	16949
905	57	15	352.73333333333335
906	57	3	56.666666666666664
907	54	100	62.35
908	900	1	17342
909	57	13	414.15384615384613
910	46	20	49.95
911	80	200	43.18
912	46	40	41.025
913	900	1	4901
914	109	43	194.7674418604651
915	901	1	19493
916	57	21	613.6666666666666
917	901	1	912
918	88	26	480.46153846153845
919	88	5	603.8
920	88	5	507.8
921	88	14	559.7142857142857
922	50	16	134.3125
923	92	30	434.8333333333333
924	92	20	334.05
925	48	30	177.63333333333333
926	49	10	206
927	48	14	221.85714285714286
928	60	128	56.6484375
929	900	60	90.96666666666667
930	109	42	226.4047619047619
931	88	5	439.2
932	88	5	373.6
933	88	5	413
934	900	1	8845
935	88	5	470.6
936	88	5	488.8
937	900	1	5815
938	88	4	517.25
939	900	1	739
940	88	5	461.4
941	900	1	1875
942	96	32	112.5
943	900	1	8576
944	88	4	520.5
945	900	1	9526
946	88	5	586
947	88	5	727.6
948	88	2	719
949	88	3	635.6666666666666
950	88	4	301
951	88	5	646.8
952	51	192	21.041666666666668
953	52	65	156.95384615384614
954	51	108	31.35185185185185
955	52	27	128.85185185185185
956	91	80	187.5125
957	88	13	754.4615384615385
958	88	5	670.2
959	88	1	410
960	88	7	526.4285714285714
961	88	11	673.9090909090909
962	70	1000	1.044
963	900	1	4530
964	60	64	99.96875
965	900	1	2241
966	109	46	265.1304347826087
967	114	46	50.08695652173913
968	56	10	231.3
969	57	5	382.4
970	900	1	15658
971	57	25	401.44
972	61	128	229.9921875
973	96	50	66.74
974	96	99	105.06060606060606
975	61	80	233.925
976	88	10	484.9
977	901	10	2425.8
978	900	20	717.15
979	98	20	139.15
980	900	0	0
981	98	46	178.8695652173913
982	900	20	203.7
983	900	1	6254
984	98	20	142.7
985	98	46	178.1086956521739
986	900	1	4196
987	51	48	61.583333333333336
988	48	25	217.48
989	50	10	116.4
990	48	10	45.8
991	48	80	189.275
992	48	24	194.375
993	51	100	64.04
994	98	25	217.88
995	98	50	173.2
996	57	5	634.2
997	56	10	256.3
998	57	5	637.4
999	900	1	15213
1000	57	4	478.5
1001	57	10	513.2
1002	57	6	599.1666666666666
1003	901	1	10870
1004	98	27	138.74074074074073
1005	901	1	16547
1006	64	10	213.7
1007	64	5	129
1008	64	4	799
1009	64	2	113
1010	64	17	95.52941176470588
1011	64	5	343.8
1012	64	72	172.44444444444446
1013	105	17	688.2352941176471
1014	67	4	116.25
1015	105	10	899.1
1016	98	20	204.7
1017	98	104	209.7596153846154
1018	900	1	3172
1019	83	197	165.76649746192894
1020	103	1	20982
1021	88	7	479.85714285714283
1022	88	4	503
1023	103	1	3811
1024	101	1	32058
1025	101	1	18318
1026	101	1	4954
1027	902	1	7113
1028	101	1	2191
1029	92	45	279.53333333333336
1030	50	125	100.296
1031	48	57	305.9298245614035
1032	51	72	40.52777777777778
1033	901	1	16
1034	902	1	7480
1035	901	1	8
1036	48	25	364.8
1037	48	10	348.5
1038	48	15	305
1039	51	240	49.67916666666667
1040	901	1	2161
1041	56	20	176.85
1042	57	57	389.280701754386
1043	61	100	212.41
1044	96	100	65.7
1045	901	1	8413
1046	115	20	158.5
1047	98	3	162
1048	115	15	146.6
1049	900	40	107.45
1050	901	1	4576
1051	115	10	104.7
1052	900	1	3368
1053	900	30	57.06666666666667
1054	115	29	176.20689655172413
1055	115	15	115.66666666666667
1056	902	0	0
1057	900	1	7124
1058	98	30	33.666666666666664
1059	48	108	333.6666666666667
1060	98	139	177.4388489208633
1061	900	1	629
1062	74	68	36.794117647058826
1063	87	9	797.8888888888889
1064	87	16	869.5
1065	900	1	3575
1066	52	125	156.376
1067	51	24	58.708333333333336
1068	50	41	108.4390243902439
1069	52	13	383.2307692307692
1070	51	40	74.325
1071	900	1	2557
1072	98	139	177.37410071942446
1073	900	4	144.5
1074	52	6	127.66666666666667
1075	51	528	32.05681818181818
1076	52	120	187.40833333333333
1077	48	18	297.44444444444446
1078	49	121	285.1735537190083
1079	48	13	399.7692307692308
1080	51	48	50.3125
1081	50	101	111.37623762376238
1082	901	1	6583
1083	48	51	324.3137254901961
1084	67	35	412.62857142857143
1085	57	2	534
1086	57	2	782
1087	57	12	386.6666666666667
1088	57	13	413.0769230769231
1089	57	4	451
1090	57	5	554.6
1091	57	9	376.3333333333333
1092	57	4	447
1093	57	40	524.875
1094	57	3	294.6666666666667
1095	57	2	319.5
1096	57	2	305.5
1097	56	30	297.1666666666667
1098	57	3	295
1099	56	10	268.2
1100	57	31	437.4193548387097
1101	57	3	375
1102	54	60	39.65
1103	56	45	223.51111111111112
1104	57	10	657.1
1105	57	22	438.3181818181818
1106	57	10	465.6
1107	56	10	218.3
1108	57	1	817
1109	57	2	380.5
1110	56	20	222.5
1111	54	20	60.6
1112	57	2	613
1113	57	11	260.1818181818182
1114	57	5	483.2
1115	57	5	483.2
1116	57	3	485
1117	56	10	199.2
1118	57	6	512.6666666666666
1119	56	10	199.7
1120	56	10	198.2
1121	56	10	190
1122	57	31	545.741935483871
1123	56	5	361.4
1124	57	2	1216
1125	56	5	298.4
1126	57	3	425.3333333333333
1127	56	5	278.2
1128	56	10	248
1129	57	2	564.5
1130	56	5	400.4
1131	57	3	527.6666666666666
1132	56	5	252.2
1133	75	20	77.1
1134	77	20	14.75
1135	84	10	103.1
1136	111	10	24.4
1137	112	10	38.2
1138	102	10	255.7
1139	113	10	26.1
1140	84	20	72.65
1141	102	20	227.75
1142	75	30	73.3
1143	77	30	14.333333333333334
1144	110	10	110.5
1145	84	20	84.9
1146	102	20	209.9
1147	94	20	37.35
1148	93	20	81.9
1149	75	20	67.15
1150	77	20	27.35
1151	95	20	128.7
1152	76	20	0.15
1153	57	11	554.6363636363636
1154	57	10	504
1155	57	11	520
1156	57	3	710
1157	57	3	413.3333333333333
1158	56	30	258.26666666666665
1159	56	10	247.2
1160	57	6	656
1161	56	5	266.2
1162	54	50	99.56
1163	13	800	2.97625
1164	53	800	11.91375
1165	54	250	58.788
1166	74	10	26.5
1167	900	1	1730
1168	87	5	910.4
1169	74	10	30.8
1170	87	5	894.8
1171	74	10	37.4
1172	87	5	828.2
1173	74	10	34.5
1174	119	10	921.8
1175	74	3	59.666666666666664
1176	119	3	896
1177	61	130	203.77692307692308
1178	63	59	88.9322033898305
1179	61	6	254.66666666666666
1180	900	100	308.94
1181	75	20	97.8
1182	77	20	32.85
1183	84	10	93.4
1184	102	10	269.6
1185	111	10	23.4
1186	112	10	51.7
1187	113	10	27.3
1188	84	10	89.6
1189	102	10	241.2
1190	84	20	107.2
1191	102	20	285.15
1192	75	20	82.5
1193	77	20	25.25
1194	110	10	128.4
1195	84	10	94.9
1196	102	10	218.8
1197	94	20	44.55
1198	93	20	82.3
1199	75	20	67.1
1200	77	20	29.2
1201	100	20	149.75
1202	76	20	43
1203	900	1	1936
1204	74	14	90.14285714285714
1205	87	7	1034.7142857142858
1206	74	20	97.3
1207	87	10	707.6
1208	74	6	87.16666666666667
1209	119	6	858
1210	74	5	253
1211	119	3	1052
1212	900	1	534
1213	109	100	274.88
1214	87	6	740.6666666666666
1215	87	5	854.8
1216	74	10	42.6
1217	87	5	889.8
1218	74	12	29.666666666666668
1219	87	7	771.8571428571429
1220	74	8	29.75
1221	87	0	0
1222	87	1	623
1223	74	6	32.833333333333336
1224	119	10	713.8
1225	900	1	9741
1226	63	73	264.05479452054794
1227	74	10	37.4
1228	87	1	1489
1229	900	1	1718
1230	87	3	884.3333333333334
1231	900	1	513
1232	74	8	17.875
1233	87	4	1036
1234	74	8	37.875
1235	87	3	988.3333333333334
1236	87	1	887
1237	74	5	21
1238	119	5	771.8
1239	119	0	0
1240	74	5	45.8
1241	119	3	883.3333333333334
1242	119	2	748.5
1243	74	5	34
1244	119	5	652.8
1245	115	9	144.88888888888889
1246	900	1	25998
1247	67	5	112.2
1248	105	1	730
1249	67	5	110.4
1250	105	24	857.4583333333334
1251	67	5	122.2
1252	105	3	942.6666666666666
1253	48	24	231.75
1254	48	30	221
1255	48	52	315.65384615384613
1256	902	1	8583
1257	51	574	36.50696864111498
1258	91	36	200.02777777777777
1259	51	100	37.77
1260	900	1	875
1261	115	20	124.05
1262	115	21	132.85714285714286
1263	64	6	118.83333333333333
1264	64	4	355
1265	900	1	2657
1266	900	1	1370
1267	900	1	2575
1268	900	1	8531
1269	900	1	4806
1270	900	1	1232
1271	64	10	319.8
1272	64	3	223
1273	64	10	223.4
1274	900	1	3520
1275	87	1	1065
1276	87	3	983.3333333333334
1277	74	10	51.1
1278	87	5	1137
1279	74	5	0.6
1280	87	5	838.6
1281	74	5	18.8
1282	87	5	824.2
1283	74	5	119.4
1284	87	2	871.5
1285	57	12	488.9166666666667
1286	57	13	493.9230769230769
1287	57	5	541.8
1288	56	30	201.53333333333333
1289	57	2	431.5
1290	56	10	269.5
1291	57	3	373.3333333333333
1292	56	10	430.4
1293	102	20	290.5
1294	900	100	15.47
1295	84	20	155.05
1296	102	20	371
1297	75	10	113.4
1298	77	10	30.6
1299	84	10	163
1300	102	10	378.9
1301	75	40	105.575
1302	77	40	27.15
1303	94	10	59.2
1304	901	1	18119
1305	901	1	14262
1306	115	11	111.63636363636364
1307	64	7	266.85714285714283
1308	64	5	287.2
1309	900	1	12529
1310	64	2	513.5
1311	64	6	221.16666666666666
1312	64	0	0
1313	900	1	4145
1314	901	1	6493
1315	57	7	528.7142857142857
1316	901	1	24938
\.


--
-- Name: admin_config_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.admin_config_id_seq', 444, true);


--
-- Name: admin_menu_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.admin_menu_id_seq', 18, false);


--
-- Name: admin_operation_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.admin_operation_log_id_seq', 1139, true);


--
-- Name: admin_permissions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.admin_permissions_id_seq', 9, false);


--
-- Name: admin_roles_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.admin_roles_id_seq', 3, false);


--
-- Name: admin_users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.admin_users_id_seq', 4, true);


--
-- Name: admins_telegram_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.admins_telegram_id_seq', 1, false);


--
-- Name: archived_operations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.archived_operations_id_seq', 249, true);


--
-- Name: black_list_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.black_list_id_seq', 1, false);


--
-- Name: bonuses_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.bonuses_id_seq', 10, false);


--
-- Name: calculator_avoided_workers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.calculator_avoided_workers_id_seq', 1, false);


--
-- Name: department_groups_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.department_groups_id_seq', 11, true);


--
-- Name: department_report_types_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.department_report_types_id_seq', 4, true);


--
-- Name: departments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.departments_id_seq', 12, true);


--
-- Name: failed_jobs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.failed_jobs_id_seq', 1, false);


--
-- Name: hour_payments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.hour_payments_id_seq', 4, false);


--
-- Name: migrations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.migrations_id_seq', 19, true);


--
-- Name: module_operation_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.module_operation_id_seq', 1, false);


--
-- Name: modules_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.modules_id_seq', 1, false);


--
-- Name: natural_operations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.natural_operations_id_seq', 248, true);


--
-- Name: operation_feedstocks_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.operation_feedstocks_id_seq', 1, false);


--
-- Name: operation_permissions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.operation_permissions_id_seq', 8, true);


--
-- Name: operation_results_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.operation_results_id_seq', 1, false);


--
-- Name: operation_versions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.operation_versions_id_seq', 131, true);


--
-- Name: operations_average_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.operations_average_id_seq', 123, true);


--
-- Name: operations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.operations_id_seq', 120, true);


--
-- Name: operations_mode_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.operations_mode_id_seq', 123, true);


--
-- Name: payment_coefficients_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.payment_coefficients_id_seq', 6, false);


--
-- Name: permission_types_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.permission_types_id_seq', 4, true);


--
-- Name: personal_access_tokens_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.personal_access_tokens_id_seq', 1, false);


--
-- Name: shift_bonuses_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.shift_bonuses_id_seq', 24, false);


--
-- Name: shift_coefficients_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.shift_coefficients_id_seq', 26, false);


--
-- Name: shift_hour_payments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.shift_hour_payments_id_seq', 10, false);


--
-- Name: shifts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.shifts_id_seq', 12, false);


--
-- Name: team_leads_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.team_leads_id_seq', 1, false);


--
-- Name: trusted_workers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.trusted_workers_id_seq', 1, false);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.users_id_seq', 1, false);


--
-- Name: work_day_departments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.work_day_departments_id_seq', 226, true);


--
-- Name: work_days_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.work_days_id_seq', 290, true);


--
-- Name: work_departments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.work_departments_id_seq', 63, true);


--
-- Name: work_permission_requests_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.work_permission_requests_id_seq', 183, true);


--
-- Name: worker_shifts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.worker_shifts_id_seq', 69, true);


--
-- Name: workers_telegram_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.workers_telegram_id_seq', 1, false);


--
-- Name: workpieces_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.workpieces_id_seq', 1, false);


--
-- Name: works_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.works_id_seq', 1316, true);


--
-- Name: admin_config admin_config_name_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_config
    ADD CONSTRAINT admin_config_name_unique UNIQUE (name);


--
-- Name: admin_config admin_config_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_config
    ADD CONSTRAINT admin_config_pkey PRIMARY KEY (id);


--
-- Name: admin_menu admin_menu_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_menu
    ADD CONSTRAINT admin_menu_pkey PRIMARY KEY (id);


--
-- Name: admin_operation_log admin_operation_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_operation_log
    ADD CONSTRAINT admin_operation_log_pkey PRIMARY KEY (id);


--
-- Name: admin_permissions admin_permissions_name_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_permissions
    ADD CONSTRAINT admin_permissions_name_unique UNIQUE (name);


--
-- Name: admin_permissions admin_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_permissions
    ADD CONSTRAINT admin_permissions_pkey PRIMARY KEY (id);


--
-- Name: admin_permissions admin_permissions_slug_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_permissions
    ADD CONSTRAINT admin_permissions_slug_unique UNIQUE (slug);


--
-- Name: admin_roles admin_roles_name_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_roles
    ADD CONSTRAINT admin_roles_name_unique UNIQUE (name);


--
-- Name: admin_roles admin_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_roles
    ADD CONSTRAINT admin_roles_pkey PRIMARY KEY (id);


--
-- Name: admin_roles admin_roles_slug_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_roles
    ADD CONSTRAINT admin_roles_slug_unique UNIQUE (slug);


--
-- Name: admin_users admin_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_users
    ADD CONSTRAINT admin_users_pkey PRIMARY KEY (id);


--
-- Name: admin_users admin_users_username_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_users
    ADD CONSTRAINT admin_users_username_unique UNIQUE (username);


--
-- Name: admins admins_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admins
    ADD CONSTRAINT admins_pkey PRIMARY KEY (telegram_id);


--
-- Name: archived_operations archived_operations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.archived_operations
    ADD CONSTRAINT archived_operations_pkey PRIMARY KEY (id);


--
-- Name: black_list black_list_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.black_list
    ADD CONSTRAINT black_list_pkey PRIMARY KEY (id);


--
-- Name: bonuses bonuses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bonuses
    ADD CONSTRAINT bonuses_pkey PRIMARY KEY (id);


--
-- Name: calculator_avoided_workers calculator_avoided_workers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calculator_avoided_workers
    ADD CONSTRAINT calculator_avoided_workers_pkey PRIMARY KEY (id);


--
-- Name: department_groups department_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.department_groups
    ADD CONSTRAINT department_groups_pkey PRIMARY KEY (id);


--
-- Name: department_report_types department_report_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.department_report_types
    ADD CONSTRAINT department_report_types_pkey PRIMARY KEY (id);


--
-- Name: departments departments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.departments
    ADD CONSTRAINT departments_pkey PRIMARY KEY (id);


--
-- Name: failed_jobs failed_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.failed_jobs
    ADD CONSTRAINT failed_jobs_pkey PRIMARY KEY (id);


--
-- Name: failed_jobs failed_jobs_uuid_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.failed_jobs
    ADD CONSTRAINT failed_jobs_uuid_unique UNIQUE (uuid);


--
-- Name: hour_payments hour_payments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hour_payments
    ADD CONSTRAINT hour_payments_pkey PRIMARY KEY (id);


--
-- Name: migrations migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.migrations
    ADD CONSTRAINT migrations_pkey PRIMARY KEY (id);


--
-- Name: module_operation module_operation_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.module_operation
    ADD CONSTRAINT module_operation_pkey PRIMARY KEY (id);


--
-- Name: modules modules_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.modules
    ADD CONSTRAINT modules_pkey PRIMARY KEY (id);


--
-- Name: natural_operations natural_operations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.natural_operations
    ADD CONSTRAINT natural_operations_pkey PRIMARY KEY (id);


--
-- Name: operation_feedstocks operation_feedstocks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operation_feedstocks
    ADD CONSTRAINT operation_feedstocks_pkey PRIMARY KEY (id);


--
-- Name: operation_permissions operation_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operation_permissions
    ADD CONSTRAINT operation_permissions_pkey PRIMARY KEY (id);


--
-- Name: operation_results operation_results_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operation_results
    ADD CONSTRAINT operation_results_pkey PRIMARY KEY (id);


--
-- Name: operation_versions operation_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operation_versions
    ADD CONSTRAINT operation_versions_pkey PRIMARY KEY (id);


--
-- Name: operations_average operations_average_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operations_average
    ADD CONSTRAINT operations_average_pkey PRIMARY KEY (id);


--
-- Name: operations_mode operations_mode_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operations_mode
    ADD CONSTRAINT operations_mode_pkey PRIMARY KEY (id);


--
-- Name: operations operations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operations
    ADD CONSTRAINT operations_pkey PRIMARY KEY (id);


--
-- Name: password_reset_tokens password_reset_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.password_reset_tokens
    ADD CONSTRAINT password_reset_tokens_pkey PRIMARY KEY (email);


--
-- Name: payment_coefficients payment_coefficients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_coefficients
    ADD CONSTRAINT payment_coefficients_pkey PRIMARY KEY (id);


--
-- Name: permission_types permission_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.permission_types
    ADD CONSTRAINT permission_types_pkey PRIMARY KEY (id);


--
-- Name: personal_access_tokens personal_access_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.personal_access_tokens
    ADD CONSTRAINT personal_access_tokens_pkey PRIMARY KEY (id);


--
-- Name: personal_access_tokens personal_access_tokens_token_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.personal_access_tokens
    ADD CONSTRAINT personal_access_tokens_token_unique UNIQUE (token);


--
-- Name: shift_bonuses shift_bonuses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shift_bonuses
    ADD CONSTRAINT shift_bonuses_pkey PRIMARY KEY (id);


--
-- Name: shift_coefficients shift_coefficients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shift_coefficients
    ADD CONSTRAINT shift_coefficients_pkey PRIMARY KEY (id);


--
-- Name: shift_hour_payments shift_hour_payments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shift_hour_payments
    ADD CONSTRAINT shift_hour_payments_pkey PRIMARY KEY (id);


--
-- Name: shifts shifts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shifts
    ADD CONSTRAINT shifts_pkey PRIMARY KEY (id);


--
-- Name: team_leads team_leads_department_id_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.team_leads
    ADD CONSTRAINT team_leads_department_id_unique UNIQUE (department_id);


--
-- Name: team_leads team_leads_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.team_leads
    ADD CONSTRAINT team_leads_pkey PRIMARY KEY (id);


--
-- Name: trusted_workers trusted_workers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trusted_workers
    ADD CONSTRAINT trusted_workers_pkey PRIMARY KEY (id);


--
-- Name: operation_permissions unique_operation; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operation_permissions
    ADD CONSTRAINT unique_operation UNIQUE (operation_id);


--
-- Name: users users_email_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_unique UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: work_day_departments work_day_departments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.work_day_departments
    ADD CONSTRAINT work_day_departments_pkey PRIMARY KEY (id);


--
-- Name: work_day_departments work_day_departments_work_day_id_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.work_day_departments
    ADD CONSTRAINT work_day_departments_work_day_id_unique UNIQUE (work_day_id);


--
-- Name: work_days work_days_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.work_days
    ADD CONSTRAINT work_days_pkey PRIMARY KEY (id);


--
-- Name: work_departments work_departments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.work_departments
    ADD CONSTRAINT work_departments_pkey PRIMARY KEY (id);


--
-- Name: work_permission_requests work_permission_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.work_permission_requests
    ADD CONSTRAINT work_permission_requests_pkey PRIMARY KEY (id);


--
-- Name: work_permission_requests work_permission_requests_work_id_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.work_permission_requests
    ADD CONSTRAINT work_permission_requests_work_id_unique UNIQUE (work_id);


--
-- Name: worker_shifts worker_shifts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.worker_shifts
    ADD CONSTRAINT worker_shifts_pkey PRIMARY KEY (id);


--
-- Name: workers workers_hurma_id_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workers
    ADD CONSTRAINT workers_hurma_id_unique UNIQUE (hurma_id);


--
-- Name: workers workers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workers
    ADD CONSTRAINT workers_pkey PRIMARY KEY (telegram_id);


--
-- Name: workpieces workpieces_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workpieces
    ADD CONSTRAINT workpieces_pkey PRIMARY KEY (id);


--
-- Name: works_average works_average_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.works_average
    ADD CONSTRAINT works_average_pkey PRIMARY KEY (work_id);


--
-- Name: works works_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.works
    ADD CONSTRAINT works_pkey PRIMARY KEY (id);


--
-- Name: admin_operation_log_user_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX admin_operation_log_user_id_index ON public.admin_operation_log USING btree (user_id);


--
-- Name: admin_role_menu_role_id_menu_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX admin_role_menu_role_id_menu_id_index ON public.admin_role_menu USING btree (role_id, menu_id);


--
-- Name: admin_role_permissions_role_id_permission_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX admin_role_permissions_role_id_permission_id_index ON public.admin_role_permissions USING btree (role_id, permission_id);


--
-- Name: admin_role_users_role_id_user_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX admin_role_users_role_id_user_id_index ON public.admin_role_users USING btree (role_id, user_id);


--
-- Name: admin_user_permissions_user_id_permission_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX admin_user_permissions_user_id_permission_id_index ON public.admin_user_permissions USING btree (user_id, permission_id);


--
-- Name: personal_access_tokens_tokenable_type_tokenable_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX personal_access_tokens_tokenable_type_tokenable_id_index ON public.personal_access_tokens USING btree (tokenable_type, tokenable_id);


--
-- Name: works after_delete_work_days_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER after_delete_work_days_trigger AFTER DELETE ON public.works FOR EACH ROW EXECUTE FUNCTION public.delete_works_average();


--
-- Name: works after_delete_work_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER after_delete_work_trigger BEFORE DELETE ON public.works FOR EACH ROW EXECUTE FUNCTION public.delete_works_requests();


--
-- Name: works after_insert_work_days_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER after_insert_work_days_trigger AFTER INSERT ON public.works FOR EACH ROW EXECUTE FUNCTION public.insert_works_average();


--
-- Name: works after_update_work_days_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER after_update_work_days_trigger AFTER UPDATE ON public.works FOR EACH ROW EXECUTE FUNCTION public.update_works_average();


--
-- Name: operations create_archived_opration_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER create_archived_opration_trigger AFTER INSERT ON public.operations FOR EACH ROW EXECUTE FUNCTION public.create_archived_operation();


--
-- Name: operations create_natural_norm_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER create_natural_norm_trigger AFTER INSERT ON public.operations FOR EACH ROW EXECUTE FUNCTION public.create_natural_norm();


--
-- Name: workers create_worker_shift_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER create_worker_shift_trigger AFTER INSERT ON public.workers FOR EACH ROW EXECUTE FUNCTION public.create_worker_shift();


--
-- Name: departments delete_department_references_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER delete_department_references_trigger BEFORE DELETE ON public.departments FOR EACH ROW EXECUTE FUNCTION public.delete_department_references();


--
-- Name: operation_permissions delete_operation_permission_references; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER delete_operation_permission_references BEFORE DELETE ON public.operation_permissions FOR EACH ROW EXECUTE FUNCTION public.delete_operation_permission_references();


--
-- Name: operations delete_operation_references_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER delete_operation_references_trigger BEFORE DELETE ON public.operations FOR EACH ROW EXECUTE FUNCTION public.delete_operation_references();


--
-- Name: shifts delete_shift_references_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER delete_shift_references_trigger BEFORE DELETE ON public.shifts FOR EACH ROW EXECUTE FUNCTION public.delete_shift_references();


--
-- Name: workers delete_worker_refrences_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER delete_worker_refrences_trigger BEFORE DELETE ON public.workers FOR EACH ROW EXECUTE FUNCTION public.delete_worker_references();


--
-- Name: operations insert_operation_version_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER insert_operation_version_trigger AFTER INSERT ON public.operations FOR EACH ROW EXECUTE FUNCTION public.insert_operation_version();


--
-- Name: operations insert_operations_average_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER insert_operations_average_trigger AFTER INSERT ON public.operations FOR EACH ROW EXECUTE FUNCTION public.insert_operations_average();


--
-- Name: operations insert_operations_mode_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER insert_operations_mode_trigger AFTER INSERT ON public.operations FOR EACH ROW EXECUTE FUNCTION public.insert_operations_mode();


--
-- Name: operations operation_normation_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER operation_normation_trigger AFTER UPDATE ON public.operations FOR EACH ROW EXECUTE FUNCTION public.operation_normation();


--
-- Name: works update_after_insert_operations_average_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_after_insert_operations_average_trigger AFTER INSERT ON public.works FOR EACH ROW EXECUTE FUNCTION public.update_operations_average();


--
-- Name: works update_after_update_operations_average_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_after_update_operations_average_trigger AFTER UPDATE ON public.works FOR EACH ROW EXECUTE FUNCTION public.update_operations_average();


--
-- Name: works update_from_old_operations_average_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_from_old_operations_average_trigger AFTER DELETE ON public.works FOR EACH ROW EXECUTE FUNCTION public.update_from_old_operations_average();


--
-- Name: works update_from_old_operations_mode_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_from_old_operations_mode_trigger AFTER DELETE ON public.works FOR EACH ROW EXECUTE FUNCTION public.update_from_old_operations_mode();


--
-- Name: works update_inserted_operations_mode_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_inserted_operations_mode_trigger AFTER INSERT ON public.works FOR EACH ROW EXECUTE FUNCTION public.update_operations_mode();


--
-- Name: operations update_operation_version_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_operation_version_trigger AFTER UPDATE ON public.operations FOR EACH ROW EXECUTE FUNCTION public.update_operation_version();


--
-- Name: works update_updated_operations_mode_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_operations_mode_trigger AFTER UPDATE ON public.works FOR EACH ROW EXECUTE FUNCTION public.update_operations_mode();


--
-- Name: archived_operations archived_operations_operation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.archived_operations
    ADD CONSTRAINT archived_operations_operation_id_fkey FOREIGN KEY (operation_id) REFERENCES public.operations(id);


--
-- Name: calculator_avoided_workers calculator_avoided_workers_worker_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calculator_avoided_workers
    ADD CONSTRAINT calculator_avoided_workers_worker_id_fkey FOREIGN KEY (worker_id) REFERENCES public.workers(telegram_id) ON DELETE CASCADE;


--
-- Name: department_groups department_groups_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.department_groups
    ADD CONSTRAINT department_groups_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.departments(id);


--
-- Name: department_groups department_groups_report_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.department_groups
    ADD CONSTRAINT department_groups_report_type_id_fkey FOREIGN KEY (report_type_id) REFERENCES public.department_report_types(id);


--
-- Name: team_leads department_heads_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.team_leads
    ADD CONSTRAINT department_heads_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.departments(id);


--
-- Name: team_leads department_heads_worker_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.team_leads
    ADD CONSTRAINT department_heads_worker_id_fkey FOREIGN KEY (worker_id) REFERENCES public.workers(telegram_id);


--
-- Name: work_days fk_bonus_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.work_days
    ADD CONSTRAINT fk_bonus_id FOREIGN KEY (bonus_id) REFERENCES public.bonuses(id);


--
-- Name: works_average fk_work_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.works_average
    ADD CONSTRAINT fk_work_id FOREIGN KEY (work_id) REFERENCES public.works(id) ON DELETE CASCADE;


--
-- Name: module_operation module_operation_module_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.module_operation
    ADD CONSTRAINT module_operation_module_id_fkey FOREIGN KEY (module_id) REFERENCES public.modules(id) ON DELETE CASCADE;


--
-- Name: module_operation module_operation_operation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.module_operation
    ADD CONSTRAINT module_operation_operation_id_fkey FOREIGN KEY (operation_id) REFERENCES public.operations(id) ON DELETE CASCADE;


--
-- Name: natural_operations natural_operations_operation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.natural_operations
    ADD CONSTRAINT natural_operations_operation_id_fkey FOREIGN KEY (operation_id) REFERENCES public.operations(id);


--
-- Name: operation_feedstocks operation_feedstocks_operation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operation_feedstocks
    ADD CONSTRAINT operation_feedstocks_operation_id_fkey FOREIGN KEY (operation_id) REFERENCES public.operations(id);


--
-- Name: operation_feedstocks operation_feedstocks_workpiece_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operation_feedstocks
    ADD CONSTRAINT operation_feedstocks_workpiece_id_fkey FOREIGN KEY (workpiece_id) REFERENCES public.workpieces(id);


--
-- Name: operation_permissions operation_permissions_operation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operation_permissions
    ADD CONSTRAINT operation_permissions_operation_id_fkey FOREIGN KEY (operation_id) REFERENCES public.operations(id);


--
-- Name: operation_permissions operation_permissions_permission_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operation_permissions
    ADD CONSTRAINT operation_permissions_permission_type_id_fkey FOREIGN KEY (permission_type_id) REFERENCES public.permission_types(id) ON DELETE CASCADE;


--
-- Name: operation_results operation_results_operation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operation_results
    ADD CONSTRAINT operation_results_operation_id_fkey FOREIGN KEY (operation_id) REFERENCES public.operations(id);


--
-- Name: operation_results operation_results_workpiece_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operation_results
    ADD CONSTRAINT operation_results_workpiece_id_fkey FOREIGN KEY (workpiece_id) REFERENCES public.workpieces(id);


--
-- Name: operation_versions operation_versions_operation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operation_versions
    ADD CONSTRAINT operation_versions_operation_id_fkey FOREIGN KEY (operation_id) REFERENCES public.operations(id);


--
-- Name: operations_average operations_average_operation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operations_average
    ADD CONSTRAINT operations_average_operation_id_fkey FOREIGN KEY (operation_id) REFERENCES public.operations(id) ON DELETE CASCADE;


--
-- Name: operations operations_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operations
    ADD CONSTRAINT operations_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.departments(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: operations_mode operations_mode_operation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operations_mode
    ADD CONSTRAINT operations_mode_operation_id_fkey FOREIGN KEY (operation_id) REFERENCES public.operations(id) ON DELETE CASCADE;


--
-- Name: shift_bonuses shift_bonuses_bonus_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shift_bonuses
    ADD CONSTRAINT shift_bonuses_bonus_id_fkey FOREIGN KEY (bonus_id) REFERENCES public.bonuses(id);


--
-- Name: shift_bonuses shift_bonuses_shift_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shift_bonuses
    ADD CONSTRAINT shift_bonuses_shift_id_fkey FOREIGN KEY (shift_id) REFERENCES public.shifts(id);


--
-- Name: shift_coefficients shift_coefficients_coefficient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shift_coefficients
    ADD CONSTRAINT shift_coefficients_coefficient_id_fkey FOREIGN KEY (coefficient_id) REFERENCES public.payment_coefficients(id);


--
-- Name: shift_coefficients shift_coefficients_shift_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shift_coefficients
    ADD CONSTRAINT shift_coefficients_shift_id_fkey FOREIGN KEY (shift_id) REFERENCES public.shifts(id);


--
-- Name: shift_hour_payments shift_hour_payments_payment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shift_hour_payments
    ADD CONSTRAINT shift_hour_payments_payment_id_fkey FOREIGN KEY (payment_id) REFERENCES public.hour_payments(id) ON DELETE CASCADE;


--
-- Name: shift_hour_payments shift_hour_payments_shift_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shift_hour_payments
    ADD CONSTRAINT shift_hour_payments_shift_id_fkey FOREIGN KEY (shift_id) REFERENCES public.shifts(id) ON DELETE CASCADE;


--
-- Name: shifts shifts_department_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shifts
    ADD CONSTRAINT shifts_department_id_foreign FOREIGN KEY (department_id) REFERENCES public.departments(id);


--
-- Name: team_leads team_leads_admin_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.team_leads
    ADD CONSTRAINT team_leads_admin_user_id_fkey FOREIGN KEY (admin_user_id) REFERENCES public.admin_users(id);


--
-- Name: trusted_workers trusted_workers_op_permission_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trusted_workers
    ADD CONSTRAINT trusted_workers_op_permission_id_fkey FOREIGN KEY (op_permission_id) REFERENCES public.operation_permissions(id);


--
-- Name: trusted_workers trusted_workers_worker_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trusted_workers
    ADD CONSTRAINT trusted_workers_worker_id_fkey FOREIGN KEY (worker_id) REFERENCES public.workers(telegram_id);


--
-- Name: work_day_departments work_day_departments_department_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.work_day_departments
    ADD CONSTRAINT work_day_departments_department_id_foreign FOREIGN KEY (department_id) REFERENCES public.departments(id) ON DELETE SET NULL;


--
-- Name: work_day_departments work_day_departments_work_day_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.work_day_departments
    ADD CONSTRAINT work_day_departments_work_day_id_foreign FOREIGN KEY (work_day_id) REFERENCES public.work_days(id) ON DELETE CASCADE;


--
-- Name: work_days work_days_worker_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.work_days
    ADD CONSTRAINT work_days_worker_id_fkey FOREIGN KEY (worker_id) REFERENCES public.workers(telegram_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: work_departments work_departments_department_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.work_departments
    ADD CONSTRAINT work_departments_department_id_foreign FOREIGN KEY (department_id) REFERENCES public.departments(id);


--
-- Name: work_departments work_departments_work_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.work_departments
    ADD CONSTRAINT work_departments_work_id_foreign FOREIGN KEY (work_id) REFERENCES public.works(id);


--
-- Name: work_permission_requests work_permission_requests_work_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.work_permission_requests
    ADD CONSTRAINT work_permission_requests_work_id_foreign FOREIGN KEY (work_id) REFERENCES public.works(id);


--
-- Name: worker_shifts worker_shifts_secondary_shift_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.worker_shifts
    ADD CONSTRAINT worker_shifts_secondary_shift_id_foreign FOREIGN KEY (secondary_shift_id) REFERENCES public.shifts(id);


--
-- Name: worker_shifts worker_shifts_shift_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.worker_shifts
    ADD CONSTRAINT worker_shifts_shift_id_fkey FOREIGN KEY (shift_id) REFERENCES public.shifts(id);


--
-- Name: worker_shifts worker_shifts_worker_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.worker_shifts
    ADD CONSTRAINT worker_shifts_worker_id_fkey FOREIGN KEY (worker_id) REFERENCES public.workers(telegram_id);


--
-- Name: works_average works_average_operation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.works_average
    ADD CONSTRAINT works_average_operation_id_fkey FOREIGN KEY (operation_id) REFERENCES public.operations(id);


--
-- Name: works works_operation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.works
    ADD CONSTRAINT works_operation_id_fkey FOREIGN KEY (operation_id) REFERENCES public.operations(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: works works_work_day_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.works
    ADD CONSTRAINT works_work_day_id_fkey FOREIGN KEY (work_day_id) REFERENCES public.work_days(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict jrV11hbygwNBetvgvZHBQMer4kO3yr4l8MWNOJ9ldFjQ1vd1eLxvqGohd2zZawk

