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
