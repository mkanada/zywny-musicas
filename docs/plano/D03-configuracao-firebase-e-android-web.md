# D03 — Projeto Firebase (plano Spark) e configuração nas 4 plataformas

**Repo:** zywny-musicas + zywny-aprendizado · **Depende de:** D01, D02 · **Decisão necessária:** resolvida (2026-10-19): o `applicationId` do Android é `br.com.kanada.zywny.musicas` (app das músicas) e `br.com.kanada.zywny.aprendizado` (app dos cursos)

**Status (2026-10-19): o código está pronto; falta criar o projeto no console do Firebase** (isso exige o login do usuário) e o aceite manual do login nas 4 plataformas. Ver "Notas de execução" no fim.

## Objetivo

Configurar o projeto no **Google Firebase** dentro do **plano gratuito (Spark)**, definir o `applicationId` definitivo no Android, registrar os aplicativos Android e Web via `flutterfire configure` e configurar as credenciais OAuth2 para login social nas 4 plataformas (Android, Web, Linux e Windows).

## Ler antes (só isto)

- [D00 — Papéis, distribuição de conteúdo e modelo de negócios](D00-papeis-e-distribuicao.md).
- [D01 — Pacote `zywny_auth` no `zywny-comum`](D01-pacote-zywny-auth.md).
- `android/app/build.gradle.kts`.

## Contexto que você precisa

- **Um único projeto Firebase para todo o ecossistema Zywny:**
  - Tanto o `zywny-musicas` quanto o `zywny-aprendizado` (e o futuro painel Web do tutor) apontam para o **mesmo projeto Firebase**. Assim, o aluno e o tutor têm **uma única conta (`uid`)** em todos os apps.
  - No plano **Spark ($0, sem cartão)**:
    - **Authentication:** até 50.000 MAU gratuitos em provedores sociais (Google, Apple, Microsoft, GitHub, etc.).
    - **Cloud Firestore:** 1 GiB guardado, 50.000 leituras/dia, 20.000 escritas/dia, 20.000 exclusões/dia gratuitos.
- **`applicationId` no Android (`android/app/build.gradle.kts`):**
  - Hoje está com o placeholder `com.example.zywny` (linhas 8 e 19).
  - Precisa mudar para o identificador definitivo (ex.: `com.zywny.musicas` aqui e `com.zywny.aprendizado` no outro app) **antes** de registrar o app no Firebase, pois o `google-services.json` e o OAuth Client ID do Android exigem o `applicationId` + o hash **SHA-1** da chave de assinatura.
- **Como o Login com Google é configurado para cada plataforma no mesmo projeto Firebase / Google Cloud Console:**
  1. **Web:** criado automaticamente ao ativar o provedor Google no Firebase Console (*Authentication > Sign-in method > Google*).
  2. **Android:** criado automaticamente pelo Firebase quando se cadastra o app Android com o `applicationId` e os certificados **SHA-1** (de debug e de release).
  3. **Linux e Windows (Desktop):** em *Google Cloud Console > APIs & Services > Credentials* (do mesmo projeto Firebase), cria-se um **OAuth 2.0 Client ID** do tipo **Web application** (ou Desktop) com URI de redirecionamento autorizado `http://127.0.0.1` (loopback) e adiciona-se esse Client ID na lista de IDs permitidos do provedor Google no Firebase Auth.
- **O que o [D01](D01-pacote-zywny-auth.md) mediu (2026-10-19), para não errar o console:**
  - **O tipo do cliente OAuth do desktop decide como o loopback funciona.** O
    `LoopbackOAuthFlow` do `zywny_auth` sobe o servidor local em `127.0.0.1`
    numa **porta livre** (`port: 0`): o cliente do tipo **"Desktop"** do Google
    aceita qualquer porta do loopback e não tem segredo; o do tipo **"Web
    application"** exige o endereço **exato** registrado (com a porta) **e**
    `client_secret` na troca do código. Para o "Web application", o app tem
    de passar `port:` e `clientSecret:` ao `FirebaseRestAuthStore`; para o
    "Desktop", só o `clientId`.
  - **`firebase_auth` 7.0.0 na Web não tem `signInWithProvider`**: o
    `FirebaseSdkAuthStore` usa `signInWithPopup(GoogleAuthProvider())` lá (o
    popup do [D00](D00-papeis-e-distribuicao.md)) e o `google_sign_in` no
    Android.
  - **`google_sign_in` 7.x**: `GoogleSignIn.instance.initialize()` e depois
    `authenticate()` (o `signIn()` não existe mais). No Android o `clientId`
    **não** é aceito — o app é identificado pelo `applicationId` + SHA-1, e o
    `server_client_id` sai do `google-services.json`.
  - **O `FirebaseSdkAuthStore` espera o `Firebase.initializeApp` feito** (o
    passo 4 deste arquivo): se o `main` não inicializou, o login falha com
    "O Firebase não foi inicializado neste app".
