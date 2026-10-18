# R24 — Fontes embutidas

**Repo:** zywny · **Depende de:** — · **Decisão necessária:** não

## Objetivo

O app mostra as suas fontes desde a primeira abertura, com ou sem
internet, e não faz pedidos aos servidores do Google (achado 17 da
[revisão](../revisao/2026-10-15-revisao-geral.md)).

## Ler antes (só isto)

- [Revisão](../revisao/2026-10-15-revisao-geral.md): achado 17.
- `lib/ui/theme.dart` L36–L50 (`serifDisplay`) e L87–L150
  (`buildAppTheme`).
- A seção `fonts:` do `pubspec.yaml`.

## Contexto que você precisa

- `serifDisplay` (`theme.dart:41`, 28 chamadores) usa
  `GoogleFonts.sourceSerif4`; o corpo usa
  `GoogleFonts.ibmPlexSansTextTheme(base.textTheme)` (`theme.dart:95`).
  O `google_fonts` baixa cada peso de `fonts.gstatic.com` na primeira vez
  e guarda em cache. Sem rede na primeira abertura, o texto sai na fonte
  reserva do sistema.
- Nos testes isso aparece como `google_fonts was unable to load font
  SourceSerif4-SemiBold … Failed to load font with url` (sem quebrar o
  teste).
- Cormorant Garamond e Instrument Sans já vêm como asset (`pubspec.yaml`,
  `fonts:`); Liberation Serif vem do `score_bridge` (`loadScoreFonts`).
- Pesos usados em `lib/` (contagem de 17/10): `w500` 11×, `w600` 55×,
  `w700` 7×, `w800` 3×, mais o regular. IBM Plex Sans vai até 700 (o 800
  cai no 700). `serifDisplay` usa `w600` por padrão; confira os outros
  pesos passados a ele e se há itálico.
- Source Serif 4 e IBM Plex Sans são OFL 1.1. A página de licenças do
  "Sobre" registra as licenças em `lib/about/licenses.dart`
  (`registerBundledLicenses`).

## O que fazer

1. Baixe os TTF dos pesos usados das duas famílias (repositórios oficiais
   da Adobe e da IBM), ponha em `assets/fonts/` com os arquivos de licença.
2. Declare as duas famílias na seção `fonts:` do `pubspec.yaml`, como a
   Cormorant.
3. `serifDisplay` passa a `TextStyle(fontFamily: 'Source Serif 4', …)`; o
   tema passa a `base.textTheme.apply(fontFamily: 'IBM Plex Sans', …)`.
4. Tire o `google_fonts` do `pubspec.yaml` se nada mais o usar.
5. Registre as duas licenças OFL em `registerBundledLicenses`.

## Fora de escopo

Os tamanhos de texto (R25). Trocar de fonte.

## Critérios de aceite

1. `grep -rn google_fonts lib packages pubspec.yaml` não acha nada (ou só
   o que tiver motivo anotado).
2. `just test` sem a mensagem `Failed to load font`.
3. `just analyze` e `just test` limpos.
4. Com o celular em modo avião, instalar e abrir o app pela primeira vez:
   títulos em Source Serif 4 e corpo em IBM Plex Sans **(manual)**.
5. `just telas` antes e depois: nenhuma diferença além de detalhes de
   desenho da fonte **(manual)**.
6. As duas licenças aparecem em "Sobre" → licenças **(manual)**.

## Notas de execução

