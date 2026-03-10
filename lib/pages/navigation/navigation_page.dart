import 'package:flutter/material.dart';
import '../../core/navigation_engine.dart';

class NavigationPage extends StatelessWidget {
  final String from;
  final String to;

  const NavigationPage({Key? key, required this.from, required this.to})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final path = CampusGraph.shortestPath(from, to);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Navigation'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: path == null
            ? _buildNoPath(context)
            : _buildPathView(context, path),
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
          "From: $from\nTo:   $to",
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
          "From: $from\nTo:   $to",
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

