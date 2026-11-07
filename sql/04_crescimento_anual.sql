-- Crescimento de outubro a outubro, para comparar os mesmos meses do ano.
-- O valor movimentado é pagadores x frequência x valor médio.
WITH outubros AS (
    SELECT
        ano_mes,
        SUM(pagadores_pf) AS pagadores,
        1.0 * SUM(qt_pago_pf) / SUM(pagadores_pf) AS frequencia,
        SUM(vl_pago_pf) / SUM(qt_pago_pf) AS valor_medio,
        SUM(vl_pago_pf) AS valor
    FROM pix_municipio_mes
    WHERE ano_mes % 100 = 10
    GROUP BY ano_mes
)
SELECT
    ano_mes,
    pagadores,
    frequencia,
    valor_medio,
    valor,
    1.0 * pagadores / LAG(pagadores) OVER (ORDER BY ano_mes) AS razao_pagadores,
    frequencia / LAG(frequencia) OVER (ORDER BY ano_mes) AS razao_frequencia,
    valor_medio / LAG(valor_medio) OVER (ORDER BY ano_mes) AS razao_valor_medio,
    valor / LAG(valor) OVER (ORDER BY ano_mes) AS razao_valor
FROM outubros
ORDER BY ano_mes;
