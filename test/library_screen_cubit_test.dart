// O Cubit da tela da biblioteca (BL15): ordem, busca, pastilhas, progresso
// lido, o catálogo (carregando, pronto ou com erro) e as guardas do fluxo. As
// transições com blocTest; o resto, com testes comuns.
import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/foundation.dart' show Uint8List;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:zywny_comum/incoming/incoming_packages.dart';
import 'package:zywny_library/library_blob_store.dart';
import 'package:zywny_library/library_cubit.dart';
import 'package:zywny_library/library_sort.dart';
import 'package:zywny_library/piece.dart';

import 'package:zywny/app/library_screen_cubit.dart';

/// Um catálogo que não é igual a nenhum outro (a identidade é o que se testa).
PieceCatalog _catalogo(String nome) =>
    PieceCatalog(<Piece>[], libraryName: nome);

/// Um Cubit com uma biblioteca em memória e o catálogo de [carregar].
LibraryScreenCubit _cubit([Future<PieceCatalog> Function()? carregar]) =>
    LibraryScreenCubit(
      libraries: LibraryCubit(blobs: MemoryLibraryBlobStore()),
      loadCatalog: carregar,
      aceitaEmbutida: false,
    );

IncomingPackage _pacote(String nome) =>
    IncomingPackage(name: nome, read: () async => Uint8List(0));

void main() {
  // O LibraryCubit abre preferências ao ser criado: a plataforma em memória.
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  _testesDoEstado();
  _testesDaOrdemEDaBusca();
  _testesDaBusca();
  _testesDoCatalogo();
  _testesDoPedidoEmCurso();
  _testesDoFimDaCarga();
  _testesDasGuardas();
  _testesDaFila();
  _testesDeAberturaEImportacao();
}

void _testesDoEstado() {
  group('LibraryScreenState', () {
    test(
      'começa na ordem por número, sem busca, com o catálogo carregando',
      () {
        const estado = LibraryScreenState();

        expect(estado.ordem.key, SortKey.number);
        expect(estado.busca, '');
        expect(estado.progressoCarregado, isFalse);
        expect(estado.pastilhasAlem, isTrue);
        expect(estado.catalogo.pronto, isNull);
        expect(estado.catalogo.carregando, isTrue);
        expect(estado.catalogo.falhou, isFalse);
      },
    );

    test('é igual pelo valor, inclusive a ordem e o catálogo', () {
      const porTitulo = SortState(key: SortKey.title);
      expect(
        const LibraryScreenState(ordem: porTitulo),
        const LibraryScreenState(ordem: porTitulo),
      );
      final catalogo = _catalogo('A');
      expect(
        LibraryScreenState(catalogo: CatalogoEstado(pronto: catalogo)),
        LibraryScreenState(catalogo: CatalogoEstado(pronto: catalogo)),
      );
      expect(
        LibraryScreenState(catalogo: CatalogoEstado(pronto: catalogo)),
        isNot(
          LibraryScreenState(catalogo: CatalogoEstado(pronto: _catalogo('A'))),
        ),
      );
    });

    test('copyWith troca só o campo pedido', () {
      const estado = LibraryScreenState(busca: 'bach');

      final outro = estado.copyWith(pastilhasAlem: false);

      expect(outro.busca, 'bach');
      expect(outro.pastilhasAlem, isFalse);
    });
  });
}

void _testesDaOrdemEDaBusca() {
  group('LibraryScreenCubit: ordem, busca e pastilhas', () {
    blocTest<LibraryScreenCubit, LibraryScreenState>(
      'mudarOrdem na chave atual inverte a direção',
      build: () => _cubit(),
      act: (cubit) => cubit.mudarOrdem(SortKey.number),
      expect: () => [
        predicate<LibraryScreenState>(
          (s) => s.ordem.key == SortKey.number && !s.ordem.ascending,
          'número, decrescente',
        ),
      ],
    );

    blocTest<LibraryScreenCubit, LibraryScreenState>(
      'tirarOrdemPorNumero põe o título quando a ordem era por número',
      build: () => _cubit(),
      act: (cubit) => cubit.tirarOrdemPorNumero(),
      expect: () => [
        predicate<LibraryScreenState>(
          (s) => s.ordem.key == SortKey.title,
          'título',
        ),
      ],
    );

    blocTest<LibraryScreenCubit, LibraryScreenState>(
      'tirarOrdemPorNumero não mexe em outra ordem',
      build: () => _cubit(),
      seed: () =>
          const LibraryScreenState(ordem: SortState(key: SortKey.score)),
      act: (cubit) => cubit.tirarOrdemPorNumero(),
      expect: () => <LibraryScreenState>[],
    );
  });
}

