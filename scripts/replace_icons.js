const fs = require('fs');
const path = require('path');

// ══════════════════════════════════════════════════════════════════
// Script de remplacement systématique Material → Iconly Pro
// Utilise des regex avec negative lookahead pour éviter les
// correspondances partielles (ex: Icons.star ≠ Icons.star_border)
// ══════════════════════════════════════════════════════════════════

const mappings = [
  // ── Profil / Person ──────────────────────────────────────────
  { from: /Icons\.person_add_alt_1(?![a-zA-Z_0-9])/g,       to: 'IconlyLight.addUser' },
  { from: /Icons\.person_add_alt_(?![a-zA-Z_0-9])/g,        to: 'IconlyLight.addUser' },
  { from: /Icons\.person_add_rounded(?![a-zA-Z_0-9])/g,     to: 'IconlyLight.addUser' },
  { from: /Icons\.person_add(?![a-zA-Z_0-9])/g,             to: 'IconlyLight.addUser' },
  { from: /Icons\.group_add_rounded(?![a-zA-Z_0-9])/g,      to: 'IconlyLight.addUser' },
  { from: /Icons\.person_outline_rounded(?![a-zA-Z_0-9])/g, to: 'IconlyLight.profile' },
  { from: /Icons\.person_off_rounded(?![a-zA-Z_0-9])/g,     to: 'IconlyLight.profile' },
  { from: /Icons\.person_rounded(?![a-zA-Z_0-9])/g,         to: 'IconlyBold.profile' },
  { from: /Icons\.person(?![a-zA-Z_0-9])/g,                 to: 'IconlyLight.profile' },

  // ── People / Groups ──────────────────────────────────────────
  { from: /Icons\.people_rounded(?![a-zA-Z_0-9])/g,         to: 'IconlyLight.people' },
  { from: /Icons\.people_outline(?![a-zA-Z_0-9])/g,         to: 'IconlyLight.people' },
  { from: /Icons\.groups(?![a-zA-Z_0-9])/g,                 to: 'IconlyBold.people' },

  // ── Heart / Favorite ─────────────────────────────────────────
  { from: /Icons\.favorite_border(?![a-zA-Z_0-9])/g,        to: 'IconlyLight.heart' },
  { from: /Icons\.favorite_rounded(?![a-zA-Z_0-9])/g,       to: 'IconlyBold.heart' },
  { from: /Icons\.favorite(?![a-zA-Z_0-9])/g,               to: 'IconlyBold.heart' },

  // ── Bookmark ─────────────────────────────────────────────────
  { from: /Icons\.bookmark_add_rounded(?![a-zA-Z_0-9])/g,   to: 'IconlyBold.bookmark' },
  { from: /Icons\.bookmark_border(?![a-zA-Z_0-9])/g,        to: 'IconlyLight.bookmark' },
  { from: /Icons\.bookmark_rounded(?![a-zA-Z_0-9])/g,       to: 'IconlyBold.bookmark' },
  { from: /Icons\.bookmark(?![a-zA-Z_0-9])/g,               to: 'IconlyBold.bookmark' },

  // ── Search ───────────────────────────────────────────────────
  { from: /Icons\.search_rounded(?![a-zA-Z_0-9])/g,         to: 'IconlyBold.search' },
  { from: /Icons\.search(?![a-zA-Z_0-9])/g,                 to: 'IconlyLight.search' },

  // ── Chat / Message ───────────────────────────────────────────
  { from: /Icons\.chat_bubble_outline_rounded(?![a-zA-Z_0-9])/g, to: 'IconlyLight.chat' },
  { from: /Icons\.chat_bubble_outline(?![a-zA-Z_0-9])/g,    to: 'IconlyLight.chat' },
  { from: /Icons\.chat_bubble_rounded(?![a-zA-Z_0-9])/g,    to: 'IconlyBold.chat' },

  // ── Send ─────────────────────────────────────────────────────
  { from: /Icons\.send_rounded(?![a-zA-Z_0-9])/g,           to: 'IconlyBold.send' },
  { from: /Icons\.send(?![a-zA-Z_0-9])/g,                   to: 'IconlyLight.send' },

  // ── Camera / Image / Photo ───────────────────────────────────
  { from: /Icons\.add_photo_alternate_rounded(?![a-zA-Z_0-9])/g, to: 'IconlyBold.camera' },
  { from: /Icons\.photo_library_rounded(?![a-zA-Z_0-9])/g,  to: 'IconlyLight.image' },
  { from: /Icons\.camera_alt_rounded(?![a-zA-Z_0-9])/g,     to: 'IconlyBold.camera' },
  { from: /Icons\.camera_alt(?![a-zA-Z_0-9])/g,             to: 'IconlyLight.camera' },
  { from: /Icons\.image_not_supported(?![a-zA-Z_0-9])/g,    to: 'IconlyLight.image' },
  { from: /Icons\.broken_image(?![a-zA-Z_0-9])/g,           to: 'IconlyLight.image' },
  { from: /Icons\.photo(?![a-zA-Z_0-9])/g,                  to: 'IconlyLight.image' },
  { from: /Icons\.image(?![a-zA-Z_0-9])/g,                  to: 'IconlyLight.image' },

  // ── More (…) ─────────────────────────────────────────────────
  { from: /Icons\.more_vert_rounded(?![a-zA-Z_0-9])/g,      to: 'IconlyLight.moreCircle' },
  { from: /Icons\.more_vert(?![a-zA-Z_0-9])/g,              to: 'IconlyLight.moreCircle' },
  { from: /Icons\.more_horiz(?![a-zA-Z_0-9])/g,             to: 'IconlyLight.moreSquare' },

  // ── Location ─────────────────────────────────────────────────
  { from: /Icons\.location_on(?![a-zA-Z_0-9])/g,            to: 'IconlyBold.location' },

  // ── Discovery / Explore ──────────────────────────────────────
  { from: /Icons\.explore_rounded(?![a-zA-Z_0-9])/g,        to: 'IconlyBold.discovery' },
  { from: /Icons\.explore(?![a-zA-Z_0-9])/g,                to: 'IconlyLight.discovery' },

  // ── Play ─────────────────────────────────────────────────────
  { from: /Icons\.play_circle_rounded(?![a-zA-Z_0-9])/g,    to: 'IconlyBold.play' },
  { from: /Icons\.play_arrow_rounded(?![a-zA-Z_0-9])/g,     to: 'IconlyLight.play' },
  { from: /Icons\.play_arrow(?![a-zA-Z_0-9])/g,             to: 'IconlyLight.play' },

  // ── Info / Lightbulb ─────────────────────────────────────────
  { from: /Icons\.info_outline(?![a-zA-Z_0-9])/g,           to: 'IconlyLight.infoSquare' },
  { from: /Icons\.lightbulb_outline(?![a-zA-Z_0-9])/g,      to: 'IconlyLight.infoSquare' },
  { from: /Icons\.info(?![a-zA-Z_0-9])/g,                   to: 'IconlyLight.infoSquare' },

  // ── Mic / Voice ──────────────────────────────────────────────
  { from: /Icons\.mic_none(?![a-zA-Z_0-9])/g,               to: 'IconlyLight.voice' },
  { from: /Icons\.mic(?![a-zA-Z_0-9])/g,                    to: 'IconlyBold.voice' },

  // ── Visibility / Show / Hide ─────────────────────────────────
  { from: /Icons\.visibility_off_outlined(?![a-zA-Z_0-9])/g, to: 'IconlyLight.hide' },
  { from: /Icons\.visibility_outlined(?![a-zA-Z_0-9])/g,    to: 'IconlyLight.show' },
  { from: /Icons\.visibility_off(?![a-zA-Z_0-9])/g,         to: 'IconlyLight.hide' },
  { from: /Icons\.visibility(?![a-zA-Z_0-9])/g,             to: 'IconlyLight.show' },

  // ── Lock ─────────────────────────────────────────────────────
  { from: /Icons\.lock_outline_rounded(?![a-zA-Z_0-9])/g,   to: 'IconlyLight.lock' },
  { from: /Icons\.lock_open(?![a-zA-Z_0-9])/g,              to: 'IconlyLight.unlock' },
  { from: /Icons\.lock(?![a-zA-Z_0-9])/g,                   to: 'IconlyBold.lock' },

  // ── Star ─────────────────────────────────────────────────────
  { from: /Icons\.star(?![a-zA-Z_0-9])/g,                   to: 'IconlyBold.star' },

  // ── Ticket / Activity ────────────────────────────────────────
  { from: /Icons\.local_activity(?![a-zA-Z_0-9])/g,         to: 'IconlyLight.ticket' },

  // ── Shopping ─────────────────────────────────────────────────
  { from: /Icons\.shopping_bag(?![a-zA-Z_0-9])/g,           to: 'IconlyLight.buy' },

  // ── List / Document ──────────────────────────────────────────
  { from: /Icons\.list_alt(?![a-zA-Z_0-9])/g,               to: 'IconlyLight.document' },

  // ── Error / Danger ───────────────────────────────────────────
  { from: /Icons\.error_outline(?![a-zA-Z_0-9])/g,          to: 'IconlyLight.danger' },
  // NB: Icons.error seul non remplacé (risque faux positifs)

  // ── History / Time ───────────────────────────────────────────
  { from: /Icons\.history_rounded(?![a-zA-Z_0-9])/g,        to: 'IconlyLight.timeCircle' },

  // ── Settings ─────────────────────────────────────────────────
  { from: /Icons\.settings(?![a-zA-Z_0-9])/g,               to: 'IconlyLight.setting' },

  // ── Delete ───────────────────────────────────────────────────
  { from: /Icons\.delete_rounded(?![a-zA-Z_0-9])/g,         to: 'IconlyBold.delete' },
  { from: /Icons\.delete(?![a-zA-Z_0-9])/g,                 to: 'IconlyLight.delete' },

  // ── Edit ─────────────────────────────────────────────────────
  { from: /Icons\.edit_rounded(?![a-zA-Z_0-9])/g,           to: 'IconlyBold.editSquare' },
  { from: /Icons\.edit(?![a-zA-Z_0-9])/g,                   to: 'IconlyLight.edit' },

  // ── Notification ─────────────────────────────────────────────
  { from: /Icons\.notifications_rounded(?![a-zA-Z_0-9])/g,  to: 'IconlyBold.notification' },
  { from: /Icons\.notifications(?![a-zA-Z_0-9])/g,          to: 'IconlyLight.notification' },

  // ── Home ─────────────────────────────────────────────────────
  { from: /Icons\.home_rounded(?![a-zA-Z_0-9])/g,           to: 'IconlyBold.home' },
  { from: /Icons\.home_outlined(?![a-zA-Z_0-9])/g,          to: 'IconlyLight.home' },
  { from: /Icons\.home(?![a-zA-Z_0-9])/g,                   to: 'IconlyBold.home' },

  // ── Filter ───────────────────────────────────────────────────
  { from: /Icons\.filter_list(?![a-zA-Z_0-9])/g,            to: 'IconlyLight.filter' },
  { from: /Icons\.tune(?![a-zA-Z_0-9])/g,                   to: 'IconlyLight.filter' },

  // ── Wallet / Euro (keep Material for euro symbol) ────────────
  { from: /Icons\.account_balance_wallet(?![a-zA-Z_0-9])/g, to: 'IconlyLight.wallet' },

  // ── Video ────────────────────────────────────────────────────
  { from: /Icons\.videocam(?![a-zA-Z_0-9])/g,               to: 'IconlyLight.video' },
  { from: /Icons\.video_call(?![a-zA-Z_0-9])/g,             to: 'IconlyLight.video' },

  // ── Calendar ─────────────────────────────────────────────────
  { from: /Icons\.calendar_today(?![a-zA-Z_0-9])/g,         to: 'IconlyLight.calendar' },
  { from: /Icons\.event(?![a-zA-Z_0-9])/g,                  to: 'IconlyLight.calendar' },
];

