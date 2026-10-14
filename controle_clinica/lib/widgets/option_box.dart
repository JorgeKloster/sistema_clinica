import 'package:flutter/material.dart';

class OptionBox extends StatelessWidget {
  final String title;
  final List<OptionItem> options;

  const OptionBox({super.key, required this.title, required this.options});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          // Options list
          Column(
            children:
                options.map((opt) {
                  return ListTile(
                    leading: Icon(opt.icon, color: Colors.blue),
                    title: Text(opt.label),
                    onTap: opt.onTap,
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }
}

class OptionItem {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  OptionItem({required this.label, required this.icon, required this.onTap});
}
