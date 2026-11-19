# Desenvolvimento

> **EN:** Notes for `SOS-Manutencao.ps1` contributors: code conventions, tests and how to build this site.
> **PT:** Notas para quem vai alterar o `SOS-Manutencao.ps1`: convenções de código, testes e como gerar este site.

## Convenções do código

- Arquivo único, PowerShell 5.1 (`#Requires -Version 5.1`). Manter sintaxe
  compatível com 5.1 — nada exclusivo do PS7.
- Textos de interface em **pt-BR**.
- Toda ação passa pela função `Run`:
  - padrão = CMD inline;
  - `-PS` = executa via PowerShell;
  - `-Win` = abre em nova janela (via `.bat` temporário ou comando
    codificado em Base64);
  - `-SemAdmin` = contexto não-elevado (obrigatório no Winget, menu 19).
- Ações destrutivas: padrão `Desc` (explica o comando) + `Confirmar`
  (`[S/N]`).
- Ações privilegiadas: registrar com `Log` (vai para
  `$env:TEMP\SOS_Manutencao.log`).
- Não criar scripts `.bat`/`.ps1` avulsos — adicionar opção em um
  `Menu-*` existente ou criar novo `Menu-*` + entrada no `Menu-Principal`.
- Convenção de IP estático: `172.16.x.x → 255.255.0.0`,
  `192.168.x.x → 255.255.255.0`, DNS = gateway por padrão.

## Versionamento

Versão no formato `v2.1.AAMMDD`: prefixo `v2.1.` fixo + data da alteração
(ano com 2 dígitos, mês, dia). Exemplo: `v2.1.261021` = 21/10/2026.
A cada release, atualizar os 5 pontos: cabeçalho do `SOS-Manutencao.ps1`, `$APP.Nome`,
linha "Versão atual" do `README.md` e blocos EN/PT do `docs/index.md`.

## Texto e encoding

- `SOS-Manutencao.ps1` é UTF-8 **com BOM** (obrigatório para o PowerShell 5.1 exibir
  `ç/ã/õ` corretamente) com quebras CRLF — preserve ambos ao editar.
- Textos de interface usam acentos; identificadores e comandos, nunca.
- Os `.bat` temporários do `Run` são gravados em UTF-8 **sem BOM** com
  `chcp 65001`, para os acentos saírem certos na janela CMD.

## Commits

Mensagem no formato `AAMMDD resumo`: data da alteração + resumo curto.
Exemplo: `git commit -m "261021 corrige texto da autenticacao"`.
(Exceção feita ao primeiro commit: `Iniciando o projeto`.)

## Testes automatizados

Harness Python sem privilégios (só leitura, exceto `run`):

```powershell
python main.py check   # sintaxe (parser PowerShell) + versao + marca + inventario
python main.py test    # pytest em tests/ (requer `poetry install` com rede)
python main.py run     # abre o menu do SOS-Manutencao.ps1 (Windows + admin)
```

`tests/` trava versão consistente, marca limpa, estrutura (funções e
dispatch dos 21 menus + submenu de USB do Menu 12), encoding do PS1 (UTF-8
com BOM e CRLF), cobertura documental das opções novas, padrão bilíngue da
docs e as travas de segurança (kill de explorer só no teste de monitor,
firewall-off e remoção de driver com confirmação, instrução de recuperação
da barra).

## Validação manual

Além do harness, em máquina/VM Windows descartável: navegar até o menu
alterado e conferir textos/fluxo. **Não** executar stress, CHKDSK, DISM/SFC,
alterações de registro, sanitização de pendrive ou Firewall como verificação.
Para o submenu USB (Menu 12, opção 40), conferir a listagem automática de
discos/volumes ao entrar, a confirmação com modelo/tamanho antes das ações
destrutivas e o rollback (opção 21) após os bloqueios 9 a 12.

## Documentação (este site)

Pré-requisito: Python 3 com pip.

```powershell
pip install -r requirements-docs.txt
mkdocs serve            # preview em http://127.0.0.1:8000
mkdocs build --strict   # gera site/ (ignorado pelo git)
```

Arquivos: `mkdocs.yml` (navegação), `docs/` (páginas em Markdown).
Ao adicionar um menu ao script, documente-o em `docs/menus.md` e atualize
a tabela de menus do `README.md`.

O fluxograma de execução fica em `docs/assets/fluxograma.{svg,png}`. Ao alterar a
cadeia de entrada (`Fixar-Janela → Garantir-Admin → Autenticar → Menu-Principal`), os
grupos de menus ou o motor de execução, edite também o SVG — o PNG é gerado a partir
dele.

## Publicação (GitHub Pages)

O workflow `.github/workflows/docs.yml` gera o site a cada push em `main`
que toque em `docs/`, `mkdocs.yml` ou `README.md`, via GitHub Actions.
Ativação única no repositório: Settings → Pages → Source: **GitHub Actions**.
URL: https://klaytonprincems.github.io/ps1Bat/
