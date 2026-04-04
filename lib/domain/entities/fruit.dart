import 'package:flutter/material.dart';

enum FruitType {
  love,
  joy,
  peace,
  patience,
  kindness,
  goodness,
  faithfulness,
  gentleness,
  selfControl;

  static FruitType fromString(String value) {
    return FruitType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => FruitType.love,
    );
  }
}

extension FruitTypeX on FruitType {
  String get label {
    switch (this) {
      case FruitType.love:          return 'Love';
      case FruitType.joy:           return 'Joy';
      case FruitType.peace:         return 'Peace';
      case FruitType.patience:      return 'Patience';
      case FruitType.kindness:      return 'Kindness';
      case FruitType.goodness:      return 'Goodness';
      case FruitType.faithfulness:  return 'Faithfulness';
      case FruitType.gentleness:    return 'Gentleness';
      case FruitType.selfControl:   return 'Self-Control';
    }
  }

  IconData get icon {
    switch (this) {
      case FruitType.love:          return Icons.favorite;
      case FruitType.joy:           return Icons.wb_sunny;
      case FruitType.peace:         return Icons.spa;
      case FruitType.patience:      return Icons.hourglass_empty;
      case FruitType.kindness:      return Icons.volunteer_activism;
      case FruitType.goodness:      return Icons.star;
      case FruitType.faithfulness:  return Icons.anchor;
      case FruitType.gentleness:    return Icons.air;
      case FruitType.selfControl:   return Icons.shield;
    }
  }

  Color get color {
    switch (this) {
      case FruitType.love:          return const Color(0xFFC62828);
      case FruitType.joy:           return const Color(0xFFF9A825);
      case FruitType.peace:         return const Color(0xFF29B6F6);
      case FruitType.patience:      return const Color(0xFF8D6E63);
      case FruitType.kindness:      return const Color(0xFFFF7043);
      case FruitType.goodness:      return const Color(0xFF2E7D32);
      case FruitType.faithfulness:  return const Color(0xFF283593);
      case FruitType.gentleness:    return const Color(0xFFAB47BC);
      case FruitType.selfControl:   return const Color(0xFF00695C);
    }
  }

  String get greekWord {
    switch (this) {
      case FruitType.love:          return 'agapē';
      case FruitType.joy:           return 'chara';
      case FruitType.peace:         return 'eirēnē';
      case FruitType.patience:      return 'makrothymia';
      case FruitType.kindness:      return 'chrēstotēs';
      case FruitType.goodness:      return 'agathōsynē';
      case FruitType.faithfulness:  return 'pistis';
      case FruitType.gentleness:    return 'prautēs';
      case FruitType.selfControl:   return 'enkrateia';
    }
  }

  String get shortDescription {
    switch (this) {
      case FruitType.love:          return 'Unconditional love that serves before it feels';
      case FruitType.joy:           return "Delight rooted in God's presence, not circumstances";
      case FruitType.peace:         return 'Deep rest and wholeness, even amid uncertainty';
      case FruitType.patience:      return "Enduring grace that doesn't snap under pressure";
      case FruitType.kindness:      return 'Warmth and goodness expressed in everyday acts';
      case FruitType.goodness:      return 'Doing right because you are being made right';
      case FruitType.faithfulness:  return 'Consistent trust and reliability in small things';
      case FruitType.gentleness:    return "Calm strength that doesn't need to force or defend";
      case FruitType.selfControl:   return 'The quiet power to choose well';
    }
  }

  String get checkInPrompt {
    switch (this) {
      case FruitType.love:
        return 'Did you act out of love today, even when it was hard?';
      case FruitType.joy:
        return "Where did you find delight in God's presence today?";
      case FruitType.peace:
        return "Did you rest in God's peace today, even amid uncertainty?";
      case FruitType.patience:
        return 'Did you respond with patient grace today?';
      case FruitType.kindness:
        return 'Did you show kindness in an everyday moment today?';
      case FruitType.goodness:
        return 'Did you choose to do right today, even when no one was watching?';
      case FruitType.faithfulness:
        return 'Were you faithful in a small thing today?';
      case FruitType.gentleness:
        return 'Did you respond with gentle strength today?';
      case FruitType.selfControl:
        return 'Did you choose well in a moment of temptation today?';
    }
  }

