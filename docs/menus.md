# Menus

> **EN:** Quick reference for the 21 `Menu-Principal` menus. Every option runs through the `Run` helper and is written to the log.
> **PT:** Referência rápida dos 21 menus do `Menu-Principal`. Toda opção executa via função auxiliar `Run` e é registrada no log.
> **EN:** Every menu accepts multi-select: type `2,3,10`, ranges like `1-3`, `TODOS`, or press ENTER to run all options in sequence (`0` goes back).
> **PT:** Todos os menus aceitam seleção múltipla: digite `2,3,10`, intervalos como `1-3`, `TODOS` ou pressione ENTER para executar todas as opções em sequência (`0` volta).

## 1. Reparo e Integridade do Sistema (DISM, SFC)

- `DISM /Online /Cleanup-Image /CheckHealth` — verificação rápida, sem reparo.
- `DISM /Online /Cleanup-Image /RestoreHealth` — repara via Windows Update
  (10–20 min, requer internet).
- `DISM /Online /Cleanup-Image /StartComponentCleanup` — remove componentes
  substituídos, libera espaço.
- `sfc /scannow` — verifica e repara arquivos do sistema (cache local).
- Opção 5: DISM + SFC em sequência (reparo completo, 20–40 min).

## 2. Discos e Armazenamento (SMART, CHKDSK, TRIM)

- SMART via `MSStorageDriver_FailurePredictStatus` (`PredictFailure = True`
  significa backup imediato).
- Contadores de confiabilidade, saúde e status (`Get-PhysicalDisk`),
  `wmic diskdrive`.
- `chkdsk C: /f /r /x` (agendado para o próximo boot).
- Otimização automática (SSD → `ReTrim`, HDD → `Defrag`); verificação e
  ativação de TRIM; desfragmentação de unidade específica (**apenas HDD**);
  `fsutil fsinfo ntfsinfo`; espaço livre por volume.

## 3. Drivers (PnPUtil)

Lista drivers (`pnputil /enum-drivers`), dispositivos com erro
(`ConfigManagerErrorCode != 0`), monitores, `/scan-devices`; adiciona
(`.inf`) e remove (`oemXX.inf`) drivers; consulta o Driver Verifier
(`verifier /query`).

## 4. Impressão e Spooler

Reset completo do spooler (para o serviço, apaga a fila, reinicia),
`printui /s /t2`, lista/renomeia/altera porta/remove impressoras
(`Get-Printer`, `Rename-Printer`, `Set-Printer`, `Remove-Printer`),
limpeza de trabalhos travados.

## 5. Limpeza e Manutenção

Temp do usuário e do sistema, limpeza completa (+ Prefetch),
`cleanmgr /sageset:1` + `/sagerun:1`, cache do Windows Update
(para `wuauserv`, limpa `SoftwareDistribution\Download`).

## 6. Energia e Desempenho (powercfg)

Relatórios de bateria, eficiência (60 s) e sleep; estados de energia;
desativar hibernação; planos Alto Desempenho e Ultimate Performance;
lista de planos; saúde da bateria via WMI (`Win32_Battery`, ideal para notebooks).

## 7. Memória RAM

Agendamento do `mdsched.exe`, `wmic memorychip`, `winsat mem`, total/livre
via CIM, `sysdm.cpl` (memória virtual).

## 8. Atualização do Windows (PSWindowsUpdate)

Verifica Execution Policy, instala o módulo `PSWindowsUpdate`,
lista/instala atualizações (com ou sem reboot automático), `gpupdate /force`.

## 9. Ajustes de Desempenho (Registro)

Efeitos visuais, animações, Aero Shake, delays de menu/startup,
SysMain/SuperFetch (para SSDs), PowerThrottling, limpeza de pagefile,
busca/Bing, balões, Focus Assist, apps silenciosos, telemetria e
instruções do algoritmo de Nagle. **Crie um ponto de restauração antes
(menu 11, opção 8).** Opções 15 e 16 aplicam (executa 1–13 de uma vez) e
restauram (desfaz 1–13, voltando cada valor ao padrão do Windows).

## 10. Rede e DNS

Reset TCP/IP e Winsock (**requer reinicialização**), `flushdns` +
`registerdns`, `ipconfig /all`, `nbtstat -n`, `netstat -ano`, `tracert`,
`getmac`, IP estático (`Configurar-IP-Estatico`), `ncpa.cpl`.

## 11. Segurança e Permissões

`icacls /reset`, `takeown`, bloqueio/desbloqueio de USB
(`USBSTOR`/`USBHUB3`), Firewall on/off (**desativar só para diagnóstico
temporário**), Execution Policy, ponto de restauração, proteção de escrita
em drives externos, MRT.

