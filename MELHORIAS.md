# Melhorias do Iferno

## Prioridade alta

### Feedback de combate

- [x] Flash visual ao acertar inimigos.
- [x] Numeros de dano por alguns frames (critico em amarelo e grande).
- [x] Particulas ao acertar e destruir inimigos.
- [x] Sons para tiro, acerto, dano recebido e morte (sintetizados em `scripts/sfx.gd`; arquivos em `assets/sfx/<nome>.wav` substituem).
- [x] Pequena tremida de camera em golpes fortes.
- [x] Barra de vida mais clara para elites e chefes.

### Upgrades

Escolha entre tres upgrades a cada 2 salas limpas e depois do chefe (`scripts/upgrades.gd`, `scripts/upgrade_pick.gd`). Pausa o jogo; escolhe com clique ou 1/2/3. Os upgrades passam de andar e zeram ao reprovar.

- [x] **Cafe duplo:** cura 1 vida e aumenta a velocidade por alguns segundos.
- [x] **Calculadora cientifica:** tiros atravessam um inimigo.
- [x] **Grampeador:** aumenta o dano, mas reduz a cadencia.
- [x] **Mochila pesada:** aumenta a vida, mas reduz o movimento.
- [x] **Monitoria:** reduz a recarga do dodge.
- [x] **Apostila:** adiciona mais projeteis ao disparo.
- [x] **Wi-Fi da faculdade:** projeteis perseguem levemente os inimigos.
- [ ] **Trabalho em grupo:** cria um pequeno aliado que atira junto.
- [x] **Caneta vermelha:** chance de causar dano critico.

## Prioridade media

### Salas especiais

- **Cantina:** cura ou compra itens.
- **Biblioteca:** combate mais dificil com recompensa melhor.
- **Xerox:** duplica um upgrade existente.
- **Laboratorio:** oferece uma mutacao temporaria de alto risco.
- **Sala dos professores:** mini-chefe ou item raro.
- **Banheiro:** emboscada curta com recompensa.

### Variedade de inimigos

- Zelador deixa uma poça que desacelera.
- Veterano faz uma investida com aviso visual forte.
- Professor cria zonas perigosas com notas vermelhas.
- Estagiario aparece em grupos maiores, mas continua fraco.
- Coordenadora altera portas ou controles por poucos segundos.

### Progressao

- Mostrar no HUD o andar, objetivo e salas limpas.
- Tela curta entre andares com estatisticas da run.
- Creditos permanentes para desbloquear estudantes ou melhorias.
- Recompensa exclusiva ao derrotar cada chefe.

## Personagens jogaveis

Criar quatro estudantes com estilos diferentes:

- **Veloz:** mais movimento e dodge menor.
- **Resistente:** mais vida e menor velocidade.
- **Atirador:** dano maior e pouca vida.
- **Especialista:** recargas menores e habilidades taticas.

## Visual e atmosfera

- Diferenciar visualmente cada andar.
- Adicionar ventiladores, monitores, luzes piscando e fumaça da cantina.
- Usar sombras mais fortes em moveis grandes.
- Criar pisos especificos para cada tipo de sala.
- Adicionar mais cartazes com frases aleatorias.
- Animar a abertura das grades depois de limpar uma sala.
- Destacar a escada liberada com luz e particulas.

## Chefe de Estatistica

- Barra de fases mais evidente.
- Cores diferentes para cada tipo de ataque.
- Pausas curtas depois de ataques grandes.
- Falas nas transicoes de fase.
- Recompensa unica depois da vitoria.

## Ordem recomendada

1. ~~Feedback de tiro, dano e morte.~~ (feito)
2. ~~Sistema de escolha entre tres upgrades.~~ (feito, falta o aliado do Trabalho em grupo)
3. Salas especiais de cantina, biblioteca e laboratorio.
4. Recompensas unicas dos chefes.
5. Quatro estudantes jogaveis.
6. Identidade visual propria para cada andar.
