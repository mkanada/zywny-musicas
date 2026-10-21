# D05 — Publicação no Google Play (AAB, chave de release e upload pela API)

**Repo:** zywny-musicas · **Depende de:** D03 · **Decisão necessária:** nenhuma

**Status (2026-10-20): o primeiro build subiu na faixa `internal` (versionCode 4, depois 5 com a correção das ABIs). A política de privacidade existe e está publicada (item 2). Falta o que só o console faz: os questionários e o teste fechado.**

## Objetivo

Publicar o app das músicas (`br.com.kanada.zywny.musicas`) no Google Play:
assinar com uma chave de release de verdade, gerar o **Pacote de apps**
(`.aab`) e subí-lo sem precisar do console — a Play Developer API faz o
upload. O app dos cursos (`br.com.kanada.zywny.aprendizado`) é **outro app**,
com a sua própria ficha e a sua própria chave.

## Ler antes (só isto)

- [D03 — Projeto Firebase e configuração nas 4 plataformas](D03-configuracao-firebase-e-android-web.md).
- A seção "Publicação no Google Play" do `README.md` (o passo a passo curto).
- `android/app/build.gradle.kts`.

## O que é o "upload de pacotes"

No Play Console, cada versão publicada tem um artefato: o **Pacote de apps
Android** (`.aab`). O Google **não** recebe o seu APK — recebe o AAB e gera
os APKs por aparelho, idioma e densidade de tela. Desde 2021 o AAB é
obrigatório em app novo; APK serve para sideload (é o `just build-apk`).

## Chave de release

O AAB é assinado com a **upload key**; o Google reassina o app com a *app
signing key* dele (Assinatura de apps do Google Play). Trocar a upload key
depois exige pedido formal ao Google — então ela nasce agora, certa.

Fica em `keys/` (fora do git, como as chaves das bibliotecas):

| Arquivo | O que é |
| --- | --- |
| `zywny-upload.jks` | o keystore, alias `upload` |
| `android-release.properties` | o caminho do keystore e as senhas |

O `build.gradle.kts` lê esse arquivo; **sem ele, o build cai na chave de
debug** (o comportamento antigo, para o `flutter run --release` continuar
funcionando em quem não tem a chave) — e esse build não sobe na loja.

**Guarde cópia do `.jks` e das senhas fora da máquina.** A senha da upload key
que a perdeu precisa de processo no Google, não é como a de debug, que se
regera em segundos.

## O upload pela API

A Play Developer API (`androidpublisher`) faz o mesmo que o console:

| Passo | Chamada |
| --- | --- |
| abre uma edição | `POST /androidpublisher/v3/applications/{pkg}/edits` |
| sobe o `.aab` | `POST .../edits/{editId}/bundles` (upload resumível) |
| joga na faixa | `PUT .../edits/{editId}/tracks/{faixa}` |
| aplica | `POST .../edits/{editId}:commit` |

`tool/play_upload.py` faz isso (`just play-upload`); `--check` só testa o
acesso, `--list` mostra o que está publicado, `--aplicar EDIT_ID` fecha uma
edição que ficou pela metade.

### A identidade

Uma **service account** do Google Cloud (a JSON em `keys/`), sem nenhum papel
de IAM — a permissão toda vem do Play Console: *Usuários e permissões →
Convidar novos usuários*, com o `client_email` do JSON e a permissão **"Liberar
apps para as faixas de teste"** no app. O menu "Acesso à API" que existia
antes não existe mais, e a conta de desenvolvedor não precisa mais estar
vinculada a um projeto do Google Cloud.

Os erros distinguem as duas portas: **401** = a credencial está errada (chave, escopo,
API não ativada antes de criar a chave) — o convite não entra nessa conta;
**403** = a service account não tem permissão no app (faltou o convite, faltou
marcar a permissão, ou a conta de desenvolvedor é outra). A permissão pode
levar horas para valer depois do convite.

### O protocolo do upload resumível

A API não é a do `google-api-python-client` e a documentação de descoberta
erra em dois pontos. O que a API aceita de verdade:

- **O destino do upload vem em `X-Goog-Upload-URL`**, não em `Location` (o
  `Location` da documentação).
- **O corpo de `tracks.update` é a faixa com a lista de releases**
  (`{"releases": [{"versionCodes": [...], "status": ...}]}`), não o release
  solto — o documento de descoberta promete o release solto e a API recusa com
  `Unknown name "versionCodes"`.
- O upload é **em blocos**: o servidor pede `X-Goog-Upload-Command: upload` e
  `X-Goog-Upload-Offset` em cada `PUT`, e derruba a conexão se o arquivo
  inteiro vai num `PUT` só (o AAB do zywny tem 84 MB). O último bloco leva
  `X-Goog-Upload-Command: upload, finalize` e é o que volta com o bundle.

