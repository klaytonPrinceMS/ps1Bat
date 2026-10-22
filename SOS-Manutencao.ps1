#Requires -Version 5.1
<#
==============================================================================
  T! SOS SISTEMAS - FERRAMENTA TÉCNICA DE MANUTENÇÃO  v2.1.261021
  T! SOS Sistemas
  Autores: Anderson / Prince, K.B

  FUNCIONALIDADES:
    1.  Reparo e Integridade do Sistema  (DISM, SFC)
    2.  Discos e Armazenamento           (SMART, CHKDSK, Optimize, TRIM)
    3.  Drivers                          (PnPUtil)
    4.  Impressão e Spooler
    5.  Energia e Desempenho             (powercfg)
    6.  Memória RAM                      (mdsched, WinSAT, wmic)
    7.  Rede e DNS                       (TCP/IP reset, flush, tracert, IP estático)
    8.  Limpeza e Manutenção             (temp, cleanmgr, cache WU)
    9.  Segurança e Permissões           (ICACLS, takeown, USB, Firewall, ExecPolicy)
    10. Diagnóstico Avancado             (processos, eventos, WinSAT, hardware, wmic)
    11. Placa de Vídeo e Monitor         (dxdiag, DCOM, GPU reset)
    12. Identidade do Sistema            (renomear PC, usuario, IP estático)
    13. Testes de Stress                 (CPU multinucleo)
    14. Segurança da Informação          (auditoria, Defender, MRT, RDP)
    15. Ajustes de Desempenho            (Registro do Windows)
    16. Atualização do Windows           (PSWindowsUpdate)
    17. Winget                           (executa em contexto de usuario comum)
    18. Utilidades Rápidas               (ping, velocidade, msinfo32, msconfig)
    19. Menu de Contexto                 (clássico Win11, atalhos T! SOS)

  SEGURANÇA: Autentica com senha de administrador local ao iniciar.
             Todas as acoes ficam gravadas em log.
  WINGET:    Executa em contexto não-elevado (requisito do gerenciador).
  LOG:       %TEMP%\SOS_Manutencao.log


  v2.1.26.0612 #menu SEGURANÇA 14.1 Processos Suspeitos, agora realiza a verificação do executablepath e commandline se tiver em branco pode ser virus e mostra o que o cmd consegue visualizar e abre o virus total

==============================================================================
#>

# ── ENCODING ──────────────────────────────────────────────────────────────────
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding            = [System.Text.Encoding]::UTF8

# ── CONFIGURAÇÕES GLOBAIS ─────────────────────────────────────────────────────
$APP = @{
    Nome    = "T! SOS Sistemas - Manutenção Técnica  v2.1.261021"
    Org     = "T! SOS Sistemas"
    Log     = "$env:TEMP\SOS_Manutencao.log"
    MaxAuth = 3
}

$C = @{
    T = "Cyan"      # Titulo
    M = "Green"     # Menu / Sucesso
    E = "Red"       # Erro
    A = "Yellow"    # Alerta
    I = "White"     # Informação
    D = "DarkCyan"  # Descricao técnica
    H = "DarkGray"  # Cabeçalho secundario
    S = "Magenta"   # Status
}

$script:isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# ── FUNÇÕES BASE ──────────────────────────────────────────────────────────────
function L { Clear-Host }

function P {
    Write-Host "`n  Pressione Enter para continuar..." -ForegroundColor $C.I
    $null = Read-Host
}

function Log {
    param([string]$m, [string]$n = "INFO")
    "[$((Get-Date -f 'yyyy-MM-dd HH:mm:ss'))][$n] $m" | Out-File -Append -FilePath $APP.Log -Encoding UTF8
}

function Cab {
    param([string]$sub = "")
    L
    Write-Host ("=" * 64) -ForegroundColor $C.T
    Write-Host "  $($APP.Nome)" -ForegroundColor $C.T
    Write-Host ("=" * 64) -ForegroundColor $C.T
    if ($sub) {
        Write-Host "  >> $sub" -ForegroundColor $C.A
        Write-Host ("─" * 64) -ForegroundColor $C.H
    }
    Write-Host ""
}

function Desc {
    # Exibe descricao técnica com quebra de linha automatica
    param([string]$texto)
    Write-Host ""
    Write-Host "  .-- O QUE ESTE COMANDO FAZ: ----------------------------." -ForegroundColor $C.D
    $words = $texto -split '\s+'; $line = "  |  "
    foreach ($w in $words) {
        if ($line.Length + $w.Length -gt 60) {
            Write-Host ($line.PadRight(61) + "|") -ForegroundColor $C.D
            $line = "  |  $w "
        } else { $line += "$w " }
    }
    if ($line.Trim() -ne "|") { Write-Host ($line.PadRight(61) + "|") -ForegroundColor $C.D }
    Write-Host "  '--------------------------------------------------------'" -ForegroundColor $C.D
    Write-Host ""
}

function Confirmar {
    param([string]$descricao = "")
    if ($descricao) { Desc $descricao }
    $r = Read-Host "  ENTER = executar | qualquer outra tecla = cancelar"
    return ($r -eq "")
}

# ── TELA INICIAL (caveira do script clássico KlaytonBuenoPrince.bat) ─────────
# Exibida uma única vez na entrada pelo Show-Splash. Não usar no Cab.
$script:Splash = @'
                        ...----....
                    ..-:"''         ''"-..
                 .-'                      '-.
               .'              .     .       '.
             .'   .          .    .      .    .''.
           .'  .    .       .   .   .     .   . ..:.
         .' .   . . .      .   .   . ..  .   . ....::.
        ..   .   .      .  .    .     .  ..  . ....:IA.
      .:  .   .    .    .  .  .    .. .  .. .. ....:IA.
      .: .   .   ..   .    .     . . .. . ... ....:.:VHA.
      '..  .  .. .   .       .  . .. . .. . .....:.::IHHB.
     .:. .  . .  . .   .  .  . . . ...:.:... .......:HIHMM.
    .:.... .   . ."::"'.. .   .  . .:.:.:II;,. .. ..:IHIMMA
    ':.:..  ..::IHHHHHI::. . .  ...:.::::.,,,. . ....VIMMHM
   .:::I. .M Klayton .III::. .:...,:IIHHHHHHMMMHHL:. . VMMMM
  .:.:V.:IVH Bueno HMMMMM::..:" .:HIHHHHHHHHHHHHHMHHA. .VMMM.
  :..V.:IVHH Prince HHHHGB... . .:VPHHMHMHMFASHHHMHMMHI.:VMMI
  ::V..:VIHHHHHHMMMHHHHHH. .   .I":IIMHHRSGSEGBDHMMHHHAPI:WMM
  ::". .:.HHHHHHHHMMHHHHHI.  . .:..I:MHMHMHMMMMMJHMHMM:':H:WM
  :: . :.::IIHHHHHHMMHHHHV  .ABA.:.:IMHHMHMHMMHMHMMH:'. .IHWW
  '.  ..:..:.:IHHHHHMMHV" .AVMHMA.:.'VHMMMMHHHHHV:' .  :IHWV
   :.  .:...:".:.:TPP"   .AVMMHMMA.:. "VMMHHHP.:... .. :IVAI
  .:.   '... .:"'   .   ..HMMMHMMMA::. ."VHHI:::....  .:IHW'
  ...  .  . ..:IIPPIH: ..HMMMI.MMMV:I:.  .:ILLH:.. ...:I:IM
: .   .'"' .:.V". .. .  :HMMM:IMMMI::I. ..:HHIIPPHI::'.P:HM.
:.  .  .  .. ..:.. .    :AMMM IMMMM..:...:IV":T::I::.".:IHIMA
'V:.. .. . .. .  .  .   'VMMV..VMMV :....:V:.:..:....::IHHHMH
  "IHH:.II:.. .:. .  . . . " :HB"" . . ..PI:.::.:::..:IHHMMV"
   :IP""HHII:.  .  .    . . .'V:. . . ..:IH:.:.::IHIHHMMMMM"
   :V:. VIMA:I..  .     .  . .. . .  .:.I:I:..:IHHHHMMHHMMM
   :"VI:.VWMA::. .:      .   .. .:. ..:.I::.:IVHHHMMMHMMMMI
   :."VIIHHMMA:.  .   .   .:  .:.. . .:.II:(35)9-8713-5649 
   :..VIHIHMMMI...::.,:.,:!"I:!"I!"I!"V:AI:VAMMMMMMHMMMMMM'
   ':.:HIHIMHHA:tisossistemas@gmail.com"HPHIMMMMHHMHMMMMMV
   ':.:HIHIMHHA:"!!"I.:AXXXVVXXXXXXXA:."HPHIMMMMHHMHMMMMMV
     V:H:I:MA:W'I :AXXXIXII:IIIISSSSSSXXA.I.VMMMHMHMMMMMM
       'I::IVA ASSSSXSSSSBBSBMBSSSSSSBBMMMBS.VVMMHIMM'"'
        I:: VPAIMSSSSSSSSSBSSSMMBSSSBBMMMMXXI:MMHIMMI
       .I::. "H:XIIXBBMMMMMMMMMMMMMMMMMBXIXXMMPHIIMM'
       :::I.  ':XSS SEM O SIGILO XXIIIXXSMMAMI:.IMM
       :::I:.  .VSSSS TEMOS A MORTE SSSBMMB:MI:..:MM
       ::.I:.  ':"SSSSSSSISISSXIIXSSSSBMMB:AHI:..MMM.
       ::.I:. . ..:"BBSSSSSSSSSSSSBBBMMMB:AHHI::.HMMI
       :..::.  . ..::":BBBBBSSBBBMMMB:MMMMHHII::IHHMI
       ':.I:... ....:IHHHHHMMMMMMMMMMMMMMMHHIIIIHMMV"
         "V:. ..:...:.IHHHMMMMMMMMMMMMMMMMHHHMHHMHP'
          ':. .:::.:.::III::IHHHHMMMMMHMHMMHHHHM"
            "::....::.:::..:..::IIIIIHHHHMMMHHMV"
              "::.::.. .. .  ...:::IIHHMMMMHMV"
                "V::... . .I::IHHMMV"'
                  '"VHVHHHAHHHHMMV:"'
'@

# ── MOTOR DE EXECUÇÃO CENTRAL ─────────────────────────────────────────────────
function Run {
    [CmdletBinding()]
    param(
        [string]$Titulo,
        [string]$Descricao = "",
        [string[]]$Cmds,
        [switch]$PS,        # Usar PowerShell (padrão = CMD)
        [switch]$Win,       # Abrir em nova janela
        [switch]$SemAdmin   # Sem elevação - para Winget
    )

    if ($Descricao -and -not (Confirmar $Descricao)) {
        Write-Host "  Operação cancelada." -ForegroundColor $C.A; P; return
    }

    Write-Host "`n  >> $Titulo" -ForegroundColor $C.A
    Log $Titulo

    try {
        if ($SemAdmin) {
            # Winget: abre nova janela CMD independente (usuario comum)
            $bloco = ($Cmds -join " & ") + " & echo. & echo   Concluído! & pause"
            $tmpBat = [IO.Path]::GetTempFileName() -replace '\.tmp$', '.bat'
            # UTF-8 sem BOM + chcp 65001: preserva acentos (ç/ã/õ) no console
            [IO.File]::WriteAllText($tmpBat, "@echo off`r`nchcp 65001 > nul`r`n$bloco", (New-Object Text.UTF8Encoding $false))
            Start-Process cmd.exe -ArgumentList "/c `"$tmpBat`""
            Write-Host "  Janela Winget aberta. Interaja com ela." -ForegroundColor $C.D
            Start-Sleep 2
            P; return
        }

        if ($Win) {
            if ($PS) {
                # Codifica em Base64 para evitar problemas com aspas
                $bloco = ($Cmds -join "; ") + "; Write-Host '`n  Concluído! Pressione Enter para fechar...' -ForegroundColor Green; `$null = Read-Host"
                $b64   = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($bloco))
                Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -EncodedCommand $b64" -Wait
            } else {
                # Escreve bat temporario para evitar problemas com aspas aninhadas
                $bloco  = ($Cmds -join "`r`n") + "`r`necho.`r`necho   Concluído!`r`npause"
                $tmpBat = [IO.Path]::GetTempFileName() -replace '\.tmp$', '.bat'
                # UTF-8 sem BOM + chcp 65001: preserva acentos (ç/ã/õ) no console
                [IO.File]::WriteAllText($tmpBat, "@echo off`r`nchcp 65001 > nul`r`n$bloco", (New-Object Text.UTF8Encoding $false))
                Start-Process cmd.exe -ArgumentList "/c `"$tmpBat`"" -Wait
                Remove-Item $tmpBat -Force -ErrorAction SilentlyContinue
            }
        } else {
            # Execução inline no contexto atual
            if ($PS) { Invoke-Expression ($Cmds -join "; ") }
            else      { cmd.exe /c ($Cmds -join " & ") }
        }
        Log "OK: $Titulo"
    }
    catch {
        Write-Host "  ERRO: $($_.Exception.Message)" -ForegroundColor $C.E
        Log "ERRO em '$Titulo': $_" "ERRO"
    }
    P
}

# ── AUTENTICAÇÃO ──────────────────────────────────────────────────────────────
function Validar-Credencial {
    param([string]$usr, [securestring]$pwd)
    try {
        Add-Type -AssemblyName System.DirectoryServices.AccountManagement
        $ctx = New-Object System.DirectoryServices.AccountManagement.PrincipalContext(
            [System.DirectoryServices.AccountManagement.ContextType]::Machine)
        $ptr  = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($pwd)
        $txt  = [Runtime.InteropServices.Marshal]::PtrToStringAuto($ptr)
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
        return $ctx.ValidateCredentials($usr, $txt)
    } catch { return $false }
}

function Get-StatusAdmin {
    # Retorna $true se o usuario e membro do grupo local de administradores,
    # $false se não e, e $null se não foi possível verificar.
    # Usa o SID do grupo (S-1-5-32-544), entao funciona em Windows pt-BR e en-US.
    param([string]$usuario)
    try {
        $grupo = Get-LocalGroup -SID 'S-1-5-32-544' -ErrorAction Stop
        $membros = Get-LocalGroupMember -Group $grupo.Name -ErrorAction Stop
        foreach ($m in $membros) {
            if ((($m.Name -split '\\')[-1]) -ieq $usuario) { return $true }
        }
        return $false
    } catch { return $null }
}

function Autenticar {
    Cab
    Write-Host $script:Splash -ForegroundColor Red
    Write-Host ""
    $agora = Get-Date
    Write-Host "  Data: $($agora.ToString('dd/MM/yyyy'))  Hora: $($agora.ToString('HH:mm'))" -ForegroundColor $C.H
    Write-Host "  !!! AUTENTICAÇÃO DE SEGURANÇA OBRIGATÓRIA !!!" -ForegroundColor $C.A
    Write-Host ""
    Write-Host "  Por segurança, confirme a senha de administrador deste" -ForegroundColor $C.I
    Write-Host "  computador antes de acessar as ferramentas do T! SOS Sistemas." -ForegroundColor $C.I
    Write-Host "  Todas as acoes ficam registradas em log de auditoria." -ForegroundColor $C.H
    Write-Host ""

    $def = $env:USERNAME
    $stDef = Get-StatusAdmin $def
    if ($stDef -eq $true) {
        Write-Host "  Sessão atual: '$def' (conta ADMINISTRADORA neste PC)." -ForegroundColor $C.M
    } elseif ($stDef -eq $false) {
        Write-Host "  Sessão atual: '$def' (NÃO e administradora neste PC)." -ForegroundColor $C.E
        Write-Host "  Informe um usuario que seja administrador para continuar." -ForegroundColor $C.A
    }
    Write-Host "  Pressione ENTER para autenticar como '$def'." -ForegroundColor $C.I
    Write-Host "  Para usar outra conta, digite o nome de login dela." -ForegroundColor $C.I
    Write-Host ""

    for ($i = 1; $i -le $APP.MaxAuth; $i++) {
        Write-Host "  Tentativa $i de $($APP.MaxAuth):" -ForegroundColor $C.I
        $usr = Read-Host "  Usuario [Enter = $def]"
        if ([string]::IsNullOrWhiteSpace($usr)) { $usr = $def }

        $st = Get-StatusAdmin $usr
        if ($st -eq $true) {
            Write-Host "  Conta '$usr' confirmada como ADMINISTRADORA." -ForegroundColor $C.M
        } elseif ($st -eq $false) {
            Write-Host "  [ERRO] '$usr' NÃO e administrador local. Tente outro usuario." -ForegroundColor $C.E
            Log "Tentativa com usuario não-administrador - $usr (tentativa $i)" "AVISO"
            Write-Host ""
            continue
        }

        $pwd = Read-Host "  Senha de administrador para '$usr'" -AsSecureString

        if (Validar-Credencial $usr $pwd) {
            Write-Host "`n  [OK] Autenticado com sucesso! Bem-vindo, $usr." -ForegroundColor $C.M
            Log "Autenticação bem-sucedida - Usuario: $usr"
            Start-Sleep 1; return
        }

        Write-Host "  [ERRO] Credenciais incorretas." -ForegroundColor $C.E
        Log "Falha de autenticação - $usr (tentativa $i)" "AVISO"
        Write-Host ""
    }

    Write-Host "  Limite de tentativas atingido. Encerrando por segurança." -ForegroundColor $C.E
    Log "Acesso bloqueado após $($APP.MaxAuth) tentativas." "ERRO"
    Start-Sleep 2; exit 1
}

