"""Pipeline ETL do projeto.

Uso:
    python etl/pipeline.py              usa os dados guardados em dados/brutos
    python etl/pipeline.py --atualizar  baixa tudo de novo das APIs
"""

import sys
from pathlib import Path

import pandas as pd

sys.path.insert(0, str(Path(__file__).resolve().parent))

import carregar as carga  # noqa: E402
import extrair as ext  # noqa: E402
import transformar as tr  # noqa: E402

BRUTOS = carga.RAIZ / "dados" / "brutos"
ARQUIVOS = {
    "pix": (BRUTOS / "pix_municipios.csv.gz", ext.extrair_pix_municipios),
    "usuarios": (BRUTOS / "usuarios_dict.csv", ext.extrair_usuarios_dict),
    "populacao": (BRUTOS / "populacao_2026.csv", ext.extrair_populacao),
    "adultos": (BRUTOS / "censo_2022_idade_uf.csv", ext.extrair_populacao_adulta),
}


def obter_brutos(atualizar=False):
    """Lê cada base do disco ou, se preciso, baixa da fonte oficial."""
    BRUTOS.mkdir(parents=True, exist_ok=True)
    brutos = {}
    for nome, (caminho, baixar) in ARQUIVOS.items():
        if atualizar or not caminho.exists():
            print(f"Baixando {nome}...")
            baixar().to_csv(caminho, index=False)
        brutos[nome] = pd.read_csv(caminho, low_memory=False)
    return brutos


def executar(atualizar=False):
    """Roda as três etapas e devolve o caminho do banco."""
    brutos = obter_brutos(atualizar)

    pix = tr.transformar_pix(brutos["pix"])
    municipios = tr.transformar_municipios(brutos["pix"], brutos["populacao"])
    usuarios = tr.transformar_usuarios(brutos["usuarios"])
    adultos = tr.transformar_populacao_adulta(brutos["adultos"])

    testes = tr.validar(pix, municipios, usuarios, adultos)
    banco = carga.carregar(pix, municipios, usuarios, adultos)

    print(f"{len(testes)} testes de qualidade aprovados")
    print(f"{len(pix):,} linhas de Pix gravadas em {banco.name}".replace(",", "."))
    return banco


if __name__ == "__main__":
    executar(atualizar="--atualizar" in sys.argv)
