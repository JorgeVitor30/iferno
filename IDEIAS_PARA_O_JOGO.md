# Ideias para evoluir o Iferno

> Documento de sugestões — nada aqui é obrigatório. A ideia é servir como cardápio para escolher as próximas melhorias sem perder o tema da faculdade.

## Direção geral

O jogo já tem uma boa base de combate, salas com ondas, upgrades e recompensas. A evolução pode se apoiar em três objetivos:

1. **Cada run deve permitir um estilo de jogo diferente.**
2. **As recompensas precisam ser fáceis de entender e empolgantes de escolher.**
3. **O cenário deve ser mais que decoração, sem atrapalhar a leitura do combate.**

## 1. Armas que o jogador pode trocar

### Proposta simples para começar

- Começar cada run com uma arma básica e encontrar outras durante a exploração.
- Carregar **duas armas** e alternAo encontrar uma arma ar com `Q` ou a roda do mouse; deixar a tecla remapeável.
- Ao encontrar uma arma nova, mostrar uma escolha clara: **equipar e trocar** ou **manter a atual**.
- Não usar munição limitada no primeiro protótipo. Diferenciar as armas por dano, cadência, alcance, dispersão e recarga.
- Mostrar a arma ativa no HUD e dar um feedback curto ao trocar.
- Upgrades passivos devem dizer se afetam todas as armas ou só a arma ativa.

### Ideias de armas

| Arma | Papel | Identidade de faculdade | Ponto forte / compensação |
|---|---|---|---|
| **Pistola de Grampos** | Equilibrada | Grampeador reforçado | Boa para começar; dano e alcance médios. |
| **Escopeta de Furador** | Curta distância | Furador de provas que dispara grampos em leque | Muito forte de perto; lenta e imprecisa de longe. |
| **Régua de Precisão** | Longo alcance | Régua metálica ou lapiseira adaptada | Tiro carregado, atravessa vários inimigos; pouca cadência. |
| **Carimbo Automático** | Alta cadência | Carimbo que dispara marcas de tinta | Muitos tiros rápidos; dano baixo e dispersão crescente. |
| **Canhão de Xerox** | Área | Copiadora portátil que lança bolas de papel | Explosão em área; disparo lento e fácil de antecipar. |
| **Régua Bumerangue** | Controle de grupo | Régua que vai e volta | Pode acertar na ida e na volta; exige posicionamento. |

### Regras para as armas ficarem distintas

- Cada arma deve resolver uma situação diferente, não ser apenas “a mesma arma com mais dano”.
- O tiro precisa ter silhueta, cor, som e impacto próprios, reconhecíveis mesmo no meio da ação.
- Armas raras podem mudar uma regra do combate, mas devem ter uma desvantagem compreensível.
- Testar cada arma sozinha e junto com upgrades; evitar combinações que limpem salas sem exigir movimento.
- Uma primeira versão pode ter só **pistola, escopeta e arma de precisão**. As outras ficam para depois.

## 2. Baús e upgrades

O projeto já tem escolhas de upgrades durante a run e um baú que oferece opções raras. O baú pode ser o lugar de recompensas especiais, sem substituir as escolhas normais.

### Melhorias para os baús

- Exibir três opções com raridade, descrição curta e comparação com os atributos atuais.
- Garantir que as opções sorteadas ainda possam ser obtidas e não estejam no limite de acúmulo.
- Variar a recompensa: upgrade raro, arma nova, cura ou escolha entre duas recompensas menores.
- Dar um som, uma animação e um brilho diferentes para baús comuns, raros e de chefe.
- Baús amaldiçoados podem oferecer uma recompensa melhor em troca de um risco anunciado antes de abrir.

### Sugestões de upgrades raros para baú

