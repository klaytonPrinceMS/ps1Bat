"""Nenhuma mencao remanescente a prefeitura / departamento antigo."""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
FORBIDDEN = ["prefeitura", "monte santo", "departamento de tecnologia", "hacker"]
SKIP_DIRS = {".git", "site", "__pycache__", ".pytest_cache", "bat", ".venv"}
SKIP_FILES = {"test_branding.py"}

if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))


def test_sem_mencoes_proibidas():
    violacoes = []
    for p in ROOT.rglob("*"):
        if not p.is_file() or SKIP_DIRS & set(p.parts) or p.name in SKIP_FILES:
            continue
        try:
            linhas = p.read_text(encoding="utf-8").splitlines()
        except (UnicodeDecodeError, OSError):
            continue
        for n, linha in enumerate(linhas, 1):
            baixa = linha.lower()
            if "forbidden" in baixa:
                continue  # definicao da propria lista de termos (main.py)
            for termo in FORBIDDEN:
                if termo in baixa:
                    violacoes.append(f"{p.relative_to(ROOT)}:{n}: {termo!r}")
    assert not violacoes, "mencoes proibidas: " + "; ".join(violacoes)


def test_check_branding_ignora_site_e_pycache(tmp_path, monkeypatch):
    """Regressao: site/ do mkdocs contem .fa-hacker-news (CSS) e nao pode falhar."""
    import main

    site_css = tmp_path / "site" / "css"
    site_css.mkdir(parents=True)
    (site_css / "theme.css").write_text(".fa-hacker-news{content:'x'}", encoding="utf-8")
    pycache = tmp_path / "pkg" / "__pycache__"
    pycache.mkdir(parents=True)
    (pycache / "mod.txt").write_text("hacker", encoding="utf-8")
    (tmp_path / "README.md").write_text("projeto limpo", encoding="utf-8")
    monkeypatch.setattr(main, "ROOT", tmp_path)
    assert main.check_branding() is True


def test_check_branding_falha_com_termo_em_arquivo_real(tmp_path, monkeypatch):
    """Com o fix, termo proibido em arquivo real sob ROOT continua falhando."""
    import main

    (tmp_path / "notas.md").write_text("mencao a hacker aqui", encoding="utf-8")
    monkeypatch.setattr(main, "ROOT", tmp_path)
    assert main.check_branding() is False
