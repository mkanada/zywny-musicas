// O Cubit da tela da biblioteca (BL15). O estado é o que a tela desenha: a
// ordenação, a busca, as pastilhas, se o progresso já foi lido e o catálogo
// (carregando, pronto ou com erro). O carregamento do catálogo mora aqui, a
// partir da biblioteca em uso.
//
// As guardas do fluxo (abrir, importar, a fila dos `.zywny` recebidos, o
// passeio) não desenham nada: são campos privados, e o State as usa pelos
// métodos abaixo. Por isso não viram estado.

import 'dart:async';

import 'package:flutter/foundation.dart' show Uint8List;
import 'package:flutter/services.dart' show rootBundle;
import 'package:zywny_bloc/zywny_bloc.dart';
import 'package:zywny_comum/incoming/incoming_packages.dart';
import 'package:zywny_library/library_cubit.dart';
import 'package:zywny_library/library_package.dart' show LibraryPackage;
import 'package:zywny_library/library_sort.dart';
import 'package:zywny_library/piece.dart';

/// O catálogo da biblioteca em uso. `pronto` é o último carregado: enquanto um
/// novo abre, continua valendo (como o `FutureBuilder` de antes). `falhou`
/// diz que a última abertura deu erro.
class CatalogoEstado extends Equatable {
  const CatalogoEstado({
    this.pronto,
    this.carregando = true,
    this.falhou = false,
  });

  final PieceCatalog? pronto;
  final bool carregando;
  final bool falhou;

  @override
  List<Object?> get props => [pronto, carregando, falhou];
}

/// O que a tela da biblioteca desenha além dos dados.
class LibraryScreenState extends Equatable {
  const LibraryScreenState({
    this.ordem = const SortState(),
    this.busca = '',
    this.progressoCarregado = false,
    this.pastilhasAlem = true,
    this.catalogo = const CatalogoEstado(),
  });

  /// A ordenação da lista (as pastilhas).
  final SortState ordem;

  /// O que está na caixa de busca ("" sem busca).
  final String busca;

  /// O histórico já foi lido: antes disso não se sabe se é o primeiro uso, e o
  /// cartão de começo não pode piscar para quem já estudou (U16).
  final bool progressoCarregado;

  /// Há pastilhas de ordenação fora da tela, à direita (U14).
  final bool pastilhasAlem;

  /// O catálogo da biblioteca em uso.
  final CatalogoEstado catalogo;

  LibraryScreenState copyWith({
    SortState? ordem,
    String? busca,
    bool? progressoCarregado,
    bool? pastilhasAlem,
    CatalogoEstado? catalogo,
  }) => LibraryScreenState(
    ordem: ordem ?? this.ordem,
    busca: busca ?? this.busca,
    progressoCarregado: progressoCarregado ?? this.progressoCarregado,
    pastilhasAlem: pastilhasAlem ?? this.pastilhasAlem,
    catalogo: catalogo ?? this.catalogo,
  );

  @override
  List<Object?> get props => [
    ordem.key,
    ordem.ascending,
    busca,
    progressoCarregado,
    pastilhasAlem,
    catalogo,
  ];
}

/// Os métodos são síncronos: a tela lê `state` na hora e o aplica na mesma hora.
class LibraryScreenCubit extends Cubit<LibraryScreenState> {
  LibraryScreenCubit({
    required this.libraries,
    this.loadCatalog,
    this.aceitaEmbutida = true,
  }) : super(const LibraryScreenState());

  /// A biblioteca instalada: de onde o catálogo em uso é aberto.
  final LibraryCubit libraries;

  /// De onde vem o catálogo quando a tela não usa a biblioteca instalada (os
  /// testes trocam por um falso); `null` é a biblioteca em uso.
  final Future<PieceCatalog> Function()? loadCatalog;

  /// Se a biblioteca embutida (os clássicos) pode entrar quando não há
  /// nenhuma instalada. Quem injeta a loja (os testes) não a quer.
  final bool aceitaEmbutida;

  // Guardas do fluxo: não desenham nada, por isso não são estado.
  Future<PieceCatalog>? _carga;
  String? _bibliotecaMostrada;
  bool _abrindo = false;
  bool _importando = false;
  bool _drenando = false;
  bool _pacoteProntoParaInstalar = false;
  final List<IncomingPackage> _fila = [];
  bool _passeioVerificado = false;
  bool _esperouSplash = false;

  // --- A ordem, a busca e as pastilhas -------------------------------------

  /// Toca numa pastilha: a mesma chave inverte a direção; outra troca de chave
  /// (e volta à direção padrão dela).
  void mudarOrdem(SortKey chave) =>
      emit(state.copyWith(ordem: state.ordem.toggled(chave)));

  /// Biblioteca sem número (os clássicos): a ordem "por número" cai na padrão
  /// (o título). Quem chama confere se a biblioteca é numerada.
  void tirarOrdemPorNumero() {
    if (state.ordem.key != SortKey.number) return;
    emit(state.copyWith(ordem: const SortState(key: SortKey.title)));
  }

  void mudarBusca(String texto) => emit(state.copyWith(busca: texto));

  void limparBusca() => emit(state.copyWith(busca: ''));

