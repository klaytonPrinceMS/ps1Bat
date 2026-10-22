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


def test_splash_so_na_tela_inicial():
    import re
    texto = (ROOT / "SOS-Manutencao.ps1").read_text(encoding="utf-8")
    assert "function Show-Splash" in texto
    chamadas = re.findall(r"(?m)^Show-Splash\s*(#|$)", texto)
    assert len(chamadas) == 1, "Show-Splash deve ser CHAMADA 1x na entrada (def nao conta)"
    marca = "VHVHHHAHHHHMMV"
    assert marca in texto, "arte da caveira sumiu"
    cab = texto.split("function Cab", 1)[1].split("\nfunction ", 1)[0]
    assert marca not in cab, "caveira nao pode aparecer no Cab (todos os menus)"


def test_menu_contexto_marca():
    texto = (ROOT / "SOS-Manutencao.ps1").read_text(encoding="utf-8")
    bloco = texto.split("function Menu-Contexto", 1)[1].split("\nfunction ", 1)[0]
    assert "T! SOS - " in bloco, "atalhos sem marca T! SOS"
    assert "KBP" in bloco, "entrada de contato KBP ausente"
    assert '"DTI - ' not in bloco, "restou rotulo DTI no menu de contexto"