function Fixar-Janela {
    # Dimensiona a janela em PIXELS (94% da largura e 90% da altura uteis do
    # monitor onde a janela esta), convertendo para colunas/linhas pelo tamanho
    # da fonte atual do console. Assim cabe em tela pequena ou vertical.
    # Trava a largura (sem rolagem horizontal) e desabilita os botoes
    # maximizar/minimizar. Roda primeiro na entrada (vale tambem apos a
    # auto-elevacao, que reabre o script em nova janela).
    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
        Add-Type -TypeDefinition '
using System;
using System.Runtime.InteropServices;
namespace SOS {
  [StructLayout(LayoutKind.Sequential)]
  public struct COORD { public short X; public short Y; }
  [StructLayout(LayoutKind.Sequential, CharSet=CharSet.Unicode)]
  public struct CONSOLE_FONT_INFOEX {
    public uint cbSize; public uint nFont; public COORD dwFontSize;
    public int FontFamily; public int FontWeight;
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst=32)] public string FaceName;
  }
  public static class JanelaFixa {
    [DllImport("user32.dll")] public static extern IntPtr GetConsoleWindow();
    [DllImport("user32.dll")] public static extern int GetWindowLong(IntPtr hWnd, int nIndex);
    [DllImport("user32.dll")] public static extern int SetWindowLong(IntPtr hWnd, int nIndex, int dwNewLong);
    [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);
    [DllImport("kernel32.dll", SetLastError=true)] public static extern IntPtr GetStdHandle(int nStdHandle);
    [DllImport("kernel32.dll", SetLastError=true)] public static extern bool GetCurrentConsoleFontEx(IntPtr hConsoleOutput, bool bMaximumWindow, ref CONSOLE_FONT_INFOEX info);
  }
}' -ErrorAction Stop
        $hwnd = [SOS.JanelaFixa]::GetConsoleWindow()
        if ($hwnd -eq [IntPtr]::Zero) { return }
        $tela = [Windows.Forms.Screen]::FromHandle($hwnd)
        if (-not $tela) { $tela = [Windows.Forms.Screen]::PrimaryScreen }
        $area = $tela.WorkingArea
        $info = New-Object SOS.CONSOLE_FONT_INFOEX
        $info.cbSize = [Runtime.InteropServices.Marshal]::SizeOf($info)
        if (-not [SOS.JanelaFixa]::GetCurrentConsoleFontEx([SOS.JanelaFixa]::GetStdHandle(-11), $false, [ref]$info)) { return }
        $fx = [Math]::Max($info.dwFontSize.X, 4)
        $fy = [Math]::Max($info.dwFontSize.Y, 4)
        $cols = [Math]::Floor($area.Width * 0.94 / $fx)
        $rows = [Math]::Floor($area.Height * 0.90 / $fy)
        $cols = [Math]::Min(160, [Math]::Max(80, $cols))
        $rows = [Math]::Min(70, [Math]::Max(30, $rows))
        $raw = $Host.UI.RawUI
        $buf = $raw.BufferSize
        $buf.Width = $cols; $buf.Height = $rows
        $raw.BufferSize = $buf
        $jan = $raw.WindowSize
        $jan.Width = $cols; $jan.Height = $rows
        $raw.WindowSize = $jan
        $estilo = [SOS.JanelaFixa]::GetWindowLong($hwnd, -16)
        $semBotoes = $estilo -band (-bnot (0x00010000 -bor 0x00020000))
        [void][SOS.JanelaFixa]::SetWindowLong($hwnd, -16, $semBotoes)
        [void][SOS.JanelaFixa]::SetWindowPos($hwnd, [IntPtr]::Zero, 0, 0, 0, 0, 0x27)
    } catch { }
}

function Garantir-Admin {
    if (-not $script:isAdmin) {
        Write-Host "  Solicitando elevação de privilégios (UAC)..." -ForegroundColor $C.A
        try {
            Start-Process powershell.exe -Verb RunAs -ArgumentList ('-NoProfile -ExecutionPolicy Bypass -File "{0}"' -f $PSCommandPath)
            exit
        } catch {
            Write-Host "  ERRO: Elevação recusada. Execute como Administrador." -ForegroundColor $C.E
            Start-Sleep 3; exit 1
        }
    }
}

# =============================================================================
# MENU 1: REPARO E INTEGRIDADE DO SISTEMA
# =============================================================================
function Menu-Reparo {
    do {
        Cab "1. REPARO E INTEGRIDADE DO SISTEMA"
        Write-Host "  Use quando: sistema instavel, lentidao inexplicavel, erros de boot." -ForegroundColor $C.H
        Write-Host ""
        Write-Host "  1. DISM - Verificar status da imagem (rápido, sem reparar)" -ForegroundColor $C.M
        Write-Host "  2. DISM - Reparar imagem do Windows (usa Windows Update)" -ForegroundColor $C.M
        Write-Host "  3. DISM - Limpar componentes substituidos (libera espaço)" -ForegroundColor $C.M
        Write-Host "  4. SFC  - Verificar e reparar arquivos do sistema" -ForegroundColor $C.M
        Write-Host "  5. SFC + DISM sequencial (reparo completo - recomendado)" -ForegroundColor $C.A
        Write-Host "  5. Teste" -ForegroundColor $C.M
        Write-Host "  0. Voltar" -ForegroundColor $C.I
        switch (Read-Host "`n  Opção") {
            "1" { Run "DISM: Verificando status da imagem..." "Verifica se a imagem do Windows tem problemas, SEM fazer reparos. Resultado: Healthy = OK; Repairable = execute a opção 2; Non repairable = reinstalacao necessaria." @("DISM /Online /Cleanup-Image /CheckHealth") -Win }
            "2" { Run "DISM: Reparando imagem..." "Repara a imagem do Windows baixando arquivos integros do Windows Update. Demora 10-20 min e requer internet. Use quando SFC ou CheckHealth indicarem problemas." @("DISM /Online /Cleanup-Image /RestoreHealth") -Win }
            "3" { Run "DISM: Limpando componentes obsoletos..." "Remove versões antigas de pacotes ja substituidos por atualizações. Libera espaço no disco do sistema sem afetar o funcionamento." @("DISM /Online /Cleanup-Image /StartComponentCleanup") -Win }
            "4" { Run "SFC: Verificando e reparando arquivos do sistema..." "Varre todos os arquivos protegidos do Windows e substitui versões corrompidas por copias do cache local. Não requer internet. Demora alguns minutos." @("sfc /scannow") -Win }
            "5" { Run "DISM + SFC (reparacao completa)..." "Sequência recomendada: DISM repara a imagem usando Windows Update, depois SFC repara os arquivos do sistema com a imagem restaurada. Total: 20-40 min. Requer internet." @("DISM /Online /Cleanup-Image /RestoreHealth", "sfc /scannow") -Win }
            "0" { return }
            default { Write-Host "  Opção inválida." -ForegroundColor $C.E; Start-Sleep 1 }
        }
    } while ($true)
}

# =============================================================================
# MENU 2: DISCOS E ARMAZENAMENTO
# =============================================================================
function Menu-Discos {
    do {
        Cab "2. DISCOS E ARMAZENAMENTO"
        Write-Host "  1. Status SMART - Previsão de falha (PredictFailure)" -ForegroundColor $C.M
        Write-Host "  2. Contadores de confiabilidade do disco" -ForegroundColor $C.M
        Write-Host "  3. Informações dos discos físicos (saúde, status)" -ForegroundColor $C.M
        Write-Host "  4. Status WMIC dos discos (modelo, serial, tamanho)" -ForegroundColor $C.M
        Write-Host "  5. CHKDSK - Verificar e corrigir erros no disco C:" -ForegroundColor $C.M
        Write-Host "  6. Otimizar todos os discos (detecta SSD/HDD auto)" -ForegroundColor $C.M
        Write-Host "  7. Verificar se TRIM esta ativo (SSDs)" -ForegroundColor $C.M
        Write-Host "  8. Ativar TRIM (SSDs)" -ForegroundColor $C.M
        Write-Host "  9. Desfragmentar disco especifico (apenas HDD)" -ForegroundColor $C.M
        Write-Host " 10. Informações do sistema de arquivos NTFS" -ForegroundColor $C.M
        Write-Host " 11. Espaço livre em todos os discos lógicos" -ForegroundColor $C.M
        Write-Host " 12. CHKDSK rápido - somente leitura (sem reiniciar)" -ForegroundColor $C.M
        Write-Host "  0. Voltar" -ForegroundColor $C.I
        switch (Read-Host "`n  Opção") {
            "1"  { Run "Verificando SMART (previsão de falha)..." "Lê os dados S.M.A.R.T. dos discos. Se PredictFailure = True, o disco esta prestes a falhar: faça backup imediatamente e substitua o hardware. Valor esperado: PredictFailure = False." @("Get-CimInstance -ClassName MSStorageDriver_FailurePredictStatus -Namespace root\wmi | Select-Object InstanceName, PredictFailure, Reason | Format-Table -AutoSize") -PS -Win }
            "2"  { Run "Contadores de confiabilidade dos discos..." "Exibe contadores de erros de leitura, escrita e desgaste de cada disco. Valores ideais são próximos de zero. WearLevel alto em SSDs indica desgaste acumulado." @("Get-PhysicalDisk | Get-StorageReliabilityCounter | Format-List *") -PS -Win }
            "3"  { Run "Informações dos discos físicos..." "Lista cada disco com seu status de saúde e status operacional. HealthStatus = Healthy e o esperado. Warning ou Unhealthy requerem atenção imediata." @("Get-PhysicalDisk | Select-Object DeviceId, FriendlyName, HealthStatus, OperationalStatus | Format-Table -AutoSize") -PS -Win }
            "4"  { Run "Status WMIC dos discos (modelo, serial)..." "Consulta o WMI para obter status, modelo, número de série e tamanho de cada disco físico instalado. Útil para inventário de hardware." @("wmic diskdrive get status,model,serialnumber,size") -Win }
            "5"  { Run "CHKDSK C: (agendado para próximo boot)..." "Agenda verificação do disco C: para a próxima reinicialização. /f corrige erros, /r localiza setores defeituosos, /x força desmontagem. O PC reiniciará uma vez para executar o teste." @("chkdsk C: /f /r /x") -Win }
            "6"  { Run "Otimizando todos os discos automaticamente..." "Detecta automaticamente se cada disco e SSD (executa ReTrim) ou HDD (executa Defrag). SSDs não devem ser desfragmentados, pois isso reduz a vida útil." @('Get-Volume | Where-Object { $_.DriveType -eq "Fixed" -and $_.DriveLetter } | ForEach-Object { $l = $_.DriveLetter; Write-Host "Otimizando ${l}:..." -ForegroundColor Cyan; try { $disk = Get-PhysicalDisk | Where-Object DeviceId -eq ((Get-Partition -DriveLetter $l -EA SilentlyContinue | Get-Disk -EA SilentlyContinue).Number); if ($disk.MediaType -eq "SSD") { Optimize-Volume -DriveLetter $l -ReTrim -Verbose } else { Optimize-Volume -DriveLetter $l -Defrag -Verbose } } catch { Write-Host "Erro em ${l}: $_" -ForegroundColor Red } }') -PS -Win }
            "7"  { Run "Verificando status do TRIM..." "Consulta a configuração de TRIM. DisableDeleteNotify = 0 significa TRIM ATIVO (correto para SSDs). DisableDeleteNotify = 1 significa TRIM DESATIVADO, use a opção 8 para ativar." @("fsutil behavior query DisableDeleteNotify") -Win }
            "8"  { Run "Ativando TRIM nos SSDs..." "Ativa o TRIM, que permite ao Windows informar ao SSD quais blocos foram apagados, mantendo a performance ao longo do tempo. Essencial para a saúde de todo SSD." @("fsutil behavior set DisableDeleteNotify 0") -Win }
            "9"  {
                $drv = Read-Host "  Letra da unidade a desfragmentar (ex: D)"
                if ($drv -match '^[A-Za-z]$') {
                    Run "Desfragmentando ${drv}:..." "Reorganiza os arquivos do disco para que fiquem em blocos contiguos, melhorando o tempo de acesso. Use APENAS em HDs mecanicos (HDD). NUNCA use em SSDs." @("Optimize-Volume -DriveLetter $drv -Defrag -Verbose") -PS -Win
                } else { Write-Host "  Letra inválida." -ForegroundColor $C.E; P }
            }
            "10" { Run "Informações NTFS do disco C:..." "Exibe parâmetros técnicos do sistema de arquivos NTFS: número de série do volume, bytes por setor, bytes por cluster, total de clusters, MFT e configuração de journaling." @("fsutil fsinfo ntfsinfo C:") -Win }
            "11" {
                Write-Host "`n  Espaço em disco:" -ForegroundColor $C.A
                Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used } |
                    Select-Object Name,
                        @{N="Total(GB)";  E={[math]::Round(($_.Used+$_.Free)/1GB,1)}},
                        @{N="Livre(GB)";  E={[math]::Round($_.Free/1GB,1)}},
                        @{N="Usado(GB)";  E={[math]::Round($_.Used/1GB,1)}},
                        @{N="Livre(%)";   E={[math]::Round($_.Free/($_.Used+$_.Free)*100,0)}} |
                    Format-Table -AutoSize
                P
            }
            "12" { Run "CHKDSK C: (somente leitura)..." "Executa o CHKDSK em modo leitura: verifica e RELATA erros sem corrigir nada e sem precisar reiniciar. Rápido e seguro para um primeiro diagnóstico; se apontar erros, use a opção 5 (correção, exige reboot)." @("chkdsk C:") -Win }
            "0"  { return }
            default { Write-Host "  Opção inválida." -ForegroundColor $C.E; Start-Sleep 1 }
        }
    } while ($true)
}

