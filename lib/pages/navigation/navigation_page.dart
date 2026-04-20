import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/navigation_engine.dart';
import '../../services/navigation_service.dart';

class NavigationPage extends StatefulWidget {
  final String from;
  final String to;

  const NavigationPage({Key? key, this.from = '', this.to = ''}) : super(key: key);

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  late final NavigationService _svc;
  List<Map<String, dynamic>> _places = [];
  List<String>? _path;
  bool _loading = true;
  String? _from;
  String? _to;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _svc = NavigationService(Supabase.instance.client);
    _from = widget.from.isEmpty ? null : widget.from;
    _to = widget.to.isEmpty ? null : widget.to;
    _init();
  }

  Future<void> _init() async {
    try {
      final rows = await _svc.fetchPlaces();
      if (!mounted) return;
      _places = rows;
      if (_from == null && rows.isNotEmpty) _from = rows.first['name'].toString();
      if (_to == null && rows.length > 1) _to = rows[1]['name'].toString();
      await _compute();
    } catch (_) {
      await _compute();
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _compute() async {
    if ((_from ?? '').isEmpty || (_to ?? '').isEmpty) {
      _path = null;
      _currentIndex = 0;
      return;
    }
    final dynamicPath = await _svc.shortestPath(_from!, _to!);
    _path = dynamicPath ?? CampusGraph.shortestPath(_from!, _to!);
    _currentIndex = 0;
  }

  String? _imageForPlace(String placeName) {
    for (final p in _places) {
      final n = (p['name'] ?? '').toString().trim().toLowerCase();
      if (n == placeName.trim().toLowerCase()) {
        final image = (p['image'] ?? '').toString().trim();
        return image.isEmpty ? null : image;
      }
    }
    return null;
  }

  Future<void> _swapFromTo() async {
    final from = _from;
    final to = _to;
    setState(() {
      _from = to;
      _to = from;
    });
    await _compute();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final path = _path;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Navigation'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _from,
              items: _places
                  .map((p) => DropdownMenuItem<String>(
                        value: p['name'].toString(),
                        child: Text(p['name'].toString()),
                      ))
                  .toList(),
              onChanged: (v) async {
                setState(() => _from = v);
                await _compute();
                if (mounted) setState(() {});
              },
              decoration: const InputDecoration(labelText: 'From'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: FilledButton.tonalIcon(
                    onPressed: _swapFromTo,
                    icon: const Icon(Icons.swap_vert),
                    label: const Text('Swap'),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _to,
              items: _places
                  .map((p) => DropdownMenuItem<String>(
                        value: p['name'].toString(),
                        child: Text(p['name'].toString()),
                      ))
                  .toList(),
              onChanged: (v) async {
                setState(() => _to = v);
                await _compute();
                if (mounted) setState(() {});
              },
              decoration: const InputDecoration(labelText: 'To'),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: path == null
                  ? _buildNoPath(context)
                  : _buildGuidedPathView(context, path),
            ),
          ],
        ),
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
          "From: ${_from ?? '-'}\nTo:   ${_to ?? '-'}",
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        const Text(
          "Either one of the locations does not exist in the campus map, "
          "or there is no connection between them in the demo graph.",
        ),
        const SizedBox(height: 16),
        const Text(
          "Try using one of these demo locations:",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final node in CampusGraph.allNodes)
              Chip(
                label: Text(node),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildGuidedPathView(BuildContext context, List<String> path) {
    final node = path[_currentIndex];
    final imageKey = _imageForPlace(node);
    final isStart = _currentIndex == 0;
    final isEnd = _currentIndex == path.length - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Best route on campus",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  "From: ${_from ?? '-'}\nTo:   ${_to ?? '-'}",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: path.length <= 1
                      ? 1
                      : _currentIndex / (path.length - 1),
                ),
                const SizedBox(height: 8),
                Text(
                  "Step ${_currentIndex + 1} of ${path.length} (${path.length - 1} hops)",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: isStart
                            ? Colors.green
                            : (isEnd ? Colors.red : Colors.indigo),
                        child: Icon(
                          isStart
                              ? Icons.my_location
                              : (isEnd ? Icons.flag : Icons.circle),
                          size: isEnd ? 16 : 12,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          node,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _ResilientNodeImage(
                      bucket: 'streetview',
                      objectKey: imageKey ?? '',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _currentIndex == 0
                              ? null
                              : () => setState(() => _currentIndex--),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text("Prev"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _currentIndex >= path.length - 1
                              ? null
                              : () => setState(() => _currentIndex++),
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
  const _ResilientNodeImage({
    required this.bucket,
    required this.objectKey,
  });

  final String bucket;
  final String objectKey;

  @override
  State<_ResilientNodeImage> createState() => _ResilientNodeImageState();
}

class _ResilientNodeImageState extends State<_ResilientNodeImage> {
  int _attempt = 0;

  List<String> _candidateKeys(String key) {
    final k = key.trim();
    if (k.isEmpty) return const [];

    final keys = <String>{k};
    keys.add(k.replaceAll(' - ', '-'));
    keys.add(k.replaceAll('-', ' - '));

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
      setState(() => _attempt = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final candidates = _candidateKeys(widget.objectKey);
    if (candidates.isEmpty) {
      return const Center(
        child: Text(
          "No image set for this place.",
          textAlign: TextAlign.center,
        ),
      );
    }

    final key = candidates[_attempt.clamp(0, candidates.length - 1)];
    final url = Supabase.instance.client.storage
        .from(widget.bucket)
        .getPublicUrl(key);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          if (_attempt < candidates.length - 1) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _attempt++);
            });
            return const Center(child: Text("Loading image..."));
          }
          return Center(
            child: Text(
              "Couldn't load image.\nKey: ${widget.objectKey}",
              textAlign: TextAlign.center,
            ),
          );
        },
      ),
    );
  }
}

