class DreamFacts {
  static final List<String> facts = [
    "Dreams typically last only 5 to 20 minutes, although we may experience multiple dreams in a single night.",
    "Everyone dreams, but not everyone remembers their dreams. On average, people have 3-5 dreams per night.",
    "You cannot read, tell time or use a phone in your dreams. If you try to do these things, you might realize you're dreaming.",
    "Blind people dream too. Those blind from birth have dreams involving emotions, sounds, and smells rather than images.",
    "Animals dream too. Studies have shown that dogs, cats, and many mammals experience REM sleep, suggesting they dream like humans.",
    "The most common emotion experienced in dreams is anxiety. Negative emotions are more common than positive ones in dreams.",
    "Recurring dreams often indicate unresolved conflicts or stress in your waking life.",
    "Dreams can help solve problems. Many scientists, artists, and inventors credit dreams with providing solutions or inspiration.",
    "Lucid dreaming (being aware you're dreaming while in the dream) can be learned through practice and techniques.",
    "The average person will spend six years of their life dreaming.",
    "Your brain is more active during dreams than when you're awake.",
    "Some people experience dreams in black and white, while most dream in color.",
    "Nightmares are more common in children than adults, often peaking between ages 3-6.",
    "External stimuli like sounds, smells, or sensations can be incorporated into your dreams.",
    "Sleep paralysis occurs when your mind wakes up but your body remains in REM sleep paralysis, often leading to hallucinations.",
    "Dreams reflect your emotional state. Stressful periods often lead to more negative dreams.",
    "The content of men's and women's dreams tend to differ slightly, with gender-specific themes appearing more often.",
    "You can only dream about faces you've seen in real life, though your brain might combine different features.",
    "Falling dreams are one of the most common types of dreams, often occurring when you feel overwhelmed or out of control.",
    "People who quit smoking often report having intensely vivid dreams during withdrawal.",
    "Dreams of flying may represent a desire for freedom or escape from current life stresses.",
    "Some cultures believe dreams are a way to communicate with ancestors or spiritual guides.",
    "Experiencing a dream within a dream is a real phenomenon and can indicate complex problem-solving during sleep.",
    "Déjà vu might be related to dreams - you may have dreamed about a place or situation before experiencing it in real life.",
    "Some people experience 'false awakenings' where they dream they've woken up but are actually still dreaming.",
    "Dream journaling can improve dream recall and help identify patterns in your dreams.",
    "Precognitive dreams that seemingly predict future events have been reported throughout history.",
    "The scientific study of dreams is called oneirology.",
    "Certain medications can suppress REM sleep, reducing dream recall or dream intensity.",
    "Sharing a bed with someone can influence your dream content, sometimes incorporating their movements or sounds.",
    "You can't read books or check the time in dreams. Your brain just can't process text or clocks properly while dreaming.",
    "You forget 90% of your dreams within 10 minutes of waking. Unless you write them down, they vanish fast!",
    "Your dog is probably dreaming of chasing cats while it sleeps!",
    "Frankenstein, the periodic table, and the sewing machine all came from dreams.",
    "People who grew up with black & white TV often dream in black & white.",
    "Recurring dreams often mean your mind is stuck on something emotional.",
    "Some people dream so vividly, they eat, cry, or even feel burning.",
    "A five-minute dream can feel like an entire movie or lifetime.",
    "Ancient civilizations treated dreams as sacred. In Egypt and Greece, people slept in 'dream temples' hoping to receive healing messages from gods or ancestors during sleep.",
    "Time works differently in dreams. You can live out what feels like hours, days, or even years in a dream that lasts just a few minutes in real life.",
    "Dreams can be contagious in close relationships. Couples and close friends often report having similar dream themes or appearing in each other's dreams more frequently.",
    "It's possible to train your mind to continue a dream from where you left off. With enough practice, visualization, and intent, some people can re-enter a dream even after waking up from it.",
    "In some cultures, dreams are considered a parallel reality - not just imagination, but a separate spiritual world you visit each night.",
  ];

  static String getRandomFact() {
    // Generate a random index between 0 and facts.length-1
    final random = DateTime.now().millisecondsSinceEpoch % facts.length;
    return facts[random];
  }
}
