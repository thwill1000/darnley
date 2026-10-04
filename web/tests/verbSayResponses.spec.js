import { describe, it, expect, beforeAll, beforeEach } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { parseSynonyms, parseMessages, parseMsgFile, renderBody } from '../src/data.js';
import { parseCommand } from '../src/words.js';
import { verbSay } from '../src/engine.js';

// Ports mmbasic/src/tests/tst_verb_say_responses.bas (step 30 of
// web/docs/2026-09-23-web-port-plan-steps.md) - the acceptance gate for
// dialogue correctness. Unlike verbSay.spec.js (fixture-based) this runs
// against the REAL data in web/data/: advent.dat's synonyms,
// p_template_suspect.msg, and the real per-suspect .msg files.
//
// Structure mirrors the MMBasic original: a single person (the "template
// suspect" by default, or a real suspect where a test says so) stands in
// room LOC001, and natural-language input is run through parseCommand()
// + verbSay(). The MMBasic stub console does not parse markup, so the
// comparison is against renderBody() of the winning entry (raw text,
// "[[colour:...]]" intact), exactly as the original compares con_output$.
//
// Not ported: test_money_unlocked() - it exists in the MMBasic file but is
// never registered with add_test(), so it never runs there either.

const __dirname = dirname(fileURLToPath(import.meta.url));
const DATA_DIR = join(__dirname, '..', 'data');
const ROOM = 'LOC001_BATHROOM';

// Real ids and (from advent.dat) real object patterns, so that comma-addressed
// commands ("Mildred, where were you...") resolve the target as in the game.
const SUSPECTS = {
  template: { id: 'P_TEMPLATE_SUSPECT', name: 'Template Suspect', pattern: 'template suspect' },
  arthur: { id: 'P_ARTHUR_CONISTON', name: 'Arthur Coniston', pattern: 'arthur' },
  redvers: { id: 'P_REDVERS_SLINGSBY', name: 'Sir Redvers Slingsby', pattern: 'redvers' },
  sarah: { id: 'P_SARAH_DARNLEY', name: 'Sarah Darnley', pattern: 'sarah' },
  millicent: { id: 'P_MILLICENT_DARNLEY', name: 'Millicent Darnley', pattern: 'millicent' },
  billingsgate: { id: 'P_ARNOLD_BILLINGSGATE', name: 'Arnold Billingsgate', pattern: 'billingsgate butler' },
  goodbody: { id: 'P_MILDRED_GOODBODY', name: 'Mildred Goodbody', pattern: 'goodbody cook' },
  mellors: { id: 'P_RONALD_MELLORS', name: 'Ronald Mellors', pattern: 'mellors gamekeeper' },
  constable: { id: 'P_POLICE_CONSTABLE', name: 'Police Constable', pattern: 'police constable policeman bobby' },
};

let synonyms;
let messages;
let msgFiles;

let objects;
let flags;

beforeAll(() => {
  synonyms = parseSynonyms(readFileSync(join(DATA_DIR, 'advent.dat'), 'utf8'));
  messages = parseMessages(readFileSync(join(DATA_DIR, 'messages.dat'), 'utf8'));
  msgFiles = new Map();
  for (const s of Object.values(SUSPECTS)) {
    const text = readFileSync(join(DATA_DIR, `${s.id.toLowerCase()}.msg`), 'utf8');
    msgFiles.set(s.id, parseMsgFile(text));
  }
});

beforeEach(() => {
  flags = new Set();
  target('template');
});

/** Puts the named suspect alone in the current room (mirrors replacing objects$(9)). */
function target(key) {
  const s = SUSPECTS[key];
  objects = [{ ...s, location: ROOM, isPerson: true }];
}

/** Replaces the flag set (mirrors reset_flags()). */
function resetFlags(...tokens) {
  flags = new Set(tokens);
}

/** Runs "say <cmd>" and returns the raw rendered body of the response. */
function respond(cmd) {
  const parsed = parseCommand('say ' + cmd);
  expect(parsed.failed).toBe(false);
  const result = verbSay(objects, msgFiles, messages, parsed.words, synonyms, ROOM, flags);
  expect(result.success).toBe(true);
  return renderBody(result.entry.body);
}

/**
 * Asserts the response body is exactly "<expected>" (quoted), or with
 * partial, merely starts with it (unquoted-start when expected begins "[",
 * i.e. the body opens with markup rather than a quote).
 */
