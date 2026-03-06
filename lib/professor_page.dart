import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfessorPage extends StatefulWidget {
  const ProfessorPage({super.key});

  @override
  State<ProfessorPage> createState() => _ProfessorPageState();
}

class _ProfessorPageState extends State<ProfessorPage> {

  final supabase = Supabase.instance.client;

  List professors = [];

  @override
  void initState() {
    super.initState();
    fetchProfessors();
  }

  Future<void> fetchProfessors() async {
    final response = await supabase
        .from('professors')
        .select();

    print("DATA FROM DB:");
    print(response);

    setState(() {
      professors = response;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Professors")),
      body: ListView.builder(
        itemCount: professors.length,
        itemBuilder: (context, index) {

          final prof = professors[index];
          String? imageUrl;
          if (prof['image'] != null && prof['image'].toString().isNotEmpty) {
            imageUrl = supabase.storage
                .from('professor-images')
                .getPublicUrl(prof['image']);
          }

          return Card(
            child: ListTile(
              leading: imageUrl != null
                  ? Image.network(
                      imageUrl,
                      width: 50,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.person),
                    )
                  : const Icon(Icons.person),
              title: Text(prof['name'] ?? 'Unknown'),
              subtitle: Text("Room: "+(prof['room']?.toString() ?? 'N/A')),
            ),
          );
        },
      ),
    );
  }
}