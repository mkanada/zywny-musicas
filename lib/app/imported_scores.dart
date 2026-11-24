// As partituras que a pessoa importou (MusicXML avulso, fora das
// bibliotecas `.zywny`).
//
// Cada importada é um XML puro em [LibraryBlobStore] (`importada-<id>`, o
// mesmo lugar das bibliotecas: arquivo no aparelho, IndexedDB na Web) mais
// uma linha no índice (`imported_scores_v1`, nas preferências) com o nome do
// arquivo e a armadura. Título, compositor e o resto ficam no
// [PieceMetadataCubit] (`importado/<id>`), então a edição é a mesma das
// músicas de biblioteca. O progresso e os ajustes usam as mesmas chaves das
// outras músicas — valem enquanto a biblioteca em uso não troca.
//
// BL12: `ImportedScoresStore` (um `ChangeNotifier`) virou [ImportedScoresCubit]:
// a lista das importadas é o [ImportedScoresState].

import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:zywny_bloc/zywny_bloc.dart';

import 'package:zywny_library/library_blob_store.dart';
import 'package:zywny_library/piece.dart';

import 'piece_metadata.dart';

/// A biblioteca (virtual) das importadas: o `libraryId` das peças dela.
const kImportedLibraryId = 'importado';

/// Uma partitura importada, como guardada no índice.
class ImportedScore extends Equatable {
  const ImportedScore({required this.id, required this.fileName, this.fifths});

  factory ImportedScore.fromJson(Map<String, dynamic> json) => ImportedScore(
    id: json['id'] as String,
    fileName: json['arquivo'] as String? ?? 'musica.musicxml',
    fifths: json['a'] as int?,
  );

  final String id;

  /// O nome do arquivo importado (`fur-elise.musicxml`).
  final String fileName;

  /// Armadura do início, como no MusicXML (`null` sem ela no arquivo).
  final int? fifths;

  Map<String, Object> toJson() => {'id': id, 'arquivo': fileName, 'a': ?fifths};

  /// A peça para a lista e a partitura: os dados do [override] (a edição da
  /// pessoa) valem; sem ele, o nome do arquivo.
  Piece toPiece(PieceMetadata? override) {
    final stem = _stemOf(fileName);
    final cleanTitle = override?.title?.trim();
    final cleanComposer = override?.composer?.trim();
    final title = cleanTitle == null || cleanTitle.isEmpty ? stem : cleanTitle;
    final composer = cleanComposer == null || cleanComposer.isEmpty
        ? ''
        : cleanComposer;
    final lyricist = _nullIfEmpty(override?.lyricist);
    final originalTitle = _nullIfEmpty(override?.originalTitle);
    return Piece(
      libraryId: kImportedLibraryId,
      id: id,
      title: title,
      composer: composer,
      lyricist: lyricist,
      originalTitle: originalTitle,
      fifths: fifths,
      titleKey: foldForSearch(title),
      composerKey: foldForSearch(composer),
      searchKey: foldForSearch('$title $composer ${lyricist ?? ''} $stem'),
    );
  }

  static String _stemOf(String name) {
    final base = name.split(RegExp(r'[/\\]')).last;
    final dot = base.lastIndexOf('.');
    final stem = (dot <= 0 ? base : base.substring(0, dot)).trim();
    return stem.isEmpty ? 'Música importada' : stem;
  }

  static String? _nullIfEmpty(String? text) {
    final trimmed = text?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  @override
  List<Object?> get props => [id, fileName, fifths];
}

/// As importadas guardadas, na ordem do índice. Imutável: a lista é outra a
/// cada mudança.
class ImportedScoresState extends Equatable {
  const ImportedScoresState({this.scores = const []});

  /// As importadas (lista só de leitura).
  final List<ImportedScore> scores;

