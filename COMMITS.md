# Padrão de commits e branches

- [Branches](#branches)
- [Commits](#commits)

---

# Branches

## Regra principal

**`main` sempre roda.** Nada vai pra `main` quebrado. Toda mudança nasce numa branch, é testada e só depois entra na `main`.

## Formato do nome

```
tipo/descricao-curta-com-hifens
```

- Tudo em minúsculas, sem acentos, sem espaços (use `-`).
- Usa os **mesmos tipos dos commits** (tabela mais abaixo).
- Descrição curta: 2 a 5 palavras dizendo o que a branch faz.

## Tipos de branch

| Branch | Quando usar | Exemplo |
|---|---|---|
| `feat/` | Nova mecânica ou conteúdo | `feat/inimigo-espiral` |
| `fix/` | Correção de bug | `fix/tiro-durante-roll` |
| `art/` | Sprites, animações, tilesets | `art/sprites-jogador` |
| `audio/` | Sons e música | `audio/sons-de-armas` |
| `level/` | Salas, mapas, geração procedural | `level/geracao-de-andares` |
| `balance/` | Rodada de ajustes de números | `balance/armas-andar-1` |
| `ui/` | HUD e menus | `ui/menu-principal` |
| `refactor/` | Reorganizar código | `refactor/classe-base-arma` |
| `perf/` | Desempenho | `perf/pool-de-projeteis` |
| `docs/` | Documentação | `docs/padrao-de-commits` |
| `chore/` | Configuração e ferramentas | `chore/configura-export` |
| `build/` | Exportação e builds | `build/preset-windows` |
| `exp/` | **Experimento**: testar uma ideia que pode ir pro lixo | `exp/arma-bumerangue` |

`exp/` é especial pra jogo: protótipo rápido sem compromisso. Se a ideia ficar boa, vira `feat/`. Se não, é só apagar a branch.

## Fluxo do dia a dia

```bash
# 1. Parte sempre da main atualizada
git switch main
git switch -c feat/inimigo-espiral

# 2. Trabalha e commita (padrão de commits abaixo)
git add -A
git commit -m "feat(enemy): adiciona inimigo que atira em espiral"

# 3. Testa: ./run.sh play

# 4. Volta pra main e junta
git switch main
git merge --no-ff feat/inimigo-espiral

# 5. Apaga a branch que já foi juntada
git branch -d feat/inimigo-espiral
```

`--no-ff` guarda no histórico que aquelas mudanças vieram juntas de uma branch, o que facilita desfazer uma feature inteira depois.

## Boas práticas

- **Uma branch = um assunto.** Não misture o inimigo novo com o menu.
- **Branch de vida curta.** Junte em poucos dias, assim ela não fica muito diferente da `main`.
- **Cuidado com `.tscn` em duas branches ao mesmo tempo.** Conflito em cena do Godot é chato de resolver. Evite editar a mesma cena em duas branches abertas.
- **Versões do jogo** são marcadas com tag na `main`: `git tag v0.1.0` (demo jogável), `v0.2.0` (próximo marco)...

---

# Commits

Este projeto segue o [Conventional Commits](https://www.conventionalcommits.org/pt-br/), adaptado pra um jogo.

## Formato

```
tipo(escopo): descrição curta no imperativo

Corpo opcional explicando o porquê da mudança,
não só o que mudou.

Rodapé opcional (ex.: Closes #12, BREAKING CHANGE: ...)
```

- **tipo**: obrigatório, em minúsculas (lista abaixo).
- **escopo**: opcional, diz a parte do jogo afetada (lista abaixo).
- **descrição**: até ~70 caracteres, verbo no imperativo ("adiciona", "corrige"), sem ponto final.
- **corpo**: separado por uma linha em branco. Use quando a mudança não for óbvia.

## Tipos

| Tipo | Quando usar | Exemplo |
|---|---|---|
| `feat` | Nova mecânica, conteúdo ou funcionalidade | `feat(enemy): adiciona inimigo que atira em espiral` |
| `fix` | Correção de bug | `fix(player): impede atirar durante o dodge roll` |
| `art` | Sprites, tilesets, animações, efeitos visuais | `art(player): adiciona animação de corrida` |
| `audio` | Efeitos sonoros e música | `audio(weapon): adiciona som de tiro da pistola` |
| `level` | Salas, mapas, geração procedural de andares | `level(dungeon): cria sala do chefe do andar 1` |
| `balance` | Ajuste de números: dano, vida, velocidade, drop rate | `balance(weapon): reduz cadência da metralhadora` |
| `ui` | HUD, menus, telas | `ui(hud): mostra munição restante` |
| `refactor` | Reorganiza código sem mudar comportamento | `refactor(weapon): extrai classe base Weapon` |
| `perf` | Melhora desempenho | `perf(bullet): usa pool de projéteis` |
| `docs` | Documentação (README, CLAUDE.md, este arquivo) | `docs: descreve padrão de commits` |
| `chore` | Configuração, ferramentas, arquivos do projeto | `chore: atualiza .gitignore` |
| `build` | Exportação e builds (Linux, Windows, web) | `build: adiciona preset de exportação Windows` |
| `test` | Testes automatizados | `test(player): testa invencibilidade no roll` |
| `revert` | Desfaz um commit anterior | `revert: feat(enemy): inimigo em espiral` |

## Escopos sugeridos

`player`, `enemy`, `boss`, `weapon`, `bullet`, `item`, `room`, `dungeon`, `hud`, `menu`, `camera`, `input`, `save`, `fx`.

Escopo novo pode ser criado quando fizer sentido. Mantenha curto e em inglês, igual aos nomes das pastas e cenas.

## Mudanças que quebram compatibilidade

Use `!` depois do tipo e explique no rodapé. No jogo, isso vale principalmente pra coisas que quebram save ou cenas existentes:

```
feat(save)!: muda formato do arquivo de save para JSON

BREAKING CHANGE: saves antigos (.dat) não são mais lidos.
```

## Boas práticas

- **Um commit = uma mudança.** Nova arma e correção do HUD vão em commits separados.
- **Commit pequeno e frequente.** Facilita voltar atrás se algo quebrar o jogo.
- **Rode o jogo antes de commitar** (`./run.sh play`) e confira se não há erros no console.
- **Não commite** a pasta `.godot/` (cache) nem builds exportadas (`export/`). O `.gitignore` já cuida disso.
- Arquivos `.uid` e `.import` gerados pelo Godot **devem** ser commitados junto com o recurso.

## Exemplos ruins → bons

| Ruim | Bom |
|---|---|
| `mudanças` | `feat(weapon): adiciona espingarda com 5 projéteis` |
| `fix bug` | `fix(enemy): corrige inimigo atravessando parede` |
| `ajustei umas coisas no player e no hud` | dois commits: `balance(player): ...` e `ui(hud): ...` |
| `Adicionado sprite.` | `art(enemy): adiciona sprite do slime` |