## 12. Segurança da Informação (auditoria, antivírus)

- Processos suspeitos: sem `Path`, +500 handles, CPU > 50 — com checagem de
  assinatura digital, hash SHA256 e link para o VirusTotal. `MsMpEng.exe`,
  `svchost.exe` e outros protegidos costumam ser falsos positivos.
- IDs auditados: 4625 (falha de logon), 4720 (criação de conta), 4728
  (grupos privilegiados), 4723/4724 (senhas), 1102 (**limpeza de log —
  altamente suspeito**), 4624 tipo 10 (RDP), 4624/4634 (logon/logoff).
- **Opção 2 (ID 4625)**: últimas falhas de logon com quantidade configurável
  (ENTER = 10, ou informe qualquer número); exibe data, nome da conta,
  endereço de rede (IP de origem) e tipo de logon decodificado:
  2 = teclado/interativo, 3 = rede, 4 = batch, 5 = serviço, 7 = desbloqueio,
  10 = RDP (RemoteInteractive), 11 = cache do logon. Falha de leitura = aviso,
  sem erro fatal.
- **Opção 7 (ID 4624 tipo 10, RDP)**: últimos logons remotos bem-sucedidos
  com quantidade configurável (ENTER = 10, ou informe qualquer número);
  mesmo visual da opção 2 — data, nome da conta, endereço de rede (IP de
  origem, `Properties[18]`; tipo de logon em `Properties[8]`) e tipo
  decodificado (10 = RDP). Falha de leitura = aviso, sem erro fatal.
- Conexões RDP ativas (porta 3389) e análise completa combinada.
- **Auditoria de contas e acessos** (opções 19–21): inventário de usuários
  locais e grupo Administradores, contas inativas/senha sem expiração
  (`Get-LocalUser`) e permissões ACL em diretórios.
- **Antivírus e endpoint** (opções 22–24): exclusões do Defender
  (`Get-MpPreference` — ExclusionPath/ExclusionProcess), status do BitLocker
  (`Get-BitLockerVolume`) e auditoria de firewall (`Get-NetFirewallProfile`,
  `Get-NetFirewallRule`).
- **Rede e superfície de ataque** (opções 25–28): portas abertas e conexões
  ativas (`Get-NetTCPConnection`, `Get-NetUDPEndpoint`), teste de conectividade
  para RDP 3389 / SMB 445 / WinRM 5985 (`Test-NetConnection`), protocolos
  legados (SMBv1, TLS 1.0/1.1) e compartilhamentos de rede (`Get-SmbShare`).
- **Persistência e integridade** (opções 29–33): itens de inicialização
  (`Run` HKLM/HKCU, `Win32_StartupCommand`, `ScheduledTask`), serviços com
  caminhos suspeitos em %TEMP%/AppData (`Win32_Service`), assinatura digital
  de executáveis (`Get-AuthenticodeSignature`), hash SHA256 (`Get-FileHash`) e
  coleta de evidências forense com timestamp (`Export-Csv`, `Compress-Archive`).
- **Conformidade e hardening** (opções 34–39): patches (`Get-HotFix`),
  baseline CIS/STIG (`secedit /export`, `auditpol`, `Get-ExecutionPolicy`),
  políticas de senha (`net accounts`), Script Block Logging (evento 4104 —
  **habilita a chave de registro** `ScriptBlockLogging`), eventos de conta
  4722/4738/4732 e membros de grupos privilegiados do AD (requer módulo
  ActiveDirectory/RSAT; sem ele a opção avisa e não falha).
- **Antivírus real** (opções 11–18, em vez do placebo do `.bat` clássico):
  status do Defender (`Get-MpComputerStatus`), atualização de assinaturas
  (`Update-MpSignature`), scan rápido e completo (`Start-MpScan`),
  scan offline com reboot (`Start-MpWDOScan` — salva tudo antes),
  quarentena/histórico (`Get-MpThreat`, `Get-MpThreatDetection`) e MRT
  (`mrt /f` só relata, `/f:y` remove).

## 13. Diagnóstico Avançado

Top 10 processos por CPU/RAM, serviços em execução/parados, últimos erros
do sistema, `eventvwr`, `perfmon /rel`, `systeminfo`, inventário WMI
(CPU/RAM/disco/placa-mãe), WinSAT (formal e por componente), programas
(`wmic product`), hotfixes (`wmic qfe`), `bcdedit`, `perfmon /report`,
serviços por processo (`tasklist /svc`, ex: descobrir o que roda
dentro de cada `svchost.exe`).

## 14. Placa de Vídeo e Monitor (dxdiag, DCOM, GPU)

