class SupportingBeatitudeVerse {
  final String text;
  final String ref;
  const SupportingBeatitudeVerse({required this.text, required this.ref});
}

class BeatitudePractice {
  final String text;
  final String habit; // e.g. 'Prayer', 'God\'s Word'
  const BeatitudePractice({required this.text, required this.habit});
}

class BeatitudeModel {
  final int number;
  final String title;
  final String verse;
  final String verseRef;
  final String promise;
  final String yourWhy;
  final String whatThisMeans;
  final String keyVerse;
  final String keyVerseRef;
  final String reflectionQuestion;
  final List<BeatitudePractice> practices;
  final List<String> fruitConnection;
  final List<SupportingBeatitudeVerse> supportingVerses;
  final String imagePath;

  const BeatitudeModel({
    required this.number,
    required this.title,
    required this.verse,
    required this.verseRef,
    required this.promise,
    required this.yourWhy,
    required this.whatThisMeans,
    required this.keyVerse,
    required this.keyVerseRef,
    required this.reflectionQuestion,
    required this.practices,
    required this.fruitConnection,
    required this.supportingVerses,
    required this.imagePath,
  });
}

const List<BeatitudeModel> kBeatitudes = [
  BeatitudeModel(
    number: 1,
    title: 'Poor in Spirit',
    verse: 'Blessed are the poor in spirit, for theirs is the kingdom of heaven.',
    verseRef: 'Matthew 5:3',
    promise: 'theirs is the kingdom of heaven',
    yourWhy: 'I come to God with empty hands because that is the only way to receive what He is offering — and the kingdom belongs not to those who have it together, but to those who know they don\'t.',
    whatThisMeans: 'To be poor in spirit is to recognise your complete spiritual bankruptcy before God — no self-sufficiency, no hidden reserves of goodness to rely on. It is the opposite of pride. It is the posture of someone who has stopped pretending and started depending. Jesus places this first because it is the gateway to everything else — nothing else in the Beatitudes is possible without it.',
    keyVerse: 'God opposes the proud but gives grace to the humble.',
    keyVerseRef: 'James 4:6',
    reflectionQuestion: 'Where am I still relying on my own strength, goodness or competence instead of coming to God with open hands?',
    practices: [
      BeatitudePractice(text: 'Begin each day this week with a written prayer of dependence — acknowledging specifically what you cannot do without God', habit: 'Prayer'),
      BeatitudePractice(text: 'Confess to God one area where spiritual pride has crept in', habit: 'Prayer'),
      BeatitudePractice(text: 'Read and meditate on Psalm 51 — David\'s prayer from the place of bankruptcy', habit: 'God\'s Word'),
      BeatitudePractice(text: 'Fast from self-promotion for one day — say nothing about your own achievements or abilities', habit: 'Fasting'),
      BeatitudePractice(text: 'Memorise James 4:6 and return to it when you feel self-sufficient', habit: 'God\'s Word'),
    ],
    fruitConnection: ['Gentleness', 'Faithfulness', 'Self-Control'],
    supportingVerses: [
      SupportingBeatitudeVerse(text: 'For thus says the One who is high and lifted up, who inhabits eternity, whose name is Holy: \'I dwell in the high and holy place, and also with him who is of a contrite and lowly spirit, to revive the spirit of the lowly, and to revive the heart of the contrite.\'', ref: 'Isaiah 57:15'),
      SupportingBeatitudeVerse(text: 'The sacrifices of God are a broken spirit; a broken and contrite heart, O God, you will not despise.', ref: 'Psalm 51:17'),
      SupportingBeatitudeVerse(text: 'Humble yourselves before the Lord, and he will exalt you.', ref: 'James 4:10'),
      SupportingBeatitudeVerse(text: 'For everyone who exalts himself will be humbled, and he who humbles himself will be exalted.', ref: 'Luke 14:11'),
    ],
    imagePath: 'assets/beatitudes_golden_etched_separate/1_poor_in_spirit.png',
  ),
  BeatitudeModel(
    number: 2,
    title: 'Those Who Mourn',
    verse: 'Blessed are those who mourn, for they shall be comforted.',
    verseRef: 'Matthew 5:4',
    promise: 'they shall be comforted',
    yourWhy: 'I bring my grief to God rather than bury it — because the comfort He promises is only found on the other side of honesty, and He is close to the brokenhearted.',
    whatThisMeans: 'This is not a blessing on sadness in general but on a specific kind of mourning — grieving over sin, over the brokenness of the world, over the distance between what is and what God intended. It is the grief of someone who takes both God and reality seriously. It also encompasses personal loss and suffering brought honestly before God rather than suppressed or spiritualised away. The promise is not that the mourning will be explained, but that it will be met — with the comfort of God himself.',
    keyVerse: 'The Lord is near to the brokenhearted and saves the crushed in spirit.',
    keyVerseRef: 'Psalm 34:18',
    reflectionQuestion: 'What am I carrying right now that I have not yet brought honestly to God — and what would it mean to lay it down before Him today?',
    practices: [
      BeatitudePractice(text: 'Write a prayer of honest lament — tell God exactly what grieves you without softening it', habit: 'Prayer'),
      BeatitudePractice(text: 'Pray specifically for someone you know who is suffering today', habit: 'Prayer'),
      BeatitudePractice(text: 'Read a Psalm of lament — Psalm 22, 42 or 88 — and let it give language to your own grief', habit: 'God\'s Word'),
      BeatitudePractice(text: 'Reach out to someone who is mourning and simply be present with them', habit: 'Connection & Community'),
      BeatitudePractice(text: 'Pray for a broken situation in the world that you normally look away from', habit: 'Prayer'),
    ],
    fruitConnection: ['Peace', 'Kindness', 'Goodness', 'Love'],
    supportingVerses: [
      SupportingBeatitudeVerse(text: 'He heals the brokenhearted and binds up their wounds.', ref: 'Psalm 147:3'),
      SupportingBeatitudeVerse(text: 'Blessed be the God and Father of our Lord Jesus Christ, the Father of mercies and God of all comfort, who comforts us in all our affliction.', ref: '2 Corinthians 1:3–4'),
      SupportingBeatitudeVerse(text: 'Rejoice with those who rejoice, weep with those who weep.', ref: 'Romans 12:15'),
      SupportingBeatitudeVerse(text: 'He will wipe away every tear from their eyes, and death shall be no more, neither shall there be mourning, nor crying, nor pain anymore, for the former things have passed away.', ref: 'Revelation 21:4'),
      SupportingBeatitudeVerse(text: 'For godly grief produces a repentance that leads to salvation without regret.', ref: '2 Corinthians 7:10'),
    ],
    imagePath: 'assets/beatitudes_golden_etched_separate/2_those_who_mourn.png',
  ),
  BeatitudeModel(
    number: 3,
    title: 'The Meek',
    verse: 'Blessed are the meek, for they shall inherit the earth.',
    verseRef: 'Matthew 5:5',
    promise: 'they shall inherit the earth',
    yourWhy: 'Meekness is not weakness — it is strength that has been surrendered to God. I choose not to assert myself, not because I have nothing to offer, but because I trust Him to vindicate me.',
    whatThisMeans: 'The Greek word here is praus — used of a wild horse that has been broken and trained. All the power is still there; it is simply now under the rider\'s control. Meekness is not passivity or timidity. It is choosing not to force your own way, not to retaliate, not to demand your rights — because you have placed yourself under God\'s authority and trusted Him with the outcome. Jesus himself is described as meek (Matthew 11:29), and he was anything but weak.',
    keyVerse: 'Take my yoke upon you, and learn from me, for I am gentle and lowly in heart, and you will find rest for your souls.',
    keyVerseRef: 'Matthew 11:29',
    reflectionQuestion: 'Where am I striving, forcing or demanding my own way — and what would it look like to release that to God today?',
    practices: [
      BeatitudePractice(text: 'Identify one situation where you are pushing for your own way and consciously release it to God in prayer', habit: 'Prayer'),
      BeatitudePractice(text: 'Choose not to defend yourself in a conversation where you normally would — and notice what that costs you', habit: 'Breaking Habits'),
      BeatitudePractice(text: 'Serve someone today in a way that will go unnoticed and unacknowledged', habit: 'Service & Generosity'),
      BeatitudePractice(text: 'Pray for someone who has authority over you — a difficult boss, a demanding family member', habit: 'Prayer'),
      BeatitudePractice(text: 'Memorise Numbers 12:3 and reflect on Moses as a model of meekness under pressure', habit: 'God\'s Word'),
    ],
    fruitConnection: ['Gentleness', 'Self-Control', 'Peace', 'Patience'],
    supportingVerses: [
      SupportingBeatitudeVerse(text: 'Now the man Moses was very meek, more than all people who were on the face of the earth.', ref: 'Numbers 12:3'),
      SupportingBeatitudeVerse(text: 'But the meek shall inherit the land and delight themselves in abundant peace.', ref: 'Psalm 37:11'),
      SupportingBeatitudeVerse(text: 'Let your reasonableness be known to everyone. The Lord is at hand.', ref: 'Philippians 4:5'),
      SupportingBeatitudeVerse(text: 'Put on then, as God\'s chosen ones, holy and beloved, compassionate hearts, kindness, humility, meekness, and patience.', ref: 'Colossians 3:12'),
      SupportingBeatitudeVerse(text: 'But I say to you, do not resist the one who is evil. But if anyone slaps you on the right cheek, turn to him the other also.', ref: 'Matthew 5:39'),
    ],
    imagePath: 'assets/beatitudes_golden_etched_separate/3_the_meek.png',
  ),
  BeatitudeModel(
    number: 4,
    title: 'Hunger & Thirst for Righteousness',
    verse: 'Blessed are those who hunger and thirst for righteousness, for they shall be satisfied.',
    verseRef: 'Matthew 5:6',
    promise: 'they shall be satisfied',
    yourWhy: 'I want to want God more than I want anything else — and this hunger, however small it feels, is itself a sign that He is already at work in me.',
    whatThisMeans: 'Jesus uses the language of physical desperation — not mild interest but the urgent, consuming need of someone who is genuinely starving and parched. The righteousness in view is both personal (a longing to be made right before God, to be holy) and cosmic (a longing for the world to be set right, for justice to prevail). This beatitude is a hunger for God himself — for His character, His kingdom, His will to be done. The promise is extraordinary: those who hunger this way will be filled. Not partially. Satisfied.',
    keyVerse: 'As a deer pants for flowing streams, so pants my soul for you, O God. My soul thirsts for God, for the living God.',
    keyVerseRef: 'Psalm 42:1–2',
    reflectionQuestion: 'What am I currently hungering for more than I hunger for God — and what would it mean to bring that appetite to Him instead?',
    practices: [
      BeatitudePractice(text: 'Spend more time in God\'s Word today than you planned — go beyond your normal reading', habit: 'God\'s Word'),
      BeatitudePractice(text: 'Pray specifically for justice in a situation you know about personally', habit: 'Prayer'),
      BeatitudePractice(text: 'Fast as a physical expression of spiritual hunger — let your body feel what your soul should be feeling', habit: 'Fasting'),
      BeatitudePractice(text: 'Advocate for someone being treated unjustly', habit: 'Service & Generosity'),
      BeatitudePractice(text: 'Memorise Psalm 42:1–2 and pray it back to God as a request', habit: 'God\'s Word'),
    ],
    fruitConnection: ['Love', 'Faithfulness', 'Goodness', 'Joy'],
    supportingVerses: [
      SupportingBeatitudeVerse(text: 'Blessed are you who are hungry now, for you shall be satisfied.', ref: 'Luke 6:21'),
      SupportingBeatitudeVerse(text: 'O God, you are my God; earnestly I seek you; my soul thirsts for you; my flesh faints for you, as in a dry and weary land where there is no water.', ref: 'Psalm 63:1'),
      SupportingBeatitudeVerse(text: 'For he satisfies the longing soul, and the hungry soul he fills with good things.', ref: 'Psalm 107:9'),
      SupportingBeatitudeVerse(text: 'Jesus said to them, \'I am the bread of life; whoever comes to me shall not hunger, and whoever believes in me shall never thirst.\'', ref: 'John 6:35'),
      SupportingBeatitudeVerse(text: 'But seek first the kingdom of God and his righteousness, and all these things will be added to you.', ref: 'Matthew 6:33'),
    ],
    imagePath: 'assets/beatitudes_golden_etched_separate/4_hunger_and_thirst_for_righteousness.png',
  ),
  BeatitudeModel(
    number: 5,
    title: 'The Merciful',
    verse: 'Blessed are the merciful, for they shall receive mercy.',
    verseRef: 'Matthew 5:7',
    promise: 'they shall receive mercy',
    yourWhy: 'I give away what I have been given — and since I have been shown mercy beyond what I deserved, I have no right to withhold it from anyone.',
    whatThisMeans: 'Mercy is compassion in action — seeing someone in need or in the wrong, and responding with grace rather than judgment, with help rather than condemnation. Jesus is not describing an occasional kind impulse but a characteristic posture — the merciful person is someone for whom mercy has become a way of seeing and responding to the world. The connection between giving and receiving mercy here is not a transaction but a revelation: the person who withholds mercy has likely not truly received it themselves.',
    keyVerse: 'Be merciful, even as your Father is merciful.',
    keyVerseRef: 'Luke 6:36',
    reflectionQuestion: 'Who in my life am I finding it hardest to show mercy to right now — and what would it look like to give them what God has given me?',
    practices: [
      BeatitudePractice(text: 'Pray for someone who has wronged you, by name, asking God to bless them', habit: 'Prayer'),
      BeatitudePractice(text: 'Reach out to someone from whom you are estranged or with whom there is unresolved tension', habit: 'Connection & Community'),
      BeatitudePractice(text: 'Perform an act of kindness for someone who has not earned it and does not expect it', habit: 'Service & Generosity'),
      BeatitudePractice(text: 'Write down one place where you are withholding forgiveness and bring it to God', habit: 'Prayer'),
      BeatitudePractice(text: 'Visit or contact someone who is lonely, sick or overlooked', habit: 'Connection & Community'),
    ],
    fruitConnection: ['Love', 'Kindness', 'Goodness', 'Patience', 'Gentleness'],
    supportingVerses: [
      SupportingBeatitudeVerse(text: 'He has told you, O man, what is good; and what does the Lord require of you but to do justice, and to love kindness, and to walk humbly with your God?', ref: 'Micah 6:8'),
      SupportingBeatitudeVerse(text: 'Therefore be merciful, just as your Father also is merciful.', ref: 'Luke 6:36'),
      SupportingBeatitudeVerse(text: 'For judgment is without mercy to one who has shown no mercy. Mercy triumphs over judgment.', ref: 'James 2:13'),
      SupportingBeatitudeVerse(text: 'Put on then, as God\'s chosen ones, holy and beloved, compassionate hearts, kindness, humility, meekness, and patience, bearing with one another and, if one has a complaint against another, forgiving each other; as the Lord has forgiven you, so you also must forgive.', ref: 'Colossians 3:12–13'),
      SupportingBeatitudeVerse(text: 'Blessed is the one who considers the poor! In the day of trouble the Lord delivers him.', ref: 'Psalm 41:1'),
    ],
    imagePath: 'assets/beatitudes_golden_etched_separate/5_the_merciful.png',
  ),
  BeatitudeModel(
    number: 6,
    title: 'The Pure in Heart',
    verse: 'Blessed are the pure in heart, for they shall see God.',
    verseRef: 'Matthew 5:8',
    promise: 'they shall see God',
    yourWhy: 'I pursue purity not to earn God\'s approval but because a divided heart cannot see Him clearly — and I want to see Him as He is.',
    whatThisMeans: 'Purity of heart in the Biblical sense is not primarily about moral perfection but about singleness of devotion — what Kierkegaard called "willing one thing." The pure heart has no hidden agenda, no double life, no compartment where God is not welcome. It is oriented wholly toward God without the distortion of competing loves. The extraordinary promise — that the pure in heart will see God — suggests that this kind of inner clarity is itself a form of spiritual vision. The divided heart sees a blurred God; the undivided heart sees more clearly.',
    keyVerse: 'Create in me a clean heart, O God, and renew a right spirit within me.',
    keyVerseRef: 'Psalm 51:10',
    reflectionQuestion: 'Is there any part of my inner life — a secret habit, a hidden motive, a private compromise — that I am keeping from God? What would it mean to open that room to Him today?',
    practices: [
      BeatitudePractice(text: 'Pray Psalm 51 slowly as your own prayer — let David\'s words become yours', habit: 'Prayer'),
      BeatitudePractice(text: 'Identify one area where your private life does not match your public faith and bring it to God specifically', habit: 'Prayer'),
      BeatitudePractice(text: 'Break a habit today that compromises your integrity before God', habit: 'Breaking Habits'),
      BeatitudePractice(text: 'Memorise Psalm 51:10 and pray it as a daily request', habit: 'God\'s Word'),
      BeatitudePractice(text: 'Examine your motives before a significant conversation or decision today — ask God to show you what is driving you', habit: 'Prayer'),
    ],
    fruitConnection: ['Self-Control', 'Faithfulness', 'Goodness', 'Gentleness'],
    supportingVerses: [
      SupportingBeatitudeVerse(text: 'Who shall ascend the hill of the Lord? And who shall stand in his holy place? He who has clean hands and a pure heart, who does not lift up his soul to what is false and does not swear deceitfully.', ref: 'Psalm 24:3–4'),
      SupportingBeatitudeVerse(text: 'Keep your heart with all vigilance, for from it flow the springs of life.', ref: 'Proverbs 4:23'),
      SupportingBeatitudeVerse(text: 'The eye is the lamp of the body. So, if your eye is healthy, your whole body will be full of light.', ref: 'Matthew 6:22'),
      SupportingBeatitudeVerse(text: 'Flee youthful passions and pursue righteousness, faith, love, and peace, along with those who call on the Lord from a pure heart.', ref: '2 Timothy 2:22'),
      SupportingBeatitudeVerse(text: 'Draw near to God, and he will draw near to you. Cleanse your hands, you sinners, and purify your hearts, you double-minded.', ref: 'James 4:8'),
    ],
    imagePath: 'assets/beatitudes_golden_etched_separate/6_pure_in_heart.png',
  ),
  BeatitudeModel(
    number: 7,
    title: 'The Peacemakers',
    verse: 'Blessed are the peacemakers, for they shall be called sons of God.',
    verseRef: 'Matthew 5:9',
    promise: 'they shall be called sons of God',
    yourWhy: 'I pursue peace because God is a reconciling God — and when I make peace, I bear the family resemblance of my Father.',
    whatThisMeans: 'The peacemaker is not someone who avoids conflict or keeps the peace at the cost of truth — that is simply conflict avoidance. The peacemaker actively works to create peace where it does not exist: restoring broken relationships, reconciling people to each other, and ultimately pointing people toward reconciliation with God. The title "sons of God" is remarkable — it is a family likeness. Peacemaking is what God does (Romans 5:1), and those who do it look like Him.',
    keyVerse: 'Therefore, since we have been justified by faith, we have peace with God through our Lord Jesus Christ.',
    keyVerseRef: 'Romans 5:1',
    reflectionQuestion: 'Is there a broken relationship or unresolved conflict in my life that I have been avoiding rather than working to restore — and what is the first step toward peace?',
    practices: [
      BeatitudePractice(text: 'Take the first step toward reconciliation with someone from whom you are estranged', habit: 'Connection & Community'),
      BeatitudePractice(text: 'Pray specifically for a conflict you know about — in your family, church, workplace or community', habit: 'Prayer'),
      BeatitudePractice(text: 'Share the gospel with someone this week — the ultimate act of peacemaking', habit: 'Evangelism'),
      BeatitudePractice(text: 'Choose a gentle answer today in a situation that normally provokes a sharp response', habit: 'Breaking Habits'),
      BeatitudePractice(text: 'Pray for peace in a region of the world currently experiencing conflict', habit: 'Prayer'),
    ],
    fruitConnection: ['Peace', 'Love', 'Kindness', 'Gentleness', 'Goodness'],
    supportingVerses: [
      SupportingBeatitudeVerse(text: 'If possible, so far as it depends on you, live peaceably with all.', ref: 'Romans 12:18'),
      SupportingBeatitudeVerse(text: 'For he himself is our peace, who has made us both one and has broken down in his flesh the dividing wall of hostility.', ref: 'Ephesians 2:14'),
      SupportingBeatitudeVerse(text: 'And the harvest of righteousness is sown in peace by those who make peace.', ref: 'James 3:18'),
      SupportingBeatitudeVerse(text: 'Let the peace of Christ rule in your hearts, to which indeed you were called in one body. And be thankful.', ref: 'Colossians 3:15'),
      SupportingBeatitudeVerse(text: 'How beautiful upon the mountains are the feet of him who brings good news, who publishes peace.', ref: 'Isaiah 52:7'),
    ],
    imagePath: 'assets/beatitudes_golden_etched_separate/7_peacemakers.png',
  ),
  BeatitudeModel(
    number: 8,
    title: 'Those Who Are Persecuted',
    verse: 'Blessed are those who are persecuted for righteousness\u2019 sake, for theirs is the kingdom of heaven. Blessed are you when others revile you and persecute you and utter all kinds of evil against you falsely on my account. Rejoice and be glad, for your reward is great in heaven.',
    verseRef: 'Matthew 5:10–12',
    promise: 'theirs is the kingdom of heaven',
    yourWhy: 'I will not shrink from what is true to avoid what is uncomfortable — because faithfulness to Christ is worth more than the approval of people, and my reward is not in this moment but in eternity.',
    whatThisMeans: 'This is the only Beatitude that Jesus immediately expands and personalises — moving from the third person ("those who are persecuted") to the second ("blessed are you"). It is also the only one that shares the same promise as the first: the kingdom of heaven. This is deliberate. The journey from spiritual poverty (Beatitude 1) to persecution (Beatitude 8) is a complete arc — from recognising your need for God to standing firm for God regardless of cost. Jesus is not romanticising suffering but promising that faithfulness under pressure is both seen and rewarded by the Father.',
    keyVerse: 'Indeed, all who desire to live a godly life in Christ Jesus will be persecuted.',
    keyVerseRef: '2 Timothy 3:12',
    reflectionQuestion: 'Where am I currently staying silent, softening my convictions or compromising my faith to avoid someone\'s disapproval — and what would faithfulness look like in that situation?',
    practices: [
      BeatitudePractice(text: 'Share your faith with someone today despite the risk of rejection or ridicule', habit: 'Evangelism'),
      BeatitudePractice(text: 'Pray for persecuted Christians around the world — use Open Doors or Voice of the Martyrs for specific names and regions', habit: 'Prayer'),
      BeatitudePractice(text: 'Read the account of a Christian martyr or someone who suffered for their faith', habit: 'Reading & Learning'),
      BeatitudePractice(text: 'Identify one situation where you are staying quiet about your faith to avoid awkwardness — and ask God for courage', habit: 'Prayer'),
      BeatitudePractice(text: 'Write down what you believe and why — articulate your faith clearly so you are ready to give a reason for your hope', habit: 'God\'s Word'),
      BeatitudePractice(text: 'Pray for someone who is currently hostile to Christianity — by name', habit: 'Prayer'),
    ],
    fruitConnection: ['Faithfulness', 'Joy', 'Peace', 'Self-Control'],
    supportingVerses: [
      SupportingBeatitudeVerse(text: 'But in your hearts honour Christ the Lord as holy, always being prepared to make a defence to anyone who asks you for a reason for the hope that is in you; yet do it with gentleness and respect.', ref: '1 Peter 3:15'),
      SupportingBeatitudeVerse(text: 'For I am not ashamed of the gospel, for it is the power of God for salvation to everyone who believes.', ref: 'Romans 1:16'),
      SupportingBeatitudeVerse(text: 'Count it all joy, my brothers, when you meet trials of various kinds, for you know that the testing of your faith produces steadfastness.', ref: 'James 1:2–3'),
      SupportingBeatitudeVerse(text: 'If the world hates you, know that it has hated me before it hated you.', ref: 'John 15:18'),
      SupportingBeatitudeVerse(text: 'And after you have suffered a little while, the God of all grace, who has called you to his eternal glory in Christ, will himself restore, confirm, strengthen, and establish you.', ref: '1 Peter 5:10'),
      SupportingBeatitudeVerse(text: 'So do not be ashamed of the testimony about our Lord, nor of me his prisoner, but share in suffering for the gospel by the power of God.', ref: '2 Timothy 1:8'),
    ],
    imagePath: 'assets/beatitudes_golden_etched_separate/8_those_who_are_persecuted.png',
  ),
];