## O que a API não faz

- **Os questionários do console**: política de privacidade, Segurança dos
  dados, público-alvo e conteúdo, classificação de conteúdo, anúncios. Não
  têm API.
- **A revisão**: subir em produção não pula a revisão. E um app novo não vai
  direto à produção — precisa de um teste fechado com 12 testadores
  inscritos, mantidos por 14 dias.
- **O acesso ao app**: o zywny abre com portão de conta, então o revisor
  precisa de um caminho para entrar (uma conta de teste e as instruções na
  seção "Acesso ao app").

## Notas de execução (2026-10-20)

### O que ficou pronto (código)

- `keys/zywny-upload.jks` + `keys/android-release.properties` (fora do git),
  e o `signingConfigs { create("upload") }` no `build.gradle.kts`, com
  fallback para a chave de debug.
- `just build-appbundle` (o `justfile` não tinha receita de AAB) e
  `just play-upload` / `just play-check`.
- `tool/play_upload.py`: o upload pela API, com o protocolo de blocos.
- A seção "Publicação no Google Play" do `README.md`.

### Desvios do plano

1. **O `applicationId` é `br.com.kanada.zywny.musicas`** (do D03) e é o
   pacote que o Play Console pede.
2. **O build do Android precisa de JDK 17+.** O AGP 9 recusa o Java 11, que
   é o `current` do `sdkman` desta máquina; o build roda com o 21
   (`JAVA_HOME=~/.sdkman/candidates/java/21.0.7-tem`).
3. **O AAB saiu com `armeabi-v7a` sem as nativas do projeto.** O Flutter
   embute o motor em 32 bits, mas `libverovio.so` e `libzywny_audio.so` só
   existem para `arm64-v8a` e `x86_64` (`just native-android` e
   `just native-audio-android`). Um celular de 32 bits instalaria um app que
   quebra ao abrir a partitura. Foram dois ajustes, porque cada um sozinho
   não bastou:
   - o `ndk { abiFilters }` no `build.gradle.kts` **não** resolve — quem
     empacota as `.so` do motor é o plugin do Flutter, que respeita o
     `--target-platform` do `flutter build`; a receita `build-appbundle`
     passou `--target-platform android-arm64,android-x64`;
   - e mesmo assim plugins que trazem `.so` de 32 bits (o `jni` e o
     `datastore`) deixavam uma pasta `armeabi-v7a` no pacote, **sem** a
     engine e sem o código Dart: o Play geraria um APK de 32 bits que não
     abre. Saiu com `packaging { jniLibs { excludes += "**/armeabi-v7a/**" } }`.

   Como o `versionCode` 4 já estava publicado na faixa `internal`, a correção
   saiu como **5** (`pubspec.yaml`: `1.0.4+5`).

### O que falta (precisa do login do usuário no console)

1. **Os questionários**: Segurança dos dados, público-alvo e conteúdo,
   classificação de conteúdo, anúncios, e o "Acesso ao app" (o app tem portão
   de conta). A URL da política de privacidade é a do item 2.
2. **A política de privacidade** existe desde 2026-10-20: `web/privacidade.html`
   no repositório, publicada no GitHub Pages em
   <https://mkanada.github.io/zywny-musicas/privacidade.html> (o `just
   publicar-web` copia a página para o site). O `D00` pede o documento por
   causa da LGPD. O e-mail de contato é `zywny.app@gmail.com`.
3. **O Firebase**: `keys/firebase.json` ainda não existe (o `D03` espera a
   criação do projeto no console). Sem ele, o AAB sai com o app **abrindo sem
   o portão da conta** — o `AuthGate` só fecha se houver `authStore`.
4. **O teste fechado** (12 testadores, 14 dias) antes de pedir a produção.
5. **O `play billing`**: o `D00` decidiu que a assinatura é pela Play Store,
   mas não há integração no app (nenhum `in_app_purchase` no `lib/`). Se a
   primeira versão vender conteúdo digital, isso é bloqueante.

## Arquivos

| Arquivo (repo) | O que é |
| --- | --- |
| `android/app/build.gradle.kts` | a `signingConfigs` de release e o `abiFilters` |
| `justfile` | `build-appbundle` (com o `--target-platform`), `play-upload`, `play-check` |
| `tool/play_upload.py` | o upload pela Play Developer API |
| `README.md` | o passo a passo curto e os avisos |
| `pubspec.yaml` | a `version`, de onde sai o `versionCode` |
