-- Ranking das UFs com e sem Pacaraima (RR), município com 7 vezes mais
-- pagadores do que moradores. Também calcula a penetração entre adultos.
WITH ultimo AS (
    SELECT p.pagadores_pf, m.uf, m.populacao, m.municipio_ibge
    FROM pix_municipio_mes AS p
    JOIN municipio AS m USING (municipio_ibge)
    WHERE p.ano_mes = (SELECT MAX(ano_mes) FROM pix_municipio_mes)
      AND m.uf IS NOT NULL
),
por_uf AS (
    SELECT
        uf,
        SUM(pagadores_pf) AS pagadores,
        SUM(populacao) AS populacao,
        1.0 * SUM(pagadores_pf) / SUM(populacao) AS com_pacaraima,
        1.0 * SUM(CASE WHEN municipio_ibge <> 1400456 THEN pagadores_pf END)
            / SUM(CASE WHEN municipio_ibge <> 1400456 THEN populacao END) AS sem_pacaraima
    FROM ultimo
    GROUP BY uf
)
SELECT
    u.uf,
    u.pagadores,
    u.populacao,
    u.com_pacaraima,
    u.sem_pacaraima,
    RANK() OVER (ORDER BY u.com_pacaraima DESC) AS rank_com,
    RANK() OVER (ORDER BY u.sem_pacaraima DESC) AS rank_sem,
    u.sem_pacaraima / (1.0 * a.populacao_18_mais / a.populacao_censo) AS adultos_sem_pacaraima
FROM por_uf AS u
JOIN populacao_adulta_uf AS a USING (uf)
ORDER BY rank_sem;
