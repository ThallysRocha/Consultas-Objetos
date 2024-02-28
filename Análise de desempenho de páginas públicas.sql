WITH lentos AS (
    SELECT ativ.workspace,
           ativ.application_id,
           ativ.application_name,
           ativ.page_id,
           ativ.page_name,
           ativ.PAGE_VIEW_TYPE,
           ROUND(AVG(ativ.elapsed_time),4) AS "Média",
           ROUND(STDDEV(ativ.elapsed_time),4) AS "Desvio padrão",
           COUNT(1) AS "Total de acessos",
           ROUND(SUM(ativ.elapsed_time),4) AS "Total em Tempo",
           'Lento' AS "Tipo"
    FROM atividade_apex ativ
    JOIN aplicacoes_apex app ON ativ.application_id = app.application_id
    WHERE ativ.elapsed_time > 3
      AND ativ.view_date > SYSDATE - 2
      AND ativ.AVAILABILITY_STATUS LIKE 'Available%'
      AND ativ.AUTHENTICATION_SCHEME_TYPE = 'No Authentication'
      AND ativ.WORKSPACE NOT IN (SELECT WORKSPACE FROM WORKSPACES_DESCONTINUADOS)
      AND ativ.application_id IN (SELECT application_id FROM aplicacoes_apex WHERE workspace = ativ.WORKSPACE)
    GROUP BY ativ.workspace,
             ativ.application_id,
             ativ.application_name,
             ativ.page_id,
             ativ.page_name,
             ativ.PAGE_VIEW_TYPE
),
rapidos AS (
    SELECT ativ.workspace,
           ativ.application_id,
           ativ.application_name,
           ativ.page_id,
           ativ.page_name,
           ativ.PAGE_VIEW_TYPE,
           ROUND(AVG(ativ.elapsed_time),4) AS "Média",
           ROUND(STDDEV(ativ.elapsed_time),4) AS "Desvio padrão",
           COUNT(1) AS "Total de acessos",
           ROUND(SUM(ativ.elapsed_time),4) AS "Total em Tempo",
           'Rápido' AS "Tipo"
    FROM atividade_apex ativ
    JOIN aplicacoes_apex app ON ativ.application_id = app.application_id
    WHERE ativ.elapsed_time <= 3
      AND ativ.view_date > SYSDATE - 2
      AND ativ.AVAILABILITY_STATUS LIKE 'Available%'
      AND ativ.AUTHENTICATION_SCHEME_TYPE = 'No Authentication'
      AND ativ.WORKSPACE NOT IN (SELECT WORKSPACE FROM WORKSPACES_DESCONTINUADOS)
      AND ativ.application_id IN (SELECT application_id FROM aplicacoes_apex WHERE workspace = ativ.WORKSPACE)
    GROUP BY ativ.workspace,
             ativ.application_id,
             ativ.application_name,
             ativ.page_id,
             ativ.page_name,
             ativ.PAGE_VIEW_TYPE
)
SELECT t.*,
       NVL(ROUND((100 * "Tempo total lentos" / "Tempo total tudo"),4),0)||'%' AS porcentagem
FROM (
    SELECT CASE WHEN lentos."Total de acessos" IS NULL THEN 0 ELSE lentos."Total de acessos" END
           + CASE WHEN rapidos."Total de acessos" IS NULL THEN 0 ELSE rapidos."Total de acessos" END AS "Total de acessos",
           NVL(lentos.workspace, rapidos.workspace) AS Workspace,
           NVL(lentos.application_id, rapidos.application_id) AS Application_id,
           NVL(lentos.application_name, rapidos.application_name) AS Application_name,
           NVL(lentos.page_id, rapidos.page_id) AS page_id,
           NVL(lentos.page_name, rapidos.page_name) AS page_name,
           NVL(lentos.PAGE_VIEW_TYPE, rapidos.PAGE_VIEW_TYPE) AS PAGE_VIEW_TYPE,
           lentos."Média" AS "Média Lentos",
           lentos."Desvio padrão" AS "Desvio padrão lentos",
           lentos."Total de acessos" AS "Total de acessos lentos",
           lentos."Total em Tempo" AS "Tempo total lentos",
           rapidos."Média" AS "Média rapidos",
           rapidos."Desvio padrão" AS "Desvio padrão rapidos",
           rapidos."Total de acessos" AS "Total de acessos rapidos",
           rapidos."Total em Tempo" AS "Tempo total rapidos",
           CASE WHEN lentos."Total em Tempo" IS NULL THEN 0 ELSE lentos."Total em Tempo" END
           + CASE WHEN rapidos."Total em Tempo" IS NULL THEN 0 ELSE rapidos."Total em Tempo" END AS "Tempo total tudo"
    FROM lentos
    FULL OUTER JOIN rapidos
    ON lentos.application_id = rapidos.application_id
    AND lentos.page_id = rapidos.page_id
    AND lentos.page_view_type = rapidos.page_view_type
    WHERE NVL(lentos.page_id, rapidos.page_id) IS NOT NULL
) t
--WHERE "Tempo total lentos" >= "Tempo total tudo" * 0.25
WHERE (t.Workspace, t.Application_id, t.page_id) NOT IN (
    SELECT WORKSPACE, APPLICATION_ID, PAGE_ID
    FROM apex_application_pag_val
    WHERE UPPER(VALIDATION_EXPRESSION1) LIKE '%PCK_RECAPTCHA.VALIDATE_RECAPTCHA%'
)
AND (t.Workspace, t.Application_id, t.page_id) NOT IN (
    SELECT WORKSPACE, APPLICATION_ID, PAGE_ID
    FROM apex_application_pag_proc
    WHERE LOWER(PROCESS_SOURCE) LIKE '%recaptcha%'
)
ORDER BY 16 DESC;
