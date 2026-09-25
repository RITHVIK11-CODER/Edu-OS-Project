import 'package:flutter/material.dart';

class EduHeader extends StatelessWidget {
  const EduHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.black54,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon ?? Icons.arrow_forward_rounded),
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Text(label),
        ),
      ),
    );
  }
}

class ProgressCard extends StatelessWidget {
  const ProgressCard({
    super.key,
    required this.title,
    required this.value,
    required this.status,
  });

  final String title;
  final int value;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text('$value%'),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: value / 100,
              minHeight: 8,
              borderRadius: BorderRadius.circular(20),
            ),
            const SizedBox(height: 8),
            Text(
              status,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.black54,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class InfoChip extends StatelessWidget {
  const InfoChip({super.key, required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 17),
      label: Text(label),
    );
  }
}