  @override
  List<Object?> get props => [scores];
}

/// As importadas guardadas: índice nas preferências, XML no [LibraryBlobStore].
/// Avisa quem escuta (`stream`) a cada mudança — a biblioteca mostra a
/// importada na hora.
class ImportedScoresCubit extends Cubit<ImportedScoresState> {
  ImportedScoresCubit({SharedPreferencesAsync? prefs, LibraryBlobStore? blobs})
    : _prefs = prefs ?? SharedPreferencesAsync(),
      _blobs = blobs ?? createLibraryBlobStore(),
      super(const ImportedScoresState());

  static const indexKey = 'imported_scores_v1';

  final SharedPreferencesAsync _prefs;
  final LibraryBlobStore _blobs;

  /// As importadas, na ordem do índice (o que está no [state]).
  List<ImportedScore> get scores => state.scores;

  static String _blobKey(String id) => 'importada-$id';

  /// Lê o índice (o XML fica onde está, só é lido ao abrir a partitura).
  Future<void> load() async {
    var lidas = <ImportedScore>[];
    try {
      final text = await _prefs.getString(indexKey);
      if (text != null) {
        lidas = [
          for (final entry in jsonDecode(text) as List<dynamic>)
            ImportedScore.fromJson(entry as Map<String, dynamic>),
        ];
      }
    } on Object {
      // Índice estragado: começa vazio em vez de travar a biblioteca.
      lidas = [];
    }
    _emitir(lidas);
  }

  /// Guarda [scoreXml] (XML puro) e entra no índice. O [id] sai do nome do
  /// arquivo, com sufixo quando já existe.
  ///
  /// O XML é gravado antes de a entrada aparecer: a lista só mostra o que tem
  /// arquivo. O índice é gravado depois da emissão.
  Future<ImportedScore> add({
    required String fileName,
    required Uint8List scoreXml,
    int? fifths,
  }) async {
    final id = _uniqueId(_slugOf(fileName));
    final score = ImportedScore(id: id, fileName: fileName, fifths: fifths);
    await _blobs.put(_blobKey(id), scoreXml);
    final novas = [...state.scores, score];
    _emitir(novas);
    await _gravarIndice(novas);
    return score;
  }

  /// O XML guardado, ou `null` se o arquivo sumiu do aparelho.
  Future<Uint8List?> loadScore(String id) => _blobs.get(_blobKey(id));

  /// Apaga a importada (índice e XML). A edição dela ([PieceMetadataCubit]) é
  /// quem chama quem apaga junto — aqui some só a partitura.
  Future<void> remove(String id) async {
    final restantes = [
      for (final s in state.scores)
        if (s.id != id) s,
    ];
    _emitir(restantes);
    await _blobs.delete(_blobKey(id));
    await _gravarIndice(restantes);
  }

  /// Emite a lista nova (síncrono, antes de qualquer gravação). Depois de
  /// [close] não emite.
  void _emitir(List<ImportedScore> lista) {
    if (isClosed) return;
    emit(ImportedScoresState(scores: List.unmodifiable(lista)));
  }

  Future<void> _gravarIndice(List<ImportedScore> lista) => _prefs.setString(
    indexKey,
    jsonEncode([for (final s in lista) s.toJson()]),
  );

  String _uniqueId(String slug) {
    final taken = {for (final s in state.scores) s.id};
    var id = slug;
    var n = 2;
    while (taken.contains(id)) {
      id = '$slug-$n';
      n++;
    }
    return id;
  }

  /// `Für Elise.mxl` → `xml-fur-elise` (só o que o id de peça aceita).
  static String _slugOf(String fileName) {
    final base = fileName.split(RegExp(r'[/\\]')).last;
    final dot = base.lastIndexOf('.');
    final stem = dot <= 0 ? base : base.substring(0, dot);
    var slug = foldForSearch(stem).replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    slug = slug.replaceAll(RegExp(r'^-+|-+$'), '');
    if (slug.isEmpty) slug = 'musica';
    if (slug.length > 40) slug = slug.substring(0, 40);
    return 'xml-${slug.replaceAll(RegExp(r'-+$'), '')}';
  }
}
