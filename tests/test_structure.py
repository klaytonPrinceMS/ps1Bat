"""Estrutura minima do SOS-Manutencao.ps1: funcoes-chave e dispatch dos menus."""
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

FUNCOES = ["Menu-Principal", "Run", "Autenticar", "Garantir-Admin",
           "Get-StatusAdmin", "Configurar-IP-Estatico", "Teste-CPU-PS",
           "Teste-CPU-CMD", "Verificar-Processos-Suspeitos", "Cab", "Log",
           "Desc", "Confirmar", "P"]
MENUS = ["Menu-Reparo", "Menu-Discos", "Menu-Drivers", "Menu-Impressao",
         "Menu-Energia", "Menu-Memoria", "Menu-Rede", "Menu-Limpeza",
         "Menu-Seguranca", "Menu-Diagnostico", "Menu-Video", "Menu-Identidade",
         "Menu-Stress", "Menu-SegInfo", "Menu-Registro", "Menu-Update",
         "Menu-Winget", "Menu-Utilidades", "Menu-Contexto", "Menu-Instalacao"]


def test_funcoes_existem():
    texto = (ROOT / "SOS-Manutencao.ps1").read_text(encoding="utf-8")
    faltando = [f for f in FUNCOES + MENUS if f"function {f}" not in texto]
    assert not faltando, f"funcoes ausentes: {faltando}"


def test_menus_despachados_no_principal():
    texto = (ROOT / "SOS-Manutencao.ps1").read_text(encoding="utf-8")
    bloco = texto.split("function Menu-Principal", 1)[1]
    faltando = [m for m in MENUS if m not in bloco]
    assert not faltando, f"menus sem dispatch: {faltando}"


def test_identificadores_ascii():
    import re
    texto = (ROOT / "SOS-Manutencao.ps1").read_text(encoding="utf-8")
    defs = re.findall(r"^function (.+?) \{", texto, re.M)
    estranhas = [d for d in defs if re.search(r"[^\x00-\x7F]", d)]
    assert not estranhas, f"funcoes com acento: {estranhas}"
    com_acento = re.findall(r"\$[\w]*[áéíóúâêôãõçà]", texto)
    assert not com_acento, f"variaveis com acento: {com_acento}"


def test_janela_fixa_na_entrada():
    texto = (ROOT / "SOS-Manutencao.ps1").read_text(encoding="utf-8")
    assert "function Fixar-Janela" in texto
    entrada = texto.split("# PONTO DE ENTRADA", 1)[1]
    assert entrada.index("Fixar-Janela") < entrada.index("Garantir-Admin"), \
        "Fixar-Janela deve rodar antes da elevacao (vale p/ janela reaberta)"
    bloco = texto.split("function Fixar-Janela", 1)[1].split("\nfunction ", 1)[0]
    assert "WorkingArea" in bloco, "sem dimensionamento por pixels do monitor"
    assert "GetCurrentConsoleFontEx" in bloco, "sem leitura da fonte (conversao px->celula)"
    assert "GetWindowLong" in bloco and "SetWindowLong" in bloco, \
        "sem trava dos botoes maximizar/minimizar"


def test_splash_so_na_autenticacao():
    import re
    texto = (ROOT / "SOS-Manutencao.ps1").read_text(encoding="utf-8")
    assert "function Show-Splash" not in texto, "splash voltou a ser tela separada"
    marca = "VHVHHHAHHHHMMV"
    assert marca in texto, "arte da caveira sumiu"
    aut = texto.split("function Autenticar", 1)[1].split("\nfunction ", 1)[0]
    assert "$script:Splash" in aut, "caveira deve aparecer na tela de autenticacao"
    cab = texto.split("function Cab", 1)[1].split("\nfunction ", 1)[0]
    assert marca not in cab, "caveira nao pode aparecer no Cab (todos os menus)"


def test_menu_contexto_marca():
    texto = (ROOT / "SOS-Manutencao.ps1").read_text(encoding="utf-8")
    bloco = texto.split("function Menu-Contexto", 1)[1].split("\nfunction ", 1)[0]
    assert "T! SOS - " in bloco, "atalhos sem marca T! SOS"
    assert "KBP" in bloco, "entrada de contato KBP ausente"
    assert '"DTI - ' not in bloco, "restou rotulo DTI no menu de contexto"


def test_multiselecao_todos_os_menus():
    import re
    texto = (ROOT / "SOS-Manutencao.ps1").read_text(encoding="utf-8")
    assert "function Expandir-Selecao" in texto, "helper de multi-selecao ausente"
    n = texto.count("Expandir-Selecao (Read-Host")
    assert n >= 21, f"esperava >=21 menus convertidos, achei {n}"
    assert "switch (Read-Host" not in texto, "ainda ha switch single-select"
    assert '$op   = Read-Host "  Opção"' in texto, "Menu-ExecPolicy (escolha unica) nao deve mudar"


def test_multiselecao_comportamento_no_powershell():
    import re
    import subprocess
    texto = (ROOT / "SOS-Manutencao.ps1").read_text(encoding="utf-8")
    m = re.search(r"function Expandir-Selecao \{.*?\n\}", texto, re.S)
    assert m, "nao achei o corpo do helper"
    helper = m.group(0)
    prova = helper + "\n" + "\n".join([
        "$C = @{ E = 'x' }",
        "$V10 = @('1','2','3','4','5','6','7','8','9','10')",
        "'R1=' + ((Expandir-Selecao '2,3,10' $V10) -join ',')",
        "'R2=' + ((Expandir-Selecao '' $V10) -join ',')",
        "'R3=' + ((Expandir-Selecao 'TODOS' $V10) -join ',')",
        "'R4=' + ((Expandir-Selecao '1-3' $V10) -join ',')",
        "'R5=' + ((Expandir-Selecao '0' $V10) -join ',')",
        "'R6=' + ((Expandir-Selecao 'abc' $V10) -join ',')",
        "'R7=' + ((Expandir-Selecao '3,3,2' $V10) -join ',')",
        "$saida = foreach ($x in (Expandir-Selecao '1,3' $V10)) { switch ($x) { '1' { 'um' } '3' { 'tres' } } }",
        "'R8=' + ($saida -join ',')",
    ])
    r = subprocess.run(
        ["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", prova],
        capture_output=True, text=True, timeout=120,
    )
    assert r.returncode == 0, f"powershell falhou: {r.stderr[:500]}"
    linhas = [l for l in r.stdout.replace("\r", "").split("\n") if l.startswith("R")]
    obt = dict(l.split("=", 1) for l in linhas if "=" in l)
    assert obt.get("R1") == "2,3,10", f"lista simples quebrou: {obt}"
    assert obt.get("R2") == "1,2,3,4,5,6,7,8,9,10", f"ENTER=todas quebrou: {obt}"
    assert obt.get("R3") == "1,2,3,4,5,6,7,8,9,10", f"TODOS quebrou: {obt}"
    assert obt.get("R4") == "1,2,3", f"intervalo quebrou: {obt}"
    assert obt.get("R5") == "0", f"voltar quebrou: {obt}"
    assert obt.get("R6") == "", f"invalido devia dar vazio: {obt}"
    assert obt.get("R7") == "3,2", f"ordem/dedup quebrou: {obt}"
    assert obt.get("R8") == "um,tres", f"switch sobre array nao despachou: {obt}"
