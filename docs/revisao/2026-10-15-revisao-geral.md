# Revisão de código — segunda rodada (15/10/2026)

Revisão do repositório inteiro (`lib/`, `packages/`, `score_bridge/`, ~44 mil
linhas), depois da fase R01–R17. As perguntas: há bugs? Como está a
arquitetura, a consistência das telas, o que ainda dá para dividir, e que
bibliotecas ajudariam?

Resumo: o código continua bem testado (1124 testes, `flutter analyze`
limpo) e os pacotes do workspace têm fronteiras boas. Os problemas que
sobraram são de três tipos: dados do aluno que podem ser perdidos ou ficar
invisíveis, telas que resolvem a mesma coisa de jeitos diferentes, e dois
arquivos (`main.dart`, `library_screen.dart`) que voltaram a crescer, com a
biblioteca fazendo o papel de raiz de composição do app.

Este documento é a especificação da **segunda rodada da fase R**. O
trabalho está dividido nos passos R18–R35 (tabela no fim), um arquivo por
passo em `docs/plano/`, no formato dos outros passos (ver
`docs/plano/README.md`, "Como executar um passo"). Quem executa um passo
lê este documento e o arquivo do passo. A numeração dos achados continua a
da [primeira rodada](2026-10-06-qualidade-e-divisao.md) (1–10).

