// Sobrescritas locais dos dados de cada música (nome, compositor, letrista,
// título original).
//
// O pacote `.zywny` é assinado e só de leitura: o que a pessoa corrige aqui
// não volta para ele. Cada correção fica em `SharedPreferences`
// (`piece_meta_<biblioteca>_<id>`) e é aplicada por cima do catálogo ao
// mostrar a lista, a busca, a ordenação e a partitura — como o progresso e os
// ajustes, sobrevive a reinstalar a biblioteca (D-BIB-REMOVER).

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zywny_bloc/zywny_bloc.dart';

import 'package:zywny_library/piece.dart';

/// Chave do que foi corrigido em [pieceId] de [libraryId].
String pieceMetaKeyFor(String libraryId, String pieceId) =>
    'piece_meta_${libraryId}_$pieceId';

/// O que a pessoa mudou nos dados de uma música. Campo `null` é "igual ao
/// do pacote"; string vazia num campo opcional é "limpar" (voltar a não ter).
/// Nos obrigatórios (nome, compositor), vazio vale como igual — o diálogo
/// nem deixa salvar sem nome.
@immutable
class PieceMetadata {
  const PieceMetadata({
    this.title,
    this.composer,
    this.lyricist,
    this.originalTitle,
  });

  /// Nenhum campo tocado: não há o que guardar.
  bool get isEmpty =>
      title == null &&
      composer == null &&
      lyricist == null &&
      originalTitle == null;

  final String? title;
  final String? composer;
  final String? lyricist;

  /// Nº de catálogo ("Op. 100 nº 2"), quando houver.
  final String? originalTitle;

  factory PieceMetadata.fromJson(Map<String, dynamic> json) => PieceMetadata(
    title: _raw(json['t']),
    composer: _raw(json['c']),
    lyricist: _raw(json['l']),
    originalTitle: _raw(json['o']),
  );

  /// Ausente (ou não-texto) é "igual ao pacote"; presente, mesmo vazio, é
  /// uma decisão da pessoa (vazio no opcional = limpar).
  static String? _raw(Object? value) => value is String ? value.trim() : null;

  Map<String, Object> toJson() => {
    'v': 1,
    if (title != null) 't': title!.trim(),
    if (composer != null) 'c': composer!.trim(),
    if (lyricist != null) 'l': lyricist!.trim(),
    if (originalTitle != null) 'o': originalTitle!.trim(),
  };

