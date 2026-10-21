"""Versao v2.1.AAMMDD consistente nos pontos oficiais."""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
FMT = re.compile(r"^v2\.1\.\d{6}$")


def _versoes(padrao, arquivo):
    texto = (ROOT / arquivo).read_text(encoding="utf-8")
    return re.findall(padrao, texto)


def test_formato_e_consistencia():
    achados = {}
    achados["cabecalho"] = _versoes(
        r"T! SOS SISTEMAS - FERRAMENTA TÉCNICA DE MANUTENÇÃO  (v2\.1\.\d{6})", "SOS-Manutencao.ps1")
    achados["app_nome"] = _versoes(
        r'Nome\s+= "T! SOS Sistemas - Manutenção Técnica  (v2\.1\.\d{6})"', "SOS-Manutencao.ps1")
    achados["readme"] = _versoes(r"Versão atual: \*\*(v2\.1\.\d{6})\*\*", "README.md")
    achados["index"] = _versoes(r"(v2\.1\.\d{6})", "docs/index.md")
    for ponto, vs in achados.items():
        assert vs, f"{ponto}: versao nao encontrada"
        for v in vs:
            assert FMT.match(v), f"{ponto}: formato invalido ({v})"
    todas = {v for vs in achados.values() for v in vs}
    assert len(todas) == 1, f"versoes divergentes: {sorted(todas)}"
