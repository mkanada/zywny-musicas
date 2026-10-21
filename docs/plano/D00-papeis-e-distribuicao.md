# D00 — Papéis, distribuição de conteúdo e modelo de negócios

**Repo:** zywny-comum + zywny-musicas + zywny-aprendizado · **Status:** decisões tomadas (2026-10-17 e 2026-10-19), primeiros passos em andamento (D01 e D02 feitos; D03 e D04 por fazer), **o serviço ainda não existe** · **Quando:** depois
da 1.0 · **Decisões necessárias:** ver "Decisões" no fim.

Este arquivo registra o modelo de negócios pedido pelo usuário e o detalha
aos poucos. As decisões `D-NEG-*` foram respondidas em 2026-10-17 e
2026-10-19; os passos iniciais de autenticação e licenciamento por conta estão
em [D01](D01-pacote-zywny-auth.md)–[D04](D04-licencas-de-pacotes-por-conta.md).

Prefixo **D**: não colide com X/N/C/K/M/T/W/V/J/L/U/B/I/Q/R/H/Y/Z/O/E (zywny)
nem com F/S/R/A/E/P/G (bridge). As decisões desta fase usam `D-NEG-*`, para
não confundir com as `D-BIB-*`, `D-LIC-*` etc. de outras fases.

## O que o usuário pediu (2026-10-17)

Três papéis:

| Papel | Quem é | O que faz |
| --- | --- | --- |
| **Plataforma** | Nós, quem desenvolve o zywny | Publica conteúdo próprio; controla quem pode receber o conteúdo de quem |
| **Tutor** | Quem usa o zywny para ensinar música | Disponibiliza cursos, músicas, exercícios e treinamentos aos seus alunos; recebe relatórios e o MIDI das sessões |
| **Aluno** | Quem estuda | Recebe conteúdo do seu tutor ou da plataforma e treina no app |

Regras, nas palavras do pedido:

1. **O tutor disponibiliza** cursos / músicas / exercícios / treinamentos ao
   aluno.
2. **O aluno recebe** conteúdo do seu tutor ou da plataforma.
3. **O tutor recebe relatórios** do andamento dos seus alunos: andamento,
   minutos de treino, erros mais comuns etc.
4. **O tutor recebe o MIDI** de cada vez que o aluno usa o app com conteúdo
   **daquele tutor**.
5. **A plataforma controla quem pode receber o conteúdo de quem.** Mesmo que o
   arquivo seja compartilhado, o aluno **não abre** conteúdo que não esteja
   atribuído a ele — seja da plataforma, seja de um tutor.
6. **Validade:** o conteúdo da plataforma vale por tempo **ilimitado**; o
   tutor **tem que definir um limite de tempo** ao disponibilizar conteúdo aos
   seus alunos.

## O que existe hoje (medido em 2026-10-17)

- **Não há rede, conta nem servidor.** Nenhum pacote HTTP no `pubspec.yaml`;
  o app é inteiramente local (Linux, Android, Web; Windows depois).
- **Pacote `.zywny`** (fase B, [B00](B00-bibliotecas-instalaveis.md)):
  cifrado (AES-256-GCM) e assinado (Ed25519) com **uma** chave da plataforma.
  A chave de conteúdo deriva da chave pública embutida no app — o limite
  honesto do B00 vale aqui: quem extrai a chave do binário decifra **qualquer**
  pacote. Serve contra arquivo solto e pacote forjado, **não** controla
  "este aluno pode, aquele não".
