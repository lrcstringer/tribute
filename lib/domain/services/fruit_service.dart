import '../entities/fruit.dart';
import '../entities/habit.dart';

// ── MicroAction ────────────────────────────────────────────────────────────────

class MicroAction {
  final String id;
  final FruitType fruit;
  final String name;
  final String description;
  final HabitTrackingType trackingType;
  final double? targetValue;
  final String defaultFrequency; // 'daily' | 'weekly'
  final String purposeStatement;
  final String promptText;
  final String completionText;
  final String? anchorVerse;

  const MicroAction({
    required this.id,
    required this.fruit,
    required this.name,
    required this.description,
    required this.trackingType,
    this.targetValue,
    required this.defaultFrequency,
    required this.purposeStatement,
    required this.promptText,
    required this.completionText,
    this.anchorVerse,
  });
}

// ── FruitSuggestionService ─────────────────────────────────────────────────────

class FruitSuggestionService {
  const FruitSuggestionService._();

  /// Suggests fruits based on a subcategory ID (new system).
  /// Falls back to [suggest] via legacy enum if subcategoryId is unrecognised.
  static List<FruitType> suggestForSubcategory(String? subcategoryId) {
    return switch (subcategoryId) {
      'gods_word'               => [FruitType.faithfulness, FruitType.peace, FruitType.joy],
      'prayer'                  => [FruitType.peace, FruitType.faithfulness, FruitType.joy],
      'church_life'             => [FruitType.love, FruitType.kindness, FruitType.faithfulness],
      'evangelism'              => [FruitType.love, FruitType.goodness, FruitType.faithfulness],
      'worship'                 => [FruitType.joy, FruitType.love, FruitType.peace],
      'fasting'                 => [FruitType.selfControl, FruitType.patience, FruitType.faithfulness],
      'exercise'                => [FruitType.selfControl, FruitType.patience],
      'health_and_nutrition'    => [FruitType.selfControl, FruitType.patience],
      'rest_and_renewal'        => [FruitType.peace, FruitType.selfControl],
      'reading_and_learning'    => [FruitType.faithfulness, FruitType.patience],
      'creativity'              => [FruitType.joy, FruitType.goodness],
      'stewardship'             => [FruitType.faithfulness, FruitType.goodness],
      'breaking_habits'         => [FruitType.selfControl, FruitType.faithfulness],
      'service_and_generosity'  => [FruitType.love, FruitType.kindness, FruitType.goodness],
      'connection_and_community'=> [FruitType.love, FruitType.kindness, FruitType.gentleness],
      _                         => [],
    };
  }

  static List<FruitType> suggest(HabitCategory category) {
    switch (category) {
      case HabitCategory.exercise:
        return [FruitType.selfControl, FruitType.patience];
      case HabitCategory.scripture:
        return [FruitType.faithfulness, FruitType.peace, FruitType.joy];
      case HabitCategory.rest:
        return [FruitType.peace, FruitType.selfControl];
      case HabitCategory.fasting:
        return [FruitType.selfControl, FruitType.patience, FruitType.faithfulness];
      case HabitCategory.study:
        return [FruitType.faithfulness, FruitType.patience];
      case HabitCategory.service:
        return [FruitType.love, FruitType.kindness, FruitType.goodness];
      case HabitCategory.connection:
        return [FruitType.love, FruitType.kindness];
      case HabitCategory.health:
        return [FruitType.selfControl, FruitType.patience];
      case HabitCategory.abstain:
        return [FruitType.selfControl, FruitType.faithfulness];
      case HabitCategory.gratitude:
        return [FruitType.joy, FruitType.love];
      case HabitCategory.custom:
        return [];
    }
  }
}

// ── FruitPurposeStatements ─────────────────────────────────────────────────────

class FruitPurposeStatements {
  const FruitPurposeStatements._();

  static String defaultFor(HabitCategory category, FruitType fruit) {
    final key = '${category.name}_${fruit.name}';
    return _statements[key] ?? _fruitDefaults[fruit] ?? '';
  }

