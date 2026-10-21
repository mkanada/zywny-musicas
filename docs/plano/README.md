# Plano de implementação — app de músicas (zywny-musicas)

Meta da 1.0: o usuário **abre uma música de uma biblioteca, vê a partitura e
toca essa música no teclado MIDI** — em **Linux, Android, Web e Windows**
(ordem de implementação, decidida pelo usuário: Windows por último por causa
do custo de infraestrutura — sem máquina local, precisa de VM/CI).

Este diretório é o plano **deste app**. O trabalho foi dividido em três
repositórios em 19/10/2026; cada fase mora onde o código dela mora (ver
**Onde está cada fase**). Leia **só** este README e o arquivo do passo que for
executar. Cada passo traz, em **"Contexto que você precisa"**, os fatos já
medidos/pesquisados — não refaça a pesquisa; se um fato estiver errado,
corrija o documento (passo 6 abaixo).

## Como executar um passo

1. Leia este README (seções **Convenções**, **Mapa do código** e **Fatos**) e
   o arquivo do passo.
2. Confira na tabela de passos se as dependências estão `concluído`.
3. Se o passo tiver **Decisão necessária** ainda não resolvida na tabela de
   decisões, **pare e pergunte ao usuário** antes de escrever código. Não
   decida sozinho.
4. Implemente só o escopo do passo ("Fora de escopo" existe para isso).
5. Rode **todos** os critérios de aceite e registre o resultado.
6. Marque o passo `concluído` na tabela e escreva "Notas de execução" no fim
   do arquivo do passo: desvios, números medidos, descobertas que afetam os
   passos seguintes. Se algo medido contradisser este README ou um passo
   futuro, **corrija o documento** — um número errado custa mais que nenhum.
7. Não faça commit nem push sem o usuário pedir.

## Os três repositórios

| Repo | Caminho | Papel |
| --- | --- | --- |
| **zywny-musicas** (este) | `/home/mauricio/IdeaProjects/zywny-musicas` | App de músicas: a biblioteca (`.zywny`), a tela da biblioteca, a partitura aberta, o play com som e a trilha de estudo de uma música da biblioteca |
| zywny-aprendizado | `/home/mauricio/IdeaProjects/zywny-aprendizado` | App de cursos: lições, exercícios, leitura à vista. Instala só pacotes de curso (`course.md`) |
| zywny-comum | `/home/mauricio/IdeaProjects/zywny-comum` | Núcleo compartilhado: o pacote `zywny_comum` (partitura, prática, trilha, MIDI, som, configurações, telas comuns), os pacotes `packages/*`, o `score_bridge/` e o motor de som nativo (`native/`) |

Cada app instala só o seu tipo de pacote: este instala bibliotecas e, se
receber um curso, diz que ele se abre no zywny-aprendizado.

O app usa o núcleo por caminho (`path:` no `pubspec.yaml`), que precisa estar
**ao lado**:

```
../zywny-comum              # obrigatório: o núcleo compartilhado
../verovio_flutter_bridge   # obrigatório: o pacote `verovio` e a libverovio.so
../Hymn_Grabber             # opcional: só para o pacote de hinos (uso privado)
```

`ZYWNY_COMUM` (no `justfile`) e `VEROVIO_BRIDGE` (nos scripts) sobrescrevem os
caminhos. Os scripts que compilam as bibliotecas nativas moram no zywny-comum e
escrevem o resultado na pasta deste app.

### Onde está cada fase

A regra que vale: **o passo aponta para o repositório onde o código mora.**

| Fase | Assunto | Onde está |
| --- | --- | --- |
| **B** | Bibliotecas instaláveis (`.zywny`), peças, curadoria, abrir pelo sistema | **aqui** (a tela e os geradores) e no zywny-comum (o envelope, o store, o `Piece`) |
| **D** | Papéis, distribuição, conta (Firebase Auth) e licenciamento por `uid` | **aqui** (a especificação e o portão do app); o pacote `zywny_auth` no zywny-comum |
| **J** | Trilha de estudo: a música em trechos, com etapas que se desbloqueiam | **aqui** (o `TrailRunner` do app); a política da trilha no zywny-comum |
| **L** | Trilha do decorar: as notas dão lugar a pausas coloridas até a prova com a partitura coberta | **aqui** (a entrada na biblioteca); o sumiço e a pausa substituta no zywny-comum |
| **O** | Letra no telão | **aqui** |
| **Q** | Transpor sem acidentes: ler a música em um tom sem sustenidos | **aqui** (a gaveta e o selo); o cálculo no zywny-comum |
| **R** | Revisão de código (bugs de dados, telas, serviços, arquivos grandes) | **aqui** os passos do app; os do núcleo e os do app de cursos foram para os repositórios deles |
| **U** | UX do celular: as telas do app de músicas | **aqui** (as telas); os widgets no zywny-comum |
| **V** | Portão da 1.0: matriz de plataformas | **aqui** |
| **Z** | Planos futuros | **aqui** |
| C, H, K, M, N, T, W, X, Y | Relógio, expressividade, motor de som, MIDI, notas, treino, Web, render por plataforma, nota fantasma | **zywny-comum** (o arquivo de passo saiu daqui) |
| E, EX, I | Ouvido, exercícios do curso, lições e curso inicial | **zywny-aprendizado** (os arquivos de passo já foram para lá) |

