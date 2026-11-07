-- Quanto do Pix termina em uma empresa: parcela recebida por PJ, por mês.
SELECT
    ano_mes,
    1.0 * SUM(qt_recebido_pj) / SUM(qt_recebido_pf + qt_recebido_pj) AS parcela_pj
FROM pix_municipio_mes
GROUP BY ano_mes
ORDER BY ano_mes;
