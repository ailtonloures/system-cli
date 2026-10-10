---
title: Security hardening do system-cli
status: ready-for-agent
created: 2026-10-10
---

## Problem Statement

Como usuário do system-cli (conjunto de CLIs em Bash: `sys`, `vpn`, `run`, `conn`, `cron`, `http`, `dk`, `dkc`, `stress`), eu confio nessas ferramentas para instalar binários, editar meu `~/.ssh/config`, meu crontab, guardar tokens de API e executar scripts. Uma análise estática encontrou lacunas que podem levar a execução de código não verificado, injeção de diretivas em configurações sensíveis, vazamento de credenciais no terminal/logs, edição do item errado no crontab e pipeline de CI com privilégios e dependências não fixadas.

## Solution

Endurecer cada ferramenta sem mudar seu uso normal: verificar integridade de tudo que é baixado e executado, validar toda entrada que vira configuração (SSH, cron, histórico), mascarar segredos por padrão, recusar execução de scripts inseguros e fixar/limitar privilégios no CI. Comportamentos legítimos continuam iguais; entradas perigosas passam a ser rejeitadas com mensagem clara.

## User Stories

1. Como usuário, quero que `sys install lazydocker` verifique o checksum SHA-256 do release, para que um tarball adulterado nunca seja instalado.
2. Como usuário, quero que a instalação do lazydocker aborte se o download falhar (HTTP de erro), para que uma página de erro nunca vire binário.
3. Como usuário, quero que a versão detectada do lazydocker seja validada (formato `vX.Y.Z`), para que um header inesperado não monte uma URL arbitrária.
4. Como usuário, quero que o `wrk` seja compilado de uma tag/commit fixo, para que o HEAD de um repositório não verificado não seja executado.
5. Como usuário, quero que diretórios temporários dos instaladores sejam sempre removidos, mesmo em falha, para que nada sensível ou parcial sobre.
6. Como usuário, quero que `run` recuse scripts que não me pertencem, para que outro usuário local não execute código como eu.
7. Como usuário, quero que `run` recuse scripts graváveis por grupo/outros, para que alterações não autorizadas não sejam executadas.
8. Como usuário, quero que `run` avise/recuse um `SCRIPTS_DIR` inseguro (fora do meu controle), para que uma variável de ambiente maliciosa não redirecione a execução.
9. Como usuário, quero que `conn <alias>` valide o alias e use `ssh --`, para que um argumento como `-oProxyCommand=...` nunca seja interpretado como opção do ssh.
10. Como usuário, quero que `conn add/edit` rejeitem espaços, quebras de linha e caracteres de controle em hostname, user, identity file e proxy jump, para que diretivas não sejam injetadas no `~/.ssh/config`.
11. Como usuário, quero que o alias seja escapado ao procurar no `~/.ssh/config`, para que `.` não case outros hosts.
12. Como usuário, quero que `conn add` grave a configuração de forma atômica (arquivo temporário + `mv`), para que uma interrupção não corrompa meu `~/.ssh/config`.
13. Como usuário, quero que o arquivo temporário do `conn` seja removido em qualquer saída, para que cópias do config não sobrem.
14. Como usuário, quero que `http client show` mascare o `auth_token` por padrão, para que ele não apareça no terminal ou scrollback.
15. Como usuário, quero uma opção explícita para revelar o token quando eu realmente precisar, para manter a conveniência de forma consciente.
16. Como usuário, quero que `http -v` mascare o header `Authorization`, para que tokens não vazem em capturas de tela ou logs de terminal.
17. Como usuário, quero que o histórico do `http` não grave query string, para que tokens em URLs não fiquem em disco.
18. Como usuário, quero que o histórico do `http` sanitize `|` e quebras de linha, para que o log não seja corrompido ou forjado.
19. Como usuário, quero que `cron add/update/remove` validem o nome do job (letras, dígitos, `-`, `_`), para que caracteres especiais não afetem a busca.
20. Como usuário, quero que o nome do job case a linha de label exata, para que remover `a` não remova `ab`.
21. Como usuário, quero um aviso quando o comando do cron contém `%`, para que eu saiba que o cron o interpreta como nova linha.
22. Como usuário, quero que `stress` valide threads, conexões e duração (numéricos/formato `Ns|Nm|Nh`), para que opções malformadas não cheguem ao `wrk`.
23. Como usuário, quero um aviso de uso autorizado e confirmação ao rodar `stress` contra hosts que não sejam locais/privados, para evitar DoS acidental em terceiros.
24. Como mantenedor, quero que os workflows declarem `permissions: contents: read`, para reduzir o impacto de um comprometimento do CI.
25. Como mantenedor, quero actions fixadas por SHA, para que uma tag movida não injete código no CI.
26. Como mantenedor, quero o `bats-core` fixado em versão/commit, para que o CI seja reprodutível e seguro.
27. Como mantenedor, quero Dependabot para actions, para receber atualizações de segurança.
28. Como mantenedor, quero um `SECURITY.md`, para que vulnerabilidades sejam reportadas de forma responsável.
29. Como mantenedor, quero testes automatizados para cada validação nova, para evitar regressões.
30. Como usuário, quero mensagens de erro claras para cada entrada rejeitada, para entender o que corrigir.
31. Como usuário, quero que o uso legítimo existente (aliases, clients, jobs válidos) continue funcionando sem mudanças, para não quebrar meu fluxo.

