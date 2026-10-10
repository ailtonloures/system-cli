---
title: Mascaramento de segredos e saneamento do histórico no http
number: 004
priority: medium
tags: [security, secrets, logging, http]
dependencies: []
related_prd: .claude/prd/security-hardening.prd.md
status: pending
created: 2026-10-10
---

# 004 - Mascaramento de segredos e saneamento do histórico no http

## Overview
`http client show` e `-v` expõem o `auth_token`; o histórico grava URLs com query string e sem sanitizar delimitadores. Mascarar por padrão e sanear o log.

## Related PRD
- **Source**: [Security hardening](../prd/security-hardening.prd.md)
- **Section Reference**: User Stories 14-18, Implementation Decisions (`http`)

## Prerequisites
- [ ] Nenhum

## Dependencies
- Nenhuma

## Implementation Tasks
### 1. bin/http
- [ ] Helper `_mask_secret` (últimos 4 caracteres visíveis)
- [ ] `http client show`: mascarar token; flag `--reveal` para exibir
- [ ] Modo `-v`: filtrar saída do curl substituindo valor de `Authorization:` por máscara
- [ ] `http_log_history`: remover `?query` e `#fragment` da URL; remover `|`, CR, LF dos campos
- [ ] Atualizar help e completions (`completions/http.*`) com `--reveal`

### 2. Testing
- [ ] Em `test/http.bats` (HOME isolado, `curl` stub): `client show` não imprime token completo
- [ ] `client show --reveal` imprime
- [ ] `-v` não contém o token
- [ ] Histórico sem query string; URL com `|`/newline não gera linha extra

## Acceptance Criteria
### Must Have
- [ ] Cenários acima passam; permissões 700/600 preservadas
- [ ] shellcheck limpo

### Should Have
- [ ] README documenta `--reveal`

## Testing Requirements
```bash
bats test/http.bats
shellcheck -x bin/http
```

## Rollback Plan
`git revert`; arquivos de client existentes permanecem compatíveis.