- **Cursos** (fase I, [I00](https://github.com/mkanada/zywny-aprendizado/blob/main/docs/plano/I00-licoes-e-curso-inicial.md)): o professor
  escreve markdown; hoje **só a plataforma assina** (D-LIC-CONFIANCA). O I00
  deixou fora de escopo "turmas, professor vendo o progresso do aluno, envio
  de gravações" — é exatamente o que esta fase traz.
- **Progresso** é guardado localmente, por música/peça e por curso
  (`packages/zywny_library/lib/piece_progress.dart`,
  `lib/course/course_progress.dart`). **Não existe** registro de sessão:
  nem minutos de treino, nem log de erros por nota, nem gravação do MIDI
  tocado. Tudo isso é novo.

## O que o pedido exige, por consequência

| Regra | Exige |
| --- | --- |
| 5 (só abre o que é seu) | **Identidade** do aluno (conta + login no app) e uma **licença por aluno**: o pacote só abre com uma chave que a plataforma entrega àquele aluno. A cifra de hoje (chave única no binário) não basta |
| 5, 6 (validade) | A licença carrega **validade**; o app precisa de uma noção de tempo confiável (relógio do aparelho pode ser adiantado/atrasado) |
| 1, 2 | Um **serviço** da plataforma: cadastro de tutores e alunos, vínculo tutor↔aluno, catálogo, atribuições |
| 1 (tutor publica) | O tutor precisa **publicar** sem a chave privada da plataforma: ou envia o conteúdo ao serviço e a plataforma assina, ou a plataforma certifica uma chave do tutor. Muda D-LIC-CONFIANCA |
| 3 (relatórios) | O app passa a **registrar sessões** (início, fim, conteúdo, acertos/erros por nota) e a **enviar** ao serviço; um painel para o tutor ver |
| 4 (MIDI) | O app **grava** a entrada MIDI da sessão e envia ao tutor dono daquele conteúdo; armazenamento no serviço |
| Todas | Funcionar **sem rede** por algum tempo (treinar no ônibus) e sincronizar depois — fila local de envios |

### Esboço técnico (para discutir, não decidido)

- **Pacote cifrado com chave de conteúdo aleatória** por pacote (não mais
  derivada da chave pública). A plataforma guarda essa chave.
- **Licença** = documento assinado pela plataforma com `conteúdo`, `aluno`,
  `aparelho(s)`, `emitida em`, `vale até` (ausente = ilimitado), e a chave de
  conteúdo **embrulhada** para a chave do aparelho do aluno (gerada no
  aparelho no primeiro login, a privada não sai dele).
- O app abre o pacote só com uma licença válida para aquele aluno naquele
  aparelho. Arquivo compartilhado sem licença = não abre (regra 5).
- **Tempo:** o app guarda o último horário confiável visto (do servidor ou da
  própria licença) e recusa relógio que andou para trás; licença **com
  validade** exige contato com o serviço a cada N dias.
- **Limite honesto, de novo:** um app que abre o conteúdo offline sempre pode
  ser quebrado por quem tem o aparelho e paciência. O objetivo é tornar o
  compartilhamento casual inútil, não ser DRM de estúdio. Na Web isso é ainda
  mais fraco.

## Decisões

Respondidas pelo usuário em sete rodadas de perguntas (2026-10-17).

| ID | Pergunta | Resposta |
| --- | --- | --- |
| D-NEG-PAGA | **Quem paga, e por quê?** Tutor paga assinatura (por aluno ativo? por faixa?); aluno paga a plataforma; tutor vende curso dentro do app e a plataforma fica com uma parte; conteúdo da plataforma é grátis ou pago? | **Decidido (2026-10-17):** o **tutor assina** (para ensinar: painel, relatórios, MIDI); o **aluno assina** a própria assinatura para usar o app, **tenha ou não tutor** — os dois pagam; o **conteúdo da plataforma é pago**. O tutor **não** vende curso pelo app (sem repasse) |
| D-NEG-LOJAS | Se o **aluno** paga conteúdo digital dentro do app, Google Play e App Store exigem o sistema de pagamento delas (comissão de 15–30%). Se quem paga é o **tutor**, fora do app (site), o app do aluno só "faz login". Qual caminho? | **Dentro do app** (2026-10-17), pelas lojas, aceitando a comissão. Consequência: Linux, Web e Windows não têm loja com cobrança — precisam de outro meio (ver D-NEG-DESKTOP) |
| D-NEG-VINCULO | Um aluno pode ter **vários tutores** ao mesmo tempo? Pode existir aluno **sem tutor** (só conteúdo da plataforma)? Como o aluno entra na turma: convite do tutor (código/link), cadastro pelo tutor? | **Decidido (2026-10-17):** aluno pode ter **vários tutores**; existe aluno **sem tutor**, que cria a própria conta no app; **o tutor cadastra** os seus alunos; aluno que já tem conta passa a ter tutor mostrando um **código do aluno** (no app), que o tutor digita no painel. Cada tutor só vê relatório e MIDI do **próprio** conteúdo e do conteúdo da plataforma que seus alunos usam |
| D-NEG-PLATAFORMA | O conteúdo **da plataforma** (ilimitado no tempo) é para todo aluno cadastrado, para quem paga, ou o tutor escolhe quais itens da plataforma seus alunos recebem? O tutor recebe relatório/MIDI de uso do conteúdo da plataforma pelos seus alunos? | **Decidido (2026-10-17):** a assinatura do aluno inclui um **catálogo básico** da plataforma (ex.: curso inicial e uma seleção de músicas); o resto é vendido em **itens avulsos**. O tutor pode **recomendar** itens da plataforma e **vê o uso** (relatório e MIDI) que seus alunos fazem deles |
| D-NEG-VALIDADE | A validade do tutor é **por atribuição** (este curso, para esta turma, até 31/12) ou por aluno? Há teto (ex.: 1 ano)? O tutor pode **prorrogar** ou **revogar** antes? Ao vencer: some da biblioteca, fica visível e bloqueado, e o **progresso** do aluno fica guardado? | **Decidido (2026-10-17):** prazo **por atribuição** (item × grupo de alunos × data); o tutor pode **prorrogar** e **revogar** a qualquer momento; **sem teto** da plataforma. A **plataforma revoga** o conteúdo de tutor que não estiver em dia com ela. Ao vencer ou ser revogado, o item fica **visível e bloqueado** e o **progresso fica guardado**; volta se o acesso voltar |
| D-NEG-PUBLICAR | Como o tutor publica: envia a pasta/arquivos ao serviço (a plataforma valida, assina e cifra) ou recebe uma chave própria? A plataforma **revisa** o conteúdo do tutor antes (direitos autorais de partituras, conteúdo impróprio) ou só valida o formato? | **Decidido (2026-10-17):** **chave própria do tutor**. A plataforma certifica a chave pública do tutor (certificado assinado pela plataforma); o tutor assina os pacotes no computador dele. A **licença por aluno** (regra 5) continua sendo emitida só pela plataforma. Falta: revisão de conteúdo (direitos autorais) — por ora, nenhuma |
| D-NEG-MIDI | O MIDI vai **sempre** ao tutor, ou só quando o aluno/tutor marca uma sessão para envio? Quanto tempo fica guardado? O aluno vê/ouve o que foi enviado? Vale também para exercícios de ouvido e curso, ou só para tocar partitura? | **Decidido (2026-10-17):** **toda sessão** com conteúdo daquele tutor vai a ele, com aviso na tela — tocar partitura, **exercícios do curso**, **ouvido** e **leitura à vista**; fica guardada **enquanto houver vínculo** e é apagada quando o vínculo acaba. O aluno **não** ouve no app o que foi enviado |
| D-NEG-PRIVACIDADE | Muitos alunos serão **menores de idade**. LGPD (e GDPR fora do Brasil) pede consentimento do responsável, finalidade clara e direito de apagar. Quem é o controlador dos dados — a plataforma, o tutor, ambos? | **Decidido (2026-10-17):** a **plataforma é a controladora**; o aluno entra com **apelido** e o serviço guarda o mínimo. Para **menores de 12**, o responsável dá o aceite por e-mail num formulário da plataforma. Ver "LGPD: por que vale" e "Apelido em vez de nome" |
| D-NEG-RELATORIO | O que entra no relatório e com que frequência: minutos por dia, conteúdos abertos, % de acerto, notas/compassos mais errados, andamento atingido, sequência de dias. Painel na Web, no próprio app, e-mail semanal? | **Decidido (2026-10-17):** entram **minutos por dia** e dias seguidos; **% de acerto e andamento** (BPM) com evolução; **onde mais erra** (notas e compassos, marcados na partitura); **etapas e lições** concluídas e onde parou. Painel Web + resumo no app. Sem e-mail semanal; o único aviso é **aluno parado** (alguns dias sem treinar), no painel |
| D-NEG-OFFLINE | Quantos dias o aluno treina **sem rede** antes de o app exigir conexão (para renovar licença e enviar sessões)? | **Decidido (2026-10-17):** **7 dias** sem rede; depois disso o app exige conexão para renovar licenças e enviar as sessões guardadas |
| D-NEG-PAPEIS-APP | O tutor usa o **mesmo app** (modo tutor) ou um painel Web separado? O tutor também é aluno de alguém (conta com dois papéis)? E escolas com vários tutores? | **Decidido (2026-10-17):** painel Web para o trabalho do tutor e resumo de relatórios no app; uma conta pode ser **tutor de uns e aluno de outro**. **Escolas** (vários tutores sob uma conta pagante) ficam **fora** da primeira versão |
| D-NEG-SERVICO | Onde roda o serviço: backend próprio (ex.: Rust, como o motor) em VPS, ou um BaaS (Supabase/Firebase)? Custo mensal aceitável no começo? | **Decidido (2026-10-17):** **Firebase**. Atenção: o FlutterFire não suporta **Linux** (e o Windows é parcial) — ver "Firebase no Linux" abaixo |
| D-NEG-DESKTOP | Como cobrar no Linux, na Web e no Windows, que não têm cobrança de loja (ou a do Windows é opcional)? Pagamento por site só nessas plataformas, ou nelas o app só abre o que foi pago no celular? | **Decidido (2026-10-17):** a **assinatura vale na conta**. Assina-se no Android (Play Billing) ou no iPhone (App Store); Web, Linux e Windows só fazem login, sem compra. Sem site de pagamento por ora |
| D-NEG-SEM-CONTA | O app continua abrindo **sem conta** (metrônomo, leitura à vista, conteúdo gratuito da plataforma), ou login passa a ser obrigatório? | **Decidido (2026-10-17):** **login obrigatório**; sem conta, só a tela de entrada |
| D-NEG-AUTH | Quais métodos de login habilitar no Firebase Authentication (plano gratuito Spark, até 50k MAU), qual o papel do login no `zywny-musicas` e onde fica o código? | **Decidido (2026-10-19):** **Login com Google e outras redes sociais** (Tier 1 do Firebase Auth, gratuito até 50.000 MAU no plano Spark, sem SMS); papel de **bloquear o acesso ao app sem conta** e **liberar bibliotecas/pacotes atribuídos ao usuário**; módulo compartilhado no **`zywny-comum`** (`packages/zywny_auth` + `lib/auth/`) para servir tanto ao `zywny-musicas` quanto ao `zywny-aprendizado` |

### Revogação de tutor inadimplente (D-NEG-VALIDADE)

Quando a plataforma revoga um tutor que não está em dia, os alunos dele são
**avisados** e há **15 dias de carência** antes de o conteúdo ficar
bloqueado. O progresso fica guardado.

### Fim do vínculo (D-NEG-VINCULO)

O **tutor**, o **aluno** (pelo app) e o **responsável** pelo menor podem
encerrar o vínculo. Ao encerrar, param os relatórios e o envio de MIDI, o
MIDI guardado daquele vínculo é apagado (D-NEG-MIDI) e o conteúdo daquele
tutor fica bloqueado com o progresso guardado. O responsável pode também
pedir que os dados sejam apagados.

### Firebase no Linux e Windows (D-NEG-SERVICO, D-NEG-AUTH)

O pacote oficial `firebase_auth` para Flutter cobre Android, iOS, macOS, Web e
Windows, mas **Linux não é suportado** pelo SDK nativo e o seletor nativo do
`google_sign_in` só existe em Android, iOS e Web. Solução definida em
2026-10-19 ([D01](D01-pacote-zywny-auth.md)):

- **Android e Web:** usam o `firebase_auth` oficial (+ `google_sign_in` no
  Android e popup/redirect na Web).
- **Linux e Windows (Desktop):** abrem o login social no navegador do sistema
  via `url_launcher` com redirecionamento para um `HttpServer` local em
  `http://127.0.0.1:<porta>` (loopback OAuth2) e trocam o token diretamente na
  **API REST oficial do Firebase Identity Toolkit**
  (`identitytoolkit.googleapis.com/v1/accounts:signInWithIdp` e
  `securetoken.googleapis.com/v1/token`), em Dart puro.
- As quatro plataformas convergem na mesma interface `AuthStore` dentro de
  `zywny-comum` (`packages/zywny_auth`), compartilhando a regra dos 7 dias
  offline (`D-NEG-OFFLINE`) e o `FakeAuthStore` para os testes.

### LGPD: por que vale (D-NEG-PRIVACIDADE)

A LGPD não depende de o dado ser foto ou áudio. Ela vale para **qualquer
informação ligada a uma pessoa identificada** — e o serviço vai guardar,
junto do nome e do contato do aluno, quanto ele treinou, quando, o que errou
e o que tocou. O MIDI não é dado **sensível** (essa categoria é saúde,
biometria, religião etc.), então as exigências são as comuns, não as mais
duras. O que pesa é o **cadastro** em si, com ou sem MIDI:

- **Criança (menor de 12 anos):** consentimento específico de um dos pais ou
  responsável (LGPD art. 14). Como o tutor cadastra o aluno, alguém precisa
  colher esse consentimento — no cadastro pelo tutor ou no primeiro login.
- **Todos:** política de privacidade, finalidade dita (relatórios ao tutor),
  só o necessário, direito de ver e **apagar** os dados.
- **Lojas:** apps com crianças como público caem na política "Famílias" do
  Google Play e na categoria Kids da App Store, com regras próprias
  (anúncios, analytics de terceiros).

Na prática é pouco trabalho se for desenhado desde o início: um aceite no
cadastro, uma política escrita e um botão "apagar minha conta".

### Chave do tutor (D-NEG-PUBLICAR)

- O tutor gera um par de chaves (ferramenta de linha de comando ou o painel
  Web, no navegador dele); a privada não sai do computador do tutor.
- A plataforma assina um **certificado**: `tutor`, chave pública, `vale até`.
  O app só aceita pacote de tutor cujo certificado confere com a chave da
  plataforma e está válido.
- O certificado é também o **interruptor da inadimplência**: a plataforma
  não renova (ou revoga) o certificado de quem não está em dia, e o app,
  depois da carência, bloqueia aquele conteúdo.
- Assinar prova **quem fez** o pacote; quem pode **abrir** continua sendo a
  licença por aluno que só a plataforma emite. O tutor precisa entregar à
  plataforma a chave de conteúdo do pacote (ou cifrar com uma chave que a
  plataforma fornece), senão a plataforma não consegue licenciar.

### Pagamento fora do Android (D-NEG-DESKTOP)

- **Google Play Billing** (assinaturas da Play Store) só funciona no app
  Android. A assinatura feita ali pode valer na **conta** em todas as
  plataformas: o serviço confere a assinatura na API do Google Play e libera
  o login em Linux/Web/Windows.
- Para **assinar** fora do Android, é preciso um processador de pagamentos
  na Web (Stripe, Mercado Pago, Pagar.me…), que aceita **Google Pay**,
  cartão e Pix. O Google não oferece cobrança de assinatura para apps
  desktop ou sites fora da Play Store.
- iOS: assinatura pela App Store, conferida do mesmo jeito pelo serviço.

### Apelido em vez de nome (D-NEG-PRIVACIDADE)

O usuário perguntou se, entrando com **apelido**, a LGPD ainda se aplica.
Resposta: o apelido **reduz** o risco, mas não tira o dado da LGPD, porque
a pessoa continua identificável — o tutor que cadastrou sabe quem ela é, a
assinatura da loja liga a conta a uma conta Google/Apple real, e o aparelho
e o IP também identificam. Dado **pseudonimizado** ainda é dado pessoal (só
dado **anonimizado**, sem volta, sai da lei). O apelido é uma boa prática
(minimização) e diminui o que vaza num incidente; o aceite do responsável
para menores de 12 continua necessário.

## Histórico da conversa

- **2026-10-17** — pedido inicial registrado acima (papéis, regras 1–6).
- **2026-10-17** — primeira rodada de perguntas: D-NEG-VINCULO decidida; D-NEG-PAGA, D-NEG-LOJAS e D-NEG-VALIDADE respondidas em parte; D-NEG-DESKTOP aberta como consequência de pagar pelas lojas.
- **2026-10-17** — segunda rodada: D-NEG-PAGA (os dois pagam), D-NEG-VALIDADE (por atribuição, prorrogar/revogar, plataforma revoga tutor inadimplente) e D-NEG-OFFLINE (7 dias) decididas; D-NEG-MIDI em parte (toda sessão).
- **2026-10-17** — terceira rodada: carência antes de bloquear tutor inadimplente; MIDI guardado enquanto houver vínculo; painel Web + resumo no app. LGPD: usuário questionou; explicação registrada, controlador ainda a escolher.
- **2026-10-17** — quarta rodada: D-NEG-PUBLICAR decidida (chave própria do tutor, certificada pela plataforma); D-NEG-PLATAFORMA em parte (avulsos, tutor recomenda, tutor vê o uso); pagamento fora do Android e apelido × LGPD explicados.
- **2026-10-17** — quinta rodada: D-NEG-PRIVACIDADE (plataforma controladora + apelido + aceite do responsável), D-NEG-DESKTOP (assinatura vale na conta), D-NEG-PLATAFORMA (básico incluso + avulsos) e D-NEG-SEM-CONTA (login obrigatório) decididas.
- **2026-10-17** — sexta rodada: vínculo por código do aluno; relatório com minutos, acerto/andamento, onde erra e etapas; MIDI também de curso, ouvido e leitura à vista, sem o aluno ouvir; conta com dois papéis; escolas fora da primeira versão.
- **2026-10-17** — sétima rodada: Firebase (com o risco do Linux registrado); aviso de aluno parado, sem e-mail; carência de 15 dias; tutor, aluno e responsável encerram o vínculo. Todas as D-NEG decididas; falta quebrar em passos D01….
- **2026-10-19** — oitava rodada (autenticação Firebase e liberação de pacotes): confirmados o uso do plano gratuito Spark (até 50.000 MAU gratuitos para login social), `D-NEG-AUTH` (Login com Google e outras redes sociais, bloqueio do app sem login + liberação de bibliotecas/pacotes por conta, código compartilhado no `zywny-comum`), solução híbrida SDK (Android/Web) + REST/Loopback (Linux/Windows) e quebra dos primeiros passos [D01](D01-pacote-zywny-auth.md)–[D04](D04-licencas-de-pacotes-por-conta.md).

## Passos da fase D (autenticação e licenciamento inicial)

| Passo | Título | Repo | Depende de | Status |
| --- | --- | --- | --- | --- |
| [D01](D01-pacote-zywny-auth.md) | Pacote `zywny_auth` no `zywny-comum` (`AuthStore`, 7 dias offline, REST/Loopback no Linux/Windows, SDK no Android/Web, `FakeAuthStore`) | zywny-comum | — | concluído (2026-10-19) |
| [D02](D02-tela-de-login-e-auth-gate.md) | Tela de entrada (`SignInScreen`), `AuthGate`, apelido inicial e seção Conta nas configurações | zywny-comum + apps | D01 | concluído (2026-10-19) |
| [D03](D03-configuracao-firebase-e-android-web.md) | Projeto Firebase (plano Spark), `applicationId` definitivo e credenciais OAuth2 nas 4 plataformas | zywny-musicas + zywny-aprendizado | D01, D02 | código pronto (2026-10-19); falta criar o projeto no console |
| [D04](D04-licencas-de-pacotes-por-conta.md) | Liberação de bibliotecas e pacotes (`.zywny` e cursos) vinculada ao `uid` e validade (`D-NEG-VALIDADE`) | zywny-comum + apps | D01, D02, D03 | pendente |
