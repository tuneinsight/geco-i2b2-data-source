--
-- PostgreSQL database dump
--


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
-- Name: gecodatasourceplugintest; Type: SCHEMA; Schema: -; Owner: i2b2
--

CREATE SCHEMA gecodatasourceplugintest;


-- ALTER SCHEMA gecodatasourceplugintest OWNER TO i2b2;

--
-- Name: i2b2demodata; Type: SCHEMA; Schema: -; Owner: i2b2
--

CREATE SCHEMA i2b2demodata;


-- ALTER SCHEMA i2b2demodata OWNER TO i2b2;

--
-- Name: i2b2hive; Type: SCHEMA; Schema: -; Owner: i2b2
--

CREATE SCHEMA i2b2hive;


-- ALTER SCHEMA i2b2hive OWNER TO i2b2;

--
-- Name: i2b2imdata; Type: SCHEMA; Schema: -; Owner: i2b2
--

CREATE SCHEMA i2b2imdata;


-- ALTER SCHEMA i2b2imdata OWNER TO i2b2;

--
-- Name: i2b2metadata; Type: SCHEMA; Schema: -; Owner: i2b2
--

CREATE SCHEMA i2b2metadata;


-- ALTER SCHEMA i2b2metadata OWNER TO i2b2;

--
-- Name: i2b2pm; Type: SCHEMA; Schema: -; Owner: i2b2
--

CREATE SCHEMA i2b2pm;


-- ALTER SCHEMA i2b2pm OWNER TO i2b2;

--
-- Name: i2b2workdata; Type: SCHEMA; Schema: -; Owner: i2b2
--

CREATE SCHEMA i2b2workdata;


-- ALTER SCHEMA i2b2workdata OWNER TO i2b2;

--
-- Name: query_status; Type: TYPE; Schema: gecodatasourceplugintest; Owner: i2b2
--

CREATE TYPE gecodatasourceplugintest.query_status AS ENUM (
    'requested',
    'running',
    'success',
    'error'
);


-- ALTER TYPE gecodatasourceplugintest.query_status OWNER TO i2b2;

--
-- Name: censoring_event(integer[], character varying[], character varying[]); Type: FUNCTION; Schema: i2b2demodata; Owner: i2b2
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


-- ALTER FUNCTION i2b2demodata.censoring_event(patient_list integer[], end_code character varying[], end_modifier_code character varying[]) OWNER TO i2b2;

--
-- Name: create_temp_concept_table(text); Type: FUNCTION; Schema: i2b2demodata; Owner: i2b2
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


-- ALTER FUNCTION i2b2demodata.create_temp_concept_table(tempconcepttablename text, OUT errormsg text) OWNER TO i2b2;

--
-- Name: create_temp_eid_table(text); Type: FUNCTION; Schema: i2b2demodata; Owner: i2b2
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


-- ALTER FUNCTION i2b2demodata.create_temp_eid_table(temppatientmappingtablename text, OUT errormsg text) OWNER TO i2b2;

--
-- Name: create_temp_modifier_table(text); Type: FUNCTION; Schema: i2b2demodata; Owner: i2b2
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


-- ALTER FUNCTION i2b2demodata.create_temp_modifier_table(tempmodifiertablename text, OUT errormsg text) OWNER TO i2b2;

--
-- Name: create_temp_patient_table(text); Type: FUNCTION; Schema: i2b2demodata; Owner: i2b2
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


-- ALTER FUNCTION i2b2demodata.create_temp_patient_table(temppatientdimensiontablename text, OUT errormsg text) OWNER TO i2b2;

--
-- Name: create_temp_pid_table(text); Type: FUNCTION; Schema: i2b2demodata; Owner: i2b2
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


-- ALTER FUNCTION i2b2demodata.create_temp_pid_table(temppatientmappingtablename text, OUT errormsg text) OWNER TO i2b2;

--
-- Name: create_temp_provider_table(text); Type: FUNCTION; Schema: i2b2demodata; Owner: i2b2
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


-- ALTER FUNCTION i2b2demodata.create_temp_provider_table(tempprovidertablename text, OUT errormsg text) OWNER TO i2b2;

--
-- Name: create_temp_table(text); Type: FUNCTION; Schema: i2b2demodata; Owner: i2b2
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


-- ALTER FUNCTION i2b2demodata.create_temp_table(temptablename text, OUT errormsg text) OWNER TO i2b2;

--
-- Name: create_temp_visit_table(text); Type: FUNCTION; Schema: i2b2demodata; Owner: i2b2
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


-- ALTER FUNCTION i2b2demodata.create_temp_visit_table(temptablename text, OUT errormsg text) OWNER TO i2b2;

--
-- Name: end_events(integer[], character varying[], character varying[]); Type: FUNCTION; Schema: i2b2demodata; Owner: i2b2
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


-- ALTER FUNCTION i2b2demodata.end_events(patient_list integer[], end_code character varying[], end_modifier_code character varying[]) OWNER TO i2b2;

--
-- Name: insert_concept_fromtemp(text, bigint); Type: FUNCTION; Schema: i2b2demodata; Owner: i2b2
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


-- ALTER FUNCTION i2b2demodata.insert_concept_fromtemp(tempconcepttablename text, upload_id bigint, OUT errormsg text) OWNER TO i2b2;

--
-- Name: insert_eid_map_fromtemp(text, bigint); Type: FUNCTION; Schema: i2b2demodata; Owner: i2b2
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


-- ALTER FUNCTION i2b2demodata.insert_eid_map_fromtemp(tempeidtablename text, upload_id bigint, OUT errormsg text) OWNER TO i2b2;

--
-- Name: insert_encountervisit_fromtemp(text, bigint); Type: FUNCTION; Schema: i2b2demodata; Owner: i2b2
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


-- ALTER FUNCTION i2b2demodata.insert_encountervisit_fromtemp(temptablename text, upload_id bigint, OUT errormsg text) OWNER TO i2b2;

--
-- Name: insert_modifier_fromtemp(text, bigint); Type: FUNCTION; Schema: i2b2demodata; Owner: i2b2
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


-- ALTER FUNCTION i2b2demodata.insert_modifier_fromtemp(tempmodifiertablename text, upload_id bigint, OUT errormsg text) OWNER TO i2b2;

--
-- Name: insert_patient_fromtemp(text, bigint); Type: FUNCTION; Schema: i2b2demodata; Owner: i2b2
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


-- ALTER FUNCTION i2b2demodata.insert_patient_fromtemp(temptablename text, upload_id bigint, OUT errormsg text) OWNER TO i2b2;

--
-- Name: insert_patient_map_fromtemp(text, bigint); Type: FUNCTION; Schema: i2b2demodata; Owner: i2b2
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


-- ALTER FUNCTION i2b2demodata.insert_patient_map_fromtemp(temppatienttablename text, upload_id bigint, OUT errormsg text) OWNER TO i2b2;

--
-- Name: insert_pid_map_fromtemp(text, bigint); Type: FUNCTION; Schema: i2b2demodata; Owner: i2b2
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


-- ALTER FUNCTION i2b2demodata.insert_pid_map_fromtemp(temppidtablename text, upload_id bigint, OUT errormsg text) OWNER TO i2b2;

--
-- Name: insert_provider_fromtemp(text, bigint); Type: FUNCTION; Schema: i2b2demodata; Owner: i2b2
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


-- ALTER FUNCTION i2b2demodata.insert_provider_fromtemp(tempprovidertablename text, upload_id bigint, OUT errormsg text) OWNER TO i2b2;

--
-- Name: remove_temp_table(character varying); Type: FUNCTION; Schema: i2b2demodata; Owner: i2b2
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


-- ALTER FUNCTION i2b2demodata.remove_temp_table(temptablename character varying, OUT errormsg text) OWNER TO i2b2;

--
-- Name: start_event(integer[], character varying[], character varying[], boolean); Type: FUNCTION; Schema: i2b2demodata; Owner: i2b2
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


-- ALTER FUNCTION i2b2demodata.start_event(patient_list integer[], start_code character varying[], start_modifier_code character varying[], start_earliest boolean) OWNER TO i2b2;

--
-- Name: sync_clear_concept_table(text, text, bigint); Type: FUNCTION; Schema: i2b2demodata; Owner: i2b2
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


-- ALTER FUNCTION i2b2demodata.sync_clear_concept_table(tempconcepttablename text, backupconcepttablename text, uploadid bigint, OUT errormsg text) OWNER TO i2b2;

--
-- Name: sync_clear_modifier_table(text, text, bigint); Type: FUNCTION; Schema: i2b2demodata; Owner: i2b2
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


-- ALTER FUNCTION i2b2demodata.sync_clear_modifier_table(tempmodifiertablename text, backupmodifiertablename text, uploadid bigint, OUT errormsg text) OWNER TO i2b2;

--
-- Name: sync_clear_provider_table(text, text, bigint); Type: FUNCTION; Schema: i2b2demodata; Owner: i2b2
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


-- ALTER FUNCTION i2b2demodata.sync_clear_provider_table(tempprovidertablename text, backupprovidertablename text, uploadid bigint, OUT errormsg text) OWNER TO i2b2;

--
-- Name: update_observation_fact(text, bigint, bigint); Type: FUNCTION; Schema: i2b2demodata; Owner: i2b2
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


-- ALTER FUNCTION i2b2demodata.update_observation_fact(upload_temptable_name text, upload_id bigint, appendflag bigint, OUT errormsg text) OWNER TO i2b2;

--
-- Name: buildtotalnumreport(integer, double precision); Type: FUNCTION; Schema: i2b2metadata; Owner: i2b2
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


-- ALTER FUNCTION i2b2metadata.buildtotalnumreport(threshold integer, sigma double precision) OWNER TO i2b2;

--
-- Name: get_concept_codes(character varying, character varying); Type: FUNCTION; Schema: i2b2metadata; Owner: i2b2
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


-- ALTER FUNCTION i2b2metadata.get_concept_codes(ontology character varying, path character varying) OWNER TO i2b2;

--
-- Name: get_modifier_codes(character varying, character varying, character varying); Type: FUNCTION; Schema: i2b2metadata; Owner: i2b2
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


-- ALTER FUNCTION i2b2metadata.get_modifier_codes(ontology character varying, path character varying, applied_path character varying) OWNER TO i2b2;

--
-- Name: get_ontology_elements(character varying, integer); Type: FUNCTION; Schema: i2b2metadata; Owner: i2b2
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


-- ALTER FUNCTION i2b2metadata.get_ontology_elements(search_string character varying, lim integer) OWNER TO i2b2;

--
-- Name: pat_count_dimensions(character varying, character varying, character varying, character varying, character varying, character varying); Type: FUNCTION; Schema: i2b2metadata; Owner: i2b2
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


-- ALTER FUNCTION i2b2metadata.pat_count_dimensions(metadatatable character varying, schemaname character varying, observationtable character varying, facttablecolumn character varying, tablename character varying, columnname character varying) OWNER TO i2b2;

--
-- Name: pat_count_visits(character varying, character varying); Type: FUNCTION; Schema: i2b2metadata; Owner: i2b2
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


-- ALTER FUNCTION i2b2metadata.pat_count_visits(tabname character varying, tableschema character varying) OWNER TO i2b2;

--
-- Name: random_normal(double precision, double precision, integer); Type: FUNCTION; Schema: i2b2metadata; Owner: i2b2
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


-- ALTER FUNCTION i2b2metadata.random_normal(mean double precision, stddev double precision, threshold integer) OWNER TO i2b2;

--
-- Name: runtotalnum(text, text, text); Type: FUNCTION; Schema: i2b2metadata; Owner: i2b2
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


-- ALTER FUNCTION i2b2metadata.runtotalnum(observationtable text, schemaname text, tablename text) OWNER TO i2b2;

--
-- Name: table_name(character varying); Type: FUNCTION; Schema: i2b2metadata; Owner: i2b2
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


-- ALTER FUNCTION i2b2metadata.table_name(table_cd character varying) OWNER TO i2b2;

--
-- Name: create_gecoi2b2datasource_schema(name, name); Type: FUNCTION; Schema: public; Owner: i2b2
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


-- ALTER FUNCTION public.create_gecoi2b2datasource_schema(schema_name name, user_name name) OWNER TO i2b2;

--
-- Name: delete_gecoi2b2datasource_schema(name); Type: FUNCTION; Schema: public; Owner: i2b2
--

CREATE FUNCTION public.delete_gecoi2b2datasource_schema(schema_name name) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
	BEGIN
		EXECUTE 'DROP SCHEMA ' || schema_name || ' CASCADE';
		RETURN true;
	END;
$$;


-- ALTER FUNCTION public.delete_gecoi2b2datasource_schema(schema_name name) OWNER TO i2b2;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: explore_query; Type: TABLE; Schema: gecodatasourceplugintest; Owner: i2b2
--

CREATE TABLE gecodatasourceplugintest.explore_query (
    id uuid NOT NULL,
    create_date timestamp without time zone NOT NULL,
    user_id character varying(255) NOT NULL,
    status gecodatasourceplugintest.query_status NOT NULL,
    definition text NOT NULL,
    result_i2b2_patient_set_id integer,
    result_geco_shared_id_count uuid,
    result_geco_shared_id_patient_list uuid
);


-- ALTER TABLE gecodatasourceplugintest.explore_query OWNER TO i2b2;

--
-- Name: saved_cohort; Type: TABLE; Schema: gecodatasourceplugintest; Owner: i2b2
--

CREATE TABLE gecodatasourceplugintest.saved_cohort (
    name character varying(255) NOT NULL,
    create_date timestamp without time zone NOT NULL,
    explore_query_id uuid NOT NULL
);


-- ALTER TABLE gecodatasourceplugintest.saved_cohort OWNER TO i2b2;

--
-- Name: archive_observation_fact; Type: TABLE; Schema: i2b2demodata; Owner: i2b2
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


-- ALTER TABLE i2b2demodata.archive_observation_fact OWNER TO i2b2;

--
-- Name: code_lookup; Type: TABLE; Schema: i2b2demodata; Owner: i2b2
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


-- ALTER TABLE i2b2demodata.code_lookup OWNER TO i2b2;

--
-- Name: concept_dimension; Type: TABLE; Schema: i2b2demodata; Owner: i2b2
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


-- ALTER TABLE i2b2demodata.concept_dimension OWNER TO i2b2;

--
-- Name: datamart_report; Type: TABLE; Schema: i2b2demodata; Owner: i2b2
--

CREATE TABLE i2b2demodata.datamart_report (
    total_patient integer,
    total_observationfact integer,
    total_event integer,
    report_date timestamp without time zone
);


-- ALTER TABLE i2b2demodata.datamart_report OWNER TO i2b2;

--
-- Name: encounter_mapping; Type: TABLE; Schema: i2b2demodata; Owner: i2b2
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


-- ALTER TABLE i2b2demodata.encounter_mapping OWNER TO i2b2;

--
-- Name: modifier_dimension; Type: TABLE; Schema: i2b2demodata; Owner: i2b2
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


-- ALTER TABLE i2b2demodata.modifier_dimension OWNER TO i2b2;

--
-- Name: observation_fact; Type: TABLE; Schema: i2b2demodata; Owner: i2b2
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


-- ALTER TABLE i2b2demodata.observation_fact OWNER TO i2b2;

--
-- Name: observation_fact_text_search_index_seq; Type: SEQUENCE; Schema: i2b2demodata; Owner: i2b2
--

CREATE SEQUENCE i2b2demodata.observation_fact_text_search_index_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


-- ALTER TABLE i2b2demodata.observation_fact_text_search_index_seq OWNER TO i2b2;

--
-- Name: observation_fact_text_search_index_seq; Type: SEQUENCE OWNED BY; Schema: i2b2demodata; Owner: i2b2
--

ALTER SEQUENCE i2b2demodata.observation_fact_text_search_index_seq OWNED BY i2b2demodata.observation_fact.text_search_index;


--
-- Name: patient_dimension; Type: TABLE; Schema: i2b2demodata; Owner: i2b2
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


-- ALTER TABLE i2b2demodata.patient_dimension OWNER TO i2b2;

--
-- Name: patient_mapping; Type: TABLE; Schema: i2b2demodata; Owner: i2b2
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


-- ALTER TABLE i2b2demodata.patient_mapping OWNER TO i2b2;

--
-- Name: provider_dimension; Type: TABLE; Schema: i2b2demodata; Owner: i2b2
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


-- ALTER TABLE i2b2demodata.provider_dimension OWNER TO i2b2;

--
-- Name: qt_analysis_plugin; Type: TABLE; Schema: i2b2demodata; Owner: i2b2
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


-- ALTER TABLE i2b2demodata.qt_analysis_plugin OWNER TO i2b2;

--
-- Name: qt_analysis_plugin_result_type; Type: TABLE; Schema: i2b2demodata; Owner: i2b2
--

CREATE TABLE i2b2demodata.qt_analysis_plugin_result_type (
    plugin_id integer NOT NULL,
    result_type_id integer NOT NULL
);


-- ALTER TABLE i2b2demodata.qt_analysis_plugin_result_type OWNER TO i2b2;

--
-- Name: qt_breakdown_path; Type: TABLE; Schema: i2b2demodata; Owner: i2b2
--

CREATE TABLE i2b2demodata.qt_breakdown_path (
    name character varying(100),
    value character varying(2000),
    create_date timestamp without time zone,
    update_date timestamp without time zone,
    user_id character varying(50)
);


-- ALTER TABLE i2b2demodata.qt_breakdown_path OWNER TO i2b2;

--
-- Name: qt_patient_enc_collection; Type: TABLE; Schema: i2b2demodata; Owner: i2b2
--

CREATE TABLE i2b2demodata.qt_patient_enc_collection (
    patient_enc_coll_id bigint NOT NULL,
    result_instance_id integer,
    set_index integer,
    patient_num integer,
    encounter_num integer
);


-- ALTER TABLE i2b2demodata.qt_patient_enc_collection OWNER TO i2b2;

--
-- Name: qt_patient_enc_collection_patient_enc_coll_id_seq; Type: SEQUENCE; Schema: i2b2demodata; Owner: i2b2
--

CREATE SEQUENCE i2b2demodata.qt_patient_enc_collection_patient_enc_coll_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


-- ALTER TABLE i2b2demodata.qt_patient_enc_collection_patient_enc_coll_id_seq OWNER TO i2b2;

--
-- Name: qt_patient_enc_collection_patient_enc_coll_id_seq; Type: SEQUENCE OWNED BY; Schema: i2b2demodata; Owner: i2b2
--

ALTER SEQUENCE i2b2demodata.qt_patient_enc_collection_patient_enc_coll_id_seq OWNED BY i2b2demodata.qt_patient_enc_collection.patient_enc_coll_id;


--
-- Name: qt_patient_set_collection; Type: TABLE; Schema: i2b2demodata; Owner: i2b2
--

CREATE TABLE i2b2demodata.qt_patient_set_collection (
    patient_set_coll_id bigint NOT NULL,
    result_instance_id integer,
    set_index integer,
    patient_num integer
);


-- ALTER TABLE i2b2demodata.qt_patient_set_collection OWNER TO i2b2;

--
-- Name: qt_patient_set_collection_patient_set_coll_id_seq; Type: SEQUENCE; Schema: i2b2demodata; Owner: i2b2
--

CREATE SEQUENCE i2b2demodata.qt_patient_set_collection_patient_set_coll_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


-- ALTER TABLE i2b2demodata.qt_patient_set_collection_patient_set_coll_id_seq OWNER TO i2b2;

--
-- Name: qt_patient_set_collection_patient_set_coll_id_seq; Type: SEQUENCE OWNED BY; Schema: i2b2demodata; Owner: i2b2
--

ALTER SEQUENCE i2b2demodata.qt_patient_set_collection_patient_set_coll_id_seq OWNED BY i2b2demodata.qt_patient_set_collection.patient_set_coll_id;


--
-- Name: qt_pdo_query_master; Type: TABLE; Schema: i2b2demodata; Owner: i2b2
--

CREATE TABLE i2b2demodata.qt_pdo_query_master (
    query_master_id integer NOT NULL,
    user_id character varying(50) NOT NULL,
    group_id character varying(50) NOT NULL,
    create_date timestamp without time zone NOT NULL,
    request_xml text,
    i2b2_request_xml text
);


-- ALTER TABLE i2b2demodata.qt_pdo_query_master OWNER TO i2b2;

--
-- Name: qt_pdo_query_master_query_master_id_seq; Type: SEQUENCE; Schema: i2b2demodata; Owner: i2b2
--

CREATE SEQUENCE i2b2demodata.qt_pdo_query_master_query_master_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


-- ALTER TABLE i2b2demodata.qt_pdo_query_master_query_master_id_seq OWNER TO i2b2;

--
-- Name: qt_pdo_query_master_query_master_id_seq; Type: SEQUENCE OWNED BY; Schema: i2b2demodata; Owner: i2b2
--

ALTER SEQUENCE i2b2demodata.qt_pdo_query_master_query_master_id_seq OWNED BY i2b2demodata.qt_pdo_query_master.query_master_id;


--
-- Name: qt_privilege; Type: TABLE; Schema: i2b2demodata; Owner: i2b2
--

CREATE TABLE i2b2demodata.qt_privilege (
    protection_label_cd character varying(1500) NOT NULL,
    dataprot_cd character varying(1000),
    hivemgmt_cd character varying(1000),
    plugin_id integer
);


-- ALTER TABLE i2b2demodata.qt_privilege OWNER TO i2b2;

--
-- Name: qt_query_instance; Type: TABLE; Schema: i2b2demodata; Owner: i2b2
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


-- ALTER TABLE i2b2demodata.qt_query_instance OWNER TO i2b2;

--
-- Name: qt_query_instance_query_instance_id_seq; Type: SEQUENCE; Schema: i2b2demodata; Owner: i2b2
--

CREATE SEQUENCE i2b2demodata.qt_query_instance_query_instance_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


-- ALTER TABLE i2b2demodata.qt_query_instance_query_instance_id_seq OWNER TO i2b2;

--
-- Name: qt_query_instance_query_instance_id_seq; Type: SEQUENCE OWNED BY; Schema: i2b2demodata; Owner: i2b2
--

ALTER SEQUENCE i2b2demodata.qt_query_instance_query_instance_id_seq OWNED BY i2b2demodata.qt_query_instance.query_instance_id;


--
-- Name: qt_query_master; Type: TABLE; Schema: i2b2demodata; Owner: i2b2
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


-- ALTER TABLE i2b2demodata.qt_query_master OWNER TO i2b2;

--
-- Name: qt_query_master_query_master_id_seq; Type: SEQUENCE; Schema: i2b2demodata; Owner: i2b2
--

CREATE SEQUENCE i2b2demodata.qt_query_master_query_master_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


-- ALTER TABLE i2b2demodata.qt_query_master_query_master_id_seq OWNER TO i2b2;

--
-- Name: qt_query_master_query_master_id_seq; Type: SEQUENCE OWNED BY; Schema: i2b2demodata; Owner: i2b2
--

ALTER SEQUENCE i2b2demodata.qt_query_master_query_master_id_seq OWNED BY i2b2demodata.qt_query_master.query_master_id;


--
-- Name: qt_query_result_instance; Type: TABLE; Schema: i2b2demodata; Owner: i2b2
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


-- ALTER TABLE i2b2demodata.qt_query_result_instance OWNER TO i2b2;

--
-- Name: qt_query_result_instance_result_instance_id_seq; Type: SEQUENCE; Schema: i2b2demodata; Owner: i2b2
--

CREATE SEQUENCE i2b2demodata.qt_query_result_instance_result_instance_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


-- ALTER TABLE i2b2demodata.qt_query_result_instance_result_instance_id_seq OWNER TO i2b2;

--
-- Name: qt_query_result_instance_result_instance_id_seq; Type: SEQUENCE OWNED BY; Schema: i2b2demodata; Owner: i2b2
--

ALTER SEQUENCE i2b2demodata.qt_query_result_instance_result_instance_id_seq OWNED BY i2b2demodata.qt_query_result_instance.result_instance_id;


--
-- Name: qt_query_result_type; Type: TABLE; Schema: i2b2demodata; Owner: i2b2
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


-- ALTER TABLE i2b2demodata.qt_query_result_type OWNER TO i2b2;

--
-- Name: qt_query_status_type; Type: TABLE; Schema: i2b2demodata; Owner: i2b2
--

CREATE TABLE i2b2demodata.qt_query_status_type (
    status_type_id integer NOT NULL,
    name character varying(100),
    description character varying(200)
);


-- ALTER TABLE i2b2demodata.qt_query_status_type OWNER TO i2b2;

--
-- Name: qt_xml_result; Type: TABLE; Schema: i2b2demodata; Owner: i2b2
--

CREATE TABLE i2b2demodata.qt_xml_result (
    xml_result_id integer NOT NULL,
    result_instance_id integer,
    xml_value text
);


-- ALTER TABLE i2b2demodata.qt_xml_result OWNER TO i2b2;

--
-- Name: qt_xml_result_xml_result_id_seq; Type: SEQUENCE; Schema: i2b2demodata; Owner: i2b2
--

CREATE SEQUENCE i2b2demodata.qt_xml_result_xml_result_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


-- ALTER TABLE i2b2demodata.qt_xml_result_xml_result_id_seq OWNER TO i2b2;

--
-- Name: qt_xml_result_xml_result_id_seq; Type: SEQUENCE OWNED BY; Schema: i2b2demodata; Owner: i2b2
--

ALTER SEQUENCE i2b2demodata.qt_xml_result_xml_result_id_seq OWNED BY i2b2demodata.qt_xml_result.xml_result_id;


--
-- Name: set_type; Type: TABLE; Schema: i2b2demodata; Owner: i2b2
--

CREATE TABLE i2b2demodata.set_type (
    id integer NOT NULL,
    name character varying(500),
    create_date timestamp without time zone
);


-- ALTER TABLE i2b2demodata.set_type OWNER TO i2b2;

--
-- Name: set_upload_status; Type: TABLE; Schema: i2b2demodata; Owner: i2b2
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


-- ALTER TABLE i2b2demodata.set_upload_status OWNER TO i2b2;

--
-- Name: source_master; Type: TABLE; Schema: i2b2demodata; Owner: i2b2
--

CREATE TABLE i2b2demodata.source_master (
    source_cd character varying(50) NOT NULL,
    description character varying(300),
    create_date timestamp without time zone
);


-- ALTER TABLE i2b2demodata.source_master OWNER TO i2b2;

--
-- Name: upload_status; Type: TABLE; Schema: i2b2demodata; Owner: i2b2
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


-- ALTER TABLE i2b2demodata.upload_status OWNER TO i2b2;

--
-- Name: upload_status_upload_id_seq; Type: SEQUENCE; Schema: i2b2demodata; Owner: i2b2
--

CREATE SEQUENCE i2b2demodata.upload_status_upload_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


-- ALTER TABLE i2b2demodata.upload_status_upload_id_seq OWNER TO i2b2;

--
-- Name: upload_status_upload_id_seq; Type: SEQUENCE OWNED BY; Schema: i2b2demodata; Owner: i2b2
--

ALTER SEQUENCE i2b2demodata.upload_status_upload_id_seq OWNED BY i2b2demodata.upload_status.upload_id;


--
-- Name: visit_dimension; Type: TABLE; Schema: i2b2demodata; Owner: i2b2
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


-- ALTER TABLE i2b2demodata.visit_dimension OWNER TO i2b2;

--
-- Name: crc_analysis_job; Type: TABLE; Schema: i2b2hive; Owner: i2b2
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


-- ALTER TABLE i2b2hive.crc_analysis_job OWNER TO i2b2;

--
-- Name: crc_db_lookup; Type: TABLE; Schema: i2b2hive; Owner: i2b2
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


-- ALTER TABLE i2b2hive.crc_db_lookup OWNER TO i2b2;

--
-- Name: hive_cell_params; Type: TABLE; Schema: i2b2hive; Owner: i2b2
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


-- ALTER TABLE i2b2hive.hive_cell_params OWNER TO i2b2;

--
-- Name: im_db_lookup; Type: TABLE; Schema: i2b2hive; Owner: i2b2
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


-- ALTER TABLE i2b2hive.im_db_lookup OWNER TO i2b2;

--
-- Name: ont_db_lookup; Type: TABLE; Schema: i2b2hive; Owner: i2b2
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


-- ALTER TABLE i2b2hive.ont_db_lookup OWNER TO i2b2;

--
-- Name: work_db_lookup; Type: TABLE; Schema: i2b2hive; Owner: i2b2
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


-- ALTER TABLE i2b2hive.work_db_lookup OWNER TO i2b2;

--
-- Name: im_audit; Type: TABLE; Schema: i2b2imdata; Owner: i2b2
--

CREATE TABLE i2b2imdata.im_audit (
    query_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    lcl_site character varying(50) NOT NULL,
    lcl_id character varying(200) NOT NULL,
    user_id character varying(50) NOT NULL,
    project_id character varying(50) NOT NULL,
    comments text
);


-- ALTER TABLE i2b2imdata.im_audit OWNER TO i2b2;

--
-- Name: im_mpi_demographics; Type: TABLE; Schema: i2b2imdata; Owner: i2b2
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


-- ALTER TABLE i2b2imdata.im_mpi_demographics OWNER TO i2b2;

--
-- Name: im_mpi_mapping; Type: TABLE; Schema: i2b2imdata; Owner: i2b2
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


-- ALTER TABLE i2b2imdata.im_mpi_mapping OWNER TO i2b2;

--
-- Name: im_project_patients; Type: TABLE; Schema: i2b2imdata; Owner: i2b2
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


-- ALTER TABLE i2b2imdata.im_project_patients OWNER TO i2b2;

--
-- Name: im_project_sites; Type: TABLE; Schema: i2b2imdata; Owner: i2b2
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


-- ALTER TABLE i2b2imdata.im_project_sites OWNER TO i2b2;

--
-- Name: birn; Type: TABLE; Schema: i2b2metadata; Owner: i2b2
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


-- ALTER TABLE i2b2metadata.birn OWNER TO i2b2;

--
-- Name: custom_meta; Type: TABLE; Schema: i2b2metadata; Owner: i2b2
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


-- ALTER TABLE i2b2metadata.custom_meta OWNER TO i2b2;

--
-- Name: i2b2; Type: TABLE; Schema: i2b2metadata; Owner: i2b2
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


-- ALTER TABLE i2b2metadata.i2b2 OWNER TO i2b2;

--
-- Name: icd10_icd9; Type: TABLE; Schema: i2b2metadata; Owner: i2b2
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


-- ALTER TABLE i2b2metadata.icd10_icd9 OWNER TO i2b2;

--
-- Name: ont_process_status; Type: TABLE; Schema: i2b2metadata; Owner: i2b2
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


-- ALTER TABLE i2b2metadata.ont_process_status OWNER TO i2b2;

--
-- Name: ont_process_status_process_id_seq; Type: SEQUENCE; Schema: i2b2metadata; Owner: i2b2
--

CREATE SEQUENCE i2b2metadata.ont_process_status_process_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


-- ALTER TABLE i2b2metadata.ont_process_status_process_id_seq OWNER TO i2b2;

--
-- Name: ont_process_status_process_id_seq; Type: SEQUENCE OWNED BY; Schema: i2b2metadata; Owner: i2b2
--

ALTER SEQUENCE i2b2metadata.ont_process_status_process_id_seq OWNED BY i2b2metadata.ont_process_status.process_id;


--
-- Name: schemes; Type: TABLE; Schema: i2b2metadata; Owner: i2b2
--

CREATE TABLE i2b2metadata.schemes (
    c_key character varying(50) NOT NULL,
    c_name character varying(50) NOT NULL,
    c_description character varying(100)
);


-- ALTER TABLE i2b2metadata.schemes OWNER TO i2b2;

--
-- Name: sphn; Type: TABLE; Schema: i2b2metadata; Owner: i2b2
--

CREATE TABLE i2b2metadata.sphn (
    c_hlevel numeric(22,0),
    c_fullname character varying(2000),
    c_name character varying(1000),
    c_synonym_cd character(1),
    c_visualattributes character(3),
    c_basecode character varying(450),
    c_facttablecolumn character varying(50),
    c_tablename character varying(50),
    c_columnname character varying(50),
    c_columndatatype character varying(50),
    c_operator character varying(10),
    c_comment text,
    c_dimcode character varying(2000),
    c_tooltip character varying(1000),
    m_applied_path character varying(2000),
    c_totalnum numeric(22,0),
    update_date date,
    download_date date,
    import_date date,
    sourcesystem_cd character varying(50),
    valuetype_cd character varying(50),
    m_exclusion_cd character varying(1000),
    c_path character varying(2000),
    c_symbol character varying(50),
    c_metadataxml text
);


-- ALTER TABLE i2b2metadata.sphn OWNER TO i2b2;

--
-- Name: table_access; Type: TABLE; Schema: i2b2metadata; Owner: i2b2
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


