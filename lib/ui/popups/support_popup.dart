import 'package:flutter/material.dart';
import 'package:parrotaac/backend/quick_store.dart';
import 'package:url_launcher/url_launcher.dart';

const _selectedSupportTabIndexKey = "selected support tab";
Future<void> showSupportDialog(
  BuildContext context, {
  QuickStore? quickStore,
}) async {
  final int index = quickStore?[_selectedSupportTabIndexKey] ?? 0;
  const tabNames = ["Financial", "Developer", "Designer"];
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      final screenHeight = MediaQuery.of(context).size.height;
      final screenWidth = MediaQuery.of(context).size.width;

      return SupportDialog(
        screenWidth: screenWidth,
        screenHeight: screenHeight,
        tabNames: tabNames,
        index: index,
        quickStore: quickStore,
      );
    },
  );
}

class SupportDialog extends StatefulWidget {
  const SupportDialog({
    super.key,
    required this.screenWidth,
    required this.screenHeight,
    required this.tabNames,
    required this.index,
    this.quickStore,
  });

  final double screenWidth;
  final double screenHeight;
  final List<String> tabNames;
  final int? index;
  final QuickStore? quickStore;

  @override
  State<SupportDialog> createState() => _SupportDialogState();
}

class _SupportDialogState extends State<SupportDialog>
    with SingleTickerProviderStateMixin {
  late final TabController controller;
  @override
  void initState() {
    controller = TabController(
      length: widget.tabNames.length,
      vsync: this,
      initialIndex: widget.index ?? 0,
    );
    controller.addListener(() {
      widget.quickStore?.writeData(
        _selectedSupportTabIndexKey,
        controller.index,
      );
    });
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    _cleanUpQuickstore();
    super.dispose();
  }

  Future<void> _cleanUpQuickstore() async {
    await widget.quickStore?.removeFromKey(_selectedSupportTabIndexKey);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: EdgeInsets.zero,
      insetPadding: EdgeInsets.symmetric(
        horizontal: widget.screenWidth * 0.1,
        vertical: widget.screenHeight * 0.1,
      ),
      content: SizedBox(
        width: widget.screenWidth * 0.8,
        height: widget.screenHeight * 0.8,
        child: Column(
          children: [
            Container(
              color: Theme.of(
                context,
              ).colorScheme.primary.withAlpha((0.1 * 255).truncate()),
              child: TabBar(
                controller: controller,
                labelColor: Colors.blue,
                unselectedLabelColor: Colors.black54,
                tabs: widget.tabNames.map((name) => Tab(text: name)).toList(),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: controller,
                children: [
                  // 💰 Financial Support
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Support the project financially',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Your contributions help keep this project alive and improving.\n'
                          'You can donate via Patreon, Ko-fi, or GitHub Sponsors. This will need to change depending on IOS, andoroid, or PC',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        //TODO: this will need to be set up per platform to confrom to os rules
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 12,
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.favorite),
                              label: const Text('one-time donation'),
                              onPressed: () async {
                                final url = Uri.parse(
                                  'https://patreon.com/yourproject',
                                );
                                if (await canLaunchUrl(url)) launchUrl(url);
                              },
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.local_cafe),
                              label: const Text('recurring donation'),
                              onPressed: () async {
                                final url = Uri.parse(
                                  'https://ko-fi.com/yourproject',
                                );
                                if (await canLaunchUrl(url)) launchUrl(url);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 💻 Developer Support
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Contribute as a Developer',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'This project is open source! You can help by contributing code, '
                          'reporting issues, or improving documentation.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.code),
                          label: const Text('View on GitHub'),
                          onPressed: () async {
                            final url = Uri.parse(
                              'https://github.com/Ben-Collett/parrotaac',
                            );
                            if (await canLaunchUrl(url)) launchUrl(url);
                          },
                        ),
                      ],
                    ),
                  ),

                  // 🎨 Designer Support
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Contribute as a Designer',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Have UI/UX improvement ideas? We’d love your input!\n'
                          'Join our design community to share feedback and concepts.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.discord),
                          label: const Text('Join Discord'),
                          onPressed: () async {
                            final url = Uri.parse(
                              'https://discord.gg/yourserver',
                            );
                            if (await canLaunchUrl(url)) launchUrl(url);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text('Close'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
