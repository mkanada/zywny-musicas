# D03 — Projeto Firebase (plano Spark) e configuração nas 4 plataformas

**Repo:** zywny-musicas + zywny-aprendizado · **Depende de:** D01, D02 · **Decisão necessária:** confirmar o `applicationId` definitivo do Android (ex.: `com.zywny.musicas` e `com.zywny.aprendizado`)

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

## Fora de escopo

- Regras de banco de dados de relatórios e MIDI (entram nos passos seguintes da fase D).

## Critérios de aceite

1. Login com conta Google funcionando de ponta a ponta no **Linux** (abre navegador, autentica e volta para a biblioteca do `zywny-musicas`).
2. Login com conta Google funcionando no **Android** e na **Web**.
3. Fechar e reabrir o app mantém o usuário logado sem pedir login de novo (e continua abrindo em modo avião dentro da janela de 7 dias).
4. `just analyze` e `just test` verdes.
