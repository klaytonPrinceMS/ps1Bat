# T! SOS Sistemas — Ferramenta Técnica de Manutenção

> **EN:** Interactive Windows maintenance toolkit by T! SOS Sistemas. Current version **v2.1.261021**, single script: `SOS-Manutencao.ps1` (PowerShell 5.1).
> **PT:** Ferramenta interativa de manutenção para Windows do T! SOS Sistemas. Versão atual **v2.1.261021**, script único: `SOS-Manutencao.ps1` (PowerShell 5.1).

Toda a lógica vive em funções `Menu-*` despachadas pelo `Menu-Principal`.
O comentário de cabeçalho do `SOS-Manutencao.ps1` (linhas 1–36) é a lista oficial de
funcionalidades.

## Início rápido

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File SOS-Manutencao.ps1
```

1. `Fixar-Janela` dimensiona a janela em pixels (94% x 90% da área útil do
   monitor, pela fonte atual) e trava os botões maximizar/minimizar.
2. `Garantir-Admin` eleva via UAC se necessário.
3. `Autenticar` exibe a caveira com data/hora e valida a senha do administrador
   local (máx. 3 tentativas, via `PrincipalContext` contra o SAM local).
4. `Menu-Principal` exibe as opções 1–20.

Todas as ações privilegiadas são registradas em
`%TEMP%\SOS_Manutencao.log` (função `Log`).