| Upgrade | Efeito sugerido |
|---|---|
| **Gabarito Oficial** | Tiros causam mais dano em inimigos com a vida cheia. |
| **Estojo Completo** | Trocar de arma recarrega parcialmente a arma guardada. |
| **Caderno de Fórmulas** | A cada certo número de acertos, o próximo tiro recebe um efeito especial. |
| **Fone com Cancelamento** | Reduz o dano recebido durante um curto período depois de usar o dodge. |
| **Diploma Provisório** | Bônus geral enquanto estiver com pouca vida; perde o bônus ao se curar. |
| **Cola em Bastão** | Tiros têm chance de desacelerar inimigos por pouco tempo. |

Os efeitos são rascunhos: ajustar números e nomes para não duplicar upgrades existentes, como crítico, ricochete, projéteis extras, cura e dodge ofensivo.

### Combinações entre armas e upgrades

- **Escopeta + crítico:** vários projéteis, mas controlar a chance para não multiplicar o dano demais.
- **Arma de precisão + atravessar:** construir uma linha de tiros contra grupos alinhados.
- **Bumerangue + ricochete:** testar com cuidado para evitar projéteis que ficam acertando sem parar.
- Exibir no inventário os upgrades ativos e deixar visíveis as sinergias importantes.

## 3. Novas mecânicas de jogo

### Salas de desafio

- **Prova surpresa:** derrotar ondas com uma regra especial e ganhar o baú raro.
- **Biblioteca silenciosa:** inimigos mais fortes, mas menos numerosos; recompensa melhor.
- **Laboratório:** escolher entre um efeito poderoso e temporário ou um efeito permanente com custo.
- **Sala da xerox:** duplicar um upgrade, com uma seleção limitada para evitar combinações quebradas.
- Mostrar a regra e a recompensa antes de entrar; o jogador não deve ser pego de surpresa por uma penalidade escondida.

### Objetivos opcionais dentro das salas

- Derrotar a onda sem receber dano.
- Destruir um objeto específico antes de acabar o combate.
- Sobreviver por alguns segundos a uma prova cronometrada.
- Proteger um objeto da sala, como um computador ou pilha de provas.
- Completar o objetivo dá uma recompensa pequena, sem bloquear a saída se o jogador falhar.

### Progressão de combate

- Adicionar variações de inimigos com avisos visuais claros, em vez de aumentar somente a vida e o dano.
- Criar ataques de chefe com pausas para esquiva e janelas de contra-ataque.
- Considerar um bônus de estilo por esquivas próximas, variedade de armas ou sequência de acertos; manter o bônus simples e legível.
- Entre andares, mostrar um resumo rápido: salas concluídas, dano recebido, inimigos derrotados e arma mais usada.

## 4. Componentes interativos no cenário

| Componente | Possível interação |
|---|---|
| **Máquina de refrigerante** | Quebrar para derrubar uma cura pequena ou ativar uma explosão de latas. |
| **Copiadora** | Ao levar dano, solta uma nuvem de papel que bloqueia projéteis por pouco tempo. |
| **Armários** | Podem servir de cobertura temporária ou esconder um item. |
| **Carteiras e cadeiras** | Empurráveis; bloqueiam tiros e mudam de posição com explosões. |
| **Quadro branco** | Um tiro pode apagar ou revelar uma pista/recompensa da sala. |
| **Interruptores e disjuntores** | Abrem portas, acendem uma sala escura ou desligam um perigo. |
| **Piso molhado** | Acelera o deslize do jogador e dos inimigos; sinalização antes de entrar na área. |
| **Ventiladores** | Empurram projéteis leves ou criam zonas de vento previsíveis. |
| **Portas e catracas** | Criam atalhos entre salas depois de cumprir uma condição. |

### Cuidados com o cenário

- Começar com um ou dois objetos interativos por tipo de sala.
- Fazer com que objetos destrutíveis sejam distinguíveis de móveis sólidos.
- Não esconder projéteis, inimigos ou o jogador atrás de efeitos e móveis altos.
- Preferir interações com consequência imediata e fácil de entender.

## 5. UX — deixar tudo mais claro e confortável

### Durante o combate

