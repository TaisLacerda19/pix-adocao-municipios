-- Municípios fora do esperado no último mês: acima de 100% da população
-- ou abaixo de 30%.
SELECT
    m.nome,
    m.uf,
    m.populacao,
    p.pagadores_pf,
    1.0 * p.pagadores_pf / m.populacao AS penetracao,
    (SELECT MIN(ano_mes) FROM pix_municipio_mes AS h
     WHERE h.municipio_ibge = m.municipio_ibge) AS primeiro_mes
FROM pix_municipio_mes AS p
JOIN municipio AS m USING (municipio_ibge)
WHERE p.ano_mes = (SELECT MAX(ano_mes) FROM pix_municipio_mes)
  AND m.regiao IS NOT NULL
  AND (1.0 * p.pagadores_pf / m.populacao > 1
       OR 1.0 * p.pagadores_pf / m.populacao < 0.3)
ORDER BY penetracao DESC;
