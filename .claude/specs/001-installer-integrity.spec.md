---
title: Integridade dos instaladores (lazydocker e wrk)
number: 001
priority: high
tags: [security, supply-chain, installer, lib]
dependencies: []
related_prd: .claude/prd/security-hardening.prd.md
status: pending
created: 2026-10-10
---

# 001 - Integridade dos instaladores (lazydocker e wrk)

## Overview
`install_lazydocker` e `install_wrk` baixam/compilam código sem verificação. Esta spec adiciona validação de versão, falha em erro HTTP, checksum SHA-256, pin do `wrk` e limpeza garantida do diretório temporário.

## Related PRD
- **Source**: [Security hardening](../prd/security-hardening.prd.md)
- **Section Reference**: User Stories 1-5, Implementation Decisions (Instaladores)

## Prerequisites
- [ ] `bats` e `shellcheck` disponíveis localmente

## Dependencies
- Nenhuma

## Implementation Tasks
### 1. lib/os.sh — lazydocker
- [ ] Trocar `curl -sI`/`curl -sL` por `curl -fsSL` (e `-fsSI` para o header)
- [ ] Validar `version` com `^v[0-9]+\.[0-9]+\.[0-9]+$`; abortar caso contrário
- [ ] Baixar `checksums.txt` do mesmo release e comparar `sha256sum`/`shasum -a 256` do tarball antes de `tar -xzf`; abortar em divergência
- [ ] Extrair somente o arquivo `lazydocker` (`tar -xzf ... lazydocker`)

### 2. lib/os.sh — wrk
- [ ] Definir constante `WRK_REF` (tag/commit fixo) e usar `git clone` + `git checkout "$WRK_REF"` (ou `--branch`)
- [ ] Confirmar o commit com `git rev-parse HEAD` antes do `make`

### 3. lib/os.sh — limpeza
- [ ] Um único `trap 'rm -rf "$tmp_dir"' EXIT` por instalador (sem `trap -` prematuro que deixe janela sem limpeza), com limpeza também em erro

### 4. Testing
- [ ] Em `test/os.bats`: stubs de `curl`/`git`/`tar` no `PATH`
- [ ] Checksum inválido → exit != 0 e nada em `~/.local/bin`
- [ ] Versão malformada → exit != 0
- [ ] curl com erro HTTP → exit != 0
- [ ] `tmp_dir` removido em sucesso e em falha

## Acceptance Criteria
### Must Have
- [ ] Todos os cenários acima passam
- [ ] `shellcheck -x bin/* lib/*.sh` limpo
- [ ] Instalação válida continua funcionando

### Should Have
- [ ] Mensagens de erro indicam qual verificação falhou

## Testing Requirements
```bash
bats test/os.bats
shellcheck -x bin/* lib/*.sh
```

## Rollback Plan
`git revert` do commit; nenhuma migração de dados envolvida.
