# Contribuição — T! SOS Sistemas

> **EN:** Notes for contributors to `SOS-Manutencao.ps1`: coding conventions, versioning, file structure, how to run tests, security rules, CI/CD, branding, and commit format.
> **PT:** Notas para quem vai contribuir com o `SOS-Manutencao.ps1`: convenções de código, versionamento, estrutura de arquivos, como executar testes, regras de segurança, CI/CD, marca e formato de commits.

## 1. Convenções de código / Coding conventions

- **Script único em PowerShell 5.1**: o arquivo `SOS-Manutencao.ps1` declara `#Requires -Version 5.1`. Mantenha a sintaxe compatível com 5.1 — nada exclusivo do PS7.
  - **EN:** Single PowerShell 5.1 script (`#Requires -Version 5.1`). Keep syntax compatible with 5.1 — nothing PS7-exclusive.
- **Textos da interface em pt-BR**: mensagens, menus e descrições usam português do Brasil com acentos (`ç/ã/õ` etc.).
  - **EN:** Interface texts in **pt-BR** (Portuguese of Brazil), with accents.
- **Identificadores sem acento**: nomes de funções, variáveis, comandos e parâmetros nunca usam caracteres acentuados (apenas ASCII).
  - **EN:** Identifiers and commands never use accented characters (ASCII only).
- Toda ação passa pela função `Run`:
  - padrão = CMD inline;
  - `-PS` = executa via PowerShell;
  - `-Win` = abre em nova janela (via `.bat` temporário ou comando codificado em Base64);
  - `-SemAdmin` = contexto não-elevado (obrigatório no Winget, menu 19).
- Ações destrutivas: padrão `Desc` (explica o comando) + `Confirmar` (`[S/N]`).
- Ações privilegiadas: registrar com `Log` (vai para `%TEMP%\SOS_Manutencao.log`).
- Não criar scripts `.bat`/`.ps1` avulsos — adicionar opção em um `Menu-*` existente ou criar novo `Menu-*` + entrada no `Menu-Principal`.

## 2. Versionamento / Versioning

Versão no formato `v2.1.AAMMDD`: prefixo `v2.1.` fixo + data da alteração (ano com 2 dígitos, mês, dia). Exemplo: `v2.1.261021` = 21/10/2026.

- **EN:** Version format `v2.1.AAMMDD`: fixed prefix `v2.1.` + change date (2-digit year, month, day). Example: `v2.1.261021` = 2026-10-21.

A cada release/alteração de versão, atualizar os pontos oficiais:

1. Cabeçalho do `SOS-Manutencao.ps1` (`T! SOS SISTEMAS - FERRAMENTA TÉCNICA DE MANUTENÇÃO (v2.1.AAMMDD)`);
2. `$APP.Nome` em `SOS-Manutencao.ps1` (`"T! SOS Sistemas - Manutenção Técnica  (v2.1.AAMMDD)"`);
3. Linha "Versão atual" do `README.md` (`Versão atual: **v2.1.AAMMDD**`);
4. Blocos EN/PT do `docs/index.md`;
5. `version` no `pyproject.toml` (`version = "2.1.AAMMDD"`);

Os testes em `tests/test_version.py` e `python main.py check` validam que os 4 pontos estão consistentes e no formato `^v2\.1\.\d{6}$`.

## 3. Nomeação de arquivos e estrutura / File naming and structure

```text
SOS-Manutencao.ps1              # único script; toda a lógica em funções Menu-*
docs/                # documentação MkDocs (index.md, uso.md, menus.md, desenvolvimento.md)
tests/               # testes pytest (test_version.py, test_structure.py, test_safety.py, test_docs.py, test_branding.py)
mkdocs.yml           # navegação/config do MkDocs
requirements-docs.txt# dependência da documentação (mkdocs)
pyproject.toml       # harness Python + versão
README.md
.github/workflows/docs.yml   # CI: build do site com mkdocs --strict
.gitattributes       # normalização de fim de linha (LF)
main.py              # ponto de entrada: check / test / run
LICENSE
```

- Nunca criar scripts `.bat`/`.ps1` soltos fora de `SOS-Manutencao.ps1`; arquivos `.bat` temporários gerados em tempo de execução são escritos pelo script, não versionados.
  - **EN:** Never create loose `.bat`/`.ps1` scripts outside `SOS-Manutencao.ps1`; temporary `.bat` files generated at runtime are written by the script itself, not committed.
- `.bat` temporários do `Run` são gravados em UTF-8 **sem BOM** com `chcp 65001`.
  - **EN:** `Run` temporary `.bat` files are written UTF-8 **without BOM** with `chcp 65001`.
- `SOS-Manutencao.ps1` é UTF-8 **com BOM** e quebras CRLF (obrigatório para o PowerShell 5.1 exibir acentos corretamente) — preserve ambos ao editar.
  - **EN:** `SOS-Manutencao.ps1` is UTF-8 **with BOM** and CRLF line endings (required for PowerShell 5.1 to display accents correctly) — preserve both when editing.

