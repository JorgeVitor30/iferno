# Lore — Iferno

> Documento vivo. A lore ainda está em desenvolvimento, e o que está aqui é a base atual.

## Premissa

Iferno é um roguelike top-down passado numa **faculdade**. Os protagonistas querem **se formar**, mas estão **presos** dentro da faculdade. Cada run é uma tentativa de escapar dela, e escapar aqui significa se formar.

## Mundo

- Os ambientes (andares, salas, biomas) são **lugares de uma faculdade**.
- Tudo no jogo segue o tema universitário: inimigos, armas, upgrades, itens.

## Protagonistas

São **4 jogadores**, todos estudantes tentando se formar.

| # | Nome | Descrição | Estilo de jogo |
|---|---|---|---|
| 1 | _a definir_ | | |
| 2 | _a definir_ | | |
| 3 | _a definir_ | | |
| 4 | _a definir_ | | |

## Inimigos e chefes

- **Chefes (bosses)** são os **professores**, e outras figuras da faculdade também entram nessa categoria.
- Inimigos comuns (todos atacam com coisas de papel ou do dia a dia da faculdade):

| Inimigo | Tipo | Ataque |
|---|---|---|
| Zelador | corpo a corpo | esfregada em arco com o esfregão; deixa poças e a plaquinha de piso molhado |
| Veterano do trote | corpo a corpo, rápido | mira e investe com o balde de tinta, sujando o chão |
| Professor | à distância | leque de provas corrigidas (com nota vermelha) |
| Estagiário | à distância, fraco | aviõezinhos de papel que perseguem o jogador |
| Coordenadora | elite surpresa (aparece na última onda de uma sala sorteada) | anel e espiral de bolinhas de papel, leque de provas |

## Andares

- Cada andar é gerado na hora: salas ligadas por corredores. Começa na **portaria** (onde o ônibus deixa os estudantes) e termina no **auditório**, onde está o chefe do andar.
- **Só dá pra subir de andar depois de derrotar o chefe**: a escada aparece no auditório quando ele cai.
- Chefe do 1º andar: **Professor de Estatística**. Topete, óculos redondos enormes, bigodão, gravata borboleta, suspensório; quase 3x o tamanho de um estudante. Muita vida, 3 fases (66%: chama monitores; 33%: fica furioso e emenda golpes).
  - Golpes: *y = log(x)* (giz em curvas logarítmicas), *curva normal* (leque de provas em sino), *calculadora* (explode em números), *histograma* (barras sobem do chão, sempre com uma brecha), *dispersão* (pontos caem do gráfico), *regressão linear* (avisa com uma reta e dispara por ela), *desvio padrão* (anéis), *amostra aleatória* (rajada), *SILÊNCIO!!* (se você fica colado nele).
  - Mira onde o jogador vai estar e escolhe o golpe pela distância, mas sempre avisa antes e para pra limpar os óculos de vez em quando.
- Salas: sala de aula, biblioteca, laboratório, cantina, sala dos professores, xerox, lab. de informática, banheiro. Tamanho, móveis e decoração são sorteados (cada tipo tem 2 a 3 jeitos de arrumar).
- Entrou numa sala com inimigos: a porta tranca com grade e fita de "interditado" até todo mundo cair.
- Café cura 1 de vida.
- Andar 1 = entrada da faculdade. Os de cima (bloco de aulas, biblioteca central...) ainda reaproveitam as mesmas salas, só que mais difíceis.

## Armas e upgrades

- As armas e os upgrades são **ligados ao ambiente universitário**, como objetos e situações do dia a dia de quem estuda.
- Lista: _a definir_.

## Perguntas em aberto

- Por que os estudantes estão presos? O que mantém eles lá?
- O que significa "se formar" no jogo (vencer o chefe final, juntar créditos)?
- Como cada andar ou ambiente corresponde a uma parte da faculdade?
- O que muda entre uma run e outra (o que o jogador carrega quando morre)?