## Convenções

- **Rodar o app (Linux)**: `just run` (= `flutter run -d linux
  --no-enable-impeller`; sem Impeller por causa de flutter#191171).
  `just test`, `just analyze`. Headless: `xvfb-run -a` quando `DISPLAY` vazio.
  `just test-comum` e `just analyze-comum` rodam a suíte do zywny-comum.
- **Refazer a libverovio.so** depois de mexer no fork: `just native` (chama
  `verovio/bindings/dart/build_linux_so.sh` do bridge e faz `strip`).
  CLI do fork: `cd verovio/tools && cmake ../cmake && make -j4` →
  `verovio/tools/verovio --resource-path verovio/data`. Rode `cmake ../cmake`
  de novo ao criar `.cpp` (glob).
- **Estilo Dart**: `dart format` + `flutter analyze` sem avisos. Comentários
  em português no bridge; no zywny o código existente comenta em inglês —
  imite o arquivo que estiver editando.
- **Tempo**: tudo em **milissegundos musicais** da partitura (o `tstamp` do
  timemap, andamento original). Tempo de parede = musical / `speed`.
- **Testes de lógica sem hardware**: toda lógica (agendador, casamento de
  notas, avaliação) é Dart puro, testável com relógio simulado. Hardware só
  nos critérios marcados **(manual)** — descreva o que foi feito e o
  resultado nas notas.
- Saídas temporárias: diretório de scratch do sistema, nunca no repo.
- **Caminhos nos passos são um retrato da época.** As fases B, J, L, Q, R, U
  e D foram escritas quando o app era um repositório só; os caminhos citados
  dentro dos arquivos de passo (`lib/library/`, `lib/practice/`,
  `lib/trail/`, `lib/settings/`, `lib/render/`, `score_bridge/`,
  `packages/`) são os de então. Hoje a maior parte está no zywny-comum, e o
  **Mapa do código** abaixo é a referência atual.

## Mapa do código (estado em 2026-10-20)

### zywny-musicas (este app)

| Conceito | Onde |
| --- | --- |
| Entrada do app, `MyApp`, `AuthGate` | `lib/main.dart` |
| A tela da biblioteca e a busca | `lib/app/library_screen.dart` |
| Instalar uma biblioteca por arquivo | `lib/app/package_install.dart` |
| Escolha da saída de som (motor nativo ou MIDI out) | `lib/app/sound_output_controller.dart` |
| Render da partitura e transposição | `lib/app/score_render_session.dart` |
| Play, agendador, loop, metrônomo, contagem | `lib/app/playback_controller.dart` |
| A trilha de estudo de uma música da biblioteca | `lib/app/trail_runner.dart` |
| Os passeios de primeiro uso | `lib/tutorial/` |
| Bibliotecas: gerar pacotes | `tool/build_library.py`, `tool/build_hymn_assets.py` (hinos), `tool/build_classics.py`, `tool/fetch_classics.py` (curadoria) |
| Testes do app | `test/` (biblioteca, telas, controladores, teste de camadas) e `integration_test/telas_celular_test.dart` (as fotos das telas) |

### zywny-comum (núcleo, `../zywny-comum`)

| Conceito | Onde |
| --- | --- |
| Partitura | `lib/render/` (Verovio, layout, tamanho de página), `score_bridge/` (parser do `.vsb`, `ScenePainter`, `ScorePlayer`) |
| Prática e trilha | `lib/practice/` (sessão, modos, avaliação, cores, transpose check), `lib/trail/` (caminho, plano, etapa, progresso) |
| MIDI | `lib/midi/`, `packages/zywny_midi` |
| Som | `lib/audio/`, `packages/zywny_audio`, `native/zywny_audio` (Rust) e `web_src/` (SpessaSynth) |
| Configurações | `lib/settings/` (`AppSettings`, `PieceSettings`, transposição efetiva) |
| Interface comum | `lib/ui/`, `lib/app/` (painéis e telas compartilhados), `lib/about/` |
| Biblioteca (dados) | `packages/zywny_library` (envelope, pacote, store, `Piece`), `lib/incoming/` (pacotes abertos pelo sistema) |
| Autenticação | `packages/zywny_auth` (contrato `AuthStore`, SDK do Firebase, login de desktop) |
| Diagnóstico | `packages/zywny_diag` |

### Os dois outros repositórios

| Conceito | Onde |
| --- | --- |
| Cursos, lições, exercícios, leitura à vista | `../zywny-aprendizado/lib/` |
| Formato de curso | `../zywny-comum/packages/zywny_course_format` |

## Fatos (pesquisados em 2026-09-24, revistos em 2026-10-20)

- **Bibliotecas (fase B, 2026-10-04):** o app **não traz música nenhuma**; as
  músicas vêm de `.zywny` instalados por arquivo (D-BIB). O `.zywny` é um
  envelope cifrado e assinado (D-BIB-CIFRA): as chaves ficam em `keys/` (fora
  do git, **nunca vão ao remoto**) e a pública entra no build por
  `--dart-define=ZYWNY_LIBRARY_KEY` (as receitas do `justfile` leem de `keys/`;
  `just chaves` gera o par). `just pacote-hinos` gera `dist/hinos.zywny` (3,1
  MB, 600 hinos). Tirar os hinos embutidos (B08) encolheu o APK arm64 de
  74.238.467 para 71.183.847 B, o bundle Linux de 59.683.240 para 56.595.310 B
  e a Web de 72.319.773 para 69.174.996 B (~3,1 MB cada).

- **Estado das plataformas hoje:** só Linux roda. Android: existe
  `verovio/bindings/dart/android-libs/arm64-v8a/libverovio.so` no bridge e um
  `build_android_so.sh`, mas o zywny não empacota a lib nem sabe achá-la.
  Windows: **não existe build** da `verovio.dll`. Web: nada roda (FFI,
  isolates, `dart:io`).
- **Máquina de dev**: Pop!_OS 24.04, Flutter 3.47.4 stable, NDKs em
  `~/Android/Sdk/ndk/` (23…29), `cargo`/`rustup` com só
  `x86_64-unknown-linux-gnu`/`musl` instalados, Chrome disponível
  (`flutter devices`). **Sem `emcc`**, sem máquina Windows local.
- **Latência**: alvo tecla→som ≤ 20 ms (bom ≤ 10 ms). Fone Bluetooth soma
  150-250 ms — avise o usuário. Android varia muito por aparelho → calibração
  (no zywny-comum).
- **Piano digital tem som próprio**: se o app também sintetizar a entrada,
  sai som em dobro. O monitor da entrada pelo sintetizador do app vem
  **desligado** por padrão quando a saída é o próprio teclado.
- **A conta do aluno (fase D):** o login é feito no Firebase Authentication,
  no plano gratuito (Spark), num projeto só para o ecossistema Zywny — o app
  das músicas, o dos cursos e o painel do tutor apontam para o mesmo projeto,
  e a conta é a mesma nos dois. A configuração fica fora do git, em
  `keys/firebase.json`, e entra no build por `--dart-define`. Sem esse arquivo
  o app **compila do mesmo jeito e abre sem a conta** (é assim que os testes e
  o roteiro `just telas` rodam). Passo a passo em
  [D03](D03-configuracao-firebase-e-android-web.md).

## Decisões

| Id | Pergunta | Bloqueia | Recomendação | Status |
| --- | --- | --- | --- | --- |
| D-BIB | Bibliotecas instaláveis: distribuição, app vazio, origem, Web, fonte dos clássicos, remover, atualizar, migrar, termo, extensão | fase B | — | **decidida** (2026-10-04): as 14 decisões D-BIB-* no [B00](B00-bibliotecas-instalaveis.md) |
| D-BIB-CIFRA | Pacote `.zywny` cifrado e assinado; privada gera, pública sob controle do usuário, chaves fora do git | fase B | — | **decidida** (2026-10-04): ver o B00 "O envelope" |
| D-SALTO | Trilha em músicas cujo caminho sem repetições tem salto (casas de 1ª/2ª vez, vários ritornelos): salto no agendador ou usar a última passagem? | J08 | (a) salto no agendador (generaliza o loop para vãos; sessões pré-filtradas sem os vãos) — a via (b) resgatava só 15/115 saltos | **decidida (a)**: ver [J08](J08-saltos-no-caminho.md) |
| D-TRP | Transpor sem acidentes: alvo, direção, tom do som do app, escopo, progresso, conferência, nomes, lições | fase Q | — | **decidida** (2026-10-04): as 8 decisões D-TRP-* no [Q00](Q00-transpor-sem-acidentes.md) |
| D-TREINO | Tolerâncias e UX do treino (janela de acerto, o que conta como erro) | T03 | ±75 ms "certo", ±150 ms "quase", fora disso "errado/perdido"; ornamentos e apojaturas não cobrados na 1.0 | **aberta** |
| D-RITMO | Treino de rítmica: janelas, cobrar duração, som do toque | T05 | ±60 ms "certo", ±130 ms "quase" (de parede); duração não cobrada; toque soa as notas esperadas do onset ("piano mágico") | **aberta** |
| D-FAIXA | Onde mora a informação da trilha no celular: na barra do título, ou numa faixa própria que não cobre a pauta? (O J00 pede "uma faixa fina na partitura"; hoje ela cobre as cifras e o cabeçalho dos painéis) | U01 | (a) barra do título — a área da partitura não muda e não há re-render; (b) faixa própria sempre presente, que custa 34 dp de pauta | **aberta** |
| D-OUVIR | Sem teclado conectado, o que o play da trilha faz? | U03 | "Ouvir o trecho" como ação própria e sempre disponível, **e** o play sem teclado ouve o trecho; alternativa: só trocar o aviso por um com o botão "Conectar" | **aberta** |
| D-SOM | "Som do app" nasce ligado? | U04 | Sim, respeitando quem já gravou desligado; mais um alto-falante na barra do título | **aberta** |
| D-SELO | O que o selo mostra durante o treino | U05 | A porcentagem corrente na conta do resultado, com a meta ("72% · meta 90%"); alternativa: os quatro contadores do resumo | **aberta** |
| D-VIRADA | Desfoque da página revelada na virada | U06 | (a) manter, mas nítida no último quarto do último compasso e sempre nítida em pausa; (b) tirar o desfoque; (c) como está | **decidida (c)**: como está, sem mudança — o U06 foi dispensado |
| D-CONTAGEM | Onde fica o número da contagem inicial | U09 | (a) grande, na metade direita, sem crescer nem desfocar, opacidade até 50%; (b) pontos de pulso na barra do título; (c) como está | **decidida (a)**: número grande na metade direita (U09) |
| D-SISTEMAS | Dois sistemas por página no celular (notação menor que 12)? | U10 (parte 3) | Decidir com a tabela que o U10 mede (compassos por página × altura do pentagrama); as partes 1 e 2 do passo não dependem disto | **decidida**: não — `kPhoneUnit` fica em 12 (a medição do U10 mostra que dois sistemas só cabem com unit ≈ 6) |
| D-MODOS | Um seletor só de quatro modos (Ouvir, Espera, Tempo real, Ritmo) no lugar do seletor de dois + dois interruptores? | U11 | Sim | **decidida**: sim (U11) |
| D-ORDEM | A seta da ordenação: direção real ("↑" crescente) ou a regra do artboard ("↓" = direção padrão da chave)? | U14 (só a seta) | Direção real | **decidida**: direção real (U14) |
| D-REV-SIMPL | A nota da versão simplificada: mostrar as duas na linha da música, ou juntar numa só? | R20 | (a) mostrar as duas ("simplificada N%"); a ordenação usa a do original | **aberta** |
| D-REV-CABEC | Cabeçalho das telas secundárias: `AppBar` com tema, ou um cabeçalho próprio no desenho da biblioteca? | R26 | (a) `AppBar` com `appBarTheme`; biblioteca e partitura ficam com o cromo delas | **aberta** |
| D-REV-DI | Como os serviços do app chegam às telas: `provider` ou `InheritedWidget` à mão? | R27 | (a) `provider` | **aberta** |
| D-REV-ROTAS | Adotar `go_router` (URL de `#` na Web) ou ficar com `Navigator.push`? | R35 | (b) ficar como está por enquanto; rever se a Web ganhar uso próprio | **aberta** |
| D-NEG | Papéis, distribuição, login obrigatório no Firebase Auth (Google e redes sociais, plano Spark até 50k MAU, compartilhado no `zywny-comum`) e licenciamento de pacotes por conta | fase D | — | **decidida** (2026-10-17 e 2026-10-19): as 15 decisões D-NEG-* no [D00](D00-papeis-e-distribuicao.md) |

As decisões do núcleo (D-SF, D-MIDI, D-WIN, D-WEB, D-WEB-SYNTH) e as do app
de cursos (D-LIC, D-OUV, D-LEI, D-EXE) saíram daqui com as fases delas.

## Riscos conhecidos

1. **A Web é o item mais caro** e não é por causa do som: o pipeline do `.vsb`
   é todo FFI. Mitigação: o protótipo do Verovio em wasm (W01, no
   zywny-comum) antes de ligar a Web.
2. **Latência no Android**. Mitigação: medir de ponta a ponta antes de
   construir o treino em cima.
3. **Notas presas** (note on sem note off) em pause/seek/erro. Mitigação: toda
   implementação de `SoundEngine` tem `allNotesOff()` e ela é chamada em
   pause, stop, seek, troca de dispositivo e `dispose`.
4. **Pitch errado com 8va/transposição**: não use `getMIDIValuesForElement`.
   Mitigação: o pitch que o Verovio calcula é o que o app usa.

## Passos

Os passos do app. Os do núcleo e os do app de cursos não estão aqui (ver
**Onde está cada fase**).

| Passo | Título | Depende de | Decisão | Status |
| --- | --- | --- | --- | --- |
| [B01](B01-formato-e-leitor.md) | Bibliotecas: formato `.zywny` e leitor (Dart puro) | — | D-BIB | concluído |
| [B02](B02-gerador-de-pacotes.md) | Bibliotecas: gerador de pacotes e o `hinos.zywny` | B01 | D-BIB | concluído |
| [B03](B03-guardar-bibliotecas.md) | Bibliotecas: guardar pacotes (nativo e IndexedDB) e a em uso | B01 | D-BIB | concluído |
| [B04](B04-musicas-por-biblioteca.md) | Bibliotecas: `Piece`, chaves por biblioteca e migração | B01, B03 | D-BIB | concluído |
| [B05](B05-instalar-por-arquivo.md) | Bibliotecas: tela sem biblioteca e instalar por arquivo | B04 | D-BIB | concluído em código (aceite manual pendente) |
| [B06](B06-bibliotecas-nas-configuracoes.md) | Bibliotecas: seção nas configurações gerais | B05 | D-BIB | concluído em código (aceite manual pendente) |
| [B07](B07-vocabulario-da-biblioteca.md) | Bibliotecas: vocabulário e ordenação do manifesto | B04 | D-BIB | concluído em código (aceite manual pendente) |
| [B08](B08-app-sem-hinos-embutidos.md) | Bibliotecas: o app sem hinos embutidos | B05, B06, B07 | D-BIB | concluído (aceite manual pendente) |
| [B09](B09-curadoria-dos-classicos.md) | Bibliotecas: curadoria dos clássicos (musetrainer/library) | — | lista aprovada pelo usuário | proposta pronta (43 peças), **aguardando aprovação** |
| [B10](B10-pacote-dos-classicos.md) | Bibliotecas: pacote dos clássicos | B02, B09 | D-BIB | pendente (espera a aprovação do B09) |
| [B11](B11-abrir-pelo-sistema.md) | Bibliotecas: o app abre `.zywny` pelo sistema (associação de arquivos) | B05 | — | Android feito e testado no emulador; Linux parcial; sem commit |
| [D01](D01-pacote-zywny-auth.md) | Autenticação: pacote `zywny_auth` no `zywny-comum` (`AuthStore`, 7 dias offline, SDK + REST/Loopback, `FakeAuthStore`) | — | D-NEG | concluído (2026-10-19) |
| [D02](D02-tela-de-login-e-auth-gate.md) | Autenticação: `SignInScreen`, `AuthGate`, apelido inicial e seção Conta nas configurações | D01 | D-NEG | concluído (2026-10-19) |
| [D03](D03-configuracao-firebase-e-android-web.md) | Autenticação: projeto Firebase (plano Spark), `applicationId` e credenciais OAuth2 nas 4 plataformas | D01, D02 | D-NEG | código pronto (2026-10-19); **falta criar o projeto no console** |
| [D04](D04-licencas-de-pacotes-por-conta.md) | Licenciamento: abertura e catálogo de bibliotecas/pacotes vinculados ao `uid` e validade | D01, D02, D03 | D-NEG | pendente |
| [D05](D05-publicacao-no-google-play.md) | Publicação: chave de release, AAB e upload pela Play Developer API | D03 | — | código pronto (2026-10-20), 1ª versão na faixa `internal`; **faltam os questionários e o teste fechado** |
| [J01](J01-caminho-e-trechos.md) | Trilha: caminho sem repetições e corte em trechos (Dart puro) | — | — | concluído (medição dos 600 nas notas) |
| [J02](J02-avaliacao-da-etapa.md) | Trilha: avaliação da etapa e blocos de reforço (Dart puro) | — | — | concluído |
| [J03](J03-modelo-e-progresso.md) | Trilha: modelo, desbloqueio e progresso persistente | J01 | — | concluído |
| [J04](J04-passagem-unica.md) | Trilha: passagem única de um intervalo no `PracticeController` | J02 | — | concluído |
| [J05](J05-tela-da-etapa.md) | Trilha: tela para executar uma etapa | J03, J04 | — | concluído (critérios manuais 5-6 no aparelho, aguardando verificação) |
| [J06](J06-gaveta-e-configuracao.md) | Trilha: lista de etapas, pular, refazer, configuração de N | J05 | — | concluído (critério manual 6 no aparelho, aguardando verificação) |
| [J07](J07-fase-final-e-reforco.md) | Trilha: fase final e reforço | J05 | — | concluído (critério manual 7 no aparelho, aguardando verificação) |
| [J08](J08-saltos-no-caminho.md) | Trilha: saltos no caminho (casas, vários ritornelos) | J04, J07 | D-SALTO | concluído (critério manual 5 no aparelho, aguardando verificação) |
| [J09](J09-progresso-na-biblioteca.md) | Trilha: progresso na biblioteca | J03 | — | concluído (critério manual 5 em 360 dp, aguardando verificação) |
| [L01](L01-sorteio-do-sumico.md) | Decorar: colunas e sorteio do sumiço (Dart puro) | J01 | — | pendente |
| [L02](L02-esconder-notas.md) | Decorar: esconder colunas no `score_bridge` (nota, barra, linha suplementar) | G09 (bridge) | — | pendente |
| [L03](L03-pausa-substituta.md) | Decorar: pausa substituta colorida (`score_bridge`) | L02, G09 (bridge) | — | pendente |
| [L04](L04-plano-e-progresso-do-decorar.md) | Decorar: plano, desbloqueio e progresso | J03, L01 | — | pendente |
| [L05](L05-passagem-com-sumico.md) | Decorar: passagem com sumiço e revelação no `PracticeController` | J04, L02, L03 | — | pendente |
| [L06](L06-tela-do-decorar.md) | Decorar: tela para entrar na trilha e executar etapas | J05, J06, L04, L05 | — | pendente |
| [L07](L07-prova-as-cegas.md) | Decorar: prova às cegas e marca "de cor" | L06 | — | pendente |
| [L08](L08-decorar-na-biblioteca.md) | Decorar: na biblioteca | J09, L04 | — | pendente |
| [Q01](Q01-verovio-transpondo.md) | Transpor: medir o Verovio transpondo (`.vsb`, repetições, determinismo, faixa) | — | — | concluído (469 hinos, 0 problemas; ids mudam a cada render — ver as notas) |
| [Q02](Q02-calculo-da-transposicao.md) | Transpor: `Transposition` e `PitchFrame` (cálculo puro) | — | D-TRP | concluído |
| [Q03](Q03-guardar-e-renderizar.md) | Transpor: guardar por música, chave geral, render transposto | Q01, Q02 | D-TRP | **concluído** (2026-10-06) |
| [Q04](Q04-progresso-por-tom.md) | Transpor: progresso separado por tom | Q03 | D-TRP | **concluído** (2026-10-06) |
| [Q05](Q05-as-alturas-no-app.md) | Transpor: casador na altura escrita, som no tom original | Q02, Q03 | D-TRP | **concluído** (2026-10-06) |
| [Q06](Q06-conferencia-no-teclado.md) | Transpor: conferência no teclado | Q05 | D-TRP | **concluído** (2026-10-06) |
| [Q07](Q07-lembretes-e-detector.md) | Transpor: lembrete de voltar a 0 e detector de deslocamento | Q05 | — | **concluído** (2026-10-06) |
| [Q08](Q08-tela-e-aceite.md) | Transpor: gaveta, selo, lista dos 12 tons e aceite manual | Q04, Q06, Q07 | D-TRP | código, testes e `just telas` feitos (2026-10-06); **aceite manual pendente** (teclado do usuário) |
| [R05](R05-telas-do-app-em-lib-app.md) | Revisão: biblioteca e painéis de configuração em `lib/app/` (achado 8) | — | — | **concluído** (2026-10-06) |
| [R06](R06-arquivos-soltos-da-raiz.md) | Revisão: arquivos soltos da raiz de `lib/`; lista de desvios vazia (achado 8) | R05 | — | **concluído** (2026-10-06) |
| [R07](R07-opened-piece-obrigatorio.md) | Revisão: `OpenedPiece` obrigatório (achado 6) | R05 | — | código e testes feitos (2026-10-06); **aceite manual pendente** |
| [R08](R08-sound-output-controller.md) | Revisão: `SoundOutputController` (achado 5) | R07 | — | código e testes feitos (2026-10-06); **aceite manual pendente** |
| [R09](R09-score-render-session.md) | Revisão: `ScoreRenderSession` (achado 5) | R08 | — | código e testes feitos (2026-10-07); **`just telas` pendente** |
| [R10](R10-playback-controller.md) | Revisão: `PlaybackController` (achado 5) | R09 | — | código e testes feitos (2026-10-07); **aceite manual pendente** |
| [R11](R11-trail-runner.md) | Revisão: `TrailRunner` (achado 5) | R10 | — | código e testes feitos (2026-10-07); **`just telas` e aceite manual pendentes** |
| [R12](R12-workspace-e-mockup.md) | Revisão: workspace na raiz; mockup em `apps/zywny_mockup` (achado 10) | R06 | — | feito (2026-10-07); **`just run-mockup` (manual) pendente** |
| [R19](R19-ler-sem-apagar.md) | Revisão 2: erro de leitura não apaga o progresso (achado 12) | — | — | pendente |
| [R20](R20-nota-da-simplificada.md) | Revisão 2: nota da versão simplificada na lista (achado 13) | — | D-REV-SIMPL | pendente |
| [R21](R21-mensagens-de-problema.md) | Revisão 2: mensagens de problema (achado 14) | — | — | pendente |
| [R22](R22-dialogos-de-confirmacao.md) | Revisão 2: diálogos de confirmação (achado 15) | — | — | pendente |
| [R26](R26-cabecalhos-das-telas.md) | Revisão 2: cabeçalhos das telas (achado 19) | — | D-REV-CABEC | pendente |
| [R27](R27-servicos-do-app.md) | Revisão 2: serviços do app (achado 20) | R19 | D-REV-DI | pendente |
| [R28](R28-um-motor-de-som.md) | Revisão 2: um motor de som para o app (achado 21) | R27 | — | pendente |
| [R29](R29-partitura-e-transposicao.md) | Revisão 2: partitura em `lib/score/`; fluxo de transposição (achado 22) | R28 | — | pendente |
| [R30](R30-partitura-em-widgets.md) | Revisão 2: partitura em widgets (achado 22) | R29 | — | pendente |
| [R31](R31-biblioteca-em-arquivos.md) | Revisão 2: biblioteca em arquivos menores (achado 22) | R28 | — | pendente |
| [R34](R34-dependencias-e-pubspec.md) | Revisão 2: dependências e `pubspec.yaml` (achado 24) | — | — | pendente |
| [R35](R35-rotas.md) | Revisão 2: rotas com `go_router` (achado 25) | R27, R31 | D-REV-ROTAS | pendente |
| [U01](U01-faixa-fora-da-pauta.md) | UX: a faixa da trilha sai de cima da pauta | — | D-FAIXA (a) | concluído (critérios 3–5, no emulador, aguardando verificação) |
| [U02](U02-a-pauta-mostra-o-trecho.md) | UX: a pauta mostra o trecho da etapa | — | — | concluído (critérios 2–5, no emulador, aguardando verificação) |
| [U03](U03-ouvir-o-trecho.md) | UX: ouvir o trecho, e o que fazer sem teclado | U01 | D-OUVIR | concluído (critérios 3–5, no emulador e no aparelho, aguardando verificação) |
| [U04](U04-som-ligado-e-indicador.md) | UX: som ligado por padrão e indicador | U01 | D-SOM | concluído (critérios 3–5, no emulador e no aparelho, aguardando verificação) |
| [U05](U05-selo-na-regua-do-resultado.md) | UX: o selo e o resumo na mesma régua | U01 | D-SELO | concluído (critério 5, no emulador, aguardando verificação) |
| [U06](U06-virada-legivel.md) | UX: virada de página que deixa ler adiante | — | D-VIRADA | dispensado (D-VIRADA = c, como está) |
| [U07](U07-barra-lateral-da-trilha.md) | UX: barra lateral com os valores da etapa | U03 | — | concluído (critérios 4–5, no emulador, aguardando verificação) |
| [U08](U08-cores-do-destaque.md) | UX: cores do destaque — primeira nota, mão do app, legenda | — | — | concluído (sem o "×" da nota perdida, adiado; critérios 3–5, no emulador, aguardando verificação) |
| [U09](U09-contagem-fora-do-primeiro-compasso.md) | UX: a contagem sai de cima do primeiro compasso | — | D-CONTAGEM | concluído (critérios 3–5, no emulador, aguardando verificação) |
| [U10](U10-aproveitar-a-tela.md) | UX: aproveitar a tela — imersivo, centro, dois sistemas | U01 | D-SISTEMAS | concluído (parte 1 no emulador, aguardando verificação; partes 2 e 3 sem mudança, por decisão) |
| [U11](U11-gaveta-de-opcoes.md) | UX: gaveta de opções — um seletor de modo, e o que vale na trilha | — | D-MODOS | concluído (critério 5, no emulador, aguardando verificação) |
| [U12](U12-resumos-legiveis.md) | UX: resumos — erros na pauta e frases no lugar de milissegundos | U02, U05 | — | concluído (critério 5, no emulador, aguardando verificação) |
| [U13](U13-progresso-a-vista.md) | UX: progresso à vista — gaveta, linha do hino e pontuação | — | — | concluído (critérios 6–7, no emulador e no aparelho, aguardando verificação) |
| [U14](U14-ordenar-e-buscar.md) | UX: biblioteca — ordenar e buscar | — | D-ORDEM | concluído (critério 6, no emulador, aguardando verificação) |
| [U15](U15-conectar-o-teclado.md) | UX: conectar o teclado — orientação e estado | — | — | concluído (critério 6, no emulador, aguardando verificação) |
| [U16](U16-primeiro-uso.md) | UX: primeiro uso — cartão de começo | U13, U15 | — | concluído (critério 5, no emulador, aguardando verificação) |
| [U17](U17-vocabulario.md) | UX: vocabulário das configurações | U15 | — | concluído (critério 4, no emulador, aguardando verificação) |
| [U18](U18-um-visual-so.md) | UX: um visual só — tema e superfícies | U12 | — | concluído (critérios 5–6, no emulador e no aparelho, aguardando verificação) |
| [U19](U19-refazer-as-telas.md) | UX: refazer as telas e conferir os achados | todos os U | — | concluído (fotos refeitas; achados conferidos na seção "Depois da fase U" do estudo) |
| [U20](U20-sobre-e-tutorial.md) | UX: tela "Sobre o Zywny" e tutorial de primeiro uso | U16, U17 | — | concluído (código, testes e Web; aceite no aparelho pendente, ver o passo) |
| [V01](V01-portao-da-1-0.md) | Portão da 1.0: matriz de plataformas | todos | — | pendente |

Fases com especificação própria, que o passo correspondente deve ler:

- [J00-trilha-de-estudo.md](J00-trilha-de-estudo.md) — a trilha, do começo
  (caminho sem repetições) à fase final.
- [L00-trilha-do-decorar.md](L00-trilha-do-decorar.md) — o decorar; se apoia
  na fase J.
- [Q00-transpor-sem-acidentes.md](Q00-transpor-sem-acidentes.md) — as três
  alturas da transposição e a conferência no teclado.
- [O00-letra-no-telao.md](O00-letra-no-telao.md) — a letra no telão (proposta
  de execução expressiva, ainda sem passo).
- [B00-bibliotecas-instalaveis.md](B00-bibliotecas-instalaveis.md) — o formato
  do pacote `.zywny` e as decisões D-BIB.
- [D00-papeis-e-distribuicao.md](D00-papeis-e-distribuicao.md) — os papéis
  (plataforma, tutor, aluno) e as decisões D-NEG.
- [U00-ux-do-celular.md](U00-ux-do-celular.md) — a fase U, que executa as
  sugestões de [`../ux/sugestoes-ux-celular.md`](../ux/sugestoes-ux-celular.md).
- [Z00-planos-futuros.md](Z00-planos-futuros.md) — ideias depois da 1.0.

A fase **R** tem especificação em
[`../revisao/2026-10-06-qualidade-e-divisao.md`](../revisao/2026-10-06-qualidade-e-divisao.md)
(primeira rodada, R05–R12) e
[`../revisao/2026-10-15-revisao-geral.md`](../revisao/2026-10-15-revisao-geral.md)
(segunda, R19–R35). Quem executa um passo R lê o documento da rodada
correspondente.

## O que saiu daqui

Em 19/10/2026 o projeto foi dividido em três repositórios. Estes arquivos de
passo saíram deste diretório — o código que eles descrevem está em outro
repositório:

| Saiu | Onde o código está | Passos ainda abertos |
| --- | --- | --- |
| C01, H00, K01–K06, M01–M03, N01–N03, T01–T05, W01–W04, X01–X02, Y01, `windows-a-partir-do-linux.md` | [zywny-comum](https://github.com/mkanada/zywny-comum) | K05 (motor no Android), K06 (motor no Windows), X02 (render no Windows) |
| R01–R04, R13–R17, R24, R25, R33 | [zywny-comum](https://github.com/mkanada/zywny-comum) | R24 (fontes embutidas), R25 (escala de texto), R33 (lints estritos) |
| R18, R23, R32 | [zywny-aprendizado](https://github.com/mkanada/zywny-aprendizado/tree/main/docs/plano) | os três, para o app de cursos |
| E00–E10, EX00–EX22, I00–I13 | [zywny-aprendizado](https://github.com/mkanada/zywny-aprendizado/tree/main/docs/plano) | E05–E10, EX01–EX22 (fases do app de cursos) |

O histórico completo continua no repositório antigo `zywny` e no histórico do
git deste repositório.
