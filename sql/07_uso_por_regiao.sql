-- Intensidade de uso por região no último mês.
SELECT
    m.regiao,
    SUM(p.pagadores_pf) AS pagadores,
    1.0 * SUM(p.qt_pago_pf) / SUM(p.pagadores_pf) AS frequencia,
    SUM(p.vl_pago_pf) / SUM(p.qt_pago_pf) AS valor_medio,
    SUM(p.vl_pago_pf) / SUM(p.pagadores_pf) AS valor_por_pagador
FROM pix_municipio_mes AS p
JOIN municipio AS m USING (municipio_ibge)
WHERE p.ano_mes = (SELECT MAX(ano_mes) FROM pix_municipio_mes)
  AND m.regiao IS NOT NULL
GROUP BY m.regiao
ORDER BY frequencia DESC;
