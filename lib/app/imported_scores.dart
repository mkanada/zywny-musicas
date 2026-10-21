// As partituras que a pessoa importou (MusicXML avulso, fora das
// bibliotecas `.zywny`).
//
// Cada importada é um XML puro em [LibraryBlobStore] (`importada-<id>`, o
// mesmo lugar das bibliotecas: arquivo no aparelho, IndexedDB na Web) mais
// uma linha no índice (`imported_scores_v1`, nas preferências) com o nome do
// arquivo e a armadura. Título, compositor e o resto ficam no
// [PieceMetadataStore] (`importado/<id>`), então a edição é a mesma das
// músicas de biblioteca. O progresso e os ajustes usam as mesmas chaves das
// outras músicas — valem enquanto a biblioteca em uso não troca.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zywny_library/library_blob_store.dart';
import 'package:zywny_library/piece.dart';

import 'piece_metadata.dart';

/// A biblioteca (virtual) das importadas: o `libraryId` das peças dela.
const kImportedLibraryId = 'importado';

/// Uma partitura importada, como guardada no índice.
@immutable
class ImportedScore {
  const ImportedScore({
    required this.id,
    required this.fileName,
    this.fifths,
  });

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

  Map<String, Object> toJson() => {
    'id': id,
    'arquivo': fileName,
    'a': ?fifths,
  };

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
}

/// As importadas guardadas: índice nas preferências, XML no [LibraryBlobStore].
/// Avisa quem escuta a cada mudança — a biblioteca mostra a importada na hora.
class ImportedScoresStore extends ChangeNotifier {
  ImportedScoresStore({SharedPreferencesAsync? prefs, LibraryBlobStore? blobs})
    : _prefs = prefs ?? SharedPreferencesAsync(),
      _blobs = blobs ?? createLibraryBlobStore();

  static const indexKey = 'imported_scores_v1';

  final SharedPreferencesAsync _prefs;
  final LibraryBlobStore _blobs;
  final List<ImportedScore> _scores = [];

  List<ImportedScore> get scores => List.unmodifiable(_scores);

  static String _blobKey(String id) => 'importada-$id';

  /// Lê o índice (o XML fica onde está, só é lido ao abrir a partitura).
  Future<void> load() async {
    _scores.clear();
    try {
      final text = await _prefs.getString(indexKey);
      if (text != null) {
        for (final entry in jsonDecode(text) as List<dynamic>) {
          _scores.add(ImportedScore.fromJson(entry as Map<String, dynamic>));
        }
      }
    } on Object {
      // Índice estragado: começa vazio em vez de travar a biblioteca.
      _scores.clear();
    }
    notifyListeners();
  }

  /// Guarda [scoreXml] (XML puro) e entra no índice. O [id] sai do nome do
  /// arquivo, com sufixo quando já existe.
  Future<ImportedScore> add({
    required String fileName,
    required Uint8List scoreXml,
    int? fifths,
  }) async {
    final id = _uniqueId(_slugOf(fileName));
    final score = ImportedScore(id: id, fileName: fileName, fifths: fifths);
    await _blobs.put(_blobKey(id), scoreXml);
    _scores.add(score);
    await _saveIndex();
    notifyListeners();
    return score;
  }

  /// O XML guardado, ou `null` se o arquivo sumiu do aparelho.
  Future<Uint8List?> loadScore(String id) => _blobs.get(_blobKey(id));

  /// Apaga a importada (índice e XML). A edição dela ([PieceMetadataStore]) é
  /// quem chama quem apaga junto — aqui some só a partitura.
  Future<void> remove(String id) async {
    _scores.removeWhere((s) => s.id == id);
    await _blobs.delete(_blobKey(id));
    await _saveIndex();
    notifyListeners();
  }

  Future<void> _saveIndex() => _prefs.setString(
    indexKey,
    jsonEncode([for (final s in _scores) s.toJson()]),
  );

  String _uniqueId(String slug) {
    final taken = {for (final s in _scores) s.id};
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
