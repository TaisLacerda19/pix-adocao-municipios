"""Extração: baixa as bases públicas do Banco Central e do IBGE."""

import time
from urllib.parse import quote

import pandas as pd
import requests

PRIMEIRO_MES = 202011  # lançamento do Pix
ULTIMO_MES = 202610  # período fixo, para os resultados não mudarem sozinhos

BCB = "https://olinda.bcb.gov.br/olinda/servico/Pix_DadosAbertos/versao/v1/odata"
SIDRA = "https://apisidra.ibge.gov.br/values"


def meses(inicio=PRIMEIRO_MES, fim=ULTIMO_MES):
    """Lista os meses no formato AAAAMM, do início ao fim."""
    atual = pd.Period(str(inicio), freq="M")
    ultimo = pd.Period(str(fim), freq="M")
    return [int(p.strftime("%Y%m")) for p in pd.period_range(atual, ultimo)]


def buscar_json(url, tentativas=4):
    """Baixa um JSON, com novas tentativas porque a API às vezes falha."""
    for tentativa in range(1, tentativas + 1):
        try:
            resposta = requests.get(url, timeout=180)
            resposta.raise_for_status()
            return resposta.json()
        except (requests.RequestException, ValueError):
            if tentativa == tentativas:
                raise
            time.sleep(5 * tentativa)


def extrair_pix_municipios():
    """Baixa as transações por município, um mês por vez."""
    partes = []
    for mes in meses():
        filtro = quote(f"AnoMes eq {mes}")
        url = (
            f"{BCB}/TransacoesPixPorMunicipio(DataBase=@DataBase)"
            f"?@DataBase='{PRIMEIRO_MES}'&$filter={filtro}&$top=10000&$format=json"
        )
        linhas = buscar_json(url)["value"]
        if not linhas:
            raise ValueError(f"A API não devolveu dados para {mes}")
        partes.append(pd.DataFrame(linhas))
        print(f"  {mes}: {len(linhas)} linhas")
    return pd.concat(partes, ignore_index=True)


def extrair_usuarios_dict():
    """Baixa o total mensal de usuários com chave Pix cadastrada."""
    url = f"{BCB}/PixUsuariosCadastradosDICT?$top=1000&$format=json"
    return pd.DataFrame(buscar_json(url)["value"])


def extrair_populacao():
    """Baixa a população estimada de cada município (IBGE, tabela 6579)."""
    url = f"{SIDRA}/t/6579/n6/all/v/9324/p/2026/f/c"
    linhas = buscar_json(url)[1:]  # a primeira linha traz só os títulos
    return pd.DataFrame(linhas)


def extrair_populacao_adulta():
    """Baixa o Censo 2022 por UF, com as faixas de idade abaixo de 18 anos."""
    faixas = "100362,93070,93084,93085,6572,6573,6574"  # total, 0 a 14, 15, 16 e 17
    url = (
        f"{SIDRA}/t/9514/n3/all/v/93/p/2022/c2/6794"
        f"/c287/{faixas}/c286/113635/f/c"
    )
    linhas = buscar_json(url)[1:]
    return pd.DataFrame(linhas)