  String get completionMessage {
    switch (this) {
      case FruitType.love:         return 'Love is patient, love is kind.';
      case FruitType.joy:          return 'The joy of the Lord is your strength.';
      case FruitType.peace:        return "The peace of God guards your heart.";
      case FruitType.patience:     return 'Let perseverance finish its work.';
      case FruitType.kindness:     return "A kind word can change someone's day.";
      case FruitType.goodness:     return 'Well done, good and faithful servant.';
      case FruitType.faithfulness: return "You've been faithful with a little.";
      case FruitType.gentleness:   return 'Blessed are the meek.';
      case FruitType.selfControl:  return 'You have the mind of Christ.';
    }
  }

  FruitVerse get keyVerse {
    switch (this) {
      case FruitType.love:
        return const FruitVerse(
          '\u201cAnd now these three remain: faith, hope and love. But the greatest of these is love.\u201d',
          '1 Corinthians 13:13',
        );
      case FruitType.joy:
        return const FruitVerse(
          '\u201cThe joy of the Lord is your strength.\u201d',
          'Nehemiah 8:10',
        );
      case FruitType.peace:
        return const FruitVerse(
          '\u201cAnd the peace of God, which transcends all understanding, will guard your hearts and your minds in Christ Jesus.\u201d',
          'Philippians 4:7',
        );
      case FruitType.patience:
        return const FruitVerse(
          '\u201cBut if we hope for what we do not yet have, we wait for it patiently.\u201d',
          'Romans 8:25',
        );
      case FruitType.kindness:
        return const FruitVerse(
          '\u201cBe kind and compassionate to one another, forgiving each other, just as in Christ God forgave you.\u201d',
          'Ephesians 4:32',
        );
      case FruitType.goodness:
        return const FruitVerse(
          '\u201cDo not be overcome by evil, but overcome evil with good.\u201d',
          'Romans 12:21',
        );
      case FruitType.faithfulness:
        return const FruitVerse(
          '\u201cWell done, good and faithful servant! You have been faithful with a few things; I will put you in charge of many things.\u201d',
          'Matthew 25:23',
        );
      case FruitType.gentleness:
        return const FruitVerse(
          '\u201cLet your gentleness be known to all men. The Lord is at hand.\u201d',
          'Philippians 4:5',
        );
      case FruitType.selfControl:
        return const FruitVerse(
          '\u201cFor the Spirit God gave us does not make us timid, but gives us power, love and self-discipline.\u201d',
          '2 Timothy 1:7',
        );
    }
  }