## Implementation Decisions

- **Instaladores (biblioteca de SO):** download com falha em erro HTTP; versão validada por regex de semver com prefixo `v`; checksum SHA-256 obtido do arquivo de checksums do release e comparado antes da extração; `wrk` clonado em tag/commit fixo definido em constante; um único mecanismo de limpeza do diretório temporário (trap) por instalador, sem sobrescrever traps existentes.
- **`run`:** antes de executar, validar dono == usuário atual e ausência de bit de escrita para grupo/outros no script e no diretório; `SCRIPTS_DIR` fora de controle do usuário é recusado. Mensagem de erro explicando como corrigir (`chmod go-w`).
- **`conn`:** validação central de alias reutilizada por connect/add/edit/remove (sem prefixo `-`); `ssh --` na conexão; validadores para hostname, user, identity file e proxy jump rejeitando espaço, tab, CR/LF e controle; escape de metacaracteres do alias em regex; `conn add` passa a usar o mesmo fluxo de arquivo temporário + `mv` do `edit`; trap de limpeza do temporário.
- **`http`:** `client show` mascara token (mostra apenas os últimos 4 caracteres) com flag explícita para revelar; modo verbose substitui o valor do header `Authorization` por máscara na saída; histórico grava URL sem query string/fragmento e com `|`, CR e LF removidos/escapados.
- **`cron`:** validador de nome compartilhado por add/update/remove; busca da linha de label por igualdade exata (linha inteira), com valor passado ao awk por ambiente em vez de `-v` para evitar interpretação de escapes; aviso para `%` no comando.
- **`stress`:** validadores para threads/conexões (inteiros positivos) e duração (inteiro + unidade `s|m|h`); host de destino fora de loopback/rede privada exige confirmação interativa (ou flag explícita não interativa) com aviso de autorização.
- **CI:** `permissions: contents: read` em todos os workflows; actions por SHA com comentário da versão; bats instalado de release/commit fixo; configuração de Dependabot para GitHub Actions; `SECURITY.md` com canal de reporte.
- Compatibilidade retroativa: nenhuma flag/comando existente muda de nome; mudanças são somente rejeição de entradas inseguras e mascaramento por padrão (único comportamento visível alterado: token mascarado em `client show`/`-v`).

## Testing Decisions

- **Bom teste:** exercita apenas comportamento externo — invoca o CLI (`bin/<cmd>`) com `HOME`, `SCRIPTS_DIR` e diretórios de dados isolados em diretório temporário, e verifica código de saída, stdout/stderr e o conteúdo dos arquivos resultantes; não testa funções internas.
- **Seam escolhido:** CLI via bats, com stubs de `curl`, `ssh`, `sudo`, `crontab`, `git`, `wrk` colocados no início do `PATH` do teste (sem rede, sem sudo real, sem tocar no crontab/ssh reais).
- **Cobertura:** instaladores (checksum inválido aborta; versão malformada aborta; erro HTTP aborta; tmp removido), `run` (arquivo de outro dono/gravável por outros recusado; seguro executa), `conn` (alias `-o...` rejeitado; newline/espaço em campos rejeitado; `.` não casa outro host; config intacto após falha), `http` (token mascarado; `-v` mascarado; histórico sem query e sem `|`/newline), `cron` (nome inválido; `a` não afeta `ab`; aviso de `%`), `stress` (números/duração inválidos; confirmação para host externo), CI (checagem de `permissions` e SHAs por teste de lint simples, opcional).
- **Prior art:** `test/validation.bats`, `test/conn.bats`, `test/http.bats`, `test/os.bats` já seguem o padrão bats e devem ser estendidos.
- Gate: `shellcheck -x bin/* lib/*.sh` e `bats test/` devem passar.

## Out of Scope

- Reescrever as ferramentas em outra linguagem.
- Assinatura GPG de releases do próprio system-cli.
- Cifrar tokens em repouso (keychain/secret-service); apenas mascaramento e permissões.
- Sandboxing de scripts executados por `run` além da checagem de dono/permissão.
- Mudanças em `dk`, `dkc` e `vpn` (apenas repassam argumentos a docker/wg-quick; sem achados relevantes).
- Auditoria de dependências externas (docker, wireguard, wrk, lazydocker) além de verificar o que é baixado.

## Further Notes

- Fonte: análise estática de vulnerabilidades feita em 2026-10-10; plano em `~/.claude/plans/preciso-que-fa-a-uma-crystalline-finch.md`.
- Severidade: médios (supply chain dos instaladores, `run`, injeção no `conn`) priorizados antes dos baixos e do CI.
- O achado de `conn_connect` precisa de reprodução na implementação (o `conn_host_exists` pode já mitigar parcialmente); o teste deve provar o comportamento antes/depois.
- Publicação: arquivo local em `.claude/prd/` (sem issue tracker remoto, conforme decisão do usuário); estado `ready-for-agent`.
