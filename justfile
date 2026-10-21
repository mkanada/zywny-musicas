# zywny — tarefas do projeto (https://just.systems)
#
#   just            lista as receitas
#   just setup      libverovio.so + assets + pub get
#   just run        roda no Linux, sem Impeller
#
# Por que sem Impeller: o backend do Flutter no Linux não resolve o MSAA,
# então tudo que é vetorial sai serrilhado — flutter/flutter#191171,
# corrigido no master por flutter/flutter#191379 (23/08/2026), ainda fora
# do stable 3.47.4. Numa partitura, que é só path fino, o efeito é
# grosseiro. Quando o fix chegar ao stable, comparar com
# `just run-impeller` e apagar a flag daqui.

linux_bundle := "build/linux/x64/release/bundle/zywny"

# O núcleo compartilhado (pacotes, partitura, som, MIDI, Verovio e os scripts
# de build que compilam as bibliotecas nativas) mora no zywny-comum. Padrão:
# a pasta ao lado deste repositório; `ZYWNY_COMUM=<pasta> just ...` troca.
comum := env_var_or_default("ZYWNY_COMUM", "../zywny-comum")

# Chave pública das bibliotecas (D-BIB-CIFRA), lida de keys/ — fora do git —
# e embutida no app. Sem o arquivo, o app compila mas não instala biblioteca.
lib_key := "--dart-define=ZYWNY_LIBRARY_KEY=$(cat keys/biblioteca.public.b64 2>/dev/null)"

# Configuração do projeto no Firebase (D03): lida de keys/firebase.json (fora
# do git) e embutida no app por --dart-define. Sem o arquivo, o app compila e
# abre **sem** o portão da conta (é assim que os testes e o roteiro de telas
# rodam). O modelo do arquivo está em ../zywny-comum/tool/firebase.example.json.
firebase_opts := "$(python3 {{comum}}/tool/firebase_defines.py keys/firebase.json 2>/dev/null)"

# O portão da conta desligado: o roteiro de telas percorre o app de verdade e,
# com a configuração do Firebase no build, o app mostraria a tela de entrada.
# Nunca vai para release.
firebase_off := "--dart-define=ZYWNY_AUTH_OFF=true"

# Lista as receitas disponíveis.
default:
    @just --list

# Roda no Linux sem Impeller. Flags extras passam: `just run --release`.
run *ARGS:
    flutter run -d linux --no-enable-impeller {{lib_key}} {{firebase_opts}} {{ARGS}}

# Roda com Impeller (padrão do Flutter) — para reconferir #191171.
run-impeller *ARGS:
    flutter run -d linux {{lib_key}} {{firebase_opts}} {{ARGS}}

# Roda no Linux com o modo de debug do app (ScoreHomePage.debugMode: guarda
# o .vsb renderizado no diretório corrente, com data/hora no nome).
# `flutter run --debug` NÃO repassa isso para `main(args)` — é um flag do
# próprio `flutter run` (build mode, já é o padrão). Por isso precisa do
# --dart-entrypoint-args para chegar no Dart.
run-debug *ARGS:
    flutter run -d linux --no-enable-impeller {{lib_key}} {{firebase_opts}} --dart-entrypoint-args=--debug {{ARGS}}

# Build de release do bundle Linux.
build-release:
    flutter build linux --release {{lib_key}} {{firebase_opts}}

# O `flutter run` passa a flag pelo ambiente (FLUTTER_ENGINE_SWITCHES +
# FLUTTER_ENGINE_SWITCH_N), não por argv, então lançar o binário direto
# pede o mesmo par.
#
# Compila e roda o bundle de release sem Impeller.
run-release: build-release
    FLUTTER_ENGINE_SWITCHES=1 FLUTTER_ENGINE_SWITCH_1=enable-impeller=false ./{{linux_bundle}}

# Mockup de interface (apps/zywny_mockup, membro do workspace — R12): telas
# sem o Verovio, imagens de partitura pré-renderizadas em
# apps/zywny_mockup/assets/. Um app à parte (com.example.zywny_mockup): não
# mexe no app nem entra no APK dele.

# Roda o mockup no Linux, sem Impeller.
run-mockup *ARGS:
    cd apps/zywny_mockup && flutter run -d linux --no-enable-impeller {{ARGS}}

# APK de release do mockup (arm64 só, para instalar direto no celular).
build-mockup-apk:
    cd apps/zywny_mockup && flutter build apk --release --target-platform android-arm64

