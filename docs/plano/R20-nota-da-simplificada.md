# R20 — Nota da versão simplificada na lista

**Repo:** zywny · **Depende de:** — · **Decisão necessária:** sim
(D-REV-SIMPL)

## Objetivo

A nota que o aluno tira na versão simplificada de uma música aparece em
algum lugar (achado 13 da
[revisão](../revisao/2026-10-15-revisao-geral.md)). Hoje ela é gravada e
nenhuma tela a mostra.

## Ler antes (só isto)

- [Revisão](../revisao/2026-10-15-revisao-geral.md): achado 13.
- `lib/app/library_screen.dart`, `_open` (L667–L750) e `_PieceRow`
  (L1784–L1942).

## Contexto que você precisa

- `Piece.asSimplified()` dá à simplificada o id `<id>.s`
  (`packages/zywny_library/lib/piece.dart:82`).
- Em `_open`, a nota vai para `progressIdFor(piece.id, transposition)`
  com o id da simplificada (`library_screen.dart:703`), e o tom escolhido
  também (`setTranspose(piece.id, …)`, L714). Já a abertura é marcada no id
  da música (`markOpened(base.id, …)`, L688).
- A lista lê pelo id do catálogo: `_progressOf` usa `forTone(piece.id, …)`
  (L563). A linha mostra "melhor N%" (L1241) e o selo da nota (L1869); a
  ordenação por nota usa `bestScore` (`packages/zywny_library/lib/library_sort.dart:103`).
- Desde 16/10, pontuar não marca a música como aberta (só `markOpened`
  marca), então a entrada `<id>.s` não aparece mais no "Continuar".

## Decisão necessária (D-REV-SIMPL)

Pergunte ao usuário antes de escrever código:

- **(a) Mostrar as duas.** A linha mostra a melhor do original e, se
  houver, "simplificada N%". A ordenação por nota usa a do original.
  Cada versão guarda a sua, como hoje.
- **(b) Juntar.** A simplificada grava no id da música; a lista mostra a
  melhor das duas, sem dizer de qual veio.

Recomendação: **(a)**. A nota da simplificada mede outra coisa (menos
notas); juntar esconde isso e uma nota alta na simplificada passaria a
valer pelo original.

## O que fazer

Com (a):

1. `PieceProgressStore`: um acesso à nota da simplificada no tom em uso
   (`forTone('<id>.s', tom)`), sem mudar o formato gravado.
2. `_PieceRow`/`_lead` mostram "simplificada N%" depois da nota do
   original, só se `piece.hasSimplified` e houver nota.
3. Teste de widget: pontuar a simplificada faz a linha mostrar a nota; a
   ordenação por nota não muda.

Com (b):

1. Em `_open`, a nota e o tom da simplificada vão para o id da música
   (`base.id`).
2. Migração única: ao carregar, juntar `<id>.s` em `<id>` (fica a maior
   nota) e apagar as entradas `<id>.s`.
3. Testes: a nota da simplificada aparece na linha; a migração junta e
   apaga.

## Fora de escopo

O tom e as configurações da simplificada (`PieceSettingsStore`), que já
são separados por versão de propósito.

## Critérios de aceite

1. Depois de tocar a simplificada, a nota aparece na linha da música
   (teste de widget).
2. `just analyze` e `just test` limpos.
3. `just telas`: a linha da biblioteca, com e sem nota da simplificada,
   cabe no celular em retrato **(manual)**.

## Notas de execução

