// Importar MusicXML (`.musicxml` avulso ou `.mxl` comprimido): escolher o
// arquivo, validar que é uma partitura e extrair os dados (título,
// compositor) para a confirmação antes de abrir.
//
// Só lê — nada de disco, disco ou rede: quem guarda é o [ImportedScoresStore]
// e quem abre é a biblioteca. O `.mxl` é descompactado aqui, então o resto do
// app só lida com XML puro (o Verovio recebe sempre `.musicxml`).

import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform, Uint8List;

/// Erro de leitura de um MusicXML; [message] já está em português, pronta
/// para a tela.
class MusicXmlFormatException implements Exception {
  const MusicXmlFormatException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// O seletor do arquivo (`.musicxml`, `.mxl`); `null` se a pessoa cancelou.
// Os testes trocam por um falso.
typedef PickMusicXmlFile = Future<({String name, Uint8List bytes})?> Function();

/// Abre o seletor para um `.musicxml`/`.mxl` e devolve nome e bytes. No
/// Android não se filtra por extensão (como o `.zywny`: sem MIME conhecido o
/// arquivo nem apareceria) e a validação é quem recusa o que não serve.
Future<({String name, Uint8List bytes})?> pickMusicXmlFile() async {
  final file = await openFile(
    acceptedTypeGroups: [
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android
          ? const XTypeGroup(label: 'partitura')
          : const XTypeGroup(
              label: 'partitura',
              extensions: ['musicxml', 'mxl', 'xml'],
            ),
    ],
  );
  if (file == null) return null;
  return (name: file.name, bytes: await file.readAsBytes());
}

/// Um MusicXML válido e pronto para guardar: o XML puro, o nome para o
/// renderizador e os dados que vieram dele (`null` onde não havia).
class ParsedMusicXml {
  const ParsedMusicXml({
    required this.fileName,
    required this.scoreXml,
    required this.title,
    this.composer,
    this.lyricist,
    this.fifths,
  });

  /// Sempre termina em `.musicxml` (o `.mxl` já vem descompactado).
  final String fileName;