# Instala o APK de release do mockup no aparelho conectado (via adb).
install-mockup-apk: build-mockup-apk
    cd apps/zywny_mockup && flutter install --release -d android

# Bundle de release do mockup para Linux.
build-mockup-linux:
    cd apps/zywny_mockup && flutter build linux --release

# Regenera apps/zywny_mockup/assets/partitura_*.png (verovio CLI + Chrome
# headless).
mockup-images:
    tool/build_mockup_images.sh

# Preparação completa a partir de um clone limpo.
setup: native assets
    flutter pub get

# Compila a libverovio.so do verovio_flutter_bridge (não versionada).
native:
    {{comum}}/tool/build_verovio_linux.sh

# Gera assets/verovio_data.zip a partir de verovio/data (não versionado).
assets:
    {{comum}}/tool/build_verovio_assets.sh

# Guarde cópia da privada fora do repositório: sem ela, nenhum app instalado
# aceita pacote novo.
# Gera o par de chaves das bibliotecas em keys/ (fora do git; não sobrescreve).
chaves:
    python3 {{comum}}/tool/library_crypto.py gen {{justfile_directory()}}/keys

# Confere a configuração do Firebase (D03): o que falta em keys/firebase.json
# para o login funcionar em cada plataforma. O modelo do arquivo está em
# {{comum}}/tool/firebase.example.json.
firebase-check:
    python3 {{comum}}/tool/firebase_defines.py keys/firebase.json --check

# Uso privado, fora do git; rode de novo quando o extrator de lá mudar.
# Gera dist/hinos.zywny do Hymn_Grabber, cifrado e assinado com keys/ (`just chaves`).
pacote-hinos *ARGS:
    tool/build_hymn_assets.py {{ARGS}}

# Uso privado, fora do git; as partituras vêm de `tool/fetch_classics.py`.
# Gera dist/classicos.zywny (as 43 peças do B09), cifrado e assinado com keys/.
pacote-classicos *ARGS:
    tool/build_classics.py {{ARGS}}

# APK de release (arm64 só, para instalar direto no celular). Rode antes
# `just native-android native-audio-android assets`, ao menos uma vez.
# Sai em build/app/outputs/flutter-apk/app-arm64-v8a-release.apk.
# - `lib_key`: sem a chave o app não abre nenhuma biblioteca (os hinos
#   instalados "somem" até um build com ela).
# - `--split-per-abi`: o versionCode sai 2000 + o do pubspec; o celular já
#   tem um assim e recusa (downgrade) o APK sem split.
build-apk:
    flutter build apk --release {{lib_key}} {{firebase_opts}} --target-platform android-arm64 --split-per-abi

# Instala o APK do `build-apk` no celular conectado pelo adb (Wi-Fi ou cabo),
# mantendo os dados.
instalar-apk:
    ~/Android/Sdk/platform-tools/adb install -r build/app/outputs/flutter-apk/app-arm64-v8a-release.apk

# AAB de release para o Google Play (Android App Bundle). É o que sobe na
# loja: o Play gera os APKs por aparelho a partir dele (APK não é aceito em
# app novo). Sai em build/app/outputs/bundle/release/app-release.aab.
# Mesmas flags do `build-apk`: sem a chave da biblioteca o app não abre
# nenhuma, e sem a do Firebase ele abre sem o portão da conta.
# O `--target-platform` deixa de fora o android-arm (32 bits): o projeto não
# compila a libverovio nem a libzywny_audio para armeabi-v7a, e um celular
# de 32 bits instalaria um app que quebra ao abrir a partitura.
build-appbundle:
    flutter build appbundle --release --target-platform android-arm64,android-x64 {{lib_key}} {{firebase_opts}}

# Sobe o AAB no Google Play pela Play Developer API. Requer a service account
# em keys/ (convite no console: Usuários e permissões → Convidar novos
# usuários, permissão "Liberar apps para as faixas de teste").
# A faixa internal não passa por revisão; produção exige o teste fechado
# (12 testadores, 14 dias) e a ficha da loja completa.
play-upload *ARGS:
    python3 tool/play_upload.py --aab build/app/outputs/bundle/release/app-release.aab {{ARGS}}

# Só testa o acesso da service account à API do Play (não sobe nada).
play-check:
    python3 tool/play_upload.py --check

# Compila a libzywny_audio.so nativa (zywny-comum/native/zywny_audio/, K02;
# não versionada).
native-audio:
    {{comum}}/tool/build_audio_linux.sh

