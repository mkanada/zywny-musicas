# D01 — Pacote `zywny_auth` no `zywny-comum`

**Repo:** zywny-comum · **Depende de:** — · **Decisão necessária:** não (D-NEG-SERVICO, D-NEG-OFFLINE e D-NEG-AUTH decididas no [D00](D00-papeis-e-distribuicao.md))

## Objetivo

Criar o pacote compartilhado `packages/zywny_auth` dentro do `zywny-comum` com o contrato de autenticação (`AuthStore`, `AuthUser`, `AuthState`), a regra de validade offline de 7 dias (`D-NEG-OFFLINE`), o `FakeAuthStore` para os testes dos dois apps e as duas implementações do Firebase Authentication:
1. **Android e Web:** via `firebase_core` + `firebase_auth` (+ `google_sign_in` no Android).
2. **Linux e Windows (Desktop):** via OAuth2 com loopback local (`HttpServer` em `127.0.0.1:<porta>`) + `url_launcher` e troca do token na API REST oficial do Firebase Identity Toolkit (`identitytoolkit.googleapis.com` / `securetoken.googleapis.com`), em Dart puro.

## Ler antes (só isto)

- [D00 — Papéis, distribuição de conteúdo e modelo de negócios](D00-papeis-e-distribuicao.md).
- `../zywny-comum/pubspec.yaml`: organização do workspace de pacotes compartilhados.

## Contexto que você precisa

- **Plano gratuito do Firebase Auth (Spark):**
  - Login social (Google, Apple, GitHub, Microsoft, Facebook) faz parte do *Tier 1* e é **gratuito até 50.000 MAU** (usuários ativos mensais), sem exigir cartão de crédito no plano Spark.
  - Autenticação por SMS **não** entra no plano gratuito (apenas 10 SMS/dia no plano Blaze), portanto fica fora de escopo.
- **As quatro plataformas (`Linux`, `Android`, `Web`, `Windows`):**
  - O plugin oficial `firebase_auth` (`^7.0.0`) não possui implementação nativa para Linux, e o `google_sign_in` não possui seletor nativo no Linux nem no Windows.
  - A API REST do Firebase Authentication é pública, documentada e usa apenas a `apiKey` Web do projeto Firebase:
    - Trocar token OAuth2 de provedor social por sessão Firebase:
      `POST https://identitytoolkit.googleapis.com/v1/accounts:signInWithIdp?key=<API_KEY>`
      com `postBody: "id_token=<TOKEN>&providerId=google.com"`, `requestUri: "http://127.0.0.1:<PORTA>"`, `returnIdpCredential: true`, `returnSecureToken: true`.
    - Renovar `idToken` vencido (dura 1 hora) usando o `refreshToken`:
      `POST https://securetoken.googleapis.com/v1/token?key=<API_KEY>`
      com `grant_type=refresh_token&refresh_token=<REFRESH_TOKEN>`.
    - Excluir a própria conta (exigência da LGPD, `D-NEG-PRIVACIDADE`):
      `POST https://identitytoolkit.googleapis.com/v1/accounts:delete?key=<API_KEY>`
      com `{"idToken": "<ID_TOKEN>"}`.
- **Regra dos 7 dias sem rede (`D-NEG-OFFLINE`):**
  - Quando o login ou a renovação do `idToken` no servidor tem sucesso, o `AuthStore` grava o instante em `SharedPreferencesAsync` (`auth_last_verified_ms`).
  - Se o aparelho abrir sem rede, a sessão guardada continua em estado `authenticated` enquanto `agora - ultimoVerificado <= 7 dias` (e `agora >= ultimoVerificado`, evitando relógio atrasado manualmente). Passados 7 dias sem conseguir renovar o token na rede, o estado muda para `offlineExpired`, pedindo reconexão.
- **Testes existentes (`test/` e `integration_test/`):**
  - Nem `flutter test` nem `just telas` têm rede ou configuração do Firebase. O `FakeAuthStore` permite injetar um usuário já autenticado por padrão nos testes.

## O que fazer

1. Criar `packages/zywny_auth/` em `../zywny-comum` (`resolution: workspace`):
   - `lib/auth_user.dart`: `AuthUser` imutável (`uid`, `email`, `displayName`, `photoUrl`, `providerId`, `idToken`, `refreshToken`, `idTokenExpiresAt`, `lastServerCheckAt`).
   - `lib/auth_state.dart`: enum/sealed `AuthStatus` (`initializing`, `unauthenticated`, `authenticated`, `offlineExpired`) + erro legível em português.
   - `lib/auth_store.dart`: interface `AuthStore` (`ValueListenable<AuthState>`), com `signInWithProvider(SocialProvider provider)`, `refreshSession()`, `updateNickname(String nickname)`, `signOut()`, `deleteAccount()`.
   - `lib/firebase_rest_auth_store.dart`: implementação em Dart puro usando `http` (ou `HttpClient` de `dart:io`), `SharedPreferencesAsync` e `LoopbackOAuthFlow` (`HttpServer.bind(InternetAddress.loopbackIPv4, 0)` + `url_launcher`) para Linux e Windows.
   - `lib/firebase_sdk_auth_store.dart`: implementação para Android e Web delegando ao `firebase_auth` + `google_sign_in`, mantendo o mesmo contrato de `lastServerCheckAt` e limite de 7 dias offline.
   - `lib/fake_auth_store.dart`: implementação em memória para testes de unidade, widget e integração.
