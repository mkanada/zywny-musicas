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
