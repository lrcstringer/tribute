import 'package:flutter/material.dart';

/// Defines the visual skin for all journalling screens.
///
/// Only 6 semantic color roles + a hero image are needed — everything
/// else (fruit chip colors, recording-ring red/amber, fullscreen viewer
/// black) is either domain data or a fixed functional color that must
/// not vary with the skin.
class JournalTheme {
  final String id;
  final String name;

  /// Main scaffold background.
  final Color bgPrimary;

  /// Card surfaces, inputs, dialogs, bottom sheets.
  final Color bgCard;

  /// Body text, headings, icon fills on light surfaces.
  final Color textPrimary;

  /// Hints, metadata, secondary labels, dividers, subtle borders.
  final Color textSecondary;

  /// Every interactive/tappable element: buttons, sliders, FAB accent,
  /// mic & playback controls.
  final Color accentAction;

  /// Subtle non-interactive container tints (upload banner, dividers).
  final Color accentMuted;

  /// Hero image shown at the top of the journal list.
  final String heroImageAsset;

  const JournalTheme({
    required this.id,
    required this.name,
    required this.bgPrimary,
    required this.bgCard,
    required this.textPrimary,
    required this.textSecondary,
    required this.accentAction,
    required this.accentMuted,
    required this.heroImageAsset,
  });

  // ── Built-in themes ───────────────────────────────────────────────────────

  /// Warm cream/parchment — the default.
  static const parchment = JournalTheme(
    id: 'parchment',
    name: 'Parchment',
    bgPrimary:    Color(0xFFF3EDE2),
    bgCard:       Color(0xFFFBF7F0),
    textPrimary:  Color(0xFF5B4B3E),
    textSecondary:Color(0xFF7A6B5D),
    accentAction: Color(0xFFD4A843),
    accentMuted:  Color(0xFFDCE3D6),
    heroImageAsset: 'assets/Journalling.png',
  );

  /// Deep navy with sage-green accents — for quiet evening reflection.
  static const nightGarden = JournalTheme(
    id: 'night_garden',
    name: 'Night Garden',
    bgPrimary:    Color(0xFF1A1F2E),
    bgCard:       Color(0xFF232A3B),
    textPrimary:  Color(0xFFE8E4DC),
    textSecondary:Color(0xFF8A96A8),
    accentAction: Color(0xFF7A9E7E),
    accentMuted:  Color(0xFF2A3828),
    heroImageAsset: 'assets/Journalling.png',
  );

  /// Clean bright linen — minimal, distraction-free writing.
  static const linen = JournalTheme(
    id: 'linen',
    name: 'Linen',
    bgPrimary:    Color(0xFFFAFAF8),
    bgCard:       Color(0xFFFFFFFF),
    textPrimary:  Color(0xFF2C2826),
    textSecondary:Color(0xFF6E6560),
    accentAction: Color(0xFFD4A843),
    accentMuted:  Color(0xFFEDF2ED),
    heroImageAsset: 'assets/Journalling.png',
  );

  static const all = [parchment, nightGarden, linen];
}