-- ALTER TABLE i2b2metadata.table_access OWNER TO i2b2;

--
-- Name: test; Type: TABLE; Schema: i2b2metadata; Owner: i2b2
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


-- ALTER TABLE i2b2metadata.test OWNER TO i2b2;

--
-- Name: totalnum; Type: TABLE; Schema: i2b2metadata; Owner: i2b2
--

CREATE TABLE i2b2metadata.totalnum (
    c_fullname character varying(850),
    agg_date date,
    agg_count integer,
    typeflag_cd character varying(3)
);


-- ALTER TABLE i2b2metadata.totalnum OWNER TO i2b2;

--
-- Name: totalnum_report; Type: TABLE; Schema: i2b2metadata; Owner: i2b2
--

CREATE TABLE i2b2metadata.totalnum_report (
    c_fullname character varying(850),
    agg_date character varying(50),
    agg_count integer
);


-- ALTER TABLE i2b2metadata.totalnum_report OWNER TO i2b2;

--
-- Name: pm_approvals; Type: TABLE; Schema: i2b2pm; Owner: i2b2
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


-- ALTER TABLE i2b2pm.pm_approvals OWNER TO i2b2;

--
-- Name: pm_approvals_params; Type: TABLE; Schema: i2b2pm; Owner: i2b2
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


-- ALTER TABLE i2b2pm.pm_approvals_params OWNER TO i2b2;

--
-- Name: pm_approvals_params_id_seq; Type: SEQUENCE; Schema: i2b2pm; Owner: i2b2
--

CREATE SEQUENCE i2b2pm.pm_approvals_params_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


-- ALTER TABLE i2b2pm.pm_approvals_params_id_seq OWNER TO i2b2;

--
-- Name: pm_approvals_params_id_seq; Type: SEQUENCE OWNED BY; Schema: i2b2pm; Owner: i2b2
--

ALTER SEQUENCE i2b2pm.pm_approvals_params_id_seq OWNED BY i2b2pm.pm_approvals_params.id;


--
-- Name: pm_cell_data; Type: TABLE; Schema: i2b2pm; Owner: i2b2
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


-- ALTER TABLE i2b2pm.pm_cell_data OWNER TO i2b2;

--
-- Name: pm_cell_params; Type: TABLE; Schema: i2b2pm; Owner: i2b2
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


-- ALTER TABLE i2b2pm.pm_cell_params OWNER TO i2b2;

--
-- Name: pm_cell_params_id_seq; Type: SEQUENCE; Schema: i2b2pm; Owner: i2b2
--

CREATE SEQUENCE i2b2pm.pm_cell_params_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


-- ALTER TABLE i2b2pm.pm_cell_params_id_seq OWNER TO i2b2;

--
-- Name: pm_cell_params_id_seq; Type: SEQUENCE OWNED BY; Schema: i2b2pm; Owner: i2b2
--

ALTER SEQUENCE i2b2pm.pm_cell_params_id_seq OWNED BY i2b2pm.pm_cell_params.id;


--
-- Name: pm_global_params; Type: TABLE; Schema: i2b2pm; Owner: i2b2
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


-- ALTER TABLE i2b2pm.pm_global_params OWNER TO i2b2;

--
-- Name: pm_global_params_id_seq; Type: SEQUENCE; Schema: i2b2pm; Owner: i2b2
--

CREATE SEQUENCE i2b2pm.pm_global_params_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


-- ALTER TABLE i2b2pm.pm_global_params_id_seq OWNER TO i2b2;

--
-- Name: pm_global_params_id_seq; Type: SEQUENCE OWNED BY; Schema: i2b2pm; Owner: i2b2
--

ALTER SEQUENCE i2b2pm.pm_global_params_id_seq OWNED BY i2b2pm.pm_global_params.id;


--
-- Name: pm_hive_data; Type: TABLE; Schema: i2b2pm; Owner: i2b2
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


-- ALTER TABLE i2b2pm.pm_hive_data OWNER TO i2b2;

--
-- Name: pm_hive_params; Type: TABLE; Schema: i2b2pm; Owner: i2b2
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


-- ALTER TABLE i2b2pm.pm_hive_params OWNER TO i2b2;

--
-- Name: pm_hive_params_id_seq; Type: SEQUENCE; Schema: i2b2pm; Owner: i2b2
--

CREATE SEQUENCE i2b2pm.pm_hive_params_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


-- ALTER TABLE i2b2pm.pm_hive_params_id_seq OWNER TO i2b2;

--
-- Name: pm_hive_params_id_seq; Type: SEQUENCE OWNED BY; Schema: i2b2pm; Owner: i2b2
--

ALTER SEQUENCE i2b2pm.pm_hive_params_id_seq OWNED BY i2b2pm.pm_hive_params.id;


--
-- Name: pm_project_data; Type: TABLE; Schema: i2b2pm; Owner: i2b2
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


-- ALTER TABLE i2b2pm.pm_project_data OWNER TO i2b2;

--
-- Name: pm_project_params; Type: TABLE; Schema: i2b2pm; Owner: i2b2
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


-- ALTER TABLE i2b2pm.pm_project_params OWNER TO i2b2;

--
-- Name: pm_project_params_id_seq; Type: SEQUENCE; Schema: i2b2pm; Owner: i2b2
--

CREATE SEQUENCE i2b2pm.pm_project_params_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


-- ALTER TABLE i2b2pm.pm_project_params_id_seq OWNER TO i2b2;

--
-- Name: pm_project_params_id_seq; Type: SEQUENCE OWNED BY; Schema: i2b2pm; Owner: i2b2
--

ALTER SEQUENCE i2b2pm.pm_project_params_id_seq OWNED BY i2b2pm.pm_project_params.id;


--
-- Name: pm_project_request; Type: TABLE; Schema: i2b2pm; Owner: i2b2
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


-- ALTER TABLE i2b2pm.pm_project_request OWNER TO i2b2;

--
-- Name: pm_project_request_id_seq; Type: SEQUENCE; Schema: i2b2pm; Owner: i2b2
--

CREATE SEQUENCE i2b2pm.pm_project_request_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


-- ALTER TABLE i2b2pm.pm_project_request_id_seq OWNER TO i2b2;

--
-- Name: pm_project_request_id_seq; Type: SEQUENCE OWNED BY; Schema: i2b2pm; Owner: i2b2
--

ALTER SEQUENCE i2b2pm.pm_project_request_id_seq OWNED BY i2b2pm.pm_project_request.id;


--
-- Name: pm_project_user_params; Type: TABLE; Schema: i2b2pm; Owner: i2b2
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


-- ALTER TABLE i2b2pm.pm_project_user_params OWNER TO i2b2;

--
-- Name: pm_project_user_params_id_seq; Type: SEQUENCE; Schema: i2b2pm; Owner: i2b2
--

CREATE SEQUENCE i2b2pm.pm_project_user_params_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


-- ALTER TABLE i2b2pm.pm_project_user_params_id_seq OWNER TO i2b2;

--
-- Name: pm_project_user_params_id_seq; Type: SEQUENCE OWNED BY; Schema: i2b2pm; Owner: i2b2
--

ALTER SEQUENCE i2b2pm.pm_project_user_params_id_seq OWNED BY i2b2pm.pm_project_user_params.id;


--
-- Name: pm_project_user_roles; Type: TABLE; Schema: i2b2pm; Owner: i2b2
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


-- ALTER TABLE i2b2pm.pm_project_user_roles OWNER TO i2b2;

--
-- Name: pm_role_requirement; Type: TABLE; Schema: i2b2pm; Owner: i2b2
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


-- ALTER TABLE i2b2pm.pm_role_requirement OWNER TO i2b2;

--
-- Name: pm_user_data; Type: TABLE; Schema: i2b2pm; Owner: i2b2
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


-- ALTER TABLE i2b2pm.pm_user_data OWNER TO i2b2;

--
-- Name: pm_user_login; Type: TABLE; Schema: i2b2pm; Owner: i2b2
--

CREATE TABLE i2b2pm.pm_user_login (
    user_id character varying(50) NOT NULL,
    attempt_cd character varying(50) NOT NULL,
    entry_date timestamp without time zone NOT NULL,
    changeby_char character varying(50),
    status_cd character varying(50)
);


-- ALTER TABLE i2b2pm.pm_user_login OWNER TO i2b2;

--
-- Name: pm_user_params; Type: TABLE; Schema: i2b2pm; Owner: i2b2
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


-- ALTER TABLE i2b2pm.pm_user_params OWNER TO i2b2;

--
-- Name: pm_user_params_id_seq; Type: SEQUENCE; Schema: i2b2pm; Owner: i2b2
--

CREATE SEQUENCE i2b2pm.pm_user_params_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


-- ALTER TABLE i2b2pm.pm_user_params_id_seq OWNER TO i2b2;

--
-- Name: pm_user_params_id_seq; Type: SEQUENCE OWNED BY; Schema: i2b2pm; Owner: i2b2
--

ALTER SEQUENCE i2b2pm.pm_user_params_id_seq OWNED BY i2b2pm.pm_user_params.id;


--
-- Name: pm_user_session; Type: TABLE; Schema: i2b2pm; Owner: i2b2
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


-- ALTER TABLE i2b2pm.pm_user_session OWNER TO i2b2;

--
-- Name: workplace; Type: TABLE; Schema: i2b2workdata; Owner: i2b2
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


-- ALTER TABLE i2b2workdata.workplace OWNER TO i2b2;

--
-- Name: workplace_access; Type: TABLE; Schema: i2b2workdata; Owner: i2b2
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


-- ALTER TABLE i2b2workdata.workplace_access OWNER TO i2b2;

--
-- Name: observation_fact text_search_index; Type: DEFAULT; Schema: i2b2demodata; Owner: i2b2
--

ALTER TABLE ONLY i2b2demodata.observation_fact ALTER COLUMN text_search_index SET DEFAULT nextval('i2b2demodata.observation_fact_text_search_index_seq'::regclass);


--
-- Name: qt_patient_enc_collection patient_enc_coll_id; Type: DEFAULT; Schema: i2b2demodata; Owner: i2b2
--

ALTER TABLE ONLY i2b2demodata.qt_patient_enc_collection ALTER COLUMN patient_enc_coll_id SET DEFAULT nextval('i2b2demodata.qt_patient_enc_collection_patient_enc_coll_id_seq'::regclass);


--
-- Name: qt_patient_set_collection patient_set_coll_id; Type: DEFAULT; Schema: i2b2demodata; Owner: i2b2
--

ALTER TABLE ONLY i2b2demodata.qt_patient_set_collection ALTER COLUMN patient_set_coll_id SET DEFAULT nextval('i2b2demodata.qt_patient_set_collection_patient_set_coll_id_seq'::regclass);


--
-- Name: qt_pdo_query_master query_master_id; Type: DEFAULT; Schema: i2b2demodata; Owner: i2b2
--

ALTER TABLE ONLY i2b2demodata.qt_pdo_query_master ALTER COLUMN query_master_id SET DEFAULT nextval('i2b2demodata.qt_pdo_query_master_query_master_id_seq'::regclass);


--
-- Name: qt_query_instance query_instance_id; Type: DEFAULT; Schema: i2b2demodata; Owner: i2b2
--

ALTER TABLE ONLY i2b2demodata.qt_query_instance ALTER COLUMN query_instance_id SET DEFAULT nextval('i2b2demodata.qt_query_instance_query_instance_id_seq'::regclass);


--
-- Name: qt_query_master query_master_id; Type: DEFAULT; Schema: i2b2demodata; Owner: i2b2
--

ALTER TABLE ONLY i2b2demodata.qt_query_master ALTER COLUMN query_master_id SET DEFAULT nextval('i2b2demodata.qt_query_master_query_master_id_seq'::regclass);


--
-- Name: qt_query_result_instance result_instance_id; Type: DEFAULT; Schema: i2b2demodata; Owner: i2b2
--

ALTER TABLE ONLY i2b2demodata.qt_query_result_instance ALTER COLUMN result_instance_id SET DEFAULT nextval('i2b2demodata.qt_query_result_instance_result_instance_id_seq'::regclass);


--
-- Name: qt_xml_result xml_result_id; Type: DEFAULT; Schema: i2b2demodata; Owner: i2b2
--

ALTER TABLE ONLY i2b2demodata.qt_xml_result ALTER COLUMN xml_result_id SET DEFAULT nextval('i2b2demodata.qt_xml_result_xml_result_id_seq'::regclass);


--
-- Name: upload_status upload_id; Type: DEFAULT; Schema: i2b2demodata; Owner: i2b2
--

ALTER TABLE ONLY i2b2demodata.upload_status ALTER COLUMN upload_id SET DEFAULT nextval('i2b2demodata.upload_status_upload_id_seq'::regclass);


--
-- Name: ont_process_status process_id; Type: DEFAULT; Schema: i2b2metadata; Owner: i2b2
--

ALTER TABLE ONLY i2b2metadata.ont_process_status ALTER COLUMN process_id SET DEFAULT nextval('i2b2metadata.ont_process_status_process_id_seq'::regclass);


--
-- Name: pm_approvals_params id; Type: DEFAULT; Schema: i2b2pm; Owner: i2b2
--

ALTER TABLE ONLY i2b2pm.pm_approvals_params ALTER COLUMN id SET DEFAULT nextval('i2b2pm.pm_approvals_params_id_seq'::regclass);


--
-- Name: pm_cell_params id; Type: DEFAULT; Schema: i2b2pm; Owner: i2b2
--

ALTER TABLE ONLY i2b2pm.pm_cell_params ALTER COLUMN id SET DEFAULT nextval('i2b2pm.pm_cell_params_id_seq'::regclass);


--
-- Name: pm_global_params id; Type: DEFAULT; Schema: i2b2pm; Owner: i2b2
--

ALTER TABLE ONLY i2b2pm.pm_global_params ALTER COLUMN id SET DEFAULT nextval('i2b2pm.pm_global_params_id_seq'::regclass);


--
-- Name: pm_hive_params id; Type: DEFAULT; Schema: i2b2pm; Owner: i2b2
--

ALTER TABLE ONLY i2b2pm.pm_hive_params ALTER COLUMN id SET DEFAULT nextval('i2b2pm.pm_hive_params_id_seq'::regclass);


--
-- Name: pm_project_params id; Type: DEFAULT; Schema: i2b2pm; Owner: i2b2
--

ALTER TABLE ONLY i2b2pm.pm_project_params ALTER COLUMN id SET DEFAULT nextval('i2b2pm.pm_project_params_id_seq'::regclass);


--
-- Name: pm_project_request id; Type: DEFAULT; Schema: i2b2pm; Owner: i2b2
--

ALTER TABLE ONLY i2b2pm.pm_project_request ALTER COLUMN id SET DEFAULT nextval('i2b2pm.pm_project_request_id_seq'::regclass);


--
-- Name: pm_project_user_params id; Type: DEFAULT; Schema: i2b2pm; Owner: i2b2
--

ALTER TABLE ONLY i2b2pm.pm_project_user_params ALTER COLUMN id SET DEFAULT nextval('i2b2pm.pm_project_user_params_id_seq'::regclass);


--
-- Name: pm_user_params id; Type: DEFAULT; Schema: i2b2pm; Owner: i2b2
--

ALTER TABLE ONLY i2b2pm.pm_user_params ALTER COLUMN id SET DEFAULT nextval('i2b2pm.pm_user_params_id_seq'::regclass);


--
-- Data for Name: explore_query; Type: TABLE DATA; Schema: gecodatasourceplugintest; Owner: i2b2
--

COPY gecodatasourceplugintest.explore_query (id, create_date, user_id, status, definition, result_i2b2_patient_set_id, result_geco_shared_id_count, result_geco_shared_id_patient_list) FROM stdin;
\.


--
-- Data for Name: saved_cohort; Type: TABLE DATA; Schema: gecodatasourceplugintest; Owner: i2b2
--

COPY gecodatasourceplugintest.saved_cohort (name, create_date, explore_query_id) FROM stdin;
\.


--
-- Data for Name: archive_observation_fact; Type: TABLE DATA; Schema: i2b2demodata; Owner: i2b2
--

COPY i2b2demodata.archive_observation_fact (encounter_num, patient_num, concept_cd, provider_id, start_date, modifier_cd, instance_num, valtype_cd, tval_char, nval_num, valueflag_cd, quantity_num, units_cd, end_date, location_cd, observation_blob, confidence_num, update_date, download_date, import_date, sourcesystem_cd, upload_id, text_search_index, archive_upload_id) FROM stdin;
\.


--
-- Data for Name: code_lookup; Type: TABLE DATA; Schema: i2b2demodata; Owner: i2b2
--

COPY i2b2demodata.code_lookup (table_cd, column_cd, code_cd, name_char, lookup_blob, upload_date, update_date, download_date, import_date, sourcesystem_cd, upload_id) FROM stdin;
\.


--
-- Data for Name: datamart_report; Type: TABLE DATA; Schema: i2b2demodata; Owner: i2b2
--

COPY i2b2demodata.datamart_report (total_patient, total_observationfact, total_event, report_date) FROM stdin;
\.


--
-- Data for Name: qt_analysis_plugin; Type: TABLE DATA; Schema: i2b2demodata; Owner: i2b2
--

COPY i2b2demodata.qt_analysis_plugin (plugin_id, plugin_name, description, version_cd, parameter_info, parameter_info_xsd, command_line, working_folder, commandoption_cd, plugin_icon, status_cd, user_id, group_id, create_date, update_date) FROM stdin;
\.


--
-- Data for Name: qt_analysis_plugin_result_type; Type: TABLE DATA; Schema: i2b2demodata; Owner: i2b2
--

COPY i2b2demodata.qt_analysis_plugin_result_type (plugin_id, result_type_id) FROM stdin;
\.


--
-- Data for Name: qt_breakdown_path; Type: TABLE DATA; Schema: i2b2demodata; Owner: i2b2
--

COPY i2b2demodata.qt_breakdown_path (name, value, create_date, update_date, user_id) FROM stdin;
\.


--
-- Data for Name: qt_patient_enc_collection; Type: TABLE DATA; Schema: i2b2demodata; Owner: i2b2
--

COPY i2b2demodata.qt_patient_enc_collection (patient_enc_coll_id, result_instance_id, set_index, patient_num, encounter_num) FROM stdin;
\.


--
-- Data for Name: qt_patient_set_collection; Type: TABLE DATA; Schema: i2b2demodata; Owner: i2b2
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
4	1	4	4
5	1	5	5
6	1	6	6
7	1	7	7
8	1	8	8
9	1	9	9
10	1	10	10
11	1	11	11
12	1	12	12
13	1	13	13
14	1	14	14
15	1	15	15
16	1	16	16
17	1	17	17
18	1	18	18
19	1	19	19
20	1	20	20
21	1	21	21
22	1	22	22
23	1	23	23
24	1	24	24
25	1	25	25
26	1	26	26
27	1	27	27
28	1	28	28
29	1	29	29
30	1	30	30
31	1	31	31
32	1	32	32
33	1	33	33
34	1	34	34
35	1	35	35
36	1	36	36
37	1	37	37
38	1	38	38
39	1	39	39
40	1	40	40
41	1	41	41
42	1	42	42
43	1	43	43
44	1	44	44
45	1	45	45
46	1	46	46
47	1	47	47
48	1	48	48
49	1	49	49
50	1	50	50
51	1	51	51
52	1	52	52
53	1	53	53
54	1	54	54
55	1	55	55
56	1	56	56
57	1	57	57
58	1	58	58
59	1	59	59
60	1	60	60
61	1	61	61
62	1	62	62
63	1	63	63
64	1	64	64
65	1	65	65
66	1	66	66
67	1	67	67
68	1	68	68
69	1	69	69
70	1	70	70
71	1	71	71
72	1	72	72
73	1	73	73
74	1	74	74
75	1	75	75
76	1	76	76
77	1	77	77
78	1	78	78
79	1	79	79
80	1	80	80
81	1	81	81
82	1	82	82
83	1	83	83
84	1	84	84
85	1	85	85
86	1	86	86
87	1	87	87
88	1	88	88
89	1	89	89
90	1	90	90
91	1	91	91
92	1	92	92
93	1	93	93
94	1	94	94
95	1	95	95
96	1	96	96
97	1	97	97
98	1	98	98
99	1	99	99
100	1	100	100
101	1	101	101
102	1	102	102
103	1	103	103
104	1	104	104
105	1	105	105
106	1	106	106
107	1	107	107
108	1	108	108
109	1	109	109
110	1	110	110
111	1	111	111
112	1	112	112
113	1	113	113
114	1	114	114
115	1	115	115
116	1	116	116
117	1	117	117
118	1	118	118
119	1	119	119
120	1	120	120
121	1	121	121
122	1	122	122
123	1	123	123
124	1	124	124
125	1	125	125
126	1	126	126
127	1	127	127
128	1	128	128
129	1	129	129
130	1	130	130
131	1	131	131
132	1	132	132
133	1	133	133
134	1	134	134
135	1	135	135
136	1	136	136
137	1	137	137
138	1	138	138
139	1	139	139
140	1	140	140
141	1	141	141
142	1	142	142
143	1	143	143
144	1	144	144
145	1	145	145
146	1	146	146
147	1	147	147
148	1	148	148
149	1	149	149
150	1	150	150
151	1	151	151
152	1	152	152
153	1	153	153
154	1	154	154
155	1	155	155
156	1	156	156
157	1	157	157
158	1	158	158
159	1	159	159
160	1	160	160
161	1	161	161
162	1	162	162
163	1	163	163
164	1	164	164
165	1	165	165
166	1	166	166
167	1	167	167
168	1	168	168
169	1	169	169
170	1	170	170
171	1	171	171
172	1	172	172
173	1	173	173
174	1	174	174
175	1	175	175
176	1	176	176
177	1	177	177
178	1	178	178
179	1	179	179
180	1	180	180
181	1	181	181
182	1	182	182
183	1	183	183
184	1	184	184
185	1	185	185
186	1	186	186
187	1	187	187
188	1	188	188
189	1	189	189
190	1	190	190
191	1	191	191
192	1	192	192
193	1	193	193
194	1	194	194
195	1	195	195
196	1	196	196
197	1	197	197
198	1	198	198
199	1	199	199
200	1	200	200
201	1	201	201
202	1	202	202
203	1	203	203
204	1	204	204
205	1	205	205
206	1	206	206
207	1	207	207
208	1	208	208
209	1	209	209
210	1	210	210
211	1	211	211
212	1	212	212
213	1	213	213
214	1	214	214
215	1	215	215
216	1	216	216
217	1	217	217
218	1	218	218
219	1	219	219
220	1	220	220
221	1	221	221
222	1	222	222
223	1	223	223
224	1	224	224
225	1	225	225
226	1	226	226
227	1	227	227
228	1	228	228
229	1	229	229
230	3	1	1
231	3	2	2
232	3	3	3
233	3	4	4
234	3	5	5
235	3	6	6
236	3	7	7
237	3	8	8
238	3	9	9
239	3	10	10
240	3	11	11
241	3	12	12
242	3	13	13
243	3	14	14
244	3	15	15
245	3	16	16
246	3	17	17
247	3	18	18
248	3	19	19
249	3	20	20
250	3	21	21
251	3	22	22
252	3	23	23
253	3	24	24
254	3	25	25
255	3	26	26
256	3	27	27
257	3	28	28
258	3	29	29
259	3	30	30
260	3	31	31
261	3	32	32
262	3	33	33
263	3	34	34
264	3	35	35
265	3	36	36
266	3	37	37
267	3	38	38
268	3	39	39
269	3	40	40
270	3	41	41
271	3	42	42
272	3	43	43
273	3	44	44
274	3	45	45
275	3	46	46
276	3	47	47
277	3	48	48
278	3	49	49
279	3	50	50
280	3	51	51
281	3	52	52
282	3	53	53
283	3	54	54
284	3	55	55
285	3	56	56
286	3	57	57
287	3	58	58
288	3	59	59
289	3	60	60
290	3	61	61
291	3	62	62
292	3	63	63
293	3	64	64
294	3	65	65
295	3	66	66
296	3	67	67
297	3	68	68
298	3	69	69
299	3	70	70
300	3	71	71
301	3	72	72
302	3	73	73
303	3	74	74
304	3	75	75
305	3	76	76
306	3	77	77
307	3	78	78
308	3	79	79
309	3	80	80
310	3	81	81
311	3	82	82
312	3	83	83
313	3	84	84
314	3	85	85
315	3	86	86
316	3	87	87
317	3	88	88
318	3	89	89
319	3	90	90
320	3	91	91
321	3	92	92
322	3	93	93
323	3	94	94
324	3	95	95
325	3	96	96
326	3	97	97
327	3	98	98
328	3	99	99
329	3	100	100
330	3	101	101
331	3	102	102
332	3	103	103
333	3	104	104
334	3	105	105
335	3	106	106
336	3	107	107
337	3	108	108
338	3	109	109
339	3	110	110
340	3	111	111
341	3	112	112
342	3	113	113
343	3	114	114
344	3	115	115
345	3	116	116
346	3	117	117
347	3	118	118
348	3	119	119
349	3	120	120
350	3	121	121
351	3	122	122
352	3	123	123
353	3	124	124
354	3	125	125
355	3	126	126
356	3	127	127
357	3	128	128
358	3	129	129
359	3	130	130
360	3	131	131
361	3	132	132
362	3	133	133
363	3	134	134
364	3	135	135
365	3	136	136
366	3	137	137
367	3	138	138
368	3	139	139
369	3	140	140
370	3	141	141
371	3	142	142
372	3	143	143
373	3	144	144
374	3	145	145
375	3	146	146
376	3	147	147
377	3	148	148
378	3	149	149
379	3	150	150
380	3	151	151
381	3	152	152
382	3	153	153
383	3	154	154
384	3	155	155
385	3	156	156
386	3	157	157
387	3	158	158
388	3	159	159
389	3	160	160
390	3	161	161
391	3	162	162
392	3	163	163
393	3	164	164
394	3	165	165
395	3	166	166
396	3	167	167
397	3	168	168
398	3	169	169
399	3	170	170
400	3	171	171
401	3	172	172
402	3	173	173
403	3	174	174
404	3	175	175
405	3	176	176
406	3	177	177
407	3	178	178
408	3	179	179
409	3	180	180
410	3	181	181
411	3	182	182
412	3	183	183
413	3	184	184
414	3	185	185
415	3	186	186
416	3	187	187
417	3	188	188
418	3	189	189
419	3	190	190
420	3	191	191
421	3	192	192
422	3	193	193
423	3	194	194
424	3	195	195
425	3	196	196
426	3	197	197
427	3	198	198
428	3	199	199
429	3	200	200
430	3	201	201
431	3	202	202
432	3	203	203
433	3	204	204
434	3	205	205
435	3	206	206
436	3	207	207
437	3	208	208
438	3	209	209
439	3	210	210
440	3	211	211
441	3	212	212
442	3	213	213
443	3	214	214
444	3	215	215
445	3	216	216
446	3	217	217
447	3	218	218
448	3	219	219
449	3	220	220
450	3	221	221
451	3	222	222
452	3	223	223
453	3	224	224
454	3	225	225
455	3	226	226
456	3	227	227
457	3	228	228
458	3	229	229
459	5	1	3
460	5	2	10
461	5	3	11
462	5	4	13
463	5	5	15
464	5	6	19
465	5	7	20
466	5	8	25
467	5	9	28
468	5	10	31
469	5	11	32
470	5	12	34
471	5	13	39
472	5	14	43
473	5	15	47
474	5	16	48
475	5	17	49
476	5	18	56
477	5	19	58
478	5	20	61
479	5	21	62
480	5	22	65
481	5	23	66
482	5	24	68
483	5	25	70
484	5	26	71
485	5	27	80
486	5	28	84
487	5	29	93
488	5	30	97
489	5	31	103
490	5	32	108
491	5	33	112
492	5	34	121
493	5	35	122
494	5	36	124
495	5	37	126
496	5	38	128
497	5	39	130
498	5	40	132
499	5	41	134
500	5	42	135
501	5	43	137
502	5	44	139
503	5	45	140
504	5	46	143
505	5	47	147
506	5	48	148
507	5	49	151
508	5	50	156
509	5	51	159
510	5	52	160
511	5	53	162
512	5	54	166
513	5	55	172
514	5	56	173
515	5	57	181
516	5	58	183
517	5	59	184
518	5	60	189
519	5	61	193
520	5	62	200
521	5	63	208
522	5	64	221
523	5	65	223
524	5	66	226
525	5	67	227
526	5	68	229
527	5	69	235
528	5	70	250
529	5	71	261
530	5	72	263
531	5	73	279
532	7	1	3
533	7	2	10
534	7	3	11
535	7	4	13
536	7	5	15
537	7	6	19
538	7	7	20
539	7	8	25
540	7	9	28
541	7	10	31
542	7	11	32
543	7	12	34
544	7	13	39
545	7	14	43
546	7	15	47
547	7	16	48
548	7	17	49
549	7	18	56
550	7	19	58
551	7	20	61
552	7	21	62
553	7	22	65
554	7	23	66
555	7	24	68
556	7	25	70
557	7	26	71
558	7	27	80
559	7	28	84
560	7	29	93
561	7	30	97
562	7	31	103
563	7	32	108
564	7	33	112
565	7	34	121
566	7	35	122
567	7	36	124
568	7	37	126
569	7	38	128
570	7	39	130
571	7	40	132
572	7	41	134
573	7	42	135
574	7	43	137
575	7	44	139
576	7	45	140
577	7	46	143
578	7	47	147
579	7	48	148
580	7	49	151
581	7	50	156
582	7	51	159
583	7	52	160
584	7	53	162
585	7	54	166
586	7	55	172
587	7	56	173
588	7	57	181
589	7	58	183
590	7	59	184
591	7	60	189
592	7	61	193
593	7	62	200
594	7	63	208
595	7	64	221
596	7	65	223
597	7	66	226
598	7	67	227
599	7	68	229
600	7	69	235
601	7	70	250
602	7	71	261
603	7	72	263
604	7	73	279
605	9	1	1
606	9	2	23
607	9	3	24
608	9	4	28
609	9	5	33
610	9	6	39
611	9	7	48
612	9	8	50
613	9	9	55
614	9	10	59
615	9	11	65
616	9	12	68
617	9	13	69
618	9	14	73
619	9	15	81
620	9	16	84
621	9	17	85
622	9	18	88
623	9	19	106
624	9	20	114
625	9	21	121
626	9	22	123
627	9	23	133
628	9	24	154
629	9	25	158
630	9	26	161
631	9	27	168
632	9	28	172
633	9	29	184
634	9	30	186
635	9	31	195
636	9	32	196
637	9	33	202
638	9	34	208
639	9	35	210
640	9	36	220
641	9	37	221
642	9	38	222
643	9	39	234
644	9	40	240
645	9	41	254
646	9	42	268
647	9	43	271
648	11	1	3
649	11	2	10
650	11	3	11
651	11	4	13
652	11	5	15
653	11	6	19
654	11	7	20
655	11	8	25
656	11	9	28
657	11	10	31
658	11	11	32
659	11	12	34
660	11	13	39
661	11	14	43
662	11	15	47
663	11	16	48
664	11	17	49
665	11	18	56
666	11	19	58
667	11	20	61
668	11	21	62
669	11	22	65
670	11	23	66
671	11	24	68
672	11	25	70
673	11	26	71
674	11	27	80
675	11	28	84
676	11	29	93
677	11	30	97
678	11	31	103
679	11	32	108
680	11	33	112
681	11	34	121
682	11	35	122
683	11	36	124
684	11	37	126
685	11	38	128
686	11	39	130
687	11	40	132
688	11	41	134
689	11	42	135
690	11	43	137
691	11	44	139
692	11	45	140
693	11	46	143
694	11	47	147
695	11	48	148
696	11	49	151
697	11	50	156
698	11	51	159
699	11	52	160
700	11	53	162
701	11	54	166
702	11	55	172
703	11	56	173
704	11	57	181
705	11	58	183
706	11	59	184
707	11	60	189
708	11	61	193
709	11	62	200
710	11	63	208
711	11	64	221
712	11	65	223
713	11	66	226
714	11	67	227
715	11	68	229
716	11	69	235
717	11	70	250
718	11	71	261
719	11	72	263
720	11	73	279
721	13	1	3
722	13	2	10
723	13	3	11
724	13	4	13
725	13	5	15
726	13	6	19
727	13	7	20
728	13	8	25
729	13	9	28
730	13	10	31
731	13	11	32
732	13	12	34
733	13	13	39
734	13	14	43
735	13	15	47
736	13	16	48
737	13	17	49
738	13	18	56
739	13	19	58
740	13	20	61
741	13	21	62
742	13	22	65
743	13	23	66
744	13	24	68
745	13	25	70
746	13	26	71
747	13	27	80
748	13	28	84
749	13	29	93
750	13	30	97
751	13	31	103
752	13	32	108
753	13	33	112
754	13	34	121
755	13	35	122
756	13	36	124
757	13	37	126
758	13	38	128
759	13	39	130
760	13	40	132
761	13	41	134
762	13	42	135
763	13	43	137
764	13	44	139
765	13	45	140
766	13	46	143
767	13	47	147
768	13	48	148
769	13	49	151
770	13	50	156
771	13	51	159
772	13	52	160
773	13	53	162
774	13	54	166
775	13	55	172
776	13	56	173
777	13	57	181
778	13	58	183
779	13	59	184
780	13	60	189
781	13	61	193
782	13	62	200
783	13	63	208
784	13	64	221
785	13	65	223
786	13	66	226
787	13	67	227
788	13	68	229
789	13	69	235
790	13	70	250
791	13	71	261
792	13	72	263
793	13	73	279
\.


