// Instalar `.zywny` no zywny-musicas: só bibliotecas (`manifest.json`).
//
// O "Abrir arquivo…" da biblioteca, a seção Bibliotecas das configurações e o
// que o sistema entrega (B11) passam por aqui. Um curso (`course.md`) não se
// instala neste app: o diálogo diz que ele se abre no zywny aprendizado.

import 'dart:async';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:zywny_comum/incoming/incoming_packages.dart';
import 'package:zywny_library/library_envelope.dart';
import 'package:zywny_library/library_installer.dart'
    show installLibraryFromFile, pickLibraryBytes;
import 'package:zywny_library/library_package.dart' show LibraryFormatException;
import 'package:zywny_library/library_store.dart';

/// Que tipo de pacote o zip de dentro descreve.
enum PackageKind { library, course }

/// Separa biblioteca de curso pelo zip **aberto** (sem envelope). Os dois
/// juntos ou nenhum dos dois viram [LibraryFormatException] com a mensagem
/// pronta para a tela.
PackageKind packageKindOfZip(Uint8List zip) {
  final Archive archive;
  try {
    if (zip.length < 4 || zip[0] != 0x50 || zip[1] != 0x4B) {
      throw const FormatException('sem assinatura de zip');
    }
    archive = ZipDecoder().decodeBytes(zip);
  } on Object {
    throw const LibraryFormatException(
      'Este arquivo não é um pacote do zywny (não é um .zip válido).',
    );
  }
  final names = {
    for (final f in archive.files)
      if (f.isFile) f.name,
  };
  final hasCourse = names.contains('course.md');
  final hasLibrary = names.contains('manifest.json');
  if (hasCourse && hasLibrary) {
    throw const LibraryFormatException(
      'Este arquivo tem curso e biblioteca ao mesmo tempo: não vou instalar.',
    );
  }
  if (hasCourse) return PackageKind.course;
  if (hasLibrary) return PackageKind.library;
  throw const LibraryFormatException(
    'Este arquivo não é um pacote do zywny (nem curso, nem biblioteca).',
  );
}

/// Escolher → conferir o tipo → instalar a biblioteca. Devolve a biblioteca
/// instalada, ou `null` se o usuário cancelou ou deu erro (o diálogo já
/// explicou); nesse caso nada foi gravado.
Future<InstalledLibrary?> installPackageFromFile(
  BuildContext context,
  LibraryStore store, {
  Future<Uint8List?> Function() pick = pickLibraryBytes,
}) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  final Uint8List? bytes;
  try {
    bytes = await pick();
  } on Object catch (e) {
    await _showError(navigator, 'Não consegui abrir o seletor de arquivos: $e');
    return null;
  }
  if (bytes == null) return null;
  if (!navigator.mounted) return null;
  return _installBytes(navigator.context, store, bytes);
}

/// O pacote que o sistema entregou ao app (B11: clique duplo, "Abrir com…"):
/// o mesmo fluxo do "Abrir arquivo…", sem o seletor.
Future<InstalledLibrary?> installIncomingPackage(
  BuildContext context,
  LibraryStore store,
  IncomingPackage package,
) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  final Uint8List bytes;
  try {
    bytes = await package.read();
  } on Object catch (e) {
    if (!navigator.mounted) return null;
    await _showError(
      navigator,
      'Não consegui ler "${package.name}": $e',
      title: 'Não deu para abrir o arquivo',
    );
    return null;
  }
  if (!navigator.mounted) return null;
  return _installBytes(navigator.context, store, bytes);
}

/// Confere o tipo do pacote e instala a biblioteca. Curso não é instalado
/// aqui: o diálogo manda abri-lo no aprendizado.
Future<InstalledLibrary?> _installBytes(
  BuildContext context,
  LibraryStore store,
  Uint8List bytes,
) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  final PackageKind kind;
  try {
    final key = store.publicKey;
    if (key == null) {
      throw const LibraryFormatException(
        'Este app foi compilado sem a chave das bibliotecas: não consigo '
        'abrir nenhum pacote.',
      );
    }
    kind = packageKindOfZip(await LibraryEnvelope.open(bytes, key));
  } on LibraryFormatException catch (e) {
    await _showError(navigator, e.message);
    return null;
  }
  if (!navigator.mounted) return null;
  return switch (kind) {
    PackageKind.library => installLibraryFromFile(
      navigator.context,
      store,
      pick: () async => bytes,
    ),
    PackageKind.course => _refuseCourse(navigator),
  };
}

Future<InstalledLibrary?> _refuseCourse(NavigatorState navigator) async {
  await _showError(
    navigator,
    'Este app instala bibliotecas de músicas. Os cursos ficam no zywny '
    'aprendizado: abra o arquivo por lá.',
    title: 'Este é um curso: abra no zywny aprendizado',
  );
  return null;
}

Future<void> _showError(
  NavigatorState navigator,
  String message, {
  String title = 'Não deu para instalar',
}) {
  return showDialog<void>(
    context: navigator.context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