# Compila a libverovio.so para Android (arm64-v8a + x86_64, X01) e instala
# em android/app/src/main/jniLibs/<abi>/ (não versionado).
native-android:
    {{comum}}/tool/build_verovio_android.sh

# Compila a libzywny_audio.so para Android (arm64-v8a + x86_64, K05) e
# instala em android/app/src/main/jniLibs/<abi>/ (não versionado).
native-audio-android:
    {{comum}}/tool/build_audio_android.sh

# Roda o app de verdade (não o mockup) no Android — emulador ou aparelho
# conectado. Rode `just native-android` antes, ao menos uma vez.
run-android *ARGS:
    flutter run -d android {{lib_key}} {{firebase_opts}} {{ARGS}}

# Refotografa as telas do celular em docs/telas/celular/ — roda o app de
# verdade num emulador ou aparelho Android já ligado (o mesmo preparo do
# `build-apk`) e percorre o roteiro de integration_test/telas_celular_test.dart.
# Em profile: sem a faixa "DEBUG" e com o desempenho de uma versão final.
# Emulador sem janela e sem gravar nada no AVD:
#   emulator -avd Medium_Phone_2 -read-only -no-window -no-audio
# O app não traz música: ponha `dist/hinos.zywny` no aparelho (`adb push`) e passe
# `--dart-define=ZYWNY_TEST_LIBRARY=<caminho no aparelho>` em ARGS.
telas *ARGS:
    flutter drive --profile --driver=test_driver/telas_celular.dart \
        --target=integration_test/telas_celular_test.dart -d android {{lib_key}} {{firebase_opts}} {{firebase_off}} {{ARGS}}

# Fotografa a partitura num tablet Android, deitado e em pé (no tablet ela
# segue o aparelho). Emulador: `emulator -avd Medium_Tablet_Edited -read-only
# -no-window -no-audio`; o `.zywny` vai como no `telas`. PNGs em TELAS_DIR.
telas-tablet *ARGS:
    flutter drive --profile --driver=test_driver/telas_celular.dart \
        --target=integration_test/telas_tablet_test.dart -d android {{lib_key}} {{firebase_opts}} {{firebase_off}} {{ARGS}}

# Gera web/audio/ (SpessaSynth empacotado com esbuild, W04; não versionado).
# Precisa de node/npm e rede na primeira vez.
web-audio:
    {{comum}}/tool/build_audio_web.sh

# Compila a versão Web (release). Antes: `{{comum}}/tool/build_verovio_web.sh` e
# `just web-audio`, ao menos uma vez.
build-web:
    flutter build web --release {{lib_key}} {{firebase_opts}}

# Teste de fumaça da Web no Chromium headless (W03/W04) — roda `build-web`.
web-smoke: build-web
    node tool/web_smoke/smoke.mjs

# Publica a versão Web no GitHub Pages (https://mkanada.github.io/zywny-musicas/):
# compila com `--base-href /zywny-musicas/` e troca o branch gh-pages do origin.
publicar-web:
    tool/publish_web.sh

# Refaz .so e assets depois que o verovio_flutter_bridge mudar.
rebuild-deps: native assets

# Teclado MIDI falso no ALSA sequencer (sem hardware; M01), do zywny-comum.
# Sem argumentos toca uma escala em laço; `just fake-midi 60 64 67 --once`,
# `just fake-midi --list`; `just fake-midi --relay` repassa um VMPK ligado por
# aconnect. Monitorar: `aseqdump -p <cliente>:0` (o script imprime a porta).
fake-midi *ARGS:
    {{comum}}/tool/fake_midi_keyboard.py {{ARGS}}

# Testes Dart (headless — não passam pelo Impeller): o app. Os do núcleo
# compartilhado rodam com `just test-comum`.
test:
    flutter test

# Testes do zywny-comum: o pacote e os de packages/ (`dart test` nos de Dart
# puro, `flutter test` nos outros).
test-comum:
    cd {{comum}} && flutter test
    cd {{comum}} && for p in packages/*/; do [ -d "$p/test" ] || continue; if grep -q "sdk: flutter" "$p/pubspec.yaml"; then (cd "$p" && flutter test) || exit 1; else (cd "$p" && dart test) || exit 1; fi; done

# Análise estática: o app, e depois o zywny-comum.
analyze:
    flutter analyze

analyze-comum:
    cd {{comum}} && flutter analyze

# Atualiza o grafo de contexto do graft/ (ver AGENTS.md).
graft:
    graft build
