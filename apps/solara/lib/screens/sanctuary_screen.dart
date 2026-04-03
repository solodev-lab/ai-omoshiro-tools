import 'package:flutter/material.dart';
import '../theme/solara_colors.dart';
import '../widgets/glass_panel.dart';

class SanctuaryScreen extends StatelessWidget {
  const SanctuaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.2,
          colors: [Color(0xFF0C1D3A), Color(0xFF080C14)],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              Center(
                child: Text(
                  'SANCTUARY',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: SolaraColors.solaraGold,
                    letterSpacing: 3.0,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Your Alignment',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              const SizedBox(height: 32),

              // Profile Section
              _SectionTitle('COSMIC PROFILE'),
              const SizedBox(height: 12),
              GlassPanel(
                child: Column(
                  children: [
                    _SettingsRow(
                      icon: Icons.person_outline,
                      label: 'Cosmic Name',
                      value: 'Solar Spark',
                    ),
                    const Divider(color: SolaraColors.glassBorder, height: 24),
                    _SettingsRow(
                      icon: Icons.cake_outlined,
                      label: 'Birth Date',
                      value: 'March 15, 1992',
                    ),
                    const Divider(color: SolaraColors.glassBorder, height: 24),
                    _SettingsRow(
                      icon: Icons.access_time,
                      label: 'Birth Time',
                      value: '14:30',
                    ),
                    const Divider(color: SolaraColors.glassBorder, height: 24),
                    _SettingsRow(
                      icon: Icons.location_on_outlined,
                      label: 'Birth City',
                      value: 'Los Angeles, CA',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Sleep Settings
              _SectionTitle('SANCTUARY SLEEP'),
              const SizedBox(height: 12),
              GlassPanel(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.nightlight_round,
                                color: SolaraColors.textSecondary, size: 20),
                            const SizedBox(width: 12),
                            Text('Silent Hours',
                                style: Theme.of(context).textTheme.bodyLarge),
                          ],
                        ),
                        Switch(
                          value: true,
                          onChanged: (_) {},
                          activeTrackColor: SolaraColors.solaraGold,
                          thumbColor: WidgetStatePropertyAll(
                            SolaraColors.solaraGoldLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('11:00 PM — 7:00 AM',
                            style: Theme.of(context).textTheme.bodyMedium),
                        Icon(Icons.chevron_right,
                            color: SolaraColors.textSecondary.withValues(alpha: 0.5)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Subscription
              _SectionTitle('COSMIC PRO'),
              const SizedBox(height: 12),
              GlassPanel(
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  children: [
                    const Icon(Icons.auto_awesome,
                        color: SolaraColors.solaraGold, size: 32),
                    const SizedBox(height: 12),
                    Text(
                      'Unlock the Full Galaxy',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: SolaraColors.textPrimary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Aether Shader · Galaxy Archive · Astro Insights',
                      style: Theme.of(context).textTheme.labelSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          colors: [
                            SolaraColors.solaraGoldLight,
                            SolaraColors.solaraGold,
                          ],
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          '\$9.99/month · 7-day free trial',
                          style: TextStyle(
                            color: Color(0xFF080C14),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'or \$49.99/year (save 58%)',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: SolaraColors.solaraGold.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Restore
              Center(
                child: TextButton(
                  onPressed: () {},
                  child: Text(
                    'Restore Purchase',
                    style: TextStyle(
                      color: SolaraColors.textSecondary.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        letterSpacing: 2.0,
        color: SolaraColors.textSecondary.withValues(alpha: 0.6),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: SolaraColors.textSecondary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
        ),
        Text(value, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
