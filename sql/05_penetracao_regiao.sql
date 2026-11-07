-- Penetração por região e mês: pagadores PF ativos sobre a população.
-- A diferença compara a região líder e a última de cada mês.
WITH populacao AS (
    SELECT regiao, SUM(populacao) AS populacao
    FROM municipio
    WHERE regiao IS NOT NULL
    GROUP BY regiao
),
penetracao AS (
    SELECT
        p.ano_mes,
        m.regiao,
        1.0 * SUM(p.pagadores_pf) / pop.populacao AS penetracao
    FROM pix_municipio_mes AS p
    JOIN municipio AS m USING (municipio_ibge)
    JOIN populacao AS pop ON pop.regiao = m.regiao
    GROUP BY p.ano_mes, m.regiao
)
SELECT
    ano_mes,
    regiao,
    penetracao,
    MAX(penetracao) OVER (PARTITION BY ano_mes)
        - MIN(penetracao) OVER (PARTITION BY ano_mes) AS diferenca,
    MAX(penetracao) OVER (PARTITION BY ano_mes)
        / MIN(penetracao) OVER (PARTITION BY ano_mes) AS razao
FROM penetracao
ORDER BY ano_mes, regiao;