# =============================================================================
# MENU 3: DRIVERS (PnPUtil)
# =============================================================================
function Menu-Drivers {
    do {
        Cab "3. GESTAO DE DRIVERS (PnPUtil)"
        Write-Host "  1. Listar todos os drivers instalados" -ForegroundColor $C.M
        Write-Host "  2. Listar dispositivos com problemas (erro != 0)" -ForegroundColor $C.M
        Write-Host "  3. Listar monitores/displays conectados" -ForegroundColor $C.M
        Write-Host "  4. Escanear dispositivos PnP (força detecção)" -ForegroundColor $C.M
        Write-Host "  5. Adicionar e instalar driver (informar .inf)" -ForegroundColor $C.M
        Write-Host "  6. Remover driver (informar oemXX.inf)" -ForegroundColor $C.M
        Write-Host "  0. Voltar" -ForegroundColor $C.I
        switch (Read-Host "`n  Opção") {
            "1" { Run "Listando drivers instalados..." "Exibe todos os pacotes de drivers instalados no repositorio do sistema, com nome do driver, versão, data e fornecedor. Útil para auditar ou localizar drivers a remover." @("pnputil /enum-drivers") -Win }
            "2" { Run "Dispositivos com problemas..." "Lista dispositivos cujo código de erro no WMI e diferente de zero. Código 0 = OK. Qualquer outro valor indica problema: driver corrompido, conflito de recursos ou hardware com defeito." @('Get-WmiObject -Class Win32_PnPEntity | Where-Object { $_.ConfigManagerErrorCode -ne 0 } | Select-Object Name, DeviceID, ConfigManagerErrorCode | Format-Table -AutoSize') -PS -Win }
            "3" { Run "Monitores e displays conectados..." "Lista todos os dispositivos de exibição reconhecidos pelo sistema via Plug and Play. Use quando um monitor não esta sendo detectado." @("pnputil /enum-devices /class Display") -Win }
            "4" { Run "Escaneando dispositivos PnP..." "Força o Windows a reescanear o barramento PnP em busca de novos dispositivos. Útil quando um dispositivo recém-conectado não aparece automaticamente." @("pnputil /scan-devices") -Win }
            "5" {
                $inf = Read-Host "  Caminho completo do arquivo .inf"
                if ($inf -and (Test-Path $inf)) {
                    Run "Adicionando driver..." "Adiciona o pacote de driver ao repositorio do Windows e instala nos dispositivos compativeis. Use apenas drivers confiaveis e certificados." @("pnputil /add-driver `"$inf`" /install") -Win
                } else { Write-Host "  Arquivo não encontrado." -ForegroundColor $C.E; P }
            }
            "6" {
                $oem = Read-Host "  Nome do driver (ex: oem15.inf)"
                if ($oem) {
                    Run "Removendo driver $oem..." "Remove o pacote de driver do repositorio. /uninstall remove dos dispositivos que o usam, /force remove mesmo se em uso. CUIDADO: confirme o driver correto antes de remover." @("pnputil /delete-driver $oem /uninstall /force") -Win
                } else { P }
            }
            "0" { return }
            default { Write-Host "  Opção inválida." -ForegroundColor $C.E; Start-Sleep 1 }
        }
    } while ($true)
}

# =============================================================================
# MENU 4: IMPRESSÃO E SPOOLER
# =============================================================================
function Menu-Impressao {
    do {
        Cab "4. IMPRESSÃO E SPOOLER"
        Write-Host "  1. Reset completo do Spooler (para erros de impressão)" -ForegroundColor $C.M
        Write-Host "  2. Abrir gerenciador de drivers de impressora" -ForegroundColor $C.M
        Write-Host "  3. Listar impressoras instaladas" -ForegroundColor $C.M
        Write-Host "  4. Listar impressoras com porta de rede (IP)" -ForegroundColor $C.M
        Write-Host "  5. Renomear impressora" -ForegroundColor $C.M
        Write-Host "  6. Alterar porta IP de uma impressora" -ForegroundColor $C.M
        Write-Host "  7. Remover impressora" -ForegroundColor $C.M
        Write-Host "  8. Limpar fila de impressão (trabalhos travados)" -ForegroundColor $C.M
        Write-Host "  9. Abrir painel de impressoras" -ForegroundColor $C.M
        Write-Host "  0. Voltar" -ForegroundColor $C.I
        switch (Read-Host "`n  Opção") {
            "1" { Run "Reset completo do Spooler..." "Para o servico de spooler, apaga todos os trabalhos pendentes da fila e reinicia o servico. Resolve a maioria dos problemas de impressão travada, filas que não esvaziam e spooler corrompido." @("net stop spooler", "del /Q /F /S `"%systemroot%\System32\Spool\Printers\*.*`"", "net start spooler") -Win }
            "2" { Run "Abrindo gerenciador de drivers de impressora..." "Abre a interface printui para gerenciar e remover pacotes de drivers de impressora do sistema. Use quando um driver corrompido impede o funcionamento correto." @("printui.exe /s /t2") -Win }
            "3" {
                Write-Host "`n  Impressoras instaladas:" -ForegroundColor $C.A
                Get-Printer | Select-Object Name, DriverName, PortName, PrinterStatus | Format-Table -AutoSize
                P
            }
            "4" { Run "Listando impressoras com portas..." "Exibe nome e porta (IP ou porta local) de cada impressora. Essencial para verificar qual IP esta configurado em cada impressora de rede." @("Get-Printer | Select-Object Name, PortName, DriverName | Format-Table -AutoSize") -PS -Win }
            "5" {
                $atual = Read-Host "  Nome atual da impressora"
                $novo  = Read-Host "  Novo nome"
                if ($atual -and $novo) {
                    Run "Renomeando impressora..." "Altera o nome de exibição da impressora no sistema. O driver e a configuração são preservados. Útil para padronizar a nomenclatura das impressoras na rede." @("Rename-Printer -Name '$atual' -NewName '$novo'") -PS -Win
                } else { P }
            }
            "6" {
                $nome  = Read-Host "  Nome da impressora"
                $porta = Read-Host "  Nova porta/IP (ex: 172.16.1.200)"
                if ($nome -and $porta) {
                    Run "Alterando porta da impressora..." "Redireciona a impressora para o novo endereço IP ou porta local. Use quando o IP da impressora na rede for alterado." @("Set-Printer -Name '$nome' -PortName '$porta'") -PS -Win
                } else { P }
            }
            "7" {
                $nome = Read-Host "  Nome da impressora a remover"
                if ($nome -and (Confirmar "ATENÇÃO: Remove permanentemente a impressora '$nome'. Confirme apenas se tem certeza.")) {
                    Run "Removendo impressora $nome..." "" @("Remove-Printer -Name '$nome'") -PS -Win
                } else { P }
            }
            "8" { Run "Limpando fila de impressão..." "Remove todos os arquivos de trabalhos de impressão pendentes da pasta Spool. Use quando trabalhos travados não desaparecem mesmo após cancelar pela fila." @("del /Q /F /S `"$env:SystemRoot\System32\Spool\Printers\*.*`"") -Win }
            "9" { Start-Process control.exe -ArgumentList "printers"; Write-Host "  Abrindo painel de impressoras..." -ForegroundColor $C.A; P }
            "0" { return }
            default { Write-Host "  Opção inválida." -ForegroundColor $C.E; Start-Sleep 1 }
        }
    } while ($true)
}

# =============================================================================
# MENU 5: ENERGIA E DESEMPENHO
# =============================================================================
function Menu-Energia {
    do {
        Cab "5. ENERGIA E DESEMPENHO"
        Write-Host "  1. Relatório de bateria (laptops)" -ForegroundColor $C.M
        Write-Host "  2. Relatório de eficiência energetica (60s)" -ForegroundColor $C.M
        Write-Host "  3. Relatório de consumo em sleep/soneca" -ForegroundColor $C.M
        Write-Host "  4. Listar estados de energia suportados" -ForegroundColor $C.M
        Write-Host "  5. Desativar hibernação (libera espaço no disco)" -ForegroundColor $C.M
        Write-Host "  6. Ativar plano Alto Desempenho" -ForegroundColor $C.M
        Write-Host "  7. Ativar plano Ultimate Performance (mais agressivo)" -ForegroundColor $C.M
        Write-Host "  8. Listar planos de energia disponíveis" -ForegroundColor $C.M
        Write-Host "  0. Voltar" -ForegroundColor $C.I
        switch (Read-Host "`n  Opção") {
            "1" { Run "Gerando relatório de bateria..." "Gera relatório HTML com histórico da bateria: capacidade original vs atual, ciclos de carga e estimativas de duracao. O relatório abre automaticamente no navegador." @("powercfg /batteryreport /output `"$env:TEMP\battery_report.html`"", "start `"$env:TEMP\battery_report.html`"") -Win }
            "2" { Run "Analisando eficiência energetica (60s)..." "Monitora o sistema por 60 segundos e gera relatório HTML com problemas de eficiência detectados: dispositivos impedindo o sleep, configurações incorretas e processos mal configurados." @("powercfg /energy /output `"$env:TEMP\energy_report.html`"", "start `"$env:TEMP\energy_report.html`"") -Win }
            "3" { Run "Gerando relatório de sleep/soneca..." "Analisa o histórico de consumo durante os periodos de hibernação e sleep. Identifica o que acorda o computador indevidamente ou impede a entrada em modo de economia." @("powercfg /sleepstudy /output `"$env:TEMP\sleep_report.html`"", "start `"$env:TEMP\sleep_report.html`"") -Win }
            "4" { Run "Verificando estados de energia disponíveis..." "Lista os estados de energia suportados pelo hardware: S0 (ligado), S3 (sleep), S4 (hiberna), S5 (desligado). Indica quais estao habilitados nesta máquina." @("powercfg /a") -Win }
            "5" { Run "Desativando hibernação..." "Remove o arquivo hiberfil.sys do disco, liberando espaço equivalente ao total de RAM. Recomendado em desktops e em SSDs com espaço crítico. Sem hibernação, o PC desliga normalmente." @("powercfg -h off") -Win }
            "6" { Run "Ativando plano Alto Desempenho..." "Define o plano de energia de alto desempenho, mantendo o processador em velocidade máxima e desativando reducoes de clock automaticas. Melhora a responsividade geral." @("powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c") -Win }
            "7" { Run "Ativando Ultimate Performance..." "Cria e ativa o plano Ultimate Performance (oculto por padrão no Windows 10). Elimina microtolerancias de energia do processador. Indicado para estacos de trabalho com demanda máxima." @("powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61", "powercfg /setactive e9a42b02-d5df-448d-aa00-03f14749eb61") -Win }
            "8" { Run "Listando planos de energia..." "Exibe todos os planos de energia instalados com seus GUIDs e indica qual esta ativo no momento." @("powercfg /list") -Win }
            "0" { return }
            default { Write-Host "  Opção inválida." -ForegroundColor $C.E; Start-Sleep 1 }
        }
    } while ($true)
}

# =============================================================================
# MENU 6: MEMÓRIA RAM
# =============================================================================
function Menu-Memoria {
    do {
        Cab "6. MEMÓRIA RAM"
        Write-Host "  1. Agendar diagnóstico de memória (executa no próximo boot)" -ForegroundColor $C.M
        Write-Host "  2. Informações dos módulos de RAM (capacidade, velocidade)" -ForegroundColor $C.M
        Write-Host "  3. Teste de desempenho da RAM (WinSAT mem)" -ForegroundColor $C.M
        Write-Host "  4. Total de RAM instalada e uso atual" -ForegroundColor $C.M
        Write-Host "  5. Abrir configuração de memória virtual (pagefile)" -ForegroundColor $C.M
        Write-Host "  0. Voltar" -ForegroundColor $C.I
        switch (Read-Host "`n  Opção") {
            "1" { Run "Agendando diagnóstico de memória..." "Agenda o Diagnóstico de Memória do Windows (mdsched.exe) para ser executado ANTES do sistema carregar no próximo boot. Detecta erros nos pentes de RAM. Útil quando ha BSOD frequentes." @("mdsched.exe") -Win }
            "2" { Run "Informações dos módulos de RAM..." "Exibe capacidade, velocidade em MHz, fabricante e localização (slot) de cada módulo de memória instalado. Útil para identificar módulos com defeito ou verificar se os slots estao corretos." @("wmic memorychip get capacity,speed,devicelocator,manufacturer,partnumber") -Win }
            "3" { Run "Teste de desempenho da RAM (WinSAT)..." "Executa o benchmark de memória RAM do Windows Assessment Tool e exibe a pontuação de desempenho. Pode levar alguns minutos." @("winsat mem") -Win }
            "4" {
                $ram   = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
                $livre = [math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1MB, 2)
                Write-Host "`n  RAM Total:      $ram GB" -ForegroundColor $C.I
                Write-Host "  RAM Livre:      $livre GB" -ForegroundColor $C.I
                Write-Host "  RAM em Uso:     $([math]::Round($ram - $livre, 2)) GB" -ForegroundColor $C.I
                Write-Host ""
                Get-CimInstance Win32_PhysicalMemory |
                    Select-Object DeviceLocator,
                        @{N="Capacidade(GB)"; E={[math]::Round($_.Capacity/1GB,1)}},
                        @{N="Velocidade(MHz)"; E={$_.Speed}},
                        Manufacturer | Format-Table -AutoSize
                P
            }
            "5" { Start-Process sysdm.cpl; Write-Host "  Abrindo Propriedades do Sistema (aba Avancado > Desempenho)..." -ForegroundColor $C.A; P }
            "0" { return }
            default { Write-Host "  Opção inválida." -ForegroundColor $C.E; Start-Sleep 1 }
        }
    } while ($true)
}

# =============================================================================
# MENU 7: REDE E DNS
# =============================================================================
function Menu-Rede {
    do {
        Cab "7. REDE E DNS"
        Write-Host "  1. Reset pilha TCP/IP (resolve a maioria dos problemas)" -ForegroundColor $C.M
        Write-Host "  2. Reset Winsock (catalogo de rede corrompido)" -ForegroundColor $C.M
        Write-Host "  3. Flush DNS (limpar cache de resolucao DNS)" -ForegroundColor $C.M
        Write-Host "  4. Exibir configuração atual de rede (ipconfig /all)" -ForegroundColor $C.M
        Write-Host "  5. Estatisticas NetBIOS (nbtstat -n)" -ForegroundColor $C.M
        Write-Host "  6. Conexões ativas e portas em escuta (netstat)" -ForegroundColor $C.M
        Write-Host "  7. Traceroute (rastrear rota até destino)" -ForegroundColor $C.M
        Write-Host "  8. Endereços MAC das interfaces de rede" -ForegroundColor $C.M
        Write-Host "  9. Configurar IP estático (Ethernet)" -ForegroundColor $C.M
        Write-Host " 10. Abrir gerenciador de adaptadores de rede" -ForegroundColor $C.M
        Write-Host "  0. Voltar" -ForegroundColor $C.I
        switch (Read-Host "`n  Opção") {
            "1"  { Run "Resetando pilha TCP/IP..." "Reseta toda a pilha de rede TCP/IP ao estado padrão de instalação. Resolve problemas de conectividade por configurações corrompidas. REQUER REINICIALIZAÇÃO para ter efeito total." @("netsh int ip reset", "netsh int ipv4 reset", "netsh int ipv6 reset") -Win }
            "2"  { Run "Resetando Winsock..." "Reseta o catalogo Winsock ao estado padrão. Resolve casos onde programas não conseguem acessar a rede mesmo com conexão ativa (ex: navegador sem internet mesmo com ping funcionando). REQUER REINICIALIZAÇÃO." @("netsh winsock reset catalog") -Win }
            "3"  { Run "Limpando cache DNS..." "Remove todas as entradas DNS em cache no computador local, forcando nova resolucao no servidor DNS para cada domínio. Resolve problemas de acesso a sites após mudanca de IP ou DNS no servidor." @("ipconfig /flushdns", "ipconfig /registerdns") -Win }
            "4"  { Run "Exibindo configuração de rede..." "Exibe IP, mascara, gateway, DNS, MAC e status de todas as interfaces de rede. Use para verificar se o IP correto foi atribuido e se o DNS esta apontando para o servidor certo." @("ipconfig /all") -Win }
            "5"  { Run "Estatisticas NetBIOS local..." "Exibe a tabela de nomes NetBIOS registrados nesta máquina na rede local. Útil para diagnosticar problemas de compartilhamento de arquivos e resolucao de nomes." @("nbtstat -n") -Win }
            "6"  { Run "Conexões ativas e portas em escuta..." "Lista todas as conexões de rede ativas, portas abertas e o PID do processo responsavel. Use para identificar conexões suspeitas, verificar portas em uso ou confirmar que um servico esta escutando." @("netstat -ano") -Win }
            "7"  {
                $dest = Read-Host "  Destino (IP ou domínio, ex: www.google.com)"
                if ($dest) { Run "Traceroute para $dest..." "Rastreia a rota completa dos pacotes até o destino, exibindo cada salto (roteador) e a latência em cada um. Útil para identificar em qual ponto a conexão degrada ou cai." @("tracert $dest") -Win }
            }
            "8"  { Run "Endereços MAC das interfaces..." "Lista os endereços físicos (MAC) de todos os adaptadores de rede. Útil para controle de acesso a rede (ACL por MAC) ou identificar a placa usada." @("getmac /v") -Win }
            "9"  { Configurar-IP-Estatico }
            "10" { Start-Process ncpa.cpl; Write-Host "  Abrindo gerenciador de conexões de rede..." -ForegroundColor $C.A; P }
            "0"  { return }
            default { Write-Host "  Opção inválida." -ForegroundColor $C.E; Start-Sleep 1 }
        }
    } while ($true)
}

function Configurar-IP-Estatico {
    L; Cab "CONFIGURAR IP ESTÁTICO - ETHERNET"
    Write-Host "  Mascaras automaticas definidas por faixa de IP:" -ForegroundColor $C.H
    Write-Host "    172.16.x.x  -->  255.255.0.0     (rede classe B)" -ForegroundColor $C.I
    Write-Host "    192.168.x.x -->  255.255.255.0   (rede classe C)" -ForegroundColor $C.I
    Write-Host ""
    $ip = Read-Host "  Endereço IP (ex: 172.16.1.50)"
    if (-not ($ip -match '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$')) { Write-Host "  IP inválido." -ForegroundColor $C.E; P; return }
    $mask = ""
    if      ($ip -match '^172\.16\.')  { $mask = "255.255.0.0" }
    elseif  ($ip -match '^192\.168\.') { $mask = "255.255.255.0" }
    else    { $mask = Read-Host "  Mascara de sub-rede (ex: 255.255.255.0)" }
    $gw   = Read-Host "  Gateway (ex: 172.16.0.1)"
    $dns  = Read-Host "  DNS Primario (Enter = usar o gateway como DNS)"
    if ([string]::IsNullOrWhiteSpace($dns)) { $dns = $gw }
    $adp  = Read-Host "  Adaptador (Enter = Ethernet)"
    if ([string]::IsNullOrWhiteSpace($adp)) { $adp = "Ethernet" }
    Write-Host ""
    Write-Host "  Resumo da configuração:" -ForegroundColor $C.A
    Write-Host "    Adaptador:  $adp"  -ForegroundColor $C.I
    Write-Host "    IP:         $ip"   -ForegroundColor $C.I
    Write-Host "    Mascara:    $mask" -ForegroundColor $C.I
    Write-Host "    Gateway:    $gw"   -ForegroundColor $C.I
    Write-Host "    DNS:        $dns"  -ForegroundColor $C.I
    Write-Host ""
    if (Confirmar "Aplicar as configurações de rede estaticas acima no adaptador '$adp'?") {
        Run "Configurando IP estático em '$adp'..." "" @(
            "netsh interface ipv4 set address name=`"$adp`" static $ip $mask $gw",
            "netsh interface ipv4 set dnsserver name=`"$adp`" static $dns primary"
        ) -Win
    } else { Write-Host "  Cancelado." -ForegroundColor $C.A; P }
}

# =============================================================================
# MENU 8: LIMPEZA E MANUTENÇÃO
# =============================================================================
function Menu-Limpeza {
    do {
        Cab "8. LIMPEZA E MANUTENÇÃO"
        Write-Host "  1. Limpar Temp do usuario (%TEMP%)" -ForegroundColor $C.M
        Write-Host "  2. Limpar Temp do sistema (C:\Windows\Temp)" -ForegroundColor $C.M
        Write-Host "  3. Limpeza completa (Temp usuario + sistema + Prefetch)" -ForegroundColor $C.M
        Write-Host "  4. Limpeza de disco avancada (Disk Cleanup)" -ForegroundColor $C.M
        Write-Host "  5. Limpar cache do Windows Update" -ForegroundColor $C.M
        Write-Host "  6. Abrir pasta %TEMP% para inspecao manual" -ForegroundColor $C.M
        Write-Host "  0. Voltar" -ForegroundColor $C.I
        switch (Read-Host "`n  Opção") {
            "1" { Run "Limpando Temp do usuario..." "Remove todos os arquivos temporarios gerados pelo usuario atual em %TEMP%. Arquivos em uso são ignorados. Não afeta documentos pessoais. Pode liberar centenas de MB." @('Get-ChildItem -Path $env:TEMP -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue; Write-Host "Limpeza concluida!"') -PS -Win }
            "2" { Run "Limpando Temp do sistema..." "Remove arquivos temporarios de C:\Windows\Temp, usados pelo sistema e por servicos. Requer privilégios de administrador. Arquivos em uso são ignorados." @('Get-ChildItem -Path "C:\Windows\Temp" -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue; Write-Host "Limpeza do sistema concluida!"') -PS -Win }
            "3" { Run "Limpeza completa de temporarios..." "Remove Temp do usuario, Temp do sistema e Prefetch. O Prefetch será regenerado automaticamente pelo Windows nas proximas execucoes. Pode liberar varios GB." @('Remove-Item "$env:TEMP\*" -Recurse -Force -EA SilentlyContinue; Remove-Item "C:\Windows\Temp\*" -Recurse -Force -EA SilentlyContinue; Remove-Item "C:\Windows\Prefetch\*" -Recurse -Force -EA SilentlyContinue; Write-Host "Limpeza completa concluida!"') -PS -Win }
            "4" { Run "Abrindo Disk Cleanup avancado..." "Abre a ferramenta de Limpeza de Disco do Windows em modo avancado. Permite selecionar categorias (arquivos WU, miniaturas, lixeira, arquivos de instalação) e libera espaço de forma segura." @("cleanmgr /sageset:1", "cleanmgr /sagerun:1") -Win }
            "5" { Run "Limpando cache do Windows Update..." "Para o servico Windows Update, remove os downloads em cache de atualizações (pasta SoftwareDistribution\Download) e reinicia o servico. Resolve erros de atualização travada ou falha de instalação." @('net stop wuauserv; Remove-Item "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force -EA SilentlyContinue; net start wuauserv; Write-Host "Cache do Windows Update limpo com sucesso!"') -PS -Win }
            "6" { Start-Process $env:TEMP; Write-Host "  Abrindo pasta de temporarios..." -ForegroundColor $C.A; P }
            "0" { return }
            default { Write-Host "  Opção inválida." -ForegroundColor $C.E; Start-Sleep 1 }
        }
    } while ($true)
}

# =============================================================================
# MENU 9: SEGURANÇA E PERMISSÕES
# =============================================================================
function Menu-Seguranca {
    do {
        Cab "9. SEGURANÇA E PERMISSÕES"
        Write-Host "  1. Resetar permissões de pasta (ICACLS)" -ForegroundColor $C.M
        Write-Host "  2. Tomar posse de pasta (takeown)" -ForegroundColor $C.M
        Write-Host "  3. Bloquear portas USB (impede pen drives)" -ForegroundColor $C.M
        Write-Host "  4. Desbloquear portas USB" -ForegroundColor $C.M
        Write-Host "  5. Habilitar Firewall (todos os perfis)" -ForegroundColor $C.M
        Write-Host "  6. Desabilitar Firewall  [CUIDADO!]" -ForegroundColor $C.A
        Write-Host "  7. Gerenciar Execution Policy do PowerShell" -ForegroundColor $C.M
        Write-Host "  8. Criar ponto de restauração do sistema" -ForegroundColor $C.M
        Write-Host "  9. Ativar proteção de escrita em drives externos" -ForegroundColor $C.M
        Write-Host " 10. Desativar proteção de escrita em drives externos" -ForegroundColor $C.M
        Write-Host " 11. Verificar malware (Windows MRT)" -ForegroundColor $C.M
        Write-Host "  0. Voltar" -ForegroundColor $C.I
        switch (Read-Host "`n  Opção") {
            "1"  {
                $p = Read-Host "  Caminho da pasta (ex: C:\Users\usuario\Documentos)"
                if ($p) { Run "Resetando permissões de '$p'..." "Reseta todas as ACLs (permissões de acesso) da pasta e seu conteúdo para heranca padrão do Windows. Resolve erros 'Acesso Negado' causados por permissões corrompidas ou herdadas incorretamente." @("icacls `"$p`" /reset /t /c /l") -Win }
                else { P }
            }
            "2"  {
                $p = Read-Host "  Caminho da pasta"
                if ($p) { Run "Tomando posse de '$p'..." "Transfere a propriedade da pasta e todo seu conteúdo para o usuario atual. Necessário antes de modificar permissões em pastas protegidas do sistema ou de outros usuarios." @("takeown /f `"$p`" /r /d y", "icacls `"$p`" /grant `"$env:USERNAME`:F`" /t") -Win }
                else { P }
            }
            "3"  { Run "Bloqueando USB..." "Desativa os drivers de armazenamento USB (USBSTOR e USBHUB3). Pen drives e HDs externos não serao reconhecidos. Valor 4 = desativado. Efetivo após reinicialização." @('reg add "HKLM\System\CurrentControlSet\Services\USBSTOR" /v Start /t REG_DWORD /d 4 /f', 'reg add "HKLM\System\CurrentControlSet\Services\USBHUB3" /v Start /t REG_DWORD /d 4 /f') -Win }
            "4"  { Run "Desbloqueando USB..." "Reativa os drivers de armazenamento USB. Valor 3 = manual (o dispositivo e ativado quando conectado)." @('reg add "HKLM\System\CurrentControlSet\Services\USBSTOR" /v Start /t REG_DWORD /d 3 /f', 'reg add "HKLM\System\CurrentControlSet\Services\USBHUB3" /v Start /t REG_DWORD /d 3 /f') -Win }
            "5"  { Run "Habilitando Firewall..." "Ativa o Firewall do Windows em todos os perfis (Domínio, Privado e Público). Protege o computador contra acessos não autorizados pela rede." @("netsh advfirewall set allprofiles state on") -Win }
            "6"  {
                if (Confirmar "ATENÇÃO RISCO DE SEGURANÇA: Desativar o Firewall expõe o computador a ataques de rede. Use APENAS para diagnóstico temporario e reative imediatamente após. CONFIRMA?") {
                    Run "Desativando Firewall..." "" @("netsh advfirewall set allprofiles state off") -Win
                } else { Write-Host "  Cancelado (correto!)." -ForegroundColor $C.M; P }
            }
            "7"  { Menu-ExecPolicy }
            "8"  { Run "Criando ponto de restauração..." "Salva o estado atual do sistema (registro, configurações de sistema) como um ponto de restauração. Permite reverter o Windows a este momento se algo der errado após uma alteração." @("Enable-ComputerRestore -Drive 'C:\' -ErrorAction SilentlyContinue; Checkpoint-Computer -Description 'T! SOS Sistemas - Manutenção $(Get-Date -f yyyy-MM-dd)' -RestorePointType MODIFY_SETTINGS; Write-Host 'Ponto de restauração criado com sucesso!'") -PS -Win }
            "9"  { Run "Ativando proteção contra escrita em drives externos..." "Impede gravação em pen drives e HDs externos. Permite leitura mas bloqueia escrita e formatação. Protege contra vazamento de dados e infeccao via drives externos." @('reg add "HKLM\System\CurrentControlSet\Control\Storage\DevicePolicies" /v WriteProtect /t REG_DWORD /d 1 /f') -Win }
            "10" { Run "Desativando proteção de escrita..." "Permite novamente a gravação em drives externos USB. Valor 0 = escrita liberada." @('reg add "HKLM\System\CurrentControlSet\Control\Storage\DevicePolicies" /v WriteProtect /t REG_DWORD /d 0 /f') -Win }
            "11" { Run "Abrindo Verificador de Malware (MRT)..." "Abre o Microsoft Malicious Software Removal Tool (MRT), ferramenta nativa do Windows que verifica e remove malwares conhecidos." @("mrt.exe") -Win }
            "0"  { return }
            default { Write-Host "  Opção inválida." -ForegroundColor $C.E; Start-Sleep 1 }
        }
    } while ($true)
}

function Menu-ExecPolicy {
    L; Cab "GERENCIAR EXECUTION POLICY DO POWERSHELL"
    Write-Host "  Política atual por escopo:" -ForegroundColor $C.A
    Get-ExecutionPolicy -List | Format-Table -AutoSize
    Write-Host ""
    Write-Host "  Opções disponíveis:" -ForegroundColor $C.I
    Write-Host "  1. Restricted    - Bloqueia todos os scripts (mais seguro, padrão)" -ForegroundColor $C.M
    Write-Host "  2. RemoteSigned  - Permite scripts locais; baixados precisam ser assinados" -ForegroundColor $C.M
    Write-Host "  3. AllSigned     - Todos os scripts precisam ter assinatura digital" -ForegroundColor $C.M
    Write-Host "  4. Unrestricted  - Permite tudo, apenas avisa em scripts baixados" -ForegroundColor $C.A
    Write-Host "  5. Undefined     - Remove a definicao do escopo (usa política do sistema)" -ForegroundColor $C.M
    Write-Host "  0. Voltar" -ForegroundColor $C.I
    Write-Host ""
    $op   = Read-Host "  Opção"
    $pols = @{ "1"="Restricted"; "2"="RemoteSigned"; "3"="AllSigned"; "4"="Unrestricted"; "5"="Undefined" }
    if ($pols.ContainsKey($op)) {
        $pol = $pols[$op]
        if (Confirmar "Alterar Execution Policy para '$pol' no escopo LocalMachine? Use RemoteSigned durante manutenção e retorne a Restricted após concluir.") {
            Set-ExecutionPolicy $pol -Scope LocalMachine -Force
            Write-Host "  [OK] Execution Policy definida para: $pol" -ForegroundColor $C.M
            Log "Execution Policy alterada para $pol"
        }
    }
    P
}

# =============================================================================
# MENU 10: DIAGNÓSTICO AVANCADO
# =============================================================================
function Menu-Diagnostico {
    do {
        Cab "10. DIAGNÓSTICO AVANCADO"
        Write-Host "  -- Processos e Servicos ----------------------------------" -ForegroundColor $C.H
        Write-Host "   1. Top 10 processos por uso de CPU" -ForegroundColor $C.M
        Write-Host "   2. Top 10 processos por uso de RAM" -ForegroundColor $C.M
        Write-Host "   3. Servicos em execução" -ForegroundColor $C.M
        Write-Host "   4. Servicos parados" -ForegroundColor $C.M
        Write-Host "  -- Eventos e Erros ---------------------------------------" -ForegroundColor $C.H
        Write-Host "   5. Últimos 10 erros críticos do sistema" -ForegroundColor $C.M
        Write-Host "   6. Abrir Visualizador de Eventos" -ForegroundColor $C.M
        Write-Host "   7. Histórico de confiabilidade do sistema" -ForegroundColor $C.M
        Write-Host "  -- Hardware e Sistema ------------------------------------" -ForegroundColor $C.H
        Write-Host "   8. Informações completas do sistema (systeminfo)" -ForegroundColor $C.M
        Write-Host "   9. Hardware via WMI (CPU, RAM, disco, placa-mae)" -ForegroundColor $C.M
        Write-Host "  10. Pontuação de desempenho WinSAT" -ForegroundColor $C.M
        Write-Host "  11. WinSAT completo - benchmark detalhado (~10min)" -ForegroundColor $C.M
        Write-Host "  12. WinSAT por componente (CPU, RAM, Disco, GPU)" -ForegroundColor $C.M
        Write-Host "  13. Programas instalados (wmic)" -ForegroundColor $C.M
        Write-Host "  14. Atualizações instaladas (wmic qfe)" -ForegroundColor $C.M
        Write-Host "  15. Informações de boot (bcdedit)" -ForegroundColor $C.M
        Write-Host "  16. Relatório de desempenho (perfmon)" -ForegroundColor $C.M
        Write-Host "   0. Voltar" -ForegroundColor $C.I
        switch (Read-Host "`n  Opção") {
            "1"  {
                Write-Host "`n  Top 10 processos por CPU:" -ForegroundColor $C.A
                Get-Process | Sort-Object CPU -Descending | Select-Object -First 10 `
                    ProcessName, @{N="CPU(s)";E={[math]::Round($_.CPU,2)}}, @{N="RAM(MB)";E={[math]::Round($_.WorkingSet/1MB,1)}}, Id |
                    Format-Table -AutoSize
                P
            }
            "2"  {
                Write-Host "`n  Top 10 processos por RAM:" -ForegroundColor $C.A
                Get-Process | Sort-Object WorkingSet -Descending | Select-Object -First 10 `
                    ProcessName, @{N="RAM(MB)";E={[math]::Round($_.WorkingSet/1MB,1)}}, @{N="CPU(s)";E={[math]::Round($_.CPU,2)}}, Id |
                    Format-Table -AutoSize
                P
            }
            "3"  { Run "Servicos em execução..." "Lista todos os servicos do Windows atualmente ativos. Útil para verificar se servicos essenciais estao rodando ou para identificar servicos desnecessarios consumindo recursos." @('Get-Service | Where-Object { $_.Status -eq "Running" } | Select-Object DisplayName, Name, StartType | Sort-Object DisplayName | Format-Table -AutoSize') -PS -Win }
            "4"  { Run "Servicos parados..." "Lista todos os servicos que estao parados. Útil para verificar se algum servico essencial foi desativado inadvertidamente ou esta falhando ao iniciar." @('Get-Service | Where-Object { $_.Status -eq "Stopped" } | Select-Object DisplayName, Name, StartType | Sort-Object DisplayName | Format-Table -AutoSize') -PS -Win }
            "5"  {
                Write-Host "`n  Últimos 10 erros do sistema:" -ForegroundColor $C.A
                Get-EventLog -LogName System -EntryType Error -Newest 10 |
                    Select-Object TimeGenerated, Source, EventID, @{N="Mensagem";E={$_.Message.Substring(0,[Math]::Min(80,$_.Message.Length))}} |
                    Format-Table -AutoSize -Wrap
                P
            }
            "6"  { Start-Process eventvwr.msc; Write-Host "  Abrindo Visualizador de Eventos..." -ForegroundColor $C.A; P }
            "7"  { Start-Process cmd.exe -ArgumentList "/k perfmon /rel"; P }
            "8"  { Run "Informações completas do sistema..." "Exibe uma ficha completa do sistema operacional: versão, arquitetura, hora do último boot, configurações de rede, hotfixes instalados, configuração de memória virtual e muito mais." @("systeminfo") -Win }
            "9"  { Run "Hardware via WMI (inventário)..." "Coleta dados de CPU (nome, núcleos, clock), RAM (capacidade por módulo, velocidade), disco (modelo, serial, status) e placa-mae (produto, fabricante). Útil para inventário de hardware." @("wmic cpu get name,currentclockspeed,maxclockspeed,numberofcores,numberoflogicalprocessors", "wmic memorychip get capacity,speed,devicelocator,manufacturer", "wmic diskdrive get status,model,serialnumber,size", "wmic baseboard get product,manufacturer,version") -Win }
            "10" {
                Write-Host "`n  Pontuacoes WinSAT (escala de 1.0 a 9.9):" -ForegroundColor $C.A
                try { Get-CimInstance Win32_WinSAT | Select-Object CPUScore, MemoryScore, DiskScore, GraphicsScore, GamingScore | Format-Table -AutoSize }
                catch { Write-Host "  Sem dados. Execute o WinSAT completo (opção 11) primeiro." -ForegroundColor $C.E }
                P
            }
            "11" { Run "WinSAT Formal (benchmark completo)..." "Executa a avaliação completa de desempenho do Windows para todos os componentes (CPU, RAM, disco, graficos). Dura 5-10 minutos. Os resultados ficam disponíveis na opção 10." @("winsat formal") -Win }
            "12" {
                L; Cab "WINSAT - BENCHMARK POR COMPONENTE"
                Write-Host "  1. CPU       2. RAM       3. Disco C:  4. 3D/DirectX"
                Write-Host "  5. DWM/Interface         6. Recursos do SO"
                Write-Host "  0. Voltar"
                switch (Read-Host "`n  Opção") {
                    "1" { Run "WinSAT CPU..." "Mede o desempenho do processador em operacoes matematicas e de compressao." @("winsat cpu") -Win }
                    "2" { Run "WinSAT RAM..." "Mede a largura de banda e latência da memória RAM." @("winsat mem") -Win }
                    "3" { Run "WinSAT Disco..." "Mede leitura/escrita sequencial e aleatoria do disco C:." @("winsat disk -drive c -ran -write -seq") -Win }
                    "4" { Run "WinSAT 3D (DirectX)..." "Mede o desempenho 3D da GPU usando DirectX. Útil para testar estabilidade da placa de vídeo." @("winsat d3d -totalindices 10") -Win }
                    "5" { Run "WinSAT DWM (interface)..." "Avalia o desempenho do Desktop Window Manager (transparências, composicao de janelas)." @("winsat dwm") -Win }
                    "6" { Run "WinSAT Features..." "Lista os recursos e capacidades do sistema para relatório." @("winsat features") -Win }
                }
                P
            }
            "13" { Run "Programas instalados..." "Lista todos os programas instalados via Windows Installer. Pode demorar alguns segundos para carregar." @("wmic product get name,version /format:table") -Win }
            "14" { Run "Atualizações instaladas (hotfixes, KBs)..." "Lista todos os KBs, patches e service packs instalados com data de instalação. Útil para verificar se um patch especifico ja foi aplicado." @("wmic qfe list") -Win }
            "15" { Run "Informações de boot (BCD)..." "Exibe a configuração completa do Boot Configuration Data: entradas de boot, timeout, drivers de debug. Útil para diagnosticar problemas de inicialização ou dual boot." @("bcdedit /enum all") -Win }
            "16" { Start-Process perfmon.exe -ArgumentList "/report"; Write-Host "  Gerando relatório de desempenho (pode demorar ~60s)..." -ForegroundColor $C.A; P }
            "0"  { return }
            default { Write-Host "  Opção inválida." -ForegroundColor $C.E; Start-Sleep 1 }
        }
    } while ($true)
}

# =============================================================================
# MENU 11: PLACA DE VÍDEO E MONITOR
# =============================================================================
function Menu-Video {
    do {
        Cab "11. PLACA DE VÍDEO E MONITOR"
        Write-Host "  1. Informações da placa de vídeo (WMI)" -ForegroundColor $C.M
        Write-Host "  2. Diagnóstico DirectX (dxdiag)" -ForegroundColor $C.M
        Write-Host "  3. Benchmark 3D / teste de tela piscando (winsat d3d)" -ForegroundColor $C.M
        Write-Host "  4. Benchmark DWM (interface do Windows)" -ForegroundColor $C.M
        Write-Host "  5. Listar monitores/displays conectados" -ForegroundColor $C.M
        Write-Host "  6. Abrir configuração de exibição (DisplaySwitch)" -ForegroundColor $C.M
        Write-Host "  7. Abrir Tarefas Agendadas (possível causa de tela preta)" -ForegroundColor $C.M
        Write-Host "  8. Abrir Servicos de Componentes DCOM (tela piscando)" -ForegroundColor $C.M
        Write-Host "  9. Abrir Gerenciador de Dispositivos" -ForegroundColor $C.M
        Write-Host " 10. Verificar erros DCOM nos logs do sistema" -ForegroundColor $C.M
        Write-Host ""
        Write-Host "  [DICA] Para resetar GPU sem reiniciar: Ctrl + Win + Shift + B" -ForegroundColor $C.D
        Write-Host ""
        Write-Host "  0. Voltar" -ForegroundColor $C.I
        switch (Read-Host "  Opção") {
            "1"  { Run "Informações da placa de vídeo..." "Exibe nome da GPU, resolucao atual, memória de vídeo e status do adaptador grafico. Útil para identificar o modelo exato da placa e verificar se o driver esta funcionando." @("wmic path win32_VideoController get name,currenthorizontalresolution,currentverticalresolution,adapterram,status") -Win }
            "2"  { Start-Process dxdiag; Write-Host "  Abrindo diagnóstico DirectX..." -ForegroundColor $C.A; P }
            "3"  { Run "Benchmark 3D DirectX..." "Avalia o desempenho 3D usando DirectX. Também usado para verificar se a tela pisca durante carga 3D, o que indica problema com driver ou hardware de vídeo." @("winsat d3d -totalindices 10") -Win }
            "4"  { Run "Benchmark DWM (interface grafica)..." "Avalia o Desktop Window Manager responsavel por renderizar as janelas, transparências e animações. Problemas aqui causam lentidao visual e artefatos na tela." @("winsat dwm") -Win }
            "5"  { Run "Monitores e displays conectados..." "Lista todos os dispositivos de exibição detectados pelo sistema. Útil quando um monitor externo não e reconhecido automaticamente." @("pnputil /enum-devices /class Display") -Win }
            "6"  { Start-Process DisplaySwitch.exe; Write-Host "  Abrindo configuração de projecao de tela..." -ForegroundColor $C.A; P }
            "7"  {
                Start-Process taskschd.msc
                Write-Host "  Abriu Tarefas Agendadas." -ForegroundColor $C.A
                Write-Host "  Verifique se existe alguma tarefa suspeita que rode cmd.exe" -ForegroundColor $C.D
                Write-Host "  ou que esteja programada no horário que a tela preta ocorre." -ForegroundColor $C.D
                P
            }
            "8"  {
                Start-Process dcomcnfg
                Write-Host "  Abriu Servicos de Componentes (DCOM)." -ForegroundColor $C.A
                Write-Host "  Se aparecer um prompt, clique em Sim e reinicie o PC." -ForegroundColor $C.D
                Write-Host "  O RuntimeBroker e o principal suspeito de instabilidade de GPU." -ForegroundColor $C.D
                P
            }
            "9"  { Start-Process devmgmt.msc; Write-Host "  Abrindo Gerenciador de Dispositivos..." -ForegroundColor $C.A; P }
            "10" { Run "Verificando erros DCOM nos logs do sistema..." "Busca nos logs do sistema erros relacionados ao DistributedCOM (DCOM). Erros frequentes de DCOM, especialmente do RuntimeBroker, são causa comum de tela piscando e instabilidade de GPU." @('Get-WinEvent -FilterHashtable @{LogName="System"; Level=2} -MaxEvents 100 -EA SilentlyContinue | Where-Object { $_.ProviderName -like "*DCOM*" -or $_.ProviderName -like "*DistributedCOM*" } | Select-Object TimeCreated, Id, Message | Format-Table -AutoSize -Wrap') -PS -Win }
            "0"  { return }
            default { Write-Host "  Opção inválida." -ForegroundColor $C.E; Start-Sleep 1 }
        }
    } while ($true)
}

# =============================================================================
# MENU 12: IDENTIDADE DO SISTEMA
# =============================================================================
function Menu-Identidade {
    do {
        Cab "12. IDENTIDADE DO SISTEMA"
        Write-Host "  1. Renomear o computador" -ForegroundColor $C.M
        Write-Host "  2. Alterar nome completo de um usuario local" -ForegroundColor $C.M
        Write-Host "  3. Alterar nome de exibição do usuario atual" -ForegroundColor $C.M
        Write-Host "  4. Configurar IP estático (Ethernet)" -ForegroundColor $C.M
        Write-Host "  5. Exibir nome do computador e usuario logado" -ForegroundColor $C.M
        Write-Host "  6. Abrir painel de usuarios do sistema" -ForegroundColor $C.M
        Write-Host "  0. Voltar" -ForegroundColor $C.I
        switch (Read-Host "`n  Opção") {
            "1" {
                Write-Host "  Computador atual: $env:COMPUTERNAME" -ForegroundColor $C.I
                $novo = Read-Host "  Novo nome (max 15 chars, sem espacos ou caracteres especiais)"
                if ($novo -match '^[A-Za-z0-9\-]{1,15}$') {
                    Run "Renomeando computador para '$novo'..." "Altera o nome de rede do computador. A mudanca soh entra em vigor após reinicialização. Padrão: usar nomenclatura definida pelo suporte (ex: SETOR-NÚMERO)." @("Rename-Computer -NewName '$novo' -ErrorAction Stop; Write-Host 'Computador renomeado para $novo. Reinicie para aplicar.'") -PS -Win
                } else { Write-Host "  Nome inválido (use apenas letras, números e hifem, max 15)." -ForegroundColor $C.E; P }
            }
            "2" {
                $conta = Read-Host "  Nome de login da conta local"
                $novo = Read-Host "  Novo nome completo para '$conta'"
                if ($conta -and $novo) { Run "Alterando fullname do usuario '$conta'..." "Altera o nome completo (nome de exibição) da conta local '$conta'. O nome de login permanece '$conta', apenas o nome visivel muda." @("net user `"$conta`" /fullname:`"$novo`"") -Win }
                else { P }
            }
            "3" {
                $novo = Read-Host "  Novo nome de exibição para '$env:USERNAME'"
                if ($novo) { Run "Alterando nome de exibição..." "Altera o DisplayName da conta do usuario atual. Pode ser necessário fazer logoff/logon para o efeito aparecer na tela de bloqueio." @("Set-LocalUser -Name '$env:USERNAME' -FullName '$novo'; Write-Host 'Nome atualizado!'") -PS -Win }
                else { P }
            }
            "4" { Configurar-IP-Estatico }
            "5" {
                Write-Host ""
                Write-Host "  Computador:  $env:COMPUTERNAME" -ForegroundColor $C.I
                Write-Host "  Usuario:     $env:USERNAME"     -ForegroundColor $C.I
                Write-Host "  Domínio:     $env:USERDOMAIN"   -ForegroundColor $C.I
                $ip4 = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notlike "*Loopback*" } | Select-Object -First 1).IPAddress
                Write-Host "  IP Ethernet: $ip4" -ForegroundColor $C.I
                Write-Host ""
                P
            }
            "6" { Start-Process "control userpasswords2"; Write-Host "  Abrindo gerenciamento de usuarios..." -ForegroundColor $C.A; P }
            "0" { return }
            default { Write-Host "  Opção inválida." -ForegroundColor $C.E; Start-Sleep 1 }
        }
    } while ($true)
}

# =============================================================================
# MENU 13: TESTES DE STRESS (CPU)
# =============================================================================
function Menu-Stress {
    do {
        Cab "13. TESTES DE STRESS"
        Write-Host "  !!! Use HWMonitor ou Core Temp para monitorar temperatura !!!" -ForegroundColor $C.A
        Write-Host "  !!! Se o PC desligar durante o teste: problema de refrigeracao !!!" -ForegroundColor $C.A
        Write-Host ""
        Write-Host "  1. Stress CPU via PowerShell (mais eficiente, demora N segundos)" -ForegroundColor $C.M
        Write-Host "  2. Stress CPU via CMD (loop de calculo simples)" -ForegroundColor $C.M
        Write-Host "  3. Ver pontuacoes WinSAT do hardware" -ForegroundColor $C.M
        Write-Host "  4. Teste de monitor [CUIDADO: pisca a tela repetidamente]" -ForegroundColor $C.A
        Write-Host "  0. Voltar" -ForegroundColor $C.I
        switch (Read-Host "`n  Opção") {
            "1" { Teste-CPU-PS }
            "2" { Teste-CPU-CMD }
            "3" {
                Write-Host ""
                try { Get-CimInstance Win32_WinSAT | Select-Object CPUScore, MemoryScore, DiskScore, GraphicsScore | Format-Table -AutoSize }
                catch { Write-Host "  Execute o WinSAT formal (Menu 10, opção 11) primeiro." -ForegroundColor $C.E }
                P
            }
            "4" {
                Write-Host ""
                Write-Host "  ATENÇÃO: Este teste reinicia o Explorer em loop." -ForegroundColor $C.A
                Write-Host "  A tela vai piscar repetidamente até você FECHAR a janela." -ForegroundColor $C.A
                Write-Host "  Não deixe o computador sem supervisao durante o teste." -ForegroundColor $C.A
                Write-Host ""
                if (Confirmar "Confirma que entendeu o aviso e quer iniciar o teste de monitor piscante?") {
                    $bat = "$env:TEMP\sos_monitor_test.bat"
                    "@echo off`r`n:loop`r`nTaskkill /f /im explorer.exe`r`nStart explorer.exe`r`nTimeout /t 5`r`nGoto loop" | Out-File $bat -Encoding ASCII
                    Start-Process cmd.exe -ArgumentList "/k `"$bat`""
                    Write-Host "  Teste iniciado em nova janela. FECHE-A para parar." -ForegroundColor $C.A
                    Write-Host "  Se a barra de tarefas sumir: Ctrl+Shift+Esc > Arquivo > Executar nova tarefa > explorer.exe" -ForegroundColor $C.A
                } else { Write-Host "  Cancelado." -ForegroundColor $C.M }
                P
            }
            "0" { return }
            default { Write-Host "  Opção inválida." -ForegroundColor $C.E; Start-Sleep 1 }
        }
    } while ($true)
}

function Teste-CPU-PS {
    L; Cab "STRESS TEST CPU - POWERSHELL"
    $nucleos = (Get-CimInstance Win32_Processor).NumberOfLogicalProcessors
    Write-Host "  CPU: $(((Get-CimInstance Win32_Processor).Name).Trim())" -ForegroundColor $C.I
    Write-Host "  Núcleos lógicos: $nucleos" -ForegroundColor $C.I
    Write-Host ""
    $num = Read-Host "  Quantos processos de stress usar? (max recomendado: $nucleos)"
    $dur = Read-Host "  Duracao do teste em segundos (ex: 60)"
    if ($num -notmatch '^\d+$' -or $dur -notmatch '^\d+$') { Write-Host "  Valores invalidos." -ForegroundColor $C.E; P; return }
    $num = [math]::Min([int]$num, $nucleos * 2)
    $dur = [int]$dur
    Write-Host ""
    Write-Host "  Iniciando $num processos por $dur segundos..." -ForegroundColor $C.A
    Write-Host "  Monitore a temperatura! Pressione Ctrl+C para cancelar." -ForegroundColor $C.A
    Write-Host ""
    $stressCode = '$end=(Get-Date).AddSeconds(' + $dur + '); $r=0; while((Get-Date)-lt$end){for($i=1;$i-lt9999;$i++){$r+=$i/($i+1)}}; Write-Host "Worker concluído!"'
    $tmpFile = "$env:TEMP\sos_stress_$((Get-Random)).ps1"
    $stressCode | Out-File $tmpFile -Encoding UTF8
    $pids = @()
    for ($i = 1; $i -le $num; $i++) {
        $proc = Start-Process powershell.exe -ArgumentList "-NoProfile -EP Bypass -File `"$tmpFile`"" -WindowStyle Minimized -PassThru
        $pids += $proc.Id
        Write-Host "  Worker $i iniciado (PID $($proc.Id))..." -ForegroundColor $C.M
    }
    Write-Host ""
    Write-Host "  Aguardando $dur segundos..." -ForegroundColor $C.A
    for ($s = 1; $s -le $dur; $s += 5) {
        Start-Sleep ([Math]::Min(5, $dur - $s + 1))
        Write-Host "  $s/$dur s..." -ForegroundColor $C.H
    }
    $pids | ForEach-Object { Stop-Process -Id $_ -Force -ErrorAction SilentlyContinue }
    Remove-Item $tmpFile -Force -ErrorAction SilentlyContinue
    Write-Host "`n  [OK] Teste de CPU concluído!" -ForegroundColor $C.M
    Log "Stress CPU PS: $num workers por ${dur}s"
    P
}

function Teste-CPU-CMD {
    L; Cab "STRESS TEST CPU - CMD (loop de calculos)"
    $nucleos = (Get-CimInstance Win32_Processor).NumberOfLogicalProcessors
    Write-Host "  Núcleos lógicos: $nucleos" -ForegroundColor $C.I
    Write-Host ""
    $num = Read-Host "  Quantos processos worker? (max: $nucleos)"
    $dur = Read-Host "  Duracao em segundos (ex: 60)"
    if ($num -notmatch '^\d+$' -or $dur -notmatch '^\d+$') { Write-Host "  Valores invalidos." -ForegroundColor $C.E; P; return }
    $num = [math]::Min([int]$num, [int]($nucleos) * 2)
    $dur = [int]$dur
    $workerBat = "$env:TEMP\sos_worker_$((Get-Random)).bat"
    "@echo off`r`ntitle SOS CPU Worker %1`r`n:loop`r`nset /a a=%random% * %random%`r`nset /a b=%random% * %random% / (%random%+1)`r`ngoto loop" | Out-File $workerBat -Encoding ASCII
    $procs = @()
    for ($i = 1; $i -le $num; $i++) {
        $p = Start-Process cmd.exe -ArgumentList "/c `"$workerBat`" $i" -WindowStyle Minimized -PassThru
        $procs += $p; Write-Host "  Worker CMD $i iniciado..." -ForegroundColor $C.M
    }
    Write-Host "  Testando por $dur segundos..." -ForegroundColor $C.A
    Start-Sleep $dur
    $procs | ForEach-Object { Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue }
    Remove-Item $workerBat -Force -ErrorAction SilentlyContinue
    Write-Host "  [OK] Teste CMD concluído!" -ForegroundColor $C.M
    Log "Stress CPU CMD: $num workers por ${dur}s"
    P
}

# =============================================================================
# FUNCAO: ANÁLISE PROFUNDA DE PROCESSOS SUSPEITOS
# =============================================================================
# v2.1.26.0612 #menu SEGURANÇA 14.1 Processos Suspeitos, agora realiza a verificação do executablepath e commandline se tiver em branco pode ser virus e mostra o que o cmd consegue visualizar e abre o virus total

function Verificar-Processos-Suspeitos {
    L; Cab "14.1 - PROCESSOS SUSPEITOS - ANÁLISE PROFUNDA"

    Desc "Lista processos sem caminho de arquivo, com mais de 500 handles e CPU acima de 50. Para cada processo encontrado, o sistema automaticamente verifica a assinatura digital, o caminho real via WMI, a linha de comando completa e oferece checar o arquivo no VirusTotal."

    Write-Host "  Buscando processos suspeitos, aguarde..." -ForegroundColor $C.A
    $suspeitos = Get-Process | Where-Object { $_.Path -eq $null -and $_.Handles -gt 500 -and $_.CPU -gt 50 }

    if (-not $suspeitos) {
        Write-Host "`n  [OK] Nenhum processo suspeito encontrado neste momento." -ForegroundColor $C.M
        Log "Verificação de processos suspeitos: nenhum encontrado."
        P; return
    }

    Write-Host "`n  Processos encontrados:" -ForegroundColor $C.A
    $suspeitos | Select-Object Name, Id, CPU, Handles, StartTime | Format-Table -AutoSize

    Write-Host ""
    Write-Host "  [AVISO] Processos como MsMpEng.exe (Windows Defender), svchost.exe," -ForegroundColor $C.H
    Write-Host "  e outros processos protegidos do SO costumam aparecer aqui como" -ForegroundColor $C.H
    Write-Host "  FALSO POSITIVO, pois o PowerShell não consegue ler o Path deles" -ForegroundColor $C.H
    Write-Host "  por restrição de permissão - não significa que o arquivo não exista." -ForegroundColor $C.H
    Write-Host ""

    foreach ($proc in $suspeitos) {
        $nome = $proc.Name
        $pid_ = $proc.Id

        Write-Host ("=" * 60) -ForegroundColor $C.H
        Write-Host "  Investigando: $nome (PID $pid_)" -ForegroundColor $C.A
        Write-Host ("=" * 60) -ForegroundColor $C.H

        # 1. Caminho real e assinatura digital via WMI (funciona mesmo com Get-Process sem Path)
        $cim = Get-CimInstance Win32_Process -Filter "ProcessId = $pid_" -ErrorAction SilentlyContinue
        $caminhoReal = $cim.ExecutablePath

        Write-Host "`n  -- Informações via WMI (Win32_Process) --" -ForegroundColor $C.I
        $cim | Select-Object Name, ProcessId, ExecutablePath, CommandLine | Format-List

        # 2. Assinatura digital (Authenticode)
        if ($caminhoReal -and (Test-Path $caminhoReal)) {
            Write-Host "  -- Assinatura Digital (Authenticode) --" -ForegroundColor $C.I
            $assinatura = Get-AuthenticodeSignature $caminhoReal
            [PSCustomObject]@{
                Name      = $nome
                Id        = $pid_
                Path      = $caminhoReal
                Assinado  = $assinatura.Status
                Assinante = $assinatura.SignerCertificate.Subject
            } | Format-List

            if ($assinatura.Status -eq 'Valid') {
                Write-Host "  [OK] Assinatura digital VÁLIDA." -ForegroundColor $C.M
            } else {
                Write-Host "  [ATENÇÃO] Assinatura digital: $($assinatura.Status)" -ForegroundColor $C.A
            }

            # 3. Hash do arquivo (para VirusTotal)
            $hash = (Get-FileHash -Path $caminhoReal -Algorithm SHA256 -ErrorAction SilentlyContinue).Hash
            if ($hash) {
                Write-Host "`n  SHA256: $hash" -ForegroundColor $C.I
            }
        } else {
            Write-Host "  [AVISO] Não foi possível acessar o caminho do executavel." -ForegroundColor $C.A
            Write-Host "  Isso e comum em processos protegidos do sistema (ex: MsMpEng.exe)." -ForegroundColor $C.H
            $hash = $null
        }

        # 4. Verificação no nome (Defender e processos conhecidos do Windows)
        $conhecidos = @("MsMpEng", "svchost", "csrss", "wininit", "services", "lsass", "winlogon", "explorer", "dwm", "SearchIndexer", "audiodg")
        if ($conhecidos -contains $nome) {
            Write-Host "`n  [INFO] '$nome' e um processo nativo conhecido do Windows." -ForegroundColor $C.M
            if ($nome -eq "MsMpEng") {
                Write-Host "  Este e o motor de proteccao em tempo real do Windows Defender." -ForegroundColor $C.M
                Write-Host "  Alto uso de CPU/handles e normal durante varreduras." -ForegroundColor $C.M
            }
        }

        # 5. Oferecer VirusTotal
        Write-Host ""
        $abrirVT = Read-Host "  Abrir VirusTotal para verificar este arquivo? [S/N]"
        if ($abrirVT -imatch '^s') {
            if ($hash) {
                Start-Process "https://www.virustotal.com/gui/file/$hash"
                Write-Host "  Abrindo VirusTotal com o hash SHA256 do arquivo..." -ForegroundColor $C.A
            } else {
                Start-Process "https://www.virustotal.com/gui/search/$nome"
                Write-Host "  Abrindo busca do VirusTotal pelo nome '$nome' (hash indisponivel)..." -ForegroundColor $C.A
            }
        }

        Log "Processo suspeito investigado: $nome (PID $pid_) - Path: $caminhoReal"
        Write-Host ""
    }

    P
}

# =============================================================================
# MENU 14: SEGURANÇA DA INFORMAÇÃO
# =============================================================================
function Menu-SegInfo {
    do {
        Cab "14. SEGURANÇA DA INFORMAÇÃO - AUDITORIA E ANTIVÍRUS"
        Write-Host "  -- Auditoria de eventos --------------------------------" -ForegroundColor $C.H
        Write-Host "  1. Processos suspeitos (sem path, alta CPU/handles)" -ForegroundColor $C.M
        Write-Host "  2. Tentativas de logon com falha (força bruta - ID 4625)" -ForegroundColor $C.M
        Write-Host "  3. Criação de contas de usuario (ID 4720)" -ForegroundColor $C.M
        Write-Host "  4. Alterações em grupos privilegiados (ID 4728)" -ForegroundColor $C.M
        Write-Host "  5. Alterações e redefinições de senha (ID 4723/4724)" -ForegroundColor $C.M
        Write-Host "  6. Limpeza de logs de auditoria (ID 1102 - suspeito!)" -ForegroundColor $C.M
        Write-Host "  7. Logons RDP remotos bem-sucedidos (ID 4624 tipo 10)" -ForegroundColor $C.M
        Write-Host "  8. Histórico de logons e logoffs" -ForegroundColor $C.M
        Write-Host "  9. Conexões RDP ativas na rede (porta 3389)" -ForegroundColor $C.M
        Write-Host " 10. Análise completa de segurança (todos os eventos)" -ForegroundColor $C.A
        Write-Host "  -- Antivírus (Defender + MRT) --------------------------" -ForegroundColor $C.H
        Write-Host "  11. Status do Windows Defender" -ForegroundColor $C.M
        Write-Host "  12. Atualizar assinaturas do Defender" -ForegroundColor $C.M
        Write-Host "  13. Scan rápido (Defender)" -ForegroundColor $C.M
        Write-Host "  14. Scan completo (Defender - demora horas)" -ForegroundColor $C.M
        Write-Host "  15. Scan offline (Defender - REINICIA o PC)" -ForegroundColor $C.A
        Write-Host "  16. Ameaças em quarentena / histórico" -ForegroundColor $C.M
        Write-Host "  17. MRT - verificação completa com remoção" -ForegroundColor $C.M
        Write-Host "  18. MRT - verificação completa (só relata)" -ForegroundColor $C.M
        Write-Host "  0. Voltar" -ForegroundColor $C.I
        switch (Read-Host "`n  Opção") {
            "1"  { Verificar-Processos-Suspeitos }
            "2"  { Run "Tentativas de logon com falha (ID 4625)..." "Busca os últimos 50 eventos de falha de autenticação. Muitas falhas seguidas do mesmo IP ou conta indicam ataque de força bruta ou password spraying. Investigue se houver padrão." @('Get-WinEvent -FilterHashtable @{LogName="Security"; Id=4625} -MaxEvents 50 -EA SilentlyContinue | Select-Object @{N="Data";E={$_.TimeCreated}},@{N="Conta";E={$_.Properties[5].Value}},@{N="IP_Origem";E={$_.Properties[18].Value}} | Format-Table -AutoSize') -PS -Win }
            "3"  { Run "Criação de contas de usuario (ID 4720)..." "Verifica os últimos 20 eventos de criação de conta local. Contas criadas sem autorizacao podem indicar comprometimento do sistema ou acesso não autorizado com privilégios elevados." @('Get-WinEvent -FilterHashtable @{LogName="Security"; Id=4720} -MaxEvents 20 -EA SilentlyContinue | Select-Object @{N="Data";E={$_.TimeCreated}},@{N="Nova_Conta";E={$_.Properties[0].Value}},@{N="Criado_Por";E={$_.Properties[4].Value}} | Format-Table -AutoSize') -PS -Win }
            "4"  { Run "Alterações em grupos privilegiados (ID 4728)..." "Verifica adicoes a grupos de segurança privilegiados como Administradores. Alterações não autorizadas podem indicar escalacao de privilégios ou movimento lateral de um invasor." @('Get-WinEvent -FilterHashtable @{LogName="Security"; Id=4728} -MaxEvents 20 -EA SilentlyContinue | Select-Object @{N="Data";E={$_.TimeCreated}},@{N="Membro_Adicionado";E={$_.Properties[0].Value}},@{N="Grupo";E={$_.Properties[2].Value}},@{N="Por";E={$_.Properties[4].Value}} | Format-Table -AutoSize') -PS -Win }
            "5"  { Run "Alterações de senha (ID 4723/4724)..." "Verifica eventos de alteração de senha (4723 = usuario muda propria senha, 4724 = admin redefine senha de outro). Alterações não autorizadas indicam comprometimento ou acesso indevido." @('Get-WinEvent -FilterHashtable @{LogName="Security"; Id=4723,4724} -MaxEvents 20 -EA SilentlyContinue | Select-Object @{N="Data";E={$_.TimeCreated}},@{N="Conta_Alvo";E={$_.Properties[0].Value}},@{N="Alterado_Por";E={$_.Properties[4].Value}},Id | Format-Table -AutoSize') -PS -Win }
            "6"  { Run "Limpeza de logs de segurança (ID 1102)..." "Verifica se o log de auditoria foi limpo. Esta acao e ALTAMENTE SUSPEITA pois atacantes apagam logs para encobrir atividades maliciosas. Qualquer ocorrência não autorizada deve ser investigada imediatamente." @('Get-WinEvent -FilterHashtable @{LogName="Security"; Id=1102} -MaxEvents 10 -EA SilentlyContinue | Select-Object @{N="Data";E={$_.TimeCreated}},@{N="Limpo_Por";E={$_.Properties[0].Value}} | Format-Table -AutoSize') -PS -Win }
            "7"  { Run "Logons RDP remotos (ID 4624, tipo 10)..." "Filtra logons bem-sucedidos do tipo 10 (RemoteInteractive/RDP). Permite rastrear quem acessou o computador remotamente, de qual IP e quando. Acesso não autorizado deve ser investigado." @('Get-WinEvent -FilterHashtable @{LogName="Security"; Id=4624} -MaxEvents 100 -EA SilentlyContinue | Where-Object { $_.Message -like "*Tipo de Logon:*10*" -or $_.Message -like "*Logon Type:*10*" } | Select-Object @{N="Data";E={$_.TimeCreated}},@{N="Conta";E={$_.Properties[5].Value}},@{N="IP_Origem";E={$_.Properties[18].Value}} | Format-Table -AutoSize') -PS -Win }
            "8"  { Run "Histórico de logons e logoffs..." "Exibe os últimos 50 logons (4624) e logoffs (4634) do sistema. Permite auditar quem usou o computador, quando entrou e saiu, e identificar sessões inesperadas." @('Get-WinEvent -FilterHashtable @{LogName="Security"; Id=4624,4634} -MaxEvents 50 -EA SilentlyContinue | Select-Object @{N="Data";E={$_.TimeCreated}},@{N="Evento";E={if($_.Id -eq 4624){"LOGON"}else{"LOGOFF"}}},@{N="Conta";E={$_.Properties[5].Value}} | Format-Table -AutoSize') -PS -Win }
            "9"  { Run "Conexões RDP ativas (porta 3389)..." "Verifica se ha conexões ativas na porta 3389 (Remote Desktop Protocol). Conexões inesperadas podem indicar acesso remoto não autorizado ao computador." @("netstat -ano | findstr :3389", "echo.", "netstat -n | findstr :3389") -Win }
            "10" { Run "Análise completa de segurança..." "Relatório abrangente: logon, logoff, falhas de autenticação, criação de usuario, mudancas de grupo, alterações de senha e limpeza de logs. Últimos 30 eventos de cada ID." @('Get-WinEvent -FilterHashtable @{LogName="Security"; Id=4624,4634,4625,4720,4723,4724,4728,1102} -MaxEvents 30 -EA SilentlyContinue | Select-Object @{N="Data";E={$_.TimeCreated}},@{N="ID";E={$_.Id}},@{N="Resumo";E={$_.Message.Substring(0,[Math]::Min(70,$_.Message.Length))}} | Format-Table -AutoSize -Wrap') -PS -Win }
            "11" { Run "Status do Windows Defender..." "Exibe se a proteção está ativa, a versão das assinaturas e há quantos dias estão desatualizadas. Assinaturas velhas = proteção furada: rode a opção 12 antes de qualquer scan." @("Get-MpComputerStatus | Select-Object AMRunning, AntivirusEnabled, AntivirusSignatureVersion, AntivirusSignatureAge | Format-List") -PS -Win }
            "12" { Run "Atualizando assinaturas do Defender..." "Baixa as definições de vírus mais recentes. Sempre rode antes de um scan para não verificar com base desatualizada." @("Update-MpSignature") -PS -Win }
            "13" { Run "Scan rápido do Defender..." "Verifica os locais onde malware costuma se instalar (memória, registro, pastas de inicialização). Leva alguns minutos." @("Start-MpScan -ScanType QuickScan") -PS -Win }
            "14" { Run "Scan completo do Defender..." "Varre TODOS os arquivos do disco em busca de malware. Pode demorar horas; deixe rodando até o fim. Rode a opção 12 antes." @("Start-MpScan -ScanType FullScan") -PS -Win }
            "15" { Run "Scan offline do Defender..." "Reinicia o PC em ambiente isolado (fora do Windows) para remover pragas persistentes como rootkits. SALVE TUDO antes: o computador vai REINICIAR na hora." @("Start-MpWDOScan") -PS -Win }
            "16" { Run "Ameaças detectadas e quarentena..." "Lista ameaças ativas/em quarentena e o histórico das últimas detecções do Defender, com data e ação tomada." @('Get-MpThreat | Select-Object ThreatName, SeverityID, DidThreatExecute, ActionSuccess | Format-Table -AutoSize', 'Get-MpThreatDetection | Select-Object -First 20 ThreatName, DomainUser, InitialDetectionTime, ActionSuccess | Format-Table -AutoSize') -PS -Win }
            "17" { Run "MRT completo com remoção..." "Microsoft Malicious Software Removal Tool em verificação completa com remoção automática (/f:y). Pode demorar bastante; o relatório final mostra o que foi encontrado e removido." @("mrt.exe /f:y") -Win }
            "18" { Run "MRT completo (só relata)..." "MRT em verificação completa sem remover nada (/f). Use para auditar antes de decidir pela remoção (opção 17)." @("mrt.exe /f") -Win }
            "0"  { return }
            default { Write-Host "  Opção inválida." -ForegroundColor $C.E; Start-Sleep 1 }
        }
    } while ($true)
}

# =============================================================================
# MENU 15: AJUSTES DE DESEMPENHO (REGISTRO)
# =============================================================================
function Menu-Registro {
    do {
        Cab "15. AJUSTES DE DESEMPENHO NO REGISTRO"
        Write-Host "  !!! Crie um ponto de restauração (Menu 9, op.8) antes de continuar !!!" -ForegroundColor $C.A
        Write-Host ""
        Write-Host "  -- Visual e Animações ----------------------------------------" -ForegroundColor $C.H
        Write-Host "   1. Ajustar para melhor desempenho (desativa efeitos visuais)" -ForegroundColor $C.M
        Write-Host "   2. Desativar animações de janelas (minimizar/maximizar)" -ForegroundColor $C.M
        Write-Host "   3. Desativar Aero Shake (agitar janela para minimizar tudo)" -ForegroundColor $C.M
        Write-Host "   4. Reduzir delay do menu Iniciar (400ms --> 20ms)" -ForegroundColor $C.M
        Write-Host "   5. Reduzir delay de startup do Explorer" -ForegroundColor $C.M
        Write-Host "  -- Servicos do Sistema ---------------------------------------" -ForegroundColor $C.H
        Write-Host "   6. Desativar SuperFetch/SysMain (útil para SSDs)" -ForegroundColor $C.M
        Write-Host "   7. Desativar PowerThrottling (remove limite de energia do CPU)" -ForegroundColor $C.M
        Write-Host "   8. Desativar limpeza do pagefile no shutdown" -ForegroundColor $C.M
        Write-Host "  -- Pesquisa e Notificações -----------------------------------" -ForegroundColor $C.H
        Write-Host "   9. Desativar busca na internet pela barra de pesquisa" -ForegroundColor $C.M
        Write-Host "  10. Desativar notificações de balao" -ForegroundColor $C.M
        Write-Host "  11. Desativar Focus Assist (modo foco automático)" -ForegroundColor $C.M
        Write-Host "  12. Desativar instalação silenciosa de apps (Microsoft Store)" -ForegroundColor $C.M
        Write-Host "  -- Telemetria e Privacidade ----------------------------------" -ForegroundColor $C.H
        Write-Host "  13. Desativar Telemetria do Windows (DataCollection)" -ForegroundColor $C.M
        Write-Host "  14. Instruções para desativar algoritmo de Nagle (latência)" -ForegroundColor $C.M
        Write-Host "  -- Em lote ---------------------------------------------------" -ForegroundColor $C.H
        Write-Host "  15. APLICAR TODOS os ajustes (executa do 1 ao 13)" -ForegroundColor $C.A
        Write-Host "  16. RESTAURAR TODOS (desfaz do 1 ao 13, volta ao padrão)" -ForegroundColor $C.M
        Write-Host "   0. Voltar" -ForegroundColor $C.I
        switch (Read-Host "`n  Opção") {
            "1"  { Run "Ajustando para melhor desempenho visual..." "Altera o VisualFXSetting para 2 (melhor desempenho). Equivale a ir em Propriedades do Sistema > Avancado > Desempenho > Ajustar para melhor desempenho. Desativa sombras, animações e transparências." @('REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 2 /f', 'REG ADD "HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 2 /f') -Win }
            "2"  { Run "Desativando animações de janelas..." "Desativa a animação de minimizar e maximizar janelas. As janelas passam a aparecer e sumir instantaneamente. Melhora a percepcao de velocidade do sistema, especialmente em máquinas mais lentas." @('REG ADD "HKCU\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_DWORD /d 0 /f') -Win }
            "3"  { Run "Desativando Aero Shake..." "Desativa o gesto de sacudir uma janela para minimizar todas as outras. Previne minimizacoes acidentais ao mover janelas rapidamente." @('REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v DisallowShaking /t REG_DWORD /d 1 /f') -Win }
            "4"  { Run "Reduzindo delay do menu Iniciar..." "Reduz o MenuShowDelay de 400ms (padrão) para 20ms. Os menus de contexto e submenus respondem muito mais rápido ao hover do mouse." @('reg add "HKCU\Control Panel\Desktop" /v MenuShowDelay /t REG_SZ /d 20 /f') -Win }
            "5"  { Run "Reduzindo delay de startup..." "Define StartupDelayInMSec = 0, removendo o atraso artificial que o Windows adiciona antes de iniciar programas na inicialização. O desktop fica funcional mais rápido." @('reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer" /v StartupDelayInMSec /t REG_DWORD /d 0 /f') -Win }
            "6"  { Run "Desativando SuperFetch/SysMain..." "Desativa o servico SysMain (SuperFetch), que pré-carrega aplicativos na RAM antecipando o uso. Em SSDs rápidos esse servico gera picos de I/O sem beneficio pratico e pode ser desativado com segurança." @('REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v EnableSuperfetch /t REG_DWORD /d 0 /f', 'REG ADD "HKLM\SYSTEM\CurrentControlSet\Services\SysMain" /v Start /t REG_DWORD /d 4 /f') -Win }
            "7"  { Run "Desativando PowerThrottling..." "Desativa a limitação de energia do processador imposta pelo Windows (PowerThrottling). O CPU não terá mais sua frequência reduzida em processos de segundo plano. Aumenta performance em troca de mais consumo energetico." @('REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /v PowerThrottlingOff /t REG_DWORD /d 1 /f') -Win }
            "8"  { Run "Desativando limpeza do pagefile no shutdown..." "Impede que o Windows apague o arquivo de paginacao (pagefile.sys) durante o desligamento. Essa limpeza, quando ativa, atrasa o desligamento. Desativar e seguro na maioria dos ambientes." @('REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v ClearPageFileAtShutdown /t REG_DWORD /d 0 /f') -Win }
            "9"  { Run "Desativando pesquisa na internet..." "Remove sugestões do Bing e pesquisa na web a partir da barra de pesquisa do Windows. A busca ficara restrita a arquivos e aplicativos locais, com resultado muito mais rápido." @('reg add "HKCU\Software\Policies\Microsoft\Windows\Explorer" /v DisableSearchBoxSuggestions /t REG_DWORD /d 1 /f', 'reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\SearchSettings" /v IsDynamicSearchBoxEnabled /t REG_DWORD /d 0 /f') -Win }
            "10" { Run "Desativando notificações de balao..." "Remove as notificações em balao da bandeja do sistema. Reduz interrupcoes e libera levemente recursos de renderizacao." @('REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v EnableBallooTips /t REG_DWORD /d 0 /F') -Win }
            "11" { Run "Desativando Focus Assist automático..." "Desativa o modo de foco que ativa automaticamente em certas condições (ex: durante apresentacoes), garantindo que notificações importantes não sejam bloqueadas sem que o usuario saiba." @('REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\FocusAssist" /v Disabled /t REG_DWORD /d 1 /f') -Win }
            "12" { Run "Desativando instalação silenciosa de apps..." "Impede que o Windows instale apps automaticamente em segundo plano sem solicitacao do usuario. Libera espaço em disco e evita aplicativos não desejados da Microsoft Store." @('REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SilentInstalledAppsEnabled /t REG_DWORD /d 0 /F') -Win }
            "13" { Run "Desativando Telemetria (DataCollection)..." "Define AllowTelemetry = 0, impedindo o Windows de coletar e enviar dados de diagnóstico e uso para a Microsoft. Reduz tráfego de rede em segundo plano e uso de CPU para coleta de dados." @('REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f') -Win }
            "14" {
                L; Write-Host ""
                Write-Host "  == INSTRUÇÕES: DESATIVAR ALGORITMO DE NAGLE (melhora latência) ==" -ForegroundColor $C.A
                Write-Host ""
                Write-Host "  O algoritmo de Nagle agrupa pacotes pequenos para otimizar" -ForegroundColor $C.I
                Write-Host "  o tráfego, mas aumenta a latência em conexões interativas." -ForegroundColor $C.I
                Write-Host "  Desativa-lo melhora a resposta em jogos e acesso remoto." -ForegroundColor $C.I
                Write-Host ""
                Write-Host "  PASSO 1: Execute ipconfig e anote o sufixo DNS da placa ativa." -ForegroundColor $C.A
                Write-Host "  PASSO 2: Abra o Regedit e va para:" -ForegroundColor $C.A
                Write-Host "    HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" -ForegroundColor $C.I
                Write-Host "  PASSO 3: Localize a subchave com o GUID da placa conectada" -ForegroundColor $C.A
                Write-Host "           (e a que tem o seu IP listado)." -ForegroundColor $C.I
                Write-Host "  PASSO 4: Dentro dessa subchave, crie dois valores DWORD 32-bit:" -ForegroundColor $C.A
                Write-Host "           - TCPNoDelay      = 1" -ForegroundColor $C.I
                Write-Host "           - TcpAckFrequency = 1" -ForegroundColor $C.I
                Write-Host "  PASSO 5: Reinicie o computador." -ForegroundColor $C.A
                Write-Host ""
                $ab = Read-Host "  Abrir o Regedit agora? [S/N]"
                if ($ab -imatch '^s') { Start-Process regedit.exe }
                P
            }
            "15" { Run "Aplicando TODOS os ajustes (1-13)..." "Aplica de uma vez todos os ajustes das opções 1 a 13 deste menu (exatamente os mesmos comandos das opções individuais). Alguns efeitos exigem logoff ou reinicialização. Recomendado: crie um ponto de restauração antes (Menu 9, opção 8)." @('REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 2 /f', 'REG ADD "HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 2 /f', 'REG ADD "HKCU\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_DWORD /d 0 /f', 'REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v DisallowShaking /t REG_DWORD /d 1 /f', 'reg add "HKCU\Control Panel\Desktop" /v MenuShowDelay /t REG_SZ /d 20 /f', 'reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer" /v StartupDelayInMSec /t REG_DWORD /d 0 /f', 'REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v EnableSuperfetch /t REG_DWORD /d 0 /f', 'REG ADD "HKLM\SYSTEM\CurrentControlSet\Services\SysMain" /v Start /t REG_DWORD /d 4 /f', 'REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /v PowerThrottlingOff /t REG_DWORD /d 1 /f', 'REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v ClearPageFileAtShutdown /t REG_DWORD /d 0 /f', 'reg add "HKCU\Software\Policies\Microsoft\Windows\Explorer" /v DisableSearchBoxSuggestions /t REG_DWORD /d 1 /f', 'reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\SearchSettings" /v IsDynamicSearchBoxEnabled /t REG_DWORD /d 0 /f', 'REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v EnableBallooTips /t REG_DWORD /d 0 /F', 'REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\FocusAssist" /v Disabled /t REG_DWORD /d 1 /f', 'REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SilentInstalledAppsEnabled /t REG_DWORD /d 0 /F', 'REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f') -Win }
            "16" { Run "Restaurando TODOS os ajustes (1-13)..." "Desfaz todos os ajustes das opções 1 a 13, voltando cada valor ao padrão do Windows (remove os valores criados pelo menu e restaura os originais). Mensagens de erro 'não encontrado' são normais e podem ser ignoradas." @('REG DELETE "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /f', 'REG DELETE "HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /f', 'REG ADD "HKCU\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_DWORD /d 1 /f', 'REG DELETE "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v DisallowShaking /f', 'reg add "HKCU\Control Panel\Desktop" /v MenuShowDelay /t REG_SZ /d 400 /f', 'REG DELETE "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer" /v StartupDelayInMSec /f', 'REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v EnableSuperfetch /t REG_DWORD /d 3 /f', 'REG ADD "HKLM\SYSTEM\CurrentControlSet\Services\SysMain" /v Start /t REG_DWORD /d 2 /f', 'REG DELETE "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /v PowerThrottlingOff /f', 'REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v ClearPageFileAtShutdown /t REG_DWORD /d 0 /f', 'reg add "HKCU\Software\Policies\Microsoft\Windows\Explorer" /v DisableSearchBoxSuggestions /t REG_DWORD /d 0 /f', 'reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\SearchSettings" /v IsDynamicSearchBoxEnabled /t REG_DWORD /d 1 /f', 'REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v EnableBallooTips /t REG_DWORD /d 1 /f', 'REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\FocusAssist" /v Disabled /t REG_DWORD /d 0 /f', 'REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SilentInstalledAppsEnabled /t REG_DWORD /d 1 /f', 'REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 1 /f') -Win }
            "0"  { return }
            default { Write-Host "  Opção inválida." -ForegroundColor $C.E; Start-Sleep 1 }
        }
    } while ($true)
}

# =============================================================================
# MENU 16: ATUALIZAÇÃO DO WINDOWS
# =============================================================================
function Menu-Update {
    do {
        Cab "16. ATUALIZAÇÃO DO WINDOWS (PSWindowsUpdate)"
        Write-Host "  1. Verificar política de execução atual" -ForegroundColor $C.M
        Write-Host "  2. Preparar ambiente (instalar módulo PSWindowsUpdate)" -ForegroundColor $C.M
        Write-Host "  3. Verificar atualizações disponíveis" -ForegroundColor $C.M
        Write-Host "  4. Instalar atualizações (com reinicialização automatica)" -ForegroundColor $C.M
        Write-Host "  5. Instalar atualizações (sem reinicialização automatica)" -ForegroundColor $C.M
        Write-Host "  6. Forçar atualização de políticas de grupo (gpupdate)" -ForegroundColor $C.M
        Write-Host "  0. Voltar" -ForegroundColor $C.I
        switch (Read-Host "`n  Opção") {
            "1" {
                Write-Host "`n  Execution Policy atual por escopo:" -ForegroundColor $C.A
                Get-ExecutionPolicy -List | Format-Table -AutoSize
                P
            }
            "2" { Run "Instalando módulo PSWindowsUpdate..." "Define a política RemoteSigned temporariamente e instala o módulo PSWindowsUpdate da PowerShell Gallery. Este módulo permite gerenciar atualizações Windows via linha de comando." @('Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force; if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) { Install-Module PSWindowsUpdate -Force -Confirm:$false }; Write-Host "Módulo PSWindowsUpdate pronto!"') -PS -Win }
            "3" { Run "Verificando atualizações disponíveis..." "Conecta ao Windows Update e lista todas as atualizações pendentes com titulo, tamanho e classificacao. Não instala nada, apenas mostra o que esta disponível." @("Import-Module PSWindowsUpdate -EA Stop; Get-WindowsUpdate") -PS -Win }
            "4" { Run "Instalando atualizações (auto-reboot)..." "Instala todas as atualizações pendentes e reinicia o computador automaticamente se necessário. Use quando puder reiniciar imediatamente após a manutenção." @("Import-Module PSWindowsUpdate -EA Stop; Install-WindowsUpdate -AcceptAll -AutoReboot") -PS -Win }
            "5" { Run "Instalando atualizações (sem reboot)..." "Instala todas as atualizações pendentes sem reiniciar automaticamente. Você devera reiniciar manualmente depois para completar a instalação de alguns pacotes." @("Import-Module PSWindowsUpdate -EA Stop; Install-WindowsUpdate -AcceptAll -IgnoreReboot") -PS -Win }
            "6" { Run "Forcando atualização de GPO..." "Força a aplicação imediata de todas as Políticas de Grupo do computador e do usuario. Útil após mudancas no Active Directory ou configurações de domínio." @("gpupdate /force") -Win }
            "0" { return }
            default { Write-Host "  Opção inválida." -ForegroundColor $C.E; Start-Sleep 1 }
        }
    } while ($true)
}

# =============================================================================
# MENU 17: WINGET (USUARIO COMUM - SEM ADMIN)
# =============================================================================
function Menu-Winget {
    do {
        Cab "17. WINGET - GERENCIADOR DE PACOTES"
        Write-Host "  [!] Winget SEMPRE executa em contexto de usuario comum" -ForegroundColor $C.D
        Write-Host "  [!] Uma nova janela CMD será aberta para interação" -ForegroundColor $C.D
        Write-Host ""
        Write-Host "  1. Verificar versão do Winget instalado" -ForegroundColor $C.M
        Write-Host "  2. Listar todos os aplicativos atualizáveis" -ForegroundColor $C.M
        Write-Host "  3. Atualizar TODOS os aplicativos" -ForegroundColor $C.M
        Write-Host "  4. Buscar aplicativo pelo nome" -ForegroundColor $C.M
        Write-Host "  5. Listar todos os aplicativos instalados via Winget" -ForegroundColor $C.M
        Write-Host "  6. Abrir Microsoft Store para instalar o Winget" -ForegroundColor $C.M
        Write-Host "  0. Voltar" -ForegroundColor $C.I
        switch (Read-Host "`n  Opção") {
            "1" { Run "Verificando versão do Winget..." "Exibe a versão atual do Winget (Windows Package Manager) instalada no sistema. Se o comando não for reconhecido, instale o App Installer pela Microsoft Store (opção 6)." @("winget --version") -SemAdmin }
            "2" { Run "Listando aplicativos atualizáveis..." "Consulta o repositorio do Winget e lista todos os aplicativos instalados que possuem uma versão mais recente disponível, com nome, versão atual e versão nova." @("winget upgrade") -SemAdmin }
            "3" { Run "Atualizando todos os aplicativos..." "Atualiza automaticamente todos os aplicativos que possuem nova versão disponível no repositorio do Winget. O processo e interativo: pode pedir confirmacao para cada app." @("winget upgrade --all --accept-package-agreements --accept-source-agreements") -SemAdmin }
            "4" {
                $busca = Read-Host "  Nome do aplicativo para buscar"
                if ($busca) { Run "Buscando '$busca' no Winget..." "Pesquisa o repositorio do Winget por aplicativos que correspondam ao nome informado. Exibe ID do pacote, nome, versão e fonte para posterior instalação." @("winget search `"$busca`"") -SemAdmin }
            }
            "5" { Run "Listando todos os apps instalados via Winget..." "Exibe a lista completa de aplicativos gerenciados pelo Winget com ID, versão instalada e fonte. Útil para auditoria de software." @("winget list") -SemAdmin }
            "6" {
                Write-Host "  Abrindo Microsoft Store para instalar o App Installer (Winget)..." -ForegroundColor $C.A
                Start-Process "ms-windows-store://pdp/?ProductId=9nblggh4nns1"
                P
            }
            "0" { return }
            default { Write-Host "  Opção inválida." -ForegroundColor $C.E; Start-Sleep 1 }
        }
    } while ($true)
}

# =============================================================================
# TESTE DE VELOCIDADE NATIVO (download + upload via Cloudflare, sem navegador)
# =============================================================================
function Teste-Velocidade {
    L; Cab "TESTE DE VELOCIDADE - INTERNET"
    Write-Host "  Servidor: Cloudflare (speed.cloudflare.com)" -ForegroundColor $C.H
    Write-Host ""
    Write-Host "  Medindo latência (ping 1.1.1.1, 4 pacotes)..." -ForegroundColor $C.I
    try {
        $p = Test-Connection -ComputerName 1.1.1.1 -Count 4 -ErrorAction Stop
        $ok = @($p | Where-Object { $_.StatusCode -eq 0 })
        $lat = [math]::Round(($ok | Measure-Object ResponseTime -Average).Average, 1)
        Write-Host "  Latência média: $lat ms (perda: $($p.Count - $ok.Count)/$($p.Count))" -ForegroundColor $C.M
    } catch {
        Write-Host "  [ERRO] Sem resposta. Verifique a conexão com a internet." -ForegroundColor $C.E
        Log "Teste de velocidade: sem conectividade" "AVISO"; P; return
    }
    Write-Host ""
    try {
        Add-Type -AssemblyName System.Net.Http
        $cli = New-Object Net.Http.HttpClient
        $cli.Timeout = [TimeSpan]::FromSeconds(120)
        Write-Host "  Baixando 25 MB (teste de download)..." -ForegroundColor $C.I
        $sw = [Diagnostics.Stopwatch]::StartNew()
        $stream = $cli.GetStreamAsync("https://speed.cloudflare.com/__down?bytes=25000000").GetAwaiter().GetResult()
        $buf = New-Object byte[] 65536
        $total = 0; $marco = 0
        do {
            $n = $stream.Read($buf, 0, $buf.Length)
            $total += $n
            if ($total - $marco -ge 5MB) { $marco = $total; Write-Host "    $([math]::Round($total/1MB,1)) MB..." -ForegroundColor $C.H }
        } while ($n -gt 0)
        $sw.Stop(); $stream.Close()
        $down = [math]::Round($total * 8 / $sw.Elapsed.TotalSeconds / 1MB, 1)
        Write-Host "  Download: $down Mbps ($([math]::Round($total/1MB,1)) MB em $([math]::Round($sw.Elapsed.TotalSeconds,1)) s)" -ForegroundColor $C.M
        Write-Host ""
        Write-Host "  Enviando 5 MB (teste de upload)..." -ForegroundColor $C.I
        $up = New-Object byte[] (5MB); (New-Object Random).NextBytes($up)
        $swUp = [Diagnostics.Stopwatch]::StartNew()
        $resp = $cli.PostAsync("https://speed.cloudflare.com/__up", (New-Object Net.Http.ByteArrayContent(,$up))).GetAwaiter().GetResult()
        $swUp.Stop(); $resp.Dispose(); $cli.Dispose()
        $upMbps = [math]::Round(5 * 8 / $swUp.Elapsed.TotalSeconds, 1)
        Write-Host "  Upload: $upMbps Mbps (5 MB em $([math]::Round($swUp.Elapsed.TotalSeconds,1)) s)" -ForegroundColor $C.M
        Log "Teste de velocidade: down ${down} Mbps / up ${upMbps} Mbps / lat ${lat} ms"
    } catch {
        Write-Host "  [ERRO] Falha no teste: $($_.Exception.Message)" -ForegroundColor $C.E
        Log "Teste de velocidade: erro - $($_.Exception.Message)" "AVISO"
    }
    P
}

# =============================================================================
# MENU 18: UTILIDADES RÁPIDAS (trazidas do script clássico KlaytonBuenoPrince.bat)
# =============================================================================
function Menu-Utilidades {
    do {
        Cab "18. UTILIDADES RÁPIDAS"
        Write-Host "  Itens não cobertos pelos outros menus, herdados do" -ForegroundColor $C.H
        Write-Host "  script clássico KlaytonBuenoPrince.bat." -ForegroundColor $C.H
        Write-Host ""
        Write-Host "   1. Ping (20 pacotes no destino)" -ForegroundColor $C.M
        Write-Host "   2. Teste de velocidade (nativo, sem navegador)" -ForegroundColor $C.M
        Write-Host "   3. Informações do sistema (msinfo32)" -ForegroundColor $C.M
        Write-Host "   4. Mouse (main.cpl)" -ForegroundColor $C.M
        Write-Host "   5. Configuração do sistema (msconfig)" -ForegroundColor $C.M
        Write-Host "   6. Programas e Recursos (appwiz.cpl)" -ForegroundColor $C.M
        Write-Host "   7. Calculadora" -ForegroundColor $C.M
        Write-Host "   8. Editor do Registro (regedit)" -ForegroundColor $C.M
        Write-Host "   0. Voltar" -ForegroundColor $C.I
        switch (Read-Host "`n  Opção") {
            "1" {
                $dest = Read-Host "  Destino (Enter = 8.8.8.8)"
                if ([string]::IsNullOrWhiteSpace($dest)) { $dest = "8.8.8.8" }
                Run "Ping em $dest (20 pacotes)..." "Envia 20 pacotes ICMP ao destino e exibe tempos de resposta e perdas. Útil para checar a conectividade básica antes de diagnósticos mais profundos." @("ping -n 20 $dest") -Win
            }
            "2" { Teste-Velocidade }
            "3" { Start-Process msinfo32.exe; Write-Host "  Abrindo Informações do Sistema..." -ForegroundColor $C.A; P }
            "4" { Start-Process main.cpl; Write-Host "  Abrindo configurações do mouse..." -ForegroundColor $C.A; P }
            "5" { Start-Process msconfig.exe; Write-Host "  Abrindo Configuração do Sistema..." -ForegroundColor $C.A; P }
            "6" { Start-Process appwiz.cpl; Write-Host "  Abrindo Programas e Recursos..." -ForegroundColor $C.A; P }
            "7" { Start-Process calc.exe; Write-Host "  Abrindo Calculadora..." -ForegroundColor $C.A; P }
            "8" { Run "Abrindo Editor do Registro..." "Abre o regedit. Navegue com cuidado: alterações incorretas podem impedir o Windows de iniciar. Prefira o Menu 15 para ajustes guiados e seguros." @("regedit.exe") -Win }
            "0"  { return }
            default { Write-Host "  Opção inválida." -ForegroundColor $C.E; Start-Sleep 1 }
        }
    } while ($true)
}

# =============================================================================
# MENU 19: MENU DE CONTEXTO (clássico do Win11 + atalhos T! SOS no desktop)
# =============================================================================
function Menu-Contexto {
    do {
        Cab "19. MENU DE CONTEXTO"
        Write-Host "  Gerencia o menu de botão direito da área de trabalho." -ForegroundColor $C.H
        Write-Host ""
        Write-Host "  -- Menu clássico do Windows 11 -------------------------" -ForegroundColor $C.H
        Write-Host "   1. Ativar menu clássico (restaura o antigo)" -ForegroundColor $C.M
        Write-Host "   2. Desativar menu clássico (volta ao moderno)" -ForegroundColor $C.M
        Write-Host "  -- Atalhos T! SOS no menu ------------------------------" -ForegroundColor $C.H
        Write-Host "   3. Adicionar atalhos (Chrome, Firefox, travas, Explorer)" -ForegroundColor $C.M
        Write-Host "   4. Remover atalhos T! SOS" -ForegroundColor $C.M
        Write-Host "   0. Voltar" -ForegroundColor $C.I
        switch (Read-Host "`n  Opção") {
            "1" { Run "Ativando menu clássico..." "Cria a chave InprocServer32 vazia que restaura o menu de contexto clássico no Windows 11. O Explorer sera reiniciado para aplicar de imediato." @('REG ADD "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /ve /f', 'taskkill /f /im explorer.exe', 'start explorer.exe') -Win }
            "2" { Run "Desativando menu clássico..." "Remove a chave InprocServer32 e volta ao menu de contexto moderno do Windows 11. O Explorer sera reiniciado para aplicar de imediato." @('REG DELETE "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" /f', 'taskkill /f /im explorer.exe', 'start explorer.exe') -Win }
            "3" { Run "Adicionando atalhos T! SOS..." "Cria 6 atalhos no menu de botão direito do desktop: contato T! SOS, Google Chrome, Firefox, encerrar processos travados, reiniciar o Explorer (corrige barra sumida) e abrir pastas temporárias. Requer que Chrome/Firefox estejam instalados para esses dois funcionarem." @('New-Item -Path Registry::HKEY_CLASSES_ROOT\DesktopBackground\Shell\googleChrome -Force | Out-Null', 'Set-ItemProperty -Path Registry::HKEY_CLASSES_ROOT\DesktopBackground\Shell\googleChrome -Name icon -Value "taskmgr.exe,-30651"', 'Set-ItemProperty -Path Registry::HKEY_CLASSES_ROOT\DesktopBackground\Shell\googleChrome -Name MUIVerb -Value "T! SOS - Google Chrome"', 'Set-ItemProperty -Path Registry::HKEY_CLASSES_ROOT\DesktopBackground\Shell\googleChrome -Name Position -Value "Top"', 'New-Item -Path Registry::HKEY_CLASSES_ROOT\DesktopBackground\Shell\googleChrome\command -Force | Out-Null', 'Set-ItemProperty -Path Registry::HKEY_CLASSES_ROOT\DesktopBackground\Shell\googleChrome\command -Name "(default)" -Value "cmd.exe /C start chrome"', 'New-Item -Path Registry::HKEY_CLASSES_ROOT\DesktopBackground\Shell\FireFox -Force | Out-Null', 'Set-ItemProperty -Path Registry::HKEY_CLASSES_ROOT\DesktopBackground\Shell\FireFox -Name icon -Value "taskmgr.exe,-30651"', 'Set-ItemProperty -Path Registry::HKEY_CLASSES_ROOT\DesktopBackground\Shell\FireFox -Name MUIVerb -Value "T! SOS - Firefox"', 'Set-ItemProperty -Path Registry::HKEY_CLASSES_ROOT\DesktopBackground\Shell\FireFox -Name Position -Value "Top"', 'New-Item -Path Registry::HKEY_CLASSES_ROOT\DesktopBackground\Shell\FireFox\command -Force | Out-Null', 'Set-ItemProperty -Path Registry::HKEY_CLASSES_ROOT\DesktopBackground\Shell\FireFox\command -Name "(default)" -Value "cmd.exe /C start firefox"', 'New-Item -Path Registry::HKEY_CLASSES_ROOT\DesktopBackground\Shell\encerrarProcessosTravados -Force | Out-Null', 'Set-ItemProperty -Path Registry::HKEY_CLASSES_ROOT\DesktopBackground\Shell\encerrarProcessosTravados -Name icon -Value "taskmgr.exe,-30651"', 'Set-ItemProperty -Path Registry::HKEY_CLASSES_ROOT\DesktopBackground\Shell\encerrarProcessosTravados -Name MUIVerb -Value "T! SOS - Encerrar processos travados"', 'Set-ItemProperty -Path Registry::HKEY_CLASSES_ROOT\DesktopBackground\Shell\encerrarProcessosTravados -Name Position -Value "Top"', 'New-Item -Path Registry::HKEY_CLASSES_ROOT\DesktopBackground\Shell\encerrarProcessosTravados\command -Force | Out-Null', 'Set-ItemProperty -Path Registry::HKEY_CLASSES_ROOT\DesktopBackground\Shell\encerrarProcessosTravados\command -Name "(default)" -Value "cmd.exe /C taskkill.exe /f /fi \"STATUS eq NOT RESPONDING\""', 'New-Item -Path Registry::HKEY_CLASSES_ROOT\DesktopBackground\Shell\reiniciarSO -Force | Out-Null', 'Set-ItemProperty -Path Registry::HKEY_CLASSES_ROOT\DesktopBackground\Shell\reiniciarSO -Name icon -Value "taskmgr.exe,-30651"', 'Set-ItemProperty -Path Registry::HKEY_CLASSES_ROOT\DesktopBackground\Shell\reiniciarSO -Name MUIVerb -Value "T! SOS - Reiniciar Explorer (corrige barra sumida)"', 'Set-ItemProperty -Path Registry::HKEY_CLASSES_ROOT\DesktopBackground\Shell\reiniciarSO -Name Position -Value "Top"', 'New-Item -Path Registry::HKEY_CLASSES_ROOT\DesktopBackground\Shell\reiniciarSO\command -Force | Out-Null', 'Set-ItemProperty -Path Registry::HKEY_CLASSES_ROOT\DesktopBackground\Shell\reiniciarSO\command -Name "(default)" -Value "cmd.exe /C taskkill /f /im explorer.exe & start explorer.exe"', 'New-Item -Path Registry::HKEY_CLASSES_ROOT\DesktopBackground\Shell\KBP -Force | Out-Null', 'Set-ItemProperty -Path Registry::HKEY_CLASSES_ROOT\DesktopBackground\Shell\KBP -Name icon -Value "taskmgr.exe,-30651"', 'Set-ItemProperty -Path Registry::HKEY_CLASSES_ROOT\DesktopBackground\Shell\KBP -Name MUIVerb -Value "T! SOS Sistemas"', 'Set-ItemProperty -Path Registry::HKEY_CLASSES_ROOT\DesktopBackground\Shell\KBP -Name Position -Value "Top"', 'New-Item -Path Registry::HKEY_CLASSES_ROOT\DesktopBackground\Shell\KBP\command -Force | Out-Null', 'Set-ItemProperty -Path Registry::HKEY_CLASSES_ROOT\DesktopBackground\Shell\KBP\command -Name "(default)" -Value "cmd.exe /C start mailto:tisossistemas@gmail.com"', 'New-Item -Path Registry::HKEY_CLASSES_ROOT\DesktopBackground\Shell\limparPastaPrefeth -Force | Out-Null', 'Set-ItemProperty -Path Registry::HKEY_CLASSES_ROOT\DesktopBackground\Shell\limparPastaPrefeth -Name icon -Value "taskmgr.exe,-30651"', 'Set-ItemProperty -Path Registry::HKEY_CLASSES_ROOT\DesktopBackground\Shell\limparPastaPrefeth -Name MUIVerb -Value "T! SOS - Abrir pastas temporárias"', 'Set-ItemProperty -Path Registry::HKEY_CLASSES_ROOT\DesktopBackground\Shell\limparPastaPrefeth -Name Position -Value "Top"', 'New-Item -Path Registry::HKEY_CLASSES_ROOT\DesktopBackground\Shell\limparPastaPrefeth\command -Force | Out-Null', 'Set-ItemProperty -Path Registry::HKEY_CLASSES_ROOT\DesktopBackground\Shell\limparPastaPrefeth\command -Name "(default)" -Value "cmd.exe /C start %windir%\prefetch & start %temp% & start temp"') -PS -Win }
            "4" { Run "Removendo atalhos T! SOS..." "Apaga os 6 atalhos criados pela opção 3. Não mexe no menu clássico/moderno (opções 1 e 2)." @('REG DELETE "HKCR\DesktopBackground\Shell\googleChrome" /f', 'REG DELETE "HKCR\DesktopBackground\Shell\FireFox" /f', 'REG DELETE "HKCR\DesktopBackground\Shell\encerrarProcessosTravados" /f', 'REG DELETE "HKCR\DesktopBackground\Shell\reiniciarSO" /f', 'REG DELETE "HKCR\DesktopBackground\Shell\KBP" /f', 'REG DELETE "HKCR\DesktopBackground\Shell\limparPastaPrefeth" /f') -Win }
            "0"  { return }
            default { Write-Host "  Opção inválida." -ForegroundColor $C.E; Start-Sleep 1 }
        }
    } while ($true)
}

# =============================================================================
# MENU PRINCIPAL
# =============================================================================
function Menu-Principal {
    do {
        Cab
        $st = if ($script:isAdmin) { "[ADMIN]" } else { "[USUARIO]" }
        # Write-Host "  Status: $st | Log: $($APP.Log)" -ForegroundColor $(if ($script:isAdmin) { $C.M } else { $C.E })  # mostra o caminho do log
        Write-Host "  Status: $st " -ForegroundColor $(if ($script:isAdmin) { $C.M } else { $C.E })
        Write-Host ""
        Write-Host "  -- MANUTENÇÃO ----------------------------------------" -ForegroundColor $C.H
        Write-Host "   1. Reparo e Integridade do Sistema  (DISM, SFC)" -ForegroundColor $C.M
        Write-Host "   2. Discos e Armazenamento           (SMART, CHKDSK, TRIM)" -ForegroundColor $C.M
        Write-Host "   3. Drivers                          (PnPUtil)" -ForegroundColor $C.M
        Write-Host "   4. Impressão e Spooler" -ForegroundColor $C.M
        Write-Host "   5. Energia e Desempenho             (powercfg, relatórios)" -ForegroundColor $C.M
        Write-Host "   6. Memória RAM                      (diagnóstico, info)" -ForegroundColor $C.M
        Write-Host "   7. Rede e DNS                       (TCP/IP, flush, IP estático)" -ForegroundColor $C.M
        Write-Host "   8. Limpeza e Manutenção             (temp, cache WU)" -ForegroundColor $C.M
        Write-Host "  -- SEGURANÇA -----------------------------------------" -ForegroundColor $C.H
        Write-Host "   9. Segurança e Permissões           (ICACLS, USB, Firewall)" -ForegroundColor $C.M
        Write-Host "  14. Segurança da Informação          (auditoria de eventos)" -ForegroundColor $C.M
        Write-Host "  -- DIAGNÓSTICO ---------------------------------------" -ForegroundColor $C.H
        Write-Host "  10. Diagnóstico Avancado             (processos, WinSAT, wmic)" -ForegroundColor $C.M
        Write-Host "  11. Placa de Vídeo e Monitor         (dxdiag, DCOM, GPU)" -ForegroundColor $C.M
        Write-Host "  -- CONFIGURAÇÃO --------------------------------------" -ForegroundColor $C.H
        Write-Host "  12. Identidade do Sistema            (PC, usuario, IP)" -ForegroundColor $C.M
        Write-Host "  15. Ajustes de Desempenho            (Registro do Windows)" -ForegroundColor $C.M
        Write-Host "  -- TESTES E ATUALIZAÇÕES -----------------------------" -ForegroundColor $C.H
        Write-Host "  13. Testes de Stress                 (CPU multinucleo)" -ForegroundColor $C.M
        Write-Host "  16. Atualização do Windows           (PSWindowsUpdate)" -ForegroundColor $C.M
        Write-Host "  17. Winget                           (usuario comum)" -ForegroundColor $C.M
        Write-Host "  -- UTILIDADES ------------------------------------------" -ForegroundColor $C.H
        Write-Host "  18. Utilidades Rápidas              (ping, velocidade, msinfo32)" -ForegroundColor $C.M
        Write-Host "  19. Menu de Contexto               (clássico Win11 + atalhos)" -ForegroundColor $C.M
        Write-Host ""
        Write-Host "   0. Sair" -ForegroundColor $C.E
        Write-Host ""
        switch (Read-Host "  Opção") {


        

         
            "teste" { Run "Teste..." "Apenas um teste latino americano, sem um deploy tranquilo, sem um log que me conforte, mais trago na cabeça a lição do meu SRPINT" @("winver") -Win -PS -SemAdmin }     # -PS  Usar PowerShell (padrão = CMD),             -Win   Abrir em nova janela,          -SemAdmin   Sem elevação
            "1"  { Menu-Reparo }
            "2"  { Menu-Discos }
            "3"  { Menu-Drivers }
            "4"  { Menu-Impressao }
            "5"  { Menu-Energia }
            "6"  { Menu-Memoria }
            "7"  { Menu-Rede }
            "8"  { Menu-Limpeza }
            "9"  { Menu-Seguranca }
            "10" { Menu-Diagnostico }
            "11" { Menu-Video }
            "12" { Menu-Identidade }
            "13" { Menu-Stress }
            "14" { Menu-SegInfo }
            "15" { Menu-Registro }
            "16" { Menu-Update }
            "17" { Menu-Winget }
            "18" { Menu-Utilidades }
            "19" { Menu-Contexto }
            "0"  {
                Write-Host "`n  Encerrando T! SOS Sistemas Ferramenta Técnica..." -ForegroundColor $C.A
                Log "Sessão encerrada pelo usuario."
                Start-Sleep 1; return
            }
            default { Write-Host "  Opção inválida. Tente novamente." -ForegroundColor $C.E; Start-Sleep 1 }
        }
    } while ($true)
}

# =============================================================================
# PONTO DE ENTRADA
# =============================================================================
Fixar-Janela       # 0. Dimensiona a janela em pixels e trava botoes max/min
Garantir-Admin    # 1. Garante execução como Administrador (eleva via UAC se necessário)
Autenticar        # 2. Autentica com senha (caveira + segurança obrigatória)
Menu-Principal    # 3. Exibe o menu principal