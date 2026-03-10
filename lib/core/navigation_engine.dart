class CampusGraph {
  // Simple unweighted graph: each node connects to its neighbours.
  // You can edit / extend this list to match your real campus.
  static final Map<String, List<String>> _adjacency = {
    'main gate': ['admin block', 'hostel gate'],
    'admin block': ['main gate', 'cse block', 'library'],
    'hostel gate': ['main gate', 'hostel a', 'hostel b'],
    'hostel a': ['hostel gate', 'hostel b'],
    'hostel b': ['hostel gate', 'hostel a'],
    'cse block': ['admin block', 'old academic block'],
    'old academic block': ['cse block', 'library'],
    'library': ['admin block', 'old academic block', 'ground'],
    'ground': ['library', 'sports complex'],
    'sports complex': ['ground'],
  };

  static Iterable<String> get allNodes => _adjacency.keys;

  /// Returns a shortest path (by number of edges) between [from] and [to],
  /// or null if either node does not exist or no path is found.
  static List<String>? shortestPath(String from, String to) {
    final start = _normalize(from);
    final goal = _normalize(to);

    if (!_adjacency.containsKey(start) || !_adjacency.containsKey(goal)) {
      return null;
    }

    if (start == goal) return [start];

    final queue = <String>[start];
    final visited = <String>{start};
    final parent = <String, String?>{start: null};

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      final neighbours = _adjacency[current] ?? [];

      for (final n in neighbours) {
        if (visited.contains(n)) continue;
        visited.add(n);
        parent[n] = current;
        if (n == goal) {
          // Reconstruct path
          final path = <String>[];
          String? node = goal;
          while (node != null) {
            path.insert(0, node);
            node = parent[node];
          }
          return path;
        }
        queue.add(n);
      }
    }
    return null;
  }

  static String _normalize(String name) => name.trim().toLowerCase();
}

