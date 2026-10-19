# D02 — Tela de entrada, `AuthGate` e conta nas configurações

**Repo:** zywny-comum + zywny-musicas + zywny-aprendizado · **Depende de:** D01 · **Decisão necessária:** não (D-NEG-SEM-CONTA, D-NEG-PRIVACIDADE e D-NEG-AUTH decididas no [D00](D00-papeis-e-distribuicao.md))

## Objetivo

Construir a interface compartilhada de autenticação em `zywny-comum/lib/auth/` (`AuthGate`, `SignInScreen`, diálogo de apelido no primeiro acesso e seção "Conta" no painel de configurações gerais) e conectá-la ao `MyApp` do `zywny-musicas` (e do `zywny-aprendizado`), bloqueando o acesso ao app sem conta (`D-NEG-SEM-CONTA`) sem quebrar nenhum teste existente.

## Ler antes (só isto)

- [D00 — Papéis, distribuição de conteúdo e modelo de negócios](D00-papeis-e-distribuicao.md).
- [D01 — Pacote `zywny_auth` no `zywny-comum`](D01-pacote-zywny-auth.md).
- `../zywny-comum/lib/ui/theme.dart` e `../zywny-comum/lib/ui/brand.dart`: paleta, tipografia e monograma.

## Contexto que você precisa

- **Login obrigatório (`D-NEG-SEM-CONTA`):**
  - Sem conta autenticada, o app mostra apenas a tela de entrada (`SignInScreen`), logo depois da `SplashOverlay`.
  - Se a sessão tiver vencido os 7 dias sem internet (`AuthStatus.offlineExpired`, `D-NEG-OFFLINE`), a tela explica de forma clara ("Faz mais de 7 dias sem conexão. Conecte-se à internet para renovar seu acesso") com botão "Tentar novamente" e opção de trocar de conta.
- **Login social (`D-NEG-AUTH`):**
  - Botão principal **"Entrar com Google"** (e suporte visual para outros provedores sociais configurados, como Apple/Microsoft/GitHub).
- **Apelido e LGPD (`D-NEG-PRIVACIDADE`):**
  - No primeiro login (quando o perfil ainda não tem apelido escolhido no Zywny), pedir apenas o **apelido** com que o aluno/tutor quer ser chamado e o aceite da política de privacidade (com aviso específico para responsável de menor de 12 anos).
  - Na seção **Conta** dentro de `GeneralSettingsPanel` (`../zywny-comum/lib/app/general_settings_panel.dart`), exibir:
    - Apelido e e-mail da conta conectada;
    - **Código do aluno** (para o tutor vincular na turma, `D-NEG-VINCULO`);
    - Botão **"Sair da conta"**;
    - Botão **"Apagar minha conta e meus dados"** com diálogo de confirmação (`R22`), exigido pela LGPD.
- **Compatibilidade com os testes (`test/` e `integration_test/`):**
  - Em `MyApp` (`lib/main.dart`), receber `final AuthStore? authStore;`.
  - Quando `authStore` não é passado nos testes existentes (ou quando se passa `FakeAuthStore.loggedIn()`), o `AuthGate` libera o `child` (`LibraryScreen`) imediatamente, mantendo todos os testes de widget e os roteiros `just telas` funcionando sem alteração.
  - Testes novos específicos para `AuthGate` e `SignInScreen` passam um `FakeAuthStore.loggedOut()` ou `FakeAuthStore.offlineExpired()`.
- **O que o [D01](D01-pacote-zywny-auth.md) entregou (2026-10-19):**
  - O contrato `AuthStore` tem `restore()` além dos métodos do plano: é ele
    que lê a sessão guardada no aparelho. O `AuthGate` deve chamá-lo ao abrir
    (antes de mostrar o app ou a tela de entrada) — enquanto ele roda, o
    estado é `initializing`.
  - O `AuthUser` tem `nickname`: é onde fica o apelido escolhido (D-NEG-PRIVACIDADE).
    Ele já vem preenchido quando a pessoa já tinha escolhido antes (o
    `FakeAuthStore.loggedIn(nickname: ...)` também aceita).
  - O `FakeAuthStore` tem as fábricas `loggedIn()`, `loggedOut()`,
    `offlineExpired()` e `initializing()`.
  - Os estados são `AuthStatus.initializing`, `unauthenticated`,
    `authenticated` e `offlineExpired`; a mensagem (em português) vem em
    `AuthState.errorMessage`.

## O que fazer

1. Em `../zywny-comum/lib/auth/`:
   - `sign_in_screen.dart`: tela de entrada seguindo a identidade visual (`kLibraryBg`, `kLibraryCardBg`, `serifDisplay`, `MonogramZ`), responsiva para celular em paisagem e desktop/tablet.
   - `auth_gate.dart`: widget que escuta o `AuthStore` e alterna entre carregamento, `SignInScreen`, tela de reconexão após 7 dias offline, passo de apelido/aceite inicial e o `child` do app.
   - `account_settings_section.dart`: seção de conta integrada ao `GeneralSettingsPanel` (apelido, e-mail, sair, apagar conta).
2. Em `lib/main.dart` (do `zywny-musicas`):
   - Adicionar `this.authStore` em `MyApp` e envolver `LibraryScreen` no `AuthGate` dentro do `SplashOverlay`.
3. Criar `test/auth_gate_test.dart` testando:
   - App bloqueado na `SignInScreen` quando `unauthenticated`;
   - Entrada com Google via `FakeAuthStore` abrindo a `LibraryScreen`;
   - Bloqueio após 7 dias offline (`offlineExpired`) e reconexão;
   - Logout e exclusão de conta pelas configurações voltando para a `SignInScreen`.

