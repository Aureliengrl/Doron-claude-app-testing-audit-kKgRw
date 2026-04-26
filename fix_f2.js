const fs = require('fs');

// ─── F2: swap bouton chat à droite du bouton "Trouver des amis" ───
const file = 'lib/pages/new_pages/search_page/search_page_widget.dart';
let c = fs.readFileSync(file, 'utf8');

const old = `  Widget _buildBottomActions() {
    return Row(
      children: [
        // Bouton Messages/Chat (Rond)
        _buildChatButtonWithBadge(),
        const SizedBox(width: 16),
        
        // Bouton Trouver des amis (navigue vers FriendsPage)
        Expanded(`;

const neu = `  Widget _buildBottomActions() {
    return Row(
      children: [
        // Bouton Trouver des amis (navigue vers FriendsPage) — F2: maintenant à gauche (Expanded)
        Expanded(`;

// Also need to move the chat button to the end
const old2 = `        ),
      ],
    );
  }

  /// Ajoute le produit`;

const neu2 = `        ),
        const SizedBox(width: 16),
        // Bouton Messages/Chat (Rond) — F2: maintenant à droite
        _buildChatButtonWithBadge(),
      ],
    );
  }

  /// Ajoute le produit`;

const tryReplace = (content, o, n, label) => {
  const oCRLF = o.replace(/\n/g, '\r\n');
  const nCRLF = n.replace(/\n/g, '\r\n');
  if (content.includes(oCRLF)) { console.log(label + ' CRLF'); return content.replace(oCRLF, nCRLF); }
  if (content.includes(o))     { console.log(label + ' LF');   return content.replace(o, n); }
  console.log('ERROR: ' + label + ' not found');
  return content;
};

c = tryReplace(c, old, neu, 'F2-swap1');
c = tryReplace(c, old2, neu2, 'F2-swap2');
fs.writeFileSync(file, c, 'utf8');
console.log('F2 done');