--
-- Data for Name: qt_pdo_query_master; Type: TABLE DATA; Schema: i2b2demodata; Owner: i2b2
--

COPY i2b2demodata.qt_pdo_query_master (query_master_id, user_id, group_id, create_date, request_xml, i2b2_request_xml) FROM stdin;
-1	demo	Demo	2022-03-04 22:19:51.786	xml-request	\N
1	demo	Demo	2022-04-11 17:25:16.019	<msgns:request xmlns:msgns="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:pdons="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ontns="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:crcpdons="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/" xmlns:crcpsmns="http://www.i2b2.org/xsd/cell/crc/psm/1.1/">\n      <message_header>\n          <i2b2_version_compatible>0.3</i2b2_version_compatible>\n          <hl7_version_compatible>2.4</hl7_version_compatible>\n          <sending_application>\n              <application_name>GeCo i2b2 Data Source</application_name>\n              <application_version>0.2</application_version>\n          </sending_application>\n          <sending_facility>\n              <facility_name>GeCo</facility_name>\n          </sending_facility>\n          <receiving_application>\n              <application_name>i2b2 cell</application_name>\n              <application_version>1.7</application_version>\n          </receiving_application>\n          <receiving_facility>\n              <facility_name>i2b2 hive</facility_name>\n          </receiving_facility>\n          <datetime_of_message>2022-04-11T17:25:15Z</datetime_of_message>\n          <security>\n              <domain>i2b2demo</domain>\n              <username>demo</username>\n              <password>*********</password>\n          </security>\n          <message_type>\n              <message_code>EQQ</message_code>\n              <event_type>Q04</event_type>\n              <message_structure>EQQ_Q04</message_structure>\n          </message_type>\n          <message_control_id>\n              <session_id>2022-04-11T17:25:15Z</session_id>\n              <message_num>1649697915</message_num>\n              <instance_num>0</instance_num>\n          </message_control_id>\n          <processing_id>\n              <processing_id>P</processing_id>\n              <processing_mode>I</processing_mode>\n          </processing_id>\n          <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n          <application_acknowledgement_type/>\n          <country_code>CH</country_code>\n          <project_id>Demo</project_id>\n      </message_header>\n      <request_header>\n          <result_waittime_ms>10000</result_waittime_ms>\n      </request_header>\n      <message_body>\n          <crcpdons:pdoheader>\n              <patient_set_limit>0</patient_set_limit>\n              <estimated_time>0</estimated_time>\n              <request_type>getPDO_fromInputList</request_type>\n          </crcpdons:pdoheader>\n          <crcpdons:request xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="crcpdons:GetPDOFromInputList_requestType">\n              <input_list>\n                  <patient_list max="1000000" min="0">\n                      <patient_set_coll_id>1</patient_set_coll_id>\n                  </patient_list>\n              </input_list>\n              <output_option name="none">\n                  <patient_set select="using_input_list" onlykeys="false" blob="false" techdata="false"/>\n              </output_option>\n          </crcpdons:request>\n      </message_body>\n  </msgns:request>	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns5:request xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <message_header>\n        <i2b2_version_compatible>0.3</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>GeCo i2b2 Data Source</application_name>\n            <application_version>0.2</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>GeCo</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>i2b2 cell</application_name>\n            <application_version>1.7</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-04-11T17:25:15Z</datetime_of_message>\n        <security>\n            <domain>i2b2demo</domain>\n            <username>demo</username>\n            <password is_token="false">password not stored</password>\n        </security>\n        <message_type>\n            <message_code>EQQ</message_code>\n            <event_type>Q04</event_type>\n            <message_structure>EQQ_Q04</message_structure>\n        </message_type>\n        <message_control_id>\n            <session_id>2022-04-11T17:25:15Z</session_id>\n            <message_num>1649697915</message_num>\n            <instance_num>0</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n        <application_acknowledgement_type></application_acknowledgement_type>\n        <country_code>CH</country_code>\n        <project_id>Demo</project_id>\n    </message_header>\n    <request_header>\n        <result_waittime_ms>10000</result_waittime_ms>\n    </request_header>\n    <message_body>\n        <ns3:pdoheader>\n            <patient_set_limit>0</patient_set_limit>\n            <estimated_time>0</estimated_time>\n            <request_type>getPDO_fromInputList</request_type>\n        </ns3:pdoheader>\n        <ns3:request xsi:type="ns3:GetPDOFromInputList_requestType" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">\n            <input_list>\n                <patient_list min="0" max="1000000">\n                    <patient_set_coll_id>1</patient_set_coll_id>\n                </patient_list>\n            </input_list>\n            <output_option>\n                <patient_set onlykeys="false" blob="false" techdata="false" select="using_input_list"/>\n            </output_option>\n        </ns3:request>\n    </message_body>\n</ns5:request>\n
2	demo	Demo	2022-04-11 17:26:10.377	<msgns:request xmlns:msgns="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:pdons="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ontns="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:crcpdons="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/" xmlns:crcpsmns="http://www.i2b2.org/xsd/cell/crc/psm/1.1/">\n      <message_header>\n          <i2b2_version_compatible>0.3</i2b2_version_compatible>\n          <hl7_version_compatible>2.4</hl7_version_compatible>\n          <sending_application>\n              <application_name>GeCo i2b2 Data Source</application_name>\n              <application_version>0.2</application_version>\n          </sending_application>\n          <sending_facility>\n              <facility_name>GeCo</facility_name>\n          </sending_facility>\n          <receiving_application>\n              <application_name>i2b2 cell</application_name>\n              <application_version>1.7</application_version>\n          </receiving_application>\n          <receiving_facility>\n              <facility_name>i2b2 hive</facility_name>\n          </receiving_facility>\n          <datetime_of_message>2022-04-11T17:26:10Z</datetime_of_message>\n          <security>\n              <domain>i2b2demo</domain>\n              <username>demo</username>\n              <password>*********</password>\n          </security>\n          <message_type>\n              <message_code>EQQ</message_code>\n              <event_type>Q04</event_type>\n              <message_structure>EQQ_Q04</message_structure>\n          </message_type>\n          <message_control_id>\n              <session_id>2022-04-11T17:26:10Z</session_id>\n              <message_num>1649697970</message_num>\n              <instance_num>0</instance_num>\n          </message_control_id>\n          <processing_id>\n              <processing_id>P</processing_id>\n              <processing_mode>I</processing_mode>\n          </processing_id>\n          <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n          <application_acknowledgement_type/>\n          <country_code>CH</country_code>\n          <project_id>Demo</project_id>\n      </message_header>\n      <request_header>\n          <result_waittime_ms>10000</result_waittime_ms>\n      </request_header>\n      <message_body>\n          <crcpdons:pdoheader>\n              <patient_set_limit>0</patient_set_limit>\n              <estimated_time>0</estimated_time>\n              <request_type>getPDO_fromInputList</request_type>\n          </crcpdons:pdoheader>\n          <crcpdons:request xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="crcpdons:GetPDOFromInputList_requestType">\n              <input_list>\n                  <patient_list max="1000000" min="0">\n                      <patient_set_coll_id>3</patient_set_coll_id>\n                  </patient_list>\n              </input_list>\n              <output_option name="none">\n                  <patient_set select="using_input_list" onlykeys="false" blob="false" techdata="false"/>\n              </output_option>\n          </crcpdons:request>\n      </message_body>\n  </msgns:request>	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns5:request xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <message_header>\n        <i2b2_version_compatible>0.3</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>GeCo i2b2 Data Source</application_name>\n            <application_version>0.2</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>GeCo</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>i2b2 cell</application_name>\n            <application_version>1.7</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-04-11T17:26:10Z</datetime_of_message>\n        <security>\n            <domain>i2b2demo</domain>\n            <username>demo</username>\n            <password is_token="false">password not stored</password>\n        </security>\n        <message_type>\n            <message_code>EQQ</message_code>\n            <event_type>Q04</event_type>\n            <message_structure>EQQ_Q04</message_structure>\n        </message_type>\n        <message_control_id>\n            <session_id>2022-04-11T17:26:10Z</session_id>\n            <message_num>1649697970</message_num>\n            <instance_num>0</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n        <application_acknowledgement_type></application_acknowledgement_type>\n        <country_code>CH</country_code>\n        <project_id>Demo</project_id>\n    </message_header>\n    <request_header>\n        <result_waittime_ms>10000</result_waittime_ms>\n    </request_header>\n    <message_body>\n        <ns3:pdoheader>\n            <patient_set_limit>0</patient_set_limit>\n            <estimated_time>0</estimated_time>\n            <request_type>getPDO_fromInputList</request_type>\n        </ns3:pdoheader>\n        <ns3:request xsi:type="ns3:GetPDOFromInputList_requestType" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">\n            <input_list>\n                <patient_list min="0" max="1000000">\n                    <patient_set_coll_id>3</patient_set_coll_id>\n                </patient_list>\n            </input_list>\n            <output_option>\n                <patient_set onlykeys="false" blob="false" techdata="false" select="using_input_list"/>\n            </output_option>\n        </ns3:request>\n    </message_body>\n</ns5:request>\n
3	demo	Demo	2022-04-11 17:28:16.107	<msgns:request xmlns:msgns="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:pdons="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ontns="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:crcpdons="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/" xmlns:crcpsmns="http://www.i2b2.org/xsd/cell/crc/psm/1.1/">\n      <message_header>\n          <i2b2_version_compatible>0.3</i2b2_version_compatible>\n          <hl7_version_compatible>2.4</hl7_version_compatible>\n          <sending_application>\n              <application_name>GeCo i2b2 Data Source</application_name>\n              <application_version>0.2</application_version>\n          </sending_application>\n          <sending_facility>\n              <facility_name>GeCo</facility_name>\n          </sending_facility>\n          <receiving_application>\n              <application_name>i2b2 cell</application_name>\n              <application_version>1.7</application_version>\n          </receiving_application>\n          <receiving_facility>\n              <facility_name>i2b2 hive</facility_name>\n          </receiving_facility>\n          <datetime_of_message>2022-04-11T17:28:15Z</datetime_of_message>\n          <security>\n              <domain>i2b2demo</domain>\n              <username>demo</username>\n              <password>*********</password>\n          </security>\n          <message_type>\n              <message_code>EQQ</message_code>\n              <event_type>Q04</event_type>\n              <message_structure>EQQ_Q04</message_structure>\n          </message_type>\n          <message_control_id>\n              <session_id>2022-04-11T17:28:15Z</session_id>\n              <message_num>1649698095</message_num>\n              <instance_num>0</instance_num>\n          </message_control_id>\n          <processing_id>\n              <processing_id>P</processing_id>\n              <processing_mode>I</processing_mode>\n          </processing_id>\n          <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n          <application_acknowledgement_type/>\n          <country_code>CH</country_code>\n          <project_id>Demo</project_id>\n      </message_header>\n      <request_header>\n          <result_waittime_ms>10000</result_waittime_ms>\n      </request_header>\n      <message_body>\n          <crcpdons:pdoheader>\n              <patient_set_limit>0</patient_set_limit>\n              <estimated_time>0</estimated_time>\n              <request_type>getPDO_fromInputList</request_type>\n          </crcpdons:pdoheader>\n          <crcpdons:request xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="crcpdons:GetPDOFromInputList_requestType">\n              <input_list>\n                  <patient_list max="1000000" min="0">\n                      <patient_set_coll_id>5</patient_set_coll_id>\n                  </patient_list>\n              </input_list>\n              <output_option name="none">\n                  <patient_set select="using_input_list" onlykeys="false" blob="false" techdata="false"/>\n              </output_option>\n          </crcpdons:request>\n      </message_body>\n  </msgns:request>	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns5:request xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <message_header>\n        <i2b2_version_compatible>0.3</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>GeCo i2b2 Data Source</application_name>\n            <application_version>0.2</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>GeCo</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>i2b2 cell</application_name>\n            <application_version>1.7</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-04-11T17:28:15Z</datetime_of_message>\n        <security>\n            <domain>i2b2demo</domain>\n            <username>demo</username>\n            <password is_token="false">password not stored</password>\n        </security>\n        <message_type>\n            <message_code>EQQ</message_code>\n            <event_type>Q04</event_type>\n            <message_structure>EQQ_Q04</message_structure>\n        </message_type>\n        <message_control_id>\n            <session_id>2022-04-11T17:28:15Z</session_id>\n            <message_num>1649698095</message_num>\n            <instance_num>0</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n        <application_acknowledgement_type></application_acknowledgement_type>\n        <country_code>CH</country_code>\n        <project_id>Demo</project_id>\n    </message_header>\n    <request_header>\n        <result_waittime_ms>10000</result_waittime_ms>\n    </request_header>\n    <message_body>\n        <ns3:pdoheader>\n            <patient_set_limit>0</patient_set_limit>\n            <estimated_time>0</estimated_time>\n            <request_type>getPDO_fromInputList</request_type>\n        </ns3:pdoheader>\n        <ns3:request xsi:type="ns3:GetPDOFromInputList_requestType" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">\n            <input_list>\n                <patient_list min="0" max="1000000">\n                    <patient_set_coll_id>5</patient_set_coll_id>\n                </patient_list>\n            </input_list>\n            <output_option>\n                <patient_set onlykeys="false" blob="false" techdata="false" select="using_input_list"/>\n            </output_option>\n        </ns3:request>\n    </message_body>\n</ns5:request>\n
4	demo	Demo	2022-04-11 17:29:07.668	<msgns:request xmlns:msgns="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:pdons="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ontns="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:crcpdons="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/" xmlns:crcpsmns="http://www.i2b2.org/xsd/cell/crc/psm/1.1/">\n      <message_header>\n          <i2b2_version_compatible>0.3</i2b2_version_compatible>\n          <hl7_version_compatible>2.4</hl7_version_compatible>\n          <sending_application>\n              <application_name>GeCo i2b2 Data Source</application_name>\n              <application_version>0.2</application_version>\n          </sending_application>\n          <sending_facility>\n              <facility_name>GeCo</facility_name>\n          </sending_facility>\n          <receiving_application>\n              <application_name>i2b2 cell</application_name>\n              <application_version>1.7</application_version>\n          </receiving_application>\n          <receiving_facility>\n              <facility_name>i2b2 hive</facility_name>\n          </receiving_facility>\n          <datetime_of_message>2022-04-11T17:29:07Z</datetime_of_message>\n          <security>\n              <domain>i2b2demo</domain>\n              <username>demo</username>\n              <password>*********</password>\n          </security>\n          <message_type>\n              <message_code>EQQ</message_code>\n              <event_type>Q04</event_type>\n              <message_structure>EQQ_Q04</message_structure>\n          </message_type>\n          <message_control_id>\n              <session_id>2022-04-11T17:29:07Z</session_id>\n              <message_num>1649698147</message_num>\n              <instance_num>0</instance_num>\n          </message_control_id>\n          <processing_id>\n              <processing_id>P</processing_id>\n              <processing_mode>I</processing_mode>\n          </processing_id>\n          <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n          <application_acknowledgement_type/>\n          <country_code>CH</country_code>\n          <project_id>Demo</project_id>\n      </message_header>\n      <request_header>\n          <result_waittime_ms>10000</result_waittime_ms>\n      </request_header>\n      <message_body>\n          <crcpdons:pdoheader>\n              <patient_set_limit>0</patient_set_limit>\n              <estimated_time>0</estimated_time>\n              <request_type>getPDO_fromInputList</request_type>\n          </crcpdons:pdoheader>\n          <crcpdons:request xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="crcpdons:GetPDOFromInputList_requestType">\n              <input_list>\n                  <patient_list max="1000000" min="0">\n                      <patient_set_coll_id>7</patient_set_coll_id>\n                  </patient_list>\n              </input_list>\n              <output_option name="none">\n                  <patient_set select="using_input_list" onlykeys="false" blob="false" techdata="false"/>\n              </output_option>\n          </crcpdons:request>\n      </message_body>\n  </msgns:request>	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns5:request xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <message_header>\n        <i2b2_version_compatible>0.3</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>GeCo i2b2 Data Source</application_name>\n            <application_version>0.2</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>GeCo</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>i2b2 cell</application_name>\n            <application_version>1.7</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-04-11T17:29:07Z</datetime_of_message>\n        <security>\n            <domain>i2b2demo</domain>\n            <username>demo</username>\n            <password is_token="false">password not stored</password>\n        </security>\n        <message_type>\n            <message_code>EQQ</message_code>\n            <event_type>Q04</event_type>\n            <message_structure>EQQ_Q04</message_structure>\n        </message_type>\n        <message_control_id>\n            <session_id>2022-04-11T17:29:07Z</session_id>\n            <message_num>1649698147</message_num>\n            <instance_num>0</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n        <application_acknowledgement_type></application_acknowledgement_type>\n        <country_code>CH</country_code>\n        <project_id>Demo</project_id>\n    </message_header>\n    <request_header>\n        <result_waittime_ms>10000</result_waittime_ms>\n    </request_header>\n    <message_body>\n        <ns3:pdoheader>\n            <patient_set_limit>0</patient_set_limit>\n            <estimated_time>0</estimated_time>\n            <request_type>getPDO_fromInputList</request_type>\n        </ns3:pdoheader>\n        <ns3:request xsi:type="ns3:GetPDOFromInputList_requestType" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">\n            <input_list>\n                <patient_list min="0" max="1000000">\n                    <patient_set_coll_id>7</patient_set_coll_id>\n                </patient_list>\n            </input_list>\n            <output_option>\n                <patient_set onlykeys="false" blob="false" techdata="false" select="using_input_list"/>\n            </output_option>\n        </ns3:request>\n    </message_body>\n</ns5:request>\n
5	demo	Demo	2022-04-12 09:33:36.531	<msgns:request xmlns:msgns="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:pdons="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ontns="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:crcpdons="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/" xmlns:crcpsmns="http://www.i2b2.org/xsd/cell/crc/psm/1.1/">\n      <message_header>\n          <i2b2_version_compatible>0.3</i2b2_version_compatible>\n          <hl7_version_compatible>2.4</hl7_version_compatible>\n          <sending_application>\n              <application_name>GeCo i2b2 Data Source</application_name>\n              <application_version>0.2</application_version>\n          </sending_application>\n          <sending_facility>\n              <facility_name>GeCo</facility_name>\n          </sending_facility>\n          <receiving_application>\n              <application_name>i2b2 cell</application_name>\n              <application_version>1.7</application_version>\n          </receiving_application>\n          <receiving_facility>\n              <facility_name>i2b2 hive</facility_name>\n          </receiving_facility>\n          <datetime_of_message>2022-04-12T09:33:36Z</datetime_of_message>\n          <security>\n              <domain>i2b2demo</domain>\n              <username>demo</username>\n              <password>*********</password>\n          </security>\n          <message_type>\n              <message_code>EQQ</message_code>\n              <event_type>Q04</event_type>\n              <message_structure>EQQ_Q04</message_structure>\n          </message_type>\n          <message_control_id>\n              <session_id>2022-04-12T09:33:36Z</session_id>\n              <message_num>1649756016</message_num>\n              <instance_num>0</instance_num>\n          </message_control_id>\n          <processing_id>\n              <processing_id>P</processing_id>\n              <processing_mode>I</processing_mode>\n          </processing_id>\n          <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n          <application_acknowledgement_type/>\n          <country_code>CH</country_code>\n          <project_id>Demo</project_id>\n      </message_header>\n      <request_header>\n          <result_waittime_ms>10000</result_waittime_ms>\n      </request_header>\n      <message_body>\n          <crcpdons:pdoheader>\n              <patient_set_limit>0</patient_set_limit>\n              <estimated_time>0</estimated_time>\n              <request_type>getPDO_fromInputList</request_type>\n          </crcpdons:pdoheader>\n          <crcpdons:request xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="crcpdons:GetPDOFromInputList_requestType">\n              <input_list>\n                  <patient_list max="1000000" min="0">\n                      <patient_set_coll_id>9</patient_set_coll_id>\n                  </patient_list>\n              </input_list>\n              <output_option name="none">\n                  <patient_set select="using_input_list" onlykeys="false" blob="false" techdata="false"/>\n              </output_option>\n          </crcpdons:request>\n      </message_body>\n  </msgns:request>	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns5:request xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <message_header>\n        <i2b2_version_compatible>0.3</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>GeCo i2b2 Data Source</application_name>\n            <application_version>0.2</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>GeCo</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>i2b2 cell</application_name>\n            <application_version>1.7</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-04-12T09:33:36Z</datetime_of_message>\n        <security>\n            <domain>i2b2demo</domain>\n            <username>demo</username>\n            <password is_token="false">password not stored</password>\n        </security>\n        <message_type>\n            <message_code>EQQ</message_code>\n            <event_type>Q04</event_type>\n            <message_structure>EQQ_Q04</message_structure>\n        </message_type>\n        <message_control_id>\n            <session_id>2022-04-12T09:33:36Z</session_id>\n            <message_num>1649756016</message_num>\n            <instance_num>0</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n        <application_acknowledgement_type></application_acknowledgement_type>\n        <country_code>CH</country_code>\n        <project_id>Demo</project_id>\n    </message_header>\n    <request_header>\n        <result_waittime_ms>10000</result_waittime_ms>\n    </request_header>\n    <message_body>\n        <ns3:pdoheader>\n            <patient_set_limit>0</patient_set_limit>\n            <estimated_time>0</estimated_time>\n            <request_type>getPDO_fromInputList</request_type>\n        </ns3:pdoheader>\n        <ns3:request xsi:type="ns3:GetPDOFromInputList_requestType" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">\n            <input_list>\n                <patient_list min="0" max="1000000">\n                    <patient_set_coll_id>9</patient_set_coll_id>\n                </patient_list>\n            </input_list>\n            <output_option>\n                <patient_set onlykeys="false" blob="false" techdata="false" select="using_input_list"/>\n            </output_option>\n        </ns3:request>\n    </message_body>\n</ns5:request>\n
6	demo	Demo	2022-04-21 09:10:05.193	<msgns:request xmlns:msgns="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:pdons="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ontns="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:crcpdons="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/" xmlns:crcpsmns="http://www.i2b2.org/xsd/cell/crc/psm/1.1/">\n      <message_header>\n          <i2b2_version_compatible>0.3</i2b2_version_compatible>\n          <hl7_version_compatible>2.4</hl7_version_compatible>\n          <sending_application>\n              <application_name>GeCo i2b2 Data Source</application_name>\n              <application_version>0.2</application_version>\n          </sending_application>\n          <sending_facility>\n              <facility_name>GeCo</facility_name>\n          </sending_facility>\n          <receiving_application>\n              <application_name>i2b2 cell</application_name>\n              <application_version>1.7</application_version>\n          </receiving_application>\n          <receiving_facility>\n              <facility_name>i2b2 hive</facility_name>\n          </receiving_facility>\n          <datetime_of_message>2022-04-21T09:10:05Z</datetime_of_message>\n          <security>\n              <domain>i2b2demo</domain>\n              <username>demo</username>\n              <password>*********</password>\n          </security>\n          <message_type>\n              <message_code>EQQ</message_code>\n              <event_type>Q04</event_type>\n              <message_structure>EQQ_Q04</message_structure>\n          </message_type>\n          <message_control_id>\n              <session_id>2022-04-21T09:10:05Z</session_id>\n              <message_num>1650532205</message_num>\n              <instance_num>0</instance_num>\n          </message_control_id>\n          <processing_id>\n              <processing_id>P</processing_id>\n              <processing_mode>I</processing_mode>\n          </processing_id>\n          <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n          <application_acknowledgement_type/>\n          <country_code>CH</country_code>\n          <project_id>Demo</project_id>\n      </message_header>\n      <request_header>\n          <result_waittime_ms>10000</result_waittime_ms>\n      </request_header>\n      <message_body>\n          <crcpdons:pdoheader>\n              <patient_set_limit>0</patient_set_limit>\n              <estimated_time>0</estimated_time>\n              <request_type>getPDO_fromInputList</request_type>\n          </crcpdons:pdoheader>\n          <crcpdons:request xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="crcpdons:GetPDOFromInputList_requestType">\n              <input_list>\n                  <patient_list max="1000000" min="0">\n                      <patient_set_coll_id>11</patient_set_coll_id>\n                  </patient_list>\n              </input_list>\n              <output_option name="none">\n                  <patient_set select="using_input_list" onlykeys="false" blob="false" techdata="false"/>\n              </output_option>\n          </crcpdons:request>\n      </message_body>\n  </msgns:request>	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns5:request xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <message_header>\n        <i2b2_version_compatible>0.3</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>GeCo i2b2 Data Source</application_name>\n            <application_version>0.2</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>GeCo</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>i2b2 cell</application_name>\n            <application_version>1.7</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-04-21T09:10:05Z</datetime_of_message>\n        <security>\n            <domain>i2b2demo</domain>\n            <username>demo</username>\n            <password is_token="false">password not stored</password>\n        </security>\n        <message_type>\n            <message_code>EQQ</message_code>\n            <event_type>Q04</event_type>\n            <message_structure>EQQ_Q04</message_structure>\n        </message_type>\n        <message_control_id>\n            <session_id>2022-04-21T09:10:05Z</session_id>\n            <message_num>1650532205</message_num>\n            <instance_num>0</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n        <application_acknowledgement_type></application_acknowledgement_type>\n        <country_code>CH</country_code>\n        <project_id>Demo</project_id>\n    </message_header>\n    <request_header>\n        <result_waittime_ms>10000</result_waittime_ms>\n    </request_header>\n    <message_body>\n        <ns3:pdoheader>\n            <patient_set_limit>0</patient_set_limit>\n            <estimated_time>0</estimated_time>\n            <request_type>getPDO_fromInputList</request_type>\n        </ns3:pdoheader>\n        <ns3:request xsi:type="ns3:GetPDOFromInputList_requestType" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">\n            <input_list>\n                <patient_list min="0" max="1000000">\n                    <patient_set_coll_id>11</patient_set_coll_id>\n                </patient_list>\n            </input_list>\n            <output_option>\n                <patient_set onlykeys="false" blob="false" techdata="false" select="using_input_list"/>\n            </output_option>\n        </ns3:request>\n    </message_body>\n</ns5:request>\n
7	demo	Demo	2022-04-21 09:12:10.354	<msgns:request xmlns:msgns="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:pdons="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ontns="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:crcpdons="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/" xmlns:crcpsmns="http://www.i2b2.org/xsd/cell/crc/psm/1.1/">\n      <message_header>\n          <i2b2_version_compatible>0.3</i2b2_version_compatible>\n          <hl7_version_compatible>2.4</hl7_version_compatible>\n          <sending_application>\n              <application_name>GeCo i2b2 Data Source</application_name>\n              <application_version>0.2</application_version>\n          </sending_application>\n          <sending_facility>\n              <facility_name>GeCo</facility_name>\n          </sending_facility>\n          <receiving_application>\n              <application_name>i2b2 cell</application_name>\n              <application_version>1.7</application_version>\n          </receiving_application>\n          <receiving_facility>\n              <facility_name>i2b2 hive</facility_name>\n          </receiving_facility>\n          <datetime_of_message>2022-04-21T09:12:10Z</datetime_of_message>\n          <security>\n              <domain>i2b2demo</domain>\n              <username>demo</username>\n              <password>*********</password>\n          </security>\n          <message_type>\n              <message_code>EQQ</message_code>\n              <event_type>Q04</event_type>\n              <message_structure>EQQ_Q04</message_structure>\n          </message_type>\n          <message_control_id>\n              <session_id>2022-04-21T09:12:10Z</session_id>\n              <message_num>1650532330</message_num>\n              <instance_num>0</instance_num>\n          </message_control_id>\n          <processing_id>\n              <processing_id>P</processing_id>\n              <processing_mode>I</processing_mode>\n          </processing_id>\n          <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n          <application_acknowledgement_type/>\n          <country_code>CH</country_code>\n          <project_id>Demo</project_id>\n      </message_header>\n      <request_header>\n          <result_waittime_ms>10000</result_waittime_ms>\n      </request_header>\n      <message_body>\n          <crcpdons:pdoheader>\n              <patient_set_limit>0</patient_set_limit>\n              <estimated_time>0</estimated_time>\n              <request_type>getPDO_fromInputList</request_type>\n          </crcpdons:pdoheader>\n          <crcpdons:request xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="crcpdons:GetPDOFromInputList_requestType">\n              <input_list>\n                  <patient_list max="1000000" min="0">\n                      <patient_set_coll_id>13</patient_set_coll_id>\n                  </patient_list>\n              </input_list>\n              <output_option name="none">\n                  <patient_set select="using_input_list" onlykeys="false" blob="false" techdata="false"/>\n              </output_option>\n          </crcpdons:request>\n      </message_body>\n  </msgns:request>	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns5:request xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <message_header>\n        <i2b2_version_compatible>0.3</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>GeCo i2b2 Data Source</application_name>\n            <application_version>0.2</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>GeCo</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>i2b2 cell</application_name>\n            <application_version>1.7</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-04-21T09:12:10Z</datetime_of_message>\n        <security>\n            <domain>i2b2demo</domain>\n            <username>demo</username>\n            <password is_token="false">password not stored</password>\n        </security>\n        <message_type>\n            <message_code>EQQ</message_code>\n            <event_type>Q04</event_type>\n            <message_structure>EQQ_Q04</message_structure>\n        </message_type>\n        <message_control_id>\n            <session_id>2022-04-21T09:12:10Z</session_id>\n            <message_num>1650532330</message_num>\n            <instance_num>0</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n        <application_acknowledgement_type></application_acknowledgement_type>\n        <country_code>CH</country_code>\n        <project_id>Demo</project_id>\n    </message_header>\n    <request_header>\n        <result_waittime_ms>10000</result_waittime_ms>\n    </request_header>\n    <message_body>\n        <ns3:pdoheader>\n            <patient_set_limit>0</patient_set_limit>\n            <estimated_time>0</estimated_time>\n            <request_type>getPDO_fromInputList</request_type>\n        </ns3:pdoheader>\n        <ns3:request xsi:type="ns3:GetPDOFromInputList_requestType" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">\n            <input_list>\n                <patient_list min="0" max="1000000">\n                    <patient_set_coll_id>13</patient_set_coll_id>\n                </patient_list>\n            </input_list>\n            <output_option>\n                <patient_set onlykeys="false" blob="false" techdata="false" select="using_input_list"/>\n            </output_option>\n        </ns3:request>\n    </message_body>\n</ns5:request>\n
\.


--
-- Data for Name: qt_privilege; Type: TABLE DATA; Schema: i2b2demodata; Owner: i2b2
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
-- Data for Name: qt_query_instance; Type: TABLE DATA; Schema: i2b2demodata; Owner: i2b2
--

COPY i2b2demodata.qt_query_instance (query_instance_id, query_master_id, user_id, group_id, batch_mode, start_date, end_date, delete_flag, status_type_id, message) FROM stdin;
-100	-100	demo	Demo	FINISHED	2022-03-04 22:19:50.704	2022-03-04 22:19:51.664	N	3	
1	1	demo	Demo	FINISHED	2022-04-11 17:25:15.368	2022-04-11 17:25:15.913	N	3	
2	2	demo	Demo	FINISHED	2022-04-11 17:26:10.05	2022-04-11 17:26:10.31	N	3	
3	3	demo	Demo	FINISHED	2022-04-11 17:28:13.588	2022-04-11 17:28:15.837	N	3	
4	4	demo	Demo	FINISHED	2022-04-11 17:29:07.186	2022-04-11 17:29:07.555	N	3	
5	5	demo	Demo	FINISHED	2022-04-12 09:33:35.105	2022-04-12 09:33:36.488	N	3	
6	6	demo	Demo	FINISHED	2022-04-21 09:10:04.804	2022-04-21 09:10:05.136	N	3	
7	7	demo	Demo	FINISHED	2022-04-21 09:12:10.042	2022-04-21 09:12:10.317	N	3	
\.


--
-- Data for Name: qt_query_master; Type: TABLE DATA; Schema: i2b2demodata; Owner: i2b2
--