  List<FruitVerse> get supportingVerses {
    switch (this) {
      case FruitType.love:
        return const [
          FruitVerse('\u201cWe love because he first loved us.\u201d', '1 John 4:19'),
          FruitVerse(
            '\u201cLove suffers long and is kind; love does not envy; love does not parade itself, is not puffed up; does not behave rudely, does not seek its own, is not provoked, thinks no evil; does not rejoice in iniquity, but rejoices in the truth; bears all things, believes all things, hopes all things, endures all things. Love never fails.\u201d',
            '1 Corinthians 13:4\u20138',
          ),
          FruitVerse('\u201cGreater love has no one than this: to lay down one\u2019s life for one\u2019s friends.\u201d', 'John 15:13'),
          FruitVerse(
            '\u201cFor I am convinced that neither death nor life, neither angels nor demons, neither the present nor the future, nor any powers, neither height nor depth, nor anything else in all creation, will be able to separate us from the love of God that is in Christ Jesus our Lord.\u201d',
            'Romans 8:38\u201339',
          ),
        ];
      case FruitType.joy:
        return const [
          FruitVerse(
            '\u201cRejoice always, pray without ceasing, in everything give thanks; for this is the will of God in Christ Jesus for you.\u201d',
            '1 Thessalonians 5:16\u201317',
          ),
          FruitVerse(
            '\u201cYou make known to me the path of life; you will fill me with joy in your presence, with eternal pleasures at your right hand.\u201d',
            'Psalm 16:11',
          ),
        ];
      case FruitType.peace:
        return const [
          FruitVerse('\u201cYou will keep in perfect peace those whose minds are steadfast, because they trust in you.\u201d', 'Isaiah 26:3'),
          FruitVerse('\u201cPeace I leave with you; my peace I give you. I do not give to you as the world gives. Do not let your hearts be troubled and do not be afraid.\u201d', 'John 14:27'),
          FruitVerse('\u201cTherefore, since we have been justified through faith, we have peace with God through our Lord Jesus Christ.\u201d', 'Romans 5:1'),
        ];
      case FruitType.patience:
        return const [
          FruitVerse(
            '\u201cBecause you know that the testing of your faith produces perseverance. Let perseverance finish its work so that you may be mature and complete, not lacking anything.\u201d',
            'James 1:3\u20134',
          ),
          FruitVerse(
            '\u201cThe Lord is good to those whose hope is in him, to the one who seeks him; it is good to wait quietly for the salvation of the Lord.\u201d',
            'Lamentations 3:25\u201326',
          ),
          FruitVerse(
            '\u201cLet us run with perseverance the race marked out for us, fixing our eyes on Jesus, the pioneer and perfecter of faith.\u201d',
            'Hebrews 12:1',
          ),
          FruitVerse(
            '\u201cFor what credit is it if, when you are beaten for your faults, you take it patiently? But when you do good and suffer, if you take it patiently, this is commendable before God. For to this you were called, because Christ also suffered for us, leaving us an example, that you should follow His steps.\u201d',
            '1 Peter 2:20\u201321',
          ),
        ];
      case FruitType.kindness:
        return const [
          FruitVerse(
            '\u201cTherefore, as God\u2019s chosen people, holy and dearly loved, clothe yourselves with compassion, kindness, humility, gentleness and patience.\u201d',
            'Colossians 3:12',
          ),
          FruitVerse('\u201cThe Lord bless him! He has not stopped showing his kindness to the living and the dead.\u201d', 'Ruth 2:20'),
        ];
      case FruitType.goodness:
        return const [
          FruitVerse('\u201cSurely your goodness and love will follow me all the days of my life.\u201d', 'Psalm 23:6'),
          FruitVerse('\u201cTaste and see that the Lord is good; blessed is the one who takes refuge in him.\u201d', 'Psalm 34:8'),
          FruitVerse(
            '\u201cI myself am convinced, my brothers and sisters, that you yourselves are full of goodness, filled with knowledge and competent to instruct one another.\u201d',
            'Romans 15:14',
          ),
          FruitVerse(
            '\u201cYou have heard that it was said, \u2018You shall love your neighbour and hate your enemy.\u2019 But I say to you, love your enemies, bless those who curse you, do good to those who hate you, and pray for those who spitefully use you and persecute you, that you may be sons of your Father in heaven; for He makes His sun rise on the evil and on the good, and sends rain on the just and on the unjust.\u201d',
            'Matthew 5:43\u201348',
          ),
        ];
      case FruitType.faithfulness:
        return const [
          FruitVerse(
            '\u201cBecause of the Lord\u2019s great love we are not consumed, for his compassions never fail. They are new every morning; great is your faithfulness.\u201d',
            'Lamentations 3:22\u201323',
          ),
          FruitVerse(
            '\u201cLet love and faithfulness never leave you; bind them around your neck, write them on the tablet of your heart. Then you will win favour and a good name in the sight of God and man.\u201d',
            'Proverbs 3:3\u20134',
          ),
          FruitVerse('\u201cNow it is required that those who have been given a trust must prove faithful.\u201d', '1 Corinthians 4:2'),
          FruitVerse('\u201cSo then faith comes by hearing, and hearing by the word of God.\u201d', 'Romans 10:17'),
        ];
      case FruitType.gentleness:
        return const [
          FruitVerse('\u201cA gentle answer turns away wrath, but a harsh word stirs up anger.\u201d', 'Proverbs 15:1'),
          FruitVerse(
            '\u201cRather, it should be that of your inner self, the unfading beauty of a gentle and quiet spirit, which is of great worth in God\u2019s sight.\u201d',
            '1 Peter 3:4',
          ),
          FruitVerse('\u201cAnd a servant of the Lord must not quarrel but be gentle to all, able to teach, patient.\u201d', '2 Timothy 2:24'),
          FruitVerse('\u201cNow Moses was a very humble man, more humble than anyone else on the face of the earth.\u201d', 'Numbers 12:3'),
          FruitVerse('\u201cTake my yoke upon you and learn from me, for I am gentle and humble in heart, and you will find rest for your souls.\u201d', 'Matthew 11:29'),
        ];
      case FruitType.selfControl:
        return const [
          FruitVerse('\u201cAnd a servant of the Lord must not quarrel but be gentle to all, able to teach, patient.\u201d', '2 Timothy 2:24'),
          FruitVerse('\u201cLike a city whose walls are broken through is a person who lacks self-control.\u201d', 'Proverbs 25:28'),
          FruitVerse(
            '\u201cEveryone who competes in the games goes into strict training. They do it to get a crown that will not last, but we do it to get a crown that will last forever. Therefore I do not run like someone running aimlessly; I do not fight like a boxer beating the air. No, I strike a blow to my body and make it my slave so that after I have preached to others, I myself will not be disqualified for the prize.\u201d',
            '1 Corinthians 9:25\u201327',
          ),
          FruitVerse(
            '\u201cFor the grace of God has appeared that offers salvation to all people. It teaches us to say no to ungodliness and worldly passions, and to live self-controlled, upright and godly lives in this present age.\u201d',
            'Titus 2:11\u201312',
          ),
        ];
    }
  }
}

