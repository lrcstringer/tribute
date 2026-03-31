import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/circle.dart';
import '../../../domain/repositories/circle_repository.dart';
import '../../theme/app_theme.dart';

class CircleSettingsView extends StatefulWidget {
  final String circleId;
  final CircleSettings settings;
  const CircleSettingsView(
      {super.key, required this.circleId, required this.settings});

  @override
  State<CircleSettingsView> createState() => _CircleSettingsViewState();
}

class _CircleSettingsViewState extends State<CircleSettingsView> {
  late String _scriptureFocusPermission;
  late bool _pulseEnabled;
  late bool _eventsEnabled;
  late bool _habitsEnabled;
  late bool _encouragementsEnabled;
  bool _saving = false;
  String? _error;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _scriptureFocusPermission = widget.settings.scriptureFocusPermission;
    _pulseEnabled = true;
    _eventsEnabled = true;
    _habitsEnabled = true;
    _encouragementsEnabled = widget.settings.encouragementPromptsEnabled;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      appBar: AppBar(
        backgroundColor: MyWalkColor.charcoal,
        title: const Text('Circle Settings',
            style: TextStyle(
                color: MyWalkColor.warmWhite,
                fontSize: 17,
                fontWeight: FontWeight.w600)),
        iconTheme: const IconThemeData(color: MyWalkColor.warmWhite),
        actions: [
          if (_dirty)
            TextButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: MyWalkColor.golden))
                  : const Text('Save',
                      style: TextStyle(
                          color: MyWalkColor.golden,
                          fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          _sectionHeader('Scripture Focus'),
          const SizedBox(height: 8),
          _settingCard(
            title: 'Who can set Scripture focus?',
            subtitle: 'Controls who can choose the weekly passage.',
            child: _permissionToggle(
              value: _scriptureFocusPermission,
              onChanged: (v) => _update(() => _scriptureFocusPermission = v),
            ),
          ),
          const SizedBox(height: 20),
          _sectionHeader('Features'),
          const SizedBox(height: 8),
          _switchCard(
            icon: Icons.people_rounded,
            iconColor: _softPurple,
            title: 'Weekly Pulse',
            subtitle: 'Allow members to check in weekly.',
            value: _pulseEnabled,
            onChanged: (v) => _update(() => _pulseEnabled = v),
          ),
          const SizedBox(height: 8),
          _switchCard(
            icon: Icons.event_rounded,
            iconColor: MyWalkColor.sage,
            title: 'Events',
            subtitle: 'Schedule events for your circle.',
            value: _eventsEnabled,
            onChanged: (v) => _update(() => _eventsEnabled = v),
          ),
          const SizedBox(height: 8),
          _switchCard(
            icon: Icons.check_circle_outline_rounded,
            iconColor: MyWalkColor.golden,
            title: 'Circle Habits',
            subtitle: 'Create shared habits for your circle.',
            value: _habitsEnabled,
            onChanged: (v) => _update(() => _habitsEnabled = v),
          ),
          const SizedBox(height: 8),
          _switchCard(
            icon: Icons.favorite_rounded,
            iconColor: MyWalkColor.warmCoral,
            title: 'Encouragement Prompts',
            subtitle: 'Sunday nudge to encourage a circle member.',
            value: _encouragementsEnabled,
            onChanged: (v) => _update(() => _encouragementsEnabled = v),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Row(children: [
              const Icon(Icons.warning_amber_rounded,
                  size: 14, color: MyWalkColor.warmCoral),
              const SizedBox(width: 8),
              Expanded(
                child: Text(_error!,
                    style: const TextStyle(
                        fontSize: 12, color: MyWalkColor.warmCoral)),
              ),
            ]),
          ],
        ],
      ),
    );
  }

  void _update(VoidCallback fn) {
    setState(() {
      fn();
      _dirty = true;
    });
  }

  Widget _sectionHeader(String title) {
    return Text(title.toUpperCase(),
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.4),
            letterSpacing: 1.2));
  }

  Widget _settingCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: MyWalkDecorations.card,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: MyWalkColor.warmWhite)),
        const SizedBox(height: 3),
        Text(subtitle,
            style: TextStyle(
                fontSize: 12, color: Colors.white.withValues(alpha: 0.45))),
        const SizedBox(height: 12),
        child,
      ]),
    );
  }

  Widget _switchCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: MyWalkDecorations.card,
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor.withValues(alpha: 0.1)),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: MyWalkColor.warmWhite)),
            Text(subtitle,
                style: TextStyle(
                    fontSize: 12, color: Colors.white.withValues(alpha: 0.45))),
          ]),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: MyWalkColor.golden,
          activeTrackColor: MyWalkColor.golden.withValues(alpha: 0.4),
          inactiveThumbColor: MyWalkColor.softGold,
          inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
        ),
      ]),
    );
  }

  Widget _permissionToggle({
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return Row(children: [
      _permissionChip('admin', 'Admins only', value, onChanged),
      const SizedBox(width: 8),
      _permissionChip('any_member', 'All members', value, onChanged),
    ]);
  }

  Widget _permissionChip(
    String optionValue,
    String label,
    String current,
    ValueChanged<String> onChanged,
  ) {
    final selected = current == optionValue;
    return GestureDetector(
      onTap: () => onChanged(optionValue),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? MyWalkColor.golden.withValues(alpha: 0.12)
              : MyWalkColor.inputBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? MyWalkColor.golden.withValues(alpha: 0.4)
                : Colors.transparent,
          ),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: selected
                    ? MyWalkColor.golden
                    : Colors.white.withValues(alpha: 0.5))),
      ),
    );
  }

  Future<void> _save() async {
    setState(() { _saving = true; _error = null; });
    try {
      await context.read<CircleRepository>().updateCircleSettings(
        widget.circleId,
        CircleSettings(
          scriptureFocusPermission: _scriptureFocusPermission,
          encouragementPromptsEnabled: _encouragementsEnabled,
        ),
      );
      if (mounted) {
        setState(() { _saving = false; _dirty = false; });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Settings saved'),
          backgroundColor: MyWalkColor.cardBackground,
        ));
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _saving = false; });
    }
  }
}

const _softPurple = Color(0xFF9B8BB8);
