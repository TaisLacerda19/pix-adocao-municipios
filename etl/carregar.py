"""Carga: grava as tabelas no banco SQLite."""

import sqlite3
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
BANCO = RAIZ / "dados" / "pix.db"
ESQUEMA = RAIZ / "sql" / "01_criar_tabelas.sql"


def carregar(pix, municipios, usuarios, adultos):
    """Recria o banco do zero e grava as quatro tabelas."""
    BANCO.unlink(missing_ok=True)
    conexao = sqlite3.connect(BANCO)
    try:
        conexao.execute("PRAGMA foreign_keys = ON")
        conexao.executescript(ESQUEMA.read_text(encoding="utf-8"))
        municipios.to_sql("municipio", conexao, if_exists="append", index=False)
        pix.to_sql("pix_municipio_mes", conexao, if_exists="append", index=False)
        usuarios.to_sql("usuarios_dict", conexao, if_exists="append", index=False)
        adultos.to_sql("populacao_adulta_uf", conexao, if_exists="append", index=False)
        conexao.commit()
    finally:
        conexao.close()
    return BANCO