COPY i2b2demodata.qt_query_master (query_master_id, name, user_id, group_id, master_type_cd, plugin_id, create_date, delete_date, delete_flag, request_xml, generated_sql, i2b2_request_xml, pm_xml) FROM stdin;
-100	63eb6d7e-d437-4f37-a346-4819ed1c74c1	demo	Demo	\N	\N	2022-03-04 22:19:50.602	\N	N	previous-query	generated-sql	i2b2_request_xml	pml-xml
1	3ccee0d7-e557-4858-83e0-28094e555d1c	demo	Demo	\N	\N	2022-04-11 17:25:15.305	\N	N	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns3:query_definition xmlns:ns2="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/">\n    <query_id>3ccee0d7-e557-4858-83e0-28094e555d1c</query_id>\n    <query_name>3ccee0d7-e557-4858-83e0-28094e555d1c</query_name>\n    <query_description>Query from GeCo i2b2 data source (3ccee0d7-e557-4858-83e0-28094e555d1c)</query_description>\n    <query_timing>ANY</query_timing>\n    <specificity_scale>0</specificity_scale>\n    <panel>\n        <panel_number>1</panel_number>\n        <panel_timing>sameinstancenum</panel_timing>\n        <panel_accuracy_scale>100</panel_accuracy_scale>\n        <invert>0</invert>\n        <total_item_occurrences>1</total_item_occurrences>\n        <item>\n            <hlevel>0</hlevel>\n            <item_name></item_name>\n            <item_key>\\\\sphn\\SPHNv2020.1\\SPOConcepts\\OncologyDrugTreatment\\</item_key>\n            <item_icon></item_icon>\n            <tooltip></tooltip>\n            <class></class>\n            <item_is_synonym>false</item_is_synonym>\n        </item>\n    </panel>\n</ns3:query_definition>\n	insert into QUERY_GLOBAL_TEMP (provider_id, start_date, concept_cd, instance_num, encounter_num,  patient_num, panel_count)\nwith t as ( \n select   f.provider_id, f.start_date, f.concept_cd, f.instance_num, f.encounter_num, f.patient_num  \nfrom i2b2demodata.observation_fact f \nwhere  \nf.CONCEPT_CD IN (select CONCEPT_CD from  i2b2demodata.CONCEPT_DIMENSION   where CONCEPT_PATH LIKE '\\\\SPHNv2020.1\\\\SPOConcepts\\\\OncologyDrugTreatment\\\\%')   \ngroup by  f.encounter_num ,f.instance_num, f.concept_cd,f.start_date,f.provider_id, f.patient_num \n ) \nselect t.provider_id, t.start_date, t.concept_cd, t.instance_num, t.encounter_num, t.patient_num, 0 as panel_count  from t \n<*>\n insert into DX (  patient_num   ) select * from ( select distinct  patient_num  from QUERY_GLOBAL_TEMP where panel_count = 0 ) q	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns5:request xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <message_header>\n        <i2b2_version_compatible>0.3</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>GeCo i2b2 Data Source</application_name>\n            <application_version>0.2</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>GeCo</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>i2b2 cell</application_name>\n            <application_version>1.7</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-04-11T17:25:14Z</datetime_of_message>\n        <security>\n            <domain>i2b2demo</domain>\n            <username>demo</username>\n            <password is_token="false">password not stored</password>\n        </security>\n        <message_type>\n            <message_code>EQQ</message_code>\n            <event_type>Q04</event_type>\n            <message_structure>EQQ_Q04</message_structure>\n        </message_type>\n        <message_control_id>\n            <session_id>2022-04-11T17:25:14Z</session_id>\n            <message_num>1649697914</message_num>\n            <instance_num>0</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n        <application_acknowledgement_type></application_acknowledgement_type>\n        <country_code>CH</country_code>\n        <project_id>Demo</project_id>\n    </message_header>\n    <request_header>\n        <result_waittime_ms>10000</result_waittime_ms>\n    </request_header>\n    <message_body>\n        <ns4:psmheader>\n            <user login="demo" group="i2b2demo">demo</user>\n            <patient_set_limit>0</patient_set_limit>\n            <estimated_time>0</estimated_time>\n            <query_mode>optimize_without_temp_table</query_mode>\n            <request_type>CRC_QRY_runQueryInstance_fromQueryDefinition</request_type>\n        </ns4:psmheader>\n        <ns4:request xsi:type="ns4:query_definition_requestType" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">\n            <query_definition>\n                <query_id>3ccee0d7-e557-4858-83e0-28094e555d1c</query_id>\n                <query_name>3ccee0d7-e557-4858-83e0-28094e555d1c</query_name>\n                <query_description>Query from GeCo i2b2 data source (3ccee0d7-e557-4858-83e0-28094e555d1c)</query_description>\n                <query_timing>ANY</query_timing>\n                <specificity_scale>0</specificity_scale>\n                <panel>\n                    <panel_number>1</panel_number>\n                    <panel_timing>sameinstancenum</panel_timing>\n                    <panel_accuracy_scale>100</panel_accuracy_scale>\n                    <invert>0</invert>\n                    <total_item_occurrences>1</total_item_occurrences>\n                    <item>\n                        <hlevel>0</hlevel>\n                        <item_name></item_name>\n                        <item_key>\\\\sphn\\SPHNv2020.1\\SPOConcepts\\OncologyDrugTreatment\\</item_key>\n                        <item_icon></item_icon>\n                        <tooltip></tooltip>\n                        <class></class>\n                        <item_is_synonym>false</item_is_synonym>\n                    </item>\n                </panel>\n            </query_definition>\n            <result_output_list>\n                <result_output name="PATIENTSET" priority_index="1"/>\n                <result_output name="PATIENT_COUNT_XML" priority_index="2"/>\n            </result_output_list>\n        </ns4:request>\n    </message_body>\n</ns5:request>\n	<ns2:response xmlns:ns2="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/hive/msg/version/">\n    <message_header>\n        <i2b2_version_compatible>1.1</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>PM Cell</application_name>\n            <application_version>1.700</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>i2b2 Hive</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>PM Cell</application_name>\n            <application_version>1.700</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 Hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-04-11T17:25:15.336Z</datetime_of_message>\n        <message_control_id>\n            <instance_num>1</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>AL</accept_acknowledgement_type>\n        <application_acknowledgement_type>AL</application_acknowledgement_type>\n        <country_code>US</country_code>\n        <project_id/>\n    </message_header>\n    <response_header>\n        <result_status>\n            <status type="DONE">PM processing completed</status>\n        </result_status>\n    </response_header>\n    <message_body>\n        <ns4:configure>\n            <environment>DEVELOPMENT</environment>\n            <helpURL>http://www.i2b2.org</helpURL>\n            <user>\n                <full_name>i2b2 User</full_name>\n                <user_name>demo</user_name>\n                <password is_token="true" token_ms_timeout="1800000">SessionKey:0iHWpopvH7JCefYXRdkj</password>\n                <domain>i2b2demo</domain>\n                <is_admin>false</is_admin>\n                <project id="Demo">\n                    <name>i2b2 Demo</name>\n                    <wiki>http://www.i2b2.org</wiki>\n                    <path>/Demo</path>\n                    <role>DATA_AGG</role>\n                    <role>DATA_DEID</role>\n                    <role>DATA_LDS</role>\n                    <role>DATA_OBFSC</role>\n                    <role>DATA_PROT</role>\n                    <role>EDITOR</role>\n                    <role>USER</role>\n                </project>\n            </user>\n            <domain_name>i2b2demo</domain_name>\n            <domain_id>i2b2demo</domain_id>\n            <active>true</active>\n            <cell_datas>\n                <cell_data id="CRC">\n                    <name>Data Repository</name>\n                    <url>http://i2b2:8080/i2b2/services/QueryToolService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="FRC">\n                    <name>File Repository </name>\n                    <url>http://i2b2:8080/i2b2/services/FRService/</url>\n                    <project_path>/</project_path>\n                    <method>SOAP</method>\n                    <can_override>true</can_override>\n                    <param name="DestDir" id="1" datatype="T">/opt/jboss/wildfly/standalone/data/i2b2_FR_files</param>\n                </cell_data>\n                <cell_data id="ONT">\n                    <name>Ontology Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/OntologyService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="WORK">\n                    <name>Workplace Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/WorkplaceService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="IM">\n                    <name>IM Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/IMService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n            </cell_datas>\n            <global_data/>\n        </ns4:configure>\n    </message_body>\n</ns2:response>
2	28934242-297b-49b5-be41-0fbd4273fc84	demo	Demo	\N	\N	2022-04-11 17:26:10.006	\N	N	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns3:query_definition xmlns:ns2="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/">\n    <query_id>28934242-297b-49b5-be41-0fbd4273fc84</query_id>\n    <query_name>28934242-297b-49b5-be41-0fbd4273fc84</query_name>\n    <query_description>Query from GeCo i2b2 data source (28934242-297b-49b5-be41-0fbd4273fc84)</query_description>\n    <query_timing>ANY</query_timing>\n    <specificity_scale>0</specificity_scale>\n    <panel>\n        <panel_number>1</panel_number>\n        <panel_timing>sameinstancenum</panel_timing>\n        <panel_accuracy_scale>100</panel_accuracy_scale>\n        <invert>0</invert>\n        <total_item_occurrences>1</total_item_occurrences>\n        <item>\n            <hlevel>0</hlevel>\n            <item_name></item_name>\n            <item_key>\\\\sphn\\SPHNv2020.1\\SPOConcepts\\OncologyDrugTreatment\\</item_key>\n            <item_icon></item_icon>\n            <tooltip></tooltip>\n            <class></class>\n            <item_is_synonym>false</item_is_synonym>\n        </item>\n    </panel>\n</ns3:query_definition>\n	insert into QUERY_GLOBAL_TEMP (provider_id, start_date, concept_cd, instance_num, encounter_num,  patient_num, panel_count)\nwith t as ( \n select   f.provider_id, f.start_date, f.concept_cd, f.instance_num, f.encounter_num, f.patient_num  \nfrom i2b2demodata.observation_fact f \nwhere  \nf.CONCEPT_CD IN (select CONCEPT_CD from  i2b2demodata.CONCEPT_DIMENSION   where CONCEPT_PATH LIKE '\\\\SPHNv2020.1\\\\SPOConcepts\\\\OncologyDrugTreatment\\\\%')   \ngroup by  f.encounter_num ,f.instance_num, f.concept_cd,f.start_date,f.provider_id, f.patient_num \n ) \nselect t.provider_id, t.start_date, t.concept_cd, t.instance_num, t.encounter_num, t.patient_num, 0 as panel_count  from t \n<*>\n insert into DX (  patient_num   ) select * from ( select distinct  patient_num  from QUERY_GLOBAL_TEMP where panel_count = 0 ) q	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns5:request xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <message_header>\n        <i2b2_version_compatible>0.3</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>GeCo i2b2 Data Source</application_name>\n            <application_version>0.2</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>GeCo</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>i2b2 cell</application_name>\n            <application_version>1.7</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-04-11T17:26:09Z</datetime_of_message>\n        <security>\n            <domain>i2b2demo</domain>\n            <username>demo</username>\n            <password is_token="false">password not stored</password>\n        </security>\n        <message_type>\n            <message_code>EQQ</message_code>\n            <event_type>Q04</event_type>\n            <message_structure>EQQ_Q04</message_structure>\n        </message_type>\n        <message_control_id>\n            <session_id>2022-04-11T17:26:09Z</session_id>\n            <message_num>1649697969</message_num>\n            <instance_num>0</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n        <application_acknowledgement_type></application_acknowledgement_type>\n        <country_code>CH</country_code>\n        <project_id>Demo</project_id>\n    </message_header>\n    <request_header>\n        <result_waittime_ms>10000</result_waittime_ms>\n    </request_header>\n    <message_body>\n        <ns4:psmheader>\n            <user login="demo" group="i2b2demo">demo</user>\n            <patient_set_limit>0</patient_set_limit>\n            <estimated_time>0</estimated_time>\n            <query_mode>optimize_without_temp_table</query_mode>\n            <request_type>CRC_QRY_runQueryInstance_fromQueryDefinition</request_type>\n        </ns4:psmheader>\n        <ns4:request xsi:type="ns4:query_definition_requestType" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">\n            <query_definition>\n                <query_id>28934242-297b-49b5-be41-0fbd4273fc84</query_id>\n                <query_name>28934242-297b-49b5-be41-0fbd4273fc84</query_name>\n                <query_description>Query from GeCo i2b2 data source (28934242-297b-49b5-be41-0fbd4273fc84)</query_description>\n                <query_timing>ANY</query_timing>\n                <specificity_scale>0</specificity_scale>\n                <panel>\n                    <panel_number>1</panel_number>\n                    <panel_timing>sameinstancenum</panel_timing>\n                    <panel_accuracy_scale>100</panel_accuracy_scale>\n                    <invert>0</invert>\n                    <total_item_occurrences>1</total_item_occurrences>\n                    <item>\n                        <hlevel>0</hlevel>\n                        <item_name></item_name>\n                        <item_key>\\\\sphn\\SPHNv2020.1\\SPOConcepts\\OncologyDrugTreatment\\</item_key>\n                        <item_icon></item_icon>\n                        <tooltip></tooltip>\n                        <class></class>\n                        <item_is_synonym>false</item_is_synonym>\n                    </item>\n                </panel>\n            </query_definition>\n            <result_output_list>\n                <result_output name="PATIENTSET" priority_index="1"/>\n                <result_output name="PATIENT_COUNT_XML" priority_index="2"/>\n            </result_output_list>\n        </ns4:request>\n    </message_body>\n</ns5:request>\n	<ns2:response xmlns:ns2="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/hive/msg/version/">\n    <message_header>\n        <i2b2_version_compatible>1.1</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>PM Cell</application_name>\n            <application_version>1.700</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>i2b2 Hive</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>PM Cell</application_name>\n            <application_version>1.700</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 Hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-04-11T17:26:10.042Z</datetime_of_message>\n        <message_control_id>\n            <instance_num>1</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>AL</accept_acknowledgement_type>\n        <application_acknowledgement_type>AL</application_acknowledgement_type>\n        <country_code>US</country_code>\n        <project_id/>\n    </message_header>\n    <response_header>\n        <result_status>\n            <status type="DONE">PM processing completed</status>\n        </result_status>\n    </response_header>\n    <message_body>\n        <ns4:configure>\n            <environment>DEVELOPMENT</environment>\n            <helpURL>http://www.i2b2.org</helpURL>\n            <user>\n                <full_name>i2b2 User</full_name>\n                <user_name>demo</user_name>\n                <password is_token="true" token_ms_timeout="1800000">SessionKey:cu73saOpVZ5zn3Tdvoa0</password>\n                <domain>i2b2demo</domain>\n                <is_admin>false</is_admin>\n                <project id="Demo">\n                    <name>i2b2 Demo</name>\n                    <wiki>http://www.i2b2.org</wiki>\n                    <path>/Demo</path>\n                    <role>DATA_AGG</role>\n                    <role>DATA_DEID</role>\n                    <role>DATA_LDS</role>\n                    <role>DATA_OBFSC</role>\n                    <role>DATA_PROT</role>\n                    <role>EDITOR</role>\n                    <role>USER</role>\n                </project>\n            </user>\n            <domain_name>i2b2demo</domain_name>\n            <domain_id>i2b2demo</domain_id>\n            <active>true</active>\n            <cell_datas>\n                <cell_data id="CRC">\n                    <name>Data Repository</name>\n                    <url>http://i2b2:8080/i2b2/services/QueryToolService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="FRC">\n                    <name>File Repository </name>\n                    <url>http://i2b2:8080/i2b2/services/FRService/</url>\n                    <project_path>/</project_path>\n                    <method>SOAP</method>\n                    <can_override>true</can_override>\n                    <param name="DestDir" id="1" datatype="T">/opt/jboss/wildfly/standalone/data/i2b2_FR_files</param>\n                </cell_data>\n                <cell_data id="ONT">\n                    <name>Ontology Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/OntologyService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="WORK">\n                    <name>Workplace Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/WorkplaceService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="IM">\n                    <name>IM Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/IMService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n            </cell_datas>\n            <global_data/>\n        </ns4:configure>\n    </message_body>\n</ns2:response>
3	00cd2146-8c76-4106-abc4-836b5d21f0af	demo	Demo	\N	\N	2022-04-11 17:28:13.321	\N	N	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns3:query_definition xmlns:ns2="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/">\n    <query_id>00cd2146-8c76-4106-abc4-836b5d21f0af</query_id>\n    <query_name>00cd2146-8c76-4106-abc4-836b5d21f0af</query_name>\n    <query_description>Query from GeCo i2b2 data source (00cd2146-8c76-4106-abc4-836b5d21f0af)</query_description>\n    <query_timing>ANY</query_timing>\n    <specificity_scale>0</specificity_scale>\n    <panel>\n        <panel_number>1</panel_number>\n        <panel_timing>sameinstancenum</panel_timing>\n        <panel_accuracy_scale>100</panel_accuracy_scale>\n        <invert>0</invert>\n        <total_item_occurrences>1</total_item_occurrences>\n        <item>\n            <hlevel>0</hlevel>\n            <item_name></item_name>\n            <item_key>\\\\sphn\\SPHNv2020.1\\SPOConcepts\\OncologyDrugTreatment\\</item_key>\n            <item_icon></item_icon>\n            <tooltip></tooltip>\n            <class></class>\n            <item_is_synonym>false</item_is_synonym>\n        </item>\n    </panel>\n</ns3:query_definition>\n	insert into QUERY_GLOBAL_TEMP (provider_id, start_date, concept_cd, instance_num, encounter_num,  patient_num, panel_count)\nwith t as ( \n select   f.provider_id, f.start_date, f.concept_cd, f.instance_num, f.encounter_num, f.patient_num  \nfrom i2b2demodata.observation_fact f \nwhere  \nf.CONCEPT_CD IN (select CONCEPT_CD from  i2b2demodata.CONCEPT_DIMENSION   where CONCEPT_PATH LIKE '\\\\SPHNv2020.1\\\\SPOConcepts\\\\OncologyDrugTreatment\\\\%')   \ngroup by  f.encounter_num ,f.instance_num, f.concept_cd,f.start_date,f.provider_id, f.patient_num \n ) \nselect t.provider_id, t.start_date, t.concept_cd, t.instance_num, t.encounter_num, t.patient_num, 0 as panel_count  from t \n<*>\n insert into DX (  patient_num   ) select * from ( select distinct  patient_num  from QUERY_GLOBAL_TEMP where panel_count = 0 ) q	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns5:request xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <message_header>\n        <i2b2_version_compatible>0.3</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>GeCo i2b2 Data Source</application_name>\n            <application_version>0.2</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>GeCo</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>i2b2 cell</application_name>\n            <application_version>1.7</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-04-11T17:28:13Z</datetime_of_message>\n        <security>\n            <domain>i2b2demo</domain>\n            <username>demo</username>\n            <password is_token="false">password not stored</password>\n        </security>\n        <message_type>\n            <message_code>EQQ</message_code>\n            <event_type>Q04</event_type>\n            <message_structure>EQQ_Q04</message_structure>\n        </message_type>\n        <message_control_id>\n            <session_id>2022-04-11T17:28:13Z</session_id>\n            <message_num>1649698093</message_num>\n            <instance_num>0</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n        <application_acknowledgement_type></application_acknowledgement_type>\n        <country_code>CH</country_code>\n        <project_id>Demo</project_id>\n    </message_header>\n    <request_header>\n        <result_waittime_ms>10000</result_waittime_ms>\n    </request_header>\n    <message_body>\n        <ns4:psmheader>\n            <user login="demo" group="i2b2demo">demo</user>\n            <patient_set_limit>0</patient_set_limit>\n            <estimated_time>0</estimated_time>\n            <query_mode>optimize_without_temp_table</query_mode>\n            <request_type>CRC_QRY_runQueryInstance_fromQueryDefinition</request_type>\n        </ns4:psmheader>\n        <ns4:request xsi:type="ns4:query_definition_requestType" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">\n            <query_definition>\n                <query_id>00cd2146-8c76-4106-abc4-836b5d21f0af</query_id>\n                <query_name>00cd2146-8c76-4106-abc4-836b5d21f0af</query_name>\n                <query_description>Query from GeCo i2b2 data source (00cd2146-8c76-4106-abc4-836b5d21f0af)</query_description>\n                <query_timing>ANY</query_timing>\n                <specificity_scale>0</specificity_scale>\n                <panel>\n                    <panel_number>1</panel_number>\n                    <panel_timing>sameinstancenum</panel_timing>\n                    <panel_accuracy_scale>100</panel_accuracy_scale>\n                    <invert>0</invert>\n                    <total_item_occurrences>1</total_item_occurrences>\n                    <item>\n                        <hlevel>0</hlevel>\n                        <item_name></item_name>\n                        <item_key>\\\\sphn\\SPHNv2020.1\\SPOConcepts\\OncologyDrugTreatment\\</item_key>\n                        <item_icon></item_icon>\n                        <tooltip></tooltip>\n                        <class></class>\n                        <item_is_synonym>false</item_is_synonym>\n                    </item>\n                </panel>\n            </query_definition>\n            <result_output_list>\n                <result_output name="PATIENTSET" priority_index="1"/>\n                <result_output name="PATIENT_COUNT_XML" priority_index="2"/>\n            </result_output_list>\n        </ns4:request>\n    </message_body>\n</ns5:request>\n	<ns2:response xmlns:ns2="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/hive/msg/version/">\n    <message_header>\n        <i2b2_version_compatible>1.1</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>PM Cell</application_name>\n            <application_version>1.700</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>i2b2 Hive</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>PM Cell</application_name>\n            <application_version>1.700</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 Hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-04-11T17:28:13.428Z</datetime_of_message>\n        <message_control_id>\n            <instance_num>1</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>AL</accept_acknowledgement_type>\n        <application_acknowledgement_type>AL</application_acknowledgement_type>\n        <country_code>US</country_code>\n        <project_id/>\n    </message_header>\n    <response_header>\n        <result_status>\n            <status type="DONE">PM processing completed</status>\n        </result_status>\n    </response_header>\n    <message_body>\n        <ns4:configure>\n            <environment>DEVELOPMENT</environment>\n            <helpURL>http://www.i2b2.org</helpURL>\n            <user>\n                <full_name>i2b2 User</full_name>\n                <user_name>demo</user_name>\n                <password is_token="true" token_ms_timeout="1800000">SessionKey:3F6Tkbr4QsjKnu5a2sWl</password>\n                <domain>i2b2demo</domain>\n                <is_admin>false</is_admin>\n                <project id="Demo">\n                    <name>i2b2 Demo</name>\n                    <wiki>http://www.i2b2.org</wiki>\n                    <path>/Demo</path>\n                    <role>DATA_AGG</role>\n                    <role>DATA_DEID</role>\n                    <role>DATA_LDS</role>\n                    <role>DATA_OBFSC</role>\n                    <role>DATA_PROT</role>\n                    <role>EDITOR</role>\n                    <role>USER</role>\n                </project>\n            </user>\n            <domain_name>i2b2demo</domain_name>\n            <domain_id>i2b2demo</domain_id>\n            <active>true</active>\n            <cell_datas>\n                <cell_data id="CRC">\n                    <name>Data Repository</name>\n                    <url>http://i2b2:8080/i2b2/services/QueryToolService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="FRC">\n                    <name>File Repository </name>\n                    <url>http://i2b2:8080/i2b2/services/FRService/</url>\n                    <project_path>/</project_path>\n                    <method>SOAP</method>\n                    <can_override>true</can_override>\n                    <param name="DestDir" id="1" datatype="T">/opt/jboss/wildfly/standalone/data/i2b2_FR_files</param>\n                </cell_data>\n                <cell_data id="ONT">\n                    <name>Ontology Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/OntologyService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="WORK">\n                    <name>Workplace Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/WorkplaceService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="IM">\n                    <name>IM Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/IMService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n            </cell_datas>\n            <global_data/>\n        </ns4:configure>\n    </message_body>\n</ns2:response>
4	5f543055-19b0-43f9-badc-d2b19f44388e	demo	Demo	\N	\N	2022-04-11 17:29:07.133	\N	N	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns3:query_definition xmlns:ns2="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/">\n    <query_id>5f543055-19b0-43f9-badc-d2b19f44388e</query_id>\n    <query_name>5f543055-19b0-43f9-badc-d2b19f44388e</query_name>\n    <query_description>Query from GeCo i2b2 data source (5f543055-19b0-43f9-badc-d2b19f44388e)</query_description>\n    <query_timing>ANY</query_timing>\n    <specificity_scale>0</specificity_scale>\n    <panel>\n        <panel_number>1</panel_number>\n        <panel_timing>sameinstancenum</panel_timing>\n        <panel_accuracy_scale>100</panel_accuracy_scale>\n        <invert>0</invert>\n        <total_item_occurrences>1</total_item_occurrences>\n        <item>\n            <hlevel>0</hlevel>\n            <item_name></item_name>\n            <item_key>\\\\sphn\\SPHNv2020.1\\SPOConcepts\\OncologyDrugTreatment\\</item_key>\n            <item_icon></item_icon>\n            <tooltip></tooltip>\n            <class></class>\n            <item_is_synonym>false</item_is_synonym>\n        </item>\n    </panel>\n</ns3:query_definition>\n	insert into QUERY_GLOBAL_TEMP (provider_id, start_date, concept_cd, instance_num, encounter_num,  patient_num, panel_count)\nwith t as ( \n select   f.provider_id, f.start_date, f.concept_cd, f.instance_num, f.encounter_num, f.patient_num  \nfrom i2b2demodata.observation_fact f \nwhere  \nf.CONCEPT_CD IN (select CONCEPT_CD from  i2b2demodata.CONCEPT_DIMENSION   where CONCEPT_PATH LIKE '\\\\SPHNv2020.1\\\\SPOConcepts\\\\OncologyDrugTreatment\\\\%')   \ngroup by  f.encounter_num ,f.instance_num, f.concept_cd,f.start_date,f.provider_id, f.patient_num \n ) \nselect t.provider_id, t.start_date, t.concept_cd, t.instance_num, t.encounter_num, t.patient_num, 0 as panel_count  from t \n<*>\n insert into DX (  patient_num   ) select * from ( select distinct  patient_num  from QUERY_GLOBAL_TEMP where panel_count = 0 ) q	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns5:request xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <message_header>\n        <i2b2_version_compatible>0.3</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>GeCo i2b2 Data Source</application_name>\n            <application_version>0.2</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>GeCo</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>i2b2 cell</application_name>\n            <application_version>1.7</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-04-11T17:29:07Z</datetime_of_message>\n        <security>\n            <domain>i2b2demo</domain>\n            <username>demo</username>\n            <password is_token="false">password not stored</password>\n        </security>\n        <message_type>\n            <message_code>EQQ</message_code>\n            <event_type>Q04</event_type>\n            <message_structure>EQQ_Q04</message_structure>\n        </message_type>\n        <message_control_id>\n            <session_id>2022-04-11T17:29:07Z</session_id>\n            <message_num>1649698147</message_num>\n            <instance_num>0</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n        <application_acknowledgement_type></application_acknowledgement_type>\n        <country_code>CH</country_code>\n        <project_id>Demo</project_id>\n    </message_header>\n    <request_header>\n        <result_waittime_ms>10000</result_waittime_ms>\n    </request_header>\n    <message_body>\n        <ns4:psmheader>\n            <user login="demo" group="i2b2demo">demo</user>\n            <patient_set_limit>0</patient_set_limit>\n            <estimated_time>0</estimated_time>\n            <query_mode>optimize_without_temp_table</query_mode>\n            <request_type>CRC_QRY_runQueryInstance_fromQueryDefinition</request_type>\n        </ns4:psmheader>\n        <ns4:request xsi:type="ns4:query_definition_requestType" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">\n            <query_definition>\n                <query_id>5f543055-19b0-43f9-badc-d2b19f44388e</query_id>\n                <query_name>5f543055-19b0-43f9-badc-d2b19f44388e</query_name>\n                <query_description>Query from GeCo i2b2 data source (5f543055-19b0-43f9-badc-d2b19f44388e)</query_description>\n                <query_timing>ANY</query_timing>\n                <specificity_scale>0</specificity_scale>\n                <panel>\n                    <panel_number>1</panel_number>\n                    <panel_timing>sameinstancenum</panel_timing>\n                    <panel_accuracy_scale>100</panel_accuracy_scale>\n                    <invert>0</invert>\n                    <total_item_occurrences>1</total_item_occurrences>\n                    <item>\n                        <hlevel>0</hlevel>\n                        <item_name></item_name>\n                        <item_key>\\\\sphn\\SPHNv2020.1\\SPOConcepts\\OncologyDrugTreatment\\</item_key>\n                        <item_icon></item_icon>\n                        <tooltip></tooltip>\n                        <class></class>\n                        <item_is_synonym>false</item_is_synonym>\n                    </item>\n                </panel>\n            </query_definition>\n            <result_output_list>\n                <result_output name="PATIENTSET" priority_index="1"/>\n                <result_output name="PATIENT_COUNT_XML" priority_index="2"/>\n            </result_output_list>\n        </ns4:request>\n    </message_body>\n</ns5:request>\n	<ns2:response xmlns:ns2="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/hive/msg/version/">\n    <message_header>\n        <i2b2_version_compatible>1.1</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>PM Cell</application_name>\n            <application_version>1.700</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>i2b2 Hive</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>PM Cell</application_name>\n            <application_version>1.700</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 Hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-04-11T17:29:07.170Z</datetime_of_message>\n        <message_control_id>\n            <instance_num>1</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>AL</accept_acknowledgement_type>\n        <application_acknowledgement_type>AL</application_acknowledgement_type>\n        <country_code>US</country_code>\n        <project_id/>\n    </message_header>\n    <response_header>\n        <result_status>\n            <status type="DONE">PM processing completed</status>\n        </result_status>\n    </response_header>\n    <message_body>\n        <ns4:configure>\n            <environment>DEVELOPMENT</environment>\n            <helpURL>http://www.i2b2.org</helpURL>\n            <user>\n                <full_name>i2b2 User</full_name>\n                <user_name>demo</user_name>\n                <password is_token="true" token_ms_timeout="1800000">SessionKey:gfVUrnxY68IryrLhWc6P</password>\n                <domain>i2b2demo</domain>\n                <is_admin>false</is_admin>\n                <project id="Demo">\n                    <name>i2b2 Demo</name>\n                    <wiki>http://www.i2b2.org</wiki>\n                    <path>/Demo</path>\n                    <role>DATA_AGG</role>\n                    <role>DATA_DEID</role>\n                    <role>DATA_LDS</role>\n                    <role>DATA_OBFSC</role>\n                    <role>DATA_PROT</role>\n                    <role>EDITOR</role>\n                    <role>USER</role>\n                </project>\n            </user>\n            <domain_name>i2b2demo</domain_name>\n            <domain_id>i2b2demo</domain_id>\n            <active>true</active>\n            <cell_datas>\n                <cell_data id="CRC">\n                    <name>Data Repository</name>\n                    <url>http://i2b2:8080/i2b2/services/QueryToolService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="FRC">\n                    <name>File Repository </name>\n                    <url>http://i2b2:8080/i2b2/services/FRService/</url>\n                    <project_path>/</project_path>\n                    <method>SOAP</method>\n                    <can_override>true</can_override>\n                    <param name="DestDir" id="1" datatype="T">/opt/jboss/wildfly/standalone/data/i2b2_FR_files</param>\n                </cell_data>\n                <cell_data id="ONT">\n                    <name>Ontology Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/OntologyService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="WORK">\n                    <name>Workplace Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/WorkplaceService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="IM">\n                    <name>IM Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/IMService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n            </cell_datas>\n            <global_data/>\n        </ns4:configure>\n    </message_body>\n</ns2:response>
5	6564291a-52f6-4e88-baf1-cc593afcca29	demo	Demo	\N	\N	2022-04-12 09:33:35.042	\N	N	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns3:query_definition xmlns:ns2="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/">\n    <query_id>6564291a-52f6-4e88-baf1-cc593afcca29</query_id>\n    <query_name>6564291a-52f6-4e88-baf1-cc593afcca29</query_name>\n    <query_description>Query from GeCo i2b2 data source (6564291a-52f6-4e88-baf1-cc593afcca29)</query_description>\n    <query_timing>ANY</query_timing>\n    <specificity_scale>0</specificity_scale>\n    <panel>\n        <panel_number>1</panel_number>\n        <panel_timing>sameinstancenum</panel_timing>\n        <panel_accuracy_scale>100</panel_accuracy_scale>\n        <invert>0</invert>\n        <total_item_occurrences>1</total_item_occurrences>\n        <item>\n            <hlevel>0</hlevel>\n            <item_name></item_name>\n            <item_key>\\\\sphn\\SPHNv2020.1\\Consent\\</item_key>\n            <item_icon></item_icon>\n            <tooltip></tooltip>\n            <class></class>\n            <constrain_by_modifier>\n                <modifier_key>\\\\sphn\\A122-Consent::status\\accepted\\</modifier_key>\n                <applied_path>\\SPHNv2020.1\\Consent\\</applied_path>\n            </constrain_by_modifier>\n            <item_is_synonym>false</item_is_synonym>\n        </item>\n        <item>\n            <hlevel>0</hlevel>\n            <item_name></item_name>\n            <item_key>\\\\sphn\\SPHNv2020.1\\Consent\\</item_key>\n            <item_icon></item_icon>\n            <tooltip></tooltip>\n            <class></class>\n            <constrain_by_modifier>\n                <modifier_key>\\\\sphn\\A122-Consent::status\\refused\\</modifier_key>\n                <applied_path>\\SPHNv2020.1\\Consent\\</applied_path>\n            </constrain_by_modifier>\n            <item_is_synonym>false</item_is_synonym>\n        </item>\n    </panel>\n</ns3:query_definition>\n	insert into QUERY_GLOBAL_TEMP (provider_id, start_date, concept_cd, instance_num, encounter_num,  patient_num, panel_count)\nwith t as ( \n select   f.provider_id, f.start_date, f.concept_cd, f.instance_num, f.encounter_num, f.patient_num  \nfrom i2b2demodata.observation_fact f \nwhere  \nf.CONCEPT_CD IN (select CONCEPT_CD from  i2b2demodata.CONCEPT_DIMENSION   where CONCEPT_PATH LIKE '\\\\SPHNv2020.1\\\\Consent\\\\%')  \n AND  (f.MODIFIER_CD IN  (select MODIFIER_CD from i2b2demodata.MODIFIER_DIMENSION where MODIFIER_PATH LIKE '\\\\A122-Consent::status\\\\accepted\\\\%'))  \ngroup by  f.encounter_num ,f.instance_num, f.concept_cd,f.start_date,f.provider_id, f.patient_num \n ) \nselect t.provider_id, t.start_date, t.concept_cd, t.instance_num, t.encounter_num, t.patient_num, 0 as panel_count  from t \n<*>\ninsert into QUERY_GLOBAL_TEMP (provider_id, start_date, concept_cd, instance_num, encounter_num,  patient_num, panel_count)\nwith t as ( \n select   f.provider_id, f.start_date, f.concept_cd, f.instance_num, f.encounter_num, f.patient_num  \nfrom i2b2demodata.observation_fact f \nwhere  \nf.CONCEPT_CD IN (select CONCEPT_CD from  i2b2demodata.CONCEPT_DIMENSION   where CONCEPT_PATH LIKE '\\\\SPHNv2020.1\\\\Consent\\\\%')  \n AND  (f.MODIFIER_CD IN  (select MODIFIER_CD from i2b2demodata.MODIFIER_DIMENSION where MODIFIER_PATH LIKE '\\\\A122-Consent::status\\\\refused\\\\%'))  \ngroup by  f.encounter_num ,f.instance_num, f.concept_cd,f.start_date,f.provider_id, f.patient_num \n ) \nselect t.provider_id, t.start_date, t.concept_cd, t.instance_num, t.encounter_num, t.patient_num, 0 as panel_count  from t \n<*>\n insert into DX (  patient_num   ) select * from ( select distinct  patient_num  from QUERY_GLOBAL_TEMP where panel_count = 0 ) q	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns5:request xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <message_header>\n        <i2b2_version_compatible>0.3</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>GeCo i2b2 Data Source</application_name>\n            <application_version>0.2</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>GeCo</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>i2b2 cell</application_name>\n            <application_version>1.7</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-04-12T09:33:34Z</datetime_of_message>\n        <security>\n            <domain>i2b2demo</domain>\n            <username>demo</username>\n            <password is_token="false">password not stored</password>\n        </security>\n        <message_type>\n            <message_code>EQQ</message_code>\n            <event_type>Q04</event_type>\n            <message_structure>EQQ_Q04</message_structure>\n        </message_type>\n        <message_control_id>\n            <session_id>2022-04-12T09:33:34Z</session_id>\n            <message_num>1649756014</message_num>\n            <instance_num>0</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n        <application_acknowledgement_type></application_acknowledgement_type>\n        <country_code>CH</country_code>\n        <project_id>Demo</project_id>\n    </message_header>\n    <request_header>\n        <result_waittime_ms>10000</result_waittime_ms>\n    </request_header>\n    <message_body>\n        <ns4:psmheader>\n            <user login="demo" group="i2b2demo">demo</user>\n            <patient_set_limit>0</patient_set_limit>\n            <estimated_time>0</estimated_time>\n            <query_mode>optimize_without_temp_table</query_mode>\n            <request_type>CRC_QRY_runQueryInstance_fromQueryDefinition</request_type>\n        </ns4:psmheader>\n        <ns4:request xsi:type="ns4:query_definition_requestType" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">\n            <query_definition>\n                <query_id>6564291a-52f6-4e88-baf1-cc593afcca29</query_id>\n                <query_name>6564291a-52f6-4e88-baf1-cc593afcca29</query_name>\n                <query_description>Query from GeCo i2b2 data source (6564291a-52f6-4e88-baf1-cc593afcca29)</query_description>\n                <query_timing>ANY</query_timing>\n                <specificity_scale>0</specificity_scale>\n                <panel>\n                    <panel_number>1</panel_number>\n                    <panel_timing>sameinstancenum</panel_timing>\n                    <panel_accuracy_scale>100</panel_accuracy_scale>\n                    <invert>0</invert>\n                    <total_item_occurrences>1</total_item_occurrences>\n                    <item>\n                        <hlevel>0</hlevel>\n                        <item_name></item_name>\n                        <item_key>\\\\sphn\\SPHNv2020.1\\Consent\\</item_key>\n                        <item_icon></item_icon>\n                        <tooltip></tooltip>\n                        <class></class>\n                        <constrain_by_modifier>\n                            <modifier_key>\\\\sphn\\A122-Consent::status\\accepted\\</modifier_key>\n                            <applied_path>\\SPHNv2020.1\\Consent\\</applied_path>\n                        </constrain_by_modifier>\n                        <item_is_synonym>false</item_is_synonym>\n                    </item>\n                    <item>\n                        <hlevel>0</hlevel>\n                        <item_name></item_name>\n                        <item_key>\\\\sphn\\SPHNv2020.1\\Consent\\</item_key>\n                        <item_icon></item_icon>\n                        <tooltip></tooltip>\n                        <class></class>\n                        <constrain_by_modifier>\n                            <modifier_key>\\\\sphn\\A122-Consent::status\\refused\\</modifier_key>\n                            <applied_path>\\SPHNv2020.1\\Consent\\</applied_path>\n                        </constrain_by_modifier>\n                        <item_is_synonym>false</item_is_synonym>\n                    </item>\n                </panel>\n            </query_definition>\n            <result_output_list>\n                <result_output name="PATIENTSET" priority_index="1"/>\n                <result_output name="PATIENT_COUNT_XML" priority_index="2"/>\n            </result_output_list>\n        </ns4:request>\n    </message_body>\n</ns5:request>\n	<ns2:response xmlns:ns2="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/hive/msg/version/">\n    <message_header>\n        <i2b2_version_compatible>1.1</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>PM Cell</application_name>\n            <application_version>1.700</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>i2b2 Hive</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>PM Cell</application_name>\n            <application_version>1.700</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 Hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-04-12T09:33:35.081Z</datetime_of_message>\n        <message_control_id>\n            <instance_num>1</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>AL</accept_acknowledgement_type>\n        <application_acknowledgement_type>AL</application_acknowledgement_type>\n        <country_code>US</country_code>\n        <project_id/>\n    </message_header>\n    <response_header>\n        <result_status>\n            <status type="DONE">PM processing completed</status>\n        </result_status>\n    </response_header>\n    <message_body>\n        <ns4:configure>\n            <environment>DEVELOPMENT</environment>\n            <helpURL>http://www.i2b2.org</helpURL>\n            <user>\n                <full_name>i2b2 User</full_name>\n                <user_name>demo</user_name>\n                <password is_token="true" token_ms_timeout="1800000">SessionKey:5c6ts1brFeX8GDzYYx00</password>\n                <domain>i2b2demo</domain>\n                <is_admin>false</is_admin>\n                <project id="Demo">\n                    <name>i2b2 Demo</name>\n                    <wiki>http://www.i2b2.org</wiki>\n                    <path>/Demo</path>\n                    <role>DATA_AGG</role>\n                    <role>DATA_DEID</role>\n                    <role>DATA_LDS</role>\n                    <role>DATA_OBFSC</role>\n                    <role>DATA_PROT</role>\n                    <role>EDITOR</role>\n                    <role>USER</role>\n                </project>\n            </user>\n            <domain_name>i2b2demo</domain_name>\n            <domain_id>i2b2demo</domain_id>\n            <active>true</active>\n            <cell_datas>\n                <cell_data id="CRC">\n                    <name>Data Repository</name>\n                    <url>http://i2b2:8080/i2b2/services/QueryToolService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="FRC">\n                    <name>File Repository </name>\n                    <url>http://i2b2:8080/i2b2/services/FRService/</url>\n                    <project_path>/</project_path>\n                    <method>SOAP</method>\n                    <can_override>true</can_override>\n                    <param name="DestDir" id="1" datatype="T">/opt/jboss/wildfly/standalone/data/i2b2_FR_files</param>\n                </cell_data>\n                <cell_data id="ONT">\n                    <name>Ontology Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/OntologyService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="WORK">\n                    <name>Workplace Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/WorkplaceService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="IM">\n                    <name>IM Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/IMService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n            </cell_datas>\n            <global_data/>\n        </ns4:configure>\n    </message_body>\n</ns2:response>
6	1dcf7d9d-4df7-43a6-a894-2adf89c828c5	demo	Demo	\N	\N	2022-04-21 09:10:04.726	\N	N	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns3:query_definition xmlns:ns2="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/">\n    <query_id>1dcf7d9d-4df7-43a6-a894-2adf89c828c5</query_id>\n    <query_name>1dcf7d9d-4df7-43a6-a894-2adf89c828c5</query_name>\n    <query_description>Query from GeCo i2b2 data source (1dcf7d9d-4df7-43a6-a894-2adf89c828c5)</query_description>\n    <query_timing>ANY</query_timing>\n    <specificity_scale>0</specificity_scale>\n    <panel>\n        <panel_number>1</panel_number>\n        <panel_timing>sameinstancenum</panel_timing>\n        <panel_accuracy_scale>100</panel_accuracy_scale>\n        <invert>0</invert>\n        <total_item_occurrences>1</total_item_occurrences>\n        <item>\n            <hlevel>0</hlevel>\n            <item_name></item_name>\n            <item_key>\\\\sphn\\SPHNv2020.1\\SPOConcepts\\OncologyDrugTreatment\\</item_key>\n            <item_icon></item_icon>\n            <tooltip></tooltip>\n            <class></class>\n            <item_is_synonym>false</item_is_synonym>\n        </item>\n    </panel>\n</ns3:query_definition>\n	insert into QUERY_GLOBAL_TEMP (provider_id, start_date, concept_cd, instance_num, encounter_num,  patient_num, panel_count)\nwith t as ( \n select   f.provider_id, f.start_date, f.concept_cd, f.instance_num, f.encounter_num, f.patient_num  \nfrom i2b2demodata.observation_fact f \nwhere  \nf.CONCEPT_CD IN (select CONCEPT_CD from  i2b2demodata.CONCEPT_DIMENSION   where CONCEPT_PATH LIKE '\\\\SPHNv2020.1\\\\SPOConcepts\\\\OncologyDrugTreatment\\\\%')   \ngroup by  f.encounter_num ,f.instance_num, f.concept_cd,f.start_date,f.provider_id, f.patient_num \n ) \nselect t.provider_id, t.start_date, t.concept_cd, t.instance_num, t.encounter_num, t.patient_num, 0 as panel_count  from t \n<*>\n insert into DX (  patient_num   ) select * from ( select distinct  patient_num  from QUERY_GLOBAL_TEMP where panel_count = 0 ) q	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns5:request xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <message_header>\n        <i2b2_version_compatible>0.3</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>GeCo i2b2 Data Source</application_name>\n            <application_version>0.2</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>GeCo</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>i2b2 cell</application_name>\n            <application_version>1.7</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-04-21T09:10:04Z</datetime_of_message>\n        <security>\n            <domain>i2b2demo</domain>\n            <username>demo</username>\n            <password is_token="false">password not stored</password>\n        </security>\n        <message_type>\n            <message_code>EQQ</message_code>\n            <event_type>Q04</event_type>\n            <message_structure>EQQ_Q04</message_structure>\n        </message_type>\n        <message_control_id>\n            <session_id>2022-04-21T09:10:04Z</session_id>\n            <message_num>1650532204</message_num>\n            <instance_num>0</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n        <application_acknowledgement_type></application_acknowledgement_type>\n        <country_code>CH</country_code>\n        <project_id>Demo</project_id>\n    </message_header>\n    <request_header>\n        <result_waittime_ms>10000</result_waittime_ms>\n    </request_header>\n    <message_body>\n        <ns4:psmheader>\n            <user login="demo" group="i2b2demo">demo</user>\n            <patient_set_limit>0</patient_set_limit>\n            <estimated_time>0</estimated_time>\n            <query_mode>optimize_without_temp_table</query_mode>\n            <request_type>CRC_QRY_runQueryInstance_fromQueryDefinition</request_type>\n        </ns4:psmheader>\n        <ns4:request xsi:type="ns4:query_definition_requestType" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">\n            <query_definition>\n                <query_id>1dcf7d9d-4df7-43a6-a894-2adf89c828c5</query_id>\n                <query_name>1dcf7d9d-4df7-43a6-a894-2adf89c828c5</query_name>\n                <query_description>Query from GeCo i2b2 data source (1dcf7d9d-4df7-43a6-a894-2adf89c828c5)</query_description>\n                <query_timing>ANY</query_timing>\n                <specificity_scale>0</specificity_scale>\n                <panel>\n                    <panel_number>1</panel_number>\n                    <panel_timing>sameinstancenum</panel_timing>\n                    <panel_accuracy_scale>100</panel_accuracy_scale>\n                    <invert>0</invert>\n                    <total_item_occurrences>1</total_item_occurrences>\n                    <item>\n                        <hlevel>0</hlevel>\n                        <item_name></item_name>\n                        <item_key>\\\\sphn\\SPHNv2020.1\\SPOConcepts\\OncologyDrugTreatment\\</item_key>\n                        <item_icon></item_icon>\n                        <tooltip></tooltip>\n                        <class></class>\n                        <item_is_synonym>false</item_is_synonym>\n                    </item>\n                </panel>\n            </query_definition>\n            <result_output_list>\n                <result_output name="PATIENTSET" priority_index="1"/>\n                <result_output name="PATIENT_COUNT_XML" priority_index="2"/>\n            </result_output_list>\n        </ns4:request>\n    </message_body>\n</ns5:request>\n	<ns2:response xmlns:ns2="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/hive/msg/version/">\n    <message_header>\n        <i2b2_version_compatible>1.1</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>PM Cell</application_name>\n            <application_version>1.700</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>i2b2 Hive</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>PM Cell</application_name>\n            <application_version>1.700</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 Hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-04-21T09:10:04.766Z</datetime_of_message>\n        <message_control_id>\n            <instance_num>1</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>AL</accept_acknowledgement_type>\n        <application_acknowledgement_type>AL</application_acknowledgement_type>\n        <country_code>US</country_code>\n        <project_id/>\n    </message_header>\n    <response_header>\n        <result_status>\n            <status type="DONE">PM processing completed</status>\n        </result_status>\n    </response_header>\n    <message_body>\n        <ns4:configure>\n            <environment>DEVELOPMENT</environment>\n            <helpURL>http://www.i2b2.org</helpURL>\n            <user>\n                <full_name>i2b2 User</full_name>\n                <user_name>demo</user_name>\n                <password is_token="true" token_ms_timeout="1800000">SessionKey:S4D5nLcT4aN843FIMMQQ</password>\n                <domain>i2b2demo</domain>\n                <is_admin>false</is_admin>\n                <project id="Demo">\n                    <name>i2b2 Demo</name>\n                    <wiki>http://www.i2b2.org</wiki>\n                    <path>/Demo</path>\n                    <role>DATA_AGG</role>\n                    <role>DATA_DEID</role>\n                    <role>DATA_LDS</role>\n                    <role>DATA_OBFSC</role>\n                    <role>DATA_PROT</role>\n                    <role>EDITOR</role>\n                    <role>USER</role>\n                </project>\n            </user>\n            <domain_name>i2b2demo</domain_name>\n            <domain_id>i2b2demo</domain_id>\n            <active>true</active>\n            <cell_datas>\n                <cell_data id="CRC">\n                    <name>Data Repository</name>\n                    <url>http://i2b2:8080/i2b2/services/QueryToolService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="FRC">\n                    <name>File Repository </name>\n                    <url>http://i2b2:8080/i2b2/services/FRService/</url>\n                    <project_path>/</project_path>\n                    <method>SOAP</method>\n                    <can_override>true</can_override>\n                    <param name="DestDir" id="1" datatype="T">/opt/jboss/wildfly/standalone/data/i2b2_FR_files</param>\n                </cell_data>\n                <cell_data id="ONT">\n                    <name>Ontology Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/OntologyService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="WORK">\n                    <name>Workplace Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/WorkplaceService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="IM">\n                    <name>IM Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/IMService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n            </cell_datas>\n            <global_data/>\n        </ns4:configure>\n    </message_body>\n</ns2:response>
7	be7cb781-af56-47ef-a4c1-c1402692172c	demo	Demo	\N	\N	2022-04-21 09:12:09.996	\N	N	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns3:query_definition xmlns:ns2="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/">\n    <query_id>be7cb781-af56-47ef-a4c1-c1402692172c</query_id>\n    <query_name>be7cb781-af56-47ef-a4c1-c1402692172c</query_name>\n    <query_description>Query from GeCo i2b2 data source (be7cb781-af56-47ef-a4c1-c1402692172c)</query_description>\n    <query_timing>ANY</query_timing>\n    <specificity_scale>0</specificity_scale>\n    <panel>\n        <panel_number>1</panel_number>\n        <panel_timing>sameinstancenum</panel_timing>\n        <panel_accuracy_scale>100</panel_accuracy_scale>\n        <invert>0</invert>\n        <total_item_occurrences>1</total_item_occurrences>\n        <item>\n            <hlevel>0</hlevel>\n            <item_name></item_name>\n            <item_key>\\\\sphn\\SPHNv2020.1\\SPOConcepts\\OncologyDrugTreatment\\</item_key>\n            <item_icon></item_icon>\n            <tooltip></tooltip>\n            <class></class>\n            <item_is_synonym>false</item_is_synonym>\n        </item>\n    </panel>\n</ns3:query_definition>\n	insert into QUERY_GLOBAL_TEMP (provider_id, start_date, concept_cd, instance_num, encounter_num,  patient_num, panel_count)\nwith t as ( \n select   f.provider_id, f.start_date, f.concept_cd, f.instance_num, f.encounter_num, f.patient_num  \nfrom i2b2demodata.observation_fact f \nwhere  \nf.CONCEPT_CD IN (select CONCEPT_CD from  i2b2demodata.CONCEPT_DIMENSION   where CONCEPT_PATH LIKE '\\\\SPHNv2020.1\\\\SPOConcepts\\\\OncologyDrugTreatment\\\\%')   \ngroup by  f.encounter_num ,f.instance_num, f.concept_cd,f.start_date,f.provider_id, f.patient_num \n ) \nselect t.provider_id, t.start_date, t.concept_cd, t.instance_num, t.encounter_num, t.patient_num, 0 as panel_count  from t \n<*>\n insert into DX (  patient_num   ) select * from ( select distinct  patient_num  from QUERY_GLOBAL_TEMP where panel_count = 0 ) q	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns5:request xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <message_header>\n        <i2b2_version_compatible>0.3</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>GeCo i2b2 Data Source</application_name>\n            <application_version>0.2</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>GeCo</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>i2b2 cell</application_name>\n            <application_version>1.7</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-04-21T09:12:09Z</datetime_of_message>\n        <security>\n            <domain>i2b2demo</domain>\n            <username>demo</username>\n            <password is_token="false">password not stored</password>\n        </security>\n        <message_type>\n            <message_code>EQQ</message_code>\n            <event_type>Q04</event_type>\n            <message_structure>EQQ_Q04</message_structure>\n        </message_type>\n        <message_control_id>\n            <session_id>2022-04-21T09:12:09Z</session_id>\n            <message_num>1650532329</message_num>\n            <instance_num>0</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>messageId</accept_acknowledgement_type>\n        <application_acknowledgement_type></application_acknowledgement_type>\n        <country_code>CH</country_code>\n        <project_id>Demo</project_id>\n    </message_header>\n    <request_header>\n        <result_waittime_ms>10000</result_waittime_ms>\n    </request_header>\n    <message_body>\n        <ns4:psmheader>\n            <user login="demo" group="i2b2demo">demo</user>\n            <patient_set_limit>0</patient_set_limit>\n            <estimated_time>0</estimated_time>\n            <query_mode>optimize_without_temp_table</query_mode>\n            <request_type>CRC_QRY_runQueryInstance_fromQueryDefinition</request_type>\n        </ns4:psmheader>\n        <ns4:request xsi:type="ns4:query_definition_requestType" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">\n            <query_definition>\n                <query_id>be7cb781-af56-47ef-a4c1-c1402692172c</query_id>\n                <query_name>be7cb781-af56-47ef-a4c1-c1402692172c</query_name>\n                <query_description>Query from GeCo i2b2 data source (be7cb781-af56-47ef-a4c1-c1402692172c)</query_description>\n                <query_timing>ANY</query_timing>\n                <specificity_scale>0</specificity_scale>\n                <panel>\n                    <panel_number>1</panel_number>\n                    <panel_timing>sameinstancenum</panel_timing>\n                    <panel_accuracy_scale>100</panel_accuracy_scale>\n                    <invert>0</invert>\n                    <total_item_occurrences>1</total_item_occurrences>\n                    <item>\n                        <hlevel>0</hlevel>\n                        <item_name></item_name>\n                        <item_key>\\\\sphn\\SPHNv2020.1\\SPOConcepts\\OncologyDrugTreatment\\</item_key>\n                        <item_icon></item_icon>\n                        <tooltip></tooltip>\n                        <class></class>\n                        <item_is_synonym>false</item_is_synonym>\n                    </item>\n                </panel>\n            </query_definition>\n            <result_output_list>\n                <result_output name="PATIENTSET" priority_index="1"/>\n                <result_output name="PATIENT_COUNT_XML" priority_index="2"/>\n            </result_output_list>\n        </ns4:request>\n    </message_body>\n</ns5:request>\n	<ns2:response xmlns:ns2="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/hive/msg/version/">\n    <message_header>\n        <i2b2_version_compatible>1.1</i2b2_version_compatible>\n        <hl7_version_compatible>2.4</hl7_version_compatible>\n        <sending_application>\n            <application_name>PM Cell</application_name>\n            <application_version>1.700</application_version>\n        </sending_application>\n        <sending_facility>\n            <facility_name>i2b2 Hive</facility_name>\n        </sending_facility>\n        <receiving_application>\n            <application_name>PM Cell</application_name>\n            <application_version>1.700</application_version>\n        </receiving_application>\n        <receiving_facility>\n            <facility_name>i2b2 Hive</facility_name>\n        </receiving_facility>\n        <datetime_of_message>2022-04-21T09:12:10.028Z</datetime_of_message>\n        <message_control_id>\n            <instance_num>1</instance_num>\n        </message_control_id>\n        <processing_id>\n            <processing_id>P</processing_id>\n            <processing_mode>I</processing_mode>\n        </processing_id>\n        <accept_acknowledgement_type>AL</accept_acknowledgement_type>\n        <application_acknowledgement_type>AL</application_acknowledgement_type>\n        <country_code>US</country_code>\n        <project_id/>\n    </message_header>\n    <response_header>\n        <result_status>\n            <status type="DONE">PM processing completed</status>\n        </result_status>\n    </response_header>\n    <message_body>\n        <ns4:configure>\n            <environment>DEVELOPMENT</environment>\n            <helpURL>http://www.i2b2.org</helpURL>\n            <user>\n                <full_name>i2b2 User</full_name>\n                <user_name>demo</user_name>\n                <password is_token="true" token_ms_timeout="1800000">SessionKey:BD8tAP3ZZIqtulkr3jBC</password>\n                <domain>i2b2demo</domain>\n                <is_admin>false</is_admin>\n                <project id="Demo">\n                    <name>i2b2 Demo</name>\n                    <wiki>http://www.i2b2.org</wiki>\n                    <path>/Demo</path>\n                    <role>DATA_AGG</role>\n                    <role>DATA_DEID</role>\n                    <role>DATA_LDS</role>\n                    <role>DATA_OBFSC</role>\n                    <role>DATA_PROT</role>\n                    <role>EDITOR</role>\n                    <role>USER</role>\n                </project>\n            </user>\n            <domain_name>i2b2demo</domain_name>\n            <domain_id>i2b2demo</domain_id>\n            <active>true</active>\n            <cell_datas>\n                <cell_data id="CRC">\n                    <name>Data Repository</name>\n                    <url>http://i2b2:8080/i2b2/services/QueryToolService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="FRC">\n                    <name>File Repository </name>\n                    <url>http://i2b2:8080/i2b2/services/FRService/</url>\n                    <project_path>/</project_path>\n                    <method>SOAP</method>\n                    <can_override>true</can_override>\n                    <param name="DestDir" id="1" datatype="T">/opt/jboss/wildfly/standalone/data/i2b2_FR_files</param>\n                </cell_data>\n                <cell_data id="ONT">\n                    <name>Ontology Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/OntologyService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="WORK">\n                    <name>Workplace Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/WorkplaceService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n                <cell_data id="IM">\n                    <name>IM Cell</name>\n                    <url>http://i2b2:8080/i2b2/services/IMService/</url>\n                    <project_path>/</project_path>\n                    <method>REST</method>\n                    <can_override>true</can_override>\n                </cell_data>\n            </cell_datas>\n            <global_data/>\n        </ns4:configure>\n    </message_body>\n</ns2:response>
\.


