const fs = require('fs');
const files = [
    'lib/pages/new_pages/gift_results/gift_results_widget.dart',
    'lib/pages/new_pages/home_pinterest/home_pinterest_widget.dart',
    'lib/pages/new_pages/search_page/search_page_widget.dart',
    'lib/pages/new_pages/user_profile/user_profile_widget.dart'
];

const R = String.fromCharCode(0xFFFD);

const dict = {
    ['G' + R + 'n' + R + 'ration']: 'Génération',
    ['G' + R + 'n' + R + 'rez']: 'Générez',
    ['r' + R + 'sum' + R]: 'résumé',
    ['personnalis' + R]: 'personnalisé',
    ['R' + R + 'sultats']: 'Résultats',
    ['r' + R + 'sultat']: 'résultat',
    ['trouv' + R + 's']: 'trouvés',
    ['S' + R + 'lectionn' + R + 's']: 'Sélectionnés',
    ['s' + R + 'curis' + R]: 'sécurisé',
    [R + 'viter']: 'éviter',
    ['}' + R]: '}',
    ['0' + R]: '0',
    [')' + R]: ')',
    ['G' + R + 'n' + R + 'rer']: 'Générer',
    ['pr' + R + 'cision']: 'précision',
    ['connect' + R]: 'connecté',
    ['charg' + R + 's']: 'chargés',
    ['charg' + R]: 'chargé',
    ['cr' + R + 'er']: 'créer',
    ['popularit' + R]: 'popularité',
    ['sp' + R + 'cifique']: 'spécifique',
    ['requ' + R + 'te']: 'requête',
    ['n' + R + 'cessite']: 'nécessite',
    ['n' + R + 'cessaire']: 'nécessaire',
    ['Augment' + R]: 'Augmenté',
    ['R' + R + 'initialiser']: 'Réinitialiser',
    ['m' + R + 'me']: 'même',
    ['g' + R + 're']: 'gère',
    [R + 'a']: 'ça',
    ['utilis' + R + 's']: 'utilisés',
    ['th' + R + 'matiques']: 'thématiques',
    ['d' + R + 'j' + R]: 'déjà',
    ['cat' + R + 'gorie']: 'catégorie',
    ['d' + R + 'terminer']: 'déterminer',
    ['Am' + R + 'lioration']: 'Amélioration',
    ['r' + R + 'cup' + R + 'rer']: 'récupérer',
    ['imm' + R + 'diatement']: 'immédiatement',
    ['APR' + R + 's']: 'APRÈS',
    ['v' + R + 'tement']: 'vêtement',
    ['d' + R + 'co']: 'déco',
    ['beaut' + R]: 'beauté',
    ['cosm' + R + 'tique']: 'cosmétique',
    ['bien-' + R + 'tre']: 'bien-être',
    ['cr' + R + 'atif']: 'créatif',
    ['d' + R + 'faut']: 'défaut',
    ['succ' + R + 's']: 'succès',
    ['Id' + R + 'es']: 'Idées',
    ['D' + R + 'couvre']: 'Découvre',
    ['d' + R + 'couverte']: 'découverte',
    ['s' + R + 'lection']: 'sélection',
    ['diff' + R + 'rencier']: 'différencier',
    ['fl' + R + 'che']: 'flèche',
    ['c' + R + 'ur']: 'cœur',
    ['rafra' + R + 'chissement']: 'rafraîchissement',
    ['apr' + R + 's']: 'après',
    ['Cr' + R + 'e']: 'Crée',
    ['d' + R + 'tails']: 'détails',
    ['r' + R + 'ussite']: 'réussite',
    ['s' + R + 'lectionne']: 'sélectionne',
    ['sauvegard' + R + 's']: 'sauvegardés',
    ['s' + R + 'lectionn' + R]: 'sélectionné',
    ['supprim' + R]: 'supprimé',
    ['premi' + R + 're']: 'première',
    ['g' + R + 'n' + R + 'rer']: 'générer',
    ['appara' + R + 'tront']: 'apparaîtront',
    ['hi' + R + 'rarchie']: 'hiérarchie',
    ['ajout' + R]: 'ajouté',
    ['d' + R + 'sactiv' + R + 'es']: 'désactivées',
    ['cat' + R + 'gories']: 'catégories',
    ['r' + R + 'sultats']: 'résultats',
    ['D' + R + 'terminer']: 'Déterminer',
    ['V' + R + 'rifie']: 'Vérifie',

    ['V+' + R + 'rifier']: 'Vérifier',
    ['apr+' + R + 's']: 'après',
    ['+' + R + 'couter']: 'Écouter',
    ['param+' + R + 'tres']: 'paramètres',
    ['flout+' + R]: 'flouté',
    ['Cr+' + R + 'e']: 'Crée',
    ['acc+' + R + 'der']: 'accéder',
    ['lik+' + R + 's']: 'likés',
    ['lik+' + R]: 'liké',
    ['pr+' + R + 'f+' + R + 'r+' + R + 's']: 'préférés',
    ['+' + R]: 'à',

    ['pr' + R + 'm']: 'prénom',
    ['r' + R + 'cup']: 'récup',
    ['r' + R + 'ini']: 'réini',
    ['D' + R + 'j' + R]: 'Déjà',
    [R + 'tre']: 'être',
    ['r' + R + 'essaye']: 'réessaye',
    [R + 'C']: 'É',
    [' ' + R + ' ']: ' à ',
    ['(' + R + ' ']: '(à ',
    [R]: 'é'
};

files.forEach(f => {
    let c = fs.readFileSync(f, 'utf8');

    // Sort keys so longer matchers apply first
    const keys = Object.keys(dict).sort((a, b) => b.length - a.length);
    for (const k of keys) {
        c = c.split(k).join(dict[k]);
    }

    fs.writeFileSync(f, c, 'utf8');
});

console.log('Done replacement script!');
