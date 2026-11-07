-- Sensibilidade no último mês: a ordem das regiões muda sem Pacaraima (RR)
-- ou quando o denominador são só os adultos?
-- O total de adultos é estimado: população de 2026 x parcela adulta do Censo 2022.
WITH ultimo AS (
    SELECT
        m.regiao,
        m.populacao,
        p.pagadores_pf,
        m.municipio_ibge,
        1.0 * a.populacao_18_mais / a.populacao_censo AS parcela_adulta
    FROM pix_municipio_mes AS p
    JOIN municipio AS m USING (municipio_ibge)
    JOIN populacao_adulta_uf AS a USING (uf)
    WHERE p.ano_mes = (SELECT MAX(ano_mes) FROM pix_municipio_mes)
),
sem_pacaraima AS (
    SELECT *
    FROM ultimo
    WHERE municipio_ibge <> 1400456
),
com AS (
    SELECT regiao, 1.0 * SUM(pagadores_pf) / SUM(populacao) AS penetracao
    FROM ultimo
    GROUP BY regiao
),
sem AS (
    SELECT
        regiao,
        1.0 * SUM(pagadores_pf) / SUM(populacao) AS sem_pacaraima,
        SUM(populacao * parcela_adulta) / SUM(populacao) AS parcela_adulta,
        1.0 * SUM(pagadores_pf) / SUM(populacao * parcela_adulta) AS adultos_sem_pacaraima
    FROM sem_pacaraima
    GROUP BY regiao
)
SELECT
    regiao,
    com.penetracao,
    sem.sem_pacaraima,
    sem.parcela_adulta,
    sem.adultos_sem_pacaraima,
    RANK() OVER (ORDER BY com.penetracao DESC) AS posicao_populacao,
    RANK() OVER (ORDER BY sem.adultos_sem_pacaraima DESC) AS posicao_adultos
FROM com
JOIN sem USING (regiao)
ORDER BY posicao_populacao;
