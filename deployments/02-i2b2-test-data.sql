--
-- PostgreSQL database dump
--

-- Dumped from database version 13.1 (Debian 13.1-1.pgdg100+1)
-- Dumped by pg_dump version 13.1 (Debian 13.1-1.pgdg100+1)

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


ALTER DATABASE i2b2 OWNER TO postgres;

\connect i2b2

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

--
-- Name: i2b2demodata; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA i2b2demodata;


ALTER SCHEMA i2b2demodata OWNER TO postgres;

--
-- Name: i2b2hive; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA i2b2hive;


ALTER SCHEMA i2b2hive OWNER TO postgres;

--
-- Name: i2b2imdata; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA i2b2imdata;


ALTER SCHEMA i2b2imdata OWNER TO postgres;

--
-- Name: i2b2metadata; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA i2b2metadata;


ALTER SCHEMA i2b2metadata OWNER TO postgres;

--
-- Name: i2b2pm; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA i2b2pm;


ALTER SCHEMA i2b2pm OWNER TO postgres;

--
-- Name: i2b2workdata; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA i2b2workdata;


ALTER SCHEMA i2b2workdata OWNER TO postgres;

--
-- Name: censoring_event(integer[], character varying[], character varying[]); Type: FUNCTION; Schema: i2b2demodata; Owner: postgres
--

CREATE FUNCTION i2b2demodata.censoring_event(patient_list integer[], end_code character varying[], end_modifier_code character varying[]) RETURNS TABLE(patient_num bigint, end_date date)
    LANGUAGE plpgsql STABLE PARALLEL SAFE
    AS $_$
DECLARE
  qq1 text := 'SELECT patient_num::bigint, MAX(COALESCE(end_date::date,start_date::date)) AS end_date
              FROM i2b2demodata.observation_fact
              WHERE patient_num=ANY($1) AND (concept_cd != ALL($2) OR modifier_cd != ALL($3))
              GROUP BY patient_num';

BEGIN




RETURN QUERY EXECUTE qq1
USING patient_list, end_code, end_modifier_code;


END;
$_$;


ALTER FUNCTION i2b2demodata.censoring_event(patient_list integer[], end_code character varying[], end_modifier_code character varying[]) OWNER TO postgres;

--
-- Name: create_temp_concept_table(text); Type: FUNCTION; Schema: i2b2demodata; Owner: postgres
--

CREATE FUNCTION i2b2demodata.create_temp_concept_table(tempconcepttablename text, OUT errormsg text) RETURNS text
    LANGUAGE plpgsql
    AS $$
BEGIN 
    EXECUTE 'create table ' ||  tempConceptTableName || ' (
        CONCEPT_CD varchar(50) NOT NULL, 
        CONCEPT_PATH varchar(900) NOT NULL , 
        NAME_CHAR varchar(2000), 
        CONCEPT_BLOB text, 
        UPDATE_DATE timestamp, 
        DOWNLOAD_DATE timestamp, 
        IMPORT_DATE timestamp, 
        SOURCESYSTEM_CD varchar(50)
    ) WITH OIDS';
    EXECUTE 'CREATE INDEX idx_' || tempConceptTableName || '_pat_id ON ' || tempConceptTableName || '  (CONCEPT_PATH)';
    EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'An error was encountered - % -ERROR- %',SQLSTATE,SQLERRM;      
END;
$$;


ALTER FUNCTION i2b2demodata.create_temp_concept_table(tempconcepttablename text, OUT errormsg text) OWNER TO postgres;

--
-- Name: create_temp_eid_table(text); Type: FUNCTION; Schema: i2b2demodata; Owner: postgres
--

CREATE FUNCTION i2b2demodata.create_temp_eid_table(temppatientmappingtablename text, OUT errormsg text) RETURNS text
    LANGUAGE plpgsql
    AS $$
BEGIN 
    EXECUTE 'create table ' ||  tempPatientMappingTableName || ' (
        ENCOUNTER_MAP_ID        varchar(200) NOT NULL,
        ENCOUNTER_MAP_ID_SOURCE     varchar(50) NOT NULL,
        PATIENT_MAP_ID          varchar(200), 
        PATIENT_MAP_ID_SOURCE   varchar(50), 
        ENCOUNTER_ID            varchar(200) NOT NULL,
        ENCOUNTER_ID_SOURCE     varchar(50) ,
        ENCOUNTER_NUM           numeric, 
        ENCOUNTER_MAP_ID_STATUS    varchar(50),
        PROCESS_STATUS_FLAG     char(1),
        UPDATE_DATE timestamp, 
        DOWNLOAD_DATE timestamp, 
        IMPORT_DATE timestamp, 
        SOURCESYSTEM_CD varchar(50)
    ) WITH OIDS';
    EXECUTE 'CREATE INDEX idx_' || tempPatientMappingTableName || '_eid_id ON ' || tempPatientMappingTableName || '  (ENCOUNTER_ID, ENCOUNTER_ID_SOURCE, ENCOUNTER_MAP_ID, ENCOUNTER_MAP_ID_SOURCE, ENCOUNTER_NUM)';
    EXECUTE 'CREATE INDEX idx_' || tempPatientMappingTableName || '_stateid_eid_id ON ' || tempPatientMappingTableName || '  (PROCESS_STATUS_FLAG)';  
    EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '%%%', SQLSTATE || ' - ' || SQLERRM;
END;
$$;


ALTER FUNCTION i2b2demodata.create_temp_eid_table(temppatientmappingtablename text, OUT errormsg text) OWNER TO postgres;

--
-- Name: create_temp_modifier_table(text); Type: FUNCTION; Schema: i2b2demodata; Owner: postgres
--

CREATE FUNCTION i2b2demodata.create_temp_modifier_table(tempmodifiertablename text, OUT errormsg text) RETURNS text
    LANGUAGE plpgsql
    AS $$
BEGIN 
EXECUTE 'create table ' ||  tempModifierTableName || ' (
        MODIFIER_CD varchar(50) NOT NULL, 
        MODIFIER_PATH varchar(900) NOT NULL , 
        NAME_CHAR varchar(2000), 
        MODIFIER_BLOB text, 
        UPDATE_DATE timestamp, 
        DOWNLOAD_DATE timestamp, 
        IMPORT_DATE timestamp, 
        SOURCESYSTEM_CD varchar(50)
         ) WITH OIDS';
 EXECUTE 'CREATE INDEX idx_' || tempModifierTableName || '_pat_id ON ' || tempModifierTableName || '  (MODIFIER_PATH)';
EXCEPTION
        WHEN OTHERS THEN
        RAISE EXCEPTION 'An error was encountered - % -ERROR- %',SQLSTATE,SQLERRM;      
END;
$$;


ALTER FUNCTION i2b2demodata.create_temp_modifier_table(tempmodifiertablename text, OUT errormsg text) OWNER TO postgres;

--
-- Name: create_temp_patient_table(text); Type: FUNCTION; Schema: i2b2demodata; Owner: postgres
--

CREATE FUNCTION i2b2demodata.create_temp_patient_table(temppatientdimensiontablename text, OUT errormsg text) RETURNS text
    LANGUAGE plpgsql
    AS $$
BEGIN 
    -- Create temp table to store encounter/visit information
    EXECUTE 'create table ' ||  tempPatientDimensionTableName || ' (
        patient_id varchar(200), 
        patient_id_source varchar(50),
        patient_num numeric(38,0),
        vital_status_cd varchar(50), 
        birth_date timestamp, 
        death_date timestamp, 
        sex_cd char(50), 
        age_in_years_num numeric(5,0), 
        language_cd varchar(50), 
        race_cd varchar(50 ), 
        marital_status_cd varchar(50), 
        religion_cd varchar(50), 
        zip_cd varchar(50), 
        statecityzip_path varchar(700), 
        patient_blob text, 
        update_date timestamp, 
        download_date timestamp, 
        import_date timestamp, 
        sourcesystem_cd varchar(50)
    )';
    EXECUTE 'CREATE INDEX idx_' || tempPatientDimensionTableName || '_pat_id ON ' || tempPatientDimensionTableName || '  (patient_id, patient_id_source,patient_num)';
    EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '%%%', SQLSTATE || ' - ' || SQLERRM;
END;
$$;


ALTER FUNCTION i2b2demodata.create_temp_patient_table(temppatientdimensiontablename text, OUT errormsg text) OWNER TO postgres;

--
-- Name: create_temp_pid_table(text); Type: FUNCTION; Schema: i2b2demodata; Owner: postgres
--

CREATE FUNCTION i2b2demodata.create_temp_pid_table(temppatientmappingtablename text, OUT errormsg text) RETURNS text
    LANGUAGE plpgsql
    AS $$
BEGIN 
	EXECUTE 'create table ' ||  tempPatientMappingTableName || ' (
		PATIENT_MAP_ID varchar(200), 
		PATIENT_MAP_ID_SOURCE varchar(50), 
		PATIENT_ID_STATUS varchar(50), 
		PATIENT_ID  varchar(200),
		PATIENT_ID_SOURCE varchar(50),
		PATIENT_NUM numeric(38,0),
		PATIENT_MAP_ID_STATUS varchar(50), 
		PROCESS_STATUS_FLAG char(1), 
		UPDATE_DATE timestamp, 
		DOWNLOAD_DATE timestamp, 
		IMPORT_DATE timestamp, 
		SOURCESYSTEM_CD varchar(50)
	) WITH OIDS';
	EXECUTE 'CREATE INDEX idx_' || tempPatientMappingTableName || '_pid_id ON ' || tempPatientMappingTableName || '  ( PATIENT_ID, PATIENT_ID_SOURCE )';
	EXECUTE 'CREATE INDEX idx_' || tempPatientMappingTableName || 'map_pid_id ON ' || tempPatientMappingTableName || '  
	( PATIENT_ID, PATIENT_ID_SOURCE,PATIENT_MAP_ID, PATIENT_MAP_ID_SOURCE,  PATIENT_NUM )';
	EXECUTE 'CREATE INDEX idx_' || tempPatientMappingTableName || 'stat_pid_id ON ' || tempPatientMappingTableName || '  
	(PROCESS_STATUS_FLAG)';
	EXCEPTION
	WHEN OTHERS THEN
		RAISE NOTICE '%%%', SQLSTATE || ' - ' || SQLERRM;
END;
$$;


ALTER FUNCTION i2b2demodata.create_temp_pid_table(temppatientmappingtablename text, OUT errormsg text) OWNER TO postgres;

--
-- Name: create_temp_provider_table(text); Type: FUNCTION; Schema: i2b2demodata; Owner: postgres
--

CREATE FUNCTION i2b2demodata.create_temp_provider_table(tempprovidertablename text, OUT errormsg text) RETURNS text
    LANGUAGE plpgsql
    AS $$
BEGIN 
    EXECUTE 'create table ' ||  tempProviderTableName || ' (
        PROVIDER_ID varchar(50) NOT NULL, 
        PROVIDER_PATH varchar(700) NOT NULL, 
        NAME_CHAR varchar(2000), 
        PROVIDER_BLOB text, 
        UPDATE_DATE timestamp, 
        DOWNLOAD_DATE timestamp, 
        IMPORT_DATE timestamp, 
        SOURCESYSTEM_CD varchar(50), 
        UPLOAD_ID numeric
    ) WITH OIDS';
    EXECUTE 'CREATE INDEX idx_' || tempProviderTableName || '_ppath_id ON ' || tempProviderTableName || '  (PROVIDER_PATH)';
    EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'An error was encountered - % -ERROR- %',SQLSTATE,SQLERRM;      

END;
$$;


ALTER FUNCTION i2b2demodata.create_temp_provider_table(tempprovidertablename text, OUT errormsg text) OWNER TO postgres;

--
-- Name: create_temp_table(text); Type: FUNCTION; Schema: i2b2demodata; Owner: postgres
--

CREATE FUNCTION i2b2demodata.create_temp_table(temptablename text, OUT errormsg text) RETURNS text
    LANGUAGE plpgsql
    AS $$
BEGIN 
    EXECUTE 'create table ' ||  tempTableName || '  (
        encounter_num  numeric(38,0),
        encounter_id varchar(200) not null, 
        encounter_id_source varchar(50) not null,
        concept_cd       varchar(50) not null, 
        patient_num numeric(38,0), 
        patient_id  varchar(200) not null,
        patient_id_source  varchar(50) not null,
        provider_id   varchar(50),
        start_date   timestamp, 
        modifier_cd varchar(100),
        instance_num numeric(18,0),
        valtype_cd varchar(50),
        tval_char varchar(255),
        nval_num numeric(18,5),
        valueflag_cd char(50),
        quantity_num numeric(18,5),
        confidence_num numeric(18,0),
        observation_blob text,
        units_cd varchar(50),
        end_date    timestamp,
        location_cd varchar(50),
        update_date  timestamp,
        download_date timestamp,
        import_date timestamp,
        sourcesystem_cd varchar(50) ,
        upload_id integer
    ) WITH OIDS';
    EXECUTE 'CREATE INDEX idx_' || tempTableName || '_pk ON ' || tempTableName || '  ( encounter_num,patient_num,concept_cd,provider_id,start_date,modifier_cd,instance_num)';
    EXECUTE 'CREATE INDEX idx_' || tempTableName || '_enc_pat_id ON ' || tempTableName || '  (encounter_id,encounter_id_source, patient_id,patient_id_source )';
    EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'An error was encountered - % -ERROR- %',SQLSTATE,SQLERRM; 
END;
$$;


ALTER FUNCTION i2b2demodata.create_temp_table(temptablename text, OUT errormsg text) OWNER TO postgres;

--
-- Name: create_temp_visit_table(text); Type: FUNCTION; Schema: i2b2demodata; Owner: postgres
--

CREATE FUNCTION i2b2demodata.create_temp_visit_table(temptablename text, OUT errormsg text) RETURNS text
    LANGUAGE plpgsql
    AS $$
BEGIN 
    -- Create temp table to store encounter/visit information
    EXECUTE 'create table ' ||  tempTableName || ' (
        encounter_id                    varchar(200) not null,
        encounter_id_source             varchar(50) not null, 
        project_id                      varchar(50) not null,
        patient_id                      varchar(200) not null,
        patient_id_source               varchar(50) not null,
        encounter_num                   numeric(38,0), 
        inout_cd                        varchar(50),
        location_cd                     varchar(50),
        location_path                   varchar(900),
        start_date                      timestamp, 
        end_date                        timestamp,
        visit_blob                      text,
        update_date                     timestamp,
        download_date                   timestamp,
        import_date                     timestamp,
        sourcesystem_cd                 varchar(50)
    ) WITH OIDS';
    EXECUTE 'CREATE INDEX idx_' || tempTableName || '_enc_id ON ' || tempTableName || '  ( encounter_id,encounter_id_source,patient_id,patient_id_source )';
    EXECUTE 'CREATE INDEX idx_' || tempTableName || '_patient_id ON ' || tempTableName || '  ( patient_id,patient_id_source )';
    EXCEPTION
    WHEN OTHERS THEN    
        RAISE EXCEPTION 'An error was encountered - % -ERROR- %',SQLSTATE,SQLERRM;    
END;
$$;


ALTER FUNCTION i2b2demodata.create_temp_visit_table(temptablename text, OUT errormsg text) OWNER TO postgres;

--
-- Name: end_events(integer[], character varying[], character varying[]); Type: FUNCTION; Schema: i2b2demodata; Owner: postgres
--

CREATE FUNCTION i2b2demodata.end_events(patient_list integer[], end_code character varying[], end_modifier_code character varying[]) RETURNS TABLE(patient_num bigint, end_date date)
    LANGUAGE plpgsql STABLE PARALLEL SAFE
    AS $_$
DECLARE
  qq1 text := 'SELECT patient_num::bigint,  start_date::date AS end_date FROM i2b2demodata.observation_fact
              WHERE patient_num=ANY($1) AND concept_cd=ANY($2) AND modifier_cd=ANY($3)';

BEGIN



RETURN QUERY EXECUTE qq1
USING patient_list, end_code, end_modifier_code;


END;
$_$;


ALTER FUNCTION i2b2demodata.end_events(patient_list integer[], end_code character varying[], end_modifier_code character varying[]) OWNER TO postgres;

--
-- Name: insert_concept_fromtemp(text, bigint); Type: FUNCTION; Schema: i2b2demodata; Owner: postgres
--

CREATE FUNCTION i2b2demodata.insert_concept_fromtemp(tempconcepttablename text, upload_id bigint, OUT errormsg text) RETURNS text
    LANGUAGE plpgsql
    AS $$
BEGIN 
    --Delete duplicate rows with same encounter and patient combination
    EXECUTE 'DELETE 
    FROM
    ' || tempConceptTableName || ' t1 
    WHERE
    oid > (SELECT  
        min(oid) 
        FROM 
        ' || tempConceptTableName || ' t2
        WHERE 
        t1.concept_cd = t2.concept_cd 
        AND t1.concept_path = t2.concept_path
    )';
    EXECUTE ' UPDATE concept_dimension  
    SET  
    concept_cd=temp.concept_cd
    ,name_char=temp.name_char
    ,concept_blob=temp.concept_blob
    ,update_date=temp.update_date
    ,download_date=temp.download_date
    ,import_date=Now()
    ,sourcesystem_cd=temp.sourcesystem_cd
    ,upload_id=' || UPLOAD_ID  || '
    FROM 
    ' || tempConceptTableName || '  temp   
    WHERE 
    temp.concept_path = concept_dimension.concept_path 
    AND temp.update_date >= concept_dimension.update_date 
    AND EXISTS (SELECT 1 
        FROM ' || tempConceptTableName || ' temp  
        WHERE temp.concept_path = concept_dimension.concept_path 
        AND temp.update_date >= concept_dimension.update_date
    )
    ';
    --Create new patient(patient_mapping) if temp table patient_ide does not exists 
    -- in patient_mapping table.
    EXECUTE 'INSERT INTO concept_dimension  (
        concept_cd
        ,concept_path
        ,name_char
        ,concept_blob
        ,update_date
        ,download_date
        ,import_date
        ,sourcesystem_cd
        ,upload_id
    )
    SELECT  
    concept_cd
    ,concept_path
    ,name_char
    ,concept_blob
    ,update_date
    ,download_date
    ,Now()
    ,sourcesystem_cd
    ,' || upload_id || '
    FROM ' || tempConceptTableName || '  temp
    WHERE NOT EXISTS (SELECT concept_cd 
        FROM concept_dimension cd 
        WHERE cd.concept_path = temp.concept_path)
    ';
    EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'An error was encountered - % -ERROR- %',SQLSTATE,SQLERRM;      
END;
$$;


ALTER FUNCTION i2b2demodata.insert_concept_fromtemp(tempconcepttablename text, upload_id bigint, OUT errormsg text) OWNER TO postgres;

--
-- Name: insert_eid_map_fromtemp(text, bigint); Type: FUNCTION; Schema: i2b2demodata; Owner: postgres
--

CREATE FUNCTION i2b2demodata.insert_eid_map_fromtemp(tempeidtablename text, upload_id bigint, OUT errormsg text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE

existingEncounterNum varchar(32);
maxEncounterNum bigint;
distinctEidCur REFCURSOR;
disEncounterId varchar(100); 
disEncounterIdSource varchar(100);
disPatientId varchar(100);
disPatientIdSource varchar(100);

BEGIN
    EXECUTE ' delete  from ' || tempEidTableName ||  ' t1  where 
    oid > (select min(oid) from ' || tempEidTableName || ' t2 
        where t1.encounter_map_id = t2.encounter_map_id
        and t1.encounter_map_id_source = t2.encounter_map_id_source
        and t1.encounter_id = t2.encounter_id
        and t1.encounter_id_source = t2.encounter_id_source) ';
    LOCK TABLE  encounter_mapping IN EXCLUSIVE MODE NOWAIT;
    select max(encounter_num) into STRICT  maxEncounterNum from encounter_mapping ; 
    if coalesce(maxEncounterNum::text, '') = '' then 
        maxEncounterNum := 0;
    end if;
    open distinctEidCur for EXECUTE 'SELECT distinct encounter_id,encounter_id_source,patient_map_id,patient_map_id_source from ' || tempEidTableName ||' ' ;
    loop
        FETCH distinctEidCur INTO disEncounterId, disEncounterIdSource,disPatientId,disPatientIdSource;
        IF NOT FOUND THEN EXIT; END IF; 
            
            if  disEncounterIdSource = 'HIVE'  THEN 
                begin
                    
                    select encounter_num into existingEncounterNum from encounter_mapping where encounter_num = CAST(disEncounterId AS numeric) and encounter_ide_source = 'HIVE';
                    EXCEPTION  when NO_DATA_FOUND THEN
                        existingEncounterNum := null;
                end;
                if (existingEncounterNum IS NOT NULL AND existingEncounterNum::text <> '') then 
                    EXECUTE ' update ' || tempEidTableName ||' set encounter_num = CAST(encounter_id AS numeric), process_status_flag = ''P''
                    where encounter_id = $1 and not exists (select 1 from encounter_mapping em where em.encounter_ide = encounter_map_id
                        and em.encounter_ide_source = encounter_map_id_source)' using disEncounterId;
                else 
                    
                    if maxEncounterNum < CAST(disEncounterId AS numeric) then 
                        maxEncounterNum := disEncounterId;
                    end if ;
                    EXECUTE ' update ' || tempEidTableName ||' set encounter_num = CAST(encounter_id AS numeric), process_status_flag = ''P'' where 
                    encounter_id =  $1 and encounter_id_source = ''HIVE'' and not exists (select 1 from encounter_mapping em where em.encounter_ide = encounter_map_id
                        and em.encounter_ide_source = encounter_map_id_source)' using disEncounterId;
                end if;    
                
                
            else 
                begin
                    select encounter_num into STRICT  existingEncounterNum from encounter_mapping where encounter_ide = disEncounterId and 
                    encounter_ide_source = disEncounterIdSource and patient_ide=disPatientId and patient_ide_source=disPatientIdSource; 
                    
                    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        existingEncounterNum := null;
                end;
                if existingEncounterNum is not  null then 
                    EXECUTE ' update ' || tempEidTableName ||' set encounter_num = CAST($1 AS numeric) , process_status_flag = ''P''
                    where encounter_id = $2 and not exists (select 1 from encounter_mapping em where em.encounter_ide = encounter_map_id
                        and em.encounter_ide_source = encounter_map_id_source and em.patient_ide_source = patient_map_id_source and em.patient_ide=patient_map_id)' using existingEncounterNum, disEncounterId;
                else 
                    maxEncounterNum := maxEncounterNum + 1 ;
                    
                    EXECUTE ' insert into ' || tempEidTableName ||' (encounter_map_id,encounter_map_id_source,encounter_id,encounter_id_source,encounter_num,process_status_flag
                        ,encounter_map_id_status,update_date,download_date,import_date,sourcesystem_cd,patient_map_id,patient_map_id_source) 
                    values($1,''HIVE'',$2,''HIVE'',$3,''P'',''A'',Now(),Now(),Now(),''edu.harvard.i2b2.crc'',$4,$5)' using maxEncounterNum,maxEncounterNum,maxEncounterNum,disPatientId,disPatientIdSource; 
                    EXECUTE ' update ' || tempEidTableName ||' set encounter_num =  $1 , process_status_flag = ''P'' 
                    where encounter_id = $2 and  not exists (select 1 from 
                        encounter_mapping em where em.encounter_ide = encounter_map_id
                        and em.encounter_ide_source = encounter_map_id_source
                        and em.patient_ide_source = patient_map_id_source and em.patient_ide=patient_map_id)' using maxEncounterNum, disEncounterId;
                end if ;
                
            end if; 
    END LOOP;
    close distinctEidCur ;
    

EXECUTE 'UPDATE encounter_mapping
SET 
encounter_num = CAST(temp.encounter_id AS numeric)
,encounter_ide_status = temp.encounter_map_id_status
,patient_ide   =   temp.patient_map_id 
,patient_ide_source  =	temp.patient_map_id_source 
,update_date = temp.update_date
,download_date  = temp.download_date
,import_date = Now()
,sourcesystem_cd  = temp.sourcesystem_cd
,upload_id = ' || upload_id ||'
FROM '|| tempEidTableName || '  temp
WHERE 
temp.encounter_map_id = encounter_mapping.encounter_ide 
and temp.encounter_map_id_source = encounter_mapping.encounter_ide_source
and temp.patient_map_id = encounter_mapping.patient_ide 
and temp.patient_map_id_source = encounter_mapping.patient_ide_source
and temp.encounter_id_source = ''HIVE''
and coalesce(temp.process_status_flag::text, '''') = ''''  
and coalesce(encounter_mapping.update_date,to_date(''01-JAN-1900'',''DD-MON-YYYY'')) <= coalesce(temp.update_date,to_date(''01-JAN-1900'',''DD-MON-YYYY''))
';

    
    EXECUTE ' insert into encounter_mapping (encounter_ide,encounter_ide_source,encounter_ide_status,encounter_num,patient_ide,patient_ide_source,update_date,download_date,import_date,sourcesystem_cd,upload_id,project_id) 
    SELECT encounter_map_id,encounter_map_id_source,encounter_map_id_status,encounter_num,patient_map_id,patient_map_id_source,update_date,download_date,Now(),sourcesystem_cd,' || upload_id || ' , ''@'' project_id
    FROM ' || tempEidTableName || '  
    WHERE process_status_flag = ''P'' ' ; 
    EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'An error was encountered - % -ERROR- %',SQLSTATE,SQLERRM;
    end;
     $_$;


ALTER FUNCTION i2b2demodata.insert_eid_map_fromtemp(tempeidtablename text, upload_id bigint, OUT errormsg text) OWNER TO postgres;

--
-- Name: insert_encountervisit_fromtemp(text, bigint); Type: FUNCTION; Schema: i2b2demodata; Owner: postgres
--

CREATE FUNCTION i2b2demodata.insert_encountervisit_fromtemp(temptablename text, upload_id bigint, OUT errormsg text) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE

maxEncounterNum bigint; 

BEGIN 
    --Delete duplicate rows with same encounter and patient combination
    EXECUTE 'DELETE FROM ' || tempTableName || ' t1 WHERE oid > 
    (SELECT  min(oid) FROM ' || tempTableName || ' t2
        WHERE t1.encounter_id = t2.encounter_id 
        AND t1.encounter_id_source = t2.encounter_id_source
        AND coalesce(t1.patient_id,'''') = coalesce(t2.patient_id,'''')
        AND coalesce(t1.patient_id_source,'''') = coalesce(t2.patient_id_source,''''))';
    LOCK TABLE  encounter_mapping IN EXCLUSIVE MODE NOWAIT;
    -- select max(encounter_num) into maxEncounterNum from encounter_mapping ;
    --Create new patient(patient_mapping) if temp table patient_ide does not exists 
    -- in patient_mapping table.
    EXECUTE 'INSERT INTO encounter_mapping (
        encounter_ide
        , encounter_ide_source
        , encounter_num
        , patient_ide
        , patient_ide_source
        , encounter_ide_status
        , upload_id
        , project_id
    )
    (SELECT 
        distinctTemp.encounter_id
        , distinctTemp.encounter_id_source
        , CAST(distinctTemp.encounter_id AS numeric)
        , distinctTemp.patient_id
        , distinctTemp.patient_id_source
        , ''A''
        ,  '|| upload_id ||'
        , distinctTemp.project_id
        FROM 
        (SELECT 
            distinct encounter_id
            , encounter_id_source
            , patient_id
            , patient_id_source 
            , project_id
            FROM ' || tempTableName || '  temp
            WHERE 
            NOT EXISTS (SELECT encounter_ide 
                FROM encounter_mapping em 
                WHERE 
                em.encounter_ide = temp.encounter_id 
                AND em.encounter_ide_source = temp.encounter_id_source
            )
            AND encounter_id_source = ''HIVE'' 
    )   distinctTemp
) ' ;
    -- update patient_num for temp table
    EXECUTE ' UPDATE ' ||  tempTableName
    || ' SET encounter_num = (SELECT em.encounter_num
        FROM encounter_mapping em
        WHERE em.encounter_ide = '|| tempTableName ||'.encounter_id
        and em.encounter_ide_source = '|| tempTableName ||'.encounter_id_source 
        and coalesce(em.patient_ide_source,'''') = coalesce('|| tempTableName ||'.patient_id_source,'''')
        and coalesce(em.patient_ide,'''')= coalesce('|| tempTableName ||'.patient_id,'''')
    )
    WHERE EXISTS (SELECT em.encounter_num 
        FROM encounter_mapping em
        WHERE em.encounter_ide = '|| tempTableName ||'.encounter_id
        and em.encounter_ide_source = '||tempTableName||'.encounter_id_source
        and coalesce(em.patient_ide_source,'''') = coalesce('|| tempTableName ||'.patient_id_source,'''')
        and coalesce(em.patient_ide,'''')= coalesce('|| tempTableName ||'.patient_id,''''))';      

    EXECUTE ' UPDATE visit_dimension  SET  
    start_date =temp.start_date
    ,end_date=temp.end_date
    ,inout_cd=temp.inout_cd
    ,location_cd=temp.location_cd
    ,visit_blob=temp.visit_blob
    ,update_date=temp.update_date
    ,download_date=temp.download_date
    ,import_date=Now()
    ,sourcesystem_cd=temp.sourcesystem_cd
    , upload_id=' || UPLOAD_ID  || '
    FROM ' || tempTableName || '  temp       
    WHERE
    temp.encounter_num = visit_dimension.encounter_num 
    AND temp.update_date >= visit_dimension.update_date 
    AND exists (SELECT 1 
        FROM ' || tempTableName || ' temp 
        WHERE temp.encounter_num = visit_dimension.encounter_num 
        AND temp.update_date >= visit_dimension.update_date
    ) ';

    EXECUTE 'INSERT INTO visit_dimension  (encounter_num,patient_num,start_date,end_date,inout_cd,location_cd,visit_blob,update_date,download_date,import_date,sourcesystem_cd, upload_id)
    SELECT temp.encounter_num
    , pm.patient_num,
    temp.start_date,temp.end_date,temp.inout_cd,temp.location_cd,temp.visit_blob,
    temp.update_date,
    temp.download_date,
    Now(), 
    temp.sourcesystem_cd,
    '|| upload_id ||'
    FROM 
    ' || tempTableName || '  temp , patient_mapping pm 
    WHERE 
    (temp.encounter_num IS NOT NULL AND temp.encounter_num::text <> '''') and 
    NOT EXISTS (SELECT encounter_num 
        FROM visit_dimension vd 
        WHERE 
        vd.encounter_num = temp.encounter_num) 
    AND pm.patient_ide = temp.patient_id 
    AND pm.patient_ide_source = temp.patient_id_source
    ';
    EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'An error was encountered - % -ERROR- %',SQLSTATE,SQLERRM;      
END;
$$;


ALTER FUNCTION i2b2demodata.insert_encountervisit_fromtemp(temptablename text, upload_id bigint, OUT errormsg text) OWNER TO postgres;

--
-- Name: insert_modifier_fromtemp(text, bigint); Type: FUNCTION; Schema: i2b2demodata; Owner: postgres
--

CREATE FUNCTION i2b2demodata.insert_modifier_fromtemp(tempmodifiertablename text, upload_id bigint, OUT errormsg text) RETURNS text
    LANGUAGE plpgsql
    AS $$
BEGIN 
    --Delete duplicate rows 
    EXECUTE 'DELETE FROM ' || tempModifierTableName || ' t1 WHERE oid > 
    (SELECT  min(oid) FROM ' || tempModifierTableName || ' t2
        WHERE t1.modifier_cd = t2.modifier_cd 
        AND t1.modifier_path = t2.modifier_path
    )';
    EXECUTE ' UPDATE modifier_dimension  SET  
        modifier_cd=temp.modifier_cd
        ,name_char=temp.name_char
        ,modifier_blob=temp.modifier_blob
        ,update_date=temp.update_date
        ,download_date=temp.download_date
        ,import_date=Now()
        ,sourcesystem_cd=temp.SOURCESYSTEM_CD
        ,upload_id=' || UPLOAD_ID  || ' 
        FROM ' || tempModifierTableName || '  temp
        WHERE 
        temp.modifier_path = modifier_dimension.modifier_path 
        AND temp.update_date >= modifier_dimension.update_date
        AND EXISTS (SELECT 1 
            FROM ' || tempModifierTableName || ' temp  
            WHERE temp.modifier_path = modifier_dimension.modifier_path 
            AND temp.update_date >= modifier_dimension.update_date)
        ';
        --Create new modifier if temp table modifier_path does not exists 
        -- in modifier dimension table.
        EXECUTE 'INSERT INTO modifier_dimension  (
            modifier_cd
            ,modifier_path
            ,name_char
            ,modifier_blob
            ,update_date
            ,download_date
            ,import_date
            ,sourcesystem_cd
            ,upload_id
        )
        SELECT  
        modifier_cd
        ,modifier_path
        ,name_char
        ,modifier_blob
        ,update_date
        ,download_date
        ,Now()
        ,sourcesystem_cd
        ,' || upload_id || '  
        FROM
        ' || tempModifierTableName || '  temp
        WHERE NOT EXISTs (SELECT modifier_cd 
            FROM modifier_dimension cd
            WHERE cd.modifier_path = temp.modifier_path
        )
        ';
        EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'An error was encountered - % -ERROR- %',SQLSTATE,SQLERRM;      
END;
$$;


ALTER FUNCTION i2b2demodata.insert_modifier_fromtemp(tempmodifiertablename text, upload_id bigint, OUT errormsg text) OWNER TO postgres;

--
-- Name: insert_patient_fromtemp(text, bigint); Type: FUNCTION; Schema: i2b2demodata; Owner: postgres
--

CREATE FUNCTION i2b2demodata.insert_patient_fromtemp(temptablename text, upload_id bigint, OUT errormsg text) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE

maxPatientNum bigint; 

BEGIN 
    LOCK TABLE  patient_mapping IN EXCLUSIVE MODE NOWAIT;
    --select max(patient_num) into maxPatientNum from patient_mapping ;
    --Create new patient(patient_mapping) if temp table patient_ide does not exists 
    -- in patient_mapping table.
    EXECUTE ' INSERT INTO patient_mapping (patient_ide,patient_ide_source,patient_num,patient_ide_status, upload_id)
    (SELECT distinctTemp.patient_id, distinctTemp.patient_id_source, CAST(distinctTemp.patient_id AS numeric), ''A'',   '|| upload_id ||'
        FROM 
        (SELECT distinct patient_id, patient_id_source from ' || tempTableName || '  temp
            where  not exists (SELECT patient_ide from patient_mapping pm where pm.patient_ide = temp.patient_id and pm.patient_ide_source = temp.patient_id_source)
            and patient_id_source = ''HIVE'' )   distinctTemp) ';

    -- update patient_num for temp table
    EXECUTE ' UPDATE ' ||  tempTableName
    || ' SET patient_num = (SELECT pm.patient_num
        FROM patient_mapping pm
        WHERE pm.patient_ide = '|| tempTableName ||'.patient_id
        AND pm.patient_ide_source = '|| tempTableName ||'.patient_id_source
    )
    WHERE EXISTS (SELECT pm.patient_num 
        FROM patient_mapping pm
        WHERE pm.patient_ide = '|| tempTableName ||'.patient_id
        AND pm.patient_ide_source = '||tempTableName||'.patient_id_source)';       

    EXECUTE ' UPDATE patient_dimension  SET  
    vital_status_cd = temp.vital_status_cd
    , birth_date = temp.birth_date
    , death_date = temp.death_date
    , sex_cd = temp.sex_cd
    , age_in_years_num = temp.age_in_years_num
    , language_cd = temp.language_cd
    , race_cd = temp.race_cd
    , marital_status_cd = temp.marital_status_cd
    , religion_cd = temp.religion_cd
    , zip_cd = temp.zip_cd
    , statecityzip_path = temp.statecityzip_path
    , patient_blob = temp.patient_blob
    , update_date = temp.update_date
    , download_date = temp.download_date
    , import_date = Now()
    , sourcesystem_cd = temp.sourcesystem_cd 
    , upload_id =  ' || UPLOAD_ID  || '
    FROM  ' || tempTableName || '  temp
    WHERE 
    temp.patient_num = patient_dimension.patient_num 
    AND temp.update_date >= patient_dimension.update_date
    AND EXISTS (select 1 
        FROM ' || tempTableName || ' temp  
        WHERE 
        temp.patient_num = patient_dimension.patient_num 
        AND temp.update_date >= patient_dimension.update_date
    )    ';

    --Create new patient(patient_dimension) for above inserted patient's.
    --If patient_dimension table's patient num does match temp table,
    --then new patient_dimension information is inserted.
    EXECUTE 'INSERT INTO patient_dimension  (patient_num,vital_status_cd, birth_date, death_date,
        sex_cd, age_in_years_num,language_cd,race_cd,marital_status_cd, religion_cd,
        zip_cd,statecityzip_path,patient_blob,update_date,download_date,import_date,sourcesystem_cd,
        upload_id)
    SELECT temp.patient_num,
    temp.vital_status_cd, temp.birth_date, temp.death_date,
    temp.sex_cd, temp.age_in_years_num,temp.language_cd,temp.race_cd,temp.marital_status_cd, temp.religion_cd,
    temp.zip_cd,temp.statecityzip_path,temp.patient_blob,
    temp.update_date,
    temp.download_date,
    Now(),
    temp.sourcesystem_cd,
    '|| upload_id ||'
    FROM 
    ' || tempTableName || '  temp 
    WHERE 
    NOT EXISTS (SELECT patient_num 
        FROM patient_dimension pd 
        WHERE pd.patient_num = temp.patient_num) 
    AND 
    (patient_num IS NOT NULL AND patient_num::text <> '''')
    ';
    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'An error was encountered - % -ERROR- %',SQLSTATE,SQLERRM;

END;
$$;


ALTER FUNCTION i2b2demodata.insert_patient_fromtemp(temptablename text, upload_id bigint, OUT errormsg text) OWNER TO postgres;

--
-- Name: insert_patient_map_fromtemp(text, bigint); Type: FUNCTION; Schema: i2b2demodata; Owner: postgres
--

CREATE FUNCTION i2b2demodata.insert_patient_map_fromtemp(temppatienttablename text, upload_id bigint, OUT errormsg text) RETURNS text
    LANGUAGE plpgsql
    AS $$
BEGIN 
        --Create new patient mapping entry for HIVE patient's if they are not already mapped in mapping table
        EXECUTE 'insert into patient_mapping (
                PERFORM distinct temp.patient_id, temp.patient_id_source,''A'',temp.patient_id ,' || upload_id || '
                from ' || tempPatientTableName ||'  temp 
                where temp.patient_id_source = ''HIVE'' and 
                not exists (select patient_ide from patient_mapping pm where pm.patient_num = temp.patient_id and pm.patient_ide_source = temp.patient_id_source) 
                )'; 
    --Create new visit for above inserted encounter's
        --If Visit table's encounter and patient num does match temp table,
        --then new visit information is created.
        EXECUTE 'MERGE  INTO patient_dimension pd
                   USING ( select case when (ptemp.patient_id_source=''HIVE'') then  cast(ptemp.patient_id as int)
                                       else pmap.patient_num end patient_num,
                                  ptemp.VITAL_STATUS_CD, 
                                  ptemp.BIRTH_DATE,
                                  ptemp.DEATH_DATE, 
                                  ptemp.SEX_CD ,
                                  ptemp.AGE_IN_YEARS_NUM,
                                  ptemp.LANGUAGE_CD,
                                  ptemp.RACE_CD,
                                  ptemp.MARITAL_STATUS_CD,
                                  ptemp.RELIGION_CD,
                                  ptemp.ZIP_CD,
                                                                  ptemp.STATECITYZIP_PATH , 
                                                                  ptemp.PATIENT_BLOB, 
                                                                  ptemp.UPDATE_DATE, 
                                                                  ptemp.DOWNLOAD_DATE, 
                                                                  ptemp.IMPORT_DATE, 
                                                                  ptemp.SOURCESYSTEM_CD
                   from ' || tempPatientTableName || '  ptemp , patient_mapping pmap
                   where   ptemp.patient_id = pmap.patient_ide(+)
                   and ptemp.patient_id_source = pmap.patient_ide_source(+)
           ) temp
                   on (
                                pd.patient_num = temp.patient_num
                    )    
                        when matched then 
                                update  set 
                                        pd.VITAL_STATUS_CD= temp.VITAL_STATUS_CD,
                    pd.BIRTH_DATE= temp.BIRTH_DATE,
                    pd.DEATH_DATE= temp.DEATH_DATE,
                    pd.SEX_CD= temp.SEX_CD,
                    pd.AGE_IN_YEARS_NUM=temp.AGE_IN_YEARS_NUM,
                    pd.LANGUAGE_CD=temp.LANGUAGE_CD,
                    pd.RACE_CD=temp.RACE_CD,
                    pd.MARITAL_STATUS_CD=temp.MARITAL_STATUS_CD,
                    pd.RELIGION_CD=temp.RELIGION_CD,
                    pd.ZIP_CD=temp.ZIP_CD,
                                        pd.STATECITYZIP_PATH =temp.STATECITYZIP_PATH,
                                        pd.PATIENT_BLOB=temp.PATIENT_BLOB,
                                        pd.UPDATE_DATE=temp.UPDATE_DATE,
                                        pd.DOWNLOAD_DATE=temp.DOWNLOAD_DATE,
                                        pd.SOURCESYSTEM_CD=temp.SOURCESYSTEM_CD,
                                        pd.UPLOAD_ID = '||upload_id||'
                    where temp.update_date > pd.update_date
                         when not matched then 
                                insert (
                                        PATIENT_NUM,
                                        VITAL_STATUS_CD,
                    BIRTH_DATE,
                    DEATH_DATE,
                    SEX_CD,
                    AGE_IN_YEARS_NUM,
                    LANGUAGE_CD,
                    RACE_CD,
                    MARITAL_STATUS_CD,
                    RELIGION_CD,
                    ZIP_CD,
                                        STATECITYZIP_PATH,
                                        PATIENT_BLOB,
                                        UPDATE_DATE,
                                        DOWNLOAD_DATE,
                                        SOURCESYSTEM_CD,
                                        import_date,
                        upload_id
                                        ) 
                                values (
                                        temp.PATIENT_NUM,
                                        temp.VITAL_STATUS_CD,
                    temp.BIRTH_DATE,
                    temp.DEATH_DATE,
                    temp.SEX_CD,
                    temp.AGE_IN_YEARS_NUM,
                    temp.LANGUAGE_CD,
                    temp.RACE_CD,
                    temp.MARITAL_STATUS_CD,
                    temp.RELIGION_CD,
                    temp.ZIP_CD,
                                        temp.STATECITYZIP_PATH,
                                        temp.PATIENT_BLOB,
                                        temp.UPDATE_DATE,
                                        temp.DOWNLOAD_DATE,
                                        temp.SOURCESYSTEM_CD,
                                        LOCALTIMESTAMP,
                                '||upload_id||'
                                )';
EXCEPTION
        WHEN OTHERS THEN
                RAISE EXCEPTION 'An error was encountered - % -ERROR- %',SQLSTATE,SQLERRM;      
END;
$$;


ALTER FUNCTION i2b2demodata.insert_patient_map_fromtemp(temppatienttablename text, upload_id bigint, OUT errormsg text) OWNER TO postgres;

--
-- Name: insert_pid_map_fromtemp(text, bigint); Type: FUNCTION; Schema: i2b2demodata; Owner: postgres
--

CREATE FUNCTION i2b2demodata.insert_pid_map_fromtemp(temppidtablename text, upload_id bigint, OUT errormsg text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
existingPatientNum varchar(32);
maxPatientNum bigint;
distinctPidCur REFCURSOR;
disPatientId varchar(100); 
disPatientIdSource varchar(100);
BEGIN
	--delete the doublons
	EXECUTE ' delete  from ' || tempPidTableName ||  ' t1  where 
	oid > (select min(oid) from ' || tempPidTableName || ' t2 
		where t1.patient_map_id = t2.patient_map_id
		and t1.patient_map_id_source = t2.patient_map_id_source) ';
	LOCK TABLE  patient_mapping IN EXCLUSIVE MODE NOWAIT;
	select max(patient_num) into STRICT  maxPatientNum from patient_mapping ; 
	-- set max patient num to zero of the value is null
	if coalesce(maxPatientNum::text, '') = '' then 
		maxPatientNum := 0;
	end if;
	open distinctPidCur for EXECUTE 'SELECT distinct patient_id,patient_id_source from ' || tempPidTableName || '' ;
	loop
		FETCH distinctPidCur INTO disPatientId, disPatientIdSource;
		IF NOT FOUND THEN EXIT; 
	END IF; -- apply on distinctPidCur
	-- dbms_output.put_line(disPatientId);
	if  disPatientIdSource = 'HIVE'  THEN 
		begin
			--check if hive number exist, if so assign that number to reset of map_id's within that pid
			select patient_num into existingPatientNum from patient_mapping where patient_num = CAST(disPatientId AS numeric) and patient_ide_source = 'HIVE';
			EXCEPTION  when NO_DATA_FOUND THEN
				existingPatientNum := null;
		end;
		if (existingPatientNum IS NOT NULL AND existingPatientNum::text <> '') then 
			EXECUTE ' update ' || tempPidTableName ||' set patient_num = CAST(patient_id AS numeric), process_status_flag = ''P''
			where patient_id = $1 and not exists (select 1 from patient_mapping pm where pm.patient_ide = patient_map_id
				and pm.patient_ide_source = patient_map_id_source)' using disPatientId;
		else 
			-- generate new patient_num i.e. take max(patient_num) + 1 
			if maxPatientNum < CAST(disPatientId AS numeric) then 
				maxPatientNum := disPatientId;
			end if ;
			EXECUTE ' update ' || tempPidTableName ||' set patient_num = CAST(patient_id AS numeric), process_status_flag = ''P'' where 
			patient_id = $1 and patient_id_source = ''HIVE'' and not exists (select 1 from patient_mapping pm where pm.patient_ide = patient_map_id
				and pm.patient_ide_source = patient_map_id_source)' using disPatientId;
		end if;    
		-- test if record fectched
		-- dbms_output.put_line(' HIVE ');
	else 
		begin
			select patient_num into STRICT  existingPatientNum from patient_mapping where patient_ide = disPatientId and 
			patient_ide_source = disPatientIdSource ; 
			-- test if record fetched. 
			EXCEPTION
	WHEN NO_DATA_FOUND THEN
		existingPatientNum := null;
		end;
		if (existingPatientNum IS NOT NULL AND existingPatientNum::text <> '') then 
			EXECUTE ' update ' || tempPidTableName ||' set patient_num = CAST($1 AS numeric) , process_status_flag = ''P''
			where patient_id = $2 and not exists (select 1 from patient_mapping pm where pm.patient_ide = patient_map_id
				and pm.patient_ide_source = patient_map_id_source)' using  existingPatientNum,disPatientId;
		else 
			maxPatientNum := maxPatientNum + 1 ; 
			EXECUTE 'insert into ' || tempPidTableName ||' (
				patient_map_id
				,patient_map_id_source
				,patient_id
				,patient_id_source
				,patient_num
				,process_status_flag
				,patient_map_id_status
				,update_date
				,download_date
				,import_date
				,sourcesystem_cd) 
			values(
				$1
				,''HIVE''
				,$2
				,''HIVE''
				,$3
				,''P''
				,''A''
				,Now()
				,Now()
				,Now()
				,''edu.harvard.i2b2.crc''
			)' using maxPatientNum,maxPatientNum,maxPatientNum; 
			EXECUTE 'update ' || tempPidTableName ||' set patient_num =  $1 , process_status_flag = ''P'' 
			where patient_id = $2 and  not exists (select 1 from 
				patient_mapping pm where pm.patient_ide = patient_map_id
				and pm.patient_ide_source = patient_map_id_source)' using maxPatientNum, disPatientId  ;
		end if ;
		-- dbms_output.put_line(' NOT HIVE ');
	end if; 
	END LOOP;
	close distinctPidCur ;
	-- do the mapping update if the update date is old
EXECUTE ' UPDATE patient_mapping
SET 
patient_num = CAST(temp.patient_id AS numeric)
,patient_ide_status = temp.patient_map_id_status
,update_date = temp.update_date
,download_date  = temp.download_date
,import_date = Now()
,sourcesystem_cd  = temp.sourcesystem_cd
,upload_id = ' || upload_id ||'
FROM '|| tempPidTableName || '  temp
WHERE 
temp.patient_map_id = patient_mapping.patient_ide 
and temp.patient_map_id_source = patient_mapping.patient_ide_source
and temp.patient_id_source = ''HIVE''
and coalesce(temp.process_status_flag::text, '''') = ''''  
and coalesce(patient_mapping.update_date,to_date(''01-JAN-1900'',''DD-MON-YYYY'')) <= coalesce(temp.update_date,to_date(''01-JAN-1900'',''DD-MON-YYYY''))
';
	-- insert new mapping records i.e flagged P
	EXECUTE ' insert into patient_mapping (patient_ide,patient_ide_source,patient_ide_status,patient_num,update_date,download_date,import_date,sourcesystem_cd,upload_id,project_id)
	SELECT patient_map_id,patient_map_id_source,patient_map_id_status,patient_num,update_date,download_date,Now(),sourcesystem_cd,' || upload_id ||', ''@'' project_id from '|| tempPidTableName || ' 
	where process_status_flag = ''P'' ' ; 
	EXCEPTION WHEN OTHERS THEN
		RAISE EXCEPTION 'An error was encountered - % -ERROR- %',SQLSTATE,SQLERRM;
	END;
	$_$;


ALTER FUNCTION i2b2demodata.insert_pid_map_fromtemp(temppidtablename text, upload_id bigint, OUT errormsg text) OWNER TO postgres;

--
-- Name: insert_provider_fromtemp(text, bigint); Type: FUNCTION; Schema: i2b2demodata; Owner: postgres
--

CREATE FUNCTION i2b2demodata.insert_provider_fromtemp(tempprovidertablename text, upload_id bigint, OUT errormsg text) RETURNS text
    LANGUAGE plpgsql
    AS $$
BEGIN 
    --Delete duplicate rows with same encounter and patient combination
    EXECUTE 'DELETE FROM ' || tempProviderTableName || ' t1 WHERE oid > 
    (SELECT  min(oid) FROM ' || tempProviderTableName || ' t2
        WHERE t1.provider_id = t2.provider_id 
        AND t1.provider_path = t2.provider_path
    )';
    EXECUTE ' UPDATE provider_dimension  SET  
        provider_id =temp.provider_id
        , name_char = temp.name_char
        , provider_blob = temp.provider_blob
        , update_date=temp.update_date
        , download_date=temp.download_date
        , import_date=Now()
        , sourcesystem_cd=temp.sourcesystem_cd
        , upload_id = ' || upload_id || '
        FROM ' || tempProviderTableName || '  temp 
        WHERE 
        temp.provider_path = provider_dimension.provider_path and temp.update_date >= provider_dimension.update_date 
    AND EXISTS (select 1 from ' || tempProviderTableName || ' temp  where temp.provider_path = provider_dimension.provider_path 
        and temp.update_date >= provider_dimension.update_date) ';

    --Create new patient(patient_mapping) if temp table patient_ide does not exists 
    -- in patient_mapping table.
    EXECUTE 'insert into provider_dimension  (provider_id,provider_path,name_char,provider_blob,update_date,download_date,import_date,sourcesystem_cd,upload_id)
    SELECT  provider_id,provider_path, 
    name_char,provider_blob,
    update_date,download_date,
    Now(),sourcesystem_cd, ' || upload_id || '
    FROM ' || tempProviderTableName || '  temp
    WHERE NOT EXISTS (SELECT provider_id 
        FROM provider_dimension pd 
        WHERE pd.provider_path = temp.provider_path 
    )';
    EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'An error was encountered - % -ERROR- %',SQLSTATE,SQLERRM;      
END;
$$;


ALTER FUNCTION i2b2demodata.insert_provider_fromtemp(tempprovidertablename text, upload_id bigint, OUT errormsg text) OWNER TO postgres;

--
-- Name: remove_temp_table(character varying); Type: FUNCTION; Schema: i2b2demodata; Owner: postgres
--

CREATE FUNCTION i2b2demodata.remove_temp_table(temptablename character varying, OUT errormsg text) RETURNS text
    LANGUAGE plpgsql
    AS $$

DECLARE

BEGIN
    EXECUTE 'DROP TABLE ' || tempTableName|| ' CASCADE ';

EXCEPTION 
WHEN OTHERS THEN
    RAISE EXCEPTION 'An error was encountered - % -ERROR- %',SQLSTATE,SQLERRM;      
END;
$$;


ALTER FUNCTION i2b2demodata.remove_temp_table(temptablename character varying, OUT errormsg text) OWNER TO postgres;

--
-- Name: start_event(integer[], character varying[], character varying[], boolean); Type: FUNCTION; Schema: i2b2demodata; Owner: postgres
--

CREATE FUNCTION i2b2demodata.start_event(patient_list integer[], start_code character varying[], start_modifier_code character varying[], start_earliest boolean) RETURNS TABLE(patient_num bigint, start_date date)
    LANGUAGE plpgsql STABLE PARALLEL SAFE
    AS $_$
DECLARE
  qq1 text := 'SELECT patient_num::bigint, ';
  qq2 text := ' AS start_date FROM i2b2demodata.observation_fact
              WHERE patient_num=ANY($1) AND concept_cd=ANY($2) AND modifier_cd=ANY($3)
              GROUP BY patient_num';

BEGIN

IF start_earliest THEN
    qq1 := qq1 || 'MIN(start_date::date)' ;
  ELSE
    qq1 := qq1 || 'MAX(start_date::date)' ;
END IF ;

qq1 := qq1 || qq2;


RETURN QUERY EXECUTE qq1
USING patient_list, start_code, start_modifier_code;


END;
$_$;


ALTER FUNCTION i2b2demodata.start_event(patient_list integer[], start_code character varying[], start_modifier_code character varying[], start_earliest boolean) OWNER TO postgres;

--
-- Name: sync_clear_concept_table(text, text, bigint); Type: FUNCTION; Schema: i2b2demodata; Owner: postgres
--

CREATE FUNCTION i2b2demodata.sync_clear_concept_table(tempconcepttablename text, backupconcepttablename text, uploadid bigint, OUT errormsg text) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
 
interConceptTableName  varchar(400);

BEGIN 
        interConceptTableName := backupConceptTableName || '_inter';
                --Delete duplicate rows with same encounter and patient combination
        EXECUTE 'DELETE FROM ' || tempConceptTableName || ' t1 WHERE oid > 
                                           (SELECT  min(oid) FROM ' || tempConceptTableName || ' t2
                                             WHERE t1.concept_cd = t2.concept_cd 
                                            AND t1.concept_path = t2.concept_path
                                            )';
    EXECUTE 'create table ' ||  interConceptTableName || ' (
    CONCEPT_CD          varchar(50) NOT NULL,
        CONCEPT_PATH            varchar(700) NOT NULL,
        NAME_CHAR               varchar(2000) NULL,
        CONCEPT_BLOB        text NULL,
        UPDATE_DATE         timestamp NULL,
        DOWNLOAD_DATE       timestamp NULL,
        IMPORT_DATE         timestamp NULL,
        SOURCESYSTEM_CD     varchar(50) NULL,
        UPLOAD_ID               numeric(38,0) NULL,
    CONSTRAINT '|| interConceptTableName ||'_pk  PRIMARY KEY(CONCEPT_PATH)
         )';
    --Create new patient(patient_mapping) if temp table patient_ide does not exists 
        -- in patient_mapping table.
        EXECUTE 'insert into '|| interConceptTableName ||'  (concept_cd,concept_path,name_char,concept_blob,update_date,download_date,import_date,sourcesystem_cd,upload_id)
                            PERFORM  concept_cd, substring(concept_path from 1 for 700),
                        name_char,concept_blob,
                        update_date,download_date,
                        LOCALTIMESTAMP,sourcesystem_cd,
                         ' || uploadId || '  from ' || tempConceptTableName || '  temp ';
        --backup the concept_dimension table before creating a new one
        EXECUTE 'alter table concept_dimension rename to ' || backupConceptTableName  ||'' ;
        -- add index on upload_id 
    EXECUTE 'CREATE INDEX ' || interConceptTableName || '_uid_idx ON ' || interConceptTableName || '(UPLOAD_ID)';
    -- add index on upload_id 
    EXECUTE 'CREATE INDEX ' || interConceptTableName || '_cd_idx ON ' || interConceptTableName || '(concept_cd)';
    --backup the concept_dimension table before creating a new one
        EXECUTE 'alter table ' || interConceptTableName  || ' rename to concept_dimension' ;
EXCEPTION
        WHEN OTHERS THEN
                RAISE EXCEPTION 'An error was encountered - % -ERROR- %',SQLSTATE,SQLERRM;      
END;
$$;


ALTER FUNCTION i2b2demodata.sync_clear_concept_table(tempconcepttablename text, backupconcepttablename text, uploadid bigint, OUT errormsg text) OWNER TO postgres;

--
-- Name: sync_clear_modifier_table(text, text, bigint); Type: FUNCTION; Schema: i2b2demodata; Owner: postgres
--

CREATE FUNCTION i2b2demodata.sync_clear_modifier_table(tempmodifiertablename text, backupmodifiertablename text, uploadid bigint, OUT errormsg text) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
 
interModifierTableName  varchar(400);

BEGIN 
        interModifierTableName := backupModifierTableName || '_inter';
        --Delete duplicate rows with same modifier_path and modifier cd
        EXECUTE 'DELETE FROM ' || tempModifierTableName || ' t1 WHERE oid > 
                                           (SELECT  min(oid) FROM ' || tempModifierTableName || ' t2
                                             WHERE t1.modifier_cd = t2.modifier_cd 
                                            AND t1.modifier_path = t2.modifier_path
                                            )';
    EXECUTE 'create table ' ||  interModifierTableName || ' (
        MODIFIER_CD          varchar(50) NOT NULL,
        MODIFIER_PATH           varchar(700) NOT NULL,
        NAME_CHAR               varchar(2000) NULL,
        MODIFIER_BLOB        text NULL,
        UPDATE_DATE         timestamp NULL,
        DOWNLOAD_DATE       timestamp NULL,
        IMPORT_DATE         timestamp NULL,
        SOURCESYSTEM_CD     varchar(50) NULL,
        UPLOAD_ID               numeric(38,0) NULL,
    CONSTRAINT '|| interModifierTableName ||'_pk  PRIMARY KEY(MODIFIER_PATH)
         )';
    --Create new patient(patient_mapping) if temp table patient_ide does not exists 
        -- in patient_mapping table.
        EXECUTE 'insert into '|| interModifierTableName ||'  (modifier_cd,modifier_path,name_char,modifier_blob,update_date,download_date,import_date,sourcesystem_cd,upload_id)
                            PERFORM  modifier_cd, substring(modifier_path from 1 for 700),
                        name_char,modifier_blob,
                        update_date,download_date,
                        LOCALTIMESTAMP,sourcesystem_cd,
                         ' || uploadId || '  from ' || tempModifierTableName || '  temp ';
        --backup the modifier_dimension table before creating a new one
        EXECUTE 'alter table modifier_dimension rename to ' || backupModifierTableName  ||'' ;
        -- add index on upload_id 
    EXECUTE 'CREATE INDEX ' || interModifierTableName || '_uid_idx ON ' || interModifierTableName || '(UPLOAD_ID)';
    -- add index on upload_id 
    EXECUTE 'CREATE INDEX ' || interModifierTableName || '_cd_idx ON ' || interModifierTableName || '(modifier_cd)';
       --backup the modifier_dimension table before creating a new one
        EXECUTE 'alter table ' || interModifierTableName  || ' rename to modifier_dimension' ;
EXCEPTION
        WHEN OTHERS THEN
                RAISE EXCEPTION 'An error was encountered - % -ERROR- %',SQLSTATE,SQLERRM;      
END;
$$;


ALTER FUNCTION i2b2demodata.sync_clear_modifier_table(tempmodifiertablename text, backupmodifiertablename text, uploadid bigint, OUT errormsg text) OWNER TO postgres;

--
-- Name: sync_clear_provider_table(text, text, bigint); Type: FUNCTION; Schema: i2b2demodata; Owner: postgres
--

CREATE FUNCTION i2b2demodata.sync_clear_provider_table(tempprovidertablename text, backupprovidertablename text, uploadid bigint, OUT errormsg text) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
 
interProviderTableName  varchar(400);

BEGIN 
        interProviderTableName := backupProviderTableName || '_inter';
                --Delete duplicate rows with same encounter and patient combination
        EXECUTE 'DELETE FROM ' || tempProviderTableName || ' t1 WHERE oid > 
                                           (SELECT  min(oid) FROM ' || tempProviderTableName || ' t2
                                             WHERE t1.provider_id = t2.provider_id 
                                            AND t1.provider_path = t2.provider_path
                                            )';
    EXECUTE 'create table ' ||  interProviderTableName || ' (
    PROVIDER_ID         varchar(50) NOT NULL,
        PROVIDER_PATH       varchar(700) NOT NULL,
        NAME_CHAR               varchar(850) NULL,
        PROVIDER_BLOB       text NULL,
        UPDATE_DATE             timestamp NULL,
        DOWNLOAD_DATE       timestamp NULL,
        IMPORT_DATE         timestamp NULL,
        SOURCESYSTEM_CD     varchar(50) NULL,
        UPLOAD_ID               numeric(38,0) NULL ,
    CONSTRAINT  ' || interProviderTableName || '_pk PRIMARY KEY(PROVIDER_PATH,provider_id)
         )';
    --Create new patient(patient_mapping) if temp table patient_ide does not exists 
        -- in patient_mapping table.
        EXECUTE 'insert into ' ||  interProviderTableName || ' (provider_id,provider_path,name_char,provider_blob,update_date,download_date,import_date,sourcesystem_cd,upload_id)
                            PERFORM  provider_id,provider_path, 
                        name_char,provider_blob,
                        update_date,download_date,
                        LOCALTIMESTAMP,sourcesystem_cd, ' || uploadId || '
                             from ' || tempProviderTableName || '  temp ';
        --backup the concept_dimension table before creating a new one
        EXECUTE 'alter table provider_dimension rename to ' || backupProviderTableName  ||'' ;
        -- add index on provider_id, name_char 
    EXECUTE 'CREATE INDEX ' || interProviderTableName || '_id_idx ON ' || interProviderTableName  || '(Provider_Id,name_char)';
    EXECUTE 'CREATE INDEX ' || interProviderTableName || '_uid_idx ON ' || interProviderTableName  || '(UPLOAD_ID)';
        --backup the concept_dimension table before creating a new one
        EXECUTE 'alter table ' || interProviderTableName  || ' rename to provider_dimension' ;
EXCEPTION
        WHEN OTHERS THEN
                RAISE EXCEPTION 'An error was encountered - % -ERROR- %',SQLSTATE,SQLERRM;      
END;
$$;


ALTER FUNCTION i2b2demodata.sync_clear_provider_table(tempprovidertablename text, backupprovidertablename text, uploadid bigint, OUT errormsg text) OWNER TO postgres;

--
-- Name: update_observation_fact(text, bigint, bigint); Type: FUNCTION; Schema: i2b2demodata; Owner: postgres
--

CREATE FUNCTION i2b2demodata.update_observation_fact(upload_temptable_name text, upload_id bigint, appendflag bigint, OUT errormsg text) RETURNS text
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- appendFlag = 0 -> remove all and then insert
    -- appendFlag <> 0 -> do update, then insert what have not been updated    

    --Delete duplicate records(encounter_ide,patient_ide,concept_cd,start_date,modifier_cd,provider_id)
    EXECUTE 'DELETE FROM ' || upload_temptable_name ||'  t1 
    WHERE oid > (select min(oid) FROM ' || upload_temptable_name ||' t2 
        WHERE t1.encounter_id = t2.encounter_id  
        AND
        t1.encounter_id_source = t2.encounter_id_source
        AND
        t1.patient_id = t2.patient_id 
        AND 
        t1.patient_id_source = t2.patient_id_source
        AND 
        t1.concept_cd = t2.concept_cd
        AND 
        t1.start_date = t2.start_date
        AND 
        coalesce(t1.modifier_cd,''xyz'') = coalesce(t2.modifier_cd,''xyz'')
        AND 
        t1.instance_num = t2.instance_num
        AND 
        t1.provider_id = t2.provider_id)';
    --Delete records having null in start_date
    EXECUTE 'DELETE FROM ' || upload_temptable_name ||'  t1           
    WHERE coalesce(t1.start_date::text, '''') = '''' 
    ';
    --One time lookup on encounter_ide to get encounter_num 
    EXECUTE 'UPDATE ' ||  upload_temptable_name
    || ' SET encounter_num = (SELECT distinct em.encounter_num
        FROM encounter_mapping em
        WHERE em.encounter_ide = ' || upload_temptable_name||'.encounter_id
        AND em.encounter_ide_source = '|| upload_temptable_name||'.encounter_id_source
        and em.project_id=''@'' and em.patient_ide = ' || upload_temptable_name||'.patient_id
        and em.patient_ide_source = '|| upload_temptable_name||'.patient_id_source
    )
    WHERE EXISTS (SELECT distinct em.encounter_num
        FROM encounter_mapping em
        WHERE em.encounter_ide = '|| upload_temptable_name||'.encounter_id
        AND em.encounter_ide_source = '||upload_temptable_name||'.encounter_id_source
                     and em.project_id=''@'' and em.patient_ide = ' || upload_temptable_name||'.patient_id
                     and em.patient_ide_source = '|| upload_temptable_name||'.patient_id_source)';		     
             
    --One time lookup on patient_ide to get patient_num 
    EXECUTE 'UPDATE ' ||  upload_temptable_name
    || ' SET patient_num = (SELECT distinct pm.patient_num
        FROM patient_mapping pm
        WHERE pm.patient_ide = '|| upload_temptable_name||'.patient_id
        AND pm.patient_ide_source = '|| upload_temptable_name||'.patient_id_source
                     and pm.project_id=''@''

    )
    WHERE EXISTS (SELECT distinct pm.patient_num 
        FROM patient_mapping pm
        WHERE pm.patient_ide = '|| upload_temptable_name||'.patient_id
        AND pm.patient_ide_source = '||upload_temptable_name||'.patient_id_source              
                     and pm.project_id=''@'')';		     

    IF (appendFlag = 0) THEN
        --Archive records which are to be deleted in observation_fact table
        EXECUTE 'INSERT INTO  archive_observation_fact 
        SELECT obsfact.*, ' || upload_id ||'
        FROM observation_fact obsfact
        WHERE obsfact.encounter_num IN 
        (SELECT temp_obsfact.encounter_num
            FROM  ' ||upload_temptable_name ||' temp_obsfact
            GROUP BY temp_obsfact.encounter_num  
        )';
        --Delete above archived row FROM observation_fact
        EXECUTE 'DELETE  
        FROM observation_fact 
        WHERE EXISTS (
            SELECT archive.encounter_num
            FROM archive_observation_fact  archive
            WHERE archive.archive_upload_id = '||upload_id ||'
            AND archive.encounter_num=observation_fact.encounter_num
            AND archive.concept_cd = observation_fact.concept_cd
            AND archive.start_date = observation_fact.start_date
        )';
END IF;
-- if the append is true, then do the update else do insert all
IF (appendFlag <> 0) THEN -- update
    EXECUTE ' 
    UPDATE observation_fact f    
    SET valtype_cd = temp.valtype_cd ,
    tval_char=temp.tval_char, 
    nval_num = temp.nval_num,
    valueflag_cd=temp.valueflag_cd,
    quantity_num=temp.quantity_num,
    confidence_num=temp.confidence_num,
    observation_blob =temp.observation_blob,
    units_cd=temp.units_cd,
    end_date=temp.end_date,
    location_cd =temp.location_cd,
    update_date=temp.update_date ,
    download_date =temp.download_date,
    import_date=temp.import_date,
    sourcesystem_cd =temp.sourcesystem_cd,
    upload_id = temp.upload_id 
    FROM ' || upload_temptable_name ||' temp
    WHERE 
    temp.patient_num is not null 
    and temp.encounter_num is not null 
    and temp.encounter_num = f.encounter_num 
    and temp.patient_num = f.patient_num
    and temp.concept_cd = f.concept_cd
    and temp.start_date = f.start_date
    and temp.provider_id = f.provider_id
    and temp.modifier_cd = f.modifier_cd 
    and temp.instance_num = f.instance_num
    and coalesce(f.update_date,to_date(''01-JAN-1900'',''DD-MON-YYYY'')) <= coalesce(temp.update_date,to_date(''01-JAN-1900'',''DD-MON-YYYY''))';

    EXECUTE  'DELETE FROM ' || upload_temptable_name ||' temp WHERE EXISTS (SELECT 1 
        FROM observation_fact f 
        WHERE temp.patient_num is not null 
        and temp.encounter_num is not null 
        and temp.encounter_num = f.encounter_num 
        and temp.patient_num = f.patient_num
        and temp.concept_cd = f.concept_cd
        and temp.start_date = f.start_date
        and temp.provider_id = f.provider_id
        and temp.modifier_cd = f.modifier_cd 
        and temp.instance_num = f.instance_num
    )';

END IF;
--Transfer all rows FROM temp_obsfact to observation_fact
EXECUTE 'INSERT INTO observation_fact(
    encounter_num
    ,concept_cd
    , patient_num
    ,provider_id
    , start_date
    ,modifier_cd
    ,instance_num
    ,valtype_cd
    ,tval_char
    ,nval_num
    ,valueflag_cd
    ,quantity_num
    ,confidence_num
    ,observation_blob
    ,units_cd
    ,end_date
    ,location_cd
    , update_date
    ,download_date
    ,import_date
    ,sourcesystem_cd
    ,upload_id)
SELECT encounter_num
,concept_cd
, patient_num
,provider_id
, start_date
,modifier_cd
,instance_num
,valtype_cd
,tval_char
,nval_num
,valueflag_cd
,quantity_num
,confidence_num
,observation_blob
,units_cd
,end_date
,location_cd
, update_date
,download_date
,Now()
,sourcesystem_cd
,temp.upload_id 
FROM ' || upload_temptable_name ||' temp
WHERE (temp.patient_num IS NOT NULL AND temp.patient_num::text <> '''') AND  (temp.encounter_num IS NOT NULL AND temp.encounter_num::text <> '''')';


EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'An error was encountered - % -ERROR- %',SQLSTATE,SQLERRM;      
END;
$$;


ALTER FUNCTION i2b2demodata.update_observation_fact(upload_temptable_name text, upload_id bigint, appendflag bigint, OUT errormsg text) OWNER TO postgres;

--
-- Name: buildtotalnumreport(integer, double precision); Type: FUNCTION; Schema: i2b2metadata; Owner: postgres
--

CREATE FUNCTION i2b2metadata.buildtotalnumreport(threshold integer, sigma double precision) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN

    truncate table totalnum_report;

    insert into totalnum_report(c_fullname, agg_count, agg_date)
     select c_fullname, case sign(agg_count - threshold + 1 ) when 1 then (round(agg_count/5.0,0)*5)+round(random_normal(0,sigma,threshold)) else -1 end agg_count, 
       to_char(agg_date,'YYYY-MM-DD') agg_date from 
       (select * from 
           (select row_number() over (partition by c_fullname order by agg_date desc) rn,c_fullname, agg_count,agg_date from totalnum where typeflag_cd like 'P%') x where rn=1) y;

    update totalnum_report set agg_count=-1 where agg_count<threshold;

END;
$$;


ALTER FUNCTION i2b2metadata.buildtotalnumreport(threshold integer, sigma double precision) OWNER TO postgres;

--
-- Name: get_concept_codes(character varying, character varying); Type: FUNCTION; Schema: i2b2metadata; Owner: postgres
--

CREATE FUNCTION i2b2metadata.get_concept_codes(ontology character varying, path character varying) RETURNS SETOF character varying
    LANGUAGE plpgsql STABLE PARALLEL SAFE
    AS $_$ 
BEGIN

    RETURN QUERY EXECUTE format(
      'SELECT c_basecode
	      FROM i2b2metadata.%I
	      WHERE (c_basecode IS NOT NULL AND c_basecode != %L
			    AND upper(c_facttablecolumn) = %L
		      AND c_fullname LIKE $1);',
      ontology, '', 'CONCEPT_CD'
    )
    USING path;
  END;
  $_$;


ALTER FUNCTION i2b2metadata.get_concept_codes(ontology character varying, path character varying) OWNER TO postgres;

--
-- Name: get_modifier_codes(character varying, character varying, character varying); Type: FUNCTION; Schema: i2b2metadata; Owner: postgres
--

CREATE FUNCTION i2b2metadata.get_modifier_codes(ontology character varying, path character varying, applied_path character varying) RETURNS SETOF character varying
    LANGUAGE plpgsql STABLE PARALLEL SAFE
    AS $_$ 
BEGIN

    RETURN QUERY EXECUTE format(
      'SELECT c_basecode
	      FROM i2b2metadata.%I
	      WHERE (c_basecode IS NOT NULL AND c_basecode != %L
			    AND upper(c_facttablecolumn) = %L
		      AND c_fullname LIKE $1 AND m_applied_path = $2);',
      ontology, '', 'MODIFIER_CD'
    )
    USING path, applied_path;
  END;
  $_$;


ALTER FUNCTION i2b2metadata.get_modifier_codes(ontology character varying, path character varying, applied_path character varying) OWNER TO postgres;

--
-- Name: get_ontology_elements(character varying, integer); Type: FUNCTION; Schema: i2b2metadata; Owner: postgres
--

CREATE FUNCTION i2b2metadata.get_ontology_elements(search_string character varying, lim integer DEFAULT 10) RETURNS TABLE(c_fullname character varying, c_name character varying, c_visualattributes character, c_basecode character varying, c_metadataxml text, c_comment text, m_applied_path character varying, id integer, fullpath text)
    LANGUAGE plpgsql PARALLEL SAFE
    AS $_$
DECLARE
      rec record;
      strSQL text;
	  tableCode text;
	  tableName text;
	  elements text[];
	  parentPath text;
	  i int;
BEGIN

	strSQL := '';

    -- create statement to retrieve all matching concepts from all tables in i2b2metadata.table_access
    -- and store them into the temporary table "ontology_elements"
    FOR rec IN SELECT DISTINCT c_table_name FROM i2b2metadata.table_access
    LOOP
		strSQL := strSQL || 'SELECT c_fullname, c_name, c_visualattributes, c_basecode, c_metadataxml, c_comment, m_applied_path
          		FROM i2b2metadata.' || lower(rec.c_table_name) || '
         		WHERE lower(c_name) LIKE $1
				UNION ALL ';
    END LOOP;
    strSQL := 'CREATE TEMP TABLE ontology_elements AS '  || trim(trailing ' UNION ALL ' from strSQL) || ' ORDER BY c_fullname LIMIT $2;';

    -- execute the statement
	EXECUTE strSQL USING '%' || lower(search_string) || '%', lim;

	-- add id column, which will be used to group together the found element and its ancestors
	ALTER TABLE ontology_elements ADD COLUMN id SERIAL;

	-- retrieve the table_cd(s) given the c_fullname(s) found in the previous step
	-- and prepend them to the c_fullname(s) in the temporary table "ontology_elements"
	FOR rec IN SELECT ontology_elements.c_fullname, ontology_elements.m_applied_path FROM ontology_elements
	LOOP
	    IF rec.m_applied_path = '@' THEN -- concept
            tableCode := (SELECT c_table_cd
            FROM i2b2metadata.table_access AS ta
            WHERE POSITION(ta.c_fullname IN rec.c_fullname) = 1
            ORDER BY LENGTH(ta.c_fullname) DESC
            LIMIT 1);
        ELSE -- modifier
            tableCode := (SELECT c_table_cd
            FROM i2b2metadata.table_access AS ta
            WHERE POSITION(ta.c_fullname IN rec.m_applied_path) = 1
            ORDER BY LENGTH(ta.c_fullname) DESC
            LIMIT 1);
        END IF;

        UPDATE ontology_elements
        SET c_fullname = '\\' || tableCode || ontology_elements.c_fullname
        WHERE ontology_elements.c_fullname = rec.c_fullname;
	END LOOP;

	-- add to the table "ontology_elements" the parents of the already present concepts
	FOR rec IN SELECT ontology_elements.c_fullname, ontology_elements.m_applied_path, ontology_elements.id FROM ontology_elements
	LOOP
		elements := regexp_split_to_array(rec.c_fullname, '\\');
		tableCode := elements[3];
		tableName := (SELECT lower(c_table_name)
					FROM i2b2metadata.table_access
					WHERE c_table_cd = tableCode);

		parentPath := E'\\';
		FOR i IN 4 .. array_length(elements, 1) - 2
   		LOOP
			parentPath := parentPath || elements[i] || E'\\';

			-- retrieve information about the parent
			EXECUTE FORMAT(
			'INSERT INTO ontology_elements(c_fullname, c_name, c_visualattributes, c_basecode, c_metadataxml, c_comment, m_applied_path, id)
			SELECT c_fullname, c_name, c_visualattributes, c_basecode, c_metadataxml, c_comment, m_applied_path, %L as id
			FROM i2b2metadata.%I
			WHERE c_fullname = $1', rec.id, tableName)
			USING parentPath;

			-- add the table code
			UPDATE ontology_elements
        	SET c_fullname = '\\' || tableCode || ontology_elements.c_fullname
        	WHERE ontology_elements.c_fullname = parentPath;
  		 END LOOP;

		 -- if the current element is a modifier, search also for the modifier's concept ancestors
		 -- we use the applied path as parent
  		 IF rec.m_applied_path != '@' THEN
  		    elements := regexp_split_to_array(rec.m_applied_path, '\\');

                parentPath := E'\\';
                FOR i IN 2 .. array_length(elements, 1) - 1
                LOOP
                    parentPath := parentPath || elements[i] || E'\\';

                    -- retrieve information about the parent
                    EXECUTE FORMAT(
                    'INSERT INTO ontology_elements(c_fullname, c_name, c_visualattributes, c_basecode, c_metadataxml, c_comment, m_applied_path, id)
                    SELECT c_fullname, c_name, c_visualattributes, c_basecode, c_metadataxml, c_comment, m_applied_path, %L as id
                    FROM i2b2metadata.%I
                    WHERE c_fullname = $1', rec.id, tableName)
                    USING parentPath;

                    -- add the table code
                    UPDATE ontology_elements
                    SET c_fullname = '\\' || tableCode || ontology_elements.c_fullname
                    WHERE ontology_elements.c_fullname = parentPath;
                 END LOOP;
  		 END IF;
	END LOOP;

	-- return the temporary table "ontology_elements" and drop it.
	-- the additional returned fullpath column contains the c_fullname column for the concepts
	-- and the m_applied_path concatenated (in a smart way) to the c_fullname column for the modifiers
	RETURN QUERY SELECT *,
	(SELECT (regexp_matches(ol.c_fullname, '\B\B[^\B]+\B'))[1]) ||
	(SELECT (regexp_replace(TRIM (LEADING E'\\' FROM TRIM(LEADING '@' FROM TRIM(TRAILING '%' FROM ol.m_applied_path))) ||
	ol.c_fullname, '\B\B[^\B]+\B', '')))
	FROM ontology_elements AS ol;
	DROP TABLE ontology_elements;

END;
$_$;


ALTER FUNCTION i2b2metadata.get_ontology_elements(search_string character varying, lim integer) OWNER TO postgres;

--
-- Name: pat_count_dimensions(character varying, character varying, character varying, character varying, character varying, character varying); Type: FUNCTION; Schema: i2b2metadata; Owner: postgres
--

CREATE FUNCTION i2b2metadata.pat_count_dimensions(metadatatable character varying, schemaname character varying, observationtable character varying, facttablecolumn character varying, tablename character varying, columnname character varying) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
declare 
        -- select PAT_COUNT_DIMENSIONS( 'I2B2' ,'public' , 'observation_fact' ,  'concept_cd', 'concept_dimension', 'concept_path'  )
    v_sqlstr text;
    v_num integer;
    curRecord RECORD;
    v_startime timestamp;
    v_duration text = '';
BEGIN
    raise info 'At %, running PAT_COUNT_DIMENSIONS(''%'')',clock_timestamp(), metadataTable;
    v_startime := clock_timestamp();

    DISCARD TEMP;
    -- Modify this query to select a list of all your ontology paths and basecodes.

    v_sqlstr := 'create temp table dimCountOnt AS '
             || ' select c_fullname, c_basecode, c_hlevel '
             || ' from ' || metadataTable  
             || ' where lower(c_facttablecolumn) = '''||facttablecolumn||''' '
             || ' and lower(c_tablename) = '''|| tablename || ''' '
             || ' and lower(c_columnname) = '''|| columnname || ''' '
             || ' and lower(c_synonym_cd) = ''n'' '
             || ' and lower(c_columndatatype) = ''t'' '
             || ' and lower(c_operator) = ''like'' '
             || ' and m_applied_path = ''@'' '
		     || ' and coalesce(c_fullname, '''') <> '''' '
		     || ' and (c_visualattributes not like ''L%'' or  c_basecode in (select distinct concept_cd from ' || lower(schemaName) || '.'|| observationTable || ')) ';
		-- NEW: Sparsify the working ontology by eliminating leaves with no data. HUGE win in ACT meds ontology (10x speedup).
        -- From 1.47M entries to 300k entries!
           
    raise info 'SQL: %',v_sqlstr;
    execute v_sqlstr;

    create index dimCountOntA on dimCountOnt using spgist (c_fullname);
    CREATE INDEX dimCountOntB ON dimCountOnt(c_fullname text_pattern_ops);

    create temp table dimOntWithFolders AS
        select distinct p1.c_fullname, p1.c_basecode
        from dimCountOnt p1
        where 1=0;
        
    CREATE INDEX dimOntWithFoldersIndex ON dimOntWithFolders using btree(c_basecode);


For curRecord IN 
		select c_fullname,c_table_name from table_access 
    LOOP 
if metadataTable = curRecord.c_table_name then
--v_sqlstr := 'insert into dimOntWithFolders select distinct  c_fullname , c_basecode  from  provider_ont where c_fullname like ''' || replace(curRecord.c_fullname,'\','\\') || '%'' ';

--v_sqlstr := 'insert into dimOntWithFolders '
--       || '   select distinct p1.c_fullname, p2.c_basecode '
--       || '   from dimCountOnt p1 '
--       || '   inner join dimCountOnt p2 '
--       || '     on p2.c_fullname like p1.c_fullname || ''%''  '
--       || '     where p2.c_fullname like  ''' || replace(curRecord.c_fullname,'\','\\') || '%'' '
--       || '       and p1.c_fullname like  ''' || replace(curRecord.c_fullname,'\','\\') || '%'' ';


-- Jeff Green's version
v_sqlstr := 'with recursive concepts (c_fullname, c_hlevel, c_basecode) as ('
	|| ' select c_fullname, c_hlevel, c_basecode '
	|| '  from dimCountOnt '
	|| '  where c_fullname like ''' || replace(curRecord.c_fullname,'\','\\') || '%'' '
	|| ' union all ' 
	|| ' select cast( '
	|| '  	left(c_fullname, length(c_fullname)-position(''\'' in right(reverse(c_fullname), length(c_fullname)-1))) '
	|| '	   	as varchar(700) '
	|| '	) c_fullname, ' 
	|| ' c_hlevel-1 c_hlevel, c_basecode '
	|| ' from concepts '
	|| ' where concepts.c_hlevel>0 '
	|| ' ) '
|| ' insert into dimOntWithFolders '
|| ' select distinct c_fullname, c_basecode '
|| '  from concepts '
|| '  where c_fullname like ''' || replace(curRecord.c_fullname,'\','\\') || '%'' '
|| '  order by c_fullname, c_basecode ';
    raise info 'SQL_dimOntWithFolders: %',v_sqlstr;
	execute v_sqlstr;
	--raise notice 'At %, collected concepts for % %',clock_timestamp(),curRecord.c_table_name,curRecord.c_fullname;
	v_duration := clock_timestamp()-v_startime;
	raise info '(BENCH) %,collected_concepts,%',curRecord,v_duration;
	v_startime := clock_timestamp();
 end if;
    END LOOP;
    -- Too slow version
    --v_sqlstr := ' create temp table finalDimCounts AS '
    --    || ' select p1.c_fullname, count(distinct patient_num) as num_patients '
    --    || ' from dimOntWithFolders p1 '
    --    || ' left join ' || schemaName ||'.'|| observationtable ||  '  o '
    --    || '     on p1.c_basecode = o.' || facttablecolumn  --provider id
    --    || '     and coalesce(p1.c_basecode, '''') <> '''' '
    --    || ' group by p1.c_fullname';
    
    -- 10-20x faster version (based on MSSQL optimizations) 
    
    -- Assign a number to each path and use this for the join to the fact table!
    create temp table Path2Num as
    select c_fullname, row_number() over (order by c_fullname) path_num
        from (
            select distinct c_fullname c_fullname
            from dimOntWithFolders
            where c_fullname is not null and c_fullname<>''
        ) t;
    
    alter table Path2Num add primary key (c_fullname);
    
    create temp table ConceptPath as
    select path_num,c_basecode from Path2Num n inner join dimontwithfolders o on o.c_fullname=n.c_fullname
    where o.c_fullname is not null and c_basecode is not null;
    
    alter table ConceptPath add primary key (c_basecode, path_num);
    
  --  create temp table PathCounts as

    v_sqlstr := 'create temp table PathCounts as select p1.path_num, count(distinct patient_num) as num_patients  from ConceptPath p1  left join ' || lower(schemaName) || '.'|| observationTable || '  o      on p1.c_basecode = o.concept_cd     and coalesce(p1.c_basecode, '''') <> ''''  group by p1.path_num';
    

	execute v_sqlstr;

    alter table PathCounts add primary key (path_num);
    
    create temp table finalCountsbyConcept as
    select p.c_fullname, c.num_patients num_patients 
        from PathCounts c
          inner join Path2Num p
           on p.path_num=c.path_num
        order by p.c_fullname;
    --raise notice 'At %, done counting.',clock_timestamp();
	v_duration := clock_timestamp()-v_startime;
	raise info '(BENCH) %,counted_concepts,%',curRecord,v_duration;
	v_startime := clock_timestamp();
    create index on finalCountsbyConcept using btree (c_fullname);
    v_sqlstr := ' update ' || metadataTable || ' a set c_totalnum=b.num_patients '
             || ' from finalCountsbyConcept b '
             || ' where a.c_fullname=b.c_fullname '
            || ' and lower(a.c_facttablecolumn)= ''' || facttablecolumn || ''' '
		    || ' and lower(a.c_tablename) = ''' || tablename || ''' '
		    || ' and lower(a.c_columnname) = ''' || columnname || ''' ';
    select count(*) into v_num from finalCountsByConcept where num_patients is not null and num_patients <> 0;
    raise info 'At %, updating c_totalnum in % %',clock_timestamp(), metadataTable, v_num;
    
	execute v_sqlstr;
	
	-- New 4/2020 - Update the totalnum reporting table as well
	insert into totalnum(c_fullname, agg_date, agg_count, typeflag_cd)
	select c_fullname, current_date, num_patients, 'PF' from finalCountsByConcept where num_patients>0;
    discard temp;
END; 
$$;


ALTER FUNCTION i2b2metadata.pat_count_dimensions(metadatatable character varying, schemaname character varying, observationtable character varying, facttablecolumn character varying, tablename character varying, columnname character varying) OWNER TO postgres;

--
-- Name: pat_count_visits(character varying, character varying); Type: FUNCTION; Schema: i2b2metadata; Owner: postgres
--

CREATE FUNCTION i2b2metadata.pat_count_visits(tabname character varying, tableschema character varying) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
declare 
    v_sqlstr text;
    -- using cursor defined withing FOR RECORD IN QUERY loop below.
    curRecord RECORD;
    v_num integer;
BEGIN
    --display count and timing information to the user
  
    --using all temporary tables instead of creating and dropping tables
    DISCARD TEMP;
    --checking each text fields for forced lowercase values since DB defaults to case sensitive 
	v_sqlstr = 'create temp table ontPatVisitDims as '
          ||    ' select c_fullname'
          ||          ', c_basecode'
          ||          ', c_facttablecolumn'
          ||          ', c_tablename'
          ||          ', c_columnname'
          ||          ', c_operator'
          ||          ', c_dimcode'
          ||          ', null::integer as numpats'
          ||      ' from ' || tabname
          ||      ' where  m_applied_path = ''@'''
          ||        ' and lower(c_tablename) in (''patient_dimension'', ''visit_dimension'') ';

    /*
     * THE ORIGINAL WUSM implementation did not have the column "visit_dimension.location_zip" in 
     *     ||        ' and lower(c_columnname) not in (''location_zip'') '; --ignoring this often occuring column that we know is not in WUSM schema
     */

    execute v_sqlstr;
    
    CREATE INDEX ontPatVisitDimsfname ON ontPatVisitDims(c_fullname);

    -- rather than creating cursor and fetching rows into local variables, instead using record variable type to 
    -- access each element of the current row of the cursor
	For curRecord IN 
		select c_fullname, c_facttablecolumn, c_tablename, c_columnname, c_operator, c_dimcode from ontPatVisitDims
    LOOP 
 --raise info 'At %: Running: %',curRecord.c_tablename, curRecord.c_columnname;
        -- check first to determine if current columns of current table actually exist in the schema
   --     if exists(select 1 from information_schema.columns 
   --               where table_catalog = current_catalog 
   --                 and table_schema = ' || tableschema || '
   --                 and table_name = lower(curRecord.c_tablename)
   --                 and column_name = lower(curRecord.c_columnname)
   --              ) then 

            -- simplified query to directly query distinct patient_num instead of querying list of patien_num to feed into outer query for the same
            -- result.  New style runs in approximately half the time as tested with all patients with a particular sex_cd value.  Since all rows 
            -- Since c_facttablecolumn is ALWAYS populated with 'patient_num' for all rows accessed by this function the change to the function is 
            -- worthwhile.  Only in rare cases if changes to the ontology tables are made would the original query be needed, but only where 
            -- c_facttablecolumn would not be 'patient_num AND the values saved in that column in the dimension table are shared between patients that 
            -- don't otherwise have the same ontology would the original method return different results.  It is believed that those results would be 
            -- inaccurate since they would reflect the number of patients who have XXX like patients with this ontology rather than the number of patients
            -- with that ontology. 
            v_sqlstr := 'update ontPatVisitDims '
                     || ' set numpats =  ( '                     
                     ||     ' select count(distinct(patient_num)) '
                     ||     ' from ' || tableschema || '.' || curRecord.c_tablename 
                     --||     ' where ' || curRecord.c_facttablecolumn
                     --||     ' in ( '
                     --||         ' select ' || curRecord.c_facttablecolumn 
                     --||         ' from ' || tableschema || '.' || curRecord.c_tablename 
                     ||         ' where '|| curRecord.c_columnname || ' '  ;
--Running: update ontPatVisitDims  set numpats =  (  select count(distinct(patient_num))  from public.PATIENT_DIMENSION where RACE_CD = es ) 
            CASE 
            WHEN lower(curRecord.c_columnname) = 'birth_date' 
                 and lower(curRecord.c_tablename) = 'patient_dimension'
                 and lower(curRecord.c_dimcode) like '%not recorded%' then 
                    -- adding specific change of " WHERE patient_dimension.birth_date in ('not_recorded') " to " WHERE patient_dimension.birth_date IS NULL " 
                    -- since IS NULL syntax is not supported in the ontology tables, but the birth_date column is a timestamp datatype and can be null, but cannot be
                    -- the character string 'not recorded'
                    v_sqlstr := v_sqlstr || ' is null';
            WHEN lower(curRecord.c_operator) = 'like' then 
                -- escaping escape characters and double quotes.  The additon of '\' to '\\' is needed in Postgres. Alternatively, a custom escape character
                -- could be listed in the query if it is known for certain that that character will never be found in any c_dimcode value accessed by this 
                -- function
                v_sqlstr := v_sqlstr || curRecord.c_operator  || ' ' || '''' || replace(replace(curRecord.c_dimcode,'\','\\'),'''','''''') || '%''' ;
           WHEN lower(curRecord.c_operator) = 'in' then 
                v_sqlstr := v_sqlstr || curRecord.c_operator  || ' ' ||  '(' || curRecord.c_dimcode || ')';
            WHEN lower(curRecord.c_operator) = '=' then 
           --     v_sqlstr := v_sqlstr || curRecord.c_operator  || ' ' ||  replace(curRecord.c_dimcode,'''','''''') ;
                v_sqlstr := v_sqlstr || curRecord.c_operator  || ' ''' ||  replace(curRecord.c_dimcode,'''','''''') || '''';
            ELSE 
                -- A mistake in WUSM data existed, requiring special handling in this function.  
                -- The original note is listed next for reference purposes only and the IF THEN 
                -- ELSE block that was needed has been commented out since the original mistake 
                -- in the ontology tables has been corrected.

                /* ORIGINAL NOTE AND CODE
                 *   -- a mistake in WUSM data has this c_dimcode incorrectly listed.  It is being handled in this function until other testing and approvals
                 *   -- are conducted to allow for the correction of this value in the ontology table.
                 *   if curRecord.c_dimcode = 'current_date - interval ''85 year''85 year''' then 
                 *       v_sqlstr := v_sqlstr || curRecord.c_operator  || ' ' || 'current_date - interval ''85 year''';
                 *   else
                 */
                        v_sqlstr := v_sqlstr || curRecord.c_operator  || ' ' || curRecord.c_dimcode;
                /* 
                 *   end if;
                 */
            END CASE;
            
            v_sqlstr := v_sqlstr -- || ' ) ' -- in
                     || ' ) ' -- set
                     || ' where c_fullname = ' || '''' || curRecord.c_fullname || '''' 
                     || ' and numpats is null';

    
			begin
            	execute v_sqlstr;
			EXCEPTION WHEN OTHERS THEN
				raise info 'At %: EROR: %',clock_timestamp()e, v_sqlstr;
		      -- keep looping
   			END;
		--else
            -- do nothing since we do not have the column in our schema
     --   end if;
    END LOOP;

	v_sqlstr := 'update ' || tabname || ' a set c_totalnum=b.numpats '
             || ' from ontPatVisitDims b '
             || ' where a.c_fullname=b.c_fullname and b.numpats>0';

    raise info 'At %: Running: %',clock_timestamp()e, v_sqlstr;
 
    --display count and timing information to the user
    select count(*) into v_num from ontPatVisitDims where numpats is not null and numpats <> 0;
    raise info 'At %, updating c_totalnum in % for % records',clock_timestamp(), tabname, v_num;
             
	execute v_sqlstr;
	
	-- New 4/2020 - Update the totalnum reporting table as well
	insert into totalnum(c_fullname, agg_date, agg_count, typeflag_cd)
	select c_fullname, current_date, numpats, 'PD' from ontPatVisitDims;
	
    discard temp;
END;
$$;


ALTER FUNCTION i2b2metadata.pat_count_visits(tabname character varying, tableschema character varying) OWNER TO postgres;

--
-- Name: random_normal(double precision, double precision, integer); Type: FUNCTION; Schema: i2b2metadata; Owner: postgres
--

CREATE FUNCTION i2b2metadata.random_normal(mean double precision DEFAULT 0.0, stddev double precision DEFAULT 1.0, threshold integer DEFAULT 10) RETURNS double precision
    LANGUAGE plpgsql STRICT SECURITY DEFINER
    AS $$
        DECLARE
            u DOUBLE PRECISION;
            v DOUBLE PRECISION;
            s DOUBLE PRECISION;
        BEGIN
            WHILE true LOOP
           
                u = RANDOM() * 2 - 1; -- range: -1.0 <= u < 1.0
                v = RANDOM() * 2 - 1; -- range: -1.0 <= v < 1.0
                s = u^2 + v^2;

                IF s != 0.0 AND s < 1.0 THEN
                    s = SQRT(-2 * LN(s) / s);
    
                    IF stddev * s * u > threshold THEN 
                        RETURN  mean + threshold;
                    ELSIF stddev * s * u < -1 * threshold THEN 
                        RETURN  mean - threshold;
                    ELSE
                        RETURN  mean + stddev * s * u;
                    END IF;
                    
                END IF;
            END LOOP;
        END;
$$;


ALTER FUNCTION i2b2metadata.random_normal(mean double precision, stddev double precision, threshold integer) OWNER TO postgres;

--
-- Name: runtotalnum(text, text, text); Type: FUNCTION; Schema: i2b2metadata; Owner: postgres
--

CREATE FUNCTION i2b2metadata.runtotalnum(observationtable text, schemaname text, tablename text DEFAULT '@'::text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE 
    curRecord RECORD;
    v_sqlstring text = '';
    v_union text = '';
    v_numpats integer;
    v_startime timestamp;
    v_duration text = '';
    denom int;
begin
    raise info 'At %, running RunTotalnum()',clock_timestamp();
    v_startime := clock_timestamp();

    for curRecord IN 
        select distinct c_table_name as sqltext
        from TABLE_ACCESS 
        where c_visualattributes like '%A%' 
    LOOP 
        raise info 'At %: Running: %',clock_timestamp(), curRecord.sqltext;

        IF tableName='@' OR tableName=curRecord.sqltext THEN
            v_sqlstring := 'select  PAT_COUNT_VISITS( '''||curRecord.sqltext||''' ,'''||schemaName||'''   )';
            execute v_sqlstring;
            v_duration := clock_timestamp()-v_startime;
            raise info '(BENCH) %,PAT_COUNT_VISITS,%',curRecord,v_duration;
            v_startime := clock_timestamp();
            
            v_sqlstring := 'select PAT_COUNT_DIMENSIONS( '''||curRecord.sqltext||''' ,'''||schemaName||''' , '''||observationTable||''' ,  ''concept_cd'', ''concept_dimension'', ''concept_path''  )';
            execute v_sqlstring;
            v_duration :=  clock_timestamp()-v_startime;
            raise info '(BENCH) %,PAT_COUNT_concept_dimension,%',curRecord,v_duration;
            v_startime := clock_timestamp();
            
            v_sqlstring := 'select PAT_COUNT_DIMENSIONS( '''||curRecord.sqltext||''' ,'''||schemaName||''' , '''||observationTable||''' ,  ''provider_id'', ''provider_dimension'', ''provider_path''  )';
            execute v_sqlstring;
            v_duration := clock_timestamp()-v_startime;
            raise info '(BENCH) %,PAT_COUNT_provider_dimension,%',curRecord,v_duration;
            v_startime := clock_timestamp();
            
            v_sqlstring := 'select PAT_COUNT_DIMENSIONS( '''||curRecord.sqltext||''' ,'''||schemaName||''' , '''||observationTable||''' ,  ''modifier_cd'', ''modifier_dimension'', ''modifier_path''  )';
            execute v_sqlstring;
            v_duration := clock_timestamp()-v_startime;
            raise info '(BENCH) %,PAT_COUNT_modifier_dimension,%',curRecord,v_duration;
            v_startime := clock_timestamp();
            
             -- New 11/20 - update counts in top levels (table_access) at the end
             execute 'update table_access set c_totalnum=(select c_totalnum from ' || curRecord.sqltext || ' x where x.c_fullname=table_access.c_fullname)';
             -- Null out cases that are actually 0 [1/21]
            execute  'update  ' || curRecord.sqltext || ' set c_totalnum=null where c_totalnum=0 and c_visualattributes like ''C%''';

        END IF;

    END LOOP;
    
      -- Cleanup (1/21)
      update table_access set c_totalnum=null where c_totalnum=0;
      -- Denominator (1/21)
      SELECT count(*) into denom from totalnum where c_fullname='\denominator\facts\' and agg_date=CURRENT_DATE;
      IF denom = 0
      THEN
          execute 'insert into totalnum(c_fullname,agg_date,agg_count,typeflag_cd)
              select ''\denominator\facts\'',CURRENT_DATE,count(distinct patient_num),''PX'' from ' || lower(schemaName) || '.'|| observationTable ;
      END IF;
    
    perform BuildTotalnumReport(10, 6.5);
    
end; 
$$;


ALTER FUNCTION i2b2metadata.runtotalnum(observationtable text, schemaname text, tablename text) OWNER TO postgres;

--
-- Name: table_name(character varying); Type: FUNCTION; Schema: i2b2metadata; Owner: postgres
--

CREATE FUNCTION i2b2metadata.table_name(table_cd character varying) RETURNS character varying
    LANGUAGE plpgsql STABLE PARALLEL SAFE
    AS $_$
DECLARE
  table_name_ varchar;
BEGIN
  EXECUTE 'SELECT c_table_name from i2b2metadata.table_access WHERE c_table_cd = $1;'
  USING table_cd INTO table_name_;
  RETURN table_name_;
END;
$_$;


ALTER FUNCTION i2b2metadata.table_name(table_cd character varying) OWNER TO postgres;

--
-- Name: create_gecoi2b2datasource_schema(name, name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.create_gecoi2b2datasource_schema(schema_name name, user_name name) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
	BEGIN
		EXECUTE 'CREATE SCHEMA ' || schema_name;
		EXECUTE 'GRANT ALL ON SCHEMA ' || schema_name || ' TO ' || user_name;
		EXECUTE 'GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA ' || schema_name || ' TO ' || user_name;
		RETURN true;
	END;
$$;


ALTER FUNCTION public.create_gecoi2b2datasource_schema(schema_name name, user_name name) OWNER TO postgres;

--
-- Name: delete_gecoi2b2datasource_schema(name); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.delete_gecoi2b2datasource_schema(schema_name name) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
	BEGIN
		EXECUTE 'DROP SCHEMA ' || schema_name || ' CASCADE';
		RETURN true;
	END;
$$;


ALTER FUNCTION public.delete_gecoi2b2datasource_schema(schema_name name) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: archive_observation_fact; Type: TABLE; Schema: i2b2demodata; Owner: postgres
--

CREATE TABLE i2b2demodata.archive_observation_fact (
    encounter_num integer,
    patient_num integer,
    concept_cd character varying(50),
    provider_id character varying(50),
    start_date timestamp without time zone,
    modifier_cd character varying(100),
    instance_num integer,
    valtype_cd character varying(50),
    tval_char character varying(255),
    nval_num numeric(18,5),
    valueflag_cd character varying(50),
    quantity_num numeric(18,5),
    units_cd character varying(50),
    end_date timestamp without time zone,
    location_cd character varying(50),
    observation_blob text,
    confidence_num numeric(18,5),
    update_date timestamp without time zone,
    download_date timestamp without time zone,
    import_date timestamp without time zone,
    sourcesystem_cd character varying(50),
    upload_id integer,
    text_search_index integer,
    archive_upload_id integer
);


ALTER TABLE i2b2demodata.archive_observation_fact OWNER TO postgres;

--
-- Name: code_lookup; Type: TABLE; Schema: i2b2demodata; Owner: postgres
--

CREATE TABLE i2b2demodata.code_lookup (
    table_cd character varying(100) NOT NULL,
    column_cd character varying(100) NOT NULL,
    code_cd character varying(50) NOT NULL,
    name_char character varying(650),
    lookup_blob text,
    upload_date timestamp without time zone,
    update_date timestamp without time zone,
    download_date timestamp without time zone,
    import_date timestamp without time zone,
    sourcesystem_cd character varying(50),
    upload_id integer
);


ALTER TABLE i2b2demodata.code_lookup OWNER TO postgres;

--
-- Name: concept_dimension; Type: TABLE; Schema: i2b2demodata; Owner: postgres
--

CREATE TABLE i2b2demodata.concept_dimension (
    concept_path character varying(2000) NOT NULL,
    concept_cd character varying(50),
    name_char character varying(2000),
    concept_blob text,
    update_date timestamp without time zone,
    download_date timestamp without time zone,
    import_date timestamp without time zone,
    sourcesystem_cd character varying(50),
    upload_id integer
);


ALTER TABLE i2b2demodata.concept_dimension OWNER TO postgres;

--
-- Name: datamart_report; Type: TABLE; Schema: i2b2demodata; Owner: postgres
--

CREATE TABLE i2b2demodata.datamart_report (
    total_patient integer,
    total_observationfact integer,
    total_event integer,
    report_date timestamp without time zone
);


ALTER TABLE i2b2demodata.datamart_report OWNER TO postgres;

--
-- Name: encounter_mapping; Type: TABLE; Schema: i2b2demodata; Owner: postgres
--

CREATE TABLE i2b2demodata.encounter_mapping (
    encounter_ide character varying(200) NOT NULL,
    encounter_ide_source character varying(50) NOT NULL,
    project_id character varying(50) NOT NULL,
    encounter_num bigint NOT NULL,
    patient_ide character varying(200) NOT NULL,
    patient_ide_source character varying(50) NOT NULL,
    encounter_ide_status character varying(50),
    upload_date timestamp without time zone,
    update_date timestamp without time zone,
    download_date timestamp without time zone,
    import_date timestamp without time zone,
    sourcesystem_cd character varying(50),
    upload_id integer
);


ALTER TABLE i2b2demodata.encounter_mapping OWNER TO postgres;

--
-- Name: modifier_dimension; Type: TABLE; Schema: i2b2demodata; Owner: postgres
--

CREATE TABLE i2b2demodata.modifier_dimension (
    modifier_path character varying(2000) NOT NULL,
    modifier_cd character varying(50),
    name_char character varying(2000),
    modifier_blob text,
    update_date timestamp without time zone,
    download_date timestamp without time zone,
    import_date timestamp without time zone,
    sourcesystem_cd character varying(50),
    upload_id integer
);


ALTER TABLE i2b2demodata.modifier_dimension OWNER TO postgres;

--
-- Name: observation_fact; Type: TABLE; Schema: i2b2demodata; Owner: postgres
--

CREATE TABLE i2b2demodata.observation_fact (
    encounter_num bigint NOT NULL,
    patient_num integer NOT NULL,
    concept_cd character varying(50) NOT NULL,
    provider_id character varying(50) NOT NULL,
    start_date timestamp without time zone NOT NULL,
    modifier_cd character varying(100) DEFAULT '@'::character varying NOT NULL,
    instance_num integer DEFAULT 1 NOT NULL,
    valtype_cd character varying(50),
    tval_char text,
    nval_num numeric(18,5),
    valueflag_cd character varying(50),
    quantity_num numeric(18,5),
    units_cd character varying(50),
    end_date timestamp without time zone,
    location_cd character varying(50),
    observation_blob text,
    confidence_num numeric(18,5),
    update_date timestamp without time zone,
    download_date timestamp without time zone,
    import_date timestamp without time zone,
    sourcesystem_cd character varying(50),
    upload_id integer,
    text_search_index integer NOT NULL
);


ALTER TABLE i2b2demodata.observation_fact OWNER TO postgres;

--
-- Name: observation_fact_text_search_index_seq; Type: SEQUENCE; Schema: i2b2demodata; Owner: postgres
--

CREATE SEQUENCE i2b2demodata.observation_fact_text_search_index_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE i2b2demodata.observation_fact_text_search_index_seq OWNER TO postgres;

--
-- Name: observation_fact_text_search_index_seq; Type: SEQUENCE OWNED BY; Schema: i2b2demodata; Owner: postgres
--

ALTER SEQUENCE i2b2demodata.observation_fact_text_search_index_seq OWNED BY i2b2demodata.observation_fact.text_search_index;


--
-- Name: patient_dimension; Type: TABLE; Schema: i2b2demodata; Owner: postgres
--

CREATE TABLE i2b2demodata.patient_dimension (
    patient_num integer NOT NULL,
    vital_status_cd character varying(50),
    birth_date timestamp without time zone,
    death_date timestamp without time zone,
    sex_cd character varying(50),
    age_in_years_num integer,
    language_cd character varying(50),
    race_cd character varying(50),
    marital_status_cd character varying(50),
    religion_cd character varying(50),
    zip_cd character varying(10),
    statecityzip_path character varying(700),
    income_cd character varying(50),
    patient_blob text,
    update_date timestamp without time zone,
    download_date timestamp without time zone,
    import_date timestamp without time zone,
    sourcesystem_cd character varying(50),
    upload_id integer
);


ALTER TABLE i2b2demodata.patient_dimension OWNER TO postgres;

--
-- Name: patient_mapping; Type: TABLE; Schema: i2b2demodata; Owner: postgres
--

CREATE TABLE i2b2demodata.patient_mapping (
    patient_ide character varying(200) NOT NULL,
    patient_ide_source character varying(50) NOT NULL,
    patient_num integer NOT NULL,
    patient_ide_status character varying(50),
    project_id character varying(50) NOT NULL,
    upload_date timestamp without time zone,
    update_date timestamp without time zone,
    download_date timestamp without time zone,
    import_date timestamp without time zone,
    sourcesystem_cd character varying(50),
    upload_id integer
);


ALTER TABLE i2b2demodata.patient_mapping OWNER TO postgres;

--
-- Name: provider_dimension; Type: TABLE; Schema: i2b2demodata; Owner: postgres
--

CREATE TABLE i2b2demodata.provider_dimension (
    provider_id character varying(50) NOT NULL,
    provider_path character varying(700) NOT NULL,
    name_char character varying(850),
    provider_blob text,
    update_date timestamp without time zone,
    download_date timestamp without time zone,
    import_date timestamp without time zone,
    sourcesystem_cd character varying(50),
    upload_id integer
);


ALTER TABLE i2b2demodata.provider_dimension OWNER TO postgres;

--
-- Name: qt_analysis_plugin; Type: TABLE; Schema: i2b2demodata; Owner: postgres
--

CREATE TABLE i2b2demodata.qt_analysis_plugin (
    plugin_id integer NOT NULL,
    plugin_name character varying(2000),
    description character varying(2000),
    version_cd character varying(50),
    parameter_info text,
    parameter_info_xsd text,
    command_line text,
    working_folder text,
    commandoption_cd text,
    plugin_icon text,
    status_cd character varying(50),
    user_id character varying(50),
    group_id character varying(50),
    create_date timestamp without time zone,
    update_date timestamp without time zone
);


ALTER TABLE i2b2demodata.qt_analysis_plugin OWNER TO postgres;

--
-- Name: qt_analysis_plugin_result_type; Type: TABLE; Schema: i2b2demodata; Owner: postgres
--

CREATE TABLE i2b2demodata.qt_analysis_plugin_result_type (
    plugin_id integer NOT NULL,
    result_type_id integer NOT NULL
);


ALTER TABLE i2b2demodata.qt_analysis_plugin_result_type OWNER TO postgres;

--
-- Name: qt_breakdown_path; Type: TABLE; Schema: i2b2demodata; Owner: postgres
--

CREATE TABLE i2b2demodata.qt_breakdown_path (
    name character varying(100),
    value character varying(2000),
    create_date timestamp without time zone,
    update_date timestamp without time zone,
    user_id character varying(50)
);


ALTER TABLE i2b2demodata.qt_breakdown_path OWNER TO postgres;

--
-- Name: qt_patient_enc_collection; Type: TABLE; Schema: i2b2demodata; Owner: postgres
--

CREATE TABLE i2b2demodata.qt_patient_enc_collection (
    patient_enc_coll_id bigint NOT NULL,
    result_instance_id integer,
    set_index integer,
    patient_num integer,
    encounter_num integer
);


ALTER TABLE i2b2demodata.qt_patient_enc_collection OWNER TO postgres;

--
-- Name: qt_patient_enc_collection_patient_enc_coll_id_seq; Type: SEQUENCE; Schema: i2b2demodata; Owner: postgres
--

CREATE SEQUENCE i2b2demodata.qt_patient_enc_collection_patient_enc_coll_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE i2b2demodata.qt_patient_enc_collection_patient_enc_coll_id_seq OWNER TO postgres;

--
-- Name: qt_patient_enc_collection_patient_enc_coll_id_seq; Type: SEQUENCE OWNED BY; Schema: i2b2demodata; Owner: postgres
--

ALTER SEQUENCE i2b2demodata.qt_patient_enc_collection_patient_enc_coll_id_seq OWNED BY i2b2demodata.qt_patient_enc_collection.patient_enc_coll_id;


--
-- Name: qt_patient_set_collection; Type: TABLE; Schema: i2b2demodata; Owner: postgres
--

CREATE TABLE i2b2demodata.qt_patient_set_collection (
    patient_set_coll_id bigint NOT NULL,
    result_instance_id integer,
    set_index integer,
    patient_num integer
);


ALTER TABLE i2b2demodata.qt_patient_set_collection OWNER TO postgres;

--
-- Name: qt_patient_set_collection_patient_set_coll_id_seq; Type: SEQUENCE; Schema: i2b2demodata; Owner: postgres
--

CREATE SEQUENCE i2b2demodata.qt_patient_set_collection_patient_set_coll_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE i2b2demodata.qt_patient_set_collection_patient_set_coll_id_seq OWNER TO postgres;

--
-- Name: qt_patient_set_collection_patient_set_coll_id_seq; Type: SEQUENCE OWNED BY; Schema: i2b2demodata; Owner: postgres
--

ALTER SEQUENCE i2b2demodata.qt_patient_set_collection_patient_set_coll_id_seq OWNED BY i2b2demodata.qt_patient_set_collection.patient_set_coll_id;


--
-- Name: qt_pdo_query_master; Type: TABLE; Schema: i2b2demodata; Owner: postgres
--

CREATE TABLE i2b2demodata.qt_pdo_query_master (
    query_master_id integer NOT NULL,
    user_id character varying(50) NOT NULL,
    group_id character varying(50) NOT NULL,
    create_date timestamp without time zone NOT NULL,
    request_xml text,
    i2b2_request_xml text
);


ALTER TABLE i2b2demodata.qt_pdo_query_master OWNER TO postgres;

--
-- Name: qt_pdo_query_master_query_master_id_seq; Type: SEQUENCE; Schema: i2b2demodata; Owner: postgres
--

CREATE SEQUENCE i2b2demodata.qt_pdo_query_master_query_master_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE i2b2demodata.qt_pdo_query_master_query_master_id_seq OWNER TO postgres;

--
-- Name: qt_pdo_query_master_query_master_id_seq; Type: SEQUENCE OWNED BY; Schema: i2b2demodata; Owner: postgres
--

ALTER SEQUENCE i2b2demodata.qt_pdo_query_master_query_master_id_seq OWNED BY i2b2demodata.qt_pdo_query_master.query_master_id;


--
-- Name: qt_privilege; Type: TABLE; Schema: i2b2demodata; Owner: postgres
--

CREATE TABLE i2b2demodata.qt_privilege (
    protection_label_cd character varying(1500) NOT NULL,
    dataprot_cd character varying(1000),
    hivemgmt_cd character varying(1000),
    plugin_id integer
);


ALTER TABLE i2b2demodata.qt_privilege OWNER TO postgres;

--
-- Name: qt_query_instance; Type: TABLE; Schema: i2b2demodata; Owner: postgres
--

CREATE TABLE i2b2demodata.qt_query_instance (
    query_instance_id integer NOT NULL,
    query_master_id integer,
    user_id character varying(50) NOT NULL,
    group_id character varying(50) NOT NULL,
    batch_mode character varying(50),
    start_date timestamp without time zone NOT NULL,
    end_date timestamp without time zone,
    delete_flag character varying(3),
    status_type_id integer,
    message text
);


ALTER TABLE i2b2demodata.qt_query_instance OWNER TO postgres;

--
-- Name: qt_query_instance_query_instance_id_seq; Type: SEQUENCE; Schema: i2b2demodata; Owner: postgres
--

CREATE SEQUENCE i2b2demodata.qt_query_instance_query_instance_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE i2b2demodata.qt_query_instance_query_instance_id_seq OWNER TO postgres;

--
-- Name: qt_query_instance_query_instance_id_seq; Type: SEQUENCE OWNED BY; Schema: i2b2demodata; Owner: postgres
--

ALTER SEQUENCE i2b2demodata.qt_query_instance_query_instance_id_seq OWNED BY i2b2demodata.qt_query_instance.query_instance_id;


--
-- Name: qt_query_master; Type: TABLE; Schema: i2b2demodata; Owner: postgres
--

CREATE TABLE i2b2demodata.qt_query_master (
    query_master_id integer NOT NULL,
    name character varying(250) NOT NULL,
    user_id character varying(50) NOT NULL,
    group_id character varying(50) NOT NULL,
    master_type_cd character varying(2000),
    plugin_id integer,
    create_date timestamp without time zone NOT NULL,
    delete_date timestamp without time zone,
    delete_flag character varying(3),
    request_xml text,
    generated_sql text,
    i2b2_request_xml text,
    pm_xml text
);


ALTER TABLE i2b2demodata.qt_query_master OWNER TO postgres;

--
-- Name: qt_query_master_query_master_id_seq; Type: SEQUENCE; Schema: i2b2demodata; Owner: postgres
--

CREATE SEQUENCE i2b2demodata.qt_query_master_query_master_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE i2b2demodata.qt_query_master_query_master_id_seq OWNER TO postgres;

--
-- Name: qt_query_master_query_master_id_seq; Type: SEQUENCE OWNED BY; Schema: i2b2demodata; Owner: postgres
--

ALTER SEQUENCE i2b2demodata.qt_query_master_query_master_id_seq OWNED BY i2b2demodata.qt_query_master.query_master_id;


--
-- Name: qt_query_result_instance; Type: TABLE; Schema: i2b2demodata; Owner: postgres
--

CREATE TABLE i2b2demodata.qt_query_result_instance (
    result_instance_id integer NOT NULL,
    query_instance_id integer,
    result_type_id integer NOT NULL,
    set_size integer,
    start_date timestamp without time zone NOT NULL,
    end_date timestamp without time zone,
    status_type_id integer NOT NULL,
    delete_flag character varying(3),
    message text,
    description character varying(200),
    real_set_size integer,
    obfusc_method character varying(500)
);


ALTER TABLE i2b2demodata.qt_query_result_instance OWNER TO postgres;

--
-- Name: qt_query_result_instance_result_instance_id_seq; Type: SEQUENCE; Schema: i2b2demodata; Owner: postgres
--

CREATE SEQUENCE i2b2demodata.qt_query_result_instance_result_instance_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE i2b2demodata.qt_query_result_instance_result_instance_id_seq OWNER TO postgres;

--
-- Name: qt_query_result_instance_result_instance_id_seq; Type: SEQUENCE OWNED BY; Schema: i2b2demodata; Owner: postgres
--

ALTER SEQUENCE i2b2demodata.qt_query_result_instance_result_instance_id_seq OWNED BY i2b2demodata.qt_query_result_instance.result_instance_id;


--
-- Name: qt_query_result_type; Type: TABLE; Schema: i2b2demodata; Owner: postgres
--

CREATE TABLE i2b2demodata.qt_query_result_type (
    result_type_id integer NOT NULL,
    name character varying(100),
    description character varying(200),
    display_type_id character varying(500),
    visual_attribute_type_id character varying(3),
    user_role_cd character varying(255),
    classname character varying(200)
);


ALTER TABLE i2b2demodata.qt_query_result_type OWNER TO postgres;

--
-- Name: qt_query_status_type; Type: TABLE; Schema: i2b2demodata; Owner: postgres
--

CREATE TABLE i2b2demodata.qt_query_status_type (
    status_type_id integer NOT NULL,
    name character varying(100),
    description character varying(200)
);


ALTER TABLE i2b2demodata.qt_query_status_type OWNER TO postgres;

--
-- Name: qt_xml_result; Type: TABLE; Schema: i2b2demodata; Owner: postgres
--

CREATE TABLE i2b2demodata.qt_xml_result (
    xml_result_id integer NOT NULL,
    result_instance_id integer,
    xml_value text
);


ALTER TABLE i2b2demodata.qt_xml_result OWNER TO postgres;

--
-- Name: qt_xml_result_xml_result_id_seq; Type: SEQUENCE; Schema: i2b2demodata; Owner: postgres
--

CREATE SEQUENCE i2b2demodata.qt_xml_result_xml_result_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE i2b2demodata.qt_xml_result_xml_result_id_seq OWNER TO postgres;

--
-- Name: qt_xml_result_xml_result_id_seq; Type: SEQUENCE OWNED BY; Schema: i2b2demodata; Owner: postgres
--

ALTER SEQUENCE i2b2demodata.qt_xml_result_xml_result_id_seq OWNED BY i2b2demodata.qt_xml_result.xml_result_id;


--
-- Name: set_type; Type: TABLE; Schema: i2b2demodata; Owner: postgres
--

CREATE TABLE i2b2demodata.set_type (
    id integer NOT NULL,
    name character varying(500),
    create_date timestamp without time zone
);


ALTER TABLE i2b2demodata.set_type OWNER TO postgres;

--
-- Name: set_upload_status; Type: TABLE; Schema: i2b2demodata; Owner: postgres
--

CREATE TABLE i2b2demodata.set_upload_status (
    upload_id integer NOT NULL,
    set_type_id integer NOT NULL,
    source_cd character varying(50) NOT NULL,
    no_of_record bigint,
    loaded_record bigint,
    deleted_record bigint,
    load_date timestamp without time zone NOT NULL,
    end_date timestamp without time zone,
    load_status character varying(100),
    message text,
    input_file_name text,
    log_file_name text,
    transform_name character varying(500)
);


ALTER TABLE i2b2demodata.set_upload_status OWNER TO postgres;

--
-- Name: source_master; Type: TABLE; Schema: i2b2demodata; Owner: postgres
--

CREATE TABLE i2b2demodata.source_master (
    source_cd character varying(50) NOT NULL,
    description character varying(300),
    create_date timestamp without time zone
);


ALTER TABLE i2b2demodata.source_master OWNER TO postgres;

--
-- Name: upload_status; Type: TABLE; Schema: i2b2demodata; Owner: postgres
--

CREATE TABLE i2b2demodata.upload_status (
    upload_id integer NOT NULL,
    upload_label character varying(500) NOT NULL,
    user_id character varying(100) NOT NULL,
    source_cd character varying(50) NOT NULL,
    no_of_record bigint,
    loaded_record bigint,
    deleted_record bigint,
    load_date timestamp without time zone NOT NULL,
    end_date timestamp without time zone,
    load_status character varying(100),
    message text,
    input_file_name text,
    log_file_name text,
    transform_name character varying(500)
);


ALTER TABLE i2b2demodata.upload_status OWNER TO postgres;

--
-- Name: upload_status_upload_id_seq; Type: SEQUENCE; Schema: i2b2demodata; Owner: postgres
--

CREATE SEQUENCE i2b2demodata.upload_status_upload_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE i2b2demodata.upload_status_upload_id_seq OWNER TO postgres;

--
-- Name: upload_status_upload_id_seq; Type: SEQUENCE OWNED BY; Schema: i2b2demodata; Owner: postgres
--

ALTER SEQUENCE i2b2demodata.upload_status_upload_id_seq OWNED BY i2b2demodata.upload_status.upload_id;


--
-- Name: visit_dimension; Type: TABLE; Schema: i2b2demodata; Owner: postgres
--

CREATE TABLE i2b2demodata.visit_dimension (
    encounter_num bigint NOT NULL,
    patient_num integer NOT NULL,
    active_status_cd character varying(50),
    start_date timestamp without time zone,
    end_date timestamp without time zone,
    inout_cd character varying(50),
    location_cd character varying(50),
    location_path character varying(900),
    length_of_stay integer,
    visit_blob text,
    update_date timestamp without time zone,
    download_date timestamp without time zone,
    import_date timestamp without time zone,
    sourcesystem_cd character varying(50),
    upload_id integer
);


ALTER TABLE i2b2demodata.visit_dimension OWNER TO postgres;

--
-- Name: crc_analysis_job; Type: TABLE; Schema: i2b2hive; Owner: postgres
--

CREATE TABLE i2b2hive.crc_analysis_job (
    job_id character varying(10) NOT NULL,
    queue_name character varying(50),
    status_type_id integer,
    domain_id character varying(255),
    project_id character varying(500),
    user_id character varying(255),
    request_xml text,
    create_date timestamp without time zone,
    update_date timestamp without time zone
);


ALTER TABLE i2b2hive.crc_analysis_job OWNER TO postgres;

--
-- Name: crc_db_lookup; Type: TABLE; Schema: i2b2hive; Owner: postgres
--

CREATE TABLE i2b2hive.crc_db_lookup (
    c_domain_id character varying(255) NOT NULL,
    c_project_path character varying(255) NOT NULL,
    c_owner_id character varying(255) NOT NULL,
    c_db_fullschema character varying(255) NOT NULL,
    c_db_datasource character varying(255) NOT NULL,
    c_db_servertype character varying(255) NOT NULL,
    c_db_nicename character varying(255),
    c_db_tooltip character varying(255),
    c_comment text,
    c_entry_date timestamp without time zone,
    c_change_date timestamp without time zone,
    c_status_cd character(1)
);


ALTER TABLE i2b2hive.crc_db_lookup OWNER TO postgres;

--
-- Name: hive_cell_params; Type: TABLE; Schema: i2b2hive; Owner: postgres
--

CREATE TABLE i2b2hive.hive_cell_params (
    id integer NOT NULL,
    datatype_cd character varying(50),
    cell_id character varying(50) NOT NULL,
    param_name_cd character varying(200) NOT NULL,
    value text,
    change_date timestamp without time zone,
    entry_date timestamp without time zone,
    changeby_char character varying(50),
    status_cd character varying(50)
);


ALTER TABLE i2b2hive.hive_cell_params OWNER TO postgres;

--
-- Name: im_db_lookup; Type: TABLE; Schema: i2b2hive; Owner: postgres
--

CREATE TABLE i2b2hive.im_db_lookup (
    c_domain_id character varying(255) NOT NULL,
    c_project_path character varying(255) NOT NULL,
    c_owner_id character varying(255) NOT NULL,
    c_db_fullschema character varying(255) NOT NULL,
    c_db_datasource character varying(255) NOT NULL,
    c_db_servertype character varying(255) NOT NULL,
    c_db_nicename character varying(255),
    c_db_tooltip character varying(255),
    c_comment text,
    c_entry_date timestamp without time zone,
    c_change_date timestamp without time zone,
    c_status_cd character(1)
);


ALTER TABLE i2b2hive.im_db_lookup OWNER TO postgres;

--
-- Name: ont_db_lookup; Type: TABLE; Schema: i2b2hive; Owner: postgres
--

CREATE TABLE i2b2hive.ont_db_lookup (
    c_domain_id character varying(255) NOT NULL,
    c_project_path character varying(255) NOT NULL,
    c_owner_id character varying(255) NOT NULL,
    c_db_fullschema character varying(255) NOT NULL,
    c_db_datasource character varying(255) NOT NULL,
    c_db_servertype character varying(255) NOT NULL,
    c_db_nicename character varying(255),
    c_db_tooltip character varying(255),
    c_comment text,
    c_entry_date timestamp without time zone,
    c_change_date timestamp without time zone,
    c_status_cd character(1)
);


ALTER TABLE i2b2hive.ont_db_lookup OWNER TO postgres;

--
-- Name: work_db_lookup; Type: TABLE; Schema: i2b2hive; Owner: postgres
--

CREATE TABLE i2b2hive.work_db_lookup (
    c_domain_id character varying(255) NOT NULL,
    c_project_path character varying(255) NOT NULL,
    c_owner_id character varying(255) NOT NULL,
    c_db_fullschema character varying(255) NOT NULL,
    c_db_datasource character varying(255) NOT NULL,
    c_db_servertype character varying(255) NOT NULL,
    c_db_nicename character varying(255),
    c_db_tooltip character varying(255),
    c_comment text,
    c_entry_date timestamp without time zone,
    c_change_date timestamp without time zone,
    c_status_cd character(1)
);


ALTER TABLE i2b2hive.work_db_lookup OWNER TO postgres;

--
-- Name: im_audit; Type: TABLE; Schema: i2b2imdata; Owner: postgres
--

CREATE TABLE i2b2imdata.im_audit (
    query_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    lcl_site character varying(50) NOT NULL,
    lcl_id character varying(200) NOT NULL,
    user_id character varying(50) NOT NULL,
    project_id character varying(50) NOT NULL,
    comments text
);


ALTER TABLE i2b2imdata.im_audit OWNER TO postgres;

--
-- Name: im_mpi_demographics; Type: TABLE; Schema: i2b2imdata; Owner: postgres
--

CREATE TABLE i2b2imdata.im_mpi_demographics (
    global_id character varying(200) NOT NULL,
    global_status character varying(50),
    demographics character varying(400),
    update_date timestamp without time zone,
    download_date timestamp without time zone,
    import_date timestamp without time zone,
    sourcesystem_cd character varying(50),
    upload_id integer
);


ALTER TABLE i2b2imdata.im_mpi_demographics OWNER TO postgres;

--
-- Name: im_mpi_mapping; Type: TABLE; Schema: i2b2imdata; Owner: postgres
--

CREATE TABLE i2b2imdata.im_mpi_mapping (
    global_id character varying(200) NOT NULL,
    lcl_site character varying(50) NOT NULL,
    lcl_id character varying(200) NOT NULL,
    lcl_status character varying(50),
    update_date timestamp without time zone NOT NULL,
    download_date timestamp without time zone,
    import_date timestamp without time zone,
    sourcesystem_cd character varying(50),
    upload_id integer
);


ALTER TABLE i2b2imdata.im_mpi_mapping OWNER TO postgres;

--
-- Name: im_project_patients; Type: TABLE; Schema: i2b2imdata; Owner: postgres
--

CREATE TABLE i2b2imdata.im_project_patients (
    project_id character varying(50) NOT NULL,
    global_id character varying(200) NOT NULL,
    patient_project_status character varying(50),
    update_date timestamp without time zone,
    download_date timestamp without time zone,
    import_date timestamp without time zone,
    sourcesystem_cd character varying(50),
    upload_id integer
);


ALTER TABLE i2b2imdata.im_project_patients OWNER TO postgres;

--
-- Name: im_project_sites; Type: TABLE; Schema: i2b2imdata; Owner: postgres
--

CREATE TABLE i2b2imdata.im_project_sites (
    project_id character varying(50) NOT NULL,
    lcl_site character varying(50) NOT NULL,
    project_status character varying(50),
    update_date timestamp without time zone,
    download_date timestamp without time zone,
    import_date timestamp without time zone,
    sourcesystem_cd character varying(50),
    upload_id integer
);


ALTER TABLE i2b2imdata.im_project_sites OWNER TO postgres;

--
-- Name: birn; Type: TABLE; Schema: i2b2metadata; Owner: postgres
--

CREATE TABLE i2b2metadata.birn (
    c_hlevel integer NOT NULL,
    c_fullname character varying(700) NOT NULL,
    c_name character varying(2000) NOT NULL,
    c_synonym_cd character(1) NOT NULL,
    c_visualattributes character(3) NOT NULL,
    c_totalnum integer,
    c_basecode character varying(50),
    c_metadataxml text,
    c_facttablecolumn character varying(50) NOT NULL,
    c_tablename character varying(50) NOT NULL,
    c_columnname character varying(50) NOT NULL,
    c_columndatatype character varying(50) NOT NULL,
    c_operator character varying(10) NOT NULL,
    c_dimcode character varying(700) NOT NULL,
    c_comment text,
    c_tooltip character varying(900),
    m_applied_path character varying(700) NOT NULL,
    update_date timestamp without time zone NOT NULL,
    download_date timestamp without time zone,
    import_date timestamp without time zone,
    sourcesystem_cd character varying(50),
    valuetype_cd character varying(50),
    m_exclusion_cd character varying(25),
    c_path character varying(700),
    c_symbol character varying(50)
);


ALTER TABLE i2b2metadata.birn OWNER TO postgres;

--
-- Name: custom_meta; Type: TABLE; Schema: i2b2metadata; Owner: postgres
--

CREATE TABLE i2b2metadata.custom_meta (
    c_hlevel integer NOT NULL,
    c_fullname character varying(700) NOT NULL,
    c_name character varying(2000) NOT NULL,
    c_synonym_cd character(1) NOT NULL,
    c_visualattributes character(3) NOT NULL,
    c_totalnum integer,
    c_basecode character varying(50),
    c_metadataxml text,
    c_facttablecolumn character varying(50) NOT NULL,
    c_tablename character varying(50) NOT NULL,
    c_columnname character varying(50) NOT NULL,
    c_columndatatype character varying(50) NOT NULL,
    c_operator character varying(10) NOT NULL,
    c_dimcode character varying(700) NOT NULL,
    c_comment text,
    c_tooltip character varying(900),
    m_applied_path character varying(700) NOT NULL,
    update_date timestamp without time zone NOT NULL,
    download_date timestamp without time zone,
    import_date timestamp without time zone,
    sourcesystem_cd character varying(50),
    valuetype_cd character varying(50),
    m_exclusion_cd character varying(25),
    c_path character varying(700),
    c_symbol character varying(50)
);


ALTER TABLE i2b2metadata.custom_meta OWNER TO postgres;

--
-- Name: i2b2; Type: TABLE; Schema: i2b2metadata; Owner: postgres
--

CREATE TABLE i2b2metadata.i2b2 (
    c_hlevel integer NOT NULL,
    c_fullname character varying(700) NOT NULL,
    c_name character varying(2000) NOT NULL,
    c_synonym_cd character(1) NOT NULL,
    c_visualattributes character(3) NOT NULL,
    c_totalnum integer,
    c_basecode character varying(50),
    c_metadataxml text,
    c_facttablecolumn character varying(50) NOT NULL,
    c_tablename character varying(50) NOT NULL,
    c_columnname character varying(50) NOT NULL,
    c_columndatatype character varying(50) NOT NULL,
    c_operator character varying(10) NOT NULL,
    c_dimcode character varying(700) NOT NULL,
    c_comment text,
    c_tooltip character varying(900),
    m_applied_path character varying(700) NOT NULL,
    update_date timestamp without time zone NOT NULL,
    download_date timestamp without time zone,
    import_date timestamp without time zone,
    sourcesystem_cd character varying(50),
    valuetype_cd character varying(50),
    m_exclusion_cd character varying(25),
    c_path character varying(700),
    c_symbol character varying(50)
);


ALTER TABLE i2b2metadata.i2b2 OWNER TO postgres;

--
-- Name: icd10_icd9; Type: TABLE; Schema: i2b2metadata; Owner: postgres
--

CREATE TABLE i2b2metadata.icd10_icd9 (
    c_hlevel integer NOT NULL,
    c_fullname character varying(700) NOT NULL,
    c_name character varying(2000) NOT NULL,
    c_synonym_cd character(1) NOT NULL,
    c_visualattributes character(3) NOT NULL,
    c_totalnum integer,
    c_basecode character varying(50),
    c_metadataxml text,
    c_facttablecolumn character varying(50) NOT NULL,
    c_tablename character varying(50) NOT NULL,
    c_columnname character varying(50) NOT NULL,
    c_columndatatype character varying(50) NOT NULL,
    c_operator character varying(10) NOT NULL,
    c_dimcode character varying(700) NOT NULL,
    c_comment text,
    c_tooltip character varying(900),
    m_applied_path character varying(700) NOT NULL,
    update_date timestamp without time zone NOT NULL,
    download_date timestamp without time zone,
    import_date timestamp without time zone,
    sourcesystem_cd character varying(50),
    valuetype_cd character varying(50),
    m_exclusion_cd character varying(25),
    c_path character varying(700),
    c_symbol character varying(50),
    plain_code character varying(25)
);


ALTER TABLE i2b2metadata.icd10_icd9 OWNER TO postgres;

--
-- Name: ont_process_status; Type: TABLE; Schema: i2b2metadata; Owner: postgres
--

CREATE TABLE i2b2metadata.ont_process_status (
    process_id integer NOT NULL,
    process_type_cd character varying(50),
    start_date timestamp without time zone,
    end_date timestamp without time zone,
    process_step_cd character varying(50),
    process_status_cd character varying(50),
    crc_upload_id integer,
    status_cd character varying(50),
    message text,
    entry_date timestamp without time zone,
    change_date timestamp without time zone,
    changedby_char character(50)
);


ALTER TABLE i2b2metadata.ont_process_status OWNER TO postgres;

--
-- Name: ont_process_status_process_id_seq; Type: SEQUENCE; Schema: i2b2metadata; Owner: postgres
--

CREATE SEQUENCE i2b2metadata.ont_process_status_process_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE i2b2metadata.ont_process_status_process_id_seq OWNER TO postgres;

--
-- Name: ont_process_status_process_id_seq; Type: SEQUENCE OWNED BY; Schema: i2b2metadata; Owner: postgres
--

ALTER SEQUENCE i2b2metadata.ont_process_status_process_id_seq OWNED BY i2b2metadata.ont_process_status.process_id;


--
-- Name: schemes; Type: TABLE; Schema: i2b2metadata; Owner: postgres
--

CREATE TABLE i2b2metadata.schemes (
    c_key character varying(50) NOT NULL,
    c_name character varying(50) NOT NULL,
    c_description character varying(100)
);


ALTER TABLE i2b2metadata.schemes OWNER TO postgres;

--
-- Name: table_access; Type: TABLE; Schema: i2b2metadata; Owner: postgres
--

CREATE TABLE i2b2metadata.table_access (
    c_table_cd character varying(50) NOT NULL,
    c_table_name character varying(50) NOT NULL,
    c_protected_access character(1),
    c_ontology_protection text,
    c_hlevel integer NOT NULL,
    c_fullname character varying(700) NOT NULL,
    c_name character varying(2000) NOT NULL,
    c_synonym_cd character(1) NOT NULL,
    c_visualattributes character(3) NOT NULL,
    c_totalnum integer,
    c_basecode character varying(50),
    c_metadataxml text,
    c_facttablecolumn character varying(50) NOT NULL,
    c_dimtablename character varying(50) NOT NULL,
    c_columnname character varying(50) NOT NULL,
    c_columndatatype character varying(50) NOT NULL,
    c_operator character varying(10) NOT NULL,
    c_dimcode character varying(700) NOT NULL,
    c_comment text,
    c_tooltip character varying(900),
    c_entry_date timestamp without time zone,
    c_change_date timestamp without time zone,
    c_status_cd character(1),
    valuetype_cd character varying(50)
);


ALTER TABLE i2b2metadata.table_access OWNER TO postgres;

--
-- Name: test; Type: TABLE; Schema: i2b2metadata; Owner: postgres
--

CREATE TABLE i2b2metadata.test (
    c_hlevel numeric(22,0) NOT NULL,
    c_fullname character varying(900) NOT NULL,
    c_name character varying(2000) NOT NULL,
    c_synonym_cd character(1) NOT NULL,
    c_visualattributes character(3) NOT NULL,
    c_totalnum numeric(22,0),
    c_basecode character varying(450),
    c_metadataxml text,
    c_facttablecolumn character varying(50) NOT NULL,
    c_tablename character varying(50) NOT NULL,
    c_columnname character varying(50) NOT NULL,
    c_columndatatype character varying(50) NOT NULL,
    c_operator character varying(10) NOT NULL,
    c_dimcode character varying(900) NOT NULL,
    c_comment text,
    c_tooltip character varying(900),
    update_date date NOT NULL,
    download_date date,
    import_date date,
    sourcesystem_cd character varying(50),
    valuetype_cd character varying(50),
    m_applied_path character varying(900) NOT NULL,
    m_exclusion_cd character varying(900),
    c_path character varying(700),
    c_symbol character varying(50),
    pcori_basecode character varying(50)
);


ALTER TABLE i2b2metadata.test OWNER TO postgres;

--
-- Name: totalnum; Type: TABLE; Schema: i2b2metadata; Owner: postgres
--

CREATE TABLE i2b2metadata.totalnum (
    c_fullname character varying(850),
    agg_date date,
    agg_count integer,
    typeflag_cd character varying(3)
);


ALTER TABLE i2b2metadata.totalnum OWNER TO postgres;

--
-- Name: totalnum_report; Type: TABLE; Schema: i2b2metadata; Owner: postgres
--

CREATE TABLE i2b2metadata.totalnum_report (
    c_fullname character varying(850),
    agg_date character varying(50),
    agg_count integer
);


ALTER TABLE i2b2metadata.totalnum_report OWNER TO postgres;

--
-- Name: pm_approvals; Type: TABLE; Schema: i2b2pm; Owner: postgres
--

CREATE TABLE i2b2pm.pm_approvals (
    approval_id character varying(50) NOT NULL,
    approval_name character varying(255),
    approval_description character varying(2000),
    approval_activation_date timestamp without time zone,
    approval_expiration_date timestamp without time zone,
    object_cd character varying(50),
    change_date timestamp without time zone,
    entry_date timestamp without time zone,
    changeby_char character varying(50),
    status_cd character varying(50)
);


ALTER TABLE i2b2pm.pm_approvals OWNER TO postgres;

--
-- Name: pm_approvals_params; Type: TABLE; Schema: i2b2pm; Owner: postgres
--

CREATE TABLE i2b2pm.pm_approvals_params (
    id integer NOT NULL,
    approval_id character varying(50) NOT NULL,
    param_name_cd character varying(50) NOT NULL,
    value text,
    activation_date timestamp without time zone,
    expiration_date timestamp without time zone,
    datatype_cd character varying(50),
    object_cd character varying(50),
    change_date timestamp without time zone,
    entry_date timestamp without time zone,
    changeby_char character varying(50),
    status_cd character varying(50)
);


ALTER TABLE i2b2pm.pm_approvals_params OWNER TO postgres;

--
-- Name: pm_approvals_params_id_seq; Type: SEQUENCE; Schema: i2b2pm; Owner: postgres
--

CREATE SEQUENCE i2b2pm.pm_approvals_params_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE i2b2pm.pm_approvals_params_id_seq OWNER TO postgres;

--
-- Name: pm_approvals_params_id_seq; Type: SEQUENCE OWNED BY; Schema: i2b2pm; Owner: postgres
--

ALTER SEQUENCE i2b2pm.pm_approvals_params_id_seq OWNED BY i2b2pm.pm_approvals_params.id;


--
-- Name: pm_cell_data; Type: TABLE; Schema: i2b2pm; Owner: postgres
--

CREATE TABLE i2b2pm.pm_cell_data (
    cell_id character varying(50) NOT NULL,
    project_path character varying(255) NOT NULL,
    name character varying(255),
    method_cd character varying(255),
    url character varying(255),
    can_override integer,
    change_date timestamp without time zone,
    entry_date timestamp without time zone,
    changeby_char character varying(50),
    status_cd character varying(50)
);


ALTER TABLE i2b2pm.pm_cell_data OWNER TO postgres;

--
-- Name: pm_cell_params; Type: TABLE; Schema: i2b2pm; Owner: postgres
--

CREATE TABLE i2b2pm.pm_cell_params (
    id integer NOT NULL,
    datatype_cd character varying(50),
    cell_id character varying(50) NOT NULL,
    project_path character varying(255) NOT NULL,
    param_name_cd character varying(50) NOT NULL,
    value text,
    can_override integer,
    change_date timestamp without time zone,
    entry_date timestamp without time zone,
    changeby_char character varying(50),
    status_cd character varying(50)
);


ALTER TABLE i2b2pm.pm_cell_params OWNER TO postgres;

--
-- Name: pm_cell_params_id_seq; Type: SEQUENCE; Schema: i2b2pm; Owner: postgres
--

CREATE SEQUENCE i2b2pm.pm_cell_params_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE i2b2pm.pm_cell_params_id_seq OWNER TO postgres;

--
-- Name: pm_cell_params_id_seq; Type: SEQUENCE OWNED BY; Schema: i2b2pm; Owner: postgres
--

ALTER SEQUENCE i2b2pm.pm_cell_params_id_seq OWNED BY i2b2pm.pm_cell_params.id;


--
-- Name: pm_global_params; Type: TABLE; Schema: i2b2pm; Owner: postgres
--

CREATE TABLE i2b2pm.pm_global_params (
    id integer NOT NULL,
    datatype_cd character varying(50),
    param_name_cd character varying(50) NOT NULL,
    project_path character varying(255) NOT NULL,
    value text,
    can_override integer,
    change_date timestamp without time zone,
    entry_date timestamp without time zone,
    changeby_char character varying(50),
    status_cd character varying(50)
);


ALTER TABLE i2b2pm.pm_global_params OWNER TO postgres;

--
-- Name: pm_global_params_id_seq; Type: SEQUENCE; Schema: i2b2pm; Owner: postgres
--

CREATE SEQUENCE i2b2pm.pm_global_params_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE i2b2pm.pm_global_params_id_seq OWNER TO postgres;

--
-- Name: pm_global_params_id_seq; Type: SEQUENCE OWNED BY; Schema: i2b2pm; Owner: postgres
--

ALTER SEQUENCE i2b2pm.pm_global_params_id_seq OWNED BY i2b2pm.pm_global_params.id;


--
-- Name: pm_hive_data; Type: TABLE; Schema: i2b2pm; Owner: postgres
--

CREATE TABLE i2b2pm.pm_hive_data (
    domain_id character varying(50) NOT NULL,
    helpurl character varying(255),
    domain_name character varying(255),
    environment_cd character varying(255),
    active integer,
    change_date timestamp without time zone,
    entry_date timestamp without time zone,
    changeby_char character varying(50),
    status_cd character varying(50)
);


ALTER TABLE i2b2pm.pm_hive_data OWNER TO postgres;

--
-- Name: pm_hive_params; Type: TABLE; Schema: i2b2pm; Owner: postgres
--

CREATE TABLE i2b2pm.pm_hive_params (
    id integer NOT NULL,
    datatype_cd character varying(50),
    domain_id character varying(50) NOT NULL,
    param_name_cd character varying(50) NOT NULL,
    value text,
    change_date timestamp without time zone,
    entry_date timestamp without time zone,
    changeby_char character varying(50),
    status_cd character varying(50)
);


ALTER TABLE i2b2pm.pm_hive_params OWNER TO postgres;

--
-- Name: pm_hive_params_id_seq; Type: SEQUENCE; Schema: i2b2pm; Owner: postgres
--

CREATE SEQUENCE i2b2pm.pm_hive_params_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE i2b2pm.pm_hive_params_id_seq OWNER TO postgres;

--
-- Name: pm_hive_params_id_seq; Type: SEQUENCE OWNED BY; Schema: i2b2pm; Owner: postgres
--

ALTER SEQUENCE i2b2pm.pm_hive_params_id_seq OWNED BY i2b2pm.pm_hive_params.id;


--
-- Name: pm_project_data; Type: TABLE; Schema: i2b2pm; Owner: postgres
--

CREATE TABLE i2b2pm.pm_project_data (
    project_id character varying(50) NOT NULL,
    project_name character varying(255),
    project_wiki character varying(255),
    project_key character varying(255),
    project_path character varying(255),
    project_description character varying(2000),
    change_date timestamp without time zone,
    entry_date timestamp without time zone,
    changeby_char character varying(50),
    status_cd character varying(50)
);


ALTER TABLE i2b2pm.pm_project_data OWNER TO postgres;

--
-- Name: pm_project_params; Type: TABLE; Schema: i2b2pm; Owner: postgres
--

CREATE TABLE i2b2pm.pm_project_params (
    id integer NOT NULL,
    datatype_cd character varying(50),
    project_id character varying(50) NOT NULL,
    param_name_cd character varying(50) NOT NULL,
    value text,
    change_date timestamp without time zone,
    entry_date timestamp without time zone,
    changeby_char character varying(50),
    status_cd character varying(50)
);


ALTER TABLE i2b2pm.pm_project_params OWNER TO postgres;

--
-- Name: pm_project_params_id_seq; Type: SEQUENCE; Schema: i2b2pm; Owner: postgres
--

CREATE SEQUENCE i2b2pm.pm_project_params_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE i2b2pm.pm_project_params_id_seq OWNER TO postgres;

--
-- Name: pm_project_params_id_seq; Type: SEQUENCE OWNED BY; Schema: i2b2pm; Owner: postgres
--

ALTER SEQUENCE i2b2pm.pm_project_params_id_seq OWNED BY i2b2pm.pm_project_params.id;


--
-- Name: pm_project_request; Type: TABLE; Schema: i2b2pm; Owner: postgres
--

CREATE TABLE i2b2pm.pm_project_request (
    id integer NOT NULL,
    title character varying(255),
    request_xml text NOT NULL,
    change_date timestamp without time zone,
    entry_date timestamp without time zone,
    changeby_char character varying(50),
    status_cd character varying(50),
    project_id character varying(50),
    submit_char character varying(50)
);


ALTER TABLE i2b2pm.pm_project_request OWNER TO postgres;

--
-- Name: pm_project_request_id_seq; Type: SEQUENCE; Schema: i2b2pm; Owner: postgres
--

CREATE SEQUENCE i2b2pm.pm_project_request_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE i2b2pm.pm_project_request_id_seq OWNER TO postgres;

--
-- Name: pm_project_request_id_seq; Type: SEQUENCE OWNED BY; Schema: i2b2pm; Owner: postgres
--

ALTER SEQUENCE i2b2pm.pm_project_request_id_seq OWNED BY i2b2pm.pm_project_request.id;


--
-- Name: pm_project_user_params; Type: TABLE; Schema: i2b2pm; Owner: postgres
--

CREATE TABLE i2b2pm.pm_project_user_params (
    id integer NOT NULL,
    datatype_cd character varying(50),
    project_id character varying(50) NOT NULL,
    user_id character varying(50) NOT NULL,
    param_name_cd character varying(50) NOT NULL,
    value text,
    change_date timestamp without time zone,
    entry_date timestamp without time zone,
    changeby_char character varying(50),
    status_cd character varying(50)
);


ALTER TABLE i2b2pm.pm_project_user_params OWNER TO postgres;

--
-- Name: pm_project_user_params_id_seq; Type: SEQUENCE; Schema: i2b2pm; Owner: postgres
--

CREATE SEQUENCE i2b2pm.pm_project_user_params_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE i2b2pm.pm_project_user_params_id_seq OWNER TO postgres;

--
-- Name: pm_project_user_params_id_seq; Type: SEQUENCE OWNED BY; Schema: i2b2pm; Owner: postgres
--

ALTER SEQUENCE i2b2pm.pm_project_user_params_id_seq OWNED BY i2b2pm.pm_project_user_params.id;


--
-- Name: pm_project_user_roles; Type: TABLE; Schema: i2b2pm; Owner: postgres
--

CREATE TABLE i2b2pm.pm_project_user_roles (
    project_id character varying(50) NOT NULL,
    user_id character varying(50) NOT NULL,
    user_role_cd character varying(255) NOT NULL,
    change_date timestamp without time zone,
    entry_date timestamp without time zone,
    changeby_char character varying(50),
    status_cd character varying(50)
);


ALTER TABLE i2b2pm.pm_project_user_roles OWNER TO postgres;

--
-- Name: pm_role_requirement; Type: TABLE; Schema: i2b2pm; Owner: postgres
--

CREATE TABLE i2b2pm.pm_role_requirement (
    table_cd character varying(50) NOT NULL,
    column_cd character varying(50) NOT NULL,
    read_hivemgmt_cd character varying(50) NOT NULL,
    write_hivemgmt_cd character varying(50) NOT NULL,
    name_char character varying(2000),
    change_date timestamp without time zone,
    entry_date timestamp without time zone,
    changeby_char character varying(50),
    status_cd character varying(50)
);


ALTER TABLE i2b2pm.pm_role_requirement OWNER TO postgres;

--
-- Name: pm_user_data; Type: TABLE; Schema: i2b2pm; Owner: postgres
--

CREATE TABLE i2b2pm.pm_user_data (
    user_id character varying(50) NOT NULL,
    full_name character varying(255),
    password character varying(255),
    email character varying(255),
    project_path character varying(255),
    change_date timestamp without time zone,
    entry_date timestamp without time zone,
    changeby_char character varying(50),
    status_cd character varying(50)
);


ALTER TABLE i2b2pm.pm_user_data OWNER TO postgres;

--
-- Name: pm_user_login; Type: TABLE; Schema: i2b2pm; Owner: postgres
--

CREATE TABLE i2b2pm.pm_user_login (
    user_id character varying(50) NOT NULL,
    attempt_cd character varying(50) NOT NULL,
    entry_date timestamp without time zone NOT NULL,
    changeby_char character varying(50),
    status_cd character varying(50)
);


ALTER TABLE i2b2pm.pm_user_login OWNER TO postgres;

--
-- Name: pm_user_params; Type: TABLE; Schema: i2b2pm; Owner: postgres
--

CREATE TABLE i2b2pm.pm_user_params (
    id integer NOT NULL,
    datatype_cd character varying(50),
    user_id character varying(50) NOT NULL,
    param_name_cd character varying(50) NOT NULL,
    value text,
    change_date timestamp without time zone,
    entry_date timestamp without time zone,
    changeby_char character varying(50),
    status_cd character varying(50)
);


ALTER TABLE i2b2pm.pm_user_params OWNER TO postgres;

--
-- Name: pm_user_params_id_seq; Type: SEQUENCE; Schema: i2b2pm; Owner: postgres
--

CREATE SEQUENCE i2b2pm.pm_user_params_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE i2b2pm.pm_user_params_id_seq OWNER TO postgres;

--
-- Name: pm_user_params_id_seq; Type: SEQUENCE OWNED BY; Schema: i2b2pm; Owner: postgres
--

ALTER SEQUENCE i2b2pm.pm_user_params_id_seq OWNED BY i2b2pm.pm_user_params.id;


--
-- Name: pm_user_session; Type: TABLE; Schema: i2b2pm; Owner: postgres
--

CREATE TABLE i2b2pm.pm_user_session (
    user_id character varying(50) NOT NULL,
    session_id character varying(50) NOT NULL,
    expired_date timestamp without time zone,
    change_date timestamp without time zone,
    entry_date timestamp without time zone,
    changeby_char character varying(50),
    status_cd character varying(50)
);


ALTER TABLE i2b2pm.pm_user_session OWNER TO postgres;

--
-- Name: workplace; Type: TABLE; Schema: i2b2workdata; Owner: postgres
--

CREATE TABLE i2b2workdata.workplace (
    c_name character varying(255) NOT NULL,
    c_user_id character varying(255) NOT NULL,
    c_group_id character varying(255) NOT NULL,
    c_share_id character varying(255),
    c_index character varying(255) NOT NULL,
    c_parent_index character varying(255),
    c_visualattributes character(3) NOT NULL,
    c_protected_access character(1),
    c_tooltip character varying(255),
    c_work_xml text,
    c_work_xml_schema text,
    c_work_xml_i2b2_type character varying(255),
    c_entry_date timestamp without time zone,
    c_change_date timestamp without time zone,
    c_status_cd character(1)
);


ALTER TABLE i2b2workdata.workplace OWNER TO postgres;

--
-- Name: workplace_access; Type: TABLE; Schema: i2b2workdata; Owner: postgres
--

CREATE TABLE i2b2workdata.workplace_access (
    c_table_cd character varying(255) NOT NULL,
    c_table_name character varying(255) NOT NULL,
    c_protected_access character(1),
    c_hlevel integer NOT NULL,
    c_name character varying(255) NOT NULL,
    c_user_id character varying(255) NOT NULL,
    c_group_id character varying(255) NOT NULL,
    c_share_id character varying(255),
    c_index character varying(255) NOT NULL,
    c_parent_index character varying(255),
    c_visualattributes character(3) NOT NULL,
    c_tooltip character varying(255),
    c_entry_date timestamp without time zone,
    c_change_date timestamp without time zone,
    c_status_cd character(1)
);


ALTER TABLE i2b2workdata.workplace_access OWNER TO postgres;

--
-- Name: observation_fact text_search_index; Type: DEFAULT; Schema: i2b2demodata; Owner: postgres
--

ALTER TABLE ONLY i2b2demodata.observation_fact ALTER COLUMN text_search_index SET DEFAULT nextval('i2b2demodata.observation_fact_text_search_index_seq'::regclass);


--
-- Name: qt_patient_enc_collection patient_enc_coll_id; Type: DEFAULT; Schema: i2b2demodata; Owner: postgres
--

ALTER TABLE ONLY i2b2demodata.qt_patient_enc_collection ALTER COLUMN patient_enc_coll_id SET DEFAULT nextval('i2b2demodata.qt_patient_enc_collection_patient_enc_coll_id_seq'::regclass);


--
-- Name: qt_patient_set_collection patient_set_coll_id; Type: DEFAULT; Schema: i2b2demodata; Owner: postgres
--

ALTER TABLE ONLY i2b2demodata.qt_patient_set_collection ALTER COLUMN patient_set_coll_id SET DEFAULT nextval('i2b2demodata.qt_patient_set_collection_patient_set_coll_id_seq'::regclass);


--
-- Name: qt_pdo_query_master query_master_id; Type: DEFAULT; Schema: i2b2demodata; Owner: postgres
--

ALTER TABLE ONLY i2b2demodata.qt_pdo_query_master ALTER COLUMN query_master_id SET DEFAULT nextval('i2b2demodata.qt_pdo_query_master_query_master_id_seq'::regclass);


--
-- Name: qt_query_instance query_instance_id; Type: DEFAULT; Schema: i2b2demodata; Owner: postgres
--

ALTER TABLE ONLY i2b2demodata.qt_query_instance ALTER COLUMN query_instance_id SET DEFAULT nextval('i2b2demodata.qt_query_instance_query_instance_id_seq'::regclass);


--
-- Name: qt_query_master query_master_id; Type: DEFAULT; Schema: i2b2demodata; Owner: postgres
--

ALTER TABLE ONLY i2b2demodata.qt_query_master ALTER COLUMN query_master_id SET DEFAULT nextval('i2b2demodata.qt_query_master_query_master_id_seq'::regclass);


--
-- Name: qt_query_result_instance result_instance_id; Type: DEFAULT; Schema: i2b2demodata; Owner: postgres
--

ALTER TABLE ONLY i2b2demodata.qt_query_result_instance ALTER COLUMN result_instance_id SET DEFAULT nextval('i2b2demodata.qt_query_result_instance_result_instance_id_seq'::regclass);


--
-- Name: qt_xml_result xml_result_id; Type: DEFAULT; Schema: i2b2demodata; Owner: postgres
--

ALTER TABLE ONLY i2b2demodata.qt_xml_result ALTER COLUMN xml_result_id SET DEFAULT nextval('i2b2demodata.qt_xml_result_xml_result_id_seq'::regclass);


--
-- Name: upload_status upload_id; Type: DEFAULT; Schema: i2b2demodata; Owner: postgres
--

ALTER TABLE ONLY i2b2demodata.upload_status ALTER COLUMN upload_id SET DEFAULT nextval('i2b2demodata.upload_status_upload_id_seq'::regclass);


--
-- Name: ont_process_status process_id; Type: DEFAULT; Schema: i2b2metadata; Owner: postgres
--

ALTER TABLE ONLY i2b2metadata.ont_process_status ALTER COLUMN process_id SET DEFAULT nextval('i2b2metadata.ont_process_status_process_id_seq'::regclass);


--
-- Name: pm_approvals_params id; Type: DEFAULT; Schema: i2b2pm; Owner: postgres
--

ALTER TABLE ONLY i2b2pm.pm_approvals_params ALTER COLUMN id SET DEFAULT nextval('i2b2pm.pm_approvals_params_id_seq'::regclass);


--
-- Name: pm_cell_params id; Type: DEFAULT; Schema: i2b2pm; Owner: postgres
--

ALTER TABLE ONLY i2b2pm.pm_cell_params ALTER COLUMN id SET DEFAULT nextval('i2b2pm.pm_cell_params_id_seq'::regclass);


--
-- Name: pm_global_params id; Type: DEFAULT; Schema: i2b2pm; Owner: postgres
--

ALTER TABLE ONLY i2b2pm.pm_global_params ALTER COLUMN id SET DEFAULT nextval('i2b2pm.pm_global_params_id_seq'::regclass);


--
-- Name: pm_hive_params id; Type: DEFAULT; Schema: i2b2pm; Owner: postgres
--

ALTER TABLE ONLY i2b2pm.pm_hive_params ALTER COLUMN id SET DEFAULT nextval('i2b2pm.pm_hive_params_id_seq'::regclass);


--
-- Name: pm_project_params id; Type: DEFAULT; Schema: i2b2pm; Owner: postgres
--

ALTER TABLE ONLY i2b2pm.pm_project_params ALTER COLUMN id SET DEFAULT nextval('i2b2pm.pm_project_params_id_seq'::regclass);


--
-- Name: pm_project_request id; Type: DEFAULT; Schema: i2b2pm; Owner: postgres
--

ALTER TABLE ONLY i2b2pm.pm_project_request ALTER COLUMN id SET DEFAULT nextval('i2b2pm.pm_project_request_id_seq'::regclass);


--
-- Name: pm_project_user_params id; Type: DEFAULT; Schema: i2b2pm; Owner: postgres
--

ALTER TABLE ONLY i2b2pm.pm_project_user_params ALTER COLUMN id SET DEFAULT nextval('i2b2pm.pm_project_user_params_id_seq'::regclass);


--
-- Name: pm_user_params id; Type: DEFAULT; Schema: i2b2pm; Owner: postgres
--

ALTER TABLE ONLY i2b2pm.pm_user_params ALTER COLUMN id SET DEFAULT nextval('i2b2pm.pm_user_params_id_seq'::regclass);


--
-- Data for Name: archive_observation_fact; Type: TABLE DATA; Schema: i2b2demodata; Owner: postgres
--

COPY i2b2demodata.archive_observation_fact (encounter_num, patient_num, concept_cd, provider_id, start_date, modifier_cd, instance_num, valtype_cd, tval_char, nval_num, valueflag_cd, quantity_num, units_cd, end_date, location_cd, observation_blob, confidence_num, update_date, download_date, import_date, sourcesystem_cd, upload_id, text_search_index, archive_upload_id) FROM stdin;
\.


--
-- Data for Name: code_lookup; Type: TABLE DATA; Schema: i2b2demodata; Owner: postgres
--

COPY i2b2demodata.code_lookup (table_cd, column_cd, code_cd, name_char, lookup_blob, upload_date, update_date, download_date, import_date, sourcesystem_cd, upload_id) FROM stdin;
\.


--
-- Data for Name: concept_dimension; Type: TABLE DATA; Schema: i2b2demodata; Owner: postgres
--

COPY i2b2demodata.concept_dimension (concept_path, concept_cd, name_char, concept_blob, update_date, download_date, import_date, sourcesystem_cd, upload_id) FROM stdin;
\\test\\		\N	\N	\N	\N	2022-05-02 12:01:25.164947	\N	1
\\test\\1\\	TEST:1	\N	\N	\N	\N	2022-05-02 12:01:25.164947	\N	1
\\test\\2\\	TEST:2	\N	\N	\N	\N	2022-05-02 12:01:25.164947	\N	1
\\test\\3\\	TEST:3	\N	\N	\N	\N	2022-05-02 12:01:25.164947	\N	1
\\SPHNv2020.1\\DeathStatus\\	A125	Death status	\N	\N	\N	\N	\N	\N
\\SPHNv2020.1\\FophDiagnosis\\	A168	Foph Diagnosis	\N	\N	\N	\N	\N	\N
\\I2B2\\Demographics\\Gender\\Female\\	DEM|SEX:f	Female	\N	\N	\N	\N	\N	\N
\\I2B2\\Demographics\\Gender\\Male\\	DEM|SEX:m	Male	\N	\N	\N	\N	\N	\N
\.


--
-- Data for Name: datamart_report; Type: TABLE DATA; Schema: i2b2demodata; Owner: postgres
--

COPY i2b2demodata.datamart_report (total_patient, total_observationfact, total_event, report_date) FROM stdin;
\.


--
-- Data for Name: encounter_mapping; Type: TABLE DATA; Schema: i2b2demodata; Owner: postgres
--

COPY i2b2demodata.encounter_mapping (encounter_ide, encounter_ide_source, project_id, encounter_num, patient_ide, patient_ide_source, encounter_ide_status, upload_date, update_date, download_date, import_date, sourcesystem_cd, upload_id) FROM stdin;
test1	test	Demo	1	test1	test	\N	\N	\N	\N	2022-05-02 12:01:25.170494	\N	1
test2	test	Demo	2	test2	test	\N	\N	\N	\N	2022-05-02 12:01:25.170494	\N	1
test3	test	Demo	3	test3	test	\N	\N	\N	\N	2022-05-02 12:01:25.170494	\N	1
test4	test	Demo	4	test4	test	\N	\N	\N	\N	2022-05-02 12:01:25.170494	\N	1
\.


--
-- Data for Name: modifier_dimension; Type: TABLE DATA; Schema: i2b2demodata; Owner: postgres
--

COPY i2b2demodata.modifier_dimension (modifier_path, modifier_cd, name_char, modifier_blob, update_date, download_date, import_date, sourcesystem_cd, upload_id) FROM stdin;
\\modifiers1\\	TEST:4-1	\N	\N	\N	\N	2022-05-02 12:01:25.16588	\N	1
\\modifiers2\\	TEST:4-2	\N	\N	\N	\N	2022-05-02 12:01:25.16588	\N	1
\\modifiers3\\	TEST:4-3	\N	\N	\N	\N	2022-05-02 12:01:25.16588	\N	1
\\modifiers1\\1\\	TEST:5	\N	\N	\N	\N	2022-05-02 12:01:25.16588	\N	1
\\modifiers2\\2\\	TEST:6	\N	\N	\N	\N	2022-05-02 12:01:25.16588	\N	1
\\modifiers3\\3\\	TEST:7	\N	\N	\N	\N	2022-05-02 12:01:25.16588	\N	1
\\modifiers2\\text\\	TEST:8	\N	\N	\N	\N	2022-05-02 12:01:25.16588	\N	1
\\modifiers3\\text\\	TEST:9	\N	\N	\N	\N	2022-05-02 12:01:25.16588	\N	1
\\DeathStatus-status\\	126	Value of death status	\N	\N	\N	\N	\N	\N
\\DeathStatus-status\\death\\	126:1	Value of death status	\N	\N	\N	\N	\N	\N
\\DeathStatus-status\\unknown\\	126:0	Value of death status	\N	\N	\N	\N	\N	\N
\\FophDiagnosis-code\\ICD10\\	101:ICD10	Diagnosis value	\N	\N	\N	\N	\N	\N
\\FophDiagnosis-code\\ICD10\\Conditions on the perinatal period(760-779)\\Maternally caused (760-763)\\(762) Fetus or newborn affected b~\\(762-3) Placental transfusion syn~\\	101:ICD10:762.5	Diagnosis value	\N	\N	\N	\N	\N	\N
\.


--
-- Data for Name: observation_fact; Type: TABLE DATA; Schema: i2b2demodata; Owner: postgres
--

COPY i2b2demodata.observation_fact (encounter_num, patient_num, concept_cd, provider_id, start_date, modifier_cd, instance_num, valtype_cd, tval_char, nval_num, valueflag_cd, quantity_num, units_cd, end_date, location_cd, observation_blob, confidence_num, update_date, download_date, import_date, sourcesystem_cd, upload_id, text_search_index) FROM stdin;
1	1	TEST:1	test	2022-05-02 12:01:25.171488	@	1	N	E	10.00000	\N	\N	\N	\N	\N	\N	\N	\N	\N	2022-05-02 12:01:25.171488	\N	1	1
1	1	TEST:1	test	2022-05-02 12:01:25.171488	TEST:5	1	N	E	10.00000	\N	\N	\N	\N	\N	\N	\N	\N	\N	2022-05-02 12:01:25.171488	\N	1	2
1	1	TEST:2	test	2022-05-02 12:01:25.171488	TEST:8	1	T	bcde	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2022-05-02 12:01:25.171488	\N	1	3
1	1	TEST:3	test	2022-05-02 12:01:25.171488	TEST:9	1	T	ab	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2022-05-02 12:01:25.171488	\N	1	4
2	2	TEST:1	test	2022-05-02 12:01:25.171488	@	1	N	E	20.00000	\N	\N	\N	\N	\N	\N	\N	\N	\N	2022-05-02 12:01:25.171488	\N	1	5
2	2	TEST:1	test	2022-05-02 12:01:25.171488	TEST:4-1	1	N	E	20.00000	\N	\N	\N	\N	\N	\N	\N	\N	\N	2022-05-02 12:01:25.171488	\N	1	6
2	2	TEST:2	test	2022-05-02 12:01:25.171488	@	1	N	E	50.00000	\N	\N	\N	\N	\N	\N	\N	\N	\N	2022-05-02 12:01:25.171488	\N	1	7
2	2	TEST:2	test	2022-05-02 12:01:25.171488	TEST:6	1	N	E	5.00000	\N	\N	\N	\N	\N	\N	\N	\N	\N	2022-05-02 12:01:25.171488	\N	1	8
2	2	TEST:2	test	2022-05-02 12:01:25.171488	TEST:8	1	T	abc	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2022-05-02 12:01:25.171488	\N	1	9
2	2	TEST:3	test	2022-05-02 12:01:25.171488	TEST:9	1	T	def	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2022-05-02 12:01:25.171488	\N	1	10
3	3	TEST:1	test	2022-05-02 12:01:25.171488	@	1	N	E	30.00000	\N	\N	\N	\N	\N	\N	\N	\N	\N	2022-05-02 12:01:25.171488	\N	1	11
3	3	TEST:1	test	2022-05-02 12:01:25.171488	TEST:4-1	1	N	E	15.00000	\N	\N	\N	\N	\N	\N	\N	\N	\N	2022-05-02 12:01:25.171488	\N	1	12
3	3	TEST:1	test	2022-05-02 12:01:25.171488	TEST:5	1	N	E	15.00000	\N	\N	\N	\N	\N	\N	\N	\N	\N	2022-05-02 12:01:25.171488	\N	1	13
3	3	TEST:2	test	2022-05-02 12:01:25.171488	@	1	N	E	25.00000	\N	\N	\N	\N	\N	\N	\N	\N	\N	2022-05-02 12:01:25.171488	\N	1	14
3	3	TEST:2	test	2022-05-02 12:01:25.171488	TEST:4-1	1	N	E	30.00000	\N	\N	\N	\N	\N	\N	\N	\N	\N	2022-05-02 12:01:25.171488	\N	1	15
3	3	TEST:2	test	2022-05-02 12:01:25.171488	TEST:6	1	N	E	15.00000	\N	\N	\N	\N	\N	\N	\N	\N	\N	2022-05-02 12:01:25.171488	\N	1	16
3	3	TEST:2	test	2022-05-02 12:01:25.171488	TEST:8	1	T	de	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2022-05-02 12:01:25.171488	\N	1	17
3	3	TEST:3	test	2022-05-02 12:01:25.171488	@	1	N	E	77.00000	\N	\N	\N	\N	\N	\N	\N	\N	\N	2022-05-02 12:01:25.171488	\N	1	18
3	3	TEST:3	test	2022-05-02 12:01:25.171488	TEST:4-1	1	N	E	66.00000	\N	\N	\N	\N	\N	\N	\N	\N	\N	2022-05-02 12:01:25.171488	\N	1	19
3	3	TEST:3	test	2022-05-02 12:01:25.171488	TEST:7	1	N	E	88.00000	\N	\N	\N	\N	\N	\N	\N	\N	\N	2022-05-02 12:01:25.171488	\N	1	20
3	3	TEST:3	test	2022-05-02 12:01:25.171488	TEST:9	1	T	abcdef	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2022-05-02 12:01:25.171488	\N	1	21
4	4	TEST:3	test	2022-05-02 12:01:25.171488	@	1	N	E	20.00000	\N	\N	\N	\N	\N	\N	\N	\N	\N	2022-05-02 12:01:25.171488	\N	1	22
4	4	TEST:3	test	2022-05-02 12:01:25.171488	TEST:7	1	N	E	10.00000	\N	\N	\N	\N	\N	\N	\N	\N	\N	2022-05-02 12:01:25.171488	\N	1	23
483573	1137	A125	CHE-XXX	1972-02-15 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-02-15 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	24
483573	1137	A125	CHE-XXX	1972-02-15 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1972-02-15 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	25
483801	1137	A168	CHE-XXX	1971-04-15 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-02-15 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	26
483801	1137	A168	CHE-XXX	1971-04-15 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-02-15 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	27
484029	1137	DEM|SEX:f	CHE-XXX	1971-04-15 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-02-15 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	28
483574	1138	A125	CHE-XXX	1971-06-12 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-06-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	29
483574	1138	A125	CHE-XXX	1971-06-12 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1971-06-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	30
483802	1138	A168	CHE-XXX	1970-03-14 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-06-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	31
483802	1138	A168	CHE-XXX	1970-03-14 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1971-06-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	32
484030	1138	DEM|SEX:f	CHE-XXX	1970-03-14 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-06-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	33
483738	1139	A125	CHE-XXX	1973-03-16 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-03-16 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	34
483738	1139	A125	CHE-XXX	1973-03-16 01:00:00	126:0	1	\N	\N	\N	\N	\N	\N	1973-03-16 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	35
483803	1139	A168	CHE-XXX	1970-06-10 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-03-16 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	36
483803	1139	A168	CHE-XXX	1970-06-10 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1973-03-16 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	37
484031	1139	DEM|SEX:f	CHE-XXX	1970-06-10 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-03-16 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	38
483575	1140	A125	CHE-XXX	1972-05-08 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-05-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	39
483575	1140	A125	CHE-XXX	1972-05-08 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1972-05-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	40
483804	1140	A168	CHE-XXX	1971-10-11 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-05-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	41
483804	1140	A168	CHE-XXX	1971-10-11 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-05-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	42
484032	1140	DEM|SEX:f	CHE-XXX	1971-10-11 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-05-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	43
483576	1141	A125	CHE-XXX	1975-02-26 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1975-02-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	44
483576	1141	A125	CHE-XXX	1975-02-26 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1975-02-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	45
483805	1141	A168	CHE-XXX	1972-09-26 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1975-02-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	46
483805	1141	A168	CHE-XXX	1972-09-26 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1975-02-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	47
484033	1141	DEM|SEX:f	CHE-XXX	1972-09-26 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1975-02-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	48
483739	1142	A125	CHE-XXX	1974-06-02 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1974-06-02 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	49
483739	1142	A125	CHE-XXX	1974-06-02 01:00:00	126:0	1	\N	\N	\N	\N	\N	\N	1974-06-02 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	50
483806	1142	A168	CHE-XXX	1971-08-15 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1974-06-02 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	51
483806	1142	A168	CHE-XXX	1971-08-15 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1974-06-02 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	52
484034	1142	DEM|SEX:f	CHE-XXX	1971-08-15 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1974-06-02 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	53
483577	1143	A125	CHE-XXX	1971-08-02 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-08-02 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	54
483577	1143	A125	CHE-XXX	1971-08-02 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1971-08-02 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	55
483807	1143	A168	CHE-XXX	1970-09-26 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-08-02 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	56
483807	1143	A168	CHE-XXX	1970-09-26 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1971-08-02 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	57
484167	1143	DEM|SEX:m	CHE-XXX	1970-09-26 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-08-02 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	58
483578	1144	A125	CHE-XXX	1973-04-30 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-04-30 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	59
483578	1144	A125	CHE-XXX	1973-04-30 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1973-04-30 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	60
483808	1144	A168	CHE-XXX	1972-05-04 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-04-30 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	61
483808	1144	A168	CHE-XXX	1972-05-04 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1973-04-30 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	62
484168	1144	DEM|SEX:m	CHE-XXX	1972-05-04 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-04-30 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	63
483579	1145	A125	CHE-XXX	1972-08-23 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-08-23 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	64
483579	1145	A125	CHE-XXX	1972-08-23 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1972-08-23 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	65
483809	1145	A168	CHE-XXX	1972-01-18 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-08-23 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	66
483809	1145	A168	CHE-XXX	1972-01-18 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-08-23 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	67
484035	1145	DEM|SEX:f	CHE-XXX	1972-01-18 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-08-23 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	68
483580	1146	A125	CHE-XXX	1972-09-10 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-09-10 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	69
483580	1146	A125	CHE-XXX	1972-09-10 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1972-09-10 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	70
483810	1146	A168	CHE-XXX	1972-03-28 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-09-10 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	71
483810	1146	A168	CHE-XXX	1972-03-28 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-09-10 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	72
484036	1146	DEM|SEX:f	CHE-XXX	1972-03-28 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-09-10 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	73
483581	1147	A125	CHE-XXX	1971-04-27 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-04-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	74
483581	1147	A125	CHE-XXX	1971-04-27 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1971-04-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	75
483811	1147	A168	CHE-XXX	1970-11-08 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-04-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	76
483811	1147	A168	CHE-XXX	1970-11-08 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1971-04-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	77
484037	1147	DEM|SEX:f	CHE-XXX	1970-11-08 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-04-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	78
483582	1148	A125	CHE-XXX	1973-10-18 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-10-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	79
483582	1148	A125	CHE-XXX	1973-10-18 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1973-10-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	80
483812	1148	A168	CHE-XXX	1972-01-03 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-10-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	81
483812	1148	A168	CHE-XXX	1972-01-03 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1973-10-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	82
484169	1148	DEM|SEX:m	CHE-XXX	1972-01-03 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-10-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	83
483583	1149	A125	CHE-XXX	1972-01-14 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-01-14 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	84
483583	1149	A125	CHE-XXX	1972-01-14 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1972-01-14 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	85
483813	1149	A168	CHE-XXX	1970-01-16 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-01-14 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	86
483813	1149	A168	CHE-XXX	1970-01-16 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-01-14 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	87
484170	1149	DEM|SEX:m	CHE-XXX	1970-01-16 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-01-14 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	88
483584	1150	A125	CHE-XXX	1972-08-13 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-08-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	89
483584	1150	A125	CHE-XXX	1972-08-13 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1972-08-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	90
483814	1150	A168	CHE-XXX	1972-06-03 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-08-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	91
483814	1150	A168	CHE-XXX	1972-06-03 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-08-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	92
484038	1150	DEM|SEX:f	CHE-XXX	1972-06-03 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-08-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	93
483585	1151	A125	CHE-XXX	1972-06-27 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-06-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	94
483585	1151	A125	CHE-XXX	1972-06-27 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1972-06-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	95
483815	1151	A168	CHE-XXX	1970-12-08 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-06-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	96
483815	1151	A168	CHE-XXX	1970-12-08 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-06-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	97
484039	1151	DEM|SEX:f	CHE-XXX	1970-12-08 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-06-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	98
483586	1152	A125	CHE-XXX	1970-12-05 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1970-12-05 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	99
483586	1152	A125	CHE-XXX	1970-12-05 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1970-12-05 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	100
483816	1152	A168	CHE-XXX	1970-07-14 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1970-12-05 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	101
483816	1152	A168	CHE-XXX	1970-07-14 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1970-12-05 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	102
484040	1152	DEM|SEX:f	CHE-XXX	1970-07-14 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1970-12-05 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	103
483587	1153	A125	CHE-XXX	1972-01-27 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-01-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	104
483587	1153	A125	CHE-XXX	1972-01-27 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1972-01-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	105
483817	1153	A168	CHE-XXX	1970-05-24 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-01-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	106
483817	1153	A168	CHE-XXX	1970-05-24 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-01-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	107
484041	1153	DEM|SEX:f	CHE-XXX	1970-05-24 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-01-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	108
483588	1154	A125	CHE-XXX	1973-10-12 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-10-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	109
483588	1154	A125	CHE-XXX	1973-10-12 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1973-10-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	110
483818	1154	A168	CHE-XXX	1971-11-05 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-10-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	111
483818	1154	A168	CHE-XXX	1971-11-05 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1973-10-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	112
484042	1154	DEM|SEX:f	CHE-XXX	1971-11-05 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-10-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	113
483589	1155	A125	CHE-XXX	1972-06-15 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-06-15 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	114
483589	1155	A125	CHE-XXX	1972-06-15 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1972-06-15 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	115
483819	1155	A168	CHE-XXX	1972-04-15 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-06-15 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	116
483819	1155	A168	CHE-XXX	1972-04-15 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-06-15 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	117
484171	1155	DEM|SEX:m	CHE-XXX	1972-04-15 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-06-15 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	118
483590	1156	A125	CHE-XXX	1972-12-13 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-12-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	119
483590	1156	A125	CHE-XXX	1972-12-13 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1972-12-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	120
483820	1156	A168	CHE-XXX	1972-09-16 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-12-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	121
483820	1156	A168	CHE-XXX	1972-09-16 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-12-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	122
484043	1156	DEM|SEX:f	CHE-XXX	1972-09-16 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-12-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	123
483591	1157	A125	CHE-XXX	1971-09-19 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-09-19 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	124
483591	1157	A125	CHE-XXX	1971-09-19 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1971-09-19 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	125
483821	1157	A168	CHE-XXX	1970-11-22 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-09-19 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	126
483821	1157	A168	CHE-XXX	1970-11-22 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1971-09-19 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	127
484044	1157	DEM|SEX:f	CHE-XXX	1970-11-22 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-09-19 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	128
483592	1158	A125	CHE-XXX	1971-11-09 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-11-09 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	129
483592	1158	A125	CHE-XXX	1971-11-09 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1971-11-09 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	130
483822	1158	A168	CHE-XXX	1971-08-20 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-11-09 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	131
483822	1158	A168	CHE-XXX	1971-08-20 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1971-11-09 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	132
484172	1158	DEM|SEX:m	CHE-XXX	1971-08-20 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-11-09 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	133
483593	1159	A125	CHE-XXX	1973-02-17 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-02-17 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	134
483593	1159	A125	CHE-XXX	1973-02-17 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1973-02-17 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	135
483823	1159	A168	CHE-XXX	1971-06-04 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-02-17 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	136
483823	1159	A168	CHE-XXX	1971-06-04 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1973-02-17 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	137
484045	1159	DEM|SEX:f	CHE-XXX	1971-06-04 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-02-17 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	138
483594	1160	A125	CHE-XXX	1972-08-29 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-08-29 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	139
483594	1160	A125	CHE-XXX	1972-08-29 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1972-08-29 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	140
483824	1160	A168	CHE-XXX	1971-08-24 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-08-29 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	141
483824	1160	A168	CHE-XXX	1971-08-24 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-08-29 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	142
484046	1160	DEM|SEX:f	CHE-XXX	1971-08-24 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-08-29 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	143
483595	1161	A125	CHE-XXX	1971-10-25 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-10-25 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	144
483595	1161	A125	CHE-XXX	1971-10-25 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1971-10-25 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	145
483825	1161	A168	CHE-XXX	1970-09-26 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-10-25 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	146
483825	1161	A168	CHE-XXX	1970-09-26 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1971-10-25 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	147
484047	1161	DEM|SEX:f	CHE-XXX	1970-09-26 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-10-25 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	148
483596	1162	A125	CHE-XXX	1973-05-20 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-05-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	149
483596	1162	A125	CHE-XXX	1973-05-20 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1973-05-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	150
483826	1162	A168	CHE-XXX	1971-12-17 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-05-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	151
483826	1162	A168	CHE-XXX	1971-12-17 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1973-05-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	152
484173	1162	DEM|SEX:m	CHE-XXX	1971-12-17 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-05-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	153
483597	1163	A125	CHE-XXX	1974-03-10 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1974-03-10 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	154
483597	1163	A125	CHE-XXX	1974-03-10 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1974-03-10 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	155
483827	1163	A168	CHE-XXX	1972-08-13 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1974-03-10 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	156
483827	1163	A168	CHE-XXX	1972-08-13 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1974-03-10 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	157
484048	1163	DEM|SEX:f	CHE-XXX	1972-08-13 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1974-03-10 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	158
483598	1164	A125	CHE-XXX	1971-02-25 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-02-25 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	159
483598	1164	A125	CHE-XXX	1971-02-25 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1971-02-25 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	160
483828	1164	A168	CHE-XXX	1970-10-30 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-02-25 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	161
483828	1164	A168	CHE-XXX	1970-10-30 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1971-02-25 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	162
484049	1164	DEM|SEX:f	CHE-XXX	1970-10-30 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-02-25 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	163
483599	1165	A125	CHE-XXX	1972-03-28 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-03-28 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	164
483599	1165	A125	CHE-XXX	1972-03-28 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1972-03-28 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	165
483829	1165	A168	CHE-XXX	1971-03-04 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-03-28 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	166
483829	1165	A168	CHE-XXX	1971-03-04 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-03-28 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	167
484050	1165	DEM|SEX:f	CHE-XXX	1971-03-04 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-03-28 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	168
483600	1166	A125	CHE-XXX	1971-05-09 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-05-09 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	169
483600	1166	A125	CHE-XXX	1971-05-09 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1971-05-09 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	170
483830	1166	A168	CHE-XXX	1971-04-27 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-05-09 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	171
483830	1166	A168	CHE-XXX	1971-04-27 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1971-05-09 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	172
484051	1166	DEM|SEX:f	CHE-XXX	1971-04-27 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-05-09 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	173
483601	1167	A125	CHE-XXX	1973-10-28 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-10-28 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	174
483601	1167	A125	CHE-XXX	1973-10-28 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1973-10-28 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	175
483831	1167	A168	CHE-XXX	1972-07-12 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-10-28 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	176
483831	1167	A168	CHE-XXX	1972-07-12 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1973-10-28 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	177
484174	1167	DEM|SEX:m	CHE-XXX	1972-07-12 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-10-28 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	178
483602	1168	A125	CHE-XXX	1970-02-12 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1970-02-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	179
483602	1168	A125	CHE-XXX	1970-02-12 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1970-02-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	180
483832	1168	A168	CHE-XXX	1970-01-17 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1970-02-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	181
483832	1168	A168	CHE-XXX	1970-01-17 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1970-02-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	182
484052	1168	DEM|SEX:f	CHE-XXX	1970-01-17 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1970-02-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	183
483603	1169	A125	CHE-XXX	1973-04-21 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-04-21 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	184
483603	1169	A125	CHE-XXX	1973-04-21 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1973-04-21 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	185
483833	1169	A168	CHE-XXX	1971-11-05 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-04-21 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	186
483833	1169	A168	CHE-XXX	1971-11-05 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1973-04-21 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	187
484053	1169	DEM|SEX:f	CHE-XXX	1971-11-05 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-04-21 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	188
483604	1170	A125	CHE-XXX	1972-09-25 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-09-25 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	189
483604	1170	A125	CHE-XXX	1972-09-25 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1972-09-25 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	190
483834	1170	A168	CHE-XXX	1972-06-10 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-09-25 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	191
483834	1170	A168	CHE-XXX	1972-06-10 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-09-25 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	192
484175	1170	DEM|SEX:m	CHE-XXX	1972-06-10 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-09-25 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	193
483605	1171	A125	CHE-XXX	1971-05-15 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-05-15 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	194
483605	1171	A125	CHE-XXX	1971-05-15 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1971-05-15 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	195
483835	1171	A168	CHE-XXX	1971-03-23 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-05-15 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	196
483835	1171	A168	CHE-XXX	1971-03-23 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1971-05-15 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	197
484054	1171	DEM|SEX:f	CHE-XXX	1971-03-23 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-05-15 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	198
483606	1172	A125	CHE-XXX	1971-02-04 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-02-04 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	199
483606	1172	A125	CHE-XXX	1971-02-04 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1971-02-04 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	200
483836	1172	A168	CHE-XXX	1970-10-05 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-02-04 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	201
483836	1172	A168	CHE-XXX	1970-10-05 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1971-02-04 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	202
484176	1172	DEM|SEX:m	CHE-XXX	1970-10-05 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-02-04 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	203
483607	1173	A125	CHE-XXX	1973-04-08 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-04-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	204
483607	1173	A125	CHE-XXX	1973-04-08 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1973-04-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	205
483837	1173	A168	CHE-XXX	1971-01-15 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-04-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	206
483837	1173	A168	CHE-XXX	1971-01-15 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1973-04-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	207
484055	1173	DEM|SEX:f	CHE-XXX	1971-01-15 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-04-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	208
483740	1174	A125	CHE-XXX	1974-06-18 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1974-06-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	209
483740	1174	A125	CHE-XXX	1974-06-18 01:00:00	126:0	1	\N	\N	\N	\N	\N	\N	1974-06-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	210
483838	1174	A168	CHE-XXX	1971-10-27 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1974-06-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	211
483838	1174	A168	CHE-XXX	1971-10-27 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1974-06-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	212
484177	1174	DEM|SEX:m	CHE-XXX	1971-10-27 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1974-06-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	213
483608	1175	A125	CHE-XXX	1972-05-04 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-05-04 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	214
483608	1175	A125	CHE-XXX	1972-05-04 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1972-05-04 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	215
483839	1175	A168	CHE-XXX	1972-02-01 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-05-04 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	216
483839	1175	A168	CHE-XXX	1972-02-01 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-05-04 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	217
484056	1175	DEM|SEX:f	CHE-XXX	1972-02-01 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-05-04 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	218
483609	1176	A125	CHE-XXX	1974-09-04 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1974-09-04 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	219
483609	1176	A125	CHE-XXX	1974-09-04 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1974-09-04 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	220
483840	1176	A168	CHE-XXX	1972-09-03 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1974-09-04 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	221
483840	1176	A168	CHE-XXX	1972-09-03 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1974-09-04 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	222
484178	1176	DEM|SEX:m	CHE-XXX	1972-09-03 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1974-09-04 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	223
483610	1177	A125	CHE-XXX	1972-03-18 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-03-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	224
483610	1177	A125	CHE-XXX	1972-03-18 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1972-03-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	225
483841	1177	A168	CHE-XXX	1970-12-14 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-03-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	226
483841	1177	A168	CHE-XXX	1970-12-14 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-03-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	227
484057	1177	DEM|SEX:f	CHE-XXX	1970-12-14 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-03-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	228
483611	1178	A125	CHE-XXX	1973-02-14 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-02-14 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	229
483611	1178	A125	CHE-XXX	1973-02-14 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1973-02-14 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	230
483842	1178	A168	CHE-XXX	1972-09-14 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-02-14 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	231
483842	1178	A168	CHE-XXX	1972-09-14 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1973-02-14 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	232
484179	1178	DEM|SEX:m	CHE-XXX	1972-09-14 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-02-14 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	233
483612	1179	A125	CHE-XXX	1972-01-20 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-01-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	234
483612	1179	A125	CHE-XXX	1972-01-20 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1972-01-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	235
483843	1179	A168	CHE-XXX	1970-11-13 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-01-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	236
483843	1179	A168	CHE-XXX	1970-11-13 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-01-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	237
484180	1179	DEM|SEX:m	CHE-XXX	1970-11-13 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-01-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	238
483613	1180	A125	CHE-XXX	1972-10-24 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-10-24 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	239
483613	1180	A125	CHE-XXX	1972-10-24 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1972-10-24 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	240
483844	1180	A168	CHE-XXX	1972-06-01 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-10-24 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	241
483844	1180	A168	CHE-XXX	1972-06-01 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-10-24 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	242
484181	1180	DEM|SEX:m	CHE-XXX	1972-06-01 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-10-24 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	243
483614	1181	A125	CHE-XXX	1973-03-30 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-03-30 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	244
483614	1181	A125	CHE-XXX	1973-03-30 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1973-03-30 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	245
483845	1181	A168	CHE-XXX	1971-08-25 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-03-30 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	246
483845	1181	A168	CHE-XXX	1971-08-25 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1973-03-30 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	247
484058	1181	DEM|SEX:f	CHE-XXX	1971-08-25 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-03-30 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	248
483615	1182	A125	CHE-XXX	1972-02-24 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-02-24 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	249
483615	1182	A125	CHE-XXX	1972-02-24 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1972-02-24 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	250
483846	1182	A168	CHE-XXX	1971-11-21 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-02-24 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	251
483846	1182	A168	CHE-XXX	1971-11-21 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-02-24 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	252
484182	1182	DEM|SEX:m	CHE-XXX	1971-11-21 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-02-24 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	253
483616	1183	A125	CHE-XXX	1971-04-17 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-04-17 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	254
483616	1183	A125	CHE-XXX	1971-04-17 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1971-04-17 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	255
483847	1183	A168	CHE-XXX	1970-06-18 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-04-17 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	256
483847	1183	A168	CHE-XXX	1970-06-18 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1971-04-17 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	257
484059	1183	DEM|SEX:f	CHE-XXX	1970-06-18 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-04-17 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	258
483617	1184	A125	CHE-XXX	1973-04-05 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-04-05 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	259
483617	1184	A125	CHE-XXX	1973-04-05 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1973-04-05 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	260
483848	1184	A168	CHE-XXX	1971-11-03 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-04-05 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	261
483848	1184	A168	CHE-XXX	1971-11-03 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1973-04-05 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	262
484060	1184	DEM|SEX:f	CHE-XXX	1971-11-03 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-04-05 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	263
483618	1185	A125	CHE-XXX	1973-12-03 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-12-03 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	264
483618	1185	A125	CHE-XXX	1973-12-03 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1973-12-03 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	265
483849	1185	A168	CHE-XXX	1972-02-29 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-12-03 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	266
483849	1185	A168	CHE-XXX	1972-02-29 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1973-12-03 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	267
484061	1185	DEM|SEX:f	CHE-XXX	1972-02-29 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-12-03 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	268
483619	1186	A125	CHE-XXX	1974-10-11 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1974-10-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	269
483619	1186	A125	CHE-XXX	1974-10-11 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1974-10-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	270
483850	1186	A168	CHE-XXX	1972-09-06 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1974-10-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	271
483850	1186	A168	CHE-XXX	1972-09-06 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1974-10-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	272
484183	1186	DEM|SEX:m	CHE-XXX	1972-09-06 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1974-10-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	273
483620	1187	A125	CHE-XXX	1972-02-02 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-02-02 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	274
483620	1187	A125	CHE-XXX	1972-02-02 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1972-02-02 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	275
483851	1187	A168	CHE-XXX	1970-01-28 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-02-02 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	276
483851	1187	A168	CHE-XXX	1970-01-28 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-02-02 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	277
484184	1187	DEM|SEX:m	CHE-XXX	1970-01-28 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-02-02 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	278
483621	1188	A125	CHE-XXX	1970-09-11 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1970-09-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	279
483621	1188	A125	CHE-XXX	1970-09-11 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1970-09-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	280
483852	1188	A168	CHE-XXX	1970-03-06 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1970-09-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	281
483852	1188	A168	CHE-XXX	1970-03-06 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1970-09-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	282
484062	1188	DEM|SEX:f	CHE-XXX	1970-03-06 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1970-09-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	283
483622	1189	A125	CHE-XXX	1970-07-01 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1970-07-01 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	284
483622	1189	A125	CHE-XXX	1970-07-01 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1970-07-01 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	285
483853	1189	A168	CHE-XXX	1970-05-09 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1970-07-01 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	286
483853	1189	A168	CHE-XXX	1970-05-09 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1970-07-01 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	287
484063	1189	DEM|SEX:f	CHE-XXX	1970-05-09 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1970-07-01 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	288
483623	1190	A125	CHE-XXX	1973-01-02 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-01-02 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	289
483623	1190	A125	CHE-XXX	1973-01-02 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1973-01-02 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	290
483854	1190	A168	CHE-XXX	1972-05-01 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-01-02 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	291
483854	1190	A168	CHE-XXX	1972-05-01 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1973-01-02 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	292
484064	1190	DEM|SEX:f	CHE-XXX	1972-05-01 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-01-02 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	293
483624	1191	A125	CHE-XXX	1972-02-08 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-02-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	294
483624	1191	A125	CHE-XXX	1972-02-08 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1972-02-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	295
483855	1191	A168	CHE-XXX	1970-03-21 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-02-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	296
483855	1191	A168	CHE-XXX	1970-03-21 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-02-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	297
484065	1191	DEM|SEX:f	CHE-XXX	1970-03-21 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-02-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	298
483625	1192	A125	CHE-XXX	1972-04-20 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-04-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	299
483625	1192	A125	CHE-XXX	1972-04-20 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1972-04-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	300
483856	1192	A168	CHE-XXX	1972-02-15 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-04-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	301
483856	1192	A168	CHE-XXX	1972-02-15 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-04-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	302
484066	1192	DEM|SEX:f	CHE-XXX	1972-02-15 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-04-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	303
483626	1193	A125	CHE-XXX	1970-02-16 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1970-02-16 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	304
483626	1193	A125	CHE-XXX	1970-02-16 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1970-02-16 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	305
483857	1193	A168	CHE-XXX	1970-02-11 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1970-02-16 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	306
483857	1193	A168	CHE-XXX	1970-02-11 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1970-02-16 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	307
484185	1193	DEM|SEX:m	CHE-XXX	1970-02-11 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1970-02-16 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	308
483627	1194	A125	CHE-XXX	1972-11-19 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-11-19 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	309
483627	1194	A125	CHE-XXX	1972-11-19 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1972-11-19 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	310
483858	1194	A168	CHE-XXX	1972-07-10 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-11-19 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	311
483858	1194	A168	CHE-XXX	1972-07-10 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-11-19 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	312
484067	1194	DEM|SEX:f	CHE-XXX	1972-07-10 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-11-19 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	313
483628	1195	A125	CHE-XXX	1972-11-25 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-11-25 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	314
483628	1195	A125	CHE-XXX	1972-11-25 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1972-11-25 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	315
483859	1195	A168	CHE-XXX	1971-01-08 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-11-25 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	316
483859	1195	A168	CHE-XXX	1971-01-08 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-11-25 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	317
484186	1195	DEM|SEX:m	CHE-XXX	1971-01-08 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-11-25 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	318
483629	1196	A125	CHE-XXX	1971-11-06 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-11-06 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	319
483629	1196	A125	CHE-XXX	1971-11-06 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1971-11-06 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	320
483860	1196	A168	CHE-XXX	1970-11-26 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-11-06 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	321
483860	1196	A168	CHE-XXX	1970-11-26 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1971-11-06 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	322
484187	1196	DEM|SEX:m	CHE-XXX	1970-11-26 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-11-06 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	323
483630	1197	A125	CHE-XXX	1971-11-08 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-11-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	324
483630	1197	A125	CHE-XXX	1971-11-08 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1971-11-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	325
483861	1197	A168	CHE-XXX	1970-08-21 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-11-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	326
483861	1197	A168	CHE-XXX	1970-08-21 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1971-11-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	327
484188	1197	DEM|SEX:m	CHE-XXX	1970-08-21 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-11-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	328
483631	1198	A125	CHE-XXX	1971-04-11 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-04-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	329
483631	1198	A125	CHE-XXX	1971-04-11 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1971-04-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	330
483862	1198	A168	CHE-XXX	1970-08-31 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-04-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	331
483862	1198	A168	CHE-XXX	1970-08-31 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1971-04-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	332
484068	1198	DEM|SEX:f	CHE-XXX	1970-08-31 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-04-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	333
483632	1199	A125	CHE-XXX	1971-12-04 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-12-04 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	334
483632	1199	A125	CHE-XXX	1971-12-04 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1971-12-04 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	335
483863	1199	A168	CHE-XXX	1971-06-12 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-12-04 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	336
483863	1199	A168	CHE-XXX	1971-06-12 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1971-12-04 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	337
484069	1199	DEM|SEX:f	CHE-XXX	1971-06-12 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-12-04 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	338
483633	1200	A125	CHE-XXX	1970-04-23 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1970-04-23 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	339
483633	1200	A125	CHE-XXX	1970-04-23 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1970-04-23 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	340
483864	1200	A168	CHE-XXX	1970-02-22 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1970-04-23 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	341
483864	1200	A168	CHE-XXX	1970-02-22 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1970-04-23 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	342
484189	1200	DEM|SEX:m	CHE-XXX	1970-02-22 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1970-04-23 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	343
483634	1201	A125	CHE-XXX	1971-05-20 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-05-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	344
483634	1201	A125	CHE-XXX	1971-05-20 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1971-05-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	345
483865	1201	A168	CHE-XXX	1970-12-08 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-05-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	346
483865	1201	A168	CHE-XXX	1970-12-08 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1971-05-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	347
484070	1201	DEM|SEX:f	CHE-XXX	1970-12-08 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-05-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	348
483635	1202	A125	CHE-XXX	1972-08-10 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-08-10 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	349
483635	1202	A125	CHE-XXX	1972-08-10 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1972-08-10 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	350
483866	1202	A168	CHE-XXX	1972-06-06 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-08-10 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	351
483866	1202	A168	CHE-XXX	1972-06-06 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-08-10 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	352
484071	1202	DEM|SEX:f	CHE-XXX	1972-06-06 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-08-10 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	353
483636	1203	A125	CHE-XXX	1972-06-02 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-06-02 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	354
483636	1203	A125	CHE-XXX	1972-06-02 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1972-06-02 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	355
483867	1203	A168	CHE-XXX	1971-11-07 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-06-02 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	356
483867	1203	A168	CHE-XXX	1971-11-07 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-06-02 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	357
484190	1203	DEM|SEX:m	CHE-XXX	1971-11-07 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-06-02 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	358
483741	1204	A125	CHE-XXX	1974-11-05 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1974-11-05 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	359
483741	1204	A125	CHE-XXX	1974-11-05 01:00:00	126:0	1	\N	\N	\N	\N	\N	\N	1974-11-05 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	360
483868	1204	A168	CHE-XXX	1972-08-06 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1974-11-05 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	361
483868	1204	A168	CHE-XXX	1972-08-06 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1974-11-05 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	362
484191	1204	DEM|SEX:m	CHE-XXX	1972-08-06 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1974-11-05 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	363
483637	1205	A125	CHE-XXX	1972-05-19 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-05-19 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	364
483637	1205	A125	CHE-XXX	1972-05-19 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1972-05-19 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	365
483869	1205	A168	CHE-XXX	1971-03-18 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-05-19 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	366
483869	1205	A168	CHE-XXX	1971-03-18 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-05-19 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	367
484072	1205	DEM|SEX:f	CHE-XXX	1971-03-18 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-05-19 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	368
483638	1206	A125	CHE-XXX	1972-09-12 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-09-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	369
483638	1206	A125	CHE-XXX	1972-09-12 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1972-09-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	370
483870	1206	A168	CHE-XXX	1972-01-26 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-09-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	371
483870	1206	A168	CHE-XXX	1972-01-26 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-09-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	372
484073	1206	DEM|SEX:f	CHE-XXX	1972-01-26 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-09-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	373
483742	1207	A125	CHE-XXX	1973-08-31 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-08-31 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	374
483742	1207	A125	CHE-XXX	1973-08-31 01:00:00	126:0	1	\N	\N	\N	\N	\N	\N	1973-08-31 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	375
483871	1207	A168	CHE-XXX	1971-05-14 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-08-31 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	376
483871	1207	A168	CHE-XXX	1971-05-14 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1973-08-31 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	377
484074	1207	DEM|SEX:f	CHE-XXX	1971-05-14 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-08-31 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	378
483639	1208	A125	CHE-XXX	1973-04-07 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-04-07 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	379
483639	1208	A125	CHE-XXX	1973-04-07 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1973-04-07 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	380
483872	1208	A168	CHE-XXX	1972-06-06 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-04-07 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	381
483872	1208	A168	CHE-XXX	1972-06-06 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1973-04-07 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	382
484192	1208	DEM|SEX:m	CHE-XXX	1972-06-06 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-04-07 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	383
483640	1209	A125	CHE-XXX	1972-06-08 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-06-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	384
483640	1209	A125	CHE-XXX	1972-06-08 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1972-06-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	385
483873	1209	A168	CHE-XXX	1972-05-28 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-06-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	386
483873	1209	A168	CHE-XXX	1972-05-28 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-06-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	387
484075	1209	DEM|SEX:f	CHE-XXX	1972-05-28 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-06-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	388
483641	1210	A125	CHE-XXX	1970-07-23 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1970-07-23 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	389
483641	1210	A125	CHE-XXX	1970-07-23 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1970-07-23 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	390
483874	1210	A168	CHE-XXX	1970-03-13 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1970-07-23 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	391
483874	1210	A168	CHE-XXX	1970-03-13 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1970-07-23 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	392
484076	1210	DEM|SEX:f	CHE-XXX	1970-03-13 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1970-07-23 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	393
483642	1211	A125	CHE-XXX	1971-06-30 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-06-30 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	394
483642	1211	A125	CHE-XXX	1971-06-30 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1971-06-30 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	395
483875	1211	A168	CHE-XXX	1970-11-16 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-06-30 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	396
483875	1211	A168	CHE-XXX	1970-11-16 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1971-06-30 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	397
484193	1211	DEM|SEX:m	CHE-XXX	1970-11-16 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-06-30 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	398
483643	1212	A125	CHE-XXX	1972-05-16 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-05-16 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	399
483643	1212	A125	CHE-XXX	1972-05-16 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1972-05-16 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	400
483876	1212	A168	CHE-XXX	1971-03-17 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-05-16 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	401
483876	1212	A168	CHE-XXX	1971-03-17 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-05-16 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	402
484194	1212	DEM|SEX:m	CHE-XXX	1971-03-17 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-05-16 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	403
483644	1213	A125	CHE-XXX	1974-01-13 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1974-01-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	404
483644	1213	A125	CHE-XXX	1974-01-13 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1974-01-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	405
483877	1213	A168	CHE-XXX	1972-02-08 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1974-01-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	406
483877	1213	A168	CHE-XXX	1972-02-08 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1974-01-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	407
484195	1213	DEM|SEX:m	CHE-XXX	1972-02-08 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1974-01-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	408
483645	1214	A125	CHE-XXX	1971-02-22 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-02-22 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	409
483645	1214	A125	CHE-XXX	1971-02-22 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1971-02-22 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	410
483878	1214	A168	CHE-XXX	1970-02-24 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-02-22 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	411
483878	1214	A168	CHE-XXX	1970-02-24 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1971-02-22 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	412
484196	1214	DEM|SEX:m	CHE-XXX	1970-02-24 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-02-22 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	413
483646	1215	A125	CHE-XXX	1972-03-13 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-03-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	414
483646	1215	A125	CHE-XXX	1972-03-13 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1972-03-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	415
483879	1215	A168	CHE-XXX	1972-03-02 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-03-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	416
483879	1215	A168	CHE-XXX	1972-03-02 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-03-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	417
484077	1215	DEM|SEX:f	CHE-XXX	1972-03-02 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-03-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	418
483647	1216	A125	CHE-XXX	1972-01-06 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-01-06 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	419
483647	1216	A125	CHE-XXX	1972-01-06 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1972-01-06 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	420
483880	1216	A168	CHE-XXX	1971-07-14 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-01-06 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	421
483880	1216	A168	CHE-XXX	1971-07-14 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-01-06 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	422
484078	1216	DEM|SEX:f	CHE-XXX	1971-07-14 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-01-06 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	423
483648	1217	A125	CHE-XXX	1973-08-16 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-08-16 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	424
483648	1217	A125	CHE-XXX	1973-08-16 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1973-08-16 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	425
483881	1217	A168	CHE-XXX	1971-06-17 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-08-16 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	426
483881	1217	A168	CHE-XXX	1971-06-17 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1973-08-16 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	427
484079	1217	DEM|SEX:f	CHE-XXX	1971-06-17 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-08-16 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	428
483649	1218	A125	CHE-XXX	1970-11-26 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1970-11-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	429
483649	1218	A125	CHE-XXX	1970-11-26 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1970-11-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	430
483882	1218	A168	CHE-XXX	1970-08-23 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1970-11-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	431
483882	1218	A168	CHE-XXX	1970-08-23 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1970-11-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	432
484080	1218	DEM|SEX:f	CHE-XXX	1970-08-23 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1970-11-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	433
483743	1219	A125	CHE-XXX	1971-08-06 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-08-06 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	434
483743	1219	A125	CHE-XXX	1971-08-06 01:00:00	126:0	1	\N	\N	\N	\N	\N	\N	1971-08-06 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	435
483883	1219	A168	CHE-XXX	1971-01-22 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-08-06 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	436
483883	1219	A168	CHE-XXX	1971-01-22 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1971-08-06 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	437
484081	1219	DEM|SEX:f	CHE-XXX	1971-01-22 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-08-06 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	438
483650	1220	A125	CHE-XXX	1970-12-31 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1970-12-31 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	439
483650	1220	A125	CHE-XXX	1970-12-31 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1970-12-31 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	440
483884	1220	A168	CHE-XXX	1970-07-17 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1970-12-31 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	441
483884	1220	A168	CHE-XXX	1970-07-17 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1970-12-31 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	442
484197	1220	DEM|SEX:m	CHE-XXX	1970-07-17 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1970-12-31 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	443
483744	1221	A125	CHE-XXX	1973-04-20 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-04-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	444
483744	1221	A125	CHE-XXX	1973-04-20 01:00:00	126:0	1	\N	\N	\N	\N	\N	\N	1973-04-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	445
483885	1221	A168	CHE-XXX	1971-02-04 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-04-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	446
483885	1221	A168	CHE-XXX	1971-02-04 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1973-04-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	447
484082	1221	DEM|SEX:f	CHE-XXX	1971-02-04 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-04-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	448
483651	1222	A125	CHE-XXX	1973-06-26 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-06-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	449
483651	1222	A125	CHE-XXX	1973-06-26 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1973-06-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	450
483886	1222	A168	CHE-XXX	1972-09-15 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-06-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	451
483886	1222	A168	CHE-XXX	1972-09-15 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1973-06-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	452
484083	1222	DEM|SEX:f	CHE-XXX	1972-09-15 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-06-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	453
483652	1223	A125	CHE-XXX	1973-03-22 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-03-22 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	454
483652	1223	A125	CHE-XXX	1973-03-22 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1973-03-22 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	455
483887	1223	A168	CHE-XXX	1971-06-20 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-03-22 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	456
483887	1223	A168	CHE-XXX	1971-06-20 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1973-03-22 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	457
484198	1223	DEM|SEX:m	CHE-XXX	1971-06-20 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-03-22 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	458
483653	1224	A125	CHE-XXX	1972-12-15 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-12-15 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	459
483653	1224	A125	CHE-XXX	1972-12-15 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1972-12-15 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	460
483888	1224	A168	CHE-XXX	1972-07-21 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-12-15 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	461
483888	1224	A168	CHE-XXX	1972-07-21 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-12-15 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	462
484084	1224	DEM|SEX:f	CHE-XXX	1972-07-21 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-12-15 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	463
483745	1225	A125	CHE-XXX	1973-02-03 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-02-03 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	464
483745	1225	A125	CHE-XXX	1973-02-03 01:00:00	126:0	1	\N	\N	\N	\N	\N	\N	1973-02-03 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	465
483889	1225	A168	CHE-XXX	1971-01-25 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-02-03 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	466
483889	1225	A168	CHE-XXX	1971-01-25 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1973-02-03 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	467
484199	1225	DEM|SEX:m	CHE-XXX	1971-01-25 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-02-03 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	468
483654	1226	A125	CHE-XXX	1971-03-18 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-03-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	469
483654	1226	A125	CHE-XXX	1971-03-18 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1971-03-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	470
483890	1226	A168	CHE-XXX	1970-10-06 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-03-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	471
483890	1226	A168	CHE-XXX	1970-10-06 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1971-03-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	472
484085	1226	DEM|SEX:f	CHE-XXX	1970-10-06 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-03-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	473
483655	1227	A125	CHE-XXX	1972-09-10 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-09-10 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	474
483655	1227	A125	CHE-XXX	1972-09-10 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1972-09-10 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	475
483891	1227	A168	CHE-XXX	1970-11-25 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-09-10 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	476
483891	1227	A168	CHE-XXX	1970-11-25 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-09-10 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	477
484086	1227	DEM|SEX:f	CHE-XXX	1970-11-25 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-09-10 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	478
483656	1228	A125	CHE-XXX	1972-06-13 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-06-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	479
483656	1228	A125	CHE-XXX	1972-06-13 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1972-06-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	480
483892	1228	A168	CHE-XXX	1971-10-18 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-06-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	481
483892	1228	A168	CHE-XXX	1971-10-18 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-06-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	482
484087	1228	DEM|SEX:f	CHE-XXX	1971-10-18 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-06-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	483
483657	1229	A125	CHE-XXX	1971-09-21 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-09-21 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	484
483657	1229	A125	CHE-XXX	1971-09-21 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1971-09-21 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	485
483893	1229	A168	CHE-XXX	1971-06-25 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-09-21 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	486
483893	1229	A168	CHE-XXX	1971-06-25 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1971-09-21 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	487
484088	1229	DEM|SEX:f	CHE-XXX	1971-06-25 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-09-21 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	488
483658	1230	A125	CHE-XXX	1972-09-02 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-09-02 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	489
483658	1230	A125	CHE-XXX	1972-09-02 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1972-09-02 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	490
483894	1230	A168	CHE-XXX	1972-01-01 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-09-02 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	491
483894	1230	A168	CHE-XXX	1972-01-01 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-09-02 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	492
484200	1230	DEM|SEX:m	CHE-XXX	1972-01-01 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-09-02 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	493
483746	1231	A125	CHE-XXX	1972-04-28 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-04-28 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	494
483746	1231	A125	CHE-XXX	1972-04-28 01:00:00	126:0	1	\N	\N	\N	\N	\N	\N	1972-04-28 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	495
483895	1231	A168	CHE-XXX	1970-09-18 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-04-28 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	496
483895	1231	A168	CHE-XXX	1970-09-18 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-04-28 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	497
484201	1231	DEM|SEX:m	CHE-XXX	1970-09-18 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-04-28 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	498
483659	1232	A125	CHE-XXX	1971-09-28 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-09-28 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	499
483659	1232	A125	CHE-XXX	1971-09-28 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1971-09-28 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	500
483896	1232	A168	CHE-XXX	1971-08-29 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-09-28 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	501
483896	1232	A168	CHE-XXX	1971-08-29 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1971-09-28 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	502
484089	1232	DEM|SEX:f	CHE-XXX	1971-08-29 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-09-28 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	503
483660	1233	A125	CHE-XXX	1971-07-27 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-07-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	504
483660	1233	A125	CHE-XXX	1971-07-27 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1971-07-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	505
483897	1233	A168	CHE-XXX	1971-01-29 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-07-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	506
483897	1233	A168	CHE-XXX	1971-01-29 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1971-07-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	507
484090	1233	DEM|SEX:f	CHE-XXX	1971-01-29 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-07-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	508
483661	1234	A125	CHE-XXX	1973-06-21 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-06-21 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	509
483661	1234	A125	CHE-XXX	1973-06-21 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1973-06-21 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	510
483898	1234	A168	CHE-XXX	1972-08-15 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-06-21 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	511
483898	1234	A168	CHE-XXX	1972-08-15 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1973-06-21 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	512
484091	1234	DEM|SEX:f	CHE-XXX	1972-08-15 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-06-21 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	513
483662	1235	A125	CHE-XXX	1973-07-08 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-07-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	514
483662	1235	A125	CHE-XXX	1973-07-08 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1973-07-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	515
483899	1235	A168	CHE-XXX	1972-03-18 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-07-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	516
483899	1235	A168	CHE-XXX	1972-03-18 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1973-07-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	517
484092	1235	DEM|SEX:f	CHE-XXX	1972-03-18 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-07-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	518
483663	1236	A125	CHE-XXX	1970-11-17 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1970-11-17 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	519
483663	1236	A125	CHE-XXX	1970-11-17 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1970-11-17 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	520
483900	1236	A168	CHE-XXX	1970-06-04 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1970-11-17 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	521
483900	1236	A168	CHE-XXX	1970-06-04 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1970-11-17 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	522
484202	1236	DEM|SEX:m	CHE-XXX	1970-06-04 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1970-11-17 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	523
483747	1237	A125	CHE-XXX	1972-08-05 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-08-05 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	524
483747	1237	A125	CHE-XXX	1972-08-05 01:00:00	126:0	1	\N	\N	\N	\N	\N	\N	1972-08-05 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	525
483901	1237	A168	CHE-XXX	1971-01-24 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-08-05 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	526
483901	1237	A168	CHE-XXX	1971-01-24 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-08-05 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	527
484203	1237	DEM|SEX:m	CHE-XXX	1971-01-24 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-08-05 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	528
483664	1238	A125	CHE-XXX	1973-03-03 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-03-03 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	529
483664	1238	A125	CHE-XXX	1973-03-03 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1973-03-03 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	530
483902	1238	A168	CHE-XXX	1971-12-09 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-03-03 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	531
483902	1238	A168	CHE-XXX	1971-12-09 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1973-03-03 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	532
484204	1238	DEM|SEX:m	CHE-XXX	1971-12-09 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-03-03 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	533
483665	1239	A125	CHE-XXX	1971-03-20 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-03-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	534
483665	1239	A125	CHE-XXX	1971-03-20 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1971-03-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	535
483903	1239	A168	CHE-XXX	1970-03-21 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-03-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	536
483903	1239	A168	CHE-XXX	1970-03-21 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1971-03-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	537
484093	1239	DEM|SEX:f	CHE-XXX	1970-03-21 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-03-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	538
483666	1240	A125	CHE-XXX	1971-08-25 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-08-25 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	539
483666	1240	A125	CHE-XXX	1971-08-25 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1971-08-25 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	540
483904	1240	A168	CHE-XXX	1971-05-10 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-08-25 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	541
483904	1240	A168	CHE-XXX	1971-05-10 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1971-08-25 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	542
484094	1240	DEM|SEX:f	CHE-XXX	1971-05-10 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-08-25 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	543
483667	1241	A125	CHE-XXX	1971-02-28 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-02-28 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	544
483667	1241	A125	CHE-XXX	1971-02-28 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1971-02-28 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	545
483905	1241	A168	CHE-XXX	1970-09-04 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-02-28 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	546
483905	1241	A168	CHE-XXX	1970-09-04 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1971-02-28 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	547
484095	1241	DEM|SEX:f	CHE-XXX	1970-09-04 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-02-28 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	548
483668	1242	A125	CHE-XXX	1970-12-23 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1970-12-23 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	549
483668	1242	A125	CHE-XXX	1970-12-23 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1970-12-23 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	550
483906	1242	A168	CHE-XXX	1970-07-20 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1970-12-23 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	551
483906	1242	A168	CHE-XXX	1970-07-20 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1970-12-23 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	552
484096	1242	DEM|SEX:f	CHE-XXX	1970-07-20 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1970-12-23 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	553
483748	1243	A125	CHE-XXX	1973-01-08 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-01-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	554
483748	1243	A125	CHE-XXX	1973-01-08 01:00:00	126:0	1	\N	\N	\N	\N	\N	\N	1973-01-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	555
483907	1243	A168	CHE-XXX	1971-07-29 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-01-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	556
483907	1243	A168	CHE-XXX	1971-07-29 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1973-01-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	557
484205	1243	DEM|SEX:m	CHE-XXX	1971-07-29 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-01-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	558
483669	1244	A125	CHE-XXX	1971-03-23 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-03-23 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	559
483669	1244	A125	CHE-XXX	1971-03-23 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1971-03-23 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	560
483908	1244	A168	CHE-XXX	1971-03-12 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-03-23 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	561
483908	1244	A168	CHE-XXX	1971-03-12 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1971-03-23 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	562
484097	1244	DEM|SEX:f	CHE-XXX	1971-03-12 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-03-23 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	563
483670	1245	A125	CHE-XXX	1971-09-13 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-09-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	564
483670	1245	A125	CHE-XXX	1971-09-13 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1971-09-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	565
483909	1245	A168	CHE-XXX	1970-07-11 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-09-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	566
483909	1245	A168	CHE-XXX	1970-07-11 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1971-09-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	567
484098	1245	DEM|SEX:f	CHE-XXX	1970-07-11 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-09-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	568
483671	1246	A125	CHE-XXX	1972-08-02 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-08-02 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	569
483671	1246	A125	CHE-XXX	1972-08-02 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1972-08-02 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	570
483910	1246	A168	CHE-XXX	1971-08-17 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-08-02 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	571
483910	1246	A168	CHE-XXX	1971-08-17 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-08-02 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	572
484206	1246	DEM|SEX:m	CHE-XXX	1971-08-17 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-08-02 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	573
483672	1247	A125	CHE-XXX	1972-04-13 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-04-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	574
483672	1247	A125	CHE-XXX	1972-04-13 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1972-04-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	575
483911	1247	A168	CHE-XXX	1972-03-29 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-04-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	576
483911	1247	A168	CHE-XXX	1972-03-29 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-04-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	577
484099	1247	DEM|SEX:f	CHE-XXX	1972-03-29 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-04-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	578
483673	1248	A125	CHE-XXX	1971-02-12 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-02-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	579
483673	1248	A125	CHE-XXX	1971-02-12 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1971-02-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	580
483912	1248	A168	CHE-XXX	1970-08-15 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-02-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	581
483912	1248	A168	CHE-XXX	1970-08-15 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1971-02-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	582
484100	1248	DEM|SEX:f	CHE-XXX	1970-08-15 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-02-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	583
483674	1249	A125	CHE-XXX	1972-12-06 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-12-06 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	584
483674	1249	A125	CHE-XXX	1972-12-06 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1972-12-06 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	585
483913	1249	A168	CHE-XXX	1972-02-27 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-12-06 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	586
483913	1249	A168	CHE-XXX	1972-02-27 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-12-06 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	587
484101	1249	DEM|SEX:f	CHE-XXX	1972-02-27 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-12-06 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	588
483675	1250	A125	CHE-XXX	1970-11-09 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1970-11-09 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	589
483675	1250	A125	CHE-XXX	1970-11-09 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1970-11-09 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	590
483914	1250	A168	CHE-XXX	1970-04-22 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1970-11-09 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	591
483914	1250	A168	CHE-XXX	1970-04-22 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1970-11-09 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	592
484207	1250	DEM|SEX:m	CHE-XXX	1970-04-22 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1970-11-09 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	593
483676	1251	A125	CHE-XXX	1971-07-02 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-07-02 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	594
483676	1251	A125	CHE-XXX	1971-07-02 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1971-07-02 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	595
483915	1251	A168	CHE-XXX	1970-01-24 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-07-02 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	596
483915	1251	A168	CHE-XXX	1970-01-24 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1971-07-02 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	597
484208	1251	DEM|SEX:m	CHE-XXX	1970-01-24 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-07-02 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	598
483677	1252	A125	CHE-XXX	1972-05-17 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-05-17 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	599
483677	1252	A125	CHE-XXX	1972-05-17 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1972-05-17 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	600
483916	1252	A168	CHE-XXX	1972-05-04 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-05-17 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	601
483916	1252	A168	CHE-XXX	1972-05-04 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-05-17 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	602
484102	1252	DEM|SEX:f	CHE-XXX	1972-05-04 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-05-17 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	603
483678	1253	A125	CHE-XXX	1971-04-25 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-04-25 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	604
483678	1253	A125	CHE-XXX	1971-04-25 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1971-04-25 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	605
483917	1253	A168	CHE-XXX	1970-09-25 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-04-25 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	606
483917	1253	A168	CHE-XXX	1970-09-25 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1971-04-25 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	607
484103	1253	DEM|SEX:f	CHE-XXX	1970-09-25 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-04-25 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	608
483679	1254	A125	CHE-XXX	1971-07-22 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-07-22 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	609
483679	1254	A125	CHE-XXX	1971-07-22 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1971-07-22 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	610
483918	1254	A168	CHE-XXX	1970-02-13 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-07-22 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	611
483918	1254	A168	CHE-XXX	1970-02-13 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1971-07-22 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	612
484104	1254	DEM|SEX:f	CHE-XXX	1970-02-13 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-07-22 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	613
483680	1255	A125	CHE-XXX	1972-02-26 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-02-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	614
483680	1255	A125	CHE-XXX	1972-02-26 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1972-02-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	615
483919	1255	A168	CHE-XXX	1971-05-14 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-02-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	616
483919	1255	A168	CHE-XXX	1971-05-14 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-02-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	617
484105	1255	DEM|SEX:f	CHE-XXX	1971-05-14 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-02-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	618
483681	1256	A125	CHE-XXX	1972-02-03 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-02-03 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	619
483681	1256	A125	CHE-XXX	1972-02-03 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1972-02-03 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	620
483920	1256	A168	CHE-XXX	1971-02-05 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-02-03 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	621
483920	1256	A168	CHE-XXX	1971-02-05 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-02-03 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	622
484106	1256	DEM|SEX:f	CHE-XXX	1971-02-05 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-02-03 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	623
483682	1257	A125	CHE-XXX	1973-08-27 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-08-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	624
483682	1257	A125	CHE-XXX	1973-08-27 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1973-08-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	625
483921	1257	A168	CHE-XXX	1972-06-11 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-08-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	626
483921	1257	A168	CHE-XXX	1972-06-11 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1973-08-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	627
484107	1257	DEM|SEX:f	CHE-XXX	1972-06-11 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-08-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	628
483683	1258	A125	CHE-XXX	1972-04-16 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-04-16 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	629
483683	1258	A125	CHE-XXX	1972-04-16 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1972-04-16 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	630
483922	1258	A168	CHE-XXX	1971-09-30 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-04-16 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	631
483922	1258	A168	CHE-XXX	1971-09-30 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-04-16 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	632
484209	1258	DEM|SEX:m	CHE-XXX	1971-09-30 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-04-16 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	633
483684	1259	A125	CHE-XXX	1972-04-08 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-04-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	634
483684	1259	A125	CHE-XXX	1972-04-08 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1972-04-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	635
483923	1259	A168	CHE-XXX	1970-10-06 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-04-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	636
483923	1259	A168	CHE-XXX	1970-10-06 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-04-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	637
484210	1259	DEM|SEX:m	CHE-XXX	1970-10-06 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-04-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	638
483685	1260	A125	CHE-XXX	1971-11-23 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-11-23 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	639
483685	1260	A125	CHE-XXX	1971-11-23 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1971-11-23 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	640
483924	1260	A168	CHE-XXX	1971-09-30 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-11-23 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	641
483924	1260	A168	CHE-XXX	1971-09-30 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1971-11-23 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	642
484108	1260	DEM|SEX:f	CHE-XXX	1971-09-30 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-11-23 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	643
483686	1261	A125	CHE-XXX	1971-11-18 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-11-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	644
483686	1261	A125	CHE-XXX	1971-11-18 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1971-11-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	645
483925	1261	A168	CHE-XXX	1970-05-09 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-11-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	646
483925	1261	A168	CHE-XXX	1970-05-09 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1971-11-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	647
484109	1261	DEM|SEX:f	CHE-XXX	1970-05-09 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-11-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	648
483687	1262	A125	CHE-XXX	1971-07-25 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-07-25 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	649
483687	1262	A125	CHE-XXX	1971-07-25 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1971-07-25 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	650
483926	1262	A168	CHE-XXX	1970-12-30 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-07-25 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	651
483926	1262	A168	CHE-XXX	1970-12-30 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1971-07-25 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	652
484110	1262	DEM|SEX:f	CHE-XXX	1970-12-30 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-07-25 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	653
483688	1263	A125	CHE-XXX	1970-12-03 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1970-12-03 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	654
483688	1263	A125	CHE-XXX	1970-12-03 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1970-12-03 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	655
483927	1263	A168	CHE-XXX	1970-09-02 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1970-12-03 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	656
483927	1263	A168	CHE-XXX	1970-09-02 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1970-12-03 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	657
484111	1263	DEM|SEX:f	CHE-XXX	1970-09-02 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1970-12-03 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	658
483689	1264	A125	CHE-XXX	1972-06-29 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-06-29 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	659
483689	1264	A125	CHE-XXX	1972-06-29 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1972-06-29 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	660
483928	1264	A168	CHE-XXX	1972-04-30 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-06-29 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	661
483928	1264	A168	CHE-XXX	1972-04-30 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-06-29 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	662
484112	1264	DEM|SEX:f	CHE-XXX	1972-04-30 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-06-29 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	663
483749	1265	A125	CHE-XXX	1973-04-30 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-04-30 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	664
483749	1265	A125	CHE-XXX	1973-04-30 01:00:00	126:0	1	\N	\N	\N	\N	\N	\N	1973-04-30 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	665
483929	1265	A168	CHE-XXX	1971-10-27 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-04-30 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	666
483929	1265	A168	CHE-XXX	1971-10-27 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1973-04-30 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	667
484211	1265	DEM|SEX:m	CHE-XXX	1971-10-27 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-04-30 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	668
483750	1266	A125	CHE-XXX	1974-02-12 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1974-02-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	669
483750	1266	A125	CHE-XXX	1974-02-12 01:00:00	126:0	1	\N	\N	\N	\N	\N	\N	1974-02-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	670
483930	1266	A168	CHE-XXX	1972-08-18 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1974-02-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	671
483930	1266	A168	CHE-XXX	1972-08-18 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1974-02-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	672
484212	1266	DEM|SEX:m	CHE-XXX	1972-08-18 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1974-02-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	673
483690	1267	A125	CHE-XXX	1973-06-01 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-06-01 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	674
483690	1267	A125	CHE-XXX	1973-06-01 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1973-06-01 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	675
483931	1267	A168	CHE-XXX	1972-08-12 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-06-01 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	676
483931	1267	A168	CHE-XXX	1972-08-12 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1973-06-01 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	677
484213	1267	DEM|SEX:m	CHE-XXX	1972-08-12 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-06-01 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	678
483691	1268	A125	CHE-XXX	1971-04-26 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-04-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	679
483691	1268	A125	CHE-XXX	1971-04-26 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1971-04-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	680
483932	1268	A168	CHE-XXX	1970-10-06 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-04-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	681
483932	1268	A168	CHE-XXX	1970-10-06 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1971-04-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	682
484113	1268	DEM|SEX:f	CHE-XXX	1970-10-06 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-04-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	683
483692	1269	A125	CHE-XXX	1971-11-15 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-11-15 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	684
483692	1269	A125	CHE-XXX	1971-11-15 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1971-11-15 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	685
483933	1269	A168	CHE-XXX	1970-11-27 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-11-15 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	686
483933	1269	A168	CHE-XXX	1970-11-27 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1971-11-15 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	687
484114	1269	DEM|SEX:f	CHE-XXX	1970-11-27 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-11-15 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	688
483751	1270	A125	CHE-XXX	1971-12-29 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-12-29 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	689
483751	1270	A125	CHE-XXX	1971-12-29 01:00:00	126:0	1	\N	\N	\N	\N	\N	\N	1971-12-29 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	690
483934	1270	A168	CHE-XXX	1970-08-05 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-12-29 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	691
483934	1270	A168	CHE-XXX	1970-08-05 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1971-12-29 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	692
484214	1270	DEM|SEX:m	CHE-XXX	1970-08-05 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-12-29 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	693
483693	1271	A125	CHE-XXX	1972-09-18 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-09-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	694
483693	1271	A125	CHE-XXX	1972-09-18 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1972-09-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	695
483935	1271	A168	CHE-XXX	1971-12-26 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-09-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	696
483935	1271	A168	CHE-XXX	1971-12-26 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-09-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	697
484115	1271	DEM|SEX:f	CHE-XXX	1971-12-26 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-09-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	698
483752	1272	A125	CHE-XXX	1972-05-09 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-05-09 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	699
483752	1272	A125	CHE-XXX	1972-05-09 01:00:00	126:0	1	\N	\N	\N	\N	\N	\N	1972-05-09 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	700
483936	1272	A168	CHE-XXX	1970-12-15 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-05-09 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	701
483936	1272	A168	CHE-XXX	1970-12-15 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-05-09 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	702
484215	1272	DEM|SEX:m	CHE-XXX	1970-12-15 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-05-09 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	703
483694	1273	A125	CHE-XXX	1973-05-27 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-05-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	704
483694	1273	A125	CHE-XXX	1973-05-27 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1973-05-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	705
483937	1273	A168	CHE-XXX	1972-05-21 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-05-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	706
483937	1273	A168	CHE-XXX	1972-05-21 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1973-05-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	707
484216	1273	DEM|SEX:m	CHE-XXX	1972-05-21 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-05-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	708
483695	1274	A125	CHE-XXX	1971-12-01 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-12-01 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	709
483695	1274	A125	CHE-XXX	1971-12-01 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1971-12-01 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	710
483938	1274	A168	CHE-XXX	1970-11-09 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-12-01 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	711
483938	1274	A168	CHE-XXX	1970-11-09 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1971-12-01 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	712
484116	1274	DEM|SEX:f	CHE-XXX	1970-11-09 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-12-01 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	713
483696	1275	A125	CHE-XXX	1973-01-11 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-01-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	714
483696	1275	A125	CHE-XXX	1973-01-11 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1973-01-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	715
483939	1275	A168	CHE-XXX	1971-10-12 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-01-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	716
483939	1275	A168	CHE-XXX	1971-10-12 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1973-01-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	717
484117	1275	DEM|SEX:f	CHE-XXX	1971-10-12 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-01-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	718
483697	1276	A125	CHE-XXX	1971-02-20 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-02-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	719
483697	1276	A125	CHE-XXX	1971-02-20 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1971-02-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	720
483940	1276	A168	CHE-XXX	1970-03-20 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-02-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	721
483940	1276	A168	CHE-XXX	1970-03-20 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1971-02-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	722
484118	1276	DEM|SEX:f	CHE-XXX	1970-03-20 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-02-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	723
483698	1277	A125	CHE-XXX	1973-01-05 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-01-05 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	724
483698	1277	A125	CHE-XXX	1973-01-05 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1973-01-05 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	725
483941	1277	A168	CHE-XXX	1972-06-18 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-01-05 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	726
483941	1277	A168	CHE-XXX	1972-06-18 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1973-01-05 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	727
484217	1277	DEM|SEX:m	CHE-XXX	1972-06-18 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-01-05 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	728
483753	1278	A125	CHE-XXX	1971-04-06 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-04-06 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	729
483753	1278	A125	CHE-XXX	1971-04-06 01:00:00	126:0	1	\N	\N	\N	\N	\N	\N	1971-04-06 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	730
483942	1278	A168	CHE-XXX	1970-02-26 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-04-06 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	731
483942	1278	A168	CHE-XXX	1970-02-26 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1971-04-06 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	732
484119	1278	DEM|SEX:f	CHE-XXX	1970-02-26 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-04-06 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	733
483699	1279	A125	CHE-XXX	1970-12-18 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1970-12-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	734
483699	1279	A125	CHE-XXX	1970-12-18 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1970-12-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	735
483943	1279	A168	CHE-XXX	1970-05-10 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1970-12-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	736
483943	1279	A168	CHE-XXX	1970-05-10 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1970-12-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	737
484120	1279	DEM|SEX:f	CHE-XXX	1970-05-10 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1970-12-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	738
483700	1280	A125	CHE-XXX	1971-11-24 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-11-24 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	739
483700	1280	A125	CHE-XXX	1971-11-24 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1971-11-24 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	740
483944	1280	A168	CHE-XXX	1971-09-23 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-11-24 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	741
483944	1280	A168	CHE-XXX	1971-09-23 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1971-11-24 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	742
484218	1280	DEM|SEX:m	CHE-XXX	1971-09-23 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-11-24 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	743
483754	1281	A125	CHE-XXX	1973-12-09 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-12-09 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	744
483754	1281	A125	CHE-XXX	1973-12-09 01:00:00	126:0	1	\N	\N	\N	\N	\N	\N	1973-12-09 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	745
483945	1281	A168	CHE-XXX	1972-09-07 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-12-09 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	746
483945	1281	A168	CHE-XXX	1972-09-07 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1973-12-09 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	747
484121	1281	DEM|SEX:f	CHE-XXX	1972-09-07 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-12-09 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	748
483755	1282	A125	CHE-XXX	1973-08-29 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-08-29 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	749
483755	1282	A125	CHE-XXX	1973-08-29 01:00:00	126:0	1	\N	\N	\N	\N	\N	\N	1973-08-29 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	750
483946	1282	A168	CHE-XXX	1972-09-07 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-08-29 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	751
483946	1282	A168	CHE-XXX	1972-09-07 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1973-08-29 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	752
484219	1282	DEM|SEX:m	CHE-XXX	1972-09-07 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-08-29 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	753
483701	1283	A125	CHE-XXX	1972-02-12 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-02-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	754
483701	1283	A125	CHE-XXX	1972-02-12 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1972-02-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	755
483947	1283	A168	CHE-XXX	1971-02-24 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-02-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	756
483947	1283	A168	CHE-XXX	1971-02-24 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-02-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	757
484122	1283	DEM|SEX:f	CHE-XXX	1971-02-24 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-02-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	758
483702	1284	A125	CHE-XXX	1971-12-27 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-12-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	759
483702	1284	A125	CHE-XXX	1971-12-27 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1971-12-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	760
483948	1284	A168	CHE-XXX	1971-07-17 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-12-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	761
483948	1284	A168	CHE-XXX	1971-07-17 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1971-12-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	762
484123	1284	DEM|SEX:f	CHE-XXX	1971-07-17 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-12-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	763
483703	1285	A125	CHE-XXX	1970-04-11 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1970-04-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	764
483703	1285	A125	CHE-XXX	1970-04-11 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1970-04-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	765
483949	1285	A168	CHE-XXX	1970-03-11 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1970-04-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	766
483949	1285	A168	CHE-XXX	1970-03-11 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1970-04-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	767
484124	1285	DEM|SEX:f	CHE-XXX	1970-03-11 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1970-04-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	768
483704	1286	A125	CHE-XXX	1972-09-05 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-09-05 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	769
483704	1286	A125	CHE-XXX	1972-09-05 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1972-09-05 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	770
483950	1286	A168	CHE-XXX	1971-10-01 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-09-05 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	771
483950	1286	A168	CHE-XXX	1971-10-01 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-09-05 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	772
484220	1286	DEM|SEX:m	CHE-XXX	1971-10-01 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-09-05 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	773
483705	1287	A125	CHE-XXX	1973-04-17 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-04-17 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	774
483705	1287	A125	CHE-XXX	1973-04-17 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1973-04-17 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	775
483951	1287	A168	CHE-XXX	1972-08-31 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-04-17 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	776
483951	1287	A168	CHE-XXX	1972-08-31 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1973-04-17 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	777
484125	1287	DEM|SEX:f	CHE-XXX	1972-08-31 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-04-17 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	778
483756	1288	A125	CHE-XXX	1972-07-08 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-07-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	779
483756	1288	A125	CHE-XXX	1972-07-08 01:00:00	126:0	1	\N	\N	\N	\N	\N	\N	1972-07-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	780
483952	1288	A168	CHE-XXX	1971-04-21 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-07-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	781
483952	1288	A168	CHE-XXX	1971-04-21 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-07-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	782
484126	1288	DEM|SEX:f	CHE-XXX	1971-04-21 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-07-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	783
483757	1289	A125	CHE-XXX	1972-10-11 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-10-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	784
483757	1289	A125	CHE-XXX	1972-10-11 01:00:00	126:0	1	\N	\N	\N	\N	\N	\N	1972-10-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	785
483953	1289	A168	CHE-XXX	1971-12-01 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-10-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	786
483953	1289	A168	CHE-XXX	1971-12-01 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-10-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	787
484221	1289	DEM|SEX:m	CHE-XXX	1971-12-01 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-10-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	788
483706	1290	A125	CHE-XXX	1971-03-09 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-03-09 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	789
483706	1290	A125	CHE-XXX	1971-03-09 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1971-03-09 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	790
483954	1290	A168	CHE-XXX	1970-09-08 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-03-09 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	791
483954	1290	A168	CHE-XXX	1970-09-08 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1971-03-09 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	792
484222	1290	DEM|SEX:m	CHE-XXX	1970-09-08 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-03-09 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	793
483707	1291	A125	CHE-XXX	1972-01-06 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-01-06 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	794
483707	1291	A125	CHE-XXX	1972-01-06 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1972-01-06 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	795
483955	1291	A168	CHE-XXX	1971-08-03 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-01-06 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	796
483955	1291	A168	CHE-XXX	1971-08-03 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-01-06 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	797
484127	1291	DEM|SEX:f	CHE-XXX	1971-08-03 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-01-06 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	798
483708	1292	A125	CHE-XXX	1972-09-19 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-09-19 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	799
483708	1292	A125	CHE-XXX	1972-09-19 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1972-09-19 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	800
483956	1292	A168	CHE-XXX	1971-10-26 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-09-19 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	801
483956	1292	A168	CHE-XXX	1971-10-26 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-09-19 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	802
484128	1292	DEM|SEX:f	CHE-XXX	1971-10-26 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-09-19 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	803
483758	1293	A125	CHE-XXX	1971-12-11 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-12-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	804
483758	1293	A125	CHE-XXX	1971-12-11 01:00:00	126:0	1	\N	\N	\N	\N	\N	\N	1971-12-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	805
483957	1293	A168	CHE-XXX	1970-12-12 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-12-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	806
483957	1293	A168	CHE-XXX	1970-12-12 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1971-12-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	807
484223	1293	DEM|SEX:m	CHE-XXX	1970-12-12 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-12-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	808
483709	1294	A125	CHE-XXX	1971-09-08 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-09-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	809
483709	1294	A125	CHE-XXX	1971-09-08 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1971-09-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	810
483958	1294	A168	CHE-XXX	1970-11-21 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-09-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	811
483958	1294	A168	CHE-XXX	1970-11-21 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1971-09-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	812
484129	1294	DEM|SEX:f	CHE-XXX	1970-11-21 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-09-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	813
483710	1295	A125	CHE-XXX	1970-08-19 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1970-08-19 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	814
483710	1295	A125	CHE-XXX	1970-08-19 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1970-08-19 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	815
483959	1295	A168	CHE-XXX	1970-02-21 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1970-08-19 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	816
483959	1295	A168	CHE-XXX	1970-02-21 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1970-08-19 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	817
484130	1295	DEM|SEX:f	CHE-XXX	1970-02-21 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1970-08-19 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	818
483759	1296	A125	CHE-XXX	1972-02-24 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-02-24 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	819
483759	1296	A125	CHE-XXX	1972-02-24 01:00:00	126:0	1	\N	\N	\N	\N	\N	\N	1972-02-24 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	820
483960	1296	A168	CHE-XXX	1971-02-13 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-02-24 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	821
483960	1296	A168	CHE-XXX	1971-02-13 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-02-24 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	822
484224	1296	DEM|SEX:m	CHE-XXX	1971-02-13 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-02-24 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	823
483760	1297	A125	CHE-XXX	1972-12-11 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-12-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	824
483760	1297	A125	CHE-XXX	1972-12-11 01:00:00	126:0	1	\N	\N	\N	\N	\N	\N	1972-12-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	825
483961	1297	A168	CHE-XXX	1971-11-23 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-12-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	826
483961	1297	A168	CHE-XXX	1971-11-23 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-12-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	827
484225	1297	DEM|SEX:m	CHE-XXX	1971-11-23 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-12-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	828
483711	1298	A125	CHE-XXX	1973-04-16 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-04-16 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	829
483711	1298	A125	CHE-XXX	1973-04-16 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1973-04-16 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	830
483962	1298	A168	CHE-XXX	1972-07-22 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-04-16 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	831
483962	1298	A168	CHE-XXX	1972-07-22 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1973-04-16 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	832
484226	1298	DEM|SEX:m	CHE-XXX	1972-07-22 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-04-16 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	833
483761	1299	A125	CHE-XXX	1972-04-20 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-04-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	834
483761	1299	A125	CHE-XXX	1972-04-20 01:00:00	126:0	1	\N	\N	\N	\N	\N	\N	1972-04-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	835
483963	1299	A168	CHE-XXX	1971-07-03 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-04-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	836
483963	1299	A168	CHE-XXX	1971-07-03 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-04-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	837
484131	1299	DEM|SEX:f	CHE-XXX	1971-07-03 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-04-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	838
483712	1300	A125	CHE-XXX	1971-02-09 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-02-09 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	839
483712	1300	A125	CHE-XXX	1971-02-09 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1971-02-09 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	840
483964	1300	A168	CHE-XXX	1970-09-20 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-02-09 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	841
483964	1300	A168	CHE-XXX	1970-09-20 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1971-02-09 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	842
484132	1300	DEM|SEX:f	CHE-XXX	1970-09-20 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-02-09 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	843
483762	1301	A125	CHE-XXX	1972-05-03 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-05-03 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	844
483762	1301	A125	CHE-XXX	1972-05-03 01:00:00	126:0	1	\N	\N	\N	\N	\N	\N	1972-05-03 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	845
483965	1301	A168	CHE-XXX	1971-03-17 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-05-03 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	846
483965	1301	A168	CHE-XXX	1971-03-17 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-05-03 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	847
484133	1301	DEM|SEX:f	CHE-XXX	1971-03-17 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-05-03 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	848
483763	1302	A125	CHE-XXX	1972-12-01 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-12-01 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	849
483763	1302	A125	CHE-XXX	1972-12-01 01:00:00	126:0	1	\N	\N	\N	\N	\N	\N	1972-12-01 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	850
483966	1302	A168	CHE-XXX	1972-03-10 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-12-01 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	851
483966	1302	A168	CHE-XXX	1972-03-10 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-12-01 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	852
484227	1302	DEM|SEX:m	CHE-XXX	1972-03-10 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-12-01 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	853
483713	1303	A125	CHE-XXX	1972-02-20 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-02-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	854
483713	1303	A125	CHE-XXX	1972-02-20 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1972-02-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	855
483967	1303	A168	CHE-XXX	1971-08-10 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-02-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	856
483967	1303	A168	CHE-XXX	1971-08-10 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-02-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	857
484228	1303	DEM|SEX:m	CHE-XXX	1971-08-10 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-02-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	858
483714	1304	A125	CHE-XXX	1973-01-23 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-01-23 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	859
483714	1304	A125	CHE-XXX	1973-01-23 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1973-01-23 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	860
483968	1304	A168	CHE-XXX	1972-03-09 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-01-23 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	861
483968	1304	A168	CHE-XXX	1972-03-09 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1973-01-23 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	862
484134	1304	DEM|SEX:f	CHE-XXX	1972-03-09 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-01-23 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	863
483715	1305	A125	CHE-XXX	1972-04-10 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-04-10 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	864
483715	1305	A125	CHE-XXX	1972-04-10 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1972-04-10 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	865
483969	1305	A168	CHE-XXX	1971-10-12 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-04-10 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	866
483969	1305	A168	CHE-XXX	1971-10-12 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-04-10 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	867
484135	1305	DEM|SEX:f	CHE-XXX	1971-10-12 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-04-10 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	868
483716	1306	A125	CHE-XXX	1971-01-13 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-01-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	869
483716	1306	A125	CHE-XXX	1971-01-13 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1971-01-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	870
483970	1306	A168	CHE-XXX	1970-04-03 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-01-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	871
483970	1306	A168	CHE-XXX	1970-04-03 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1971-01-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	872
484136	1306	DEM|SEX:f	CHE-XXX	1970-04-03 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-01-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	873
483764	1307	A125	CHE-XXX	1971-10-15 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-10-15 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	874
483764	1307	A125	CHE-XXX	1971-10-15 01:00:00	126:0	1	\N	\N	\N	\N	\N	\N	1971-10-15 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	875
483971	1307	A168	CHE-XXX	1970-12-18 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-10-15 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	876
483971	1307	A168	CHE-XXX	1970-12-18 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1971-10-15 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	877
484137	1307	DEM|SEX:f	CHE-XXX	1970-12-18 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-10-15 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	878
483717	1308	A125	CHE-XXX	1971-09-28 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-09-28 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	879
483717	1308	A125	CHE-XXX	1971-09-28 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1971-09-28 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	880
483972	1308	A168	CHE-XXX	1970-10-15 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-09-28 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	881
483972	1308	A168	CHE-XXX	1970-10-15 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1971-09-28 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	882
484229	1308	DEM|SEX:m	CHE-XXX	1970-10-15 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-09-28 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	883
483718	1309	A125	CHE-XXX	1972-07-22 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-07-22 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	884
483718	1309	A125	CHE-XXX	1972-07-22 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1972-07-22 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	885
483973	1309	A168	CHE-XXX	1972-01-07 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-07-22 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	886
483973	1309	A168	CHE-XXX	1972-01-07 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-07-22 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	887
484138	1309	DEM|SEX:f	CHE-XXX	1972-01-07 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-07-22 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	888
483765	1310	A125	CHE-XXX	1971-04-17 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-04-17 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	889
483765	1310	A125	CHE-XXX	1971-04-17 01:00:00	126:0	1	\N	\N	\N	\N	\N	\N	1971-04-17 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	890
483974	1310	A168	CHE-XXX	1970-03-31 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-04-17 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	891
483974	1310	A168	CHE-XXX	1970-03-31 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1971-04-17 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	892
484230	1310	DEM|SEX:m	CHE-XXX	1970-03-31 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-04-17 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	893
483766	1311	A125	CHE-XXX	1972-06-07 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-06-07 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	894
483766	1311	A125	CHE-XXX	1972-06-07 01:00:00	126:0	1	\N	\N	\N	\N	\N	\N	1972-06-07 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	895
483975	1311	A168	CHE-XXX	1971-08-09 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-06-07 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	896
483975	1311	A168	CHE-XXX	1971-08-09 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-06-07 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	897
484139	1311	DEM|SEX:f	CHE-XXX	1971-08-09 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-06-07 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	898
483767	1312	A125	CHE-XXX	1973-02-19 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-02-19 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	899
483767	1312	A125	CHE-XXX	1973-02-19 01:00:00	126:0	1	\N	\N	\N	\N	\N	\N	1973-02-19 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	900
483976	1312	A168	CHE-XXX	1972-04-29 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-02-19 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	901
483976	1312	A168	CHE-XXX	1972-04-29 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1973-02-19 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	902
484231	1312	DEM|SEX:m	CHE-XXX	1972-04-29 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-02-19 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	903
483719	1313	A125	CHE-XXX	1972-01-11 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-01-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	904
483719	1313	A125	CHE-XXX	1972-01-11 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1972-01-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	905
483977	1313	A168	CHE-XXX	1971-07-15 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-01-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	906
483977	1313	A168	CHE-XXX	1971-07-15 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-01-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	907
484140	1313	DEM|SEX:f	CHE-XXX	1971-07-15 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-01-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	908
483720	1314	A125	CHE-XXX	1971-08-19 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-08-19 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	909
483720	1314	A125	CHE-XXX	1971-08-19 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1971-08-19 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	910
483978	1314	A168	CHE-XXX	1971-02-14 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-08-19 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	911
483978	1314	A168	CHE-XXX	1971-02-14 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1971-08-19 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	912
484232	1314	DEM|SEX:m	CHE-XXX	1971-02-14 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-08-19 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	913
483721	1315	A125	CHE-XXX	1971-08-25 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-08-25 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	914
483721	1315	A125	CHE-XXX	1971-08-25 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1971-08-25 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	915
483979	1315	A168	CHE-XXX	1971-04-02 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-08-25 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	916
483979	1315	A168	CHE-XXX	1971-04-02 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1971-08-25 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	917
484233	1315	DEM|SEX:m	CHE-XXX	1971-04-02 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-08-25 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	918
483768	1316	A125	CHE-XXX	1972-07-04 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-07-04 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	919
483768	1316	A125	CHE-XXX	1972-07-04 01:00:00	126:0	1	\N	\N	\N	\N	\N	\N	1972-07-04 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	920
483980	1316	A168	CHE-XXX	1971-10-09 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-07-04 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	921
483980	1316	A168	CHE-XXX	1971-10-09 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-07-04 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	922
484234	1316	DEM|SEX:m	CHE-XXX	1971-10-09 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-07-04 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	923
483769	1317	A125	CHE-XXX	1971-01-07 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-01-07 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	924
483769	1317	A125	CHE-XXX	1971-01-07 01:00:00	126:0	1	\N	\N	\N	\N	\N	\N	1971-01-07 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	925
483981	1317	A168	CHE-XXX	1970-03-13 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-01-07 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	926
483981	1317	A168	CHE-XXX	1970-03-13 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1971-01-07 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	927
484141	1317	DEM|SEX:f	CHE-XXX	1970-03-13 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-01-07 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	928
483770	1318	A125	CHE-XXX	1972-10-26 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-10-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	929
483770	1318	A125	CHE-XXX	1972-10-26 01:00:00	126:0	1	\N	\N	\N	\N	\N	\N	1972-10-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	930
483982	1318	A168	CHE-XXX	1972-01-16 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-10-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	931
483982	1318	A168	CHE-XXX	1972-01-16 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-10-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	932
484142	1318	DEM|SEX:f	CHE-XXX	1972-01-16 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-10-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	933
483722	1319	A125	CHE-XXX	1973-01-12 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-01-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	934
483722	1319	A125	CHE-XXX	1973-01-12 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1973-01-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	935
483983	1319	A168	CHE-XXX	1972-01-28 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-01-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	936
483983	1319	A168	CHE-XXX	1972-01-28 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1973-01-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	937
484235	1319	DEM|SEX:m	CHE-XXX	1972-01-28 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-01-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	938
483771	1320	A125	CHE-XXX	1971-11-20 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-11-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	939
483771	1320	A125	CHE-XXX	1971-11-20 01:00:00	126:0	1	\N	\N	\N	\N	\N	\N	1971-11-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	940
483984	1320	A168	CHE-XXX	1971-02-21 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-11-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	941
483984	1320	A168	CHE-XXX	1971-02-21 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1971-11-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	942
484236	1320	DEM|SEX:m	CHE-XXX	1971-02-21 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-11-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	943
483772	1321	A125	CHE-XXX	1972-10-11 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-10-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	944
483772	1321	A125	CHE-XXX	1972-10-11 01:00:00	126:0	1	\N	\N	\N	\N	\N	\N	1972-10-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	945
483985	1321	A168	CHE-XXX	1971-12-24 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-10-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	946
483985	1321	A168	CHE-XXX	1971-12-24 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-10-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	947
484237	1321	DEM|SEX:m	CHE-XXX	1971-12-24 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-10-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	948
483773	1322	A125	CHE-XXX	1972-08-23 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-08-23 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	949
483773	1322	A125	CHE-XXX	1972-08-23 01:00:00	126:0	1	\N	\N	\N	\N	\N	\N	1972-08-23 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	950
483986	1322	A168	CHE-XXX	1971-09-26 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-08-23 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	951
483986	1322	A168	CHE-XXX	1971-09-26 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-08-23 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	952
484238	1322	DEM|SEX:m	CHE-XXX	1971-09-26 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-08-23 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	953
483723	1323	A125	CHE-XXX	1972-09-03 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-09-03 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	954
483723	1323	A125	CHE-XXX	1972-09-03 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1972-09-03 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	955
483987	1323	A168	CHE-XXX	1971-11-23 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-09-03 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	956
483987	1323	A168	CHE-XXX	1971-11-23 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-09-03 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	957
484239	1323	DEM|SEX:m	CHE-XXX	1971-11-23 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-09-03 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	958
483774	1324	A125	CHE-XXX	1972-06-16 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-06-16 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	959
483774	1324	A125	CHE-XXX	1972-06-16 01:00:00	126:0	1	\N	\N	\N	\N	\N	\N	1972-06-16 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	960
483988	1324	A168	CHE-XXX	1971-10-01 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-06-16 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	961
483988	1324	A168	CHE-XXX	1971-10-01 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-06-16 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	962
484143	1324	DEM|SEX:f	CHE-XXX	1971-10-01 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-06-16 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	963
483724	1325	A125	CHE-XXX	1970-06-16 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1970-06-16 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	964
483724	1325	A125	CHE-XXX	1970-06-16 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1970-06-16 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	965
483989	1325	A168	CHE-XXX	1970-02-26 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1970-06-16 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	966
483989	1325	A168	CHE-XXX	1970-02-26 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1970-06-16 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	967
484144	1325	DEM|SEX:f	CHE-XXX	1970-02-26 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1970-06-16 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	968
483725	1326	A125	CHE-XXX	1972-02-20 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-02-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	969
483725	1326	A125	CHE-XXX	1972-02-20 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1972-02-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	970
483990	1326	A168	CHE-XXX	1971-05-10 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-02-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	971
483990	1326	A168	CHE-XXX	1971-05-10 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-02-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	972
484145	1326	DEM|SEX:f	CHE-XXX	1971-05-10 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-02-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	973
483726	1327	A125	CHE-XXX	1970-11-26 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1970-11-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	974
483726	1327	A125	CHE-XXX	1970-11-26 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1970-11-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	975
483991	1327	A168	CHE-XXX	1970-03-01 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1970-11-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	976
483991	1327	A168	CHE-XXX	1970-03-01 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1970-11-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	977
484146	1327	DEM|SEX:f	CHE-XXX	1970-03-01 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1970-11-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	978
483727	1328	A125	CHE-XXX	1972-10-10 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-10-10 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	979
483727	1328	A125	CHE-XXX	1972-10-10 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1972-10-10 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	980
483992	1328	A168	CHE-XXX	1972-07-21 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-10-10 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	981
483992	1328	A168	CHE-XXX	1972-07-21 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-10-10 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	982
484147	1328	DEM|SEX:f	CHE-XXX	1972-07-21 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-10-10 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	983
483728	1329	A125	CHE-XXX	1971-02-27 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-02-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	984
483728	1329	A125	CHE-XXX	1971-02-27 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1971-02-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	985
483993	1329	A168	CHE-XXX	1970-10-19 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-02-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	986
483993	1329	A168	CHE-XXX	1970-10-19 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1971-02-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	987
484148	1329	DEM|SEX:f	CHE-XXX	1970-10-19 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-02-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	988
483775	1330	A125	CHE-XXX	1972-03-02 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-03-02 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	989
483775	1330	A125	CHE-XXX	1972-03-02 01:00:00	126:0	1	\N	\N	\N	\N	\N	\N	1972-03-02 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	990
483994	1330	A168	CHE-XXX	1971-07-21 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-03-02 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	991
483994	1330	A168	CHE-XXX	1971-07-21 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-03-02 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	992
484149	1330	DEM|SEX:f	CHE-XXX	1971-07-21 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-03-02 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	993
483729	1331	A125	CHE-XXX	1972-04-27 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-04-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	994
483729	1331	A125	CHE-XXX	1972-04-27 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1972-04-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	995
483995	1331	A168	CHE-XXX	1971-08-02 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-04-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	996
483995	1331	A168	CHE-XXX	1971-08-02 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-04-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	997
484150	1331	DEM|SEX:f	CHE-XXX	1971-08-02 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-04-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	998
483776	1332	A125	CHE-XXX	1972-12-07 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-12-07 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	999
483776	1332	A125	CHE-XXX	1972-12-07 01:00:00	126:0	1	\N	\N	\N	\N	\N	\N	1972-12-07 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1000
483996	1332	A168	CHE-XXX	1972-04-26 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-12-07 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1001
483996	1332	A168	CHE-XXX	1972-04-26 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-12-07 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1002
484151	1332	DEM|SEX:f	CHE-XXX	1972-04-26 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-12-07 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1003
483777	1333	A125	CHE-XXX	1970-11-08 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1970-11-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1004
483777	1333	A125	CHE-XXX	1970-11-08 01:00:00	126:0	1	\N	\N	\N	\N	\N	\N	1970-11-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1005
483997	1333	A168	CHE-XXX	1970-03-10 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1970-11-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1006
483997	1333	A168	CHE-XXX	1970-03-10 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1970-11-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1007
484240	1333	DEM|SEX:m	CHE-XXX	1970-03-10 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1970-11-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1008
483778	1334	A125	CHE-XXX	1970-11-23 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1970-11-23 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1009
483778	1334	A125	CHE-XXX	1970-11-23 01:00:00	126:0	1	\N	\N	\N	\N	\N	\N	1970-11-23 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1010
483998	1334	A168	CHE-XXX	1970-02-17 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1970-11-23 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1011
483998	1334	A168	CHE-XXX	1970-02-17 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1970-11-23 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1012
484152	1334	DEM|SEX:f	CHE-XXX	1970-02-17 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1970-11-23 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1013
483779	1335	A125	CHE-XXX	1971-02-21 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-02-21 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1014
483779	1335	A125	CHE-XXX	1971-02-21 01:00:00	126:0	1	\N	\N	\N	\N	\N	\N	1971-02-21 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1015
483999	1335	A168	CHE-XXX	1970-05-21 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-02-21 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1016
483999	1335	A168	CHE-XXX	1970-05-21 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1971-02-21 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1017
484241	1335	DEM|SEX:m	CHE-XXX	1970-05-21 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-02-21 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1018
483730	1336	A125	CHE-XXX	1972-09-07 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-09-07 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1019
483730	1336	A125	CHE-XXX	1972-09-07 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1972-09-07 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1020
484000	1336	A168	CHE-XXX	1972-04-25 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-09-07 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1021
484000	1336	A168	CHE-XXX	1972-04-25 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-09-07 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1022
484153	1336	DEM|SEX:f	CHE-XXX	1972-04-25 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-09-07 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1023
483731	1337	A125	CHE-XXX	1972-11-13 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-11-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1024
483731	1337	A125	CHE-XXX	1972-11-13 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1972-11-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1025
484001	1337	A168	CHE-XXX	1972-08-26 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-11-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1026
484001	1337	A168	CHE-XXX	1972-08-26 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-11-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1027
484242	1337	DEM|SEX:m	CHE-XXX	1972-08-26 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-11-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1028
483732	1338	A125	CHE-XXX	1972-03-12 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-03-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1029
483732	1338	A125	CHE-XXX	1972-03-12 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1972-03-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1030
484002	1338	A168	CHE-XXX	1972-01-13 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-03-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1031
484002	1338	A168	CHE-XXX	1972-01-13 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-03-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1032
484154	1338	DEM|SEX:f	CHE-XXX	1972-01-13 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-03-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1033
483780	1339	A125	CHE-XXX	1970-12-12 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1970-12-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1034
483780	1339	A125	CHE-XXX	1970-12-12 01:00:00	126:0	1	\N	\N	\N	\N	\N	\N	1970-12-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1035
484003	1339	A168	CHE-XXX	1970-04-16 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1970-12-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1036
484003	1339	A168	CHE-XXX	1970-04-16 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1970-12-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1037
484243	1339	DEM|SEX:m	CHE-XXX	1970-04-16 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1970-12-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1038
483781	1340	A125	CHE-XXX	1971-09-13 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-09-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1039
483781	1340	A125	CHE-XXX	1971-09-13 01:00:00	126:0	1	\N	\N	\N	\N	\N	\N	1971-09-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1040
484004	1340	A168	CHE-XXX	1971-02-23 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-09-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1041
484004	1340	A168	CHE-XXX	1971-02-23 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1971-09-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1042
484244	1340	DEM|SEX:m	CHE-XXX	1971-02-23 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-09-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1043
483782	1341	A125	CHE-XXX	1972-06-26 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-06-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1044
483782	1341	A125	CHE-XXX	1972-06-26 01:00:00	126:0	1	\N	\N	\N	\N	\N	\N	1972-06-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1045
484005	1341	A168	CHE-XXX	1971-11-04 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-06-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1046
484005	1341	A168	CHE-XXX	1971-11-04 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-06-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1047
484245	1341	DEM|SEX:m	CHE-XXX	1971-11-04 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-06-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1048
483733	1342	A125	CHE-XXX	1970-04-26 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1970-04-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1049
483733	1342	A125	CHE-XXX	1970-04-26 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1970-04-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1050
484006	1342	A168	CHE-XXX	1970-01-11 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1970-04-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1051
484006	1342	A168	CHE-XXX	1970-01-11 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1970-04-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1052
484155	1342	DEM|SEX:f	CHE-XXX	1970-01-11 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1970-04-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1053
483783	1343	A125	CHE-XXX	1971-12-17 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-12-17 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1054
483783	1343	A125	CHE-XXX	1971-12-17 01:00:00	126:0	1	\N	\N	\N	\N	\N	\N	1971-12-17 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1055
484007	1343	A168	CHE-XXX	1971-05-07 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-12-17 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1056
484007	1343	A168	CHE-XXX	1971-05-07 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1971-12-17 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1057
484246	1343	DEM|SEX:m	CHE-XXX	1971-05-07 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-12-17 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1058
483734	1344	A125	CHE-XXX	1972-03-09 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-03-09 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1059
483734	1344	A125	CHE-XXX	1972-03-09 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1972-03-09 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1060
484008	1344	A168	CHE-XXX	1971-07-14 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-03-09 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1061
484008	1344	A168	CHE-XXX	1971-07-14 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-03-09 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1062
484247	1344	DEM|SEX:m	CHE-XXX	1971-07-14 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-03-09 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1063
483784	1345	A125	CHE-XXX	1972-09-30 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-09-30 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1064
483784	1345	A125	CHE-XXX	1972-09-30 01:00:00	126:0	1	\N	\N	\N	\N	\N	\N	1972-09-30 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1065
484009	1345	A168	CHE-XXX	1972-02-06 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-09-30 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1066
484009	1345	A168	CHE-XXX	1972-02-06 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-09-30 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1067
484156	1345	DEM|SEX:f	CHE-XXX	1972-02-06 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-09-30 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1068
483785	1346	A125	CHE-XXX	1971-11-07 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-11-07 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1069
483785	1346	A125	CHE-XXX	1971-11-07 01:00:00	126:0	1	\N	\N	\N	\N	\N	\N	1971-11-07 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1070
484010	1346	A168	CHE-XXX	1971-05-18 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-11-07 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1071
484010	1346	A168	CHE-XXX	1971-05-18 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1971-11-07 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1072
484248	1346	DEM|SEX:m	CHE-XXX	1971-05-18 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-11-07 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1073
483786	1347	A125	CHE-XXX	1971-05-22 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-05-22 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1074
483786	1347	A125	CHE-XXX	1971-05-22 01:00:00	126:0	1	\N	\N	\N	\N	\N	\N	1971-05-22 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1075
484011	1347	A168	CHE-XXX	1970-09-12 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-05-22 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1076
484011	1347	A168	CHE-XXX	1970-09-12 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1971-05-22 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1077
484249	1347	DEM|SEX:m	CHE-XXX	1970-09-12 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-05-22 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1078
483787	1348	A125	CHE-XXX	1970-12-21 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1970-12-21 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1079
483787	1348	A125	CHE-XXX	1970-12-21 01:00:00	126:0	1	\N	\N	\N	\N	\N	\N	1970-12-21 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1080
484012	1348	A168	CHE-XXX	1970-05-14 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1970-12-21 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1081
484012	1348	A168	CHE-XXX	1970-05-14 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1970-12-21 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1082
484157	1348	DEM|SEX:f	CHE-XXX	1970-05-14 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1970-12-21 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1083
483788	1349	A125	CHE-XXX	1971-06-07 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-06-07 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1084
483788	1349	A125	CHE-XXX	1971-06-07 01:00:00	126:0	1	\N	\N	\N	\N	\N	\N	1971-06-07 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1085
484013	1349	A168	CHE-XXX	1970-12-04 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-06-07 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1086
484013	1349	A168	CHE-XXX	1970-12-04 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1971-06-07 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1087
484158	1349	DEM|SEX:f	CHE-XXX	1970-12-04 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-06-07 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1088
483789	1350	A125	CHE-XXX	1972-06-07 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-06-07 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1089
483789	1350	A125	CHE-XXX	1972-06-07 01:00:00	126:0	1	\N	\N	\N	\N	\N	\N	1972-06-07 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1090
484014	1350	A168	CHE-XXX	1972-03-07 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-06-07 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1091
484014	1350	A168	CHE-XXX	1972-03-07 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-06-07 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1092
484250	1350	DEM|SEX:m	CHE-XXX	1972-03-07 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-06-07 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1093
483735	1351	A125	CHE-XXX	1972-04-27 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-04-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1094
483735	1351	A125	CHE-XXX	1972-04-27 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1972-04-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1095
484015	1351	A168	CHE-XXX	1972-04-14 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-04-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1096
484015	1351	A168	CHE-XXX	1972-04-14 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-04-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1097
484159	1351	DEM|SEX:f	CHE-XXX	1972-04-14 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-04-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1098
483790	1352	A125	CHE-XXX	1973-04-28 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-04-28 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1099
483790	1352	A125	CHE-XXX	1973-04-28 01:00:00	126:0	1	\N	\N	\N	\N	\N	\N	1973-04-28 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1100
484016	1352	A168	CHE-XXX	1972-09-18 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-04-28 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1101
484016	1352	A168	CHE-XXX	1972-09-18 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1973-04-28 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1102
484160	1352	DEM|SEX:f	CHE-XXX	1972-09-18 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1973-04-28 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1103
483791	1353	A125	CHE-XXX	1971-09-22 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-09-22 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1104
483791	1353	A125	CHE-XXX	1971-09-22 01:00:00	126:0	1	\N	\N	\N	\N	\N	\N	1971-09-22 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1105
484017	1353	A168	CHE-XXX	1971-03-14 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-09-22 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1106
484017	1353	A168	CHE-XXX	1971-03-14 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1971-09-22 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1107
484251	1353	DEM|SEX:m	CHE-XXX	1971-03-14 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-09-22 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1108
483736	1354	A125	CHE-XXX	1971-05-01 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-05-01 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1109
483736	1354	A125	CHE-XXX	1971-05-01 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1971-05-01 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1110
484018	1354	A168	CHE-XXX	1970-10-30 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-05-01 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1111
484018	1354	A168	CHE-XXX	1970-10-30 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1971-05-01 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1112
484161	1354	DEM|SEX:f	CHE-XXX	1970-10-30 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-05-01 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1113
483792	1355	A125	CHE-XXX	1972-08-09 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-08-09 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1114
483792	1355	A125	CHE-XXX	1972-08-09 01:00:00	126:0	1	\N	\N	\N	\N	\N	\N	1972-08-09 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1115
484019	1355	A168	CHE-XXX	1972-01-11 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-08-09 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1116
484019	1355	A168	CHE-XXX	1972-01-11 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-08-09 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1117
484252	1355	DEM|SEX:m	CHE-XXX	1972-01-11 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-08-09 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1118
483793	1356	A125	CHE-XXX	1971-04-28 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-04-28 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1119
483793	1356	A125	CHE-XXX	1971-04-28 01:00:00	126:0	1	\N	\N	\N	\N	\N	\N	1971-04-28 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1120
484020	1356	A168	CHE-XXX	1970-11-04 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-04-28 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1121
484020	1356	A168	CHE-XXX	1970-11-04 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1971-04-28 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1122
484253	1356	DEM|SEX:m	CHE-XXX	1970-11-04 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-04-28 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1123
483794	1357	A125	CHE-XXX	1971-12-03 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-12-03 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1124
483794	1357	A125	CHE-XXX	1971-12-03 01:00:00	126:0	1	\N	\N	\N	\N	\N	\N	1971-12-03 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1125
484021	1357	A168	CHE-XXX	1971-05-20 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-12-03 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1126
484021	1357	A168	CHE-XXX	1971-05-20 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1971-12-03 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1127
484162	1357	DEM|SEX:f	CHE-XXX	1971-05-20 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-12-03 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1128
483795	1358	A125	CHE-XXX	1971-01-18 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-01-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1129
483795	1358	A125	CHE-XXX	1971-01-18 01:00:00	126:0	1	\N	\N	\N	\N	\N	\N	1971-01-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1130
484022	1358	A168	CHE-XXX	1970-06-29 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-01-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1131
484022	1358	A168	CHE-XXX	1970-06-29 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1971-01-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1132
484254	1358	DEM|SEX:m	CHE-XXX	1970-06-29 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-01-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1133
483737	1359	A125	CHE-XXX	1972-02-28 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-02-28 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1134
483737	1359	A125	CHE-XXX	1972-02-28 01:00:00	126:1	1	\N	\N	\N	\N	\N	\N	1972-02-28 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1135
484023	1359	A168	CHE-XXX	1971-11-04 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-02-28 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1136
484023	1359	A168	CHE-XXX	1971-11-04 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-02-28 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1137
484163	1359	DEM|SEX:f	CHE-XXX	1971-11-04 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-02-28 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1138
483796	1360	A125	CHE-XXX	1972-03-18 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-03-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1139
483796	1360	A125	CHE-XXX	1972-03-18 01:00:00	126:0	1	\N	\N	\N	\N	\N	\N	1972-03-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1140
484024	1360	A168	CHE-XXX	1971-09-12 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-03-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1141
484024	1360	A168	CHE-XXX	1971-09-12 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-03-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1142
484164	1360	DEM|SEX:f	CHE-XXX	1971-09-12 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-03-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1143
483797	1361	A125	CHE-XXX	1972-10-10 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-10-10 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1144
483797	1361	A125	CHE-XXX	1972-10-10 01:00:00	126:0	1	\N	\N	\N	\N	\N	\N	1972-10-10 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1145
484025	1361	A168	CHE-XXX	1972-04-02 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-10-10 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1146
484025	1361	A168	CHE-XXX	1972-04-02 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1972-10-10 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1147
484165	1361	DEM|SEX:f	CHE-XXX	1972-04-02 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1972-10-10 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1148
483798	1362	A125	CHE-XXX	1971-09-02 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-09-02 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1149
483798	1362	A125	CHE-XXX	1971-09-02 01:00:00	126:0	1	\N	\N	\N	\N	\N	\N	1971-09-02 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1150
484026	1362	A168	CHE-XXX	1971-05-20 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-09-02 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1151
484026	1362	A168	CHE-XXX	1971-05-20 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1971-09-02 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1152
484255	1362	DEM|SEX:m	CHE-XXX	1971-05-20 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-09-02 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1153
483799	1363	A125	CHE-XXX	1971-08-27 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-08-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1154
483799	1363	A125	CHE-XXX	1971-08-27 01:00:00	126:0	1	\N	\N	\N	\N	\N	\N	1971-08-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1155
484027	1363	A168	CHE-XXX	1971-03-06 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-08-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1156
484027	1363	A168	CHE-XXX	1971-03-06 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1971-08-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1157
484166	1363	DEM|SEX:f	CHE-XXX	1971-03-06 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-08-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1158
483800	1364	A125	CHE-XXX	1971-04-25 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-04-25 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1159
483800	1364	A125	CHE-XXX	1971-04-25 01:00:00	126:0	1	\N	\N	\N	\N	\N	\N	1971-04-25 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1160
484028	1364	A168	CHE-XXX	1970-10-30 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-04-25 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1161
484028	1364	A168	CHE-XXX	1970-10-30 01:00:00	171:0	1	\N	\N	\N	\N	\N	\N	1971-04-25 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1162
484256	1364	DEM|SEX:m	CHE-XXX	1970-10-30 01:00:00	@	1	\N	\N	\N	\N	\N	\N	1971-04-25 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	1163
\.


--
-- Data for Name: patient_dimension; Type: TABLE DATA; Schema: i2b2demodata; Owner: postgres
--

COPY i2b2demodata.patient_dimension (patient_num, vital_status_cd, birth_date, death_date, sex_cd, age_in_years_num, language_cd, race_cd, marital_status_cd, religion_cd, zip_cd, statecityzip_path, income_cd, patient_blob, update_date, download_date, import_date, sourcesystem_cd, upload_id) FROM stdin;
1	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2022-05-02 12:01:25.167675	\N	1
2	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2022-05-02 12:01:25.167675	\N	1
3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2022-05-02 12:01:25.167675	\N	1
4	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2022-05-02 12:01:25.167675	\N	1
1137	Y	1898-03-04 01:00:00	1972-02-15 01:00:00	M	74	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1138	Y	1903-06-29 01:00:00	1971-06-12 01:00:00	M	68	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1139	N	1917-03-30 01:00:00	\N	M	56	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1140	Y	1915-05-23 01:00:00	1972-05-08 01:00:00	M	57	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1141	Y	1915-03-13 01:00:00	1975-02-26 01:00:00	M	60	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1142	N	1900-06-20 01:00:00	\N	M	74	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1143	Y	1903-08-19 01:00:00	1971-08-02 01:00:00	F	68	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1144	Y	1902-05-18 01:00:00	1973-04-30 01:00:00	F	71	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1145	Y	1919-09-06 01:00:00	1972-08-23 01:00:00	M	53	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1146	Y	1911-09-26 01:00:00	1972-09-10 01:00:00	M	61	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1147	Y	1914-05-11 01:00:00	1971-04-27 01:00:00	M	57	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1148	Y	1905-11-04 01:00:00	1973-10-18 01:00:00	F	68	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1149	Y	1904-01-31 01:00:00	1972-01-14 01:00:00	F	68	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1150	Y	1912-08-28 01:00:00	1972-08-13 01:00:00	M	60	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1151	Y	1915-07-12 01:00:00	1972-06-27 01:00:00	M	57	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1152	Y	1903-12-22 01:00:00	1970-12-05 01:00:00	M	67	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1153	Y	1902-02-13 01:00:00	1972-01-27 01:00:00	M	70	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1154	Y	1910-10-28 01:00:00	1973-10-12 01:00:00	M	63	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1155	Y	1916-06-29 01:00:00	1972-06-15 01:00:00	F	56	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1156	Y	1915-12-28 01:00:00	1972-12-13 01:00:00	M	57	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1157	Y	1904-10-05 01:00:00	1971-09-19 01:00:00	M	67	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1158	Y	1922-11-21 01:00:00	1971-11-09 01:00:00	F	49	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1159	Y	1923-03-02 01:00:00	1973-02-17 01:00:00	M	50	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1160	Y	1914-09-13 01:00:00	1972-08-29 01:00:00	M	58	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1161	Y	1899-11-11 01:00:00	1971-10-25 01:00:00	M	72	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1162	Y	1903-06-07 01:00:00	1973-05-20 01:00:00	F	70	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1163	Y	1914-03-25 01:00:00	1974-03-10 01:00:00	M	60	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1164	Y	1901-03-14 01:00:00	1971-02-25 01:00:00	M	70	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1165	Y	1919-04-11 01:00:00	1972-03-28 01:00:00	M	53	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1166	Y	1897-05-26 01:00:00	1971-05-09 01:00:00	M	74	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1167	Y	1904-11-14 01:00:00	1973-10-28 01:00:00	F	69	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1168	Y	1897-03-01 01:00:00	1970-02-12 01:00:00	M	73	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1169	Y	1925-05-03 01:00:00	1973-04-21 01:00:00	M	48	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1170	Y	1912-10-10 01:00:00	1972-09-25 01:00:00	F	60	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1171	Y	1910-05-30 01:00:00	1971-05-15 01:00:00	M	61	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1172	Y	1909-02-19 01:00:00	1971-02-04 01:00:00	F	62	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1173	Y	1908-04-24 01:00:00	1973-04-08 01:00:00	M	65	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1174	N	1908-07-04 01:00:00	\N	F	66	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1175	Y	1898-05-22 01:00:00	1972-05-04 01:00:00	M	74	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1176	Y	1910-09-20 01:00:00	1974-09-04 01:00:00	F	64	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1177	Y	1902-04-05 01:00:00	1972-03-18 01:00:00	M	70	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1178	Y	1900-03-04 01:00:00	1973-02-14 01:00:00	F	73	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1179	Y	1913-02-03 01:00:00	1972-01-20 01:00:00	F	59	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1180	Y	1912-11-08 01:00:00	1972-10-24 01:00:00	F	60	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1181	Y	1905-04-16 01:00:00	1973-03-30 01:00:00	M	68	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1182	Y	1896-03-13 01:00:00	1972-02-24 01:00:00	F	76	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1183	Y	1897-05-04 01:00:00	1971-04-17 01:00:00	M	74	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1184	Y	1910-04-21 01:00:00	1973-04-05 01:00:00	M	63	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1185	Y	1899-12-21 01:00:00	1973-12-03 01:00:00	M	74	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1186	Y	1924-10-23 01:00:00	1974-10-11 01:00:00	F	50	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1187	Y	1900-02-19 01:00:00	1972-02-02 01:00:00	F	72	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1188	Y	1907-09-27 01:00:00	1970-09-11 01:00:00	M	63	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1189	Y	1902-07-18 01:00:00	1970-07-01 01:00:00	M	68	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1190	Y	1915-01-17 01:00:00	1973-01-02 01:00:00	M	58	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1191	Y	1913-02-22 01:00:00	1972-02-08 01:00:00	M	59	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1192	Y	1910-05-06 01:00:00	1972-04-20 01:00:00	M	62	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1193	Y	1905-03-04 01:00:00	1970-02-16 01:00:00	F	65	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1194	Y	1915-12-04 01:00:00	1972-11-19 01:00:00	M	57	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1195	Y	1914-12-10 01:00:00	1972-11-25 01:00:00	F	58	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1196	Y	1907-11-22 01:00:00	1971-11-06 01:00:00	F	64	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1197	Y	1896-11-25 01:00:00	1971-11-08 01:00:00	F	75	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1198	Y	1923-04-23 01:00:00	1971-04-11 01:00:00	M	48	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1199	Y	1898-12-21 01:00:00	1971-12-04 01:00:00	M	73	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1200	Y	1905-05-09 01:00:00	1970-04-23 01:00:00	F	65	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1201	Y	1902-06-06 01:00:00	1971-05-20 01:00:00	M	69	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1202	Y	1904-08-27 01:00:00	1972-08-10 01:00:00	M	68	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1203	Y	1905-06-19 01:00:00	1972-06-02 01:00:00	F	67	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1204	N	1910-11-21 01:00:00	\N	F	64	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1205	Y	1904-06-05 01:00:00	1972-05-19 01:00:00	M	68	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1206	Y	1905-09-29 01:00:00	1972-09-12 01:00:00	M	67	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1207	N	1910-09-16 01:00:00	\N	M	63	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1208	Y	1925-04-19 01:00:00	1973-04-07 01:00:00	F	48	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1209	Y	1898-06-26 01:00:00	1972-06-08 01:00:00	M	74	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1210	Y	1930-08-02 01:00:00	1970-07-23 01:00:00	M	40	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1211	Y	1918-07-13 01:00:00	1971-06-30 01:00:00	F	53	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1212	Y	1901-06-03 01:00:00	1972-05-16 01:00:00	F	71	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1213	Y	1923-01-26 01:00:00	1974-01-13 01:00:00	F	51	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1214	Y	1915-03-08 01:00:00	1971-02-22 01:00:00	F	56	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1215	Y	1891-04-02 01:00:00	1972-03-13 01:00:00	M	81	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1216	Y	1899-01-23 01:00:00	1972-01-06 01:00:00	M	73	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1217	Y	1914-08-31 01:00:00	1973-08-16 01:00:00	M	59	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1218	Y	1915-12-10 01:00:00	1970-11-26 01:00:00	M	55	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1219	N	1929-08-16 01:00:00	\N	M	42	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1220	Y	1927-01-11 01:00:00	1970-12-31 01:00:00	F	44	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1221	N	1929-05-01 01:00:00	\N	M	44	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1222	Y	1902-07-14 01:00:00	1973-06-26 01:00:00	M	71	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1223	Y	1911-04-07 01:00:00	1973-03-22 01:00:00	F	62	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1224	Y	1911-12-31 01:00:00	1972-12-15 01:00:00	M	61	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1225	N	1929-02-14 01:00:00	\N	F	44	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1226	Y	1899-04-04 01:00:00	1971-03-18 01:00:00	M	72	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1227	Y	1909-09-26 01:00:00	1972-09-10 01:00:00	M	63	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1228	Y	1902-07-01 01:00:00	1972-06-13 01:00:00	M	70	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1229	Y	1905-10-07 01:00:00	1971-09-21 01:00:00	M	66	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1230	Y	1915-09-17 01:00:00	1972-09-02 01:00:00	F	57	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1231	N	1903-05-16 01:00:00	\N	F	69	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1232	Y	1899-10-15 01:00:00	1971-09-28 01:00:00	M	72	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1233	Y	1902-08-13 01:00:00	1971-07-27 01:00:00	M	69	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1234	Y	1902-07-09 01:00:00	1973-06-21 01:00:00	M	71	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1235	Y	1909-07-24 01:00:00	1973-07-08 01:00:00	M	64	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1236	Y	1900-12-04 01:00:00	1970-11-17 01:00:00	F	70	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1237	N	1914-08-20 01:00:00	\N	F	58	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1238	Y	1904-03-20 01:00:00	1973-03-03 01:00:00	F	69	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1239	Y	1915-04-03 01:00:00	1971-03-20 01:00:00	M	56	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1240	Y	1908-09-09 01:00:00	1971-08-25 01:00:00	M	63	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1241	Y	1912-03-14 01:00:00	1971-02-28 01:00:00	M	59	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1242	Y	1905-01-08 01:00:00	1970-12-23 01:00:00	M	66	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1243	N	1919-01-22 01:00:00	\N	F	54	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1244	Y	1904-04-08 01:00:00	1971-03-23 01:00:00	M	67	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1245	Y	1916-09-26 01:00:00	1971-09-13 01:00:00	M	55	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1246	Y	1897-08-20 01:00:00	1972-08-02 01:00:00	F	75	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1247	Y	1903-05-01 01:00:00	1972-04-13 01:00:00	M	69	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1248	Y	1927-02-23 01:00:00	1971-02-12 01:00:00	M	44	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1249	Y	1892-12-25 01:00:00	1972-12-06 01:00:00	M	80	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1250	Y	1895-11-27 01:00:00	1970-11-09 01:00:00	F	75	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1251	Y	1917-07-15 01:00:00	1971-07-02 01:00:00	F	54	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1252	Y	1896-06-04 01:00:00	1972-05-17 01:00:00	M	76	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1253	Y	1922-05-07 01:00:00	1971-04-25 01:00:00	M	49	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1254	Y	1903-08-08 01:00:00	1971-07-22 01:00:00	M	68	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1255	Y	1906-03-14 01:00:00	1972-02-26 01:00:00	M	66	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1256	Y	1892-02-22 01:00:00	1972-02-03 01:00:00	M	80	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1257	Y	1898-09-14 01:00:00	1973-08-27 01:00:00	M	75	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1258	Y	1912-05-01 01:00:00	1972-04-16 01:00:00	F	60	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1259	Y	1903-04-26 01:00:00	1972-04-08 01:00:00	F	69	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1260	Y	1899-12-10 01:00:00	1971-11-23 01:00:00	M	72	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1261	Y	1901-12-05 01:00:00	1971-11-18 01:00:00	M	70	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1262	Y	1905-08-10 01:00:00	1971-07-25 01:00:00	M	66	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1263	Y	1920-12-15 01:00:00	1970-12-03 01:00:00	M	50	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1264	Y	1908-07-15 01:00:00	1972-06-29 01:00:00	M	64	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1265	N	1896-05-18 01:00:00	\N	F	77	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1266	N	1926-02-24 01:00:00	\N	F	48	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1267	Y	1914-06-16 01:00:00	1973-06-01 01:00:00	F	59	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1268	Y	1918-05-09 01:00:00	1971-04-26 01:00:00	M	53	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1269	Y	1924-11-26 01:00:00	1971-11-15 01:00:00	M	47	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1270	N	1917-01-11 01:00:00	\N	F	55	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1271	Y	1905-10-05 01:00:00	1972-09-18 01:00:00	M	67	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1272	N	1898-05-27 01:00:00	\N	F	74	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1273	Y	1915-06-11 01:00:00	1973-05-27 01:00:00	F	58	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1274	Y	1915-12-15 01:00:00	1971-12-01 01:00:00	M	56	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1275	Y	1919-01-25 01:00:00	1973-01-11 01:00:00	M	54	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1276	Y	1915-03-06 01:00:00	1971-02-20 01:00:00	M	56	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1277	Y	1900-01-23 01:00:00	1973-01-05 01:00:00	F	73	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1278	N	1897-04-23 01:00:00	\N	M	74	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1279	Y	1895-01-05 01:00:00	1970-12-18 01:00:00	M	76	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1280	Y	1906-12-10 01:00:00	1971-11-24 01:00:00	F	65	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1281	N	1916-12-23 01:00:00	\N	M	57	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1282	N	1920-09-11 01:00:00	\N	F	53	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1283	Y	1901-03-01 01:00:00	1972-02-12 01:00:00	M	71	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1284	Y	1918-01-09 01:00:00	1971-12-27 01:00:00	M	54	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1285	Y	1888-04-30 01:00:00	1970-04-11 01:00:00	M	82	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1286	Y	1913-09-20 01:00:00	1972-09-05 01:00:00	F	59	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1287	Y	1903-05-05 01:00:00	1973-04-17 01:00:00	M	70	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1288	N	1912-07-23 01:00:00	\N	M	60	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1289	N	1910-10-27 01:00:00	\N	F	62	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1290	Y	1918-03-22 01:00:00	1971-03-09 01:00:00	F	53	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1291	Y	1917-01-19 01:00:00	1972-01-06 01:00:00	M	55	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1292	Y	1903-10-07 01:00:00	1972-09-19 01:00:00	M	69	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1293	N	1903-12-28 01:00:00	\N	F	68	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1294	Y	1909-09-23 01:00:00	1971-09-08 01:00:00	M	62	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1295	Y	1907-09-04 01:00:00	1970-08-19 01:00:00	M	63	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1296	N	1916-03-09 01:00:00	\N	F	56	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1297	N	1910-12-27 01:00:00	\N	F	62	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1298	Y	1929-04-27 01:00:00	1973-04-16 01:00:00	F	44	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1299	N	1903-05-08 01:00:00	\N	M	69	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1300	Y	1908-02-25 01:00:00	1971-02-09 01:00:00	M	63	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1301	N	1908-05-19 01:00:00	\N	M	64	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1302	N	1915-12-16 01:00:00	\N	F	57	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1303	Y	1912-03-06 01:00:00	1972-02-20 01:00:00	F	60	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1304	Y	1927-02-04 01:00:00	1973-01-23 01:00:00	M	46	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1305	Y	1911-04-26 01:00:00	1972-04-10 01:00:00	M	61	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1306	Y	1906-01-29 01:00:00	1971-01-13 01:00:00	M	65	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1307	N	1910-10-30 01:00:00	\N	M	61	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1308	Y	1913-10-12 01:00:00	1971-09-28 01:00:00	F	58	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1309	Y	1916-08-05 01:00:00	1972-07-22 01:00:00	M	56	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1310	N	1928-04-27 01:00:00	\N	F	43	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1311	N	1919-06-21 01:00:00	\N	M	53	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1312	N	1914-03-06 01:00:00	\N	F	59	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1313	Y	1916-01-25 01:00:00	1972-01-11 01:00:00	M	56	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1314	Y	1916-09-01 01:00:00	1971-08-19 01:00:00	F	55	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1315	Y	1918-09-07 01:00:00	1971-08-25 01:00:00	F	53	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1316	N	1898-07-22 01:00:00	\N	F	74	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1317	N	1911-01-22 01:00:00	\N	M	60	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1318	N	1933-11-05 01:00:00	\N	M	39	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1319	Y	1907-01-29 01:00:00	1973-01-12 01:00:00	F	66	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1320	N	1906-12-06 01:00:00	\N	F	65	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1321	N	1921-10-24 01:00:00	\N	F	51	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1322	N	1927-09-04 01:00:00	\N	F	45	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1323	Y	1900-09-21 01:00:00	1972-09-03 01:00:00	F	72	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1324	N	1914-07-01 01:00:00	\N	M	58	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1325	Y	1906-07-02 01:00:00	1970-06-16 01:00:00	M	64	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1326	Y	1919-03-05 01:00:00	1972-02-20 01:00:00	M	53	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1327	Y	1898-12-13 01:00:00	1970-11-26 01:00:00	M	72	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1328	Y	1920-10-23 01:00:00	1972-10-10 01:00:00	M	52	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1329	Y	1921-03-11 01:00:00	1971-02-27 01:00:00	M	50	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1330	N	1908-03-18 01:00:00	\N	M	64	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1331	Y	1901-05-15 01:00:00	1972-04-27 01:00:00	M	71	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1332	N	1902-12-25 01:00:00	\N	M	70	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1333	N	1907-11-24 01:00:00	\N	F	63	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1334	N	1906-12-09 01:00:00	\N	M	64	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1335	N	1919-03-06 01:00:00	\N	F	52	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1336	Y	1912-09-22 01:00:00	1972-09-07 01:00:00	M	60	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1337	Y	1908-11-29 01:00:00	1972-11-13 01:00:00	F	64	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1338	Y	1899-03-30 01:00:00	1972-03-12 01:00:00	M	73	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1339	N	1907-12-28 01:00:00	\N	F	63	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1340	N	1921-09-25 01:00:00	\N	F	50	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1341	N	1909-07-12 01:00:00	\N	F	63	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1342	Y	1908-05-11 01:00:00	1970-04-26 01:00:00	M	62	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1343	N	1916-12-30 01:00:00	\N	F	55	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1344	Y	1922-03-22 01:00:00	1972-03-09 01:00:00	F	50	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1345	N	1903-10-18 01:00:00	\N	M	69	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1346	N	1912-11-21 01:00:00	\N	F	59	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1347	N	1911-06-06 01:00:00	\N	F	60	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1348	N	1904-01-07 01:00:00	\N	M	67	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1349	N	1902-06-24 01:00:00	\N	M	69	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1350	N	1908-06-23 01:00:00	\N	F	64	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1351	Y	1907-05-14 01:00:00	1972-04-27 01:00:00	M	65	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1352	N	1908-05-14 01:00:00	\N	M	65	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1353	N	1930-10-02 01:00:00	\N	F	41	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1354	Y	1895-05-19 01:00:00	1971-05-01 01:00:00	M	76	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1355	N	1902-08-27 01:00:00	\N	F	70	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1356	N	1914-05-12 01:00:00	\N	F	57	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1357	N	1904-12-19 01:00:00	\N	M	67	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1358	N	1900-02-04 01:00:00	\N	F	71	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1359	Y	1896-03-17 01:00:00	1972-02-28 01:00:00	M	76	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1360	N	1895-04-06 01:00:00	\N	M	77	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1361	N	1933-10-20 01:00:00	\N	M	39	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1362	N	1896-09-19 01:00:00	\N	F	75	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1363	N	1905-09-12 01:00:00	\N	M	66	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1364	N	1913-05-09 01:00:00	\N	F	58	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
\.


--
-- Data for Name: patient_mapping; Type: TABLE DATA; Schema: i2b2demodata; Owner: postgres
--

COPY i2b2demodata.patient_mapping (patient_ide, patient_ide_source, patient_num, patient_ide_status, project_id, upload_date, update_date, download_date, import_date, sourcesystem_cd, upload_id) FROM stdin;
test1	test	1	\N	Demo	\N	\N	\N	2022-05-02 12:01:25.168642	\N	1
test2	test	2	\N	Demo	\N	\N	\N	2022-05-02 12:01:25.168642	\N	1
test3	test	3	\N	Demo	\N	\N	\N	2022-05-02 12:01:25.168642	\N	1
test4	test	4	\N	Demo	\N	\N	\N	2022-05-02 12:01:25.168642	\N	1
\.


--
-- Data for Name: provider_dimension; Type: TABLE DATA; Schema: i2b2demodata; Owner: postgres
--

COPY i2b2demodata.provider_dimension (provider_id, provider_path, name_char, provider_blob, update_date, download_date, import_date, sourcesystem_cd, upload_id) FROM stdin;
test	\\test\\	test	\N	\N	\N	2022-05-02 12:01:25.166779	\N	1
\.


--
-- Data for Name: qt_analysis_plugin; Type: TABLE DATA; Schema: i2b2demodata; Owner: postgres
--

COPY i2b2demodata.qt_analysis_plugin (plugin_id, plugin_name, description, version_cd, parameter_info, parameter_info_xsd, command_line, working_folder, commandoption_cd, plugin_icon, status_cd, user_id, group_id, create_date, update_date) FROM stdin;
\.


--
-- Data for Name: qt_analysis_plugin_result_type; Type: TABLE DATA; Schema: i2b2demodata; Owner: postgres
--

COPY i2b2demodata.qt_analysis_plugin_result_type (plugin_id, result_type_id) FROM stdin;
\.


--
-- Data for Name: qt_breakdown_path; Type: TABLE DATA; Schema: i2b2demodata; Owner: postgres
--

COPY i2b2demodata.qt_breakdown_path (name, value, create_date, update_date, user_id) FROM stdin;
\.


--
-- Data for Name: qt_patient_enc_collection; Type: TABLE DATA; Schema: i2b2demodata; Owner: postgres
--

COPY i2b2demodata.qt_patient_enc_collection (patient_enc_coll_id, result_instance_id, set_index, patient_num, encounter_num) FROM stdin;
\.


--
-- Data for Name: qt_patient_set_collection; Type: TABLE DATA; Schema: i2b2demodata; Owner: postgres
--

COPY i2b2demodata.qt_patient_set_collection (patient_set_coll_id, result_instance_id, set_index, patient_num) FROM stdin;
-1	-101	1	1137
-2	-101	2	1138
-3	-101	3	1139
-4	-101	4	1140
-5	-101	5	1141
-6	-101	6	1142
-7	-101	7	1143
-8	-101	8	1144
-9	-101	9	1145
-10	-101	10	1146
-11	-101	11	1147
-12	-101	12	1148
-13	-101	13	1149
-14	-101	14	1150
-15	-101	15	1151
-16	-101	16	1152
-17	-101	17	1153
-18	-101	18	1154
-19	-101	19	1155
-20	-101	20	1156
-21	-101	21	1157
-22	-101	22	1158
-23	-101	23	1159
-24	-101	24	1160
-25	-101	25	1161
-26	-101	26	1162
-27	-101	27	1163
-28	-101	28	1164
-29	-101	29	1165
-30	-101	30	1166
-31	-101	31	1167
-32	-101	32	1168
-33	-101	33	1169
-34	-101	34	1170
-35	-101	35	1171
-36	-101	36	1172
-37	-101	37	1173
-38	-101	38	1174
-39	-101	39	1175
-40	-101	40	1176
-41	-101	41	1177
-42	-101	42	1178
-43	-101	43	1179
-44	-101	44	1180
-45	-101	45	1181
-46	-101	46	1182
-47	-101	47	1183
-48	-101	48	1184
-49	-101	49	1185
-50	-101	50	1186
-51	-101	51	1187
-52	-101	52	1188
-53	-101	53	1189
-54	-101	54	1190
-55	-101	55	1191
-56	-101	56	1192
-57	-101	57	1193
-58	-101	58	1194
-59	-101	59	1195
-60	-101	60	1196
-61	-101	61	1197
-62	-101	62	1198
-63	-101	63	1199
-64	-101	64	1200
-65	-101	65	1201
-66	-101	66	1202
-67	-101	67	1203
-68	-101	68	1204
-69	-101	69	1205
-70	-101	70	1206
-71	-101	71	1207
-72	-101	72	1208
-73	-101	73	1209
-74	-101	74	1210
-75	-101	75	1211
-76	-101	76	1212
-77	-101	77	1213
-78	-101	78	1214
-79	-101	79	1215
-80	-101	80	1216
-81	-101	81	1217
-82	-101	82	1218
-83	-101	83	1219
-84	-101	84	1220
-85	-101	85	1221
-86	-101	86	1222
-87	-101	87	1223
-88	-101	88	1224
-89	-101	89	1225
-90	-101	90	1226
-91	-101	91	1227
-92	-101	92	1228
-93	-101	93	1229
-94	-101	94	1230
-95	-101	95	1231
-96	-101	96	1232
-97	-101	97	1233
-98	-101	98	1234
-99	-101	99	1235
-100	-101	100	1236
-101	-101	101	1237
-102	-101	102	1238
-103	-101	103	1239
-104	-101	104	1240
-105	-101	105	1241
-106	-101	106	1242
-107	-101	107	1243
-108	-101	108	1244
-109	-101	109	1245
-110	-101	110	1246
-111	-101	111	1247
-112	-101	112	1248
-113	-101	113	1249
-114	-101	114	1250
-115	-101	115	1251
-116	-101	116	1252
-117	-101	117	1253
-118	-101	118	1254
-119	-101	119	1255
-120	-101	120	1256
-121	-101	121	1257
-122	-101	122	1258
-123	-101	123	1259
-124	-101	124	1260
-125	-101	125	1261
-126	-101	126	1262
-127	-101	127	1263
-128	-101	128	1264
-129	-101	129	1265
-130	-101	130	1266
-131	-101	131	1267
-132	-101	132	1268
-133	-101	133	1269
-134	-101	134	1270
-135	-101	135	1271
-136	-101	136	1272
-137	-101	137	1273
-138	-101	138	1274
-139	-101	139	1275
-140	-101	140	1276
-141	-101	141	1277
-142	-101	142	1278
-143	-101	143	1279
-144	-101	144	1280
-145	-101	145	1281
-146	-101	146	1282
-147	-101	147	1283
-148	-101	148	1284
-149	-101	149	1285
-150	-101	150	1286
-151	-101	151	1287
-152	-101	152	1288
-153	-101	153	1289
-154	-101	154	1290
-155	-101	155	1291
-156	-101	156	1292
-157	-101	157	1293
-158	-101	158	1294
-159	-101	159	1295
-160	-101	160	1296
-161	-101	161	1297
-162	-101	162	1298
-163	-101	163	1299
-164	-101	164	1300
-165	-101	165	1301
-166	-101	166	1302
-167	-101	167	1303
-168	-101	168	1304
-169	-101	169	1305
-170	-101	170	1306
-171	-101	171	1307
-172	-101	172	1308
-173	-101	173	1309
-174	-101	174	1310
-175	-101	175	1311
-176	-101	176	1312
-177	-101	177	1313
-178	-101	178	1314
-179	-101	179	1315
-180	-101	180	1316
-181	-101	181	1317
-182	-101	182	1318
-183	-101	183	1319
-184	-101	184	1320
-185	-101	185	1321
-186	-101	186	1322
-187	-101	187	1323
-188	-101	188	1324
-189	-101	189	1325
-190	-101	190	1326
-191	-101	191	1327
-192	-101	192	1328
-193	-101	193	1329
-194	-101	194	1330
-195	-101	195	1331
-196	-101	196	1332
-197	-101	197	1333
-198	-101	198	1334
-199	-101	199	1335
-200	-101	200	1336
-201	-101	201	1337
-202	-101	202	1338
-203	-101	203	1339
-204	-101	204	1340
-205	-101	205	1341
-206	-101	206	1342
-207	-101	207	1343
-208	-101	208	1344
-209	-101	209	1345
-210	-101	210	1346
-211	-101	211	1347
-212	-101	212	1348
-213	-101	213	1349
-214	-101	214	1350
-215	-101	215	1351
-216	-101	216	1352
-217	-101	217	1353
-218	-101	218	1354
-219	-101	219	1355
-220	-101	220	1356
-221	-101	221	1357
-222	-101	222	1358
-223	-101	223	1359
-224	-101	224	1360
-225	-101	225	1361
-226	-101	226	1362
-227	-101	227	1363
-228	-101	228	1364
1	1	1	1
2	1	2	2
3	1	3	3
4	3	1	1
5	5	1	1
6	5	2	2
7	5	3	3
8	7	1	1
9	7	2	2
10	7	3	3
11	7	4	4
12	9	1	1
13	9	2	2
14	9	3	3
15	11	1	1
16	11	2	2
17	11	3	3
18	11	4	4
19	13	1	1
20	15	1	1
21	15	2	4
22	17	1	1
23	17	2	3
24	19	1	1
25	19	2	2
26	19	3	3
27	21	1	1
28	23	1	2
29	25	1	1
30	25	2	2
31	25	3	3
32	27	1	1137
33	27	2	1138
34	27	3	1139
35	27	4	1140
36	27	5	1141
37	27	6	1142
38	27	7	1143
39	27	8	1144
40	27	9	1145
41	27	10	1146
42	27	11	1147
43	27	12	1148
44	27	13	1149
45	27	14	1150
46	27	15	1151
47	27	16	1152
48	27	17	1153
49	27	18	1154
50	27	19	1155
51	27	20	1156
52	27	21	1157
53	27	22	1158
54	27	23	1159
55	27	24	1160
56	27	25	1161
57	27	26	1162
58	27	27	1163
59	27	28	1164
60	27	29	1165
61	27	30	1166
62	27	31	1167
63	27	32	1168
64	27	33	1169
65	27	34	1170
66	27	35	1171
67	27	36	1172
68	27	37	1173
69	27	38	1174
70	27	39	1175
71	27	40	1176
72	27	41	1177
73	27	42	1178
74	27	43	1179
75	27	44	1180
76	27	45	1181
77	27	46	1182
78	27	47	1183
79	27	48	1184
80	27	49	1185
81	27	50	1186
82	27	51	1187
83	27	52	1188
84	27	53	1189
85	27	54	1190
86	27	55	1191
87	27	56	1192
88	27	57	1193
89	27	58	1194
90	27	59	1195
91	27	60	1196
92	27	61	1197
93	27	62	1198
94	27	63	1199
95	27	64	1200
96	27	65	1201
97	27	66	1202
98	27	67	1203
99	27	68	1204
100	27	69	1205
101	27	70	1206
102	27	71	1207
103	27	72	1208
104	27	73	1209
105	27	74	1210
106	27	75	1211
107	27	76	1212
108	27	77	1213
109	27	78	1214
110	27	79	1215
111	27	80	1216
112	27	81	1217
113	27	82	1218
114	27	83	1219
115	27	84	1220
116	27	85	1221
117	27	86	1222
118	27	87	1223
119	27	88	1224
120	27	89	1225
121	27	90	1226
122	27	91	1227
123	27	92	1228
124	27	93	1229
125	27	94	1230
126	27	95	1231
127	27	96	1232
128	27	97	1233
129	27	98	1234
130	27	99	1235
131	27	100	1236
132	27	101	1237
133	27	102	1238
134	27	103	1239
135	27	104	1240
136	27	105	1241
137	27	106	1242
138	27	107	1243
139	27	108	1244
140	27	109	1245
141	27	110	1246
142	27	111	1247
143	27	112	1248
144	27	113	1249
145	27	114	1250
146	27	115	1251
147	27	116	1252
148	27	117	1253
149	27	118	1254
150	27	119	1255
151	27	120	1256
152	27	121	1257
153	27	122	1258
154	27	123	1259
155	27	124	1260
156	27	125	1261
157	27	126	1262
158	27	127	1263
159	27	128	1264
160	27	129	1265
161	27	130	1266
162	27	131	1267
163	27	132	1268
164	27	133	1269
165	27	134	1270
166	27	135	1271
167	27	136	1272
168	27	137	1273
169	27	138	1274
170	27	139	1275
171	27	140	1276
172	27	141	1277
173	27	142	1278
174	27	143	1279
175	27	144	1280
176	27	145	1281
177	27	146	1282
178	27	147	1283
179	27	148	1284
180	27	149	1285
181	27	150	1286
182	27	151	1287
183	27	152	1288
184	27	153	1289
185	27	154	1290
186	27	155	1291
187	27	156	1292
188	27	157	1293
189	27	158	1294
190	27	159	1295
191	27	160	1296
192	27	161	1297
193	27	162	1298
194	27	163	1299
195	27	164	1300
196	27	165	1301
197	27	166	1302
198	27	167	1303
199	27	168	1304
200	27	169	1305
201	27	170	1306
202	27	171	1307
203	27	172	1308
204	27	173	1309
205	27	174	1310
206	27	175	1311
207	27	176	1312
208	27	177	1313
209	27	178	1314
210	27	179	1315
211	27	180	1316
212	27	181	1317
213	27	182	1318
214	27	183	1319
215	27	184	1320
216	27	185	1321
217	27	186	1322
218	27	187	1323
219	27	188	1324
220	27	189	1325
221	27	190	1326
222	27	191	1327
223	27	192	1328
224	27	193	1329
225	27	194	1330
226	27	195	1331
227	27	196	1332
228	27	197	1333
229	27	198	1334
230	27	199	1335
231	27	200	1336
232	27	201	1337
233	27	202	1338
234	27	203	1339
235	27	204	1340
236	27	205	1341
237	27	206	1342
238	27	207	1343
239	27	208	1344
240	27	209	1345
241	27	210	1346
242	27	211	1347
243	27	212	1348
244	27	213	1349
245	27	214	1350
246	27	215	1351
247	27	216	1352
248	27	217	1353
249	27	218	1354
250	27	219	1355
251	27	220	1356
252	27	221	1357
253	27	222	1358
254	27	223	1359
255	27	224	1360
256	27	225	1361
257	27	226	1362
258	27	227	1363
259	27	228	1364
260	29	1	1137
261	29	2	1138
262	29	3	1139
263	29	4	1140
264	29	5	1141
265	29	6	1142
266	29	7	1143
267	29	8	1144
268	29	9	1145
269	29	10	1146
270	29	11	1147
271	29	12	1148
272	29	13	1149
273	29	14	1150
274	29	15	1151
275	29	16	1152
276	29	17	1153
277	29	18	1154
278	29	19	1155
279	29	20	1156
280	29	21	1157
281	29	22	1158
282	29	23	1159
283	29	24	1160
284	29	25	1161
285	29	26	1162
286	29	27	1163
287	29	28	1164
288	29	29	1165
289	29	30	1166
290	29	31	1167
291	29	32	1168
292	29	33	1169
293	29	34	1170
294	29	35	1171
295	29	36	1172
296	29	37	1173
297	29	38	1174
298	29	39	1175
299	29	40	1176
300	29	41	1177
301	29	42	1178
302	29	43	1179
303	29	44	1180
304	29	45	1181
305	29	46	1182
306	29	47	1183
307	29	48	1184
308	29	49	1185
309	29	50	1186
310	29	51	1187
311	29	52	1188
312	29	53	1189
313	29	54	1190
314	29	55	1191
315	29	56	1192
316	29	57	1193
317	29	58	1194
318	29	59	1195
319	29	60	1196
320	29	61	1197
321	29	62	1198
322	29	63	1199
323	29	64	1200
324	29	65	1201
325	29	66	1202
326	29	67	1203
327	29	68	1204
328	29	69	1205
329	29	70	1206
330	29	71	1207
331	29	72	1208
332	29	73	1209
333	29	74	1210
334	29	75	1211
335	29	76	1212
336	29	77	1213
337	29	78	1214
338	29	79	1215
339	29	80	1216
340	29	81	1217
341	29	82	1218
342	29	83	1219
343	29	84	1220
344	29	85	1221
345	29	86	1222
346	29	87	1223
347	29	88	1224
348	29	89	1225
349	29	90	1226
350	29	91	1227
351	29	92	1228
352	29	93	1229
353	29	94	1230
354	29	95	1231
355	29	96	1232
356	29	97	1233
357	29	98	1234
358	29	99	1235
359	29	100	1236
360	29	101	1237
361	29	102	1238
362	29	103	1239
363	29	104	1240
364	29	105	1241
365	29	106	1242
366	29	107	1243
367	29	108	1244
368	29	109	1245
369	29	110	1246
370	29	111	1247
371	29	112	1248
372	29	113	1249
373	29	114	1250
374	29	115	1251
375	29	116	1252
376	29	117	1253
377	29	118	1254
378	29	119	1255
379	29	120	1256
380	29	121	1257
381	29	122	1258
382	29	123	1259
383	29	124	1260
384	29	125	1261
385	29	126	1262
386	29	127	1263
387	29	128	1264
388	29	129	1265
389	29	130	1266
390	29	131	1267
391	29	132	1268
392	29	133	1269
393	29	134	1270
394	29	135	1271
395	29	136	1272
396	29	137	1273
397	29	138	1274
398	29	139	1275
399	29	140	1276
400	29	141	1277
401	29	142	1278
402	29	143	1279
403	29	144	1280
404	29	145	1281
405	29	146	1282
406	29	147	1283
407	29	148	1284
408	29	149	1285
409	29	150	1286
410	29	151	1287
411	29	152	1288
412	29	153	1289
413	29	154	1290
414	29	155	1291
415	29	156	1292
416	29	157	1293
417	29	158	1294
418	29	159	1295
419	29	160	1296
420	29	161	1297
421	29	162	1298
422	29	163	1299
423	29	164	1300
424	29	165	1301
425	29	166	1302
426	29	167	1303
427	29	168	1304
428	29	169	1305
429	29	170	1306
430	29	171	1307
431	29	172	1308
432	29	173	1309
433	29	174	1310
434	29	175	1311
435	29	176	1312
436	29	177	1313
437	29	178	1314
438	29	179	1315
439	29	180	1316
440	29	181	1317
441	29	182	1318
442	29	183	1319
443	29	184	1320
444	29	185	1321
445	29	186	1322
446	29	187	1323
447	29	188	1324
448	29	189	1325
449	29	190	1326
450	29	191	1327
451	29	192	1328
452	29	193	1329
453	29	194	1330
454	29	195	1331
455	29	196	1332
456	29	197	1333
457	29	198	1334
458	29	199	1335
459	29	200	1336
460	29	201	1337
461	29	202	1338
462	29	203	1339
463	29	204	1340
464	29	205	1341
465	29	206	1342
466	29	207	1343
467	29	208	1344
468	29	209	1345
469	29	210	1346
470	29	211	1347
471	29	212	1348
472	29	213	1349
473	29	214	1350
474	29	215	1351
475	29	216	1352
476	29	217	1353
477	29	218	1354
478	29	219	1355
479	29	220	1356
480	29	221	1357
481	29	222	1358
482	29	223	1359
483	29	224	1360
484	29	225	1361
485	29	226	1362
486	29	227	1363
487	29	228	1364
488	31	1	1137
489	31	2	1138
490	31	3	1139
491	31	4	1140
492	31	5	1141
493	31	6	1142
494	31	7	1143
495	31	8	1144
496	31	9	1145
497	31	10	1146
498	31	11	1147
499	31	12	1148
500	31	13	1149
501	31	14	1150
502	31	15	1151
503	31	16	1152
504	31	17	1153
505	31	18	1154
506	31	19	1155
507	31	20	1156
508	31	21	1157
509	31	22	1158
510	31	23	1159
511	31	24	1160
512	31	25	1161
513	31	26	1162
514	31	27	1163
515	31	28	1164
516	31	29	1165
517	31	30	1166
518	31	31	1167
519	31	32	1168
520	31	33	1169
521	31	34	1170
522	31	35	1171
523	31	36	1172
524	31	37	1173
525	31	38	1174
526	31	39	1175
527	31	40	1176
528	31	41	1177
529	31	42	1178
530	31	43	1179
531	31	44	1180
532	31	45	1181
533	31	46	1182
534	31	47	1183
535	31	48	1184
536	31	49	1185
537	31	50	1186
538	31	51	1187
539	31	52	1188
540	31	53	1189
541	31	54	1190
542	31	55	1191
543	31	56	1192
544	31	57	1193
545	31	58	1194
546	31	59	1195
547	31	60	1196
548	31	61	1197
549	31	62	1198
550	31	63	1199
551	31	64	1200
552	31	65	1201
553	31	66	1202
554	31	67	1203
555	31	68	1204
556	31	69	1205
557	31	70	1206
558	31	71	1207
559	31	72	1208
560	31	73	1209
561	31	74	1210
562	31	75	1211
563	31	76	1212
564	31	77	1213
565	31	78	1214
566	31	79	1215
567	31	80	1216
568	31	81	1217
569	31	82	1218
570	31	83	1219
571	31	84	1220
572	31	85	1221
573	31	86	1222
574	31	87	1223
575	31	88	1224
576	31	89	1225
577	31	90	1226
578	31	91	1227
579	31	92	1228
580	31	93	1229
581	31	94	1230
582	31	95	1231
583	31	96	1232
584	31	97	1233
585	31	98	1234
586	31	99	1235
587	31	100	1236
588	31	101	1237
589	31	102	1238
590	31	103	1239
591	31	104	1240
592	31	105	1241
593	31	106	1242
594	31	107	1243
595	31	108	1244
596	31	109	1245
597	31	110	1246
598	31	111	1247
599	31	112	1248
600	31	113	1249
601	31	114	1250
602	31	115	1251
603	31	116	1252
604	31	117	1253
605	31	118	1254
606	31	119	1255
607	31	120	1256
608	31	121	1257
609	31	122	1258
610	31	123	1259
611	31	124	1260
612	31	125	1261
613	31	126	1262
614	31	127	1263
615	31	128	1264
616	31	129	1265
617	31	130	1266
618	31	131	1267
619	31	132	1268
620	31	133	1269
621	31	134	1270
622	31	135	1271
623	31	136	1272
624	31	137	1273
625	31	138	1274
626	31	139	1275
627	31	140	1276
628	31	141	1277
629	31	142	1278
630	31	143	1279
631	31	144	1280
632	31	145	1281
633	31	146	1282
634	31	147	1283
635	31	148	1284
636	31	149	1285
637	31	150	1286
638	31	151	1287
639	31	152	1288
640	31	153	1289
641	31	154	1290
642	31	155	1291
643	31	156	1292
644	31	157	1293
645	31	158	1294
646	31	159	1295
647	31	160	1296
648	31	161	1297
649	31	162	1298
650	31	163	1299
651	31	164	1300
652	31	165	1301
653	31	166	1302
654	31	167	1303
655	31	168	1304
656	31	169	1305
657	31	170	1306
658	31	171	1307
659	31	172	1308
660	31	173	1309
661	31	174	1310
662	31	175	1311
663	31	176	1312
664	31	177	1313
665	31	178	1314
666	31	179	1315
667	31	180	1316
668	31	181	1317
669	31	182	1318
670	31	183	1319
671	31	184	1320
672	31	185	1321
673	31	186	1322
674	31	187	1323
675	31	188	1324
676	31	189	1325
677	31	190	1326
678	31	191	1327
679	31	192	1328
680	31	193	1329
681	31	194	1330
682	31	195	1331
683	31	196	1332
684	31	197	1333
685	31	198	1334
686	31	199	1335
687	31	200	1336
688	31	201	1337
689	31	202	1338
690	31	203	1339
691	31	204	1340
692	31	205	1341
693	31	206	1342
694	31	207	1343
695	31	208	1344
696	31	209	1345
697	31	210	1346
698	31	211	1347
699	31	212	1348
700	31	213	1349
701	31	214	1350
702	31	215	1351
703	31	216	1352
704	31	217	1353
705	31	218	1354
706	31	219	1355
707	31	220	1356
708	31	221	1357
709	31	222	1358
710	31	223	1359
711	31	224	1360
712	31	225	1361
713	31	226	1362
714	31	227	1363
715	31	228	1364
716	33	1	1137
717	33	2	1138
718	33	3	1139
719	33	4	1140
720	33	5	1141
721	33	6	1142
722	33	7	1143
723	33	8	1144
724	33	9	1145
725	33	10	1146
726	33	11	1147
727	33	12	1148
728	33	13	1149
729	33	14	1150
730	33	15	1151
731	33	16	1152
732	33	17	1153
733	33	18	1154
734	33	19	1155
735	33	20	1156
736	33	21	1157
737	33	22	1158
738	33	23	1159
739	33	24	1160
740	33	25	1161
741	33	26	1162
742	33	27	1163
743	33	28	1164
744	33	29	1165
745	33	30	1166
746	33	31	1167
747	33	32	1168
748	33	33	1169
749	33	34	1170
750	33	35	1171
751	33	36	1172
752	33	37	1173
753	33	38	1174
754	33	39	1175
755	33	40	1176
756	33	41	1177
757	33	42	1178
758	33	43	1179
759	33	44	1180
760	33	45	1181
761	33	46	1182
762	33	47	1183
763	33	48	1184
764	33	49	1185
765	33	50	1186
766	33	51	1187
767	33	52	1188
768	33	53	1189
769	33	54	1190
770	33	55	1191
771	33	56	1192
772	33	57	1193
773	33	58	1194
774	33	59	1195
775	33	60	1196
776	33	61	1197
777	33	62	1198
778	33	63	1199
779	33	64	1200
780	33	65	1201
781	33	66	1202
782	33	67	1203
783	33	68	1204
784	33	69	1205
785	33	70	1206
786	33	71	1207
787	33	72	1208
788	33	73	1209
789	33	74	1210
790	33	75	1211
791	33	76	1212
792	33	77	1213
793	33	78	1214
794	33	79	1215
795	33	80	1216
796	33	81	1217
797	33	82	1218
798	33	83	1219
799	33	84	1220
800	33	85	1221
801	33	86	1222
802	33	87	1223
803	33	88	1224
804	33	89	1225
805	33	90	1226
806	33	91	1227
807	33	92	1228
808	33	93	1229
809	33	94	1230
810	33	95	1231
811	33	96	1232
812	33	97	1233
813	33	98	1234
814	33	99	1235
815	33	100	1236
816	33	101	1237
817	33	102	1238
818	33	103	1239
819	33	104	1240
820	33	105	1241
821	33	106	1242
822	33	107	1243
823	33	108	1244
824	33	109	1245
825	33	110	1246
826	33	111	1247
827	33	112	1248
828	33	113	1249
829	33	114	1250
830	33	115	1251
831	33	116	1252
832	33	117	1253
833	33	118	1254
834	33	119	1255
835	33	120	1256
836	33	121	1257
837	33	122	1258
838	33	123	1259
839	33	124	1260
840	33	125	1261
841	33	126	1262
842	33	127	1263
843	33	128	1264
844	33	129	1265
845	33	130	1266
846	33	131	1267
847	33	132	1268
848	33	133	1269
849	33	134	1270
850	33	135	1271
851	33	136	1272
852	33	137	1273
853	33	138	1274
854	33	139	1275
855	33	140	1276
856	33	141	1277
857	33	142	1278
858	33	143	1279
859	33	144	1280
860	33	145	1281
861	33	146	1282
862	33	147	1283
863	33	148	1284
864	33	149	1285
865	33	150	1286
866	33	151	1287
867	33	152	1288
868	33	153	1289
869	33	154	1290
870	33	155	1291
871	33	156	1292
872	33	157	1293
873	33	158	1294
874	33	159	1295
875	33	160	1296
876	33	161	1297
877	33	162	1298
878	33	163	1299
879	33	164	1300
880	33	165	1301
881	33	166	1302
882	33	167	1303
883	33	168	1304
884	33	169	1305
885	33	170	1306
886	33	171	1307
887	33	172	1308
888	33	173	1309
889	33	174	1310
890	33	175	1311
891	33	176	1312
892	33	177	1313
893	33	178	1314
894	33	179	1315
895	33	180	1316
896	33	181	1317
897	33	182	1318
898	33	183	1319
899	33	184	1320
900	33	185	1321
901	33	186	1322
902	33	187	1323
903	33	188	1324
904	33	189	1325
905	33	190	1326
906	33	191	1327
907	33	192	1328
908	33	193	1329
909	33	194	1330
910	33	195	1331
911	33	196	1332
912	33	197	1333
913	33	198	1334
914	33	199	1335
915	33	200	1336
916	33	201	1337
917	33	202	1338
918	33	203	1339
919	33	204	1340
920	33	205	1341
921	33	206	1342
922	33	207	1343
923	33	208	1344
924	33	209	1345
925	33	210	1346
926	33	211	1347
927	33	212	1348
928	33	213	1349
929	33	214	1350
930	33	215	1351
931	33	216	1352
932	33	217	1353
933	33	218	1354
934	33	219	1355
935	33	220	1356
936	33	221	1357
937	33	222	1358
938	33	223	1359
939	33	224	1360
940	33	225	1361
941	33	226	1362
942	33	227	1363
943	33	228	1364
944	37	1	1143
945	37	2	1144
946	37	3	1148
947	37	4	1149
948	37	5	1155
949	37	6	1158
950	37	7	1162
951	37	8	1167
952	37	9	1170
953	37	10	1172
954	37	11	1174
955	37	12	1176
956	37	13	1178
957	37	14	1179
958	37	15	1180
959	37	16	1182
960	37	17	1186
961	37	18	1187
962	37	19	1193
963	37	20	1195
964	37	21	1196
965	37	22	1197
966	37	23	1200
967	37	24	1203
968	37	25	1204
969	37	26	1208
970	37	27	1211
971	37	28	1212
972	37	29	1213
973	37	30	1214
974	37	31	1220
975	37	32	1223
976	37	33	1225
977	37	34	1230
978	37	35	1231
979	37	36	1236
980	37	37	1237
981	37	38	1238
982	37	39	1243
983	37	40	1246
984	37	41	1250
985	37	42	1251
986	37	43	1258
987	37	44	1259
988	37	45	1265
989	37	46	1266
990	37	47	1267
991	37	48	1270
992	37	49	1272
993	37	50	1273
994	37	51	1277
995	37	52	1280
996	37	53	1282
997	37	54	1286
998	37	55	1289
999	37	56	1290
1000	37	57	1293
1001	37	58	1296
1002	37	59	1297
1003	37	60	1298
1004	37	61	1302
1005	37	62	1303
1006	37	63	1308
1007	37	64	1310
1008	37	65	1312
1009	37	66	1314
1010	37	67	1315
1011	37	68	1316
1012	37	69	1319
1013	37	70	1320
1014	37	71	1321
1015	37	72	1322
1016	37	73	1323
1017	37	74	1333
1018	37	75	1335
1019	37	76	1337
1020	37	77	1339
1021	37	78	1340
1022	37	79	1341
1023	37	80	1343
1024	37	81	1344
1025	37	82	1346
1026	37	83	1347
1027	37	84	1350
1028	37	85	1353
1029	37	86	1355
1030	37	87	1356
1031	37	88	1358
1032	37	89	1362
1033	37	90	1364
1034	35	1	1137
1035	35	2	1138
1036	35	3	1139
1037	35	4	1140
1038	35	5	1141
1039	35	6	1142
1040	35	7	1145
1041	35	8	1146
1042	35	9	1147
1043	35	10	1150
1044	35	11	1151
1045	35	12	1152
1046	35	13	1153
1047	35	14	1154
1048	35	15	1156
1049	35	16	1157
1050	35	17	1159
1051	35	18	1160
1052	35	19	1161
1053	35	20	1163
1054	35	21	1164
1055	35	22	1165
1056	35	23	1166
1057	35	24	1168
1058	35	25	1169
1059	35	26	1171
1060	35	27	1173
1061	35	28	1175
1062	35	29	1177
1063	35	30	1181
1064	35	31	1183
1065	35	32	1184
1066	35	33	1185
1067	35	34	1188
1068	35	35	1189
1069	35	36	1190
1070	35	37	1191
1071	35	38	1192
1072	35	39	1194
1073	35	40	1198
1074	35	41	1199
1075	35	42	1201
1076	35	43	1202
1077	35	44	1205
1078	35	45	1206
1079	35	46	1207
1080	35	47	1209
1081	35	48	1210
1082	35	49	1215
1083	35	50	1216
1084	35	51	1217
1085	35	52	1218
1086	35	53	1219
1087	35	54	1221
1088	35	55	1222
1089	35	56	1224
1090	35	57	1226
1091	35	58	1227
1092	35	59	1228
1093	35	60	1229
1094	35	61	1232
1095	35	62	1233
1096	35	63	1234
1097	35	64	1235
1098	35	65	1239
1099	35	66	1240
1100	35	67	1241
1101	35	68	1242
1102	35	69	1244
1103	35	70	1245
1104	35	71	1247
1105	35	72	1248
1106	35	73	1249
1107	35	74	1252
1108	35	75	1253
1109	35	76	1254
1110	35	77	1255
1111	35	78	1256
1112	35	79	1257
1113	35	80	1260
1114	35	81	1261
1115	35	82	1262
1116	35	83	1263
1117	35	84	1264
1118	35	85	1268
1119	35	86	1269
1120	35	87	1271
1121	35	88	1274
1122	35	89	1275
1123	35	90	1276
1124	35	91	1278
1125	35	92	1279
1126	35	93	1281
1127	35	94	1283
1128	35	95	1284
1129	35	96	1285
1130	35	97	1287
1131	35	98	1288
1132	35	99	1291
1133	35	100	1292
1134	35	101	1294
1135	35	102	1295
1136	35	103	1299
1137	35	104	1300
1138	35	105	1301
1139	35	106	1304
1140	35	107	1305
1141	35	108	1306
1142	35	109	1307
1143	35	110	1309
1144	35	111	1311
1145	35	112	1313
1146	35	113	1317
1147	35	114	1318
1148	35	115	1324
1149	35	116	1325
1150	35	117	1326
1151	35	118	1327
1152	35	119	1328
1153	35	120	1329
1154	35	121	1330
1155	35	122	1331
1156	35	123	1332
1157	35	124	1334
1158	35	125	1336
1159	35	126	1338
1160	35	127	1342
1161	35	128	1345
1162	35	129	1348
1163	35	130	1349
1164	35	131	1351
1165	35	132	1352
1166	35	133	1354
1167	35	134	1357
1168	35	135	1359
1169	35	136	1360
1170	35	137	1361
1171	35	138	1363
\.


--
-- Data for Name: qt_pdo_query_master; Type: TABLE DATA; Schema: i2b2demodata; Owner: postgres
--

COPY i2b2demodata.qt_pdo_query_master (query_master_id, user_id, group_id, create_date, request_xml, i2b2_request_xml) FROM stdin;
-1	demo	Demo	2022-03-04 22:19:51.786	xml-request	\N
1	demo	Demo	2022-05-02 12:02:04.057	<msgns:request xmlns:msgns="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:pdons="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ontns="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:crcpdons="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/" xmlns:crcpsmns="http://www.i2b2.org/xsd/cell/crc/psm/1.1/">\n      <message_header>\n          <i2b2_version_compatible>0.3</i2b2_version_compatible>\n          <hl7_version_compatible>2.4</hl7_version_compatible>\n          <sending_application>\n              <application_name>GeCo i2b2 Data Source</application_name>\n              <application_version>0.2</application_version>\n          </sending_application>\n          <sending_facility>\n              <facility_name>GeCo</facility_name>\n          </sending_facility>\n          <receiving_application>\n              <application_name>i2b2 cell</application_name>\n              <application_version>1.7</application_version>\n          </receiving_application>\n          <receiving_facility>\n              <facility_name>i2b2 hive</facility_name>\n          </receiving_facility>\n          <datetime_of_message>2022-05-02T14:02:03+02:00</datetime_of_message>\n          <security>\n              <domain>i2b2demo</domain>\n              <username>demo</username>\n              <password>*********</password>\n          </security>\n          <message_type>\n              <message_code>EQQ</message_code>\n              <event_type>Q04</event_type>\n              <message_structure>EQQ_Q04</message_structure>\n          </message_type>\n          <message_control_id>\n              <session_id>2022-05-02T14:02:03+02:00</session_id>\n              <message_num>1651492923</message_num>\n              <instance_num>0</instance_num>\n          </message_control_id>\n          <processing_id>\n              <processing_id>P</processing_id>\n              <processing_mode>I</processing_mode>\n          </processing_id>\n          <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n          <application_acknowledgement_type/>\n          <country_code>CH</country_code>\n          <project_id>Demo</project_id>\n      </message_header>\n      <request_header>\n          <result_waittime_ms>10000</result_waittime_ms>\n      </request_header>\n      <message_body>\n          <crcpdons:pdoheader>\n              <patient_set_limit>0</patient_set_limit>\n              <estimated_time>0</estimated_time>\n              <request_type>getPDO_fromInputList</request_type>\n          </crcpdons:pdoheader>\n          <crcpdons:request xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="crcpdons:GetPDOFromInputList_requestType">\n              <input_list>\n                  <patient_list max="1000000" min="0">\n                      <patient_set_coll_id>1</patient_set_coll_id>\n                  </patient_list>\n              </input_list>\n              <output_option name="none">\n                  <patient_set select="using_input_list" onlykeys="false" blob="false" techdata="false"/>\n              </output_option>\n          </crcpdons:request>\n      </message_body>\n  </msgns:request>	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns5:request xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <message_header>\n        <i2b2_version_compatible>0.3</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>GeCo i2b2 Data Source</application_name>\n            <application_version>0.2</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>GeCo</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>i2b2 cell</application_name>\n            <application_version>1.7</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-05-02T14:02:03+02:00</datetime_of_message>\n        <security>\n            <domain>i2b2demo</domain>\n            <username>demo</username>\n            <password is_token="false">password not stored</password>\n        </security>\n        <message_type>\n            <message_code>EQQ</message_code>\n            <event_type>Q04</event_type>\n            <message_structure>EQQ_Q04</message_structure>\n        </message_type>\n        <message_control_id>\n            <session_id>2022-05-02T14:02:03+02:00</session_id>\n            <message_num>1651492923</message_num>\n            <instance_num>0</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n        <application_acknowledgement_type></application_acknowledgement_type>\n        <country_code>CH</country_code>\n        <project_id>Demo</project_id>\n    </message_header>\n    <request_header>\n        <result_waittime_ms>10000</result_waittime_ms>\n    </request_header>\n    <message_body>\n        <ns3:pdoheader>\n            <patient_set_limit>0</patient_set_limit>\n            <estimated_time>0</estimated_time>\n            <request_type>getPDO_fromInputList</request_type>\n        </ns3:pdoheader>\n        <ns3:request xsi:type="ns3:GetPDOFromInputList_requestType" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">\n            <input_list>\n                <patient_list min="0" max="1000000">\n                    <patient_set_coll_id>1</patient_set_coll_id>\n                </patient_list>\n            </input_list>\n            <output_option>\n                <patient_set onlykeys="false" blob="false" techdata="false" select="using_input_list"/>\n            </output_option>\n        </ns3:request>\n    </message_body>\n</ns5:request>\n
2	demo	Demo	2022-05-02 12:02:05.292	<msgns:request xmlns:msgns="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:pdons="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ontns="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:crcpdons="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/" xmlns:crcpsmns="http://www.i2b2.org/xsd/cell/crc/psm/1.1/">\n      <message_header>\n          <i2b2_version_compatible>0.3</i2b2_version_compatible>\n          <hl7_version_compatible>2.4</hl7_version_compatible>\n          <sending_application>\n              <application_name>GeCo i2b2 Data Source</application_name>\n              <application_version>0.2</application_version>\n          </sending_application>\n          <sending_facility>\n              <facility_name>GeCo</facility_name>\n          </sending_facility>\n          <receiving_application>\n              <application_name>i2b2 cell</application_name>\n              <application_version>1.7</application_version>\n          </receiving_application>\n          <receiving_facility>\n              <facility_name>i2b2 hive</facility_name>\n          </receiving_facility>\n          <datetime_of_message>2022-05-02T14:02:05+02:00</datetime_of_message>\n          <security>\n              <domain>i2b2demo</domain>\n              <username>demo</username>\n              <password>*********</password>\n          </security>\n          <message_type>\n              <message_code>EQQ</message_code>\n              <event_type>Q04</event_type>\n              <message_structure>EQQ_Q04</message_structure>\n          </message_type>\n          <message_control_id>\n              <session_id>2022-05-02T14:02:05+02:00</session_id>\n              <message_num>1651492925</message_num>\n              <instance_num>0</instance_num>\n          </message_control_id>\n          <processing_id>\n              <processing_id>P</processing_id>\n              <processing_mode>I</processing_mode>\n          </processing_id>\n          <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n          <application_acknowledgement_type/>\n          <country_code>CH</country_code>\n          <project_id>Demo</project_id>\n      </message_header>\n      <request_header>\n          <result_waittime_ms>10000</result_waittime_ms>\n      </request_header>\n      <message_body>\n          <crcpdons:pdoheader>\n              <patient_set_limit>0</patient_set_limit>\n              <estimated_time>0</estimated_time>\n              <request_type>getPDO_fromInputList</request_type>\n          </crcpdons:pdoheader>\n          <crcpdons:request xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="crcpdons:GetPDOFromInputList_requestType">\n              <input_list>\n                  <patient_list max="1000000" min="0">\n                      <patient_set_coll_id>3</patient_set_coll_id>\n                  </patient_list>\n              </input_list>\n              <output_option name="none">\n                  <patient_set select="using_input_list" onlykeys="false" blob="false" techdata="false"/>\n              </output_option>\n          </crcpdons:request>\n      </message_body>\n  </msgns:request>	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns5:request xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <message_header>\n        <i2b2_version_compatible>0.3</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>GeCo i2b2 Data Source</application_name>\n            <application_version>0.2</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>GeCo</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>i2b2 cell</application_name>\n            <application_version>1.7</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-05-02T14:02:05+02:00</datetime_of_message>\n        <security>\n            <domain>i2b2demo</domain>\n            <username>demo</username>\n            <password is_token="false">password not stored</password>\n        </security>\n        <message_type>\n            <message_code>EQQ</message_code>\n            <event_type>Q04</event_type>\n            <message_structure>EQQ_Q04</message_structure>\n        </message_type>\n        <message_control_id>\n            <session_id>2022-05-02T14:02:05+02:00</session_id>\n            <message_num>1651492925</message_num>\n            <instance_num>0</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n        <application_acknowledgement_type></application_acknowledgement_type>\n        <country_code>CH</country_code>\n        <project_id>Demo</project_id>\n    </message_header>\n    <request_header>\n        <result_waittime_ms>10000</result_waittime_ms>\n    </request_header>\n    <message_body>\n        <ns3:pdoheader>\n            <patient_set_limit>0</patient_set_limit>\n            <estimated_time>0</estimated_time>\n            <request_type>getPDO_fromInputList</request_type>\n        </ns3:pdoheader>\n        <ns3:request xsi:type="ns3:GetPDOFromInputList_requestType" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">\n            <input_list>\n                <patient_list min="0" max="1000000">\n                    <patient_set_coll_id>3</patient_set_coll_id>\n                </patient_list>\n            </input_list>\n            <output_option>\n                <patient_set onlykeys="false" blob="false" techdata="false" select="using_input_list"/>\n            </output_option>\n        </ns3:request>\n    </message_body>\n</ns5:request>\n
3	demo	Demo	2022-05-02 12:02:05.671	<msgns:request xmlns:msgns="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:pdons="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ontns="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:crcpdons="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/" xmlns:crcpsmns="http://www.i2b2.org/xsd/cell/crc/psm/1.1/">\n      <message_header>\n          <i2b2_version_compatible>0.3</i2b2_version_compatible>\n          <hl7_version_compatible>2.4</hl7_version_compatible>\n          <sending_application>\n              <application_name>GeCo i2b2 Data Source</application_name>\n              <application_version>0.2</application_version>\n          </sending_application>\n          <sending_facility>\n              <facility_name>GeCo</facility_name>\n          </sending_facility>\n          <receiving_application>\n              <application_name>i2b2 cell</application_name>\n              <application_version>1.7</application_version>\n          </receiving_application>\n          <receiving_facility>\n              <facility_name>i2b2 hive</facility_name>\n          </receiving_facility>\n          <datetime_of_message>2022-05-02T14:02:05+02:00</datetime_of_message>\n          <security>\n              <domain>i2b2demo</domain>\n              <username>demo</username>\n              <password>*********</password>\n          </security>\n          <message_type>\n              <message_code>EQQ</message_code>\n              <event_type>Q04</event_type>\n              <message_structure>EQQ_Q04</message_structure>\n          </message_type>\n          <message_control_id>\n              <session_id>2022-05-02T14:02:05+02:00</session_id>\n              <message_num>1651492925</message_num>\n              <instance_num>0</instance_num>\n          </message_control_id>\n          <processing_id>\n              <processing_id>P</processing_id>\n              <processing_mode>I</processing_mode>\n          </processing_id>\n          <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n          <application_acknowledgement_type/>\n          <country_code>CH</country_code>\n          <project_id>Demo</project_id>\n      </message_header>\n      <request_header>\n          <result_waittime_ms>10000</result_waittime_ms>\n      </request_header>\n      <message_body>\n          <crcpdons:pdoheader>\n              <patient_set_limit>0</patient_set_limit>\n              <estimated_time>0</estimated_time>\n              <request_type>getPDO_fromInputList</request_type>\n          </crcpdons:pdoheader>\n          <crcpdons:request xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="crcpdons:GetPDOFromInputList_requestType">\n              <input_list>\n                  <patient_list max="1000000" min="0">\n                      <patient_set_coll_id>5</patient_set_coll_id>\n                  </patient_list>\n              </input_list>\n              <output_option name="none">\n                  <patient_set select="using_input_list" onlykeys="false" blob="false" techdata="false"/>\n              </output_option>\n          </crcpdons:request>\n      </message_body>\n  </msgns:request>	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns5:request xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <message_header>\n        <i2b2_version_compatible>0.3</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>GeCo i2b2 Data Source</application_name>\n            <application_version>0.2</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>GeCo</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>i2b2 cell</application_name>\n            <application_version>1.7</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-05-02T14:02:05+02:00</datetime_of_message>\n        <security>\n            <domain>i2b2demo</domain>\n            <username>demo</username>\n            <password is_token="false">password not stored</password>\n        </security>\n        <message_type>\n            <message_code>EQQ</message_code>\n            <event_type>Q04</event_type>\n            <message_structure>EQQ_Q04</message_structure>\n        </message_type>\n        <message_control_id>\n            <session_id>2022-05-02T14:02:05+02:00</session_id>\n            <message_num>1651492925</message_num>\n            <instance_num>0</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n        <application_acknowledgement_type></application_acknowledgement_type>\n        <country_code>CH</country_code>\n        <project_id>Demo</project_id>\n    </message_header>\n    <request_header>\n        <result_waittime_ms>10000</result_waittime_ms>\n    </request_header>\n    <message_body>\n        <ns3:pdoheader>\n            <patient_set_limit>0</patient_set_limit>\n            <estimated_time>0</estimated_time>\n            <request_type>getPDO_fromInputList</request_type>\n        </ns3:pdoheader>\n        <ns3:request xsi:type="ns3:GetPDOFromInputList_requestType" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">\n            <input_list>\n                <patient_list min="0" max="1000000">\n                    <patient_set_coll_id>5</patient_set_coll_id>\n                </patient_list>\n            </input_list>\n            <output_option>\n                <patient_set onlykeys="false" blob="false" techdata="false" select="using_input_list"/>\n            </output_option>\n        </ns3:request>\n    </message_body>\n</ns5:request>\n
4	demo	Demo	2022-05-02 12:02:05.981	<msgns:request xmlns:msgns="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:pdons="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ontns="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:crcpdons="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/" xmlns:crcpsmns="http://www.i2b2.org/xsd/cell/crc/psm/1.1/">\n      <message_header>\n          <i2b2_version_compatible>0.3</i2b2_version_compatible>\n          <hl7_version_compatible>2.4</hl7_version_compatible>\n          <sending_application>\n              <application_name>GeCo i2b2 Data Source</application_name>\n              <application_version>0.2</application_version>\n          </sending_application>\n          <sending_facility>\n              <facility_name>GeCo</facility_name>\n          </sending_facility>\n          <receiving_application>\n              <application_name>i2b2 cell</application_name>\n              <application_version>1.7</application_version>\n          </receiving_application>\n          <receiving_facility>\n              <facility_name>i2b2 hive</facility_name>\n          </receiving_facility>\n          <datetime_of_message>2022-05-02T14:02:05+02:00</datetime_of_message>\n          <security>\n              <domain>i2b2demo</domain>\n              <username>demo</username>\n              <password>*********</password>\n          </security>\n          <message_type>\n              <message_code>EQQ</message_code>\n              <event_type>Q04</event_type>\n              <message_structure>EQQ_Q04</message_structure>\n          </message_type>\n          <message_control_id>\n              <session_id>2022-05-02T14:02:05+02:00</session_id>\n              <message_num>1651492925</message_num>\n              <instance_num>0</instance_num>\n          </message_control_id>\n          <processing_id>\n              <processing_id>P</processing_id>\n              <processing_mode>I</processing_mode>\n          </processing_id>\n          <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n          <application_acknowledgement_type/>\n          <country_code>CH</country_code>\n          <project_id>Demo</project_id>\n      </message_header>\n      <request_header>\n          <result_waittime_ms>10000</result_waittime_ms>\n      </request_header>\n      <message_body>\n          <crcpdons:pdoheader>\n              <patient_set_limit>0</patient_set_limit>\n              <estimated_time>0</estimated_time>\n              <request_type>getPDO_fromInputList</request_type>\n          </crcpdons:pdoheader>\n          <crcpdons:request xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="crcpdons:GetPDOFromInputList_requestType">\n              <input_list>\n                  <patient_list max="1000000" min="0">\n                      <patient_set_coll_id>7</patient_set_coll_id>\n                  </patient_list>\n              </input_list>\n              <output_option name="none">\n                  <patient_set select="using_input_list" onlykeys="false" blob="false" techdata="false"/>\n              </output_option>\n          </crcpdons:request>\n      </message_body>\n  </msgns:request>	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns5:request xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <message_header>\n        <i2b2_version_compatible>0.3</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>GeCo i2b2 Data Source</application_name>\n            <application_version>0.2</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>GeCo</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>i2b2 cell</application_name>\n            <application_version>1.7</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-05-02T14:02:05+02:00</datetime_of_message>\n        <security>\n            <domain>i2b2demo</domain>\n            <username>demo</username>\n            <password is_token="false">password not stored</password>\n        </security>\n        <message_type>\n            <message_code>EQQ</message_code>\n            <event_type>Q04</event_type>\n            <message_structure>EQQ_Q04</message_structure>\n        </message_type>\n        <message_control_id>\n            <session_id>2022-05-02T14:02:05+02:00</session_id>\n            <message_num>1651492925</message_num>\n            <instance_num>0</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n        <application_acknowledgement_type></application_acknowledgement_type>\n        <country_code>CH</country_code>\n        <project_id>Demo</project_id>\n    </message_header>\n    <request_header>\n        <result_waittime_ms>10000</result_waittime_ms>\n    </request_header>\n    <message_body>\n        <ns3:pdoheader>\n            <patient_set_limit>0</patient_set_limit>\n            <estimated_time>0</estimated_time>\n            <request_type>getPDO_fromInputList</request_type>\n        </ns3:pdoheader>\n        <ns3:request xsi:type="ns3:GetPDOFromInputList_requestType" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">\n            <input_list>\n                <patient_list min="0" max="1000000">\n                    <patient_set_coll_id>7</patient_set_coll_id>\n                </patient_list>\n            </input_list>\n            <output_option>\n                <patient_set onlykeys="false" blob="false" techdata="false" select="using_input_list"/>\n            </output_option>\n        </ns3:request>\n    </message_body>\n</ns5:request>\n
5	demo	Demo	2022-05-02 12:02:06.438	<msgns:request xmlns:msgns="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:pdons="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ontns="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:crcpdons="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/" xmlns:crcpsmns="http://www.i2b2.org/xsd/cell/crc/psm/1.1/">\n      <message_header>\n          <i2b2_version_compatible>0.3</i2b2_version_compatible>\n          <hl7_version_compatible>2.4</hl7_version_compatible>\n          <sending_application>\n              <application_name>GeCo i2b2 Data Source</application_name>\n              <application_version>0.2</application_version>\n          </sending_application>\n          <sending_facility>\n              <facility_name>GeCo</facility_name>\n          </sending_facility>\n          <receiving_application>\n              <application_name>i2b2 cell</application_name>\n              <application_version>1.7</application_version>\n          </receiving_application>\n          <receiving_facility>\n              <facility_name>i2b2 hive</facility_name>\n          </receiving_facility>\n          <datetime_of_message>2022-05-02T14:02:06+02:00</datetime_of_message>\n          <security>\n              <domain>i2b2demo</domain>\n              <username>demo</username>\n              <password>*********</password>\n          </security>\n          <message_type>\n              <message_code>EQQ</message_code>\n              <event_type>Q04</event_type>\n              <message_structure>EQQ_Q04</message_structure>\n          </message_type>\n          <message_control_id>\n              <session_id>2022-05-02T14:02:06+02:00</session_id>\n              <message_num>1651492926</message_num>\n              <instance_num>0</instance_num>\n          </message_control_id>\n          <processing_id>\n              <processing_id>P</processing_id>\n              <processing_mode>I</processing_mode>\n          </processing_id>\n          <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n          <application_acknowledgement_type/>\n          <country_code>CH</country_code>\n          <project_id>Demo</project_id>\n      </message_header>\n      <request_header>\n          <result_waittime_ms>10000</result_waittime_ms>\n      </request_header>\n      <message_body>\n          <crcpdons:pdoheader>\n              <patient_set_limit>0</patient_set_limit>\n              <estimated_time>0</estimated_time>\n              <request_type>getPDO_fromInputList</request_type>\n          </crcpdons:pdoheader>\n          <crcpdons:request xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="crcpdons:GetPDOFromInputList_requestType">\n              <input_list>\n                  <patient_list max="1000000" min="0">\n                      <patient_set_coll_id>9</patient_set_coll_id>\n                  </patient_list>\n              </input_list>\n              <output_option name="none">\n                  <patient_set select="using_input_list" onlykeys="false" blob="false" techdata="false"/>\n              </output_option>\n          </crcpdons:request>\n      </message_body>\n  </msgns:request>	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns5:request xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <message_header>\n        <i2b2_version_compatible>0.3</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>GeCo i2b2 Data Source</application_name>\n            <application_version>0.2</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>GeCo</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>i2b2 cell</application_name>\n            <application_version>1.7</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-05-02T14:02:06+02:00</datetime_of_message>\n        <security>\n            <domain>i2b2demo</domain>\n            <username>demo</username>\n            <password is_token="false">password not stored</password>\n        </security>\n        <message_type>\n            <message_code>EQQ</message_code>\n            <event_type>Q04</event_type>\n            <message_structure>EQQ_Q04</message_structure>\n        </message_type>\n        <message_control_id>\n            <session_id>2022-05-02T14:02:06+02:00</session_id>\n            <message_num>1651492926</message_num>\n            <instance_num>0</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n        <application_acknowledgement_type></application_acknowledgement_type>\n        <country_code>CH</country_code>\n        <project_id>Demo</project_id>\n    </message_header>\n    <request_header>\n        <result_waittime_ms>10000</result_waittime_ms>\n    </request_header>\n    <message_body>\n        <ns3:pdoheader>\n            <patient_set_limit>0</patient_set_limit>\n            <estimated_time>0</estimated_time>\n            <request_type>getPDO_fromInputList</request_type>\n        </ns3:pdoheader>\n        <ns3:request xsi:type="ns3:GetPDOFromInputList_requestType" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">\n            <input_list>\n                <patient_list min="0" max="1000000">\n                    <patient_set_coll_id>9</patient_set_coll_id>\n                </patient_list>\n            </input_list>\n            <output_option>\n                <patient_set onlykeys="false" blob="false" techdata="false" select="using_input_list"/>\n            </output_option>\n        </ns3:request>\n    </message_body>\n</ns5:request>\n
6	demo	Demo	2022-05-02 12:02:06.863	<msgns:request xmlns:msgns="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:pdons="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ontns="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:crcpdons="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/" xmlns:crcpsmns="http://www.i2b2.org/xsd/cell/crc/psm/1.1/">\n      <message_header>\n          <i2b2_version_compatible>0.3</i2b2_version_compatible>\n          <hl7_version_compatible>2.4</hl7_version_compatible>\n          <sending_application>\n              <application_name>GeCo i2b2 Data Source</application_name>\n              <application_version>0.2</application_version>\n          </sending_application>\n          <sending_facility>\n              <facility_name>GeCo</facility_name>\n          </sending_facility>\n          <receiving_application>\n              <application_name>i2b2 cell</application_name>\n              <application_version>1.7</application_version>\n          </receiving_application>\n          <receiving_facility>\n              <facility_name>i2b2 hive</facility_name>\n          </receiving_facility>\n          <datetime_of_message>2022-05-02T14:02:06+02:00</datetime_of_message>\n          <security>\n              <domain>i2b2demo</domain>\n              <username>demo</username>\n              <password>*********</password>\n          </security>\n          <message_type>\n              <message_code>EQQ</message_code>\n              <event_type>Q04</event_type>\n              <message_structure>EQQ_Q04</message_structure>\n          </message_type>\n          <message_control_id>\n              <session_id>2022-05-02T14:02:06+02:00</session_id>\n              <message_num>1651492926</message_num>\n              <instance_num>0</instance_num>\n          </message_control_id>\n          <processing_id>\n              <processing_id>P</processing_id>\n              <processing_mode>I</processing_mode>\n          </processing_id>\n          <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n          <application_acknowledgement_type/>\n          <country_code>CH</country_code>\n          <project_id>Demo</project_id>\n      </message_header>\n      <request_header>\n          <result_waittime_ms>10000</result_waittime_ms>\n      </request_header>\n      <message_body>\n          <crcpdons:pdoheader>\n              <patient_set_limit>0</patient_set_limit>\n              <estimated_time>0</estimated_time>\n              <request_type>getPDO_fromInputList</request_type>\n          </crcpdons:pdoheader>\n          <crcpdons:request xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="crcpdons:GetPDOFromInputList_requestType">\n              <input_list>\n                  <patient_list max="1000000" min="0">\n                      <patient_set_coll_id>11</patient_set_coll_id>\n                  </patient_list>\n              </input_list>\n              <output_option name="none">\n                  <patient_set select="using_input_list" onlykeys="false" blob="false" techdata="false"/>\n              </output_option>\n          </crcpdons:request>\n      </message_body>\n  </msgns:request>	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns5:request xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <message_header>\n        <i2b2_version_compatible>0.3</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>GeCo i2b2 Data Source</application_name>\n            <application_version>0.2</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>GeCo</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>i2b2 cell</application_name>\n            <application_version>1.7</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-05-02T14:02:06+02:00</datetime_of_message>\n        <security>\n            <domain>i2b2demo</domain>\n            <username>demo</username>\n            <password is_token="false">password not stored</password>\n        </security>\n        <message_type>\n            <message_code>EQQ</message_code>\n            <event_type>Q04</event_type>\n            <message_structure>EQQ_Q04</message_structure>\n        </message_type>\n        <message_control_id>\n            <session_id>2022-05-02T14:02:06+02:00</session_id>\n            <message_num>1651492926</message_num>\n            <instance_num>0</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n        <application_acknowledgement_type></application_acknowledgement_type>\n        <country_code>CH</country_code>\n        <project_id>Demo</project_id>\n    </message_header>\n    <request_header>\n        <result_waittime_ms>10000</result_waittime_ms>\n    </request_header>\n    <message_body>\n        <ns3:pdoheader>\n            <patient_set_limit>0</patient_set_limit>\n            <estimated_time>0</estimated_time>\n            <request_type>getPDO_fromInputList</request_type>\n        </ns3:pdoheader>\n        <ns3:request xsi:type="ns3:GetPDOFromInputList_requestType" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">\n            <input_list>\n                <patient_list min="0" max="1000000">\n                    <patient_set_coll_id>11</patient_set_coll_id>\n                </patient_list>\n            </input_list>\n            <output_option>\n                <patient_set onlykeys="false" blob="false" techdata="false" select="using_input_list"/>\n            </output_option>\n        </ns3:request>\n    </message_body>\n</ns5:request>\n
7	demo	Demo	2022-05-02 12:02:07.215	<msgns:request xmlns:msgns="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:pdons="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ontns="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:crcpdons="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/" xmlns:crcpsmns="http://www.i2b2.org/xsd/cell/crc/psm/1.1/">\n      <message_header>\n          <i2b2_version_compatible>0.3</i2b2_version_compatible>\n          <hl7_version_compatible>2.4</hl7_version_compatible>\n          <sending_application>\n              <application_name>GeCo i2b2 Data Source</application_name>\n              <application_version>0.2</application_version>\n          </sending_application>\n          <sending_facility>\n              <facility_name>GeCo</facility_name>\n          </sending_facility>\n          <receiving_application>\n              <application_name>i2b2 cell</application_name>\n              <application_version>1.7</application_version>\n          </receiving_application>\n          <receiving_facility>\n              <facility_name>i2b2 hive</facility_name>\n          </receiving_facility>\n          <datetime_of_message>2022-05-02T14:02:07+02:00</datetime_of_message>\n          <security>\n              <domain>i2b2demo</domain>\n              <username>demo</username>\n              <password>*********</password>\n          </security>\n          <message_type>\n              <message_code>EQQ</message_code>\n              <event_type>Q04</event_type>\n              <message_structure>EQQ_Q04</message_structure>\n          </message_type>\n          <message_control_id>\n              <session_id>2022-05-02T14:02:07+02:00</session_id>\n              <message_num>1651492927</message_num>\n              <instance_num>0</instance_num>\n          </message_control_id>\n          <processing_id>\n              <processing_id>P</processing_id>\n              <processing_mode>I</processing_mode>\n          </processing_id>\n          <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n          <application_acknowledgement_type/>\n          <country_code>CH</country_code>\n          <project_id>Demo</project_id>\n      </message_header>\n      <request_header>\n          <result_waittime_ms>10000</result_waittime_ms>\n      </request_header>\n      <message_body>\n          <crcpdons:pdoheader>\n              <patient_set_limit>0</patient_set_limit>\n              <estimated_time>0</estimated_time>\n              <request_type>getPDO_fromInputList</request_type>\n          </crcpdons:pdoheader>\n          <crcpdons:request xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="crcpdons:GetPDOFromInputList_requestType">\n              <input_list>\n                  <patient_list max="1000000" min="0">\n                      <patient_set_coll_id>13</patient_set_coll_id>\n                  </patient_list>\n              </input_list>\n              <output_option name="none">\n                  <patient_set select="using_input_list" onlykeys="false" blob="false" techdata="false"/>\n              </output_option>\n          </crcpdons:request>\n      </message_body>\n  </msgns:request>	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns5:request xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <message_header>\n        <i2b2_version_compatible>0.3</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>GeCo i2b2 Data Source</application_name>\n            <application_version>0.2</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>GeCo</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>i2b2 cell</application_name>\n            <application_version>1.7</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-05-02T14:02:07+02:00</datetime_of_message>\n        <security>\n            <domain>i2b2demo</domain>\n            <username>demo</username>\n            <password is_token="false">password not stored</password>\n        </security>\n        <message_type>\n            <message_code>EQQ</message_code>\n            <event_type>Q04</event_type>\n            <message_structure>EQQ_Q04</message_structure>\n        </message_type>\n        <message_control_id>\n            <session_id>2022-05-02T14:02:07+02:00</session_id>\n            <message_num>1651492927</message_num>\n            <instance_num>0</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n        <application_acknowledgement_type></application_acknowledgement_type>\n        <country_code>CH</country_code>\n        <project_id>Demo</project_id>\n    </message_header>\n    <request_header>\n        <result_waittime_ms>10000</result_waittime_ms>\n    </request_header>\n    <message_body>\n        <ns3:pdoheader>\n            <patient_set_limit>0</patient_set_limit>\n            <estimated_time>0</estimated_time>\n            <request_type>getPDO_fromInputList</request_type>\n        </ns3:pdoheader>\n        <ns3:request xsi:type="ns3:GetPDOFromInputList_requestType" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">\n            <input_list>\n                <patient_list min="0" max="1000000">\n                    <patient_set_coll_id>13</patient_set_coll_id>\n                </patient_list>\n            </input_list>\n            <output_option>\n                <patient_set onlykeys="false" blob="false" techdata="false" select="using_input_list"/>\n            </output_option>\n        </ns3:request>\n    </message_body>\n</ns5:request>\n
8	demo	Demo	2022-05-02 12:02:07.699	<msgns:request xmlns:msgns="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:pdons="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ontns="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:crcpdons="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/" xmlns:crcpsmns="http://www.i2b2.org/xsd/cell/crc/psm/1.1/">\n      <message_header>\n          <i2b2_version_compatible>0.3</i2b2_version_compatible>\n          <hl7_version_compatible>2.4</hl7_version_compatible>\n          <sending_application>\n              <application_name>GeCo i2b2 Data Source</application_name>\n              <application_version>0.2</application_version>\n          </sending_application>\n          <sending_facility>\n              <facility_name>GeCo</facility_name>\n          </sending_facility>\n          <receiving_application>\n              <application_name>i2b2 cell</application_name>\n              <application_version>1.7</application_version>\n          </receiving_application>\n          <receiving_facility>\n              <facility_name>i2b2 hive</facility_name>\n          </receiving_facility>\n          <datetime_of_message>2022-05-02T14:02:07+02:00</datetime_of_message>\n          <security>\n              <domain>i2b2demo</domain>\n              <username>demo</username>\n              <password>*********</password>\n          </security>\n          <message_type>\n              <message_code>EQQ</message_code>\n              <event_type>Q04</event_type>\n              <message_structure>EQQ_Q04</message_structure>\n          </message_type>\n          <message_control_id>\n              <session_id>2022-05-02T14:02:07+02:00</session_id>\n              <message_num>1651492927</message_num>\n              <instance_num>0</instance_num>\n          </message_control_id>\n          <processing_id>\n              <processing_id>P</processing_id>\n              <processing_mode>I</processing_mode>\n          </processing_id>\n          <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n          <application_acknowledgement_type/>\n          <country_code>CH</country_code>\n          <project_id>Demo</project_id>\n      </message_header>\n      <request_header>\n          <result_waittime_ms>10000</result_waittime_ms>\n      </request_header>\n      <message_body>\n          <crcpdons:pdoheader>\n              <patient_set_limit>0</patient_set_limit>\n              <estimated_time>0</estimated_time>\n              <request_type>getPDO_fromInputList</request_type>\n          </crcpdons:pdoheader>\n          <crcpdons:request xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="crcpdons:GetPDOFromInputList_requestType">\n              <input_list>\n                  <patient_list max="1000000" min="0">\n                      <patient_set_coll_id>15</patient_set_coll_id>\n                  </patient_list>\n              </input_list>\n              <output_option name="none">\n                  <patient_set select="using_input_list" onlykeys="false" blob="false" techdata="false"/>\n              </output_option>\n          </crcpdons:request>\n      </message_body>\n  </msgns:request>	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns5:request xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <message_header>\n        <i2b2_version_compatible>0.3</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>GeCo i2b2 Data Source</application_name>\n            <application_version>0.2</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>GeCo</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>i2b2 cell</application_name>\n            <application_version>1.7</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-05-02T14:02:07+02:00</datetime_of_message>\n        <security>\n            <domain>i2b2demo</domain>\n            <username>demo</username>\n            <password is_token="false">password not stored</password>\n        </security>\n        <message_type>\n            <message_code>EQQ</message_code>\n            <event_type>Q04</event_type>\n            <message_structure>EQQ_Q04</message_structure>\n        </message_type>\n        <message_control_id>\n            <session_id>2022-05-02T14:02:07+02:00</session_id>\n            <message_num>1651492927</message_num>\n            <instance_num>0</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n        <application_acknowledgement_type></application_acknowledgement_type>\n        <country_code>CH</country_code>\n        <project_id>Demo</project_id>\n    </message_header>\n    <request_header>\n        <result_waittime_ms>10000</result_waittime_ms>\n    </request_header>\n    <message_body>\n        <ns3:pdoheader>\n            <patient_set_limit>0</patient_set_limit>\n            <estimated_time>0</estimated_time>\n            <request_type>getPDO_fromInputList</request_type>\n        </ns3:pdoheader>\n        <ns3:request xsi:type="ns3:GetPDOFromInputList_requestType" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">\n            <input_list>\n                <patient_list min="0" max="1000000">\n                    <patient_set_coll_id>15</patient_set_coll_id>\n                </patient_list>\n            </input_list>\n            <output_option>\n                <patient_set onlykeys="false" blob="false" techdata="false" select="using_input_list"/>\n            </output_option>\n        </ns3:request>\n    </message_body>\n</ns5:request>\n
9	demo	Demo	2022-05-02 12:02:08.192	<msgns:request xmlns:msgns="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:pdons="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ontns="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:crcpdons="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/" xmlns:crcpsmns="http://www.i2b2.org/xsd/cell/crc/psm/1.1/">\n      <message_header>\n          <i2b2_version_compatible>0.3</i2b2_version_compatible>\n          <hl7_version_compatible>2.4</hl7_version_compatible>\n          <sending_application>\n              <application_name>GeCo i2b2 Data Source</application_name>\n              <application_version>0.2</application_version>\n          </sending_application>\n          <sending_facility>\n              <facility_name>GeCo</facility_name>\n          </sending_facility>\n          <receiving_application>\n              <application_name>i2b2 cell</application_name>\n              <application_version>1.7</application_version>\n          </receiving_application>\n          <receiving_facility>\n              <facility_name>i2b2 hive</facility_name>\n          </receiving_facility>\n          <datetime_of_message>2022-05-02T14:02:08+02:00</datetime_of_message>\n          <security>\n              <domain>i2b2demo</domain>\n              <username>demo</username>\n              <password>*********</password>\n          </security>\n          <message_type>\n              <message_code>EQQ</message_code>\n              <event_type>Q04</event_type>\n              <message_structure>EQQ_Q04</message_structure>\n          </message_type>\n          <message_control_id>\n              <session_id>2022-05-02T14:02:08+02:00</session_id>\n              <message_num>1651492928</message_num>\n              <instance_num>0</instance_num>\n          </message_control_id>\n          <processing_id>\n              <processing_id>P</processing_id>\n              <processing_mode>I</processing_mode>\n          </processing_id>\n          <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n          <application_acknowledgement_type/>\n          <country_code>CH</country_code>\n          <project_id>Demo</project_id>\n      </message_header>\n      <request_header>\n          <result_waittime_ms>10000</result_waittime_ms>\n      </request_header>\n      <message_body>\n          <crcpdons:pdoheader>\n              <patient_set_limit>0</patient_set_limit>\n              <estimated_time>0</estimated_time>\n              <request_type>getPDO_fromInputList</request_type>\n          </crcpdons:pdoheader>\n          <crcpdons:request xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="crcpdons:GetPDOFromInputList_requestType">\n              <input_list>\n                  <patient_list max="1000000" min="0">\n                      <patient_set_coll_id>17</patient_set_coll_id>\n                  </patient_list>\n              </input_list>\n              <output_option name="none">\n                  <patient_set select="using_input_list" onlykeys="false" blob="false" techdata="false"/>\n              </output_option>\n          </crcpdons:request>\n      </message_body>\n  </msgns:request>	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns5:request xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <message_header>\n        <i2b2_version_compatible>0.3</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>GeCo i2b2 Data Source</application_name>\n            <application_version>0.2</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>GeCo</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>i2b2 cell</application_name>\n            <application_version>1.7</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-05-02T14:02:08+02:00</datetime_of_message>\n        <security>\n            <domain>i2b2demo</domain>\n            <username>demo</username>\n            <password is_token="false">password not stored</password>\n        </security>\n        <message_type>\n            <message_code>EQQ</message_code>\n            <event_type>Q04</event_type>\n            <message_structure>EQQ_Q04</message_structure>\n        </message_type>\n        <message_control_id>\n            <session_id>2022-05-02T14:02:08+02:00</session_id>\n            <message_num>1651492928</message_num>\n            <instance_num>0</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n        <application_acknowledgement_type></application_acknowledgement_type>\n        <country_code>CH</country_code>\n        <project_id>Demo</project_id>\n    </message_header>\n    <request_header>\n        <result_waittime_ms>10000</result_waittime_ms>\n    </request_header>\n    <message_body>\n        <ns3:pdoheader>\n            <patient_set_limit>0</patient_set_limit>\n            <estimated_time>0</estimated_time>\n            <request_type>getPDO_fromInputList</request_type>\n        </ns3:pdoheader>\n        <ns3:request xsi:type="ns3:GetPDOFromInputList_requestType" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">\n            <input_list>\n                <patient_list min="0" max="1000000">\n                    <patient_set_coll_id>17</patient_set_coll_id>\n                </patient_list>\n            </input_list>\n            <output_option>\n                <patient_set onlykeys="false" blob="false" techdata="false" select="using_input_list"/>\n            </output_option>\n        </ns3:request>\n    </message_body>\n</ns5:request>\n
10	demo	Demo	2022-05-02 12:02:08.726	<msgns:request xmlns:msgns="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:pdons="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ontns="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:crcpdons="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/" xmlns:crcpsmns="http://www.i2b2.org/xsd/cell/crc/psm/1.1/">\n      <message_header>\n          <i2b2_version_compatible>0.3</i2b2_version_compatible>\n          <hl7_version_compatible>2.4</hl7_version_compatible>\n          <sending_application>\n              <application_name>GeCo i2b2 Data Source</application_name>\n              <application_version>0.2</application_version>\n          </sending_application>\n          <sending_facility>\n              <facility_name>GeCo</facility_name>\n          </sending_facility>\n          <receiving_application>\n              <application_name>i2b2 cell</application_name>\n              <application_version>1.7</application_version>\n          </receiving_application>\n          <receiving_facility>\n              <facility_name>i2b2 hive</facility_name>\n          </receiving_facility>\n          <datetime_of_message>2022-05-02T14:02:08+02:00</datetime_of_message>\n          <security>\n              <domain>i2b2demo</domain>\n              <username>demo</username>\n              <password>*********</password>\n          </security>\n          <message_type>\n              <message_code>EQQ</message_code>\n              <event_type>Q04</event_type>\n              <message_structure>EQQ_Q04</message_structure>\n          </message_type>\n          <message_control_id>\n              <session_id>2022-05-02T14:02:08+02:00</session_id>\n              <message_num>1651492928</message_num>\n              <instance_num>0</instance_num>\n          </message_control_id>\n          <processing_id>\n              <processing_id>P</processing_id>\n              <processing_mode>I</processing_mode>\n          </processing_id>\n          <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n          <application_acknowledgement_type/>\n          <country_code>CH</country_code>\n          <project_id>Demo</project_id>\n      </message_header>\n      <request_header>\n          <result_waittime_ms>10000</result_waittime_ms>\n      </request_header>\n      <message_body>\n          <crcpdons:pdoheader>\n              <patient_set_limit>0</patient_set_limit>\n              <estimated_time>0</estimated_time>\n              <request_type>getPDO_fromInputList</request_type>\n          </crcpdons:pdoheader>\n          <crcpdons:request xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="crcpdons:GetPDOFromInputList_requestType">\n              <input_list>\n                  <patient_list max="1000000" min="0">\n                      <patient_set_coll_id>19</patient_set_coll_id>\n                  </patient_list>\n              </input_list>\n              <output_option name="none">\n                  <patient_set select="using_input_list" onlykeys="false" blob="false" techdata="false"/>\n              </output_option>\n          </crcpdons:request>\n      </message_body>\n  </msgns:request>	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns5:request xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <message_header>\n        <i2b2_version_compatible>0.3</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>GeCo i2b2 Data Source</application_name>\n            <application_version>0.2</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>GeCo</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>i2b2 cell</application_name>\n            <application_version>1.7</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-05-02T14:02:08+02:00</datetime_of_message>\n        <security>\n            <domain>i2b2demo</domain>\n            <username>demo</username>\n            <password is_token="false">password not stored</password>\n        </security>\n        <message_type>\n            <message_code>EQQ</message_code>\n            <event_type>Q04</event_type>\n            <message_structure>EQQ_Q04</message_structure>\n        </message_type>\n        <message_control_id>\n            <session_id>2022-05-02T14:02:08+02:00</session_id>\n            <message_num>1651492928</message_num>\n            <instance_num>0</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n        <application_acknowledgement_type></application_acknowledgement_type>\n        <country_code>CH</country_code>\n        <project_id>Demo</project_id>\n    </message_header>\n    <request_header>\n        <result_waittime_ms>10000</result_waittime_ms>\n    </request_header>\n    <message_body>\n        <ns3:pdoheader>\n            <patient_set_limit>0</patient_set_limit>\n            <estimated_time>0</estimated_time>\n            <request_type>getPDO_fromInputList</request_type>\n        </ns3:pdoheader>\n        <ns3:request xsi:type="ns3:GetPDOFromInputList_requestType" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">\n            <input_list>\n                <patient_list min="0" max="1000000">\n                    <patient_set_coll_id>19</patient_set_coll_id>\n                </patient_list>\n            </input_list>\n            <output_option>\n                <patient_set onlykeys="false" blob="false" techdata="false" select="using_input_list"/>\n            </output_option>\n        </ns3:request>\n    </message_body>\n</ns5:request>\n
11	demo	Demo	2022-05-02 12:02:09.12	<msgns:request xmlns:msgns="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:pdons="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ontns="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:crcpdons="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/" xmlns:crcpsmns="http://www.i2b2.org/xsd/cell/crc/psm/1.1/">\n      <message_header>\n          <i2b2_version_compatible>0.3</i2b2_version_compatible>\n          <hl7_version_compatible>2.4</hl7_version_compatible>\n          <sending_application>\n              <application_name>GeCo i2b2 Data Source</application_name>\n              <application_version>0.2</application_version>\n          </sending_application>\n          <sending_facility>\n              <facility_name>GeCo</facility_name>\n          </sending_facility>\n          <receiving_application>\n              <application_name>i2b2 cell</application_name>\n              <application_version>1.7</application_version>\n          </receiving_application>\n          <receiving_facility>\n              <facility_name>i2b2 hive</facility_name>\n          </receiving_facility>\n          <datetime_of_message>2022-05-02T14:02:09+02:00</datetime_of_message>\n          <security>\n              <domain>i2b2demo</domain>\n              <username>demo</username>\n              <password>*********</password>\n          </security>\n          <message_type>\n              <message_code>EQQ</message_code>\n              <event_type>Q04</event_type>\n              <message_structure>EQQ_Q04</message_structure>\n          </message_type>\n          <message_control_id>\n              <session_id>2022-05-02T14:02:09+02:00</session_id>\n              <message_num>1651492929</message_num>\n              <instance_num>0</instance_num>\n          </message_control_id>\n          <processing_id>\n              <processing_id>P</processing_id>\n              <processing_mode>I</processing_mode>\n          </processing_id>\n          <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n          <application_acknowledgement_type/>\n          <country_code>CH</country_code>\n          <project_id>Demo</project_id>\n      </message_header>\n      <request_header>\n          <result_waittime_ms>10000</result_waittime_ms>\n      </request_header>\n      <message_body>\n          <crcpdons:pdoheader>\n              <patient_set_limit>0</patient_set_limit>\n              <estimated_time>0</estimated_time>\n              <request_type>getPDO_fromInputList</request_type>\n          </crcpdons:pdoheader>\n          <crcpdons:request xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="crcpdons:GetPDOFromInputList_requestType">\n              <input_list>\n                  <patient_list max="1000000" min="0">\n                      <patient_set_coll_id>21</patient_set_coll_id>\n                  </patient_list>\n              </input_list>\n              <output_option name="none">\n                  <patient_set select="using_input_list" onlykeys="false" blob="false" techdata="false"/>\n              </output_option>\n          </crcpdons:request>\n      </message_body>\n  </msgns:request>	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns5:request xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <message_header>\n        <i2b2_version_compatible>0.3</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>GeCo i2b2 Data Source</application_name>\n            <application_version>0.2</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>GeCo</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>i2b2 cell</application_name>\n            <application_version>1.7</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-05-02T14:02:09+02:00</datetime_of_message>\n        <security>\n            <domain>i2b2demo</domain>\n            <username>demo</username>\n            <password is_token="false">password not stored</password>\n        </security>\n        <message_type>\n            <message_code>EQQ</message_code>\n            <event_type>Q04</event_type>\n            <message_structure>EQQ_Q04</message_structure>\n        </message_type>\n        <message_control_id>\n            <session_id>2022-05-02T14:02:09+02:00</session_id>\n            <message_num>1651492929</message_num>\n            <instance_num>0</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n        <application_acknowledgement_type></application_acknowledgement_type>\n        <country_code>CH</country_code>\n        <project_id>Demo</project_id>\n    </message_header>\n    <request_header>\n        <result_waittime_ms>10000</result_waittime_ms>\n    </request_header>\n    <message_body>\n        <ns3:pdoheader>\n            <patient_set_limit>0</patient_set_limit>\n            <estimated_time>0</estimated_time>\n            <request_type>getPDO_fromInputList</request_type>\n        </ns3:pdoheader>\n        <ns3:request xsi:type="ns3:GetPDOFromInputList_requestType" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">\n            <input_list>\n                <patient_list min="0" max="1000000">\n                    <patient_set_coll_id>21</patient_set_coll_id>\n                </patient_list>\n            </input_list>\n            <output_option>\n                <patient_set onlykeys="false" blob="false" techdata="false" select="using_input_list"/>\n            </output_option>\n        </ns3:request>\n    </message_body>\n</ns5:request>\n
12	demo	Demo	2022-05-02 12:02:09.51	<msgns:request xmlns:msgns="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:pdons="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ontns="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:crcpdons="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/" xmlns:crcpsmns="http://www.i2b2.org/xsd/cell/crc/psm/1.1/">\n      <message_header>\n          <i2b2_version_compatible>0.3</i2b2_version_compatible>\n          <hl7_version_compatible>2.4</hl7_version_compatible>\n          <sending_application>\n              <application_name>GeCo i2b2 Data Source</application_name>\n              <application_version>0.2</application_version>\n          </sending_application>\n          <sending_facility>\n              <facility_name>GeCo</facility_name>\n          </sending_facility>\n          <receiving_application>\n              <application_name>i2b2 cell</application_name>\n              <application_version>1.7</application_version>\n          </receiving_application>\n          <receiving_facility>\n              <facility_name>i2b2 hive</facility_name>\n          </receiving_facility>\n          <datetime_of_message>2022-05-02T14:02:09+02:00</datetime_of_message>\n          <security>\n              <domain>i2b2demo</domain>\n              <username>demo</username>\n              <password>*********</password>\n          </security>\n          <message_type>\n              <message_code>EQQ</message_code>\n              <event_type>Q04</event_type>\n              <message_structure>EQQ_Q04</message_structure>\n          </message_type>\n          <message_control_id>\n              <session_id>2022-05-02T14:02:09+02:00</session_id>\n              <message_num>1651492929</message_num>\n              <instance_num>0</instance_num>\n          </message_control_id>\n          <processing_id>\n              <processing_id>P</processing_id>\n              <processing_mode>I</processing_mode>\n          </processing_id>\n          <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n          <application_acknowledgement_type/>\n          <country_code>CH</country_code>\n          <project_id>Demo</project_id>\n      </message_header>\n      <request_header>\n          <result_waittime_ms>10000</result_waittime_ms>\n      </request_header>\n      <message_body>\n          <crcpdons:pdoheader>\n              <patient_set_limit>0</patient_set_limit>\n              <estimated_time>0</estimated_time>\n              <request_type>getPDO_fromInputList</request_type>\n          </crcpdons:pdoheader>\n          <crcpdons:request xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="crcpdons:GetPDOFromInputList_requestType">\n              <input_list>\n                  <patient_list max="1000000" min="0">\n                      <patient_set_coll_id>23</patient_set_coll_id>\n                  </patient_list>\n              </input_list>\n              <output_option name="none">\n                  <patient_set select="using_input_list" onlykeys="false" blob="false" techdata="false"/>\n              </output_option>\n          </crcpdons:request>\n      </message_body>\n  </msgns:request>	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns5:request xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <message_header>\n        <i2b2_version_compatible>0.3</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>GeCo i2b2 Data Source</application_name>\n            <application_version>0.2</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>GeCo</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>i2b2 cell</application_name>\n            <application_version>1.7</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-05-02T14:02:09+02:00</datetime_of_message>\n        <security>\n            <domain>i2b2demo</domain>\n            <username>demo</username>\n            <password is_token="false">password not stored</password>\n        </security>\n        <message_type>\n            <message_code>EQQ</message_code>\n            <event_type>Q04</event_type>\n            <message_structure>EQQ_Q04</message_structure>\n        </message_type>\n        <message_control_id>\n            <session_id>2022-05-02T14:02:09+02:00</session_id>\n            <message_num>1651492929</message_num>\n            <instance_num>0</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n        <application_acknowledgement_type></application_acknowledgement_type>\n        <country_code>CH</country_code>\n        <project_id>Demo</project_id>\n    </message_header>\n    <request_header>\n        <result_waittime_ms>10000</result_waittime_ms>\n    </request_header>\n    <message_body>\n        <ns3:pdoheader>\n            <patient_set_limit>0</patient_set_limit>\n            <estimated_time>0</estimated_time>\n            <request_type>getPDO_fromInputList</request_type>\n        </ns3:pdoheader>\n        <ns3:request xsi:type="ns3:GetPDOFromInputList_requestType" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">\n            <input_list>\n                <patient_list min="0" max="1000000">\n                    <patient_set_coll_id>23</patient_set_coll_id>\n                </patient_list>\n            </input_list>\n            <output_option>\n                <patient_set onlykeys="false" blob="false" techdata="false" select="using_input_list"/>\n            </output_option>\n        </ns3:request>\n    </message_body>\n</ns5:request>\n
13	demo	Demo	2022-05-02 12:02:09.849	<msgns:request xmlns:msgns="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:pdons="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ontns="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:crcpdons="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/" xmlns:crcpsmns="http://www.i2b2.org/xsd/cell/crc/psm/1.1/">\n      <message_header>\n          <i2b2_version_compatible>0.3</i2b2_version_compatible>\n          <hl7_version_compatible>2.4</hl7_version_compatible>\n          <sending_application>\n              <application_name>GeCo i2b2 Data Source</application_name>\n              <application_version>0.2</application_version>\n          </sending_application>\n          <sending_facility>\n              <facility_name>GeCo</facility_name>\n          </sending_facility>\n          <receiving_application>\n              <application_name>i2b2 cell</application_name>\n              <application_version>1.7</application_version>\n          </receiving_application>\n          <receiving_facility>\n              <facility_name>i2b2 hive</facility_name>\n          </receiving_facility>\n          <datetime_of_message>2022-05-02T14:02:09+02:00</datetime_of_message>\n          <security>\n              <domain>i2b2demo</domain>\n              <username>demo</username>\n              <password>*********</password>\n          </security>\n          <message_type>\n              <message_code>EQQ</message_code>\n              <event_type>Q04</event_type>\n              <message_structure>EQQ_Q04</message_structure>\n          </message_type>\n          <message_control_id>\n              <session_id>2022-05-02T14:02:09+02:00</session_id>\n              <message_num>1651492929</message_num>\n              <instance_num>0</instance_num>\n          </message_control_id>\n          <processing_id>\n              <processing_id>P</processing_id>\n              <processing_mode>I</processing_mode>\n          </processing_id>\n          <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n          <application_acknowledgement_type/>\n          <country_code>CH</country_code>\n          <project_id>Demo</project_id>\n      </message_header>\n      <request_header>\n          <result_waittime_ms>10000</result_waittime_ms>\n      </request_header>\n      <message_body>\n          <crcpdons:pdoheader>\n              <patient_set_limit>0</patient_set_limit>\n              <estimated_time>0</estimated_time>\n              <request_type>getPDO_fromInputList</request_type>\n          </crcpdons:pdoheader>\n          <crcpdons:request xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="crcpdons:GetPDOFromInputList_requestType">\n              <input_list>\n                  <patient_list max="1000000" min="0">\n                      <patient_set_coll_id>25</patient_set_coll_id>\n                  </patient_list>\n              </input_list>\n              <output_option name="none">\n                  <patient_set select="using_input_list" onlykeys="false" blob="false" techdata="false"/>\n              </output_option>\n          </crcpdons:request>\n      </message_body>\n  </msgns:request>	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns5:request xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <message_header>\n        <i2b2_version_compatible>0.3</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>GeCo i2b2 Data Source</application_name>\n            <application_version>0.2</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>GeCo</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>i2b2 cell</application_name>\n            <application_version>1.7</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-05-02T14:02:09+02:00</datetime_of_message>\n        <security>\n            <domain>i2b2demo</domain>\n            <username>demo</username>\n            <password is_token="false">password not stored</password>\n        </security>\n        <message_type>\n            <message_code>EQQ</message_code>\n            <event_type>Q04</event_type>\n            <message_structure>EQQ_Q04</message_structure>\n        </message_type>\n        <message_control_id>\n            <session_id>2022-05-02T14:02:09+02:00</session_id>\n            <message_num>1651492929</message_num>\n            <instance_num>0</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n        <application_acknowledgement_type></application_acknowledgement_type>\n        <country_code>CH</country_code>\n        <project_id>Demo</project_id>\n    </message_header>\n    <request_header>\n        <result_waittime_ms>10000</result_waittime_ms>\n    </request_header>\n    <message_body>\n        <ns3:pdoheader>\n            <patient_set_limit>0</patient_set_limit>\n            <estimated_time>0</estimated_time>\n            <request_type>getPDO_fromInputList</request_type>\n        </ns3:pdoheader>\n        <ns3:request xsi:type="ns3:GetPDOFromInputList_requestType" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">\n            <input_list>\n                <patient_list min="0" max="1000000">\n                    <patient_set_coll_id>25</patient_set_coll_id>\n                </patient_list>\n            </input_list>\n            <output_option>\n                <patient_set onlykeys="false" blob="false" techdata="false" select="using_input_list"/>\n            </output_option>\n        </ns3:request>\n    </message_body>\n</ns5:request>\n
14	demo	Demo	2022-05-02 12:02:11.048	<msgns:request xmlns:msgns="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:pdons="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ontns="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:crcpdons="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/" xmlns:crcpsmns="http://www.i2b2.org/xsd/cell/crc/psm/1.1/">\n      <message_header>\n          <i2b2_version_compatible>0.3</i2b2_version_compatible>\n          <hl7_version_compatible>2.4</hl7_version_compatible>\n          <sending_application>\n              <application_name>GeCo i2b2 Data Source</application_name>\n              <application_version>0.2</application_version>\n          </sending_application>\n          <sending_facility>\n              <facility_name>GeCo</facility_name>\n          </sending_facility>\n          <receiving_application>\n              <application_name>i2b2 cell</application_name>\n              <application_version>1.7</application_version>\n          </receiving_application>\n          <receiving_facility>\n              <facility_name>i2b2 hive</facility_name>\n          </receiving_facility>\n          <datetime_of_message>2022-05-02T14:02:11+02:00</datetime_of_message>\n          <security>\n              <domain>i2b2demo</domain>\n              <username>demo</username>\n              <password>*********</password>\n          </security>\n          <message_type>\n              <message_code>EQQ</message_code>\n              <event_type>Q04</event_type>\n              <message_structure>EQQ_Q04</message_structure>\n          </message_type>\n          <message_control_id>\n              <session_id>2022-05-02T14:02:11+02:00</session_id>\n              <message_num>1651492931</message_num>\n              <instance_num>0</instance_num>\n          </message_control_id>\n          <processing_id>\n              <processing_id>P</processing_id>\n              <processing_mode>I</processing_mode>\n          </processing_id>\n          <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n          <application_acknowledgement_type/>\n          <country_code>CH</country_code>\n          <project_id>Demo</project_id>\n      </message_header>\n      <request_header>\n          <result_waittime_ms>10000</result_waittime_ms>\n      </request_header>\n      <message_body>\n          <crcpdons:pdoheader>\n              <patient_set_limit>0</patient_set_limit>\n              <estimated_time>0</estimated_time>\n              <request_type>getPDO_fromInputList</request_type>\n          </crcpdons:pdoheader>\n          <crcpdons:request xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="crcpdons:GetPDOFromInputList_requestType">\n              <input_list>\n                  <patient_list max="1000000" min="0">\n                      <patient_set_coll_id>27</patient_set_coll_id>\n                  </patient_list>\n              </input_list>\n              <output_option name="none">\n                  <patient_set select="using_input_list" onlykeys="false" blob="false" techdata="false"/>\n              </output_option>\n          </crcpdons:request>\n      </message_body>\n  </msgns:request>	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns5:request xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <message_header>\n        <i2b2_version_compatible>0.3</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>GeCo i2b2 Data Source</application_name>\n            <application_version>0.2</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>GeCo</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>i2b2 cell</application_name>\n            <application_version>1.7</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-05-02T14:02:11+02:00</datetime_of_message>\n        <security>\n            <domain>i2b2demo</domain>\n            <username>demo</username>\n            <password is_token="false">password not stored</password>\n        </security>\n        <message_type>\n            <message_code>EQQ</message_code>\n            <event_type>Q04</event_type>\n            <message_structure>EQQ_Q04</message_structure>\n        </message_type>\n        <message_control_id>\n            <session_id>2022-05-02T14:02:11+02:00</session_id>\n            <message_num>1651492931</message_num>\n            <instance_num>0</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n        <application_acknowledgement_type></application_acknowledgement_type>\n        <country_code>CH</country_code>\n        <project_id>Demo</project_id>\n    </message_header>\n    <request_header>\n        <result_waittime_ms>10000</result_waittime_ms>\n    </request_header>\n    <message_body>\n        <ns3:pdoheader>\n            <patient_set_limit>0</patient_set_limit>\n            <estimated_time>0</estimated_time>\n            <request_type>getPDO_fromInputList</request_type>\n        </ns3:pdoheader>\n        <ns3:request xsi:type="ns3:GetPDOFromInputList_requestType" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">\n            <input_list>\n                <patient_list min="0" max="1000000">\n                    <patient_set_coll_id>27</patient_set_coll_id>\n                </patient_list>\n            </input_list>\n            <output_option>\n                <patient_set onlykeys="false" blob="false" techdata="false" select="using_input_list"/>\n            </output_option>\n        </ns3:request>\n    </message_body>\n</ns5:request>\n
15	demo	Demo	2022-05-02 12:02:11.415	<msgns:request xmlns:msgns="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:pdons="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ontns="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:crcpdons="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/" xmlns:crcpsmns="http://www.i2b2.org/xsd/cell/crc/psm/1.1/">\n      <message_header>\n          <i2b2_version_compatible>0.3</i2b2_version_compatible>\n          <hl7_version_compatible>2.4</hl7_version_compatible>\n          <sending_application>\n              <application_name>GeCo i2b2 Data Source</application_name>\n              <application_version>0.2</application_version>\n          </sending_application>\n          <sending_facility>\n              <facility_name>GeCo</facility_name>\n          </sending_facility>\n          <receiving_application>\n              <application_name>i2b2 cell</application_name>\n              <application_version>1.7</application_version>\n          </receiving_application>\n          <receiving_facility>\n              <facility_name>i2b2 hive</facility_name>\n          </receiving_facility>\n          <datetime_of_message>2022-05-02T14:02:11+02:00</datetime_of_message>\n          <security>\n              <domain>i2b2demo</domain>\n              <username>demo</username>\n              <password>*********</password>\n          </security>\n          <message_type>\n              <message_code>EQQ</message_code>\n              <event_type>Q04</event_type>\n              <message_structure>EQQ_Q04</message_structure>\n          </message_type>\n          <message_control_id>\n              <session_id>2022-05-02T14:02:11+02:00</session_id>\n              <message_num>1651492931</message_num>\n              <instance_num>0</instance_num>\n          </message_control_id>\n          <processing_id>\n              <processing_id>P</processing_id>\n              <processing_mode>I</processing_mode>\n          </processing_id>\n          <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n          <application_acknowledgement_type/>\n          <country_code>CH</country_code>\n          <project_id>Demo</project_id>\n      </message_header>\n      <request_header>\n          <result_waittime_ms>10000</result_waittime_ms>\n      </request_header>\n      <message_body>\n          <crcpdons:pdoheader>\n              <patient_set_limit>0</patient_set_limit>\n              <estimated_time>0</estimated_time>\n              <request_type>getPDO_fromInputList</request_type>\n          </crcpdons:pdoheader>\n          <crcpdons:request xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="crcpdons:GetPDOFromInputList_requestType">\n              <input_list>\n                  <patient_list max="1000000" min="0">\n                      <patient_set_coll_id>29</patient_set_coll_id>\n                  </patient_list>\n              </input_list>\n              <output_option name="none">\n                  <patient_set select="using_input_list" onlykeys="false" blob="false" techdata="false"/>\n              </output_option>\n          </crcpdons:request>\n      </message_body>\n  </msgns:request>	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns5:request xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <message_header>\n        <i2b2_version_compatible>0.3</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>GeCo i2b2 Data Source</application_name>\n            <application_version>0.2</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>GeCo</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>i2b2 cell</application_name>\n            <application_version>1.7</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-05-02T14:02:11+02:00</datetime_of_message>\n        <security>\n            <domain>i2b2demo</domain>\n            <username>demo</username>\n            <password is_token="false">password not stored</password>\n        </security>\n        <message_type>\n            <message_code>EQQ</message_code>\n            <event_type>Q04</event_type>\n            <message_structure>EQQ_Q04</message_structure>\n        </message_type>\n        <message_control_id>\n            <session_id>2022-05-02T14:02:11+02:00</session_id>\n            <message_num>1651492931</message_num>\n            <instance_num>0</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n        <application_acknowledgement_type></application_acknowledgement_type>\n        <country_code>CH</country_code>\n        <project_id>Demo</project_id>\n    </message_header>\n    <request_header>\n        <result_waittime_ms>10000</result_waittime_ms>\n    </request_header>\n    <message_body>\n        <ns3:pdoheader>\n            <patient_set_limit>0</patient_set_limit>\n            <estimated_time>0</estimated_time>\n            <request_type>getPDO_fromInputList</request_type>\n        </ns3:pdoheader>\n        <ns3:request xsi:type="ns3:GetPDOFromInputList_requestType" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">\n            <input_list>\n                <patient_list min="0" max="1000000">\n                    <patient_set_coll_id>29</patient_set_coll_id>\n                </patient_list>\n            </input_list>\n            <output_option>\n                <patient_set onlykeys="false" blob="false" techdata="false" select="using_input_list"/>\n            </output_option>\n        </ns3:request>\n    </message_body>\n</ns5:request>\n
16	demo	Demo	2022-05-02 12:02:11.798	<msgns:request xmlns:msgns="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:pdons="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ontns="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:crcpdons="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/" xmlns:crcpsmns="http://www.i2b2.org/xsd/cell/crc/psm/1.1/">\n      <message_header>\n          <i2b2_version_compatible>0.3</i2b2_version_compatible>\n          <hl7_version_compatible>2.4</hl7_version_compatible>\n          <sending_application>\n              <application_name>GeCo i2b2 Data Source</application_name>\n              <application_version>0.2</application_version>\n          </sending_application>\n          <sending_facility>\n              <facility_name>GeCo</facility_name>\n          </sending_facility>\n          <receiving_application>\n              <application_name>i2b2 cell</application_name>\n              <application_version>1.7</application_version>\n          </receiving_application>\n          <receiving_facility>\n              <facility_name>i2b2 hive</facility_name>\n          </receiving_facility>\n          <datetime_of_message>2022-05-02T14:02:11+02:00</datetime_of_message>\n          <security>\n              <domain>i2b2demo</domain>\n              <username>demo</username>\n              <password>*********</password>\n          </security>\n          <message_type>\n              <message_code>EQQ</message_code>\n              <event_type>Q04</event_type>\n              <message_structure>EQQ_Q04</message_structure>\n          </message_type>\n          <message_control_id>\n              <session_id>2022-05-02T14:02:11+02:00</session_id>\n              <message_num>1651492931</message_num>\n              <instance_num>0</instance_num>\n          </message_control_id>\n          <processing_id>\n              <processing_id>P</processing_id>\n              <processing_mode>I</processing_mode>\n          </processing_id>\n          <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n          <application_acknowledgement_type/>\n          <country_code>CH</country_code>\n          <project_id>Demo</project_id>\n      </message_header>\n      <request_header>\n          <result_waittime_ms>10000</result_waittime_ms>\n      </request_header>\n      <message_body>\n          <crcpdons:pdoheader>\n              <patient_set_limit>0</patient_set_limit>\n              <estimated_time>0</estimated_time>\n              <request_type>getPDO_fromInputList</request_type>\n          </crcpdons:pdoheader>\n          <crcpdons:request xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="crcpdons:GetPDOFromInputList_requestType">\n              <input_list>\n                  <patient_list max="1000000" min="0">\n                      <patient_set_coll_id>31</patient_set_coll_id>\n                  </patient_list>\n              </input_list>\n              <output_option name="none">\n                  <patient_set select="using_input_list" onlykeys="false" blob="false" techdata="false"/>\n              </output_option>\n          </crcpdons:request>\n      </message_body>\n  </msgns:request>	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns5:request xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <message_header>\n        <i2b2_version_compatible>0.3</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>GeCo i2b2 Data Source</application_name>\n            <application_version>0.2</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>GeCo</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>i2b2 cell</application_name>\n            <application_version>1.7</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-05-02T14:02:11+02:00</datetime_of_message>\n        <security>\n            <domain>i2b2demo</domain>\n            <username>demo</username>\n            <password is_token="false">password not stored</password>\n        </security>\n        <message_type>\n            <message_code>EQQ</message_code>\n            <event_type>Q04</event_type>\n            <message_structure>EQQ_Q04</message_structure>\n        </message_type>\n        <message_control_id>\n            <session_id>2022-05-02T14:02:11+02:00</session_id>\n            <message_num>1651492931</message_num>\n            <instance_num>0</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n        <application_acknowledgement_type></application_acknowledgement_type>\n        <country_code>CH</country_code>\n        <project_id>Demo</project_id>\n    </message_header>\n    <request_header>\n        <result_waittime_ms>10000</result_waittime_ms>\n    </request_header>\n    <message_body>\n        <ns3:pdoheader>\n            <patient_set_limit>0</patient_set_limit>\n            <estimated_time>0</estimated_time>\n            <request_type>getPDO_fromInputList</request_type>\n        </ns3:pdoheader>\n        <ns3:request xsi:type="ns3:GetPDOFromInputList_requestType" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">\n            <input_list>\n                <patient_list min="0" max="1000000">\n                    <patient_set_coll_id>31</patient_set_coll_id>\n                </patient_list>\n            </input_list>\n            <output_option>\n                <patient_set onlykeys="false" blob="false" techdata="false" select="using_input_list"/>\n            </output_option>\n        </ns3:request>\n    </message_body>\n</ns5:request>\n
17	demo	Demo	2022-05-02 12:02:12.202	<msgns:request xmlns:msgns="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:pdons="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ontns="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:crcpdons="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/" xmlns:crcpsmns="http://www.i2b2.org/xsd/cell/crc/psm/1.1/">\n      <message_header>\n          <i2b2_version_compatible>0.3</i2b2_version_compatible>\n          <hl7_version_compatible>2.4</hl7_version_compatible>\n          <sending_application>\n              <application_name>GeCo i2b2 Data Source</application_name>\n              <application_version>0.2</application_version>\n          </sending_application>\n          <sending_facility>\n              <facility_name>GeCo</facility_name>\n          </sending_facility>\n          <receiving_application>\n              <application_name>i2b2 cell</application_name>\n              <application_version>1.7</application_version>\n          </receiving_application>\n          <receiving_facility>\n              <facility_name>i2b2 hive</facility_name>\n          </receiving_facility>\n          <datetime_of_message>2022-05-02T14:02:12+02:00</datetime_of_message>\n          <security>\n              <domain>i2b2demo</domain>\n              <username>demo</username>\n              <password>*********</password>\n          </security>\n          <message_type>\n              <message_code>EQQ</message_code>\n              <event_type>Q04</event_type>\n              <message_structure>EQQ_Q04</message_structure>\n          </message_type>\n          <message_control_id>\n              <session_id>2022-05-02T14:02:12+02:00</session_id>\n              <message_num>1651492932</message_num>\n              <instance_num>0</instance_num>\n          </message_control_id>\n          <processing_id>\n              <processing_id>P</processing_id>\n              <processing_mode>I</processing_mode>\n          </processing_id>\n          <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n          <application_acknowledgement_type/>\n          <country_code>CH</country_code>\n          <project_id>Demo</project_id>\n      </message_header>\n      <request_header>\n          <result_waittime_ms>10000</result_waittime_ms>\n      </request_header>\n      <message_body>\n          <crcpdons:pdoheader>\n              <patient_set_limit>0</patient_set_limit>\n              <estimated_time>0</estimated_time>\n              <request_type>getPDO_fromInputList</request_type>\n          </crcpdons:pdoheader>\n          <crcpdons:request xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="crcpdons:GetPDOFromInputList_requestType">\n              <input_list>\n                  <patient_list max="1000000" min="0">\n                      <patient_set_coll_id>33</patient_set_coll_id>\n                  </patient_list>\n              </input_list>\n              <output_option name="none">\n                  <patient_set select="using_input_list" onlykeys="false" blob="false" techdata="false"/>\n              </output_option>\n          </crcpdons:request>\n      </message_body>\n  </msgns:request>	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns5:request xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <message_header>\n        <i2b2_version_compatible>0.3</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>GeCo i2b2 Data Source</application_name>\n            <application_version>0.2</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>GeCo</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>i2b2 cell</application_name>\n            <application_version>1.7</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-05-02T14:02:12+02:00</datetime_of_message>\n        <security>\n            <domain>i2b2demo</domain>\n            <username>demo</username>\n            <password is_token="false">password not stored</password>\n        </security>\n        <message_type>\n            <message_code>EQQ</message_code>\n            <event_type>Q04</event_type>\n            <message_structure>EQQ_Q04</message_structure>\n        </message_type>\n        <message_control_id>\n            <session_id>2022-05-02T14:02:12+02:00</session_id>\n            <message_num>1651492932</message_num>\n            <instance_num>0</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n        <application_acknowledgement_type></application_acknowledgement_type>\n        <country_code>CH</country_code>\n        <project_id>Demo</project_id>\n    </message_header>\n    <request_header>\n        <result_waittime_ms>10000</result_waittime_ms>\n    </request_header>\n    <message_body>\n        <ns3:pdoheader>\n            <patient_set_limit>0</patient_set_limit>\n            <estimated_time>0</estimated_time>\n            <request_type>getPDO_fromInputList</request_type>\n        </ns3:pdoheader>\n        <ns3:request xsi:type="ns3:GetPDOFromInputList_requestType" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">\n            <input_list>\n                <patient_list min="0" max="1000000">\n                    <patient_set_coll_id>33</patient_set_coll_id>\n                </patient_list>\n            </input_list>\n            <output_option>\n                <patient_set onlykeys="false" blob="false" techdata="false" select="using_input_list"/>\n            </output_option>\n        </ns3:request>\n    </message_body>\n</ns5:request>\n
18	demo	Demo	2022-05-02 12:02:12.86	<msgns:request xmlns:msgns="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:pdons="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ontns="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:crcpdons="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/" xmlns:crcpsmns="http://www.i2b2.org/xsd/cell/crc/psm/1.1/">\n      <message_header>\n          <i2b2_version_compatible>0.3</i2b2_version_compatible>\n          <hl7_version_compatible>2.4</hl7_version_compatible>\n          <sending_application>\n              <application_name>GeCo i2b2 Data Source</application_name>\n              <application_version>0.2</application_version>\n          </sending_application>\n          <sending_facility>\n              <facility_name>GeCo</facility_name>\n          </sending_facility>\n          <receiving_application>\n              <application_name>i2b2 cell</application_name>\n              <application_version>1.7</application_version>\n          </receiving_application>\n          <receiving_facility>\n              <facility_name>i2b2 hive</facility_name>\n          </receiving_facility>\n          <datetime_of_message>2022-05-02T14:02:12+02:00</datetime_of_message>\n          <security>\n              <domain>i2b2demo</domain>\n              <username>demo</username>\n              <password>*********</password>\n          </security>\n          <message_type>\n              <message_code>EQQ</message_code>\n              <event_type>Q04</event_type>\n              <message_structure>EQQ_Q04</message_structure>\n          </message_type>\n          <message_control_id>\n              <session_id>2022-05-02T14:02:12+02:00</session_id>\n              <message_num>1651492932</message_num>\n              <instance_num>0</instance_num>\n          </message_control_id>\n          <processing_id>\n              <processing_id>P</processing_id>\n              <processing_mode>I</processing_mode>\n          </processing_id>\n          <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n          <application_acknowledgement_type/>\n          <country_code>CH</country_code>\n          <project_id>Demo</project_id>\n      </message_header>\n      <request_header>\n          <result_waittime_ms>10000</result_waittime_ms>\n      </request_header>\n      <message_body>\n          <crcpdons:pdoheader>\n              <patient_set_limit>0</patient_set_limit>\n              <estimated_time>0</estimated_time>\n              <request_type>getPDO_fromInputList</request_type>\n          </crcpdons:pdoheader>\n          <crcpdons:request xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="crcpdons:GetPDOFromInputList_requestType">\n              <input_list>\n                  <patient_list max="1000000" min="0">\n                      <patient_set_coll_id>37</patient_set_coll_id>\n                  </patient_list>\n              </input_list>\n              <output_option name="none">\n                  <patient_set select="using_input_list" onlykeys="false" blob="false" techdata="false"/>\n              </output_option>\n          </crcpdons:request>\n      </message_body>\n  </msgns:request>	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns5:request xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <message_header>\n        <i2b2_version_compatible>0.3</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>GeCo i2b2 Data Source</application_name>\n            <application_version>0.2</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>GeCo</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>i2b2 cell</application_name>\n            <application_version>1.7</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-05-02T14:02:12+02:00</datetime_of_message>\n        <security>\n            <domain>i2b2demo</domain>\n            <username>demo</username>\n            <password is_token="false">password not stored</password>\n        </security>\n        <message_type>\n            <message_code>EQQ</message_code>\n            <event_type>Q04</event_type>\n            <message_structure>EQQ_Q04</message_structure>\n        </message_type>\n        <message_control_id>\n            <session_id>2022-05-02T14:02:12+02:00</session_id>\n            <message_num>1651492932</message_num>\n            <instance_num>0</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n        <application_acknowledgement_type></application_acknowledgement_type>\n        <country_code>CH</country_code>\n        <project_id>Demo</project_id>\n    </message_header>\n    <request_header>\n        <result_waittime_ms>10000</result_waittime_ms>\n    </request_header>\n    <message_body>\n        <ns3:pdoheader>\n            <patient_set_limit>0</patient_set_limit>\n            <estimated_time>0</estimated_time>\n            <request_type>getPDO_fromInputList</request_type>\n        </ns3:pdoheader>\n        <ns3:request xsi:type="ns3:GetPDOFromInputList_requestType" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">\n            <input_list>\n                <patient_list min="0" max="1000000">\n                    <patient_set_coll_id>37</patient_set_coll_id>\n                </patient_list>\n            </input_list>\n            <output_option>\n                <patient_set onlykeys="false" blob="false" techdata="false" select="using_input_list"/>\n            </output_option>\n        </ns3:request>\n    </message_body>\n</ns5:request>\n
19	demo	Demo	2022-05-02 12:02:12.865	<msgns:request xmlns:msgns="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:pdons="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ontns="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:crcpdons="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/" xmlns:crcpsmns="http://www.i2b2.org/xsd/cell/crc/psm/1.1/">\n      <message_header>\n          <i2b2_version_compatible>0.3</i2b2_version_compatible>\n          <hl7_version_compatible>2.4</hl7_version_compatible>\n          <sending_application>\n              <application_name>GeCo i2b2 Data Source</application_name>\n              <application_version>0.2</application_version>\n          </sending_application>\n          <sending_facility>\n              <facility_name>GeCo</facility_name>\n          </sending_facility>\n          <receiving_application>\n              <application_name>i2b2 cell</application_name>\n              <application_version>1.7</application_version>\n          </receiving_application>\n          <receiving_facility>\n              <facility_name>i2b2 hive</facility_name>\n          </receiving_facility>\n          <datetime_of_message>2022-05-02T14:02:12+02:00</datetime_of_message>\n          <security>\n              <domain>i2b2demo</domain>\n              <username>demo</username>\n              <password>*********</password>\n          </security>\n          <message_type>\n              <message_code>EQQ</message_code>\n              <event_type>Q04</event_type>\n              <message_structure>EQQ_Q04</message_structure>\n          </message_type>\n          <message_control_id>\n              <session_id>2022-05-02T14:02:12+02:00</session_id>\n              <message_num>1651492932</message_num>\n              <instance_num>0</instance_num>\n          </message_control_id>\n          <processing_id>\n              <processing_id>P</processing_id>\n              <processing_mode>I</processing_mode>\n          </processing_id>\n          <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n          <application_acknowledgement_type/>\n          <country_code>CH</country_code>\n          <project_id>Demo</project_id>\n      </message_header>\n      <request_header>\n          <result_waittime_ms>10000</result_waittime_ms>\n      </request_header>\n      <message_body>\n          <crcpdons:pdoheader>\n              <patient_set_limit>0</patient_set_limit>\n              <estimated_time>0</estimated_time>\n              <request_type>getPDO_fromInputList</request_type>\n          </crcpdons:pdoheader>\n          <crcpdons:request xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="crcpdons:GetPDOFromInputList_requestType">\n              <input_list>\n                  <patient_list max="1000000" min="0">\n                      <patient_set_coll_id>35</patient_set_coll_id>\n                  </patient_list>\n              </input_list>\n              <output_option name="none">\n                  <patient_set select="using_input_list" onlykeys="false" blob="false" techdata="false"/>\n              </output_option>\n          </crcpdons:request>\n      </message_body>\n  </msgns:request>	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns5:request xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <message_header>\n        <i2b2_version_compatible>0.3</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>GeCo i2b2 Data Source</application_name>\n            <application_version>0.2</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>GeCo</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>i2b2 cell</application_name>\n            <application_version>1.7</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-05-02T14:02:12+02:00</datetime_of_message>\n        <security>\n            <domain>i2b2demo</domain>\n            <username>demo</username>\n            <password is_token="false">password not stored</password>\n        </security>\n        <message_type>\n            <message_code>EQQ</message_code>\n            <event_type>Q04</event_type>\n            <message_structure>EQQ_Q04</message_structure>\n        </message_type>\n        <message_control_id>\n            <session_id>2022-05-02T14:02:12+02:00</session_id>\n            <message_num>1651492932</message_num>\n            <instance_num>0</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n        <application_acknowledgement_type></application_acknowledgement_type>\n        <country_code>CH</country_code>\n        <project_id>Demo</project_id>\n    </message_header>\n    <request_header>\n        <result_waittime_ms>10000</result_waittime_ms>\n    </request_header>\n    <message_body>\n        <ns3:pdoheader>\n            <patient_set_limit>0</patient_set_limit>\n            <estimated_time>0</estimated_time>\n            <request_type>getPDO_fromInputList</request_type>\n        </ns3:pdoheader>\n        <ns3:request xsi:type="ns3:GetPDOFromInputList_requestType" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">\n            <input_list>\n                <patient_list min="0" max="1000000">\n                    <patient_set_coll_id>35</patient_set_coll_id>\n                </patient_list>\n            </input_list>\n            <output_option>\n                <patient_set onlykeys="false" blob="false" techdata="false" select="using_input_list"/>\n            </output_option>\n        </ns3:request>\n    </message_body>\n</ns5:request>\n
\.


--
-- Data for Name: qt_privilege; Type: TABLE DATA; Schema: i2b2demodata; Owner: postgres
--

COPY i2b2demodata.qt_privilege (protection_label_cd, dataprot_cd, hivemgmt_cd, plugin_id) FROM stdin;
PDO_WITHOUT_BLOB	DATA_LDS	USER	\N
PDO_WITH_BLOB	DATA_DEID	USER	\N
SETFINDER_QRY_WITH_DATAOBFSC	DATA_OBFSC	USER	\N
SETFINDER_QRY_WITHOUT_DATAOBFSC	DATA_AGG	USER	\N
UPLOAD	DATA_OBFSC	MANAGER	\N
SETFINDER_QRY_WITH_LGTEXT	DATA_DEID	USER	\N
SETFINDER_QRY_PROTECTED	DATA_PROT	USER	\N
\.


--
-- Data for Name: qt_query_instance; Type: TABLE DATA; Schema: i2b2demodata; Owner: postgres
--

COPY i2b2demodata.qt_query_instance (query_instance_id, query_master_id, user_id, group_id, batch_mode, start_date, end_date, delete_flag, status_type_id, message) FROM stdin;
-100	-100	demo	Demo	FINISHED	2022-03-04 22:19:50.704	2022-03-04 22:19:51.664	N	3	
14	14	demo	Demo	FINISHED	2022-05-02 12:02:10.87	2022-05-02 12:02:11.01	N	3	
1	1	demo	Demo	FINISHED	2022-05-02 12:02:03.364	2022-05-02 12:02:03.917	N	3	
2	2	demo	Demo	FINISHED	2022-05-02 12:02:04.685	2022-05-02 12:02:05.224	N	3	
15	15	demo	Demo	FINISHED	2022-05-02 12:02:11.242	2022-05-02 12:02:11.379	N	3	
3	3	demo	Demo	FINISHED	2022-05-02 12:02:05.429	2022-05-02 12:02:05.618	N	3	
16	16	demo	Demo	FINISHED	2022-05-02 12:02:11.591	2022-05-02 12:02:11.747	N	3	
4	4	demo	Demo	FINISHED	2022-05-02 12:02:05.769	2022-05-02 12:02:05.938	N	3	
5	5	demo	Demo	FINISHED	2022-05-02 12:02:06.069	2022-05-02 12:02:06.379	N	3	
17	17	demo	Demo	FINISHED	2022-05-02 12:02:12.003	2022-05-02 12:02:12.162	N	3	
6	6	demo	Demo	FINISHED	2022-05-02 12:02:06.543	2022-05-02 12:02:06.817	N	3	
7	7	demo	Demo	FINISHED	2022-05-02 12:02:06.982	2022-05-02 12:02:07.16	N	3	
19	19	demo	Demo	FINISHED	2022-05-02 12:02:12.487	2022-05-02 12:02:12.781	N	3	
8	8	demo	Demo	FINISHED	2022-05-02 12:02:07.315	2022-05-02 12:02:07.64	N	3	
18	18	demo	Demo	FINISHED	2022-05-02 12:02:12.428	2022-05-02 12:02:12.792	N	3	
9	9	demo	Demo	FINISHED	2022-05-02 12:02:07.854	2022-05-02 12:02:08.136	N	3	
10	10	demo	Demo	FINISHED	2022-05-02 12:02:08.286	2022-05-02 12:02:08.646	N	3	
11	11	demo	Demo	FINISHED	2022-05-02 12:02:08.846	2022-05-02 12:02:09.079	N	3	
12	12	demo	Demo	FINISHED	2022-05-02 12:02:09.203	2022-05-02 12:02:09.47	N	3	
13	13	demo	Demo	FINISHED	2022-05-02 12:02:09.612	2022-05-02 12:02:09.79	N	3	
\.


--
-- Data for Name: qt_query_master; Type: TABLE DATA; Schema: i2b2demodata; Owner: postgres
--

COPY i2b2demodata.qt_query_master (query_master_id, name, user_id, group_id, master_type_cd, plugin_id, create_date, delete_date, delete_flag, request_xml, generated_sql, i2b2_request_xml, pm_xml) FROM stdin;
-100	63eb6d7e-d437-4f37-a346-4819ed1c74c1	demo	Demo	\N	\N	2022-03-04 22:19:50.602	\N	N	previous-query	generated-sql	i2b2_request_xml	pml-xml
1	99999999-9999-1122-0000-999999999999	demo	Demo	\N	\N	2022-05-02 12:02:03.254	\N	N	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns4:query_definition xmlns:ns2="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/">\n    <query_id>99999999-9999-1122-0000-999999999999</query_id>\n    <query_name>99999999-9999-1122-0000-999999999999</query_name>\n    <query_description>Query from GeCo i2b2 data source (99999999-9999-1122-0000-999999999999)</query_description>\n    <query_timing>ANY</query_timing>\n    <specificity_scale>0</specificity_scale>\n    <panel>\n        <panel_number>1</panel_number>\n        <panel_timing>ANY</panel_timing>\n        <panel_accuracy_scale>100</panel_accuracy_scale>\n        <invert>0</invert>\n        <total_item_occurrences>1</total_item_occurrences>\n        <item>\n            <hlevel>0</hlevel>\n            <item_name></item_name>\n            <item_key>\\\\TEST\\test\\1\\</item_key>\n            <item_icon></item_icon>\n            <tooltip></tooltip>\n            <class></class>\n            <item_is_synonym>false</item_is_synonym>\n        </item>\n    </panel>\n</ns4:query_definition>\n	insert into QUERY_GLOBAL_TEMP (patient_num, panel_count)\nwith t as ( \n select  f.patient_num  \nfrom i2b2demodata.observation_fact f \nwhere  \nf.concept_cd IN (select concept_cd from  i2b2demodata.concept_dimension   where concept_path LIKE '\\\\test\\\\1\\\\%')   \ngroup by  f.patient_num \n ) \nselect  t.patient_num, 0 as panel_count  from t \n<*>\n insert into DX (  patient_num   ) select * from ( select distinct  patient_num  from QUERY_GLOBAL_TEMP where panel_count = 0 ) q	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns5:request xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <message_header>\n        <i2b2_version_compatible>0.3</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>GeCo i2b2 Data Source</application_name>\n            <application_version>0.2</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>GeCo</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>i2b2 cell</application_name>\n            <application_version>1.7</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-05-02T14:02:02+02:00</datetime_of_message>\n        <security>\n            <domain>i2b2demo</domain>\n            <username>demo</username>\n            <password is_token="false">password not stored</password>\n        </security>\n        <message_type>\n            <message_code>EQQ</message_code>\n            <event_type>Q04</event_type>\n            <message_structure>EQQ_Q04</message_structure>\n        </message_type>\n        <message_control_id>\n            <session_id>2022-05-02T14:02:02+02:00</session_id>\n            <message_num>1651492922</message_num>\n            <instance_num>0</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n        <application_acknowledgement_type></application_acknowledgement_type>\n        <country_code>CH</country_code>\n        <project_id>Demo</project_id>\n    </message_header>\n    <request_header>\n        <result_waittime_ms>10000</result_waittime_ms>\n    </request_header>\n    <message_body>\n        <ns4:psmheader>\n            <user login="demo" group="i2b2demo">demo</user>\n            <patient_set_limit>0</patient_set_limit>\n            <estimated_time>0</estimated_time>\n            <query_mode>optimize_without_temp_table</query_mode>\n            <request_type>CRC_QRY_runQueryInstance_fromQueryDefinition</request_type>\n        </ns4:psmheader>\n        <ns4:request xsi:type="ns4:query_definition_requestType" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">\n            <query_definition>\n                <query_id>99999999-9999-1122-0000-999999999999</query_id>\n                <query_name>99999999-9999-1122-0000-999999999999</query_name>\n                <query_description>Query from GeCo i2b2 data source (99999999-9999-1122-0000-999999999999)</query_description>\n                <query_timing>ANY</query_timing>\n                <specificity_scale>0</specificity_scale>\n                <panel>\n                    <panel_number>1</panel_number>\n                    <panel_timing>ANY</panel_timing>\n                    <panel_accuracy_scale>100</panel_accuracy_scale>\n                    <invert>0</invert>\n                    <total_item_occurrences>1</total_item_occurrences>\n                    <item>\n                        <hlevel>0</hlevel>\n                        <item_name></item_name>\n                        <item_key>\\\\TEST\\test\\1\\</item_key>\n                        <item_icon></item_icon>\n                        <tooltip></tooltip>\n                        <class></class>\n                        <item_is_synonym>false</item_is_synonym>\n                    </item>\n                </panel>\n            </query_definition>\n            <result_output_list>\n                <result_output name="PATIENTSET" priority_index="1"/>\n                <result_output name="PATIENT_COUNT_XML" priority_index="2"/>\n            </result_output_list>\n        </ns4:request>\n    </message_body>\n</ns5:request>\n	<ns2:response xmlns:ns2="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/hive/msg/version/">\n    <message_header>\n        <i2b2_version_compatible>1.1</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>PM Cell</application_name>\n            <application_version>1.700</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>i2b2 Hive</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>PM Cell</application_name>\n            <application_version>1.700</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 Hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-05-02T12:02:03.318Z</datetime_of_message>\n        <message_control_id>\n            <instance_num>1</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>AL</accept_acknowledgement_type>\n        <application_acknowledgement_type>AL</application_acknowledgement_type>\n        <country_code>US</country_code>\n        <project_id/>\n    </message_header>\n    <response_header>\n        <result_status>\n            <status type="DONE">PM processing completed</status>\n        </result_status>\n    </response_header>\n    <message_body>\n        <ns4:configure>\n            <environment>DEVELOPMENT</environment>\n            <helpURL>http://www.i2b2.org</helpURL>\n            <user>\n                <full_name>i2b2 User</full_name>\n                <user_name>demo</user_name>\n                <password is_token="true" token_ms_timeout="1800000">SessionKey:eQJgwLaFDmHkc5wXxEPy</password>\n                <domain>i2b2demo</domain>\n                <is_admin>false</is_admin>\n                <project id="Demo">\n                    <name>i2b2 Demo</name>\n                    <wiki>http://www.i2b2.org</wiki>\n                    <path>/Demo</path>\n                    <role>DATA_AGG</role>\n                    <role>DATA_DEID</role>\n                    <role>DATA_LDS</role>\n                    <role>DATA_OBFSC</role>\n                    <role>DATA_PROT</role>\n                    <role>EDITOR</role>\n                    <role>USER</role>\n                </project>\n            </user>\n            <domain_name>i2b2demo</domain_name>\n            <domain_id>i2b2demo</domain_id>\n            <active>true</active>\n            <cell_datas>\n                <cell_data id="CRC">\n                    <name>Data Repository</name>\n                    <url>http://i2b2:8080/i2b2/services/QueryToolService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="FRC">\n                    <name>File Repository </name>\n                    <url>http://i2b2:8080/i2b2/services/FRService/</url>\n                    <project_path>/</project_path>\n                    <method>SOAP</method>\n                    <can_override>true</can_override>\n                    <param name="DestDir" id="1" datatype="T">/opt/jboss/wildfly/standalone/data/i2b2_FR_files</param>\n                </cell_data>\n                <cell_data id="ONT">\n                    <name>Ontology Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/OntologyService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="WORK">\n                    <name>Workplace Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/WorkplaceService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="IM">\n                    <name>IM Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/IMService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n            </cell_datas>\n            <global_data/>\n        </ns4:configure>\n    </message_body>\n</ns2:response>
2	99999999-9999-9999-9999-999999999999	demo	Demo	\N	\N	2022-05-02 12:02:04.607	\N	N	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns4:query_definition xmlns:ns2="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/">\n    <query_id>99999999-9999-9999-9999-999999999999</query_id>\n    <query_name>99999999-9999-9999-9999-999999999999</query_name>\n    <query_description>Query from GeCo i2b2 data source (99999999-9999-9999-9999-999999999999)</query_description>\n    <query_timing>ANY</query_timing>\n    <specificity_scale>0</specificity_scale>\n    <panel>\n        <panel_number>1</panel_number>\n        <panel_timing>ANY</panel_timing>\n        <panel_accuracy_scale>100</panel_accuracy_scale>\n        <invert>0</invert>\n        <total_item_occurrences>1</total_item_occurrences>\n        <item>\n            <hlevel>0</hlevel>\n            <item_name></item_name>\n            <item_key>\\\\TEST\\test\\2\\</item_key>\n            <item_icon></item_icon>\n            <tooltip></tooltip>\n            <class></class>\n            <constrain_by_modifier>\n                <modifier_key>\\\\TEST\\modifiers2\\text\\</modifier_key>\n                <applied_path>\\test\\2\\</applied_path>\n                <constrain_by_value>\n                    <value_operator>LIKE[contains]</value_operator>\n                    <value_constraint>cd</value_constraint>\n                    <value_type>TEXT</value_type>\n                </constrain_by_value>\n            </constrain_by_modifier>\n            <item_is_synonym>false</item_is_synonym>\n        </item>\n    </panel>\n    <panel>\n        <panel_number>2</panel_number>\n        <panel_timing>ANY</panel_timing>\n        <panel_accuracy_scale>100</panel_accuracy_scale>\n        <invert>0</invert>\n        <total_item_occurrences>1</total_item_occurrences>\n        <item>\n            <hlevel>0</hlevel>\n            <item_name></item_name>\n            <item_key>\\\\TEST\\test\\1\\</item_key>\n            <item_icon></item_icon>\n            <tooltip></tooltip>\n            <class></class>\n            <constrain_by_value>\n                <value_operator>EQ</value_operator>\n                <value_constraint>10</value_constraint>\n                <value_type>NUMBER</value_type>\n            </constrain_by_value>\n            <item_is_synonym>false</item_is_synonym>\n        </item>\n        <item>\n            <hlevel>0</hlevel>\n            <item_name></item_name>\n            <item_key>\\\\TEST\\test\\3\\</item_key>\n            <item_icon></item_icon>\n            <tooltip></tooltip>\n            <class></class>\n            <constrain_by_value>\n                <value_operator>EQ</value_operator>\n                <value_constraint>20</value_constraint>\n                <value_type>NUMBER</value_type>\n            </constrain_by_value>\n            <item_is_synonym>false</item_is_synonym>\n        </item>\n    </panel>\n</ns4:query_definition>\n	insert into QUERY_GLOBAL_TEMP (patient_num, panel_count)\nwith t as ( \n select  f.patient_num  \nfrom i2b2demodata.observation_fact f \nwhere  \nf.concept_cd IN (select concept_cd from  i2b2demodata.concept_dimension   where concept_path LIKE '\\\\test\\\\2\\\\%')  \n AND  (f.modifier_cd IN  (select modifier_cd from i2b2demodata.modifier_dimension where modifier_path LIKE '\\\\modifiers2\\\\text\\\\%')) \n  AND  (  valtype_cd = 'T' AND tval_char LIKE '%cd%' ) \ngroup by  f.patient_num \n ) \nselect  t.patient_num, 0 as panel_count  from t \n<*>\nupdate QUERY_GLOBAL_TEMP set panel_count =1 where QUERY_GLOBAL_TEMP.panel_count =  0 and exists ( select 1 from ( select  f.patient_num  \nfrom i2b2demodata.observation_fact f \nwhere  \nf.concept_cd IN (select concept_cd from  i2b2demodata.concept_dimension   where concept_path LIKE '\\\\test\\\\1\\\\%')  \n  AND  (  modifier_cd = '@'  AND     valtype_cd = 'N' AND   nval_num  = 10 AND  tval_char='E'  ) \ngroup by  f.patient_num ) t where QUERY_GLOBAL_TEMP.patient_num = t.patient_num    ) \n<*>\nupdate QUERY_GLOBAL_TEMP set panel_count =1 where QUERY_GLOBAL_TEMP.panel_count =  0 and exists ( select 1 from ( select  f.patient_num  \nfrom i2b2demodata.observation_fact f \nwhere  \nf.concept_cd IN (select concept_cd from  i2b2demodata.concept_dimension   where concept_path LIKE '\\\\test\\\\3\\\\%')  \n  AND  (  modifier_cd = '@'  AND     valtype_cd = 'N' AND   nval_num  = 20 AND  tval_char='E'  ) \ngroup by  f.patient_num ) t where QUERY_GLOBAL_TEMP.patient_num = t.patient_num    ) \n<*>\n insert into DX (  patient_num   ) select * from ( select distinct  patient_num  from QUERY_GLOBAL_TEMP where panel_count = 1 ) q	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns5:request xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <message_header>\n        <i2b2_version_compatible>0.3</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>GeCo i2b2 Data Source</application_name>\n            <application_version>0.2</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>GeCo</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>i2b2 cell</application_name>\n            <application_version>1.7</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-05-02T14:02:04+02:00</datetime_of_message>\n        <security>\n            <domain>i2b2demo</domain>\n            <username>demo</username>\n            <password is_token="false">password not stored</password>\n        </security>\n        <message_type>\n            <message_code>EQQ</message_code>\n            <event_type>Q04</event_type>\n            <message_structure>EQQ_Q04</message_structure>\n        </message_type>\n        <message_control_id>\n            <session_id>2022-05-02T14:02:04+02:00</session_id>\n            <message_num>1651492924</message_num>\n            <instance_num>0</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n        <application_acknowledgement_type></application_acknowledgement_type>\n        <country_code>CH</country_code>\n        <project_id>Demo</project_id>\n    </message_header>\n    <request_header>\n        <result_waittime_ms>10000</result_waittime_ms>\n    </request_header>\n    <message_body>\n        <ns4:psmheader>\n            <user login="demo" group="i2b2demo">demo</user>\n            <patient_set_limit>0</patient_set_limit>\n            <estimated_time>0</estimated_time>\n            <query_mode>optimize_without_temp_table</query_mode>\n            <request_type>CRC_QRY_runQueryInstance_fromQueryDefinition</request_type>\n        </ns4:psmheader>\n        <ns4:request xsi:type="ns4:query_definition_requestType" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">\n            <query_definition>\n                <query_id>99999999-9999-9999-9999-999999999999</query_id>\n                <query_name>99999999-9999-9999-9999-999999999999</query_name>\n                <query_description>Query from GeCo i2b2 data source (99999999-9999-9999-9999-999999999999)</query_description>\n                <query_timing>ANY</query_timing>\n                <specificity_scale>0</specificity_scale>\n                <panel>\n                    <panel_number>1</panel_number>\n                    <panel_timing>ANY</panel_timing>\n                    <panel_accuracy_scale>100</panel_accuracy_scale>\n                    <invert>0</invert>\n                    <total_item_occurrences>1</total_item_occurrences>\n                    <item>\n                        <hlevel>0</hlevel>\n                        <item_name></item_name>\n                        <item_key>\\\\TEST\\test\\2\\</item_key>\n                        <item_icon></item_icon>\n                        <tooltip></tooltip>\n                        <class></class>\n                        <constrain_by_modifier>\n                            <modifier_key>\\\\TEST\\modifiers2\\text\\</modifier_key>\n                            <applied_path>\\test\\2\\</applied_path>\n                            <constrain_by_value>\n                                <value_operator>LIKE[contains]</value_operator>\n                                <value_constraint>cd</value_constraint>\n                                <value_type>TEXT</value_type>\n                            </constrain_by_value>\n                        </constrain_by_modifier>\n                        <item_is_synonym>false</item_is_synonym>\n                    </item>\n                </panel>\n                <panel>\n                    <panel_number>2</panel_number>\n                    <panel_timing>ANY</panel_timing>\n                    <panel_accuracy_scale>100</panel_accuracy_scale>\n                    <invert>0</invert>\n                    <total_item_occurrences>1</total_item_occurrences>\n                    <item>\n                        <hlevel>0</hlevel>\n                        <item_name></item_name>\n                        <item_key>\\\\TEST\\test\\1\\</item_key>\n                        <item_icon></item_icon>\n                        <tooltip></tooltip>\n                        <class></class>\n                        <constrain_by_value>\n                            <value_operator>EQ</value_operator>\n                            <value_constraint>10</value_constraint>\n                            <value_type>NUMBER</value_type>\n                        </constrain_by_value>\n                        <item_is_synonym>false</item_is_synonym>\n                    </item>\n                    <item>\n                        <hlevel>0</hlevel>\n                        <item_name></item_name>\n                        <item_key>\\\\TEST\\test\\3\\</item_key>\n                        <item_icon></item_icon>\n                        <tooltip></tooltip>\n                        <class></class>\n                        <constrain_by_value>\n                            <value_operator>EQ</value_operator>\n                            <value_constraint>20</value_constraint>\n                            <value_type>NUMBER</value_type>\n                        </constrain_by_value>\n                        <item_is_synonym>false</item_is_synonym>\n                    </item>\n                </panel>\n            </query_definition>\n            <result_output_list>\n                <result_output name="PATIENTSET" priority_index="1"/>\n                <result_output name="PATIENT_COUNT_XML" priority_index="2"/>\n            </result_output_list>\n        </ns4:request>\n    </message_body>\n</ns5:request>\n	<ns2:response xmlns:ns2="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/hive/msg/version/">\n    <message_header>\n        <i2b2_version_compatible>1.1</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>PM Cell</application_name>\n            <application_version>1.700</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>i2b2 Hive</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>PM Cell</application_name>\n            <application_version>1.700</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 Hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-05-02T12:02:04.655Z</datetime_of_message>\n        <message_control_id>\n            <instance_num>1</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>AL</accept_acknowledgement_type>\n        <application_acknowledgement_type>AL</application_acknowledgement_type>\n        <country_code>US</country_code>\n        <project_id/>\n    </message_header>\n    <response_header>\n        <result_status>\n            <status type="DONE">PM processing completed</status>\n        </result_status>\n    </response_header>\n    <message_body>\n        <ns4:configure>\n            <environment>DEVELOPMENT</environment>\n            <helpURL>http://www.i2b2.org</helpURL>\n            <user>\n                <full_name>i2b2 User</full_name>\n                <user_name>demo</user_name>\n                <password is_token="true" token_ms_timeout="1800000">SessionKey:xRZ8EwrMCOqHdsBpFL9E</password>\n                <domain>i2b2demo</domain>\n                <is_admin>false</is_admin>\n                <project id="Demo">\n                    <name>i2b2 Demo</name>\n                    <wiki>http://www.i2b2.org</wiki>\n                    <path>/Demo</path>\n                    <role>DATA_AGG</role>\n                    <role>DATA_DEID</role>\n                    <role>DATA_LDS</role>\n                    <role>DATA_OBFSC</role>\n                    <role>DATA_PROT</role>\n                    <role>EDITOR</role>\n                    <role>USER</role>\n                </project>\n            </user>\n            <domain_name>i2b2demo</domain_name>\n            <domain_id>i2b2demo</domain_id>\n            <active>true</active>\n            <cell_datas>\n                <cell_data id="CRC">\n                    <name>Data Repository</name>\n                    <url>http://i2b2:8080/i2b2/services/QueryToolService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="FRC">\n                    <name>File Repository </name>\n                    <url>http://i2b2:8080/i2b2/services/FRService/</url>\n                    <project_path>/</project_path>\n                    <method>SOAP</method>\n                    <can_override>true</can_override>\n                    <param name="DestDir" id="1" datatype="T">/opt/jboss/wildfly/standalone/data/i2b2_FR_files</param>\n                </cell_data>\n                <cell_data id="ONT">\n                    <name>Ontology Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/OntologyService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="WORK">\n                    <name>Workplace Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/WorkplaceService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="IM">\n                    <name>IM Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/IMService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n            </cell_datas>\n            <global_data/>\n        </ns4:configure>\n    </message_body>\n</ns2:response>
3	0	demo	Demo	\N	\N	2022-05-02 12:02:05.396	\N	N	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns4:query_definition xmlns:ns2="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/">\n    <query_id>0</query_id>\n    <query_name>0</query_name>\n    <query_description>Query from GeCo i2b2 data source (0)</query_description>\n    <query_timing>ANY</query_timing>\n    <specificity_scale>0</specificity_scale>\n    <panel>\n        <panel_number>1</panel_number>\n        <panel_timing>ANY</panel_timing>\n        <panel_accuracy_scale>100</panel_accuracy_scale>\n        <invert>0</invert>\n        <total_item_occurrences>1</total_item_occurrences>\n        <item>\n            <hlevel>0</hlevel>\n            <item_name></item_name>\n            <item_key>\\\\TEST\\test\\1\\</item_key>\n            <item_icon></item_icon>\n            <tooltip></tooltip>\n            <class></class>\n            <item_is_synonym>false</item_is_synonym>\n        </item>\n    </panel>\n</ns4:query_definition>\n	insert into QUERY_GLOBAL_TEMP (patient_num, panel_count)\nwith t as ( \n select  f.patient_num  \nfrom i2b2demodata.observation_fact f \nwhere  \nf.concept_cd IN (select concept_cd from  i2b2demodata.concept_dimension   where concept_path LIKE '\\\\test\\\\1\\\\%')   \ngroup by  f.patient_num \n ) \nselect  t.patient_num, 0 as panel_count  from t \n<*>\n insert into DX (  patient_num   ) select * from ( select distinct  patient_num  from QUERY_GLOBAL_TEMP where panel_count = 0 ) q	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns5:request xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <message_header>\n        <i2b2_version_compatible>0.3</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>GeCo i2b2 Data Source</application_name>\n            <application_version>0.2</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>GeCo</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>i2b2 cell</application_name>\n            <application_version>1.7</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-05-02T14:02:05+02:00</datetime_of_message>\n        <security>\n            <domain>i2b2demo</domain>\n            <username>demo</username>\n            <password is_token="false">password not stored</password>\n        </security>\n        <message_type>\n            <message_code>EQQ</message_code>\n            <event_type>Q04</event_type>\n            <message_structure>EQQ_Q04</message_structure>\n        </message_type>\n        <message_control_id>\n            <session_id>2022-05-02T14:02:05+02:00</session_id>\n            <message_num>1651492925</message_num>\n            <instance_num>0</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n        <application_acknowledgement_type></application_acknowledgement_type>\n        <country_code>CH</country_code>\n        <project_id>Demo</project_id>\n    </message_header>\n    <request_header>\n        <result_waittime_ms>10000</result_waittime_ms>\n    </request_header>\n    <message_body>\n        <ns4:psmheader>\n            <user login="demo" group="i2b2demo">demo</user>\n            <patient_set_limit>0</patient_set_limit>\n            <estimated_time>0</estimated_time>\n            <query_mode>optimize_without_temp_table</query_mode>\n            <request_type>CRC_QRY_runQueryInstance_fromQueryDefinition</request_type>\n        </ns4:psmheader>\n        <ns4:request xsi:type="ns4:query_definition_requestType" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">\n            <query_definition>\n                <query_id>0</query_id>\n                <query_name>0</query_name>\n                <query_description>Query from GeCo i2b2 data source (0)</query_description>\n                <query_timing>ANY</query_timing>\n                <specificity_scale>0</specificity_scale>\n                <panel>\n                    <panel_number>1</panel_number>\n                    <panel_timing>ANY</panel_timing>\n                    <panel_accuracy_scale>100</panel_accuracy_scale>\n                    <invert>0</invert>\n                    <total_item_occurrences>1</total_item_occurrences>\n                    <item>\n                        <hlevel>0</hlevel>\n                        <item_name></item_name>\n                        <item_key>\\\\TEST\\test\\1\\</item_key>\n                        <item_icon></item_icon>\n                        <tooltip></tooltip>\n                        <class></class>\n                        <item_is_synonym>false</item_is_synonym>\n                    </item>\n                </panel>\n            </query_definition>\n            <result_output_list>\n                <result_output name="PATIENTSET" priority_index="1"/>\n                <result_output name="PATIENT_COUNT_XML" priority_index="2"/>\n            </result_output_list>\n        </ns4:request>\n    </message_body>\n</ns5:request>\n	<ns2:response xmlns:ns2="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/hive/msg/version/">\n    <message_header>\n        <i2b2_version_compatible>1.1</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>PM Cell</application_name>\n            <application_version>1.700</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>i2b2 Hive</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>PM Cell</application_name>\n            <application_version>1.700</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 Hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-05-02T12:02:05.418Z</datetime_of_message>\n        <message_control_id>\n            <instance_num>1</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>AL</accept_acknowledgement_type>\n        <application_acknowledgement_type>AL</application_acknowledgement_type>\n        <country_code>US</country_code>\n        <project_id/>\n    </message_header>\n    <response_header>\n        <result_status>\n            <status type="DONE">PM processing completed</status>\n        </result_status>\n    </response_header>\n    <message_body>\n        <ns4:configure>\n            <environment>DEVELOPMENT</environment>\n            <helpURL>http://www.i2b2.org</helpURL>\n            <user>\n                <full_name>i2b2 User</full_name>\n                <user_name>demo</user_name>\n                <password is_token="true" token_ms_timeout="1800000">SessionKey:LakRYMgS115UJyzoCiRm</password>\n                <domain>i2b2demo</domain>\n                <is_admin>false</is_admin>\n                <project id="Demo">\n                    <name>i2b2 Demo</name>\n                    <wiki>http://www.i2b2.org</wiki>\n                    <path>/Demo</path>\n                    <role>DATA_AGG</role>\n                    <role>DATA_DEID</role>\n                    <role>DATA_LDS</role>\n                    <role>DATA_OBFSC</role>\n                    <role>DATA_PROT</role>\n                    <role>EDITOR</role>\n                    <role>USER</role>\n                </project>\n            </user>\n            <domain_name>i2b2demo</domain_name>\n            <domain_id>i2b2demo</domain_id>\n            <active>true</active>\n            <cell_datas>\n                <cell_data id="CRC">\n                    <name>Data Repository</name>\n                    <url>http://i2b2:8080/i2b2/services/QueryToolService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="FRC">\n                    <name>File Repository </name>\n                    <url>http://i2b2:8080/i2b2/services/FRService/</url>\n                    <project_path>/</project_path>\n                    <method>SOAP</method>\n                    <can_override>true</can_override>\n                    <param name="DestDir" id="1" datatype="T">/opt/jboss/wildfly/standalone/data/i2b2_FR_files</param>\n                </cell_data>\n                <cell_data id="ONT">\n                    <name>Ontology Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/OntologyService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="WORK">\n                    <name>Workplace Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/WorkplaceService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="IM">\n                    <name>IM Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/IMService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n            </cell_datas>\n            <global_data/>\n        </ns4:configure>\n    </message_body>\n</ns2:response>
4	1	demo	Demo	\N	\N	2022-05-02 12:02:05.733	\N	N	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns4:query_definition xmlns:ns2="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/">\n    <query_id>1</query_id>\n    <query_name>1</query_name>\n    <query_description>Query from GeCo i2b2 data source (1)</query_description>\n    <query_timing>ANY</query_timing>\n    <specificity_scale>0</specificity_scale>\n    <panel>\n        <panel_number>1</panel_number>\n        <panel_timing>ANY</panel_timing>\n        <panel_accuracy_scale>100</panel_accuracy_scale>\n        <invert>0</invert>\n        <total_item_occurrences>1</total_item_occurrences>\n        <item>\n            <hlevel>0</hlevel>\n            <item_name></item_name>\n            <item_key>\\\\TEST\\test\\3\\</item_key>\n            <item_icon></item_icon>\n            <tooltip></tooltip>\n            <class></class>\n            <item_is_synonym>false</item_is_synonym>\n        </item>\n    </panel>\n</ns4:query_definition>\n	insert into QUERY_GLOBAL_TEMP (patient_num, panel_count)\nwith t as ( \n select  f.patient_num  \nfrom i2b2demodata.observation_fact f \nwhere  \nf.concept_cd IN (select concept_cd from  i2b2demodata.concept_dimension   where concept_path LIKE '\\\\test\\\\3\\\\%')   \ngroup by  f.patient_num \n ) \nselect  t.patient_num, 0 as panel_count  from t \n<*>\n insert into DX (  patient_num   ) select * from ( select distinct  patient_num  from QUERY_GLOBAL_TEMP where panel_count = 0 ) q	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns5:request xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <message_header>\n        <i2b2_version_compatible>0.3</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>GeCo i2b2 Data Source</application_name>\n            <application_version>0.2</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>GeCo</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>i2b2 cell</application_name>\n            <application_version>1.7</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-05-02T14:02:05+02:00</datetime_of_message>\n        <security>\n            <domain>i2b2demo</domain>\n            <username>demo</username>\n            <password is_token="false">password not stored</password>\n        </security>\n        <message_type>\n            <message_code>EQQ</message_code>\n            <event_type>Q04</event_type>\n            <message_structure>EQQ_Q04</message_structure>\n        </message_type>\n        <message_control_id>\n            <session_id>2022-05-02T14:02:05+02:00</session_id>\n            <message_num>1651492925</message_num>\n            <instance_num>0</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n        <application_acknowledgement_type></application_acknowledgement_type>\n        <country_code>CH</country_code>\n        <project_id>Demo</project_id>\n    </message_header>\n    <request_header>\n        <result_waittime_ms>10000</result_waittime_ms>\n    </request_header>\n    <message_body>\n        <ns4:psmheader>\n            <user login="demo" group="i2b2demo">demo</user>\n            <patient_set_limit>0</patient_set_limit>\n            <estimated_time>0</estimated_time>\n            <query_mode>optimize_without_temp_table</query_mode>\n            <request_type>CRC_QRY_runQueryInstance_fromQueryDefinition</request_type>\n        </ns4:psmheader>\n        <ns4:request xsi:type="ns4:query_definition_requestType" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">\n            <query_definition>\n                <query_id>1</query_id>\n                <query_name>1</query_name>\n                <query_description>Query from GeCo i2b2 data source (1)</query_description>\n                <query_timing>ANY</query_timing>\n                <specificity_scale>0</specificity_scale>\n                <panel>\n                    <panel_number>1</panel_number>\n                    <panel_timing>ANY</panel_timing>\n                    <panel_accuracy_scale>100</panel_accuracy_scale>\n                    <invert>0</invert>\n                    <total_item_occurrences>1</total_item_occurrences>\n                    <item>\n                        <hlevel>0</hlevel>\n                        <item_name></item_name>\n                        <item_key>\\\\TEST\\test\\3\\</item_key>\n                        <item_icon></item_icon>\n                        <tooltip></tooltip>\n                        <class></class>\n                        <item_is_synonym>false</item_is_synonym>\n                    </item>\n                </panel>\n            </query_definition>\n            <result_output_list>\n                <result_output name="PATIENTSET" priority_index="1"/>\n                <result_output name="PATIENT_COUNT_XML" priority_index="2"/>\n            </result_output_list>\n        </ns4:request>\n    </message_body>\n</ns5:request>\n	<ns2:response xmlns:ns2="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/hive/msg/version/">\n    <message_header>\n        <i2b2_version_compatible>1.1</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>PM Cell</application_name>\n            <application_version>1.700</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>i2b2 Hive</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>PM Cell</application_name>\n            <application_version>1.700</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 Hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-05-02T12:02:05.759Z</datetime_of_message>\n        <message_control_id>\n            <instance_num>1</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>AL</accept_acknowledgement_type>\n        <application_acknowledgement_type>AL</application_acknowledgement_type>\n        <country_code>US</country_code>\n        <project_id/>\n    </message_header>\n    <response_header>\n        <result_status>\n            <status type="DONE">PM processing completed</status>\n        </result_status>\n    </response_header>\n    <message_body>\n        <ns4:configure>\n            <environment>DEVELOPMENT</environment>\n            <helpURL>http://www.i2b2.org</helpURL>\n            <user>\n                <full_name>i2b2 User</full_name>\n                <user_name>demo</user_name>\n                <password is_token="true" token_ms_timeout="1800000">SessionKey:xtevImfZG4fafcJo4bow</password>\n                <domain>i2b2demo</domain>\n                <is_admin>false</is_admin>\n                <project id="Demo">\n                    <name>i2b2 Demo</name>\n                    <wiki>http://www.i2b2.org</wiki>\n                    <path>/Demo</path>\n                    <role>DATA_AGG</role>\n                    <role>DATA_DEID</role>\n                    <role>DATA_LDS</role>\n                    <role>DATA_OBFSC</role>\n                    <role>DATA_PROT</role>\n                    <role>EDITOR</role>\n                    <role>USER</role>\n                </project>\n            </user>\n            <domain_name>i2b2demo</domain_name>\n            <domain_id>i2b2demo</domain_id>\n            <active>true</active>\n            <cell_datas>\n                <cell_data id="CRC">\n                    <name>Data Repository</name>\n                    <url>http://i2b2:8080/i2b2/services/QueryToolService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="FRC">\n                    <name>File Repository </name>\n                    <url>http://i2b2:8080/i2b2/services/FRService/</url>\n                    <project_path>/</project_path>\n                    <method>SOAP</method>\n                    <can_override>true</can_override>\n                    <param name="DestDir" id="1" datatype="T">/opt/jboss/wildfly/standalone/data/i2b2_FR_files</param>\n                </cell_data>\n                <cell_data id="ONT">\n                    <name>Ontology Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/OntologyService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="WORK">\n                    <name>Workplace Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/WorkplaceService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="IM">\n                    <name>IM Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/IMService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n            </cell_datas>\n            <global_data/>\n        </ns4:configure>\n    </message_body>\n</ns2:response>
13	44444444-7777-4444-4444-444444444442	demo	Demo	\N	\N	2022-05-02 12:02:09.58	\N	N	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns4:query_definition xmlns:ns2="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/">\n    <query_id>44444444-7777-4444-4444-444444444442</query_id>\n    <query_name>44444444-7777-4444-4444-444444444442</query_name>\n    <query_description>Query from GeCo i2b2 data source (44444444-7777-4444-4444-444444444442)</query_description>\n    <query_timing>ANY</query_timing>\n    <specificity_scale>0</specificity_scale>\n    <panel>\n        <panel_number>1</panel_number>\n        <panel_timing>ANY</panel_timing>\n        <panel_accuracy_scale>100</panel_accuracy_scale>\n        <invert>0</invert>\n        <total_item_occurrences>1</total_item_occurrences>\n        <item>\n            <hlevel>0</hlevel>\n            <item_name></item_name>\n            <item_key>\\\\TEST\\test\\1\\</item_key>\n            <item_icon></item_icon>\n            <tooltip></tooltip>\n            <class></class>\n            <item_is_synonym>false</item_is_synonym>\n        </item>\n    </panel>\n</ns4:query_definition>\n	insert into QUERY_GLOBAL_TEMP (patient_num, panel_count)\nwith t as ( \n select  f.patient_num  \nfrom i2b2demodata.observation_fact f \nwhere  \nf.concept_cd IN (select concept_cd from  i2b2demodata.concept_dimension   where concept_path LIKE '\\\\test\\\\1\\\\%')   \ngroup by  f.patient_num \n ) \nselect  t.patient_num, 0 as panel_count  from t \n<*>\n insert into DX (  patient_num   ) select * from ( select distinct  patient_num  from QUERY_GLOBAL_TEMP where panel_count = 0 ) q	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns5:request xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <message_header>\n        <i2b2_version_compatible>0.3</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>GeCo i2b2 Data Source</application_name>\n            <application_version>0.2</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>GeCo</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>i2b2 cell</application_name>\n            <application_version>1.7</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-05-02T14:02:09+02:00</datetime_of_message>\n        <security>\n            <domain>i2b2demo</domain>\n            <username>demo</username>\n            <password is_token="false">password not stored</password>\n        </security>\n        <message_type>\n            <message_code>EQQ</message_code>\n            <event_type>Q04</event_type>\n            <message_structure>EQQ_Q04</message_structure>\n        </message_type>\n        <message_control_id>\n            <session_id>2022-05-02T14:02:09+02:00</session_id>\n            <message_num>1651492929</message_num>\n            <instance_num>0</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n        <application_acknowledgement_type></application_acknowledgement_type>\n        <country_code>CH</country_code>\n        <project_id>Demo</project_id>\n    </message_header>\n    <request_header>\n        <result_waittime_ms>10000</result_waittime_ms>\n    </request_header>\n    <message_body>\n        <ns4:psmheader>\n            <user login="demo" group="i2b2demo">demo</user>\n            <patient_set_limit>0</patient_set_limit>\n            <estimated_time>0</estimated_time>\n            <query_mode>optimize_without_temp_table</query_mode>\n            <request_type>CRC_QRY_runQueryInstance_fromQueryDefinition</request_type>\n        </ns4:psmheader>\n        <ns4:request xsi:type="ns4:query_definition_requestType" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">\n            <query_definition>\n                <query_id>44444444-7777-4444-4444-444444444442</query_id>\n                <query_name>44444444-7777-4444-4444-444444444442</query_name>\n                <query_description>Query from GeCo i2b2 data source (44444444-7777-4444-4444-444444444442)</query_description>\n                <query_timing>ANY</query_timing>\n                <specificity_scale>0</specificity_scale>\n                <panel>\n                    <panel_number>1</panel_number>\n                    <panel_timing>ANY</panel_timing>\n                    <panel_accuracy_scale>100</panel_accuracy_scale>\n                    <invert>0</invert>\n                    <total_item_occurrences>1</total_item_occurrences>\n                    <item>\n                        <hlevel>0</hlevel>\n                        <item_name></item_name>\n                        <item_key>\\\\TEST\\test\\1\\</item_key>\n                        <item_icon></item_icon>\n                        <tooltip></tooltip>\n                        <class></class>\n                        <item_is_synonym>false</item_is_synonym>\n                    </item>\n                </panel>\n            </query_definition>\n            <result_output_list>\n                <result_output name="PATIENTSET" priority_index="1"/>\n                <result_output name="PATIENT_COUNT_XML" priority_index="2"/>\n            </result_output_list>\n        </ns4:request>\n    </message_body>\n</ns5:request>\n	<ns2:response xmlns:ns2="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/hive/msg/version/">\n    <message_header>\n        <i2b2_version_compatible>1.1</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>PM Cell</application_name>\n            <application_version>1.700</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>i2b2 Hive</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>PM Cell</application_name>\n            <application_version>1.700</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 Hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-05-02T12:02:09.602Z</datetime_of_message>\n        <message_control_id>\n            <instance_num>1</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>AL</accept_acknowledgement_type>\n        <application_acknowledgement_type>AL</application_acknowledgement_type>\n        <country_code>US</country_code>\n        <project_id/>\n    </message_header>\n    <response_header>\n        <result_status>\n            <status type="DONE">PM processing completed</status>\n        </result_status>\n    </response_header>\n    <message_body>\n        <ns4:configure>\n            <environment>DEVELOPMENT</environment>\n            <helpURL>http://www.i2b2.org</helpURL>\n            <user>\n                <full_name>i2b2 User</full_name>\n                <user_name>demo</user_name>\n                <password is_token="true" token_ms_timeout="1800000">SessionKey:A752HWuIGQxQMobbIeRe</password>\n                <domain>i2b2demo</domain>\n                <is_admin>false</is_admin>\n                <project id="Demo">\n                    <name>i2b2 Demo</name>\n                    <wiki>http://www.i2b2.org</wiki>\n                    <path>/Demo</path>\n                    <role>DATA_AGG</role>\n                    <role>DATA_DEID</role>\n                    <role>DATA_LDS</role>\n                    <role>DATA_OBFSC</role>\n                    <role>DATA_PROT</role>\n                    <role>EDITOR</role>\n                    <role>USER</role>\n                </project>\n            </user>\n            <domain_name>i2b2demo</domain_name>\n            <domain_id>i2b2demo</domain_id>\n            <active>true</active>\n            <cell_datas>\n                <cell_data id="CRC">\n                    <name>Data Repository</name>\n                    <url>http://i2b2:8080/i2b2/services/QueryToolService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="FRC">\n                    <name>File Repository </name>\n                    <url>http://i2b2:8080/i2b2/services/FRService/</url>\n                    <project_path>/</project_path>\n                    <method>SOAP</method>\n                    <can_override>true</can_override>\n                    <param name="DestDir" id="1" datatype="T">/opt/jboss/wildfly/standalone/data/i2b2_FR_files</param>\n                </cell_data>\n                <cell_data id="ONT">\n                    <name>Ontology Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/OntologyService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="WORK">\n                    <name>Workplace Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/WorkplaceService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="IM">\n                    <name>IM Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/IMService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n            </cell_datas>\n            <global_data/>\n        </ns4:configure>\n    </message_body>\n</ns2:response>
5	2	demo	Demo	\N	\N	2022-05-02 12:02:06.036	\N	N	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns4:query_definition xmlns:ns2="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/">\n    <query_id>2</query_id>\n    <query_name>2</query_name>\n    <query_description>Query from GeCo i2b2 data source (2)</query_description>\n    <query_timing>ANY</query_timing>\n    <specificity_scale>0</specificity_scale>\n    <panel>\n        <panel_number>1</panel_number>\n        <panel_timing>ANY</panel_timing>\n        <panel_accuracy_scale>100</panel_accuracy_scale>\n        <invert>0</invert>\n        <total_item_occurrences>1</total_item_occurrences>\n        <item>\n            <hlevel>0</hlevel>\n            <item_name></item_name>\n            <item_key>\\\\TEST\\test\\1\\</item_key>\n            <item_icon></item_icon>\n            <tooltip></tooltip>\n            <class></class>\n            <item_is_synonym>false</item_is_synonym>\n        </item>\n    </panel>\n    <panel>\n        <panel_number>2</panel_number>\n        <panel_timing>ANY</panel_timing>\n        <panel_accuracy_scale>100</panel_accuracy_scale>\n        <invert>0</invert>\n        <total_item_occurrences>1</total_item_occurrences>\n        <item>\n            <hlevel>0</hlevel>\n            <item_name></item_name>\n            <item_key>\\\\TEST\\test\\2\\</item_key>\n            <item_icon></item_icon>\n            <tooltip></tooltip>\n            <class></class>\n            <item_is_synonym>false</item_is_synonym>\n        </item>\n    </panel>\n    <panel>\n        <panel_number>3</panel_number>\n        <panel_timing>ANY</panel_timing>\n        <panel_accuracy_scale>100</panel_accuracy_scale>\n        <invert>0</invert>\n        <total_item_occurrences>1</total_item_occurrences>\n        <item>\n            <hlevel>0</hlevel>\n            <item_name></item_name>\n            <item_key>\\\\TEST\\test\\3\\</item_key>\n            <item_icon></item_icon>\n            <tooltip></tooltip>\n            <class></class>\n            <item_is_synonym>false</item_is_synonym>\n        </item>\n    </panel>\n</ns4:query_definition>\n	insert into QUERY_GLOBAL_TEMP (patient_num, panel_count)\nwith t as ( \n select  f.patient_num  \nfrom i2b2demodata.observation_fact f \nwhere  \nf.concept_cd IN (select concept_cd from  i2b2demodata.concept_dimension   where concept_path LIKE '\\\\test\\\\1\\\\%')   \ngroup by  f.patient_num \n ) \nselect  t.patient_num, 0 as panel_count  from t \n<*>\nupdate QUERY_GLOBAL_TEMP set panel_count =1 where QUERY_GLOBAL_TEMP.panel_count =  0 and exists ( select 1 from ( select  f.patient_num  \nfrom i2b2demodata.observation_fact f \nwhere  \nf.concept_cd IN (select concept_cd from  i2b2demodata.concept_dimension   where concept_path LIKE '\\\\test\\\\2\\\\%')   \ngroup by  f.patient_num ) t where QUERY_GLOBAL_TEMP.patient_num = t.patient_num    ) \n<*>\nupdate QUERY_GLOBAL_TEMP set panel_count =2 where QUERY_GLOBAL_TEMP.panel_count =  1 and exists ( select 1 from ( select  f.patient_num  \nfrom i2b2demodata.observation_fact f \nwhere  \nf.concept_cd IN (select concept_cd from  i2b2demodata.concept_dimension   where concept_path LIKE '\\\\test\\\\3\\\\%')   \ngroup by  f.patient_num ) t where QUERY_GLOBAL_TEMP.patient_num = t.patient_num    ) \n<*>\n insert into DX (  patient_num   ) select * from ( select distinct  patient_num  from QUERY_GLOBAL_TEMP where panel_count = 2 ) q	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns5:request xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <message_header>\n        <i2b2_version_compatible>0.3</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>GeCo i2b2 Data Source</application_name>\n            <application_version>0.2</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>GeCo</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>i2b2 cell</application_name>\n            <application_version>1.7</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-05-02T14:02:05+02:00</datetime_of_message>\n        <security>\n            <domain>i2b2demo</domain>\n            <username>demo</username>\n            <password is_token="false">password not stored</password>\n        </security>\n        <message_type>\n            <message_code>EQQ</message_code>\n            <event_type>Q04</event_type>\n            <message_structure>EQQ_Q04</message_structure>\n        </message_type>\n        <message_control_id>\n            <session_id>2022-05-02T14:02:05+02:00</session_id>\n            <message_num>1651492925</message_num>\n            <instance_num>0</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n        <application_acknowledgement_type></application_acknowledgement_type>\n        <country_code>CH</country_code>\n        <project_id>Demo</project_id>\n    </message_header>\n    <request_header>\n        <result_waittime_ms>10000</result_waittime_ms>\n    </request_header>\n    <message_body>\n        <ns4:psmheader>\n            <user login="demo" group="i2b2demo">demo</user>\n            <patient_set_limit>0</patient_set_limit>\n            <estimated_time>0</estimated_time>\n            <query_mode>optimize_without_temp_table</query_mode>\n            <request_type>CRC_QRY_runQueryInstance_fromQueryDefinition</request_type>\n        </ns4:psmheader>\n        <ns4:request xsi:type="ns4:query_definition_requestType" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">\n            <query_definition>\n                <query_id>2</query_id>\n                <query_name>2</query_name>\n                <query_description>Query from GeCo i2b2 data source (2)</query_description>\n                <query_timing>ANY</query_timing>\n                <specificity_scale>0</specificity_scale>\n                <panel>\n                    <panel_number>1</panel_number>\n                    <panel_timing>ANY</panel_timing>\n                    <panel_accuracy_scale>100</panel_accuracy_scale>\n                    <invert>0</invert>\n                    <total_item_occurrences>1</total_item_occurrences>\n                    <item>\n                        <hlevel>0</hlevel>\n                        <item_name></item_name>\n                        <item_key>\\\\TEST\\test\\1\\</item_key>\n                        <item_icon></item_icon>\n                        <tooltip></tooltip>\n                        <class></class>\n                        <item_is_synonym>false</item_is_synonym>\n                    </item>\n                </panel>\n                <panel>\n                    <panel_number>2</panel_number>\n                    <panel_timing>ANY</panel_timing>\n                    <panel_accuracy_scale>100</panel_accuracy_scale>\n                    <invert>0</invert>\n                    <total_item_occurrences>1</total_item_occurrences>\n                    <item>\n                        <hlevel>0</hlevel>\n                        <item_name></item_name>\n                        <item_key>\\\\TEST\\test\\2\\</item_key>\n                        <item_icon></item_icon>\n                        <tooltip></tooltip>\n                        <class></class>\n                        <item_is_synonym>false</item_is_synonym>\n                    </item>\n                </panel>\n                <panel>\n                    <panel_number>3</panel_number>\n                    <panel_timing>ANY</panel_timing>\n                    <panel_accuracy_scale>100</panel_accuracy_scale>\n                    <invert>0</invert>\n                    <total_item_occurrences>1</total_item_occurrences>\n                    <item>\n                        <hlevel>0</hlevel>\n                        <item_name></item_name>\n                        <item_key>\\\\TEST\\test\\3\\</item_key>\n                        <item_icon></item_icon>\n                        <tooltip></tooltip>\n                        <class></class>\n                        <item_is_synonym>false</item_is_synonym>\n                    </item>\n                </panel>\n            </query_definition>\n            <result_output_list>\n                <result_output name="PATIENTSET" priority_index="1"/>\n                <result_output name="PATIENT_COUNT_XML" priority_index="2"/>\n            </result_output_list>\n        </ns4:request>\n    </message_body>\n</ns5:request>\n	<ns2:response xmlns:ns2="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/hive/msg/version/">\n    <message_header>\n        <i2b2_version_compatible>1.1</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>PM Cell</application_name>\n            <application_version>1.700</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>i2b2 Hive</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>PM Cell</application_name>\n            <application_version>1.700</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 Hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-05-02T12:02:06.060Z</datetime_of_message>\n        <message_control_id>\n            <instance_num>1</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>AL</accept_acknowledgement_type>\n        <application_acknowledgement_type>AL</application_acknowledgement_type>\n        <country_code>US</country_code>\n        <project_id/>\n    </message_header>\n    <response_header>\n        <result_status>\n            <status type="DONE">PM processing completed</status>\n        </result_status>\n    </response_header>\n    <message_body>\n        <ns4:configure>\n            <environment>DEVELOPMENT</environment>\n            <helpURL>http://www.i2b2.org</helpURL>\n            <user>\n                <full_name>i2b2 User</full_name>\n                <user_name>demo</user_name>\n                <password is_token="true" token_ms_timeout="1800000">SessionKey:63j3ww0OdraCGP5PCMdP</password>\n                <domain>i2b2demo</domain>\n                <is_admin>false</is_admin>\n                <project id="Demo">\n                    <name>i2b2 Demo</name>\n                    <wiki>http://www.i2b2.org</wiki>\n                    <path>/Demo</path>\n                    <role>DATA_AGG</role>\n                    <role>DATA_DEID</role>\n                    <role>DATA_LDS</role>\n                    <role>DATA_OBFSC</role>\n                    <role>DATA_PROT</role>\n                    <role>EDITOR</role>\n                    <role>USER</role>\n                </project>\n            </user>\n            <domain_name>i2b2demo</domain_name>\n            <domain_id>i2b2demo</domain_id>\n            <active>true</active>\n            <cell_datas>\n                <cell_data id="CRC">\n                    <name>Data Repository</name>\n                    <url>http://i2b2:8080/i2b2/services/QueryToolService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="FRC">\n                    <name>File Repository </name>\n                    <url>http://i2b2:8080/i2b2/services/FRService/</url>\n                    <project_path>/</project_path>\n                    <method>SOAP</method>\n                    <can_override>true</can_override>\n                    <param name="DestDir" id="1" datatype="T">/opt/jboss/wildfly/standalone/data/i2b2_FR_files</param>\n                </cell_data>\n                <cell_data id="ONT">\n                    <name>Ontology Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/OntologyService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="WORK">\n                    <name>Workplace Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/WorkplaceService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="IM">\n                    <name>IM Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/IMService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n            </cell_datas>\n            <global_data/>\n        </ns4:configure>\n    </message_body>\n</ns2:response>
6	3	demo	Demo	\N	\N	2022-05-02 12:02:06.501	\N	N	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns4:query_definition xmlns:ns2="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/">\n    <query_id>3</query_id>\n    <query_name>3</query_name>\n    <query_description>Query from GeCo i2b2 data source (3)</query_description>\n    <query_timing>ANY</query_timing>\n    <specificity_scale>0</specificity_scale>\n    <panel>\n        <panel_number>1</panel_number>\n        <panel_timing>ANY</panel_timing>\n        <panel_accuracy_scale>100</panel_accuracy_scale>\n        <invert>0</invert>\n        <total_item_occurrences>1</total_item_occurrences>\n        <item>\n            <hlevel>0</hlevel>\n            <item_name></item_name>\n            <item_key>\\\\TEST\\test\\1\\</item_key>\n            <item_icon></item_icon>\n            <tooltip></tooltip>\n            <class></class>\n            <item_is_synonym>false</item_is_synonym>\n        </item>\n        <item>\n            <hlevel>0</hlevel>\n            <item_name></item_name>\n            <item_key>\\\\TEST\\test\\3\\</item_key>\n            <item_icon></item_icon>\n            <tooltip></tooltip>\n            <class></class>\n            <item_is_synonym>false</item_is_synonym>\n        </item>\n    </panel>\n</ns4:query_definition>\n	insert into QUERY_GLOBAL_TEMP (patient_num, panel_count)\nwith t as ( \n select  f.patient_num  \nfrom i2b2demodata.observation_fact f \nwhere  \nf.concept_cd IN (select concept_cd from  i2b2demodata.concept_dimension   where concept_path LIKE '\\\\test\\\\1\\\\%')   \ngroup by  f.patient_num \n ) \nselect  t.patient_num, 0 as panel_count  from t \n<*>\ninsert into QUERY_GLOBAL_TEMP (patient_num, panel_count)\nwith t as ( \n select  f.patient_num  \nfrom i2b2demodata.observation_fact f \nwhere  \nf.concept_cd IN (select concept_cd from  i2b2demodata.concept_dimension   where concept_path LIKE '\\\\test\\\\3\\\\%')   \ngroup by  f.patient_num \n ) \nselect  t.patient_num, 0 as panel_count  from t \n<*>\n insert into DX (  patient_num   ) select * from ( select distinct  patient_num  from QUERY_GLOBAL_TEMP where panel_count = 0 ) q	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns5:request xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <message_header>\n        <i2b2_version_compatible>0.3</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>GeCo i2b2 Data Source</application_name>\n            <application_version>0.2</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>GeCo</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>i2b2 cell</application_name>\n            <application_version>1.7</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-05-02T14:02:06+02:00</datetime_of_message>\n        <security>\n            <domain>i2b2demo</domain>\n            <username>demo</username>\n            <password is_token="false">password not stored</password>\n        </security>\n        <message_type>\n            <message_code>EQQ</message_code>\n            <event_type>Q04</event_type>\n            <message_structure>EQQ_Q04</message_structure>\n        </message_type>\n        <message_control_id>\n            <session_id>2022-05-02T14:02:06+02:00</session_id>\n            <message_num>1651492926</message_num>\n            <instance_num>0</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n        <application_acknowledgement_type></application_acknowledgement_type>\n        <country_code>CH</country_code>\n        <project_id>Demo</project_id>\n    </message_header>\n    <request_header>\n        <result_waittime_ms>10000</result_waittime_ms>\n    </request_header>\n    <message_body>\n        <ns4:psmheader>\n            <user login="demo" group="i2b2demo">demo</user>\n            <patient_set_limit>0</patient_set_limit>\n            <estimated_time>0</estimated_time>\n            <query_mode>optimize_without_temp_table</query_mode>\n            <request_type>CRC_QRY_runQueryInstance_fromQueryDefinition</request_type>\n        </ns4:psmheader>\n        <ns4:request xsi:type="ns4:query_definition_requestType" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">\n            <query_definition>\n                <query_id>3</query_id>\n                <query_name>3</query_name>\n                <query_description>Query from GeCo i2b2 data source (3)</query_description>\n                <query_timing>ANY</query_timing>\n                <specificity_scale>0</specificity_scale>\n                <panel>\n                    <panel_number>1</panel_number>\n                    <panel_timing>ANY</panel_timing>\n                    <panel_accuracy_scale>100</panel_accuracy_scale>\n                    <invert>0</invert>\n                    <total_item_occurrences>1</total_item_occurrences>\n                    <item>\n                        <hlevel>0</hlevel>\n                        <item_name></item_name>\n                        <item_key>\\\\TEST\\test\\1\\</item_key>\n                        <item_icon></item_icon>\n                        <tooltip></tooltip>\n                        <class></class>\n                        <item_is_synonym>false</item_is_synonym>\n                    </item>\n                    <item>\n                        <hlevel>0</hlevel>\n                        <item_name></item_name>\n                        <item_key>\\\\TEST\\test\\3\\</item_key>\n                        <item_icon></item_icon>\n                        <tooltip></tooltip>\n                        <class></class>\n                        <item_is_synonym>false</item_is_synonym>\n                    </item>\n                </panel>\n            </query_definition>\n            <result_output_list>\n                <result_output name="PATIENTSET" priority_index="1"/>\n                <result_output name="PATIENT_COUNT_XML" priority_index="2"/>\n            </result_output_list>\n        </ns4:request>\n    </message_body>\n</ns5:request>\n	<ns2:response xmlns:ns2="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/hive/msg/version/">\n    <message_header>\n        <i2b2_version_compatible>1.1</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>PM Cell</application_name>\n            <application_version>1.700</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>i2b2 Hive</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>PM Cell</application_name>\n            <application_version>1.700</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 Hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-05-02T12:02:06.531Z</datetime_of_message>\n        <message_control_id>\n            <instance_num>1</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>AL</accept_acknowledgement_type>\n        <application_acknowledgement_type>AL</application_acknowledgement_type>\n        <country_code>US</country_code>\n        <project_id/>\n    </message_header>\n    <response_header>\n        <result_status>\n            <status type="DONE">PM processing completed</status>\n        </result_status>\n    </response_header>\n    <message_body>\n        <ns4:configure>\n            <environment>DEVELOPMENT</environment>\n            <helpURL>http://www.i2b2.org</helpURL>\n            <user>\n                <full_name>i2b2 User</full_name>\n                <user_name>demo</user_name>\n                <password is_token="true" token_ms_timeout="1800000">SessionKey:YR6rtpH5B8Rr5xcNhUqc</password>\n                <domain>i2b2demo</domain>\n                <is_admin>false</is_admin>\n                <project id="Demo">\n                    <name>i2b2 Demo</name>\n                    <wiki>http://www.i2b2.org</wiki>\n                    <path>/Demo</path>\n                    <role>DATA_AGG</role>\n                    <role>DATA_DEID</role>\n                    <role>DATA_LDS</role>\n                    <role>DATA_OBFSC</role>\n                    <role>DATA_PROT</role>\n                    <role>EDITOR</role>\n                    <role>USER</role>\n                </project>\n            </user>\n            <domain_name>i2b2demo</domain_name>\n            <domain_id>i2b2demo</domain_id>\n            <active>true</active>\n            <cell_datas>\n                <cell_data id="CRC">\n                    <name>Data Repository</name>\n                    <url>http://i2b2:8080/i2b2/services/QueryToolService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="FRC">\n                    <name>File Repository </name>\n                    <url>http://i2b2:8080/i2b2/services/FRService/</url>\n                    <project_path>/</project_path>\n                    <method>SOAP</method>\n                    <can_override>true</can_override>\n                    <param name="DestDir" id="1" datatype="T">/opt/jboss/wildfly/standalone/data/i2b2_FR_files</param>\n                </cell_data>\n                <cell_data id="ONT">\n                    <name>Ontology Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/OntologyService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="WORK">\n                    <name>Workplace Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/WorkplaceService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="IM">\n                    <name>IM Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/IMService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n            </cell_datas>\n            <global_data/>\n        </ns4:configure>\n    </message_body>\n</ns2:response>
7	0	demo	Demo	\N	\N	2022-05-02 12:02:06.945	\N	N	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns4:query_definition xmlns:ns2="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/">\n    <query_id>0</query_id>\n    <query_name>0</query_name>\n    <query_description>Query from GeCo i2b2 data source (0)</query_description>\n    <query_timing>ANY</query_timing>\n    <specificity_scale>0</specificity_scale>\n    <panel>\n        <panel_number>1</panel_number>\n        <panel_timing>ANY</panel_timing>\n        <panel_accuracy_scale>100</panel_accuracy_scale>\n        <invert>0</invert>\n        <total_item_occurrences>1</total_item_occurrences>\n        <item>\n            <hlevel>0</hlevel>\n            <item_name></item_name>\n            <item_key>\\\\TEST\\test\\1\\</item_key>\n            <item_icon></item_icon>\n            <tooltip></tooltip>\n            <class></class>\n            <constrain_by_value>\n                <value_operator>EQ</value_operator>\n                <value_constraint>10</value_constraint>\n                <value_type>NUMBER</value_type>\n            </constrain_by_value>\n            <item_is_synonym>false</item_is_synonym>\n        </item>\n    </panel>\n</ns4:query_definition>\n	insert into QUERY_GLOBAL_TEMP (patient_num, panel_count)\nwith t as ( \n select  f.patient_num  \nfrom i2b2demodata.observation_fact f \nwhere  \nf.concept_cd IN (select concept_cd from  i2b2demodata.concept_dimension   where concept_path LIKE '\\\\test\\\\1\\\\%')  \n  AND  (  modifier_cd = '@'  AND     valtype_cd = 'N' AND   nval_num  = 10 AND  tval_char='E'  ) \ngroup by  f.patient_num \n ) \nselect  t.patient_num, 0 as panel_count  from t \n<*>\n insert into DX (  patient_num   ) select * from ( select distinct  patient_num  from QUERY_GLOBAL_TEMP where panel_count = 0 ) q	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns5:request xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <message_header>\n        <i2b2_version_compatible>0.3</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>GeCo i2b2 Data Source</application_name>\n            <application_version>0.2</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>GeCo</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>i2b2 cell</application_name>\n            <application_version>1.7</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-05-02T14:02:06+02:00</datetime_of_message>\n        <security>\n            <domain>i2b2demo</domain>\n            <username>demo</username>\n            <password is_token="false">password not stored</password>\n        </security>\n        <message_type>\n            <message_code>EQQ</message_code>\n            <event_type>Q04</event_type>\n            <message_structure>EQQ_Q04</message_structure>\n        </message_type>\n        <message_control_id>\n            <session_id>2022-05-02T14:02:06+02:00</session_id>\n            <message_num>1651492926</message_num>\n            <instance_num>0</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n        <application_acknowledgement_type></application_acknowledgement_type>\n        <country_code>CH</country_code>\n        <project_id>Demo</project_id>\n    </message_header>\n    <request_header>\n        <result_waittime_ms>10000</result_waittime_ms>\n    </request_header>\n    <message_body>\n        <ns4:psmheader>\n            <user login="demo" group="i2b2demo">demo</user>\n            <patient_set_limit>0</patient_set_limit>\n            <estimated_time>0</estimated_time>\n            <query_mode>optimize_without_temp_table</query_mode>\n            <request_type>CRC_QRY_runQueryInstance_fromQueryDefinition</request_type>\n        </ns4:psmheader>\n        <ns4:request xsi:type="ns4:query_definition_requestType" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">\n            <query_definition>\n                <query_id>0</query_id>\n                <query_name>0</query_name>\n                <query_description>Query from GeCo i2b2 data source (0)</query_description>\n                <query_timing>ANY</query_timing>\n                <specificity_scale>0</specificity_scale>\n                <panel>\n                    <panel_number>1</panel_number>\n                    <panel_timing>ANY</panel_timing>\n                    <panel_accuracy_scale>100</panel_accuracy_scale>\n                    <invert>0</invert>\n                    <total_item_occurrences>1</total_item_occurrences>\n                    <item>\n                        <hlevel>0</hlevel>\n                        <item_name></item_name>\n                        <item_key>\\\\TEST\\test\\1\\</item_key>\n                        <item_icon></item_icon>\n                        <tooltip></tooltip>\n                        <class></class>\n                        <constrain_by_value>\n                            <value_operator>EQ</value_operator>\n                            <value_constraint>10</value_constraint>\n                            <value_type>NUMBER</value_type>\n                        </constrain_by_value>\n                        <item_is_synonym>false</item_is_synonym>\n                    </item>\n                </panel>\n            </query_definition>\n            <result_output_list>\n                <result_output name="PATIENTSET" priority_index="1"/>\n                <result_output name="PATIENT_COUNT_XML" priority_index="2"/>\n            </result_output_list>\n        </ns4:request>\n    </message_body>\n</ns5:request>\n	<ns2:response xmlns:ns2="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/hive/msg/version/">\n    <message_header>\n        <i2b2_version_compatible>1.1</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>PM Cell</application_name>\n            <application_version>1.700</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>i2b2 Hive</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>PM Cell</application_name>\n            <application_version>1.700</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 Hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-05-02T12:02:06.972Z</datetime_of_message>\n        <message_control_id>\n            <instance_num>1</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>AL</accept_acknowledgement_type>\n        <application_acknowledgement_type>AL</application_acknowledgement_type>\n        <country_code>US</country_code>\n        <project_id/>\n    </message_header>\n    <response_header>\n        <result_status>\n            <status type="DONE">PM processing completed</status>\n        </result_status>\n    </response_header>\n    <message_body>\n        <ns4:configure>\n            <environment>DEVELOPMENT</environment>\n            <helpURL>http://www.i2b2.org</helpURL>\n            <user>\n                <full_name>i2b2 User</full_name>\n                <user_name>demo</user_name>\n                <password is_token="true" token_ms_timeout="1800000">SessionKey:aHaqxbOLJRbbstHBA6mA</password>\n                <domain>i2b2demo</domain>\n                <is_admin>false</is_admin>\n                <project id="Demo">\n                    <name>i2b2 Demo</name>\n                    <wiki>http://www.i2b2.org</wiki>\n                    <path>/Demo</path>\n                    <role>DATA_AGG</role>\n                    <role>DATA_DEID</role>\n                    <role>DATA_LDS</role>\n                    <role>DATA_OBFSC</role>\n                    <role>DATA_PROT</role>\n                    <role>EDITOR</role>\n                    <role>USER</role>\n                </project>\n            </user>\n            <domain_name>i2b2demo</domain_name>\n            <domain_id>i2b2demo</domain_id>\n            <active>true</active>\n            <cell_datas>\n                <cell_data id="CRC">\n                    <name>Data Repository</name>\n                    <url>http://i2b2:8080/i2b2/services/QueryToolService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="FRC">\n                    <name>File Repository </name>\n                    <url>http://i2b2:8080/i2b2/services/FRService/</url>\n                    <project_path>/</project_path>\n                    <method>SOAP</method>\n                    <can_override>true</can_override>\n                    <param name="DestDir" id="1" datatype="T">/opt/jboss/wildfly/standalone/data/i2b2_FR_files</param>\n                </cell_data>\n                <cell_data id="ONT">\n                    <name>Ontology Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/OntologyService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="WORK">\n                    <name>Workplace Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/WorkplaceService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="IM">\n                    <name>IM Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/IMService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n            </cell_datas>\n            <global_data/>\n        </ns4:configure>\n    </message_body>\n</ns2:response>
8	1	demo	Demo	\N	\N	2022-05-02 12:02:07.278	\N	N	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns4:query_definition xmlns:ns2="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/">\n    <query_id>1</query_id>\n    <query_name>1</query_name>\n    <query_description>Query from GeCo i2b2 data source (1)</query_description>\n    <query_timing>ANY</query_timing>\n    <specificity_scale>0</specificity_scale>\n    <panel>\n        <panel_number>1</panel_number>\n        <panel_timing>ANY</panel_timing>\n        <panel_accuracy_scale>100</panel_accuracy_scale>\n        <invert>0</invert>\n        <total_item_occurrences>1</total_item_occurrences>\n        <item>\n            <hlevel>0</hlevel>\n            <item_name></item_name>\n            <item_key>\\\\TEST\\test\\1\\</item_key>\n            <item_icon></item_icon>\n            <tooltip></tooltip>\n            <class></class>\n            <constrain_by_value>\n                <value_operator>EQ</value_operator>\n                <value_constraint>10</value_constraint>\n                <value_type>NUMBER</value_type>\n            </constrain_by_value>\n            <item_is_synonym>false</item_is_synonym>\n        </item>\n        <item>\n            <hlevel>0</hlevel>\n            <item_name></item_name>\n            <item_key>\\\\TEST\\test\\3\\</item_key>\n            <item_icon></item_icon>\n            <tooltip></tooltip>\n            <class></class>\n            <constrain_by_value>\n                <value_operator>EQ</value_operator>\n                <value_constraint>20</value_constraint>\n                <value_type>NUMBER</value_type>\n            </constrain_by_value>\n            <item_is_synonym>false</item_is_synonym>\n        </item>\n    </panel>\n</ns4:query_definition>\n	insert into QUERY_GLOBAL_TEMP (patient_num, panel_count)\nwith t as ( \n select  f.patient_num  \nfrom i2b2demodata.observation_fact f \nwhere  \nf.concept_cd IN (select concept_cd from  i2b2demodata.concept_dimension   where concept_path LIKE '\\\\test\\\\1\\\\%')  \n  AND  (  modifier_cd = '@'  AND     valtype_cd = 'N' AND   nval_num  = 10 AND  tval_char='E'  ) \ngroup by  f.patient_num \n ) \nselect  t.patient_num, 0 as panel_count  from t \n<*>\ninsert into QUERY_GLOBAL_TEMP (patient_num, panel_count)\nwith t as ( \n select  f.patient_num  \nfrom i2b2demodata.observation_fact f \nwhere  \nf.concept_cd IN (select concept_cd from  i2b2demodata.concept_dimension   where concept_path LIKE '\\\\test\\\\3\\\\%')  \n  AND  (  modifier_cd = '@'  AND     valtype_cd = 'N' AND   nval_num  = 20 AND  tval_char='E'  ) \ngroup by  f.patient_num \n ) \nselect  t.patient_num, 0 as panel_count  from t \n<*>\n insert into DX (  patient_num   ) select * from ( select distinct  patient_num  from QUERY_GLOBAL_TEMP where panel_count = 0 ) q	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns5:request xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <message_header>\n        <i2b2_version_compatible>0.3</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>GeCo i2b2 Data Source</application_name>\n            <application_version>0.2</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>GeCo</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>i2b2 cell</application_name>\n            <application_version>1.7</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-05-02T14:02:07+02:00</datetime_of_message>\n        <security>\n            <domain>i2b2demo</domain>\n            <username>demo</username>\n            <password is_token="false">password not stored</password>\n        </security>\n        <message_type>\n            <message_code>EQQ</message_code>\n            <event_type>Q04</event_type>\n            <message_structure>EQQ_Q04</message_structure>\n        </message_type>\n        <message_control_id>\n            <session_id>2022-05-02T14:02:07+02:00</session_id>\n            <message_num>1651492927</message_num>\n            <instance_num>0</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n        <application_acknowledgement_type></application_acknowledgement_type>\n        <country_code>CH</country_code>\n        <project_id>Demo</project_id>\n    </message_header>\n    <request_header>\n        <result_waittime_ms>10000</result_waittime_ms>\n    </request_header>\n    <message_body>\n        <ns4:psmheader>\n            <user login="demo" group="i2b2demo">demo</user>\n            <patient_set_limit>0</patient_set_limit>\n            <estimated_time>0</estimated_time>\n            <query_mode>optimize_without_temp_table</query_mode>\n            <request_type>CRC_QRY_runQueryInstance_fromQueryDefinition</request_type>\n        </ns4:psmheader>\n        <ns4:request xsi:type="ns4:query_definition_requestType" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">\n            <query_definition>\n                <query_id>1</query_id>\n                <query_name>1</query_name>\n                <query_description>Query from GeCo i2b2 data source (1)</query_description>\n                <query_timing>ANY</query_timing>\n                <specificity_scale>0</specificity_scale>\n                <panel>\n                    <panel_number>1</panel_number>\n                    <panel_timing>ANY</panel_timing>\n                    <panel_accuracy_scale>100</panel_accuracy_scale>\n                    <invert>0</invert>\n                    <total_item_occurrences>1</total_item_occurrences>\n                    <item>\n                        <hlevel>0</hlevel>\n                        <item_name></item_name>\n                        <item_key>\\\\TEST\\test\\1\\</item_key>\n                        <item_icon></item_icon>\n                        <tooltip></tooltip>\n                        <class></class>\n                        <constrain_by_value>\n                            <value_operator>EQ</value_operator>\n                            <value_constraint>10</value_constraint>\n                            <value_type>NUMBER</value_type>\n                        </constrain_by_value>\n                        <item_is_synonym>false</item_is_synonym>\n                    </item>\n                    <item>\n                        <hlevel>0</hlevel>\n                        <item_name></item_name>\n                        <item_key>\\\\TEST\\test\\3\\</item_key>\n                        <item_icon></item_icon>\n                        <tooltip></tooltip>\n                        <class></class>\n                        <constrain_by_value>\n                            <value_operator>EQ</value_operator>\n                            <value_constraint>20</value_constraint>\n                            <value_type>NUMBER</value_type>\n                        </constrain_by_value>\n                        <item_is_synonym>false</item_is_synonym>\n                    </item>\n                </panel>\n            </query_definition>\n            <result_output_list>\n                <result_output name="PATIENTSET" priority_index="1"/>\n                <result_output name="PATIENT_COUNT_XML" priority_index="2"/>\n            </result_output_list>\n        </ns4:request>\n    </message_body>\n</ns5:request>\n	<ns2:response xmlns:ns2="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/hive/msg/version/">\n    <message_header>\n        <i2b2_version_compatible>1.1</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>PM Cell</application_name>\n            <application_version>1.700</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>i2b2 Hive</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>PM Cell</application_name>\n            <application_version>1.700</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 Hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-05-02T12:02:07.305Z</datetime_of_message>\n        <message_control_id>\n            <instance_num>1</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>AL</accept_acknowledgement_type>\n        <application_acknowledgement_type>AL</application_acknowledgement_type>\n        <country_code>US</country_code>\n        <project_id/>\n    </message_header>\n    <response_header>\n        <result_status>\n            <status type="DONE">PM processing completed</status>\n        </result_status>\n    </response_header>\n    <message_body>\n        <ns4:configure>\n            <environment>DEVELOPMENT</environment>\n            <helpURL>http://www.i2b2.org</helpURL>\n            <user>\n                <full_name>i2b2 User</full_name>\n                <user_name>demo</user_name>\n                <password is_token="true" token_ms_timeout="1800000">SessionKey:a3IaP7uuPjDedaoTPi2b</password>\n                <domain>i2b2demo</domain>\n                <is_admin>false</is_admin>\n                <project id="Demo">\n                    <name>i2b2 Demo</name>\n                    <wiki>http://www.i2b2.org</wiki>\n                    <path>/Demo</path>\n                    <role>DATA_AGG</role>\n                    <role>DATA_DEID</role>\n                    <role>DATA_LDS</role>\n                    <role>DATA_OBFSC</role>\n                    <role>DATA_PROT</role>\n                    <role>EDITOR</role>\n                    <role>USER</role>\n                </project>\n            </user>\n            <domain_name>i2b2demo</domain_name>\n            <domain_id>i2b2demo</domain_id>\n            <active>true</active>\n            <cell_datas>\n                <cell_data id="CRC">\n                    <name>Data Repository</name>\n                    <url>http://i2b2:8080/i2b2/services/QueryToolService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="FRC">\n                    <name>File Repository </name>\n                    <url>http://i2b2:8080/i2b2/services/FRService/</url>\n                    <project_path>/</project_path>\n                    <method>SOAP</method>\n                    <can_override>true</can_override>\n                    <param name="DestDir" id="1" datatype="T">/opt/jboss/wildfly/standalone/data/i2b2_FR_files</param>\n                </cell_data>\n                <cell_data id="ONT">\n                    <name>Ontology Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/OntologyService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="WORK">\n                    <name>Workplace Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/WorkplaceService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="IM">\n                    <name>IM Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/IMService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n            </cell_datas>\n            <global_data/>\n        </ns4:configure>\n    </message_body>\n</ns2:response>
9	0	demo	Demo	\N	\N	2022-05-02 12:02:07.811	\N	N	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns4:query_definition xmlns:ns2="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/">\n    <query_id>0</query_id>\n    <query_name>0</query_name>\n    <query_description>Query from GeCo i2b2 data source (0)</query_description>\n    <query_timing>ANY</query_timing>\n    <specificity_scale>0</specificity_scale>\n    <panel>\n        <panel_number>1</panel_number>\n        <panel_timing>ANY</panel_timing>\n        <panel_accuracy_scale>100</panel_accuracy_scale>\n        <invert>0</invert>\n        <total_item_occurrences>1</total_item_occurrences>\n        <item>\n            <hlevel>0</hlevel>\n            <item_name></item_name>\n            <item_key>\\\\TEST\\test\\1\\</item_key>\n            <item_icon></item_icon>\n            <tooltip></tooltip>\n            <class></class>\n            <constrain_by_modifier>\n                <modifier_key>\\\\TEST\\modifiers1\\1\\</modifier_key>\n                <applied_path>\\test\\1\\</applied_path>\n            </constrain_by_modifier>\n            <item_is_synonym>false</item_is_synonym>\n        </item>\n    </panel>\n</ns4:query_definition>\n	insert into QUERY_GLOBAL_TEMP (patient_num, panel_count)\nwith t as ( \n select  f.patient_num  \nfrom i2b2demodata.observation_fact f \nwhere  \nf.concept_cd IN (select concept_cd from  i2b2demodata.concept_dimension   where concept_path LIKE '\\\\test\\\\1\\\\%')  \n AND  (f.modifier_cd IN  (select modifier_cd from i2b2demodata.modifier_dimension where modifier_path LIKE '\\\\modifiers1\\\\1\\\\%'))  \ngroup by  f.patient_num \n ) \nselect  t.patient_num, 0 as panel_count  from t \n<*>\n insert into DX (  patient_num   ) select * from ( select distinct  patient_num  from QUERY_GLOBAL_TEMP where panel_count = 0 ) q	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns5:request xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <message_header>\n        <i2b2_version_compatible>0.3</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>GeCo i2b2 Data Source</application_name>\n            <application_version>0.2</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>GeCo</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>i2b2 cell</application_name>\n            <application_version>1.7</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-05-02T14:02:07+02:00</datetime_of_message>\n        <security>\n            <domain>i2b2demo</domain>\n            <username>demo</username>\n            <password is_token="false">password not stored</password>\n        </security>\n        <message_type>\n            <message_code>EQQ</message_code>\n            <event_type>Q04</event_type>\n            <message_structure>EQQ_Q04</message_structure>\n        </message_type>\n        <message_control_id>\n            <session_id>2022-05-02T14:02:07+02:00</session_id>\n            <message_num>1651492927</message_num>\n            <instance_num>0</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n        <application_acknowledgement_type></application_acknowledgement_type>\n        <country_code>CH</country_code>\n        <project_id>Demo</project_id>\n    </message_header>\n    <request_header>\n        <result_waittime_ms>10000</result_waittime_ms>\n    </request_header>\n    <message_body>\n        <ns4:psmheader>\n            <user login="demo" group="i2b2demo">demo</user>\n            <patient_set_limit>0</patient_set_limit>\n            <estimated_time>0</estimated_time>\n            <query_mode>optimize_without_temp_table</query_mode>\n            <request_type>CRC_QRY_runQueryInstance_fromQueryDefinition</request_type>\n        </ns4:psmheader>\n        <ns4:request xsi:type="ns4:query_definition_requestType" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">\n            <query_definition>\n                <query_id>0</query_id>\n                <query_name>0</query_name>\n                <query_description>Query from GeCo i2b2 data source (0)</query_description>\n                <query_timing>ANY</query_timing>\n                <specificity_scale>0</specificity_scale>\n                <panel>\n                    <panel_number>1</panel_number>\n                    <panel_timing>ANY</panel_timing>\n                    <panel_accuracy_scale>100</panel_accuracy_scale>\n                    <invert>0</invert>\n                    <total_item_occurrences>1</total_item_occurrences>\n                    <item>\n                        <hlevel>0</hlevel>\n                        <item_name></item_name>\n                        <item_key>\\\\TEST\\test\\1\\</item_key>\n                        <item_icon></item_icon>\n                        <tooltip></tooltip>\n                        <class></class>\n                        <constrain_by_modifier>\n                            <modifier_key>\\\\TEST\\modifiers1\\1\\</modifier_key>\n                            <applied_path>\\test\\1\\</applied_path>\n                        </constrain_by_modifier>\n                        <item_is_synonym>false</item_is_synonym>\n                    </item>\n                </panel>\n            </query_definition>\n            <result_output_list>\n                <result_output name="PATIENTSET" priority_index="1"/>\n                <result_output name="PATIENT_COUNT_XML" priority_index="2"/>\n            </result_output_list>\n        </ns4:request>\n    </message_body>\n</ns5:request>\n	<ns2:response xmlns:ns2="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/hive/msg/version/">\n    <message_header>\n        <i2b2_version_compatible>1.1</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>PM Cell</application_name>\n            <application_version>1.700</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>i2b2 Hive</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>PM Cell</application_name>\n            <application_version>1.700</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 Hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-05-02T12:02:07.842Z</datetime_of_message>\n        <message_control_id>\n            <instance_num>1</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>AL</accept_acknowledgement_type>\n        <application_acknowledgement_type>AL</application_acknowledgement_type>\n        <country_code>US</country_code>\n        <project_id/>\n    </message_header>\n    <response_header>\n        <result_status>\n            <status type="DONE">PM processing completed</status>\n        </result_status>\n    </response_header>\n    <message_body>\n        <ns4:configure>\n            <environment>DEVELOPMENT</environment>\n            <helpURL>http://www.i2b2.org</helpURL>\n            <user>\n                <full_name>i2b2 User</full_name>\n                <user_name>demo</user_name>\n                <password is_token="true" token_ms_timeout="1800000">SessionKey:0r8Y5DwM7vIM5qzIV11O</password>\n                <domain>i2b2demo</domain>\n                <is_admin>false</is_admin>\n                <project id="Demo">\n                    <name>i2b2 Demo</name>\n                    <wiki>http://www.i2b2.org</wiki>\n                    <path>/Demo</path>\n                    <role>DATA_AGG</role>\n                    <role>DATA_DEID</role>\n                    <role>DATA_LDS</role>\n                    <role>DATA_OBFSC</role>\n                    <role>DATA_PROT</role>\n                    <role>EDITOR</role>\n                    <role>USER</role>\n                </project>\n            </user>\n            <domain_name>i2b2demo</domain_name>\n            <domain_id>i2b2demo</domain_id>\n            <active>true</active>\n            <cell_datas>\n                <cell_data id="CRC">\n                    <name>Data Repository</name>\n                    <url>http://i2b2:8080/i2b2/services/QueryToolService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="FRC">\n                    <name>File Repository </name>\n                    <url>http://i2b2:8080/i2b2/services/FRService/</url>\n                    <project_path>/</project_path>\n                    <method>SOAP</method>\n                    <can_override>true</can_override>\n                    <param name="DestDir" id="1" datatype="T">/opt/jboss/wildfly/standalone/data/i2b2_FR_files</param>\n                </cell_data>\n                <cell_data id="ONT">\n                    <name>Ontology Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/OntologyService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="WORK">\n                    <name>Workplace Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/WorkplaceService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="IM">\n                    <name>IM Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/IMService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n            </cell_datas>\n            <global_data/>\n        </ns4:configure>\n    </message_body>\n</ns2:response>
10	1	demo	Demo	\N	\N	2022-05-02 12:02:08.25	\N	N	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns4:query_definition xmlns:ns2="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/">\n    <query_id>1</query_id>\n    <query_name>1</query_name>\n    <query_description>Query from GeCo i2b2 data source (1)</query_description>\n    <query_timing>ANY</query_timing>\n    <specificity_scale>0</specificity_scale>\n    <panel>\n        <panel_number>1</panel_number>\n        <panel_timing>ANY</panel_timing>\n        <panel_accuracy_scale>100</panel_accuracy_scale>\n        <invert>0</invert>\n        <total_item_occurrences>1</total_item_occurrences>\n        <item>\n            <hlevel>0</hlevel>\n            <item_name></item_name>\n            <item_key>\\\\TEST\\test\\1\\</item_key>\n            <item_icon></item_icon>\n            <tooltip></tooltip>\n            <class></class>\n            <constrain_by_modifier>\n                <modifier_key>\\\\TEST\\modifiers1\\1\\</modifier_key>\n                <applied_path>\\test\\1\\</applied_path>\n            </constrain_by_modifier>\n            <item_is_synonym>false</item_is_synonym>\n        </item>\n        <item>\n            <hlevel>0</hlevel>\n            <item_name></item_name>\n            <item_key>\\\\TEST\\test\\2\\</item_key>\n            <item_icon></item_icon>\n            <tooltip></tooltip>\n            <class></class>\n            <constrain_by_modifier>\n                <modifier_key>\\\\TEST\\modifiers2\\text\\</modifier_key>\n                <applied_path>\\test\\2\\</applied_path>\n            </constrain_by_modifier>\n            <item_is_synonym>false</item_is_synonym>\n        </item>\n    </panel>\n</ns4:query_definition>\n	insert into QUERY_GLOBAL_TEMP (patient_num, panel_count)\nwith t as ( \n select  f.patient_num  \nfrom i2b2demodata.observation_fact f \nwhere  \nf.concept_cd IN (select concept_cd from  i2b2demodata.concept_dimension   where concept_path LIKE '\\\\test\\\\1\\\\%')  \n AND  (f.modifier_cd IN  (select modifier_cd from i2b2demodata.modifier_dimension where modifier_path LIKE '\\\\modifiers1\\\\1\\\\%'))  \ngroup by  f.patient_num \n ) \nselect  t.patient_num, 0 as panel_count  from t \n<*>\ninsert into QUERY_GLOBAL_TEMP (patient_num, panel_count)\nwith t as ( \n select  f.patient_num  \nfrom i2b2demodata.observation_fact f \nwhere  \nf.concept_cd IN (select concept_cd from  i2b2demodata.concept_dimension   where concept_path LIKE '\\\\test\\\\2\\\\%')  \n AND  (f.modifier_cd IN  (select modifier_cd from i2b2demodata.modifier_dimension where modifier_path LIKE '\\\\modifiers2\\\\text\\\\%'))  \ngroup by  f.patient_num \n ) \nselect  t.patient_num, 0 as panel_count  from t \n<*>\n insert into DX (  patient_num   ) select * from ( select distinct  patient_num  from QUERY_GLOBAL_TEMP where panel_count = 0 ) q	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns5:request xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <message_header>\n        <i2b2_version_compatible>0.3</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>GeCo i2b2 Data Source</application_name>\n            <application_version>0.2</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>GeCo</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>i2b2 cell</application_name>\n            <application_version>1.7</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-05-02T14:02:08+02:00</datetime_of_message>\n        <security>\n            <domain>i2b2demo</domain>\n            <username>demo</username>\n            <password is_token="false">password not stored</password>\n        </security>\n        <message_type>\n            <message_code>EQQ</message_code>\n            <event_type>Q04</event_type>\n            <message_structure>EQQ_Q04</message_structure>\n        </message_type>\n        <message_control_id>\n            <session_id>2022-05-02T14:02:08+02:00</session_id>\n            <message_num>1651492928</message_num>\n            <instance_num>0</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n        <application_acknowledgement_type></application_acknowledgement_type>\n        <country_code>CH</country_code>\n        <project_id>Demo</project_id>\n    </message_header>\n    <request_header>\n        <result_waittime_ms>10000</result_waittime_ms>\n    </request_header>\n    <message_body>\n        <ns4:psmheader>\n            <user login="demo" group="i2b2demo">demo</user>\n            <patient_set_limit>0</patient_set_limit>\n            <estimated_time>0</estimated_time>\n            <query_mode>optimize_without_temp_table</query_mode>\n            <request_type>CRC_QRY_runQueryInstance_fromQueryDefinition</request_type>\n        </ns4:psmheader>\n        <ns4:request xsi:type="ns4:query_definition_requestType" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">\n            <query_definition>\n                <query_id>1</query_id>\n                <query_name>1</query_name>\n                <query_description>Query from GeCo i2b2 data source (1)</query_description>\n                <query_timing>ANY</query_timing>\n                <specificity_scale>0</specificity_scale>\n                <panel>\n                    <panel_number>1</panel_number>\n                    <panel_timing>ANY</panel_timing>\n                    <panel_accuracy_scale>100</panel_accuracy_scale>\n                    <invert>0</invert>\n                    <total_item_occurrences>1</total_item_occurrences>\n                    <item>\n                        <hlevel>0</hlevel>\n                        <item_name></item_name>\n                        <item_key>\\\\TEST\\test\\1\\</item_key>\n                        <item_icon></item_icon>\n                        <tooltip></tooltip>\n                        <class></class>\n                        <constrain_by_modifier>\n                            <modifier_key>\\\\TEST\\modifiers1\\1\\</modifier_key>\n                            <applied_path>\\test\\1\\</applied_path>\n                        </constrain_by_modifier>\n                        <item_is_synonym>false</item_is_synonym>\n                    </item>\n                    <item>\n                        <hlevel>0</hlevel>\n                        <item_name></item_name>\n                        <item_key>\\\\TEST\\test\\2\\</item_key>\n                        <item_icon></item_icon>\n                        <tooltip></tooltip>\n                        <class></class>\n                        <constrain_by_modifier>\n                            <modifier_key>\\\\TEST\\modifiers2\\text\\</modifier_key>\n                            <applied_path>\\test\\2\\</applied_path>\n                        </constrain_by_modifier>\n                        <item_is_synonym>false</item_is_synonym>\n                    </item>\n                </panel>\n            </query_definition>\n            <result_output_list>\n                <result_output name="PATIENTSET" priority_index="1"/>\n                <result_output name="PATIENT_COUNT_XML" priority_index="2"/>\n            </result_output_list>\n        </ns4:request>\n    </message_body>\n</ns5:request>\n	<ns2:response xmlns:ns2="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/hive/msg/version/">\n    <message_header>\n        <i2b2_version_compatible>1.1</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>PM Cell</application_name>\n            <application_version>1.700</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>i2b2 Hive</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>PM Cell</application_name>\n            <application_version>1.700</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 Hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-05-02T12:02:08.277Z</datetime_of_message>\n        <message_control_id>\n            <instance_num>1</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>AL</accept_acknowledgement_type>\n        <application_acknowledgement_type>AL</application_acknowledgement_type>\n        <country_code>US</country_code>\n        <project_id/>\n    </message_header>\n    <response_header>\n        <result_status>\n            <status type="DONE">PM processing completed</status>\n        </result_status>\n    </response_header>\n    <message_body>\n        <ns4:configure>\n            <environment>DEVELOPMENT</environment>\n            <helpURL>http://www.i2b2.org</helpURL>\n            <user>\n                <full_name>i2b2 User</full_name>\n                <user_name>demo</user_name>\n                <password is_token="true" token_ms_timeout="1800000">SessionKey:sS5MrXDi9C99CXWn5zeV</password>\n                <domain>i2b2demo</domain>\n                <is_admin>false</is_admin>\n                <project id="Demo">\n                    <name>i2b2 Demo</name>\n                    <wiki>http://www.i2b2.org</wiki>\n                    <path>/Demo</path>\n                    <role>DATA_AGG</role>\n                    <role>DATA_DEID</role>\n                    <role>DATA_LDS</role>\n                    <role>DATA_OBFSC</role>\n                    <role>DATA_PROT</role>\n                    <role>EDITOR</role>\n                    <role>USER</role>\n                </project>\n            </user>\n            <domain_name>i2b2demo</domain_name>\n            <domain_id>i2b2demo</domain_id>\n            <active>true</active>\n            <cell_datas>\n                <cell_data id="CRC">\n                    <name>Data Repository</name>\n                    <url>http://i2b2:8080/i2b2/services/QueryToolService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="FRC">\n                    <name>File Repository </name>\n                    <url>http://i2b2:8080/i2b2/services/FRService/</url>\n                    <project_path>/</project_path>\n                    <method>SOAP</method>\n                    <can_override>true</can_override>\n                    <param name="DestDir" id="1" datatype="T">/opt/jboss/wildfly/standalone/data/i2b2_FR_files</param>\n                </cell_data>\n                <cell_data id="ONT">\n                    <name>Ontology Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/OntologyService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="WORK">\n                    <name>Workplace Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/WorkplaceService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="IM">\n                    <name>IM Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/IMService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n            </cell_datas>\n            <global_data/>\n        </ns4:configure>\n    </message_body>\n</ns2:response>
11	0	demo	Demo	\N	\N	2022-05-02 12:02:08.818	\N	N	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns4:query_definition xmlns:ns2="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/">\n    <query_id>0</query_id>\n    <query_name>0</query_name>\n    <query_description>Query from GeCo i2b2 data source (0)</query_description>\n    <query_timing>ANY</query_timing>\n    <specificity_scale>0</specificity_scale>\n    <panel>\n        <panel_number>1</panel_number>\n        <panel_timing>ANY</panel_timing>\n        <panel_accuracy_scale>100</panel_accuracy_scale>\n        <invert>0</invert>\n        <total_item_occurrences>1</total_item_occurrences>\n        <item>\n            <hlevel>0</hlevel>\n            <item_name></item_name>\n            <item_key>\\\\TEST\\test\\2\\</item_key>\n            <item_icon></item_icon>\n            <tooltip></tooltip>\n            <class></class>\n            <constrain_by_modifier>\n                <modifier_key>\\\\TEST\\modifiers2\\text\\</modifier_key>\n                <applied_path>\\test\\2\\</applied_path>\n                <constrain_by_value>\n                    <value_operator>LIKE[contains]</value_operator>\n                    <value_constraint>cd</value_constraint>\n                    <value_type>TEXT</value_type>\n                </constrain_by_value>\n            </constrain_by_modifier>\n            <item_is_synonym>false</item_is_synonym>\n        </item>\n    </panel>\n</ns4:query_definition>\n	insert into QUERY_GLOBAL_TEMP (patient_num, panel_count)\nwith t as ( \n select  f.patient_num  \nfrom i2b2demodata.observation_fact f \nwhere  \nf.concept_cd IN (select concept_cd from  i2b2demodata.concept_dimension   where concept_path LIKE '\\\\test\\\\2\\\\%')  \n AND  (f.modifier_cd IN  (select modifier_cd from i2b2demodata.modifier_dimension where modifier_path LIKE '\\\\modifiers2\\\\text\\\\%')) \n  AND  (  valtype_cd = 'T' AND tval_char LIKE '%cd%' ) \ngroup by  f.patient_num \n ) \nselect  t.patient_num, 0 as panel_count  from t \n<*>\n insert into DX (  patient_num   ) select * from ( select distinct  patient_num  from QUERY_GLOBAL_TEMP where panel_count = 0 ) q	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns5:request xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <message_header>\n        <i2b2_version_compatible>0.3</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>GeCo i2b2 Data Source</application_name>\n            <application_version>0.2</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>GeCo</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>i2b2 cell</application_name>\n            <application_version>1.7</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-05-02T14:02:08+02:00</datetime_of_message>\n        <security>\n            <domain>i2b2demo</domain>\n            <username>demo</username>\n            <password is_token="false">password not stored</password>\n        </security>\n        <message_type>\n            <message_code>EQQ</message_code>\n            <event_type>Q04</event_type>\n            <message_structure>EQQ_Q04</message_structure>\n        </message_type>\n        <message_control_id>\n            <session_id>2022-05-02T14:02:08+02:00</session_id>\n            <message_num>1651492928</message_num>\n            <instance_num>0</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n        <application_acknowledgement_type></application_acknowledgement_type>\n        <country_code>CH</country_code>\n        <project_id>Demo</project_id>\n    </message_header>\n    <request_header>\n        <result_waittime_ms>10000</result_waittime_ms>\n    </request_header>\n    <message_body>\n        <ns4:psmheader>\n            <user login="demo" group="i2b2demo">demo</user>\n            <patient_set_limit>0</patient_set_limit>\n            <estimated_time>0</estimated_time>\n            <query_mode>optimize_without_temp_table</query_mode>\n            <request_type>CRC_QRY_runQueryInstance_fromQueryDefinition</request_type>\n        </ns4:psmheader>\n        <ns4:request xsi:type="ns4:query_definition_requestType" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">\n            <query_definition>\n                <query_id>0</query_id>\n                <query_name>0</query_name>\n                <query_description>Query from GeCo i2b2 data source (0)</query_description>\n                <query_timing>ANY</query_timing>\n                <specificity_scale>0</specificity_scale>\n                <panel>\n                    <panel_number>1</panel_number>\n                    <panel_timing>ANY</panel_timing>\n                    <panel_accuracy_scale>100</panel_accuracy_scale>\n                    <invert>0</invert>\n                    <total_item_occurrences>1</total_item_occurrences>\n                    <item>\n                        <hlevel>0</hlevel>\n                        <item_name></item_name>\n                        <item_key>\\\\TEST\\test\\2\\</item_key>\n                        <item_icon></item_icon>\n                        <tooltip></tooltip>\n                        <class></class>\n                        <constrain_by_modifier>\n                            <modifier_key>\\\\TEST\\modifiers2\\text\\</modifier_key>\n                            <applied_path>\\test\\2\\</applied_path>\n                            <constrain_by_value>\n                                <value_operator>LIKE[contains]</value_operator>\n                                <value_constraint>cd</value_constraint>\n                                <value_type>TEXT</value_type>\n                            </constrain_by_value>\n                        </constrain_by_modifier>\n                        <item_is_synonym>false</item_is_synonym>\n                    </item>\n                </panel>\n            </query_definition>\n            <result_output_list>\n                <result_output name="PATIENTSET" priority_index="1"/>\n                <result_output name="PATIENT_COUNT_XML" priority_index="2"/>\n            </result_output_list>\n        </ns4:request>\n    </message_body>\n</ns5:request>\n	<ns2:response xmlns:ns2="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/hive/msg/version/">\n    <message_header>\n        <i2b2_version_compatible>1.1</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>PM Cell</application_name>\n            <application_version>1.700</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>i2b2 Hive</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>PM Cell</application_name>\n            <application_version>1.700</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 Hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-05-02T12:02:08.837Z</datetime_of_message>\n        <message_control_id>\n            <instance_num>1</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>AL</accept_acknowledgement_type>\n        <application_acknowledgement_type>AL</application_acknowledgement_type>\n        <country_code>US</country_code>\n        <project_id/>\n    </message_header>\n    <response_header>\n        <result_status>\n            <status type="DONE">PM processing completed</status>\n        </result_status>\n    </response_header>\n    <message_body>\n        <ns4:configure>\n            <environment>DEVELOPMENT</environment>\n            <helpURL>http://www.i2b2.org</helpURL>\n            <user>\n                <full_name>i2b2 User</full_name>\n                <user_name>demo</user_name>\n                <password is_token="true" token_ms_timeout="1800000">SessionKey:fAelUs9Ram1czTOumYkN</password>\n                <domain>i2b2demo</domain>\n                <is_admin>false</is_admin>\n                <project id="Demo">\n                    <name>i2b2 Demo</name>\n                    <wiki>http://www.i2b2.org</wiki>\n                    <path>/Demo</path>\n                    <role>DATA_AGG</role>\n                    <role>DATA_DEID</role>\n                    <role>DATA_LDS</role>\n                    <role>DATA_OBFSC</role>\n                    <role>DATA_PROT</role>\n                    <role>EDITOR</role>\n                    <role>USER</role>\n                </project>\n            </user>\n            <domain_name>i2b2demo</domain_name>\n            <domain_id>i2b2demo</domain_id>\n            <active>true</active>\n            <cell_datas>\n                <cell_data id="CRC">\n                    <name>Data Repository</name>\n                    <url>http://i2b2:8080/i2b2/services/QueryToolService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="FRC">\n                    <name>File Repository </name>\n                    <url>http://i2b2:8080/i2b2/services/FRService/</url>\n                    <project_path>/</project_path>\n                    <method>SOAP</method>\n                    <can_override>true</can_override>\n                    <param name="DestDir" id="1" datatype="T">/opt/jboss/wildfly/standalone/data/i2b2_FR_files</param>\n                </cell_data>\n                <cell_data id="ONT">\n                    <name>Ontology Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/OntologyService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="WORK">\n                    <name>Workplace Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/WorkplaceService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="IM">\n                    <name>IM Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/IMService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n            </cell_datas>\n            <global_data/>\n        </ns4:configure>\n    </message_body>\n</ns2:response>
12	1	demo	Demo	\N	\N	2022-05-02 12:02:09.173	\N	N	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns4:query_definition xmlns:ns2="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/">\n    <query_id>1</query_id>\n    <query_name>1</query_name>\n    <query_description>Query from GeCo i2b2 data source (1)</query_description>\n    <query_timing>ANY</query_timing>\n    <specificity_scale>0</specificity_scale>\n    <panel>\n        <panel_number>1</panel_number>\n        <panel_timing>ANY</panel_timing>\n        <panel_accuracy_scale>100</panel_accuracy_scale>\n        <invert>0</invert>\n        <total_item_occurrences>1</total_item_occurrences>\n        <item>\n            <hlevel>0</hlevel>\n            <item_name></item_name>\n            <item_key>\\\\TEST\\test\\3\\</item_key>\n            <item_icon></item_icon>\n            <tooltip></tooltip>\n            <class></class>\n            <constrain_by_modifier>\n                <modifier_key>\\\\TEST\\modifiers3\\text\\</modifier_key>\n                <applied_path>\\test\\3\\</applied_path>\n                <constrain_by_value>\n                    <value_operator>LIKE[exact]</value_operator>\n                    <value_constraint>def</value_constraint>\n                    <value_type>TEXT</value_type>\n                </constrain_by_value>\n            </constrain_by_modifier>\n            <item_is_synonym>false</item_is_synonym>\n        </item>\n    </panel>\n    <panel>\n        <panel_number>2</panel_number>\n        <panel_timing>ANY</panel_timing>\n        <panel_accuracy_scale>100</panel_accuracy_scale>\n        <invert>0</invert>\n        <total_item_occurrences>1</total_item_occurrences>\n        <item>\n            <hlevel>0</hlevel>\n            <item_name></item_name>\n            <item_key>\\\\TEST\\test\\2\\</item_key>\n            <item_icon></item_icon>\n            <tooltip></tooltip>\n            <class></class>\n            <constrain_by_modifier>\n                <modifier_key>\\\\TEST\\modifiers2\\text\\</modifier_key>\n                <applied_path>\\test\\2\\</applied_path>\n                <constrain_by_value>\n                    <value_operator>LIKE[begin]</value_operator>\n                    <value_constraint>a</value_constraint>\n                    <value_type>TEXT</value_type>\n                </constrain_by_value>\n            </constrain_by_modifier>\n            <item_is_synonym>false</item_is_synonym>\n        </item>\n    </panel>\n</ns4:query_definition>\n	insert into QUERY_GLOBAL_TEMP (patient_num, panel_count)\nwith t as ( \n select  f.patient_num  \nfrom i2b2demodata.observation_fact f \nwhere  \nf.concept_cd IN (select concept_cd from  i2b2demodata.concept_dimension   where concept_path LIKE '\\\\test\\\\3\\\\%')  \n AND  (f.modifier_cd IN  (select modifier_cd from i2b2demodata.modifier_dimension where modifier_path LIKE '\\\\modifiers3\\\\text\\\\%')) \n  AND  (  valtype_cd = 'T' AND tval_char = 'def' ) \ngroup by  f.patient_num \n ) \nselect  t.patient_num, 0 as panel_count  from t \n<*>\nupdate QUERY_GLOBAL_TEMP set panel_count =1 where QUERY_GLOBAL_TEMP.panel_count =  0 and exists ( select 1 from ( select  f.patient_num  \nfrom i2b2demodata.observation_fact f \nwhere  \nf.concept_cd IN (select concept_cd from  i2b2demodata.concept_dimension   where concept_path LIKE '\\\\test\\\\2\\\\%')  \n AND  (f.modifier_cd IN  (select modifier_cd from i2b2demodata.modifier_dimension where modifier_path LIKE '\\\\modifiers2\\\\text\\\\%')) \n  AND  (  valtype_cd = 'T' AND tval_char LIKE 'a%' ) \ngroup by  f.patient_num ) t where QUERY_GLOBAL_TEMP.patient_num = t.patient_num    ) \n<*>\n insert into DX (  patient_num   ) select * from ( select distinct  patient_num  from QUERY_GLOBAL_TEMP where panel_count = 1 ) q	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns5:request xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <message_header>\n        <i2b2_version_compatible>0.3</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>GeCo i2b2 Data Source</application_name>\n            <application_version>0.2</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>GeCo</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>i2b2 cell</application_name>\n            <application_version>1.7</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-05-02T14:02:09+02:00</datetime_of_message>\n        <security>\n            <domain>i2b2demo</domain>\n            <username>demo</username>\n            <password is_token="false">password not stored</password>\n        </security>\n        <message_type>\n            <message_code>EQQ</message_code>\n            <event_type>Q04</event_type>\n            <message_structure>EQQ_Q04</message_structure>\n        </message_type>\n        <message_control_id>\n            <session_id>2022-05-02T14:02:09+02:00</session_id>\n            <message_num>1651492929</message_num>\n            <instance_num>0</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n        <application_acknowledgement_type></application_acknowledgement_type>\n        <country_code>CH</country_code>\n        <project_id>Demo</project_id>\n    </message_header>\n    <request_header>\n        <result_waittime_ms>10000</result_waittime_ms>\n    </request_header>\n    <message_body>\n        <ns4:psmheader>\n            <user login="demo" group="i2b2demo">demo</user>\n            <patient_set_limit>0</patient_set_limit>\n            <estimated_time>0</estimated_time>\n            <query_mode>optimize_without_temp_table</query_mode>\n            <request_type>CRC_QRY_runQueryInstance_fromQueryDefinition</request_type>\n        </ns4:psmheader>\n        <ns4:request xsi:type="ns4:query_definition_requestType" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">\n            <query_definition>\n                <query_id>1</query_id>\n                <query_name>1</query_name>\n                <query_description>Query from GeCo i2b2 data source (1)</query_description>\n                <query_timing>ANY</query_timing>\n                <specificity_scale>0</specificity_scale>\n                <panel>\n                    <panel_number>1</panel_number>\n                    <panel_timing>ANY</panel_timing>\n                    <panel_accuracy_scale>100</panel_accuracy_scale>\n                    <invert>0</invert>\n                    <total_item_occurrences>1</total_item_occurrences>\n                    <item>\n                        <hlevel>0</hlevel>\n                        <item_name></item_name>\n                        <item_key>\\\\TEST\\test\\3\\</item_key>\n                        <item_icon></item_icon>\n                        <tooltip></tooltip>\n                        <class></class>\n                        <constrain_by_modifier>\n                            <modifier_key>\\\\TEST\\modifiers3\\text\\</modifier_key>\n                            <applied_path>\\test\\3\\</applied_path>\n                            <constrain_by_value>\n                                <value_operator>LIKE[exact]</value_operator>\n                                <value_constraint>def</value_constraint>\n                                <value_type>TEXT</value_type>\n                            </constrain_by_value>\n                        </constrain_by_modifier>\n                        <item_is_synonym>false</item_is_synonym>\n                    </item>\n                </panel>\n                <panel>\n                    <panel_number>2</panel_number>\n                    <panel_timing>ANY</panel_timing>\n                    <panel_accuracy_scale>100</panel_accuracy_scale>\n                    <invert>0</invert>\n                    <total_item_occurrences>1</total_item_occurrences>\n                    <item>\n                        <hlevel>0</hlevel>\n                        <item_name></item_name>\n                        <item_key>\\\\TEST\\test\\2\\</item_key>\n                        <item_icon></item_icon>\n                        <tooltip></tooltip>\n                        <class></class>\n                        <constrain_by_modifier>\n                            <modifier_key>\\\\TEST\\modifiers2\\text\\</modifier_key>\n                            <applied_path>\\test\\2\\</applied_path>\n                            <constrain_by_value>\n                                <value_operator>LIKE[begin]</value_operator>\n                                <value_constraint>a</value_constraint>\n                                <value_type>TEXT</value_type>\n                            </constrain_by_value>\n                        </constrain_by_modifier>\n                        <item_is_synonym>false</item_is_synonym>\n                    </item>\n                </panel>\n            </query_definition>\n            <result_output_list>\n                <result_output name="PATIENTSET" priority_index="1"/>\n                <result_output name="PATIENT_COUNT_XML" priority_index="2"/>\n            </result_output_list>\n        </ns4:request>\n    </message_body>\n</ns5:request>\n	<ns2:response xmlns:ns2="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/hive/msg/version/">\n    <message_header>\n        <i2b2_version_compatible>1.1</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>PM Cell</application_name>\n            <application_version>1.700</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>i2b2 Hive</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>PM Cell</application_name>\n            <application_version>1.700</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 Hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-05-02T12:02:09.194Z</datetime_of_message>\n        <message_control_id>\n            <instance_num>1</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>AL</accept_acknowledgement_type>\n        <application_acknowledgement_type>AL</application_acknowledgement_type>\n        <country_code>US</country_code>\n        <project_id/>\n    </message_header>\n    <response_header>\n        <result_status>\n            <status type="DONE">PM processing completed</status>\n        </result_status>\n    </response_header>\n    <message_body>\n        <ns4:configure>\n            <environment>DEVELOPMENT</environment>\n            <helpURL>http://www.i2b2.org</helpURL>\n            <user>\n                <full_name>i2b2 User</full_name>\n                <user_name>demo</user_name>\n                <password is_token="true" token_ms_timeout="1800000">SessionKey:tcik967PB5GRK2QxHVfr</password>\n                <domain>i2b2demo</domain>\n                <is_admin>false</is_admin>\n                <project id="Demo">\n                    <name>i2b2 Demo</name>\n                    <wiki>http://www.i2b2.org</wiki>\n                    <path>/Demo</path>\n                    <role>DATA_AGG</role>\n                    <role>DATA_DEID</role>\n                    <role>DATA_LDS</role>\n                    <role>DATA_OBFSC</role>\n                    <role>DATA_PROT</role>\n                    <role>EDITOR</role>\n                    <role>USER</role>\n                </project>\n            </user>\n            <domain_name>i2b2demo</domain_name>\n            <domain_id>i2b2demo</domain_id>\n            <active>true</active>\n            <cell_datas>\n                <cell_data id="CRC">\n                    <name>Data Repository</name>\n                    <url>http://i2b2:8080/i2b2/services/QueryToolService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="FRC">\n                    <name>File Repository </name>\n                    <url>http://i2b2:8080/i2b2/services/FRService/</url>\n                    <project_path>/</project_path>\n                    <method>SOAP</method>\n                    <can_override>true</can_override>\n                    <param name="DestDir" id="1" datatype="T">/opt/jboss/wildfly/standalone/data/i2b2_FR_files</param>\n                </cell_data>\n                <cell_data id="ONT">\n                    <name>Ontology Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/OntologyService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="WORK">\n                    <name>Workplace Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/WorkplaceService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="IM">\n                    <name>IM Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/IMService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n            </cell_datas>\n            <global_data/>\n        </ns4:configure>\n    </message_body>\n</ns2:response>
14	6926d7ab-086b-410f-9c94-d9005d51122b	demo	Demo	\N	\N	2022-05-02 12:02:10.839	\N	N	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns4:query_definition xmlns:ns2="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/">\n    <query_id>6926d7ab-086b-410f-9c94-d9005d51122b</query_id>\n    <query_name>6926d7ab-086b-410f-9c94-d9005d51122b</query_name>\n    <query_description>Query from GeCo i2b2 data source (6926d7ab-086b-410f-9c94-d9005d51122b)</query_description>\n    <query_timing>any</query_timing>\n    <specificity_scale>0</specificity_scale>\n    <panel>\n        <panel_number>1</panel_number>\n        <panel_timing>any</panel_timing>\n        <panel_accuracy_scale>100</panel_accuracy_scale>\n        <invert>0</invert>\n        <total_item_occurrences>1</total_item_occurrences>\n        <item>\n            <hlevel>0</hlevel>\n            <item_name></item_name>\n            <item_key>patient_set_coll_id:-101</item_key>\n            <item_icon></item_icon>\n            <tooltip></tooltip>\n            <class></class>\n            <item_is_synonym>false</item_is_synonym>\n        </item>\n    </panel>\n    <panel>\n        <panel_number>2</panel_number>\n        <panel_timing>any</panel_timing>\n        <panel_accuracy_scale>100</panel_accuracy_scale>\n        <invert>0</invert>\n        <total_item_occurrences>1</total_item_occurrences>\n        <item>\n            <hlevel>0</hlevel>\n            <item_name></item_name>\n            <item_key>\\\\SPHN\\SPHNv2020.1\\FophDiagnosis\\</item_key>\n            <item_icon></item_icon>\n            <tooltip></tooltip>\n            <class></class>\n            <item_is_synonym>false</item_is_synonym>\n        </item>\n    </panel>\n</ns4:query_definition>\n	insert into QUERY_GLOBAL_TEMP (patient_num, panel_count)\nwith t as ( \nselect  patient_num  from  i2b2demodata.qt_patient_set_collection    where  result_instance_id   =  -101\n ) \nselect  t.patient_num, 0 as panel_count  from t \n<*>\nupdate QUERY_GLOBAL_TEMP set panel_count =1 where QUERY_GLOBAL_TEMP.panel_count =  0 and exists ( select 1 from ( select  f.patient_num  \nfrom i2b2demodata.observation_fact f \nwhere  \nf.concept_cd IN (select concept_cd from  i2b2demodata.concept_dimension   where concept_path LIKE '\\\\SPHNv2020.1\\\\FophDiagnosis\\\\%')   \ngroup by  f.patient_num ) t where QUERY_GLOBAL_TEMP.patient_num = t.patient_num    ) \n<*>\n insert into DX (  patient_num   ) select * from ( select distinct  patient_num  from QUERY_GLOBAL_TEMP where panel_count = 1 ) q	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns5:request xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <message_header>\n        <i2b2_version_compatible>0.3</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>GeCo i2b2 Data Source</application_name>\n            <application_version>0.2</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>GeCo</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>i2b2 cell</application_name>\n            <application_version>1.7</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-05-02T14:02:10+02:00</datetime_of_message>\n        <security>\n            <domain>i2b2demo</domain>\n            <username>demo</username>\n            <password is_token="false">password not stored</password>\n        </security>\n        <message_type>\n            <message_code>EQQ</message_code>\n            <event_type>Q04</event_type>\n            <message_structure>EQQ_Q04</message_structure>\n        </message_type>\n        <message_control_id>\n            <session_id>2022-05-02T14:02:10+02:00</session_id>\n            <message_num>1651492930</message_num>\n            <instance_num>0</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n        <application_acknowledgement_type></application_acknowledgement_type>\n        <country_code>CH</country_code>\n        <project_id>Demo</project_id>\n    </message_header>\n    <request_header>\n        <result_waittime_ms>10000</result_waittime_ms>\n    </request_header>\n    <message_body>\n        <ns4:psmheader>\n            <user login="demo" group="i2b2demo">demo</user>\n            <patient_set_limit>0</patient_set_limit>\n            <estimated_time>0</estimated_time>\n            <query_mode>optimize_without_temp_table</query_mode>\n            <request_type>CRC_QRY_runQueryInstance_fromQueryDefinition</request_type>\n        </ns4:psmheader>\n        <ns4:request xsi:type="ns4:query_definition_requestType" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">\n            <query_definition>\n                <query_id>6926d7ab-086b-410f-9c94-d9005d51122b</query_id>\n                <query_name>6926d7ab-086b-410f-9c94-d9005d51122b</query_name>\n                <query_description>Query from GeCo i2b2 data source (6926d7ab-086b-410f-9c94-d9005d51122b)</query_description>\n                <query_timing>any</query_timing>\n                <specificity_scale>0</specificity_scale>\n                <panel>\n                    <panel_number>1</panel_number>\n                    <panel_timing>any</panel_timing>\n                    <panel_accuracy_scale>100</panel_accuracy_scale>\n                    <invert>0</invert>\n                    <total_item_occurrences>1</total_item_occurrences>\n                    <item>\n                        <hlevel>0</hlevel>\n                        <item_name></item_name>\n                        <item_key>patient_set_coll_id:-101</item_key>\n                        <item_icon></item_icon>\n                        <tooltip></tooltip>\n                        <class></class>\n                        <item_is_synonym>false</item_is_synonym>\n                    </item>\n                </panel>\n                <panel>\n                    <panel_number>2</panel_number>\n                    <panel_timing>any</panel_timing>\n                    <panel_accuracy_scale>100</panel_accuracy_scale>\n                    <invert>0</invert>\n                    <total_item_occurrences>1</total_item_occurrences>\n                    <item>\n                        <hlevel>0</hlevel>\n                        <item_name></item_name>\n                        <item_key>\\\\SPHN\\SPHNv2020.1\\FophDiagnosis\\</item_key>\n                        <item_icon></item_icon>\n                        <tooltip></tooltip>\n                        <class></class>\n                        <item_is_synonym>false</item_is_synonym>\n                    </item>\n                </panel>\n            </query_definition>\n            <result_output_list>\n                <result_output name="PATIENTSET" priority_index="1"/>\n                <result_output name="PATIENT_COUNT_XML" priority_index="2"/>\n            </result_output_list>\n        </ns4:request>\n    </message_body>\n</ns5:request>\n	<ns2:response xmlns:ns2="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/hive/msg/version/">\n    <message_header>\n        <i2b2_version_compatible>1.1</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>PM Cell</application_name>\n            <application_version>1.700</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>i2b2 Hive</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>PM Cell</application_name>\n            <application_version>1.700</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 Hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-05-02T12:02:10.862Z</datetime_of_message>\n        <message_control_id>\n            <instance_num>1</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>AL</accept_acknowledgement_type>\n        <application_acknowledgement_type>AL</application_acknowledgement_type>\n        <country_code>US</country_code>\n        <project_id/>\n    </message_header>\n    <response_header>\n        <result_status>\n            <status type="DONE">PM processing completed</status>\n        </result_status>\n    </response_header>\n    <message_body>\n        <ns4:configure>\n            <environment>DEVELOPMENT</environment>\n            <helpURL>http://www.i2b2.org</helpURL>\n            <user>\n                <full_name>i2b2 User</full_name>\n                <user_name>demo</user_name>\n                <password is_token="true" token_ms_timeout="1800000">SessionKey:6xvoeEVWq4of6RkFvrCC</password>\n                <domain>i2b2demo</domain>\n                <is_admin>false</is_admin>\n                <project id="Demo">\n                    <name>i2b2 Demo</name>\n                    <wiki>http://www.i2b2.org</wiki>\n                    <path>/Demo</path>\n                    <role>DATA_AGG</role>\n                    <role>DATA_DEID</role>\n                    <role>DATA_LDS</role>\n                    <role>DATA_OBFSC</role>\n                    <role>DATA_PROT</role>\n                    <role>EDITOR</role>\n                    <role>USER</role>\n                </project>\n            </user>\n            <domain_name>i2b2demo</domain_name>\n            <domain_id>i2b2demo</domain_id>\n            <active>true</active>\n            <cell_datas>\n                <cell_data id="CRC">\n                    <name>Data Repository</name>\n                    <url>http://i2b2:8080/i2b2/services/QueryToolService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="FRC">\n                    <name>File Repository </name>\n                    <url>http://i2b2:8080/i2b2/services/FRService/</url>\n                    <project_path>/</project_path>\n                    <method>SOAP</method>\n                    <can_override>true</can_override>\n                    <param name="DestDir" id="1" datatype="T">/opt/jboss/wildfly/standalone/data/i2b2_FR_files</param>\n                </cell_data>\n                <cell_data id="ONT">\n                    <name>Ontology Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/OntologyService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="WORK">\n                    <name>Workplace Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/WorkplaceService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="IM">\n                    <name>IM Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/IMService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n            </cell_datas>\n            <global_data/>\n        </ns4:configure>\n    </message_body>\n</ns2:response>
15	24af9eef-c645-4e56-a335-841ae16b3260	demo	Demo	\N	\N	2022-05-02 12:02:11.22	\N	N	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns4:query_definition xmlns:ns2="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/">\n    <query_id>24af9eef-c645-4e56-a335-841ae16b3260</query_id>\n    <query_name>24af9eef-c645-4e56-a335-841ae16b3260</query_name>\n    <query_description>Query from GeCo i2b2 data source (24af9eef-c645-4e56-a335-841ae16b3260)</query_description>\n    <query_timing>any</query_timing>\n    <specificity_scale>0</specificity_scale>\n    <panel>\n        <panel_number>1</panel_number>\n        <panel_timing>any</panel_timing>\n        <panel_accuracy_scale>100</panel_accuracy_scale>\n        <invert>0</invert>\n        <total_item_occurrences>1</total_item_occurrences>\n        <item>\n            <hlevel>0</hlevel>\n            <item_name></item_name>\n            <item_key>patient_set_coll_id:-101</item_key>\n            <item_icon></item_icon>\n            <tooltip></tooltip>\n            <class></class>\n            <item_is_synonym>false</item_is_synonym>\n        </item>\n    </panel>\n    <panel>\n        <panel_number>2</panel_number>\n        <panel_timing>any</panel_timing>\n        <panel_accuracy_scale>100</panel_accuracy_scale>\n        <invert>0</invert>\n        <total_item_occurrences>1</total_item_occurrences>\n        <item>\n            <hlevel>0</hlevel>\n            <item_name></item_name>\n            <item_key>\\\\SPHN\\SPHNv2020.1\\FophDiagnosis\\</item_key>\n            <item_icon></item_icon>\n            <tooltip></tooltip>\n            <class></class>\n            <item_is_synonym>false</item_is_synonym>\n        </item>\n    </panel>\n</ns4:query_definition>\n	insert into QUERY_GLOBAL_TEMP (patient_num, panel_count)\nwith t as ( \nselect  patient_num  from  i2b2demodata.qt_patient_set_collection    where  result_instance_id   =  -101\n ) \nselect  t.patient_num, 0 as panel_count  from t \n<*>\nupdate QUERY_GLOBAL_TEMP set panel_count =1 where QUERY_GLOBAL_TEMP.panel_count =  0 and exists ( select 1 from ( select  f.patient_num  \nfrom i2b2demodata.observation_fact f \nwhere  \nf.concept_cd IN (select concept_cd from  i2b2demodata.concept_dimension   where concept_path LIKE '\\\\SPHNv2020.1\\\\FophDiagnosis\\\\%')   \ngroup by  f.patient_num ) t where QUERY_GLOBAL_TEMP.patient_num = t.patient_num    ) \n<*>\n insert into DX (  patient_num   ) select * from ( select distinct  patient_num  from QUERY_GLOBAL_TEMP where panel_count = 1 ) q	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns5:request xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <message_header>\n        <i2b2_version_compatible>0.3</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>GeCo i2b2 Data Source</application_name>\n            <application_version>0.2</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>GeCo</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>i2b2 cell</application_name>\n            <application_version>1.7</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-05-02T14:02:11+02:00</datetime_of_message>\n        <security>\n            <domain>i2b2demo</domain>\n            <username>demo</username>\n            <password is_token="false">password not stored</password>\n        </security>\n        <message_type>\n            <message_code>EQQ</message_code>\n            <event_type>Q04</event_type>\n            <message_structure>EQQ_Q04</message_structure>\n        </message_type>\n        <message_control_id>\n            <session_id>2022-05-02T14:02:11+02:00</session_id>\n            <message_num>1651492931</message_num>\n            <instance_num>0</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n        <application_acknowledgement_type></application_acknowledgement_type>\n        <country_code>CH</country_code>\n        <project_id>Demo</project_id>\n    </message_header>\n    <request_header>\n        <result_waittime_ms>10000</result_waittime_ms>\n    </request_header>\n    <message_body>\n        <ns4:psmheader>\n            <user login="demo" group="i2b2demo">demo</user>\n            <patient_set_limit>0</patient_set_limit>\n            <estimated_time>0</estimated_time>\n            <query_mode>optimize_without_temp_table</query_mode>\n            <request_type>CRC_QRY_runQueryInstance_fromQueryDefinition</request_type>\n        </ns4:psmheader>\n        <ns4:request xsi:type="ns4:query_definition_requestType" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">\n            <query_definition>\n                <query_id>24af9eef-c645-4e56-a335-841ae16b3260</query_id>\n                <query_name>24af9eef-c645-4e56-a335-841ae16b3260</query_name>\n                <query_description>Query from GeCo i2b2 data source (24af9eef-c645-4e56-a335-841ae16b3260)</query_description>\n                <query_timing>any</query_timing>\n                <specificity_scale>0</specificity_scale>\n                <panel>\n                    <panel_number>1</panel_number>\n                    <panel_timing>any</panel_timing>\n                    <panel_accuracy_scale>100</panel_accuracy_scale>\n                    <invert>0</invert>\n                    <total_item_occurrences>1</total_item_occurrences>\n                    <item>\n                        <hlevel>0</hlevel>\n                        <item_name></item_name>\n                        <item_key>patient_set_coll_id:-101</item_key>\n                        <item_icon></item_icon>\n                        <tooltip></tooltip>\n                        <class></class>\n                        <item_is_synonym>false</item_is_synonym>\n                    </item>\n                </panel>\n                <panel>\n                    <panel_number>2</panel_number>\n                    <panel_timing>any</panel_timing>\n                    <panel_accuracy_scale>100</panel_accuracy_scale>\n                    <invert>0</invert>\n                    <total_item_occurrences>1</total_item_occurrences>\n                    <item>\n                        <hlevel>0</hlevel>\n                        <item_name></item_name>\n                        <item_key>\\\\SPHN\\SPHNv2020.1\\FophDiagnosis\\</item_key>\n                        <item_icon></item_icon>\n                        <tooltip></tooltip>\n                        <class></class>\n                        <item_is_synonym>false</item_is_synonym>\n                    </item>\n                </panel>\n            </query_definition>\n            <result_output_list>\n                <result_output name="PATIENTSET" priority_index="1"/>\n                <result_output name="PATIENT_COUNT_XML" priority_index="2"/>\n            </result_output_list>\n        </ns4:request>\n    </message_body>\n</ns5:request>\n	<ns2:response xmlns:ns2="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/hive/msg/version/">\n    <message_header>\n        <i2b2_version_compatible>1.1</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>PM Cell</application_name>\n            <application_version>1.700</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>i2b2 Hive</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>PM Cell</application_name>\n            <application_version>1.700</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 Hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-05-02T12:02:11.235Z</datetime_of_message>\n        <message_control_id>\n            <instance_num>1</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>AL</accept_acknowledgement_type>\n        <application_acknowledgement_type>AL</application_acknowledgement_type>\n        <country_code>US</country_code>\n        <project_id/>\n    </message_header>\n    <response_header>\n        <result_status>\n            <status type="DONE">PM processing completed</status>\n        </result_status>\n    </response_header>\n    <message_body>\n        <ns4:configure>\n            <environment>DEVELOPMENT</environment>\n            <helpURL>http://www.i2b2.org</helpURL>\n            <user>\n                <full_name>i2b2 User</full_name>\n                <user_name>demo</user_name>\n                <password is_token="true" token_ms_timeout="1800000">SessionKey:rto4Awn4XXndaQQClkWt</password>\n                <domain>i2b2demo</domain>\n                <is_admin>false</is_admin>\n                <project id="Demo">\n                    <name>i2b2 Demo</name>\n                    <wiki>http://www.i2b2.org</wiki>\n                    <path>/Demo</path>\n                    <role>DATA_AGG</role>\n                    <role>DATA_DEID</role>\n                    <role>DATA_LDS</role>\n                    <role>DATA_OBFSC</role>\n                    <role>DATA_PROT</role>\n                    <role>EDITOR</role>\n                    <role>USER</role>\n                </project>\n            </user>\n            <domain_name>i2b2demo</domain_name>\n            <domain_id>i2b2demo</domain_id>\n            <active>true</active>\n            <cell_datas>\n                <cell_data id="CRC">\n                    <name>Data Repository</name>\n                    <url>http://i2b2:8080/i2b2/services/QueryToolService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="FRC">\n                    <name>File Repository </name>\n                    <url>http://i2b2:8080/i2b2/services/FRService/</url>\n                    <project_path>/</project_path>\n                    <method>SOAP</method>\n                    <can_override>true</can_override>\n                    <param name="DestDir" id="1" datatype="T">/opt/jboss/wildfly/standalone/data/i2b2_FR_files</param>\n                </cell_data>\n                <cell_data id="ONT">\n                    <name>Ontology Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/OntologyService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="WORK">\n                    <name>Workplace Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/WorkplaceService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="IM">\n                    <name>IM Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/IMService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n            </cell_datas>\n            <global_data/>\n        </ns4:configure>\n    </message_body>\n</ns2:response>
16	5a2d240c-918f-45b9-8532-86e6d3211af8	demo	Demo	\N	\N	2022-05-02 12:02:11.564	\N	N	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns4:query_definition xmlns:ns2="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/">\n    <query_id>5a2d240c-918f-45b9-8532-86e6d3211af8</query_id>\n    <query_name>5a2d240c-918f-45b9-8532-86e6d3211af8</query_name>\n    <query_description>Query from GeCo i2b2 data source (5a2d240c-918f-45b9-8532-86e6d3211af8)</query_description>\n    <query_timing>any</query_timing>\n    <specificity_scale>0</specificity_scale>\n    <panel>\n        <panel_number>1</panel_number>\n        <panel_timing>any</panel_timing>\n        <panel_accuracy_scale>100</panel_accuracy_scale>\n        <invert>0</invert>\n        <total_item_occurrences>1</total_item_occurrences>\n        <item>\n            <hlevel>0</hlevel>\n            <item_name></item_name>\n            <item_key>patient_set_coll_id:-101</item_key>\n            <item_icon></item_icon>\n            <tooltip></tooltip>\n            <class></class>\n            <item_is_synonym>false</item_is_synonym>\n        </item>\n    </panel>\n    <panel>\n        <panel_number>2</panel_number>\n        <panel_timing>any</panel_timing>\n        <panel_accuracy_scale>100</panel_accuracy_scale>\n        <invert>0</invert>\n        <total_item_occurrences>1</total_item_occurrences>\n        <item>\n            <hlevel>0</hlevel>\n            <item_name></item_name>\n            <item_key>\\\\SPHN\\SPHNv2020.1\\FophDiagnosis\\</item_key>\n            <item_icon></item_icon>\n            <tooltip></tooltip>\n            <class></class>\n            <item_is_synonym>false</item_is_synonym>\n        </item>\n    </panel>\n</ns4:query_definition>\n	insert into QUERY_GLOBAL_TEMP (patient_num, panel_count)\nwith t as ( \nselect  patient_num  from  i2b2demodata.qt_patient_set_collection    where  result_instance_id   =  -101\n ) \nselect  t.patient_num, 0 as panel_count  from t \n<*>\nupdate QUERY_GLOBAL_TEMP set panel_count =1 where QUERY_GLOBAL_TEMP.panel_count =  0 and exists ( select 1 from ( select  f.patient_num  \nfrom i2b2demodata.observation_fact f \nwhere  \nf.concept_cd IN (select concept_cd from  i2b2demodata.concept_dimension   where concept_path LIKE '\\\\SPHNv2020.1\\\\FophDiagnosis\\\\%')   \ngroup by  f.patient_num ) t where QUERY_GLOBAL_TEMP.patient_num = t.patient_num    ) \n<*>\n insert into DX (  patient_num   ) select * from ( select distinct  patient_num  from QUERY_GLOBAL_TEMP where panel_count = 1 ) q	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns5:request xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <message_header>\n        <i2b2_version_compatible>0.3</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>GeCo i2b2 Data Source</application_name>\n            <application_version>0.2</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>GeCo</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>i2b2 cell</application_name>\n            <application_version>1.7</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-05-02T14:02:11+02:00</datetime_of_message>\n        <security>\n            <domain>i2b2demo</domain>\n            <username>demo</username>\n            <password is_token="false">password not stored</password>\n        </security>\n        <message_type>\n            <message_code>EQQ</message_code>\n            <event_type>Q04</event_type>\n            <message_structure>EQQ_Q04</message_structure>\n        </message_type>\n        <message_control_id>\n            <session_id>2022-05-02T14:02:11+02:00</session_id>\n            <message_num>1651492931</message_num>\n            <instance_num>0</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n        <application_acknowledgement_type></application_acknowledgement_type>\n        <country_code>CH</country_code>\n        <project_id>Demo</project_id>\n    </message_header>\n    <request_header>\n        <result_waittime_ms>10000</result_waittime_ms>\n    </request_header>\n    <message_body>\n        <ns4:psmheader>\n            <user login="demo" group="i2b2demo">demo</user>\n            <patient_set_limit>0</patient_set_limit>\n            <estimated_time>0</estimated_time>\n            <query_mode>optimize_without_temp_table</query_mode>\n            <request_type>CRC_QRY_runQueryInstance_fromQueryDefinition</request_type>\n        </ns4:psmheader>\n        <ns4:request xsi:type="ns4:query_definition_requestType" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">\n            <query_definition>\n                <query_id>5a2d240c-918f-45b9-8532-86e6d3211af8</query_id>\n                <query_name>5a2d240c-918f-45b9-8532-86e6d3211af8</query_name>\n                <query_description>Query from GeCo i2b2 data source (5a2d240c-918f-45b9-8532-86e6d3211af8)</query_description>\n                <query_timing>any</query_timing>\n                <specificity_scale>0</specificity_scale>\n                <panel>\n                    <panel_number>1</panel_number>\n                    <panel_timing>any</panel_timing>\n                    <panel_accuracy_scale>100</panel_accuracy_scale>\n                    <invert>0</invert>\n                    <total_item_occurrences>1</total_item_occurrences>\n                    <item>\n                        <hlevel>0</hlevel>\n                        <item_name></item_name>\n                        <item_key>patient_set_coll_id:-101</item_key>\n                        <item_icon></item_icon>\n                        <tooltip></tooltip>\n                        <class></class>\n                        <item_is_synonym>false</item_is_synonym>\n                    </item>\n                </panel>\n                <panel>\n                    <panel_number>2</panel_number>\n                    <panel_timing>any</panel_timing>\n                    <panel_accuracy_scale>100</panel_accuracy_scale>\n                    <invert>0</invert>\n                    <total_item_occurrences>1</total_item_occurrences>\n                    <item>\n                        <hlevel>0</hlevel>\n                        <item_name></item_name>\n                        <item_key>\\\\SPHN\\SPHNv2020.1\\FophDiagnosis\\</item_key>\n                        <item_icon></item_icon>\n                        <tooltip></tooltip>\n                        <class></class>\n                        <item_is_synonym>false</item_is_synonym>\n                    </item>\n                </panel>\n            </query_definition>\n            <result_output_list>\n                <result_output name="PATIENTSET" priority_index="1"/>\n                <result_output name="PATIENT_COUNT_XML" priority_index="2"/>\n            </result_output_list>\n        </ns4:request>\n    </message_body>\n</ns5:request>\n	<ns2:response xmlns:ns2="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/hive/msg/version/">\n    <message_header>\n        <i2b2_version_compatible>1.1</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>PM Cell</application_name>\n            <application_version>1.700</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>i2b2 Hive</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>PM Cell</application_name>\n            <application_version>1.700</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 Hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-05-02T12:02:11.583Z</datetime_of_message>\n        <message_control_id>\n            <instance_num>1</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>AL</accept_acknowledgement_type>\n        <application_acknowledgement_type>AL</application_acknowledgement_type>\n        <country_code>US</country_code>\n        <project_id/>\n    </message_header>\n    <response_header>\n        <result_status>\n            <status type="DONE">PM processing completed</status>\n        </result_status>\n    </response_header>\n    <message_body>\n        <ns4:configure>\n            <environment>DEVELOPMENT</environment>\n            <helpURL>http://www.i2b2.org</helpURL>\n            <user>\n                <full_name>i2b2 User</full_name>\n                <user_name>demo</user_name>\n                <password is_token="true" token_ms_timeout="1800000">SessionKey:yqagct0euSn8pDLAMmJp</password>\n                <domain>i2b2demo</domain>\n                <is_admin>false</is_admin>\n                <project id="Demo">\n                    <name>i2b2 Demo</name>\n                    <wiki>http://www.i2b2.org</wiki>\n                    <path>/Demo</path>\n                    <role>DATA_AGG</role>\n                    <role>DATA_DEID</role>\n                    <role>DATA_LDS</role>\n                    <role>DATA_OBFSC</role>\n                    <role>DATA_PROT</role>\n                    <role>EDITOR</role>\n                    <role>USER</role>\n                </project>\n            </user>\n            <domain_name>i2b2demo</domain_name>\n            <domain_id>i2b2demo</domain_id>\n            <active>true</active>\n            <cell_datas>\n                <cell_data id="CRC">\n                    <name>Data Repository</name>\n                    <url>http://i2b2:8080/i2b2/services/QueryToolService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="FRC">\n                    <name>File Repository </name>\n                    <url>http://i2b2:8080/i2b2/services/FRService/</url>\n                    <project_path>/</project_path>\n                    <method>SOAP</method>\n                    <can_override>true</can_override>\n                    <param name="DestDir" id="1" datatype="T">/opt/jboss/wildfly/standalone/data/i2b2_FR_files</param>\n                </cell_data>\n                <cell_data id="ONT">\n                    <name>Ontology Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/OntologyService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="WORK">\n                    <name>Workplace Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/WorkplaceService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="IM">\n                    <name>IM Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/IMService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n            </cell_datas>\n            <global_data/>\n        </ns4:configure>\n    </message_body>\n</ns2:response>
17	f0140b96-33a4-46e2-80e5-cdc721053c32	demo	Demo	\N	\N	2022-05-02 12:02:11.968	\N	N	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns4:query_definition xmlns:ns2="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/">\n    <query_id>f0140b96-33a4-46e2-80e5-cdc721053c32</query_id>\n    <query_name>f0140b96-33a4-46e2-80e5-cdc721053c32</query_name>\n    <query_description>Query from GeCo i2b2 data source (f0140b96-33a4-46e2-80e5-cdc721053c32)</query_description>\n    <query_timing>any</query_timing>\n    <specificity_scale>0</specificity_scale>\n    <panel>\n        <panel_number>1</panel_number>\n        <panel_timing>any</panel_timing>\n        <panel_accuracy_scale>100</panel_accuracy_scale>\n        <invert>0</invert>\n        <total_item_occurrences>1</total_item_occurrences>\n        <item>\n            <hlevel>0</hlevel>\n            <item_name></item_name>\n            <item_key>patient_set_coll_id:-101</item_key>\n            <item_icon></item_icon>\n            <tooltip></tooltip>\n            <class></class>\n            <item_is_synonym>false</item_is_synonym>\n        </item>\n    </panel>\n    <panel>\n        <panel_number>2</panel_number>\n        <panel_timing>any</panel_timing>\n        <panel_accuracy_scale>100</panel_accuracy_scale>\n        <invert>0</invert>\n        <total_item_occurrences>1</total_item_occurrences>\n        <item>\n            <hlevel>0</hlevel>\n            <item_name></item_name>\n            <item_key>\\\\SPHN\\SPHNv2020.1\\FophDiagnosis\\</item_key>\n            <item_icon></item_icon>\n            <tooltip></tooltip>\n            <class></class>\n            <item_is_synonym>false</item_is_synonym>\n        </item>\n    </panel>\n</ns4:query_definition>\n	insert into QUERY_GLOBAL_TEMP (patient_num, panel_count)\nwith t as ( \nselect  patient_num  from  i2b2demodata.qt_patient_set_collection    where  result_instance_id   =  -101\n ) \nselect  t.patient_num, 0 as panel_count  from t \n<*>\nupdate QUERY_GLOBAL_TEMP set panel_count =1 where QUERY_GLOBAL_TEMP.panel_count =  0 and exists ( select 1 from ( select  f.patient_num  \nfrom i2b2demodata.observation_fact f \nwhere  \nf.concept_cd IN (select concept_cd from  i2b2demodata.concept_dimension   where concept_path LIKE '\\\\SPHNv2020.1\\\\FophDiagnosis\\\\%')   \ngroup by  f.patient_num ) t where QUERY_GLOBAL_TEMP.patient_num = t.patient_num    ) \n<*>\n insert into DX (  patient_num   ) select * from ( select distinct  patient_num  from QUERY_GLOBAL_TEMP where panel_count = 1 ) q	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns5:request xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <message_header>\n        <i2b2_version_compatible>0.3</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>GeCo i2b2 Data Source</application_name>\n            <application_version>0.2</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>GeCo</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>i2b2 cell</application_name>\n            <application_version>1.7</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-05-02T14:02:11+02:00</datetime_of_message>\n        <security>\n            <domain>i2b2demo</domain>\n            <username>demo</username>\n            <password is_token="false">password not stored</password>\n        </security>\n        <message_type>\n            <message_code>EQQ</message_code>\n            <event_type>Q04</event_type>\n            <message_structure>EQQ_Q04</message_structure>\n        </message_type>\n        <message_control_id>\n            <session_id>2022-05-02T14:02:11+02:00</session_id>\n            <message_num>1651492931</message_num>\n            <instance_num>0</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n        <application_acknowledgement_type></application_acknowledgement_type>\n        <country_code>CH</country_code>\n        <project_id>Demo</project_id>\n    </message_header>\n    <request_header>\n        <result_waittime_ms>10000</result_waittime_ms>\n    </request_header>\n    <message_body>\n        <ns4:psmheader>\n            <user login="demo" group="i2b2demo">demo</user>\n            <patient_set_limit>0</patient_set_limit>\n            <estimated_time>0</estimated_time>\n            <query_mode>optimize_without_temp_table</query_mode>\n            <request_type>CRC_QRY_runQueryInstance_fromQueryDefinition</request_type>\n        </ns4:psmheader>\n        <ns4:request xsi:type="ns4:query_definition_requestType" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">\n            <query_definition>\n                <query_id>f0140b96-33a4-46e2-80e5-cdc721053c32</query_id>\n                <query_name>f0140b96-33a4-46e2-80e5-cdc721053c32</query_name>\n                <query_description>Query from GeCo i2b2 data source (f0140b96-33a4-46e2-80e5-cdc721053c32)</query_description>\n                <query_timing>any</query_timing>\n                <specificity_scale>0</specificity_scale>\n                <panel>\n                    <panel_number>1</panel_number>\n                    <panel_timing>any</panel_timing>\n                    <panel_accuracy_scale>100</panel_accuracy_scale>\n                    <invert>0</invert>\n                    <total_item_occurrences>1</total_item_occurrences>\n                    <item>\n                        <hlevel>0</hlevel>\n                        <item_name></item_name>\n                        <item_key>patient_set_coll_id:-101</item_key>\n                        <item_icon></item_icon>\n                        <tooltip></tooltip>\n                        <class></class>\n                        <item_is_synonym>false</item_is_synonym>\n                    </item>\n                </panel>\n                <panel>\n                    <panel_number>2</panel_number>\n                    <panel_timing>any</panel_timing>\n                    <panel_accuracy_scale>100</panel_accuracy_scale>\n                    <invert>0</invert>\n                    <total_item_occurrences>1</total_item_occurrences>\n                    <item>\n                        <hlevel>0</hlevel>\n                        <item_name></item_name>\n                        <item_key>\\\\SPHN\\SPHNv2020.1\\FophDiagnosis\\</item_key>\n                        <item_icon></item_icon>\n                        <tooltip></tooltip>\n                        <class></class>\n                        <item_is_synonym>false</item_is_synonym>\n                    </item>\n                </panel>\n            </query_definition>\n            <result_output_list>\n                <result_output name="PATIENTSET" priority_index="1"/>\n                <result_output name="PATIENT_COUNT_XML" priority_index="2"/>\n            </result_output_list>\n        </ns4:request>\n    </message_body>\n</ns5:request>\n	<ns2:response xmlns:ns2="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/hive/msg/version/">\n    <message_header>\n        <i2b2_version_compatible>1.1</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>PM Cell</application_name>\n            <application_version>1.700</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>i2b2 Hive</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>PM Cell</application_name>\n            <application_version>1.700</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 Hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-05-02T12:02:11.994Z</datetime_of_message>\n        <message_control_id>\n            <instance_num>1</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>AL</accept_acknowledgement_type>\n        <application_acknowledgement_type>AL</application_acknowledgement_type>\n        <country_code>US</country_code>\n        <project_id/>\n    </message_header>\n    <response_header>\n        <result_status>\n            <status type="DONE">PM processing completed</status>\n        </result_status>\n    </response_header>\n    <message_body>\n        <ns4:configure>\n            <environment>DEVELOPMENT</environment>\n            <helpURL>http://www.i2b2.org</helpURL>\n            <user>\n                <full_name>i2b2 User</full_name>\n                <user_name>demo</user_name>\n                <password is_token="true" token_ms_timeout="1800000">SessionKey:xtmU85RAEYdYUiiViO95</password>\n                <domain>i2b2demo</domain>\n                <is_admin>false</is_admin>\n                <project id="Demo">\n                    <name>i2b2 Demo</name>\n                    <wiki>http://www.i2b2.org</wiki>\n                    <path>/Demo</path>\n                    <role>DATA_AGG</role>\n                    <role>DATA_DEID</role>\n                    <role>DATA_LDS</role>\n                    <role>DATA_OBFSC</role>\n                    <role>DATA_PROT</role>\n                    <role>EDITOR</role>\n                    <role>USER</role>\n                </project>\n            </user>\n            <domain_name>i2b2demo</domain_name>\n            <domain_id>i2b2demo</domain_id>\n            <active>true</active>\n            <cell_datas>\n                <cell_data id="CRC">\n                    <name>Data Repository</name>\n                    <url>http://i2b2:8080/i2b2/services/QueryToolService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="FRC">\n                    <name>File Repository </name>\n                    <url>http://i2b2:8080/i2b2/services/FRService/</url>\n                    <project_path>/</project_path>\n                    <method>SOAP</method>\n                    <can_override>true</can_override>\n                    <param name="DestDir" id="1" datatype="T">/opt/jboss/wildfly/standalone/data/i2b2_FR_files</param>\n                </cell_data>\n                <cell_data id="ONT">\n                    <name>Ontology Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/OntologyService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="WORK">\n                    <name>Workplace Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/WorkplaceService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="IM">\n                    <name>IM Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/IMService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n            </cell_datas>\n            <global_data/>\n        </ns4:configure>\n    </message_body>\n</ns2:response>
19	7aa4c27f-a542-41b0-9285-d698b6787e58	demo	Demo	\N	\N	2022-05-02 12:02:12.402	\N	N	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns4:query_definition xmlns:ns2="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/">\n    <query_id>7aa4c27f-a542-41b0-9285-d698b6787e58</query_id>\n    <query_name>7aa4c27f-a542-41b0-9285-d698b6787e58</query_name>\n    <query_description>Query from GeCo i2b2 data source (7aa4c27f-a542-41b0-9285-d698b6787e58)</query_description>\n    <query_timing>any</query_timing>\n    <specificity_scale>0</specificity_scale>\n    <panel>\n        <panel_number>1</panel_number>\n        <panel_timing>any</panel_timing>\n        <panel_accuracy_scale>100</panel_accuracy_scale>\n        <invert>0</invert>\n        <total_item_occurrences>1</total_item_occurrences>\n        <item>\n            <hlevel>0</hlevel>\n            <item_name></item_name>\n            <item_key>\\\\I2B2\\I2B2\\Demographics\\Gender\\Male\\</item_key>\n            <item_icon></item_icon>\n            <tooltip></tooltip>\n            <class></class>\n            <item_is_synonym>false</item_is_synonym>\n        </item>\n    </panel>\n    <panel>\n        <panel_number>2</panel_number>\n        <panel_timing>any</panel_timing>\n        <panel_accuracy_scale>100</panel_accuracy_scale>\n        <invert>0</invert>\n        <total_item_occurrences>1</total_item_occurrences>\n        <item>\n            <hlevel>0</hlevel>\n            <item_name></item_name>\n            <item_key>patient_set_coll_id:-101</item_key>\n            <item_icon></item_icon>\n            <tooltip></tooltip>\n            <class></class>\n            <item_is_synonym>false</item_is_synonym>\n        </item>\n    </panel>\n    <panel>\n        <panel_number>3</panel_number>\n        <panel_timing>any</panel_timing>\n        <panel_accuracy_scale>100</panel_accuracy_scale>\n        <invert>0</invert>\n        <total_item_occurrences>1</total_item_occurrences>\n        <item>\n            <hlevel>0</hlevel>\n            <item_name></item_name>\n            <item_key>\\\\SPHN\\SPHNv2020.1\\FophDiagnosis\\</item_key>\n            <item_icon></item_icon>\n            <tooltip></tooltip>\n            <class></class>\n            <item_is_synonym>false</item_is_synonym>\n        </item>\n    </panel>\n</ns4:query_definition>\n	insert into QUERY_GLOBAL_TEMP (patient_num, panel_count)\nwith t as ( \n select  f.patient_num  \nfrom i2b2demodata.observation_fact f \nwhere  \nf.concept_cd IN (select concept_cd from  i2b2demodata.concept_dimension   where concept_path LIKE '\\\\I2B2\\\\Demographics\\\\Gender\\\\Male\\\\%')   \ngroup by  f.patient_num \n ) \nselect  t.patient_num, 0 as panel_count  from t \n<*>\nupdate QUERY_GLOBAL_TEMP set panel_count =1 where QUERY_GLOBAL_TEMP.panel_count =  0 and exists ( select 1 from (select  patient_num  from  i2b2demodata.qt_patient_set_collection    where  result_instance_id   =  -101) t where QUERY_GLOBAL_TEMP.patient_num = t.patient_num    ) \n<*>\nupdate QUERY_GLOBAL_TEMP set panel_count =2 where QUERY_GLOBAL_TEMP.panel_count =  1 and exists ( select 1 from ( select  f.patient_num  \nfrom i2b2demodata.observation_fact f \nwhere  \nf.concept_cd IN (select concept_cd from  i2b2demodata.concept_dimension   where concept_path LIKE '\\\\SPHNv2020.1\\\\FophDiagnosis\\\\%')   \ngroup by  f.patient_num ) t where QUERY_GLOBAL_TEMP.patient_num = t.patient_num    ) \n<*>\n insert into DX (  patient_num   ) select * from ( select distinct  patient_num  from QUERY_GLOBAL_TEMP where panel_count = 2 ) q	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns5:request xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <message_header>\n        <i2b2_version_compatible>0.3</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>GeCo i2b2 Data Source</application_name>\n            <application_version>0.2</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>GeCo</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>i2b2 cell</application_name>\n            <application_version>1.7</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-05-02T14:02:12+02:00</datetime_of_message>\n        <security>\n            <domain>i2b2demo</domain>\n            <username>demo</username>\n            <password is_token="false">password not stored</password>\n        </security>\n        <message_type>\n            <message_code>EQQ</message_code>\n            <event_type>Q04</event_type>\n            <message_structure>EQQ_Q04</message_structure>\n        </message_type>\n        <message_control_id>\n            <session_id>2022-05-02T14:02:12+02:00</session_id>\n            <message_num>1651492932</message_num>\n            <instance_num>0</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n        <application_acknowledgement_type></application_acknowledgement_type>\n        <country_code>CH</country_code>\n        <project_id>Demo</project_id>\n    </message_header>\n    <request_header>\n        <result_waittime_ms>10000</result_waittime_ms>\n    </request_header>\n    <message_body>\n        <ns4:psmheader>\n            <user login="demo" group="i2b2demo">demo</user>\n            <patient_set_limit>0</patient_set_limit>\n            <estimated_time>0</estimated_time>\n            <query_mode>optimize_without_temp_table</query_mode>\n            <request_type>CRC_QRY_runQueryInstance_fromQueryDefinition</request_type>\n        </ns4:psmheader>\n        <ns4:request xsi:type="ns4:query_definition_requestType" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">\n            <query_definition>\n                <query_id>7aa4c27f-a542-41b0-9285-d698b6787e58</query_id>\n                <query_name>7aa4c27f-a542-41b0-9285-d698b6787e58</query_name>\n                <query_description>Query from GeCo i2b2 data source (7aa4c27f-a542-41b0-9285-d698b6787e58)</query_description>\n                <query_timing>any</query_timing>\n                <specificity_scale>0</specificity_scale>\n                <panel>\n                    <panel_number>1</panel_number>\n                    <panel_timing>any</panel_timing>\n                    <panel_accuracy_scale>100</panel_accuracy_scale>\n                    <invert>0</invert>\n                    <total_item_occurrences>1</total_item_occurrences>\n                    <item>\n                        <hlevel>0</hlevel>\n                        <item_name></item_name>\n                        <item_key>\\\\I2B2\\I2B2\\Demographics\\Gender\\Male\\</item_key>\n                        <item_icon></item_icon>\n                        <tooltip></tooltip>\n                        <class></class>\n                        <item_is_synonym>false</item_is_synonym>\n                    </item>\n                </panel>\n                <panel>\n                    <panel_number>2</panel_number>\n                    <panel_timing>any</panel_timing>\n                    <panel_accuracy_scale>100</panel_accuracy_scale>\n                    <invert>0</invert>\n                    <total_item_occurrences>1</total_item_occurrences>\n                    <item>\n                        <hlevel>0</hlevel>\n                        <item_name></item_name>\n                        <item_key>patient_set_coll_id:-101</item_key>\n                        <item_icon></item_icon>\n                        <tooltip></tooltip>\n                        <class></class>\n                        <item_is_synonym>false</item_is_synonym>\n                    </item>\n                </panel>\n                <panel>\n                    <panel_number>3</panel_number>\n                    <panel_timing>any</panel_timing>\n                    <panel_accuracy_scale>100</panel_accuracy_scale>\n                    <invert>0</invert>\n                    <total_item_occurrences>1</total_item_occurrences>\n                    <item>\n                        <hlevel>0</hlevel>\n                        <item_name></item_name>\n                        <item_key>\\\\SPHN\\SPHNv2020.1\\FophDiagnosis\\</item_key>\n                        <item_icon></item_icon>\n                        <tooltip></tooltip>\n                        <class></class>\n                        <item_is_synonym>false</item_is_synonym>\n                    </item>\n                </panel>\n            </query_definition>\n            <result_output_list>\n                <result_output name="PATIENTSET" priority_index="1"/>\n                <result_output name="PATIENT_COUNT_XML" priority_index="2"/>\n            </result_output_list>\n        </ns4:request>\n    </message_body>\n</ns5:request>\n	<ns2:response xmlns:ns2="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/hive/msg/version/">\n    <message_header>\n        <i2b2_version_compatible>1.1</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>PM Cell</application_name>\n            <application_version>1.700</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>i2b2 Hive</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>PM Cell</application_name>\n            <application_version>1.700</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 Hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-05-02T12:02:12.426Z</datetime_of_message>\n        <message_control_id>\n            <instance_num>1</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>AL</accept_acknowledgement_type>\n        <application_acknowledgement_type>AL</application_acknowledgement_type>\n        <country_code>US</country_code>\n        <project_id/>\n    </message_header>\n    <response_header>\n        <result_status>\n            <status type="DONE">PM processing completed</status>\n        </result_status>\n    </response_header>\n    <message_body>\n        <ns4:configure>\n            <environment>DEVELOPMENT</environment>\n            <helpURL>http://www.i2b2.org</helpURL>\n            <user>\n                <full_name>i2b2 User</full_name>\n                <user_name>demo</user_name>\n                <password is_token="true" token_ms_timeout="1800000">SessionKey:zIRIqnUKd9TiT7qLZEd0</password>\n                <domain>i2b2demo</domain>\n                <is_admin>false</is_admin>\n                <project id="Demo">\n                    <name>i2b2 Demo</name>\n                    <wiki>http://www.i2b2.org</wiki>\n                    <path>/Demo</path>\n                    <role>DATA_AGG</role>\n                    <role>DATA_DEID</role>\n                    <role>DATA_LDS</role>\n                    <role>DATA_OBFSC</role>\n                    <role>DATA_PROT</role>\n                    <role>EDITOR</role>\n                    <role>USER</role>\n                </project>\n            </user>\n            <domain_name>i2b2demo</domain_name>\n            <domain_id>i2b2demo</domain_id>\n            <active>true</active>\n            <cell_datas>\n                <cell_data id="CRC">\n                    <name>Data Repository</name>\n                    <url>http://i2b2:8080/i2b2/services/QueryToolService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="FRC">\n                    <name>File Repository </name>\n                    <url>http://i2b2:8080/i2b2/services/FRService/</url>\n                    <project_path>/</project_path>\n                    <method>SOAP</method>\n                    <can_override>true</can_override>\n                    <param name="DestDir" id="1" datatype="T">/opt/jboss/wildfly/standalone/data/i2b2_FR_files</param>\n                </cell_data>\n                <cell_data id="ONT">\n                    <name>Ontology Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/OntologyService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="WORK">\n                    <name>Workplace Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/WorkplaceService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="IM">\n                    <name>IM Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/IMService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n            </cell_datas>\n            <global_data/>\n        </ns4:configure>\n    </message_body>\n</ns2:response>
18	b3176990-8813-481e-a04a-556eed0ae79f	demo	Demo	\N	\N	2022-05-02 12:02:12.391	\N	N	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns4:query_definition xmlns:ns2="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/">\n    <query_id>b3176990-8813-481e-a04a-556eed0ae79f</query_id>\n    <query_name>b3176990-8813-481e-a04a-556eed0ae79f</query_name>\n    <query_description>Query from GeCo i2b2 data source (b3176990-8813-481e-a04a-556eed0ae79f)</query_description>\n    <query_timing>any</query_timing>\n    <specificity_scale>0</specificity_scale>\n    <panel>\n        <panel_number>1</panel_number>\n        <panel_timing>any</panel_timing>\n        <panel_accuracy_scale>100</panel_accuracy_scale>\n        <invert>0</invert>\n        <total_item_occurrences>1</total_item_occurrences>\n        <item>\n            <hlevel>0</hlevel>\n            <item_name></item_name>\n            <item_key>\\\\I2B2\\I2B2\\Demographics\\Gender\\Female\\</item_key>\n            <item_icon></item_icon>\n            <tooltip></tooltip>\n            <class></class>\n            <item_is_synonym>false</item_is_synonym>\n        </item>\n    </panel>\n    <panel>\n        <panel_number>2</panel_number>\n        <panel_timing>any</panel_timing>\n        <panel_accuracy_scale>100</panel_accuracy_scale>\n        <invert>0</invert>\n        <total_item_occurrences>1</total_item_occurrences>\n        <item>\n            <hlevel>0</hlevel>\n            <item_name></item_name>\n            <item_key>patient_set_coll_id:-101</item_key>\n            <item_icon></item_icon>\n            <tooltip></tooltip>\n            <class></class>\n            <item_is_synonym>false</item_is_synonym>\n        </item>\n    </panel>\n    <panel>\n        <panel_number>3</panel_number>\n        <panel_timing>any</panel_timing>\n        <panel_accuracy_scale>100</panel_accuracy_scale>\n        <invert>0</invert>\n        <total_item_occurrences>1</total_item_occurrences>\n        <item>\n            <hlevel>0</hlevel>\n            <item_name></item_name>\n            <item_key>\\\\SPHN\\SPHNv2020.1\\FophDiagnosis\\</item_key>\n            <item_icon></item_icon>\n            <tooltip></tooltip>\n            <class></class>\n            <item_is_synonym>false</item_is_synonym>\n        </item>\n    </panel>\n</ns4:query_definition>\n	insert into QUERY_GLOBAL_TEMP (patient_num, panel_count)\nwith t as ( \n select  f.patient_num  \nfrom i2b2demodata.observation_fact f \nwhere  \nf.concept_cd IN (select concept_cd from  i2b2demodata.concept_dimension   where concept_path LIKE '\\\\I2B2\\\\Demographics\\\\Gender\\\\Female\\\\%')   \ngroup by  f.patient_num \n ) \nselect  t.patient_num, 0 as panel_count  from t \n<*>\nupdate QUERY_GLOBAL_TEMP set panel_count =1 where QUERY_GLOBAL_TEMP.panel_count =  0 and exists ( select 1 from (select  patient_num  from  i2b2demodata.qt_patient_set_collection    where  result_instance_id   =  -101) t where QUERY_GLOBAL_TEMP.patient_num = t.patient_num    ) \n<*>\nupdate QUERY_GLOBAL_TEMP set panel_count =2 where QUERY_GLOBAL_TEMP.panel_count =  1 and exists ( select 1 from ( select  f.patient_num  \nfrom i2b2demodata.observation_fact f \nwhere  \nf.concept_cd IN (select concept_cd from  i2b2demodata.concept_dimension   where concept_path LIKE '\\\\SPHNv2020.1\\\\FophDiagnosis\\\\%')   \ngroup by  f.patient_num ) t where QUERY_GLOBAL_TEMP.patient_num = t.patient_num    ) \n<*>\n insert into DX (  patient_num   ) select * from ( select distinct  patient_num  from QUERY_GLOBAL_TEMP where panel_count = 2 ) q	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns5:request xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <message_header>\n        <i2b2_version_compatible>0.3</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>GeCo i2b2 Data Source</application_name>\n            <application_version>0.2</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>GeCo</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>i2b2 cell</application_name>\n            <application_version>1.7</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-05-02T14:02:12+02:00</datetime_of_message>\n        <security>\n            <domain>i2b2demo</domain>\n            <username>demo</username>\n            <password is_token="false">password not stored</password>\n        </security>\n        <message_type>\n            <message_code>EQQ</message_code>\n            <event_type>Q04</event_type>\n            <message_structure>EQQ_Q04</message_structure>\n        </message_type>\n        <message_control_id>\n            <session_id>2022-05-02T14:02:12+02:00</session_id>\n            <message_num>1651492932</message_num>\n            <instance_num>0</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n        <application_acknowledgement_type></application_acknowledgement_type>\n        <country_code>CH</country_code>\n        <project_id>Demo</project_id>\n    </message_header>\n    <request_header>\n        <result_waittime_ms>10000</result_waittime_ms>\n    </request_header>\n    <message_body>\n        <ns4:psmheader>\n            <user login="demo" group="i2b2demo">demo</user>\n            <patient_set_limit>0</patient_set_limit>\n            <estimated_time>0</estimated_time>\n            <query_mode>optimize_without_temp_table</query_mode>\n            <request_type>CRC_QRY_runQueryInstance_fromQueryDefinition</request_type>\n        </ns4:psmheader>\n        <ns4:request xsi:type="ns4:query_definition_requestType" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">\n            <query_definition>\n                <query_id>b3176990-8813-481e-a04a-556eed0ae79f</query_id>\n                <query_name>b3176990-8813-481e-a04a-556eed0ae79f</query_name>\n                <query_description>Query from GeCo i2b2 data source (b3176990-8813-481e-a04a-556eed0ae79f)</query_description>\n                <query_timing>any</query_timing>\n                <specificity_scale>0</specificity_scale>\n                <panel>\n                    <panel_number>1</panel_number>\n                    <panel_timing>any</panel_timing>\n                    <panel_accuracy_scale>100</panel_accuracy_scale>\n                    <invert>0</invert>\n                    <total_item_occurrences>1</total_item_occurrences>\n                    <item>\n                        <hlevel>0</hlevel>\n                        <item_name></item_name>\n                        <item_key>\\\\I2B2\\I2B2\\Demographics\\Gender\\Female\\</item_key>\n                        <item_icon></item_icon>\n                        <tooltip></tooltip>\n                        <class></class>\n                        <item_is_synonym>false</item_is_synonym>\n                    </item>\n                </panel>\n                <panel>\n                    <panel_number>2</panel_number>\n                    <panel_timing>any</panel_timing>\n                    <panel_accuracy_scale>100</panel_accuracy_scale>\n                    <invert>0</invert>\n                    <total_item_occurrences>1</total_item_occurrences>\n                    <item>\n                        <hlevel>0</hlevel>\n                        <item_name></item_name>\n                        <item_key>patient_set_coll_id:-101</item_key>\n                        <item_icon></item_icon>\n                        <tooltip></tooltip>\n                        <class></class>\n                        <item_is_synonym>false</item_is_synonym>\n                    </item>\n                </panel>\n                <panel>\n                    <panel_number>3</panel_number>\n                    <panel_timing>any</panel_timing>\n                    <panel_accuracy_scale>100</panel_accuracy_scale>\n                    <invert>0</invert>\n                    <total_item_occurrences>1</total_item_occurrences>\n                    <item>\n                        <hlevel>0</hlevel>\n                        <item_name></item_name>\n                        <item_key>\\\\SPHN\\SPHNv2020.1\\FophDiagnosis\\</item_key>\n                        <item_icon></item_icon>\n                        <tooltip></tooltip>\n                        <class></class>\n                        <item_is_synonym>false</item_is_synonym>\n                    </item>\n                </panel>\n            </query_definition>\n            <result_output_list>\n                <result_output name="PATIENTSET" priority_index="1"/>\n                <result_output name="PATIENT_COUNT_XML" priority_index="2"/>\n            </result_output_list>\n        </ns4:request>\n    </message_body>\n</ns5:request>\n	<ns2:response xmlns:ns2="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/hive/msg/version/">\n    <message_header>\n        <i2b2_version_compatible>1.1</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>PM Cell</application_name>\n            <application_version>1.700</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>i2b2 Hive</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>PM Cell</application_name>\n            <application_version>1.700</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 Hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-05-02T12:02:12.418Z</datetime_of_message>\n        <message_control_id>\n            <instance_num>1</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>AL</accept_acknowledgement_type>\n        <application_acknowledgement_type>AL</application_acknowledgement_type>\n        <country_code>US</country_code>\n        <project_id/>\n    </message_header>\n    <response_header>\n        <result_status>\n            <status type="DONE">PM processing completed</status>\n        </result_status>\n    </response_header>\n    <message_body>\n        <ns4:configure>\n            <environment>DEVELOPMENT</environment>\n            <helpURL>http://www.i2b2.org</helpURL>\n            <user>\n                <full_name>i2b2 User</full_name>\n                <user_name>demo</user_name>\n                <password is_token="true" token_ms_timeout="1800000">SessionKey:dhyRL4yuz5m0XfBCmgPY</password>\n                <domain>i2b2demo</domain>\n                <is_admin>false</is_admin>\n                <project id="Demo">\n                    <name>i2b2 Demo</name>\n                    <wiki>http://www.i2b2.org</wiki>\n                    <path>/Demo</path>\n                    <role>DATA_AGG</role>\n                    <role>DATA_DEID</role>\n                    <role>DATA_LDS</role>\n                    <role>DATA_OBFSC</role>\n                    <role>DATA_PROT</role>\n                    <role>EDITOR</role>\n                    <role>USER</role>\n                </project>\n            </user>\n            <domain_name>i2b2demo</domain_name>\n            <domain_id>i2b2demo</domain_id>\n            <active>true</active>\n            <cell_datas>\n                <cell_data id="CRC">\n                    <name>Data Repository</name>\n                    <url>http://i2b2:8080/i2b2/services/QueryToolService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="FRC">\n                    <name>File Repository </name>\n                    <url>http://i2b2:8080/i2b2/services/FRService/</url>\n                    <project_path>/</project_path>\n                    <method>SOAP</method>\n                    <can_override>true</can_override>\n                    <param name="DestDir" id="1" datatype="T">/opt/jboss/wildfly/standalone/data/i2b2_FR_files</param>\n                </cell_data>\n                <cell_data id="ONT">\n                    <name>Ontology Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/OntologyService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="WORK">\n                    <name>Workplace Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/WorkplaceService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="IM">\n                    <name>IM Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/IMService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n            </cell_datas>\n            <global_data/>\n        </ns4:configure>\n    </message_body>\n</ns2:response>
\.


--
-- Data for Name: qt_query_result_instance; Type: TABLE DATA; Schema: i2b2demodata; Owner: postgres
--

COPY i2b2demodata.qt_query_result_instance (result_instance_id, query_instance_id, result_type_id, set_size, start_date, end_date, status_type_id, delete_flag, message, description, real_set_size, obfusc_method) FROM stdin;
-101	-100	1	228	2022-03-04 22:19:50.731	2022-03-04 22:19:51.571	3	N		Patient Set for "63eb6d7e-d437-4f37-a346-4819ed1c74c1"	1	
-102	-100	4	228	2022-03-04 22:19:50.744	2022-03-04 22:19:51.613	3	N		Number of patients for "63eb6d7e-d437-4f37-a346-4819ed1c74c1"	1	
38	19	4	90	2022-05-02 12:02:12.493	2022-05-02 12:02:12.757	3	N		Number of patients for "7aa4c27f-a542-41b0-9285-d698b6787e58"	90	
24	12	4	1	2022-05-02 12:02:09.208	2022-05-02 12:02:09.456	3	N		Number of patients for "1"	1	
1	1	1	3	2022-05-02 12:02:03.378	2022-05-02 12:02:03.854	3	N		Patient Set for "99999999-9999-1122-0000-999999999999"	3	
2	1	4	3	2022-05-02 12:02:03.384	2022-05-02 12:02:03.885	3	N		Number of patients for "99999999-9999-1122-0000-999999999999"	3	
3	2	1	1	2022-05-02 12:02:04.69	2022-05-02 12:02:05.19	3	N		Patient Set for "99999999-9999-9999-9999-999999999999"	1	
36	18	4	138	2022-05-02 12:02:12.489	2022-05-02 12:02:12.768	3	N		Number of patients for "b3176990-8813-481e-a04a-556eed0ae79f"	138	
4	2	4	1	2022-05-02 12:02:04.695	2022-05-02 12:02:05.2	3	N		Number of patients for "99999999-9999-9999-9999-999999999999"	1	
25	13	1	3	2022-05-02 12:02:09.615	2022-05-02 12:02:09.763	3	N		Patient Set for "44444444-7777-4444-4444-444444444442"	3	
5	3	1	3	2022-05-02 12:02:05.432	2022-05-02 12:02:05.591	3	N		Patient Set for "0"	3	
26	13	4	3	2022-05-02 12:02:09.617	2022-05-02 12:02:09.772	3	N		Number of patients for "44444444-7777-4444-4444-444444444442"	3	
6	3	4	3	2022-05-02 12:02:05.436	2022-05-02 12:02:05.6	3	N		Number of patients for "0"	3	
7	4	1	4	2022-05-02 12:02:05.772	2022-05-02 12:02:05.914	3	N		Patient Set for "1"	4	
8	4	4	4	2022-05-02 12:02:05.774	2022-05-02 12:02:05.921	3	N		Number of patients for "1"	4	
27	14	1	228	2022-05-02 12:02:10.872	2022-05-02 12:02:10.988	3	N		Patient Set for "6926d7ab-086b-410f-9c94-d9005d51122b"	228	
9	5	1	3	2022-05-02 12:02:06.071	2022-05-02 12:02:06.353	3	N		Patient Set for "2"	3	
10	5	4	3	2022-05-02 12:02:06.073	2022-05-02 12:02:06.362	3	N		Number of patients for "2"	3	
28	14	4	228	2022-05-02 12:02:10.873	2022-05-02 12:02:10.995	3	N		Number of patients for "6926d7ab-086b-410f-9c94-d9005d51122b"	228	
11	6	1	4	2022-05-02 12:02:06.546	2022-05-02 12:02:06.793	3	N		Patient Set for "3"	4	
12	6	4	4	2022-05-02 12:02:06.548	2022-05-02 12:02:06.801	3	N		Number of patients for "3"	4	
13	7	1	1	2022-05-02 12:02:06.985	2022-05-02 12:02:07.132	3	N		Patient Set for "0"	1	
29	15	1	228	2022-05-02 12:02:11.244	2022-05-02 12:02:11.36	3	N		Patient Set for "24af9eef-c645-4e56-a335-841ae16b3260"	228	
14	7	4	1	2022-05-02 12:02:06.987	2022-05-02 12:02:07.141	3	N		Number of patients for "0"	1	
30	15	4	228	2022-05-02 12:02:11.247	2022-05-02 12:02:11.366	3	N		Number of patients for "24af9eef-c645-4e56-a335-841ae16b3260"	228	
15	8	1	2	2022-05-02 12:02:07.318	2022-05-02 12:02:07.614	3	N		Patient Set for "1"	2	
16	8	4	2	2022-05-02 12:02:07.32	2022-05-02 12:02:07.623	3	N		Number of patients for "1"	2	
17	9	1	2	2022-05-02 12:02:07.857	2022-05-02 12:02:08.11	3	N		Patient Set for "0"	2	
18	9	4	2	2022-05-02 12:02:07.86	2022-05-02 12:02:08.118	3	N		Number of patients for "0"	2	
31	16	1	228	2022-05-02 12:02:11.593	2022-05-02 12:02:11.721	3	N		Patient Set for "5a2d240c-918f-45b9-8532-86e6d3211af8"	228	
19	10	1	3	2022-05-02 12:02:08.288	2022-05-02 12:02:08.619	3	N		Patient Set for "1"	3	
32	16	4	228	2022-05-02 12:02:11.595	2022-05-02 12:02:11.73	3	N		Number of patients for "5a2d240c-918f-45b9-8532-86e6d3211af8"	228	
20	10	4	3	2022-05-02 12:02:08.29	2022-05-02 12:02:08.626	3	N		Number of patients for "1"	3	
21	11	1	1	2022-05-02 12:02:08.849	2022-05-02 12:02:09.055	3	N		Patient Set for "0"	1	
22	11	4	1	2022-05-02 12:02:08.852	2022-05-02 12:02:09.061	3	N		Number of patients for "0"	1	
23	12	1	1	2022-05-02 12:02:09.206	2022-05-02 12:02:09.451	3	N		Patient Set for "1"	1	
33	17	1	228	2022-05-02 12:02:12.006	2022-05-02 12:02:12.142	3	N		Patient Set for "f0140b96-33a4-46e2-80e5-cdc721053c32"	228	
34	17	4	228	2022-05-02 12:02:12.008	2022-05-02 12:02:12.148	3	N		Number of patients for "f0140b96-33a4-46e2-80e5-cdc721053c32"	228	
37	19	1	90	2022-05-02 12:02:12.49	2022-05-02 12:02:12.733	3	N		Patient Set for "7aa4c27f-a542-41b0-9285-d698b6787e58"	90	
35	18	1	138	2022-05-02 12:02:12.487	2022-05-02 12:02:12.754	3	N		Patient Set for "b3176990-8813-481e-a04a-556eed0ae79f"	138	
\.


--
-- Data for Name: qt_query_result_type; Type: TABLE DATA; Schema: i2b2demodata; Owner: postgres
--

COPY i2b2demodata.qt_query_result_type (result_type_id, name, description, display_type_id, visual_attribute_type_id, user_role_cd, classname) FROM stdin;
1	PATIENTSET	Patient set	LIST	LA	\N	edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientSetGenerator
2	PATIENT_ENCOUNTER_SET	Encounter set	LIST	LA	\N	edu.harvard.i2b2.crc.dao.setfinder.QueryResultEncounterSetGenerator
3	XML	Generic query result	CATNUM	LH	\N	\N
4	PATIENT_COUNT_XML	Number of patients	CATNUM	LA	\N	edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientCountGenerator
5	PATIENT_GENDER_COUNT_XML	Gender patient breakdown	CATNUM	LA	\N	edu.harvard.i2b2.crc.dao.setfinder.QueryResultGenerator
6	PATIENT_VITALSTATUS_COUNT_XML	Vital Status patient breakdown	CATNUM	LA	\N	edu.harvard.i2b2.crc.dao.setfinder.QueryResultGenerator
7	PATIENT_RACE_COUNT_XML	Race patient breakdown	CATNUM	LA	\N	edu.harvard.i2b2.crc.dao.setfinder.QueryResultGenerator
8	PATIENT_AGE_COUNT_XML	Age patient breakdown	CATNUM	LA	\N	edu.harvard.i2b2.crc.dao.setfinder.QueryResultGenerator
9	PATIENTSET	Timeline	LIST	LA	\N	edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientSetGenerator
10	PATIENT_LOS_XML	Length of stay breakdown	CATNUM	LA	DATA_LDS	edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientSQLCountGenerator
11	PATIENT_TOP20MEDS_XML	Top 20 medications breakdown	CATNUM	LA	DATA_LDS	edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientSQLCountGenerator
12	PATIENT_TOP20DIAG_XML	Top 20 diagnoses breakdown	CATNUM	LA	DATA_LDS	edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientSQLCountGenerator
13	PATIENT_INOUT_XML	Inpatient and outpatient breakdown	CATNUM	LA	DATA_LDS	edu.harvard.i2b2.crc.dao.setfinder.QueryResultPatientSQLCountGenerator
\.


--
-- Data for Name: qt_query_status_type; Type: TABLE DATA; Schema: i2b2demodata; Owner: postgres
--

COPY i2b2demodata.qt_query_status_type (status_type_id, name, description) FROM stdin;
1	QUEUED	 WAITING IN QUEUE TO START PROCESS
2	PROCESSING	PROCESSING
3	FINISHED	FINISHED
4	ERROR	ERROR
5	INCOMPLETE	INCOMPLETE
6	COMPLETED	COMPLETED
7	MEDIUM_QUEUE	MEDIUM QUEUE
8	LARGE_QUEUE	LARGE QUEUE
9	CANCELLED	CANCELLED
10	TIMEDOUT	TIMEDOUT
\.


--
-- Data for Name: qt_xml_result; Type: TABLE DATA; Schema: i2b2demodata; Owner: postgres
--

COPY i2b2demodata.qt_xml_result (xml_result_id, result_instance_id, xml_value) FROM stdin;
-1	-102	xml-result
1	2	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns10:i2b2_result_envelope xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <body>\n        <ns10:result name="PATIENT_COUNT_XML">\n            <data column="patient_count" type="int">3</data>\n        </ns10:result>\n    </body>\n</ns10:i2b2_result_envelope>\n
2	4	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns10:i2b2_result_envelope xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <body>\n        <ns10:result name="PATIENT_COUNT_XML">\n            <data column="patient_count" type="int">1</data>\n        </ns10:result>\n    </body>\n</ns10:i2b2_result_envelope>\n
3	6	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns10:i2b2_result_envelope xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <body>\n        <ns10:result name="PATIENT_COUNT_XML">\n            <data column="patient_count" type="int">3</data>\n        </ns10:result>\n    </body>\n</ns10:i2b2_result_envelope>\n
4	8	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns10:i2b2_result_envelope xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <body>\n        <ns10:result name="PATIENT_COUNT_XML">\n            <data column="patient_count" type="int">4</data>\n        </ns10:result>\n    </body>\n</ns10:i2b2_result_envelope>\n
5	10	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns10:i2b2_result_envelope xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <body>\n        <ns10:result name="PATIENT_COUNT_XML">\n            <data column="patient_count" type="int">3</data>\n        </ns10:result>\n    </body>\n</ns10:i2b2_result_envelope>\n
6	12	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns10:i2b2_result_envelope xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <body>\n        <ns10:result name="PATIENT_COUNT_XML">\n            <data column="patient_count" type="int">4</data>\n        </ns10:result>\n    </body>\n</ns10:i2b2_result_envelope>\n
7	14	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns10:i2b2_result_envelope xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <body>\n        <ns10:result name="PATIENT_COUNT_XML">\n            <data column="patient_count" type="int">1</data>\n        </ns10:result>\n    </body>\n</ns10:i2b2_result_envelope>\n
8	16	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns10:i2b2_result_envelope xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <body>\n        <ns10:result name="PATIENT_COUNT_XML">\n            <data column="patient_count" type="int">2</data>\n        </ns10:result>\n    </body>\n</ns10:i2b2_result_envelope>\n
9	18	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns10:i2b2_result_envelope xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <body>\n        <ns10:result name="PATIENT_COUNT_XML">\n            <data column="patient_count" type="int">2</data>\n        </ns10:result>\n    </body>\n</ns10:i2b2_result_envelope>\n
10	20	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns10:i2b2_result_envelope xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <body>\n        <ns10:result name="PATIENT_COUNT_XML">\n            <data column="patient_count" type="int">3</data>\n        </ns10:result>\n    </body>\n</ns10:i2b2_result_envelope>\n
11	22	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns10:i2b2_result_envelope xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <body>\n        <ns10:result name="PATIENT_COUNT_XML">\n            <data column="patient_count" type="int">1</data>\n        </ns10:result>\n    </body>\n</ns10:i2b2_result_envelope>\n
12	24	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns10:i2b2_result_envelope xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <body>\n        <ns10:result name="PATIENT_COUNT_XML">\n            <data column="patient_count" type="int">1</data>\n        </ns10:result>\n    </body>\n</ns10:i2b2_result_envelope>\n
13	26	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns10:i2b2_result_envelope xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <body>\n        <ns10:result name="PATIENT_COUNT_XML">\n            <data column="patient_count" type="int">3</data>\n        </ns10:result>\n    </body>\n</ns10:i2b2_result_envelope>\n
14	28	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns10:i2b2_result_envelope xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <body>\n        <ns10:result name="PATIENT_COUNT_XML">\n            <data column="patient_count" type="int">228</data>\n        </ns10:result>\n    </body>\n</ns10:i2b2_result_envelope>\n
15	30	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns10:i2b2_result_envelope xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <body>\n        <ns10:result name="PATIENT_COUNT_XML">\n            <data column="patient_count" type="int">228</data>\n        </ns10:result>\n    </body>\n</ns10:i2b2_result_envelope>\n
16	32	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns10:i2b2_result_envelope xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <body>\n        <ns10:result name="PATIENT_COUNT_XML">\n            <data column="patient_count" type="int">228</data>\n        </ns10:result>\n    </body>\n</ns10:i2b2_result_envelope>\n
17	34	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns10:i2b2_result_envelope xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <body>\n        <ns10:result name="PATIENT_COUNT_XML">\n            <data column="patient_count" type="int">228</data>\n        </ns10:result>\n    </body>\n</ns10:i2b2_result_envelope>\n
18	38	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns10:i2b2_result_envelope xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <body>\n        <ns10:result name="PATIENT_COUNT_XML">\n            <data column="patient_count" type="int">90</data>\n        </ns10:result>\n    </body>\n</ns10:i2b2_result_envelope>\n
19	36	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns10:i2b2_result_envelope xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <body>\n        <ns10:result name="PATIENT_COUNT_XML">\n            <data column="patient_count" type="int">138</data>\n        </ns10:result>\n    </body>\n</ns10:i2b2_result_envelope>\n
\.


--
-- Data for Name: set_type; Type: TABLE DATA; Schema: i2b2demodata; Owner: postgres
--

COPY i2b2demodata.set_type (id, name, create_date) FROM stdin;
1	event_set	2022-05-02 12:01:21.357477
2	patient_set	2022-05-02 12:01:21.358416
3	concept_set	2022-05-02 12:01:21.359179
4	observer_set	2022-05-02 12:01:21.35994
5	observation_set	2022-05-02 12:01:21.360673
6	pid_set	2022-05-02 12:01:21.361398
7	eid_set	2022-05-02 12:01:21.362088
8	modifier_set	2022-05-02 12:01:21.36282
\.


--
-- Data for Name: set_upload_status; Type: TABLE DATA; Schema: i2b2demodata; Owner: postgres
--

COPY i2b2demodata.set_upload_status (upload_id, set_type_id, source_cd, no_of_record, loaded_record, deleted_record, load_date, end_date, load_status, message, input_file_name, log_file_name, transform_name) FROM stdin;
\.


--
-- Data for Name: source_master; Type: TABLE DATA; Schema: i2b2demodata; Owner: postgres
--

COPY i2b2demodata.source_master (source_cd, description, create_date) FROM stdin;
\.


--
-- Data for Name: upload_status; Type: TABLE DATA; Schema: i2b2demodata; Owner: postgres
--

COPY i2b2demodata.upload_status (upload_id, upload_label, user_id, source_cd, no_of_record, loaded_record, deleted_record, load_date, end_date, load_status, message, input_file_name, log_file_name, transform_name) FROM stdin;
\.


--
-- Data for Name: visit_dimension; Type: TABLE DATA; Schema: i2b2demodata; Owner: postgres
--

COPY i2b2demodata.visit_dimension (encounter_num, patient_num, active_status_cd, start_date, end_date, inout_cd, location_cd, location_path, length_of_stay, visit_blob, update_date, download_date, import_date, sourcesystem_cd, upload_id) FROM stdin;
1	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2022-05-02 12:01:25.169535	\N	1
2	2	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2022-05-02 12:01:25.169535	\N	1
3	3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2022-05-02 12:01:25.169535	\N	1
4	4	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2022-05-02 12:01:25.169535	\N	1
483573	1137	\N	1972-02-15 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483801	1137	\N	1971-04-15 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484029	1137	\N	1971-04-15 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483574	1138	\N	1971-06-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483802	1138	\N	1970-03-14 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484030	1138	\N	1970-03-14 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483738	1139	\N	1973-03-16 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483803	1139	\N	1970-06-10 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484031	1139	\N	1970-06-10 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483575	1140	\N	1972-05-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483804	1140	\N	1971-10-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484032	1140	\N	1971-10-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483576	1141	\N	1975-02-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483805	1141	\N	1972-09-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484033	1141	\N	1972-09-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483739	1142	\N	1974-06-02 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483806	1142	\N	1971-08-15 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484034	1142	\N	1971-08-15 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483577	1143	\N	1971-08-02 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483807	1143	\N	1970-09-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484167	1143	\N	1970-09-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483578	1144	\N	1973-04-30 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483808	1144	\N	1972-05-04 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484168	1144	\N	1972-05-04 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483579	1145	\N	1972-08-23 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483809	1145	\N	1972-01-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484035	1145	\N	1972-01-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483580	1146	\N	1972-09-10 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483810	1146	\N	1972-03-28 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484036	1146	\N	1972-03-28 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483581	1147	\N	1971-04-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483811	1147	\N	1970-11-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484037	1147	\N	1970-11-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483582	1148	\N	1973-10-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483812	1148	\N	1972-01-03 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484169	1148	\N	1972-01-03 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483583	1149	\N	1972-01-14 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483813	1149	\N	1970-01-16 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484170	1149	\N	1970-01-16 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483584	1150	\N	1972-08-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483814	1150	\N	1972-06-03 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484038	1150	\N	1972-06-03 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483585	1151	\N	1972-06-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483815	1151	\N	1970-12-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484039	1151	\N	1970-12-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483586	1152	\N	1970-12-05 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483816	1152	\N	1970-07-14 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484040	1152	\N	1970-07-14 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483587	1153	\N	1972-01-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483817	1153	\N	1970-05-24 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484041	1153	\N	1970-05-24 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483588	1154	\N	1973-10-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483818	1154	\N	1971-11-05 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484042	1154	\N	1971-11-05 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483589	1155	\N	1972-06-15 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483819	1155	\N	1972-04-15 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484171	1155	\N	1972-04-15 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483590	1156	\N	1972-12-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483820	1156	\N	1972-09-16 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484043	1156	\N	1972-09-16 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483591	1157	\N	1971-09-19 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483821	1157	\N	1970-11-22 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484044	1157	\N	1970-11-22 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483592	1158	\N	1971-11-09 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483822	1158	\N	1971-08-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484172	1158	\N	1971-08-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483593	1159	\N	1973-02-17 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483823	1159	\N	1971-06-04 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484045	1159	\N	1971-06-04 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483594	1160	\N	1972-08-29 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483824	1160	\N	1971-08-24 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484046	1160	\N	1971-08-24 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483595	1161	\N	1971-10-25 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483825	1161	\N	1970-09-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484047	1161	\N	1970-09-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483596	1162	\N	1973-05-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483826	1162	\N	1971-12-17 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484173	1162	\N	1971-12-17 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483597	1163	\N	1974-03-10 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483827	1163	\N	1972-08-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484048	1163	\N	1972-08-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483598	1164	\N	1971-02-25 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483828	1164	\N	1970-10-30 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484049	1164	\N	1970-10-30 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483599	1165	\N	1972-03-28 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483829	1165	\N	1971-03-04 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484050	1165	\N	1971-03-04 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483600	1166	\N	1971-05-09 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483830	1166	\N	1971-04-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484051	1166	\N	1971-04-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483601	1167	\N	1973-10-28 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483831	1167	\N	1972-07-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484174	1167	\N	1972-07-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483602	1168	\N	1970-02-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483832	1168	\N	1970-01-17 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484052	1168	\N	1970-01-17 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483603	1169	\N	1973-04-21 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483833	1169	\N	1971-11-05 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484053	1169	\N	1971-11-05 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483604	1170	\N	1972-09-25 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483834	1170	\N	1972-06-10 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484175	1170	\N	1972-06-10 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483605	1171	\N	1971-05-15 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483835	1171	\N	1971-03-23 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484054	1171	\N	1971-03-23 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483606	1172	\N	1971-02-04 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483836	1172	\N	1970-10-05 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484176	1172	\N	1970-10-05 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483607	1173	\N	1973-04-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483837	1173	\N	1971-01-15 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484055	1173	\N	1971-01-15 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483740	1174	\N	1974-06-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483838	1174	\N	1971-10-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484177	1174	\N	1971-10-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483608	1175	\N	1972-05-04 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483839	1175	\N	1972-02-01 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484056	1175	\N	1972-02-01 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483609	1176	\N	1974-09-04 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483840	1176	\N	1972-09-03 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484178	1176	\N	1972-09-03 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483610	1177	\N	1972-03-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483841	1177	\N	1970-12-14 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484057	1177	\N	1970-12-14 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483611	1178	\N	1973-02-14 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483842	1178	\N	1972-09-14 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484179	1178	\N	1972-09-14 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483612	1179	\N	1972-01-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483843	1179	\N	1970-11-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484180	1179	\N	1970-11-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483613	1180	\N	1972-10-24 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483844	1180	\N	1972-06-01 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484181	1180	\N	1972-06-01 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483614	1181	\N	1973-03-30 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483845	1181	\N	1971-08-25 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484058	1181	\N	1971-08-25 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483615	1182	\N	1972-02-24 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483846	1182	\N	1971-11-21 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484182	1182	\N	1971-11-21 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483616	1183	\N	1971-04-17 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483847	1183	\N	1970-06-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484059	1183	\N	1970-06-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483617	1184	\N	1973-04-05 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483848	1184	\N	1971-11-03 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484060	1184	\N	1971-11-03 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483618	1185	\N	1973-12-03 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483849	1185	\N	1972-02-29 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484061	1185	\N	1972-02-29 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483619	1186	\N	1974-10-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483850	1186	\N	1972-09-06 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484183	1186	\N	1972-09-06 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483620	1187	\N	1972-02-02 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483851	1187	\N	1970-01-28 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484184	1187	\N	1970-01-28 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483621	1188	\N	1970-09-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483852	1188	\N	1970-03-06 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484062	1188	\N	1970-03-06 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483622	1189	\N	1970-07-01 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483853	1189	\N	1970-05-09 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484063	1189	\N	1970-05-09 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483623	1190	\N	1973-01-02 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483854	1190	\N	1972-05-01 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484064	1190	\N	1972-05-01 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483624	1191	\N	1972-02-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483855	1191	\N	1970-03-21 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484065	1191	\N	1970-03-21 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483625	1192	\N	1972-04-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483856	1192	\N	1972-02-15 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484066	1192	\N	1972-02-15 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483626	1193	\N	1970-02-16 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483857	1193	\N	1970-02-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484185	1193	\N	1970-02-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483627	1194	\N	1972-11-19 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483858	1194	\N	1972-07-10 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484067	1194	\N	1972-07-10 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483628	1195	\N	1972-11-25 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483859	1195	\N	1971-01-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484186	1195	\N	1971-01-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483629	1196	\N	1971-11-06 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483860	1196	\N	1970-11-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484187	1196	\N	1970-11-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483630	1197	\N	1971-11-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483861	1197	\N	1970-08-21 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484188	1197	\N	1970-08-21 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483631	1198	\N	1971-04-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483862	1198	\N	1970-08-31 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484068	1198	\N	1970-08-31 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483632	1199	\N	1971-12-04 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483863	1199	\N	1971-06-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484069	1199	\N	1971-06-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483633	1200	\N	1970-04-23 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483864	1200	\N	1970-02-22 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484189	1200	\N	1970-02-22 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483634	1201	\N	1971-05-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483865	1201	\N	1970-12-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484070	1201	\N	1970-12-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483635	1202	\N	1972-08-10 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483866	1202	\N	1972-06-06 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484071	1202	\N	1972-06-06 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483636	1203	\N	1972-06-02 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483867	1203	\N	1971-11-07 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484190	1203	\N	1971-11-07 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483741	1204	\N	1974-11-05 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483868	1204	\N	1972-08-06 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484191	1204	\N	1972-08-06 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483637	1205	\N	1972-05-19 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483869	1205	\N	1971-03-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484072	1205	\N	1971-03-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483638	1206	\N	1972-09-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483870	1206	\N	1972-01-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484073	1206	\N	1972-01-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483742	1207	\N	1973-08-31 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483871	1207	\N	1971-05-14 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484074	1207	\N	1971-05-14 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483639	1208	\N	1973-04-07 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483872	1208	\N	1972-06-06 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484192	1208	\N	1972-06-06 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483640	1209	\N	1972-06-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483873	1209	\N	1972-05-28 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484075	1209	\N	1972-05-28 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483641	1210	\N	1970-07-23 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483874	1210	\N	1970-03-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484076	1210	\N	1970-03-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483642	1211	\N	1971-06-30 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483875	1211	\N	1970-11-16 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484193	1211	\N	1970-11-16 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483643	1212	\N	1972-05-16 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483876	1212	\N	1971-03-17 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484194	1212	\N	1971-03-17 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483644	1213	\N	1974-01-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483877	1213	\N	1972-02-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484195	1213	\N	1972-02-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483645	1214	\N	1971-02-22 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483878	1214	\N	1970-02-24 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484196	1214	\N	1970-02-24 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483646	1215	\N	1972-03-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483879	1215	\N	1972-03-02 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484077	1215	\N	1972-03-02 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483647	1216	\N	1972-01-06 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483880	1216	\N	1971-07-14 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484078	1216	\N	1971-07-14 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483648	1217	\N	1973-08-16 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483881	1217	\N	1971-06-17 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484079	1217	\N	1971-06-17 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483649	1218	\N	1970-11-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483882	1218	\N	1970-08-23 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484080	1218	\N	1970-08-23 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483743	1219	\N	1971-08-06 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483883	1219	\N	1971-01-22 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484081	1219	\N	1971-01-22 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483650	1220	\N	1970-12-31 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483884	1220	\N	1970-07-17 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484197	1220	\N	1970-07-17 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483744	1221	\N	1973-04-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483885	1221	\N	1971-02-04 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484082	1221	\N	1971-02-04 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483651	1222	\N	1973-06-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483886	1222	\N	1972-09-15 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484083	1222	\N	1972-09-15 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483652	1223	\N	1973-03-22 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483887	1223	\N	1971-06-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484198	1223	\N	1971-06-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483653	1224	\N	1972-12-15 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483888	1224	\N	1972-07-21 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484084	1224	\N	1972-07-21 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483745	1225	\N	1973-02-03 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483889	1225	\N	1971-01-25 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484199	1225	\N	1971-01-25 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483654	1226	\N	1971-03-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483890	1226	\N	1970-10-06 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484085	1226	\N	1970-10-06 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483655	1227	\N	1972-09-10 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483891	1227	\N	1970-11-25 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484086	1227	\N	1970-11-25 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483656	1228	\N	1972-06-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483892	1228	\N	1971-10-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484087	1228	\N	1971-10-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483657	1229	\N	1971-09-21 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483893	1229	\N	1971-06-25 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484088	1229	\N	1971-06-25 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483658	1230	\N	1972-09-02 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483894	1230	\N	1972-01-01 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484200	1230	\N	1972-01-01 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483746	1231	\N	1972-04-28 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483895	1231	\N	1970-09-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484201	1231	\N	1970-09-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483659	1232	\N	1971-09-28 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483896	1232	\N	1971-08-29 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484089	1232	\N	1971-08-29 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483660	1233	\N	1971-07-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483897	1233	\N	1971-01-29 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484090	1233	\N	1971-01-29 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483661	1234	\N	1973-06-21 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483898	1234	\N	1972-08-15 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484091	1234	\N	1972-08-15 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483662	1235	\N	1973-07-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483899	1235	\N	1972-03-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484092	1235	\N	1972-03-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483663	1236	\N	1970-11-17 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483900	1236	\N	1970-06-04 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484202	1236	\N	1970-06-04 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483747	1237	\N	1972-08-05 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483901	1237	\N	1971-01-24 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484203	1237	\N	1971-01-24 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483664	1238	\N	1973-03-03 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483902	1238	\N	1971-12-09 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484204	1238	\N	1971-12-09 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483665	1239	\N	1971-03-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483903	1239	\N	1970-03-21 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484093	1239	\N	1970-03-21 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483666	1240	\N	1971-08-25 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483904	1240	\N	1971-05-10 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484094	1240	\N	1971-05-10 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483667	1241	\N	1971-02-28 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483905	1241	\N	1970-09-04 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484095	1241	\N	1970-09-04 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483668	1242	\N	1970-12-23 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483906	1242	\N	1970-07-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484096	1242	\N	1970-07-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483748	1243	\N	1973-01-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483907	1243	\N	1971-07-29 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484205	1243	\N	1971-07-29 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483669	1244	\N	1971-03-23 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483908	1244	\N	1971-03-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484097	1244	\N	1971-03-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483670	1245	\N	1971-09-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483909	1245	\N	1970-07-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484098	1245	\N	1970-07-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483671	1246	\N	1972-08-02 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483910	1246	\N	1971-08-17 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484206	1246	\N	1971-08-17 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483672	1247	\N	1972-04-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483911	1247	\N	1972-03-29 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484099	1247	\N	1972-03-29 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483673	1248	\N	1971-02-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483912	1248	\N	1970-08-15 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484100	1248	\N	1970-08-15 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483674	1249	\N	1972-12-06 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483913	1249	\N	1972-02-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484101	1249	\N	1972-02-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483675	1250	\N	1970-11-09 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483914	1250	\N	1970-04-22 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484207	1250	\N	1970-04-22 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483676	1251	\N	1971-07-02 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483915	1251	\N	1970-01-24 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484208	1251	\N	1970-01-24 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483677	1252	\N	1972-05-17 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483916	1252	\N	1972-05-04 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484102	1252	\N	1972-05-04 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483678	1253	\N	1971-04-25 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483917	1253	\N	1970-09-25 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484103	1253	\N	1970-09-25 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483679	1254	\N	1971-07-22 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483918	1254	\N	1970-02-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484104	1254	\N	1970-02-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483680	1255	\N	1972-02-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483919	1255	\N	1971-05-14 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484105	1255	\N	1971-05-14 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483681	1256	\N	1972-02-03 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483920	1256	\N	1971-02-05 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484106	1256	\N	1971-02-05 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483682	1257	\N	1973-08-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483921	1257	\N	1972-06-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484107	1257	\N	1972-06-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483683	1258	\N	1972-04-16 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483922	1258	\N	1971-09-30 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484209	1258	\N	1971-09-30 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483684	1259	\N	1972-04-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483923	1259	\N	1970-10-06 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484210	1259	\N	1970-10-06 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483685	1260	\N	1971-11-23 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483924	1260	\N	1971-09-30 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484108	1260	\N	1971-09-30 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483686	1261	\N	1971-11-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483925	1261	\N	1970-05-09 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484109	1261	\N	1970-05-09 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483687	1262	\N	1971-07-25 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483926	1262	\N	1970-12-30 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484110	1262	\N	1970-12-30 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483688	1263	\N	1970-12-03 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483927	1263	\N	1970-09-02 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484111	1263	\N	1970-09-02 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483689	1264	\N	1972-06-29 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483928	1264	\N	1972-04-30 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484112	1264	\N	1972-04-30 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483749	1265	\N	1973-04-30 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483929	1265	\N	1971-10-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484211	1265	\N	1971-10-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483750	1266	\N	1974-02-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483930	1266	\N	1972-08-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484212	1266	\N	1972-08-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483690	1267	\N	1973-06-01 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483931	1267	\N	1972-08-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484213	1267	\N	1972-08-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483691	1268	\N	1971-04-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483932	1268	\N	1970-10-06 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484113	1268	\N	1970-10-06 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483692	1269	\N	1971-11-15 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483933	1269	\N	1970-11-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484114	1269	\N	1970-11-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483751	1270	\N	1971-12-29 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483934	1270	\N	1970-08-05 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484214	1270	\N	1970-08-05 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483693	1271	\N	1972-09-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483935	1271	\N	1971-12-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484115	1271	\N	1971-12-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483752	1272	\N	1972-05-09 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483936	1272	\N	1970-12-15 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484215	1272	\N	1970-12-15 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483694	1273	\N	1973-05-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483937	1273	\N	1972-05-21 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484216	1273	\N	1972-05-21 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483695	1274	\N	1971-12-01 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483938	1274	\N	1970-11-09 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484116	1274	\N	1970-11-09 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483696	1275	\N	1973-01-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483939	1275	\N	1971-10-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484117	1275	\N	1971-10-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483697	1276	\N	1971-02-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483940	1276	\N	1970-03-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484118	1276	\N	1970-03-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483698	1277	\N	1973-01-05 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483941	1277	\N	1972-06-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484217	1277	\N	1972-06-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483753	1278	\N	1971-04-06 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483942	1278	\N	1970-02-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484119	1278	\N	1970-02-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483699	1279	\N	1970-12-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483943	1279	\N	1970-05-10 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484120	1279	\N	1970-05-10 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483700	1280	\N	1971-11-24 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483944	1280	\N	1971-09-23 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484218	1280	\N	1971-09-23 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483754	1281	\N	1973-12-09 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483945	1281	\N	1972-09-07 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484121	1281	\N	1972-09-07 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483755	1282	\N	1973-08-29 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483946	1282	\N	1972-09-07 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484219	1282	\N	1972-09-07 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483701	1283	\N	1972-02-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483947	1283	\N	1971-02-24 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484122	1283	\N	1971-02-24 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483702	1284	\N	1971-12-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483948	1284	\N	1971-07-17 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484123	1284	\N	1971-07-17 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483703	1285	\N	1970-04-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483949	1285	\N	1970-03-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484124	1285	\N	1970-03-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483704	1286	\N	1972-09-05 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483950	1286	\N	1971-10-01 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484220	1286	\N	1971-10-01 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483705	1287	\N	1973-04-17 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483951	1287	\N	1972-08-31 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484125	1287	\N	1972-08-31 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483756	1288	\N	1972-07-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483952	1288	\N	1971-04-21 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484126	1288	\N	1971-04-21 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483757	1289	\N	1972-10-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483953	1289	\N	1971-12-01 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484221	1289	\N	1971-12-01 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483706	1290	\N	1971-03-09 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483954	1290	\N	1970-09-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484222	1290	\N	1970-09-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483707	1291	\N	1972-01-06 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483955	1291	\N	1971-08-03 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484127	1291	\N	1971-08-03 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483708	1292	\N	1972-09-19 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483956	1292	\N	1971-10-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484128	1292	\N	1971-10-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483758	1293	\N	1971-12-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483957	1293	\N	1970-12-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484223	1293	\N	1970-12-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483709	1294	\N	1971-09-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483958	1294	\N	1970-11-21 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484129	1294	\N	1970-11-21 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483710	1295	\N	1970-08-19 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483959	1295	\N	1970-02-21 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484130	1295	\N	1970-02-21 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483759	1296	\N	1972-02-24 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483960	1296	\N	1971-02-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484224	1296	\N	1971-02-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483760	1297	\N	1972-12-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483961	1297	\N	1971-11-23 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484225	1297	\N	1971-11-23 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483711	1298	\N	1973-04-16 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483962	1298	\N	1972-07-22 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484226	1298	\N	1972-07-22 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483761	1299	\N	1972-04-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483963	1299	\N	1971-07-03 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484131	1299	\N	1971-07-03 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483712	1300	\N	1971-02-09 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483964	1300	\N	1970-09-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484132	1300	\N	1970-09-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483762	1301	\N	1972-05-03 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483965	1301	\N	1971-03-17 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484133	1301	\N	1971-03-17 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483763	1302	\N	1972-12-01 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483966	1302	\N	1972-03-10 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484227	1302	\N	1972-03-10 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483713	1303	\N	1972-02-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483967	1303	\N	1971-08-10 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484228	1303	\N	1971-08-10 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483714	1304	\N	1973-01-23 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483968	1304	\N	1972-03-09 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484134	1304	\N	1972-03-09 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483715	1305	\N	1972-04-10 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483969	1305	\N	1971-10-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484135	1305	\N	1971-10-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483716	1306	\N	1971-01-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483970	1306	\N	1970-04-03 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484136	1306	\N	1970-04-03 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483764	1307	\N	1971-10-15 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483971	1307	\N	1970-12-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484137	1307	\N	1970-12-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483717	1308	\N	1971-09-28 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483972	1308	\N	1970-10-15 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484229	1308	\N	1970-10-15 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483718	1309	\N	1972-07-22 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483973	1309	\N	1972-01-07 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484138	1309	\N	1972-01-07 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483765	1310	\N	1971-04-17 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483974	1310	\N	1970-03-31 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484230	1310	\N	1970-03-31 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483766	1311	\N	1972-06-07 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483975	1311	\N	1971-08-09 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484139	1311	\N	1971-08-09 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483767	1312	\N	1973-02-19 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483976	1312	\N	1972-04-29 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484231	1312	\N	1972-04-29 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483719	1313	\N	1972-01-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483977	1313	\N	1971-07-15 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484140	1313	\N	1971-07-15 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483720	1314	\N	1971-08-19 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483978	1314	\N	1971-02-14 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484232	1314	\N	1971-02-14 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483721	1315	\N	1971-08-25 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483979	1315	\N	1971-04-02 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484233	1315	\N	1971-04-02 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483768	1316	\N	1972-07-04 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483980	1316	\N	1971-10-09 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484234	1316	\N	1971-10-09 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483769	1317	\N	1971-01-07 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483981	1317	\N	1970-03-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484141	1317	\N	1970-03-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483770	1318	\N	1972-10-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483982	1318	\N	1972-01-16 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484142	1318	\N	1972-01-16 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483722	1319	\N	1973-01-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483983	1319	\N	1972-01-28 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484235	1319	\N	1972-01-28 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483771	1320	\N	1971-11-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483984	1320	\N	1971-02-21 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484236	1320	\N	1971-02-21 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483772	1321	\N	1972-10-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483985	1321	\N	1971-12-24 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484237	1321	\N	1971-12-24 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483773	1322	\N	1972-08-23 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483986	1322	\N	1971-09-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484238	1322	\N	1971-09-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483723	1323	\N	1972-09-03 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483987	1323	\N	1971-11-23 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484239	1323	\N	1971-11-23 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483774	1324	\N	1972-06-16 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483988	1324	\N	1971-10-01 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484143	1324	\N	1971-10-01 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483724	1325	\N	1970-06-16 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483989	1325	\N	1970-02-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484144	1325	\N	1970-02-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483725	1326	\N	1972-02-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483990	1326	\N	1971-05-10 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484145	1326	\N	1971-05-10 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483726	1327	\N	1970-11-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483991	1327	\N	1970-03-01 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484146	1327	\N	1970-03-01 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483727	1328	\N	1972-10-10 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483992	1328	\N	1972-07-21 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484147	1328	\N	1972-07-21 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483728	1329	\N	1971-02-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483993	1329	\N	1970-10-19 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484148	1329	\N	1970-10-19 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483775	1330	\N	1972-03-02 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483994	1330	\N	1971-07-21 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484149	1330	\N	1971-07-21 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483729	1331	\N	1972-04-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483995	1331	\N	1971-08-02 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484150	1331	\N	1971-08-02 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483776	1332	\N	1972-12-07 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483996	1332	\N	1972-04-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484151	1332	\N	1972-04-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483777	1333	\N	1970-11-08 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483997	1333	\N	1970-03-10 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484240	1333	\N	1970-03-10 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483778	1334	\N	1970-11-23 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483998	1334	\N	1970-02-17 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484152	1334	\N	1970-02-17 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483779	1335	\N	1971-02-21 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483999	1335	\N	1970-05-21 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484241	1335	\N	1970-05-21 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483730	1336	\N	1972-09-07 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484000	1336	\N	1972-04-25 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484153	1336	\N	1972-04-25 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483731	1337	\N	1972-11-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484001	1337	\N	1972-08-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484242	1337	\N	1972-08-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483732	1338	\N	1972-03-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484002	1338	\N	1972-01-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484154	1338	\N	1972-01-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483780	1339	\N	1970-12-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484003	1339	\N	1970-04-16 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484243	1339	\N	1970-04-16 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483781	1340	\N	1971-09-13 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484004	1340	\N	1971-02-23 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484244	1340	\N	1971-02-23 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483782	1341	\N	1972-06-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484005	1341	\N	1971-11-04 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484245	1341	\N	1971-11-04 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483733	1342	\N	1970-04-26 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484006	1342	\N	1970-01-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484155	1342	\N	1970-01-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483783	1343	\N	1971-12-17 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484007	1343	\N	1971-05-07 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484246	1343	\N	1971-05-07 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483734	1344	\N	1972-03-09 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484008	1344	\N	1971-07-14 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484247	1344	\N	1971-07-14 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483784	1345	\N	1972-09-30 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484009	1345	\N	1972-02-06 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484156	1345	\N	1972-02-06 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483785	1346	\N	1971-11-07 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484010	1346	\N	1971-05-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484248	1346	\N	1971-05-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483786	1347	\N	1971-05-22 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484011	1347	\N	1970-09-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484249	1347	\N	1970-09-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483787	1348	\N	1970-12-21 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484012	1348	\N	1970-05-14 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484157	1348	\N	1970-05-14 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483788	1349	\N	1971-06-07 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484013	1349	\N	1970-12-04 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484158	1349	\N	1970-12-04 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483789	1350	\N	1972-06-07 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484014	1350	\N	1972-03-07 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484250	1350	\N	1972-03-07 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483735	1351	\N	1972-04-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484015	1351	\N	1972-04-14 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484159	1351	\N	1972-04-14 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483790	1352	\N	1973-04-28 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484016	1352	\N	1972-09-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484160	1352	\N	1972-09-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483791	1353	\N	1971-09-22 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484017	1353	\N	1971-03-14 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484251	1353	\N	1971-03-14 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483736	1354	\N	1971-05-01 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484018	1354	\N	1970-10-30 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484161	1354	\N	1970-10-30 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483792	1355	\N	1972-08-09 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484019	1355	\N	1972-01-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484252	1355	\N	1972-01-11 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483793	1356	\N	1971-04-28 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484020	1356	\N	1970-11-04 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484253	1356	\N	1970-11-04 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483794	1357	\N	1971-12-03 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484021	1357	\N	1971-05-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484162	1357	\N	1971-05-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483795	1358	\N	1971-01-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484022	1358	\N	1970-06-29 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484254	1358	\N	1970-06-29 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483737	1359	\N	1972-02-28 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484023	1359	\N	1971-11-04 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484163	1359	\N	1971-11-04 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483796	1360	\N	1972-03-18 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484024	1360	\N	1971-09-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484164	1360	\N	1971-09-12 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483797	1361	\N	1972-10-10 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484025	1361	\N	1972-04-02 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484165	1361	\N	1972-04-02 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483798	1362	\N	1971-09-02 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484026	1362	\N	1971-05-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484255	1362	\N	1971-05-20 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483799	1363	\N	1971-08-27 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484027	1363	\N	1971-03-06 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484166	1363	\N	1971-03-06 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
483800	1364	\N	1971-04-25 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484028	1364	\N	1970-10-30 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
484256	1364	\N	1970-10-30 01:00:00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
\.


--
-- Data for Name: crc_analysis_job; Type: TABLE DATA; Schema: i2b2hive; Owner: postgres
--

COPY i2b2hive.crc_analysis_job (job_id, queue_name, status_type_id, domain_id, project_id, user_id, request_xml, create_date, update_date) FROM stdin;
\.


--
-- Data for Name: crc_db_lookup; Type: TABLE DATA; Schema: i2b2hive; Owner: postgres
--

COPY i2b2hive.crc_db_lookup (c_domain_id, c_project_path, c_owner_id, c_db_fullschema, c_db_datasource, c_db_servertype, c_db_nicename, c_db_tooltip, c_comment, c_entry_date, c_change_date, c_status_cd) FROM stdin;
i2b2demo	/ACT/	@	i2b2demodata	java:/QueryToolDemoDS	POSTGRESQL	Demo	\N	\N	\N	\N	\N
i2b2demo	/Demo/	@	i2b2demodata	java:/QueryToolDemoDS	POSTGRESQL	Demo	\N	\N	\N	\N	\N
\.


--
-- Data for Name: hive_cell_params; Type: TABLE DATA; Schema: i2b2hive; Owner: postgres
--

COPY i2b2hive.hive_cell_params (id, datatype_cd, cell_id, param_name_cd, value, change_date, entry_date, changeby_char, status_cd) FROM stdin;
33	T	CRC	queryprocessor.jndi.queryinfolocal	ejb.querytool.QueryInfoLocal	\N	\N	\N	A
31	T	CRC	queryprocessor.jndi.querymanagerlocal	ejb.querytool.QueryManagerLocal	\N	\N	\N	A
37	T	CRC	queryprocessor.jndi.querymanagerremote	ejb.querytool.QueryManager	\N	\N	\N	A
61	T	ONT	applicationName	Ontology Cell	\N	\N	\N	A
63	T	CRC	applicationName	CRC Cell	\N	\N	\N	A
62	T	ONT	applicationVersion	1.7	\N	\N	\N	A
64	T	CRC	applicationVersion	1.7	\N	\N	\N	A
16	T	CRC	edu.harvard.i2b2.crc.analysis.queue.large.jobcheck.timemills	60000	\N	\N	\N	A
14	T	CRC	edu.harvard.i2b2.crc.analysis.queue.large.maxjobcount	1	\N	\N	\N	A
13	T	CRC	edu.harvard.i2b2.crc.analysis.queue.large.timeoutmills	43200000	\N	\N	\N	A
15	T	CRC	edu.harvard.i2b2.crc.analysis.queue.medium.jobcheck.timemills	60000	\N	\N	\N	A
12	T	CRC	edu.harvard.i2b2.crc.analysis.queue.medium.maxjobcount	4	\N	\N	\N	A
11	T	CRC	edu.harvard.i2b2.crc.analysis.queue.medium.timeoutmills	3000	\N	\N	\N	A
2	T	CRC	edu.harvard.i2b2.crc.delegate.ontology.operation.getchildren	/getChildren	\N	\N	\N	A
3	T	CRC	edu.harvard.i2b2.crc.delegate.ontology.operation.getmodifierinfo	/getModifierInfo	\N	\N	\N	A
1	T	CRC	edu.harvard.i2b2.crc.delegate.ontology.operation.getterminfo	/getTermInfo	\N	\N	\N	A
67	U	CRC	edu.harvard.i2b2.crc.delegate.ontology.url	/services/OntologyService	\N	\N	\N	A
28	T	CRC	edu.harvard.i2b2.crc.i2b2SocketServer	7070	\N	\N	\N	A
19	T	CRC	edu.harvard.i2b2.crc.jms.large.timeoutsec	43200	\N	\N	\N	A
18	T	CRC	edu.harvard.i2b2.crc.jms.medium.timeoutsec	14400	\N	\N	\N	A
17	T	CRC	edu.harvard.i2b2.crc.jms.small.timeoutsec	180	\N	\N	\N	A
23	T	CRC	edu.harvard.i2b2.crc.lockout.setfinderquery.day	30	\N	\N	\N	A
24	T	CRC	edu.harvard.i2b2.crc.lockout.setfinderquery.zero.count	-1	\N	\N	\N	A
7	T	CRC	edu.harvard.i2b2.crc.pdo.paging.inputlist.minpercent	20	\N	\N	\N	A
8	T	CRC	edu.harvard.i2b2.crc.pdo.paging.inputlist.minsize	1	\N	\N	\N	A
6	T	CRC	edu.harvard.i2b2.crc.pdo.paging.iteration	100	\N	\N	\N	A
9	T	CRC	edu.harvard.i2b2.crc.pdo.paging.method	SUBDIVIDE_INPUT_METHOD 	\N	\N	\N	A
5	T	CRC	edu.harvard.i2b2.crc.pdo.paging.observation.size	7500	\N	\N	\N	A
10	T	CRC	edu.harvard.i2b2.crc.pdo.request.timeoutmills	600000	\N	\N	\N	A
20	T	CRC	edu.harvard.i2b2.crc.pm.serviceaccount.user	AGG_SERVICE_ACCOUNT	\N	\N	\N	A
66	T	CRC	edu.harvard.i2b2.crc.setfinder.querygenerator.version	1.7	\N	\N	\N	A
26	T	CRC	edu.harvard.i2b2.crc.setfinderquery.obfuscation.breakdowncount.sigma	1.6	\N	\N	\N	A
25	T	CRC	edu.harvard.i2b2.crc.setfinderquery.obfuscation.count.sigma	1.323	\N	\N	\N	A
27	T	CRC	edu.harvard.i2b2.crc.setfinderquery.obfuscation.minimum.value	3	\N	\N	\N	A
29	T	CRC	edu.harvard.i2b2.crc.setfinderquery.skiptemptable.maxconcept	40	\N	\N	\N	A
54	U	ONT	edu.harvard.i2b2.ontology.ws.crc.url	/services/QueryToolService	\N	\N	\N	A
59	T	ONT	edu.harvard.i2b2.ontology.ws.fr.attachmentname	cid	\N	\N	\N	A
58	T	ONT	edu.harvard.i2b2.ontology.ws.fr.filethreshold	4000	\N	\N	\N	A
60	T	ONT	edu.harvard.i2b2.ontology.ws.fr.operation	urn:recvfileRequest	\N	\N	\N	A
56	T	ONT	edu.harvard.i2b2.ontology.ws.fr.tempspace	/tmp	\N	\N	\N	A
57	T	ONT	edu.harvard.i2b2.ontology.ws.fr.timeout	10000	\N	\N	\N	A
55	U	ONT	edu.harvard.i2b2.ontology.ws.fr.url	/services/FRService/	\N	\N	\N	A
42	T	CRC	I2B2_MESSAGE_ERROR_AUTHENTICATION_FAILURE	Authentication failure.	\N	\N	\N	A
43	T	CRC	I2B2_MESSAGE_ERROR_INVALID_MESSAGE	Invalid message body	\N	\N	\N	A
48	T	CRC	I2B2_MESSAGE_STATUS_COMPLETED	COMPLETED	\N	\N	\N	A
46	T	CRC	I2B2_MESSAGE_STATUS_ERROR	ERROR	\N	\N	\N	A
47	T	CRC	I2B2_MESSAGE_STATUS_FINISHED	FINISHED	\N	\N	\N	A
49	T	CRC	I2B2_MESSAGE_STATUS_INCOMPLE	INCOMPLETE	\N	\N	\N	A
45	T	CRC	I2B2_MESSAGE_STATUS_PROCESSING	PROCESSING	\N	\N	\N	A
44	T	CRC	I2B2_MESSAGE_STATUS_QUEUED	QUEUED	\N	\N	\N	A
65	T	ONT	ontology.terminal.delimiter	true	\N	\N	\N	A
53	U	ONT	ontology.ws.pm.url	/services/PMService/getServices	\N	\N	\N	A
36	T	CRC	queryprocessor.jndi.pdoquerylocal	ejb.querytool.PdoQueryLocal	\N	\N	\N	A
30	T	CRC	queryprocessor.jndi.queryexecutormdblocal	ejb.querytool.QueryExecutorMDBLocal	\N	\N	\N	A
38	T	CRC	queryprocessor.jndi.queryexecutormdbremote	ejb.querytool.QueryExecutorMDB	\N	\N	\N	A
32	T	CRC	queryprocessor.jndi.querymasterlocal	ejb.querytool.QueryMasterLocal	\N	\N	\N	A
35	T	CRC	queryprocessor.jndi.queryresultlocal	ejb.querytool.QueryResultLocal	\N	\N	\N	A
34	T	CRC	queryprocessor.jndi.queryrunlocal	ejb.querytool.QueryRunLocal	\N	\N	\N	A
39	T	CRC	queryprocessor.jndi.queue.connectionfactory	ConnectionFactory	\N	\N	\N	A
41	T	CRC	queryprocessor.jndi.queue.executor_queue	queue/jms.querytool.QueryExecutor	\N	\N	\N	A
40	T	CRC	queryprocessor.jndi.queue.response_queue	queue/jms.querytool.QueryResponse	\N	\N	\N	A
4	T	CRC	queryprocessor.multifacttable	false	\N	\N	\N	A
50	U	CRC	queryprocessor.ws.ontology.url	/services/OntologyService/getTermInfo	\N	\N	\N	A
51	U	CRC	queryprocessor.ws.pm.url	/services/PMService/getServices	\N	\N	\N	A
52	U	WORK	workplace.ws.pm.url	/services/PMService/getServices	\N	\N	\N	A
68	U	IM	im.ws.pm.url	/services/PMService/getServices	\N	\N	\N	A
69	T	IM	im.checkPatientInProject	true	\N	\N	\N	A
70	T	IM	im.empi.service	none	\N	\N	\N	A
22	T	CRC	edu.harvard.i2b2.crc.lockout.setfinderquery.count	-1	\N	\N	\N	A
21	T	CRC	edu.harvard.i2b2.crc.pm.serviceaccount.password	changeme	\N	\N	\N	A
\.


--
-- Data for Name: im_db_lookup; Type: TABLE DATA; Schema: i2b2hive; Owner: postgres
--

COPY i2b2hive.im_db_lookup (c_domain_id, c_project_path, c_owner_id, c_db_fullschema, c_db_datasource, c_db_servertype, c_db_nicename, c_db_tooltip, c_comment, c_entry_date, c_change_date, c_status_cd) FROM stdin;
i2b2demo	Demo/	@	i2b2imdata	java:/IMDemoDS	POSTGRESQL	IM	\N	\N	\N	\N	\N
\.


--
-- Data for Name: ont_db_lookup; Type: TABLE DATA; Schema: i2b2hive; Owner: postgres
--

COPY i2b2hive.ont_db_lookup (c_domain_id, c_project_path, c_owner_id, c_db_fullschema, c_db_datasource, c_db_servertype, c_db_nicename, c_db_tooltip, c_comment, c_entry_date, c_change_date, c_status_cd) FROM stdin;
i2b2demo	ACT/	@	i2b2metadata	java:/OntologyDemoDS	POSTGRESQL	Metadata	\N	\N	\N	\N	\N
i2b2demo	Demo/	@	i2b2metadata	java:/OntologyDemoDS	POSTGRESQL	Metadata	\N	\N	\N	\N	\N
\.


--
-- Data for Name: work_db_lookup; Type: TABLE DATA; Schema: i2b2hive; Owner: postgres
--

COPY i2b2hive.work_db_lookup (c_domain_id, c_project_path, c_owner_id, c_db_fullschema, c_db_datasource, c_db_servertype, c_db_nicename, c_db_tooltip, c_comment, c_entry_date, c_change_date, c_status_cd) FROM stdin;
i2b2demo	ACT/	@	i2b2workdata	java:/WorkplaceDemoDS	POSTGRESQL	Workplace	\N	\N	\N	\N	\N
i2b2demo	Demo/	@	i2b2workdata	java:/WorkplaceDemoDS	POSTGRESQL	Workplace	\N	\N	\N	\N	\N
\.


--
-- Data for Name: im_audit; Type: TABLE DATA; Schema: i2b2imdata; Owner: postgres
--

COPY i2b2imdata.im_audit (query_date, lcl_site, lcl_id, user_id, project_id, comments) FROM stdin;
\.


--
-- Data for Name: im_mpi_demographics; Type: TABLE DATA; Schema: i2b2imdata; Owner: postgres
--

COPY i2b2imdata.im_mpi_demographics (global_id, global_status, demographics, update_date, download_date, import_date, sourcesystem_cd, upload_id) FROM stdin;
\.


--
-- Data for Name: im_mpi_mapping; Type: TABLE DATA; Schema: i2b2imdata; Owner: postgres
--

COPY i2b2imdata.im_mpi_mapping (global_id, lcl_site, lcl_id, lcl_status, update_date, download_date, import_date, sourcesystem_cd, upload_id) FROM stdin;
\.


--
-- Data for Name: im_project_patients; Type: TABLE DATA; Schema: i2b2imdata; Owner: postgres
--

COPY i2b2imdata.im_project_patients (project_id, global_id, patient_project_status, update_date, download_date, import_date, sourcesystem_cd, upload_id) FROM stdin;
\.


--
-- Data for Name: im_project_sites; Type: TABLE DATA; Schema: i2b2imdata; Owner: postgres
--

COPY i2b2imdata.im_project_sites (project_id, lcl_site, project_status, update_date, download_date, import_date, sourcesystem_cd, upload_id) FROM stdin;
\.


--
-- Data for Name: birn; Type: TABLE DATA; Schema: i2b2metadata; Owner: postgres
--

COPY i2b2metadata.birn (c_hlevel, c_fullname, c_name, c_synonym_cd, c_visualattributes, c_totalnum, c_basecode, c_metadataxml, c_facttablecolumn, c_tablename, c_columnname, c_columndatatype, c_operator, c_dimcode, c_comment, c_tooltip, m_applied_path, update_date, download_date, import_date, sourcesystem_cd, valuetype_cd, m_exclusion_cd, c_path, c_symbol) FROM stdin;
\.


--
-- Data for Name: custom_meta; Type: TABLE DATA; Schema: i2b2metadata; Owner: postgres
--

COPY i2b2metadata.custom_meta (c_hlevel, c_fullname, c_name, c_synonym_cd, c_visualattributes, c_totalnum, c_basecode, c_metadataxml, c_facttablecolumn, c_tablename, c_columnname, c_columndatatype, c_operator, c_dimcode, c_comment, c_tooltip, m_applied_path, update_date, download_date, import_date, sourcesystem_cd, valuetype_cd, m_exclusion_cd, c_path, c_symbol) FROM stdin;
\.


--
-- Data for Name: i2b2; Type: TABLE DATA; Schema: i2b2metadata; Owner: postgres
--

COPY i2b2metadata.i2b2 (c_hlevel, c_fullname, c_name, c_synonym_cd, c_visualattributes, c_totalnum, c_basecode, c_metadataxml, c_facttablecolumn, c_tablename, c_columnname, c_columndatatype, c_operator, c_dimcode, c_comment, c_tooltip, m_applied_path, update_date, download_date, import_date, sourcesystem_cd, valuetype_cd, m_exclusion_cd, c_path, c_symbol) FROM stdin;
\.


--
-- Data for Name: icd10_icd9; Type: TABLE DATA; Schema: i2b2metadata; Owner: postgres
--

COPY i2b2metadata.icd10_icd9 (c_hlevel, c_fullname, c_name, c_synonym_cd, c_visualattributes, c_totalnum, c_basecode, c_metadataxml, c_facttablecolumn, c_tablename, c_columnname, c_columndatatype, c_operator, c_dimcode, c_comment, c_tooltip, m_applied_path, update_date, download_date, import_date, sourcesystem_cd, valuetype_cd, m_exclusion_cd, c_path, c_symbol, plain_code) FROM stdin;
\.


--
-- Data for Name: ont_process_status; Type: TABLE DATA; Schema: i2b2metadata; Owner: postgres
--

COPY i2b2metadata.ont_process_status (process_id, process_type_cd, start_date, end_date, process_step_cd, process_status_cd, crc_upload_id, status_cd, message, entry_date, change_date, changedby_char) FROM stdin;
\.


--
-- Data for Name: schemes; Type: TABLE DATA; Schema: i2b2metadata; Owner: postgres
--

COPY i2b2metadata.schemes (c_key, c_name, c_description) FROM stdin;
TEST:	Test	Test scheme.
\.


--
-- Data for Name: table_access; Type: TABLE DATA; Schema: i2b2metadata; Owner: postgres
--

COPY i2b2metadata.table_access (c_table_cd, c_table_name, c_protected_access, c_ontology_protection, c_hlevel, c_fullname, c_name, c_synonym_cd, c_visualattributes, c_totalnum, c_basecode, c_metadataxml, c_facttablecolumn, c_dimtablename, c_columnname, c_columndatatype, c_operator, c_dimcode, c_comment, c_tooltip, c_entry_date, c_change_date, c_status_cd, valuetype_cd) FROM stdin;
TEST	TEST	N	\N	0	\\test\\	Test Ontology	N	CA 	\N	\N	\N	concept_cd	concept_dimension	concept_path	T	LIKE	\\test\\	\N	Test	\N	\N	\N	\N
SPHN	TEST	N	\N	0	\\SPHNv2020.1\\	SPHN Ontology version 2020.1	N	CA 	\N	\N	\N	concept_cd	concept_dimension	concept_path	T	LIKE	\\test\\	\N	SPHN Ontology version 2020.1	\N	\N	\N	\N
I2B2	TEST	N	\N	0	\\I2B2\\	I2B2 ontology	N	CA 	\N	\N	\N	concept_cd	concept_dimension	concept_path	T	LIKE	\\test\\	\N	I2B2 Ontology	\N	\N	\N	\N
\.


--
-- Data for Name: test; Type: TABLE DATA; Schema: i2b2metadata; Owner: postgres
--

COPY i2b2metadata.test (c_hlevel, c_fullname, c_name, c_synonym_cd, c_visualattributes, c_totalnum, c_basecode, c_metadataxml, c_facttablecolumn, c_tablename, c_columnname, c_columndatatype, c_operator, c_dimcode, c_comment, c_tooltip, update_date, download_date, import_date, sourcesystem_cd, valuetype_cd, m_applied_path, m_exclusion_cd, c_path, c_symbol, pcori_basecode) FROM stdin;
0	\\test\\	Test	N	CA 	0		\N	concept_cd	concept_dimension	concept_path	T	LIKE	\\test\\	Test	\\test\\	2022-05-02	2022-05-02	2022-05-02	\N	TEST	@	\N	\N	\N	\N
1	\\test\\1\\	Concept 1	N	LA 	0	TEST:1	<?xml version="1.0"?><ValueMetadata></ValueMetadata>	concept_cd	concept_dimension	concept_path	T	LIKE	\\test\\1\\	Concept 1	\\test\\1\\	2022-05-02	2022-05-02	2022-05-02	\N	TEST	@	\N	\N	\N	\N
1	\\test\\2\\	Concept 2	N	LA 	0	TEST:2	\N	concept_cd	concept_dimension	concept_path	T	LIKE	\\test\\2\\	Concept 2	\\test\\2\\	2022-05-02	2022-05-02	2022-05-02	\N	TEST	@	\N	\N	\N	\N
1	\\test\\3\\	Concept 3	N	LA 	0	TEST:3	\N	concept_cd	concept_dimension	concept_path	T	LIKE	\\test\\3\\	Concept 3	\\test\\3\\	2022-05-02	2022-05-02	2022-05-02	\N	TEST	@	\N	\N	\N	\N
0	\\modifiers1\\	Modifiers 1 test	N	DA 	0	TEST:4-1	\N	modifier_cd	modifier_dimension	modifier_path	T	LIKE	\\modifiers1\\	Modifiers 1 Test	\\modifiers1\\	2022-05-02	2022-05-02	2022-05-02	\N	TEST	\\test\\1\\	\N	\N	\N	\N
0	\\modifiers2\\	Modifiers 2 test	N	DA 	0	TEST:4-2	\N	modifier_cd	modifier_dimension	modifier_path	T	LIKE	\\modifiers2\\	Modifiers 2 Test	\\modifiers2\\	2022-05-02	2022-05-02	2022-05-02	\N	TEST	\\test\\2\\	\N	\N	\N	\N
0	\\modifiers3\\	Modifiers 3 test	N	DA 	0	TEST:4-3	\N	modifier_cd	modifier_dimension	modifier_path	T	LIKE	\\modifiers1\\	Modifiers 3 Test	\\modifiers3\\	2022-05-02	2022-05-02	2022-05-02	\N	TEST	\\test\\3\\	\N	\N	\N	\N
1	\\modifiers1\\1\\	Modifier 1	N	RA 	0	TEST:5	<?xml version="1.0"?><ValueMetadata></ValueMetadata>	modifier_cd	modifier_dimension	modifier_path	T	LIKE	\\modifiers1\\1\\	Modifier 1	\\modifiers1\\1\\	2022-05-02	2022-05-02	2022-05-02	\N	TEST	\\test\\1\\	\N	\N	\N	\N
1	\\modifiers2\\2\\	Modifier 2	N	RA 	0	TEST:6	\N	modifier_cd	modifier_dimension	modifier_path	T	LIKE	\\modifiers2\\2\\	Modifier 2	\\modifiers2\\2\\	2022-05-02	2022-05-02	2022-05-02	\N	TEST	\\test\\2\\	\N	\N	\N	\N
1	\\modifiers3\\3\\	Modifier 3	N	RA 	0	TEST:7	\N	modifier_cd	modifier_dimension	modifier_path	T	LIKE	\\modifiers3\\3\\	Modifier 3	\\modifiers3\\3\\	2022-05-02	2022-05-02	2022-05-02	\N	TEST	\\test\\3\\	\N	\N	\N	\N
1	\\modifiers2\\text\\	Modifier 2 text	N	RA 	0	TEST:8	\N	modifier_cd	modifier_dimension	modifier_path	T	LIKE	\\modifiers2\\text\\	Modifier 2 text	\\modifiers2\\text\\	2022-05-02	2022-05-02	2022-05-02	\N	T	\\test\\2\\	\N	\N	\N	\N
1	\\modifiers3\\text\\	Modifier 3 text	N	RA 	0	TEST:9	\N	modifier_cd	modifier_dimension	modifier_path	T	LIKE	\\modifiers3\\text\\	Modifier 3 text	\\modifiers3\\text\\	2022-05-02	2022-05-02	2022-05-02	\N	T	\\test\\3\\	\N	\N	\N	\N
0	\\SPHNv2020.1\\	SPHN ontology	N	CA 	\N	\N	\N	concept_cd	concept_dimension	concept_path	T	LIKE	\\SPHNv2020.1\\	\N	\\ SPHNv2020.1 \\	1972-04-25	\N	\N	\N	\N	@	\N	\N	\N	\N
1	\\SPHNv2020.1\\DeathStatus\\	Death Status	N	LA 	\N	A125	\N	concept_cd	concept_dimension	concept_path	T	LIKE	\\SPHNv2020.1\\DeathStatus\\	\N	\\ SPHNv2020.1 \\ DeathStatus \\	1972-04-25	\N	\N	\N	\N	@	\N	\N	\N	\N
1	\\DeathStatus-status\\	Value of the death status	N	DA 	\N	126	\N	modifier_cd	modifier_dimension	modifier_path	T	LIKE	\\DeathStatus-status\\	\N	\\ DeathStatus-status \\	1972-04-25	\N	\N	\N	\N	\\SPHNv2020.1\\DeathStatus\\	\N	\N	\N	\N
2	\\DeathStatus-status\\unknown\\	Unknown	N	RA 	\N	126:0	\N	modifier_cd	modifier_dimension	modifier_path	T	LIKE	\\DeathStatus-status\\unknown\\	\N	\\ DeathStatus-status \\ unknown \\	1972-04-25	\N	\N	\N	\N	\\SPHNv2020.1\\DeathStatus\\	\N	\N	\N	\N
2	\\DeathStatus-status\\death\\	Death	N	RA 	\N	126:1	\N	modifier_cd	modifier_dimension	modifier_path	T	LIKE	\\DeathStatus-status\\death\\	\N	\\ DeathStatus-status \\ death \\	1972-04-25	\N	\N	\N	\N	\\SPHNv2020.1\\DeathStatus\\	\N	\N	\N	\N
1	\\SPHNv2020.1\\FophDiagnosis\\	Foph Diagnosis	N	LA 	\N	A168	\N	concept_cd	concept_dimension	concept_path	T	LIKE	\\SPHNv2020.1\\FophDiagnosis\\	\N	\\ SPHNv2020.1 \\ FophDiagnosis \\	1972-04-25	\N	\N	\N	\N	@	\N	\N	\N	\N
6	\\FophDiagnosis-code\\ICD10\\Conditions on the perinatal period(760-779)\\Maternally caused (760-763)\\(762) Fetus or newborn affected b~\\(762-3) Placental transfusion syn~\\	Placental Tranfusion	N	RA 	\N	101:ICD10:762.5	\N	modifier_cd	modifier_dimension	modifier_path	T	LIKE	\\FophDiagnosis-code\\ICD10\\Conditions on the perinatal period(760-779)\\Maternally caused (760-763)\\(762) Fetus or newborn affected b~\\(762-3) Placental transfusion syn~\\	\N	\\ FophDiagnosis-code \\ ICD10 \\ Conditions on the perinatal period(760-779) \\ Maternally caused (760-763) \\ (762) Fetus or newborn affected b~ \\ (762-3) Placental transfusion syn~ \\	1972-04-25	\N	\N	\N	\N	\\SPHNv2020.1\\FophDiagnosis\\	\N	\N	\N	\N
5	\\FophDiagnosis-code\\ICD10\\Conditions on the perinatal period(760-779)\\Maternally caused (760-763)\\(762) Fetus or newborn affected b~\\	Fetus or newborn	N	DA 	\N	\N	\N	modifier_cd	modifier_dimension	modifier_path	T	LIKE	\\FophDiagnosis-code\\ICD10\\Conditions on the perinatal period(760-779)\\Maternally caused (760-763)\\(762) Fetus or newborn affected b~\\	\N	\\ FophDiagnosis-code \\ ICD10 \\ Conditions on the perinatal period(760-779) \\ Maternally caused (760-763) \\ (762) Fetus or newborn affected b~ \\	1972-04-25	\N	\N	\N	\N	\\SPHNv2020.1\\FophDiagnosis\\	\N	\N	\N	\N
4	\\FophDiagnosis-code\\ICD10\\Conditions on the perinatal period(760-779)\\Maternally caused (760-763)\\	Maternally caused	N	DA 	\N	\N	\N	modifier_cd	modifier_dimension	modifier_path	T	LIKE	\\FophDiagnosis-code\\ICD10\\Conditions on the perinatal period(760-779)\\Maternally caused (760-763)\\	\N	\\ FophDiagnosis-code \\ ICD10 \\ Conditions on the perinatal period(760-779) \\ Maternally caused (760-763) \\	1972-04-25	\N	\N	\N	\N	\\SPHNv2020.1\\FophDiagnosis\\	\N	\N	\N	\N
3	\\FophDiagnosis-code\\ICD10\\Conditions on the perinatal period(760-779)\\	Perinatal	N	DA 	\N	\N	\N	modifier_cd	modifier_dimension	modifier_path	T	LIKE	\\FophDiagnosis-code\\ICD10\\Conditions on the perinatal period(760-779)\\	\N	\\ FophDiagnosis-code \\ ICD10 \\ Conditions on the perinatal period(760-779) \\	1972-04-25	\N	\N	\N	\N	\\SPHNv2020.1\\FophDiagnosis\\	\N	\N	\N	\N
2	\\FophDiagnosis-code\\ICD10\\	ICD10	N	DA 	\N	101:ICD10	\N	modifier_cd	modifier_dimension	modifier_path	T	LIKE	\\FophDiagnosis-code\\ICD10\\	\N	\\ FophDiagnosis-code \\ ICD10 \\	1972-04-25	\N	\N	\N	\N	\\SPHNv2020.1\\FophDiagnosis\\	\N	\N	\N	\N
1	\\FophDiagnosis-code\\	Diagnosis value	N	DA 	\N	101	\N	modifier_cd	modifier_dimension	modifier_path	T	LIKE	\\FophDiagnosis-code\\	\N	\\ FophDiagnosis-code \\	1972-04-25	\N	\N	\N	\N	\\SPHNv2020.1\\FophDiagnosis\\	\N	\N	\N	\N
0	\\I2B2\\	I2B2 ontology	N	CA 	\N	\N	\N	concept_cd	concept_dimension	concept_path	T	LIKE	\\I2B2\\	\N	\\ I2B2 \\	1972-04-25	\N	\N	\N	\N	@	\N	\N	\N	\N
3	\\I2B2\\Demographics\\Gender\\Female\\	Female gender	N	LA 	\N	DEM|SEX:f	\N	concept_cd	concept_dimension	concept_path	T	LIKE	\\I2B2\\Demographics\\Gender\\Female\\	\N	\\ I2B2 \\ Demographics \\ Gender \\ Female \\	1972-04-25	\N	\N	\N	\N	@	\N	\N	\N	\N
3	\\I2B2\\Demographics\\Gender\\Male\\	Male gender	N	LA 	\N	DEM|SEX:m	\N	concept_cd	concept_dimension	concept_path	T	LIKE	\\I2B2\\Demographics\\Gender\\Male\\	\N	\\ I2B2 \\ Demographics \\ Gender \\ Male \\	1972-04-25	\N	\N	\N	\N	@	\N	\N	\N	\N
2	\\I2B2\\Demographics\\Gender\\	Gender	N	FA 	\N	\N	\N	concept_cd	concept_dimension	concept_path	T	LIKE	\\I2B2\\Demographics\\Gender\\	\N	\\ I2B2 \\ Demographics \\ Gender \\	1972-04-25	\N	\N	\N	\N	@	\N	\N	\N	\N
1	\\I2B2\\Demographics\\	I2B2 demographics	N	FA 	\N	\N	\N	concept_cd	concept_dimension	concept_path	T	LIKE	\\I2B2\\Demographics\\	\N	\\ I2B2 \\ Demographics \\	1972-04-25	\N	\N	\N	\N	@	\N	\N	\N	\N
\.


--
-- Data for Name: totalnum; Type: TABLE DATA; Schema: i2b2metadata; Owner: postgres
--

COPY i2b2metadata.totalnum (c_fullname, agg_date, agg_count, typeflag_cd) FROM stdin;
\.


--
-- Data for Name: totalnum_report; Type: TABLE DATA; Schema: i2b2metadata; Owner: postgres
--

COPY i2b2metadata.totalnum_report (c_fullname, agg_date, agg_count) FROM stdin;
\.


--
-- Data for Name: pm_approvals; Type: TABLE DATA; Schema: i2b2pm; Owner: postgres
--

COPY i2b2pm.pm_approvals (approval_id, approval_name, approval_description, approval_activation_date, approval_expiration_date, object_cd, change_date, entry_date, changeby_char, status_cd) FROM stdin;
\.


--
-- Data for Name: pm_approvals_params; Type: TABLE DATA; Schema: i2b2pm; Owner: postgres
--

COPY i2b2pm.pm_approvals_params (id, approval_id, param_name_cd, value, activation_date, expiration_date, datatype_cd, object_cd, change_date, entry_date, changeby_char, status_cd) FROM stdin;
\.


--
-- Data for Name: pm_cell_data; Type: TABLE DATA; Schema: i2b2pm; Owner: postgres
--

COPY i2b2pm.pm_cell_data (cell_id, project_path, name, method_cd, url, can_override, change_date, entry_date, changeby_char, status_cd) FROM stdin;
CRC	/	Data Repository	REST	http://i2b2:8080/i2b2/services/QueryToolService/	1	\N	\N	\N	A
FRC	/	File Repository 	SOAP	http://i2b2:8080/i2b2/services/FRService/	1	\N	\N	\N	A
ONT	/	Ontology Cell	REST	http://i2b2:8080/i2b2/services/OntologyService/	1	\N	\N	\N	A
WORK	/	Workplace Cell	REST	http://i2b2:8080/i2b2/services/WorkplaceService/	1	\N	\N	\N	A
IM	/	IM Cell	REST	http://i2b2:8080/i2b2/services/IMService/	1	\N	\N	\N	A
\.


--
-- Data for Name: pm_cell_params; Type: TABLE DATA; Schema: i2b2pm; Owner: postgres
--

COPY i2b2pm.pm_cell_params (id, datatype_cd, cell_id, project_path, param_name_cd, value, can_override, change_date, entry_date, changeby_char, status_cd) FROM stdin;
1	T	FRC	/	DestDir	/opt/jboss/wildfly/standalone/data/i2b2_FR_files	\N	\N	\N	i2b2	A
\.


--
-- Data for Name: pm_global_params; Type: TABLE DATA; Schema: i2b2pm; Owner: postgres
--

COPY i2b2pm.pm_global_params (id, datatype_cd, param_name_cd, project_path, value, can_override, change_date, entry_date, changeby_char, status_cd) FROM stdin;
\.


--
-- Data for Name: pm_hive_data; Type: TABLE DATA; Schema: i2b2pm; Owner: postgres
--

COPY i2b2pm.pm_hive_data (domain_id, helpurl, domain_name, environment_cd, active, change_date, entry_date, changeby_char, status_cd) FROM stdin;
i2b2demo	http://www.i2b2.org	i2b2demo	DEVELOPMENT	1	\N	\N	\N	A
\.


--
-- Data for Name: pm_hive_params; Type: TABLE DATA; Schema: i2b2pm; Owner: postgres
--

COPY i2b2pm.pm_hive_params (id, datatype_cd, domain_id, param_name_cd, value, change_date, entry_date, changeby_char, status_cd) FROM stdin;
\.


--
-- Data for Name: pm_project_data; Type: TABLE DATA; Schema: i2b2pm; Owner: postgres
--

COPY i2b2pm.pm_project_data (project_id, project_name, project_wiki, project_key, project_path, project_description, change_date, entry_date, changeby_char, status_cd) FROM stdin;
Demo	i2b2 Demo	http://www.i2b2.org	\N	/Demo	\N	\N	\N	\N	A
\.


--
-- Data for Name: pm_project_params; Type: TABLE DATA; Schema: i2b2pm; Owner: postgres
--

COPY i2b2pm.pm_project_params (id, datatype_cd, project_id, param_name_cd, value, change_date, entry_date, changeby_char, status_cd) FROM stdin;
\.


--
-- Data for Name: pm_project_request; Type: TABLE DATA; Schema: i2b2pm; Owner: postgres
--

COPY i2b2pm.pm_project_request (id, title, request_xml, change_date, entry_date, changeby_char, status_cd, project_id, submit_char) FROM stdin;
\.


--
-- Data for Name: pm_project_user_params; Type: TABLE DATA; Schema: i2b2pm; Owner: postgres
--

COPY i2b2pm.pm_project_user_params (id, datatype_cd, project_id, user_id, param_name_cd, value, change_date, entry_date, changeby_char, status_cd) FROM stdin;
\.


--
-- Data for Name: pm_project_user_roles; Type: TABLE DATA; Schema: i2b2pm; Owner: postgres
--

COPY i2b2pm.pm_project_user_roles (project_id, user_id, user_role_cd, change_date, entry_date, changeby_char, status_cd) FROM stdin;
@	i2b2	ADMIN	\N	\N	\N	A
Demo	AGG_SERVICE_ACCOUNT	USER	\N	\N	\N	A
Demo	AGG_SERVICE_ACCOUNT	MANAGER	\N	\N	\N	A
Demo	AGG_SERVICE_ACCOUNT	DATA_OBFSC	\N	\N	\N	A
Demo	AGG_SERVICE_ACCOUNT	DATA_AGG	\N	\N	\N	A
Demo	i2b2	MANAGER	\N	\N	\N	A
Demo	i2b2	USER	\N	\N	\N	A
Demo	i2b2	DATA_OBFSC	\N	\N	\N	A
Demo	demo	USER	\N	\N	\N	A
Demo	demo	DATA_DEID	\N	\N	\N	A
Demo	demo	DATA_OBFSC	\N	\N	\N	A
Demo	demo	DATA_AGG	\N	\N	\N	A
Demo	demo	DATA_LDS	\N	\N	\N	A
Demo	demo	EDITOR	\N	\N	\N	A
Demo	demo	DATA_PROT	\N	\N	\N	A
Demo	demo_obf	USER	\N	\N	\N	A
Demo	demo_obf	DATA_OBFSC	\N	\N	\N	A
Demo	demo_mgr	USER	\N	\N	\N	A
Demo	demo_mgr	DATA_OBFSC	\N	\N	\N	A
Demo	demo_mgr	DATA_AGG	\N	\N	\N	A
Demo	demo_mgr	MANAGER	\N	\N	\N	A
\.


--
-- Data for Name: pm_role_requirement; Type: TABLE DATA; Schema: i2b2pm; Owner: postgres
--

COPY i2b2pm.pm_role_requirement (table_cd, column_cd, read_hivemgmt_cd, write_hivemgmt_cd, name_char, change_date, entry_date, changeby_char, status_cd) FROM stdin;
PM_HIVE_DATA	@	@	ADMIN	\N	\N	\N	\N	A
PM_HIVE_PARAMS	@	@	ADMIN	\N	\N	\N	\N	A
PM_PROJECT_DATA	@	@	MANAGER	\N	\N	\N	\N	A
PM_PROJECT_USER_ROLES	@	@	MANAGER	\N	\N	\N	\N	A
PM_USER_DATA	@	@	ADMIN	\N	\N	\N	\N	A
PM_PROJECT_PARAMS	@	@	MANAGER	\N	\N	\N	\N	A
PM_PROJECT_USER_PARAMS	@	@	MANAGER	\N	\N	\N	\N	A
PM_USER_PARAMS	@	@	ADMIN	\N	\N	\N	\N	A
PM_CELL_DATA	@	@	MANAGER	\N	\N	\N	\N	A
PM_CELL_PARAMS	@	@	MANAGER	\N	\N	\N	\N	A
PM_GLOBAL_PARAMS	@	@	ADMIN	\N	\N	\N	\N	A
\.


--
-- Data for Name: pm_user_data; Type: TABLE DATA; Schema: i2b2pm; Owner: postgres
--

COPY i2b2pm.pm_user_data (user_id, full_name, password, email, project_path, change_date, entry_date, changeby_char, status_cd) FROM stdin;
demo_obf	i2b2 Obfuscated User	9117d59a69dc49807671a51f10ab7f	\N	\N	\N	\N	\N	A
demo_mgr	i2b2 Manager User	9117d59a69dc49807671a51f10ab7f	\N	\N	\N	\N	\N	A
i2b2	i2b2 Admin	4cb9c8a848fd02294477fcb1a41191a	\N	\N	\N	\N	\N	A
demo	i2b2 User	4cb9c8a848fd02294477fcb1a41191a	\N	\N	\N	\N	\N	A
AGG_SERVICE_ACCOUNT	AGG_SERVICE_ACCOUNT	4cb9c8a848fd02294477fcb1a41191a	\N	\N	\N	\N	\N	A
\.


--
-- Data for Name: pm_user_login; Type: TABLE DATA; Schema: i2b2pm; Owner: postgres
--

COPY i2b2pm.pm_user_login (user_id, attempt_cd, entry_date, changeby_char, status_cd) FROM stdin;
demo	SUCCESS	2022-05-02 12:02:02.266906	demo	A
demo	SUCCESS	2022-05-02 12:02:03.123974	demo	A
demo	SUCCESS	2022-05-02 12:02:03.300617	demo	A
demo	SUCCESS	2022-05-02 12:02:03.788039	demo	A
demo	SUCCESS	2022-05-02 12:02:03.993194	demo	A
demo	SUCCESS	2022-05-02 12:02:04.227294	demo	A
demo	SUCCESS	2022-05-02 12:02:04.312625	demo	A
demo	SUCCESS	2022-05-02 12:02:04.391528	demo	A
demo	SUCCESS	2022-05-02 12:02:04.462048	demo	A
demo	SUCCESS	2022-05-02 12:02:04.568745	demo	A
demo	SUCCESS	2022-05-02 12:02:04.644774	demo	A
demo	SUCCESS	2022-05-02 12:02:05.168729	demo	A
demo	SUCCESS	2022-05-02 12:02:05.265029	demo	A
demo	SUCCESS	2022-05-02 12:02:05.371062	demo	A
demo	SUCCESS	2022-05-02 12:02:05.412294	demo	A
demo	SUCCESS	2022-05-02 12:02:05.570523	demo	A
demo	SUCCESS	2022-05-02 12:02:05.650001	demo	A
demo	SUCCESS	2022-05-02 12:02:05.706824	demo	A
demo	SUCCESS	2022-05-02 12:02:05.751891	demo	A
demo	SUCCESS	2022-05-02 12:02:05.89716	demo	A
demo	SUCCESS	2022-05-02 12:02:05.964484	demo	A
demo	SUCCESS	2022-05-02 12:02:06.018018	demo	A
demo	SUCCESS	2022-05-02 12:02:06.05377	demo	A
demo	SUCCESS	2022-05-02 12:02:06.331848	demo	A
demo	SUCCESS	2022-05-02 12:02:06.417348	demo	A
demo	SUCCESS	2022-05-02 12:02:06.476725	demo	A
demo	SUCCESS	2022-05-02 12:02:06.523311	demo	A
demo	SUCCESS	2022-05-02 12:02:06.774773	demo	A
demo	SUCCESS	2022-05-02 12:02:06.843135	demo	A
demo	SUCCESS	2022-05-02 12:02:06.923472	demo	A
demo	SUCCESS	2022-05-02 12:02:06.96449	demo	A
demo	SUCCESS	2022-05-02 12:02:07.108677	demo	A
demo	SUCCESS	2022-05-02 12:02:07.197207	demo	A
demo	SUCCESS	2022-05-02 12:02:07.258575	demo	A
demo	SUCCESS	2022-05-02 12:02:07.297634	demo	A
demo	SUCCESS	2022-05-02 12:02:07.595863	demo	A
demo	SUCCESS	2022-05-02 12:02:07.676599	demo	A
demo	SUCCESS	2022-05-02 12:02:07.785565	demo	A
demo	SUCCESS	2022-05-02 12:02:07.83199	demo	A
demo	SUCCESS	2022-05-02 12:02:08.092936	demo	A
demo	SUCCESS	2022-05-02 12:02:08.174214	demo	A
demo	SUCCESS	2022-05-02 12:02:08.230296	demo	A
demo	SUCCESS	2022-05-02 12:02:08.270502	demo	A
demo	SUCCESS	2022-05-02 12:02:08.603781	demo	A
demo	SUCCESS	2022-05-02 12:02:08.7043	demo	A
demo	SUCCESS	2022-05-02 12:02:08.798355	demo	A
demo	SUCCESS	2022-05-02 12:02:08.831571	demo	A
demo	SUCCESS	2022-05-02 12:02:09.039696	demo	A
demo	SUCCESS	2022-05-02 12:02:09.104973	demo	A
demo	SUCCESS	2022-05-02 12:02:09.155554	demo	A
demo	SUCCESS	2022-05-02 12:02:09.188512	demo	A
demo	SUCCESS	2022-05-02 12:02:09.437971	demo	A
demo	SUCCESS	2022-05-02 12:02:09.496714	demo	A
demo	SUCCESS	2022-05-02 12:02:09.561605	demo	A
demo	SUCCESS	2022-05-02 12:02:09.59522	demo	A
demo	SUCCESS	2022-05-02 12:02:09.745793	demo	A
demo	SUCCESS	2022-05-02 12:02:09.827872	demo	A
demo	SUCCESS	2022-05-02 12:02:09.973889	demo	A
demo	SUCCESS	2022-05-02 12:02:10.018383	demo	A
demo	SUCCESS	2022-05-02 12:02:10.084192	demo	A
demo	SUCCESS	2022-05-02 12:02:10.125682	demo	A
demo	SUCCESS	2022-05-02 12:02:10.168125	demo	A
demo	SUCCESS	2022-05-02 12:02:10.210366	demo	A
demo	SUCCESS	2022-05-02 12:02:10.252167	demo	A
demo	SUCCESS	2022-05-02 12:02:10.317634	demo	A
demo	SUCCESS	2022-05-02 12:02:10.382093	demo	A
demo	SUCCESS	2022-05-02 12:02:10.416317	demo	A
demo	SUCCESS	2022-05-02 12:02:10.474036	demo	A
demo	SUCCESS	2022-05-02 12:02:10.527331	demo	A
demo	SUCCESS	2022-05-02 12:02:10.595515	demo	A
demo	SUCCESS	2022-05-02 12:02:10.634072	demo	A
demo	SUCCESS	2022-05-02 12:02:10.669126	demo	A
demo	SUCCESS	2022-05-02 12:02:10.724829	demo	A
demo	SUCCESS	2022-05-02 12:02:10.819896	demo	A
demo	SUCCESS	2022-05-02 12:02:10.853891	demo	A
demo	SUCCESS	2022-05-02 12:02:10.970359	demo	A
demo	SUCCESS	2022-05-02 12:02:11.03307	demo	A
demo	SUCCESS	2022-05-02 12:02:11.205286	demo	A
demo	SUCCESS	2022-05-02 12:02:11.23074	demo	A
demo	SUCCESS	2022-05-02 12:02:11.342563	demo	A
demo	SUCCESS	2022-05-02 12:02:11.401016	demo	A
demo	SUCCESS	2022-05-02 12:02:11.547082	demo	A
demo	SUCCESS	2022-05-02 12:02:11.577231	demo	A
demo	SUCCESS	2022-05-02 12:02:11.694115	demo	A
demo	SUCCESS	2022-05-02 12:02:11.776813	demo	A
demo	SUCCESS	2022-05-02 12:02:11.944015	demo	A
demo	SUCCESS	2022-05-02 12:02:11.986113	demo	A
demo	SUCCESS	2022-05-02 12:02:12.122529	demo	A
demo	SUCCESS	2022-05-02 12:02:12.187386	demo	A
demo	SUCCESS	2022-05-02 12:02:12.365064	demo	A
demo	SUCCESS	2022-05-02 12:02:12.374988	demo	A
demo	SUCCESS	2022-05-02 12:02:12.40864	demo	A
demo	SUCCESS	2022-05-02 12:02:12.417108	demo	A
demo	SUCCESS	2022-05-02 12:02:12.70151	demo	A
demo	SUCCESS	2022-05-02 12:02:12.721229	demo	A
demo	SUCCESS	2022-05-02 12:02:12.826245	demo	A
demo	SUCCESS	2022-05-02 12:02:12.834422	demo	A
demo	SUCCESS	2022-05-02 12:02:15.067765	demo	A
demo	SUCCESS	2022-05-02 12:02:15.129574	demo	A
\.


--
-- Data for Name: pm_user_params; Type: TABLE DATA; Schema: i2b2pm; Owner: postgres
--

COPY i2b2pm.pm_user_params (id, datatype_cd, user_id, param_name_cd, value, change_date, entry_date, changeby_char, status_cd) FROM stdin;
\.


--
-- Data for Name: pm_user_session; Type: TABLE DATA; Schema: i2b2pm; Owner: postgres
--

COPY i2b2pm.pm_user_session (user_id, session_id, expired_date, change_date, entry_date, changeby_char, status_cd) FROM stdin;
demo	eaubhNk08rtL6AUUnBKK	2022-05-02 12:32:02.271113	\N	2022-05-02 12:02:02.271113	demo	\N
demo	Vv6lxWumJME3FeMKXzVa	2022-05-02 12:32:03.126878	\N	2022-05-02 12:02:03.126878	demo	\N
demo	eQJgwLaFDmHkc5wXxEPy	2022-05-02 12:32:03.30317	\N	2022-05-02 12:02:03.30317	demo	\N
AGG_SERVICE_ACCOUNT	gCTklGwfqAPKftSyiHK2	2022-05-02 12:32:03.555932	\N	2022-05-02 12:02:03.555932	AGG_SERVICE_ACCOUNT	\N
demo	tfcT526WcAKelSKyxghC	2022-05-02 12:32:03.789965	\N	2022-05-02 12:02:03.789965	demo	\N
demo	R4fnEXHHAZRZwtzhoeAQ	2022-05-02 12:32:03.995295	\N	2022-05-02 12:02:03.995295	demo	\N
demo	w6d42K2bTqIa246IjYUt	2022-05-02 12:32:04.23013	\N	2022-05-02 12:02:04.23013	demo	\N
demo	PvGtEA5ZoGu3Ouuxi82y	2022-05-02 12:32:04.314399	\N	2022-05-02 12:02:04.314399	demo	\N
demo	XMaYNHhogm86F9QSfYpW	2022-05-02 12:32:04.393257	\N	2022-05-02 12:02:04.393257	demo	\N
demo	42VCA47TZG2yozdSF8cH	2022-05-02 12:32:04.464205	\N	2022-05-02 12:02:04.464205	demo	\N
demo	C8IOwhNIe45PdhEee2HC	2022-05-02 12:32:04.570785	\N	2022-05-02 12:02:04.570785	demo	\N
demo	xRZ8EwrMCOqHdsBpFL9E	2022-05-02 12:32:04.646484	\N	2022-05-02 12:02:04.646484	demo	\N
AGG_SERVICE_ACCOUNT	3mwsEEZh5dfc9s3EkVfQ	2022-05-02 12:32:04.800519	\N	2022-05-02 12:02:04.800519	AGG_SERVICE_ACCOUNT	\N
AGG_SERVICE_ACCOUNT	p6gGrniL6CKvy9Lmt0y3	2022-05-02 12:32:04.92453	\N	2022-05-02 12:02:04.92453	AGG_SERVICE_ACCOUNT	\N
AGG_SERVICE_ACCOUNT	2gemeRnjWghs31Q0loea	2022-05-02 12:32:05.000913	\N	2022-05-02 12:02:05.000913	AGG_SERVICE_ACCOUNT	\N
AGG_SERVICE_ACCOUNT	8ypjJvNUHOa0fUGkkGTc	2022-05-02 12:32:05.085315	\N	2022-05-02 12:02:05.085315	AGG_SERVICE_ACCOUNT	\N
demo	iQ9tWUb0CfPWZqqPPJVp	2022-05-02 12:32:05.170367	\N	2022-05-02 12:02:05.170367	demo	\N
demo	Q73CUVtCzeqndEH7Abw4	2022-05-02 12:32:05.266384	\N	2022-05-02 12:02:05.266384	demo	\N
demo	hXkX8buzZxSea2JLAyKx	2022-05-02 12:32:05.373054	\N	2022-05-02 12:02:05.373054	demo	\N
demo	LakRYMgS115UJyzoCiRm	2022-05-02 12:32:05.413432	\N	2022-05-02 12:02:05.413432	demo	\N
AGG_SERVICE_ACCOUNT	WIgnbEibj06K4ohP7lM7	2022-05-02 12:32:05.493908	\N	2022-05-02 12:02:05.493908	AGG_SERVICE_ACCOUNT	\N
demo	W9Fb4miQnlR6DsfTTFvV	2022-05-02 12:32:05.571765	\N	2022-05-02 12:02:05.571765	demo	\N
demo	lhAJJK7R6AnRWvGdT7Xh	2022-05-02 12:32:05.651179	\N	2022-05-02 12:02:05.651179	demo	\N
demo	7NWMbrIFAEguelfeI8KV	2022-05-02 12:32:05.707997	\N	2022-05-02 12:02:05.707997	demo	\N
demo	xtevImfZG4fafcJo4bow	2022-05-02 12:32:05.753098	\N	2022-05-02 12:02:05.753098	demo	\N
AGG_SERVICE_ACCOUNT	snxVX4yHyoWPF6Kyu2p7	2022-05-02 12:32:05.831906	\N	2022-05-02 12:02:05.831906	AGG_SERVICE_ACCOUNT	\N
demo	fA8PkWfqW3x3HbuEPY1n	2022-05-02 12:32:05.898715	\N	2022-05-02 12:02:05.898715	demo	\N
demo	OpRwU1G6eJ1vcsi1Qd9Y	2022-05-02 12:32:05.965503	\N	2022-05-02 12:02:05.965503	demo	\N
demo	MF6RoRMYTuYeaRVa6Thr	2022-05-02 12:32:06.019046	\N	2022-05-02 12:02:06.019046	demo	\N
demo	63j3ww0OdraCGP5PCMdP	2022-05-02 12:32:06.054963	\N	2022-05-02 12:02:06.054963	demo	\N
AGG_SERVICE_ACCOUNT	lgCGAtdSig8MlCj4pxFe	2022-05-02 12:32:06.121665	\N	2022-05-02 12:02:06.121665	AGG_SERVICE_ACCOUNT	\N
AGG_SERVICE_ACCOUNT	PLICv61QfBA2AReYFCEK	2022-05-02 12:32:06.184206	\N	2022-05-02 12:02:06.184206	AGG_SERVICE_ACCOUNT	\N
AGG_SERVICE_ACCOUNT	PXxpi9xFNN64rTPIsy2A	2022-05-02 12:32:06.249548	\N	2022-05-02 12:02:06.249548	AGG_SERVICE_ACCOUNT	\N
demo	nFQTKAL4mrlq81rXzz17	2022-05-02 12:32:06.333028	\N	2022-05-02 12:02:06.333028	demo	\N
demo	nB0aNa5aYBFT7a3eibGR	2022-05-02 12:32:06.418539	\N	2022-05-02 12:02:06.418539	demo	\N
demo	VFrpRWYrvNmle13AkF7e	2022-05-02 12:32:06.478978	\N	2022-05-02 12:02:06.478978	demo	\N
demo	YR6rtpH5B8Rr5xcNhUqc	2022-05-02 12:32:06.524633	\N	2022-05-02 12:02:06.524633	demo	\N
AGG_SERVICE_ACCOUNT	BVCUcuPPqwI90BW3ob4i	2022-05-02 12:32:06.643265	\N	2022-05-02 12:02:06.643265	AGG_SERVICE_ACCOUNT	\N
AGG_SERVICE_ACCOUNT	JKF2Yoqhoh9lRf6Z9rxo	2022-05-02 12:32:06.71313	\N	2022-05-02 12:02:06.71313	AGG_SERVICE_ACCOUNT	\N
demo	QREGcFSncMCnArKLR1s1	2022-05-02 12:32:06.77586	\N	2022-05-02 12:02:06.77586	demo	\N
demo	GahZvkSIIEBEqm66I1Vq	2022-05-02 12:32:06.844315	\N	2022-05-02 12:02:06.844315	demo	\N
demo	UgQ4ZFRCzBJJXSXXRpYR	2022-05-02 12:32:06.924834	\N	2022-05-02 12:02:06.924834	demo	\N
demo	aHaqxbOLJRbbstHBA6mA	2022-05-02 12:32:06.965859	\N	2022-05-02 12:02:06.965859	demo	\N
AGG_SERVICE_ACCOUNT	OGv9WHWb6TKBaiPCSx2g	2022-05-02 12:32:07.039023	\N	2022-05-02 12:02:07.039023	AGG_SERVICE_ACCOUNT	\N
demo	ONrbY3g24YlosVhgJxoG	2022-05-02 12:32:07.109949	\N	2022-05-02 12:02:07.109949	demo	\N
demo	KOAcNlCF6WaQpEVuGuyG	2022-05-02 12:32:07.198424	\N	2022-05-02 12:02:07.198424	demo	\N
demo	cfwTXakhULS8iEakCerH	2022-05-02 12:32:07.25968	\N	2022-05-02 12:02:07.25968	demo	\N
demo	a3IaP7uuPjDedaoTPi2b	2022-05-02 12:32:07.299035	\N	2022-05-02 12:02:07.299035	demo	\N
AGG_SERVICE_ACCOUNT	KPQhlKWJg23efW7tst8S	2022-05-02 12:32:07.450465	\N	2022-05-02 12:02:07.450465	AGG_SERVICE_ACCOUNT	\N
AGG_SERVICE_ACCOUNT	hwggMmIXis1nyEZMronm	2022-05-02 12:32:07.522088	\N	2022-05-02 12:02:07.522088	AGG_SERVICE_ACCOUNT	\N
demo	dlb5reFSK7dNMHQl3uje	2022-05-02 12:32:07.597302	\N	2022-05-02 12:02:07.597302	demo	\N
demo	E4DS1GGpGm2BUFP1qld8	2022-05-02 12:32:07.67796	\N	2022-05-02 12:02:07.67796	demo	\N
demo	sfAD2AN0VT1ennQljsXd	2022-05-02 12:32:07.787038	\N	2022-05-02 12:02:07.787038	demo	\N
demo	0r8Y5DwM7vIM5qzIV11O	2022-05-02 12:32:07.833752	\N	2022-05-02 12:02:07.833752	demo	\N
AGG_SERVICE_ACCOUNT	lTFANbDkdTuhgcuYVVVN	2022-05-02 12:32:07.933879	\N	2022-05-02 12:02:07.933879	AGG_SERVICE_ACCOUNT	\N
AGG_SERVICE_ACCOUNT	J9bVKdlvdIVNO7YDOjM7	2022-05-02 12:32:08.014615	\N	2022-05-02 12:02:08.014615	AGG_SERVICE_ACCOUNT	\N
demo	Ohtb9EruQXDONzo35pPX	2022-05-02 12:32:08.094081	\N	2022-05-02 12:02:08.094081	demo	\N
demo	qfteCVmtVupNGC6XwOI7	2022-05-02 12:32:08.175808	\N	2022-05-02 12:02:08.175808	demo	\N
demo	qIHUCQulNqiOBM3FGdkR	2022-05-02 12:32:08.231404	\N	2022-05-02 12:02:08.231404	demo	\N
demo	sS5MrXDi9C99CXWn5zeV	2022-05-02 12:32:08.271631	\N	2022-05-02 12:02:08.271631	demo	\N
AGG_SERVICE_ACCOUNT	mgoCstZ4sYj7f4TxTCcw	2022-05-02 12:32:08.353076	\N	2022-05-02 12:02:08.353076	AGG_SERVICE_ACCOUNT	\N
AGG_SERVICE_ACCOUNT	B7Vf1RVv2o4LYSYqfKfe	2022-05-02 12:32:08.415338	\N	2022-05-02 12:02:08.415338	AGG_SERVICE_ACCOUNT	\N
AGG_SERVICE_ACCOUNT	VhLdxoILnwPKmuloVtWg	2022-05-02 12:32:08.479548	\N	2022-05-02 12:02:08.479548	AGG_SERVICE_ACCOUNT	\N
AGG_SERVICE_ACCOUNT	57tVtFY9yp3KSGboZ76f	2022-05-02 12:32:08.53315	\N	2022-05-02 12:02:08.53315	AGG_SERVICE_ACCOUNT	\N
demo	u117i1TqTKYvqMx3yJJd	2022-05-02 12:32:08.604977	\N	2022-05-02 12:02:08.604977	demo	\N
demo	JoyQKfAl059rtb4DdRfd	2022-05-02 12:32:08.70588	\N	2022-05-02 12:02:08.70588	demo	\N
demo	DBN6WfKexqVq1YvXwjEb	2022-05-02 12:32:08.799509	\N	2022-05-02 12:02:08.799509	demo	\N
demo	fAelUs9Ram1czTOumYkN	2022-05-02 12:32:08.832662	\N	2022-05-02 12:02:08.832662	demo	\N
AGG_SERVICE_ACCOUNT	ljtf5TscFu39Z0IlMUdJ	2022-05-02 12:32:08.907203	\N	2022-05-02 12:02:08.907203	AGG_SERVICE_ACCOUNT	\N
AGG_SERVICE_ACCOUNT	XG1bkkkkSPQcoBduyQ9A	2022-05-02 12:32:08.969259	\N	2022-05-02 12:02:08.969259	AGG_SERVICE_ACCOUNT	\N
demo	8rIFxdl1tTirUTgxaOcd	2022-05-02 12:32:09.041027	\N	2022-05-02 12:02:09.041027	demo	\N
demo	nyxrv5XjSLMNzCbOSiME	2022-05-02 12:32:09.106113	\N	2022-05-02 12:02:09.106113	demo	\N
demo	prHcVwScKvLK7ZCi59vm	2022-05-02 12:32:09.15665	\N	2022-05-02 12:02:09.15665	demo	\N
demo	tcik967PB5GRK2QxHVfr	2022-05-02 12:32:09.189687	\N	2022-05-02 12:02:09.189687	demo	\N
AGG_SERVICE_ACCOUNT	d6QFuoSbL13uBl6siWxH	2022-05-02 12:32:09.252118	\N	2022-05-02 12:02:09.252118	AGG_SERVICE_ACCOUNT	\N
AGG_SERVICE_ACCOUNT	FXXMi7fx0PwLZpc4NkE9	2022-05-02 12:32:09.295463	\N	2022-05-02 12:02:09.295463	AGG_SERVICE_ACCOUNT	\N
AGG_SERVICE_ACCOUNT	BwHXRU87obC9uswGhqSC	2022-05-02 12:32:09.339013	\N	2022-05-02 12:02:09.339013	AGG_SERVICE_ACCOUNT	\N
AGG_SERVICE_ACCOUNT	3NqYaAnSO1pGZvESdKHi	2022-05-02 12:32:09.382625	\N	2022-05-02 12:02:09.382625	AGG_SERVICE_ACCOUNT	\N
demo	bbTf53NCcN50ag9VRmdL	2022-05-02 12:32:09.439195	\N	2022-05-02 12:02:09.439195	demo	\N
demo	dAyHkr2MVtDFO4Ty0rUI	2022-05-02 12:32:09.497714	\N	2022-05-02 12:02:09.497714	demo	\N
demo	t7M6hO3tXy2a2HszNcgZ	2022-05-02 12:32:09.562786	\N	2022-05-02 12:02:09.562786	demo	\N
demo	A752HWuIGQxQMobbIeRe	2022-05-02 12:32:09.596384	\N	2022-05-02 12:02:09.596384	demo	\N
AGG_SERVICE_ACCOUNT	bmtiG1qyCZchIc2Ej1pF	2022-05-02 12:32:09.675378	\N	2022-05-02 12:02:09.675378	AGG_SERVICE_ACCOUNT	\N
demo	ArlMXbQa9DJHKPM1MoUs	2022-05-02 12:32:09.747013	\N	2022-05-02 12:02:09.747013	demo	\N
demo	BE8EchMbsZczctxbkmD2	2022-05-02 12:32:09.829091	\N	2022-05-02 12:02:09.829091	demo	\N
demo	HsiZ2dGwwCfEMcizYO7j	2022-05-02 12:32:09.975332	\N	2022-05-02 12:02:09.975332	demo	\N
demo	V7hX4Ds5oXAo9NZZkTES	2022-05-02 12:32:10.019501	\N	2022-05-02 12:02:10.019501	demo	\N
demo	LeWa6J5ZpyWpfRlua1Qc	2022-05-02 12:32:10.085344	\N	2022-05-02 12:02:10.085344	demo	\N
demo	JxvdeVaJnA7vZHWOC1GU	2022-05-02 12:32:10.126869	\N	2022-05-02 12:02:10.126869	demo	\N
demo	KThSsGmrPWWvqOOEYtJn	2022-05-02 12:32:10.169482	\N	2022-05-02 12:02:10.169482	demo	\N
demo	cGyUrEyrHHVro0xUW1xn	2022-05-02 12:32:10.211707	\N	2022-05-02 12:02:10.211707	demo	\N
demo	v4cqn6GyiEsgE3WDhnTq	2022-05-02 12:32:10.254828	\N	2022-05-02 12:02:10.254828	demo	\N
demo	74EZNqtFd4aoYsElMIuC	2022-05-02 12:32:10.318791	\N	2022-05-02 12:02:10.318791	demo	\N
demo	TIXho7IzKgdGbiSZl4wn	2022-05-02 12:32:10.383309	\N	2022-05-02 12:02:10.383309	demo	\N
demo	jhulOqBsHCElnWOiS285	2022-05-02 12:32:10.417301	\N	2022-05-02 12:02:10.417301	demo	\N
demo	DYoW9fEjfM8oYOFiN6ML	2022-05-02 12:32:10.47516	\N	2022-05-02 12:02:10.47516	demo	\N
demo	qqA9hWxkLv0wHm9Dlom2	2022-05-02 12:32:10.529032	\N	2022-05-02 12:02:10.529032	demo	\N
demo	UFmktyTgeTQCjLgUCfwD	2022-05-02 12:32:10.596739	\N	2022-05-02 12:02:10.596739	demo	\N
demo	XIHwxILhahclTg8iw6EO	2022-05-02 12:32:10.635088	\N	2022-05-02 12:02:10.635088	demo	\N
demo	xJXLnamwX7FgkRprqlYV	2022-05-02 12:32:10.670088	\N	2022-05-02 12:02:10.670088	demo	\N
demo	MVPo2KWqvYkvpgjd2doN	2022-05-02 12:32:10.726051	\N	2022-05-02 12:02:10.726051	demo	\N
demo	8XOZPR8fd9aNjP2KbE82	2022-05-02 12:32:10.821066	\N	2022-05-02 12:02:10.821066	demo	\N
demo	6xvoeEVWq4of6RkFvrCC	2022-05-02 12:32:10.856484	\N	2022-05-02 12:02:10.856484	demo	\N
AGG_SERVICE_ACCOUNT	pNCWAoaqKoh6mBIAN4Ca	2022-05-02 12:32:10.917976	\N	2022-05-02 12:02:10.917976	AGG_SERVICE_ACCOUNT	\N
demo	s96kD50lmx4elfHEzDS5	2022-05-02 12:32:10.971452	\N	2022-05-02 12:02:10.971452	demo	\N
demo	yZUgvEIDbos965k53j5O	2022-05-02 12:32:11.034169	\N	2022-05-02 12:02:11.034169	demo	\N
demo	NQNZ5iVnyQGXsWyxc6wa	2022-05-02 12:32:11.206337	\N	2022-05-02 12:02:11.206337	demo	\N
demo	rto4Awn4XXndaQQClkWt	2022-05-02 12:32:11.231741	\N	2022-05-02 12:02:11.231741	demo	\N
AGG_SERVICE_ACCOUNT	2b3fB8KTXIDUA6qGsWBd	2022-05-02 12:32:11.285561	\N	2022-05-02 12:02:11.285561	AGG_SERVICE_ACCOUNT	\N
demo	GTL3LEwdTHC1tjbMSsa6	2022-05-02 12:32:11.343636	\N	2022-05-02 12:02:11.343636	demo	\N
demo	zey0lXDGrLxyxF3j7a3d	2022-05-02 12:32:11.402246	\N	2022-05-02 12:02:11.402246	demo	\N
demo	HmR4g6rmEgVK74hty2vS	2022-05-02 12:32:11.548158	\N	2022-05-02 12:02:11.548158	demo	\N
demo	yqagct0euSn8pDLAMmJp	2022-05-02 12:32:11.578304	\N	2022-05-02 12:02:11.578304	demo	\N
AGG_SERVICE_ACCOUNT	hdrRXSeBr98rX6BjkOBE	2022-05-02 12:32:11.63282	\N	2022-05-02 12:02:11.63282	AGG_SERVICE_ACCOUNT	\N
demo	nQxJjfsUMFsMW0MXE4in	2022-05-02 12:32:11.695182	\N	2022-05-02 12:02:11.695182	demo	\N
demo	wmLSRLYNBymVkcfHSZTt	2022-05-02 12:32:11.777992	\N	2022-05-02 12:02:11.777992	demo	\N
demo	8MH2VFqoshpD8xgSKqmp	2022-05-02 12:32:11.945507	\N	2022-05-02 12:02:11.945507	demo	\N
demo	xtmU85RAEYdYUiiViO95	2022-05-02 12:32:11.987298	\N	2022-05-02 12:02:11.987298	demo	\N
AGG_SERVICE_ACCOUNT	Q1xfkDO9FUMTOgnPROb5	2022-05-02 12:32:12.059576	\N	2022-05-02 12:02:12.059576	AGG_SERVICE_ACCOUNT	\N
demo	mjgKtAUrW1QpvLMvPkTQ	2022-05-02 12:32:12.123899	\N	2022-05-02 12:02:12.123899	demo	\N
demo	YFrm9g9sDJ1eeSDiX3w6	2022-05-02 12:32:12.19003	\N	2022-05-02 12:02:12.19003	demo	\N
demo	9Tt3PmD8JAqjc7FNLuYA	2022-05-02 12:32:12.366357	\N	2022-05-02 12:02:12.366357	demo	\N
demo	fYPT9BfCrDBBJNP2TaJe	2022-05-02 12:32:12.376306	\N	2022-05-02 12:02:12.376306	demo	\N
demo	dhyRL4yuz5m0XfBCmgPY	2022-05-02 12:32:12.409962	\N	2022-05-02 12:02:12.409962	demo	\N
demo	zIRIqnUKd9TiT7qLZEd0	2022-05-02 12:32:12.418254	\N	2022-05-02 12:02:12.418254	demo	\N
AGG_SERVICE_ACCOUNT	A7u2LY9MWpdXTqa9ZYZy	2022-05-02 12:32:12.551898	\N	2022-05-02 12:02:12.551898	AGG_SERVICE_ACCOUNT	\N
AGG_SERVICE_ACCOUNT	AvwOY7CW6ag8CygVJco1	2022-05-02 12:32:12.554162	\N	2022-05-02 12:02:12.554162	AGG_SERVICE_ACCOUNT	\N
AGG_SERVICE_ACCOUNT	6UEnrAPvlukDsKmclXCy	2022-05-02 12:32:12.606353	\N	2022-05-02 12:02:12.606353	AGG_SERVICE_ACCOUNT	\N
AGG_SERVICE_ACCOUNT	7acuYIwdMUNWI2EieqDF	2022-05-02 12:32:12.610039	\N	2022-05-02 12:02:12.610039	AGG_SERVICE_ACCOUNT	\N
demo	M3I2Ouecnw47uHyIXhGo	2022-05-02 12:32:12.70317	\N	2022-05-02 12:02:12.70317	demo	\N
demo	fq9nugITmmKI6KtD043W	2022-05-02 12:32:12.722536	\N	2022-05-02 12:02:12.722536	demo	\N
demo	gcwKBdjn5Z7KRBVsJZ6F	2022-05-02 12:32:12.828834	\N	2022-05-02 12:02:12.828834	demo	\N
demo	BFCQs8fhF0tnfIcWREFA	2022-05-02 12:32:12.836242	\N	2022-05-02 12:02:12.836242	demo	\N
demo	RWqMe7I5Hi06FGe5EboJ	2022-05-02 12:32:15.06916	\N	2022-05-02 12:02:15.06916	demo	\N
demo	VnmbqkqU2GS24mSP7yzd	2022-05-02 12:32:15.130906	\N	2022-05-02 12:02:15.130906	demo	\N
\.


--
-- Data for Name: workplace; Type: TABLE DATA; Schema: i2b2workdata; Owner: postgres
--

COPY i2b2workdata.workplace (c_name, c_user_id, c_group_id, c_share_id, c_index, c_parent_index, c_visualattributes, c_protected_access, c_tooltip, c_work_xml, c_work_xml_schema, c_work_xml_i2b2_type, c_entry_date, c_change_date, c_status_cd) FROM stdin;
\.


--
-- Data for Name: workplace_access; Type: TABLE DATA; Schema: i2b2workdata; Owner: postgres
--

COPY i2b2workdata.workplace_access (c_table_cd, c_table_name, c_protected_access, c_hlevel, c_name, c_user_id, c_group_id, c_share_id, c_index, c_parent_index, c_visualattributes, c_tooltip, c_entry_date, c_change_date, c_status_cd) FROM stdin;
demo	WORKPLACE	N	0	SHARED	shared	demo	Y	100	\N	CA 	SHARED	\N	\N	\N
demo	WORKPLACE	N	0	@	@	@	N	0	\N	CA 	@	\N	\N	\N
\.


--
-- Name: observation_fact_text_search_index_seq; Type: SEQUENCE SET; Schema: i2b2demodata; Owner: postgres
--

SELECT pg_catalog.setval('i2b2demodata.observation_fact_text_search_index_seq', 1163, true);


--
-- Name: qt_patient_enc_collection_patient_enc_coll_id_seq; Type: SEQUENCE SET; Schema: i2b2demodata; Owner: postgres
--

SELECT pg_catalog.setval('i2b2demodata.qt_patient_enc_collection_patient_enc_coll_id_seq', 1, false);


--
-- Name: qt_patient_set_collection_patient_set_coll_id_seq; Type: SEQUENCE SET; Schema: i2b2demodata; Owner: postgres
--

SELECT pg_catalog.setval('i2b2demodata.qt_patient_set_collection_patient_set_coll_id_seq', 1171, true);


--
-- Name: qt_pdo_query_master_query_master_id_seq; Type: SEQUENCE SET; Schema: i2b2demodata; Owner: postgres
--

SELECT pg_catalog.setval('i2b2demodata.qt_pdo_query_master_query_master_id_seq', 19, true);


--
-- Name: qt_query_instance_query_instance_id_seq; Type: SEQUENCE SET; Schema: i2b2demodata; Owner: postgres
--

SELECT pg_catalog.setval('i2b2demodata.qt_query_instance_query_instance_id_seq', 19, true);


--
-- Name: qt_query_master_query_master_id_seq; Type: SEQUENCE SET; Schema: i2b2demodata; Owner: postgres
--

SELECT pg_catalog.setval('i2b2demodata.qt_query_master_query_master_id_seq', 19, true);


--
-- Name: qt_query_result_instance_result_instance_id_seq; Type: SEQUENCE SET; Schema: i2b2demodata; Owner: postgres
--

SELECT pg_catalog.setval('i2b2demodata.qt_query_result_instance_result_instance_id_seq', 38, true);


--
-- Name: qt_xml_result_xml_result_id_seq; Type: SEQUENCE SET; Schema: i2b2demodata; Owner: postgres
--

SELECT pg_catalog.setval('i2b2demodata.qt_xml_result_xml_result_id_seq', 19, true);


--
-- Name: upload_status_upload_id_seq; Type: SEQUENCE SET; Schema: i2b2demodata; Owner: postgres
--

SELECT pg_catalog.setval('i2b2demodata.upload_status_upload_id_seq', 1, false);


--
-- Name: ont_process_status_process_id_seq; Type: SEQUENCE SET; Schema: i2b2metadata; Owner: postgres
--

SELECT pg_catalog.setval('i2b2metadata.ont_process_status_process_id_seq', 1, false);


--
-- Name: pm_approvals_params_id_seq; Type: SEQUENCE SET; Schema: i2b2pm; Owner: postgres
--

SELECT pg_catalog.setval('i2b2pm.pm_approvals_params_id_seq', 1, false);


--
-- Name: pm_cell_params_id_seq; Type: SEQUENCE SET; Schema: i2b2pm; Owner: postgres
--

SELECT pg_catalog.setval('i2b2pm.pm_cell_params_id_seq', 1, true);


--
-- Name: pm_global_params_id_seq; Type: SEQUENCE SET; Schema: i2b2pm; Owner: postgres
--

SELECT pg_catalog.setval('i2b2pm.pm_global_params_id_seq', 1, false);


--
-- Name: pm_hive_params_id_seq; Type: SEQUENCE SET; Schema: i2b2pm; Owner: postgres
--

SELECT pg_catalog.setval('i2b2pm.pm_hive_params_id_seq', 1, false);


--
-- Name: pm_project_params_id_seq; Type: SEQUENCE SET; Schema: i2b2pm; Owner: postgres
--

SELECT pg_catalog.setval('i2b2pm.pm_project_params_id_seq', 1, false);


--
-- Name: pm_project_request_id_seq; Type: SEQUENCE SET; Schema: i2b2pm; Owner: postgres
--

SELECT pg_catalog.setval('i2b2pm.pm_project_request_id_seq', 1, false);


--
-- Name: pm_project_user_params_id_seq; Type: SEQUENCE SET; Schema: i2b2pm; Owner: postgres
--

SELECT pg_catalog.setval('i2b2pm.pm_project_user_params_id_seq', 1, false);


--
-- Name: pm_user_params_id_seq; Type: SEQUENCE SET; Schema: i2b2pm; Owner: postgres
--

SELECT pg_catalog.setval('i2b2pm.pm_user_params_id_seq', 1, false);


--
-- Name: qt_analysis_plugin analysis_plugin_pk; Type: CONSTRAINT; Schema: i2b2demodata; Owner: postgres
--

ALTER TABLE ONLY i2b2demodata.qt_analysis_plugin
    ADD CONSTRAINT analysis_plugin_pk PRIMARY KEY (plugin_id);


--
-- Name: qt_analysis_plugin_result_type analysis_plugin_result_pk; Type: CONSTRAINT; Schema: i2b2demodata; Owner: postgres
--

ALTER TABLE ONLY i2b2demodata.qt_analysis_plugin_result_type
    ADD CONSTRAINT analysis_plugin_result_pk PRIMARY KEY (plugin_id, result_type_id);


--
-- Name: code_lookup code_lookup_pk; Type: CONSTRAINT; Schema: i2b2demodata; Owner: postgres
--

ALTER TABLE ONLY i2b2demodata.code_lookup
    ADD CONSTRAINT code_lookup_pk PRIMARY KEY (table_cd, column_cd, code_cd);


--
-- Name: concept_dimension concept_dimension_pk; Type: CONSTRAINT; Schema: i2b2demodata; Owner: postgres
--

ALTER TABLE ONLY i2b2demodata.concept_dimension
    ADD CONSTRAINT concept_dimension_pk PRIMARY KEY (concept_path);


--
-- Name: encounter_mapping encounter_mapping_pk; Type: CONSTRAINT; Schema: i2b2demodata; Owner: postgres
--

ALTER TABLE ONLY i2b2demodata.encounter_mapping
    ADD CONSTRAINT encounter_mapping_pk PRIMARY KEY (encounter_ide, encounter_ide_source, project_id, patient_ide, patient_ide_source);


--
-- Name: modifier_dimension modifier_dimension_pk; Type: CONSTRAINT; Schema: i2b2demodata; Owner: postgres
--

ALTER TABLE ONLY i2b2demodata.modifier_dimension
    ADD CONSTRAINT modifier_dimension_pk PRIMARY KEY (modifier_path);


--
-- Name: observation_fact observation_fact_pk; Type: CONSTRAINT; Schema: i2b2demodata; Owner: postgres
--

ALTER TABLE ONLY i2b2demodata.observation_fact
    ADD CONSTRAINT observation_fact_pk PRIMARY KEY (patient_num, concept_cd, modifier_cd, start_date, encounter_num, instance_num, provider_id);


--
-- Name: patient_dimension patient_dimension_pk; Type: CONSTRAINT; Schema: i2b2demodata; Owner: postgres
--

ALTER TABLE ONLY i2b2demodata.patient_dimension
    ADD CONSTRAINT patient_dimension_pk PRIMARY KEY (patient_num);


--
-- Name: patient_mapping patient_mapping_pk; Type: CONSTRAINT; Schema: i2b2demodata; Owner: postgres
--

ALTER TABLE ONLY i2b2demodata.patient_mapping
    ADD CONSTRAINT patient_mapping_pk PRIMARY KEY (patient_ide, patient_ide_source, project_id);


--
-- Name: source_master pk_sourcemaster_sourcecd; Type: CONSTRAINT; Schema: i2b2demodata; Owner: postgres
--

ALTER TABLE ONLY i2b2demodata.source_master
    ADD CONSTRAINT pk_sourcemaster_sourcecd PRIMARY KEY (source_cd);


--
-- Name: set_type pk_st_id; Type: CONSTRAINT; Schema: i2b2demodata; Owner: postgres
--

ALTER TABLE ONLY i2b2demodata.set_type
    ADD CONSTRAINT pk_st_id PRIMARY KEY (id);


--
-- Name: set_upload_status pk_up_upstatus_idsettypeid; Type: CONSTRAINT; Schema: i2b2demodata; Owner: postgres
--

ALTER TABLE ONLY i2b2demodata.set_upload_status
    ADD CONSTRAINT pk_up_upstatus_idsettypeid PRIMARY KEY (upload_id, set_type_id);


--
-- Name: provider_dimension provider_dimension_pk; Type: CONSTRAINT; Schema: i2b2demodata; Owner: postgres
--

ALTER TABLE ONLY i2b2demodata.provider_dimension
    ADD CONSTRAINT provider_dimension_pk PRIMARY KEY (provider_path, provider_id);


--
-- Name: qt_patient_enc_collection qt_patient_enc_collection_pkey; Type: CONSTRAINT; Schema: i2b2demodata; Owner: postgres
--

ALTER TABLE ONLY i2b2demodata.qt_patient_enc_collection
    ADD CONSTRAINT qt_patient_enc_collection_pkey PRIMARY KEY (patient_enc_coll_id);


--
-- Name: qt_patient_set_collection qt_patient_set_collection_pkey; Type: CONSTRAINT; Schema: i2b2demodata; Owner: postgres
--

ALTER TABLE ONLY i2b2demodata.qt_patient_set_collection
    ADD CONSTRAINT qt_patient_set_collection_pkey PRIMARY KEY (patient_set_coll_id);


--
-- Name: qt_pdo_query_master qt_pdo_query_master_pkey; Type: CONSTRAINT; Schema: i2b2demodata; Owner: postgres
--

ALTER TABLE ONLY i2b2demodata.qt_pdo_query_master
    ADD CONSTRAINT qt_pdo_query_master_pkey PRIMARY KEY (query_master_id);


--
-- Name: qt_privilege qt_privilege_pkey; Type: CONSTRAINT; Schema: i2b2demodata; Owner: postgres
--

ALTER TABLE ONLY i2b2demodata.qt_privilege
    ADD CONSTRAINT qt_privilege_pkey PRIMARY KEY (protection_label_cd);


--
-- Name: qt_query_instance qt_query_instance_pkey; Type: CONSTRAINT; Schema: i2b2demodata; Owner: postgres
--

ALTER TABLE ONLY i2b2demodata.qt_query_instance
    ADD CONSTRAINT qt_query_instance_pkey PRIMARY KEY (query_instance_id);


--
-- Name: qt_query_master qt_query_master_pkey; Type: CONSTRAINT; Schema: i2b2demodata; Owner: postgres
--

ALTER TABLE ONLY i2b2demodata.qt_query_master
    ADD CONSTRAINT qt_query_master_pkey PRIMARY KEY (query_master_id);


--
-- Name: qt_query_result_instance qt_query_result_instance_pkey; Type: CONSTRAINT; Schema: i2b2demodata; Owner: postgres
--

ALTER TABLE ONLY i2b2demodata.qt_query_result_instance
    ADD CONSTRAINT qt_query_result_instance_pkey PRIMARY KEY (result_instance_id);


--
-- Name: qt_query_result_type qt_query_result_type_pkey; Type: CONSTRAINT; Schema: i2b2demodata; Owner: postgres
--

ALTER TABLE ONLY i2b2demodata.qt_query_result_type
    ADD CONSTRAINT qt_query_result_type_pkey PRIMARY KEY (result_type_id);


--
-- Name: qt_query_status_type qt_query_status_type_pkey; Type: CONSTRAINT; Schema: i2b2demodata; Owner: postgres
--

ALTER TABLE ONLY i2b2demodata.qt_query_status_type
    ADD CONSTRAINT qt_query_status_type_pkey PRIMARY KEY (status_type_id);


--
-- Name: qt_xml_result qt_xml_result_pkey; Type: CONSTRAINT; Schema: i2b2demodata; Owner: postgres
--

ALTER TABLE ONLY i2b2demodata.qt_xml_result
    ADD CONSTRAINT qt_xml_result_pkey PRIMARY KEY (xml_result_id);


--
-- Name: upload_status upload_status_pkey; Type: CONSTRAINT; Schema: i2b2demodata; Owner: postgres
--

ALTER TABLE ONLY i2b2demodata.upload_status
    ADD CONSTRAINT upload_status_pkey PRIMARY KEY (upload_id);


--
-- Name: visit_dimension visit_dimension_pk; Type: CONSTRAINT; Schema: i2b2demodata; Owner: postgres
--

ALTER TABLE ONLY i2b2demodata.visit_dimension
    ADD CONSTRAINT visit_dimension_pk PRIMARY KEY (encounter_num, patient_num);


--
-- Name: crc_analysis_job analsis_job_pk; Type: CONSTRAINT; Schema: i2b2hive; Owner: postgres
--

ALTER TABLE ONLY i2b2hive.crc_analysis_job
    ADD CONSTRAINT analsis_job_pk PRIMARY KEY (job_id);


--
-- Name: crc_db_lookup crc_db_lookup_pk; Type: CONSTRAINT; Schema: i2b2hive; Owner: postgres
--

ALTER TABLE ONLY i2b2hive.crc_db_lookup
    ADD CONSTRAINT crc_db_lookup_pk PRIMARY KEY (c_domain_id, c_project_path, c_owner_id);


--
-- Name: hive_cell_params hive_ce__pk; Type: CONSTRAINT; Schema: i2b2hive; Owner: postgres
--

ALTER TABLE ONLY i2b2hive.hive_cell_params
    ADD CONSTRAINT hive_ce__pk PRIMARY KEY (id);


--
-- Name: im_db_lookup im_db_lookup_pk; Type: CONSTRAINT; Schema: i2b2hive; Owner: postgres
--

ALTER TABLE ONLY i2b2hive.im_db_lookup
    ADD CONSTRAINT im_db_lookup_pk PRIMARY KEY (c_domain_id, c_project_path, c_owner_id);


--
-- Name: ont_db_lookup ont_db_lookup_pk; Type: CONSTRAINT; Schema: i2b2hive; Owner: postgres
--

ALTER TABLE ONLY i2b2hive.ont_db_lookup
    ADD CONSTRAINT ont_db_lookup_pk PRIMARY KEY (c_domain_id, c_project_path, c_owner_id);


--
-- Name: work_db_lookup work_db_lookup_pk; Type: CONSTRAINT; Schema: i2b2hive; Owner: postgres
--

ALTER TABLE ONLY i2b2hive.work_db_lookup
    ADD CONSTRAINT work_db_lookup_pk PRIMARY KEY (c_domain_id, c_project_path, c_owner_id);


--
-- Name: im_mpi_demographics im_mpi_demographics_pk; Type: CONSTRAINT; Schema: i2b2imdata; Owner: postgres
--

ALTER TABLE ONLY i2b2imdata.im_mpi_demographics
    ADD CONSTRAINT im_mpi_demographics_pk PRIMARY KEY (global_id);


--
-- Name: im_mpi_mapping im_mpi_mapping_pk; Type: CONSTRAINT; Schema: i2b2imdata; Owner: postgres
--

ALTER TABLE ONLY i2b2imdata.im_mpi_mapping
    ADD CONSTRAINT im_mpi_mapping_pk PRIMARY KEY (lcl_site, lcl_id, update_date);


--
-- Name: im_project_patients im_project_patients_pk; Type: CONSTRAINT; Schema: i2b2imdata; Owner: postgres
--

ALTER TABLE ONLY i2b2imdata.im_project_patients
    ADD CONSTRAINT im_project_patients_pk PRIMARY KEY (project_id, global_id);


--
-- Name: im_project_sites im_project_sites_pk; Type: CONSTRAINT; Schema: i2b2imdata; Owner: postgres
--

ALTER TABLE ONLY i2b2imdata.im_project_sites
    ADD CONSTRAINT im_project_sites_pk PRIMARY KEY (project_id, lcl_site);


--
-- Name: test basecode_un_10; Type: CONSTRAINT; Schema: i2b2metadata; Owner: postgres
--

ALTER TABLE ONLY i2b2metadata.test
    ADD CONSTRAINT basecode_un_10 UNIQUE (c_basecode);


--
-- Name: test fullname_pk_10; Type: CONSTRAINT; Schema: i2b2metadata; Owner: postgres
--

ALTER TABLE ONLY i2b2metadata.test
    ADD CONSTRAINT fullname_pk_10 PRIMARY KEY (c_fullname);


--
-- Name: ont_process_status ont_process_status_pkey; Type: CONSTRAINT; Schema: i2b2metadata; Owner: postgres
--

ALTER TABLE ONLY i2b2metadata.ont_process_status
    ADD CONSTRAINT ont_process_status_pkey PRIMARY KEY (process_id);


--
-- Name: schemes schemes_pk; Type: CONSTRAINT; Schema: i2b2metadata; Owner: postgres
--

ALTER TABLE ONLY i2b2metadata.schemes
    ADD CONSTRAINT schemes_pk PRIMARY KEY (c_key);


--
-- Name: pm_approvals_params pm_approvals_params_pkey; Type: CONSTRAINT; Schema: i2b2pm; Owner: postgres
--

ALTER TABLE ONLY i2b2pm.pm_approvals_params
    ADD CONSTRAINT pm_approvals_params_pkey PRIMARY KEY (id);


--
-- Name: pm_cell_data pm_cell_data_pkey; Type: CONSTRAINT; Schema: i2b2pm; Owner: postgres
--

ALTER TABLE ONLY i2b2pm.pm_cell_data
    ADD CONSTRAINT pm_cell_data_pkey PRIMARY KEY (cell_id, project_path);


--
-- Name: pm_cell_params pm_cell_params_pkey; Type: CONSTRAINT; Schema: i2b2pm; Owner: postgres
--

ALTER TABLE ONLY i2b2pm.pm_cell_params
    ADD CONSTRAINT pm_cell_params_pkey PRIMARY KEY (id);


--
-- Name: pm_global_params pm_global_params_pkey; Type: CONSTRAINT; Schema: i2b2pm; Owner: postgres
--

ALTER TABLE ONLY i2b2pm.pm_global_params
    ADD CONSTRAINT pm_global_params_pkey PRIMARY KEY (id);


--
-- Name: pm_hive_data pm_hive_data_pkey; Type: CONSTRAINT; Schema: i2b2pm; Owner: postgres
--

ALTER TABLE ONLY i2b2pm.pm_hive_data
    ADD CONSTRAINT pm_hive_data_pkey PRIMARY KEY (domain_id);


--
-- Name: pm_hive_params pm_hive_params_pkey; Type: CONSTRAINT; Schema: i2b2pm; Owner: postgres
--

ALTER TABLE ONLY i2b2pm.pm_hive_params
    ADD CONSTRAINT pm_hive_params_pkey PRIMARY KEY (id);


--
-- Name: pm_project_data pm_project_data_pkey; Type: CONSTRAINT; Schema: i2b2pm; Owner: postgres
--

ALTER TABLE ONLY i2b2pm.pm_project_data
    ADD CONSTRAINT pm_project_data_pkey PRIMARY KEY (project_id);


--
-- Name: pm_project_params pm_project_params_pkey; Type: CONSTRAINT; Schema: i2b2pm; Owner: postgres
--

ALTER TABLE ONLY i2b2pm.pm_project_params
    ADD CONSTRAINT pm_project_params_pkey PRIMARY KEY (id);


--
-- Name: pm_project_request pm_project_request_pkey; Type: CONSTRAINT; Schema: i2b2pm; Owner: postgres
--

ALTER TABLE ONLY i2b2pm.pm_project_request
    ADD CONSTRAINT pm_project_request_pkey PRIMARY KEY (id);


--
-- Name: pm_project_user_params pm_project_user_params_pkey; Type: CONSTRAINT; Schema: i2b2pm; Owner: postgres
--

ALTER TABLE ONLY i2b2pm.pm_project_user_params
    ADD CONSTRAINT pm_project_user_params_pkey PRIMARY KEY (id);


--
-- Name: pm_project_user_roles pm_project_user_roles_pkey; Type: CONSTRAINT; Schema: i2b2pm; Owner: postgres
--

ALTER TABLE ONLY i2b2pm.pm_project_user_roles
    ADD CONSTRAINT pm_project_user_roles_pkey PRIMARY KEY (project_id, user_id, user_role_cd);


--
-- Name: pm_role_requirement pm_role_requirement_pkey; Type: CONSTRAINT; Schema: i2b2pm; Owner: postgres
--

ALTER TABLE ONLY i2b2pm.pm_role_requirement
    ADD CONSTRAINT pm_role_requirement_pkey PRIMARY KEY (table_cd, column_cd, read_hivemgmt_cd, write_hivemgmt_cd);


--
-- Name: pm_user_data pm_user_data_pkey; Type: CONSTRAINT; Schema: i2b2pm; Owner: postgres
--

ALTER TABLE ONLY i2b2pm.pm_user_data
    ADD CONSTRAINT pm_user_data_pkey PRIMARY KEY (user_id);


--
-- Name: pm_user_params pm_user_params_pkey; Type: CONSTRAINT; Schema: i2b2pm; Owner: postgres
--

ALTER TABLE ONLY i2b2pm.pm_user_params
    ADD CONSTRAINT pm_user_params_pkey PRIMARY KEY (id);


--
-- Name: pm_user_session pm_user_session_pkey; Type: CONSTRAINT; Schema: i2b2pm; Owner: postgres
--

ALTER TABLE ONLY i2b2pm.pm_user_session
    ADD CONSTRAINT pm_user_session_pkey PRIMARY KEY (session_id, user_id);


--
-- Name: workplace_access workplace_access_pk; Type: CONSTRAINT; Schema: i2b2workdata; Owner: postgres
--

ALTER TABLE ONLY i2b2workdata.workplace_access
    ADD CONSTRAINT workplace_access_pk PRIMARY KEY (c_index);


--
-- Name: workplace workplace_pk; Type: CONSTRAINT; Schema: i2b2workdata; Owner: postgres
--

ALTER TABLE ONLY i2b2workdata.workplace
    ADD CONSTRAINT workplace_pk PRIMARY KEY (c_index);


--
-- Name: cd_idx_uploadid; Type: INDEX; Schema: i2b2demodata; Owner: postgres
--

CREATE INDEX cd_idx_uploadid ON i2b2demodata.concept_dimension USING btree (upload_id);


--
-- Name: cl_idx_name_char; Type: INDEX; Schema: i2b2demodata; Owner: postgres
--

CREATE INDEX cl_idx_name_char ON i2b2demodata.code_lookup USING btree (name_char);


--
-- Name: cl_idx_uploadid; Type: INDEX; Schema: i2b2demodata; Owner: postgres
--

CREATE INDEX cl_idx_uploadid ON i2b2demodata.code_lookup USING btree (upload_id);


--
-- Name: em_encnum_idx; Type: INDEX; Schema: i2b2demodata; Owner: postgres
--

CREATE INDEX em_encnum_idx ON i2b2demodata.encounter_mapping USING btree (encounter_num);


--
-- Name: em_idx_encpath; Type: INDEX; Schema: i2b2demodata; Owner: postgres
--

CREATE INDEX em_idx_encpath ON i2b2demodata.encounter_mapping USING btree (encounter_ide, encounter_ide_source, patient_ide, patient_ide_source, encounter_num);


--
-- Name: em_idx_uploadid; Type: INDEX; Schema: i2b2demodata; Owner: postgres
--

CREATE INDEX em_idx_uploadid ON i2b2demodata.encounter_mapping USING btree (upload_id);


--
-- Name: md_idx_uploadid; Type: INDEX; Schema: i2b2demodata; Owner: postgres
--

CREATE INDEX md_idx_uploadid ON i2b2demodata.modifier_dimension USING btree (upload_id);


--
-- Name: of_idx_allobservation_fact; Type: INDEX; Schema: i2b2demodata; Owner: postgres
--

CREATE INDEX of_idx_allobservation_fact ON i2b2demodata.observation_fact USING btree (patient_num, encounter_num, concept_cd, start_date, provider_id, modifier_cd, instance_num, valtype_cd, tval_char, nval_num, valueflag_cd, quantity_num, units_cd, end_date, location_cd, confidence_num);


--
-- Name: of_idx_clusteredconcept; Type: INDEX; Schema: i2b2demodata; Owner: postgres
--

CREATE INDEX of_idx_clusteredconcept ON i2b2demodata.observation_fact USING btree (concept_cd);


--
-- Name: of_idx_encounter_patient; Type: INDEX; Schema: i2b2demodata; Owner: postgres
--

CREATE INDEX of_idx_encounter_patient ON i2b2demodata.observation_fact USING btree (encounter_num, patient_num, instance_num);


--
-- Name: of_idx_modifier; Type: INDEX; Schema: i2b2demodata; Owner: postgres
--

CREATE INDEX of_idx_modifier ON i2b2demodata.observation_fact USING btree (modifier_cd);


--
-- Name: of_idx_sourcesystem_cd; Type: INDEX; Schema: i2b2demodata; Owner: postgres
--

CREATE INDEX of_idx_sourcesystem_cd ON i2b2demodata.observation_fact USING btree (sourcesystem_cd);


--
-- Name: of_idx_start_date; Type: INDEX; Schema: i2b2demodata; Owner: postgres
--

CREATE INDEX of_idx_start_date ON i2b2demodata.observation_fact USING btree (start_date, patient_num);


--
-- Name: of_idx_uploadid; Type: INDEX; Schema: i2b2demodata; Owner: postgres
--

CREATE INDEX of_idx_uploadid ON i2b2demodata.observation_fact USING btree (upload_id);


--
-- Name: of_text_search_unique; Type: INDEX; Schema: i2b2demodata; Owner: postgres
--

CREATE UNIQUE INDEX of_text_search_unique ON i2b2demodata.observation_fact USING btree (text_search_index);


--
-- Name: pa_idx_uploadid; Type: INDEX; Schema: i2b2demodata; Owner: postgres
--

CREATE INDEX pa_idx_uploadid ON i2b2demodata.patient_dimension USING btree (upload_id);


--
-- Name: pd_idx_allpatientdim; Type: INDEX; Schema: i2b2demodata; Owner: postgres
--

CREATE INDEX pd_idx_allpatientdim ON i2b2demodata.patient_dimension USING btree (patient_num, vital_status_cd, birth_date, death_date, sex_cd, age_in_years_num, language_cd, race_cd, marital_status_cd, income_cd, religion_cd, zip_cd);


--
-- Name: pd_idx_dates; Type: INDEX; Schema: i2b2demodata; Owner: postgres
--

CREATE INDEX pd_idx_dates ON i2b2demodata.patient_dimension USING btree (patient_num, vital_status_cd, birth_date, death_date);


--
-- Name: pd_idx_name_char; Type: INDEX; Schema: i2b2demodata; Owner: postgres
--

CREATE INDEX pd_idx_name_char ON i2b2demodata.provider_dimension USING btree (provider_id, name_char);


--
-- Name: pd_idx_statecityzip; Type: INDEX; Schema: i2b2demodata; Owner: postgres
--

CREATE INDEX pd_idx_statecityzip ON i2b2demodata.patient_dimension USING btree (statecityzip_path, patient_num);


--
-- Name: pd_idx_uploadid; Type: INDEX; Schema: i2b2demodata; Owner: postgres
--

CREATE INDEX pd_idx_uploadid ON i2b2demodata.provider_dimension USING btree (upload_id);


--
-- Name: pk_archive_obsfact; Type: INDEX; Schema: i2b2demodata; Owner: postgres
--

CREATE INDEX pk_archive_obsfact ON i2b2demodata.archive_observation_fact USING btree (encounter_num, patient_num, concept_cd, provider_id, start_date, modifier_cd, archive_upload_id);


--
-- Name: pm_encpnum_idx; Type: INDEX; Schema: i2b2demodata; Owner: postgres
--

CREATE INDEX pm_encpnum_idx ON i2b2demodata.patient_mapping USING btree (patient_ide, patient_ide_source, patient_num);


--
-- Name: pm_idx_uploadid; Type: INDEX; Schema: i2b2demodata; Owner: postgres
--

CREATE INDEX pm_idx_uploadid ON i2b2demodata.patient_mapping USING btree (upload_id);


--
-- Name: pm_patnum_idx; Type: INDEX; Schema: i2b2demodata; Owner: postgres
--

CREATE INDEX pm_patnum_idx ON i2b2demodata.patient_mapping USING btree (patient_num);


--
-- Name: qt_apnamevergrp_idx; Type: INDEX; Schema: i2b2demodata; Owner: postgres
--

CREATE INDEX qt_apnamevergrp_idx ON i2b2demodata.qt_analysis_plugin USING btree (plugin_name, version_cd, group_id);


--
-- Name: qt_idx_pqm_ugid; Type: INDEX; Schema: i2b2demodata; Owner: postgres
--

CREATE INDEX qt_idx_pqm_ugid ON i2b2demodata.qt_pdo_query_master USING btree (user_id, group_id);


--
-- Name: qt_idx_qi_mstartid; Type: INDEX; Schema: i2b2demodata; Owner: postgres
--

CREATE INDEX qt_idx_qi_mstartid ON i2b2demodata.qt_query_instance USING btree (query_master_id, start_date);


--
-- Name: qt_idx_qi_ugid; Type: INDEX; Schema: i2b2demodata; Owner: postgres
--

CREATE INDEX qt_idx_qi_ugid ON i2b2demodata.qt_query_instance USING btree (user_id, group_id);


--
-- Name: qt_idx_qm_ugid; Type: INDEX; Schema: i2b2demodata; Owner: postgres
--

CREATE INDEX qt_idx_qm_ugid ON i2b2demodata.qt_query_master USING btree (user_id, group_id, master_type_cd);


--
-- Name: qt_idx_qpsc_riid; Type: INDEX; Schema: i2b2demodata; Owner: postgres
--

CREATE INDEX qt_idx_qpsc_riid ON i2b2demodata.qt_patient_set_collection USING btree (result_instance_id);


--
-- Name: vd_idx_allvisitdim; Type: INDEX; Schema: i2b2demodata; Owner: postgres
--

CREATE INDEX vd_idx_allvisitdim ON i2b2demodata.visit_dimension USING btree (encounter_num, patient_num, inout_cd, location_cd, start_date, length_of_stay, end_date);


--
-- Name: vd_idx_dates; Type: INDEX; Schema: i2b2demodata; Owner: postgres
--

CREATE INDEX vd_idx_dates ON i2b2demodata.visit_dimension USING btree (encounter_num, start_date, end_date);


--
-- Name: vd_idx_uploadid; Type: INDEX; Schema: i2b2demodata; Owner: postgres
--

CREATE INDEX vd_idx_uploadid ON i2b2demodata.visit_dimension USING btree (upload_id);


--
-- Name: crc_idx_aj_qnstid; Type: INDEX; Schema: i2b2hive; Owner: postgres
--

CREATE INDEX crc_idx_aj_qnstid ON i2b2hive.crc_analysis_job USING btree (queue_name, status_type_id);


--
-- Name: meta_appl_path_icd10_icd9_idx; Type: INDEX; Schema: i2b2metadata; Owner: postgres
--

CREATE INDEX meta_appl_path_icd10_icd9_idx ON i2b2metadata.icd10_icd9 USING btree (m_applied_path);


--
-- Name: meta_applied_path_idx_birn; Type: INDEX; Schema: i2b2metadata; Owner: postgres
--

CREATE INDEX meta_applied_path_idx_birn ON i2b2metadata.birn USING btree (m_applied_path);


--
-- Name: meta_applied_path_idx_custom; Type: INDEX; Schema: i2b2metadata; Owner: postgres
--

CREATE INDEX meta_applied_path_idx_custom ON i2b2metadata.custom_meta USING btree (m_applied_path);


--
-- Name: meta_applied_path_idx_i2b2; Type: INDEX; Schema: i2b2metadata; Owner: postgres
--

CREATE INDEX meta_applied_path_idx_i2b2 ON i2b2metadata.i2b2 USING btree (m_applied_path);


--
-- Name: meta_exclusion_icd10_icd9_idx; Type: INDEX; Schema: i2b2metadata; Owner: postgres
--

CREATE INDEX meta_exclusion_icd10_icd9_idx ON i2b2metadata.icd10_icd9 USING btree (m_exclusion_cd);


--
-- Name: meta_exclusion_idx_i2b2; Type: INDEX; Schema: i2b2metadata; Owner: postgres
--

CREATE INDEX meta_exclusion_idx_i2b2 ON i2b2metadata.i2b2 USING btree (m_exclusion_cd);


--
-- Name: meta_fullname_idx_birn; Type: INDEX; Schema: i2b2metadata; Owner: postgres
--

CREATE INDEX meta_fullname_idx_birn ON i2b2metadata.birn USING btree (c_fullname);


--
-- Name: meta_fullname_idx_custom; Type: INDEX; Schema: i2b2metadata; Owner: postgres
--

CREATE INDEX meta_fullname_idx_custom ON i2b2metadata.custom_meta USING btree (c_fullname);


--
-- Name: meta_fullname_idx_i2b2; Type: INDEX; Schema: i2b2metadata; Owner: postgres
--

CREATE INDEX meta_fullname_idx_i2b2 ON i2b2metadata.i2b2 USING btree (c_fullname);


--
-- Name: meta_fullname_idx_icd10_icd9; Type: INDEX; Schema: i2b2metadata; Owner: postgres
--

CREATE INDEX meta_fullname_idx_icd10_icd9 ON i2b2metadata.icd10_icd9 USING btree (c_fullname);


--
-- Name: meta_hlevel_icd10_icd9_idx; Type: INDEX; Schema: i2b2metadata; Owner: postgres
--

CREATE INDEX meta_hlevel_icd10_icd9_idx ON i2b2metadata.icd10_icd9 USING btree (c_hlevel);


--
-- Name: meta_hlevel_idx_i2b2; Type: INDEX; Schema: i2b2metadata; Owner: postgres
--

CREATE INDEX meta_hlevel_idx_i2b2 ON i2b2metadata.i2b2 USING btree (c_hlevel);


--
-- Name: meta_synonym_icd10_icd9_idx; Type: INDEX; Schema: i2b2metadata; Owner: postgres
--

CREATE INDEX meta_synonym_icd10_icd9_idx ON i2b2metadata.icd10_icd9 USING btree (c_synonym_cd);


--
-- Name: meta_synonym_idx_i2b2; Type: INDEX; Schema: i2b2metadata; Owner: postgres
--

CREATE INDEX meta_synonym_idx_i2b2 ON i2b2metadata.i2b2 USING btree (c_synonym_cd);


--
-- Name: totalnum_idx; Type: INDEX; Schema: i2b2metadata; Owner: postgres
--

CREATE INDEX totalnum_idx ON i2b2metadata.totalnum USING btree (c_fullname, agg_date, typeflag_cd);


--
-- Name: totalnum_report_idx; Type: INDEX; Schema: i2b2metadata; Owner: postgres
--

CREATE INDEX totalnum_report_idx ON i2b2metadata.totalnum_report USING btree (c_fullname);


--
-- Name: pm_user_login_idx; Type: INDEX; Schema: i2b2pm; Owner: postgres
--

CREATE INDEX pm_user_login_idx ON i2b2pm.pm_user_login USING btree (user_id, entry_date);


--
-- Name: set_upload_status fk_up_set_type_id; Type: FK CONSTRAINT; Schema: i2b2demodata; Owner: postgres
--

ALTER TABLE ONLY i2b2demodata.set_upload_status
    ADD CONSTRAINT fk_up_set_type_id FOREIGN KEY (set_type_id) REFERENCES i2b2demodata.set_type(id);


--
-- Name: qt_patient_enc_collection qt_fk_pesc_ri; Type: FK CONSTRAINT; Schema: i2b2demodata; Owner: postgres
--

ALTER TABLE ONLY i2b2demodata.qt_patient_enc_collection
    ADD CONSTRAINT qt_fk_pesc_ri FOREIGN KEY (result_instance_id) REFERENCES i2b2demodata.qt_query_result_instance(result_instance_id);


--
-- Name: qt_patient_set_collection qt_fk_psc_ri; Type: FK CONSTRAINT; Schema: i2b2demodata; Owner: postgres
--

ALTER TABLE ONLY i2b2demodata.qt_patient_set_collection
    ADD CONSTRAINT qt_fk_psc_ri FOREIGN KEY (result_instance_id) REFERENCES i2b2demodata.qt_query_result_instance(result_instance_id);


--
-- Name: qt_query_instance qt_fk_qi_mid; Type: FK CONSTRAINT; Schema: i2b2demodata; Owner: postgres
--

ALTER TABLE ONLY i2b2demodata.qt_query_instance
    ADD CONSTRAINT qt_fk_qi_mid FOREIGN KEY (query_master_id) REFERENCES i2b2demodata.qt_query_master(query_master_id);


--
-- Name: qt_query_instance qt_fk_qi_stid; Type: FK CONSTRAINT; Schema: i2b2demodata; Owner: postgres
--

ALTER TABLE ONLY i2b2demodata.qt_query_instance
    ADD CONSTRAINT qt_fk_qi_stid FOREIGN KEY (status_type_id) REFERENCES i2b2demodata.qt_query_status_type(status_type_id);


--
-- Name: qt_query_result_instance qt_fk_qri_rid; Type: FK CONSTRAINT; Schema: i2b2demodata; Owner: postgres
--

ALTER TABLE ONLY i2b2demodata.qt_query_result_instance
    ADD CONSTRAINT qt_fk_qri_rid FOREIGN KEY (query_instance_id) REFERENCES i2b2demodata.qt_query_instance(query_instance_id);


--
-- Name: qt_query_result_instance qt_fk_qri_rtid; Type: FK CONSTRAINT; Schema: i2b2demodata; Owner: postgres
--

ALTER TABLE ONLY i2b2demodata.qt_query_result_instance
    ADD CONSTRAINT qt_fk_qri_rtid FOREIGN KEY (result_type_id) REFERENCES i2b2demodata.qt_query_result_type(result_type_id);


--
-- Name: qt_query_result_instance qt_fk_qri_stid; Type: FK CONSTRAINT; Schema: i2b2demodata; Owner: postgres
--

ALTER TABLE ONLY i2b2demodata.qt_query_result_instance
    ADD CONSTRAINT qt_fk_qri_stid FOREIGN KEY (status_type_id) REFERENCES i2b2demodata.qt_query_status_type(status_type_id);


--
-- Name: qt_xml_result qt_fk_xmlr_riid; Type: FK CONSTRAINT; Schema: i2b2demodata; Owner: postgres
--

ALTER TABLE ONLY i2b2demodata.qt_xml_result
    ADD CONSTRAINT qt_fk_xmlr_riid FOREIGN KEY (result_instance_id) REFERENCES i2b2demodata.qt_query_result_instance(result_instance_id);


--
-- PostgreSQL database dump complete
--

