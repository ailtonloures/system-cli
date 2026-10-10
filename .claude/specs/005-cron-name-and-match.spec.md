---
title: Validação de nome e casamento exato no cron
number: 005
priority: medium
tags: [bugfix, security, cron]
dependencies: []
related_prd: .claude/prd/security-hardening.prd.md
status: pending
created: 2026-10-10
---

# 005 - Validação de nome e casamento exato no cron

## Overview
`cron` aceita nomes arbitrários e localiza jobs por substring (`grep -F`), podendo editar/remover o job errado; `awk -v` interpreta escapes. Corrigir validação e matching e avisar sobre `%`.

## Related PRD
- **Source**: [Security hardening](../prd/security-hardening.prd.md)
- **Section Reference**: User Stories 19-21, Implementation Decisions (`cron`)

## Prerequisites
- [ ] Nenhum

## Dependencies
- Nenhuma

## Implementation Tasks
### 1. bin/cron
- [ ] `cron_validate_name`: `^[a-zA-Z0-9_-]+$`, aplicado em add/update/remove
- [ ] `cron_entry_exists` e localização de entrada: igualdade da linha inteira do label (`grep -Fx` / awk `$0 == label`)
- [ ] Passar label/new_entry ao awk via `ENVIRON` em vez de `-v`
- [ ] Aviso (não erro) quando o comando contém `%` sem escape

### 2. Testing
- [ ] Em novo `test/cron.bats` (stub de `crontab` com arquivo de estado): nome inválido rejeitado
- [ ] Remover `a` não afeta `ab`
- [ ] Update afeta só o job correto
- [ ] Aviso de `%` exibido

## Acceptance Criteria
### Must Have
- [ ] Cenários acima passam; jobs existentes continuam gerenciáveis
- [ ] shellcheck limpo

### Should Have
- [ ] Completions `cron.*` sem regressão

## Testing Requirements
```bash
bats test/cron.bats
shellcheck -x bin/cron
```

## Rollback Plan
`git revert`; formato do crontab inalterado.