> **Depois da divisão em três repositórios (19/10/2026).** Este texto é de
> 15/10, quando o app ainda era um só. Dos passos R18–R35, ficaram neste
> repositório os que mexem no app de músicas (R19–R22, R26–R31 e R35,
> tabela no fim). R18, R23 e R32 são do app de cursos e foram para o
> [zywny-aprendizado](https://github.com/mkanada/zywny-aprendizado/tree/main/docs/plano); R24, R25 e R33
> são do núcleo compartilhado, o arquivo de passo saiu daqui e o código
> está no [zywny-comum](https://github.com/mkanada/zywny-comum). Os achados 11, 16, 17, 18 e 23
> saíram junto com eles.

Diferente da primeira rodada, alguns passos **mudam o que a pessoa vê**
(mensagens, diálogos, fontes, cabeçalhos). Esses passos pedem `just telas`
antes e depois, e aceite manual.

## Já corrigido (16/10, sem commit quando este documento foi escrito)

- **O "Continuar" sumia depois de tocar a versão simplificada.**
  `PieceProgressStore.recordScore` marcava como "aberta" uma entrada nova;
  a simplificada (`<id>.s`) virava a última aberta e não está no catálogo.
  Agora só `markOpened` marca como aberta.
- **Escrita no progresso do curso antes da leitura.** As escritas de
  `CourseProgressStore` partiam de um progresso vazio se o curso ainda não
  tinha sido lido. Agora esperam a leitura, e a leitura não troca uma
  escrita que chegou antes. (App de cursos — agora no
  [zywny-aprendizado](https://github.com/mkanada/zywny-aprendizado).)
- **"Voltar ao passo" mostrava um passo não gravado.** A tela de níveis só
  confirma depois de gravar; se falhar, volta ao passo anterior e avisa.
  Um store novo lê o último valor gravado mesmo com a escrita a caminho.
  (Leitura à vista — app de cursos.)

O primeiro tem teste de regressão em `test/progresso_por_tom_test.dart` (a
parte da música, que fica aqui); os outros dois, em
`test/course_progress_test.dart` e `test/sight_levels_screen_test.dart` (no
app de cursos).

## O que está bom

- Pacotes do workspace com fronteiras limpas: `zywny_music`,
  `zywny_course_format` e `zywny_library` são Dart puro e testáveis (hoje
  no [zywny-comum](https://github.com/mkanada/zywny-comum/tree/main/packages)).
- `ExerciseSource` deixa a leitura à vista e o "só ouvido" reaproveitarem a
  `ExerciseScreen` inteira. (App de cursos.)
- Os controllers da primeira rodada (`SoundOutputController`,
  `ScoreRenderSession`, `PlaybackController`, `TrailRunner`) têm guardas
  `_disposed` consistentes e são testados sem widget.
- As cores estão centralizadas em `lib/ui/theme.dart` (45 `Color(0x…)`, 21
  deles lá).
- Comentários que explicam o porquê.

## Achados abertos

| # | Achado | Tipo | Passos |
|---|--------|------|--------|
| 11 | Arquivos de curso com `:` no nome não gravam no Windows | bug | R18 *(app de cursos)* |
| 12 | Um erro de leitura faz a próxima gravação apagar o progresso | bug | R19 |
| 13 | A nota da versão simplificada não aparece em lugar nenhum | produto | R20 |
| 14 | Mensagens mostram a exceção crua; redação desigual | UX | R21 |
| 15 | Diálogos de confirmação repetidos, sem destaque no destrutivo | UX | R22 |
| 16 | Tela de níveis da leitura: seis acabamentos | UX/código | R23 *(app de cursos)* |
| 17 | Fontes do texto baixadas da internet na primeira abertura | bug/UX | R24 *(núcleo)* |
| 18 | 202 tamanhos de fonte soltos, sem escala | UX | R25 *(núcleo)* |
| 19 | Cabeçalhos das telas de dois jeitos | UX | R26 |
| 20 | Os serviços do app vivem no estado da biblioteca | arquitetura | R27 |
| 21 | Dois motores de som abertos ao mesmo tempo | arquitetura | R28 |
| 22 | Arquivos grandes demais | arquitetura | R29–R31 |
| 23 | Lints do pacote padrão, sem as regras estritas | ferramentas | R33 *(núcleo)* |
| 24 | Dependências atrasadas; `pubspec.yaml` com textos do modelo | ferramentas | R34 |
| 25 | Navegação sem rotas (sem URL na Web) | arquitetura | R35 |

### 12. Erro de leitura apaga o progresso

Os stores juntam "não consegui ler" e "não há nada guardado" num valor
vazio. A próxima gravação parte do vazio e sobrescreve o que estava no
aparelho:

- `CourseProgressStore._read` (`lib/course/course_progress.dart`) devolve
  `null` em qualquer erro. O aluno veria lições concluídas bloqueadas de
  novo e exercícios sem o selo de aprovado.
- `PieceProgressStore.load` (`packages/zywny_library/lib/piece_progress.dart`)
  limpa o mapa inteiro; `_save` regrava a biblioteca toda. Perdem-se as
  notas e o "Continuar" de todas as músicas.
- `TrailProgressStore.ensureLoaded` (`lib/trail/trail_progress.dart:299`)
  descarta a trilha; a primeira etapa feita grava por cima.
- `SightReadingStore._load` volta ao 1a; a próxima rodada grava por cima.

JSON corrompido é outro caso, e ali começar do zero é o certo. Erro de
leitura é raro no Android e no desktop; na Web acontece com armazenamento
bloqueado.

**Como resolver:** separar os quatro resultados (ausente, valor,
corrompido, ilegível). Ilegível bloqueia a gravação daquela chave até uma
leitura dar certo.

### 13. Nota da versão simplificada

A simplificada grava a nota com o id `<id>.s`
(`lib/app/library_screen.dart:703`). A lista só lê pelo id do catálogo
(`_progressOf`, `library_screen.dart:563`): a linha ("melhor N%",
`library_screen.dart:1241`) e a ordenação por nota
(`packages/zywny_library/lib/library_sort.dart:103`) ignoram a
simplificada. Não há perda nem erro; a nota fica guardada e invisível.

**Como resolver:** decisão de produto (D-REV-SIMPL): mostrar as duas, ou
juntar numa nota só.

### 14. Mensagens de problema

Cerca de dez lugares mostram a exceção ao aluno (`… : $e`): por exemplo
`library_screen.dart:740` e `app/sound_output_controller.dart:278`. A redação varia: "Não consegui",
"não consegui" (minúscula) e "Não deu para".

**Como resolver:** um helper que mostra só o texto amigável e manda o
detalhe para o `DiagLog`; padrão "Não consegui …".

### 15. Confirmações

O mesmo `AlertDialog` (Cancelar + verbo) está escrito em cinco lugares; o
`confirmTrailReset` (`lib/trail/trail_widgets.dart:265`) já existe mas não
é usado por todos. Nenhum botão destrutivo (Remover, Reiniciar) tem cor
própria.

**Como resolver:** um `confirmAction` em `lib/ui/`, com `destructive:`.

### 19. Cabeçalhos

As telas secundárias usam `AppBar` (Sobre, rascunho, exercício); biblioteca,
configurações e partitura têm cabeçalhos próprios. O voltar, a fonte do
título e a cor do fundo variam.

**Como resolver:** decisão D-REV-CABEC (um padrão para as secundárias).

### 20. Serviços dentro do estado da biblioteca

`_LibraryScreenState` (`lib/app/library_screen.dart:222-290`) cria o
`MidiDeviceManager`, o `AppSettings`, seis stores e os motores de som dos
cursos, e os passa à mão para a partitura (`OpenedPiece`). O `dispose`
(L457–L471) descarta cada store só se não veio de fora
(`if (widget.progress == null)`), a mesma posse dupla do achado 6.

**Como resolver:** um objeto de serviços criado no `main()` e exposto por
escopo (D-REV-DI).

### 21. Dois motores de som

A escolha do motor está escrita duas vezes: `library_screen.dart:285-323`
(abertura do pacote) e `SoundOutputController` (partitura). Com uma música
aberta, o motor do pacote continua aberto por baixo.

**Como resolver:** um `SoundOutputController` só, nos serviços do app.

### 22. Arquivos grandes

| Arquivo | Linhas | Passo |
|---|---|---|
| `lib/main.dart` (`_ScoreHomePageState` ~1780) | 2007 | R29, R30 |
| `lib/app/library_screen.dart` | 2115 | R31 |
| `lib/app/general_settings_panel.dart` | 758 | R32 *(núcleo)* |

### 23. Lints

`analysis_options.yaml` só inclui `flutter_lints`. Medido em 17/10 com
`strict-casts`, `strict-inference`, `strict-raw-types`,
`unawaited_futures`, `discarded_futures`, `avoid_dynamic_calls` e
`prefer_final_locals` no `lib/`: **27 achados** (20 `discarded_futures`,
3 erros de `dynamic`, 2 `avoid_dynamic_calls`, 1 `strict_raw_type`, 1
`unawaited_futures`). Os pacotes têm `analysis_options.yaml` próprio e não
foram medidos.

### 24. Dependências e `pubspec.yaml`

35 pacotes têm versão nova fora das restrições; entre os diretos,
`google_fonts` 9, `flutter_midi_command` 1.4, `package_info_plus`,
`shared_preferences` e `wakelock_plus`. O `pubspec.yaml` ainda tem
`description: "A new Flutter project."` e os comentários do modelo.

### 25. Navegação sem rotas

25 `Navigator.push` com `MaterialPageRoute`. Na versão Web não há URL por
tela, e o voltar do navegador não segue as telas. Abrir `.zywny` pelo
sistema (B11) teria um caminho natural com rotas.

**Como resolver:** decisão D-REV-ROTAS (`go_router` ou ficar como está).

## Bibliotecas

| Biblioteca | Para quê | Recomendação |
|---|---|---|
| `provider` | Expor os serviços (achado 20); o código já é todo `ChangeNotifier` | Sim, no R27 (D-REV-DI) |
| `go_router` | Rotas, URL na Web, abrir pelo sistema | Depois do R27 e do R31 (D-REV-ROTAS) |
| Lints estritos (sem pacote novo) | Achado 23 | Sim, no zywny-comum |
| `freezed` + `json_serializable` | 12 `fromJson` e 14 `operator ==` à mão | Não agora: geração de código num projeto que não a usa custa mais que os 26 métodos |
| `drift` | Progresso em SQLite | Não agora: o volume cabe no `shared_preferences`; rever se o progresso crescer |
| Riverpod ou Bloc | Gerência de estado | Não: troca de paradigma sem ganho sobre `ChangeNotifier` + `provider` |

## Passos, na ordem de implementação

Os passos que ficaram neste repositório:

| Passo | O que faz | Achado | Depende de | Decisão |
|-------|-----------|--------|------------|---------|
| [R19](../plano/R19-ler-sem-apagar.md) | Ilegível ≠ ausente nos quatro stores | 12 | — | — |
| [R20](../plano/R20-nota-da-simplificada.md) | Nota da simplificada na lista | 13 | — | D-REV-SIMPL |
| [R21](../plano/R21-mensagens-de-problema.md) | Helper de mensagem; redação única | 14 | — | — |
| [R22](../plano/R22-dialogos-de-confirmacao.md) | `confirmAction` com destrutivo | 15 | — | — |
| [R26](../plano/R26-cabecalhos-das-telas.md) | Um cabeçalho para as telas secundárias | 19 | — | D-REV-CABEC |
| [R27](../plano/R27-servicos-do-app.md) | Serviços criados no `main()`, por escopo | 20 | R19 | D-REV-DI |
| [R28](../plano/R28-um-motor-de-som.md) | Um `SoundOutputController` para o app | 21 | R27 | — |
| [R29](../plano/R29-partitura-e-transposicao.md) | Partitura em `lib/score/`; fluxo de transposição | 22 | R28 | — |
| [R30](../plano/R30-partitura-em-widgets.md) | Zoom, gaveta, barra e corpo em widgets | 22 | R29 | — |
| [R31](../plano/R31-biblioteca-em-arquivos.md) | Biblioteca em arquivos menores | 22 | R28 | — |
| [R34](../plano/R34-dependencias-e-pubspec.md) | Dependências em dia; `pubspec.yaml` limpo | 24 | — | — |
| [R35](../plano/R35-rotas.md) | Rotas com `go_router` | 25 | R27, R31 | D-REV-ROTAS |

R18, R23 e R32 foram para o [zywny-aprendizado](https://github.com/mkanada/zywny-aprendizado/tree/main/docs/plano)
(app de cursos); R24, R25 e R33 eram do núcleo compartilhado e saíram daqui
com o [zywny-comum](https://github.com/mkanada/zywny-comum).

Por que esta ordem: os bugs (R19) vêm primeiro porque perdem dados ou
impedem o uso. Os passos de UX pequenos (R21, R22) não dependem da
arquitetura e dão resultado visível logo. Os serviços (R27) vêm antes de
qualquer divisão de arquivo porque mudam as mesmas linhas de
`library_screen.dart` e `main.dart`; o motor único (R28) depende deles. As
rotas ficam por último: mexem em todas as telas e só valem a pena com os
serviços já fora da biblioteca.

R19, R21 e R22 não dependem de nada e podem ser adiantados.
