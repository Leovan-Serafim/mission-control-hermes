---
name: wiki-skill
description: "Read/write Hermes memory wiki for Mission Control bridge."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [hermes, memory, wiki, mission-control, bridge]
    related_skills: [obsidian, memory-manager]
---

## When to Use

Use when reading/writing the Hermes memory wiki (`~/.hermes/wiki/`) that the Mission Control bridge mirrors to the `HermesMemory` table in Postgres. Trigger: "wiki read", "wiki write", "wiki list", "wiki commit".

# Wiki Skill — Hermes Memory Wiki

Skill para ler/escrever o **Hermes memory wiki** (markdown git-tracked em `~/.hermes/wiki/`) que o bridge do Mission Control espelha para a tabela `HermesMemory` no Postgres.

## Estrutura do Wiki

```
~/.hermes/wiki/
├── facts/          # Fatos verificados (type: fact)
├── notes/          # Anotações gerais (type: note)
├── open-loops/     # Pendências em aberto (type: open_loop)
├── decisions/      # Decisões registradas (type: decision)
├── links/          # Links de referência (type: link)
└── index.md        # Índice navegável
```

Cada entrada é um arquivo `.md` com frontmatter YAML:
```yaml
---
id: "slug-do-arquivo"
type: "fact" | "note" | "open_loop" | "decision" | "link"
title: "Título legível"
status: "active" | "archived"
confidence: "high" | "medium" | "low"
provenance: "source URL ou contexto"
tags: ["tag1", "tag2"]
links: ["outro-slug", "outro-slug-2"]
valid_from: "2026-01-15"
valid_to: ""
updated_at: "2026-10-31T12:00:00Z"
---

Corpo do conteúdo em markdown...
```

## Operações

### Ler entrada
```bash
hermes chat -q "wiki read facts/arquitetura-sistema"
```

### Escrever/atualizar entrada
```bash
hermes chat -q "wiki write facts/nova-entrada --type fact --title 'Nova Fato' --body 'Conteúdo...'"
```

### Listar entradas
```bash
hermes chat -q "wiki list --type fact"
```

### Commit e push (git)
```bash
hermes chat -q "wiki commit 'wiki: update facts/arquitetura-sistema'"
```

## Integração com Bridge

O bridge (`hermes-bridge/bridge.mjs`) roda a cada `BRIDGE_MIRROR_MS` (default 30s):
1. **Pull**: Lê `~/.hermes/wiki/`, faz parse do frontmatter, upserta em `HermesMemory`
2. **Push**: Recebe `AgentRequest` kind=`memory.write`, escreve no wiki, commita, espelha

## Convenções
- **Slugs**: kebab-case, sem espaços, ASCII apenas
- **Tipos**: `fact`, `note`, `open_loop`, `decision`, `link`
- **Status**: `active` (padrão) ou `archived`
- **Confidence**: `high` (verificado), `medium` (parcial), `low` (hipótese)
- **Provenance**: URL, sessão ID, ou "manual"
- **Tags**: lowercase, singular
- **Links**: array de slugs relacionados (bidirecional)

## Validação
- Frontmatter obrigatório em toda entrada
- `id` = caminho relativo sem `.md` (ex: `facts/arquitetura-sistema`)
- `updated_at` em ISO 8601 UTC
- Git commit message padrão: `wiki: <action> <slug> (via dashboard)`
