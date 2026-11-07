-- Penetração e uso por tamanho do município no último mês.
SELECT
    m.faixa_porte,
    COUNT(*) AS municipios,
    SUM(m.populacao) AS populacao,
    1.0 * SUM(p.pagadores_pf) / SUM(m.populacao) AS penetracao,
    1.0 * SUM(p.qt_pago_pf) / SUM(p.pagadores_pf) AS frequencia,
    SUM(p.vl_pago_pf) / SUM(p.qt_pago_pf) AS valor_medio
FROM pix_municipio_mes AS p
JOIN municipio AS m USING (municipio_ibge)
WHERE p.ano_mes = (SELECT MAX(ano_mes) FROM pix_municipio_mes)
  AND m.regiao IS NOT NULL
GROUP BY m.faixa_porte
ORDER BY MIN(m.populacao);
