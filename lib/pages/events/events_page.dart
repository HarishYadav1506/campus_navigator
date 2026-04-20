import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/session_manager.dart';
import '../../services/engagement_service.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  final _supabase = Supabase.instance.client;
  final _eng = EngagementService(Supabase.instance.client);
  final _searchController = TextEditingController();
  String _query = '';
  late final Stream<List<Map<String, dynamic>>> _eventRows;
  Map<String, int> _interestWeights = {};

  @override
  void initState() {
    super.initState();
    _eventRows = _supabase
        .from('events')
        .stream(primaryKey: ['id'])
        .order('date_time', ascending: true);
    _loadInterests();
  }

  Future<void> _loadInterests() async {
    final e = SessionManager.email;
    if (e == null || e.isEmpty) return;
    try {
      final w = await _eng.fetchInterestWeights(e);
      if (mounted) setState(() => _interestWeights = w);
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Research Events & Seminars'),
        actions: [
          if ((SessionManager.role == 'admin') ||
              (SessionManager.role == 'professor') ||
              (SessionManager.role == 'prof'))
            IconButton(
              tooltip: 'Add event',
              onPressed: () => Navigator.pushNamed(context, '/admin_events'),
              icon: const Icon(Icons.add_circle_outline),
            ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _eventRows,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final events = (snapshot.data ?? [])
              .map((e) => _Event.fromMap(Map<String, dynamic>.from(e)))
              .toList();

          // Add hardcoded events for "that day" and upcoming
          events.addAll([
            _Event(
              id: 'local_event_1',
              title: 'AI in Robotics Seminar',
              type: 'Seminar',
              dateTime: DateTime.now().add(const Duration(hours: 2)),
              location: 'Lecture Hall Complex',
            ),
            _Event(
              id: 'local_event_2',
              title: 'Spring Tech Festival',
              type: 'Event',
              dateTime: DateTime.now().add(const Duration(hours: 4)),
              location: 'R&D Block',
            ),
            _Event(
              id: 'local_event_3',
              title: 'Cybersecurity Workshop',
              type: 'Event',
              dateTime: DateTime.now().add(const Duration(days: 2)),
              location: 'Seminar Block',
            ),
          ]);
          events.sort((a, b) {
            final sa = _interestWeights[a.type.toLowerCase()] ?? 0;
            final sb = _interestWeights[b.type.toLowerCase()] ?? 0;
            if (sa != sb) return sb.compareTo(sa);
            return a.dateTime.compareTo(b.dateTime);
          });
          final filtered = _query.trim().isEmpty
              ? events
              : events.where((e) {
                  final q = _query.toLowerCase();
                  return e.title.toLowerCase().contains(q) ||
                      e.type.toLowerCase().contains(q) ||
                      e.location.toLowerCase().contains(q);
                }).toList();

          if (filtered.isEmpty) {
            return const Center(
              child: Text("No matching events right now."),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadInterests,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: const InputDecoration(
                      hintText: 'Search by title, type or location...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  );
                }
                final e = filtered[index - 1];
                return _EventCard(
                  event: e,
                  onInterest: () async {
                    final email = SessionManager.email;
                    if (email == null || email.isEmpty) return;
                    await _eng.recordInterest(email, e.type);
                    _loadInterests();
                  },
                ).animate().fadeIn(delay: (50 * (index - 1)).ms);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/seminars');
        },
        icon: const Icon(Icons.event_note),
        label: const Text("More seminars"),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final _Event event;
  final Future<void> Function() onInterest;

  const _EventCard({required this.event, required this.onInterest});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1D4ED8),
            Color(0xFF4F46E5),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Location: ${event.location}')),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    event.type.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      letterSpacing: 0.6,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event.dateString,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.place_outlined,
                            color: Colors.white70,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event.location,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white24),
                        ),
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/navigator',
                            arguments: {
                              'from': 'IIITD Gate',
                              'to': event.location,
                            },
                          );
                        },
                        icon: const Icon(Icons.navigation_outlined, size: 18),
                        label: const Text('Navigate'),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    onInterest();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Marked as interested: ${event.title}"),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.favorite_border,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Event {
  final String id;
  final String title;
  final String type;
  final DateTime dateTime;
  final String location;

  _Event({
    required this.id,
    required this.title,
    required this.type,
    required this.dateTime,
    required this.location,
  });

  String get dateString =>
      "${dateTime.day}/${dateTime.month} • ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";

  factory _Event.fromMap(Map<String, dynamic> map) {
    return _Event(
      id: map['id'].toString(),
      title: map['title'] as String,
      type: (map['type'] ?? 'Event') as String,
      dateTime: DateTime.parse(map['date_time'] as String),
      location: (map['location'] ?? '') as String,
    );
  }
}