## Fora de escopo

- Cobrança de assinatura no Google Play / App Store.
- Painel Web do tutor.

## Critérios de aceite

1. `just analyze-comum`, `just test-comum`, `just analyze` e `just test` 100% verdes.
2. Todos os 32 arquivos de teste existentes em `test/` continuam passando sem alteração de comportamento.
3. Os novos testes de widget de `AuthGate` / `SignInScreen` cobrem os estados `unauthenticated`, `authenticated`, `offlineExpired`, `signOut` e `deleteAccount`.

**Status (2026-10-19): concluído.** Os três critérios passaram (ver "Notas de execução").

## Notas de execução (2026-10-19)

### Arquivos

| Arquivo (repo) | O que é |
| --- | --- |
| `zywny-comum/lib/auth/sign_in_screen.dart` | `SignInScreen` (a tela de entrada), `AuthPanel` (o cartão que as telas de entrada usam) e `AuthMessage` (o aviso de erro) |
| `zywny-comum/lib/auth/auth_gate.dart` | `AuthGate` (o portão), a tela de reconexão (7 dias sem rede) e o passo do apelido/aceite |
| `zywny-comum/lib/auth/account_settings_section.dart` | a seção "Conta" das configurações e o `studentCodeFor` (o código do aluno) |
| `zywny-comum/lib/ui/brand.dart` | `BrandMonogram` (o quadrado vinho com o Z, que as telas de entrada mostram) |
| `zywny-comum/lib/app/general_settings_panel.dart` | `GeneralSettingsPanel`/`GeneralSettingsScreen` aceitaram o `authStore` (com ele, a seção "Conta") |
| `zywny-musicas/lib/main.dart` | `MyApp` recebe o `authStore` e o `requireNickname`; o `LibraryScreen` vai dentro do `AuthGate`, dentro do `SplashOverlay`; `ScoreHomePage` repassa o store ao painel |
| `zywny-musicas/lib/app/library_screen.dart` | `LibraryScreen` recebe o `authStore` e o repassa às configurações |
| `zywny-aprendizado/lib/main.dart` e `lib/app/courses_home.dart` | o mesmo no app dos cursos (o `MyApp` e a `CoursesHome`) |
| `zywny-musicas/test/auth_gate_test.dart` | os testes do portão (11 testes) |

### Desvios do plano

1. **O pedido do apelido é opt-in** (`requireNickname`, padrão `false`). O
   plano diz que o `AuthGate` pergunta o apelido "quando o perfil ainda não
   tem apelido escolhido" — mas o `FakeAuthStore.loggedIn()` (usado pelos
   testes) não tem apelido, e o plano também diz que ele tem de liberar o
   app na hora. As duas coisas só cabem juntas se o pedido for ligado à
   mão: o `AuthGate` pergunta quando `requireNickname` está ligado e o
   apelido está vazio. Quem liga é o app — o [D03](D03-configuracao-firebase-e-android-web.md),
   quando criar o store de verdade.
2. **O app ainda não cria store nenhum.** Sem projeto no Firebase (é o D03),
   não há login para fazer; o `main()` segue sem `authStore` e o portão
   não segura nada. O `MyApp` já aceita o `authStore` — o D03 só tem que
   passá-lo.
3. **O `AuthPanel` mora em `sign_in_screen.dart`** (e não em arquivo
   próprio): as três telas de entrada (entrada, reconexão e apelido) usam o
   mesmo cartão.
4. **A seção "Conta" fecha as telas ao sair ou apagar a conta** (ela volta
   para a primeira tela, onde o portão mostra a entrada). Sem isso, quem
   saísse ficaria olhando as configurações por cima da tela de entrada.

### Decisões que o passo tomou (e que o D04 vai usar)

- **O código do aluno** sai do `uid` (o identificador da conta no Firebase):
  oito caracteres em maiúsculas, com um hífen no meio (`FAKE-UID0` para o
  uid de mentira dos testes). É o que o tutor digita no painel dele
  (D-NEG-VINCULO).
- **O apelido é do Zywny, não do provedor** — como no D01, ele fica no
  aparelho e só continua quando o login é da mesma pessoa.

### O que ficou para o D03

- Criar o store de verdade (`FirebaseSdkAuthStore` no Android e na Web,
  `FirebaseRestAuthStore` no desktop) e passá-lo ao `MyApp` com
  `requireNickname: true`.
- Conferir o login de verdade (aqui não há Firebase: o `FakeAuthStore`
  resolve).

### Números medidos

- `just analyze-comum`: limpo. `just test-comum`: **354 testes do núcleo**
  (7 pulados, os manuais) + os 6 pacotes que têm teste (o `zywny_auth` com
  25), todos verdes.
- `just analyze` + `just test` no `zywny-musicas`: **271 testes verdes** (2
  pulados, os manuais) — 11 deles são os novos do portão.
- `just analyze` + `just test` no `zywny-aprendizado`: 508 testes, verdes.
- `just telas` (emulador Android, API 29): **24 telas fotografadas, 3
  falhas que não são deste passo** — "não chegou a: o hino", "não chegou a:
  gaveta de opções" e "não chegou a: teclado conectado". O mesmo roteiro,
  com as mudanças deste passo guardadas (`git stash`), falha nas mesmas
  três: é o emulador, não o portão. As telas do app saíram iguais (a
  seção "Conta" não aparece sem conta — o roteiro não passa store).

### Fora de escopo, como o plano previa

Cobrança de assinatura nas lojas e o painel Web do tutor continuam por
fazer (e o [R22](R22-dialogos-de-confirmacao.md), o diálogo único de
confirmação: o botão de apagar já usa a cor de perigo, como o R22 propõe).

