import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/session_manager.dart';
import '../../services/navigation_service.dart';
import '../../widgets/campus_essentials_strip.dart';
import '../../widgets/notification_icon_button.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// Background (Uber-like map placeholder with blur + gradient)
          Positioned.fill(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  "assets/old_academic.jpg",
                  fit: BoxFit.cover,
                  color: Colors.black.withOpacity(0.3),
                  colorBlendMode: BlendMode.darken,
                ),
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(
                    color: const Color(0xFF020617).withOpacity(0.75),
                  ),
                ),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x661F2937),
                        Color(0x99020B1A),
                        Color(0xFF020617),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          /// Top bar: logo + app name (left) and Sign/Login (right)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          "assets/logo.jpg",
                          height: 36,
                          width: 36,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "Campus Navigator",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const NotificationIconButton(),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                            side: const BorderSide(
                              color: Colors.white24,
                            ),
                          ),
                          backgroundColor: Colors.white.withOpacity(0.06),
                        ),
                        onPressed: () {
                          if (SessionManager.isLoggedIn) {
                            Navigator.pushNamed(context, '/settings');
                          } else {
                            Navigator.pushNamed(context, "/auth");
                          }
                        },
                        icon: const Icon(
                          Icons.person_outline,
                          size: 18,
                        ),
                        label: Text(
                          SessionManager.isLoggedIn
                              ? (SessionManager.role ?? "Profile")
                              : "Sign / Login",
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          /// Center search card (Uber-style "Where to?")
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 110, left: 16, right: 16),
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                tween: Tween(begin: 0, end: 1),
                builder: (context, value, child) {
                  // Curves like easeOutBack can overshoot; Opacity requires 0..1.
                  final o = value.clamp(0.0, 1.0);
                  return Opacity(
                    opacity: o,
                    child: Transform.translate(
                      offset: Offset(0, (1 - o) * 20),
                      child: child,
                    ),
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    /// Website banner + 360 icon row
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Row(
                              children: const [
                                Icon(
                                  Icons.public,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    "Visit campus website for latest notices",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () async {
                                final Uri url = Uri.parse(
                                  "https://last5sec.github.io/campus-navigation/streetview/index.html",
                                );

                                if (!await launchUrl(
                                  url,
                                  mode: LaunchMode.externalApplication,
                                )) {
                                  throw Exception('Could not launch $url');
                                }
                              },
                              borderRadius: BorderRadius.circular(999),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF4F46E5),
                                      Color(0xFF06B6D4),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.threed_rotation,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "360° website",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Material(
                      color: Colors.white,
                      elevation: 16,
                      shadowColor: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(22),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(22),
                        onTap: () async {
                          final result = await showDialog<Map<String, String>>(
                            context: context,
                            builder: (context) => const _FromToDialog(),
                          );

                          if (result != null &&
                              result['from'] != null &&
                              result['to'] != null &&
                              result['from']!.isNotEmpty &&
                              result['to']!.isNotEmpty) {
                            Navigator.pushNamed(
                              context,
                              '/navigator',
                              arguments: {
                                'from': result['from']!,
                                'to': result['to']!,
                              },
                            );
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          child: Row(
                            children: [
                              Container(
                                height: 36,
                                width: 36,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF4F46E5),
                                      Color(0xFF6366F1),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.navigation_outlined,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "Where to on campus?",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      "Tap to select from and to location",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.search,
                                color: Colors.black87,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _QuickChip(
                          icon: Icons.star_border,
                          label: "Events",
                          onTap: () {
                            Navigator.pushNamed(context, '/events');
                          },
                        ),
                        const SizedBox(width: 8),
                        _QuickChip(
                          icon: Icons.sports_soccer_outlined,
                          label: "Sports",
                          onTap: () {
                            Navigator.pushNamed(context, '/sports');
                          },
                        ),
                        const SizedBox(width: 8),
                        _QuickChip(
                          icon: Icons.school_outlined,
                          label: "IP / BTP",
                          onTap: () {
                            Navigator.pushNamed(context, '/ip_btp');
                          },
                        ),
                        const SizedBox(width: 8),
                        _QuickChip(
                          icon: Icons.health_and_safety_outlined,
                          label: "Safety",
                          onTap: () {
                            Navigator.pushNamed(context, '/campus_support');
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const CampusEssentialsStrip(),
                  ],
                ),
              ),
            ),
          ),

          /// Draggable bottom sheet: quick access to main features
          DraggableScrollableSheet(
            initialChildSize: 0.24,
            minChildSize: 0.22,
            maxChildSize: 0.55,
            builder: (context, scrollController) {
              return TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutBack,
                tween: Tween(begin: 0, end: 1),
                builder: (context, value, child) {
                  // easeOutBack overshoots past 1.0; Opacity must stay in [0, 1].
                  final o = value.clamp(0.0, 1.0);
                  return Transform.translate(
                    offset: Offset(0, (1 - o) * 40),
                    child: Opacity(opacity: o, child: child),
                  );
                },
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 16,
                        offset: Offset(0, -8),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          "Explore campus services",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _ActionTile(
                              icon: Icons.sports_soccer_outlined,
                              label: "Sports",
                              onTap: () {
                                Navigator.pushNamed(context, '/sports');
                              },
                            ),
                            _ActionTile(
                              icon: Icons.school_outlined,
                              label: "IP/BTP",
                              onTap: () {
                                Navigator.pushNamed(context, '/ip_btp');
                              },
                            ),
                            _ActionTile(
                              icon: Icons.calendar_today_outlined,
                              label: "Calendar",
                              onTap: () {
                                Navigator.pushNamed(context, '/calendar');
                              },
                            ),
                            _ActionTile(
                              icon: Icons.chat_bubble_outline,
                              label: "Chats",
                              onTap: () {
                                Navigator.pushNamed(context, '/chat_list');
                              },
                            ),
                            _ActionTile(
                              icon: Icons.event_note_outlined,
                              label: "Events",
                              onTap: () {
                                Navigator.pushNamed(context, '/events');
                              },
                            ),
                            _ActionTile(
                              icon: Icons.health_and_safety_outlined,
                              label: "Support",
                              onTap: () {
                                Navigator.pushNamed(context, '/campus_support');
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 10),
                        const Text(
                          "Top 5 features",
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _ServiceRow(
                          icon: Icons.sports_soccer_outlined,
                          title: "Sports Booking",
                          subtitle: "Live status, waitlist, admin approval",
                          onTap: () => Navigator.pushNamed(context, '/sports'),
                        ),
                        _ServiceRow(
                          icon: Icons.event_note_outlined,
                          title: "Events & Seminars",
                          subtitle: "Realtime updates and interest tracking",
                          onTap: () => Navigator.pushNamed(context, '/events'),
                        ),
                        _ServiceRow(
                          icon: Icons.chat_bubble_outline,
                          title: "Course & office chats",
                          subtitle: "Join with a code; office hours unlock for one hour",
                          onTap: () => Navigator.pushNamed(context, '/chat_list'),
                        ),
                        _ServiceRow(
                          icon: Icons.schedule_outlined,
                          title: "Professor Slots",
                          subtitle: "Search prof and book available slots",
                          onTap: () => Navigator.pushNamed(context, '/prof_slots'),
                        ),
                        _ServiceRow(
                          icon: Icons.health_and_safety_outlined,
                          title: "Safety & Support",
                          subtitle: "Emergency, medical and issue reporting",
                          onTap: () => Navigator.pushNamed(context, '/campus_support'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.16),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: Colors.white24,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: Colors.indigo.shade600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ServiceRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.035),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black.withOpacity(0.06)),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.indigo.shade600),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.black45),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FromToDialog extends StatefulWidget {
  const _FromToDialog({Key? key}) : super(key: key);

  @override
  State<_FromToDialog> createState() => _FromToDialogState();
}

class _FromToDialogState extends State<_FromToDialog> {
  final fromController = TextEditingController();
  final toController = TextEditingController();
  late final NavigationService _navigationService;
  List<String> _locationOptions = const [];
  bool _loadingOptions = true;

  @override
  void initState() {
    super.initState();
    _navigationService = NavigationService(Supabase.instance.client);
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    try {
      final places = await _navigationService.fetchPlaces();
      if (!mounted) return;
      setState(() {
        _locationOptions = places
            .map((p) {
              final name = p['name']?.toString().trim();
              if (name != null && name.isNotEmpty) return name;
              final placeName = p['place_name']?.toString().trim();
              return (placeName == null || placeName.isEmpty) ? null : placeName;
            })
            .whereType<String>()
            .toSet()
            .toList()
          ..sort();
        _loadingOptions = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingOptions = false);
    }
  }

  Iterable<String> _filterOptions(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return _locationOptions.take(12);
    return _locationOptions
        .where((option) => option.toLowerCase().contains(q))
        .take(12);
  }

  @override
  void dispose() {
    fromController.dispose();
    toController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Navigate on campus"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Autocomplete<String>(
            optionsBuilder: (textEditingValue) => _filterOptions(textEditingValue.text),
            onSelected: (value) => fromController.text = value,
            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
              if (controller.text.isEmpty && fromController.text.isNotEmpty) {
                controller.text = fromController.text;
                controller.selection = TextSelection.fromPosition(
                  TextPosition(offset: controller.text.length),
                );
              }
              return TextField(
                controller: controller,
                focusNode: focusNode,
                onChanged: (value) => fromController.text = value,
                decoration: InputDecoration(
                  labelText: "From",
                  hintText: _loadingOptions
                      ? "Loading locations..."
                      : "Type to search locations",
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Autocomplete<String>(
            optionsBuilder: (textEditingValue) => _filterOptions(textEditingValue.text),
            onSelected: (value) => toController.text = value,
            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
              if (controller.text.isEmpty && toController.text.isNotEmpty) {
                controller.text = toController.text;
                controller.selection = TextSelection.fromPosition(
                  TextPosition(offset: controller.text.length),
                );
              }
              return TextField(
                controller: controller,
                focusNode: focusNode,
                onChanged: (value) => toController.text = value,
                decoration: InputDecoration(
                  labelText: "To",
                  hintText: _loadingOptions
                      ? "Loading locations..."
                      : "Type to search locations",
                ),
              );
            },
          ),
          if (_locationOptions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Suggestions: ${_locationOptions.take(8).join(', ')}",
                style: const TextStyle(fontSize: 11, color: Colors.white70),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () async {
            final rawFrom = fromController.text.trim();
            final rawTo = toController.text.trim();
            if (rawFrom.isEmpty || rawTo.isEmpty) {
              return;
            }

            final resolvedFrom = await _navigationService.resolvePlaceName(rawFrom);
            final resolvedTo = await _navigationService.resolvePlaceName(rawTo);

            if (!mounted) return;
            if (resolvedFrom == null || resolvedTo == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Choose locations from the list or type a closer match.'),
                ),
              );
              return;
            }

            Navigator.pop<Map<String, String>>(context, {
              'from': resolvedFrom,
              'to': resolvedTo,
            });
          },
          child: const Text("Navigate"),
        ),
      ],
    );
  }
}

