---
title: Hardening do CI e política de segurança
number: 007
priority: medium
tags: [security, ci, github-actions, docs]
dependencies: [001-installer-integrity.spec.md]
related_prd: .claude/prd/security-hardening.prd.md
status: pending
created: 2026-10-10
---

# 007 - Hardening do CI e política de segurança

## Overview
Workflows sem `permissions`, actions por tag e bats clonado do HEAD. Fixar versões, reduzir privilégios, adicionar Dependabot e `SECURITY.md`.

## Related PRD
- **Source**: [Security hardening](../prd/security-hardening.prd.md)
- **Section Reference**: User Stories 24-28, Implementation Decisions (CI)

## Prerequisites
- [ ] Obter SHAs atuais de `actions/checkout@v4` e do release de bats-core a fixar (verificar no GitHub; não inventar)

## Dependencies
- `001-installer-integrity.spec.md` - mesmo padrão de pin/verificação

## Implementation Tasks
### 1. .github/workflows
- [ ] `permissions: contents: read` em `lint.yml` e `test.yml`
- [ ] `actions/checkout` por SHA com comentário `# v4.x.y`
- [ ] bats-core: `git clone --branch <tag>` + verificação do commit esperado (ou pacote `bats` do apt)

### 2. Repositório
- [ ] `.github/dependabot.yml` para `github-actions` (weekly)
- [ ] `SECURITY.md` com canal de reporte e política de divulgação
- [ ] Entrada no `CHANGELOG.md` e menção no README

### 3. Testing
- [ ] Validar sintaxe dos workflows (`actionlint` se disponível) e executar CI em PR

## Acceptance Criteria
### Must Have
- [ ] Workflows verdes com as mudanças
- [ ] Nenhum `uses:` sem SHA fixo

### Should Have
- [ ] Dependabot abre PR de teste

## Testing Requirements
```bash
actionlint .github/workflows/*.yml   # se instalado
bats test/
```

## Rollback Plan
`git revert`.
