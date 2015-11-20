--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'SQL_ASCII';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

--
-- Name: mediawiki; Type: SCHEMA; Schema: -; Owner: wikiuser
--

CREATE SCHEMA mediawiki;


ALTER SCHEMA mediawiki OWNER TO wikiuser;

--
-- Name: plpgsql; Type: PROCEDURAL LANGUAGE; Schema: -; Owner: wikiuser
--

CREATE PROCEDURAL LANGUAGE plpgsql;


ALTER PROCEDURAL LANGUAGE plpgsql OWNER TO wikiuser;

SET search_path = mediawiki, pg_catalog;

--
-- Name: add_interwiki(text, integer, smallint); Type: FUNCTION; Schema: mediawiki; Owner: wikiuser
--

CREATE FUNCTION add_interwiki(text, integer, smallint) RETURNS integer
    LANGUAGE sql
    AS $_$
 INSERT INTO interwiki (iw_prefix, iw_url, iw_local) VALUES ($1,$2,$3);
 SELECT 1;
 $_$;


ALTER FUNCTION mediawiki.add_interwiki(text, integer, smallint) OWNER TO wikiuser;

--
-- Name: page_deleted(); Type: FUNCTION; Schema: mediawiki; Owner: wikiuser
--

CREATE FUNCTION page_deleted() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
 BEGIN
 DELETE FROM recentchanges WHERE rc_namespace = OLD.page_namespace AND rc_title = OLD.page_title;
 RETURN NULL;
 END;
 $$;


ALTER FUNCTION mediawiki.page_deleted() OWNER TO wikiuser;

--
-- Name: ts2_page_text(); Type: FUNCTION; Schema: mediawiki; Owner: wikiuser
--

CREATE FUNCTION ts2_page_text() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
 BEGIN
 IF TG_OP = 'INSERT' THEN
 NEW.textvector = to_tsvector(NEW.old_text);
 ELSIF NEW.old_text != OLD.old_text THEN
 NEW.textvector := to_tsvector(NEW.old_text);
 END IF;
 RETURN NEW;
 END;
 $$;


ALTER FUNCTION mediawiki.ts2_page_text() OWNER TO wikiuser;

--
-- Name: ts2_page_title(); Type: FUNCTION; Schema: mediawiki; Owner: wikiuser
--

CREATE FUNCTION ts2_page_title() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
 BEGIN
 IF TG_OP = 'INSERT' THEN
 NEW.titlevector = to_tsvector(REPLACE(NEW.page_title,'/',' '));
 ELSIF NEW.page_title != OLD.page_title THEN
 NEW.titlevector := to_tsvector(REPLACE(NEW.page_title,'/',' '));
 END IF;
 RETURN NEW;
 END;
 $$;


ALTER FUNCTION mediawiki.ts2_page_title() OWNER TO wikiuser;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: archive; Type: TABLE; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE TABLE archive (
    ar_namespace smallint NOT NULL,
    ar_title text NOT NULL,
    ar_text text,
    ar_page_id integer,
    ar_parent_id integer,
    ar_comment text,
    ar_user integer,
    ar_user_text text NOT NULL,
    ar_timestamp timestamp with time zone NOT NULL,
    ar_minor_edit smallint DEFAULT 0 NOT NULL,
    ar_flags text,
    ar_rev_id integer,
    ar_text_id integer,
    ar_deleted smallint DEFAULT 0 NOT NULL,
    ar_len integer
);


ALTER TABLE mediawiki.archive OWNER TO wikiuser;

--
-- Name: category_id_seq; Type: SEQUENCE; Schema: mediawiki; Owner: wikiuser
--

CREATE SEQUENCE category_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE mediawiki.category_id_seq OWNER TO wikiuser;

--
-- Name: category_id_seq; Type: SEQUENCE SET; Schema: mediawiki; Owner: wikiuser
--

SELECT pg_catalog.setval('category_id_seq', 1, false);


--
-- Name: category; Type: TABLE; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE TABLE category (
    cat_id integer DEFAULT nextval('category_id_seq'::regclass) NOT NULL,
    cat_title text NOT NULL,
    cat_pages integer DEFAULT 0 NOT NULL,
    cat_subcats integer DEFAULT 0 NOT NULL,
    cat_files integer DEFAULT 0 NOT NULL,
    cat_hidden smallint DEFAULT 0 NOT NULL
);


ALTER TABLE mediawiki.category OWNER TO wikiuser;

--
-- Name: categorylinks; Type: TABLE; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE TABLE categorylinks (
    cl_from integer NOT NULL,
    cl_to text NOT NULL,
    cl_sortkey text,
    cl_timestamp timestamp with time zone NOT NULL
);


ALTER TABLE mediawiki.categorylinks OWNER TO wikiuser;

--
-- Name: change_tag; Type: TABLE; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE TABLE change_tag (
    ct_rc_id integer,
    ct_log_id integer,
    ct_rev_id integer,
    ct_tag text NOT NULL,
    ct_params text
);


ALTER TABLE mediawiki.change_tag OWNER TO wikiuser;

--
-- Name: externallinks; Type: TABLE; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE TABLE externallinks (
    el_from integer NOT NULL,
    el_to text NOT NULL,
    el_index text NOT NULL
);


ALTER TABLE mediawiki.externallinks OWNER TO wikiuser;

--
-- Name: filearchive_fa_id_seq; Type: SEQUENCE; Schema: mediawiki; Owner: wikiuser
--

CREATE SEQUENCE filearchive_fa_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE mediawiki.filearchive_fa_id_seq OWNER TO wikiuser;

--
-- Name: filearchive_fa_id_seq; Type: SEQUENCE SET; Schema: mediawiki; Owner: wikiuser
--

SELECT pg_catalog.setval('filearchive_fa_id_seq', 1, false);


--
-- Name: filearchive; Type: TABLE; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE TABLE filearchive (
    fa_id integer DEFAULT nextval('filearchive_fa_id_seq'::regclass) NOT NULL,
    fa_name text NOT NULL,
    fa_archive_name text,
    fa_storage_group text,
    fa_storage_key text,
    fa_deleted_user integer,
    fa_deleted_timestamp timestamp with time zone NOT NULL,
    fa_deleted_reason text,
    fa_size integer NOT NULL,
    fa_width integer NOT NULL,
    fa_height integer NOT NULL,
    fa_metadata bytea DEFAULT ''::bytea NOT NULL,
    fa_bits smallint,
    fa_media_type text,
    fa_major_mime text DEFAULT 'unknown'::text,
    fa_minor_mime text DEFAULT 'unknown'::text,
    fa_description text NOT NULL,
    fa_user integer,
    fa_user_text text NOT NULL,
    fa_timestamp timestamp with time zone,
    fa_deleted smallint DEFAULT 0 NOT NULL
);


ALTER TABLE mediawiki.filearchive OWNER TO wikiuser;

--
-- Name: hitcounter; Type: TABLE; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE TABLE hitcounter (
    hc_id bigint NOT NULL
);


ALTER TABLE mediawiki.hitcounter OWNER TO wikiuser;

--
-- Name: image; Type: TABLE; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE TABLE image (
    img_name text NOT NULL,
    img_size integer NOT NULL,
    img_width integer NOT NULL,
    img_height integer NOT NULL,
    img_metadata bytea DEFAULT ''::bytea NOT NULL,
    img_bits smallint,
    img_media_type text,
    img_major_mime text DEFAULT 'unknown'::text,
    img_minor_mime text DEFAULT 'unknown'::text,
    img_description text NOT NULL,
    img_user integer,
    img_user_text text NOT NULL,
    img_timestamp timestamp with time zone,
    img_sha1 text DEFAULT ''::text NOT NULL
);


ALTER TABLE mediawiki.image OWNER TO wikiuser;

--
-- Name: imagelinks; Type: TABLE; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE TABLE imagelinks (
    il_from integer NOT NULL,
    il_to text NOT NULL
);


ALTER TABLE mediawiki.imagelinks OWNER TO wikiuser;

--
-- Name: interwiki; Type: TABLE; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE TABLE interwiki (
    iw_prefix text NOT NULL,
    iw_url text NOT NULL,
    iw_local smallint NOT NULL,
    iw_trans smallint DEFAULT 0 NOT NULL
);


ALTER TABLE mediawiki.interwiki OWNER TO wikiuser;

--
-- Name: ipblocks_ipb_id_val; Type: SEQUENCE; Schema: mediawiki; Owner: wikiuser
--

CREATE SEQUENCE ipblocks_ipb_id_val
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE mediawiki.ipblocks_ipb_id_val OWNER TO wikiuser;

--
-- Name: ipblocks_ipb_id_val; Type: SEQUENCE SET; Schema: mediawiki; Owner: wikiuser
--

SELECT pg_catalog.setval('ipblocks_ipb_id_val', 1, false);


