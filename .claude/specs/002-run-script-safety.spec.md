---
title: Execução segura de scripts no run
number: 002
priority: high
tags: [security, hardening, run]
dependencies: []
related_prd: .claude/prd/security-hardening.prd.md
status: pending
created: 2026-10-10
---

# 002 - Execução segura de scripts no run

## Overview
`run` executa qualquer `*.sh` em `$SCRIPTS_DIR`. Adicionar checagem de dono e permissões antes de executar e recusar `SCRIPTS_DIR` inseguro.

## Related PRD
- **Source**: [Security hardening](../prd/security-hardening.prd.md)
- **Section Reference**: User Stories 6-8, Implementation Decisions (`run`)

## Prerequisites
- [ ] Nenhum

## Dependencies
- Nenhuma

## Implementation Tasks
### 1. bin/run
- [ ] Função de verificação: dono == `id -u` e sem escrita para grupo/outros (compatível Linux `stat -c` e macOS `stat -f`)
- [ ] Aplicar a verificação ao script (em `run_script` e `run_picker`) e ao diretório `SCRIPTS_DIR`
- [ ] Erro claro com dica `chmod go-w <arquivo>`
- [ ] Validar o nome em `run <name>` (sem `/` nem `..`) para impedir path traversal

### 2. Testing
- [ ] Em novo `test/run.bats` (HOME e SCRIPTS_DIR em tmp): script seguro executa
- [ ] Script com `chmod 666` é recusado
- [ ] Diretório gravável por outros é recusado
- [ ] `run ../x` é recusado

## Acceptance Criteria
### Must Have
- [ ] Cenários acima passam; uso normal inalterado
- [ ] shellcheck limpo

### Should Have
- [ ] Documentar a regra no README

## Testing Requirements
```bash
bats test/run.bats
shellcheck -x bin/run
```

## Rollback Plan
`git revert` do commit.