void _testesDaBusca() {
  group('LibraryScreenCubit: busca, progresso e pastilhas', () {
    blocTest<LibraryScreenCubit, LibraryScreenState>(
      'mudarBusca guarda o texto',
      build: () => _cubit(),
      act: (cubit) => cubit.mudarBusca('bach'),
      expect: () => [const LibraryScreenState(busca: 'bach')],
    );

    blocTest<LibraryScreenCubit, LibraryScreenState>(
      'limparBusca esvazia a busca',
      build: () => _cubit(),
      seed: () => const LibraryScreenState(busca: 'bach'),
      act: (cubit) => cubit.limparBusca(),
      expect: () => [const LibraryScreenState()],
    );

    blocTest<LibraryScreenCubit, LibraryScreenState>(
      'marcarProgressoCarregado liga o progresso lido',
      build: () => _cubit(),
      act: (cubit) => cubit.marcarProgressoCarregado(),
      expect: () => [const LibraryScreenState(progressoCarregado: true)],
    );

    blocTest<LibraryScreenCubit, LibraryScreenState>(
      'definirPastilhasAlem(false) esconde o esmaecido da borda',
      build: () => _cubit(),
      act: (cubit) => cubit.definirPastilhasAlem(false),
      expect: () => [const LibraryScreenState(pastilhasAlem: false)],
    );

    test('o mesmo valor de pastilhas não emite de novo', () async {
      final cubit = _cubit()..definirPastilhasAlem(false);
      addTearDown(cubit.close);
      final emitidos = <LibraryScreenState>[];
      final sub = cubit.stream.listen(emitidos.add);
      addTearDown(sub.cancel);

      cubit.definirPastilhasAlem(false);
      await pumpEventQueue();

      expect(emitidos, isEmpty);
    });
  });
}

void _testesDoCatalogo() {
  group('LibraryScreenCubit: catálogo', () {
    test('carregarCatalogo vai de carregando para pronto', () async {
      final carga = Completer<PieceCatalog>();
      final cubit = _cubit(() => carga.future);
      addTearDown(cubit.close);
      final catalogo = _catalogo('A');

      cubit.carregarCatalogo();
      expect(cubit.state.catalogo.carregando, isTrue);

      carga.complete(catalogo);
      await cubit.aguardarCatalogo();
      await pumpEventQueue();

      expect(cubit.state.catalogo.pronto, same(catalogo));
      expect(cubit.state.catalogo.carregando, isFalse);
      expect(cubit.state.catalogo.falhou, isFalse);
    });

    test('um erro vira falhou, sem catálogo', () async {
      final cubit = _cubit(() async => throw StateError('sem pacote'));
      addTearDown(cubit.close);

      final carga = cubit.carregarCatalogo();
      await expectLater(carga, throwsStateError);
      await pumpEventQueue();

      expect(cubit.state.catalogo.pronto, isNull);
      expect(cubit.state.catalogo.falhou, isTrue);
      expect(cubit.state.catalogo.carregando, isFalse);
    });
  });
}

void _testesDoPedidoEmCurso() {
  group('LibraryScreenCubit: pedidos do catálogo', () {
    test('enquanto um novo abre, o pronto anterior continua valendo', () async {
      final primeiro = _catalogo('antes');
      var pedidos = 0;
      final segunda = Completer<PieceCatalog>();
      final cubit = _cubit(() {
        pedidos++;
        return pedidos == 1 ? Future.value(primeiro) : segunda.future;
      });
      addTearDown(cubit.close);
      await cubit.carregarCatalogo();

      cubit.carregarCatalogo();

      expect(cubit.state.catalogo.pronto, same(primeiro));
      expect(cubit.state.catalogo.carregando, isTrue);
      segunda.complete(_catalogo('depois'));
    });

    test(
      'só vale o último pedido: um pedido antigo que termina depois é ignorado',
      () async {
        final antigo = Completer<PieceCatalog>();
        final novo = Completer<PieceCatalog>();
        var pedidos = 0;
        final cubit = _cubit(() {
          pedidos++;
          return pedidos == 1 ? antigo.future : novo.future;
        });
        addTearDown(cubit.close);
        cubit.carregarCatalogo();
        final ultimo = _catalogo('novo');

        cubit.carregarCatalogo();
        novo.complete(ultimo);
        await cubit.aguardarCatalogo();
        antigo.complete(_catalogo('antigo'));
        await pumpEventQueue();

        expect(cubit.state.catalogo.pronto, same(ultimo));
      },
    );
  });
}

