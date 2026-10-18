# R19 — Ler sem apagar o progresso

**Repo:** zywny · **Depende de:** — · **Decisão necessária:** não

## Objetivo

Um erro ao **ler** o progresso não pode fazer a próxima gravação apagar o
que está guardado (achado 12 da
[revisão](../revisao/2026-10-15-revisao-geral.md)). JSON corrompido
continua começando do zero, como hoje.

## Ler antes (só isto)

- [Revisão](../revisao/2026-10-15-revisao-geral.md): achado 12 e "Já
  corrigido".
- Os quatro stores, nos trechos abaixo.

## Contexto que você precisa

Os quatro stores juntam "não consegui ler" e "não há nada" num valor vazio:

| Store | Onde lê | O que faz no erro | O que o aluno perderia |
|---|---|---|---|
| `CourseProgressStore` | `_read`, `lib/course/course_progress.dart` | devolve `null` | lições concluídas e exercícios aprovados do curso |
| `PieceProgressStore` | `load`, `packages/zywny_library/lib/piece_progress.dart` (~L87–L111) | `_byId.clear()`; `_save` regrava o mapa da biblioteca inteira | notas e "Continuar" de todas as músicas da biblioteca |
| `TrailProgressStore` | `ensureLoaded` (L299) e `_readAll` (~L349), `lib/trail/trail_progress.dart` | remove a trilha / pula a música | a trilha da música (o `TrailRunner`, `lib/app/trail_runner.dart:321`, parte do vazio e a primeira etapa grava por cima) |
| `SightReadingStore` | `_load`, `lib/sight_reading/sight_progress.dart` | volta ao 1a | o passo da leitura à vista |

- O erro de leitura vem de `SharedPreferencesAsync.getString`/`getKeys`
  (`PlatformException` no nativo; armazenamento bloqueado na Web). JSON
  ruim vem de `jsonDecode` (`FormatException`) ou do `fromJson`
  (`TypeError`, cast). Hoje um `try` só cobre os dois.
- A correção de 16/10 já fez as escritas do curso esperarem a leitura
  (`CourseProgressStore._update` e `_load`); falta a leitura dizer que
  falhou.
- `test/sight_progress_test.dart` tem um `_BrokenPrefs` (implementa
  `SharedPreferencesAsync` com `noSuchMethod`) que serve de modelo para um
  prefs que falha no `getString`.
- `PieceProgressStore` mora em `packages/zywny_library`, de que o app já
  depende; os outros três moram no app.

## O que fazer

1. `packages/zywny_library/lib/prefs_json.dart`: `readJsonKey(prefs, key)`
   devolve um resultado selado — `JsonMissing`, `JsonValue(Map)`,
   `JsonCorrupt(error)`, `JsonUnreadable(error)`. Dois `try` separados:
   um no `getString` (ilegível), outro no `jsonDecode` (corrompido). Os
   stores fazem o próprio `fromJson` e tratam um erro ali como corrompido.
2. Nos quatro stores:
   - corrompido → vazio, como hoje, com `DiagLog.log('erro', …)`;
   - ilegível → a chave fica marcada como "não lida". Antes de gravar
     nela, o store tenta ler de novo; se der certo, aplica a mudança sobre
     o que leu; se falhar de novo, guarda a mudança só na memória (não
     grava) e registra no `DiagLog`.
3. Testes, um por store: com o `getString` falhando, uma gravação não
   muda o valor que estava no armazenamento; quando a leitura volta a
   funcionar, a gravação seguinte junta a mudança ao que estava guardado;
   JSON corrompido ainda começa do zero.

## Fora de escopo

Avisar o aluno na tela (só se aparecer no `DiagLog` de alguém). Trocar o
`shared_preferences` por outra coisa. A base comum dos stores além da
leitura (cada um continua com o próprio formato).

## Critérios de aceite

1. Nos quatro stores, um erro de leitura seguido de gravação deixa o valor
   guardado intacto (testes).
2. JSON corrompido continua dando progresso vazio (os testes de hoje
   passam sem mudança).
3. `just analyze` e `just test` limpos.

## Notas de execução

