import 'package:supabase_flutter/supabase_flutter.dart';

class NavigationService {
  NavigationService(this._client);

  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> fetchPlaces() async {
    final placesRows = await _client
        .from('places')
        .select('place_name,node')
        .order('place_name');
    final nodesRows = await _client
        .from('nodes')
        .select('node_id,place_name,image');

    final nodeMeta = <int, Map<String, dynamic>>{};
    for (final r in nodesRows as List) {
      final m = Map<String, dynamic>.from(r as Map);
      final nodeId = (m['node_id'] as num?)?.toInt();
      if (nodeId != null) nodeMeta[nodeId] = m;
    }

    final out = <Map<String, dynamic>>[];
    for (final r in placesRows as List) {
      final p = Map<String, dynamic>.from(r as Map);
      final node = (p['node'] as num?)?.toInt();
      final meta = node == null ? null : nodeMeta[node];
      out.add({
        'name': (p['place_name'] ?? '').toString(),
        'node': node,
        'image': (meta?['image'] ?? '').toString(),
      });
    }
    return out;
  }

  Future<List<String>?> shortestPath(String fromName, String toName) async {
    final placesRows = await _client.from('places').select('place_name,node');
    final nodesRows = await _client
        .from('nodes')
        .select('node_id,place_name');
    final edgesRows = await _client
        .from('edges')
        .select('node_from,node_to');

    int? startNode;
    int? goalNode;
    final nodeToName = <int, String>{};

    for (final r in nodesRows as List) {
      final m = Map<String, dynamic>.from(r as Map);
      final nodeId = (m['node_id'] as num?)?.toInt();
      if (nodeId == null) continue;
      nodeToName[nodeId] = (m['place_name'] ?? '').toString();
    }

    for (final r in placesRows as List) {
      final p = Map<String, dynamic>.from(r as Map);
      final name = (p['place_name'] ?? '').toString().trim().toLowerCase();
      final node = (p['node'] as num?)?.toInt();
      if (node == null) continue;
      if (name == fromName.trim().toLowerCase()) startNode = node;
      if (name == toName.trim().toLowerCase()) goalNode = node;
      nodeToName.putIfAbsent(node, () => (p['place_name'] ?? '').toString());
    }

    if (startNode == null || goalNode == null) return null;

    final adj = <int, List<int>>{};
    for (final e in edgesRows as List) {
      final m = Map<String, dynamic>.from(e as Map);
      final from = (m['node_from'] as num?)?.toInt();
      final to = (m['node_to'] as num?)?.toInt();
      if (from == null || to == null) continue;
      adj.putIfAbsent(from, () => []).add(to);
      adj.putIfAbsent(to, () => []).add(from);
    }

    final queue = <int>[startNode];
    final visited = <int>{startNode};
    final parent = <int, int?>{startNode: null};
    while (queue.isNotEmpty) {
      final cur = queue.removeAt(0);
      if (cur == goalNode) break;
      for (final nxt in (adj[cur] ?? const <int>[])) {
        if (visited.contains(nxt)) continue;
        visited.add(nxt);
        parent[nxt] = cur;
        queue.add(nxt);
      }
    }
    if (!parent.containsKey(goalNode)) return null;
    final pathNodes = <int>[];
    int? node = goalNode;
    while (node != null) {
      pathNodes.insert(0, node);
      node = parent[node];
    }
    final names = <String>[];
    for (final n in pathNodes) {
      names.add(nodeToName[n] ?? 'Node $n');
    }
    return names;
  }
}