--
-- Data for Name: qt_query_result_instance; Type: TABLE DATA; Schema: i2b2demodata; Owner: i2b2
--

COPY i2b2demodata.qt_query_result_instance (result_instance_id, query_instance_id, result_type_id, set_size, start_date, end_date, status_type_id, delete_flag, message, description, real_set_size, obfusc_method) FROM stdin;
-101	-100	1	228	2022-03-04 22:19:50.731	2022-03-04 22:19:51.571	3	N		Patient Set for "63eb6d7e-d437-4f37-a346-4819ed1c74c1"	1	
-102	-100	4	228	2022-03-04 22:19:50.744	2022-03-04 22:19:51.613	3	N		Number of patients for "63eb6d7e-d437-4f37-a346-4819ed1c74c1"	1	
1	1	1	229	2022-04-11 17:25:15.384	2022-04-11 17:25:15.85	3	N		Patient Set for "3ccee0d7-e557-4858-83e0-28094e555d1c"	229	
2	1	4	229	2022-04-11 17:25:15.391	2022-04-11 17:25:15.875	3	N		Number of patients for "3ccee0d7-e557-4858-83e0-28094e555d1c"	229	
3	2	1	229	2022-04-11 17:26:10.054	2022-04-11 17:26:10.276	3	N		Patient Set for "28934242-297b-49b5-be41-0fbd4273fc84"	229	
4	2	4	229	2022-04-11 17:26:10.057	2022-04-11 17:26:10.287	3	N		Number of patients for "28934242-297b-49b5-be41-0fbd4273fc84"	229	
5	3	1	73	2022-04-11 17:28:13.637	2022-04-11 17:28:15.015	3	N		Patient Set for "00cd2146-8c76-4106-abc4-836b5d21f0af"	73	
6	3	4	73	2022-04-11 17:28:13.724	2022-04-11 17:28:15.341	3	N		Number of patients for "00cd2146-8c76-4106-abc4-836b5d21f0af"	73	
7	4	1	73	2022-04-11 17:29:07.19	2022-04-11 17:29:07.507	3	N		Patient Set for "5f543055-19b0-43f9-badc-d2b19f44388e"	73	
8	4	4	73	2022-04-11 17:29:07.198	2022-04-11 17:29:07.526	3	N		Number of patients for "5f543055-19b0-43f9-badc-d2b19f44388e"	73	
9	5	1	43	2022-04-12 09:33:35.11	2022-04-12 09:33:36.456	3	N		Patient Set for "6564291a-52f6-4e88-baf1-cc593afcca29"	43	
10	5	4	43	2022-04-12 09:33:35.113	2022-04-12 09:33:36.47	3	N		Number of patients for "6564291a-52f6-4e88-baf1-cc593afcca29"	43	
11	6	1	73	2022-04-21 09:10:04.81	2022-04-21 09:10:05.09	3	N		Patient Set for "1dcf7d9d-4df7-43a6-a894-2adf89c828c5"	73	
12	6	4	73	2022-04-21 09:10:04.815	2022-04-21 09:10:05.104	3	N		Number of patients for "1dcf7d9d-4df7-43a6-a894-2adf89c828c5"	73	
13	7	1	73	2022-04-21 09:12:10.046	2022-04-21 09:12:10.286	3	N		Patient Set for "be7cb781-af56-47ef-a4c1-c1402692172c"	73	
14	7	4	73	2022-04-21 09:12:10.05	2022-04-21 09:12:10.297	3	N		Number of patients for "be7cb781-af56-47ef-a4c1-c1402692172c"	73	
\.


--
-- Data for Name: qt_query_result_type; Type: TABLE DATA; Schema: i2b2demodata; Owner: i2b2
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
-- Data for Name: qt_query_status_type; Type: TABLE DATA; Schema: i2b2demodata; Owner: i2b2
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
-- Data for Name: qt_xml_result; Type: TABLE DATA; Schema: i2b2demodata; Owner: i2b2
--

COPY i2b2demodata.qt_xml_result (xml_result_id, result_instance_id, xml_value) FROM stdin;
-1	-102	xml-result
1	2	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns10:i2b2_result_envelope xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <body>\n        <ns10:result name="PATIENT_COUNT_XML">\n            <data column="patient_count" type="int">229</data>\n        </ns10:result>\n    </body>\n</ns10:i2b2_result_envelope>\n
2	4	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns10:i2b2_result_envelope xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <body>\n        <ns10:result name="PATIENT_COUNT_XML">\n            <data column="patient_count" type="int">229</data>\n        </ns10:result>\n    </body>\n</ns10:i2b2_result_envelope>\n
3	6	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns10:i2b2_result_envelope xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <body>\n        <ns10:result name="PATIENT_COUNT_XML">\n            <data column="patient_count" type="int">73</data>\n        </ns10:result>\n    </body>\n</ns10:i2b2_result_envelope>\n
4	8	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns10:i2b2_result_envelope xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <body>\n        <ns10:result name="PATIENT_COUNT_XML">\n            <data column="patient_count" type="int">73</data>\n        </ns10:result>\n    </body>\n</ns10:i2b2_result_envelope>\n
5	10	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns10:i2b2_result_envelope xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <body>\n        <ns10:result name="PATIENT_COUNT_XML">\n            <data column="patient_count" type="int">43</data>\n        </ns10:result>\n    </body>\n</ns10:i2b2_result_envelope>\n
6	12	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns10:i2b2_result_envelope xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <body>\n        <ns10:result name="PATIENT_COUNT_XML">\n            <data column="patient_count" type="int">73</data>\n        </ns10:result>\n    </body>\n</ns10:i2b2_result_envelope>\n
7	14	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<ns10:i2b2_result_envelope xmlns:ns6="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/pm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/crc/psm/analysisdefinition/1.1/" xmlns:ns9="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns10="http://www.i2b2.org/xsd/hive/msg/result/1.1/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n    <body>\n        <ns10:result name="PATIENT_COUNT_XML">\n            <data column="patient_count" type="int">73</data>\n        </ns10:result>\n    </body>\n</ns10:i2b2_result_envelope>\n
\.


--
-- Data for Name: set_type; Type: TABLE DATA; Schema: i2b2demodata; Owner: i2b2
--

COPY i2b2demodata.set_type (id, name, create_date) FROM stdin;
1	event_set	2022-04-11 17:12:45.666487
2	patient_set	2022-04-11 17:12:45.669444
3	concept_set	2022-04-11 17:12:45.672061
4	observer_set	2022-04-11 17:12:45.685433
5	observation_set	2022-04-11 17:12:45.690822
6	pid_set	2022-04-11 17:12:45.692747
7	eid_set	2022-04-11 17:12:45.695122
8	modifier_set	2022-04-11 17:12:45.697739
\.


