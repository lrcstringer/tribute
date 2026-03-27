import 'habit.dart';

class Scripture {
  final String text;
  final String reference;

  const Scripture({required this.text, required this.reference});
}

class ScriptureLibrary {
  static Scripture anchorVerse(HabitCategory category) {
    switch (category) {
      case HabitCategory.exercise:
        return const Scripture(text: 'Do you not know that your bodies are temples of the Holy Spirit, who is in you, whom you have received from God? You are not your own; you were bought at a price. Therefore honour God with your bodies.', reference: '1 Corinthians 6:19\u201320');
      case HabitCategory.scripture:
        return const Scripture(text: 'Keep this Book of the Law always on your lips; meditate on it day and night, so that you may be careful to do everything written in it.', reference: 'Joshua 1:8');
      case HabitCategory.rest:
        return const Scripture(text: 'In vain you rise early and stay up late, toiling for food to eat \u2014 for he grants sleep to those he loves.', reference: 'Psalm 127:2');
      case HabitCategory.fasting:
        return const Scripture(text: 'When you fast, put oil on your head and wash your face, so that it will not be obvious to others that you are fasting, but only to your Father, who is unseen.', reference: 'Matthew 6:17\u201318');
      case HabitCategory.study:
        return const Scripture(text: 'Do not conform to the pattern of this world, but be transformed by the renewing of your mind.', reference: 'Romans 12:2');
      case HabitCategory.service:
        return const Scripture(text: 'And let us consider how we may spur one another on towards love and good deeds.', reference: 'Hebrews 10:24');
      case HabitCategory.connection:
        return const Scripture(text: 'As iron sharpens iron, so one person sharpens another.', reference: 'Proverbs 27:17');
      case HabitCategory.health:
        return const Scripture(text: 'Do you not know that your bodies are temples of the Holy Spirit, who is in you, whom you have received from God?', reference: '1 Corinthians 6:19');
      case HabitCategory.abstain:
        return const Scripture(text: 'No temptation has overtaken you except what is common to mankind. And God is faithful; he will not let you be tempted beyond what you can bear.', reference: '1 Corinthians 10:13');
      case HabitCategory.custom:
        return const Scripture(text: 'Whatever you do, whether in word or deed, do it all in the name of the Lord Jesus, giving thanks to God the Father through him.', reference: 'Colossians 3:17');
      case HabitCategory.gratitude:
        return const Scripture(text: 'Give thanks in all circumstances; for this is God\u2019s will for you in Christ Jesus.', reference: '1 Thessalonians 5:18');
    }
  }

