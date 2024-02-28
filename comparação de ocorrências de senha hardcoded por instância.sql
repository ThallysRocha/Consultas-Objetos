WITH CASOS_PROD AS (
    SELECT cod_aplicacao,
           workspace,
           nome_apelido,
           descr_par_1,
           descr_par_2,
           descr_par_3,
           descr_par_4,
           tipo,
           LISTAGG(NVL(EMAIL, LOWER(user_name) || '@tcu.gov.br'), ' , ') WITHIN GROUP (ORDER BY workspace) AS LISTA_DEST
    FROM (
        SELECT senhas.*, user_name, email
        FROM (
            SELECT NULL AS cod_aplicacao,
                   OWNER AS workspace,
                   NULL AS nome_apelido,
                   NAME AS descr_par_1,
                   LINE AS descr_par_2,
                   TEXT AS descr_par_3,
                   TYPE AS descr_par_4,
                   'SOURCE' AS TIPO
            FROM vw_apex_dba_source
            WHERE (UPPER(TEXT) LIKE '%"PASSWORD"%' OR LOWER(TEXT) LIKE '%"senha"%')
              AND OWNER NOT IN (SELECT * FROM vw_apex_wkp_descontinuado)
              AND UPPER(TEXT) NOT LIKE '%--%'
              AND (SELECT PCK_UTILS.f_se_parametro_src(OWNER, NAME, TYPE, TEXT) FROM dual) = 'N'
            UNION ALL
            SELECT proc.APPLICATION_ID AS cod_aplicacao,
                   proc.WORKSPACE AS workspace,
                   app.ALIAS AS nome_apelido,
                   proc.APPLICATION_NAME AS descr_par_1,
                   PAGE_ID AS descr_par_2,
                   PROCESS_NAME AS descr_par_3,
                   NULL AS descr_par_4,
                   'PROCESS' AS TIPO
            FROM apex_application_page_proc proc
            JOIN apex_applications app ON proc.application_id = app.application_id
            WHERE (UPPER(PROCESS_SOURCE) LIKE '%"PASSWORD"%' OR LOWER(PROCESS_SOURCE) LIKE '%"senha%')
              AND LOWER(PROCESS_SOURCE) LIKE '%apex_web_service.make_rest_request%'
              AND LOWER(AVAILABILITY_STATUS) NOT LIKE ('%unavailable%')
              AND (SELECT PCK_UTILS.F_SE_PARAMETRO_PROC(proc.WORKSPACE, proc.APPLICATION_ID, proc.PROCESS_NAME, proc.PAGE_ID, proc.PROCESS_SOURCE) FROM dual) = 'N'
        ) senhas
        JOIN apex_workspace_apex_users users ON senhas.workspace = users.workspace_name
        WHERE ACCOUNT_LOCKED = 'No'
        AND workspace NOT IN ('APEX_SEPROC_MONITORAMENTO', 'APEX_STI_API', 'APEX_STI_MONITOR')
        GROUP BY cod_aplicacao, workspace, nome_apelido, descr_par_1, descr_par_2, descr_par_3, descr_par_4, tipo
        ORDER BY tipo, workspace, COD_APLICACAO, descr_par_1, descr_par_2
    )
    GROUP BY cod_aplicacao, workspace, nome_apelido, descr_par_1, descr_par_2, descr_par_3, descr_par_4, tipo
    ORDER BY tipo, workspace, COD_APLICACAO, descr_par_1, descr_par_2
),