- **O que o [D02](D02-tela-de-login-e-auth-gate.md) entregou (2026-10-19):**
  - O `MyApp` dos dois apps já aceita `authStore` (e `requireNickname`): o
    passo 4 deste arquivo é criar o store e passá-lo, com
    `requireNickname: true` (no primeiro acesso o app pergunta o apelido).
  - Sem `authStore`, o app abre direto — é assim que os testes e o roteiro
    `just telas` rodam (ninguém tem Firebase configurado).
  - A seção "Conta" das configurações (apelido, e-mail, código do aluno,
    sair e apagar a conta) já existe e acompanha o store.

## O que fazer

1. Trocar `com.example.zywny` pelo `applicationId` definitivo em `android/app/build.gradle.kts` (e nos arquivos Kotlin/manifest correspondentes).
2. No Console do Firebase (plano **Spark**):
   - Criar o projeto (ex.: `zywny-prod`), sem ativar cobrança por SMS.
   - Em *Authentication > Sign-in method*, habilitar **Google** (e demais redes sociais desejadas) e configurar o e-mail de suporte e nome público do projeto.
3. Rodar `flutterfire configure` gerando `lib/firebase_options.dart` e `android/app/google-services.json`.
4. Configurar a inicialização no `main()` de `lib/main.dart`:
   - Em Android e Web: `await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` e `FirebaseSdkAuthStore()`.
   - Em Linux e Windows: `FirebaseRestAuthStore(apiKey: ..., googleClientId: ...)`.
5. Documentar no `README.md` os comandos para obter o SHA-1 de debug (`keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore`) para que qualquer máquina de desenvolvimento possa autenticar no emulador/aparelho Android.

