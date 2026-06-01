import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_app/theme/app_theme.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static const List<String> _fontFamilies = [
    'Default',
    'Courier New',
    'Georgia',
    'Trebuchet MS',
  ];

  static const List<Map<String, dynamic>> _accentPresets = [
    {'label': 'Cyan', 'color': Colors.cyanAccent},
    {'label': 'Teal', 'color': Color(0xFF00FFB3)},
    {'label': 'Violet', 'color': Color(0xFFAA80FF)},
    {'label': 'Amber', 'color': Colors.amberAccent},
    {'label': 'Rose', 'color': Color(0xFFFF6B9D)},
    {'label': 'Lime', 'color': Color(0xFFB8FF5B)},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();

    return Scaffold(
      backgroundColor: theme.baseBg,
      appBar: AppBar(
        backgroundColor: theme.baseBg,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.primaryTextColor),
        title: Text(
          'Settings',
          style: TextStyle(
            color: theme.primaryTextColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => context.read<AppTheme>().reset(),
            child: Text(
              'Reset',
              style: TextStyle(
                color: theme.accentColor.withValues(alpha: 0.8),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPreviewCard(theme),
            const SizedBox(height: 28),

            _buildSection(
              theme: theme,
              title: 'Font Size',
              icon: Icons.text_fields_outlined,
              child: _buildFontSizeControl(theme, context),
            ),
            const SizedBox(height: 16),

            _buildSection(
              theme: theme,
              title: 'Font Family',
              icon: Icons.font_download_outlined,
              child: _buildFontFamilyControl(theme, context),
            ),
            const SizedBox(height: 16),

            _buildSection(
              theme: theme,
              title: 'Accent Color',
              icon: Icons.palette_outlined,
              child: _buildAccentColorControl(theme, context),
            ),
            const SizedBox(height: 16),

            _buildSection(
              theme: theme,
              title: 'Background Brightness',
              icon: Icons.brightness_6_outlined,
              child: _buildBrightnessControl(theme, context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard(AppTheme theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.surfaceBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.accentColor.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: theme.accentColor.withValues(alpha: 0.06),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.preview_outlined, color: theme.accentColor, size: 16),
              const SizedBox(width: 8),
              Text(
                'Preview',
                style: TextStyle(
                  color: theme.accentColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Wuthering Wares',
            style: TextStyle(
              color: theme.primaryTextColor,
              fontSize: theme.fontSize + 4,
              fontWeight: FontWeight.bold,
              fontFamily: theme.fontFamily == 'Default' ? null : theme.fontFamily,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your trusted marketplace for Resonators, Echoes, and rare materials from the Huanglong region.',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: theme.fontSize,
              fontFamily: theme.fontFamily == 'Default' ? null : theme.fontFamily,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.accentColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  'Shop Now',
                  style: TextStyle(
                    color: theme.accentColor,
                    fontSize: theme.fontSize - 1,
                    fontWeight: FontWeight.w700,
                    fontFamily: theme.fontFamily == 'Default' ? null : theme.fontFamily,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '4,750 G available',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: theme.fontSize - 1,
                  fontFamily: theme.fontFamily == 'Default' ? null : theme.fontFamily,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required AppTheme theme,
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.surfaceBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: theme.accentColor, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: theme.primaryTextColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildFontSizeControl(AppTheme theme, BuildContext context) {
    return Column(
      children: [
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: theme.accentColor,
            inactiveTrackColor: theme.borderColor,
            thumbColor: theme.accentColor,
            overlayColor: theme.accentColor.withValues(alpha: 0.12),
            trackHeight: 3,
          ),
          child: Slider(
            value: theme.fontSize,
            min: 11,
            max: 20,
            divisions: 9,
            onChanged: (v) => context.read<AppTheme>().setFontSize(v),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Small', style: TextStyle(color: Colors.grey[600], fontSize: 11)),
            Text(
              '${theme.fontSize.toStringAsFixed(0)} pt',
              style: TextStyle(
                color: theme.accentColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text('Large', style: TextStyle(color: Colors.grey[600], fontSize: 11)),
          ],
        ),
      ],
    );
  }

  Widget _buildFontFamilyControl(AppTheme theme, BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _fontFamilies.map((family) {
        final selected = theme.fontFamily == family;
        return GestureDetector(
          onTap: () => context.read<AppTheme>().setFontFamily(family),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? theme.accentColor.withValues(alpha: 0.15)
                  : theme.borderColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected
                    ? theme.accentColor.withValues(alpha: 0.6)
                    : theme.borderColor,
              ),
            ),
            child: Text(
              family,
              style: TextStyle(
                color: selected ? theme.accentColor : Colors.grey[400],
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                fontFamily: family == 'Default' ? null : family,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAccentColorControl(AppTheme theme, BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _accentPresets.map((preset) {
        final color = preset['color'] as Color;
        final selected = theme.accentColor.value == color.value;
        return GestureDetector(
          onTap: () => context.read<AppTheme>().setAccentColor(color),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.2),
              border: Border.all(
                color: selected ? color : color.withValues(alpha: 0.3),
                width: selected ? 2.5 : 1,
              ),
              boxShadow: selected
                  ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 10)]
                  : [],
            ),
            child: Center(
              child: AnimatedOpacity(
                opacity: selected ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Icon(Icons.check_rounded, color: color, size: 18),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBrightnessControl(AppTheme theme, BuildContext context) {
    final modes = [
      (BgMode.dark,  Icons.nightlight_round,  'Dark',  'Default dark theme'),
      (BgMode.light, Icons.wb_sunny_outlined, 'Light', 'Bright with dark text'),
      (BgMode.amoled,Icons.circle,            'AMOLED','Pure black, battery saver'),
    ];

    return Row(
      children: modes.map((entry) {
        final (mode, icon, label, subtitle) = entry;
        final selected = theme.bgMode == mode;
        return Expanded(
          child: GestureDetector(
            onTap: () => context.read<AppTheme>().setBgMode(mode),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: selected
                    ? theme.accentColor.withValues(alpha: 0.12)
                    : theme.surfaceBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? theme.accentColor : theme.borderColor,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(icon,
                      color: selected ? theme.accentColor : Colors.grey[500],
                      size: 20),
                  const SizedBox(height: 6),
                  Text(label,
                      style: TextStyle(
                        color: selected ? theme.accentColor : Colors.grey[400],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      )),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], fontSize: 9)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}