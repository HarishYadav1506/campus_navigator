import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'supabase_service.dart';

class CampusGraph {

  static Map<int, List<int>> graph = {};
  static Map<String, int> placeToNode = {};
  static Map<String, String> _keyToCanonicalName = {};
  static Map<int, String> nodeToImage = {};

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  static Future<void> loadGraph() async {

    graph = {};
    placeToNode = {};
    _keyToCanonicalName = {};
    nodeToImage = {};

    final places = await SupabaseService.getPlaces();
    final nodes = await SupabaseService.getNodes();
    final edges = await SupabaseService.getEdges();

    // place → node (case-insensitive: store lowercase key, keep canonical name for display)
    for (var p in places) {
      final name = (p['place_name']?.toString() ?? '').trim();
      final node = _toInt(p['node']);
      if (name.isNotEmpty && node != null) {
        final key = name.toLowerCase();
        placeToNode[key] = node;
        _keyToCanonicalName[key] = name;
      }
    }

    // node → image
    for (var n in nodes) {
      final node = _toInt(n['node']);
      final image = (n['image']?.toString() ?? '').trim();
      if (node != null) {
        nodeToImage[node] = image;
      }
    }

    // edges → graph
    for (var e in edges) {
      final from = _toInt(e['node_from']);
      final to = _toInt(e['node_to']);
      if (from == null || to == null) continue;

      graph.putIfAbsent(from, () => []).add(to);
    }

    debugPrint(
      '[CampusGraph] loaded places=${places.length} nodes=${nodes.length} edges=${edges.length} '
      'mappedPlaces=${placeToNode.length} mappedNodes=${nodeToImage.length} graphNodes=${graph.length}',
    );
  }

  static List<int>? shortestPath(String from, String to) {
    final fromKey = from.trim().toLowerCase();
    final toKey = to.trim().toLowerCase();
    final start = placeToNode[fromKey];
    final end = placeToNode[toKey];

    if (start == null || end == null) return null;

    Queue<List<int>> queue = Queue();
    Set<int> visited = {};

    queue.add([start]);
    visited.add(start);

    while (queue.isNotEmpty) {
      final path = queue.removeFirst();
      final node = path.last;

      if (node == end) return path;

      for (var next in graph[node] ?? []) {
        if (!visited.contains(next)) {
          visited.add(next);
          queue.add([...path, next]);
        }
      }
    }

    return null;
  }

  static String getImage(int node) {
    return nodeToImage[node] ?? '';
  }

  /// Canonical place name for display (e.g. "library" → "Library").
  static String getCanonicalPlaceName(String input) {
    final key = input.trim().toLowerCase();
    return _keyToCanonicalName[key] ?? input;
  }

  static List<String> get allNodes => _keyToCanonicalName.values.toList();
}