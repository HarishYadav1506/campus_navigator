import 'package:supabase_flutter/supabase_flutter.dart';

class NavigationService {
  NavigationService(this._client);

  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> fetchPlaces() async {
    final rows = await _client.from('places').select().order('name');
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<List<String>?> shortestPath(String fromName, String toName) async {
    final places = await _client
        .from('places')
        .select('id,name')
        .inFilter('name', [fromName, toName]);
    if ((places as List).length < 2) return null;

    final placeMap = {
      for (final p in places) (p as Map)['id'].toString(): (p)['name'].toString()
    };
    final nodes = await _client.from('place_nodes').select('node_id,place_id');
    final nodeToPlace = <String, String>{};
    String? startNode;
    String? goalNode;
    for (final n in nodes as List) {
      final m = Map<String, dynamic>.from(n as Map);
      final nodeId = m['node_id'].toString();
      final placeId = m['place_id'].toString();
      nodeToPlace[nodeId] = placeId;
      final name = placeMap[placeId];
      if (name == fromName) startNode = nodeId;
      if (name == toName) goalNode = nodeId;
    }
    if (startNode == null || goalNode == null) return null;

    final edges = await _client.from('place_edges').select('from_node,to_node');
    final adj = <String, List<String>>{};
    for (final e in edges as List) {
      final m = Map<String, dynamic>.from(e as Map);
      final from = m['from_node'].toString();
      final to = m['to_node'].toString();
      adj.putIfAbsent(from, () => []).add(to);
      adj.putIfAbsent(to, () => []).add(from);
    }

    final queue = <String>[startNode];
    final visited = <String>{startNode};
    final parent = <String, String?>{startNode: null};
    while (queue.isNotEmpty) {
      final cur = queue.removeAt(0);
      if (cur == goalNode) break;
      for (final nxt in (adj[cur] ?? const <String>[])) {
        if (visited.contains(nxt)) continue;
        visited.add(nxt);
        parent[nxt] = cur;
        queue.add(nxt);
      }
    }
    if (!parent.containsKey(goalNode)) return null;
    final pathNodes = <String>[];
    String? node = goalNode;
    while (node != null) {
      pathNodes.insert(0, node);
      node = parent[node];
    }
    final names = <String>[];
    for (final n in pathNodes) {
      final placeId = nodeToPlace[n];
      if (placeId == null) continue;
      names.add(placeMap[placeId] ?? placeId);
    }
    return names;
  }
}
