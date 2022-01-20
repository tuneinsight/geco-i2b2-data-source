#!/bin/bash
set -Eeuo pipefail
# set up data in the database for end-to-end tests

### description of the test data
# 4 patients: 1, 2, 3, 4
# 3 concepts: 1, 2, 3
# observation_fact: p1: c1; p2: c1, c2; p3: c2, c3; p4: c1, c2, c3
# the same data is replicated on all nodes

psql $PSQL_PARAMS -d "$I2B2_DB_NAME" <<-EOSQL

    -- i2b2metadata.schemes
    insert into i2b2metadata.schemes(c_key, c_name, c_description) values('TEST:', 'Test', 'Test scheme.');

    -- i2b2metadata.table_access
    insert into i2b2metadata.table_access (c_table_cd, c_table_name, c_protected_access, c_hlevel, c_fullname, c_name,
        c_synonym_cd, c_visualattributes, c_facttablecolumn, c_dimtablename,
        c_columnname, c_columndatatype, c_operator, c_dimcode, c_tooltip) VALUES
        ('TEST', 'TEST', 'N', '0', '\test\', 'Test Ontology',
        'N', 'CA', 'concept_cd', 'concept_dimension', 'concept_path', 'T', 'LIKE', '\test\', 'Test');

    -- i2b2metadata.test
    CREATE TABLE i2b2metadata.test(
        c_hlevel numeric(22,0) not null,
        c_fullname character varying(900) not null,
        c_name character varying(2000) not null,
        c_synonym_cd character(1) not null,
        c_visualattributes character(3) not null,
        c_totalnum numeric(22,0),
        c_basecode character varying(450),
        c_metadataxml text,
        c_facttablecolumn character varying(50) not null,
        c_tablename character varying(50) not null,
        c_columnname character varying(50) not null,
        c_columndatatype character varying(50) not null,
        c_operator character varying(10) not null,
        c_dimcode character varying(900) not null,
        c_comment text,
        c_tooltip character varying(900),
        update_date date not null,
        download_date date,
        import_date date,
        sourcesystem_cd character varying(50),
        valuetype_cd character varying(50),
        m_applied_path character varying(900) not null,
        m_exclusion_cd character varying(900),
        c_path character varying(700),
        c_symbol character varying(50),
        pcori_basecode character varying(50)
    );
    ALTER TABLE ONLY i2b2metadata.test ADD CONSTRAINT fullname_pk_10 PRIMARY KEY (c_fullname);
    ALTER TABLE ONLY i2b2metadata.test ADD CONSTRAINT basecode_un_10 UNIQUE (c_basecode);
    ALTER TABLE i2b2metadata.test OWNER TO $I2B2_DB_USER;

    insert into i2b2metadata.test
        (c_hlevel, c_fullname, c_name, c_synonym_cd, c_visualattributes, c_totalnum,
        c_facttablecolumn, c_tablename, c_columnname, c_columndatatype, c_operator,
        c_dimcode, c_comment, c_tooltip, update_date, download_date, import_date,
        valuetype_cd, m_applied_path, c_basecode, c_metadataxml) values
            (
                '0', '\test\', 'Test', 'N', 'CA', '0',
                'concept_cd', 'concept_dimension', 'concept_path',
                'T', 'LIKE', '\test\', 'Test', '\test\',
                'NOW()', 'NOW()', 'NOW()', 'TEST', '@', '', NULL
            ), (
                '1', '\test\1\', 'Concept 1', 'N', 'LA', '0',
                'concept_cd', 'concept_dimension', 'concept_path',
                'T', 'LIKE', '\test\1\', 'Concept 1', '\test\1\',
                'NOW()', 'NOW()', 'NOW()', 'TEST', '@', 'TEST:1', '<?xml version="1.0"?><ValueMetadata></ValueMetadata>'
            ), (
                '1', '\test\2\', 'Concept 2', 'N', 'LA', '0',
                'concept_cd', 'concept_dimension', 'concept_path',
                'T', 'LIKE', '\test\2\', 'Concept 2', '\test\2\',
                'NOW()', 'NOW()', 'NOW()', 'TEST', '@', 'TEST:2', NULL
            ), (
                '1', '\test\3\', 'Concept 3', 'N', 'LA', '0',
                'concept_cd', 'concept_dimension', 'concept_path',
                'T', 'LIKE', '\test\3\', 'Concept 3', '\test\3\',
                'NOW()', 'NOW()', 'NOW()', 'TEST', '@', 'TEST:3', NULL
            ), (
                '0', '\modifiers\', 'Modifiers test', 'N', 'DA', '0',
                'modifier_cd', 'modifier_dimension', 'modifier_path',
                'T', 'LIKE', '\modifiers\', 'Modifiers Test', '\modifiers\',
                'NOW()', 'NOW()', 'NOW()', 'TEST', '\test\%', 'TEST:4', NULL
            ), (
                '1', '\modifiers\1\', 'Modifier 1', 'N', 'RA', '0',
                'modifier_cd', 'modifier_dimension', 'modifier_path',
                'T', 'LIKE', '\modifiers\1\', 'Modifier 1', '\modifiers\1\',
                'NOW()', 'NOW()', 'NOW()', 'TEST', '\test\1\', 'TEST:5', '<?xml version="1.0"?><ValueMetadata></ValueMetadata>'
            ), (
                '1', '\modifiers\2\', 'Modifier 2', 'N', 'RA', '0',
                'modifier_cd', 'modifier_dimension', 'modifier_path',
                'T', 'LIKE', '\modifiers\2\', 'Modifier 2', '\modifiers\2\',
                'NOW()', 'NOW()', 'NOW()', 'TEST', '\test\2\', 'TEST:6', NULL
            ), (
                '1', '\modifiers\3\', 'Modifier 3', 'N', 'RA', '0',
                'modifier_cd', 'modifier_dimension', 'modifier_path',
                'T', 'LIKE', '\modifiers\3\', 'Modifier 3', '\modifiers\3\',
                'NOW()', 'NOW()', 'NOW()', 'TEST', '\test\3\', 'TEST:7', NULL
            ), (
                '1', '\modifiers\2text\', 'Modifier 2 text', 'N', 'RA', '0',
                'modifier_cd', 'modifier_dimension', 'modifier_path',
                'T', 'LIKE', '\modifiers\2text\', 'Modifier 2 text', '\modifiers\2text\',
                'NOW()', 'NOW()', 'NOW()', 'T', '\test\2\', 'TEST:8', NULL
            ), (
                '1', '\modifiers\3text\', 'Modifier 3 text', 'N', 'RA', '0',
                'modifier_cd', 'modifier_dimension', 'modifier_path',
                'T', 'LIKE', '\modifiers\3text\', 'Modifier 3 text', '\modifiers\3text\',
                'NOW()', 'NOW()', 'NOW()', 'T', '\test\3\', 'TEST:9', NULL
            );

    -- i2b2demodata.concept_dimension
    insert into i2b2demodata.concept_dimension
        (concept_path, concept_cd, import_date, upload_id) values
            ('\test\', '', 'NOW()', '1'),
            ('\test\1\', 'TEST:1', 'NOW()', '1'),
            ('\test\2\', 'TEST:2', 'NOW()', '1'),
            ('\test\3\', 'TEST:3', 'NOW()', '1');

    -- i2b2demodata.modifier_dimension
    insert into i2b2demodata.modifier_dimension
        (modifier_path, modifier_cd, import_date, upload_id) values
            ('\modifiers\', 'TEST:4', 'NOW()', '1'),
            ('\modifiers\1\', 'TEST:5', 'NOW()', '1'),
            ('\modifiers\2\', 'TEST:6', 'NOW()', '1'),
            ('\modifiers\3\', 'TEST:7', 'NOW()', '1'),
            ('\modifiers\2text\', 'TEST:8', 'NOW()', '1'),
            ('\modifiers\3text\', 'TEST:9', 'NOW()', '1');

    -- i2b2demodata.provider_dimension
    insert into i2b2demodata.provider_dimension
        (provider_id, provider_path, name_char, import_date, upload_id) values
            ('test', '\test\', 'test', 'NOW()', '1');

    -- i2b2demodata.patient_dimension
    insert into i2b2demodata.patient_dimension
        (patient_num, import_date, upload_id) values
            ('1', 'NOW()', '1'),
            ('2', 'NOW()', '1'),
            ('3', 'NOW()', '1'),
            ('4', 'NOW()', '1');

    -- i2b2demodata.patient_mapping
    insert into i2b2demodata.patient_mapping
        (patient_ide, patient_ide_source, patient_num, project_id, import_date, upload_id) values
            ('test1', 'test', '1', 'Demo', 'NOW()', '1'),
            ('test2', 'test', '2', 'Demo', 'NOW()', '1'),
            ('test3', 'test', '3', 'Demo', 'NOW()', '1'),
            ('test4', 'test', '4', 'Demo', 'NOW()', '1');

    -- i2b2demodata.visit_dimension
    insert into i2b2demodata.visit_dimension
        (encounter_num, patient_num, import_date, upload_id) values
            ('1', '1', 'NOW()', '1'),
            ('2', '2', 'NOW()', '1'),
            ('3', '3', 'NOW()', '1'),
            ('4', '4', 'NOW()', '1');

    -- i2b2demodata.encounter_mapping
    insert into i2b2demodata.encounter_mapping
        (encounter_ide, encounter_ide_source, project_id, encounter_num, patient_ide, patient_ide_source, import_date, upload_id) values
            ('test1', 'test', 'Demo', '1', 'test1', 'test', 'NOW()', '1'),
            ('test2', 'test', 'Demo', '2', 'test2', 'test', 'NOW()', '1'),
            ('test3', 'test', 'Demo', '3', 'test3', 'test', 'NOW()', '1'),
            ('test4', 'test', 'Demo', '4', 'test4', 'test', 'NOW()', '1');

    -- i2b2demodata.observation_fact
    insert into i2b2demodata.observation_fact
        (encounter_num, patient_num, concept_cd, provider_id, start_date, modifier_cd, instance_num, import_date, upload_id, valtype_cd, tval_char, nval_num) values
            ('1', '1', 'TEST:1', 'test', 'NOW()', '@', '1', 'NOW()', '1', 'N', 'E', '10'),
            ('1', '1', 'TEST:1', 'test', 'NOW()', 'TEST:5', '1', 'NOW()', '1', 'N', 'E', '10'),
            ('1', '1', 'TEST:2', 'test', 'NOW()', 'TEST:8', '1', 'NOW()', '1', 'T', 'bcde', NULL),
            ('1', '1', 'TEST:3', 'test', 'NOW()', 'TEST:9', '1', 'NOW()', '1', 'T', 'ab', NULL),

            ('2', '2', 'TEST:1', 'test', 'NOW()', '@', '1', 'NOW()', '1', 'N', 'E', '20'),
            ('2', '2', 'TEST:1', 'test', 'NOW()', 'TEST:4', '1', 'NOW()', '1', 'N', 'E', '20'),
            ('2', '2', 'TEST:2', 'test', 'NOW()', '@', '1', 'NOW()', '1', 'N', 'E', '50'),
            ('2', '2', 'TEST:2', 'test', 'NOW()', 'TEST:6', '1', 'NOW()', '1', 'N', 'E', '5'),
            ('2', '2', 'TEST:2', 'test', 'NOW()', 'TEST:8', '1', 'NOW()', '1', 'T', 'abc', NULL),
            ('2', '2', 'TEST:3', 'test', 'NOW()', 'TEST:9', '1', 'NOW()', '1', 'T', 'def', NULL),

            ('3', '3', 'TEST:1', 'test', 'NOW()', '@', '1', 'NOW()', '1', 'N', 'E', '30'),
            ('3', '3', 'TEST:1', 'test', 'NOW()', 'TEST:4', '1', 'NOW()', '1', 'N', 'E', '15'),
            ('3', '3', 'TEST:1', 'test', 'NOW()', 'TEST:5', '1', 'NOW()', '1', 'N', 'E', '15'),
            ('3', '3', 'TEST:2', 'test', 'NOW()', '@', '1', 'NOW()', '1', 'N', 'E', '25'),
            ('3', '3', 'TEST:2', 'test', 'NOW()', 'TEST:4', '1', 'NOW()', '1', 'N', 'E', '30'),
            ('3', '3', 'TEST:2', 'test', 'NOW()', 'TEST:6', '1', 'NOW()', '1', 'N', 'E', '15'),
            ('3', '3', 'TEST:2', 'test', 'NOW()', 'TEST:8', '1', 'NOW()', '1', 'T', 'de', NULL),
            ('3', '3', 'TEST:3', 'test', 'NOW()', '@', '1', 'NOW()', '1', 'N', 'E', '77'),
            ('3', '3', 'TEST:3', 'test', 'NOW()', 'TEST:4', '1', 'NOW()', '1', 'N', 'E', '66'),
            ('3', '3', 'TEST:3', 'test', 'NOW()', 'TEST:7', '1', 'NOW()', '1', 'N', 'E', '88'),
            ('3', '3', 'TEST:3', 'test', 'NOW()', 'TEST:9', '1', 'NOW()', '1', 'T', 'abcdef', NULL),

            ('4', '4', 'TEST:3', 'test', 'NOW()', '@', '1', 'NOW()', '1', 'N', 'E', '20'),
            ('4', '4', 'TEST:3', 'test', 'NOW()', 'TEST:7', '1', 'NOW()', '1', 'N', 'E', '10');
EOSQL