2. Registrar `packages/zywny_auth` no `workspace:` de `../zywny-comum/pubspec.yaml` e expor no `pubspec.yaml` do `zywny-musicas` e do `zywny-aprendizado`.
3. Testes de unidade em `packages/zywny_auth/test/`:
   - Fluxo de login, persistência e restauração da sessão.
   - Renovação do `idToken` via cliente HTTP falso.
   - Expiração após 7 dias sem rede (`offlineExpired`) e detecção de relógio que andou para trás.
   - Exclusão de conta (`deleteAccount`) limpando os dados locais.

## Fora de escopo

- Telas (`SignInScreen`, `AuthGate`) — entram no [D02](D02-tela-de-login-e-auth-gate.md).
- Criar o projeto no console do Firebase e gerar o `google-services.json` — entram no [D03](D03-configuracao-firebase-e-android-web.md).
- Licenças de pacotes `.zywny` por aluno — entram no [D04](D04-licencas-de-pacotes-por-conta.md).

## Critérios de aceite

1. `flutter test` em `../zywny-comum/packages/zywny_auth` passa com todos os cenários (login, refresh, 7 dias offline, relógio regressivo, logout e exclusão de conta).
2. `just analyze-comum` e `just test-comum` limpos.
3. `just analyze` e `just test` no `zywny-musicas` continuam verdes.

**Status (2026-10-19): concluído.** Os três critérios passaram (ver "Notas de execução").

## Notas de execução (2026-10-19)

O pacote ficou em `../zywny-comum/packages/zywny_auth` (membro do workspace da
raiz do `zywny-comum`), registrado no `pubspec.yaml` dos dois apps.

### Arquivos

| Arquivo | O que é |
| --- | --- |
| `lib/auth_user.dart` | `AuthUser` (imutável) e o enum `SocialProvider` |
| `lib/auth_state.dart` | `AuthStatus`, `AuthState` e `AuthException` (mensagem em português) |
| `lib/auth_store.dart` | o contrato `AuthStore` e a base `AuthStoreBase` |
| `lib/session_freshness.dart` | a regra dos 7 dias e o relógio que anda para trás |
| `lib/session_storage.dart` | a sessão guardada nas preferências (a dos dois caminhos de login) |
| `lib/loopback_oauth.dart` | o login pelo navegador do sistema (PKCE) e a troca do código |
| `lib/src/loopback_server_io.dart` | o servidor local de volta (`127.0.0.1`) |
| `lib/src/loopback_server_stub.dart` | o mesmo na Web, onde não há servidor local |
| `lib/firebase_rest_auth_store.dart` | o login do desktop (REST do Identity Toolkit) |
| `lib/firebase_sdk_auth_store.dart` | o login do Android e da Web (SDK do Firebase) |
| `lib/fake_auth_store.dart` | o store de mentira dos testes dos dois apps |
| `lib/id_token.dart` | a validade lida do próprio `idToken` (JWT) |

### Desvios do plano

1. **`restore()` entrou no contrato.** O plano lista só `signInWithProvider`,
   `refreshSession`, `updateNickname`, `signOut` e `deleteAccount`; mas a
   sessão guardada precisa ser lida quando o app abre (é o que o D02 chama
   primeiro). `restore()` foi acrescentado ao `AuthStore` — e é o que os testes
   de "restauração da sessão" exercitam.
2. **`AuthUser` ganhou `nickname`.** O plano não lista o apelido entre os
   campos, mas `updateNickname` precisa guardá-lo em algum lugar e o D02
   mostra o apelido do lado do e-mail. O apelido fica no aparelho (é do
   Zywny, não do provedor) e só continua quando o login é da **mesma** pessoa
   (mesmo `uid`): trocar de conta não leva o apelido junto.
3. **Arquivos além dos listados.** O plano citava `lib/auth_user.dart`,
   `auth_state.dart`, `auth_store.dart`, `firebase_rest_auth_store.dart`,
   `firebase_sdk_auth_store.dart` e `fake_auth_store.dart`; o loopback, a
   regra dos 7 dias e o armazenamento da sessão ficaram em arquivos próprios,
   para os dois stores não repetirem código.
4. **`crypto` entrou como dependência** (SHA-256 do desafio do PKCE).

### Descobertas que afetam os passos seguintes

- **Na Web, `firebase_auth` 7.0.0 não implementa `signInWithProvider`** (só
  `signInWithPopup` e `signInWithRedirect`). O `FirebaseSdkAuthStore` usa
  `signInWithPopup(GoogleAuthProvider())` na Web — que é o "popup/redirect" do
  [D00](D00-papeis-e-distribuicao.md) — e o `google_sign_in` no Android.
- **O `google_sign_in` 7.x mudou a API**: é `GoogleSignIn.instance.initialize()`
  seguido de `authenticate()` (o `signIn()` sumiu), e no Android o `clientId`
  **não** é aceito (o app é identificado pelo `applicationId` + SHA-1; o
  `server_client_id` sai do `google-services.json`).