  static List<Scripture> companionVerses(HabitCategory category) {
    switch (category) {
      case HabitCategory.exercise:
        return const [
          Scripture(text: 'I praise you because I am fearfully and wonderfully made.', reference: 'Psalm 139:14'),
          Scripture(text: 'Whatever you do, work at it with all your heart, as working for the Lord.', reference: 'Colossians 3:23'),
          Scripture(text: 'Therefore, I urge you, brothers and sisters, in view of God\u2019s mercy, to offer your bodies as a living sacrifice.', reference: 'Romans 12:1'),
          Scripture(text: 'She sets about her work vigorously; her arms are strong for her tasks.', reference: 'Proverbs 31:17'),
          Scripture(text: 'Physical training is of some value, but godliness has value for all things.', reference: '1 Timothy 4:8'),
        ];
      case HabitCategory.scripture:
        return const [
          Scripture(text: 'Your word is a lamp for my feet, a light on my path.', reference: 'Psalm 119:105'),
          Scripture(text: 'All Scripture is God-breathed and is useful for teaching, rebuking, correcting and training in righteousness.', reference: '2 Timothy 3:16\u201317'),
          Scripture(text: 'The unfolding of your words gives light; it gives understanding to the simple.', reference: 'Psalm 119:130'),
          Scripture(text: 'Let the message of Christ dwell among you richly as you teach and admonish one another with all wisdom.', reference: 'Colossians 3:16'),
          Scripture(text: 'For the word of God is alive and active. Sharper than any double-edged sword.', reference: 'Hebrews 4:12'),
        ];
      case HabitCategory.rest:
        return const [
          Scripture(text: 'Come to me, all you who are weary and burdened, and I will give you rest.', reference: 'Matthew 11:28'),
          Scripture(text: 'He makes me lie down in green pastures, he leads me beside quiet waters, he refreshes my soul.', reference: 'Psalm 23:2\u20133'),
          Scripture(text: "Come with me by yourselves to a quiet place and get some rest.", reference: 'Mark 6:31'),
          Scripture(text: 'There remains, then, a Sabbath-rest for the people of God.', reference: 'Hebrews 4:9'),
          Scripture(text: 'Be still, and know that I am God.', reference: 'Psalm 46:10'),
        ];
      case HabitCategory.fasting:
        return const [
          Scripture(text: 'Man shall not live on bread alone, but on every word that comes from the mouth of God.', reference: 'Matthew 4:4'),
          Scripture(text: 'Is not this the kind of fasting I have chosen: to loose the chains of injustice?', reference: 'Isaiah 58:6'),
          Scripture(text: 'But when you fast, put oil on your head and wash your face.', reference: 'Matthew 6:17'),
          Scripture(text: 'So we fasted and petitioned our God about this, and he answered our prayer.', reference: 'Ezra 8:23'),
          Scripture(text: 'Then you will call on me and come and pray to me, and I will listen to you.', reference: 'Jeremiah 29:12'),
        ];
      case HabitCategory.study:
        return const [
          Scripture(text: 'The fear of the Lord is the beginning of wisdom, and knowledge of the Holy One is understanding.', reference: 'Proverbs 9:10'),
          Scripture(text: 'An intelligent heart acquires knowledge, and the ear of the wise seeks knowledge.', reference: 'Proverbs 18:15'),
          Scripture(text: 'Study to show thyself approved unto God, a workman that needeth not to be ashamed.', reference: '2 Timothy 2:15'),
          Scripture(text: 'For the Lord gives wisdom; from his mouth come knowledge and understanding.', reference: 'Proverbs 2:6'),
          Scripture(text: 'If any of you lacks wisdom, you should ask God, who gives generously to all without finding fault.', reference: 'James 1:5'),
        ];
      case HabitCategory.service:
        return const [
          Scripture(text: 'Each of you should use whatever gift you have received to serve others.', reference: '1 Peter 4:10'),
          Scripture(text: 'Love your neighbour as yourself.', reference: 'Matthew 22:39'),
          Scripture(text: "Carry each other\u2019s burdens, and in this way you will fulfil the law of Christ.", reference: 'Galatians 6:2'),
          Scripture(text: 'For even the Son of Man did not come to be served, but to serve.', reference: 'Mark 10:45'),
          Scripture(text: 'Whoever wants to become great among you must be your servant.', reference: 'Matthew 20:26'),
        ];
      case HabitCategory.connection:
        return const [
          Scripture(text: 'The prayer of a righteous person is powerful and effective.', reference: 'James 5:16'),
          Scripture(text: 'Two are better than one, because they have a good return for their labor.', reference: 'Ecclesiastes 4:9'),
          Scripture(text: 'A friend loves at all times, and a brother is born for a time of adversity.', reference: 'Proverbs 17:17'),
          Scripture(text: 'Therefore encourage one another and build each other up, just as in fact you are doing.', reference: '1 Thessalonians 5:11'),
          Scripture(text: 'Let us not give up meeting together, as some are in the habit of doing, but let us encourage one another.', reference: 'Hebrews 10:25'),
        ];
      case HabitCategory.health:
        return const [
          Scripture(text: 'I praise you because I am fearfully and wonderfully made; your works are wonderful, I know that full well.', reference: 'Psalm 139:14'),
          Scripture(text: 'Therefore, I urge you, brothers and sisters, in view of God\u2019s mercy, to offer your bodies as a living sacrifice, holy and pleasing to God.', reference: 'Romans 12:1'),
          Scripture(text: 'So whether you eat or drink or whatever you do, do it all for the glory of God.', reference: '1 Corinthians 10:31'),
          Scripture(text: 'Dear friend, I pray that you may enjoy good health and that all may go well with you.', reference: '3 John 1:2'),
          Scripture(text: 'She gets up while it is still night; she provides food for her family and portions for her female servants.', reference: 'Proverbs 31:15'),
        ];
      case HabitCategory.abstain:
        return const [
          Scripture(text: 'It is for freedom that Christ has set us free. Stand firm, then, and do not let yourselves be burdened again by a yoke of slavery.', reference: 'Galatians 5:1'),
          Scripture(text: 'I can do all this through him who gives me strength.', reference: 'Philippians 4:13'),
          Scripture(text: 'Submit yourselves, then, to God. Resist the devil, and he will flee from you.', reference: 'James 4:7'),
          Scripture(text: 'The Lord is my strength and my shield; my heart trusts in him, and he helps me.', reference: 'Psalm 28:7'),
          Scripture(text: 'Create in me a pure heart, O God, and renew a steadfast spirit within me.', reference: 'Psalm 51:10'),
        ];
      case HabitCategory.custom:
        return const [
          Scripture(text: 'Commit to the Lord whatever you do, and he will establish your plans.', reference: 'Proverbs 16:3'),
          Scripture(text: 'Whatever you do, work at it with all your heart, as working for the Lord, not for human masters.', reference: 'Colossians 3:23'),
          Scripture(text: 'But the fruit of the Spirit is love, joy, peace, forbearance, kindness, goodness, faithfulness, gentleness and self-control.', reference: 'Galatians 5:22\u201323'),
          Scripture(text: "Well done, good and faithful servant!", reference: 'Matthew 25:21'),
          Scripture(text: 'And let us not grow weary of doing good, for in due season we will reap, if we do not give up.', reference: 'Galatians 6:9'),
        ];
      case HabitCategory.gratitude:
        return const [
          Scripture(text: 'Every good and perfect gift is from above.', reference: 'James 1:17'),
          Scripture(text: 'Enter his gates with thanksgiving and his courts with praise.', reference: 'Psalm 100:4'),
          Scripture(text: 'I will give thanks to the Lord with my whole heart.', reference: 'Psalm 9:1'),
          Scripture(text: 'Let the peace of Christ rule in your hearts, since as members of one body you were called to peace. And be thankful.', reference: 'Colossians 3:15'),
          Scripture(text: 'Rejoice always, pray continually, give thanks in all circumstances.', reference: '1 Thessalonians 5:16\u201318'),
        ];
    }
  }

  static Scripture rotatingVerse(HabitCategory category, DateTime date) {
    final verses = companionVerses(category);
    if (verses.isEmpty) return anchorVerse(category);

    final weekOfYear = _weekOfYear(date);
    final weekday = date.weekday % 7; // 0=Sun..6=Sat
    final weekSeed = weekOfYear * 7;
    final shuffled = _seededShuffle(verses, weekSeed);
    final index = weekday % shuffled.length;
    return shuffled[index];
  }

  static Scripture completionVerse(HabitCategory category, DateTime date, {required bool isPremium}) {
    if (isPremium) return rotatingVerse(category, date);
    return anchorVerse(category);
  }

  static int _weekOfYear(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    final diff = date.difference(startOfYear).inDays;
    return (diff / 7).floor();
  }

  static List<Scripture> _seededShuffle(List<Scripture> array, int seed) {
    final result = List<Scripture>.from(array);
    var rng = seed;
    for (int i = result.length - 1; i >= 1; i--) {
      rng = ((rng * 1103515245) + 12345) & 0x7fffffff;
      final j = rng % (i + 1);
      final tmp = result[i];
      result[i] = result[j];
      result[j] = tmp;
    }
    return result;
  }
}
