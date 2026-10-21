// Editar os dados de uma música: nome, compositor, letrista e título
// original (nº de catálogo).
//
// Usado na lista da biblioteca (qualquer música) e na confirmação da
// importação de MusicXML (pré-preenchido com o que veio do arquivo). O diálogo
// é puro: mostra os valores de partida, valida e devolve só o que mudou em
// relação a [base]; quem chamou guarda no [PieceMetadataStore] (e apaga a
// importada, quando for o caso).

import 'package:flutter/material.dart';

import 'package:zywny_library/piece.dart';

import 'piece_metadata.dart';

/// O que a pessoa decidiu no diálogo: `null` é "cancelou".
class EditPieceResult {
  const EditPieceResult({required this.meta, this.deleted = false});

  /// Só o que mudou em relação à peça (vazio é "restaurar o original").
  final PieceMetadata meta;

  /// A pessoa mandou apagar a importada (só aparece para importadas).
  final bool deleted;
}

/// Abre o diálogo de edição. [base] é a peça como está hoje (com a edição
/// atual já aplicada); [saved] é a correção guardada, ou `null` sem
/// nenhuma — os campos partem dela, e o que voltar ao valor de [base] sai
/// como "não mudou".
Future<EditPieceResult?> showEditPieceDialog(
  BuildContext context, {
  required Piece base,
  PieceMetadata? saved,
  bool canDelete = false,
}) => showDialog<EditPieceResult>(
  context: context,
  builder: (context) => _EditPieceDialog(
    base: base,
    saved: saved,
    canDelete: canDelete,
  ),
);

class _EditPieceDialog extends StatefulWidget {
  const _EditPieceDialog({
    required this.base,
    required this.saved,
    required this.canDelete,
  });

  final Piece base;
  final PieceMetadata? saved;
  final bool canDelete;

  @override
  State<_EditPieceDialog> createState() => _EditPieceDialogState();
}

class _EditPieceDialogState extends State<_EditPieceDialog> {
  Piece get _base => widget.base;
  PieceMetadata? get _saved => widget.saved;

  String _starting(String? edited, String? current) =>
      edited ?? current ?? '';

  late final TextEditingController _title = TextEditingController(
    text: _starting(_saved?.title, _base.title),
  );
  late final TextEditingController _composer = TextEditingController(
    text: _starting(_saved?.composer, _base.composer),
  );
  late final TextEditingController _lyricist = TextEditingController(
    text: _starting(_saved?.lyricist, _base.lyricist),
  );
  late final TextEditingController _original = TextEditingController(
    text: _starting(_saved?.originalTitle, _base.originalTitle),
  );
  String? _titleError;

  @override
  void dispose() {
    _title.dispose();
    _composer.dispose();
    _lyricist.dispose();
    _original.dispose();
    super.dispose();
  }

  bool get _hasSaved => _saved != null && !_saved!.isEmpty;

  /// Só o que difere de [base]: igual é `null` ("não mudou"); campo opcional
  /// esvaziado é `''` ("limpar").
  PieceMetadata get _diff {
    String? diff(String entered, String? current) {
      final text = entered.trim();
      return text == (current ?? '') ? null : text;
    }

    return PieceMetadata(
      title: diff(_title.text, _base.title),
      composer: diff(_composer.text, _base.composer),
      lyricist: diff(_lyricist.text, _base.lyricist),
      originalTitle: diff(_original.text, _base.originalTitle),
    );
  }

  void _save() {
    if (_title.text.trim().isEmpty) {
      setState(() => _titleError = 'Dê um nome à música.');
      return;
    }
    Navigator.pop(context, EditPieceResult(meta: _diff));
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apagar importada?'),
        content: const Text(
          'A partitura sai do aparelho. O progresso e os ajustes dela '
          'ficam guardados: se você importar de novo, tudo volta.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      Navigator.pop(
        context,
        const EditPieceResult(meta: PieceMetadata(), deleted: true),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar dados da música'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _base.title,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _title,
              autofocus: true,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Nome',
                errorText: _titleError,
              ),
              onChanged: (_) {
                if (_titleError != null) setState(() => _titleError = null);
              },
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _composer,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Compositor'),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _lyricist,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Letrista'),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _original,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Título original',
                helperText: 'Nº de catálogo (Op. 100 nº 2), se houver.',
              ),
              onSubmitted: (_) => _save(),
            ),
          ],
        ),
      ),
      actions: [
        if (widget.canDelete)
          TextButton(
            onPressed: _delete,
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Apagar'),
          ),
        if (_hasSaved)
          TextButton(
            onPressed: () => Navigator.pop(
              context,
              const EditPieceResult(meta: PieceMetadata()),
            ),
            child: const Text('Restaurar'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _save, child: const Text('Salvar')),
      ],
    );
  }
}
