# D04 — Liberação de bibliotecas e pacotes por conta (`uid`)

**Repo:** zywny-comum + zywny-musicas + zywny-aprendizado · **Depende de:** D01, D02, D03 · **Decisão necessária:** não (D-NEG-PLATAFORMA, D-NEG-VALIDADE e regra 5 decididas no [D00](D00-papeis-e-distribuicao.md))

## Objetivo

Vincular a abertura e o download de bibliotecas (`.zywny`) e cursos à conta autenticada no Firebase (`AuthUser.uid`), garantindo a **Regra 5** do [D00](D00-papeis-e-distribuicao.md): *mesmo que o arquivo `.zywny` seja copiado de um aparelho para outro, o aluno só abre os pacotes que estiverem licenciados para o seu `uid` e dentro do prazo de validade (`D-NEG-VALIDADE`)*.

## Ler antes (só isto)

- [D00 — Papéis, distribuição de conteúdo e modelo de negócios](D00-papeis-e-distribuicao.md).
- [B00 — Bibliotecas instaláveis](B00-bibliotecas-instalaveis.md) e `../zywny-comum/packages/zywny_library/lib/library_envelope.dart`.
- [D01 — Pacote `zywny_auth` no `zywny-comum`](D01-pacote-zywny-auth.md).

## Contexto que você precisa

- **Como o `.zywny` funciona hoje (formato v1 do envelope, `B00`):**
  - Em `library_envelope.dart`, o zip interno é cifrado com uma chave derivada de `HKDF-SHA256(chave pública embutida no app, sal)`.
  - Isso protege contra arquivos soltos ou adulterados, mas qualquer instância do app com a mesma `ZYWNY_LIBRARY_KEY` abre qualquer arquivo `.zywny`.
- **O que muda com o login no Firebase (licença por aluno):**
  1. **Documento de Licença (`PackageLicense`):**
     - Guardado no Cloud Firestore em `users/{uid}/licenses/{packageId}` (protegido por Security Rules do Firestore onde somente `request.auth != null && request.auth.uid == uid` pode ler, e apenas a plataforma/tutor autorizado pode gravar) **e** assinado digitalmente (Ed25519) para que o app possa guardar em cache local e validar offline por até 7 dias (`D-NEG-OFFLINE`).
     - Campos da licença:
       - `packageId`: id da biblioteca ou curso (ex.: `classicos`, `hinos`, `curso-inicial`);
       - `uid`: o `uid` do Firebase Auth do aluno dono da licença;
       - `issuedAt`: timestamp de emissão (servidor);
       - `expiresAt`: timestamp de validade (`null` para conteúdo permanente da plataforma, ou data limite definida pelo tutor conforme `D-NEG-VALIDADE`);
       - `status`: `active` | `revoked` | `gracePeriod` (15 dias de carência quando tutor fica inadimplente, `D-NEG-VALIDADE`);
       - `contentKey`: chave simétrica de abertura do pacote (ou autorização de chave para aquele `packageId`).
  2. **Comportamento na Biblioteca (`LibraryScreen`):**
     - Ao fazer login (e sempre que houver rede), o `LicenseStore` sincroniza `users/{uid}/licenses` do Firestore para o cache local assinado.
     - Ao abrir ou instalar uma biblioteca `.zywny`, o `LibraryStore` confere no `LicenseStore` se há licença ativa para `(uidAtual, libraryId)` e se `horarioConfiavel <= expiresAt`.
     - **Ao vencer ou ser revogada (`D-NEG-VALIDADE`):** a biblioteca **não é apagada** e o **progresso continua guardado** (`shared_preferences`), mas ela aparece na lista como **bloqueada** ("Acesso encerrado — fale com seu tutor ou renove sua assinatura") e não permite abrir as partituras até que a licença volte a ficar ativa.
     - **Ao trocar de conta no mesmo aparelho:** as bibliotecas que não tiverem licença para o novo `uid` ficam bloqueadas imediatamente.

## O que fazer

1. Criar `LicenseStore` e `PackageLicense` em `../zywny-comum/packages/zywny_library/lib/library_license.dart` (ou em `zywny_auth`):
   - Verificação da assinatura Ed25519 da licença + conferência de `license.uid == authStore.currentUser.uid` + conferência de `expiresAt` contra o relógio monotônico confiável.
   - Cache local em `SharedPreferencesAsync` para funcionamento offline durante os 7 dias (`D-NEG-OFFLINE`).
   - Fonte remota (`LicenseRemoteSource`) que lê `users/{uid}/licenses` no Firestore usando o `idToken` do `AuthStore`.
2. Atualizar `LibraryStore` e `LibraryScreen` no `zywny-musicas`:
   - Exibir na tela da biblioteca os pacotes liberados para a conta logada (permitindo baixar direto os do catálogo atribuído ou abrir `.zywny` local autorizado).
   - Se um pacote `.zywny` aberto por arquivo não estiver atribuído ao `uid` logado, mostrar mensagem clara: *"Esta biblioteca não está atribuída à sua conta."*
   - Se a licença estiver vencida ou revogada, manter o item visível com cadeado e preservar todo o progresso (`PieceProgress` / `TrailProgress`).
3. Escrever as regras de segurança do Firestore (`firestore.rules`) garantindo isolamento por `request.auth.uid`.
4. Testes de unidade e de widget com `FakeLicenseStore` + `FakeAuthStore` cobrindo:
   - Pacote com licença válida abre normalmente;
   - Pacote sem licença para o `uid` atual é recusado;
   - Pacote com licença vencida fica visível e bloqueado, preservando o progresso;
   - Renovar a licença desbloqueia o pacote com o progresso intacto.

## Fora de escopo

- Emissão de certificados para chaves próprias de tutores (passo futuro da fase D, publicação pelo tutor).
- Envio de relatórios e gravações MIDI das sessões ao tutor (passos futuros da fase D).

## Critérios de aceite

1. `just analyze-comum`, `just test-comum`, `just analyze` e `just test` verdes.
2. Um arquivo `.zywny` sem licença correspondente para o `uid` logado não abre, mesmo sendo um `.zywny` íntegro.
3. Uma biblioteca cuja licença venceu aparece bloqueada na tela, mantém o progresso salvo e volta a abrir assim que a licença é prorrogada.
