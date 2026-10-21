"""Nenhuma mencao remanescente a prefeitura / departamento antigo."""
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
FORBIDDEN = ["prefeitura", "monte santo", "departamento de tecnologia"]
SKIP_DIRS = {".git", "site", "__pycache__", ".pytest_cache", "bat"}
SKIP_FILES = {"test_branding.py"}


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
