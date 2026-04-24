const fs = require('fs');
const path = require('path');

// Second pass - icons missed in first pass (exact suffixes, 1-occurrence variants)
const mappings2 = [
  // person variants manqués
  { from: /Icons\.person_add_outlined(?![a-zA-Z_0-9])/g,   to: 'IconlyLight.addUser' },
  { from: /Icons\.person_add_alt_(?![a-zA-Z_0-9])/g,       to: 'IconlyLight.addUser' },
  { from: /Icons\.person_search_rounded(?![a-zA-Z_0-9])/g, to: 'IconlyLight.profile' },
  { from: /Icons\.person_search(?![a-zA-Z_0-9])/g,         to: 'IconlyLight.profile' },
  { from: /Icons\.person_outline(?![a-zA-Z_0-9])/g,        to: 'IconlyLight.profile' },
  { from: /Icons\.person_remove_outlined(?![a-zA-Z_0-9])/g, to: 'IconlyLight.profile' },
  { from: /Icons\.person_off_outlined(?![a-zA-Z_0-9])/g,   to: 'IconlyLight.profile' },
  { from: /Icons\.group_add(?![a-zA-Z_0-9])/g,             to: 'IconlyLight.addUser' },
  { from: /Icons\.group_rounded(?![a-zA-Z_0-9])/g,         to: 'IconlyLight.people' },
  { from: /Icons\.group_work(?![a-zA-Z_0-9])/g,            to: 'IconlyLight.people' },
  { from: /Icons\.people_outline_rounded(?![a-zA-Z_0-9])/g, to: 'IconlyLight.people' },
  { from: /Icons\.people(?![a-zA-Z_0-9])/g,                to: 'IconlyLight.people' },

  // heart / favorite variants manqués
  { from: /Icons\.favorite_border_rounded(?![a-zA-Z_0-9])/g, to: 'IconlyLight.heart' },
  { from: /Icons\.favorite_sharp(?![a-zA-Z_0-9])/g,        to: 'IconlyBold.heart' },

  // bookmark variant
  { from: /Icons\.bookmark_outline(?![a-zA-Z_0-9])/g,      to: 'IconlyLight.bookmark' },

  // search variants
  { from: /Icons\.search_off(?![a-zA-Z_0-9])/g,            to: 'IconlyLight.search' },
  { from: /Icons\.search_sharp(?![a-zA-Z_0-9])/g,          to: 'IconlyLight.search' },
  { from: /Icons\.manage_search_rounded(?![a-zA-Z_0-9])/g, to: 'IconlyLight.search' },

  // image variants
  { from: /Icons\.image_not_supported_outlined(?![a-zA-Z_0-9])/g, to: 'IconlyLight.image' },
  { from: /Icons\.image_not_supported_rounded(?![a-zA-Z_0-9])/g,  to: 'IconlyLight.image' },
  { from: /Icons\.photo_library_outlined(?![a-zA-Z_0-9])/g, to: 'IconlyLight.image' },
  { from: /Icons\.add_a_photo(?![a-zA-Z_0-9])/g,           to: 'IconlyBold.camera' },

  // delete variants
  { from: /Icons\.delete_outline_rounded(?![a-zA-Z_0-9])/g, to: 'IconlyLight.delete' },
  { from: /Icons\.delete_forever_rounded(?![a-zA-Z_0-9])/g, to: 'IconlyBold.delete' },
  { from: /Icons\.delete_sweep_rounded(?![a-zA-Z_0-9])/g,  to: 'IconlyBold.delete' },
  { from: /Icons\.delete_outline(?![a-zA-Z_0-9])/g,        to: 'IconlyLight.delete' },

  // edit variants
  { from: /Icons\.edit_outlined(?![a-zA-Z_0-9])/g,         to: 'IconlyLight.edit' },
  { from: /Icons\.edit_note_rounded(?![a-zA-Z_0-9])/g,     to: 'IconlyLight.editSquare' },

  // star variants
  { from: /Icons\.star_outline_rounded(?![a-zA-Z_0-9])/g,  to: 'IconlyLight.star' },
  { from: /Icons\.star_rounded(?![a-zA-Z_0-9])/g,          to: 'IconlyBold.star' },
  { from: /Icons\.stars_rounded(?![a-zA-Z_0-9])/g,         to: 'IconlyBold.star' },

  // info variants
  { from: /Icons\.info_outline_rounded(?![a-zA-Z_0-9])/g,  to: 'IconlyLight.infoSquare' },

  // lock
  { from: /Icons\.lock_outline(?![a-zA-Z_0-9])/g,          to: 'IconlyLight.lock' },

  // list
  { from: /Icons\.list_alt_rounded(?![a-zA-Z_0-9])/g,      to: 'IconlyLight.document' },
  { from: /Icons\.list(?![a-zA-Z_0-9])/g,                  to: 'IconlyLight.document' },

  // more
  { from: /Icons\.more_vert_rounded(?![a-zA-Z_0-9])/g,     to: 'IconlyLight.moreCircle' },

  // filter
  { from: /Icons\.tune_rounded(?![a-zA-Z_0-9])/g,          to: 'IconlyLight.filter' },

  // location
  { from: /Icons\.location_off(?![a-zA-Z_0-9])/g,          to: 'IconlyLight.location' },

  // shopping
  { from: /Icons\.shopping_bag_outlined(?![a-zA-Z_0-9])/g, to: 'IconlyLight.buy' },
  { from: /Icons\.shopping_cart(?![a-zA-Z_0-9])/g,         to: 'IconlyLight.buy' },
  { from: /Icons\.local_offer_rounded(?![a-zA-Z_0-9])/g,   to: 'IconlyLight.ticket' },

  // document / list
  { from: /Icons\.label_outline_rounded(?![a-zA-Z_0-9])/g, to: 'IconlyLight.document' },

  // settings
  { from: /Icons\.menu_rounded(?![a-zA-Z_0-9])/g,          to: 'IconlyLight.moreSquare' },

  // calendar
  { from: /Icons\.event_rounded(?![a-zA-Z_0-9])/g,         to: 'IconlyLight.calendar' },

  // logout
  { from: /Icons\.logout_rounded(?![a-zA-Z_0-9])/g,        to: 'IconlyLight.logout' },
  { from: /Icons\.exit_to_app(?![a-zA-Z_0-9])/g,           to: 'IconlyLight.logout' },

  // send/share
  { from: /Icons\.share_rounded(?![a-zA-Z_0-9])/g,         to: 'IconlyBold.send' },
  { from: /Icons\.ios_share_rounded(?![a-zA-Z_0-9])/g,     to: 'IconlyBold.send' },
  { from: /Icons\.ios_share(?![a-zA-Z_0-9])/g,             to: 'IconlyBold.send' },

  // notification
  { from: /Icons\.mark_email_read_outlined(?![a-zA-Z_0-9])/g, to: 'IconlyLight.notification' },
  { from: /Icons\.mail_outline(?![a-zA-Z_0-9])/g,          to: 'IconlyLight.message' },
  { from: /Icons\.alternate_email_rounded(?![a-zA-Z_0-9])/g, to: 'IconlyLight.message' },
  { from: /Icons\.alternate_email(?![a-zA-Z_0-9])/g,       to: 'IconlyLight.message' },

  // auto_fix (magic wand → activity)
  { from: /Icons\.auto_fix_high_rounded(?![a-zA-Z_0-9])/g, to: 'IconlyLight.activity' },
  { from: /Icons\.interests(?![a-zA-Z_0-9])/g,             to: 'IconlyLight.activity' },
  { from: /Icons\.rocket_launch(?![a-zA-Z_0-9])/g,         to: 'IconlyLight.activity' },
  { from: /Icons\.celebration(?![a-zA-Z_0-9])/g,           to: 'IconlyBold.star' },
  { from: /Icons\.thumb_up_outlined(?![a-zA-Z_0-9])/g,     to: 'IconlyLight.heart' },

  // contacts
  { from: /Icons\.contacts_rounded(?![a-zA-Z_0-9])/g,      to: 'IconlyLight.people' },

  // store → buy
  { from: /Icons\.storefront(?![a-zA-Z_0-9])/g,            to: 'IconlyLight.buy' },
  { from: /Icons\.store_mall_directory_outlined(?![a-zA-Z_0-9])/g, to: 'IconlyLight.buy' },
  { from: /Icons\.store(?![a-zA-Z_0-9])/g,                 to: 'IconlyLight.buy' },

  // verified
  { from: /Icons\.verified_user(?![a-zA-Z_0-9])/g,         to: 'IconlyBold.shieldDone' },
  { from: /Icons\.done_all(?![a-zA-Z_0-9])/g,              to: 'IconlyBold.shieldDone' },

  // camera extra
  { from: /Icons\.apps_rounded(?![a-zA-Z_0-9])/g,          to: 'IconlyLight.category' },

  // data
  { from: /Icons\.data_usage_outlined(?![a-zA-Z_0-9])/g,   to: 'IconlyLight.chart' },

  // language
  { from: /Icons\.language_rounded(?![a-zA-Z_0-9])/g,      to: 'IconlyLight.discovery' },

  // production_quantity_limits
  { from: /Icons\.production_quantity_limits(?![a-zA-Z_0-9])/g, to: 'IconlyLight.danger' },

  // scan
  { from: /Icons\.manage_search_rounded(?![a-zA-Z_0-9])/g, to: 'IconlyLight.scan' },
];

const ICONLY_IMPORT = "import 'package:flutter_iconly/flutter_iconly.dart';";
let totalUpdated = 0;

function processDir(dir) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) { processDir(full); continue; }
    if (!entry.name.endsWith('.dart')) continue;
    let content = fs.readFileSync(full, 'utf8');
    let modified = false;
    for (const { from, to } of mappings2) {
      const next = content.replace(from, to);
      if (next !== content) { content = next; modified = true; }
    }
    if (!modified) continue;
    // Add import if missing
    if (!content.includes(ICONLY_IMPORT)) {
      content = content.replace(
        "import 'package:flutter/material.dart';",
        `import 'package:flutter/material.dart';\n${ICONLY_IMPORT}`
      );
    }
    fs.writeFileSync(full, content, 'utf8');
    console.log('✅ Pass2 updated:', entry.name);
    totalUpdated++;
  }
}
processDir('lib');
console.log(`\nPass 2: ${totalUpdated} additional files updated.`);
