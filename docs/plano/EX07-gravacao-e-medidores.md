# EX07 — Medidores: a gravação da execução e os nove medidores (Dart puro)

**Repo:** zywny · **Depende de:** — · **Decisão necessária:**
D-EXE-LIMIARES (os números são provisórios até o EX08)

## Objetivo

Hoje o treino confere **que nota** e **quando**. O teclado manda mais do
que isso, e os livros cobram o resto o tempo todo:

- a velocity;
- o note-off (com a hora);
- o pedal (CC64).

Este passo grava tudo numa estrutura, a `PerformanceCapture`, e escreve
nove **medidores** que a leem. Fica sem tela, e o EX08 liga os medidores ao
`pass` e ao resumo.

| Medidor | O que mede | Livros |
| --- | --- | --- |
| `legato` | ligação entre notas seguidas da mesma mão: sem buraco e sem borrão | Pike 14 |
| `staccato` | quanto da duração escrita soou | Pike 14; Pearl 3 |
| `dynamics` | se a velocity segue o p, mf, f, crescendo e diminuendo escritos | Pike 11, 22 e 24 |
| `balance` | a melodia mais forte que o acompanhamento | Pike 31; PFA 6; a prova de ouvido do currículo (0.1) |
| `pedal` | a troca de pedal "sincopada" e o pedal que borra a harmonia | Pearl 9; Pike 12 e 13 |
| `steadiness` | regularidade: o desvio-padrão dos ataques, a tendência de correr ou arrastar | todos; Vinter ("sólido como rocha") |
| `swing` | a razão entre a 1ª e a 2ª colcheia de cada tempo | Harrison (conceitos rítmicos de cada livro); Willey (o pandeiro cai em ~2/3) |
| `accents` | a velocity nas posições acentuadas contra as outras | Willey (ganzá); Martignon (clave); Pearl 10 |
| `choruses` | quantas voltas seguidas sem erro (a mão esquerda "no piloto automático") | Vinter; Valerio *Stride* |

## Ler antes (só isto)

- `packages/zywny_midi/lib/midi_input_service.dart`: `PlayedNote` (velocity,
  on e off, `atSeconds`) e `sustain` (CC64).
- `lib/practice/practice_controller.dart`, perto da L515 a L531: como a hora
  de parede vira **ms musicais** (`scheduler.musicalAtDevice(note.atSeconds
  - inputLatencyMs / 1000)`).
- `lib/practice/practice_report.dart`: o `stdDevMs` e o `meanDeltaMs` já
  existem; `steadiness` reaproveita a mesma conta.
- `packages/zywny_audio/lib/performance_track.dart`: `SoundEvent` (onMs,
  offMs, staff, velocity) e `PedalEvent`.

## O que fazer

### 1. A gravação — `lib/practice/performance_capture.dart`

```dart
@immutable
class CapturedNote {
  final int pitch;
  final double onMs;      // musical
  final double? offMs;    // null enquanto segurada
  final int velocity;
}

@immutable
class CapturedPedal {
  final double atMs;
  final bool down;        // value >= 64
}

/// Grava a execução em ms musicais. Quem converte a hora é quem chama
/// (o PracticeController ou o TimedRoundRunner): a gravação não conhece
/// relógio.
class PerformanceCapture {
  void noteOn(int pitch, int velocity, double atMs);
  void noteOff(int pitch, double atMs);
  void pedal(int value, double atMs);
  List<CapturedNote> get notes;   // em ordem de onMs
  List<CapturedPedal> get pedals;
  void clear();
}
```

Ligue a gravação no `PracticeController`: no mesmo lugar em que o
`noteOn` chega à sessão, e também no **note-off** e no **sustain**. O
`sustain` hoje não é escutado. Use a mesma conversão para ms musicais nos
três. O `PracticeController` passa a expor `capture`.

### 2. O casamento com o escrito

Cinco medidores comparam o tocado com o escrito: `legato`, `staccato`,
`dynamics`, `balance` e `accents`. Eles precisam saber que nota tocada
corresponde a que nota da partitura.

- **No tempo real:** a `RealtimeSession` já casa (`NoteVerdict.eventId` e
  `pitch`).
- **No modo espera:** o `WaitModeSession` guarda `_hits[pitch]` com
  `atMs` e `velocity`.

Exponha os dois como uma lista de pares `(SoundEvent escrito, CapturedNote
tocada)`, numa estrutura comum (`MatchedNote`), sem mudar a conferência.

**O que o `midi.json` não traz (meça antes de escrever os medidores):** o
`SoundEvent` tem altura, início, fim, pauta e velocity. Não se sabe ainda
se ele traz as **marcas de expressão**:

- a dinâmica escrita (p, f, crescendo);
- o staccato;
- a ligadura de expressão.

O Verovio usa `@vel` na nota quando ela existe. Confira, com um MusicXML
que tenha `p` e `f`, staccato e uma ligadura, as três coisas:

1. A `velocity` dos `SoundEvent` muda entre o trecho p e o trecho f?
2. O `offMs` da nota em staccato é mais curto?
3. Existe algo que marque a ligadura?

Registre as respostas nas notas. Conforme o resultado:

- **Se não trazem:** os medidores recebem as marcas por outro caminho, uma
  lista `ExpressionMarks` (dinâmica com hora, ids em staccato, pares
  ligados):
  - nas **rodadas geradas pelo app** (`play-pattern`, EX06; a grade,
    EX09), quem gera sabe onde pôs cada marca e preenche a lista;
  - nas **partituras de autor**, ela fica vazia até um passo no bridge
    exportar as marcas (abra o pedido no plano do bridge, no molde do
    G01, e anote aqui o número);
  - sem marcas, o `legato` vale para **todo par de notas seguidas da mesma
    pauta sem pausa entre elas**, se o autor pediu `legato` no `pass`;
    `staccato` e `dynamics` dizem "nada para medir aqui".
