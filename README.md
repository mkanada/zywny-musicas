# zywny-musicas

App Flutter de treino musical no teclado MIDI. Não traz música nenhuma: as
músicas chegam em **bibliotecas** (`.zywny`, cifradas e assinadas) que se
instalam por arquivo, e uma delas fica em uso. A partitura é gerada em runtime
no formato `.vsb` (*Verovio Score Bridge*), via FFI, e desenhada com
`CustomPaint`.

Este é o repositório do **zywny-musicas** (a pasta local continua `zywny`). Ele
faz parte de uma divisão em três:

- **zywny-musicas** (este) — bibliotecas de músicas, partitura, treino (trilha,
  decorar, transpor, letra, revisão), tutorial e a tela da biblioteca.
- **zywny-aprendizado** — o app de cursos e lições, exercícios de ouvido, leitura
  à vista e exercícios de acordes. Instala só cursos (`course.md`).
- **zywny-comum** — o núcleo que os dois usam: o pacote `zywny_comum` (tela
  Sobre, configurações, tema, MIDI, som, motor de prática e de trilha, Verovio),
  os pacotes `packages/*` (`zywny_music`, `zywny_audio`, `zywny_midi`,
  `zywny_library`, `zywny_diag`, `zywny_course_format`), `score_bridge/` e a
  biblioteca nativa de som (`native/`).

Cada app instala só o seu tipo de pacote: este instala bibliotecas e, se
receber um curso, diz que ele se abre no zywny-aprendizado.

## Repositórios vizinhos

O `pubspec.yaml`, o `linux/CMakeLists.txt` e as receitas do `justfile` procuram
checkouts **ao lado** deste repositório (um symlink basta):

```
../zywny-comum              # obrigatório: o núcleo compartilhado
../verovio_flutter_bridge   # obrigatório: o pacote `verovio` e a libverovio.so
../Hymn_Grabber             # opcional: só para o pacote de hinos (uso privado)
```

`ZYWNY_COMUM` (no `justfile`) e `VEROVIO_BRIDGE` (nos scripts) sobrescrevem os
caminhos. Os scripts que compilam as bibliotecas nativas moram no zywny-comum e
escrevem o resultado na pasta deste app.

## Como rodar

Com [`just`](https://just.systems) (`just` sozinho lista as receitas):

```sh
just setup          # libverovio.so + assets/verovio_data.zip + pub get
just chaves         # par de chaves das bibliotecas em keys/ (uma vez; fora do git)
just pacote-hinos   # dist/hinos.zywny, a partir do Hymn_Grabber (uso privado)
just run            # flutter run -d linux --no-enable-impeller
just test           # testes deste app
just test-comum     # testes do zywny-comum e de packages/
just analyze        # flutter analyze deste app (analyze-comum, do comum)
```

O `--no-enable-impeller` não é preferência: o backend Impeller no Linux não
resolve o MSAA e serrilha todo o vetorial — [flutter#191171][aa], corrigido no
master por [flutter#191379][aafix] (23/08/2026), ainda fora do stable 3.47.4.
Numa partitura, que é path fino, o resultado é grosseiro. Quando o fix descer
para o stable, comparar com `just run-impeller` e largar a flag.

[aa]: https://github.com/flutter/flutter/issues/191171
[aafix]: https://github.com/flutter/flutter/pull/191379

Sem `just`, na mão (a partir da raiz deste repositório):

```sh
../zywny-comum/tool/build_verovio_linux.sh    # compila e strippa a libverovio.so
../zywny-comum/tool/build_verovio_assets.sh   # gera assets/verovio_data.zip
python3 ../zywny-comum/tool/library_crypto.py gen keys
tool/build_hymn_assets.py                     # gera dist/hinos.zywny (cifrado e assinado)
flutter pub get
flutter run -d linux --no-enable-impeller
```

## Artefatos gerados (não versionados)

- `../verovio_flutter_bridge/verovio/bindings/dart/libverovio.so` —
  `linux/CMakeLists.txt` a instala em `lib/` do bundle (RPATH `$ORIGIN/lib`).
- `../zywny-comum/native/zywny_audio/target/release/libzywny_audio.so` — o motor
  de som; o CMake a instala no bundle Linux.
- `assets/verovio_data.zip` — as fontes de gravação (`verovio/data`) num zip
  único, extraído na primeira execução por `render/verovio_resources.dart` (no
  zywny-comum). Zip porque o bundler de assets do Flutter não recursa em
  diretórios.
- `keys/` — o par de chaves das bibliotecas (Ed25519). A **privada** gera
  (assina e cifra) os pacotes e só existe com quem os gera; a **pública** é
  embutida no app (`--dart-define=ZYWNY_LIBRARY_KEY`, que as receitas leem
  daqui). Fica fora do git e **nunca vai ao repositório remoto**; guarde cópia
  da privada — sem ela nenhum app instalado aceita pacote novo. Sem a pública o
  app compila, mas recusa instalar biblioteca.
- `dist/hinos.zywny` — a biblioteca de hinos (`just pacote-hinos`), gerada a
  partir de `../Hymn_Grabber`. Fica fora do git porque as partituras têm
  direitos de terceiros: o arquivo passa de mão em mão e o app nunca diz de onde
  baixar.

Rode os scripts do zywny-comum de novo sempre que o `verovio_flutter_bridge`
andar, e `just pacote-hinos` quando o extrator do Hymn_Grabber mudar.

## Configurações

Dois painéis, duas gavetas de dados — ambas em `SharedPreferencesAsync`, que
sobrevive a fechar o app e a instalar uma versão nova por cima:

- **Gerais** (`AppSettings`, no zywny-comum; painel `GeneralSettingsPanel`):
  som, saída, instrumentos da partitura, metrônomo, tipo de treino e cores.
  Valem para todas as músicas; abrem pela engrenagem da biblioteca ou por
  "Configurações gerais" na partitura.
- **Layout da partitura** (painel `LayoutPanel`, no zywny-comum): tamanho da
  notação, página e demais opções do Verovio. Guarda-se só o que a pessoa mudou.
- **De cada música** (`PieceSettings`, no zywny-comum): andamento, mão, trilha e
  tom, numa chave `piece_settings_<biblioteca>_<id>`. Só o que saiu do padrão é
  gravado.

## Tutorial e "Sobre"

A seção **Ajuda** das configurações gerais tem "Sobre o Zywny" (tela no
zywny-comum, `about/`) e "Rever o tutorial". O tutorial deste app (`lib/tutorial/`)
é um passeio que escurece a tela e recorta cada botão: um pela biblioteca e
outro pela partitura, cada um na primeira vez. Detalhes em
[`docs/plano/U20-sobre-e-tutorial.md`](docs/plano/U20-sobre-e-tutorial.md).

## Estrutura deste repositório

- `lib/main.dart` — entrada do app, `MyApp` e a tela da partitura (`ScoreHomePage`).
- `lib/app/` — a tela da biblioteca (`library_screen.dart`), o instalador de
  bibliotecas (`package_install.dart`) e os controladores da partitura e do
  treino (`playback_controller.dart`, `score_render_session.dart`,
  `sound_output_controller.dart`, `trail_runner.dart`).
- `lib/tutorial/` — os passeios de primeiro uso.
- `apps/zywny_mockup/` — protótipo navegável da interface (não é o app).
- `test/`, `integration_test/` — testes da biblioteca, passeios, hinos e o
  roteiro de fotos das telas (`just telas`).
- `web/`, `android/`, `linux/`, `windows/` — as plataformas.
- `docs/` — planos por fase e registros de decisão.

Para o núcleo, veja o `README.md` do zywny-comum.
