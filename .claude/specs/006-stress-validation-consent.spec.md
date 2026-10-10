---
title: Validação de parâmetros e consentimento no stress
number: 006
priority: low
tags: [security, validation, stress]
dependencies: []
related_prd: .claude/prd/security-hardening.prd.md
status: pending
created: 2026-10-10
---

# 006 - Validação de parâmetros e consentimento no stress

## Overview
`stress` repassa threads/conexões/duração sem validar e permite carga contra qualquer host sem aviso. Validar entradas e exigir confirmação para alvos externos.

## Related PRD
- **Source**: [Security hardening](../prd/security-hardening.prd.md)
- **Section Reference**: User Stories 22-23, Implementation Decisions (`stress`)

## Prerequisites
- [ ] Nenhum

## Dependencies
- Nenhuma

## Implementation Tasks
### 1. bin/stress
- [ ] `-t`/`-c`: inteiros positivos; `-d`: `^[0-9]+[smh]$`
- [ ] Extrair host da URL; se não for loopback/RFC1918/`.local`, exibir aviso de uso autorizado e pedir confirmação `[y/N]`
- [ ] Flag `--yes` para modo não interativo
- [ ] Mover `stress_check_deps` para depois do parse de help/versão (não instalar `wrk` só para `help`)
- [ ] Atualizar help

### 2. Testing
- [ ] Em novo `test/stress.bats` (stub de `wrk`): valores inválidos rejeitados
- [ ] Host externo sem `--yes` e sem `y` cancela
- [ ] `localhost` roda sem prompt
- [ ] `help` não dispara instalação

## Acceptance Criteria
### Must Have
- [ ] Cenários acima passam; shellcheck limpo

### Should Have
- [ ] README atualizado

## Testing Requirements
```bash
bats test/stress.bats
shellcheck -x bin/stress
```

## Rollback Plan
`git revert`.