- **Se trazem:** use direto o `SoundEvent`.

### 3. Os medidores — `lib/practice/meters.dart`

Cada medidor é uma função pura que devolve um `MeterResult`:

```dart
@immutable
class MeterResult {
  final String id;          // 'legato'
  final double value;       // o número do medidor (ver a tabela)
  final double? target;     // o alvo do `pass`, quando há
  final bool? passed;
  final String sentence;    // "8 de 10 ligações limpas; 2 borradas (c. 3, 5)."
  final List<int> measures; // compassos com problema (ocorrência), para o reforço
}
```

Definições e limiares **provisórios** (D-EXE-LIMIARES). Todos em ms de
**parede** (divida por `speed`, como o `PracticeReport`):

| Medidor | Definição | Valor | Provisório |
| --- | --- | --- | --- |
| `legato` | para cada par de notas seguidas da mesma mão (mesma pauta) que a partitura liga: a sobreposição `s = off(a) − on(b)`. Buraco se `s < −20 ms`; borrão se `s > max(80 ms, 25% da duração de a)` | % de ligações limpas | buraco −20 ms, borrão 80 ms |
| `staccato` | para cada nota com staccato escrito: `tocada = off − on`, contra `escrita = offMs − onMs` do `SoundEvent` | % de notas com `tocada <= 60% da escrita` | 60% |
| `dynamics` | a velocity mediana por trecho de dinâmica escrita (p, mf, f, entre as marcas). Passa se a ordem das medianas segue a ordem das marcas **e** a diferença entre trechos vizinhos de marca diferente é `>= 12`. No crescendo e no diminuendo, a inclinação da velocity ao longo do trecho tem o sinal certo | % de trechos certos | 12 de velocity |
| `balance` | a velocity mediana das notas da **melodia** (a pauta 1, ou a voz mais aguda quando há acorde) menos a do acompanhamento, nos ataques simultâneos | a diferença em velocity | alvo 10 |
| `pedal` | para cada troca de harmonia escrita (onde o `PedalEvent` do arquivo troca, ou cada compasso quando não há pedal escrito e o exercício pede `pedal`): **borrão** se o pedal está abaixado sem subir entre `on(acorde novo) − 30 ms` e `on + 250 ms`; **buraco** se ele sobe antes do acorde novo e só desce `> 400 ms` depois | % de trocas limpas | 250 ms, 400 ms |
| `steadiness` | o desvio-padrão do `deltaMs` das notas casadas (a mesma conta do `PracticeReport.stdDevMs`), e a média (correr < 0, arrastar > 0) | ms (menor é melhor) | alvo 40 ms |
| `swing` | para cada tempo com duas colcheias tocadas: `r = (on(2ª) − início do tempo) / duração do tempo` | a mediana de `r`, em % | 50 = reto, 67 = tercina |
| `accents` | a velocity mediana nas posições acentuadas (a `<accent>` escrita, ou o molde do exercício) menos a das outras | a diferença | alvo 12 |
| `choruses` | voltas completas da forma (a grade ou a repetição) sem nenhuma nota errada ou perdida, seguidas | número | — |

Regras:

- **Medidor sem dado:** se não há o que medir (nenhuma ligação, nenhuma
  marca de dinâmica, nenhum pedal pedido), o resultado é
  `value = NaN` e `sentence = 'nada para medir aqui'`. Nesse caso o
  medidor **não** reprova.
- **Teclado sem velocity:** alguns teclados (e o MIDI falso) mandam
  velocity fixa. Se todas as velocities da gravação forem iguais,
  `dynamics`, `balance` e `accents` devolvem "seu teclado não manda a
  força da tecla" e não reprovam.
- **Teclado sem pedal:** se nenhum CC64 chegou e o exercício pede `pedal`,
  a sentença diz "nenhum pedal chegou do teclado; ele está ligado?".

## Testes (`test/meters_test.dart`)

Cada medidor com uma gravação montada à mão (sem MIDI):

1. `legato`: 4 notas com sobreposição de 10 ms dão 100%; uma com buraco de
   50 ms dá 66%; uma com borrão de 200 ms dá 66%, e a sentença cita o
   compasso.
2. `staccato`: semínimas a 60 bpm, tocadas com 200 ms, passam; com 800 ms,
   não.
3. `dynamics`: um trecho p (vel. 40) e um f (vel. 90) passa; p 70 e f 75
   não passa; velocities todas iguais dão o aviso do teclado.
4. `balance`: melodia a 90 e acompanhamento a 60 dão 30.
5. `pedal`: a troca 100 ms depois do acorde passa; o pedal preso por 2
   acordes é borrão; o pedal ausente dá o aviso.
6. `swing`: as colcheias a 50% e 67% do tempo dão 50 e 67.
7. `accents`, `steadiness` e `choruses`: um caso que passa e um que não
   passa, cada um.
8. A ligação no `PracticeController`: com MIDI falso (`practice_fakes.dart`),
   o note-on, o note-off e o pedal chegam à `capture` com ms musicais
   iguais aos do casador.

## Critérios de aceite

1. `just test` e `just analyze` verdes.
2. Nada muda na tela nem no resultado dos exercícios: os medidores só
   calculam.

## Fora de escopo

O `pass`, a tela, a calibração dos limiares (EX08) e o swing na
reprodução (EX12).

## Notas de execução

(preencher)
