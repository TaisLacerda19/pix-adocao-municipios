-- Primeiro mês em que cada região passou de 50% da população.
WITH populacao AS (
    SELECT regiao, SUM(populacao) AS populacao
    FROM municipio
    WHERE regiao IS NOT NULL
    GROUP BY regiao
),
mensal AS (
    SELECT
        p.ano_mes,
        m.regiao,
        1.0 * SUM(p.pagadores_pf) / pop.populacao AS penetracao
    FROM pix_municipio_mes AS p
    JOIN municipio AS m USING (municipio_ibge)
    JOIN populacao AS pop ON pop.regiao = m.regiao
    GROUP BY p.ano_mes, m.regiao
),
acima AS (
    SELECT
        regiao,
        ano_mes,
        penetracao,
        ROW_NUMBER() OVER (PARTITION BY regiao ORDER BY ano_mes) AS ordem
    FROM mensal
    WHERE penetracao >= 0.5
)
SELECT regiao, ano_mes AS mes_marco, penetracao
FROM acima
WHERE ordem = 1
ORDER BY ano_mes;
