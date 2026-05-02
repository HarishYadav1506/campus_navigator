import 'package:supabase_flutter/supabase_flutter.dart';

class NavigationStep {
  NavigationStep({
    required this.nodeId,
    required this.title,
    this.imageKey,
  });

  final int nodeId;
  final String title;
  final String? imageKey;
}

class NavigationPathResult {
  NavigationPathResult({
    required this.resolvedFrom,
    required this.resolvedTo,
    required this.steps,
  });

  final String resolvedFrom;
  final String resolvedTo;
  final List<NavigationStep> steps;
}

class NavigationService {
  NavigationService(this._client);

  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> fetchPlaces() async {
    final rows = await _client.from('places').select('id, place_name, node, name');
    final places = List<Map<String, dynamic>>.from(rows as List);
    places.sort((a, b) => _placeLabel(a).compareTo(_placeLabel(b)));
    return places;
  }

  Future<String?> resolvePlaceName(String input) async {
    final places = await fetchPlaces();
    final place = _resolvePlace(input, places);
    return place == null ? null : _placeLabel(place);
  }

  Future<NavigationPathResult?> shortestPath(String fromInput, String toInput) async {
    final places = await fetchPlaces();
    if (places.isEmpty) return null;

    final from = _resolvePlace(fromInput, places);
    final to = _resolvePlace(toInput, places);
    if (from == null || to == null) return null;

    final startNode = _readNodeId(from);
    final goalNode = _readNodeId(to);
    if (startNode == null || goalNode == null) return null;

    final rpcPath = await _findPathViaRpc(
      fromLabel: _placeLabel(from),
      toLabel: _placeLabel(to),
    );
    if (rpcPath != null && rpcPath.isNotEmpty) {
      return _buildPathResult(
        places: places,
        from: from,
        to: to,
        pathNodes: rpcPath,
      );
    }

    final edgesRows = await _fetchEdges();
    final pathNodes = _bfsPathNodes(startNode, goalNode, edgesRows);
    if (pathNodes == null) return null;

    return _buildPathResult(
      places: places,
      from: from,
      to: to,
      pathNodes: pathNodes,
    );
  }

  Future<Map<String, dynamic>> diagnosePath(String fromInput, String toInput) async {
    final debug = <String, dynamic>{
      'input_from': fromInput,
      'input_to': toInput,
    };

    final places = await fetchPlaces();
    debug['places_count'] = places.length;

    final from = _resolvePlace(fromInput, places);
    final to = _resolvePlace(toInput, places);
    debug['resolved_from'] = from == null ? null : _placeLabel(from);
    debug['resolved_to'] = to == null ? null : _placeLabel(to);

    if (from == null || to == null) {
      debug['status'] = 'place_resolution_failed';
      return debug;
    }

    final startNode = _readNodeId(from);
    final goalNode = _readNodeId(to);
    debug['start_node'] = startNode;
    debug['goal_node'] = goalNode;
    if (startNode == null || goalNode == null) {
      debug['status'] = 'node_mapping_failed';
      return debug;
    }

    final rpcPath = await _findPathViaRpc(
      fromLabel: _placeLabel(from),
      toLabel: _placeLabel(to),
    );
    debug['rpc_path'] = rpcPath;
    debug['rpc_path_found'] = rpcPath != null && rpcPath.isNotEmpty;

    final edgesRows = await _fetchEdges();
    debug['edges_count'] = edgesRows.length;
    final bfsPath = _bfsPathNodes(startNode, goalNode, edgesRows);
    debug['bfs_path'] = bfsPath;
    debug['bfs_path_found'] = bfsPath != null && bfsPath.isNotEmpty;

    final nodeMeta = await _fetchNodeMeta();
    debug['node_meta_count'] = nodeMeta.length;

    final chosenPath = (rpcPath != null && rpcPath.isNotEmpty) ? rpcPath : bfsPath;
    if (chosenPath != null && chosenPath.isNotEmpty) {
      debug['path_for_ui'] = chosenPath;
      debug['titles_for_ui'] = chosenPath
          .map((n) => nodeMeta[n]?['title'] ?? 'Node $n')
          .toList();
      debug['images_for_ui'] = chosenPath
          .map((n) => nodeMeta[n]?['image'] ?? '$n.jpg')
          .toList();
      debug['status'] = 'path_found';
      return debug;
    }

    debug['status'] = 'no_path_found';
    return debug;
  }

  Future<NavigationPathResult> _buildPathResult({
    required List<Map<String, dynamic>> places,
    required Map<String, dynamic> from,
    required Map<String, dynamic> to,
    required List<int> pathNodes,
  }) async {
    final nodeMeta = await _fetchNodeMeta();
    final placeNameByNode = <int, String>{
      for (final p in places)
        if (_readNodeId(p) != null) _readNodeId(p)!: _placeLabel(p),
    };

    final steps = <NavigationStep>[];
    for (final n in pathNodes) {
      final meta = nodeMeta[n];
      final title = meta?['title'] ?? placeNameByNode[n] ?? 'Node $n';
      final image = meta?['image'];
      steps.add(NavigationStep(nodeId: n, title: title, imageKey: image));
    }

    return NavigationPathResult(
      resolvedFrom: _placeLabel(from),
      resolvedTo: _placeLabel(to),
      steps: steps,
    );
  }

