// Importar MusicXML: validação e extração dos dados.
import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart' show Uint8List;
import 'package:flutter_test/flutter_test.dart';

import 'package:zywny/app/musicxml_import.dart';

const _score = '''
<?xml version="1.0" encoding="UTF-8"?>
<score-partwise version="3.1">
  <work><work-title>Für Elise &amp; Amigos</work-title></work>
  <identification>
    <creator type="composer">Ludwig van Beethoven</creator>
    <creator type="lyricist">Ninguém</creator>
  </identification>
  <part-list><score-part id="P1"><part-name>Piano</part-name></score-part></part-list>
  <part id="P1"><measure number="1"><attributes><key><fifths>-3</fifths></key></attributes></measure></part>
</score-partwise>
''';

Uint8List _bytes(String text) => Uint8List.fromList(utf8.encode(text));

Uint8List _mxl(String innerName, String inner) {
  final archive = Archive()
    ..add(ArchiveFile.bytes('META-INF/container.xml', utf8.encode(inner)))
    ..add(ArchiveFile.bytes(innerName, utf8.encode(inner)));
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

const _container =
    '<?xml version="1.0"?><container><rootfiles>'
    '<rootfile full-path="partitura.musicxml"/>'
    '</rootfiles></container>';

void main() {
  group('parseMusicXml', () {
    test('lê título, autores e armadura', () {
      final parsed = parseMusicXml('fur-elise.musicxml', _bytes(_score));
      expect(parsed.title, 'Für Elise & Amigos');
      expect(parsed.composer, 'Ludwig van Beethoven');
      expect(parsed.lyricist, 'Ninguém');
      expect(parsed.fifths, -3);
      expect(parsed.fileName, 'fur-elise.musicxml');
    });

    test('movement-title vale mais que work-title', () {
      const xml = '<score-partwise><movement-title>Mov</movement-title>'
          '<work><work-title>Work</work-title></work></score-partwise>';
      expect(parseMusicXml('a.musicxml', _bytes(xml)).title, 'Mov');
    });

    test('sem cabeçalho, vale o título da primeira página', () {
      const xml = '<score-partwise><credit><credit-type>title</credit-type>'
          '<credit-words>Na Página</credit-words></credit></score-partwise>';
      expect(parseMusicXml('a.musicxml', _bytes(xml)).title, 'Na Página');
    });

    test('sem título nenhum, vale o nome do arquivo', () {
      const xml = '<score-partwise><part-list/></score-partwise>';
      final parsed = parseMusicXml('minha-musica.musicxml', _bytes(xml));
      expect(parsed.title, 'minha-musica');
      expect(parsed.composer, isNull);
      expect(parsed.fifths, isNull);
    });

    test('aceita score-timewise', () {
      const xml = '<score-timewise version="3.1"></score-timewise>';
      expect(
        parseMusicXml('a.musicxml', _bytes(xml)).title,
        'a',
      );
    });

    test('.mxl descompacta e guarda XML puro', () {
      final bytes = _mxl('peca.musicxml', _score);
      final parsed = parseMusicXml('peca.mxl', bytes);
      expect(parsed.title, 'Für Elise & Amigos');
      expect(parsed.fileName, 'peca.musicxml');
      final text = String.fromCharCodes(parsed.scoreXml);
      expect(text.contains('<score-partwise'), isTrue);
    });

    test('.mxl segue o rootfile do container', () {
      final archive = Archive()
        ..add(
          ArchiveFile.bytes(
            'META-INF/container.xml',
            utf8.encode(_container),
          ),
        )
        ..add(ArchiveFile.bytes('outra.musicxml', utf8.encode(_score)))
        ..add(
          ArchiveFile.bytes(
            'partitura.musicxml',
            utf8.encode('<score-partwise/>'),
          ),
        );
      final bytes = Uint8List.fromList(ZipEncoder().encode(archive));
      final parsed = parseMusicXml('x.mxl', bytes);
      expect(parsed.fileName, 'x.musicxml');
    });

    group('recusa com mensagem pronta para a tela', () {
      test('vazio', () {
        expect(
          () => parseMusicXml('a.musicxml', Uint8List(0)),
          throwsA(
            isA<MusicXmlFormatException>().having(
              (e) => e.message,
              'message',
              contains('vazio'),
            ),
          ),
        );
      });

      test('não é XML de partitura', () {
        expect(
          () => parseMusicXml('letra.txt', _bytes('só uma letra de música')),
          throwsA(isA<MusicXmlFormatException>()),
        );
      });

      test('zip sem partitura dentro', () {
        final bytes = Uint8List.fromList(
          ZipEncoder().encode(
            Archive()..add(ArchiveFile.bytes('foto.png', [1, 2, 3])),
          ),
        );
        expect(
          () => parseMusicXml('a.mxl', bytes),
          throwsA(isA<MusicXmlFormatException>()),
        );
      });

      test('zip quebrado com nome .mxl', () {
        expect(
          () => parseMusicXml(
            'a.mxl',
            Uint8List.fromList([0x50, 0x4B, 0x03, 0x04, 1, 2, 3]),
          ),
          throwsA(isA<MusicXmlFormatException>()),
        );
      });
    });
  });
}