- HUD com **nome/ícone da arma ativa**, arma guardada e indicação de recarga, se existir.
- Mostrar a vida do chefe e as fases de forma consistente; telegráficos de ataques precisam contrastar com o chão.
- Indicar de onde veio o dano recebido com um breve flash ou direção, sem cobrir a ação.
- Mostrar cooldown do dodge e feedback de invulnerabilidade de forma discreta.
- Usar ícones consistentes para cura, baú, saída, perigo e objetivo.

### Escolhas e inventário

- Em cada carta, mostrar claramente **o que muda**, **quanto muda** e, quando relevante, **o custo**.
- Comparar atributos antes/depois (por exemplo: dano, tiros por segundo, alcance e dispersão da arma).
- Permitir ver a descrição completa de um upgrade no inventário sem pausar por muito tempo.
- Diferenciar visualmente upgrades novos, acumuláveis e já no limite.
- Ao trocar uma arma, oferecer comparação direta com a equipada.

### Navegação e controles

- Mostrar controles essenciais na primeira sala e deixar o lembrete consultável depois.
- No minimapa, distinguir salas visitadas, salas desconhecidas, baú, chefe e saída.
- Indicar a direção do objetivo quando o jogador estiver longe, sem transformar o mapa em GPS obrigatório.
- Permitir remapear teclas e escolher entre segurar ou alternar ações quando fizer sentido.
- Incluir pausa com **continuar**, **opções**, **reiniciar run** e **voltar ao menu**, sempre com confirmação para ações destrutivas.

### Acessibilidade e opções

- Controles separados para volume geral, efeitos e música.
- Opção de reduzir tremor de câmera, flashes e partículas.
- Contraste ajustável para avisos de perigo; não depender só de cores para comunicar.
- Escala de interface e textos legíveis em diferentes resoluções.
- Garantir que as cores das raridades continuem distinguíveis para pessoas com daltonismo.

## 6. Conteúdo e progressão entre runs

- Desbloquear estudantes com estilos diferentes, sem tornar o personagem inicial obsoleto.
- Liberar armas novas por desafios claros (por exemplo, vencer um chefe usando dodge ou concluir uma sala sem dano).
- Adicionar recordes locais: melhor andar, tempo, chefe derrotado e armas usadas.
- Criar pequenas cenas/textos entre andares para reforçar a história da faculdade.
- Fazer cada andar ter paleta, objetos, perigos e inimigos próprios, reaproveitando sistemas já existentes.

## Ordem sugerida de implementação

### Etapa 1 — variedade de combate

- [ ] Definir troca de duas armas e como o jogador encontra/substitui armas.
- [ ] Implementar pistola, escopeta e arma de precisão.
- [ ] Adicionar indicador da arma ativa e comparação ao pegar outra.
- [ ] Testar combinações com os upgrades atuais.

### Etapa 2 — valor das recompensas

- [ ] Revisar apresentação e variedade das escolhas do baú.
- [ ] Adicionar dois ou três upgrades raros com efeitos bem distintos.
- [ ] Adicionar pelo menos uma sala de desafio com regra e recompensa anunciadas.

### Etapa 3 — salas mais vivas

- [ ] Criar um objeto interativo por ambiente (por exemplo, copiadora ou máquina de refrigerante).
- [ ] Testar cobertura e perigos sem prejudicar a leitura dos projéteis.
- [ ] Expandir salas especiais e variedade de inimigos.

### Etapa 4 — polimento de UX

- [ ] Completar HUD de armas, recarga, objetivos e mapa.
- [ ] Revisar menus, controles remapeáveis e confirmações.
- [ ] Adicionar opções de acessibilidade e resumo entre andares.

## Princípios de balanceamento

- Toda vantagem grande deve ter um custo, condição ou situação em que seja menos útil.
- O jogador deve entender a recompensa antes de escolhê-la.
- Evitar upgrades que só aumentem números sem mudar decisões de jogo.
- Testar a dificuldade com armas diferentes, não apenas com a combinação mais forte.
- Priorizar mudanças pequenas e testar uma mecânica nova por vez.
