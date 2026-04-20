import 'package:flutter/material.dart';
import '../../core/navigation_engine.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
      return;
    }
    final dynamicPath = await _svc.shortestPath(_from!, _to!);
    _path = dynamicPath ?? CampusGraph.shortestPath(_from!, _to!);
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
            : _buildPathView(context, path),
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

  Widget _buildPathView(BuildContext context, List<String> path) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Best route on campus",
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          "From: ${_from ?? '-'}\nTo:   ${_to ?? '-'}",
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        Text(
          "Steps (${path.length - 1} hops):",
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            itemCount: path.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final node = path[index];
              final isStart = index == 0;
              final isEnd = index == path.length - 1;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      if (!isStart)
                        Container(
                          width: 2,
                          height: 10,
                          color: Colors.grey.shade400,
                        ),
                      CircleAvatar(
                        radius: 14,
                        backgroundColor:
                            isStart ? Colors.green : (isEnd ? Colors.red : Colors.indigo),
                        child: Icon(
                          isStart
                              ? Icons.my_location
                              : (isEnd ? Icons.flag : Icons.circle),
                          size: isEnd ? 14 : 10,
                          color: Colors.white,
                        ),
                      ),
                      if (!isEnd)
                        Container(
                          width: 2,
                          height: 10,
                          color: Colors.grey.shade400,
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Text(
                          node,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "This is a demo shortest path using a simple node-to-node graph. "
          "You can later replace the graph in CampusGraph with real campus data.",
          style: TextStyle(fontSize: 11),
        ),
      ],
    );
  }
}