class FruitVerse {
  final String text;
  final String reference;
  const FruitVerse(this.text, this.reference);
}

// ── Portfolio data ─────────────────────────────────────────────────────────────

class FruitPortfolioEntry {
  final FruitType fruit;
  final int habitCount;
  final int totalCompletions;
  final int weeklyCompletions;
  final DateTime? lastCompletedAt;
  final int currentStreak;
  final int longestStreak;

  const FruitPortfolioEntry({
    required this.fruit,
    this.habitCount = 0,
    this.totalCompletions = 0,
    this.weeklyCompletions = 0,
    this.lastCompletedAt,
    this.currentStreak = 0,
    this.longestStreak = 0,
  });

  FruitPortfolioEntry copyWith({
    int? habitCount,
    int? totalCompletions,
    int? weeklyCompletions,
    DateTime? lastCompletedAt,
    int? currentStreak,
    int? longestStreak,
  }) =>
      FruitPortfolioEntry(
        fruit: fruit,
        habitCount: habitCount ?? this.habitCount,
        totalCompletions: totalCompletions ?? this.totalCompletions,
        weeklyCompletions: weeklyCompletions ?? this.weeklyCompletions,
        lastCompletedAt: lastCompletedAt ?? this.lastCompletedAt,
        currentStreak: currentStreak ?? this.currentStreak,
        longestStreak: longestStreak ?? this.longestStreak,
      );

  Map<String, dynamic> toFirestore() => {
        'fruit': fruit.name,
        'habitCount': habitCount,
        'totalCompletions': totalCompletions,
        'weeklyCompletions': weeklyCompletions,
        'lastCompletedAt': lastCompletedAt?.toIso8601String(),
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
      };

  factory FruitPortfolioEntry.fromFirestore(Map<String, dynamic> data) {
    DateTime? lastCompleted;
    final raw = data['lastCompletedAt'];
    if (raw is String) lastCompleted = DateTime.tryParse(raw);

    return FruitPortfolioEntry(
      fruit: FruitType.fromString(data['fruit'] as String? ?? ''),
      habitCount: (data['habitCount'] as num?)?.toInt() ?? 0,
      totalCompletions: (data['totalCompletions'] as num?)?.toInt() ?? 0,
      weeklyCompletions: (data['weeklyCompletions'] as num?)?.toInt() ?? 0,
      lastCompletedAt: lastCompleted,
      currentStreak: (data['currentStreak'] as num?)?.toInt() ?? 0,
      longestStreak: (data['longestStreak'] as num?)?.toInt() ?? 0,
    );
  }
}

class FruitPortfolio {
  final Map<FruitType, FruitPortfolioEntry> entries;

  const FruitPortfolio({required this.entries});

  factory FruitPortfolio.empty() => FruitPortfolio(
        entries: {
          for (final f in FruitType.values)
            f: FruitPortfolioEntry(fruit: f),
        },
      );

  FruitPortfolioEntry entryFor(FruitType fruit) =>
      entries[fruit] ?? FruitPortfolioEntry(fruit: fruit);

  List<FruitType> get activeFruits => FruitType.values
      .where((f) => (entries[f]?.habitCount ?? 0) > 0)
      .toList();

  List<FruitType> get neglectedFruits => FruitType.values
      .where((f) => (entries[f]?.habitCount ?? 0) == 0)
      .toList();

  FruitType? get dominantFruit {
    FruitType? top;
    int topCount = 0;
    for (final f in FruitType.values) {
      final count = entries[f]?.weeklyCompletions ?? 0;
      if (count > topCount) {
        topCount = count;
        top = f;
      }
    }
    return top;
  }

  /// Percentage of fruits that have at least one weekly completion (0–100).
  int get weeklyBalance {
    final withCompletions =
        FruitType.values.where((f) => (entries[f]?.weeklyCompletions ?? 0) > 0).length;
    return (withCompletions / FruitType.values.length * 100).round();
  }
}
