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


def test_documentacao_submenu_usb():
    readme = (ROOT / "README.md").read_text(encoding="utf-8").lower()
    assert "usb/pendrives" in readme, "README sem a opcao de USB no Menu 12"

    men = (ROOT / "docs/menus.md").read_text(encoding="utf-8")
    sec = men.split("## 12. Segurança da Informação", 1)[1].split("\n## ", 1)[0]
    for trecho in ("opção 40", "USBSTOR", "Get-PnpDevice", "auditpol",
                   "Register-CimIndicationEvent", "WriteProtect", "BitLocker",
                   "Get-FileHash", "cipher /w", "rollback", "pipeline"):
        assert trecho.lower() in sec.lower(), f"docs/menus.md secao 12 sem: {trecho}"

    index = (ROOT / "docs/index.md").read_text(encoding="utf-8").lower()
    assert "drives usb e pendrives" in index, "docs/index.md sem o submenu USB"
    uso = (ROOT / "docs/uso.md").read_text(encoding="utf-8").lower()
    assert "opção 40" in uso and "rollback" in uso, "docs/uso.md sem as regras do submenu USB"


def test_fluxograma_reflete_estado_atual():
    svg = (ROOT / "docs/assets/fluxograma.svg").read_text(encoding="utf-8")
    png = (ROOT / "docs/assets/fluxograma.png").read_bytes()
    assert png[:8] == b"\x89PNG\r\n\x1a\n", "fluxograma.png nao e PNG valido"
    assert len(png) > 10000, "fluxograma.png vazio ou invalido"
    import struct
    larg, alt = struct.unpack(">II", png[16:24])
    assert (larg, alt) == (1920, 1660), f"PNG {larg}x{alt} diferente do viewBox do SVG"
    for trecho in ("MENU 12 · OPÇÕES E SUBMENUS CRIADOS", "19-21 · CONTAS",
                   "25-28 · REDE", "34-39 · HARDENING", "40 · USB / PENDRIVES",
                   "22 pipeline"):
        assert trecho.lower() in svg.lower(), f"SVG sem o resumo: {trecho}"
    assert 'viewBox="0 0 1920 1660"' in svg, "viewBox nao expandido para o resumo"
    assert "usb/pendrives" in svg.lower(), "SVG sem o submenu USB"
    assert "pytest em tests/" in svg, "SVG sem a referencia ao pytest"
    assert "27 testes" not in svg, "SVG com contagem de testes desatualizada"
    assert "bom + crlf" in svg.lower(), "SVG sem a trava de encoding"


def test_nav_mkdocs_confere_com_arquivos():
    mkdocs = (ROOT / "mkdocs.yml").read_text(encoding="utf-8")
    for doc in DOCS:
        rel = doc if doc != "README.md" else None
        if rel:
            assert rel.split("/", 1)[1] in mkdocs, f"{doc}: fora do nav do mkdocs"
