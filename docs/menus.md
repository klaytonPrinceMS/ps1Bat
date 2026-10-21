# Menus

> **EN:** Quick reference for the 17 `Menu-Principal` menus. Every option runs through the `Run` helper and is written to the log.
> **PT:** Referência rápida dos 17 menus do `Menu-Principal`. Toda opção executa via função auxiliar `Run` e é registrada no log.

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
(`.inf`) e remove (`oemXX.inf`) drivers.

## 4. Impressão e Spooler

Reset completo do spooler (para o serviço, apaga a fila, reinicia),
`printui /s /t2`, lista/renomeia/altera porta/remove impressoras
(`Get-Printer`, `Rename-Printer`, `Set-Printer`, `Remove-Printer`),
limpeza de trabalhos travados.

## 5. Energia e Desempenho (powercfg)

Relatórios de bateria, eficiência (60 s) e sleep; estados de energia;
desativar hibernação; planos Alto Desempenho e Ultimate Performance;
lista de planos.

## 6. Memória RAM

Agendamento do `mdsched.exe`, `wmic memorychip`, `winsat mem`, total/livre
via CIM, `sysdm.cpl` (memória virtual).

## 7. Rede e DNS

Reset TCP/IP e Winsock (**requer reinicialização**), `flushdns` +
`registerdns`, `ipconfig /all`, `nbtstat -n`, `netstat -ano`, `tracert`,
`getmac`, IP estático (`Configurar-IP-Estatico`), `ncpa.cpl`.

## 8. Limpeza e Manutenção

Temp do usuário e do sistema, limpeza completa (+ Prefetch),
`cleanmgr /sageset:1` + `/sagerun:1`, cache do Windows Update
(para `wuauserv`, limpa `SoftwareDistribution\Download`).

## 9. Segurança e Permissões

`icacls /reset`, `takeown`, bloqueio/desbloqueio de USB
(`USBSTOR`/`USBHUB3`), Firewall on/off (**desativar só para diagnóstico
temporário**), Execution Policy, ponto de restauração, proteção de escrita
em drives externos, MRT.

## 10. Diagnóstico Avançado

Top 10 processos por CPU/RAM, serviços em execução/parados, últimos erros
do sistema, `eventvwr`, `perfmon /rel`, `systeminfo`, inventário WMI
(CPU/RAM/disco/placa-mãe), WinSAT (formal e por componente), programas
(`wmic product`), hotfixes (`wmic qfe`), `bcdedit`, `perfmon /report`.

## 11. Placa de Vídeo e Monitor (dxdiag, DCOM, GPU)

GPU via WMI, `dxdiag`, benchmarks `winsat d3d`/`dwm`, `pnputil` (Display),
`DisplaySwitch`, `taskschd`, `dcomcnfg`, `devmgmt`, erros DCOM no log.
Dica: reset de GPU sem reiniciar com `Ctrl + Win + Shift + B`.

## 12. Identidade do Sistema

Renomear computador (validação `^[A-Za-z0-9\-]{1,15}$`, exige reboot),
alterar nome completo de uma conta local (pergunta o login e o novo nome),
alterar exibição do usuário atual, IP estático, exibir computador/usuário/
domínio/IP, `control userpasswords2`.

## 13. Testes de Stress (CPU multi-núcleo)

- Stress via PowerShell (workers `-EP Bypass`, até 2× núcleos).
- Stress via CMD (loop aritmético, até 2× núcleos).
- Pontuações WinSAT.
- Teste de monitor: loop que reinicia o `explorer.exe` a cada 5 s em janela
  separada — **feche a janela para parar**. Se a barra de tarefas sumir:
  `Ctrl+Shift+Esc` > Arquivo > Executar nova tarefa > `explorer.exe`.
  Monitore a temperatura (HWMonitor/Core Temp).

## 14. Segurança da Informação (auditoria de eventos)

- Processos suspeitos: sem `Path`, +500 handles, CPU > 50 — com checagem de
  assinatura digital, hash SHA256 e link para o VirusTotal. `MsMpEng.exe`,
  `svchost.exe` e outros protegidos costumam ser falsos positivos.
- IDs auditados: 4625 (falha de logon), 4720 (criação de conta), 4728
  (grupos privilegiados), 4723/4724 (senhas), 1102 (**limpeza de log —
  altamente suspeito**), 4624 tipo 10 (RDP), 4624/4634 (logon/logoff).
- Conexões RDP ativas (porta 3389) e análise completa combinada.

## 15. Ajustes de Desempenho (Registro)

Efeitos visuais, animações, Aero Shake, delays de menu/startup,
SysMain/SuperFetch (para SSDs), PowerThrottling, limpeza de pagefile,
busca/Bing, balões, Focus Assist, apps silenciosos, telemetria e
instruções do algoritmo de Nagle. **Crie um ponto de restauração antes
(menu 9, opção 8).** Opções 15 e 16 aplicam (executa 1–13 de uma vez) e
restauram (desfaz 1–13, voltando cada valor ao padrão do Windows).

## 16. Atualização do Windows (PSWindowsUpdate)

Verifica Execution Policy, instala o módulo `PSWindowsUpdate`,
lista/instala atualizações (com ou sem reboot automático), `gpupdate /force`.

## 17. Winget (usuário comum — sem admin)

Versão, `upgrade`, `upgrade --all`, `search`, `list`; abre a Microsoft
Store para instalar o App Installer. **Sempre executa não-elevado
(`-SemAdmin`) em nova janela CMD.**
