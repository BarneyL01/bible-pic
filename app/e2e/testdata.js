// The plan's many-topics data: 50 verses, 50 distinct topics, three topics each
// (plus `hope` on the first ten so the counts differ).
const T = [
  'love', 'hope', 'peace', 'faith', 'joy', 'strength', 'comfort', 'fear', 'anxiety', 'grace',
  'forgiveness', 'prayer', 'wisdom', 'patience', 'courage', 'salvation', 'healing', 'trust',
  'guidance', 'thankfulness', 'rest', 'provision', 'protection', 'worship', 'obedience',
  'humility', 'kindness', 'family', 'marriage', 'friendship', 'work', 'money', 'grief',
  'suffering', 'temptation', 'creation', 'eternal life', 'holy spirit', 'jesus', 'gods word',
  'mercy', 'justice', 'encouragement', 'perseverance', 'contentment', 'generosity', 'purpose',
  'identity', 'light', 'morning',
];

exports.topics = T;

exports.topicsOf = (i) => {
  const list = [T[i - 1], T[((i - 1) * 7 + 3) % 50], T[((i - 1) * 13 + 5) % 50]];
  if (i <= 10) list.push('hope');
  return list;
};

exports.blocks = () =>
  Array.from({ length: 50 }, (_, k) => k + 1)
    .map((i) => `Psalm ${i}:1 (KJV)\nVerse text number ${i} for testing a long list of topics.\n# ${exports.topicsOf(i).join(', ')}`)
    .join('\n\n');

/** Bulk imports the data through the app (Menu, Bulk import) and returns to the home screen. */
exports.importTestData = async (page, d) => {
  await d.click('Menu', false);
  await d.click('Bulk import', false, 1200);
  await page.getByRole('textbox').first().click();
  await page.keyboard.insertText(exports.blocks());
  await page.waitForTimeout(800);
  await d.click('Import pasted text', false, 3000);
  await d.click('Back', false);
};
