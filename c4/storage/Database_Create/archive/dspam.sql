--
-- Name: dspam; Type: DATABASE; Schema: -;
--


SET statement_timeout = 0;
SET client_encoding = 'SQL_ASCII';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

--
-- Name: plpgsql; Type: PROCEDURAL LANGUAGE; Schema: -;
--

CREATE PROCEDURAL LANGUAGE plpgsql;


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: dspam_token_data; Type: TABLE; Schema: public; Owner: dspam; Tablespace: 
--

CREATE TABLE dspam_token_data (
    uid smallint,
    token bigint,
    spam_hits integer,
    innocent_hits integer,
    last_hit date
);


--
-- Name: lookup_tokens(integer, bigint[]); Type: FUNCTION; Schema: public; Owner: dspam
--

CREATE FUNCTION lookup_tokens(integer, bigint[]) RETURNS SETOF dspam_token_data
    LANGUAGE plpgsql STABLE
    AS $_$
declare
  v_rec record;
begin
  for v_rec in select * from dspam_token_data
                where uid=$1
                  and token in (select $2[i]
                                  from generate_series(array_lower($2,1),
                                                       array_upper($2,1)) s(i))
  loop
    return next v_rec;
  end loop;
  return;
end;$_$;


--
-- Name: dspam_preferences; Type: TABLE; Schema: public; Owner: dspam; Tablespace: 
--

CREATE TABLE dspam_preferences (
    uid smallint,
    preference character varying(128),
    value character varying(128)
);


--
-- Name: dspam_signature_data; Type: TABLE; Schema: public; Owner: dspam; Tablespace: 
--

CREATE TABLE dspam_signature_data (
    uid smallint,
    signature character varying(128),
    data bytea,
    length integer,
    created_on date
);


--
-- Name: dspam_stats; Type: TABLE; Schema: public; Owner: dspam; Tablespace: 
--

CREATE TABLE dspam_stats (
    uid smallint NOT NULL,
    spam_learned integer,
    innocent_learned integer,
    spam_misclassified integer,
    innocent_misclassified integer,
    spam_corpusfed integer,
    innocent_corpusfed integer,
    spam_classified integer,
    innocent_classified integer
);


--
-- Name: dspam_virtual_uids_seq; Type: SEQUENCE; Schema: public; Owner: dspam
--

CREATE SEQUENCE dspam_virtual_uids_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: dspam_virtual_uids_seq; Type: SEQUENCE SET; Schema: public; Owner: dspam
--

SELECT pg_catalog.setval('dspam_virtual_uids_seq', 1, false);


--
-- Name: dspam_virtual_uids; Type: TABLE; Schema: public; Owner: dspam; Tablespace: 
--

CREATE TABLE dspam_virtual_uids (
    uid smallint DEFAULT nextval('dspam_virtual_uids_seq'::regclass) NOT NULL,
    username character varying(128)
);


--
-- Name: dspam_preferences_uid_key; Type: CONSTRAINT; Schema: public; Owner: dspam; Tablespace: 
--

ALTER TABLE ONLY dspam_preferences
    ADD CONSTRAINT dspam_preferences_uid_key UNIQUE (uid, preference);


--
-- Name: dspam_signature_data_uid_key; Type: CONSTRAINT; Schema: public; Owner: dspam; Tablespace: 
--

ALTER TABLE ONLY dspam_signature_data
    ADD CONSTRAINT dspam_signature_data_uid_key UNIQUE (uid, signature);


--
-- Name: dspam_stats_pkey; Type: CONSTRAINT; Schema: public; Owner: dspam; Tablespace: 
--

ALTER TABLE ONLY dspam_stats
    ADD CONSTRAINT dspam_stats_pkey PRIMARY KEY (uid);


--
-- Name: dspam_token_data_uid_key; Type: CONSTRAINT; Schema: public; Owner: dspam; Tablespace: 
--

ALTER TABLE ONLY dspam_token_data
    ADD CONSTRAINT dspam_token_data_uid_key UNIQUE (uid, token);


--
-- Name: dspam_virtual_uids_pkey; Type: CONSTRAINT; Schema: public; Owner: dspam; Tablespace: 
--

ALTER TABLE ONLY dspam_virtual_uids
    ADD CONSTRAINT dspam_virtual_uids_pkey PRIMARY KEY (uid);


--
-- Name: id_virtual_uids_01; Type: INDEX; Schema: public; Owner: dspam; Tablespace: 
--

CREATE UNIQUE INDEX id_virtual_uids_01 ON dspam_virtual_uids USING btree (username);


--
-- Name: id_virtual_uids_02; Type: INDEX; Schema: public; Owner: dspam; Tablespace: 
--

CREATE UNIQUE INDEX id_virtual_uids_02 ON dspam_virtual_uids USING btree (uid);


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

