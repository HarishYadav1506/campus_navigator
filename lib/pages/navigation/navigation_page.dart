import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/navigation_engine.dart';

class NavigationPage extends StatefulWidget {
  final String from;
  final String to;

  const NavigationPage({
    Key? key,
    required this.from,
    required this.to,
  }) : super(key: key);

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  late final List<int>? path;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    path = CampusGraph.shortestPath(widget.from, widget.to);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Navigation'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: path == null ? _buildNoPath(context) : _buildStepView(context),
      ),
    );
  }

  Widget _buildNoPath(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "No route found",
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          "From: ${CampusGraph.getCanonicalPlaceName(widget.from)}\nTo:   ${CampusGraph.getCanonicalPlaceName(widget.to)}",
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        const Text(
          "Either one of the locations does not exist in the campus map "
          "or there is no connection between them.",
        ),
        const SizedBox(height: 16),
        const Text(
          "Available locations:",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final node in CampusGraph.allNodes)
              Chip(label: Text(node)),
          ],
        ),
      ],
    );
  }

  Widget _buildStepView(BuildContext context) {
    final p = path!;
    final node = p[currentIndex];
    final image = CampusGraph.getImage(node);
    final isStart = currentIndex == 0;
    final isEnd = currentIndex == p.length - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Best route on campus",
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          "From: ${CampusGraph.getCanonicalPlaceName(widget.from)}\nTo:   ${CampusGraph.getCanonicalPlaceName(widget.to)}",
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text(
              "Step ${currentIndex + 1} of ${p.length}",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(width: 10),
            Text(
              "(${p.length - 1} hops total)",
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor:
                  isStart ? Colors.green : (isEnd ? Colors.red : Colors.indigo),
              child: Icon(
                isStart ? Icons.my_location : (isEnd ? Icons.flag : Icons.circle),
                size: isEnd ? 16 : 12,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              "Node $node",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _ResilientNodeImage(
                      bucket: 'streetview',
                      objectKey: image,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: currentIndex == 0
                              ? null
                              : () => setState(() => currentIndex--),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text("Prev"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: currentIndex >= p.length - 1
                              ? null
                              : () => setState(() => currentIndex++),
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text("Next"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isEnd ? "Arrived at destination." : "Tap Next to continue.",
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _ResilientNodeImage extends StatefulWidget {
  final String bucket;
  final String objectKey;

  const _ResilientNodeImage({
    required this.bucket,
    required this.objectKey,
  });

  @override
  State<_ResilientNodeImage> createState() => _ResilientNodeImageState();
}

class _ResilientNodeImageState extends State<_ResilientNodeImage> {
  int attempt = 0;

  List<String> _candidateKeys(String key) {
    final k = key.trim();
    if (k.isEmpty) return const [];

    final keys = <String>{k};

    // Common naming inconsistencies: " - " vs "-" (keep both candidates)
    keys.add(k.replaceAll(' - ', '-'));
    keys.add(k.replaceAll('-', ' - '));

    // If key is HEIC/HEIF, also try jpg/jpeg/png versions (same basename).
    final lower = k.toLowerCase();
    final dot = k.lastIndexOf('.');
    final hasExt = dot != -1 && dot > 0 && dot < k.length - 1;
    final base = hasExt ? k.substring(0, dot) : k;
    final ext = hasExt ? lower.substring(dot + 1) : '';

    if (ext == 'heic' || ext == 'heif') {
      keys.add('$base.jpg');
      keys.add('$base.jpeg');
      keys.add('$base.png');
    }

    return keys.toList();
  }

  @override
  void didUpdateWidget(covariant _ResilientNodeImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.objectKey != widget.objectKey) {
      setState(() => attempt = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final candidates = _candidateKeys(widget.objectKey);
    if (candidates.isEmpty) {
      return const Center(
        child: Text(
          "No image set for this node.",
          style: TextStyle(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
      );
    }

    final key = candidates[attempt.clamp(0, candidates.length - 1)];
    final url = Supabase.instance.client.storage.from(widget.bucket).getPublicUrl(key);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // Try next candidate filename if available; otherwise show actual error.
          if (attempt < candidates.length - 1) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => attempt++);
            });
            return const Center(
              child: Text(
                "Loading image…",
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return Center(
            child: Text(
              "Couldn’t load image.\nKey: ${widget.objectKey}\nTried: ${candidates.join(', ')}\nError: $error",
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          );
        },
      ),
    );
  }
}