## 4. Como executar / How to run

Pré-requisito: Python 3 com pip (e, para docs, `mkdocs`).

Instalar dependências:
```powershell
pip install -r requirements-docs.txt   # mkdocs (documentação)
# ou, com Poetry:
poetry install                         # pytest + mkdocs
```

Executar o harness Python (`main.py`):

```powershell
python main.py check   # validação estática: sintaxe PowerShell 5.1, versão consistente, marca limpa (funciona em qualquer SO)
python main.py test    # roda pytest em tests/ (requer `poetry install` com rede / `pip install pytest`)
python main.py run     # abre o menu do SOS-Manutencao.ps1 (somente Windows + privilégios de administrador)
```

- `check`: apenas leitura — não executa nenhuma ação privilegiada.
  - **EN:** `check`: read-only — does not execute any privileged action.
- `run` exige Windows e elevação de admin (UAC) + autenticação com senha do administrador local (máx. 3 tentativas).
  - **EN:** `run` requires Windows and admin elevation (UAC) + authentication with the local administrator password (max. 3 attempts).

Executar o script diretamente (apenas Windows):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File SOS-Manutencao.ps1
```

Ou clique com o botão direito em `SOS-Manutencao.ps1` → **Executar como Administrador**.

Na inicialização, a ordem é fixa: `Garantir-Admin` → `Autenticar` → `Menu-Principal`.

## 5. Testes / Testing

- Suíte automatizada: `pytest` em `tests/`.
  - **EN:** Automated suite: `pytest` in `tests/`.
- Rode com: `python main.py test` (ou `pytest tests` / `poetry run pytest`).
- Os testes travam: versão consistente, marca limpa, estrutura (funções e dispatch dos menus), padrão bilíngue da docs, e travas de segurança (kill de explorer só no teste de monitor, firewall-off e remoção de driver com confirmação, instrução de recuperação da barra).
- Validação manual adicional, em máquina/VM Windows descartável: navegar até o menu alterado e conferir textos/fluxo. **Não** executar stress, CHKDSK, DISM/SFC, alterações de registro ou Firewall como verificação.
  - **EN:** Additional manual validation, on a disposable Windows machine/VM: navigate to the changed menu and check texts/flow. **Do not** run stress, CHKDSK, DISM/SFC, registry or Firewall changes as verification.

## 6. Segurança / Security

- **Autenticação obrigatória**: a senha do administrador local é validada ao iniciar (máx. 3 tentativas, via `PrincipalContext` contra o SAM local). Não pule nem desative essa etapa.
  - **EN:** **Mandatory admin auth**: local administrator password validated at startup (max. 3 attempts via `PrincipalContext` against the local SAM). Do not skip or disable this step.
- **Log obrigatório**: todas as ações privilegiadas são registradas em `%TEMP%\SOS_Manutencao.log` pela função `Log`.
  - **EN:** **Mandatory logging**: all privileged actions are logged to `%TEMP%\SOS_Manutencao.log` via the `Log` function.
- **Ações destrutivas exigem `Desc` + `Confirmar`**: `Desc` explica o comando e `Confirmar` pede confirmação (`[S/N]`, ENTER executa, qualquer outra tecla cancela).
  - **EN:** **Destructive actions require `Desc` + `Confirmar`**: `Desc` explains the command and `Confirmar` asks for confirmation (`[S/N]`, ENTER runs, any other key cancels).
- Exemplo de travas de segurança testadas: remoção de driver com `pnputil /delete-driver` só com aviso/confirmação; desligar firewall (`advfirewall ... state off`) só com `Confirmar` por perto; kill de explorer só no teste de monitor (menu 15), com instrução de recuperação (`Ctrl+Shift+Esc > Arquivo > Executar nova tarefa > explorer.exe`).

## 7. CI/CD

O workflow GitHub Actions `.github/workflows/docs.yml` gera o site de documentação a cada push em `main` que toque em `docs/`, `mkdocs.yml` ou `README.md`:

```yaml
name: docs
on:
  push:
    branches: [main]
    paths:
      - "docs/**"
      - "mkdocs.yml"
      - "README.md"
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with: python-version: "3.13"
      - run: pip install -r requirements-docs.txt
      - run: mkdocs build --strict   # gera site/ com --strict
      - uses: actions/upload-pages-artifact@v3
        with: path: site
  deploy:
    needs: build
    runs-on: ubuntu-latest
    environment:
      name: github-pages
    steps:
      - uses: actions/deploy-pages@v4
