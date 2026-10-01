class MotivationalQuote {
  final String text;
  final String author;
  final String category;
  final String tag;

  const MotivationalQuote({
    required this.text,
    required this.author,
    required this.category,
    required this.tag,
  });
}

class QuotesService {
  static const List<MotivationalQuote> quotes = [
    MotivationalQuote(
      text: "You have power over your mind - not outside events. Realize this, and you will find strength.",
      author: "Marcus Aurelius",
      category: "Discipline",
      tag: "⚡ STOICISM",
    ),
    MotivationalQuote(
      text: "Don't stop when you're tired. Stop when you're done.",
      author: "David Goggins",
      category: "Mental Toughness",
      tag: "🔥 UNBROKEN",
    ),
    MotivationalQuote(
      text: "We must all suffer one of two things: the pain of discipline or the pain of regret.",
      author: "Jim Rohn",
      category: "Discipline",
      tag: "🛡️ DISCIPLINE",
    ),
    MotivationalQuote(
      text: "Suffer for 90 days in silence. Shock the world in the spring.",
      author: "Winter Arc Protocol",
      category: "Winter Arc",
      tag: "❄️ THE ARC",
    ),
    MotivationalQuote(
      text: "Discipline equals freedom.",
      author: "Jocko Willink",
      category: "Discipline",
      tag: "⚔️ FREEDOM",
    ),
    MotivationalQuote(
      text: "It is not death that a man should fear, but he should fear never beginning to live.",
      author: "Marcus Aurelius",
      category: "Action & Focus",
      tag: "⚡ ACTION",
    ),
    MotivationalQuote(
      text: "I fear not the man who has practiced 10,000 kicks once, but I fear the man who has practiced one kick 10,000 times.",
      author: "Bruce Lee",
      category: "Action & Focus",
      tag: "🥋 MASTERY",
    ),
    MotivationalQuote(
      text: "Rest at the end, not in the middle.",
      author: "Kobe Bryant",
      category: "Mental Toughness",
      tag: "🐍 MAMBA",
    ),
    MotivationalQuote(
      text: "Today I will do what others won't, so tomorrow I can accomplish what others can't.",
      author: "Jerry Rice",
      category: "Grit",
      tag: "🔥 RELENTLESS",
    ),
    MotivationalQuote(
      text: "There is nothing outside of yourself that can enable you to get better, stronger, or faster. Everything is within.",
      author: "Miyamoto Musashi",
      category: "Mental Toughness",
      tag: "🗡️ SAMURAI",
    ),
    MotivationalQuote(
      text: "Difficulties strengthen the mind, as labor does the body.",
      author: "Seneca",
      category: "Discipline",
      tag: "⚡ STOICISM",
    ),
    MotivationalQuote(
      text: "The cold doesn't negotiate with your comfort. Show up anyway.",
      author: "Winter Arc Creed",
      category: "Winter Arc",
      tag: "❄️ COLD ARC",
    ),
  ];

  static MotivationalQuote getQuoteOfDay() {
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    return quotes[dayOfYear % quotes.length];
  }

  static List<MotivationalQuote> getByCategory(String category) {
    if (category == 'All') return quotes;
    return quotes.where((q) => q.category == category).toList();
  }
}