  void marcarProgressoCarregado() =>
      emit(state.copyWith(progressoCarregado: true));

  void definirPastilhasAlem(bool mais) =>
      emit(state.copyWith(pastilhasAlem: mais));

  // --- O catálogo ----------------------------------------------------------

  /// O catálogo do último pedido (ou o primeiro, se ainda não houve).
  Future<PieceCatalog> aguardarCatalogo() => _carga ?? carregarCatalogo();

  /// Pede o catálogo da biblioteca em uso (de novo, depois de uma troca ou de
  /// uma instalação). Zera o progresso lido: quem chama o lê de novo. O
  /// resultado só vale se for do último pedido.
  Future<PieceCatalog> carregarCatalogo() {
    final carga = _carregar();
    _carga = carga;
    final anterior = state.catalogo;
    emit(
      state.copyWith(
        progressoCarregado: false,
        catalogo: CatalogoEstado(
          pronto: anterior.pronto,
          falhou: anterior.falhou,
        ),
      ),
    );
    unawaited(
      carga.then<void>(
        (pronto) =>
            _terminou(carga, CatalogoEstado(pronto: pronto, carregando: false)),
        onError: (Object _) => _terminou(
          carga,
          const CatalogoEstado(carregando: false, falhou: true),
        ),
      ),
    );
    return carga;
  }

  void _terminou(Future<PieceCatalog> carga, CatalogoEstado catalogo) {
    if (isClosed || !identical(_carga, carga)) return;
    emit(state.copyWith(catalogo: catalogo));
  }

  /// O catálogo da biblioteca em uso: a instalada, ou a embutida, ou nenhum.
  Future<PieceCatalog> _carregar() async {
    final pedido = loadCatalog;
    if (pedido != null) return pedido();
    await libraries.load();
    final id = libraries.state.activeId;
    if (id != null) {
      final package = await libraries.open(id);
      if (package != null) {
        _bibliotecaMostrada = _assinatura();
        return PieceCatalog.fromPackage(package);
      }
    }
    if (aceitaEmbutida) {
      final embutida = await _embutida();
      if (embutida != null) {
        _bibliotecaMostrada = _assinatura();
        return PieceCatalog.fromPackage(embutida);
      }
    }
    _bibliotecaMostrada = _assinatura();
    return const PieceCatalog.none();
  }

  /// Instala e abre a biblioteca embutida (`assets/classicos.zywny`), quando o
  /// app não tem nenhuma. Sem o asset ou sem chave compatível, `null`.
  Future<LibraryPackage?> _embutida() async {
    if (libraries.publicKey == null) return null;
    try {
      final data = await rootBundle.load('assets/classicos.zywny');
      final bytes = Uint8List.sublistView(data);
      final package = await libraries.inspect(bytes);
      try {
        await libraries.install(bytes, inspected: package);
      } on Object {
        // Se não puder persistir no disco agora, ainda mostra o catálogo aberto.
      }
      return package;
    } on Object {
      // Sem o asset ou sem chave: abre vazio em vez de quebrar.
      return null;
    }
  }

  /// Qual biblioteca (e versão) a lista mostra: muda quando a em uso troca, é
  /// substituída ou some.
  String _assinatura() =>
      '${libraries.state.activeId}/${libraries.state.active?.version}';

  /// A biblioteca mostrada mudou desde a última carga.
  bool bibliotecaMudou() => _bibliotecaMostrada != _assinatura();

  /// Anota a biblioteca em uso, se ainda não se sabe qual é (as configurações
  /// perguntam antes de a lista abrir).
  void garantirBibliotecaMostrada() => _bibliotecaMostrada ??= _assinatura();

  // --- As guardas do fluxo -------------------------------------------------

  /// Começa a abrir uma partitura; `false` se já há uma abrindo.
  bool iniciarAbertura() {
    if (_abrindo) return false;
    _abrindo = true;
    return true;
  }

  void terminarAbertura() => _abrindo = false;

  /// Começa a importar um MusicXML; `false` se já há uma importação.
  bool iniciarImportacao() {
    if (_importando) return false;
    _importando = true;
    return true;
  }

  void terminarImportacao() => _importando = false;

  /// O `.zywny` recebido entra na fila, na vez dele.
  void enfileirarPacote(IncomingPackage pacote) => _fila.add(pacote);

  bool get filaVazia => _fila.isEmpty;

  IncomingPackage proximoPacote() => _fila.removeAt(0);

  bool get drenando => _drenando;

  void iniciarDrenagem() => _drenando = true;

  void terminarDrenagem() => _drenando = false;

  /// Há arquivo recebido na fila ou sendo instalado: o passeio cede a vez.
  bool get ocupadoComPacote => _drenando || _fila.isNotEmpty;

  /// `true` só na primeira vez: a fila começa depois da espera da abertura.
  bool marcarPacotePronto() {
    if (_pacoteProntoParaInstalar) return false;
    _pacoteProntoParaInstalar = true;
    return true;
  }

  bool get passeioVerificado => _passeioVerificado;

  void marcarPasseioVerificado() => _passeioVerificado = true;

  void desmarcarPasseioVerificado() => _passeioVerificado = false;

  bool get esperouSplash => _esperouSplash;

  void marcarEsperouSplash() => _esperouSplash = true;
}
