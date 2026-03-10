import 'package:flutter/material.dart';
import '../../core/session_manager.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// Background (Uber-like map placeholder)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF111827),
                    Color(0xFF020617),
                  ],
                ),
              ),
              child: Opacity(
                opacity: 0.12,
                child: Image.asset(
                  "assets/images/old_academic.jpg",
                  fit: BoxFit.cover,
                ),
              ),
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
                          "assets/images/logo.jpg",
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
                        Navigator.pushNamed(context, "/dashboard");
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
            ),
          ),

          /// Center search card (Uber-style "Where to?")
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 110, left: 16, right: 16),
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
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
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
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      InkWell(
                        onTap: () {
                          // You can later open a real 360 view URL here.
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("360° Street View coming soon"),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.16),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white30),
                          ),
                          child: const Icon(
                            Icons.threed_rotation,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Material(
                    color: Colors.white,
                    elevation: 10,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
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
                          // Open navigation page with from/to
                          // You can plug this into your node-to-node engine
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
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Container(
                              height: 32,
                              width: 32,
                              decoration: const BoxDecoration(
                                color: Color(0xFF4F46E5),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.navigation_outlined,
                                color: Colors.white,
                                size: 18,
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
                                      fontWeight: FontWeight.w600,
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
                        label: "Favourites",
                        onTap: () {
                          Navigator.pushNamed(context, '/events');
                        },
                      ),
                      const SizedBox(width: 8),
                      _QuickChip(
                        icon: Icons.history,
                        label: "Recent",
                        onTap: () {
                          Navigator.pushNamed(context, '/sports');
                        },
                      ),
                      const SizedBox(width: 8),
                      _QuickChip(
                        icon: Icons.school_outlined,
                        label: "Departments",
                        onTap: () {
                          Navigator.pushNamed(context, '/ip_btp');
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          /// Bottom feature panel: quick access to main features
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 170,
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
              child: Padding(
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
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          label: "Chat",
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
                      ],
                    ),
                  ],
                ),
              ),
            ),
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

class _FromToDialog extends StatefulWidget {
  const _FromToDialog({Key? key}) : super(key: key);

  @override
  State<_FromToDialog> createState() => _FromToDialogState();
}

class _FromToDialogState extends State<_FromToDialog> {
  final fromController = TextEditingController();
  final toController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Navigate on campus"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: fromController,
            decoration: const InputDecoration(
              labelText: "From",
              hintText: "e.g. Hostel, Gate, Block A",
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: toController,
            decoration: const InputDecoration(
              labelText: "To",
              hintText: "e.g. Library, CSE Dept, Ground",
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop<Map<String, String>>(context, {
              'from': fromController.text.trim(),
              'to': toController.text.trim(),
            });
          },
          child: const Text("Navigate"),
        ),
      ],
    );
  }
}