--
-- Name: ipblocks; Type: TABLE; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE TABLE ipblocks (
    ipb_id integer DEFAULT nextval('ipblocks_ipb_id_val'::regclass) NOT NULL,
    ipb_address text,
    ipb_user integer,
    ipb_by integer NOT NULL,
    ipb_by_text text DEFAULT ''::text NOT NULL,
    ipb_reason text NOT NULL,
    ipb_timestamp timestamp with time zone NOT NULL,
    ipb_auto smallint DEFAULT 0 NOT NULL,
    ipb_anon_only smallint DEFAULT 0 NOT NULL,
    ipb_create_account smallint DEFAULT 1 NOT NULL,
    ipb_enable_autoblock smallint DEFAULT 1 NOT NULL,
    ipb_expiry timestamp with time zone NOT NULL,
    ipb_range_start text,
    ipb_range_end text,
    ipb_deleted smallint DEFAULT 0 NOT NULL,
    ipb_block_email smallint DEFAULT 0 NOT NULL,
    ipb_allow_usertalk smallint DEFAULT 0 NOT NULL
);


ALTER TABLE mediawiki.ipblocks OWNER TO wikiuser;

--
-- Name: job_job_id_seq; Type: SEQUENCE; Schema: mediawiki; Owner: wikiuser
--

CREATE SEQUENCE job_job_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE mediawiki.job_job_id_seq OWNER TO wikiuser;

--
-- Name: job_job_id_seq; Type: SEQUENCE SET; Schema: mediawiki; Owner: wikiuser
--

SELECT pg_catalog.setval('job_job_id_seq', 1, false);


--
-- Name: job; Type: TABLE; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE TABLE job (
    job_id integer DEFAULT nextval('job_job_id_seq'::regclass) NOT NULL,
    job_cmd text NOT NULL,
    job_namespace smallint NOT NULL,
    job_title text NOT NULL,
    job_params text NOT NULL
);


ALTER TABLE mediawiki.job OWNER TO wikiuser;

--
-- Name: langlinks; Type: TABLE; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE TABLE langlinks (
    ll_from integer NOT NULL,
    ll_lang text,
    ll_title text
);


ALTER TABLE mediawiki.langlinks OWNER TO wikiuser;

--
-- Name: log_log_id_seq; Type: SEQUENCE; Schema: mediawiki; Owner: wikiuser
--

CREATE SEQUENCE log_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE mediawiki.log_log_id_seq OWNER TO wikiuser;

--
-- Name: log_log_id_seq; Type: SEQUENCE SET; Schema: mediawiki; Owner: wikiuser
--

SELECT pg_catalog.setval('log_log_id_seq', 1, false);


--
-- Name: logging; Type: TABLE; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE TABLE logging (
    log_id integer DEFAULT nextval('log_log_id_seq'::regclass) NOT NULL,
    log_type text NOT NULL,
    log_action text NOT NULL,
    log_timestamp timestamp with time zone NOT NULL,
    log_user integer,
    log_namespace smallint NOT NULL,
    log_title text NOT NULL,
    log_comment text,
    log_params text,
    log_deleted smallint DEFAULT 0 NOT NULL
);


ALTER TABLE mediawiki.logging OWNER TO wikiuser;

--
-- Name: math; Type: TABLE; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE TABLE math (
    math_inputhash bytea NOT NULL,
    math_outputhash bytea NOT NULL,
    math_html_conservativeness smallint NOT NULL,
    math_html text,
    math_mathml text
);


ALTER TABLE mediawiki.math OWNER TO wikiuser;

