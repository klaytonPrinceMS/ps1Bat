"""Padrao misto da documentacao: cabecalho bilingue EN/PT, resto em pt-BR."""
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DOCS = ["README.md", "docs/index.md", "docs/uso.md",
        "docs/menus.md", "docs/desenvolvimento.md"]


def test_cabecalho_bilingue():
    for doc in DOCS:
        texto = (ROOT / doc).read_text(encoding="utf-8")
        linhas = texto.splitlines()
        assert linhas[0].startswith("# "), f"{doc}: sem titulo H1"
        assert "> **EN:**" in texto, f"{doc}: sem bloco EN"
        assert "> **PT:**" in texto, f"{doc}: sem bloco PT"


def test_nav_mkdocs_confere_com_arquivos():
    mkdocs = (ROOT / "mkdocs.yml").read_text(encoding="utf-8")
    for doc in DOCS:
        rel = doc if doc != "README.md" else None
        if rel:
            assert rel.split("/", 1)[1] in mkdocs, f"{doc}: fora do nav do mkdocs"
