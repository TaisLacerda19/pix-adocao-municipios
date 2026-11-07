-- Funil mensal do país: cadastrados, ativos, frequência e valor médio.
-- Inclui a linha de município não informado, porque aqui o total é nacional.
WITH mensal AS (
    SELECT
        ano_mes,
        SUM(pagadores_pf) AS pagadores,
        SUM(qt_pago_pf) AS transacoes,
        SUM(vl_pago_pf) AS valor
    FROM pix_municipio_mes
    GROUP BY ano_mes
)
SELECT
    m.ano_mes,
    u.usuarios_pf AS cadastrados,
    m.pagadores,
    1.0 * m.pagadores / u.usuarios_pf AS taxa_ativacao,
    1.0 * m.pagadores / (SELECT SUM(populacao) FROM municipio) AS penetracao,
    1.0 * m.transacoes / m.pagadores AS frequencia,
    m.valor / m.transacoes AS valor_medio,
    m.valor,
    m.transacoes
FROM mensal AS m
JOIN usuarios_dict AS u USING (ano_mes)
ORDER BY m.ano_mes;