- **A porta do servidor local importa (para o D03).** O `LoopbackOAuthFlow`
  sobe em `127.0.0.1` numa porta livre (`port: 0`). O tipo de cliente OAuth
  "Desktop" do Google aceita qualquer porta do loopback; o tipo "Web
  application" exige o endereço **exato** registrado. Para o "Web
  application", passe `port:` com a porta registrada (e o `clientSecret`, que
  só ele tem). O passo tem o parâmetro `port` justamente por isso.
- **O servidor local tem de escutar antes de o navegador abrir.** Se o
  `waitForCode` só começasse depois do `launchUrl`, o navegador (que espera a
  resposta) ficaria esperando um servidor que ainda não escuta: o login
  trava. O `signIn()` registra a espera antes de abrir o navegador.
- **O relógio que anda para trás recusa a sessão.** Com `agora < último
  visto`, a sessão não é considerada fresca e o app pede conexão (o estado
  `offlineExpired`, com a mensagem do relógio). A validade da licença
  (D-NEG-VALIDADE) depende de um relógio confiável.
- **Só o Google tem o caminho do desktop.** No `FirebaseRestAuthStore`, os
  outros provedores (Apple, Microsoft, GitHub, Facebook) respondem "no
  computador, por enquanto, só o login com Google funciona" — o botão pode
  mostrá-los, mas o `AuthStore` recusa. O caminho de loopback dos outros
  provedores é um passo futuro.
- **`signOut` e `deleteAccount` são diferentes.** `signOut` revoga o
  `refreshToken` no servidor (melhor esforço: sem rede, sai do mesmo jeito);
  `deleteAccount` **exige** resposta do servidor (`accounts:delete`) e só
  então limpa o aparelho — se o servidor recusa, os dados locais ficam, para
  o app não prometer uma exclusão que não aconteceu.
- **A renovação falha sem derrubar o acesso.** Sem rede, `refreshSession()`
  deixa o estado `authenticated` com um aviso; só vira `offlineExpired` se
  também passou dos 7 dias.
- **O SDK do Firebase é dependência do pacote inteiro.** `zywny_auth` puxa
  `firebase_auth`, `firebase_core` e `google_sign_in` para os dois apps (que
  não têm plugin nativo no Linux). O `dart:io` do servidor local ficou
  atrás de um import condicional (`src/loopback_server_stub.dart` /
  `_io.dart`), senão o app não compilaria na Web.
- **O build do Windows passa a baixar o Firebase C++ SDK.** `firebase_core`
  tem plugin de Windows: o CMake baixa o **Firebase C++ SDK 14.0.0** de
  `dl.google.com` na hora de compilar (centenas de MB), a menos que
  `FIREBASE_CPP_SDK_DIR` aponte para uma cópia da mesma versão. No Windows o
  login é pelo navegador do sistema (REST), então esse SDK não é usado — mas
  o build paga o download. Registrado no [X02](X02-windows-render.md).

### Testes

- `packages/zywny_auth/test/firebase_rest_auth_store_test.dart` — login,
  persistência, restauração em outro app aberto, renovação do token, 7 dias
  sem rede (e o limite do 7º dia), relógio atrasado, renovação sem rede
  (com e sem os 7 dias), saída, exclusão da conta (com a chamada ao
  `accounts:delete`), apelido, provedor não suportado e navegador que não
  abre.
- `packages/zywny_auth/test/loopback_oauth_test.dart` — a troca do código
  pelo token (com o código e o verificador do PKCE), o endereço de
  autorização, o `state` diferente, o navegador que não abre e o provedor
  que recusa a troca.
- `packages/zywny_auth/test/fake_auth_store_test.dart` — o contrato do store
  de mentira (que o D02 usa para os testes dos apps).
- `packages/zywny_auth/test/support/fake_browser.dart` — o navegador de
  mentira (volta para o servidor local com o código) e o `id_token` de
  mentira no formato JWT.

**O caminho do SDK não tem teste automático:** ele precisa do Firebase
real (o `firebase_auth` fala com o plugin nativo). O aceite do SDK no
aparelho e no navegador é do [D03](D03-configuracao-firebase-e-android-web.md),
que é quem cria o projeto no console.

### Números medidos

- `flutter test` em `packages/zywny_auth`: **25 testes, todos passando**.
- `just analyze-comum`: limpo. `just test-comum`: 7 pacotes, todos verdes.
- `just analyze` + `just test` no `zywny-musicas`: 259 testes, verdes.
- `just analyze` + `just test` no `zywny-aprendizado`: 508 testes, verdes.
- Versões resolvidas: `firebase_auth` 7.0.0, `firebase_core` 5.0.0,
  `google_sign_in` 7.2.0, `http` 1.6.0, `shared_preferences` 2.5.6.

### Fora de escopo, como o plano previa

Telas (D02), projeto no console do Firebase (D03) e licenças por `uid`
(D04) continuam por fazer. O `FakeAuthStore` e o contrato já estão prontos
para o D02.

