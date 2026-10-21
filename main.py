#!/usr/bin/env python3
"""Ponto de entrada Python do projeto.

Nao executa nenhuma acao privilegiada sozinho: `check` faz apenas leitura
(validacao estatica do SOS-Manutencao.ps1), `test` roda o pytest, e `run` abre o menu
interativo do SOS-Manutencao.ps1 (esse sim pede elevacao/admin no Windows).

Uso:
    python main.py check   # validacao estatica (funciona em qualquer SO)
    python main.py test    # roda tests/ com pytest
    python main.py run     # abre o SOS-Manutencao.ps1 (somente Windows + admin)
"""

import argparse
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SCRIPT = ROOT / "SOS-Manutencao.ps1"
VERSION_RE = re.compile(r"v2\.1\.(\d{6})")
FORBIDDEN = ["prefeitura", "monte santo", "departamento de tecnologia"]
# (arquivo, padrao, descricao) — inventario de operacoes perigosas esperado.
DANGER = [
    ("SOS-Manutencao.ps1", r"Taskkill /f /im explorer\.exe", "mata o explorer (teste de monitor)"),
    ("SOS-Manutencao.ps1", r"advfirewall set allprofiles state off", "desliga o firewall"),
    ("SOS-Manutencao.ps1", r"pnputil /delete-driver", "remove driver"),
    ("SOS-Manutencao.ps1", r"icacls ", "altera ACLs"),
    ("SOS-Manutencao.ps1", r"takeown", "toma posse de pasta"),
]


def fail(msg):
    print(f"[FALHA] {msg}")
    return False


def check_syntax_pwsh():
    """Valida a sintaxe via parser do PowerShell (somente Windows)."""
    launcher = None
    for cand in ("powershell", "pwsh"):
        try:
            subprocess.run([cand, "-NoProfile", "-Command", "$PSVersionTable.PSVersion"],
                           capture_output=True, check=True, timeout=30)
            launcher = cand
            break
        except (OSError, subprocess.SubprocessError):
            continue
    if launcher is None:
        print("[INFO] PowerShell indisponivel; sintaxe via parser ignorada.")
        return True
    ps = ("$t=$null; $e=$null; "
          "[void][System.Management.Automation.Language.Parser]::ParseFile("
          f"'{SCRIPT}', [ref]$t, [ref]$e); $e.Count")
    r = subprocess.run([launcher, "-NoProfile", "-Command", ps],
                       capture_output=True, text=True, timeout=60)
    try:
        n = int(r.stdout.strip().splitlines()[-1])
    except (IndexError, ValueError):
        return fail(f"saida inesperada do parser: {r.stdout!r} {r.stderr!r}")
    if n != 0:
        return fail(f"parser acusa {n} erro(s) de sintaxe")
    print("[OK] sintaxe PowerShell valida")
    return True


def check_versions():
    """Versao v2.1.AAMMDD consistente nos 4 pontos oficiais."""
    alvos = {
        "SOS-Manutencao.ps1 (cabecalho)": r"T! SOS SISTEMAS - FERRAMENTA TÉCNICA DE MANUTENÇÃO  (v2\.1\.\d{6})",
        "SOS-Manutencao.ps1 ($APP.Nome)": r'Nome\s+= "T! SOS Sistemas - Manutenção Técnica  (v2\.1\.\d{6})"',
        "README.md": r"Versão atual: \*\*(v2\.1\.\d{6})\*\*",
        "docs/index.md": r"(v2\.1\.\d{6})",
    }
    versoes = set()
    ok = True
    for rotulo, padrao in alvos.items():
        arq = rotulo.split(" ")[0]
        texto = (ROOT / arq).read_text(encoding="utf-8", errors="replace")
        m = re.findall(padrao, texto)
        if not m:
            ok = fail(f"{rotulo}: padrao de versao nao encontrado") or False
            continue
        for v in m:
            if not VERSION_RE.fullmatch(v):
                ok = fail(f"{rotulo}: formato invalido ({v})") or False
            versoes.add(v)
    if len(versoes) > 1:
        ok = fail(f"versoes divergentes: {sorted(versoes)}") or False
    if ok:
        print(f"[OK] versao consistente: {versoes.pop()}")
    return ok


def check_branding():
    ok = True
    for p in ROOT.rglob("*"):
        if not p.is_file():
            continue
        if ".git" in p.parts or "bat" in p.parts or p.suffix in {".pyc"} or p.parent.name in {"site", "__pycache__"}:
            continue
        try:
            texto = p.read_text(encoding="utf-8").lower()
        except (UnicodeDecodeError, OSError):
            continue
        for termo in FORBIDDEN:
            if termo in texto and "test_branding" not in texto:
                ok = fail(f"{p.name}: contem {termo!r}") or False
    if ok:
        print("[OK] marca limpa (sem termos proibidos)")
    return ok


def report_danger():
    """Apenas relata onde estao as operacoes perigosas (nao falha)."""
    print("--- inventario de operacoes sensiveis ---")
    for arq, padrao, desc in DANGER:
        texto = (ROOT / arq).read_text(encoding="utf-8", errors="replace")
        linhas = [i + 1 for i, l in enumerate(texto.splitlines()) if re.search(padrao, l)]
        print(f"{desc}: {arq}:{linhas if linhas else 'ausente'}")
    print("Perigo real de 'barra sumida': menu 13 opcao 4 (mata explorer em loop).")
    print("Recuperacao: Ctrl+Shift+Esc > Arquivo > Executar nova tarefa > explorer.exe")


def cmd_check(_args):
    if not SCRIPT.exists():
        return fail("SOS-Manutencao.ps1 nao encontrado")
    ok = check_syntax_pwsh()
    ok = check_versions() and ok
    ok = check_branding() and ok
    report_danger()
    print("RESULTADO:", "OK" if ok else "FALHAS ACIMA")
    return 0 if ok else 1


def cmd_test(args):
    try:
        import pytest  # noqa: F401
    except ImportError:
        print("pytest nao instalado. Com rede: `poetry install` e `poetry run pytest`.")
        print("Sem rede: rode `python main.py check` (validacao estatica sem dependencias).")
        return 2
    r = subprocess.run([sys.executable, "-m", "pytest", "tests", "-q"] + args.extra,
                       cwd=ROOT)
    return r.returncode


def cmd_run(_args):
    if sys.platform != "win32":
        return fail("run exige Windows")
    r = subprocess.run(["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass",
                        "-File", str(SCRIPT)])
    return r.returncode


def main(argv=None):
    ap = argparse.ArgumentParser(description="Harness do SOS-Manutencao.ps1")
    sub = ap.add_subparsers(dest="cmd", required=True)
    sub.add_parser("check", help="validacao estatica (leitura apenas)")
    t = sub.add_parser("test", help="roda o pytest em tests/")
    t.add_argument("extra", nargs="*", help="args extras ao pytest")
    sub.add_parser("run", help="abre o menu do SOS-Manutencao.ps1 (Windows + admin)")
    args = ap.parse_args(argv)
    return {"check": cmd_check, "test": cmd_test, "run": cmd_run}[args.cmd](args)


if __name__ == "__main__":
    raise SystemExit(main())
