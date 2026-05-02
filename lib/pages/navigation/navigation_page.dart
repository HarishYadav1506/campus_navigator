import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/navigation_service.dart';

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
  late final NavigationService _service;
  NavigationPathResult? _result;
  List<Map<String, dynamic>> _places = const [];
  bool _loading = true;
  String? _error;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _service = NavigationService(Supabase.instance.client);
    _load();
  }

  Future<void> _load() async {
    try {
      final places = await _service.fetchPlaces();
      final result = await _service.shortestPath(widget.from, widget.to);
      if (!mounted) return;
      setState(() {
        _places = places;
        _result = result;
        _error = result == null
            ? 'No connected route found between the selected places.'
            : null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Navigation'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _result == null ? _buildNoPath(context) : _buildStepView(context),
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
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(label: Text('From: ${widget.from}')),
            Chip(label: Text('To: ${widget.to}')),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          _error ??
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
            for (final place in _places.take(30)) Chip(label: Text(_label(place))),
          ],
        ),
      ],
    );
  }

  Widget _buildStepView(BuildContext context) {
    final p = _result!.steps;
    final step = p[currentIndex];
    final node = step.title;
    final image = _buildPrimaryImageKey(step);
    final isStart = currentIndex == 0;
    final isEnd = currentIndex == p.length - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            border: Border.all(color: Colors.white24),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Best route on campus",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text('From: ${_result!.resolvedFrom}')),
                  Chip(label: Text('To: ${_result!.resolvedTo}')),
                  Chip(label: Text('${p.length - 1} hops')),
                ],
              ),
            ],
          ),
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
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: p.length <= 1 ? 1 : currentIndex / (p.length - 1),
          minHeight: 6,
          borderRadius: BorderRadius.circular(999),
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
            Text(node, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: isEnd
                          ? null
                          : () => setState(() {
                                currentIndex++;
                              }),
                      child: _ResilientNodeImage(
                        bucket: 'Streetview',
                        objectKey: image,
                        nodeId: step.nodeId,
                        nodeTitle: step.title,
                      ),
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
                          label: const Text("Previous"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: currentIndex >= p.length - 1
                              ? null
                              : () => setState(() => currentIndex++),
                          icon: const Icon(Icons.arrow_forward),
                          label: Text(isEnd ? "Done" : "Next"),
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
          isEnd
              ? "Arrived at destination. Path complete."
              : "Tap image or Next to move to the next node.",
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  String _buildPrimaryImageKey(NavigationStep step) {
    final configured = step.imageKey?.trim();
    if (configured != null && configured.isNotEmpty) return configured;
    return '${step.nodeId}.jpg';
  }

  String _label(Map<String, dynamic> row) {
    final name = row['name']?.toString().trim();
    if (name != null && name.isNotEmpty) return name;
    final placeName = row['place_name']?.toString().trim();
    if (placeName != null && placeName.isNotEmpty) return placeName;
    return 'Unknown';
  }
}

class _ResilientNodeImage extends StatefulWidget {
  final String bucket;
  final String objectKey;
  final int nodeId;
  final String nodeTitle;

  const _ResilientNodeImage({
    required this.bucket,
    required this.objectKey,
    required this.nodeId,
    required this.nodeTitle,
  });

  @override
  State<_ResilientNodeImage> createState() => _ResilientNodeImageState();
}

class _ResilientNodeImageState extends State<_ResilientNodeImage> {
  int attempt = 0;
  String? _resolvedBucket;
  List<String> _bucketObjectNames = const [];
  bool _loadingBucketObjects = false;

  @override
  void initState() {
    super.initState();
    _prefetchBucketObjects();
  }

  String _slug(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  List<String> _candidateKeys(String key) {
    final k = key.trim();
    final keys = <String>{};
    if (k.isNotEmpty) {
      keys.add(k);

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
    }

    // Node-based fallbacks for path arrays such as [14,37,13,55].
    keys.add('${widget.nodeId}.jpg');
    keys.add('${widget.nodeId}.jpeg');
    keys.add('${widget.nodeId}.png');
    final slug = widget.nodeTitle.trim();
    if (slug.isNotEmpty) {
      keys.add('$slug.jpg');
      keys.add('$slug.jpeg');
      keys.add('$slug.png');
      final lower = slug.toLowerCase();
      keys.add('$lower.jpg');
      keys.add('$lower.jpeg');
      keys.add('$lower.png');
      final underscored = _slug(slug);
      if (underscored.isNotEmpty) {
        keys.add('$underscored.jpg');
        keys.add('$underscored.jpeg');
        keys.add('$underscored.png');
      }
    }

    if (_bucketObjectNames.isNotEmpty) {
      final title = widget.nodeTitle.trim().toLowerCase();
      final titleTokens = title
          .split(RegExp(r'[^a-z0-9]+'))
          .where((t) => t.length >= 3)
          .toList();

      final ranked = <String>[];
      for (final name in _bucketObjectNames) {
        final lower = name.toLowerCase();
        final byFullTitle = title.isNotEmpty && lower.contains(title);
        final byToken = titleTokens.any(lower.contains);
        final byNode = lower.contains('${widget.nodeId}');
        if (byFullTitle || byToken || byNode) {
          ranked.add(name);
        }
      }

      ranked.sort((a, b) => a.length.compareTo(b.length));
      for (final name in ranked) {
        keys.add(name);
      }
    }

    return keys.toList();
  }

  List<String> _candidateBuckets(String bucket) {
    final b = bucket.trim();
    final buckets = <String>{};
    if (_resolvedBucket != null && _resolvedBucket!.trim().isNotEmpty) {
      buckets.add(_resolvedBucket!);
    }
    if (b.isNotEmpty) buckets.add(b);
    buckets.add('Streetview');
    buckets.add('StreetView');
    buckets.add('streetview');
    buckets.add('street_view');
    buckets.add('street-view');
    return buckets.toList();
  }

  Future<void> _prefetchBucketObjects() async {
    if (_loadingBucketObjects) return;
    _loadingBucketObjects = true;
    try {
      final buckets = _candidateBuckets(widget.bucket);
      for (final bucket in buckets) {
        try {
          final files = await Supabase.instance.client.storage.from(bucket).list();
          final names = <String>[];
          for (final file in files) {
            final dynamic f = file;
            String name = '';
            try {
              name = (f.name ?? '').toString().trim();
            } catch (_) {
              if (f is Map) {
                name = (f['name'] ?? '').toString().trim();
              }
            }
            if (name.isNotEmpty) names.add(name);
          }
          if (names.isNotEmpty) {
            if (!mounted) return;
            setState(() {
              _resolvedBucket = bucket;
              _bucketObjectNames = names;
              attempt = 0;
            });
            return;
          }
        } catch (_) {
          // Try next candidate bucket.
        }
      }
    } finally {
      _loadingBucketObjects = false;
    }
  }

  @override
  void didUpdateWidget(covariant _ResilientNodeImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.objectKey != widget.objectKey ||
        oldWidget.nodeId != widget.nodeId ||
        oldWidget.nodeTitle != widget.nodeTitle ||
        oldWidget.bucket != widget.bucket) {
      setState(() => attempt = 0);
      _prefetchBucketObjects();
    }
  }

  @override
  Widget build(BuildContext context) {
    final candidates = _candidateKeys(widget.objectKey);
    final buckets = _candidateBuckets(widget.bucket);
    final pairCount = buckets.length * candidates.length;
    if (candidates.isEmpty) {
      return const Center(
        child: Text(
          "No image set for this node.",
          style: TextStyle(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
      );
    }

    final idx = attempt.clamp(0, pairCount - 1);
    final bucket = buckets[idx ~/ candidates.length];
    final key = candidates[idx % candidates.length];
    final url = Supabase.instance.client.storage.from(bucket).getPublicUrl(key);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // Try next candidate filename if available; otherwise show actual error.
          if (attempt < pairCount - 1) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => attempt++);
            });
            return const Center(
              child: Text(
                "Loading image...",
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return Center(
            child: Text(
              "Couldn't load image.\n"
              "Initial key: ${widget.objectKey}\n"
              "Tried buckets: ${buckets.join(', ')}\n"
              "Tried keys: ${candidates.join(', ')}\n"
              "Last attempt: $bucket/$key\n"
              "Error: $error",
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          );
        },
      ),
    );
  }
}