```

- Ativação única no repositório: Settings → Pages → Source: **GitHub Actions**.
  - **EN:** One-time repo activation: Settings → Pages → Source: **GitHub Actions**.
- URL do site: https://klaytonprincems.github.io/ps1Bat/
- Localmente, pré-visualize com `mkdocs serve` (http://127.0.0.1:8000) e valide com `mkdocs build --strict`.

## 8. Estilo de código / Code style

- Não criar scripts `.bat`/`.ps1` avulsos — adicionar opção em um `Menu-*` existente ou criar novo `Menu-*` + entrada no `Menu-Principal`.
- Arquivos `.bat` temporários do `Run` são gravados em tempo de execução (não versionados), codificados em UTF-8 sem BOM com `chcp 65001`; comandos sensíveis podem ser passados codificados em Base64 via `-Win`.
  - **EN:** `Run` temporary `.bat` files are generated at runtime (not committed), UTF-8 without BOM with `chcp 65001`; sensitive commands may be passed Base64-encoded via `-Win`.
- Máscaras de IP estático: `172.16.x.x → 255.255.0.0`, `192.168.x.x → 255.255.255.0`; DNS = gateway por padrão.
  - **EN:** Static IP masks: `172.16.x.x → 255.255.0.0`, `192.168.x.x → 255.255.255.0`; DNS = default gateway.
- Identificadores e comandos sem acento; textos de interface com acento em pt-BR.
- Arquivo principal UTF-8 com BOM e CRLF.

## 9. Checklist do contribuidor / Contributor checklist

Antes de abrir um Pull Request, certifique-se de:

- [ ] Executou `python main.py check` e obteve `RESULTADO: OK`
  - **EN:** Ran `python main.py check` and got `RESULTADO: OK`
- [ ] Executou `python main.py test` (pytest em `tests/`) com sucesso
  - **EN:** Ran `python main.py test` (pytest in `tests/`) successfully
- [ ] Atualizou `docs/menus.md` (se adicionou/alterou um menu)
  - **EN:** Updated `docs/menus.md` (if adding/changing a menu)
- [ ] Atualizou a tabela de menus do `README.md` (se aplicável)
  - **EN:** Updated the menus table in `README.md` (if applicable)
- [ ] Atualizou os blocos EN/PT de `docs/index.md` (se aplicável)
  - **EN:** Updated EN/PT blocks in `docs/index.md` (if applicable)
- [ ] Atualizou a versão `v2.1.AAMMDD` nos 5 pontos oficiais (cabeçalho do `.ps1`, `$APP.Nome`, `README.md`, `docs/index.md`, `pyproject.toml`)
  - **EN:** Updated version `v2.1.AAMMDD` in the 5 official points (`.ps1` header, `$APP.Nome`, `README.md`, `docs/index.md`, `pyproject.toml`)
- [ ] Atualizou `tests/test_structure.py` (se adicionou/renomeou funções `Menu-*` ou funções-chave)
  - **EN:** Updated `tests/test_structure.py` (if adding/renaming `Menu-*` or key functions)
- [ ] Revisou `.gitattributes` (normalização `* text=auto` preservada)
  - **EN:** Reviewed `.gitattributes` (`* text=auto` normalization preserved)
- [ ] Não introduziu termos proibidos da marca fora de `tests/test_branding.py`
  - **EN:** Did not introduce forbidden brand terms outside `tests/test_branding.py`
- [ ] Commit segue o formato `AAMMDD resumo` (ou `Iniciando o projeto` no primeiro commit)
  - **EN:** Commit follows the `AAMMDD resumo` format (or `Iniciando o projeto` for the first commit)

## 10. Formato de commits / Commit message format

Mensagem no formato `AAMMDD resumo`: data da alteração + resumo curto.

Exemplo:
```powershell
git commit -m "261021 corrige texto da autenticacao"
```

Exceção feita ao primeiro commit: `Iniciando o projeto`.

- **EN:** Commit message format: `AAMMDD resumo` (change date + short summary). Example: `git commit -m "261021 corrige texto da autenticacao"`. Exception: the first commit is `Iniciando o projeto`.

## 11. Marca / Branding

O repositório não pode conter menções a órgãos ou entidades antigos, nem termos técnicos usados de forma imprópria. A lista exata de termos barrados vive em `tests/test_branding.py` — o único arquivo autorizado a defini-la — e é validada automaticamente por `python main.py check` e pelo pytest em `tests/`.

- **EN:** The repo must not contain mentions of old agencies or entities, nor improper technical terms. The exact list of barred terms lives in `tests/test_branding.py` — the only file allowed to define it — and is enforced automatically by `python main.py check` and by pytest in `tests/`.

## 12. Lembrete final / Final reminder

Sempre rode **`python main.py check`** antes de commitar. Ele valida sintaxe do PowerShell 5.1, consistência da versão `v2.1.AAMMDD` nos pontos oficiais e limpeza da marca — sem executar nenhuma ação privilegiada.

- **EN:** Always run **`python main.py check`** before committing. It validates PowerShell 5.1 syntax, `v2.1.AAMMDD` version consistency across the official points, and brand cleanliness — without executing any privileged action.