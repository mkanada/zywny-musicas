# R25 — Escala de texto

**Repo:** zywny · **Depende de:** R24 · **Decisão necessária:** não

## Objetivo

Os tamanhos de texto vêm de uma escala com nomes no tema, em vez de 202
números soltos (achado 18 da
[revisão](../revisao/2026-10-15-revisao-geral.md)). Mudar um tamanho passa a
ser uma linha.

## Ler antes (só isto)

- [Revisão](../revisao/2026-10-15-revisao-geral.md): achado 18.
- `lib/ui/theme.dart` inteiro.

## Contexto que você precisa

- Contagem de 17/10 (`grep -rhoE 'fontSize: [0-9.]+' lib`): 13 (58×),
  14 (27×), 15 (26×), 12 (25×), 16 (14×), 18, 22 e 26 (6× cada), 20 (5×),
  28 (3×), 13,5 (3×), 15,5, 12,5 e 11,5 (2× cada). Há também `fontSize:`
  com expressão (6×). São 22 usos de `textTheme`.
- As cores já seguem o padrão a imitar: constantes `k…` em `theme.dart`.
- `serifDisplay(fontSize: …)` é o estilo dos títulos (28 chamadores).
- Lugares com tamanho próprio de propósito: o número da contagem inicial
  (`lib/practice/count_in_overlay.dart`), os rótulos do teclado
  (`lib/midi/piano_keyboard.dart`) e o que é desenhado sobre a partitura.

## O que fazer

1. Em `theme.dart`, preencha os papéis do `TextTheme` com a escala:

   | Papel | Tamanho | Uso típico de hoje |
   |---|---|---|
   | `labelSmall` | 12 | legendas, contadores |
   | `bodySmall` | 13 | subtítulos, notas de rodapé |
   | `bodyMedium` | 14 | texto de lista |
   | `bodyLarge` | 15 | texto corrido, frase principal |
   | `titleSmall` | 16 | título de cartão |
   | `titleMedium` | 18 | título de nível, de seção |

   E para os títulos em serifa, constantes (`kTitleSize = 22`,
   `kDisplaySize = 26`, `kHeroSize = 28`) usadas com `serifDisplay`.
2. As frações vão para o vizinho mais próximo (11,5 → 12; 12,5 → 13;
   13,5 → 13 ou 14; 15,5 → 15 ou 16). Anote cada escolha nas notas.
3. Troque os literais pasta por pasta (`ui`, `app`, `course`,
   `sight_reading`, `trail`, `practice`, `settings`, `tutorial`, `about`),
   rodando `just telas` depois de cada uma.

## Fora de escopo

Mudar a hierarquia visual de alguma tela. Os tamanhos de propósito
listados acima (ficam com um comentário dizendo por quê).

## Critérios de aceite

1. `grep -rn 'fontSize: [0-9]' lib | wc -l` ≤ 25, e cada um que sobrou
   tem comentário.
2. `just analyze` e `just test` limpos.
3. `just telas` antes e depois: só as diferenças das frações
   arredondadas, nenhuma quebra de linha nova **(manual)**.

## Notas de execução

