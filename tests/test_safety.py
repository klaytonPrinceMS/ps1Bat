"""Trava as operacoes sensiveis: kill de explorer so no teste de monitor,
firewall-off e remocao de driver sempre com confirmacao."""
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def _linhas():
    return (ROOT / "SOS-Manutencao.ps1").read_text(encoding="utf-8").splitlines()


def _funcao_que_contem(linhas, n):
    for i in range(n, -1, -1):
        if linhas[i].startswith("function "):
            return linhas[i]
    return ""


def test_explorer_kill_so_no_teste_de_monitor():
    linhas = _linhas()
    alvos = [i for i, l in enumerate(linhas) if "Taskkill /f /im explorer.exe" in l]
    assert len(alvos) == 1, f"kill de explorer fora do esperado: {alvos}"
    assert "Menu-Stress" in _funcao_que_contem(linhas, alvos[0]), \
        "kill de explorer fora do Menu-Stress"


def test_firewall_off_com_confirmacao():
    linhas = _linhas()
    idx = next(i for i, l in enumerate(linhas)
               if "advfirewall set allprofiles state off" in l)
    janela = "\n".join(linhas[max(0, idx - 6):idx + 1])
    assert "Confirmar" in janela, "desligar firewall sem Confirmar por perto"


def test_driver_delete_com_confirmacao_e_desc():
    texto = (ROOT / "SOS-Manutencao.ps1").read_text(encoding="utf-8")
    assert "pnputil /delete-driver" in texto
    idx = texto.index("pnputil /delete-driver")
    janela = texto[max(0, idx - 600):idx]
    assert "CUIDADO" in janela and "Confirmar" in texto[idx - 200:idx + 100] or \
        "Run" in janela, "remocao de driver sem aviso/confirmacao"


def test_monitor_tem_instrucao_de_recuperacao():
    texto = (ROOT / "SOS-Manutencao.ps1").read_text(encoding="utf-8")
    assert "Executar nova tarefa > explorer.exe" in texto, \
        "teste de monitor sem instrucao de recuperacao da barra"


def test_confirmar_enter_executa_qualquer_tecla_cancela():
    texto = (ROOT / "SOS-Manutencao.ps1").read_text(encoding="utf-8")
    bloco = texto.split("function Confirmar", 1)[1].split("\n}", 1)[0]
    assert '($r -eq "")' in bloco, "Confirmar nao usa regra ENTER-vazio"
    assert "imatch" not in bloco and "[S/N]" not in bloco, \
        "Confirmar ainda usa padrao [S/N]"


def test_registro_lote_cobre_todos_os_ajustes():
    texto = (ROOT / "SOS-Manutencao.ps1").read_text(encoding="utf-8")
    menu = texto.split("function Menu-Registro", 1)[1].split("function Menu-Update", 1)[0]
    assert "APLICAR TODOS" in menu and "RESTAURAR TODOS" in menu
    aplica = menu.split("APLICAR TODOS", 1)[1].split('"16"', 1)[0]
    restaura = menu.split("RESTAURAR TODOS", 1)[1]
    chaves = ["VisualFXSetting", "MinAnimate", "DisallowShaking", "MenuShowDelay",
              "StartupDelayInMSec", "EnableSuperfetch", "SysMain",
              "PowerThrottlingOff", "ClearPageFileAtShutdown",
              "DisableSearchBoxSuggestions", "IsDynamicSearchBoxEnabled",
              "EnableBallooTips", "FocusAssist", "SilentInstalledAppsEnabled",
              "AllowTelemetry"]
    for c in chaves:
        assert c in aplica, f"{c} fora do aplicar-todos"
        assert c in restaura, f"{c} fora do restaurar-todos"
