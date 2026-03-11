import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/session_manager.dart';

class BookCourtPage extends StatefulWidget {
  final String arenaName;

  const BookCourtPage({super.key, required this.arenaName});

  @override
  State<BookCourtPage> createState() => _BookCourtPageState();
}

class _BookCourtPageState extends State<BookCourtPage> {
  final emailController = TextEditingController();
  final otpController = TextEditingController();

  static final Map<String, DateTime> _blockedUntilByEmail = {};

  DateTime? _bookingCreatedAt;
  Timer? _timer;
  bool _banSetForCurrentBooking = false;

  String get _status {
    if (_bookingCreatedAt == null) return "No active booking";
    final diff = DateTime.now().difference(_bookingCreatedAt!);
    if (diff.inMinutes >= 60) return "Slot finished";
    if (diff.inMinutes >= 10) {
      // mark user as banned for 12 hours if not already done
      if (!_banSetForCurrentBooking && emailController.text.isNotEmpty) {
        _blockedUntilByEmail[emailController.text.trim()] =
            DateTime.now().add(const Duration(hours: 12));
        _banSetForCurrentBooking = true;
      }
      return "Cancelled (did not reach in 10 mins)";
    }
    return "Active (reach arena within 10 mins)";
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _bookSlot() {
    if (emailController.text.isEmpty || otpController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter email and OTP")),
      );
      return;
    }

    final email = emailController.text.trim();
    final blockedUntil = _blockedUntilByEmail[email];
    if (blockedUntil != null && blockedUntil.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "You missed a previous booking. You can book again after ${blockedUntil.toLocal()}",
          ),
        ),
      );
      return;
    }

    setState(() {
      _bookingCreatedAt = DateTime.now();
      _banSetForCurrentBooking = false;
    });
    _startTimer();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Booked ${widget.arenaName} for 1 hour as ${SessionManager.role ?? 'user'}",
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    emailController.dispose();
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final role = SessionManager.role ?? 'user';
    final start = _bookingCreatedAt;
    final end = start?.add(const Duration(hours: 1));

    return Scaffold(
      appBar: AppBar(title: Text('Book ${widget.arenaName}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Booking as $role",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Your campus email",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "OTP (from email / gate system)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _bookSlot,
                  child: const Text("Confirm 1-hour booking"),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Slot details",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text("Status: $_status"),
              if (start != null && end != null) ...[
                const SizedBox(height: 4),
                Text("From: $start"),
                Text("To:   $end"),
              ],
              const SizedBox(height: 16),
              const Text(
                "Rule: If you do not reach the arena within 10 minutes of booking, "
                "the slot is considered cancelled and you cannot book again for the next 12 hours.",
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