function assertResponse(cmd, expected, partial = false) {
  const text = respond(cmd);
  if (partial) {
    const wanted = expected.startsWith('[') ? expected : '"' + expected;
    expect(text.slice(0, wanted.length)).toBe(wanted);
  } else {
    expect(text).toBe('"' + expected + '"');
  }
}

/** Asserts every command in cmds gives the same (full) response. */
function all(expected, cmds) {
  for (const cmd of cmds) assertResponse(cmd, expected);
}

describe('verbSay() against the real template/suspect .msg files', () => {
  it('Good morning.', () => {
    all('greeting response', ['hello', 'hi there', 'good morning', 'afternoon', 'evening', 'warm greetings']);
  });

  it("Bit cold isn't it?", () => {
    all('weather response', [
      "it's cold today", "bit cold isn't it", 'what dreadful weather', 'all this snow',
      'freezing cold out there', "some weather we're having",
    ]);
  });

  it('What happened last night?', () => {
    all('events response', [
      'tell me about last night', 'what happened last night', 'describe what happened yesterday',
      'walk me through the events of that night', 'run me through the events of the murder',
    ]);
  });

  it('Why are you here?', () => {
    all('why here response', ['why are you here', 'why are you visiting', 'what brings you here']);

    target('arthur');
    assertResponse('why are you here', 'I was down for the weekend to ask the old boy', true);

    target('redvers');
    assertResponse('why are you here', 'Business. Damned inconvenient business', true);
    resetFlags('x_newspaper');
    assertResponse('why are you here', 'Business. Damned inconvenient business', true);
  });

  it('What were you doing at the time of the murder?', () => {
    all('alibi response', [
      'alibi', "What's your alibi?", 'Give me your alibi', 'Do you have an alibi?',
      'What alibi can you give me?', 'What were you doing at the time of the murder?',
      'Where were you at the time of the murder?',
    ]);

    target('goodbody');
    assertResponse('Mildred, where were you at the time of the murder?', 'We was all three together', true);
  });

  it('Can anyone confirm your alibi?', () => {
    all('alibi confirm response', [
      'Can anyone confirm your alibi?', 'Did anyone see you at 11:30?', 'Can anyone corroborate that?',
      'Is there a witness to confirm it?', 'Were you alone the whole time?',
    ]);
  });

  it('Tell me about these slippers.', () => {
    all('slippers response', [
      'ask about slippers', 'whose slippers are these', 'tell me about the slippers',
      'what do you know about the slippers',
    ]);
  });

  it('Whose boots are these?', () => {
    all('boots response', [
      'ask about the boots', 'who do these boots belong to', 'tell me about the muddy boots', 'whose boots are these',
    ]);
  });

  it('Whose knife is this?', () => {
    all('knife response', [
      'ask about the knife', 'what about the kitchen knife', 'tell me about the bloody knife', 'whose knife is this',
    ]);
  });

  it('Who smokes cigarettes?', () => {
    all('smoking response', [
      'cheroot', 'cigar', 'cigarette', 'smoking', 'smokes', 'Do you smoke cigarettes?',
      'Did you see anyone smoking by the pond?', 'Who smokes a cigar?', 'Who smokes cheroots?',
      'Who in the family smoked?',
    ]);
  });

  it('What guns are there in the house?', () => {
    all('guns in the house response', [
      'revolver', 'pistol', 'Tell me about the revolver', 'Whose revolver is this?',
      'Do you recognise this revolver?', 'What guns are there in the house?',
      'Does anyone own a shotgun?', 'Are there any rifles here?',
    ]);
  });

  it('What do you know about this revolver I found in the pond?', () => {
    resetFlags('x_revolver');
    assertResponse('revolver', 'revolver response given pond revolver');
    assertResponse('What do you know about this revolver I found in the pond?', 'revolver response given pond revolver');
    assertResponse('What guns are there in the house?', 'guns in the house response');
  });

  it('What do you know about the missing revolver?', () => {
    resetFlags('x_gunrack');
    assertResponse('revolver', 'revolver response given gun rack');
    assertResponse('What do you know about the missing revolver?', 'revolver response given gun rack');
    assertResponse('What guns are there in the house?', 'guns in the house response');
  });

  it('What do you know about the revolver? (after revolver and gun rack examined)', () => {
    resetFlags('x_revolver', 'x_gunrack');
    const both = 'revolver response given pond revolver and gun rack';
    assertResponse('revolver', both);
    assertResponse('What do you know about this revolver I found in the pond?', both);
    assertResponse('What do you know about the missing revolver?', both);
    assertResponse('What guns are there in the house?', 'guns in the house response');
  });

  it('What happened to the missing statue?', () => {
    all('missing statue response', [
      'ask about the missing statue', 'what happened to the missing statue',
      "tell me about the statue that's gone", "where's the fourth statue",
    ]);
  });

  it('Was anyone playing the gramophone?', () => {
    all('gramophone response', [
      'ask about the gramophone', 'what about the gramophone', 'tell me about the gramophone',
      'was anyone playing the gramophone',
      // Misspelling of "gramophone" as "gramaphone" (via synonyms)
      'tell me about the gramaphone', 'gramaphone', 'that gramaphone record',
    ]);
  });

  it('Was the piano being played last night?', () => {
    all('piano response', [
      'ask about the piano', 'who was playing the piano', 'tell me about the piano',
      'was the piano being played last night',
    ]);
  });

  it("Who owns these lady's shoes?", () => {
    all('ladys shoes response', [
      'ask about the ladys shoes', 'whose womens shoes are these', "tell me about the woman's shoes",
      "who owns these lady's shoes",
    ]);
  });

  it('Did you read the newspaper? (before the newspaper is found)', () => {
    all('newspaper response', [
      'ask about the newspaper', 'what about the newspaper', 'tell me about the newspaper',
      'did you read the newspaper',
    ]);

    // Without x_newspaper all three holders of gated knowledge stay evasive.
    target('redvers');
    assertResponse('did you read the newspaper', "Can't say I've had much leisure for reading", true);
    target('arthur');
    assertResponse('did you read the newspaper', "Can't say I get much further than the sporting pages", true);
    target('sarah');
    assertResponse('did you read the newspaper', "I really couldn't say - Sebastian read the paper over breakfast, not I.", true);
  });

  it('Did you read the newspaper? (after the newspaper is found)', () => {
    resetFlags('x_newspaper');
    all('newspaper response given newspaper found', [
      'ask about the newspaper', 'what about the newspaper', 'tell me about the newspaper',
      'did you read the newspaper',
    ]);

    target('redvers');
    assertResponse('did you read the newspaper', '[[reset:He stiffens slightly', true);
    target('arthur');
    assertResponse('did you read the newspaper', 'I heard that old Slingsby had plunged into mining shares', true);
    target('sarah');
    assertResponse('did you read the newspaper', '[[reset:She hesitates, choosing her words', true);
  });

  it("What do you know about the letter on the Colonel's desk?", () => {
    all('letter response', [
      'ask about the letter', 'what about the unfinished letter', 'tell me about the letter on the desk',
      'who was the letter addressed to',
    ]);
  });

  it('Who dropped this handkerchief?', () => {
    all('handkerchief response', [
      'ask about the handkerchief', 'whose handkerchief is this', 'tell me about the handkerchief',
      'who dropped this handkerchief', 'who dropped this hankerchief', 'who dropped this hanky',
      'who dropped these handkerchiefs', 'who dropped these hankerchiefs', 'who dropped these hankys',
    ]);
  });

  it('What did you think of Colonel Darnley?', () => {
    all('colonel darnley opinion response', [
      'What did you think of Colonel Darnley?', 'What was the Colonel like',
      'Tell me about Colonel Darnley', 'What did you make of Sebastian Darnley',
    ]);

    // Millicent's "father"/"mother" and Sarah's "husband"/"daughter" are
    // rewritten by the suspect-specific replacements (darnley_xtra.inc).
    target('millicent');
    assertResponse('What did you think of your father?', 'Daddy was a tyrant', true);
    assertResponse('What did you think of your mother?', 'We got on well enough', true);

    target('sarah');
    assertResponse('What did you think of your husband?', 'He was somewhat strict', true);
    assertResponse('What did you think of your daughter?', 'Her father spoiled her', true);
  });

  it('What do you think of Sarah Darnley?', () => {
    all('sarah response', [
      'sarah', 'sarah darnley', 'what do you think of sarah', 'what do you make of sarah', 'tell me about sarah',
      "what's sarah like", 'your impression of sarah', 'how do you get on with sarah',
      'What do you think of Sarah Darnley?',
    ]);
  });

  it('What do you think of Millicent Darnley?', () => {
    all('millicent response', [
      'millicent', 'millicent darnley', 'what do you think of millicent', 'what do you make of millicent',
      'tell me about millicent', "what's millicent like", 'your impression of millicent',
      'how do you get on with millicent', 'What do you think of Millicent Darnley?',
    ]);
  });

  const opinionCases = [
    ['What do you think of Arthur Coniston?', 'arthur response', 'arthur coniston'],
    ['What do you think of Sir Redvers Slingsby?', 'redvers response', 'redvers slingsby'],
    ['What do you think of Arnold Billingsgate?', 'arnold response', 'arnold billingsgate'],
    ['What do you think of Mildred Goodbody?', 'mildred response', 'mildred goodbody'],
    ['What do you think of Norah Bagsby?', 'norah response', 'norah bagsby'],
    ['What do you think of Ronald Mellors?', 'mellors response', 'ronald mellors'],
  ];
  for (const [description, expected, name] of opinionCases) {
    it(description, () => {
      all(expected, [
        `what do you think of ${name}`, `what do you make of ${name}`, `tell me about ${name}`,
        `what's ${name} like`, `your impression of ${name}`, `how do you get on with ${name}`,
      ]);

      if (name === 'redvers slingsby') {
        // Ask Millicent about Redvers.
        target('millicent');
        assertResponse('Millicent, what do you think about sir redvers?', "I didn't know him before last night.");
      }
    });
  }

  it('Tell me about the ginger cat.', () => {
    all('chester cat response', ['cat', 'Tell me about the ginger cat']);
  });

  it('What do you think of the Police Constable?', () => {
    all('police constable response', [
      'What do you think of the police constable?', 'What do you make of the officer at the gate?',
      'Tell me about the constable.', "What's the policeman like?", 'Your impression of the officer.',
      'How do you get on with the constable?',
    ]);

    // Ask the Police Constable about himself directly.
    target('constable');
    for (const cmd of [
      'What do you make of yourself, constable?', 'How long have you been on duty here?',
      'Were you posted here at the gate?', 'What are your orders at the drive?',
    ]) {
      assertResponse(cmd, 'Me, sir? Not much to tell', true);
    }
  });

  it('What do you know about the horse?', () => {
    all('horse response', [
      'horse', 'bay hunter', 'Tell me about the horse', 'What do you know about the horse?',
      "Ask about the Colonel's bay hunter",
    ]);
  });

  it('Tell me about the Daimler.', () => {
    all('daimler response', [
      'daimler', 'motor car', 'Tell me about the daimler', 'What do you know about the family car?',
      'What about the saloon in the garage?',
    ]);
  });

  it('Tell me about the police car.', () => {
    all('police car response', [
      'police car', 'Tell me about the police car', 'What is that police saloon doing on the drive?',
      'Whose police car is that?',
    ]);

    target('constable');
    assertResponse('Is this your police car?', "That's yours, sir", true);
  });

  it('What do you know about the flat-footed bootprints?', () => {
    all('flatfooted bootprints response', [
      'ask about flatfooted bootprints', 'tell me about the flat-footed marks',
      'tell me about the flat footed prints', 'what about those odd bootprints',
    ]);
  });

  it('What do you know about the hobnailed bootprints?', () => {
    all('hobnailed bootprints response', [
      'ask about hobnailed bootprints', 'what about the hobnailed marks', 'tell me about the hobnailed boot tracks',
    ]);
  });

  it('What do you know about the slipper prints?', () => {
    all('slipper prints response', [
      'ask about slipper prints', 'what about the slipper tracks', 'tell me about those slipper marks',
    ]);
  });

  it("What do you know about the men's shoe prints?", () => {
    all('mens shoeprints response', [
      'ask about mens shoe prints', "what about the men's shoe tracks", "whose men's shoe prints are these",
    ]);
  });

  it("What do you know about the women's shoe prints?", () => {
    all('womens shoeprints response', [
      'ask about womens shoe prints', "what about the women's shoe tracks", "whose women's footprints are these",
    ]);
  });

  it('Tell me about the footprints.', () => {
    all('footprints response', [
      'Tell me about the footprints', 'Tell me about the foot prints', 'Tell me about the footprints in the snow',
      'Tell me about the foot prints in the snow', 'Tell me about the prints',
      'Tell me about the prints in the snow', 'Tell me about the bootprints', 'What about the bootprints?',
      'What about the boot tracks?', 'Tell me about the shoeprints', 'Tell me about the shoe prints',
      'What about the shoeprints?', 'What about the shoe tracks?',
    ]);
  });

  it('What do you know about the tyre tracks by the car?', () => {
    all('car tracks response', [
      'car tracks', 'Tell me about the tyre tracks', 'What about the tracks by the car?',
      "What about the daimler's tyres?",
    ]);
  });

  it('What do you know about the pond?', () => {
    all('pond response', ['pond', 'Tell me about the ornamental pond', 'What about the pond?']);
  });

  it('Tell me about the pipe in the servants\' quarters.', () => {
    all('pipe response', [
      'pipe', 'ask about the pipe', 'whose pipe is this', "tell me about the pipe in the servants' quarters",
    ]);
  });

  it('Whose books are these?', () => {
    all('bookshelf response', ['bookshelf', 'books', 'Tell me about the bookshelf', 'Whose books are these?']);
  });

  it('Tell me about the correspondence and photographs.', () => {
    all('correspondence response', [
      'correspondence', 'photographs', 'Tell me about the correspondence and photographs',
      "Whose letters are these that I found in the servants' quarters?",
    ]);
  });

  it('What do you know about about the cheroot butt found in the pond?', () => {
    all('cheroot in the pond response', [
      'ask about the cheroot in the pond', 'what about the cigar end found in the pond',
      'tell me about the cheroot found in the pond',
    ]);
  });

  it("Tell me about the suit found in the servants' quarters.", () => {
    all('suit response', [
      'suit', "ask about the suit in the servants' quarters",
      "what about the suit I found in the servants' quarters", "tell me about the suit found in the servants' quarters",
    ]);
  });

  it('Why is their furniture stacked in the hall?', () => {
    all('stacked furniture response', [
      'stacked furniture', 'Tell me about the stacked furtniture in the hall',
      'Why is their furniture stacked in the hall?',
    ]);
  });

  it('Why is the kitchen passage blocked?', () => {
    all('kitchen passage response', ['kitchen passage', 'blocked door', 'Why is the kitchen passage blocked?']);
  });

  it('Why is Sir Redvers not staying in the second guest room?', () => {
    all('second guest room response', [
      'second guest room', 'spare room', 'Why is Sir Redvers not staying in the second guest room?',
    ]);
  });

  it("Can you corroborate Arthur's alibi?", () => {
    all('vouch for arthur response', [
      'confirm arthur', "Can you corroborate Arthur's alibi?", 'Was Arthur with you?', 'Can you vouch for Coniston?',
    ]);
  });

  it("Can you corroborate Millicent's alibi?", () => {
    all('vouch for millicent response', [
      'confirm millicent', "Can you corroborate Millicent's alibi?", 'Was Millicent with you?',
      'Can you vouch for Millicent?',
    ]);
  });

  it("Can you corroborate Sarah's alibi?", () => {
    all('vouch for sarah response', [
      'confirm sarah', "Can you corroborate Sarah's alibi?", 'Was Sarah with you?', 'Can you vouch for Sarah?',
    ]);

    // With no flags set, Mellors' corroboration of Sarah falls to the unconditional entry.
    target('mellors');
    assertResponse('confirm sarah', "Don't know anything about Mrs. Darnley's evening.", true);

    // Once both gating flags are set, the more specific (still evasive) entry wins.
    resetFlags('x_handkerchief', 'x_cigarettes');
    assertResponse('confirm sarah', '[[reset:Something flickers behind his flat stare.]]', true);
  });

  it("Can you corroborate Redvers' alibi?", () => {
    all('vouch for redvers response', [
      'confirm redvers', "Can you corroborate Redvers' alibi?", 'Was Redvers with you?', 'Can you vouch for Slingsby?',
    ]);
  });

  it("Can you corroborate the Servants' alibi?", () => {
    all('vouch for servants response', [
      'confirm servants', "Can you corroborate the Servants' alibi?", 'Was Billingsgate with you?',
      'Can you vouch for Norah?',
    ]);
  });

  it("Can you corroborate Mellors' alibi?", () => {
    all('vouch for mellors response', [
      'confirm mellors', "Can you corroborate Mellors' alibi?", 'Was Ronald with you?',
      'Can you vouch for the Gamekeeper?', 'Can you vouch for the Game keeper?',
      'Can you vouch for the Game-keeper?',
    ]);
  });

  it('Who had a motive?', () => {
    all('motive response', [
      'motive', 'Who had a motive?', 'why would someone murder him', 'why would anyone want him dead',
      'what reason would someone have', 'what would be the motive',
    ]);
  });

  it('Who stands to inherit?', () => {
    all('inheritance response', [
      'inheritance', 'Who stands to inherit?', 'What happens to the inheritance?', 'Who inherits the estate?',
      'What did he leave in his will?', 'Tell me about the will?', 'Who gets his money?',
    ]);
  });

  it('Was Mellors about to be dismissed?', () => {
    all("mellors' dismissal response", [
      'Was Mellors about to be dismissed?', 'Tell me about Mellors warning letter', 'Was Mellors given notice',
      'Was Mellors going to be fired', 'Was Mellors going to be sacked', 'Was Mellors job in danger',
      'Was Mellors position at risk', 'Did the colonel give Mellors notice',
    ]);

    target('mellors');
    assertResponse('Mellors, did the Colonel threaten your position?', 'Who told you that? ...', true);
  });

  it('Who do you think is the murderer?', () => {
    all('who did it response', [
      'who do you think did it?', 'who is the murderer?', 'who is the killer?', 'who would you accuse?',
      'who do you think murdered colonel darnley?', 'who killed him', 'who do you suspect',
      'any idea who did this', 'who would want to kill him',
    ]);
  });

  it('Were the Colonel and Sarah happy?', () => {
    all("colonel's marriage response", [
      'were the colonel and sarah happy', 'were they a happy couple', 'how was the marriage',
      'did sarah and the colonel get on',
    ]);
  });

  it('Have you considered remarrying?', () => {
    all("sarah's remarriage response", [
      'remarriage', 'remarry', 'remarrying', 'marry again', 'Have you considered remarrying?',
    ]);
  });

  it('When did Arthur and Millicent get engaged?', () => {
    all("millicent's engagement response", [
      'tell me about the engagement', "tell me about millicent's engagement", 'when did they get engaged',
      'how did arthur propose to millicent',
    ]);
  });

  it('How was the study locked?', () => {
    all('locked study response', [
      'how was the study locked', 'how was the study sealed', 'how could someone have gotten into the study',
      'explain the locked door on the study',
    ]);
  });

  it('What do you know about the broken french window?', () => {
    all('broken window response', [
      'what do you know about the broken window', 'tell me about the smashed glass',
      'how was the french window broken', 'what about the shattered pane', 'tell me about the broken glass',
    ]);

    // Billingsgate and Arthur were present at the break-in.
    target('billingsgate');
    assertResponse('tell me about the broken window', 'I broke it myself, sir', true);
    target('arthur');
    assertResponse('tell me about the broken window', 'That was me, old boy', true);
  });

  it('What clues have you found?', () => {
    all('evidence response', [
      'what clues have you found', 'what have you found so far', 'any clues yet', "what's the evidence",
    ]);
  });

  it('Where is the body?', () => {
    all('body location response', [
      'Where is the body?', "Where's the body?", 'Where did you find the body?', 'Where was the colonel found?',
    ]);
  });

  it('Was there something going on between Sarah and Mellors?', () => {
    all('affair response', [
      'ask about the affair', 'was there something going on between sarah and mellors',
      'was sarah having a secret affair with the gamekeeper',
    ]);
  });

  it('Was there something going on between Sarah and Mellors? (once handkerchief and cigarettes are found)', () => {
    resetFlags('x_handkerchief', 'x_cigarettes');

    all('affair response given handkerchief and cigarettes', [
      'ask about the affair',
      'was there something going on between sarah and mellors',
      'was sarah having a secret affair with the gamekeeper',
    ]);
  });

  it("Tell me about the Colonel's finances", () => {
    all('finance response', [
      "tell me about the colonel's finances",
      "tell me about redvers' debts",
      "tell me about redvers' money troubles",
      "tell me about redvers's money troubles",
      "what about slingsby's debts",
      "did redvers lose money",
    ]);
  });

  it("Tell me about the Colonel's finances (after the newspaper is found)", () => {
    resetFlags('x_newspaper');

    all('finance response', [
      "tell me about the colonel's finances",
    ]);

    all('finance response given newspaper and redvers', [
      "tell me about redvers' debts",
      "tell me about redvers' money troubles",
      "tell me about redvers's money troubles",
      "what about slingsby's debts",
      'did redvers lose money',
    ]);

    // Ask Redvers directly without referencing him by name in the subject.
    target('redvers');
    assertResponse('Redvers, did you have money troubles?', "[[reset:He goes rather grey about the gills.", true);
  });

  it('What do you know about the bangs last night?', () => {
    all('bang/shot timeline response', [
      'bang', 'shot', 'What about the bang?', 'What about the shot?', 'What time was the bang?',
      'What time was the shot?', 'What time did you hear the bang?', 'What time did you hear the shot?',
      'When did you hear the bang?', 'When did you hear the shot?', 'Tell me about the bang?',
      'Tell me about the shot?', 'Did you hear a bang?', 'What time exactly did you hear the shot?',
    ]);
  });

  it('Did you argue with the colonel? (before the newspaper is found)', () => {
    all('argument with colonel response', [
      'did you argue with the colonel', 'did you have an argument with the colonel',
      'was there a row with the colonel', 'did you quarrel with the colonel',
    ]);

    target('redvers');
    assertResponse('did you argue with the colonel', "Argued, yes - I'll not pretend otherwise", true);
    assertResponse('did you have an argument with the colonel', "Argued, yes - I'll not pretend otherwise", true);
  });

  it('Did you argue with the colonel? (after the newspaper is found)', () => {
    resetFlags('x_newspaper');
    all('argument with colonel given newspaper response', [
      'did you argue with the colonel', 'did you have an argument with the colonel',
      'was there a row with the colonel', 'did you quarrel with the colonel',
    ]);

    target('redvers');
    const opening = '[[reset:He exhales slowly, some of the bluster gone out of him.';
    assertResponse('did you argue with the colonel', opening, true);
    assertResponse('did you have an argument with the colonel', opening, true);
  });

  it('What do you think of the police investigation?', () => {
    all('investigation response', [
      'what do you think of the police investigation', 'what do you think of the police being here',
      'how do you feel about the police investigation',
    ]);
  });

  const accusations = [
    'accuse', 'guilty', 'I accuse you!', 'You did it', 'You are the murderer', 'You are the killer',
    'You killed the colonel', 'You murdered the colonel', "J'accuse!", 'I accuse you of murder',
    'I accuse you, confess!', 'You are guilty!',
  ];

  it("I accuse you! (but don't have all the clues)", () => {
    all('premature accusation response', accusations);
  });

  it('I accuse you! (the first time)', () => {
    for (const cmd of accusations) {
      resetFlags('all_clues');
      assertResponse(cmd, 'first accusation response');
    }
  });

  it('I accuse you! (subsequent times)', () => {
    for (const cmd of accusations) {
      resetFlags('all_clues', 'accuse_b4_tag');
      assertResponse(cmd, 'subsequent accusation response');
    }
  });

  it('Goodbye.', () => {
    all('goodbye response', ['goodbye', 'bye', 'well, goodbye then', 'thanks for your time', 'thank you very much']);
  });

  it('INTERNAL: Test successful accusation response', () => {
    // With the flag unset falls back to the wildcard response...
    assertResponse('accuse_succeed', 'wildcard response');
    // ...but with it set the real response is used.
    flags.add('accuse_succeed');
    assertResponse('accuse_succeed', 'successful accusation response');
  });

  it('INTERNAL: Test failed accusation response', () => {
    assertResponse('accuse_fail', 'wildcard response');
    flags.add('accuse_fail');
    assertResponse('accuse_fail', 'failed accusation response');
  });

  it('Unhandled question falls back to the question wildcard', () => {
    all('unhandled question response', ['?', 'who', 'whose', 'whom', 'why', 'what', 'where', 'when', 'how', 'which']);
  });

  it('Something nonsensical falls back to the non-question wildcard', () => {
    assertResponse('xyzzy plugh', 'wildcard response');
  });
});
