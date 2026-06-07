const fs = require('fs');
const path = 'lib/repositories/src/person_repository.dart';
let content = fs.readFileSync(path, 'utf8');

content = content.replace(
  'FirebaseDataService.updatePersonPendingFlag(personId, isPending: false);',
  'FirebaseDataService.updatePersonPendingFlag(personId, false);'
);

content = content.replace(
  'FirebaseDataService.loadGiftListsForPerson(personId: personId);',
  'FirebaseDataService.loadGiftListsForPerson(personId);'
);

content = content.replace(
  'FirebaseDataService.loadLatestGiftListForPerson(personId: personId);',
  'FirebaseDataService.loadLatestGiftListForPerson(personId);'
);

fs.writeFileSync(path, content, 'utf8');
console.log('Fixed person_repository.dart');
