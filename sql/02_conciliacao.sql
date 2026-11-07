-- Teste de auditoria: no total do país, todo Pix pago precisa ter sido recebido.
SELECT
    ano_mes,
    SUM(qt_pago_pf + qt_pago_pj) AS qt_pago,
    SUM(qt_recebido_pf + qt_recebido_pj) AS qt_recebido,
    SUM(vl_pago_pf + vl_pago_pj) AS vl_pago,
    SUM(qt_pago_pf + qt_pago_pj) - SUM(qt_recebido_pf + qt_recebido_pj) AS diferenca_qt,
    ROUND(SUM(vl_pago_pf + vl_pago_pj) - SUM(vl_recebido_pf + vl_recebido_pj), 2) AS diferenca_vl
FROM pix_municipio_mes
GROUP BY ano_mes
ORDER BY ano_mes;