  /// O XML em UTF-8, como o Verovio recebe.
  final Uint8List scoreXml;
  final String title;
  final String? composer;
  final String? lyricist;
  final int? fifths;
}

/// Confere [bytes] ([name] é só para as mensagens) e devolve o XML com os
/// dados. Qualquer problema vira [MusicXmlFormatException].
ParsedMusicXml parseMusicXml(String name, Uint8List bytes) {
  if (bytes.isEmpty) {
    throw const MusicXmlFormatException('O arquivo está vazio.');
  }
  final stem = _stemOf(name);
  final String xml;
  if (_isZip(bytes)) {
    xml = _extractMxl(bytes, name);
  } else {
    xml = _decode(bytes, name);
    if (!_isScore(xml)) {
      throw MusicXmlFormatException(
        '"$name" não é um MusicXML válido: não achei '
        '<score-partwise> nem <score-timewise> nele.',
      );
    }
  }
  return ParsedMusicXml(
    fileName: '$stem.musicxml',
    scoreXml: Uint8List.fromList(utf8.encode(xml)),
    title:
        _firstTag(xml, 'movement-title') ??
        _firstTag(xml, 'work-title') ??
        _creditTitle(xml) ??
        stem,
    composer: _firstCreator(xml, 'composer'),
    lyricist: _firstCreator(xml, 'lyricist') ?? _firstCreator(xml, 'poet'),
    fifths: _firstFifths(xml),
  );
}

bool _isZip(Uint8List bytes) =>
    bytes.length >= 4 &&
    bytes[0] == 0x50 &&
    bytes[1] == 0x4B &&
    bytes[2] == 0x03 &&
    bytes[3] == 0x04;

/// O XML de dentro do `.mxl`: o `rootfile` do `META-INF/container.xml`, ou o
/// primeiro `.musicxml` (`.xml`, em último caso) do zip.
String _extractMxl(Uint8List bytes, String name) {
  final Archive archive;
  try {
    archive = ZipDecoder().decodeBytes(bytes);
  } catch (_) {
    throw MusicXmlFormatException('"$name" não é um .mxl válido.');
  }
  final files = [for (final f in archive) if (f.isFile) f];
  if (files.isEmpty) {
    throw MusicXmlFormatException('"$name" está vazio por dentro.');
  }
  ArchiveFile? pick(String suffix) => files
      .where((f) => f.name.toLowerCase().endsWith(suffix))
      .firstOrNull;
  final root = _containerRoot(files);
  ArchiveFile? entry = root == null
      ? null
      : files.where((f) => f.name == root).firstOrNull;
  entry ??= pick('.musicxml') ?? pick('.xml');
  if (entry == null || entry.name.toLowerCase().endsWith('container.xml')) {
    throw MusicXmlFormatException(
      '"$name" não tem partitura dentro (esperava um .musicxml).',
    );
  }
  final xml = _decode(entry.content as List<int>, name);
  if (!_isScore(xml)) {
    throw MusicXmlFormatException(
      '"$name" não tem uma partitura MusicXML dentro.',
    );
  }
  return xml;
}

/// O caminho do `rootfile` em `META-INF/container.xml`, ou `null` sem ele (o
/// primeiro `.musicxml` vale, então).
String? _containerRoot(List<ArchiveFile> files) {
  final container = files
      .where((f) => f.name.toLowerCase().endsWith('container.xml'))
      .firstOrNull;
  if (container == null) return null;
  final text = utf8.decode(
    container.content as List<int>,
    allowMalformed: true,
  );
  final match = RegExp(
    '<rootfile[^>]*full-path\\s*=\\s*"([^"]+)"',
    dotAll: true,
  ).firstMatch(text);
  return match?.group(1)?.trim();
}

String _decode(List<int> bytes, String name) {
  try {
    final text = utf8.decode(bytes);
    return text.startsWith('\uFEFF') ? text.substring(1) : text;
  } on FormatException {
    throw MusicXmlFormatException(
      'Não consegui ler "$name": não é um texto válido (esperava UTF-8).',
    );
  }
}

bool _isScore(String xml) =>
    xml.contains('<score-partwise') || xml.contains('<score-timewise');

String _stemOf(String name) {
  final base = name.split(RegExp(r'[/\\]')).last;
  final dot = base.lastIndexOf('.');
  final stem = (dot <= 0 ? base : base.substring(0, dot)).trim();
  return stem.isEmpty ? 'musica' : stem;
}

/// O conteúdo do primeiro `<tag>…</tag>`, limpo — ou `null` sem ele.
String? _firstTag(String xml, String tag) {
  final match = RegExp(
    '<$tag\\b[^>]*>(.*?)</$tag>',
    dotAll: true,
  ).firstMatch(xml);
  final text = _clean(match?.group(1));
  return text == null || text.isEmpty ? null : text;
}

/// O primeiro `<creator …type="kind"…>…</creator>`.
String? _firstCreator(String xml, String kind) {
  for (final match in RegExp(
    '<creator\\b([^>]*)>(.*?)</creator>',
    dotAll: true,
  ).allMatches(xml)) {
    final attrs = match.group(1) ?? '';
    if (!RegExp(
      'type\\s*=\\s*["\']?$kind["\']?',
      caseSensitive: false,
    ).hasMatch(attrs)) {
      continue;
    }
    final text = _clean(match.group(2));
    if (text != null && text.isNotEmpty) return text;
  }
  return null;
}

/// O `<credit-words>` do bloco `<credit-type>title</credit-type>` (o título
/// gravado na primeira página, quando o cabeçalho não o traz).
String? _creditTitle(String xml) {
  final blocks = RegExp(
    '<credit\\b[^>]*>(.*?)</credit>',
    dotAll: true,
  ).allMatches(xml);
  for (final block in blocks) {
    final body = block.group(1) ?? '';
    if (!RegExp(
      '<credit-type>\\s*title\\s*</credit-type>',
    ).hasMatch(body)) {
      continue;
    }
    final words = RegExp(
      '<credit-words\\b[^>]*>(.*?)</credit-words>',
      dotAll: true,
    ).allMatches(body).map((m) => _clean(m.group(1))).where(
      (w) => w != null && w.isNotEmpty,
    );
    final title = words.join(' ').trim();
    if (title.isNotEmpty) return title;
  }
  return null;
}

/// A armadura do início (`<fifths>` do primeiro compasso), ou `null` sem ela.
int? _firstFifths(String xml) {
  final match = RegExp(
    '<fifths>\\s*(-?\\d+)\\s*</fifths>',
  ).firstMatch(xml);
  return match == null ? null : int.tryParse(match.group(1)!);
}

/// Tira as marcas do XML, junta as quebras de linha e desfaz as entidades
/// (`&amp;`, `&lt;`…).
String? _clean(String? raw) {
  if (raw == null) return null;
  var text = raw.replaceAll(RegExp(r'<[^>]*>'), '');
  text = text.replaceAllMapped(RegExp(r'&#(\d+);'), (m) {
    final code = int.tryParse(m.group(1)!);
    return code == null ? m[0]! : String.fromCharCode(code);
  });
  text = text.replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (m) {
    final code = int.tryParse(m.group(1)!, radix: 16);
    return code == null ? m[0]! : String.fromCharCode(code);
  });
  for (final entity in const {
    '&amp;': '&',
    '&lt;': '<',
    '&gt;': '>',
    '&quot;': '"',
    '&apos;': "'",
  }.entries) {
    text = text.replaceAll(entity.key, entity.value);
  }
  text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  return text;
}
