# Uso

> **EN:** Requirements, how to run, mandatory authentication, audit log and operational rules.
> **PT:** Requisitos, como executar, autenticação obrigatória, log de auditoria e regras operacionais.

## Requisitos

- Windows com PowerShell 5.1+ (manter sintaxe compatível com 5.1:
  `wmic`, `pnputil` e `powercfg` ainda são usados).
- Conta com privilégios de Administrador.
- Menu 8 exige o módulo `PSWindowsUpdate` - o próprio menu instala
  (`Set-ExecutionPolicy RemoteSigned -Scope CurrentUser`, depois
  `Install-Module PSWindowsUpdate`).

## Execução

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File SOS-Manutencao.ps1
```

Ou botão direito em `SOS-Manutencao.ps1` → **Executar como Administrador**.

## Autenticação

`Autenticar` mostra o usuário da sessão atual (`$env:USERNAME`) e informa se
ele é administrador local (checado com `Get-StatusAdmin`, que consulta o
grupo de administradores pelo SID `S-1-5-32-544` — vale em Windows pt-BR e
en-US). Pressione Enter para autenticar como esse usuário ou digite outro
login. Contas que não são administradoras são recusadas antes da senha. A
senha é validada com
`System.DirectoryServices.AccountManagement.PrincipalContext` (tipo
`Machine`). Três tentativas (`$APP.MaxAuth`); após a terceira o script
encerra com `exit 1` e registra o bloqueio no log.

## Log de auditoria

Cada ação passa pela função `Log` e é anexada a
`$env:TEMP\SOS_Manutencao.log` no formato
`[yyyy-MM-dd HH:mm:ss][NIVEL] mensagem`.
Novas ações privilegiadas devem chamar `Log` da mesma forma.

## Regras operacionais

- Ações destrutivas usam o padrão `Desc` + `Confirmar` (ENTER vazio executa, qualquer tecla cancela).
  Preserve esse padrão em novas opções.
- Menu 9 (Registro): crie um ponto de restauração antes (menu 11, opção 8).
- Menu 15 (testes): monitore a temperatura; desligamento durante o teste
  indica problema de refrigeração. O teste de monitor (opção 4) reinicia o
  `explorer.exe` em loop numa janela separada — feche a janela para parar.
- Menu 19 (Winget): **sempre não-elevado** (`-SemAdmin`). O `Run` abre uma
  nova janela CMD independente para interação. Não altere para modo elevado.
- Rede/IP estático: máscara automática `172.16.x.x → 255.255.0.0` e
  `192.168.x.x → 255.255.255.0`; DNS usa o gateway por padrão.
