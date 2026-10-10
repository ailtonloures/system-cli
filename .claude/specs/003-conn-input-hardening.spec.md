---
title: Validação e escrita atômica no conn
number: 003
priority: high
tags: [security, injection, ssh, conn]
dependencies: []
related_prd: .claude/prd/security-hardening.prd.md
status: pending
created: 2026-10-10
---

# 003 - Validação e escrita atômica no conn

## Overview
`conn` aceita alias não validado em `connect`, campos livres que injetam diretivas em `~/.ssh/config`, usa alias em regex sem escape e faz append não atômico. Esta spec centraliza validação e torna a escrita segura.

## Related PRD
- **Source**: [Security hardening](../prd/security-hardening.prd.md)
- **Section Reference**: User Stories 9-13, Implementation Decisions (`conn`)

## Prerequisites
- [ ] Reproduzir `conn -oProxyCommand=id` antes da correção (documentar resultado no teste)

## Dependencies
- Nenhuma

## Implementation Tasks
### 1. bin/conn
- [ ] `conn_validate_alias`: `^[a-zA-Z0-9._-]+$` e sem prefixo `-`; usar em connect/add/edit/remove
- [ ] `ssh -- "$alias"` em `conn_connect`
- [ ] `conn_validate_field`: rejeitar espaço, tab, CR/LF e controle em hostname, user, identity_file, proxy_jump (proxy permite vírgula)
- [ ] Escapar metacaracteres do alias em `conn_host_exists` (ou comparar via awk por igualdade)
- [ ] `conn_add`: gravar via `mktemp` + cópia do config + `mv` (como `edit`), `chmod 600`
- [ ] `trap` de remoção do temporário em `add`/`edit`/`remove`

### 2. Testing
- [ ] Em `test/conn.bats` (HOME isolado, `ssh` stub): alias `-oProxyCommand=x` rejeitado
- [ ] hostname com espaço/newline rejeitado; config inalterado
- [ ] `a.b` não casa host `aXb`
- [ ] Interrupção simulada não corrompe config; temporário removido

## Acceptance Criteria
### Must Have
- [ ] Cenários acima passam; aliases/hosts legítimos continuam funcionando
- [ ] shellcheck limpo

### Should Have
- [ ] Completions `conn.bash/zsh` sem regressão

## Testing Requirements
```bash
bats test/conn.bats test/validation.bats
shellcheck -x bin/conn
```

## Rollback Plan
`git revert`; `~/.ssh/config` mantém formato inalterado.
