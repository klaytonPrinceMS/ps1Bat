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
         "Menu-Winget", "Menu-Utilidades", "Menu-Contexto"]


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
