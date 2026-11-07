-- Distância entre os municípios: percentis 10, 50 e 90 da penetração, por mês.
-- Só entram municípios com a série completa.
WITH completos AS (
    SELECT municipio_ibge
    FROM pix_municipio_mes
    WHERE municipio_ibge <> 0
    GROUP BY municipio_ibge
    HAVING COUNT(*) = (SELECT COUNT(DISTINCT ano_mes) FROM pix_municipio_mes)
),
ordenado AS (
    SELECT
        p.ano_mes,
        1.0 * p.pagadores_pf / m.populacao AS penetracao,
        PERCENT_RANK() OVER (
            PARTITION BY p.ano_mes
            ORDER BY 1.0 * p.pagadores_pf / m.populacao
        ) AS posicao
    FROM pix_municipio_mes AS p
    JOIN completos USING (municipio_ibge)
    JOIN municipio AS m USING (municipio_ibge)
)
SELECT
    ano_mes,
    MIN(CASE WHEN posicao >= 0.1 THEN penetracao END) AS p10,
    MIN(CASE WHEN posicao >= 0.5 THEN penetracao END) AS p50,
    MIN(CASE WHEN posicao >= 0.9 THEN penetracao END) AS p90
FROM ordenado
GROUP BY ano_mes
ORDER BY ano_mes;