void _testesDoFimDaCarga() {
  group('LibraryScreenCubit: fim da carga', () {
    test('carregarCatalogo zera o progresso lido', () async {
      final cubit = _cubit(() async => _catalogo('A'));
      addTearDown(cubit.close);
      cubit.marcarProgressoCarregado();

      cubit.carregarCatalogo();

      expect(cubit.state.progressoCarregado, isFalse);
    });

    test('a carga que termina depois do close não lança', () async {
      final carga = Completer<PieceCatalog>();
      final cubit = _cubit(() => carga.future);
      cubit.carregarCatalogo();

      await cubit.close();
      carga.complete(_catalogo('A'));
      await pumpEventQueue();

      expect(cubit.isClosed, isTrue);
    });
  });
}

void _testesDasGuardas() {
  group('LibraryScreenCubit: guardas do fluxo', () {});
}

void _testesDeAberturaEImportacao() {
  group('LibraryScreenCubit: abrir e importar', () {
    test('abrir uma partitura: só uma de cada vez', () {
      final cubit = _cubit();
      addTearDown(cubit.close);

      expect(cubit.iniciarAbertura(), isTrue);
      expect(cubit.iniciarAbertura(), isFalse);
      cubit.terminarAbertura();
      expect(cubit.iniciarAbertura(), isTrue);
    });

    test('importar um MusicXML: só um de cada vez', () {
      final cubit = _cubit();
      addTearDown(cubit.close);

      expect(cubit.iniciarImportacao(), isTrue);
      expect(cubit.iniciarImportacao(), isFalse);
      cubit.terminarImportacao();
      expect(cubit.iniciarImportacao(), isTrue);
    });
  });
}

void _testesDaFila() {
  group('LibraryScreenCubit: fila, passeio e biblioteca', () {
    test('a fila dos .zywny sai na ordem de chegada', () {
      final cubit = _cubit();
      addTearDown(cubit.close);
      cubit.enfileirarPacote(_pacote('a.zywny'));
      cubit.enfileirarPacote(_pacote('b.zywny'));

      expect(cubit.filaVazia, isFalse);
      expect(cubit.proximoPacote().name, 'a.zywny');
      expect(cubit.proximoPacote().name, 'b.zywny');
      expect(cubit.filaVazia, isTrue);
    });

    test('ocupado com pacote enquanto a fila ou a drenagem andam', () {
      final cubit = _cubit();
      addTearDown(cubit.close);
      expect(cubit.ocupadoComPacote, isFalse);

      cubit.enfileirarPacote(_pacote('a.zywny'));
      expect(cubit.ocupadoComPacote, isTrue);

      cubit.proximoPacote();
      cubit.iniciarDrenagem();
      expect(cubit.ocupadoComPacote, isTrue);
      cubit.terminarDrenagem();
      expect(cubit.ocupadoComPacote, isFalse);
    });

    test('a fila começa uma vez só', () {
      final cubit = _cubit();
      addTearDown(cubit.close);

      expect(cubit.marcarPacotePronto(), isTrue);
      expect(cubit.marcarPacotePronto(), isFalse);
    });

    test('o passeio: verificado, desmarcado e a espera do splash', () {
      final cubit = _cubit();
      addTearDown(cubit.close);
      expect(cubit.passeioVerificado, isFalse);
      expect(cubit.esperouSplash, isFalse);

      cubit.marcarPasseioVerificado();
      expect(cubit.passeioVerificado, isTrue);
      cubit.desmarcarPasseioVerificado();
      expect(cubit.passeioVerificado, isFalse);

      cubit.marcarEsperouSplash();
      expect(cubit.esperouSplash, isTrue);
    });

    test('a biblioteca mostrada: não mudou desde que foi anotada', () {
      final cubit = _cubit();
      addTearDown(cubit.close);

      cubit.garantirBibliotecaMostrada();

      expect(cubit.bibliotecaMudou(), isFalse);
    });
  });
}