  static const Map<String, String> _statements = {
    // Exercise
    'exercise_selfControl': 'Disciplining my body is an act of stewardship.',
    'exercise_patience': 'Progress is built through faithfulness, not speed.',
    // Scripture
    'scripture_faithfulness': "I'm someone who puts God's Word first.",
    'scripture_peace': 'His Word is a lamp that brings peace to my path.',
    'scripture_joy': "God's Word fills me with a joy that circumstances can't touch.",
    // Rest
    'rest_peace': "Rest is an act of trust — I don't have to earn tomorrow.",
    'rest_selfControl': 'Choosing to stop is choosing to trust.',
    // Fasting
    'fasting_selfControl': 'Fasting teaches me that I am not ruled by my appetites.',
    'fasting_patience': 'Waiting on God is the highest use of hunger.',
    'fasting_faithfulness': 'Fasting is faithfulness made physical.',
    // Study
    'study_faithfulness': 'Growing my mind is an act of stewardship.',
    'study_patience': 'Deep understanding requires slow, patient thought.',
    // Service
    'service_love': 'Serving others is how I love them in action.',
    'service_kindness': 'Kindness is most real when it costs me something.',
    'service_goodness': 'Doing good for others shapes who I am becoming.',
    // Connection
    'connection_love': 'I was made for community — love is lived in relationship.',
    'connection_kindness': 'Small acts of kindness build lasting bonds.',
    // Health
    'health_selfControl': "My body is God's temple. Caring for it is an act of worship.",
    'health_patience': 'Good health is built slowly, one faithful choice at a time.',
    // Abstain
    'abstain_selfControl': 'God made me for freedom. This habit is how I walk in it.',
    'abstain_faithfulness': "Faithful in the small battles, faithful in the large ones.",
    // Gratitude
    'gratitude_joy': 'Gratitude trains my eyes to see the goodness already here.',
    'gratitude_love': 'Every good gift comes from above.',
  };

  static const Map<FruitType, String> _fruitDefaults = {
    FruitType.love:         'I am learning to love the way I have been loved.',
    FruitType.joy:          "Joy is a discipline — I'm training my attention on what is good.",
    FruitType.peace:        "Peace isn't the absence of problems. It's the presence of God.",
    FruitType.patience:     'Patience is love with a long fuse.',
    FruitType.kindness:     'Small acts of kindness are never small to the one receiving them.',
    FruitType.goodness:     'I am being made good — one choice at a time.',
    FruitType.faithfulness: "Faithfulness doesn't require perfection — just showing up.",
    FruitType.gentleness:   "Gentleness is not weakness — it's strength under God's control.",
    FruitType.selfControl:  "Self-control is the quiet power to choose what I actually want.",
  };
}

// ── MicroActionLibrary ─────────────────────────────────────────────────────────

class MicroActionLibrary {
  const MicroActionLibrary._();

  static List<MicroAction> actionsFor(FruitType fruit) =>
      _library[fruit] ?? const [];

  static List<MicroAction> get all =>
      FruitType.values.expand((f) => _library[f] ?? <MicroAction>[]).toList();