--
-- Name: mediawiki_version; Type: TABLE; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE TABLE mediawiki_version (
    type text NOT NULL,
    mw_version text NOT NULL,
    notes text,
    pg_version text,
    pg_dbname text,
    pg_user text,
    pg_port text,
    mw_schema text,
    ts2_schema text,
    ctype text,
    sql_version text,
    sql_date text,
    cdate timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE mediawiki.mediawiki_version OWNER TO wikiuser;

--
-- Name: user_user_id_seq; Type: SEQUENCE; Schema: mediawiki; Owner: wikiuser
--

CREATE SEQUENCE user_user_id_seq
    START WITH 0
    INCREMENT BY 1
    NO MAXVALUE
    MINVALUE 0
    CACHE 1;


ALTER TABLE mediawiki.user_user_id_seq OWNER TO wikiuser;

--
-- Name: user_user_id_seq; Type: SEQUENCE SET; Schema: mediawiki; Owner: wikiuser
--

SELECT pg_catalog.setval('user_user_id_seq', 1, true);


--
-- Name: mwuser; Type: TABLE; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE TABLE mwuser (
    user_id integer DEFAULT nextval('user_user_id_seq'::regclass) NOT NULL,
    user_name text NOT NULL,
    user_real_name text,
    user_password text,
    user_newpassword text,
    user_newpass_time timestamp with time zone,
    user_token text,
    user_email text,
    user_email_token text,
    user_email_token_expires timestamp with time zone,
    user_email_authenticated timestamp with time zone,
    user_options text,
    user_touched timestamp with time zone,
    user_registration timestamp with time zone,
    user_editcount integer
);


ALTER TABLE mediawiki.mwuser OWNER TO wikiuser;

--
-- Name: objectcache; Type: TABLE; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE TABLE objectcache (
    keyname text,
    value bytea DEFAULT ''::bytea NOT NULL,
    exptime timestamp with time zone NOT NULL
);


ALTER TABLE mediawiki.objectcache OWNER TO wikiuser;

--
-- Name: oldimage; Type: TABLE; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE TABLE oldimage (
    oi_name text NOT NULL,
    oi_archive_name text NOT NULL,
    oi_size integer NOT NULL,
    oi_width integer NOT NULL,
    oi_height integer NOT NULL,
    oi_bits smallint,
    oi_description text,
    oi_user integer,
    oi_user_text text NOT NULL,
    oi_timestamp timestamp with time zone,
    oi_metadata bytea DEFAULT ''::bytea NOT NULL,
    oi_media_type text,
    oi_major_mime text DEFAULT 'unknown'::text,
    oi_minor_mime text DEFAULT 'unknown'::text,
    oi_deleted smallint DEFAULT 0 NOT NULL,
    oi_sha1 text DEFAULT ''::text NOT NULL
);


ALTER TABLE mediawiki.oldimage OWNER TO wikiuser;

--
-- Name: page_page_id_seq; Type: SEQUENCE; Schema: mediawiki; Owner: wikiuser
--

CREATE SEQUENCE page_page_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE mediawiki.page_page_id_seq OWNER TO wikiuser;

--
-- Name: page_page_id_seq; Type: SEQUENCE SET; Schema: mediawiki; Owner: wikiuser
--

SELECT pg_catalog.setval('page_page_id_seq', 2, true);


--
-- Name: page; Type: TABLE; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE TABLE page (
    page_id integer DEFAULT nextval('page_page_id_seq'::regclass) NOT NULL,
    page_namespace smallint NOT NULL,
    page_title text NOT NULL,
    page_restrictions text,
    page_counter bigint DEFAULT 0 NOT NULL,
    page_is_redirect smallint DEFAULT 0 NOT NULL,
    page_is_new smallint DEFAULT 0 NOT NULL,
    page_random numeric(15,14) DEFAULT random() NOT NULL,
    page_touched timestamp with time zone,
    page_latest integer NOT NULL,
    page_len integer NOT NULL,
    titlevector tsvector
);


ALTER TABLE mediawiki.page OWNER TO wikiuser;

--
-- Name: page_props; Type: TABLE; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE TABLE page_props (
    pp_page integer NOT NULL,
    pp_propname text NOT NULL,
    pp_value text NOT NULL
);


ALTER TABLE mediawiki.page_props OWNER TO wikiuser;

--
-- Name: pr_id_val; Type: SEQUENCE; Schema: mediawiki; Owner: wikiuser
--

CREATE SEQUENCE pr_id_val
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE mediawiki.pr_id_val OWNER TO wikiuser;

--
-- Name: pr_id_val; Type: SEQUENCE SET; Schema: mediawiki; Owner: wikiuser
--

SELECT pg_catalog.setval('pr_id_val', 1, false);


--
-- Name: page_restrictions; Type: TABLE; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE TABLE page_restrictions (
    pr_id integer DEFAULT nextval('pr_id_val'::regclass) NOT NULL,
    pr_page integer NOT NULL,
    pr_type text NOT NULL,
    pr_level text NOT NULL,
    pr_cascade smallint NOT NULL,
    pr_user integer,
    pr_expiry timestamp with time zone
);


ALTER TABLE mediawiki.page_restrictions OWNER TO wikiuser;

--
-- Name: text_old_id_val; Type: SEQUENCE; Schema: mediawiki; Owner: wikiuser
--

CREATE SEQUENCE text_old_id_val
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE mediawiki.text_old_id_val OWNER TO wikiuser;

--
-- Name: text_old_id_val; Type: SEQUENCE SET; Schema: mediawiki; Owner: wikiuser
--

SELECT pg_catalog.setval('text_old_id_val', 2, true);


--
-- Name: pagecontent; Type: TABLE; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE TABLE pagecontent (
    old_id integer DEFAULT nextval('text_old_id_val'::regclass) NOT NULL,
    old_text text,
    old_flags text,
    textvector tsvector
);


ALTER TABLE mediawiki.pagecontent OWNER TO wikiuser;

--
-- Name: pagelinks; Type: TABLE; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE TABLE pagelinks (
    pl_from integer NOT NULL,
    pl_namespace smallint NOT NULL,
    pl_title text NOT NULL
);


ALTER TABLE mediawiki.pagelinks OWNER TO wikiuser;

--
-- Name: profiling; Type: TABLE; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE TABLE profiling (
    pf_count integer DEFAULT 0 NOT NULL,
    pf_time numeric(18,10) DEFAULT 0 NOT NULL,
    pf_memory numeric(18,10) DEFAULT 0 NOT NULL,
    pf_name text NOT NULL,
    pf_server text
);


ALTER TABLE mediawiki.profiling OWNER TO wikiuser;

--
-- Name: protected_titles; Type: TABLE; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE TABLE protected_titles (
    pt_namespace smallint NOT NULL,
    pt_title text NOT NULL,
    pt_user integer,
    pt_reason text,
    pt_timestamp timestamp with time zone NOT NULL,
    pt_expiry timestamp with time zone,
    pt_create_perm text DEFAULT ''::text NOT NULL
);


ALTER TABLE mediawiki.protected_titles OWNER TO wikiuser;

--
-- Name: querycache; Type: TABLE; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE TABLE querycache (
    qc_type text NOT NULL,
    qc_value integer NOT NULL,
    qc_namespace smallint NOT NULL,
    qc_title text NOT NULL
);


ALTER TABLE mediawiki.querycache OWNER TO wikiuser;

--
-- Name: querycache_info; Type: TABLE; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE TABLE querycache_info (
    qci_type text,
    qci_timestamp timestamp with time zone
);


ALTER TABLE mediawiki.querycache_info OWNER TO wikiuser;

--
-- Name: querycachetwo; Type: TABLE; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE TABLE querycachetwo (
    qcc_type text NOT NULL,
    qcc_value integer DEFAULT 0 NOT NULL,
    qcc_namespace integer DEFAULT 0 NOT NULL,
    qcc_title text DEFAULT ''::text NOT NULL,
    qcc_namespacetwo integer DEFAULT 0 NOT NULL,
    qcc_titletwo text DEFAULT ''::text NOT NULL
);


ALTER TABLE mediawiki.querycachetwo OWNER TO wikiuser;

--
-- Name: rc_rc_id_seq; Type: SEQUENCE; Schema: mediawiki; Owner: wikiuser
--

CREATE SEQUENCE rc_rc_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE mediawiki.rc_rc_id_seq OWNER TO wikiuser;

--
-- Name: rc_rc_id_seq; Type: SEQUENCE SET; Schema: mediawiki; Owner: wikiuser
--

SELECT pg_catalog.setval('rc_rc_id_seq', 1, false);


--
-- Name: recentchanges; Type: TABLE; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE TABLE recentchanges (
    rc_id integer DEFAULT nextval('rc_rc_id_seq'::regclass) NOT NULL,
    rc_timestamp timestamp with time zone NOT NULL,
    rc_cur_time timestamp with time zone NOT NULL,
    rc_user integer,
    rc_user_text text NOT NULL,
    rc_namespace smallint NOT NULL,
    rc_title text NOT NULL,
    rc_comment text,
    rc_minor smallint DEFAULT 0 NOT NULL,
    rc_bot smallint DEFAULT 0 NOT NULL,
    rc_new smallint DEFAULT 0 NOT NULL,
    rc_cur_id integer,
    rc_this_oldid integer NOT NULL,
    rc_last_oldid integer NOT NULL,
    rc_type smallint DEFAULT 0 NOT NULL,
    rc_moved_to_ns smallint,
    rc_moved_to_title text,
    rc_patrolled smallint DEFAULT 0 NOT NULL,
    rc_ip cidr,
    rc_old_len integer,
    rc_new_len integer,
    rc_deleted smallint DEFAULT 0 NOT NULL,
    rc_logid integer DEFAULT 0 NOT NULL,
    rc_log_type text,
    rc_log_action text,
    rc_params text
);


ALTER TABLE mediawiki.recentchanges OWNER TO wikiuser;

--
-- Name: redirect; Type: TABLE; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE TABLE redirect (
    rd_from integer NOT NULL,
    rd_namespace smallint NOT NULL,
    rd_title text NOT NULL
);


ALTER TABLE mediawiki.redirect OWNER TO wikiuser;

--
-- Name: rev_rev_id_val; Type: SEQUENCE; Schema: mediawiki; Owner: wikiuser
--

CREATE SEQUENCE rev_rev_id_val
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE mediawiki.rev_rev_id_val OWNER TO wikiuser;

--
-- Name: rev_rev_id_val; Type: SEQUENCE SET; Schema: mediawiki; Owner: wikiuser
--

SELECT pg_catalog.setval('rev_rev_id_val', 2, true);


--
-- Name: revision; Type: TABLE; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE TABLE revision (
    rev_id integer DEFAULT nextval('rev_rev_id_val'::regclass) NOT NULL,
    rev_page integer,
    rev_text_id integer,
    rev_comment text,
    rev_user integer NOT NULL,
    rev_user_text text NOT NULL,
    rev_timestamp timestamp with time zone NOT NULL,
    rev_minor_edit smallint DEFAULT 0 NOT NULL,
    rev_deleted smallint DEFAULT 0 NOT NULL,
    rev_len integer,
    rev_parent_id integer
);


ALTER TABLE mediawiki.revision OWNER TO wikiuser;

--
-- Name: site_stats; Type: TABLE; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE TABLE site_stats (
    ss_row_id integer NOT NULL,
    ss_total_views integer DEFAULT 0,
    ss_total_edits integer DEFAULT 0,
    ss_good_articles integer DEFAULT 0,
    ss_total_pages integer DEFAULT (-1),
    ss_users integer DEFAULT (-1),
    ss_active_users integer DEFAULT (-1),
    ss_admins integer DEFAULT (-1),
    ss_images integer DEFAULT 0
);


ALTER TABLE mediawiki.site_stats OWNER TO wikiuser;

--
-- Name: tag_summary; Type: TABLE; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE TABLE tag_summary (
    ts_rc_id integer,
    ts_log_id integer,
    ts_rev_id integer,
    ts_tags text NOT NULL
);


ALTER TABLE mediawiki.tag_summary OWNER TO wikiuser;

--
-- Name: templatelinks; Type: TABLE; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE TABLE templatelinks (
    tl_from integer NOT NULL,
    tl_namespace smallint NOT NULL,
    tl_title text NOT NULL
);


ALTER TABLE mediawiki.templatelinks OWNER TO wikiuser;

--
-- Name: trackbacks_tb_id_seq; Type: SEQUENCE; Schema: mediawiki; Owner: wikiuser
--

CREATE SEQUENCE trackbacks_tb_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE mediawiki.trackbacks_tb_id_seq OWNER TO wikiuser;

--
-- Name: trackbacks_tb_id_seq; Type: SEQUENCE SET; Schema: mediawiki; Owner: wikiuser
--

SELECT pg_catalog.setval('trackbacks_tb_id_seq', 1, false);


--
-- Name: trackbacks; Type: TABLE; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE TABLE trackbacks (
    tb_id integer DEFAULT nextval('trackbacks_tb_id_seq'::regclass) NOT NULL,
    tb_page integer,
    tb_title text NOT NULL,
    tb_url text NOT NULL,
    tb_ex text,
    tb_name text
);


ALTER TABLE mediawiki.trackbacks OWNER TO wikiuser;

--
-- Name: transcache; Type: TABLE; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE TABLE transcache (
    tc_url text NOT NULL,
    tc_contents text NOT NULL,
    tc_time timestamp with time zone NOT NULL
);


ALTER TABLE mediawiki.transcache OWNER TO wikiuser;

--
-- Name: updatelog; Type: TABLE; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE TABLE updatelog (
    ul_key text NOT NULL
);


ALTER TABLE mediawiki.updatelog OWNER TO wikiuser;

--
-- Name: user_groups; Type: TABLE; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE TABLE user_groups (
    ug_user integer,
    ug_group text NOT NULL
);


ALTER TABLE mediawiki.user_groups OWNER TO wikiuser;

--
-- Name: user_newtalk; Type: TABLE; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE TABLE user_newtalk (
    user_id integer NOT NULL,
    user_ip text,
    user_last_timestamp timestamp with time zone
);


ALTER TABLE mediawiki.user_newtalk OWNER TO wikiuser;

--
-- Name: valid_tag; Type: TABLE; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE TABLE valid_tag (
    vt_tag text NOT NULL
);


ALTER TABLE mediawiki.valid_tag OWNER TO wikiuser;

--
-- Name: watchlist; Type: TABLE; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE TABLE watchlist (
    wl_user integer NOT NULL,
    wl_namespace smallint DEFAULT 0 NOT NULL,
    wl_title text NOT NULL,
    wl_notificationtimestamp timestamp with time zone
);


ALTER TABLE mediawiki.watchlist OWNER TO wikiuser;

--
-- Data for Name: archive; Type: TABLE DATA; Schema: mediawiki; Owner: wikiuser
--

COPY archive (ar_namespace, ar_title, ar_text, ar_page_id, ar_parent_id, ar_comment, ar_user, ar_user_text, ar_timestamp, ar_minor_edit, ar_flags, ar_rev_id, ar_text_id, ar_deleted, ar_len) FROM stdin;
\.


--
-- Data for Name: category; Type: TABLE DATA; Schema: mediawiki; Owner: wikiuser
--

COPY category (cat_id, cat_title, cat_pages, cat_subcats, cat_files, cat_hidden) FROM stdin;
\.


--
-- Data for Name: categorylinks; Type: TABLE DATA; Schema: mediawiki; Owner: wikiuser
--

COPY categorylinks (cl_from, cl_to, cl_sortkey, cl_timestamp) FROM stdin;
\.


--
-- Data for Name: change_tag; Type: TABLE DATA; Schema: mediawiki; Owner: wikiuser
--

COPY change_tag (ct_rc_id, ct_log_id, ct_rev_id, ct_tag, ct_params) FROM stdin;
\.


--
-- Data for Name: externallinks; Type: TABLE DATA; Schema: mediawiki; Owner: wikiuser
--

COPY externallinks (el_from, el_to, el_index) FROM stdin;
\.


--
-- Data for Name: filearchive; Type: TABLE DATA; Schema: mediawiki; Owner: wikiuser
--

COPY filearchive (fa_id, fa_name, fa_archive_name, fa_storage_group, fa_storage_key, fa_deleted_user, fa_deleted_timestamp, fa_deleted_reason, fa_size, fa_width, fa_height, fa_metadata, fa_bits, fa_media_type, fa_major_mime, fa_minor_mime, fa_description, fa_user, fa_user_text, fa_timestamp, fa_deleted) FROM stdin;
\.


--
-- Data for Name: hitcounter; Type: TABLE DATA; Schema: mediawiki; Owner: wikiuser
--

COPY hitcounter (hc_id) FROM stdin;
\.


--
-- Data for Name: image; Type: TABLE DATA; Schema: mediawiki; Owner: wikiuser
--

COPY image (img_name, img_size, img_width, img_height, img_metadata, img_bits, img_media_type, img_major_mime, img_minor_mime, img_description, img_user, img_user_text, img_timestamp, img_sha1) FROM stdin;
\.


--
-- Data for Name: imagelinks; Type: TABLE DATA; Schema: mediawiki; Owner: wikiuser
--

COPY imagelinks (il_from, il_to) FROM stdin;
\.


--
-- Data for Name: interwiki; Type: TABLE DATA; Schema: mediawiki; Owner: wikiuser
--

COPY interwiki (iw_prefix, iw_url, iw_local, iw_trans) FROM stdin;
acronym	http://www.acronymfinder.com/af-query.asp?String=exact&Acronym=$1	0	0
advogato	http://www.advogato.org/$1	0	0
annotationwiki	http://www.seedwiki.com/page.cfm?wikiid=368&doc=$1	0	0
arxiv	http://www.arxiv.org/abs/$1	0	0
c2find	http://c2.com/cgi/wiki?FindPage&value=$1	0	0
cache	http://www.google.com/search?q=cache:$1	0	0
commons	http://commons.wikimedia.org/wiki/$1	0	0
corpknowpedia	http://corpknowpedia.org/wiki/index.php/$1	0	0
dictionary	http://www.dict.org/bin/Dict?Database=*&Form=Dict1&Strategy=*&Query=$1	0	0
disinfopedia	http://www.disinfopedia.org/wiki.phtml?title=$1	0	0
docbook	http://wiki.docbook.org/topic/$1	0	0
doi	http://dx.doi.org/$1	0	0
drumcorpswiki	http://www.drumcorpswiki.com/index.php/$1	0	0
dwjwiki	http://www.suberic.net/cgi-bin/dwj/wiki.cgi?$1	0	0
emacswiki	http://www.emacswiki.org/cgi-bin/wiki.pl?$1	0	0
elibre	http://enciclopedia.us.es/index.php/$1	0	0
foldoc	http://foldoc.org/?$1	0	0
foxwiki	http://fox.wikis.com/wc.dll?Wiki~$1	0	0
freebsdman	http://www.FreeBSD.org/cgi/man.cgi?apropos=1&query=$1	0	0
gej	http://www.esperanto.de/cgi-bin/aktivikio/wiki.pl?$1	0	0
gentoo-wiki	http://gentoo-wiki.com/$1	0	0
google	http://www.google.com/search?q=$1	0	0
googlegroups	http://groups.google.com/groups?q=$1	0	0
hammondwiki	http://www.dairiki.org/HammondWiki/$1	0	0
hewikisource	http://he.wikisource.org/wiki/$1	1	0
hrwiki	http://www.hrwiki.org/index.php/$1	0	0
imdb	http://us.imdb.com/Title?$1	0	0
jargonfile	http://sunir.org/apps/meta.pl?wiki=JargonFile&redirect=$1	0	0
jspwiki	http://www.jspwiki.org/wiki/$1	0	0
keiki	http://kei.ki/en/$1	0	0
kmwiki	http://kmwiki.wikispaces.com/$1	0	0
linuxwiki	http://linuxwiki.de/$1	0	0
lojban	http://www.lojban.org/tiki/tiki-index.php?page=$1	0	0
lqwiki	http://wiki.linuxquestions.org/wiki/$1	0	0
lugkr	http://lug-kr.sourceforge.net/cgi-bin/lugwiki.pl?$1	0	0
mathsongswiki	http://SeedWiki.com/page.cfm?wikiid=237&doc=$1	0	0
meatball	http://www.usemod.com/cgi-bin/mb.pl?$1	0	0
mediazilla	http://bugzilla.wikipedia.org/$1	1	0
mediawikiwiki	http://www.mediawiki.org/wiki/$1	0	0
memoryalpha	http://www.memory-alpha.org/en/index.php/$1	0	0
metawiki	http://sunir.org/apps/meta.pl?$1	0	0
metawikipedia	http://meta.wikimedia.org/wiki/$1	0	0
moinmoin	http://purl.net/wiki/moin/$1	0	0
mozillawiki	http://wiki.mozilla.org/index.php/$1	0	0
oeis	http://www.research.att.com/cgi-bin/access.cgi/as/njas/sequences/eisA.cgi?Anum=$1	0	0
openfacts	http://openfacts.berlios.de/index.phtml?title=$1	0	0
openwiki	http://openwiki.com/?$1	0	0
patwiki	http://gauss.ffii.org/$1	0	0
pmeg	http://www.bertilow.com/pmeg/$1.php	0	0
ppr	http://c2.com/cgi/wiki?$1	0	0
pythoninfo	http://wiki.python.org/moin/$1	0	0
rfc	http://www.rfc-editor.org/rfc/rfc$1.txt	0	0
s23wiki	http://is-root.de/wiki/index.php/$1	0	0
seattlewiki	http://seattle.wikia.com/wiki/$1	0	0
seattlewireless	http://seattlewireless.net/?$1	0	0
senseislibrary	http://senseis.xmp.net/?$1	0	0
slashdot	http://slashdot.org/article.pl?sid=$1	0	0
sourceforge	http://sourceforge.net/$1	0	0
squeak	http://wiki.squeak.org/squeak/$1	0	0
susning	http://www.susning.nu/$1	0	0
svgwiki	http://wiki.svg.org/$1	0	0
tavi	http://tavi.sourceforge.net/$1	0	0
tejo	http://www.tejo.org/vikio/$1	0	0
tmbw	http://www.tmbw.net/wiki/$1	0	0
tmnet	http://www.technomanifestos.net/?$1	0	0
tmwiki	http://www.EasyTopicMaps.com/?page=$1	0	0
theopedia	http://www.theopedia.com/$1	0	0
twiki	http://twiki.org/cgi-bin/view/$1	0	0
uea	http://www.tejo.org/uea/$1	0	0
unreal	http://wiki.beyondunreal.com/wiki/$1	0	0
usemod	http://www.usemod.com/cgi-bin/wiki.pl?$1	0	0
vinismo	http://vinismo.com/en/$1	0	0
webseitzwiki	http://webseitz.fluxent.com/wiki/$1	0	0
why	http://clublet.com/c/c/why?$1	0	0
wiki	http://c2.com/cgi/wiki?$1	0	0
wikia	http://www.wikia.com/wiki/$1	0	0
wikibooks	http://en.wikibooks.org/wiki/$1	1	0
wikicities	http://www.wikicities.com/index.php/$1	0	0
wikif1	http://www.wikif1.org/$1	0	0
wikihow	http://www.wikihow.com/$1	0	0
wikinfo	http://www.wikinfo.org/index.php/$1	0	0
wikimedia	http://wikimediafoundation.org/wiki/$1	0	0
wikiquote	http://en.wikiquote.org/wiki/$1	1	0
wikinews	http://en.wikinews.org/wiki/$1	1	0
wikisource	http://sources.wikipedia.org/wiki/$1	1	0
wikispecies	http://species.wikipedia.org/wiki/$1	1	0
wikitravel	http://wikitravel.org/en/$1	0	0
wiktionary	http://en.wiktionary.org/wiki/$1	1	0
wlug	http://www.wlug.org.nz/$1	0	0
zwiki	http://zwiki.org/$1	0	0
zzz wiki	http://wiki.zzz.ee/index.php/$1	0	0
wikt	http://en.wiktionary.org/wiki/$1	1	0
\.


--
-- Data for Name: ipblocks; Type: TABLE DATA; Schema: mediawiki; Owner: wikiuser
--

COPY ipblocks (ipb_id, ipb_address, ipb_user, ipb_by, ipb_by_text, ipb_reason, ipb_timestamp, ipb_auto, ipb_anon_only, ipb_create_account, ipb_enable_autoblock, ipb_expiry, ipb_range_start, ipb_range_end, ipb_deleted, ipb_block_email, ipb_allow_usertalk) FROM stdin;
\.


--
-- Data for Name: job; Type: TABLE DATA; Schema: mediawiki; Owner: wikiuser
--

COPY job (job_id, job_cmd, job_namespace, job_title, job_params) FROM stdin;
\.


--
-- Data for Name: langlinks; Type: TABLE DATA; Schema: mediawiki; Owner: wikiuser
--

COPY langlinks (ll_from, ll_lang, ll_title) FROM stdin;
\.


--
-- Data for Name: logging; Type: TABLE DATA; Schema: mediawiki; Owner: wikiuser
--

COPY logging (log_id, log_type, log_action, log_timestamp, log_user, log_namespace, log_title, log_comment, log_params, log_deleted) FROM stdin;
\.


--
-- Data for Name: math; Type: TABLE DATA; Schema: mediawiki; Owner: wikiuser
--

COPY math (math_inputhash, math_outputhash, math_html_conservativeness, math_html, math_mathml) FROM stdin;
\.


--
-- Data for Name: mediawiki_version; Type: TABLE DATA; Schema: mediawiki; Owner: wikiuser
--

COPY mediawiki_version (type, mw_version, notes, pg_version, pg_dbname, pg_user, pg_port, mw_schema, ts2_schema, ctype, sql_version, sql_date, cdate) FROM stdin;
Creation	1.15.1	\N	8.4.4	wikidb	wikiuser	5432	mediawiki	public	C	$LastChangedRevision: 48615 $	$LastChangedDate: 2009-03-20 12:15:41 +1100 (Fri, 20 Mar 2009) $	2010-07-05 09:21:32.052992-04
\.


--
-- Data for Name: mwuser; Type: TABLE DATA; Schema: mediawiki; Owner: wikiuser
--

COPY mwuser (user_id, user_name, user_real_name, user_password, user_newpassword, user_newpass_time, user_token, user_email, user_email_token, user_email_token_expires, user_email_authenticated, user_options, user_touched, user_registration, user_editcount) FROM stdin;
1	MediaWiki default				\N	207a103b721957fffcc60e76446c8f3a			\N	\N	quickbar=1\nunderline=2\ncols=80\nrows=25\nsearchlimit=20\ncontextlines=5\ncontextchars=50\ndisablesuggest=0\nskin=\nmath=1\nusenewrc=0\nrcdays=7\nrclimit=50\nwllimit=250\nhideminor=0\nhidepatrolled=0\nnewpageshidepatrolled=0\nhighlightbroken=1\nstubthreshold=0\npreviewontop=1\npreviewonfirst=0\neditsection=1\neditsectiononrightclick=0\neditondblclick=0\neditwidth=0\nshowtoc=1\nshowtoolbar=1\nminordefault=0\ndate=default\nimagesize=2\nthumbsize=2\nrememberpassword=0\nnocache=0\ndiffonly=0\nshowhiddencats=0\nnorollbackdiff=0\nenotifwatchlistpages=0\nenotifusertalkpages=1\nenotifminoredits=0\nenotifrevealaddr=0\nshownumberswatching=1\nfancysig=0\nexternaleditor=0\nexternaldiff=0\nforceeditsummary=0\nshowjumplinks=1\njustify=0\nnumberheadings=0\nuselivepreview=0\nwatchlistdays=3\nextendwatchlist=0\nwatchlisthideminor=0\nwatchlisthidebots=0\nwatchlisthideown=0\nwatchlisthideanons=0\nwatchlisthideliu=0\nwatchlisthidepatrolled=0\nwatchcreations=0\nwatchdefault=0\nwatchmoves=0\nwatchdeletion=0\nnoconvertlink=0\ngender=unknown\nvariant=en\nlanguage=en\nsearchNs0=1	2011-03-06 22:07:30-05	2011-03-06 22:07:25-05	0
\.


--
-- Data for Name: objectcache; Type: TABLE DATA; Schema: mediawiki; Owner: wikiuser
--

COPY objectcache (keyname, value, exptime) FROM stdin;
\.


--
-- Data for Name: oldimage; Type: TABLE DATA; Schema: mediawiki; Owner: wikiuser
--

COPY oldimage (oi_name, oi_archive_name, oi_size, oi_width, oi_height, oi_bits, oi_description, oi_user, oi_user_text, oi_timestamp, oi_metadata, oi_media_type, oi_major_mime, oi_minor_mime, oi_deleted, oi_sha1) FROM stdin;
\.


--
-- Data for Name: page; Type: TABLE DATA; Schema: mediawiki; Owner: wikiuser
--

COPY page (page_id, page_namespace, page_title, page_restrictions, page_counter, page_is_redirect, page_is_new, page_random, page_touched, page_latest, page_len, titlevector) FROM stdin;
1	0	Main_Page		0	0	0	0.83397604163400	2010-07-05 09:21:35-05	1	449	'main':1 'page':2
2	8	Common.js		0	0	0	0.59812893046300	2010-07-05 09:21:35-05	2	161	'common.js':1
\.


--
-- Data for Name: page_props; Type: TABLE DATA; Schema: mediawiki; Owner: wikiuser
--

COPY page_props (pp_page, pp_propname, pp_value) FROM stdin;
\.


--
-- Data for Name: page_restrictions; Type: TABLE DATA; Schema: mediawiki; Owner: wikiuser
--

COPY page_restrictions (pr_id, pr_page, pr_type, pr_level, pr_cascade, pr_user, pr_expiry) FROM stdin;
\.


--
-- Data for Name: pagecontent; Type: TABLE DATA; Schema: mediawiki; Owner: wikiuser
--

COPY pagecontent (old_id, old_text, old_flags, textvector) FROM stdin;
1	<big>'''MediaWiki has been successfully installed.'''</big>\n\nConsult the [http://meta.wikimedia.org/wiki/Help:Contents User's Guide] for information on using the wiki software.\n\n== Getting started ==\n* [http://www.mediawiki.org/wiki/Manual:Configuration_settings Configuration settings list]\n* [http://www.mediawiki.org/wiki/Manual:FAQ MediaWiki FAQ]\n* [https://lists.wikimedia.org/mailman/listinfo/mediawiki-announce MediaWiki release mailing list]	utf-8	'/mailman/listinfo/mediawiki-announce':36 '/wiki/help:contents':10 '/wiki/manual:configuration_settings':25 '/wiki/manual:faq':31 'configur':26 'consult':6 'faq':33 'get':21 'guid':13 'inform':15 'instal':5 'list':28,40 'lists.wikimedia.org':35 'lists.wikimedia.org/mailman/listinfo/mediawiki-announce':34 'mail':39 'mediawiki':1,32,37 'meta.wikimedia.org':9 'meta.wikimedia.org/wiki/help':8 'releas':38 'set':27 'softwar':20 'start':22 'success':4 'use':17 'user':11 'wiki':19 'www.mediawiki.org':24,30 'www.mediawiki.org/wiki/manual':23,29
2	/* Any JavaScript here will be loaded for all users on every page load. */\ndocument.write('<script type="text/javascript" src="/extensions/wikEd.js"></script>');	utf-8	\N
\.


--
-- Data for Name: pagelinks; Type: TABLE DATA; Schema: mediawiki; Owner: wikiuser
--

COPY pagelinks (pl_from, pl_namespace, pl_title) FROM stdin;
\.


--
-- Data for Name: profiling; Type: TABLE DATA; Schema: mediawiki; Owner: wikiuser
--

COPY profiling (pf_count, pf_time, pf_memory, pf_name, pf_server) FROM stdin;
\.


--
-- Data for Name: protected_titles; Type: TABLE DATA; Schema: mediawiki; Owner: wikiuser
--

COPY protected_titles (pt_namespace, pt_title, pt_user, pt_reason, pt_timestamp, pt_expiry, pt_create_perm) FROM stdin;
\.


--
-- Data for Name: querycache; Type: TABLE DATA; Schema: mediawiki; Owner: wikiuser
--

COPY querycache (qc_type, qc_value, qc_namespace, qc_title) FROM stdin;
\.


--
-- Data for Name: querycache_info; Type: TABLE DATA; Schema: mediawiki; Owner: wikiuser
--

COPY querycache_info (qci_type, qci_timestamp) FROM stdin;
\.


--
-- Data for Name: querycachetwo; Type: TABLE DATA; Schema: mediawiki; Owner: wikiuser
--

COPY querycachetwo (qcc_type, qcc_value, qcc_namespace, qcc_title, qcc_namespacetwo, qcc_titletwo) FROM stdin;
\.


--
-- Data for Name: recentchanges; Type: TABLE DATA; Schema: mediawiki; Owner: wikiuser
--

COPY recentchanges (rc_id, rc_timestamp, rc_cur_time, rc_user, rc_user_text, rc_namespace, rc_title, rc_comment, rc_minor, rc_bot, rc_new, rc_cur_id, rc_this_oldid, rc_last_oldid, rc_type, rc_moved_to_ns, rc_moved_to_title, rc_patrolled, rc_ip, rc_old_len, rc_new_len, rc_deleted, rc_logid, rc_log_type, rc_log_action, rc_params) FROM stdin;
\.


--
-- Data for Name: redirect; Type: TABLE DATA; Schema: mediawiki; Owner: wikiuser
--

COPY redirect (rd_from, rd_namespace, rd_title) FROM stdin;
\.


--
-- Data for Name: revision; Type: TABLE DATA; Schema: mediawiki; Owner: wikiuser
--

COPY revision (rev_id, rev_page, rev_text_id, rev_comment, rev_user, rev_user_text, rev_timestamp, rev_minor_edit, rev_deleted, rev_len, rev_parent_id) FROM stdin;
1	1	1		1	MediaWiki default	2010-07-05 09:21:35-04	0	0	449	0
2	2	2		1	MediaWiki default	2011-02-23 10:55:25-05	0	0	161	0
\.


--
-- Data for Name: site_stats; Type: TABLE DATA; Schema: mediawiki; Owner: wikiuser
--

COPY site_stats (ss_row_id, ss_total_views, ss_total_edits, ss_good_articles, ss_total_pages, ss_users, ss_active_users, ss_admins, ss_images) FROM stdin;
1	0	2	0	2	0	-1	0	0
\.


--
-- Data for Name: tag_summary; Type: TABLE DATA; Schema: mediawiki; Owner: wikiuser
--

COPY tag_summary (ts_rc_id, ts_log_id, ts_rev_id, ts_tags) FROM stdin;
\.


--
-- Data for Name: templatelinks; Type: TABLE DATA; Schema: mediawiki; Owner: wikiuser
--

COPY templatelinks (tl_from, tl_namespace, tl_title) FROM stdin;
\.


--
-- Data for Name: trackbacks; Type: TABLE DATA; Schema: mediawiki; Owner: wikiuser
--

COPY trackbacks (tb_id, tb_page, tb_title, tb_url, tb_ex, tb_name) FROM stdin;
\.


--
-- Data for Name: transcache; Type: TABLE DATA; Schema: mediawiki; Owner: wikiuser
--

COPY transcache (tc_url, tc_contents, tc_time) FROM stdin;
\.


--
-- Data for Name: updatelog; Type: TABLE DATA; Schema: mediawiki; Owner: wikiuser
--

COPY updatelog (ul_key) FROM stdin;
\.


--
-- Data for Name: user_groups; Type: TABLE DATA; Schema: mediawiki; Owner: wikiuser
--

COPY user_groups (ug_user, ug_group) FROM stdin;
\.


--
-- Data for Name: user_newtalk; Type: TABLE DATA; Schema: mediawiki; Owner: wikiuser
--

COPY user_newtalk (user_id, user_ip, user_last_timestamp) FROM stdin;
\.


--
-- Data for Name: valid_tag; Type: TABLE DATA; Schema: mediawiki; Owner: wikiuser
--

COPY valid_tag (vt_tag) FROM stdin;
\.


--
-- Data for Name: watchlist; Type: TABLE DATA; Schema: mediawiki; Owner: wikiuser
--

COPY watchlist (wl_user, wl_namespace, wl_title, wl_notificationtimestamp) FROM stdin;
\.


--
-- Name: category_pkey; Type: CONSTRAINT; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

ALTER TABLE ONLY category
    ADD CONSTRAINT category_pkey PRIMARY KEY (cat_id);


--
-- Name: filearchive_pkey; Type: CONSTRAINT; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

ALTER TABLE ONLY filearchive
    ADD CONSTRAINT filearchive_pkey PRIMARY KEY (fa_id);


--
-- Name: image_pkey; Type: CONSTRAINT; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

ALTER TABLE ONLY image
    ADD CONSTRAINT image_pkey PRIMARY KEY (img_name);


--
-- Name: interwiki_iw_prefix_key; Type: CONSTRAINT; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

ALTER TABLE ONLY interwiki
    ADD CONSTRAINT interwiki_iw_prefix_key UNIQUE (iw_prefix);


--
-- Name: ipblocks_pkey; Type: CONSTRAINT; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

ALTER TABLE ONLY ipblocks
    ADD CONSTRAINT ipblocks_pkey PRIMARY KEY (ipb_id);


--
-- Name: job_pkey; Type: CONSTRAINT; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

ALTER TABLE ONLY job
    ADD CONSTRAINT job_pkey PRIMARY KEY (job_id);


--
-- Name: logging_pkey; Type: CONSTRAINT; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

ALTER TABLE ONLY logging
    ADD CONSTRAINT logging_pkey PRIMARY KEY (log_id);


--
-- Name: math_math_inputhash_key; Type: CONSTRAINT; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

ALTER TABLE ONLY math
    ADD CONSTRAINT math_math_inputhash_key UNIQUE (math_inputhash);


--
-- Name: mwuser_pkey; Type: CONSTRAINT; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

ALTER TABLE ONLY mwuser
    ADD CONSTRAINT mwuser_pkey PRIMARY KEY (user_id);


--
-- Name: mwuser_user_name_key; Type: CONSTRAINT; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

ALTER TABLE ONLY mwuser
    ADD CONSTRAINT mwuser_user_name_key UNIQUE (user_name);


--
-- Name: objectcache_keyname_key; Type: CONSTRAINT; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

ALTER TABLE ONLY objectcache
    ADD CONSTRAINT objectcache_keyname_key UNIQUE (keyname);


--
-- Name: page_pkey; Type: CONSTRAINT; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

ALTER TABLE ONLY page
    ADD CONSTRAINT page_pkey PRIMARY KEY (page_id);


--
-- Name: page_props_pk; Type: CONSTRAINT; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

ALTER TABLE ONLY page_props
    ADD CONSTRAINT page_props_pk PRIMARY KEY (pp_page, pp_propname);


--
-- Name: page_restrictions_pk; Type: CONSTRAINT; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

ALTER TABLE ONLY page_restrictions
    ADD CONSTRAINT page_restrictions_pk PRIMARY KEY (pr_page, pr_type);


--
-- Name: page_restrictions_pr_id_key; Type: CONSTRAINT; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

ALTER TABLE ONLY page_restrictions
    ADD CONSTRAINT page_restrictions_pr_id_key UNIQUE (pr_id);


--
-- Name: pagecontent_pkey; Type: CONSTRAINT; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

ALTER TABLE ONLY pagecontent
    ADD CONSTRAINT pagecontent_pkey PRIMARY KEY (old_id);


--
-- Name: querycache_info_qci_type_key; Type: CONSTRAINT; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

ALTER TABLE ONLY querycache_info
    ADD CONSTRAINT querycache_info_qci_type_key UNIQUE (qci_type);


--
-- Name: recentchanges_pkey; Type: CONSTRAINT; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

ALTER TABLE ONLY recentchanges
    ADD CONSTRAINT recentchanges_pkey PRIMARY KEY (rc_id);


--
-- Name: revision_rev_id_key; Type: CONSTRAINT; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

ALTER TABLE ONLY revision
    ADD CONSTRAINT revision_rev_id_key UNIQUE (rev_id);


--
-- Name: site_stats_ss_row_id_key; Type: CONSTRAINT; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

ALTER TABLE ONLY site_stats
    ADD CONSTRAINT site_stats_ss_row_id_key UNIQUE (ss_row_id);


--
-- Name: trackbacks_pkey; Type: CONSTRAINT; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

ALTER TABLE ONLY trackbacks
    ADD CONSTRAINT trackbacks_pkey PRIMARY KEY (tb_id);


--
-- Name: transcache_tc_url_key; Type: CONSTRAINT; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

ALTER TABLE ONLY transcache
    ADD CONSTRAINT transcache_tc_url_key UNIQUE (tc_url);


--
-- Name: updatelog_pkey; Type: CONSTRAINT; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

ALTER TABLE ONLY updatelog
    ADD CONSTRAINT updatelog_pkey PRIMARY KEY (ul_key);


--
-- Name: valid_tag_pkey; Type: CONSTRAINT; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

ALTER TABLE ONLY valid_tag
    ADD CONSTRAINT valid_tag_pkey PRIMARY KEY (vt_tag);


--
-- Name: archive_name_title_timestamp; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE INDEX archive_name_title_timestamp ON archive USING btree (ar_namespace, ar_title, ar_timestamp);


--
-- Name: archive_user_text; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE INDEX archive_user_text ON archive USING btree (ar_user_text);


--
-- Name: category_pages; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE INDEX category_pages ON category USING btree (cat_pages);


--
-- Name: category_title; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE UNIQUE INDEX category_title ON category USING btree (cat_title);


--
-- Name: change_tag_log_tag; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE UNIQUE INDEX change_tag_log_tag ON change_tag USING btree (ct_log_id, ct_tag);


--
-- Name: change_tag_rc_tag; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE UNIQUE INDEX change_tag_rc_tag ON change_tag USING btree (ct_rc_id, ct_tag);


--
-- Name: change_tag_rev_tag; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE UNIQUE INDEX change_tag_rev_tag ON change_tag USING btree (ct_rev_id, ct_tag);


--
-- Name: change_tag_tag_id; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE INDEX change_tag_tag_id ON change_tag USING btree (ct_tag, ct_rc_id, ct_rev_id, ct_log_id);


--
-- Name: cl_from; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE UNIQUE INDEX cl_from ON categorylinks USING btree (cl_from, cl_to);


--
-- Name: cl_sortkey; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE INDEX cl_sortkey ON categorylinks USING btree (cl_to, cl_sortkey, cl_from);


--
-- Name: externallinks_from_to; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE INDEX externallinks_from_to ON externallinks USING btree (el_from, el_to);


--
-- Name: externallinks_index; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE INDEX externallinks_index ON externallinks USING btree (el_index);


--
-- Name: fa_dupe; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE INDEX fa_dupe ON filearchive USING btree (fa_storage_group, fa_storage_key);


--
-- Name: fa_name_time; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE INDEX fa_name_time ON filearchive USING btree (fa_name, fa_timestamp);


--
-- Name: fa_notime; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE INDEX fa_notime ON filearchive USING btree (fa_deleted_timestamp);


--
-- Name: fa_nouser; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE INDEX fa_nouser ON filearchive USING btree (fa_deleted_user);


--
-- Name: il_from; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE UNIQUE INDEX il_from ON imagelinks USING btree (il_to, il_from);


--
-- Name: img_sha1; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE INDEX img_sha1 ON image USING btree (img_sha1);


--
-- Name: img_size_idx; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE INDEX img_size_idx ON image USING btree (img_size);


--
-- Name: img_timestamp_idx; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE INDEX img_timestamp_idx ON image USING btree (img_timestamp);


--
-- Name: ipb_address_unique; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE UNIQUE INDEX ipb_address_unique ON ipblocks USING btree (ipb_address, ipb_user, ipb_auto, ipb_anon_only);


--
-- Name: ipb_range; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE INDEX ipb_range ON ipblocks USING btree (ipb_range_start, ipb_range_end);


--
-- Name: ipb_user; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE INDEX ipb_user ON ipblocks USING btree (ipb_user);


--
-- Name: job_cmd_namespace_title; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE INDEX job_cmd_namespace_title ON job USING btree (job_cmd, job_namespace, job_title);


--
-- Name: langlinks_lang_title; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE INDEX langlinks_lang_title ON langlinks USING btree (ll_lang, ll_title);


--
-- Name: langlinks_unique; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE UNIQUE INDEX langlinks_unique ON langlinks USING btree (ll_from, ll_lang);


--
-- Name: logging_page_time; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE INDEX logging_page_time ON logging USING btree (log_namespace, log_title, log_timestamp);


--
-- Name: logging_type_name; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE INDEX logging_type_name ON logging USING btree (log_type, log_timestamp);


--
-- Name: logging_user_time; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE INDEX logging_user_time ON logging USING btree (log_timestamp, log_user);


--
-- Name: new_name_timestamp; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE INDEX new_name_timestamp ON recentchanges USING btree (rc_new, rc_namespace, rc_timestamp);


--
-- Name: objectcacache_exptime; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE INDEX objectcacache_exptime ON objectcache USING btree (exptime);


--
-- Name: oi_name_archive_name; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE INDEX oi_name_archive_name ON oldimage USING btree (oi_name, oi_archive_name);


--
-- Name: oi_name_timestamp; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE INDEX oi_name_timestamp ON oldimage USING btree (oi_name, oi_timestamp);


--
-- Name: oi_sha1; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE INDEX oi_sha1 ON oldimage USING btree (oi_sha1);


--
-- Name: page_len_idx; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE INDEX page_len_idx ON page USING btree (page_len);


--
-- Name: page_main_title; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE INDEX page_main_title ON page USING btree (page_title) WHERE (page_namespace = 0);


--
-- Name: page_project_title; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE INDEX page_project_title ON page USING btree (page_title) WHERE (page_namespace = 4);


--
-- Name: page_props_propname; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE INDEX page_props_propname ON page_props USING btree (pp_propname);


--
-- Name: page_random_idx; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE INDEX page_random_idx ON page USING btree (page_random);


--
-- Name: page_talk_title; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE INDEX page_talk_title ON page USING btree (page_title) WHERE (page_namespace = 1);


--
-- Name: page_unique_name; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE UNIQUE INDEX page_unique_name ON page USING btree (page_namespace, page_title);


--
-- Name: page_user_title; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE INDEX page_user_title ON page USING btree (page_title) WHERE (page_namespace = 2);


--
-- Name: page_utalk_title; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE INDEX page_utalk_title ON page USING btree (page_title) WHERE (page_namespace = 3);


--
-- Name: pagelink_unique; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE UNIQUE INDEX pagelink_unique ON pagelinks USING btree (pl_from, pl_namespace, pl_title);


--
-- Name: pf_name_server; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE UNIQUE INDEX pf_name_server ON profiling USING btree (pf_name, pf_server);


--
-- Name: protected_titles_unique; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE UNIQUE INDEX protected_titles_unique ON protected_titles USING btree (pt_namespace, pt_title);


--
-- Name: querycache_type_value; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE INDEX querycache_type_value ON querycache USING btree (qc_type, qc_value);


--
-- Name: querycachetwo_title; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE INDEX querycachetwo_title ON querycachetwo USING btree (qcc_type, qcc_namespace, qcc_title);


--
-- Name: querycachetwo_titletwo; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE INDEX querycachetwo_titletwo ON querycachetwo USING btree (qcc_type, qcc_namespacetwo, qcc_titletwo);


--
-- Name: querycachetwo_type_value; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE INDEX querycachetwo_type_value ON querycachetwo USING btree (qcc_type, qcc_value);


--
-- Name: rc_cur_id; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE INDEX rc_cur_id ON recentchanges USING btree (rc_cur_id);


--
-- Name: rc_ip; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE INDEX rc_ip ON recentchanges USING btree (rc_ip);


--
-- Name: rc_namespace_title; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE INDEX rc_namespace_title ON recentchanges USING btree (rc_namespace, rc_title);


--
-- Name: rc_timestamp; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE INDEX rc_timestamp ON recentchanges USING btree (rc_timestamp);


--
-- Name: rc_timestamp_bot; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE INDEX rc_timestamp_bot ON recentchanges USING btree (rc_timestamp) WHERE (rc_bot = 0);


--
-- Name: redirect_ns_title; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE INDEX redirect_ns_title ON redirect USING btree (rd_namespace, rd_title, rd_from);


--
-- Name: rev_text_id_idx; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE INDEX rev_text_id_idx ON revision USING btree (rev_text_id);


--
-- Name: rev_timestamp_idx; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE INDEX rev_timestamp_idx ON revision USING btree (rev_timestamp);


--
-- Name: rev_user_idx; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE INDEX rev_user_idx ON revision USING btree (rev_user);


--
-- Name: rev_user_text_idx; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE INDEX rev_user_text_idx ON revision USING btree (rev_user_text);


--
-- Name: revision_unique; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE UNIQUE INDEX revision_unique ON revision USING btree (rev_page, rev_id);


--
-- Name: tag_summary_log_id; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE UNIQUE INDEX tag_summary_log_id ON tag_summary USING btree (ts_log_id);


--
-- Name: tag_summary_rc_id; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE UNIQUE INDEX tag_summary_rc_id ON tag_summary USING btree (ts_rc_id);


--
-- Name: tag_summary_rev_id; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE UNIQUE INDEX tag_summary_rev_id ON tag_summary USING btree (ts_rev_id);


--
-- Name: templatelinks_from; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE INDEX templatelinks_from ON templatelinks USING btree (tl_from);


--
-- Name: templatelinks_unique; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE UNIQUE INDEX templatelinks_unique ON templatelinks USING btree (tl_namespace, tl_title, tl_from);


--
-- Name: trackback_page; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE INDEX trackback_page ON trackbacks USING btree (tb_page);


--
-- Name: ts2_page_text; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE INDEX ts2_page_text ON pagecontent USING gin (textvector);


--
-- Name: ts2_page_title; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE INDEX ts2_page_title ON page USING gin (titlevector);


--
-- Name: user_email_token_idx; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE INDEX user_email_token_idx ON mwuser USING btree (user_email_token);


--
-- Name: user_groups_unique; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE UNIQUE INDEX user_groups_unique ON user_groups USING btree (ug_user, ug_group);


--
-- Name: user_newtalk_id_idx; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE INDEX user_newtalk_id_idx ON user_newtalk USING btree (user_id);


--
-- Name: user_newtalk_ip_idx; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE INDEX user_newtalk_ip_idx ON user_newtalk USING btree (user_ip);


--
-- Name: wl_user; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE INDEX wl_user ON watchlist USING btree (wl_user);


--
-- Name: wl_user_namespace_title; Type: INDEX; Schema: mediawiki; Owner: wikiuser; Tablespace: 
--

CREATE UNIQUE INDEX wl_user_namespace_title ON watchlist USING btree (wl_namespace, wl_title, wl_user);


--
-- Name: page_deleted; Type: TRIGGER; Schema: mediawiki; Owner: wikiuser
--

CREATE TRIGGER page_deleted
    AFTER DELETE ON page
    FOR EACH ROW
    EXECUTE PROCEDURE page_deleted();


--
-- Name: ts2_page_text; Type: TRIGGER; Schema: mediawiki; Owner: wikiuser
--

CREATE TRIGGER ts2_page_text
    BEFORE INSERT OR UPDATE ON pagecontent
    FOR EACH ROW
    EXECUTE PROCEDURE ts2_page_text();


--
-- Name: ts2_page_title; Type: TRIGGER; Schema: mediawiki; Owner: wikiuser
--

CREATE TRIGGER ts2_page_title
    BEFORE INSERT OR UPDATE ON page
    FOR EACH ROW
    EXECUTE PROCEDURE ts2_page_title();


--
-- Name: archive_ar_user_fkey; Type: FK CONSTRAINT; Schema: mediawiki; Owner: wikiuser
--

ALTER TABLE ONLY archive
    ADD CONSTRAINT archive_ar_user_fkey FOREIGN KEY (ar_user) REFERENCES mwuser(user_id) ON DELETE SET NULL;


--
-- Name: categorylinks_cl_from_fkey; Type: FK CONSTRAINT; Schema: mediawiki; Owner: wikiuser
--

ALTER TABLE ONLY categorylinks
    ADD CONSTRAINT categorylinks_cl_from_fkey FOREIGN KEY (cl_from) REFERENCES page(page_id) ON DELETE CASCADE;


--
-- Name: externallinks_el_from_fkey; Type: FK CONSTRAINT; Schema: mediawiki; Owner: wikiuser
--

ALTER TABLE ONLY externallinks
    ADD CONSTRAINT externallinks_el_from_fkey FOREIGN KEY (el_from) REFERENCES page(page_id) ON DELETE CASCADE;


--
-- Name: filearchive_fa_deleted_user_fkey; Type: FK CONSTRAINT; Schema: mediawiki; Owner: wikiuser
--

ALTER TABLE ONLY filearchive
    ADD CONSTRAINT filearchive_fa_deleted_user_fkey FOREIGN KEY (fa_deleted_user) REFERENCES mwuser(user_id) ON DELETE SET NULL;


--
-- Name: filearchive_fa_user_fkey; Type: FK CONSTRAINT; Schema: mediawiki; Owner: wikiuser
--

ALTER TABLE ONLY filearchive
    ADD CONSTRAINT filearchive_fa_user_fkey FOREIGN KEY (fa_user) REFERENCES mwuser(user_id) ON DELETE SET NULL;


--
-- Name: image_img_user_fkey; Type: FK CONSTRAINT; Schema: mediawiki; Owner: wikiuser
--

ALTER TABLE ONLY image
    ADD CONSTRAINT image_img_user_fkey FOREIGN KEY (img_user) REFERENCES mwuser(user_id) ON DELETE SET NULL;


--
-- Name: imagelinks_il_from_fkey; Type: FK CONSTRAINT; Schema: mediawiki; Owner: wikiuser
--

ALTER TABLE ONLY imagelinks
    ADD CONSTRAINT imagelinks_il_from_fkey FOREIGN KEY (il_from) REFERENCES page(page_id) ON DELETE CASCADE;


--
-- Name: ipblocks_ipb_by_fkey; Type: FK CONSTRAINT; Schema: mediawiki; Owner: wikiuser
--

ALTER TABLE ONLY ipblocks
    ADD CONSTRAINT ipblocks_ipb_by_fkey FOREIGN KEY (ipb_by) REFERENCES mwuser(user_id) ON DELETE CASCADE;


--
-- Name: ipblocks_ipb_user_fkey; Type: FK CONSTRAINT; Schema: mediawiki; Owner: wikiuser
--

ALTER TABLE ONLY ipblocks
    ADD CONSTRAINT ipblocks_ipb_user_fkey FOREIGN KEY (ipb_user) REFERENCES mwuser(user_id) ON DELETE SET NULL;


--
-- Name: langlinks_ll_from_fkey; Type: FK CONSTRAINT; Schema: mediawiki; Owner: wikiuser
--

ALTER TABLE ONLY langlinks
    ADD CONSTRAINT langlinks_ll_from_fkey FOREIGN KEY (ll_from) REFERENCES page(page_id) ON DELETE CASCADE;


--
-- Name: logging_log_user_fkey; Type: FK CONSTRAINT; Schema: mediawiki; Owner: wikiuser
--

ALTER TABLE ONLY logging
    ADD CONSTRAINT logging_log_user_fkey FOREIGN KEY (log_user) REFERENCES mwuser(user_id) ON DELETE SET NULL;


--
-- Name: oldimage_oi_name_fkey_cascade; Type: FK CONSTRAINT; Schema: mediawiki; Owner: wikiuser
--

ALTER TABLE ONLY oldimage
    ADD CONSTRAINT oldimage_oi_name_fkey_cascade FOREIGN KEY (oi_name) REFERENCES image(img_name) ON DELETE CASCADE;


--
-- Name: oldimage_oi_user_fkey; Type: FK CONSTRAINT; Schema: mediawiki; Owner: wikiuser
--

ALTER TABLE ONLY oldimage
    ADD CONSTRAINT oldimage_oi_user_fkey FOREIGN KEY (oi_user) REFERENCES mwuser(user_id) ON DELETE SET NULL;


--
-- Name: page_props_pp_page_fkey; Type: FK CONSTRAINT; Schema: mediawiki; Owner: wikiuser
--

ALTER TABLE ONLY page_props
    ADD CONSTRAINT page_props_pp_page_fkey FOREIGN KEY (pp_page) REFERENCES page(page_id) ON DELETE CASCADE;


--
-- Name: page_restrictions_pr_page_fkey; Type: FK CONSTRAINT; Schema: mediawiki; Owner: wikiuser
--

ALTER TABLE ONLY page_restrictions
    ADD CONSTRAINT page_restrictions_pr_page_fkey FOREIGN KEY (pr_page) REFERENCES page(page_id) ON DELETE CASCADE;


--
-- Name: pagelinks_pl_from_fkey; Type: FK CONSTRAINT; Schema: mediawiki; Owner: wikiuser
--

ALTER TABLE ONLY pagelinks
    ADD CONSTRAINT pagelinks_pl_from_fkey FOREIGN KEY (pl_from) REFERENCES page(page_id) ON DELETE CASCADE;


--
-- Name: protected_titles_pt_user_fkey; Type: FK CONSTRAINT; Schema: mediawiki; Owner: wikiuser
--

ALTER TABLE ONLY protected_titles
    ADD CONSTRAINT protected_titles_pt_user_fkey FOREIGN KEY (pt_user) REFERENCES mwuser(user_id) ON DELETE SET NULL;


--
-- Name: recentchanges_rc_cur_id_fkey; Type: FK CONSTRAINT; Schema: mediawiki; Owner: wikiuser
--

ALTER TABLE ONLY recentchanges
    ADD CONSTRAINT recentchanges_rc_cur_id_fkey FOREIGN KEY (rc_cur_id) REFERENCES page(page_id) ON DELETE SET NULL;


--
-- Name: recentchanges_rc_user_fkey; Type: FK CONSTRAINT; Schema: mediawiki; Owner: wikiuser
--

ALTER TABLE ONLY recentchanges
    ADD CONSTRAINT recentchanges_rc_user_fkey FOREIGN KEY (rc_user) REFERENCES mwuser(user_id) ON DELETE SET NULL;


--
-- Name: redirect_rd_from_fkey; Type: FK CONSTRAINT; Schema: mediawiki; Owner: wikiuser
--

ALTER TABLE ONLY redirect
    ADD CONSTRAINT redirect_rd_from_fkey FOREIGN KEY (rd_from) REFERENCES page(page_id) ON DELETE CASCADE;


--
-- Name: revision_rev_page_fkey; Type: FK CONSTRAINT; Schema: mediawiki; Owner: wikiuser
--

ALTER TABLE ONLY revision
    ADD CONSTRAINT revision_rev_page_fkey FOREIGN KEY (rev_page) REFERENCES page(page_id) ON DELETE CASCADE;


--
-- Name: revision_rev_user_fkey; Type: FK CONSTRAINT; Schema: mediawiki; Owner: wikiuser
--

ALTER TABLE ONLY revision
    ADD CONSTRAINT revision_rev_user_fkey FOREIGN KEY (rev_user) REFERENCES mwuser(user_id) ON DELETE RESTRICT;


--
-- Name: templatelinks_tl_from_fkey; Type: FK CONSTRAINT; Schema: mediawiki; Owner: wikiuser
--

ALTER TABLE ONLY templatelinks
    ADD CONSTRAINT templatelinks_tl_from_fkey FOREIGN KEY (tl_from) REFERENCES page(page_id) ON DELETE CASCADE;


--
-- Name: trackbacks_tb_page_fkey; Type: FK CONSTRAINT; Schema: mediawiki; Owner: wikiuser
--

ALTER TABLE ONLY trackbacks
    ADD CONSTRAINT trackbacks_tb_page_fkey FOREIGN KEY (tb_page) REFERENCES page(page_id) ON DELETE CASCADE;


--
-- Name: user_groups_ug_user_fkey; Type: FK CONSTRAINT; Schema: mediawiki; Owner: wikiuser
--

ALTER TABLE ONLY user_groups
    ADD CONSTRAINT user_groups_ug_user_fkey FOREIGN KEY (ug_user) REFERENCES mwuser(user_id) ON DELETE CASCADE;


--
-- Name: user_newtalk_user_id_fkey; Type: FK CONSTRAINT; Schema: mediawiki; Owner: wikiuser
--

ALTER TABLE ONLY user_newtalk
    ADD CONSTRAINT user_newtalk_user_id_fkey FOREIGN KEY (user_id) REFERENCES mwuser(user_id) ON DELETE CASCADE;


--
-- Name: watchlist_wl_user_fkey; Type: FK CONSTRAINT; Schema: mediawiki; Owner: wikiuser
--

ALTER TABLE ONLY watchlist
    ADD CONSTRAINT watchlist_wl_user_fkey FOREIGN KEY (wl_user) REFERENCES mwuser(user_id) ON DELETE CASCADE;


--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