--
-- Data for Name: set_upload_status; Type: TABLE DATA; Schema: i2b2demodata; Owner: i2b2
--

COPY i2b2demodata.set_upload_status (upload_id, set_type_id, source_cd, no_of_record, loaded_record, deleted_record, load_date, end_date, load_status, message, input_file_name, log_file_name, transform_name) FROM stdin;
\.


--
-- Data for Name: source_master; Type: TABLE DATA; Schema: i2b2demodata; Owner: i2b2
--

COPY i2b2demodata.source_master (source_cd, description, create_date) FROM stdin;
\.


--
-- Data for Name: upload_status; Type: TABLE DATA; Schema: i2b2demodata; Owner: i2b2
--

COPY i2b2demodata.upload_status (upload_id, upload_label, user_id, source_cd, no_of_record, loaded_record, deleted_record, load_date, end_date, load_status, message, input_file_name, log_file_name, transform_name) FROM stdin;
\.


--
-- Data for Name: crc_analysis_job; Type: TABLE DATA; Schema: i2b2hive; Owner: i2b2
--

COPY i2b2hive.crc_analysis_job (job_id, queue_name, status_type_id, domain_id, project_id, user_id, request_xml, create_date, update_date) FROM stdin;
\.


--
-- Data for Name: crc_db_lookup; Type: TABLE DATA; Schema: i2b2hive; Owner: i2b2
--

COPY i2b2hive.crc_db_lookup (c_domain_id, c_project_path, c_owner_id, c_db_fullschema, c_db_datasource, c_db_servertype, c_db_nicename, c_db_tooltip, c_comment, c_entry_date, c_change_date, c_status_cd) FROM stdin;
i2b2demo	/ACT/	@	i2b2demodata	java:/QueryToolDemoDS	POSTGRESQL	Demo	\N	\N	\N	\N	\N
i2b2demo	/Demo/	@	i2b2demodata	java:/QueryToolDemoDS	POSTGRESQL	Demo	\N	\N	\N	\N	\N
\.


--
-- Data for Name: hive_cell_params; Type: TABLE DATA; Schema: i2b2hive; Owner: i2b2
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
-- Data for Name: im_db_lookup; Type: TABLE DATA; Schema: i2b2hive; Owner: i2b2
--

COPY i2b2hive.im_db_lookup (c_domain_id, c_project_path, c_owner_id, c_db_fullschema, c_db_datasource, c_db_servertype, c_db_nicename, c_db_tooltip, c_comment, c_entry_date, c_change_date, c_status_cd) FROM stdin;
i2b2demo	Demo/	@	i2b2imdata	java:/IMDemoDS	POSTGRESQL	IM	\N	\N	\N	\N	\N
\.


--
-- Data for Name: ont_db_lookup; Type: TABLE DATA; Schema: i2b2hive; Owner: i2b2
--

COPY i2b2hive.ont_db_lookup (c_domain_id, c_project_path, c_owner_id, c_db_fullschema, c_db_datasource, c_db_servertype, c_db_nicename, c_db_tooltip, c_comment, c_entry_date, c_change_date, c_status_cd) FROM stdin;
i2b2demo	ACT/	@	i2b2metadata	java:/OntologyDemoDS	POSTGRESQL	Metadata	\N	\N	\N	\N	\N
i2b2demo	Demo/	@	i2b2metadata	java:/OntologyDemoDS	POSTGRESQL	Metadata	\N	\N	\N	\N	\N
\.


--
-- Data for Name: work_db_lookup; Type: TABLE DATA; Schema: i2b2hive; Owner: i2b2
--

COPY i2b2hive.work_db_lookup (c_domain_id, c_project_path, c_owner_id, c_db_fullschema, c_db_datasource, c_db_servertype, c_db_nicename, c_db_tooltip, c_comment, c_entry_date, c_change_date, c_status_cd) FROM stdin;
i2b2demo	ACT/	@	i2b2workdata	java:/WorkplaceDemoDS	POSTGRESQL	Workplace	\N	\N	\N	\N	\N
i2b2demo	Demo/	@	i2b2workdata	java:/WorkplaceDemoDS	POSTGRESQL	Workplace	\N	\N	\N	\N	\N
\.


--
-- Data for Name: im_audit; Type: TABLE DATA; Schema: i2b2imdata; Owner: i2b2
--

COPY i2b2imdata.im_audit (query_date, lcl_site, lcl_id, user_id, project_id, comments) FROM stdin;
\.


--
-- Data for Name: im_mpi_demographics; Type: TABLE DATA; Schema: i2b2imdata; Owner: i2b2
--

COPY i2b2imdata.im_mpi_demographics (global_id, global_status, demographics, update_date, download_date, import_date, sourcesystem_cd, upload_id) FROM stdin;
\.


--
-- Data for Name: im_mpi_mapping; Type: TABLE DATA; Schema: i2b2imdata; Owner: i2b2
--

COPY i2b2imdata.im_mpi_mapping (global_id, lcl_site, lcl_id, lcl_status, update_date, download_date, import_date, sourcesystem_cd, upload_id) FROM stdin;
\.


--
-- Data for Name: im_project_patients; Type: TABLE DATA; Schema: i2b2imdata; Owner: i2b2
--

COPY i2b2imdata.im_project_patients (project_id, global_id, patient_project_status, update_date, download_date, import_date, sourcesystem_cd, upload_id) FROM stdin;
\.


--
-- Data for Name: im_project_sites; Type: TABLE DATA; Schema: i2b2imdata; Owner: i2b2
--

COPY i2b2imdata.im_project_sites (project_id, lcl_site, project_status, update_date, download_date, import_date, sourcesystem_cd, upload_id) FROM stdin;
\.


--
-- Data for Name: birn; Type: TABLE DATA; Schema: i2b2metadata; Owner: i2b2
--

COPY i2b2metadata.birn (c_hlevel, c_fullname, c_name, c_synonym_cd, c_visualattributes, c_totalnum, c_basecode, c_metadataxml, c_facttablecolumn, c_tablename, c_columnname, c_columndatatype, c_operator, c_dimcode, c_comment, c_tooltip, m_applied_path, update_date, download_date, import_date, sourcesystem_cd, valuetype_cd, m_exclusion_cd, c_path, c_symbol) FROM stdin;
\.


--
-- Data for Name: custom_meta; Type: TABLE DATA; Schema: i2b2metadata; Owner: i2b2
--

COPY i2b2metadata.custom_meta (c_hlevel, c_fullname, c_name, c_synonym_cd, c_visualattributes, c_totalnum, c_basecode, c_metadataxml, c_facttablecolumn, c_tablename, c_columnname, c_columndatatype, c_operator, c_dimcode, c_comment, c_tooltip, m_applied_path, update_date, download_date, import_date, sourcesystem_cd, valuetype_cd, m_exclusion_cd, c_path, c_symbol) FROM stdin;
\.


--
-- Data for Name: i2b2; Type: TABLE DATA; Schema: i2b2metadata; Owner: i2b2
--

COPY i2b2metadata.i2b2 (c_hlevel, c_fullname, c_name, c_synonym_cd, c_visualattributes, c_totalnum, c_basecode, c_metadataxml, c_facttablecolumn, c_tablename, c_columnname, c_columndatatype, c_operator, c_dimcode, c_comment, c_tooltip, m_applied_path, update_date, download_date, import_date, sourcesystem_cd, valuetype_cd, m_exclusion_cd, c_path, c_symbol) FROM stdin;
\.


--
-- Data for Name: icd10_icd9; Type: TABLE DATA; Schema: i2b2metadata; Owner: i2b2
--

COPY i2b2metadata.icd10_icd9 (c_hlevel, c_fullname, c_name, c_synonym_cd, c_visualattributes, c_totalnum, c_basecode, c_metadataxml, c_facttablecolumn, c_tablename, c_columnname, c_columndatatype, c_operator, c_dimcode, c_comment, c_tooltip, m_applied_path, update_date, download_date, import_date, sourcesystem_cd, valuetype_cd, m_exclusion_cd, c_path, c_symbol, plain_code) FROM stdin;
\.


--
-- Data for Name: ont_process_status; Type: TABLE DATA; Schema: i2b2metadata; Owner: i2b2
--

COPY i2b2metadata.ont_process_status (process_id, process_type_cd, start_date, end_date, process_step_cd, process_status_cd, crc_upload_id, status_cd, message, entry_date, change_date, changedby_char) FROM stdin;
\.


--
-- Data for Name: schemes; Type: TABLE DATA; Schema: i2b2metadata; Owner: i2b2
--

COPY i2b2metadata.schemes (c_key, c_name, c_description) FROM stdin;
TEST:	Test	Test scheme.
\.


--
-- Data for Name: table_access; Type: TABLE DATA; Schema: i2b2metadata; Owner: i2b2
--

COPY i2b2metadata.table_access (c_table_cd, c_table_name, c_protected_access, c_ontology_protection, c_hlevel, c_fullname, c_name, c_synonym_cd, c_visualattributes, c_totalnum, c_basecode, c_metadataxml, c_facttablecolumn, c_dimtablename, c_columnname, c_columndatatype, c_operator, c_dimcode, c_comment, c_tooltip, c_entry_date, c_change_date, c_status_cd, valuetype_cd) FROM stdin;
sphn	sphn	N	\N	0	\\SPHNv2020.1\\	NO_DATA	N	FA 	\N			concept_cd	concept_dimension	concept_path	T	LIKE	\\SPHNv2020.1\\		SPHN demo ontology	\N	\N	\N	\N
\.


--
-- Data for Name: test; Type: TABLE DATA; Schema: i2b2metadata; Owner: i2b2
--

COPY i2b2metadata.test (c_hlevel, c_fullname, c_name, c_synonym_cd, c_visualattributes, c_totalnum, c_basecode, c_metadataxml, c_facttablecolumn, c_tablename, c_columnname, c_columndatatype, c_operator, c_dimcode, c_comment, c_tooltip, update_date, download_date, import_date, sourcesystem_cd, valuetype_cd, m_applied_path, m_exclusion_cd, c_path, c_symbol, pcori_basecode) FROM stdin;
0	\\test\\	Test	N	CA 	0		\N	concept_cd	concept_dimension	concept_path	T	LIKE	\\test\\	Test	\\test\\	2022-04-11	2022-04-11	2022-04-11	\N	TEST	@	\N	\N	\N	\N
1	\\test\\1\\	Concept 1	N	LA 	0	TEST:1	<?xml version="1.0"?><ValueMetadata></ValueMetadata>	concept_cd	concept_dimension	concept_path	T	LIKE	\\test\\1\\	Concept 1	\\test\\1\\	2022-04-11	2022-04-11	2022-04-11	\N	TEST	@	\N	\N	\N	\N
1	\\test\\2\\	Concept 2	N	LA 	0	TEST:2	\N	concept_cd	concept_dimension	concept_path	T	LIKE	\\test\\2\\	Concept 2	\\test\\2\\	2022-04-11	2022-04-11	2022-04-11	\N	TEST	@	\N	\N	\N	\N
1	\\test\\3\\	Concept 3	N	LA 	0	TEST:3	\N	concept_cd	concept_dimension	concept_path	T	LIKE	\\test\\3\\	Concept 3	\\test\\3\\	2022-04-11	2022-04-11	2022-04-11	\N	TEST	@	\N	\N	\N	\N
0	\\modifiers1\\	Modifiers 1 test	N	DA 	0	TEST:4-1	\N	modifier_cd	modifier_dimension	modifier_path	T	LIKE	\\modifiers1\\	Modifiers 1 Test	\\modifiers1\\	2022-04-11	2022-04-11	2022-04-11	\N	TEST	\\test\\1\\	\N	\N	\N	\N
0	\\modifiers2\\	Modifiers 2 test	N	DA 	0	TEST:4-2	\N	modifier_cd	modifier_dimension	modifier_path	T	LIKE	\\modifiers2\\	Modifiers 2 Test	\\modifiers2\\	2022-04-11	2022-04-11	2022-04-11	\N	TEST	\\test\\2\\	\N	\N	\N	\N
0	\\modifiers3\\	Modifiers 3 test	N	DA 	0	TEST:4-3	\N	modifier_cd	modifier_dimension	modifier_path	T	LIKE	\\modifiers1\\	Modifiers 3 Test	\\modifiers3\\	2022-04-11	2022-04-11	2022-04-11	\N	TEST	\\test\\3\\	\N	\N	\N	\N
1	\\modifiers1\\1\\	Modifier 1	N	RA 	0	TEST:5	<?xml version="1.0"?><ValueMetadata></ValueMetadata>	modifier_cd	modifier_dimension	modifier_path	T	LIKE	\\modifiers1\\1\\	Modifier 1	\\modifiers1\\1\\	2022-04-11	2022-04-11	2022-04-11	\N	TEST	\\test\\1\\	\N	\N	\N	\N
1	\\modifiers2\\2\\	Modifier 2	N	RA 	0	TEST:6	\N	modifier_cd	modifier_dimension	modifier_path	T	LIKE	\\modifiers2\\2\\	Modifier 2	\\modifiers2\\2\\	2022-04-11	2022-04-11	2022-04-11	\N	TEST	\\test\\2\\	\N	\N	\N	\N
1	\\modifiers3\\3\\	Modifier 3	N	RA 	0	TEST:7	\N	modifier_cd	modifier_dimension	modifier_path	T	LIKE	\\modifiers3\\3\\	Modifier 3	\\modifiers3\\3\\	2022-04-11	2022-04-11	2022-04-11	\N	TEST	\\test\\3\\	\N	\N	\N	\N
1	\\modifiers2\\text\\	Modifier 2 text	N	RA 	0	TEST:8	\N	modifier_cd	modifier_dimension	modifier_path	T	LIKE	\\modifiers2\\text\\	Modifier 2 text	\\modifiers2\\text\\	2022-04-11	2022-04-11	2022-04-11	\N	T	\\test\\2\\	\N	\N	\N	\N
1	\\modifiers3\\text\\	Modifier 3 text	N	RA 	0	TEST:9	\N	modifier_cd	modifier_dimension	modifier_path	T	LIKE	\\modifiers3\\text\\	Modifier 3 text	\\modifiers3\\text\\	2022-04-11	2022-04-11	2022-04-11	\N	T	\\test\\3\\	\N	\N	\N	\N
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
-- Data for Name: totalnum; Type: TABLE DATA; Schema: i2b2metadata; Owner: i2b2
--

COPY i2b2metadata.totalnum (c_fullname, agg_date, agg_count, typeflag_cd) FROM stdin;
\.


--
-- Data for Name: totalnum_report; Type: TABLE DATA; Schema: i2b2metadata; Owner: i2b2
--

COPY i2b2metadata.totalnum_report (c_fullname, agg_date, agg_count) FROM stdin;
\.


--
-- Data for Name: pm_approvals; Type: TABLE DATA; Schema: i2b2pm; Owner: i2b2
--

COPY i2b2pm.pm_approvals (approval_id, approval_name, approval_description, approval_activation_date, approval_expiration_date, object_cd, change_date, entry_date, changeby_char, status_cd) FROM stdin;
\.


--
-- Data for Name: pm_approvals_params; Type: TABLE DATA; Schema: i2b2pm; Owner: i2b2
--

COPY i2b2pm.pm_approvals_params (id, approval_id, param_name_cd, value, activation_date, expiration_date, datatype_cd, object_cd, change_date, entry_date, changeby_char, status_cd) FROM stdin;
\.


--
-- Data for Name: pm_cell_data; Type: TABLE DATA; Schema: i2b2pm; Owner: i2b2
--

COPY i2b2pm.pm_cell_data (cell_id, project_path, name, method_cd, url, can_override, change_date, entry_date, changeby_char, status_cd) FROM stdin;
CRC	/	Data Repository	REST	http://i2b2:8080/i2b2/services/QueryToolService/	1	\N	\N	\N	A
FRC	/	File Repository 	SOAP	http://i2b2:8080/i2b2/services/FRService/	1	\N	\N	\N	A
ONT	/	Ontology Cell	REST	http://i2b2:8080/i2b2/services/OntologyService/	1	\N	\N	\N	A
WORK	/	Workplace Cell	REST	http://i2b2:8080/i2b2/services/WorkplaceService/	1	\N	\N	\N	A
IM	/	IM Cell	REST	http://i2b2:8080/i2b2/services/IMService/	1	\N	\N	\N	A
\.


--
-- Data for Name: pm_cell_params; Type: TABLE DATA; Schema: i2b2pm; Owner: i2b2
--

COPY i2b2pm.pm_cell_params (id, datatype_cd, cell_id, project_path, param_name_cd, value, can_override, change_date, entry_date, changeby_char, status_cd) FROM stdin;
1	T	FRC	/	DestDir	/opt/jboss/wildfly/standalone/data/i2b2_FR_files	\N	\N	\N	i2b2	A
\.


--
-- Data for Name: pm_global_params; Type: TABLE DATA; Schema: i2b2pm; Owner: i2b2
--

COPY i2b2pm.pm_global_params (id, datatype_cd, param_name_cd, project_path, value, can_override, change_date, entry_date, changeby_char, status_cd) FROM stdin;
\.


--
-- Data for Name: pm_hive_data; Type: TABLE DATA; Schema: i2b2pm; Owner: i2b2
--

COPY i2b2pm.pm_hive_data (domain_id, helpurl, domain_name, environment_cd, active, change_date, entry_date, changeby_char, status_cd) FROM stdin;
i2b2demo	http://www.i2b2.org	i2b2demo	DEVELOPMENT	1	\N	\N	\N	A
\.


--
-- Data for Name: pm_hive_params; Type: TABLE DATA; Schema: i2b2pm; Owner: i2b2
--

COPY i2b2pm.pm_hive_params (id, datatype_cd, domain_id, param_name_cd, value, change_date, entry_date, changeby_char, status_cd) FROM stdin;
\.


--
-- Data for Name: pm_project_data; Type: TABLE DATA; Schema: i2b2pm; Owner: i2b2
--

COPY i2b2pm.pm_project_data (project_id, project_name, project_wiki, project_key, project_path, project_description, change_date, entry_date, changeby_char, status_cd) FROM stdin;
Demo	i2b2 Demo	http://www.i2b2.org	\N	/Demo	\N	\N	\N	\N	A
\.


--
-- Data for Name: pm_project_params; Type: TABLE DATA; Schema: i2b2pm; Owner: i2b2
--

COPY i2b2pm.pm_project_params (id, datatype_cd, project_id, param_name_cd, value, change_date, entry_date, changeby_char, status_cd) FROM stdin;
\.


--
-- Data for Name: pm_project_request; Type: TABLE DATA; Schema: i2b2pm; Owner: i2b2
--

COPY i2b2pm.pm_project_request (id, title, request_xml, change_date, entry_date, changeby_char, status_cd, project_id, submit_char) FROM stdin;
\.


--
-- Data for Name: pm_project_user_params; Type: TABLE DATA; Schema: i2b2pm; Owner: i2b2
--

COPY i2b2pm.pm_project_user_params (id, datatype_cd, project_id, user_id, param_name_cd, value, change_date, entry_date, changeby_char, status_cd) FROM stdin;
\.


--
-- Data for Name: pm_project_user_roles; Type: TABLE DATA; Schema: i2b2pm; Owner: i2b2
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
-- Data for Name: pm_role_requirement; Type: TABLE DATA; Schema: i2b2pm; Owner: i2b2
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
-- Data for Name: pm_user_data; Type: TABLE DATA; Schema: i2b2pm; Owner: i2b2
--

COPY i2b2pm.pm_user_data (user_id, full_name, password, email, project_path, change_date, entry_date, changeby_char, status_cd) FROM stdin;
demo_obf	i2b2 Obfuscated User	9117d59a69dc49807671a51f10ab7f	\N	\N	\N	\N	\N	A
demo_mgr	i2b2 Manager User	9117d59a69dc49807671a51f10ab7f	\N	\N	\N	\N	\N	A
i2b2	i2b2 Admin	4cb9c8a848fd02294477fcb1a41191a	\N	\N	\N	\N	\N	A
demo	i2b2 User	4cb9c8a848fd02294477fcb1a41191a	\N	\N	\N	\N	\N	A
AGG_SERVICE_ACCOUNT	AGG_SERVICE_ACCOUNT	4cb9c8a848fd02294477fcb1a41191a	\N	\N	\N	\N	\N	A
\.


--
-- Data for Name: pm_user_login; Type: TABLE DATA; Schema: i2b2pm; Owner: i2b2
--

COPY i2b2pm.pm_user_login (user_id, attempt_cd, entry_date, changeby_char, status_cd) FROM stdin;
demo	SUCCESS	2022-04-11 17:24:59.230126	demo	A
demo	SUCCESS	2022-04-11 17:25:04.694441	demo	A
demo	SUCCESS	2022-04-11 17:25:04.906043	demo	A
demo	SUCCESS	2022-04-11 17:25:06.576551	demo	A
demo	SUCCESS	2022-04-11 17:25:06.808998	demo	A
demo	SUCCESS	2022-04-11 17:25:10.719539	demo	A
demo	SUCCESS	2022-04-11 17:25:11.050882	demo	A
demo	SUCCESS	2022-04-11 17:25:15.196212	demo	A
demo	SUCCESS	2022-04-11 17:25:15.324588	demo	A
demo	SUCCESS	2022-04-11 17:25:15.778048	demo	A
demo	SUCCESS	2022-04-11 17:25:15.974735	demo	A
demo	SUCCESS	2022-04-11 17:25:16.285836	demo	A
demo	SUCCESS	2022-04-11 17:25:16.342186	demo	A
demo	SUCCESS	2022-04-11 17:25:54.297119	demo	A
demo	SUCCESS	2022-04-11 17:25:56.518351	demo	A
demo	SUCCESS	2022-04-11 17:25:56.596521	demo	A
demo	SUCCESS	2022-04-11 17:25:58.577295	demo	A
demo	SUCCESS	2022-04-11 17:25:58.848934	demo	A
demo	SUCCESS	2022-04-11 17:26:01.334821	demo	A
demo	SUCCESS	2022-04-11 17:26:01.629734	demo	A
demo	SUCCESS	2022-04-11 17:26:09.973491	demo	A
demo	SUCCESS	2022-04-11 17:26:10.033759	demo	A
demo	SUCCESS	2022-04-11 17:26:10.241095	demo	A
demo	SUCCESS	2022-04-11 17:26:10.352106	demo	A
demo	SUCCESS	2022-04-11 17:26:10.494133	demo	A
demo	SUCCESS	2022-04-11 17:26:10.536871	demo	A
demo	SUCCESS	2022-04-11 17:27:30.770323	demo	A
demo	SUCCESS	2022-04-11 17:27:54.97052	demo	A
demo	SUCCESS	2022-04-11 17:27:57.279529	demo	A
demo	SUCCESS	2022-04-11 17:27:57.360429	demo	A
demo	SUCCESS	2022-04-11 17:27:59.981852	demo	A
demo	SUCCESS	2022-04-11 17:28:00.503864	demo	A
demo	SUCCESS	2022-04-11 17:28:03.487818	demo	A
demo	SUCCESS	2022-04-11 17:28:03.764718	demo	A
demo	SUCCESS	2022-04-11 17:28:08.356475	demo	A
demo	SUCCESS	2022-04-11 17:28:08.819094	demo	A
demo	SUCCESS	2022-04-11 17:28:13.169041	demo	A
demo	SUCCESS	2022-04-11 17:28:13.355327	demo	A
demo	SUCCESS	2022-04-11 17:28:14.755167	demo	A
demo	SUCCESS	2022-04-11 17:28:15.965747	demo	A
demo	SUCCESS	2022-04-11 17:28:16.318569	demo	A
demo	SUCCESS	2022-04-11 17:28:16.321499	demo	A
demo	SUCCESS	2022-04-11 17:28:16.381725	demo	A
demo	SUCCESS	2022-04-11 17:28:16.392616	demo	A
demo	SUCCESS	2022-04-11 17:28:37.69793	demo	A
demo	SUCCESS	2022-04-11 17:28:52.26506	demo	A
demo	SUCCESS	2022-04-11 17:28:54.232017	demo	A
demo	SUCCESS	2022-04-11 17:28:54.300648	demo	A
demo	SUCCESS	2022-04-11 17:28:55.925217	demo	A
demo	SUCCESS	2022-04-11 17:28:56.156633	demo	A
demo	SUCCESS	2022-04-11 17:28:57.096036	demo	A
demo	SUCCESS	2022-04-11 17:28:57.436242	demo	A
demo	SUCCESS	2022-04-11 17:28:58.56717	demo	A
demo	SUCCESS	2022-04-11 17:28:58.749518	demo	A
demo	SUCCESS	2022-04-11 17:29:07.089933	demo	A
demo	SUCCESS	2022-04-11 17:29:07.161812	demo	A
demo	SUCCESS	2022-04-11 17:29:07.476624	demo	A
demo	SUCCESS	2022-04-11 17:29:07.631552	demo	A
demo	SUCCESS	2022-04-11 17:29:07.846391	demo	A
demo	SUCCESS	2022-04-11 17:29:07.846735	demo	A
demo	SUCCESS	2022-04-11 17:29:07.86857	demo	A
demo	SUCCESS	2022-04-11 17:29:07.871215	demo	A
demo	SUCCESS	2022-04-12 07:54:09.608758	demo	A
demo	SUCCESS	2022-04-12 08:07:07.991168	demo	A
demo	SUCCESS	2022-04-12 09:24:14.636031	demo	A
demo	SUCCESS	2022-04-12 09:24:50.296127	demo	A
demo	SUCCESS	2022-04-12 09:32:46.821802	demo	A
demo	SUCCESS	2022-04-12 09:32:54.511955	demo	A
demo	SUCCESS	2022-04-12 09:32:54.572879	demo	A
demo	SUCCESS	2022-04-12 09:33:02.250227	demo	A
demo	SUCCESS	2022-04-12 09:33:02.434294	demo	A
demo	SUCCESS	2022-04-12 09:33:04.260424	demo	A
demo	SUCCESS	2022-04-12 09:33:23.052309	demo	A
demo	SUCCESS	2022-04-12 09:33:23.399957	demo	A
demo	SUCCESS	2022-04-12 09:33:30.69111	demo	A
demo	SUCCESS	2022-04-12 09:33:30.86378	demo	A
demo	SUCCESS	2022-04-12 09:33:34.986041	demo	A
demo	SUCCESS	2022-04-12 09:33:35.073085	demo	A
demo	SUCCESS	2022-04-12 09:33:36.421846	demo	A
demo	SUCCESS	2022-04-12 09:33:36.512236	demo	A
demo	SUCCESS	2022-04-12 09:33:36.615483	demo	A
demo	SUCCESS	2022-04-12 09:33:36.666546	demo	A
demo	SUCCESS	2022-04-12 09:33:36.678102	demo	A
demo	SUCCESS	2022-04-12 09:33:36.685868	demo	A
demo	SUCCESS	2022-04-13 06:31:24.4844	demo	A
demo	SUCCESS	2022-04-13 06:44:26.805143	demo	A
demo	SUCCESS	2022-04-13 09:27:15.072604	demo	A
demo	SUCCESS	2022-04-13 09:27:19.103265	demo	A
demo	SUCCESS	2022-04-13 09:27:19.172766	demo	A
demo	SUCCESS	2022-04-13 09:27:21.091597	demo	A
demo	SUCCESS	2022-04-13 09:27:21.276875	demo	A
demo	SUCCESS	2022-04-19 08:14:15.013217	demo	A
demo	SUCCESS	2022-04-19 08:14:17.455457	demo	A
demo	SUCCESS	2022-04-19 08:14:17.525325	demo	A
demo	SUCCESS	2022-04-19 08:14:19.969963	demo	A
demo	SUCCESS	2022-04-19 08:14:20.192415	demo	A
demo	SUCCESS	2022-04-21 09:09:15.238801	demo	A
demo	SUCCESS	2022-04-21 09:09:17.185989	demo	A
demo	SUCCESS	2022-04-21 09:09:17.242054	demo	A
demo	SUCCESS	2022-04-21 09:09:19.425055	demo	A
demo	SUCCESS	2022-04-21 09:09:19.730855	demo	A
demo	SUCCESS	2022-04-21 09:09:39.758782	demo	A
demo	SUCCESS	2022-04-21 09:09:39.794785	demo	A
demo	SUCCESS	2022-04-21 09:09:47.892941	demo	A
demo	SUCCESS	2022-04-21 09:09:49.358572	demo	A
demo	SUCCESS	2022-04-21 09:09:49.391057	demo	A
demo	SUCCESS	2022-04-21 09:09:50.368336	demo	A
demo	SUCCESS	2022-04-21 09:09:50.534667	demo	A
demo	SUCCESS	2022-04-21 09:09:59.249103	demo	A
demo	SUCCESS	2022-04-21 09:09:59.441244	demo	A
demo	SUCCESS	2022-04-21 09:10:04.664813	demo	A
demo	SUCCESS	2022-04-21 09:10:04.757218	demo	A
demo	SUCCESS	2022-04-21 09:10:05.047445	demo	A
demo	SUCCESS	2022-04-21 09:10:05.171583	demo	A
demo	SUCCESS	2022-04-21 09:10:05.314753	demo	A
demo	SUCCESS	2022-04-21 09:10:05.365153	demo	A
demo	SUCCESS	2022-04-21 09:10:21.895136	demo	A
demo	SUCCESS	2022-04-21 09:10:22.194961	demo	A
demo	SUCCESS	2022-04-21 09:11:02.433621	demo	A
demo	SUCCESS	2022-04-21 09:11:16.820633	demo	A
demo	SUCCESS	2022-04-21 09:11:16.887912	demo	A
demo	SUCCESS	2022-04-21 09:11:20.654128	demo	A
demo	SUCCESS	2022-04-21 09:11:20.835777	demo	A
demo	SUCCESS	2022-04-21 09:11:33.673083	demo	A
demo	SUCCESS	2022-04-21 09:11:33.846273	demo	A
demo	SUCCESS	2022-04-21 09:11:42.161011	demo	A
demo	SUCCESS	2022-04-21 09:11:42.349897	demo	A
demo	SUCCESS	2022-04-21 09:12:09.948499	demo	A
demo	SUCCESS	2022-04-21 09:12:10.020436	demo	A
demo	SUCCESS	2022-04-21 09:12:10.237908	demo	A
demo	SUCCESS	2022-04-21 09:12:10.338287	demo	A
demo	SUCCESS	2022-04-21 09:12:10.445053	demo	A
demo	SUCCESS	2022-04-21 09:12:10.474598	demo	A
demo	SUCCESS	2022-04-21 09:12:10.492769	demo	A
demo	SUCCESS	2022-04-21 09:12:10.496016	demo	A
demo	SUCCESS	2022-04-25 10:23:20.408645	demo	A
demo	SUCCESS	2022-04-25 10:23:22.772288	demo	A
demo	SUCCESS	2022-04-25 10:23:22.837534	demo	A
demo	SUCCESS	2022-04-25 10:23:24.836623	demo	A
demo	SUCCESS	2022-04-25 10:23:25.059328	demo	A
demo	SUCCESS	2022-04-25 10:23:26.053078	demo	A
demo	SUCCESS	2022-04-25 10:23:26.089425	demo	A
\.


--
-- Data for Name: pm_user_params; Type: TABLE DATA; Schema: i2b2pm; Owner: i2b2
--

COPY i2b2pm.pm_user_params (id, datatype_cd, user_id, param_name_cd, value, change_date, entry_date, changeby_char, status_cd) FROM stdin;
\.


--
-- Data for Name: pm_user_session; Type: TABLE DATA; Schema: i2b2pm; Owner: i2b2
--

