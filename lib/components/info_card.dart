import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class InfoCard extends StatelessWidget {
  const InfoCard({
    required this.name,
    required this.profession,
    super.key,
  });

  final String name, profession;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: Icon(CupertinoIcons.person),
        backgroundColor: Colors.white24,
      ),
      title: Text(name),
      subtitle: Text(profession),
    );
  }
}
