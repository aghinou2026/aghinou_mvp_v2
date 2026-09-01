import 'package:flutter/material.dart';

const aghPrimary = Color(0xFF6C3FE8);
const aghSecondary = Color(0xFF00A896);
const aghSurface = Color(0xFFFFFFFF);
const aghBackground = Color(0xFFF7F5FF);

class AghinouSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  const AghinouSearchBar({super.key, required this.controller, this.onChanged});

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        onChanged: onChanged,
        textDirection: TextDirection.rtl,
        decoration: InputDecoration(
          hintText: 'چی می‌خوای پیدا کنی؟',
          prefixIcon: const Icon(Icons.search_rounded),
          filled: true,
          fillColor: aghSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
        ),
      );
}

class AghinouSectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const AghinouSectionTitle({super.key, required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900))),
          if (action != null)
            TextButton(onPressed: onAction, child: Text(action!)),
        ],
      );
}

class AghinouCategoryTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const AghinouCategoryTile({super.key, required this.title, required this.icon, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: 94,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .09),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: .12)),
          ),
          child: Column(
            children: [
              CircleAvatar(radius: 25, backgroundColor: color.withValues(alpha: .15), child: Icon(icon, color: color)),
              const SizedBox(height: 7),
              Text(title, maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
            ],
          ),
        ),
      );
}

class AghinouEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  const AghinouEmptyState({super.key, required this.icon, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            CircleAvatar(radius: 36, backgroundColor: aghPrimary.withValues(alpha: .10), child: Icon(icon, size: 38, color: aghPrimary)),
            const SizedBox(height: 14),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            if (subtitle != null) ...[
              const SizedBox(height: 7),
              Text(subtitle!, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ]),
        ),
      );
}