COPY i2b2pm.pm_user_session (user_id, session_id, expired_date, change_date, entry_date, changeby_char, status_cd) FROM stdin;
demo	xj91XbQYwSm3whG8QtxL	2022-04-11 17:54:59.23313	\N	2022-04-11 17:24:59.23313	demo	\N
demo	kU6BJqIw5HHPutXNKT63	2022-04-11 17:55:04.696035	\N	2022-04-11 17:25:04.696035	demo	\N
demo	Guik8wNxkh1qRm95GdJu	2022-04-11 17:55:04.908744	\N	2022-04-11 17:25:04.908744	demo	\N
demo	m8DiA9tq8qiUn6UDAN6e	2022-04-11 17:55:06.580648	\N	2022-04-11 17:25:06.580648	demo	\N
demo	N786BIRtJDszxljdjdTH	2022-04-11 17:55:06.810576	\N	2022-04-11 17:25:06.810576	demo	\N
demo	yMyFWxWdALtqBPzOYPOO	2022-04-11 17:55:10.72084	\N	2022-04-11 17:25:10.72084	demo	\N
demo	nFOV0oW0HQpAOx4s3FOM	2022-04-11 17:55:11.053808	\N	2022-04-11 17:25:11.053808	demo	\N
demo	pxExyiZdCur1WqSSc1Li	2022-04-11 17:55:15.197751	\N	2022-04-11 17:25:15.197751	demo	\N
demo	0iHWpopvH7JCefYXRdkj	2022-04-11 17:55:15.325817	\N	2022-04-11 17:25:15.325817	demo	\N
AGG_SERVICE_ACCOUNT	6K28j4idueIpaBjplwI1	2022-04-11 17:55:15.600534	\N	2022-04-11 17:25:15.600534	AGG_SERVICE_ACCOUNT	\N
demo	VuvOiKinmjdVFLKO2oYA	2022-04-11 17:55:15.780047	\N	2022-04-11 17:25:15.780047	demo	\N
demo	3O9gwZBbcb5YdopYzvXr	2022-04-11 17:55:15.97676	\N	2022-04-11 17:25:15.97676	demo	\N
demo	UuY3sAPwprvL7achti5c	2022-04-11 17:55:16.291121	\N	2022-04-11 17:25:16.291121	demo	\N
demo	YMysVuVRaT8uG6Y1ajhO	2022-04-11 17:55:16.343788	\N	2022-04-11 17:25:16.343788	demo	\N
demo	mPwfH6yp703Y6RVD3v9Z	2022-04-11 17:55:54.299141	\N	2022-04-11 17:25:54.299141	demo	\N
demo	tIAnAzQi9hEMyW6RJECB	2022-04-11 17:55:56.519674	\N	2022-04-11 17:25:56.519674	demo	\N
demo	eoqmzqbqsI3wWKILLlf0	2022-04-11 17:55:56.597928	\N	2022-04-11 17:25:56.597928	demo	\N
demo	mDXQt5qnNEEnTk3wv6he	2022-04-11 17:55:58.578857	\N	2022-04-11 17:25:58.578857	demo	\N
demo	nBKY39Q463xihCKtvZve	2022-04-11 17:55:58.850068	\N	2022-04-11 17:25:58.850068	demo	\N
demo	E1X45hrglyjnDBbUvFHr	2022-04-11 17:56:01.3371	\N	2022-04-11 17:26:01.3371	demo	\N
demo	fV4cejMNjgjJTmZTil1b	2022-04-11 17:56:01.631193	\N	2022-04-11 17:26:01.631193	demo	\N
demo	FWnwhCqYKN1wOL6uq24I	2022-04-11 17:56:09.975032	\N	2022-04-11 17:26:09.975032	demo	\N
demo	cu73saOpVZ5zn3Tdvoa0	2022-04-11 17:56:10.034834	\N	2022-04-11 17:26:10.034834	demo	\N
AGG_SERVICE_ACCOUNT	JtXmfNyGZlT8BPsQUTM9	2022-04-11 17:56:10.139744	\N	2022-04-11 17:26:10.139744	AGG_SERVICE_ACCOUNT	\N
demo	kArVqMuK8lRcACFJyB8d	2022-04-11 17:56:10.242306	\N	2022-04-11 17:26:10.242306	demo	\N
demo	VnLw8GLZm1REb3NrrDcO	2022-04-11 17:56:10.353299	\N	2022-04-11 17:26:10.353299	demo	\N
demo	9Y598LELUN2EZKe8feJS	2022-04-11 17:56:10.497416	\N	2022-04-11 17:26:10.497416	demo	\N
demo	gyojxADATP89IjU8Uh2L	2022-04-11 17:56:10.53861	\N	2022-04-11 17:26:10.53861	demo	\N
demo	nw4Vknb8xbuG1F823CrQ	2022-04-11 17:57:30.788894	\N	2022-04-11 17:27:30.788894	demo	\N
demo	rUMQIZ9gNgcreDmhrHik	2022-04-11 17:57:54.971779	\N	2022-04-11 17:27:54.971779	demo	\N
demo	OE6Gl2yLsHkDQRAs73pw	2022-04-11 17:57:57.28131	\N	2022-04-11 17:27:57.28131	demo	\N
demo	3PjnPctJ8Hjw8NgcHOI8	2022-04-11 17:57:57.367577	\N	2022-04-11 17:27:57.367577	demo	\N
demo	XdgKZ8zbiP2EuHLfXQy9	2022-04-11 17:58:00.000912	\N	2022-04-11 17:28:00.000912	demo	\N
demo	V3CpuVAxVfen7gXM7vaj	2022-04-11 17:58:00.51083	\N	2022-04-11 17:28:00.51083	demo	\N
demo	b8GSsBUOOjEhcHKeUcJ3	2022-04-11 17:58:03.501412	\N	2022-04-11 17:28:03.501412	demo	\N
demo	N3YKU5vT5v0AXvGRWSvc	2022-04-11 17:58:03.775956	\N	2022-04-11 17:28:03.775956	demo	\N
demo	lLbMKlnRMpKkaBRlaNQ3	2022-04-11 17:58:08.362879	\N	2022-04-11 17:28:08.362879	demo	\N
demo	JjnFYngtNc8cVggaqjeB	2022-04-11 17:58:08.833856	\N	2022-04-11 17:28:08.833856	demo	\N
demo	D4Krgmw7ejk4gvlbEQBq	2022-04-11 17:58:13.273436	\N	2022-04-11 17:28:13.273436	demo	\N
demo	3F6Tkbr4QsjKnu5a2sWl	2022-04-11 17:58:13.387132	\N	2022-04-11 17:28:13.387132	demo	\N
AGG_SERVICE_ACCOUNT	CsA5T6jr2lIPJrMQ6FIW	2022-04-11 17:58:14.012382	\N	2022-04-11 17:28:14.012382	AGG_SERVICE_ACCOUNT	\N
demo	LMgFRrqehGMWxsgAZUQR	2022-04-11 17:58:14.802497	\N	2022-04-11 17:28:14.802497	demo	\N
demo	5hEvGKgjxIdyDzoMaThe	2022-04-11 17:58:16.027724	\N	2022-04-11 17:28:16.027724	demo	\N
demo	oHXv8IexANrfzHmmlUeo	2022-04-11 17:58:16.330805	\N	2022-04-11 17:28:16.330805	demo	\N
demo	IyeS3J2S5uOkh2jxUa6o	2022-04-11 17:58:16.331555	\N	2022-04-11 17:28:16.331555	demo	\N
demo	hoPXpI6r4lZWVMVZfsYL	2022-04-11 17:58:16.385248	\N	2022-04-11 17:28:16.385248	demo	\N
demo	6pJpL7S6mG2EVoRKuWOv	2022-04-11 17:58:16.397611	\N	2022-04-11 17:28:16.397611	demo	\N
demo	GYf9MSEZJuklTxPmJDwr	2022-04-11 17:58:37.699559	\N	2022-04-11 17:28:37.699559	demo	\N
demo	7UCxN4llcyqX15NMG4Aj	2022-04-11 17:58:52.266279	\N	2022-04-11 17:28:52.266279	demo	\N
demo	Gu5FajQWuw5453CWFvos	2022-04-11 17:58:54.233309	\N	2022-04-11 17:28:54.233309	demo	\N
demo	KLc4eKkELh1uZSEgpXg6	2022-04-11 17:58:54.302454	\N	2022-04-11 17:28:54.302454	demo	\N
demo	D2ztDyOa4yoPaiYp28JK	2022-04-11 17:58:55.926427	\N	2022-04-11 17:28:55.926427	demo	\N
demo	S8bgq8c2aj0dxGqJ6URo	2022-04-11 17:58:56.159446	\N	2022-04-11 17:28:56.159446	demo	\N
demo	kJLC520LucXn6ildZNtc	2022-04-11 17:58:57.097405	\N	2022-04-11 17:28:57.097405	demo	\N
demo	IImjekNbgAHtJH9X7x9O	2022-04-11 17:58:57.437362	\N	2022-04-11 17:28:57.437362	demo	\N
demo	1BpBcDOAiQhTmFo6fx5l	2022-04-11 17:58:58.568703	\N	2022-04-11 17:28:58.568703	demo	\N
demo	ORdiIlUFU9WL7hawNqLF	2022-04-11 17:58:58.75185	\N	2022-04-11 17:28:58.75185	demo	\N
demo	pjrbEEFlbpYUMKzNVsg1	2022-04-11 17:59:07.091125	\N	2022-04-11 17:29:07.091125	demo	\N
demo	gfVUrnxY68IryrLhWc6P	2022-04-11 17:59:07.162989	\N	2022-04-11 17:29:07.162989	demo	\N
AGG_SERVICE_ACCOUNT	aY8CziIIxokx9X9YJyNo	2022-04-11 17:59:07.343364	\N	2022-04-11 17:29:07.343364	AGG_SERVICE_ACCOUNT	\N
demo	2UQyr0N9tiRJxZARQ9Gb	2022-04-11 17:59:07.477772	\N	2022-04-11 17:29:07.477772	demo	\N
demo	DsmMhR8oaxksZ21vyESQ	2022-04-11 17:59:07.632897	\N	2022-04-11 17:29:07.632897	demo	\N
demo	EUQmjUaND23NEZIy5Hnk	2022-04-11 17:59:07.849499	\N	2022-04-11 17:29:07.849499	demo	\N
demo	3rn5gYdbd1p89eE1Ix7I	2022-04-11 17:59:07.849666	\N	2022-04-11 17:29:07.849666	demo	\N
demo	gvR0e0tkIsc2sy4L8vMN	2022-04-11 17:59:07.869834	\N	2022-04-11 17:29:07.869834	demo	\N
demo	XWPnNKPf8fV6ls92lWut	2022-04-11 17:59:07.872502	\N	2022-04-11 17:29:07.872502	demo	\N
demo	TMqhyWdpaVoBEhhjv8Kc	2022-04-12 08:24:09.610239	\N	2022-04-12 07:54:09.610239	demo	\N
demo	9dOqsUoHdtyZyxoc8yZB	2022-04-12 08:37:07.996452	\N	2022-04-12 08:07:07.996452	demo	\N
demo	F63WXEVRIbV2sJiMivKx	2022-04-12 09:54:14.638224	\N	2022-04-12 09:24:14.638224	demo	\N
demo	zrVyeWXABU6EeOpLv7VR	2022-04-12 09:54:50.29759	\N	2022-04-12 09:24:50.29759	demo	\N
demo	bDySelsCE99OWYMCMT3D	2022-04-12 10:02:46.823085	\N	2022-04-12 09:32:46.823085	demo	\N
demo	iCyK8l1P82GUg0F93ZYP	2022-04-12 10:02:54.513398	\N	2022-04-12 09:32:54.513398	demo	\N
demo	PjHIVptYE06Zl9Uolscp	2022-04-12 10:02:54.574289	\N	2022-04-12 09:32:54.574289	demo	\N
demo	flS2HaB2zMDPZo3ixyEI	2022-04-12 10:03:02.251343	\N	2022-04-12 09:33:02.251343	demo	\N
demo	1O9iPGWtxfFKF4CeUWpK	2022-04-12 10:03:02.435642	\N	2022-04-12 09:33:02.435642	demo	\N
demo	Hn7SwlucxDJpyGfiJIsQ	2022-04-12 10:03:04.26315	\N	2022-04-12 09:33:04.26315	demo	\N
demo	mrkwTC4Fel2geKyDIUJv	2022-04-12 10:03:23.053566	\N	2022-04-12 09:33:23.053566	demo	\N
demo	tKVx3GoIgW1fFxDbPWwE	2022-04-12 10:03:23.401271	\N	2022-04-12 09:33:23.401271	demo	\N
demo	DzQ3n4LOXs4kf9N4e05o	2022-04-12 10:03:30.6924	\N	2022-04-12 09:33:30.6924	demo	\N
demo	qvkT194OfVpNc2EiLZSf	2022-04-12 10:03:30.865398	\N	2022-04-12 09:33:30.865398	demo	\N
demo	5PYtFr3aAgByQ5IBrThc	2022-04-12 10:03:34.987526	\N	2022-04-12 09:33:34.987526	demo	\N
demo	5c6ts1brFeX8GDzYYx00	2022-04-12 10:03:35.07441	\N	2022-04-12 09:33:35.07441	demo	\N
AGG_SERVICE_ACCOUNT	ZoDAUNxAndyD72r3KNKT	2022-04-12 10:03:35.18201	\N	2022-04-12 09:33:35.18201	AGG_SERVICE_ACCOUNT	\N
AGG_SERVICE_ACCOUNT	FgdjWnc6UgUH76CjXW3n	2022-04-12 10:03:35.23579	\N	2022-04-12 09:33:35.23579	AGG_SERVICE_ACCOUNT	\N
AGG_SERVICE_ACCOUNT	qVKlBFzWZET357IdyLnc	2022-04-12 10:03:35.296824	\N	2022-04-12 09:33:35.296824	AGG_SERVICE_ACCOUNT	\N
AGG_SERVICE_ACCOUNT	v9syv88ySGhce0cg6nKA	2022-04-12 10:03:35.344845	\N	2022-04-12 09:33:35.344845	AGG_SERVICE_ACCOUNT	\N
demo	9tcyczFzYZjQ3jSHoKAr	2022-04-12 10:03:36.42309	\N	2022-04-12 09:33:36.42309	demo	\N
demo	pqY2cHGiAWB5ZeFQHUoD	2022-04-12 10:03:36.513602	\N	2022-04-12 09:33:36.513602	demo	\N
demo	NwfRYfNufmyPMkbmSrPh	2022-04-12 10:03:36.647565	\N	2022-04-12 09:33:36.647565	demo	\N
demo	nyjUq2l2BhcAfoWn9pfo	2022-04-12 10:03:36.667673	\N	2022-04-12 09:33:36.667673	demo	\N
demo	rq6sV1U1JFouqQS5uVyI	2022-04-12 10:03:36.679887	\N	2022-04-12 09:33:36.679887	demo	\N
demo	5yJ6Vb3zA0ekD2LrXnTR	2022-04-12 10:03:36.686785	\N	2022-04-12 09:33:36.686785	demo	\N
demo	6glOy5ljExT6TEaYkGHm	2022-04-13 07:01:24.486254	\N	2022-04-13 06:31:24.486254	demo	\N
demo	KvIuPUetqcVMomQJmb6p	2022-04-13 07:14:26.806463	\N	2022-04-13 06:44:26.806463	demo	\N
demo	DabFReWQcKtOu34tJfm3	2022-04-13 09:57:15.073878	\N	2022-04-13 09:27:15.073878	demo	\N
demo	JMeysVOL57WIAzB17jeJ	2022-04-13 09:57:19.104379	\N	2022-04-13 09:27:19.104379	demo	\N
demo	q4ecLFMEcw5CMoRtE89z	2022-04-13 09:57:19.173967	\N	2022-04-13 09:27:19.173967	demo	\N
demo	nmO9DXVNvYzr0La3FnJx	2022-04-13 09:57:21.092715	\N	2022-04-13 09:27:21.092715	demo	\N
demo	JrpG9q92rxBey1lCN6CO	2022-04-13 09:57:21.27812	\N	2022-04-13 09:27:21.27812	demo	\N
demo	eQN9f9cdk1RqabjTN5fd	2022-04-19 08:44:15.014835	\N	2022-04-19 08:14:15.014835	demo	\N
demo	RKQn7uUTzoQwXOOFJl8x	2022-04-19 08:44:17.456913	\N	2022-04-19 08:14:17.456913	demo	\N
demo	XAFgT1vXi2JIc8CUJYVS	2022-04-19 08:44:17.526784	\N	2022-04-19 08:14:17.526784	demo	\N
demo	r2G6yQyLln3PVuixrnxd	2022-04-19 08:44:19.973352	\N	2022-04-19 08:14:19.973352	demo	\N
demo	RZR2XD2QEx4piUt6Ha5F	2022-04-19 08:44:20.193804	\N	2022-04-19 08:14:20.193804	demo	\N
demo	AQEw1vHMGQYVEEZr1j7P	2022-04-21 09:39:15.240299	\N	2022-04-21 09:09:15.240299	demo	\N
demo	uNBQZW30KUJzkOaFQSdI	2022-04-21 09:39:17.18744	\N	2022-04-21 09:09:17.18744	demo	\N
demo	Vj2I7Idvr9rh9K8235jv	2022-04-21 09:39:17.243127	\N	2022-04-21 09:09:17.243127	demo	\N
demo	nkybjeJcEXcr3AxG5U95	2022-04-21 09:39:19.426684	\N	2022-04-21 09:09:19.426684	demo	\N
demo	Nqu48mZLXEWhQnRZeCpK	2022-04-21 09:39:19.73234	\N	2022-04-21 09:09:19.73234	demo	\N
demo	7RcSrgpPMWU071jWHY8r	2022-04-21 09:39:39.760038	\N	2022-04-21 09:09:39.760038	demo	\N
demo	b2b94KUo3IqihAhav1XE	2022-04-21 09:39:39.796287	\N	2022-04-21 09:09:39.796287	demo	\N
demo	HVSPYyxawEiKA9PKyLUo	2022-04-21 09:39:47.894247	\N	2022-04-21 09:09:47.894247	demo	\N
demo	41J2vewt2fhfJBlnLNom	2022-04-21 09:39:49.359586	\N	2022-04-21 09:09:49.359586	demo	\N
demo	mdVW1UdDYtl4e3yPB4pK	2022-04-21 09:39:49.391931	\N	2022-04-21 09:09:49.391931	demo	\N
demo	wVnoG1wVvmvGjj52eqQ4	2022-04-21 09:39:50.369656	\N	2022-04-21 09:09:50.369656	demo	\N
demo	fRqz1HyM28DTJlDA7XCk	2022-04-21 09:39:50.536132	\N	2022-04-21 09:09:50.536132	demo	\N
demo	K8UuVArOJVQp4Y528y1l	2022-04-21 09:39:59.250367	\N	2022-04-21 09:09:59.250367	demo	\N
demo	wY6CVqifDSnRyvgjeYeB	2022-04-21 09:39:59.442168	\N	2022-04-21 09:09:59.442168	demo	\N
demo	1MbD7WPNnotDqjC6Xofi	2022-04-21 09:40:04.667112	\N	2022-04-21 09:10:04.667112	demo	\N
demo	S4D5nLcT4aN843FIMMQQ	2022-04-21 09:40:04.758708	\N	2022-04-21 09:10:04.758708	demo	\N
AGG_SERVICE_ACCOUNT	Wo5ga9XC8BnF4hI9v12F	2022-04-21 09:40:04.900684	\N	2022-04-21 09:10:04.900684	AGG_SERVICE_ACCOUNT	\N
demo	pfpPvKWrSeq64qnIFfUE	2022-04-21 09:40:05.049572	\N	2022-04-21 09:10:05.049572	demo	\N
demo	6ubZRkhI9wfGLsolyTjw	2022-04-21 09:40:05.172859	\N	2022-04-21 09:10:05.172859	demo	\N
demo	lmpbbuXKNnDL7Hlgj4w5	2022-04-21 09:40:05.318869	\N	2022-04-21 09:10:05.318869	demo	\N
demo	vvFJIPDdgnfEmFeA8RY6	2022-04-21 09:40:05.366925	\N	2022-04-21 09:10:05.366925	demo	\N
demo	pZKmrTx4f9pcDsBI6iDy	2022-04-21 09:40:21.89637	\N	2022-04-21 09:10:21.89637	demo	\N
demo	KzTo3nvltLJwmaL8jMrQ	2022-04-21 09:40:22.196464	\N	2022-04-21 09:10:22.196464	demo	\N
demo	70bGEhXSnkryGIdW4cFN	2022-04-21 09:41:02.434723	\N	2022-04-21 09:11:02.434723	demo	\N
demo	6c8jES73fOGhrz6H7jSH	2022-04-21 09:41:16.822086	\N	2022-04-21 09:11:16.822086	demo	\N
demo	2CDCxwFGWWT6v0asGtgq	2022-04-21 09:41:16.889621	\N	2022-04-21 09:11:16.889621	demo	\N
demo	a2KEUK9toGNbR3tRXSSR	2022-04-21 09:41:20.655703	\N	2022-04-21 09:11:20.655703	demo	\N
demo	Ap9mUU52FmYxWABGVdAm	2022-04-21 09:41:20.837072	\N	2022-04-21 09:11:20.837072	demo	\N
demo	EQPwF9Hd1SaLx6ZKwNYV	2022-04-21 09:41:33.674323	\N	2022-04-21 09:11:33.674323	demo	\N
demo	IjHsZhjqRdUPiQZDrbO9	2022-04-21 09:41:33.847612	\N	2022-04-21 09:11:33.847612	demo	\N
demo	ZKUiKEmICnsaaD3nFrdK	2022-04-21 09:41:42.16298	\N	2022-04-21 09:11:42.16298	demo	\N
demo	6bJcZySnXs4jRnM74CUL	2022-04-21 09:41:42.350989	\N	2022-04-21 09:11:42.350989	demo	\N
demo	mjl3eekyupJ2pcIWZPgL	2022-04-21 09:42:09.949988	\N	2022-04-21 09:12:09.949988	demo	\N
demo	BD8tAP3ZZIqtulkr3jBC	2022-04-21 09:42:10.021522	\N	2022-04-21 09:12:10.021522	demo	\N
AGG_SERVICE_ACCOUNT	0uKTuc8dgIDWbt9jrODp	2022-04-21 09:42:10.148595	\N	2022-04-21 09:12:10.148595	AGG_SERVICE_ACCOUNT	\N
demo	Rt8HFEjB3y5q8srT5D8V	2022-04-21 09:42:10.239984	\N	2022-04-21 09:12:10.239984	demo	\N
demo	k6prLvarf2oD6dXB1D6B	2022-04-21 09:42:10.339277	\N	2022-04-21 09:12:10.339277	demo	\N
demo	jEbX5K2gFBWvqkbVxoPK	2022-04-21 09:42:10.446755	\N	2022-04-21 09:12:10.446755	demo	\N
demo	oSvGJu2avGV8iEIvRBZI	2022-04-21 09:42:10.478707	\N	2022-04-21 09:12:10.478707	demo	\N
demo	iYkd90lMPPP4yakYv7jb	2022-04-21 09:42:10.498803	\N	2022-04-21 09:12:10.498803	demo	\N
demo	4chLcmaarqDKZNHqYidB	2022-04-21 09:42:10.499408	\N	2022-04-21 09:12:10.499408	demo	\N
demo	ZC2Kj5rF5K2ROHJORPRe	2022-04-25 10:53:20.41021	\N	2022-04-25 10:23:20.41021	demo	\N
demo	7GzeN55HyuY1TCGlPS2H	2022-04-25 10:53:22.774148	\N	2022-04-25 10:23:22.774148	demo	\N
demo	rLeGdfwxXRmfQ5TXFQM5	2022-04-25 10:53:22.840083	\N	2022-04-25 10:23:22.840083	demo	\N
demo	2yNTXSWOvlwh76nLpXEg	2022-04-25 10:53:24.838351	\N	2022-04-25 10:23:24.838351	demo	\N
demo	JbE6uPhbFsSA5l7lWATT	2022-04-25 10:53:25.06046	\N	2022-04-25 10:23:25.06046	demo	\N
demo	wvHtqeO18zdzWfJ8KpBS	2022-04-25 10:53:26.054678	\N	2022-04-25 10:23:26.054678	demo	\N
demo	NajCUn5f3Gt4V6bRbppJ	2022-04-25 10:53:26.090421	\N	2022-04-25 10:23:26.090421	demo	\N
\.


--
-- Data for Name: workplace; Type: TABLE DATA; Schema: i2b2workdata; Owner: i2b2
--

COPY i2b2workdata.workplace (c_name, c_user_id, c_group_id, c_share_id, c_index, c_parent_index, c_visualattributes, c_protected_access, c_tooltip, c_work_xml, c_work_xml_schema, c_work_xml_i2b2_type, c_entry_date, c_change_date, c_status_cd) FROM stdin;
\.


--
-- Data for Name: workplace_access; Type: TABLE DATA; Schema: i2b2workdata; Owner: i2b2
--

COPY i2b2workdata.workplace_access (c_table_cd, c_table_name, c_protected_access, c_hlevel, c_name, c_user_id, c_group_id, c_share_id, c_index, c_parent_index, c_visualattributes, c_tooltip, c_entry_date, c_change_date, c_status_cd) FROM stdin;
demo	WORKPLACE	N	0	SHARED	shared	demo	Y	100	\N	CA 	SHARED	\N	\N	\N
demo	WORKPLACE	N	0	@	@	@	N	0	\N	CA 	@	\N	\N	\N
\.


--
-- Name: observation_fact_text_search_index_seq; Type: SEQUENCE SET; Schema: i2b2demodata; Owner: i2b2
--

SELECT pg_catalog.setval('i2b2demodata.observation_fact_text_search_index_seq', 1163, true);


--
-- Name: qt_patient_enc_collection_patient_enc_coll_id_seq; Type: SEQUENCE SET; Schema: i2b2demodata; Owner: i2b2
--

SELECT pg_catalog.setval('i2b2demodata.qt_patient_enc_collection_patient_enc_coll_id_seq', 1, false);


--
-- Name: qt_patient_set_collection_patient_set_coll_id_seq; Type: SEQUENCE SET; Schema: i2b2demodata; Owner: i2b2
--

SELECT pg_catalog.setval('i2b2demodata.qt_patient_set_collection_patient_set_coll_id_seq', 793, true);


--
-- Name: qt_pdo_query_master_query_master_id_seq; Type: SEQUENCE SET; Schema: i2b2demodata; Owner: i2b2
--

SELECT pg_catalog.setval('i2b2demodata.qt_pdo_query_master_query_master_id_seq', 7, true);


--
-- Name: qt_query_instance_query_instance_id_seq; Type: SEQUENCE SET; Schema: i2b2demodata; Owner: i2b2
--

SELECT pg_catalog.setval('i2b2demodata.qt_query_instance_query_instance_id_seq', 7, true);


--
-- Name: qt_query_master_query_master_id_seq; Type: SEQUENCE SET; Schema: i2b2demodata; Owner: i2b2
--

SELECT pg_catalog.setval('i2b2demodata.qt_query_master_query_master_id_seq', 7, true);


--
-- Name: qt_query_result_instance_result_instance_id_seq; Type: SEQUENCE SET; Schema: i2b2demodata; Owner: i2b2
--

SELECT pg_catalog.setval('i2b2demodata.qt_query_result_instance_result_instance_id_seq', 14, true);


--
-- Name: qt_xml_result_xml_result_id_seq; Type: SEQUENCE SET; Schema: i2b2demodata; Owner: i2b2
--

SELECT pg_catalog.setval('i2b2demodata.qt_xml_result_xml_result_id_seq', 7, true);


--
-- Name: upload_status_upload_id_seq; Type: SEQUENCE SET; Schema: i2b2demodata; Owner: i2b2
--

SELECT pg_catalog.setval('i2b2demodata.upload_status_upload_id_seq', 1, false);


--
-- Name: ont_process_status_process_id_seq; Type: SEQUENCE SET; Schema: i2b2metadata; Owner: i2b2
--

SELECT pg_catalog.setval('i2b2metadata.ont_process_status_process_id_seq', 1, false);


--
-- Name: pm_approvals_params_id_seq; Type: SEQUENCE SET; Schema: i2b2pm; Owner: i2b2
--

SELECT pg_catalog.setval('i2b2pm.pm_approvals_params_id_seq', 1, false);


--
-- Name: pm_cell_params_id_seq; Type: SEQUENCE SET; Schema: i2b2pm; Owner: i2b2
--

SELECT pg_catalog.setval('i2b2pm.pm_cell_params_id_seq', 1, true);


--
-- Name: pm_global_params_id_seq; Type: SEQUENCE SET; Schema: i2b2pm; Owner: i2b2
--

SELECT pg_catalog.setval('i2b2pm.pm_global_params_id_seq', 1, false);


--
-- Name: pm_hive_params_id_seq; Type: SEQUENCE SET; Schema: i2b2pm; Owner: i2b2
--

SELECT pg_catalog.setval('i2b2pm.pm_hive_params_id_seq', 1, false);


--
-- Name: pm_project_params_id_seq; Type: SEQUENCE SET; Schema: i2b2pm; Owner: i2b2
--

SELECT pg_catalog.setval('i2b2pm.pm_project_params_id_seq', 1, false);


--
-- Name: pm_project_request_id_seq; Type: SEQUENCE SET; Schema: i2b2pm; Owner: i2b2
--

SELECT pg_catalog.setval('i2b2pm.pm_project_request_id_seq', 1, false);


--
-- Name: pm_project_user_params_id_seq; Type: SEQUENCE SET; Schema: i2b2pm; Owner: i2b2
--

SELECT pg_catalog.setval('i2b2pm.pm_project_user_params_id_seq', 1, false);


--
-- Name: pm_user_params_id_seq; Type: SEQUENCE SET; Schema: i2b2pm; Owner: i2b2
--

SELECT pg_catalog.setval('i2b2pm.pm_user_params_id_seq', 1, false);


--
-- Name: explore_query explore_query_pkey; Type: CONSTRAINT; Schema: gecodatasourceplugintest; Owner: i2b2
--

ALTER TABLE ONLY gecodatasourceplugintest.explore_query
    ADD CONSTRAINT explore_query_pkey PRIMARY KEY (id);


--
-- Name: saved_cohort saved_cohort_pkey; Type: CONSTRAINT; Schema: gecodatasourceplugintest; Owner: i2b2
--

ALTER TABLE ONLY gecodatasourceplugintest.saved_cohort
    ADD CONSTRAINT saved_cohort_pkey PRIMARY KEY (name, explore_query_id);


--
-- Name: qt_analysis_plugin analysis_plugin_pk; Type: CONSTRAINT; Schema: i2b2demodata; Owner: i2b2
--

ALTER TABLE ONLY i2b2demodata.qt_analysis_plugin
    ADD CONSTRAINT analysis_plugin_pk PRIMARY KEY (plugin_id);


--
-- Name: qt_analysis_plugin_result_type analysis_plugin_result_pk; Type: CONSTRAINT; Schema: i2b2demodata; Owner: i2b2
--

ALTER TABLE ONLY i2b2demodata.qt_analysis_plugin_result_type
    ADD CONSTRAINT analysis_plugin_result_pk PRIMARY KEY (plugin_id, result_type_id);


--
-- Name: code_lookup code_lookup_pk; Type: CONSTRAINT; Schema: i2b2demodata; Owner: i2b2
--

ALTER TABLE ONLY i2b2demodata.code_lookup
    ADD CONSTRAINT code_lookup_pk PRIMARY KEY (table_cd, column_cd, code_cd);


--
-- Name: concept_dimension concept_dimension_pk; Type: CONSTRAINT; Schema: i2b2demodata; Owner: i2b2
--

ALTER TABLE ONLY i2b2demodata.concept_dimension
    ADD CONSTRAINT concept_dimension_pk PRIMARY KEY (concept_path);


--
-- Name: encounter_mapping encounter_mapping_pk; Type: CONSTRAINT; Schema: i2b2demodata; Owner: i2b2
--

ALTER TABLE ONLY i2b2demodata.encounter_mapping
    ADD CONSTRAINT encounter_mapping_pk PRIMARY KEY (encounter_ide, encounter_ide_source, project_id, patient_ide, patient_ide_source);


--
-- Name: modifier_dimension modifier_dimension_pk; Type: CONSTRAINT; Schema: i2b2demodata; Owner: i2b2
--

ALTER TABLE ONLY i2b2demodata.modifier_dimension
    ADD CONSTRAINT modifier_dimension_pk PRIMARY KEY (modifier_path);


--
-- Name: observation_fact observation_fact_pk; Type: CONSTRAINT; Schema: i2b2demodata; Owner: i2b2
--

ALTER TABLE ONLY i2b2demodata.observation_fact
    ADD CONSTRAINT observation_fact_pk PRIMARY KEY (patient_num, concept_cd, modifier_cd, start_date, encounter_num, instance_num, provider_id);


--
-- Name: patient_dimension patient_dimension_pk; Type: CONSTRAINT; Schema: i2b2demodata; Owner: i2b2
--

ALTER TABLE ONLY i2b2demodata.patient_dimension
    ADD CONSTRAINT patient_dimension_pk PRIMARY KEY (patient_num);


--
-- Name: patient_mapping patient_mapping_pk; Type: CONSTRAINT; Schema: i2b2demodata; Owner: i2b2
--

ALTER TABLE ONLY i2b2demodata.patient_mapping
    ADD CONSTRAINT patient_mapping_pk PRIMARY KEY (patient_ide, patient_ide_source, project_id);


--
-- Name: source_master pk_sourcemaster_sourcecd; Type: CONSTRAINT; Schema: i2b2demodata; Owner: i2b2
--

ALTER TABLE ONLY i2b2demodata.source_master
    ADD CONSTRAINT pk_sourcemaster_sourcecd PRIMARY KEY (source_cd);


--
-- Name: set_type pk_st_id; Type: CONSTRAINT; Schema: i2b2demodata; Owner: i2b2
--

