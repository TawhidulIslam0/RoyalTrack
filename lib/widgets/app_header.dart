import 'package:flutter/material.dart';
class AppHeader extends StatelessWidget {
  const AppHeader({super.key, this.subtitle});
  final String? subtitle;
  @override Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
    child: Row(children: [
      Container(width: 42, height: 42, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.emoji_events_rounded, color: Colors.white)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('ROYALTRACK', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        if (subtitle != null) Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
      ])),
    ]),
  );
}