  static final Map<FruitType, List<MicroAction>> _library = {
    // ── Love ──────────────────────────────────────────────────────────────────
    FruitType.love: [
      const MicroAction(
        id: 'love_1',
        fruit: FruitType.love,
        name: 'Write a note of appreciation',
        description:
            'Write a brief note — handwritten or digital — telling someone a specific quality you appreciate about them.',
        trackingType: HabitTrackingType.checkIn,
        defaultFrequency: 'daily',
        purposeStatement: 'Love is most visible when it names what it sees.',
        promptText: 'Who did you express appreciation to today?',
        completionText: 'Love spoken becomes love received.',
        anchorVerse: '1 Thessalonians 5:11',
      ),
      const MicroAction(
        id: 'love_2',
        fruit: FruitType.love,
        name: 'Pray for someone difficult',
        description:
            'Spend 3 minutes in prayer for someone you find hard to love right now. Pray for their wellbeing, not their change.',
        trackingType: HabitTrackingType.timed,
        targetValue: 3,
        defaultFrequency: 'daily',
        purposeStatement: 'When prayer changes your heart, love follows.',
        promptText: 'Did you pray for someone who tests your love today?',
        completionText: 'Prayer softens the hardest hearts — beginning with our own.',
        anchorVerse: 'Matthew 5:44',
      ),
      const MicroAction(
        id: 'love_3',
        fruit: FruitType.love,
        name: 'Give your full attention',
        description:
            'Put down your phone and give someone your full, undivided attention for at least 10 minutes.',
        trackingType: HabitTrackingType.timed,
        targetValue: 10,
        defaultFrequency: 'daily',
        purposeStatement: 'Attention is one of the rarest forms of love.',
        promptText: 'Who did you give your full attention to today?',
        completionText: 'Love looks people in the eye.',
      ),
      const MicroAction(
        id: 'love_4',
        fruit: FruitType.love,
        name: 'Serve without being asked',
        description:
            'Do something helpful for someone without being asked and without mentioning it.',
        trackingType: HabitTrackingType.checkIn,
        defaultFrequency: 'daily',
        purposeStatement: 'Love acts before it is invited.',
        promptText: 'Did you serve someone today without being asked?',
        completionText: 'The greatest among you will be your servant.',
        anchorVerse: 'Matthew 23:11',
      ),
      const MicroAction(
        id: 'love_5',
        fruit: FruitType.love,
        name: 'Reach out to someone lonely',
        description:
            'Call, text, or visit someone who might be isolated or forgotten this week.',
        trackingType: HabitTrackingType.checkIn,
        defaultFrequency: 'weekly',
        purposeStatement: 'Love does not wait to be asked.',
        promptText: 'Did you reach out to someone who needed connection this week?',
        completionText: 'You saw someone. That is love.',
        anchorVerse: 'Romans 12:10',
      ),
    ],

    // ── Joy ───────────────────────────────────────────────────────────────────
    FruitType.joy: [
      const MicroAction(
        id: 'joy_1',
        fruit: FruitType.joy,
        name: 'Record moments of delight',
        description:
            'Write down three specific things that brought you delight today — even the smallest ones count.',
        trackingType: HabitTrackingType.count,
        targetValue: 3,
        defaultFrequency: 'daily',
        purposeStatement: 'Joy is a discipline of noticing.',
        promptText: 'What three delights did you record today?',
        completionText: 'A noticing heart becomes a joyful heart.',
        anchorVerse: 'Philippians 4:8',
      ),
      const MicroAction(
        id: 'joy_2',
        fruit: FruitType.joy,
        name: "Rest in God's presence",
        description:
            "Sit quietly for 10 minutes, not asking for anything — just resting in awareness of God's presence.",
        trackingType: HabitTrackingType.timed,
        targetValue: 10,
        defaultFrequency: 'daily',
        purposeStatement: "Joy is rooted in presence, not outcomes.",
        promptText: 'Did you rest in God today without an agenda?',
        completionText: 'In his presence there is fullness of joy.',
        anchorVerse: 'Psalm 16:11',
      ),
      const MicroAction(
        id: 'joy_3',
        fruit: FruitType.joy,
        name: 'Laugh with someone',
        description:
            'Share something genuinely funny or joyful with another person today. Joy multiplies when shared.',
        trackingType: HabitTrackingType.checkIn,
        defaultFrequency: 'daily',
        purposeStatement: 'A cheerful heart is good medicine.',
        promptText: 'Did you share joy with someone today?',
        completionText: 'Joy shared is joy doubled.',
        anchorVerse: 'Proverbs 17:22',
      ),
      const MicroAction(
        id: 'joy_4',
        fruit: FruitType.joy,
        name: 'Memorise a joy-filled verse',
        description:
            "Choose one verse this week that speaks of God's joy or delight and memorise it.",
        trackingType: HabitTrackingType.checkIn,
        defaultFrequency: 'weekly',
        purposeStatement: "God's Word carries a joy that circumstances can't touch.",
        promptText: 'Did you memorise your joy-filled verse this week?',
        completionText: "The Word hidden in your heart can't be taken away.",
        anchorVerse: 'Psalm 119:11',
      ),
      const MicroAction(
        id: 'joy_5',
        fruit: FruitType.joy,
        name: 'Praise God physically',
        description:
            'Express worship through your body — sing, dance, raise your hands — even for just 5 minutes.',
        trackingType: HabitTrackingType.timed,
        targetValue: 5,
        defaultFrequency: 'daily',
        purposeStatement: 'The joy of the Lord is your strength.',
        promptText: 'Did you express joyful worship today?',
        completionText: 'Your whole self belongs to the God who made it.',
        anchorVerse: 'Nehemiah 8:10',
      ),
    ],

    // ── Peace ─────────────────────────────────────────────────────────────────
    FruitType.peace: [
      const MicroAction(
        id: 'peace_2',
        fruit: FruitType.peace,
        name: 'Take one step toward peace',
        description:
            "Take one step toward resolving tension in a relationship — send a message, say sorry, or simply pray for the person.",
        trackingType: HabitTrackingType.checkIn,
        defaultFrequency: 'weekly',
        purposeStatement: 'As far as it depends on you, live at peace with everyone.',
        promptText: 'Did you take a step toward peace in a relationship this week?',
        completionText: 'Peacemakers are called children of God.',
        anchorVerse: 'Romans 12:18',
      ),
      const MicroAction(
        id: 'peace_3',
        fruit: FruitType.peace,
        name: 'Digital rest before bed',
        description:
            'Take a 30-minute break from all screens before bed, to let your mind settle.',
        trackingType: HabitTrackingType.timed,
        targetValue: 30,
        defaultFrequency: 'daily',
        purposeStatement: "Rest is not absence — it's trust made physical.",
        promptText: 'Did you rest from screens before bed tonight?',
        completionText: 'He grants sleep to those he loves.',
        anchorVerse: 'Psalm 127:2',
      ),
      const MicroAction(
        id: 'peace_4',
        fruit: FruitType.peace,
        name: 'Sit in silence',
        description:
            'Spend 5 minutes in complete quiet — no music, no podcasts, no phone. Just be.',
        trackingType: HabitTrackingType.timed,
        targetValue: 5,
        defaultFrequency: 'daily',
        purposeStatement: 'Be still and know that I am God.',
        promptText: 'Did you sit in silence today?',
        completionText: 'Stillness is where God is found.',
        anchorVerse: 'Psalm 46:10',
      ),
      const MicroAction(
        id: 'peace_5',
        fruit: FruitType.peace,
        name: 'Release a worry in prayer',
        description:
            'Write a specific worry on paper and consciously give it to God in prayer, then set the paper aside.',
        trackingType: HabitTrackingType.checkIn,
        defaultFrequency: 'daily',
        purposeStatement: 'Cast all your anxiety on him, because he cares for you.',
        promptText: 'Did you release a worry to God today?',
        completionText: 'You handed it over. It is no longer yours to carry.',
        anchorVerse: '1 Peter 5:7',
      ),
    ],

    // ── Patience ──────────────────────────────────────────────────────────────
    FruitType.patience: [
      const MicroAction(
        id: 'patience_1',
        fruit: FruitType.patience,
        name: 'Pause before responding',
        description:
            'When irritated or reactive, practise pausing for 10 seconds before you speak or reply.',
        trackingType: HabitTrackingType.checkIn,
        defaultFrequency: 'daily',
        purposeStatement: 'Patience is a muscle built one pause at a time.',
        promptText: 'Did you choose to pause before reacting today?',
        completionText: 'The one who is patient has great understanding.',
        anchorVerse: 'Proverbs 14:29',
      ),
      const MicroAction(
        id: 'patience_2',
        fruit: FruitType.patience,
        name: 'Wait without your phone',
        description:
            "Spend a waiting period — in a queue, in traffic, before a meeting — without reaching for your phone.",
        trackingType: HabitTrackingType.checkIn,
        defaultFrequency: 'daily',
        purposeStatement: 'Impatience reaches for distraction; patience sits still.',
        promptText: 'Did you wait patiently without filling the silence today?',
        completionText: 'You sat in the wait. That is patience.',
      ),
      const MicroAction(
        id: 'patience_3',
        fruit: FruitType.patience,
        name: 'Pray for the one who frustrated you',
        description:
            'At the end of the day, pray specifically for someone who tested your patience today.',
        trackingType: HabitTrackingType.checkIn,
        defaultFrequency: 'daily',
        purposeStatement: 'Patience toward others flows from grace received.',
        promptText: 'Did you pray for someone who tested your patience today?',
        completionText: 'Praying for them is one of the kindest things you can do.',
        anchorVerse: 'Colossians 3:12',
      ),
      const MicroAction(
        id: 'patience_4',
        fruit: FruitType.patience,
        name: 'Read slowly and deeply',
        description:
            'Read 10 pages of a book that requires thought — no skimming. Sit with the ideas.',
        trackingType: HabitTrackingType.timed,
        targetValue: 15,
        defaultFrequency: 'daily',
        purposeStatement: 'Patience learns to be still in a hurry.',
        promptText: 'Did you read slowly and attentively today?',
        completionText: 'Slow thought produces deep fruit.',
      ),
      const MicroAction(
        id: 'patience_5',
        fruit: FruitType.patience,
        name: 'Journal without an agenda',
        description:
            'Write for 15 minutes without a goal — just following your thoughts wherever they lead.',
        trackingType: HabitTrackingType.timed,
        targetValue: 15,
        defaultFrequency: 'weekly',
        purposeStatement: "Patience isn't passive — it's active trust.",
        promptText: 'Did you journal openly this week?',
        completionText: 'The unhurried mind discovers what the busy mind misses.',
      ),
    ],

    // ── Kindness ──────────────────────────────────────────────────────────────
    FruitType.kindness: [
      const MicroAction(
        id: 'kindness_1',
        fruit: FruitType.kindness,
        name: 'Do one kind thing for a stranger',
        description:
            'Perform a deliberate act of kindness for someone you do not know — hold a door, pay for a coffee, offer a compliment.',
        trackingType: HabitTrackingType.checkIn,
        defaultFrequency: 'daily',
        purposeStatement: 'Kindness that costs nothing is still kindness.',
        promptText: 'Did you show kindness to a stranger today?',
        completionText: 'Small kindnesses make a large world smaller.',
        anchorVerse: 'Galatians 6:10',
      ),
      const MicroAction(
        id: 'kindness_2',
        fruit: FruitType.kindness,
        name: 'Speak one encouraging word',
        description:
            'Deliberately say something specific and encouraging to someone in your life today.',
        trackingType: HabitTrackingType.checkIn,
        defaultFrequency: 'daily',
        purposeStatement: 'Gracious words are a honeycomb, sweet to the soul.',
        promptText: 'Did you speak a specific word of encouragement today?',
        completionText: 'Your words can carry more than you know.',
        anchorVerse: 'Proverbs 16:24',
      ),
      const MicroAction(
        id: 'kindness_3',
        fruit: FruitType.kindness,
        name: 'Bring a meal or gift',
        description:
            'Prepare or deliver food or a small gift for someone who needs it this week.',
        trackingType: HabitTrackingType.checkIn,
        defaultFrequency: 'weekly',
        purposeStatement: 'Kindness is love made tangible.',
        promptText: 'Did you bring someone a meal or gift this week?',
        completionText: 'You gave them something they could hold.',
        anchorVerse: 'Romans 12:13',
      ),
      const MicroAction(
        id: 'kindness_4',
        fruit: FruitType.kindness,
        name: 'Notice the overlooked',
        description:
            'Give attention to someone who is often ignored or sidelined — the quiet colleague, the overlooked neighbour.',
        trackingType: HabitTrackingType.checkIn,
        defaultFrequency: 'daily',
        purposeStatement: 'Who do you see that others walk past?',
        promptText: 'Did you notice and acknowledge someone who is often overlooked today?',
        completionText: 'Being seen is one of the deepest human needs. You met it today.',
      ),
      const MicroAction(
        id: 'kindness_5',
        fruit: FruitType.kindness,
        name: 'Volunteer an hour',
        description:
            'Give one hour of your time to serve others without expectation of anything in return.',
        trackingType: HabitTrackingType.timed,
        targetValue: 60,
        defaultFrequency: 'weekly',
        purposeStatement: 'Pure and undefiled religion is caring for the vulnerable.',
        promptText: 'Did you volunteer your time this week?',
        completionText: 'Time freely given is the most generous currency.',
        anchorVerse: 'James 1:27',
      ),
    ],

    // ── Goodness ──────────────────────────────────────────────────────────────
    FruitType.goodness: [
      const MicroAction(
        id: 'goodness_1',
        fruit: FruitType.goodness,
        name: 'Keep a private commitment',
        description:
            'Follow through on something you promised yourself, even if no one would know if you did not.',
        trackingType: HabitTrackingType.checkIn,
        defaultFrequency: 'daily',
        purposeStatement: "Goodness isn't for the audience. It's for the soul.",
        promptText: 'Did you keep a private commitment today?',
        completionText: 'Character is who you are when no one is watching.',
      ),
      const MicroAction(
        id: 'goodness_2',
        fruit: FruitType.goodness,
        name: 'Address one small dishonesty',
        description:
            'Notice and address one small dishonesty in your life — an excuse, a rationalisation, a silence that misled.',
        trackingType: HabitTrackingType.checkIn,
        defaultFrequency: 'weekly',
        purposeStatement: 'Goodness requires courage, not just warmth.',
        promptText: 'Did you address a small dishonesty in your life this week?',
        completionText: 'The truth makes us free, one small honesty at a time.',
        anchorVerse: 'John 8:32',
      ),
      const MicroAction(
        id: 'goodness_3',
        fruit: FruitType.goodness,
        name: 'Give without recognition',
        description:
            'Do something genuinely good today that no one will know you did. No credit, no mention.',
        trackingType: HabitTrackingType.checkIn,
        defaultFrequency: 'daily',
        purposeStatement: 'Do not let your left hand know what your right hand is doing.',
        promptText: 'Did you do something good today that no one will know about?',
        completionText: "Your Father who sees in secret rewards. That's enough.",
        anchorVerse: 'Matthew 6:3',
      ),
      const MicroAction(
        id: 'goodness_4',
        fruit: FruitType.goodness,
        name: 'Take one hard right step',
        description:
            "Name one choice you've been avoiding because it's hard. Take one concrete step toward it today.",
        trackingType: HabitTrackingType.checkIn,
        defaultFrequency: 'weekly',
        purposeStatement: 'Goodness is the will to do right when it is hard.',
        promptText: 'Did you take a step toward a hard right choice this week?',
        completionText: 'The right path is rarely the easy path.',
      ),
      const MicroAction(
        id: 'goodness_5',
        fruit: FruitType.goodness,
        name: 'Spend time with the overlooked',
        description:
            'Eat with, visit, or call someone who is often left out, marginalised, or forgotten.',
        trackingType: HabitTrackingType.checkIn,
        defaultFrequency: 'weekly',
        purposeStatement: 'Goodness has legs.',
        promptText: 'Did you spend time with someone who is often overlooked this week?',
        completionText: 'You did for the least of these.',
        anchorVerse: 'Matthew 25:40',
      ),
    ],

    // ── Faithfulness ──────────────────────────────────────────────────────────
    FruitType.faithfulness: [
      const MicroAction(
        id: 'faithfulness_1',
        fruit: FruitType.faithfulness,
        name: 'Show up on a hard day',
        description:
            'Complete one daily habit you committed to, even on a day when you do not feel like it.',
        trackingType: HabitTrackingType.checkIn,
        defaultFrequency: 'daily',
        purposeStatement: 'Faithfulness is what discipline looks like over time.',
        promptText: 'Did you show up for your habit even when it was hard today?',
        completionText: 'Faithfulness looks like this — one small yes.',
        anchorVerse: 'Luke 16:10',
      ),
      const MicroAction(
        id: 'faithfulness_2',
        fruit: FruitType.faithfulness,
        name: 'Keep a small promise',
        description:
            'Do something you said you would do, even if it feels small or inconvenient.',
        trackingType: HabitTrackingType.checkIn,
        defaultFrequency: 'daily',
        purposeStatement: 'Whoever can be trusted with a little can be trusted with much.',
        promptText: 'Did you keep a small promise today?',
        completionText: 'Your word is your character.',
        anchorVerse: 'Luke 16:10',
      ),
      const MicroAction(
        id: 'faithfulness_3',
        fruit: FruitType.faithfulness,
        name: 'Read the Bible every day',
        description:
            'Read at least a chapter of the Bible every day. No skimming — read to meet God.',
        trackingType: HabitTrackingType.checkIn,
        defaultFrequency: 'daily',
        purposeStatement: 'Faithfulness is fed by the Word.',
        promptText: 'Did you read your Bible today?',
        completionText: "God's Word is lamp to your feet.",
        anchorVerse: 'Psalm 119:105',
      ),
      const MicroAction(
        id: 'faithfulness_4',
        fruit: FruitType.faithfulness,
        name: 'Give faithfully',
        description:
            'Give or tithe this week as you committed to — consistently, regardless of circumstance.',
        trackingType: HabitTrackingType.checkIn,
        defaultFrequency: 'weekly',
        purposeStatement: 'Where your treasure is, there your heart will be also.',
        promptText: 'Did you give faithfully this week?',
        completionText: 'Giving is faith made financial.',
        anchorVerse: 'Matthew 6:21',
      ),
      const MicroAction(
        id: 'faithfulness_5',
        fruit: FruitType.faithfulness,
        name: 'Be reliable for someone',
        description:
            'Show up reliably for a person who is counting on you this week — no excuses, no delay.',
        trackingType: HabitTrackingType.checkIn,
        defaultFrequency: 'weekly',
        purposeStatement: 'A faithful person will be richly blessed.',
        promptText: 'Were you reliably there for someone who needed you this week?',
        completionText: 'You were someone they could count on.',
        anchorVerse: 'Proverbs 28:20',
      ),
    ],

    // ── Gentleness ────────────────────────────────────────────────────────────
    FruitType.gentleness: [
      const MicroAction(
        id: 'gentleness_1',
        fruit: FruitType.gentleness,
        name: 'Lower your voice',
        description:
            'The next time you feel the urge to escalate, deliberately lower your voice and slow your words.',
        trackingType: HabitTrackingType.checkIn,
        defaultFrequency: 'daily',
        purposeStatement: 'A gentle answer turns away wrath.',
        promptText: 'Did you choose a gentle response instead of escalating today?',
        completionText: 'Softness can do what force cannot.',
        anchorVerse: 'Proverbs 15:1',
      ),
      const MicroAction(
        id: 'gentleness_2',
        fruit: FruitType.gentleness,
        name: 'Speak gently to yourself',
        description:
            'Write one compassionate, gentle truth about yourself today — the kind of thing a good friend would say.',
        trackingType: HabitTrackingType.checkIn,
        defaultFrequency: 'daily',
        purposeStatement: 'You cannot give what you do not have.',
        promptText: 'Did you speak gently to yourself today?',
        completionText: "You are God's beloved. That doesn't change.",
      ),
      const MicroAction(
        id: 'gentleness_3',
        fruit: FruitType.gentleness,
        name: 'Respond, not react',
        description:
            'In a difficult moment today, take a breath and consciously choose your response rather than defaulting to your instinct.',
        trackingType: HabitTrackingType.checkIn,
        defaultFrequency: 'daily',
        purposeStatement: "Gentleness is strength under God's control.",
        promptText: 'Did you choose your response rather than react today?',
        completionText: 'Between stimulus and response, there is a space. You found it.',
      ),
      const MicroAction(
        id: 'gentleness_4',
        fruit: FruitType.gentleness,
        name: 'Listen without fixing',
        description:
            "Sit with someone who is hurting for at least 15 minutes — listen without offering solutions, advice, or silver linings.",
        trackingType: HabitTrackingType.timed,
        targetValue: 15,
        defaultFrequency: 'weekly',
        purposeStatement: 'Blessed are those who mourn, for they will be comforted.',
        promptText: 'Did you listen without fixing this week?',
        completionText: 'Presence is the most powerful thing you can offer.',
        anchorVerse: 'Matthew 5:4',
      ),
      const MicroAction(
        id: 'gentleness_5',
        fruit: FruitType.gentleness,
        name: 'Pray with open hands',
        description:
            'Spend 5 minutes in prayer with your palms open, facing upward — a physical posture of surrender and receptiveness.',
        trackingType: HabitTrackingType.timed,
        targetValue: 5,
        defaultFrequency: 'daily',
        purposeStatement: 'Let your gentleness be evident to all.',
        promptText: 'Did you pray with an open and surrendered heart today?',
        completionText: 'Open hands receive what clenched fists cannot.',
        anchorVerse: 'Philippians 4:5',
      ),
    ],

    // ── Self-Control ──────────────────────────────────────────────────────────
    FruitType.selfControl: [
      const MicroAction(
        id: 'selfcontrol_1',
        fruit: FruitType.selfControl,
        name: 'Delay a craving',
        description:
            'The next time you feel an impulse to indulge, wait 10 minutes before deciding. After 10 minutes, decide consciously.',
        trackingType: HabitTrackingType.checkIn,
        defaultFrequency: 'daily',
        purposeStatement: 'Self-control is the gap between impulse and action.',
        promptText: 'Did you pause before acting on a craving or impulse today?',
        completionText: 'You chose. The craving did not choose for you.',
      ),
      const MicroAction(
        id: 'selfcontrol_2',
        fruit: FruitType.selfControl,
        name: 'Limit social media',
        description:
            'Stay off social media for a defined block of time each day — set a specific window and keep it.',
        trackingType: HabitTrackingType.checkIn,
        defaultFrequency: 'daily',
        purposeStatement: 'You are not owned by what demands your attention.',
        promptText: 'Did you honour your social media limit today?',
        completionText: 'Attention directed is life directed.',
        anchorVerse: 'Philippians 4:8',
      ),
      const MicroAction(
        id: 'selfcontrol_3',
        fruit: FruitType.selfControl,
        name: 'Sleep at a consistent time',
        description:
            'Get to bed within 30 minutes of your goal bedtime, even when the evening feels unfinished.',
        trackingType: HabitTrackingType.checkIn,
        defaultFrequency: 'daily',
        purposeStatement: 'Discipline starts in the evening.',
        promptText: 'Did you go to bed on time tonight?',
        completionText: 'Rest is a form of self-control.',
        anchorVerse: 'Psalm 127:2',
      ),
      const MicroAction(
        id: 'selfcontrol_4',
        fruit: FruitType.selfControl,
        name: 'Fast from what controls you',
        description:
            'Fast for one day from something that has too much power over you — food, social media, entertainment, approval.',
        trackingType: HabitTrackingType.checkIn,
        defaultFrequency: 'weekly',
        purposeStatement: 'Self-control exposes what really has our heart.',
        promptText: 'Did you fast from something that controls you this week?',
        completionText: 'You are free. This is the evidence.',
        anchorVerse: '1 Corinthians 9:27',
      ),
      const MicroAction(
        id: 'selfcontrol_5',
        fruit: FruitType.selfControl,
        name: 'Guard your words',
        description:
            'Go through at least one full conversation without complaining, criticising, or boasting.',
        trackingType: HabitTrackingType.checkIn,
        defaultFrequency: 'daily',
        purposeStatement: 'The one who guards their mouth keeps their life.',
        promptText: 'Did you guard your words in a conversation today?',
        completionText: 'Words restrained make space for words that matter.',
        anchorVerse: 'Proverbs 21:23',
      ),
    ],
  };
}
