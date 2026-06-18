import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/providers.dart';
import '../widgets/confirm_dialog.dart';

/// Exportar e importar todos los datos en un archivo JSON.
class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _busy = false;

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      final now = DateTime.now();
      final json = await ref.read(backupServiceProvider).exportJson(now: now);
      final stamp = DateFormat('yyyy-MM-dd').format(now);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/billetera-backup-$stamp.json');
      await file.writeAsString(json);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/json')],
          subject: 'Copia de seguridad de Billetera',
        ),
      );
    } catch (e) {
      _toast('No se pudo exportar: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    const group = XTypeGroup(label: 'JSON', extensions: ['json']);
    final file = await openFile(acceptedTypeGroups: [group]);
    if (file == null || !mounted) return;

    final ok = await confirmDialog(
      context,
      title: '¿Restaurar esta copia?',
      message: 'Se BORRARÁN todos los datos actuales (cuentas, movimientos, '
          'presupuestos…) y se reemplazarán por los del archivo. No se puede '
          'deshacer.',
      confirmLabel: 'Restaurar',
    );
    if (!ok) return;

    setState(() => _busy = true);
    try {
      final raw = await file.readAsString();
      await ref.read(backupServiceProvider).importJson(raw);
      _toast('Copia restaurada correctamente.');
    } on FormatException catch (e) {
      _toast(e.message);
    } catch (e) {
      _toast('No se pudo importar: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Copia de seguridad')),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Guarda todos tus datos en un archivo o restaura una copia para '
                'cambiar de teléfono o tras reinstalar.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.upload_file),
                  title: const Text('Exportar copia'),
                  subtitle: const Text('Genera un .json y lo comparte'),
                  onTap: _busy ? null : _export,
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.download),
                  title: const Text('Importar copia'),
                  subtitle: const Text('Reemplaza tus datos por los del archivo'),
                  onTap: _busy ? null : _import,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'La copia debe ser de esta misma versión de la app.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.outline),
              ),
            ],
          ),
          if (_busy)
            const ColoredBox(
              color: Color(0x66000000),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