> **Como foi feito (2026-10-19):** os passos 1, 4 e 5 estão prontos; os 2 e 3
> dependem do login do usuário no console do Firebase. O passo 3 mudou de
> forma: a configuração não vem do `flutterfire configure` e sim de
> `keys/firebase.json` por `--dart-define` (o motivo está em "Notas de
> execução", abaixo).

## Fora de escopo

- Regras de banco de dados de relatórios e MIDI (entram nos passos seguintes da fase D).

## Critérios de aceite

1. Login com conta Google funcionando de ponta a ponta no **Linux** (abre navegador, autentica e volta para a biblioteca do `zywny-musicas`).
2. Login com conta Google funcionando no **Android** e na **Web**.
3. Fechar e reabrir o app mantém o usuário logado sem pedir login de novo (e continua abrindo em modo avião dentro da janela de 7 dias).
4. `just analyze` e `just test` verdes.

**Status (2026-10-19): o critério 4 passou; os 1–3 dependem do projeto no console** (o usuário cria o projeto, preenche `keys/firebase.json` e o aceite é manual). Ver "Notas de execução".

## Notas de execução (2026-10-19)

### O que ficou pronto (código)

- O `applicationId` definitivo do Android, nos dois apps:
  `br.com.kanada.zywny.musicas` (músicas) e `br.com.kanada.zywny.aprendizado`
  (cursos) — em `android/app/build.gradle.kts` (`namespace` e
  `applicationId`) e no `MainActivity.kt`, que mudou de pasta.
- A configuração do projeto no Firebase e a escolha do caminho de login de
  cada plataforma, no pacote compartilhado `zywny_auth` (zywny-comum).
- O `main()` dos dois apps cria o store da plataforma e o passa ao `MyApp`
  (com `requireNickname: true`).
- A configuração sai de `keys/firebase.json` (fora do git) e entra no build
  por `--dart-define`; o `justfile` de cada app monta as flags.
- O `README.md` de cada app traz o passo a passo do console e o comando do
  SHA-1.

### Desvios do plano

1. **A configuração não vem do `flutterfire configure`.** O plano pedia
   `lib/firebase_options.dart` e `android/app/google-services.json`
   versionados. Aqui a configuração fica **fora do git**, em
   `keys/firebase.json` (como as chaves das bibliotecas), e entra por
   `--dart-define`; o app monta o `FirebaseOptions` na mão
   (`packages/zywny_auth/lib/firebase_config.dart`). Motivos:
   - o repositório já tem a regra de "chave fora do git" (`keys/`, com
     `--dart-define`), e a configuração do Firebase é do mesmo tipo;
   - sem o arquivo, o app **compila** e abre direto (testes, `just telas`),
     em vez de quebrar a build de quem não tem o projeto;
   - as `FirebaseOptions` explícitas dispensam o plugin Gradle
     `com.google.gms.google-services` (e o `google-services.json`): o
     `server_client_id` do Android, que vinha de lá, é uma flag
     (`ZYWNY_GOOGLE_SERVER_CLIENT_ID`).
   O `firebase_options.dart` do FlutterFire **não** é gerado: se alguém rodar
   `flutterfire configure`, o arquivo sai sem uso (o app lê o
   `firebase_config.dart`).
2. **Sem a configuração, o app abre sem o portão da conta.** O `D02` já
   deixava anotado que "sem `authStore`, o app abre direto"; agora é a
   própria configuração que decide: com o projeto configurado, o portão fecha
   e o login vira obrigatório (`D-NEG-SEM-CONTA`); sem ele, o app abre
   direto — é assim que os testes e o roteiro `just telas` continuam
   funcionando.
3. **`ZYWNY_AUTH_OFF=true` desliga o portão.** O roteiro `just telas` percorre
   o app de verdade: com a configuração no build, ele pararia na tela de
   entrada. A flag desliga o portão só nesse roteiro (e em depuração) —
   **nunca** em release.
4. **O `applicationId` é `br.com.kanada.zywny.musicas`** (decidido pelo
   usuário em 2026-10-19), e não `com.zywny.musicas` como o plano exemplificava.
5. **O código compartilhado foi para o `zywny_auth`** (zywny-comum), e não
   para cada app: os dois apps (músicas e cursos) usam a mesma conta, e a
   configuração do projeto é a mesma.

### Arquivos

| Arquivo (repo) | O que é |
| --- | --- |
| `zywny-comum/packages/zywny_auth/lib/firebase_config.dart` | a configuração do projeto (vinda das flags), o que falta para cada plataforma e as opções do SDK |
| `zywny-comum/packages/zywny_auth/lib/auth_bootstrap.dart` | a plataforma em que o app roda, o caminho do login (SDK ou REST) e a criação do store |
| `zywny-comum/packages/zywny_auth/test/firebase_config_test.dart` | os testes da configuração e da escolha do caminho (7 testes) |
| `zywny-comum/tool/firebase_defines.py` | lê `keys/firebase.json` e imprime as flags `--dart-define` (`--check` diz o que falta) |
| `zywny-comum/tool/firebase.example.json` | o modelo do `keys/firebase.json` |
| `zywny-musicas/lib/main.dart` | o `main()` cria o store e o passa ao `MyApp` |
| `zywny-musicas/android/app/build.gradle.kts` e `.../kotlin/br/com/kanada/zywny/musicas/MainActivity.kt` | o `applicationId` definitivo |
| `zywny-musicas/justfile` | `firebase_opts` nas receitas de build, `firebase_off` no `just telas` e a receita `firebase-check` |
| `zywny-musicas/README.md` | o passo a passo do console e o SHA-1 |
| `zywny-aprendizado/` | o mesmo nos quatro arquivos correspondentes |

### O que falta (precisa do login do usuário no console)

1. Criar o projeto no console do Firebase, no plano **Spark** (sem cartão):
   <https://console.firebase.google.com/> — um projeto só para o ecossistema
   Zywny (o app das músicas, o dos cursos e o painel do tutor apontam para
   o mesmo).
2. Em *Authentication > Sign-in method*, habilitar **Google** e anotar o
   e-mail de suporte e o nome público do projeto.
3. Registrar os apps:
   - **Android das músicas**: `br.com.kanada.zywny.musicas`, com o SHA-1 de
     debug **e** de release;
   - **Android dos cursos**: `br.com.kanada.zywny.aprendizado`, com os
     mesmos SHA-1;
   - **Web**: o app do zywny-musicas (o do zywny-aprendizado pode vir
     depois).
4. No *Google Cloud Console > APIs & Services > Credentials* (do mesmo
   projeto): um **OAuth 2.0 Client ID do tipo "Desktop"** (o do login pelo
   navegador do sistema, no Linux e no Windows — ele aceita qualquer porta do
   loopback e não tem segredo) e o **OAuth do tipo "Web" do app Android**
   (o `server_client_id`, que vai no `google-services.json` do app).
   Adicionar os dois na lista de IDs permitidos do provedor Google.
5. Preencher `keys/firebase.json` (modelo em
   `../zywny-comum/tool/firebase.example.json`) e conferir com
   `just firebase-check`.
6. Rodar o app (`just run` no Linux, `just run-android`, `just build-web`) e
   conferir o login.

O SHA-1 de debug (o mesmo em todas as máquinas de desenvolvimento):

```sh
keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore
```

(a senha é `android`).

### Números medidos

- `zywny_auth`: **32 testes** (25 do D01 + 7 do D03), verdes.
- `just analyze` do zywny-comum: limpo.
- `just analyze` + `just test` do zywny-musicas: 271 testes, verdes.
- `just analyze` + `just test` do zywny-aprendizado: 508 testes, verdes.

### Fora de escopo, como o plano previa

O login **de verdade** (o critério 1–3) só pode ser conferido com o projeto
no console; o código do portão e do store já está, e o `FakeAuthStore`
continua cobrindo os testes.
