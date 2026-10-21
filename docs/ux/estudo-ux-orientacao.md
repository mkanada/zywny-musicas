# Estudo de UX — retrato e paisagem no celular

Avaliação das telas fotografadas nas **duas orientações** (2026-10-06,
`main` em `942c4aa`): [`docs/telas/celular/retrato/`](../telas/celular/retrato/)
e [`docs/telas/celular/paisagem/`](../telas/celular/paisagem/), lado a lado em
[`docs/telas/ORIENTACAO.md`](../telas/ORIENTACAO.md). Os números entre
parênteses — (02), (30) — são os das telas, os mesmos de
[`celular/README.md`](../telas/celular/README.md); **R** e **P** dizem a
orientação.

Este estudo complementa o [estudo da fase U](estudo-ux-celular.md), que olhou
cada tela só na orientação em que o app a mostrava. Aqui a pergunta é outra:
**o que acontece quando o aparelho está na outra posição?** Também registro o
que mudou desde as fotos de 05/10 (o giro da biblioteca).

As telas de curso, lição e exercício foram retiradas daqui: são do app de
cursos, que virou o [zywny-aprendizado](https://github.com/mkanada/zywny-aprendizado).

## Método e limites

- Mesmo método do estudo anterior: avaliação heurística, de um avaliador só,
  sobre as fotos e o código. Os achados são hipóteses fundamentadas, não
  medições com alunos.
- **Como as fotos foram feitas.** O roteiro `just telas` ganhou
  `--dart-define=ZYWNY_TELAS_ORIENTACAO=retrato|paisagem`: o tamanho da tela
  é fixado no Flutter (1080×2274 ou 2274×1080 px, 411×866 dp no emulador
  `Medium_Phone_2`) para todas as telas. As barras do sistema viram margens
  fixas (24 dp de status e 16 dp de navegação em retrato; nenhuma em paisagem).
  Isso é um bom retrato do layout, mas não do Android: o giro de verdade, o
  teclado virtual e as barras reais não aparecem.
- **A partitura só existe em paisagem** no celular (trava em `lib/main.dart:440`
  e não grava a página numa caixa em retrato, `lib/main.dart:615`). Na
  passagem em retrato ela abre deitada e **não é fotografada**: 10–25 e 30–45
  só têm a versão P. A foto
  [`retrato/extra-partitura-em-retrato.png`](../telas/celular/retrato/extra-partitura-em-retrato.png)
  mostra o que aconteceria se a trava não valesse (ver O4).
- Na passagem em paisagem, o roteiro gira a tela para retrato só pelo instante
  de tocar no hino, porque em paisagem a lista não aparece (O1).

Gravidade: **alta** — engana o aluno ou trava o caminho principal;
**média** — atrapalha, mas ele passa; **baixa** — acabamento.

## Resumo

O app foi desenhado com uma orientação por tela: biblioteca em retrato e
partitura em paisagem. Desde o `cfcf647` (05/10), a biblioteca segue o giro do
aparelho, e é aí que mora o achado mais grave: **em paisagem a biblioteca não
mostra nenhum hino.** O caso não é raro. Quem estuda põe o celular deitado na
estante do piano, e é assim que ele volta da partitura, que é sempre paisagem.

Fora isso, os problemas são de espaço (a busca atrás do teclado virtual, a
partitura em branco onde a trava de orientação não vale) e, na partitura, a
página parada no meio da virada ao retomar a trilha (a confirmar).

Se só der para fazer duas coisas: **O1** e **O2**, e conferir **P1** num aparelho.

## Mapa: cada tela em cada orientação

| Telas | Retrato | Paisagem |
|---|---|---|
| Abertura (01) | boa | boa, outro arranjo (logo ao lado do nome) |
| Biblioteca (02–05, 26–28, 46) | boa; busca apertada com o teclado (O2) | **sem nenhum hino na tela** (O1) |
| Seletor de teclado (06, 29) | bom | bom |
| Configurações gerais (07–09) | boas | boas (cartão central, rola) |
| Partitura, trilha, treino (10–25, 30–45) | não existe (trava) | é a orientação do desenho |

## Achados

### O — Orientação

**O1 · alta · Em paisagem, a biblioteca não mostra nenhum hino.**
(P02, P03, P04, P05, P26, P27, P28, P46)

<img src="../telas/celular/paisagem/27-biblioteca-com-historico.png" width="460">

Em paisagem a tela tem ~411 dp de altura. O topo da biblioteca é fixo:
título, busca, cartão "Comece por aqui" ou "Continuar" e ordenação. Esse topo
ocupa a altura inteira, e a lista fica num `Expanded` com o que sobra, que é
nada (`lib/app/library_screen.dart:652-673`).
Consequências:

- a lista de 600 hinos simplesmente não aparece; em P26 aparece só o topo da
  primeira linha;
- a busca (P03) aceita o texto e não mostra resultado nenhum, nem a mensagem
  de "nenhum hino" (P04);
- trocar a ordenação (P05, P28) não muda nada visível;
- não há rolagem que resolva: o que rola é a lista, e ela tem altura zero.

Até o `cfcf647` a biblioteca era travada em retrato; depois passou a seguir o
aparelho (`_followDevice`, `lib/app/library_screen.dart:260`). O celular
deitado na estante, voltando de um hino, cai direto aqui.

- Rápido: travar de novo a biblioteca em retrato.
- Melhor: o topo rola junto com a lista (`CustomScrollView`, com a busca e a
  ordenação presas no alto ao rolar). Em paisagem sobra largura: um arranjo de
  duas colunas (cartões à esquerda, lista à direita) mostra ~5 hinos de uma vez.

**O2 · média · Em retrato, a busca fica atrás do teclado virtual.** (R03, R04)

<img src="../telas/celular/retrato/03-biblioteca-busca.png" width="230">

Os resultados começam a ~51% da altura (R03): acima deles ficam a busca, o
cartão "Comece por aqui" e a ordenação. O teclado
virtual do Android cobre ~40% de baixo, então o aluno digita e vê um ou dois
resultados (a foto não mostra o teclado: o espaço é o dele). A mensagem
"Nenhum hino com 'chopin'" (R04) também cai no meio da tela, onde estaria o
teclado.

- Com a busca em foco, esconder o cartão "Comece por aqui"/"Continuar". A
  ordenação pode ficar, porque é curta.
- A mesma regra alivia O1, se o topo continuar fixo.

**O4 · baixa · Onde a trava não vale, a partitura fica em branco para sempre.**
(foto extra em `retrato/`)

<img src="../telas/celular/retrato/extra-partitura-em-retrato.png" width="200">

A partitura pede paisagem e, numa caixa mais alta que larga, não grava a
página: fica esperando o giro (`lib/main.dart:611-615`). No celular o Android
gira e tudo bem. Já em tablets e dobráveis abertos, o Android 16 ignora a
trava de orientação dos apps que miram o SDK 36. Também em janela dividida, a
tela fica eternamente em "5 · Jubilosos Te Adoramos", com o play desabilitado
e sem explicação. Não é o alvo (ver a meta "celular, não tablet"), mas
custa pouco: depois de ~1 s em retrato, mostrar "Gire o aparelho para ver a
partitura" no lugar do título.

### P — Partitura (paisagem)

**P1 · alta, a confirmar · A página retomada fica parada no meio da virada.**
(P30, P35)

<img src="../telas/celular/paisagem/30-trilha-retomada.png" width="460">

Ao retomar a trilha pelo "Continuar" (P30) e ao escolher a etapa seguinte
(P35), a partitura aparece borrada, com só o último compasso da página
anterior nítido atrás da haste azul. O aluno está **parado**, olhando o
trecho que vai tocar, e não consegue lê-lo. Nas fotos de 05/10 as mesmas
telas mostravam o trecho nítido e marcado. Aqui o defeito se repetiu nas
quatro passagens em paisagem. Pode ser regressão do `cfcf647`/`bc3d33c` (os
dois mexem em `lib/main.dart`) ou efeito do tamanho forçado do roteiro. Na
passagem forçada o aparelho não gira ao abrir o hino, e a gravação da página
pode seguir outro caminho. Conferir num aparelho antes de mexer.

**P2 · baixa · Rótulo cortado na barra lateral.** (P11, P30, P33, P37)
Sob a mão da etapa aparece "mão da" — o "etapa" não cabe nos 84 dp da barra.
"da etapa" sob o andamento cabe (P37); sob a mão, não. Sugestão: "mão" só,
como no treino livre.

**P3 · baixa · O texto da etapa some na barra do título.** (P37, P38)
"Trecho 1/6 · Tudo junto no ritmo 50% · 98…" — com etapa de nome longo, a
parte cortada é o que o aluno queria ler. O andamento já está na barra
lateral ("50% da etapa"), então pode sair do título.

Continuam abertos do estudo anterior e aparecem nestas fotos: a primeira
nota verde com a etapa parada (P11, P13), o borrão da virada atrás dos
resumos (P34, P39, P42), a cifra "C7sus♮(7)" sobreposta (P21) e a linha do
hino cortando o "melhor" (R27).

### Biblioteca em retrato — miúdos

- **Ordenação rolada esconde a escolha** (R05): depois de rolar as pastilhas
  até "Dificuldade", a escolhida fica cortada na borda ("ficuldade ↑"). Em
  retrato cabem quatro das seis; ao escolher, centralizar a pastilha.
- **Seletor de teclado apertado** (R29): "Teclado digital" quebra em duas
  linhas para caber "Desconectar" ao lado. O botão pode ir para baixo do
  nome.

## Prioridade

| # | Achado | Gravidade | Esforço |
|---|---|---|---|
| O1 | Biblioteca sem hinos em paisagem | alta | baixo (travar) / médio (rolar junto) |
| P1 | Página parada na virada ao retomar | alta, a confirmar | ? |
| O2 | Busca atrás do teclado virtual | média | baixo |
| O4 | Partitura em branco onde a trava não vale | baixa | baixo |
| P2, P3 | acabamento | baixa | baixo |

## Como refazer

    emulator -avd Medium_Phone_2 -read-only -no-window -no-audio &
    adb push dist/hinos.zywny /data/local/tmp/hinos.zywny
    TELAS_DIR=docs/telas/celular/retrato just telas \
        --dart-define=ZYWNY_TEST_LIBRARY=/data/local/tmp/hinos.zywny \
        --dart-define=ZYWNY_TELAS_ORIENTACAO=retrato
    # idem com paisagem

Sem `ZYWNY_TELAS_ORIENTACAO`, o roteiro faz o de sempre (cada tela na
orientação do app, em `docs/telas/celular/`).
