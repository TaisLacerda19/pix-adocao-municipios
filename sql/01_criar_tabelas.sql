-- Esquema do banco. Os valores são em reais nominais.

CREATE TABLE municipio (
    municipio_ibge INTEGER PRIMARY KEY,  -- 0 = município não informado
    nome           TEXT NOT NULL,
    uf             TEXT,
    regiao         TEXT,
    populacao      INTEGER CHECK (populacao > 0),  -- estimativa do IBGE para 2026
    faixa_porte    TEXT
);

CREATE TABLE pix_municipio_mes (
    ano_mes        INTEGER NOT NULL,  -- formato AAAAMM
    municipio_ibge INTEGER NOT NULL REFERENCES municipio (municipio_ibge),
    pagadores_pf   INTEGER NOT NULL CHECK (pagadores_pf >= 0),
    qt_pago_pf     INTEGER NOT NULL,
    vl_pago_pf     REAL    NOT NULL,
    qt_pago_pj     INTEGER NOT NULL,
    vl_pago_pj     REAL    NOT NULL,
    qt_recebido_pf INTEGER NOT NULL,
    vl_recebido_pf REAL    NOT NULL,
    qt_recebido_pj INTEGER NOT NULL,
    vl_recebido_pj REAL    NOT NULL,
    PRIMARY KEY (ano_mes, municipio_ibge)
);

CREATE INDEX idx_pix_municipio ON pix_municipio_mes (municipio_ibge);

CREATE TABLE usuarios_dict (
    ano_mes     INTEGER PRIMARY KEY,
    usuarios_pf INTEGER NOT NULL,
    usuarios_pj INTEGER NOT NULL
);

CREATE TABLE populacao_adulta_uf (
    uf                TEXT PRIMARY KEY,
    populacao_censo   INTEGER NOT NULL,
    populacao_18_mais INTEGER NOT NULL
);
