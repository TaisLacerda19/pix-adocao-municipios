"""Transformação: limpa as bases e confere se elas fazem sentido."""

import pandas as pd

from extrair import PRIMEIRO_MES, ULTIMO_MES, meses

UF_POR_CODIGO = {
    11: "RO", 12: "AC", 13: "AM", 14: "RR", 15: "PA", 16: "AP", 17: "TO",
    21: "MA", 22: "PI", 23: "CE", 24: "RN", 25: "PB", 26: "PE", 27: "AL",
    28: "SE", 29: "BA", 31: "MG", 32: "ES", 33: "RJ", 35: "SP", 41: "PR",
    42: "SC", 43: "RS", 50: "MS", 51: "MT", 52: "GO", 53: "DF",
}
REGIAO_POR_DIGITO = {
    1: "Norte", 2: "Nordeste", 3: "Sudeste", 4: "Sul", 5: "Centro-Oeste",
}
FAIXAS_PORTE = [0, 20_000, 100_000, 500_000, float("inf")]
NOMES_PORTE = ["Até 20 mil", "20 a 100 mil", "100 a 500 mil", "Mais de 500 mil"]
CODIGO_NAO_INFORMADO = 0  # linha do Banco Central sem município identificado
CODIGO_TOTAL_IDADES = 100362  # categoria "Total" da tabela 9514 do IBGE
MATERIALIDADE = 0.0001  # diferença aceita na conciliação: 0,01% do valor

COLUNAS_PIX = {
    "AnoMes": "ano_mes",
    "Municipio_Ibge": "municipio_ibge",
    "QT_PES_PagadorPF": "pagadores_pf",
    "QT_PagadorPF": "qt_pago_pf",
    "VL_PagadorPF": "vl_pago_pf",
    "QT_PagadorPJ": "qt_pago_pj",
    "VL_PagadorPJ": "vl_pago_pj",
    "QT_RecebedorPF": "qt_recebido_pf",
    "VL_RecebedorPF": "vl_recebido_pf",
    "QT_RecebedorPJ": "qt_recebido_pj",
    "VL_RecebedorPJ": "vl_recebido_pj",
}


def transformar_pix(bruto):
    """Renomeia as colunas e dá um código à linha sem município."""
    pix = bruto.rename(columns=COLUNAS_PIX)[list(COLUNAS_PIX.values())].copy()
    pix["municipio_ibge"] = (
        pix["municipio_ibge"].fillna(CODIGO_NAO_INFORMADO).astype(int)
    )
    return pix


def transformar_municipios(bruto_pix, bruto_populacao):
    """Monta a dimensão de municípios: nome, UF, região, população e porte."""
    populacao = pd.DataFrame({
        "municipio_ibge": bruto_populacao["D1C"].astype(int),
        "populacao": pd.to_numeric(bruto_populacao["V"]).astype(int),
    })
    ultimos = (
        bruto_pix.dropna(subset=["Municipio_Ibge"])
        .sort_values("AnoMes")
        .drop_duplicates("Municipio_Ibge", keep="last")
    )
    nomes = pd.DataFrame({
        "municipio_ibge": ultimos["Municipio_Ibge"].astype(int),
        "nome": ultimos["Municipio"].str.title(),
    })
    municipios = populacao.merge(nomes, on="municipio_ibge", how="left")
    municipios["uf"] = (municipios["municipio_ibge"] // 100_000).map(UF_POR_CODIGO)
    municipios["regiao"] = (
        municipios["municipio_ibge"] // 1_000_000
    ).map(REGIAO_POR_DIGITO)
    municipios["faixa_porte"] = pd.cut(
        municipios["populacao"], FAIXAS_PORTE, labels=NOMES_PORTE
    ).astype(str)

    nao_informado = pd.DataFrame([{
        "municipio_ibge": CODIGO_NAO_INFORMADO,
        "populacao": None,
        "nome": "Não informado",
        "uf": None,
        "regiao": None,
        "faixa_porte": None,
    }])
    return pd.concat([municipios, nao_informado], ignore_index=True)


def transformar_usuarios(bruto):
    """Deixa o total de usuários cadastrados no mesmo formato de mês do Pix."""
    return pd.DataFrame({
        "ano_mes": bruto["DataGraficosPix"].str[:7].str.replace("-", "").astype(int),
        "usuarios_pf": bruto["qtdUsuariosPessoaFisica"],
        "usuarios_pj": bruto["qtdUsuariosPessoaJuridica"],
    })


def transformar_populacao_adulta(bruto):
    """Calcula o total de adultos em cada UF no Censo 2022."""
    censo = pd.DataFrame({
        "uf": bruto["D1C"].astype(int).map(UF_POR_CODIGO),
        "faixa": bruto["D5C"].astype(int),
        "pessoas": pd.to_numeric(bruto["V"]),
    })
    e_total = censo["faixa"] == CODIGO_TOTAL_IDADES
    total = censo[e_total].set_index("uf")["pessoas"]
    menores = censo[~e_total].groupby("uf")["pessoas"].sum()
    return pd.DataFrame({
        "populacao_censo": total.astype(int),
        "populacao_18_mais": (total - menores).astype(int),
    }).reset_index()


def validar(pix, municipios, usuarios, adultos):
    """Testes de qualidade: qualquer falha interrompe o pipeline."""
    esperados = set(meses(PRIMEIRO_MES, ULTIMO_MES))
    medidas = pix.drop(columns=["ano_mes", "municipio_ibge"])
    mensal = pix.groupby("ano_mes").sum()
    pago = mensal["vl_pago_pf"] + mensal["vl_pago_pj"]
    recebido = mensal["vl_recebido_pf"] + mensal["vl_recebido_pj"]
    reais = municipios[municipios["municipio_ibge"] != CODIGO_NAO_INFORMADO]
    testes = {
        "todos os meses do período presentes": set(pix["ano_mes"]) == esperados,
        "sem município repetido no mesmo mês": (
            not pix.duplicated(["ano_mes", "municipio_ibge"]).any()
        ),
        "sem valor negativo": bool((medidas >= 0).all().all()),
        "todo município do Pix tem cadastro": (
            set(pix["municipio_ibge"]) <= set(municipios["municipio_ibge"])
        ),
        "todo município tem nome, UF e região": bool(
            reais[["nome", "uf", "regiao"]].notna().all().all()
        ),
        "pago e recebido fecham dentro da materialidade": bool(
            ((pago - recebido).abs() / pago <= MATERIALIDADE).all()
        ),
        "27 UFs com população adulta": len(adultos) == 27,
        "adultos são parte da população": bool(
            (adultos["populacao_18_mais"] < adultos["populacao_censo"]).all()
        ),
        "usuários cadastrados em todos os meses": (
            set(usuarios["ano_mes"]) >= esperados
        ),
    }
    falhas = [nome for nome, passou in testes.items() if not passou]
    if falhas:
        raise ValueError(f"Testes de qualidade falharam: {falhas}")
    return testes