  Future<List<int>?> _findPathViaRpc({
    required String fromLabel,
    required String toLabel,
  }) async {
    try {
      final response = await _client.rpc(
        'find_path',
        params: {
          'start_place': fromLabel,
          'end_place': toLabel,
        },
      );
      return _extractPathNodesFromRpc(response);
    } catch (_) {
      return null;
    }
  }

  List<int>? _extractPathNodesFromRpc(dynamic response) {
    if (response == null) return null;

    if (response is List) {
      if (response.isEmpty) return null;
      final first = response.first;
      if (first is Map) {
        final map = Map<String, dynamic>.from(first);
        final pathValue = map['path'];
        final parsed = _parseNodeList(pathValue);
        if (parsed != null && parsed.isNotEmpty) return parsed;
      }

      final parsed = _parseNodeList(response);
      if (parsed != null && parsed.isNotEmpty) return parsed;
    }

    if (response is Map) {
      final map = Map<String, dynamic>.from(response);
      final pathValue = map['path'];
      final parsed = _parseNodeList(pathValue);
      if (parsed != null && parsed.isNotEmpty) return parsed;
    }

    return _parseNodeList(response);
  }

  List<int>? _parseNodeList(dynamic value) {
    if (value == null) return null;

    if (value is List) {
      final result = <int>[];
      for (final item in value) {
        final id = item is int ? item : int.tryParse(item.toString());
        if (id == null) return null;
        result.add(id);
      }
      return result;
    }

    if (value is String) {
      final raw = value.trim();
      if (raw.isEmpty) return null;
      final cleaned = raw.replaceAll('{', '').replaceAll('}', '');
      if (cleaned.trim().isEmpty) return null;
      final parts = cleaned.split(',');
      final result = <int>[];
      for (final part in parts) {
        final id = int.tryParse(part.trim());
        if (id == null) return null;
        result.add(id);
      }
      return result;
    }

    return null;
  }

  List<int>? _bfsPathNodes(
    int startNode,
    int goalNode,
    List<Map<String, dynamic>> edgesRows,
  ) {
    final adj = <int, List<int>>{};
    for (final row in edgesRows) {
      final fromNode = _readEdgeFrom(row);
      final toNode = _readEdgeTo(row);
      if (fromNode == null || toNode == null) continue;
      adj.putIfAbsent(fromNode, () => <int>[]).add(toNode);
      adj.putIfAbsent(toNode, () => <int>[]).add(fromNode);
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
    return pathNodes;
  }

  Future<List<Map<String, dynamic>>> _fetchEdges() async {
    try {
      final rows = await _client.from('edges').select('node_from, node_to');
      return List<Map<String, dynamic>>.from(rows as List);
    } catch (_) {
      final rows = await _client.from('place_edges').select('from_node, to_node');
      return List<Map<String, dynamic>>.from(rows as List);
    }
  }

  Future<Map<int, Map<String, String?>>> _fetchNodeMeta() async {
    try {
      // Match actual DB schema: nodes(node, place_name, image, id).
      final rows = await _client.from('nodes').select('node, place_name, image');
      final result = <int, Map<String, String?>>{};
      for (final row in rows as List) {
        final map = Map<String, dynamic>.from(row as Map);
        final nodeId = _readNodeId(map);
        if (nodeId == null) continue;
        result[nodeId] = {
          'title': _firstString(map, ['place_name']),
          'image': _firstString(map, ['image']),
        };
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  Map<String, dynamic>? _resolvePlace(
    String input,
    List<Map<String, dynamic>> places,
  ) {
    final q = _normalize(input);
    if (q.isEmpty) return null;

    for (final p in places) {
      if (_normalize(_placeLabel(p)) == q) return p;
    }

    for (final p in places) {
      final name = _normalize(_placeLabel(p));
      if (name.contains(q) || q.contains(name)) return p;
    }

    Map<String, dynamic>? best;
    var bestDistance = 1 << 30;
    for (final p in places) {
      final name = _normalize(_placeLabel(p));
      final d = _levenshtein(q, name);
      if (d < bestDistance) {
        bestDistance = d;
        best = p;
      }
    }
    final threshold = q.length <= 5 ? 2 : 3;
    return bestDistance <= threshold ? best : null;
  }

  String _placeLabel(Map<String, dynamic> row) {
    return _firstString(row, ['name', 'place_name']) ?? '';
  }

  int? _readNodeId(Map<String, dynamic> row) {
    final value = row['node'] ?? row['node_id'] ?? row['id'];
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  int? _readEdgeFrom(Map<String, dynamic> row) {
    final value = row['node_from'] ?? row['from_node'] ?? row['from'];
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  int? _readEdgeTo(Map<String, dynamic> row) {
    final value = row['node_to'] ?? row['to_node'] ?? row['to'];
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  String? _firstString(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final v = map[key];
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return null;
  }

  String _normalize(String s) {
    return s
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  int _levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    final dp = List.generate(
      a.length + 1,
      (_) => List<int>.filled(b.length + 1, 0),
    );
    for (var i = 0; i <= a.length; i++) {
      dp[i][0] = i;
    }
    for (var j = 0; j <= b.length; j++) {
      dp[0][j] = j;
    }

    for (var i = 1; i <= a.length; i++) {
      for (var j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        final insert = dp[i][j - 1] + 1;
        final delete = dp[i - 1][j] + 1;
        final replace = dp[i - 1][j - 1] + cost;
        dp[i][j] = [insert, delete, replace].reduce((x, y) => x < y ? x : y);
      }
    }

    return dp[a.length][b.length];
  }
}
