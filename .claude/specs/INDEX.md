# Specs — Security hardening

PRD: [security-hardening.prd.md](../prd/security-hardening.prd.md)

| # | Título | Prioridade | Status | Tags | Dependências |
|---|--------|-----------|--------|------|--------------|
| 001 | Integridade dos instaladores (lazydocker e wrk) | high | done | security, supply-chain, installer, lib | — |
| 002 | Execução segura de scripts no run | high | done | security, hardening, run | — |
| 003 | Validação e escrita atômica no conn | high | done | security, injection, ssh, conn | — |
| 004 | Mascaramento de segredos e saneamento do histórico no http | medium | done | security, secrets, logging, http | — |
| 005 | Validação de nome e casamento exato no cron | medium | done | bugfix, security, cron | — |
| 006 | Validação de parâmetros e consentimento no stress | low | done | security, validation, stress | — |
| 007 | Hardening do CI e política de segurança | medium | done | security, ci, github-actions, docs | 001 |

Specs 001-006 são independentes entre si e podem rodar em paralelo; 007 depois de 001.