  /// A peça com as correções aplicadas (e as chaves de busca refeitas, para
  /// a ordenação e a busca enxergarem o texto novo). [piece] sai intacta.
  Piece applyTo(Piece piece) {
    if (isEmpty) return piece;
    final rawTitle = this.title?.trim();
    final rawComposer = this.composer?.trim();
    final title = rawTitle == null || rawTitle.isEmpty ? piece.title : rawTitle;
    final composer = rawComposer == null || rawComposer.isEmpty
        ? piece.composer
        : rawComposer;
    final lyricist = this.lyricist == null
        ? piece.lyricist
        : _nullIfEmpty(this.lyricist);
    final originalTitle = this.originalTitle == null
        ? piece.originalTitle
        : _nullIfEmpty(this.originalTitle);
    return Piece(
      libraryId: piece.libraryId,
      id: piece.id,
      number: piece.number,
      title: title,
      composer: composer,
      lyricist: lyricist,
      originalTitle: originalTitle,
      hasSimplified: piece.hasSimplified,
      simplified: piece.simplified,
      fifths: piece.fifths,
      titleKey: foldForSearch(title),
      composerKey: foldForSearch(composer),
      searchKey: foldForSearch(
        '${piece.number ?? ''} $title ${originalTitle ?? ''} '
        '$composer ${lyricist ?? ''}',
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PieceMetadata &&
      other.title?.trim() == title?.trim() &&
      other.composer?.trim() == composer?.trim() &&
      other.lyricist?.trim() == lyricist?.trim() &&
      other.originalTitle?.trim() == originalTitle?.trim();

  @override
  int get hashCode => Object.hash(
    title?.trim(),
    composer?.trim(),
    lyricist?.trim(),
    originalTitle?.trim(),
  );

  static String? _nullIfEmpty(String? text) {
    final trimmed = text?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}

/// As correções de todas as bibliotecas (a em uso mais a das importadas), por
/// chave ([pieceMetaKeyFor]). Imutável: o mapa é outro a cada mudança.
class PieceMetadataState extends Equatable {
  const PieceMetadataState({this.byKey = const {}});

  /// Chave (`piece_meta_<biblioteca>_<id>`) → a correção.
  final Map<String, PieceMetadata> byKey;

  @override
  List<Object?> get props => [byKey];
}

/// As correções de várias bibliotecas ao mesmo tempo (a em uso mais a das
/// importadas): cada biblioteca tem a sua chave, então [load] só atualiza as
/// músicas pedidas, sem apagar as outras. Avisa quem escuta (`stream`) a cada
/// mudança — a lista refaz os títulos na hora.
///
/// BL12: `PieceMetadataStore` (um `ChangeNotifier`) virou este Cubit. Quem
/// muda emite antes de gravar: a correção já vale na tela, e o `Future` de
/// [save] e [clear] só fica pronto depois da gravação.
class PieceMetadataCubit extends Cubit<PieceMetadataState> {
  PieceMetadataCubit({SharedPreferencesAsync? prefs})
    : _prefs = prefs ?? SharedPreferencesAsync(),
      super(const PieceMetadataState());

  final SharedPreferencesAsync _prefs;

  /// A correção de [pieceId] em [libraryId], ou `null` sem nenhuma.
  PieceMetadata? get(String libraryId, String pieceId) =>
      state.byKey[pieceMetaKeyFor(libraryId, pieceId)];

  /// Lê as correções de [pieceIds] em [libraryId] (as que já estavam na
  /// memória para outras bibliotecas ficam).
  Future<void> load(String libraryId, Iterable<String> pieceIds) async {
    final lidas = <String, PieceMetadata?>{};
    for (final id in pieceIds) {
      final key = pieceMetaKeyFor(libraryId, id);
      PieceMetadata? meta;
      try {
        final text = await _prefs.getString(key);
        if (text != null) {
          meta = PieceMetadata.fromJson(
            jsonDecode(text) as Map<String, dynamic>,
          );
        }
      } on Object {
        meta = null;
      }
      lidas[key] = meta == null || meta.isEmpty ? null : meta;
    }
    if (isClosed) return;
    final novo = {...state.byKey};
    lidas.forEach((key, meta) {
      if (meta == null) {
        novo.remove(key);
      } else {
        novo[key] = meta;
      }
    });
    _emitir(novo);
  }

  /// Guarda a correção (vazia é o mesmo que [clear]). Emite antes de gravar.
  Future<void> save(String libraryId, String pieceId, PieceMetadata meta) {
    if (meta.isEmpty) return clear(libraryId, pieceId);
    final key = pieceMetaKeyFor(libraryId, pieceId);
    _emitir({...state.byKey, key: meta});
    return _prefs.setString(key, jsonEncode(meta.toJson()));
  }

  /// Volta a música aos dados do pacote. Emite antes de gravar.
  Future<void> clear(String libraryId, String pieceId) {
    final key = pieceMetaKeyFor(libraryId, pieceId);
    if (state.byKey.containsKey(key)) {
      _emitir({...state.byKey}..remove(key));
    }
    return _prefs.remove(key);
  }

  /// As [pieces] de [libraryId] com as correções aplicadas.
  List<Piece> applyAll(String libraryId, Iterable<Piece> pieces) => [
    for (final p in pieces) get(libraryId, p.id)?.applyTo(p) ?? p,
  ];

  void _emitir(Map<String, PieceMetadata> byKey) {
    if (isClosed) return;
    emit(PieceMetadataState(byKey: Map.unmodifiable(byKey)));
  }
}