GPU via WMI, `dxdiag`, benchmarks `winsat d3d`/`dwm`, `pnputil` (Display),
`DisplaySwitch`, `taskschd`, `dcomcnfg`, `devmgmt`, erros DCOM no log.
Dica: reset de GPU sem reiniciar com `Ctrl + Win + Shift + B`.

## 15. Testes (CPU, velocidade, monitor)

- Stress via PowerShell (workers `-EP Bypass`, até 2× núcleos).
- Stress via CMD (loop aritmético, até 2× núcleos).
- Pontuações WinSAT.
- Teste de monitor: loop que reinicia o `explorer.exe` a cada 5 s em janela
  separada — **feche a janela para parar**. Se a barra de tarefas sumir:
  `Ctrl+Shift+Esc` > Arquivo > Executar nova tarefa > `explorer.exe`.
  Monitore a temperatura (HWMonitor/Core Temp).
- Teste de velocidade (opção 5): latência em 1.1.1.1 e 8.8.8.8 (10 pacotes
  cada), download de 25 MB e upload de 5 MB via Cloudflare — tudo em
  PowerShell, sem abrir navegador.

## 16. Identidade do Sistema

Renomear computador (validação `^[A-Za-z0-9\-]{1,15}$`, exige reboot),
alterar nome completo de uma conta local (pergunta o login e o novo nome),
alterar exibição do usuário atual, IP estático, exibir computador/usuário/
domínio/IP, `control userpasswords2`, relógio AM/PM (`sTimeFormat`,
`s1159`/`s2359` em `HKCU:\Control Panel\International`).

## 17. Menu de Contexto (script clássico)

Gerencia o menu de botão direito do desktop, herdado dos três `.bat` de
contexto (`menuContexto`, `menuContexto - Copia`, `menuContexto klayton`):
ativa/desativa o menu clássico do Windows 11 (com reinício do Explorer) e
adiciona/remove 6 atalhos — contato T! SOS (e-mail), Chrome, Firefox, encerrar
processos travados, reiniciar o Explorer e abrir pastas temporárias. Todos os
rótulos `DTI - ...` viraram `T! SOS - ...`.
## 18. Utilidades Rápidas (script clássico)

Itens herdados do `KlaytonBuenoPrince.bat` não cobertos pelos outros menus:
ping (20 pacotes, destino editável), `msinfo32`, mouse (`main.cpl`),
`msconfig`, `appwiz.cpl`, calculadora e `regedit` (com confirmação). Sites mortos do script original (velocímetro,
direta.com.br, Facebook) e a limpeza de desktop foram descartados.

## 19. Winget (usuário comum — sem admin)

Versão, `upgrade`, `upgrade --all`, `search`, `list`; abre a Microsoft
Store para instalar o App Installer. **Sempre executa não-elevado
(`-SemAdmin`) em nova janela CMD.**
Substitui os instaladores silenciosos legados (pacotes congelados em
2015–2016 com vulnerabilidades conhecidas e arquivos ausentes no projeto);
as antigas ferramentas de diagnóstico de rede agora têm perfil próprio abaixo.

## 20. Instalação de Programas (Winget, 3 perfis)

Perfis prontos de instalação via Winget: **usuário comum** (navegador,
PDF, escritório, multimídia, runtimes), **usuário avançado** (diagnóstico
de rede e resposta a incidentes) e **desenvolvimento** (VS Code, Git,
Python, Node, Java). ENTER instala tudo do perfil; ou digite os números
separados por vírgula (ex: `3,4,13`). A instalação roda em nova janela,
em contexto de usuário comum (sem elevação). Requer Winget (menu 19,
opção 6).

## 21. Informe IP no Relógio do Windows

- Exibe um IP no relógio da bandeja do Windows (junto à hora), via `sTimeFormat`/`sShortTime`
  em `HKCU:\Control Panel\International`.
- Lista IPs IPv4 não-loopback/não-169.254; IPs fixos `172.16.x.x` (/16) não são exibidos por
  padrão, mas podem ser selecionados manualmente (exibidos como `IP: <octeto3>.<octeto4>`).
- Opções: 1) escolher IP a exibir (oferece reiniciar o Explorer ao aplicar); 2) atualizar IP
  agora (re-lê o IP atual, ignorando 172.16/16); 3) remover o IP do relógio (restaura `HH:mm`);
  4) configurar persistência (script VBS `Atualizar-IpRelogio.vbs` em `C:\dti\informeIp` +
  tarefa agendada `kbp_atualiza_ip`, no logon e no intervalo escolhido); 5) ver status da
  persistência; 6) definir texto personalizado no relógio; `0. Voltar`.
- Texto exibido limitado a 39 caracteres (o excedente é truncado).