CASOS_DESENVOL AS (
    SELECT cod_aplicacao,
           workspace,
           nome_apelido,
           descr_par_1,
           descr_par_2,
           descr_par_3,
           descr_par_4,
           tipo,
           LISTAGG(NVL(EMAIL, LOWER(user_name) || '@tcu.gov.br'), ' , ') WITHIN GROUP (ORDER BY workspace) AS LISTA_DEST
    FROM (
        SELECT senhas.*, user_name, email
        FROM (
            SELECT NULL AS cod_aplicacao,
                   OWNER AS workspace,
                   NULL AS nome_apelido,
                   NAME AS descr_par_1,
                   LINE AS descr_par_2,
                   TEXT AS descr_par_3,
                   TYPE AS descr_par_4,
                   'SOURCE' AS TIPO
            FROM vw_apex_dba_source@DBL_DESENVOL
            WHERE (UPPER(TEXT) LIKE '%"PASSWORD"%' OR LOWER(TEXT) LIKE '%"senha"%')
              AND OWNER NOT IN (SELECT * FROM vw_apex_wkp_descontinuado@DBL_DESENVOL)
              AND UPPER(TEXT) NOT LIKE '%--%'
              AND (SELECT PCK_UTILS.f_se_parametro_src@DBL_DESENVOL(OWNER, NAME, TYPE, TEXT) FROM dual) = 'N'
            UNION ALL
            SELECT proc.APPLICATION_ID AS cod_aplicacao,
                   proc.WORKSPACE AS workspace,
                   app.ALIAS AS nome_apelido,
                   proc.APPLICATION_NAME AS descr_par_1,
                   PAGE_ID AS descr_par_2,
                   PROCESS_NAME AS descr_par_3,
                   NULL AS descr_par_4,
                   'PROCESS' AS TIPO
            FROM apex_application_page_proc@DBL_DESENVOL proc
            JOIN apex_applications@DBL_DESENVOL app ON proc.application_id = app.application_id
            WHERE (UPPER(PROCESS_SOURCE) LIKE '%"PASSWORD"%' OR LOWER(PROCESS_SOURCE) LIKE '%"senha%')
              AND LOWER(PROCESS_SOURCE) LIKE '%apex_web_service.make_rest_request%'
              AND LOWER(AVAILABILITY_STATUS) NOT LIKE ('%unavailable%')
              AND (SELECT PCK_UTILS.F_SE_PARAMETRO_PROC@DBL_DESENVOL(proc.WORKSPACE, proc.APPLICATION_ID, proc.PROCESS_NAME, proc.PAGE_ID) FROM dual) = 'N'
        ) senhas
        JOIN apex_workspace_apex_users@DBL_DESENVOL users ON senhas.workspace = users.workspace_name
        WHERE ACCOUNT_LOCKED = 'No'
        AND workspace NOT IN ('APEX_SEPROC_MONITORAMENTO', 'APEX_STI_API', 'APEX_STI_MONITOR')
        GROUP BY cod_aplicacao, workspace, nome_apelido, descr_par_1, descr_par_2, descr_par_3, descr_par_4, tipo
        ORDER BY tipo, workspace, COD_APLICACAO, descr_par_1, descr_par_2
    )
    GROUP BY cod_aplicacao, workspace, nome_apelido, descr_par_1, descr_par_2, descr_par_3, descr_par_4, tipo
    ORDER BY tipo, workspace, COD_APLICACAO, descr_par_1, descr_par_2
)

SELECT COUNT(1) AS total_casos, instancia
FROM (
    SELECT LISTAGG(INSTANCIA,' E ') WITHIN GROUP (ORDER BY INSTANCIA) AS INSTANCIA,
           COD_APLICACAO,
           WORKSPACE,
           NOME_APELIDO,
           DESCR_PAR_1,
           DESCR_PAR_2,
           DESCR_PAR_3,
           DESCR_PAR_4,
           TIPO
    FROM (
        SELECT 'DESENVOL' AS INSTANCIA, CASOS_DESENVOL.* FROM CASOS_DESENVOL
        UNION ALL
        SELECT 'PRODUCAO' AS INSTANCIA, CASOS_PROD.* FROM CASOS_PROD
    )
    GROUP BY COD_APLICACAO, WORKSPACE, NOME_APELIDO, DESCR_PAR_1, DESCR_PAR_2, DESCR_PAR_3, DESCR_PAR_4, TIPO
    ORDER BY 1 DESC
) 
GROUP BY instancia
ORDER BY 1;