ALTER TABLE ONLY i2b2demodata.set_type
    ADD CONSTRAINT pk_st_id PRIMARY KEY (id);


--
-- Name: set_upload_status pk_up_upstatus_idsettypeid; Type: CONSTRAINT; Schema: i2b2demodata; Owner: i2b2
--

ALTER TABLE ONLY i2b2demodata.set_upload_status
    ADD CONSTRAINT pk_up_upstatus_idsettypeid PRIMARY KEY (upload_id, set_type_id);


--
-- Name: provider_dimension provider_dimension_pk; Type: CONSTRAINT; Schema: i2b2demodata; Owner: i2b2
--

ALTER TABLE ONLY i2b2demodata.provider_dimension
    ADD CONSTRAINT provider_dimension_pk PRIMARY KEY (provider_path, provider_id);


--
-- Name: qt_patient_enc_collection qt_patient_enc_collection_pkey; Type: CONSTRAINT; Schema: i2b2demodata; Owner: i2b2
--

ALTER TABLE ONLY i2b2demodata.qt_patient_enc_collection
    ADD CONSTRAINT qt_patient_enc_collection_pkey PRIMARY KEY (patient_enc_coll_id);


--
-- Name: qt_patient_set_collection qt_patient_set_collection_pkey; Type: CONSTRAINT; Schema: i2b2demodata; Owner: i2b2
--

ALTER TABLE ONLY i2b2demodata.qt_patient_set_collection
    ADD CONSTRAINT qt_patient_set_collection_pkey PRIMARY KEY (patient_set_coll_id);


--
-- Name: qt_pdo_query_master qt_pdo_query_master_pkey; Type: CONSTRAINT; Schema: i2b2demodata; Owner: i2b2
--

ALTER TABLE ONLY i2b2demodata.qt_pdo_query_master
    ADD CONSTRAINT qt_pdo_query_master_pkey PRIMARY KEY (query_master_id);


--
-- Name: qt_privilege qt_privilege_pkey; Type: CONSTRAINT; Schema: i2b2demodata; Owner: i2b2
--

ALTER TABLE ONLY i2b2demodata.qt_privilege
    ADD CONSTRAINT qt_privilege_pkey PRIMARY KEY (protection_label_cd);


--
-- Name: qt_query_instance qt_query_instance_pkey; Type: CONSTRAINT; Schema: i2b2demodata; Owner: i2b2
--

ALTER TABLE ONLY i2b2demodata.qt_query_instance
    ADD CONSTRAINT qt_query_instance_pkey PRIMARY KEY (query_instance_id);


--
-- Name: qt_query_master qt_query_master_pkey; Type: CONSTRAINT; Schema: i2b2demodata; Owner: i2b2
--

ALTER TABLE ONLY i2b2demodata.qt_query_master
    ADD CONSTRAINT qt_query_master_pkey PRIMARY KEY (query_master_id);


--
-- Name: qt_query_result_instance qt_query_result_instance_pkey; Type: CONSTRAINT; Schema: i2b2demodata; Owner: i2b2
--

ALTER TABLE ONLY i2b2demodata.qt_query_result_instance
    ADD CONSTRAINT qt_query_result_instance_pkey PRIMARY KEY (result_instance_id);


--
-- Name: qt_query_result_type qt_query_result_type_pkey; Type: CONSTRAINT; Schema: i2b2demodata; Owner: i2b2
--

ALTER TABLE ONLY i2b2demodata.qt_query_result_type
    ADD CONSTRAINT qt_query_result_type_pkey PRIMARY KEY (result_type_id);


--
-- Name: qt_query_status_type qt_query_status_type_pkey; Type: CONSTRAINT; Schema: i2b2demodata; Owner: i2b2
--

ALTER TABLE ONLY i2b2demodata.qt_query_status_type
    ADD CONSTRAINT qt_query_status_type_pkey PRIMARY KEY (status_type_id);


--
-- Name: qt_xml_result qt_xml_result_pkey; Type: CONSTRAINT; Schema: i2b2demodata; Owner: i2b2
--

ALTER TABLE ONLY i2b2demodata.qt_xml_result
    ADD CONSTRAINT qt_xml_result_pkey PRIMARY KEY (xml_result_id);


--
-- Name: upload_status upload_status_pkey; Type: CONSTRAINT; Schema: i2b2demodata; Owner: i2b2
--

ALTER TABLE ONLY i2b2demodata.upload_status
    ADD CONSTRAINT upload_status_pkey PRIMARY KEY (upload_id);


--
-- Name: visit_dimension visit_dimension_pk; Type: CONSTRAINT; Schema: i2b2demodata; Owner: i2b2
--

ALTER TABLE ONLY i2b2demodata.visit_dimension
    ADD CONSTRAINT visit_dimension_pk PRIMARY KEY (encounter_num, patient_num);


--
-- Name: crc_analysis_job analsis_job_pk; Type: CONSTRAINT; Schema: i2b2hive; Owner: i2b2
--

ALTER TABLE ONLY i2b2hive.crc_analysis_job
    ADD CONSTRAINT analsis_job_pk PRIMARY KEY (job_id);


--
-- Name: crc_db_lookup crc_db_lookup_pk; Type: CONSTRAINT; Schema: i2b2hive; Owner: i2b2
--

ALTER TABLE ONLY i2b2hive.crc_db_lookup
    ADD CONSTRAINT crc_db_lookup_pk PRIMARY KEY (c_domain_id, c_project_path, c_owner_id);


--
-- Name: hive_cell_params hive_ce__pk; Type: CONSTRAINT; Schema: i2b2hive; Owner: i2b2
--

ALTER TABLE ONLY i2b2hive.hive_cell_params
    ADD CONSTRAINT hive_ce__pk PRIMARY KEY (id);


--
-- Name: im_db_lookup im_db_lookup_pk; Type: CONSTRAINT; Schema: i2b2hive; Owner: i2b2
--

ALTER TABLE ONLY i2b2hive.im_db_lookup
    ADD CONSTRAINT im_db_lookup_pk PRIMARY KEY (c_domain_id, c_project_path, c_owner_id);


--
-- Name: ont_db_lookup ont_db_lookup_pk; Type: CONSTRAINT; Schema: i2b2hive; Owner: i2b2
--

ALTER TABLE ONLY i2b2hive.ont_db_lookup
    ADD CONSTRAINT ont_db_lookup_pk PRIMARY KEY (c_domain_id, c_project_path, c_owner_id);


--
-- Name: work_db_lookup work_db_lookup_pk; Type: CONSTRAINT; Schema: i2b2hive; Owner: i2b2
--

ALTER TABLE ONLY i2b2hive.work_db_lookup
    ADD CONSTRAINT work_db_lookup_pk PRIMARY KEY (c_domain_id, c_project_path, c_owner_id);


--
-- Name: im_mpi_demographics im_mpi_demographics_pk; Type: CONSTRAINT; Schema: i2b2imdata; Owner: i2b2
--

ALTER TABLE ONLY i2b2imdata.im_mpi_demographics
    ADD CONSTRAINT im_mpi_demographics_pk PRIMARY KEY (global_id);


--
-- Name: im_mpi_mapping im_mpi_mapping_pk; Type: CONSTRAINT; Schema: i2b2imdata; Owner: i2b2
--

ALTER TABLE ONLY i2b2imdata.im_mpi_mapping
    ADD CONSTRAINT im_mpi_mapping_pk PRIMARY KEY (lcl_site, lcl_id, update_date);


--
-- Name: im_project_patients im_project_patients_pk; Type: CONSTRAINT; Schema: i2b2imdata; Owner: i2b2
--

ALTER TABLE ONLY i2b2imdata.im_project_patients
    ADD CONSTRAINT im_project_patients_pk PRIMARY KEY (project_id, global_id);


--
-- Name: im_project_sites im_project_sites_pk; Type: CONSTRAINT; Schema: i2b2imdata; Owner: i2b2
--

ALTER TABLE ONLY i2b2imdata.im_project_sites
    ADD CONSTRAINT im_project_sites_pk PRIMARY KEY (project_id, lcl_site);


--
-- Name: test basecode_un_10; Type: CONSTRAINT; Schema: i2b2metadata; Owner: i2b2
--

ALTER TABLE ONLY i2b2metadata.test
    ADD CONSTRAINT basecode_un_10 UNIQUE (c_basecode);


--
-- Name: test fullname_pk_10; Type: CONSTRAINT; Schema: i2b2metadata; Owner: i2b2
--

ALTER TABLE ONLY i2b2metadata.test
    ADD CONSTRAINT fullname_pk_10 PRIMARY KEY (c_fullname);


--
-- Name: ont_process_status ont_process_status_pkey; Type: CONSTRAINT; Schema: i2b2metadata; Owner: i2b2
--

ALTER TABLE ONLY i2b2metadata.ont_process_status
    ADD CONSTRAINT ont_process_status_pkey PRIMARY KEY (process_id);


--
-- Name: schemes schemes_pk; Type: CONSTRAINT; Schema: i2b2metadata; Owner: i2b2
--

ALTER TABLE ONLY i2b2metadata.schemes
    ADD CONSTRAINT schemes_pk PRIMARY KEY (c_key);


--
-- Name: pm_approvals_params pm_approvals_params_pkey; Type: CONSTRAINT; Schema: i2b2pm; Owner: i2b2
--

ALTER TABLE ONLY i2b2pm.pm_approvals_params
    ADD CONSTRAINT pm_approvals_params_pkey PRIMARY KEY (id);


--
-- Name: pm_cell_data pm_cell_data_pkey; Type: CONSTRAINT; Schema: i2b2pm; Owner: i2b2
--

ALTER TABLE ONLY i2b2pm.pm_cell_data
    ADD CONSTRAINT pm_cell_data_pkey PRIMARY KEY (cell_id, project_path);


--
-- Name: pm_cell_params pm_cell_params_pkey; Type: CONSTRAINT; Schema: i2b2pm; Owner: i2b2
--

ALTER TABLE ONLY i2b2pm.pm_cell_params
    ADD CONSTRAINT pm_cell_params_pkey PRIMARY KEY (id);


--
-- Name: pm_global_params pm_global_params_pkey; Type: CONSTRAINT; Schema: i2b2pm; Owner: i2b2
--

ALTER TABLE ONLY i2b2pm.pm_global_params
    ADD CONSTRAINT pm_global_params_pkey PRIMARY KEY (id);


--
-- Name: pm_hive_data pm_hive_data_pkey; Type: CONSTRAINT; Schema: i2b2pm; Owner: i2b2
--

ALTER TABLE ONLY i2b2pm.pm_hive_data
    ADD CONSTRAINT pm_hive_data_pkey PRIMARY KEY (domain_id);


--
-- Name: pm_hive_params pm_hive_params_pkey; Type: CONSTRAINT; Schema: i2b2pm; Owner: i2b2
--

ALTER TABLE ONLY i2b2pm.pm_hive_params
    ADD CONSTRAINT pm_hive_params_pkey PRIMARY KEY (id);


--
-- Name: pm_project_data pm_project_data_pkey; Type: CONSTRAINT; Schema: i2b2pm; Owner: i2b2
--

ALTER TABLE ONLY i2b2pm.pm_project_data
    ADD CONSTRAINT pm_project_data_pkey PRIMARY KEY (project_id);


--
-- Name: pm_project_params pm_project_params_pkey; Type: CONSTRAINT; Schema: i2b2pm; Owner: i2b2
--

ALTER TABLE ONLY i2b2pm.pm_project_params
    ADD CONSTRAINT pm_project_params_pkey PRIMARY KEY (id);


--
-- Name: pm_project_request pm_project_request_pkey; Type: CONSTRAINT; Schema: i2b2pm; Owner: i2b2
--

ALTER TABLE ONLY i2b2pm.pm_project_request
    ADD CONSTRAINT pm_project_request_pkey PRIMARY KEY (id);


--
-- Name: pm_project_user_params pm_project_user_params_pkey; Type: CONSTRAINT; Schema: i2b2pm; Owner: i2b2
--

ALTER TABLE ONLY i2b2pm.pm_project_user_params
    ADD CONSTRAINT pm_project_user_params_pkey PRIMARY KEY (id);


--
-- Name: pm_project_user_roles pm_project_user_roles_pkey; Type: CONSTRAINT; Schema: i2b2pm; Owner: i2b2
--

ALTER TABLE ONLY i2b2pm.pm_project_user_roles
    ADD CONSTRAINT pm_project_user_roles_pkey PRIMARY KEY (project_id, user_id, user_role_cd);


--
-- Name: pm_role_requirement pm_role_requirement_pkey; Type: CONSTRAINT; Schema: i2b2pm; Owner: i2b2
--

ALTER TABLE ONLY i2b2pm.pm_role_requirement
    ADD CONSTRAINT pm_role_requirement_pkey PRIMARY KEY (table_cd, column_cd, read_hivemgmt_cd, write_hivemgmt_cd);


--
-- Name: pm_user_data pm_user_data_pkey; Type: CONSTRAINT; Schema: i2b2pm; Owner: i2b2
--

ALTER TABLE ONLY i2b2pm.pm_user_data
    ADD CONSTRAINT pm_user_data_pkey PRIMARY KEY (user_id);


--
-- Name: pm_user_params pm_user_params_pkey; Type: CONSTRAINT; Schema: i2b2pm; Owner: i2b2
--

ALTER TABLE ONLY i2b2pm.pm_user_params
    ADD CONSTRAINT pm_user_params_pkey PRIMARY KEY (id);


--
-- Name: pm_user_session pm_user_session_pkey; Type: CONSTRAINT; Schema: i2b2pm; Owner: i2b2
--

ALTER TABLE ONLY i2b2pm.pm_user_session
    ADD CONSTRAINT pm_user_session_pkey PRIMARY KEY (session_id, user_id);


--
-- Name: workplace_access workplace_access_pk; Type: CONSTRAINT; Schema: i2b2workdata; Owner: i2b2
--

ALTER TABLE ONLY i2b2workdata.workplace_access
    ADD CONSTRAINT workplace_access_pk PRIMARY KEY (c_index);


--
-- Name: workplace workplace_pk; Type: CONSTRAINT; Schema: i2b2workdata; Owner: i2b2
--

ALTER TABLE ONLY i2b2workdata.workplace
    ADD CONSTRAINT workplace_pk PRIMARY KEY (c_index);


--
-- Name: cd_idx_uploadid; Type: INDEX; Schema: i2b2demodata; Owner: i2b2
--

CREATE INDEX cd_idx_uploadid ON i2b2demodata.concept_dimension USING btree (upload_id);


--
-- Name: cl_idx_name_char; Type: INDEX; Schema: i2b2demodata; Owner: i2b2
--

CREATE INDEX cl_idx_name_char ON i2b2demodata.code_lookup USING btree (name_char);


--
-- Name: cl_idx_uploadid; Type: INDEX; Schema: i2b2demodata; Owner: i2b2
--

CREATE INDEX cl_idx_uploadid ON i2b2demodata.code_lookup USING btree (upload_id);


--
-- Name: em_encnum_idx; Type: INDEX; Schema: i2b2demodata; Owner: i2b2
--

CREATE INDEX em_encnum_idx ON i2b2demodata.encounter_mapping USING btree (encounter_num);


--
-- Name: em_idx_encpath; Type: INDEX; Schema: i2b2demodata; Owner: i2b2
--

CREATE INDEX em_idx_encpath ON i2b2demodata.encounter_mapping USING btree (encounter_ide, encounter_ide_source, patient_ide, patient_ide_source, encounter_num);


--
-- Name: em_idx_uploadid; Type: INDEX; Schema: i2b2demodata; Owner: i2b2
--

CREATE INDEX em_idx_uploadid ON i2b2demodata.encounter_mapping USING btree (upload_id);


--
-- Name: md_idx_uploadid; Type: INDEX; Schema: i2b2demodata; Owner: i2b2
--

CREATE INDEX md_idx_uploadid ON i2b2demodata.modifier_dimension USING btree (upload_id);


--
-- Name: of_idx_allobservation_fact; Type: INDEX; Schema: i2b2demodata; Owner: i2b2
--

CREATE INDEX of_idx_allobservation_fact ON i2b2demodata.observation_fact USING btree (patient_num, encounter_num, concept_cd, start_date, provider_id, modifier_cd, instance_num, valtype_cd, tval_char, nval_num, valueflag_cd, quantity_num, units_cd, end_date, location_cd, confidence_num);


--
-- Name: of_idx_clusteredconcept; Type: INDEX; Schema: i2b2demodata; Owner: i2b2
--

CREATE INDEX of_idx_clusteredconcept ON i2b2demodata.observation_fact USING btree (concept_cd);


--
-- Name: of_idx_encounter_patient; Type: INDEX; Schema: i2b2demodata; Owner: i2b2
--

CREATE INDEX of_idx_encounter_patient ON i2b2demodata.observation_fact USING btree (encounter_num, patient_num, instance_num);


--
-- Name: of_idx_modifier; Type: INDEX; Schema: i2b2demodata; Owner: i2b2
--

CREATE INDEX of_idx_modifier ON i2b2demodata.observation_fact USING btree (modifier_cd);


--
-- Name: of_idx_sourcesystem_cd; Type: INDEX; Schema: i2b2demodata; Owner: i2b2
--

CREATE INDEX of_idx_sourcesystem_cd ON i2b2demodata.observation_fact USING btree (sourcesystem_cd);


--
-- Name: of_idx_start_date; Type: INDEX; Schema: i2b2demodata; Owner: i2b2
--

CREATE INDEX of_idx_start_date ON i2b2demodata.observation_fact USING btree (start_date, patient_num);


--
-- Name: of_idx_uploadid; Type: INDEX; Schema: i2b2demodata; Owner: i2b2
--

CREATE INDEX of_idx_uploadid ON i2b2demodata.observation_fact USING btree (upload_id);


--
-- Name: of_text_search_unique; Type: INDEX; Schema: i2b2demodata; Owner: i2b2
--

CREATE UNIQUE INDEX of_text_search_unique ON i2b2demodata.observation_fact USING btree (text_search_index);


--
-- Name: pa_idx_uploadid; Type: INDEX; Schema: i2b2demodata; Owner: i2b2
--

CREATE INDEX pa_idx_uploadid ON i2b2demodata.patient_dimension USING btree (upload_id);


--
-- Name: pd_idx_allpatientdim; Type: INDEX; Schema: i2b2demodata; Owner: i2b2
--

CREATE INDEX pd_idx_allpatientdim ON i2b2demodata.patient_dimension USING btree (patient_num, vital_status_cd, birth_date, death_date, sex_cd, age_in_years_num, language_cd, race_cd, marital_status_cd, income_cd, religion_cd, zip_cd);


--
-- Name: pd_idx_dates; Type: INDEX; Schema: i2b2demodata; Owner: i2b2
--

CREATE INDEX pd_idx_dates ON i2b2demodata.patient_dimension USING btree (patient_num, vital_status_cd, birth_date, death_date);


--
-- Name: pd_idx_name_char; Type: INDEX; Schema: i2b2demodata; Owner: i2b2
--

CREATE INDEX pd_idx_name_char ON i2b2demodata.provider_dimension USING btree (provider_id, name_char);


--
-- Name: pd_idx_statecityzip; Type: INDEX; Schema: i2b2demodata; Owner: i2b2
--

CREATE INDEX pd_idx_statecityzip ON i2b2demodata.patient_dimension USING btree (statecityzip_path, patient_num);


--
-- Name: pd_idx_uploadid; Type: INDEX; Schema: i2b2demodata; Owner: i2b2
--

CREATE INDEX pd_idx_uploadid ON i2b2demodata.provider_dimension USING btree (upload_id);


--
-- Name: pk_archive_obsfact; Type: INDEX; Schema: i2b2demodata; Owner: i2b2
--

CREATE INDEX pk_archive_obsfact ON i2b2demodata.archive_observation_fact USING btree (encounter_num, patient_num, concept_cd, provider_id, start_date, modifier_cd, archive_upload_id);


--
-- Name: pm_encpnum_idx; Type: INDEX; Schema: i2b2demodata; Owner: i2b2
--

CREATE INDEX pm_encpnum_idx ON i2b2demodata.patient_mapping USING btree (patient_ide, patient_ide_source, patient_num);


--
-- Name: pm_idx_uploadid; Type: INDEX; Schema: i2b2demodata; Owner: i2b2
--

CREATE INDEX pm_idx_uploadid ON i2b2demodata.patient_mapping USING btree (upload_id);


--
-- Name: pm_patnum_idx; Type: INDEX; Schema: i2b2demodata; Owner: i2b2
--

CREATE INDEX pm_patnum_idx ON i2b2demodata.patient_mapping USING btree (patient_num);


--
-- Name: qt_apnamevergrp_idx; Type: INDEX; Schema: i2b2demodata; Owner: i2b2
--

CREATE INDEX qt_apnamevergrp_idx ON i2b2demodata.qt_analysis_plugin USING btree (plugin_name, version_cd, group_id);


--
-- Name: qt_idx_pqm_ugid; Type: INDEX; Schema: i2b2demodata; Owner: i2b2
--

CREATE INDEX qt_idx_pqm_ugid ON i2b2demodata.qt_pdo_query_master USING btree (user_id, group_id);


--
-- Name: qt_idx_qi_mstartid; Type: INDEX; Schema: i2b2demodata; Owner: i2b2
--

CREATE INDEX qt_idx_qi_mstartid ON i2b2demodata.qt_query_instance USING btree (query_master_id, start_date);


--
-- Name: qt_idx_qi_ugid; Type: INDEX; Schema: i2b2demodata; Owner: i2b2
--

CREATE INDEX qt_idx_qi_ugid ON i2b2demodata.qt_query_instance USING btree (user_id, group_id);


--
-- Name: qt_idx_qm_ugid; Type: INDEX; Schema: i2b2demodata; Owner: i2b2
--

CREATE INDEX qt_idx_qm_ugid ON i2b2demodata.qt_query_master USING btree (user_id, group_id, master_type_cd);


--
-- Name: qt_idx_qpsc_riid; Type: INDEX; Schema: i2b2demodata; Owner: i2b2
--

CREATE INDEX qt_idx_qpsc_riid ON i2b2demodata.qt_patient_set_collection USING btree (result_instance_id);


--
-- Name: vd_idx_allvisitdim; Type: INDEX; Schema: i2b2demodata; Owner: i2b2
--

CREATE INDEX vd_idx_allvisitdim ON i2b2demodata.visit_dimension USING btree (encounter_num, patient_num, inout_cd, location_cd, start_date, length_of_stay, end_date);


--
-- Name: vd_idx_dates; Type: INDEX; Schema: i2b2demodata; Owner: i2b2
--

CREATE INDEX vd_idx_dates ON i2b2demodata.visit_dimension USING btree (encounter_num, start_date, end_date);


--
-- Name: vd_idx_uploadid; Type: INDEX; Schema: i2b2demodata; Owner: i2b2
--

CREATE INDEX vd_idx_uploadid ON i2b2demodata.visit_dimension USING btree (upload_id);


--
-- Name: crc_idx_aj_qnstid; Type: INDEX; Schema: i2b2hive; Owner: i2b2
--

CREATE INDEX crc_idx_aj_qnstid ON i2b2hive.crc_analysis_job USING btree (queue_name, status_type_id);


--
-- Name: meta_appl_path_icd10_icd9_idx; Type: INDEX; Schema: i2b2metadata; Owner: i2b2
--

CREATE INDEX meta_appl_path_icd10_icd9_idx ON i2b2metadata.icd10_icd9 USING btree (m_applied_path);


--
-- Name: meta_applied_path_idx; Type: INDEX; Schema: i2b2metadata; Owner: i2b2
--

CREATE INDEX meta_applied_path_idx ON i2b2metadata.sphn USING btree (m_applied_path);


--
-- Name: meta_applied_path_idx_birn; Type: INDEX; Schema: i2b2metadata; Owner: i2b2
--

CREATE INDEX meta_applied_path_idx_birn ON i2b2metadata.birn USING btree (m_applied_path);


--
-- Name: meta_applied_path_idx_custom; Type: INDEX; Schema: i2b2metadata; Owner: i2b2
--

CREATE INDEX meta_applied_path_idx_custom ON i2b2metadata.custom_meta USING btree (m_applied_path);


--
-- Name: meta_applied_path_idx_i2b2; Type: INDEX; Schema: i2b2metadata; Owner: i2b2
--

CREATE INDEX meta_applied_path_idx_i2b2 ON i2b2metadata.i2b2 USING btree (m_applied_path);


--
-- Name: meta_cname_idx; Type: INDEX; Schema: i2b2metadata; Owner: i2b2
--

CREATE INDEX meta_cname_idx ON i2b2metadata.sphn USING btree (c_name);


--
-- Name: meta_exclusion_icd10_icd9_idx; Type: INDEX; Schema: i2b2metadata; Owner: i2b2
--

CREATE INDEX meta_exclusion_icd10_icd9_idx ON i2b2metadata.icd10_icd9 USING btree (m_exclusion_cd);


--
-- Name: meta_exclusion_idx; Type: INDEX; Schema: i2b2metadata; Owner: i2b2
--

CREATE INDEX meta_exclusion_idx ON i2b2metadata.sphn USING btree (m_exclusion_cd);


--
-- Name: meta_exclusion_idx_i2b2; Type: INDEX; Schema: i2b2metadata; Owner: i2b2
--

CREATE INDEX meta_exclusion_idx_i2b2 ON i2b2metadata.i2b2 USING btree (m_exclusion_cd);


--
-- Name: meta_fullname_idx; Type: INDEX; Schema: i2b2metadata; Owner: i2b2
--

CREATE INDEX meta_fullname_idx ON i2b2metadata.sphn USING btree (c_fullname);


--
-- Name: meta_fullname_idx_birn; Type: INDEX; Schema: i2b2metadata; Owner: i2b2
--

CREATE INDEX meta_fullname_idx_birn ON i2b2metadata.birn USING btree (c_fullname);


--
-- Name: meta_fullname_idx_custom; Type: INDEX; Schema: i2b2metadata; Owner: i2b2
--

CREATE INDEX meta_fullname_idx_custom ON i2b2metadata.custom_meta USING btree (c_fullname);


--
-- Name: meta_fullname_idx_i2b2; Type: INDEX; Schema: i2b2metadata; Owner: i2b2
--

CREATE INDEX meta_fullname_idx_i2b2 ON i2b2metadata.i2b2 USING btree (c_fullname);


--
-- Name: meta_fullname_idx_icd10_icd9; Type: INDEX; Schema: i2b2metadata; Owner: i2b2
--

CREATE INDEX meta_fullname_idx_icd10_icd9 ON i2b2metadata.icd10_icd9 USING btree (c_fullname);


--
-- Name: meta_hlevel_icd10_icd9_idx; Type: INDEX; Schema: i2b2metadata; Owner: i2b2
--

CREATE INDEX meta_hlevel_icd10_icd9_idx ON i2b2metadata.icd10_icd9 USING btree (c_hlevel);


--
-- Name: meta_hlevel_idx; Type: INDEX; Schema: i2b2metadata; Owner: i2b2
--

CREATE INDEX meta_hlevel_idx ON i2b2metadata.sphn USING btree (c_hlevel);


--
-- Name: meta_hlevel_idx_i2b2; Type: INDEX; Schema: i2b2metadata; Owner: i2b2
--

CREATE INDEX meta_hlevel_idx_i2b2 ON i2b2metadata.i2b2 USING btree (c_hlevel);


--
-- Name: meta_synonym_icd10_icd9_idx; Type: INDEX; Schema: i2b2metadata; Owner: i2b2
--

CREATE INDEX meta_synonym_icd10_icd9_idx ON i2b2metadata.icd10_icd9 USING btree (c_synonym_cd);


--
-- Name: meta_synonym_idx; Type: INDEX; Schema: i2b2metadata; Owner: i2b2
--

CREATE INDEX meta_synonym_idx ON i2b2metadata.sphn USING btree (c_synonym_cd);


--
-- Name: meta_synonym_idx_i2b2; Type: INDEX; Schema: i2b2metadata; Owner: i2b2
--

CREATE INDEX meta_synonym_idx_i2b2 ON i2b2metadata.i2b2 USING btree (c_synonym_cd);


--
-- Name: totalnum_idx; Type: INDEX; Schema: i2b2metadata; Owner: i2b2
--

CREATE INDEX totalnum_idx ON i2b2metadata.totalnum USING btree (c_fullname, agg_date, typeflag_cd);


--
-- Name: totalnum_report_idx; Type: INDEX; Schema: i2b2metadata; Owner: i2b2
--

CREATE INDEX totalnum_report_idx ON i2b2metadata.totalnum_report USING btree (c_fullname);


--
-- Name: pm_user_login_idx; Type: INDEX; Schema: i2b2pm; Owner: i2b2
--

CREATE INDEX pm_user_login_idx ON i2b2pm.pm_user_login USING btree (user_id, entry_date);


--
-- Name: saved_cohort saved_cohort_fkey_explore_query; Type: FK CONSTRAINT; Schema: gecodatasourceplugintest; Owner: i2b2
--

ALTER TABLE ONLY gecodatasourceplugintest.saved_cohort
    ADD CONSTRAINT saved_cohort_fkey_explore_query FOREIGN KEY (explore_query_id) REFERENCES gecodatasourceplugintest.explore_query(id);


--
-- Name: set_upload_status fk_up_set_type_id; Type: FK CONSTRAINT; Schema: i2b2demodata; Owner: i2b2
--

ALTER TABLE ONLY i2b2demodata.set_upload_status
    ADD CONSTRAINT fk_up_set_type_id FOREIGN KEY (set_type_id) REFERENCES i2b2demodata.set_type(id);


--
-- Name: qt_patient_enc_collection qt_fk_pesc_ri; Type: FK CONSTRAINT; Schema: i2b2demodata; Owner: i2b2
--

ALTER TABLE ONLY i2b2demodata.qt_patient_enc_collection
    ADD CONSTRAINT qt_fk_pesc_ri FOREIGN KEY (result_instance_id) REFERENCES i2b2demodata.qt_query_result_instance(result_instance_id);


--
-- Name: qt_patient_set_collection qt_fk_psc_ri; Type: FK CONSTRAINT; Schema: i2b2demodata; Owner: i2b2
--

ALTER TABLE ONLY i2b2demodata.qt_patient_set_collection
    ADD CONSTRAINT qt_fk_psc_ri FOREIGN KEY (result_instance_id) REFERENCES i2b2demodata.qt_query_result_instance(result_instance_id);


--
-- Name: qt_query_instance qt_fk_qi_mid; Type: FK CONSTRAINT; Schema: i2b2demodata; Owner: i2b2
--

ALTER TABLE ONLY i2b2demodata.qt_query_instance
    ADD CONSTRAINT qt_fk_qi_mid FOREIGN KEY (query_master_id) REFERENCES i2b2demodata.qt_query_master(query_master_id);


--
-- Name: qt_query_instance qt_fk_qi_stid; Type: FK CONSTRAINT; Schema: i2b2demodata; Owner: i2b2
--

ALTER TABLE ONLY i2b2demodata.qt_query_instance
    ADD CONSTRAINT qt_fk_qi_stid FOREIGN KEY (status_type_id) REFERENCES i2b2demodata.qt_query_status_type(status_type_id);


--
-- Name: qt_query_result_instance qt_fk_qri_rid; Type: FK CONSTRAINT; Schema: i2b2demodata; Owner: i2b2
--

ALTER TABLE ONLY i2b2demodata.qt_query_result_instance
    ADD CONSTRAINT qt_fk_qri_rid FOREIGN KEY (query_instance_id) REFERENCES i2b2demodata.qt_query_instance(query_instance_id);


--
-- Name: qt_query_result_instance qt_fk_qri_rtid; Type: FK CONSTRAINT; Schema: i2b2demodata; Owner: i2b2
--

ALTER TABLE ONLY i2b2demodata.qt_query_result_instance
    ADD CONSTRAINT qt_fk_qri_rtid FOREIGN KEY (result_type_id) REFERENCES i2b2demodata.qt_query_result_type(result_type_id);


--
-- Name: qt_query_result_instance qt_fk_qri_stid; Type: FK CONSTRAINT; Schema: i2b2demodata; Owner: i2b2
--

ALTER TABLE ONLY i2b2demodata.qt_query_result_instance
    ADD CONSTRAINT qt_fk_qri_stid FOREIGN KEY (status_type_id) REFERENCES i2b2demodata.qt_query_status_type(status_type_id);


--
-- Name: qt_xml_result qt_fk_xmlr_riid; Type: FK CONSTRAINT; Schema: i2b2demodata; Owner: i2b2
--

ALTER TABLE ONLY i2b2demodata.qt_xml_result
    ADD CONSTRAINT qt_fk_xmlr_riid FOREIGN KEY (result_instance_id) REFERENCES i2b2demodata.qt_query_result_instance(result_instance_id);


--
-- PostgreSQL database dump complete
--

