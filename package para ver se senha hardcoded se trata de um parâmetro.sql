create or replace package body PCK_UTILS
AS

    /*
    Espaço reservado para descrição da função

    */
    FUNCTION F_SE_PARAMETRO_SRC (P_WORKSPACE VARCHAR2,
                                 P_NAME VARCHAR2,
                                 P_TYPE VARCHAR2,
                                 P_TEXT VARCHAR2,
                                 P_LINE NUMBER DEFAULT NULL) RETURN CHAR
    IS
        V_LINHA_INICIO         NUMBER;
        V_LINHA_FIM            NUMBER;
        
    BEGIN 
        IF P_TYPE = 'PACKAGE BODY' THEN
            SELECT MAX(LINE) INTO V_LINHA_INICIO 
                FROM VW_APEX_DBA_SOURCE 
                WHERE OWNER = P_WORKSPACE AND NAME = P_NAME AND TYPE = P_TYPE
                AND (LOWER(TEXT) LIKE '%function%' OR LOWER(TEXT) LIKE '%procedure%') 
                AND LINE <= P_LINE;
             SELECT MIN(LINE) INTO V_LINHA_FIM
                FROM VW_APEX_DBA_SOURCE
                WHERE OWNER = P_WORKSPACE AND NAME = P_NAME AND TYPE = P_TYPE
                AND (REGEXP_LIKE(lower(TEXT), '^\s{0,}end(\s{1,}\w)', 'in')
                OR REGEXP_LIKE(LOWER(TEXT), '^\s{0,}end;', 'i'))
                AND NOT REGEXP_LIKE(lower(TEXT), '^\s{0,}end\s{1,}(if|case|loop)', 'i')
                AND LINE >= P_LINE;
            RETURN F_CHECA_PARAMETRO_SRC (p_workspace => p_workspace, 
                                          p_name => p_name, 
                                          p_type => p_type, 
                                          p_text => p_text, 
                                          p_line => p_line,
                                          p_linha_inicio => v_linha_inicio,
                                          p_linha_fim => v_linha_fim);
        ELSE
            RETURN F_CHECA_PARAMETRO_SRC (p_workspace => p_workspace, 
                                          p_name => p_name, 
                                          p_type => p_type, 
                                          p_text => p_text, 
                                          p_line => p_line);
        END IF;
    END;

    /*
    Espaço reservado para descrição da função

    */
    FUNCTION F_CHECA_PARAMETRO_SRC(P_WORKSPACE VARCHAR2,
                                   P_NAME VARCHAR2,
                                   P_TYPE VARCHAR2,
                                   P_TEXT VARCHAR2,
                                   P_LINE NUMBER DEFAULT NULL,
                                   P_LINHA_INICIO NUMBER DEFAULT NULL,
                                   P_LINHA_FIM NUMBER DEFAULT NULL) RETURN CHAR
   IS
    V_TEXT_NO_SPACES VARCHAR2(4000) := LOWER(REPLACE(P_TEXT,' ',''));
    V_INICIO_PASSWORD NUMBER := INSTR(V_TEXT_NO_SPACES,'"password":"');
    V_INICIO_SENHA NUMBER := INSTR(V_TEXT_NO_SPACES,'"senha":"');
    V_INICIO_AUX_1 NUMBER := CASE WHEN V_INICIO_PASSWORD > V_INICIO_SENHA THEN V_INICIO_PASSWORD + 12 ELSE V_INICIO_SENHA + 9 END;
    V_AUX_TEXT_1 VARCHAR2(4000) := SUBSTR(V_TEXT_NO_SPACES,V_INICIO_AUX_1);
    V_INICIO_AUX_2 NUMBER := INSTR(V_AUX_TEXT_1,'||') + 2;
    V_INICIO NUMBER := V_INICIO_AUX_1 + V_INICIO_AUX_2;
    V_AUX_TEXT_2 VARCHAR2(4000)  := SUBSTR(V_AUX_TEXT_1,V_INICIO_AUX_2);
    V_FIM NUMBER := INSTR(V_AUX_TEXT_2,'||') - 1;
    V_PARAM VARCHAR2(4000)  := LOWER(SUBSTR(V_AUX_TEXT_2,1,V_FIM));
    V_RESP CHAR := 'N';
    BEGIN
        IF V_FIM = -1 THEN RETURN V_RESP; END IF;
        
        IF P_LINHA_INICIO IS NULL AND P_LINHA_FIM IS NULL THEN 
            SELECT 'S' INTO V_RESP FROM VW_APEX_DBA_SOURCE SOURCE
            WHERE LOWER(TEXT) LIKE 	'%'||V_PARAM||'%'
            AND OWNER = P_WORKSPACE 
            AND NAME = P_NAME
            AND SOURCE.TYPE = P_TYPE
            --AND SOURCE.TYPE <> 'PACKAGE BODY'
            AND LINE <= (SELECT MIN(LINE) FROM VW_APEX_DBA_SOURCE SOURCE2
                         WHERE (LOWER(TEXT) LIKE '% is %' OR LOWER(TEXT) LIKE '% is_' OR LOWER(TEXT) LIKE 'is %' OR LOWER(TEXT) LIKE 'is_' OR REGEXP_LIKE(lower(TEXT), '^is', 'i')
                               OR LOWER(TEXT) LIKE '% as %' OR LOWER(TEXT) LIKE '% as_' OR LOWER(TEXT) LIKE 'as %' OR LOWER(TEXT) LIKE 'as_' OR REGEXP_LIKE(lower(TEXT), '^as', 'i'))
                         AND OWNER = P_WORKSPACE 
                         AND NAME = P_NAME
                         AND SOURCE2.TYPE = P_TYPE);
        ELSE
            SELECT 'S' INTO V_RESP FROM VW_APEX_DBA_SOURCE SOURCE
            WHERE LOWER(TEXT) LIKE 	'%'||V_PARAM||'%'
            AND OWNER = P_WORKSPACE 
            AND NAME = P_NAME
            AND SOURCE.TYPE = P_TYPE
            AND LINE <= (SELECT MIN(LINE) FROM VW_APEX_DBA_SOURCE SOURCE2
                         WHERE (LOWER(TEXT) LIKE '% is %' OR LOWER(TEXT) LIKE '% is_' OR LOWER(TEXT) LIKE 'is %' OR LOWER(TEXT) LIKE 'is_' OR REGEXP_LIKE(lower(TEXT), '^is', 'i')
                               OR LOWER(TEXT) LIKE '% as %' OR LOWER(TEXT) LIKE '% as_' OR LOWER(TEXT) LIKE 'as %' OR LOWER(TEXT) LIKE 'as_' OR REGEXP_LIKE(lower(TEXT), '^as', 'i'))
                         AND OWNER = P_WORKSPACE 
                         AND NAME = P_NAME
                         AND SOURCE2.TYPE = P_TYPE
                         AND SOURCE2.LINE BETWEEN P_LINHA_INICIO AND P_LINHA_FIM)
            AND LINE >= P_LINHA_INICIO;
        END IF;
        RETURN V_RESP;

        EXCEPTION 
            WHEN NO_DATA_FOUND THEN 
                V_RESP := 'N';
                
                /*HTP.P('WORKSPACE: ' || P_WORKSPACE);
                HTP.P('NOME: ' || P_NAME);
                HTP.P('TIPO: ' || P_TYPE);
                HTP.P('TEXTO: ' || P_TEXT);
                --HTP.P('AUX1: ' || V_AUX_TEXT_1);
                --HTP.P('AUX2: ' || V_AUX_TEXT_2);
                HTP.P(' LINHA INICIO: ' || P_LINHA_INICIO);
                HTP.P('LINHA FIM: ' || P_LINHA_FIM);
                HTP.P('PARAM: ' || V_PARAM);
                HTP.P('-------------------------------------------------------------');*/
                
                RETURN V_RESP;
            WHEN OTHERS THEN 
                RETURN V_RESP;
            
    END F_CHECA_PARAMETRO_SRC;
    /*
    Espaço reservado para descrição da função

    */
    FUNCTION F_SE_PARAMETRO_PROC(P_WORKSPACE VARCHAR2,
                                 P_APP_ID NUMBER,
                                 P_PROCESS_NAME VARCHAR2,
                                 P_PAGE NUMBER) RETURN CHAR
    IS
    V_TEXT_NO_SPACES CLOB;
    V_INICIO_PASSWORD NUMBER;
    V_INICIO_SENHA NUMBER;
    V_INICIO_AUX_1 NUMBER;
    V_AUX_TEXT_1 CLOB;
    V_FIM_PASSWORD NUMBER;
    V_INICIO_AUX_2 NUMBER;
    V_INICIO NUMBER;
    V_AUX_TEXT_2 CLOB;
    V_FIM NUMBER;
    V_PARAM VARCHAR2(4000);
    V_RESP CHAR := 'N';
    V_TEXT CLOB;
    v_chunk varchar2(4000);
    V_POS pls_integer := 1;
    c_chunk_size    constant pls_integer := 4000;
    BEGIN
    dbms_lob.createtemporary(V_TEXT, true, dbms_lob.call);
    
    LOOP
        BEGIN
            SELECT dbms_lob.substr(PROCESS_SOURCE,c_chunk_size,V_POS) INTO V_CHUNK FROM apex_application_page_proc WHERE WORKSPACE = P_WORKSPACE AND APPLICATION_ID = P_APP_ID AND PAGE_ID = P_PAGE AND PROCESS_NAME = P_PROCESS_NAME;

            dbms_lob.append(V_TEXT, V_CHUNK); 
            exception when others then
                if sqlcode = -6502 then exit; else raise; end if;
        end;
        if length(V_CHUNK) < c_chunk_size then exit; end if;
            v_pos := v_pos + c_chunk_size;
    END LOOP;
    
    -- ISOLANDO O PARAMETRO
    V_TEXT_NO_SPACES := LOWER(REPLACE(V_TEXT,' ',''));
    V_INICIO_PASSWORD := INSTR(V_TEXT_NO_SPACES,'"password":"');
    V_INICIO_SENHA := INSTR(V_TEXT_NO_SPACES,'"senha":"');
    V_INICIO_AUX_1 := CASE WHEN V_INICIO_PASSWORD > V_INICIO_SENHA THEN V_INICIO_PASSWORD + 12 ELSE V_INICIO_SENHA + 9 END;
    V_AUX_TEXT_1 := SUBSTR(V_TEXT_NO_SPACES,V_INICIO_AUX_1);
    --HTP.P(V_AUX_TEXT_1);
    V_FIM_PASSWORD := INSTR(V_AUX_TEXT_1,'"');
    V_INICIO_AUX_2 := INSTR(V_AUX_TEXT_1,'||') + 2;
    V_INICIO := V_INICIO_AUX_1 + V_INICIO_AUX_2;
    V_AUX_TEXT_2 := SUBSTR(V_AUX_TEXT_1,V_INICIO_AUX_2);
    V_FIM := INSTR(V_AUX_TEXT_2,'||') - 2;
    V_PARAM := UPPER(SUBSTR(V_AUX_TEXT_2,INSTR(V_AUX_TEXT_2,':')+1,V_FIM));
    
    IF V_FIM_PASSWORD = 1 OR V_FIM = -1 OR V_FIM > V_FIM_PASSWORD THEN RETURN V_RESP; END IF;
    
    SELECT 'S' INTO V_RESP FROM DUAL 
    WHERE NOT EXISTS(SELECT 1 FROM APEX_APPLICATION_PAGE_ITEMS 
                     WHERE APPLICATION_ID = P_APP_ID
                     AND ITEM_NAME LIKE '%'||V_PARAM||'%'
                     AND (ITEM_DEFAULT IS NOT NULL 
                     OR ITEM_SOURCE IS NOT NULL))
     AND NOT EXISTS(SELECT 1 FROM APEX_APPLICATION_COMPUTATIONS 
                     WHERE APPLICATION_ID = P_APP_ID
                     AND UPPER(COMPUTATION) LIKE '%'||V_PARAM||'%')
     AND NOT EXISTS(SELECT 1 FROM APEX_APPLICATION_PAGE_DA_ACTS 
                    WHERE WORKSPACE = P_WORKSPACE
                    AND APPLICATION_ID = P_APP_ID
                    AND (REGEXP_LIKE(UPPER(ATTRIBUTE_01), V_PARAM||'\s{0,}:=','i')
                         OR REGEXP_LIKE(UPPER(ATTRIBUTE_02), V_PARAM||'\s{0,}:=','i')
                         OR REGEXP_LIKE(UPPER(ATTRIBUTE_03), V_PARAM||'\s{0,}:=','i'))
     AND NOT EXISTS(SELECT 1 FROM APEX_APPLICATION_PAGE_PROC
                    WHERE WORKSPACE = P_WORKSPACE
                    AND APPLICATION_ID = P_APP_ID
                    AND PROCESS_NAME <> P_PROCESS_NAME
                    AND REGEXP_LIKE(UPPER(PROCESS_SOURCE), V_PARAM||'\s{0,}:=','i')));
        RETURN V_RESP;
    EXCEPTION 
            WHEN NO_DATA_FOUND THEN 
                V_RESP := 'N';  
                    RETURN V_RESP;
            WHEN OTHERS THEN 
                RETURN V_RESP;
    END F_SE_PARAMETRO_PROC;
END PCK_UTILS;
