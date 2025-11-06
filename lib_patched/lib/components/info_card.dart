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
        backgroundColor: Colors.white24,
        child: Icon(CupertinoIcons.person),
      ),
      title: Text(name),
      subtitle: Text(profession),
    );
  }
}
