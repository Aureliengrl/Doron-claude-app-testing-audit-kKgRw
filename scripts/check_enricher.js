const c = require('fs').readFileSync('doron_enricher.js', 'utf8');
console.log('Tag affilié doron072004-21:', c.includes('doron072004-21'));
console.log('applyAmazonTag:', c.includes('applyAmazonTag'));
console.log('affiliated tag:', c.includes('affiliateTag'));
console.log('Modèle Claude:', c.match(/model:\s+'([^']+)'/)?.[1]);
