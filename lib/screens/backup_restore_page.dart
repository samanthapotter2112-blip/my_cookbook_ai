import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/backup_service.dart';
import '../services/web_download_service.dart';

class BackupRestorePage extends StatefulWidget {
  const BackupRestorePage({super.key});

  @override
  State<BackupRestorePage> createState() =>
      _BackupRestorePageState();
}

class _BackupRestorePageState
    extends State<BackupRestorePage> {
  bool isCreatingBackup = false;
  bool isRestoringBackup = false;

  Future<void> createBackup() async {
  if (isCreatingBackup ||
      isRestoringBackup) {
    return;
  }

  setState(() {
    isCreatingBackup = true;
  });

  try {
    final Map<String, dynamic> backup =
        await BackupService.createBackup();

    final String jsonText =
        BackupService.backupToJson(
      backup,
    );

    final Uint8List backupBytes =
        Uint8List.fromList(
      utf8.encode(jsonText),
    );

    final DateTime now =
        DateTime.now();

    final String dateText =
        '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';

    WebDownloadService.downloadFile(
      bytes: backupBytes,
      fileName:
          'my_cookbook_backup_$dateText.json',
      mimeType: 'application/json',
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Backup downloaded successfully.',
        ),
      ),
    );
  } catch (error) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          'Could not create backup: $error',
        ),
      ),
    );
  } finally {
    if (mounted) {
      setState(() {
        isCreatingBackup = false;
      });
    }
  }
}

  Future<void> chooseBackupToRestore() async {
    if (isCreatingBackup || isRestoringBackup) {
      return;
    }

    final bool? shouldContinue =
        await showDialog<bool>(
      context: context,
      builder: (
        BuildContext dialogContext,
      ) {
        return AlertDialog(
          title: const Text(
            'Restore backup?',
          ),
          content: const Text(
            'Restoring will replace the app data '
            'contained in the backup, including '
            'cookbooks, recipes, meal plans, '
            'shopping lists and collections.\n\n'
            'It is a good idea to create a new '
            'backup first.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Choose Backup',
              ),
            ),
          ],
        );
      },
    );

    if (shouldContinue != true || !mounted) {
      return;
    }

    await restoreBackup();
  }

  Future<void> restoreBackup() async {
    setState(() {
      isRestoringBackup = true;
    });

    try {
      final FilePickerResult? result =
          await FilePicker.platform.pickFiles(
        dialogTitle: 'Choose cookbook backup',
        type: FileType.custom,
        allowedExtensions: <String>[
          'json',
        ],
        allowMultiple: false,
        withData: true,
      );

      if (result == null) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Restore cancelled.',
            ),
          ),
        );

        return;
      }

      final Uint8List? backupBytes =
          result.files.single.bytes;

      if (backupBytes == null) {
        throw const FormatException(
          'The selected backup could not be read.',
        );
      }

      final String jsonText =
          utf8.decode(backupBytes);

      final Map<String, dynamic> backup =
          BackupService.backupFromJson(
        jsonText,
      );

      validateBackup(backup);

      await BackupService.restoreBackup(
        backup,
      );

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (
          BuildContext dialogContext,
        ) {
          return AlertDialog(
            title: const Text(
              'Backup restored',
            ),
            content: const Text(
              'Your cookbook library has been '
              'restored successfully.\n\n'
              'Return to the Home page to see '
              'the restored data.',
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                  );

                  Navigator.pop(
                    context,
                    true,
                  );
                },
                child: const Text(
                  'Return Home',
                ),
              ),
            ],
          );
        },
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not restore backup: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isRestoringBackup = false;
        });
      }
    }
  }

  void validateBackup(
    Map<String, dynamic> backup,
  ) {
    final dynamic version =
        backup['version'];

    final dynamic boxes =
        backup['boxes'];

    if (version == null || boxes is! Map) {
      throw const FormatException(
        'This is not a valid My Cookbook AI backup.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isBusy =
        isCreatingBackup || isRestoringBackup;

    return Scaffold(
      backgroundColor:
          const Color(0xFFF8F5F2),
      appBar: AppBar(
        title: const Text(
          'Backup & Restore',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          18,
          14,
          18,
          30,
        ),
        children: [
          const _BackupHeader(),
          const SizedBox(height: 20),
          _BackupActionCard(
            icon: Icons.download_outlined,
            title: 'Create Backup',
            description:
                'Save your cookbooks, recipes, '
                'photos, ratings, tags, meal plan, '
                'shopping list and collections to '
                'one backup file.',
            buttonText: isCreatingBackup
                ? 'Creating Backup...'
                : 'Create Backup',
            isLoading: isCreatingBackup,
            onPressed:
                isBusy ? null : createBackup,
          ),
          const SizedBox(height: 16),
          _BackupActionCard(
            icon: Icons.restore_outlined,
            title: 'Restore Backup',
            description:
                'Choose a previously saved backup '
                'file and restore your cookbook '
                'library.',
            buttonText: isRestoringBackup
                ? 'Restoring Backup...'
                : 'Restore Backup',
            isLoading: isRestoringBackup,
            onPressed: isBusy
                ? null
                : chooseBackupToRestore,
          ),
          const SizedBox(height: 20),
          const _BackupAdviceCard(),
        ],
      ),
    );
  }
}

class _BackupHeader extends StatelessWidget {
  const _BackupHeader();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(
                  0xFFE8EEF8,
                ),
                borderRadius:
                    BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.cloud_done_outlined,
                color: Color(0xFF4F678A),
                size: 30,
              ),
            ),
            const SizedBox(width: 15),
            const Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Keep your recipes safe',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Create a backup regularly so '
                    'your cookbook library can be '
                    'restored if you change devices '
                    'or lose your app data.',
                    style: TextStyle(
                      color:
                          Color(0xFF7C7470),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackupActionCard
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String buttonText;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _BackupActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonText,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFFFFE3D5,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(
                      0xFFD96C3F,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              description,
              style: const TextStyle(
                color: Color(0xFF6F6864),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: onPressed,
                icon: isLoading
                    ? const SizedBox(
                        width: 19,
                        height: 19,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(icon),
                label: Text(buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackupAdviceCard
    extends StatelessWidget {
  const _BackupAdviceCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1DA),
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE8D2AA),
        ),
      ),
      child: const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: Color(0xFF9A6824),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Keep at least one recent backup '
              'somewhere outside the app, such as '
              'your Documents folder or cloud drive.',
              style: TextStyle(
                color: Color(0xFF79551F),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}