const ICONLY_IMPORT = "import 'package:flutter_iconly/flutter_iconly.dart';";
const updatedFiles = [];

function processDir(dir) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      processDir(full);
    } else if (entry.name.endsWith('.dart')) {
      processFile(full);
    }
  }
}

function processFile(filePath) {
  let content = fs.readFileSync(filePath, 'utf8');
  let modified = false;

  for (const { from, to } of mappings) {
    const next = content.replace(from, to);
    if (next !== content) {
      content = next;
      modified = true;
    }
  }

  if (!modified) return;

  // Ajouter l'import Iconly si le fichier utilise IconlyLight/IconlyBold mais ne l'a pas encore
  const usesIconly = /IconlyLight\.|IconlyBold\./.test(content);
  if (usesIconly && !content.includes(ICONLY_IMPORT)) {
    // Insérer juste après l'import material.dart
    content = content.replace(
      "import 'package:flutter/material.dart';",
      `import 'package:flutter/material.dart';\n${ICONLY_IMPORT}`
    );
    // Fallback si material.dart n'est pas le premier import
    if (!content.includes(ICONLY_IMPORT)) {
      const firstImport = content.indexOf("import '");
      if (firstImport !== -1) {
        content = content.slice(0, firstImport) + ICONLY_IMPORT + '\n' + content.slice(firstImport);
      }
    }
  }

  fs.writeFileSync(filePath, content, 'utf8');
  updatedFiles.push(path.basename(filePath));
  console.log('✅ Updated:', path.basename(filePath));
}

processDir('lib');

console.log('\n══════ SUMMARY ══════');
console.log(`${updatedFiles.length} file(s) updated:`);
updatedFiles.forEach(f => console.log('  -', f));
console.log('═════════════════════');
