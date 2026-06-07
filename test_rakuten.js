const appId = '46ca81e7-0edd-470a-8349-6057408bd3ba';
const affId = '54a003ba.b9f68257.54a003bb.33b2e077';
const accessKey = 'pk_rvua3cE54MueHdOmCFkeQ7FWMqATA4s5riMFf1gwb96';
const keyword = 'cadeau';

async function testRakuten() {
  const url1 = `https://app.rakuten.co.jp/services/api/IchibaItem/Search/20220601?format=json&keyword=${keyword}&applicationId=${accessKey}&affiliateId=${affId}`;
  
  // Test 2: Rakuten Marketing (LinkShare) API format
  const url2 = `https://api.rakutenmarketing.com/productsearch/1.0?keyword=${keyword}&max=5`;
  
  console.log('Testing URL 1 (RWS):', url1);
  try {
    const r1 = await fetch(url1);
    console.log('URL 1 Status:', r1.status);
    console.log('URL 1 Body:', await r1.text());
  } catch (e) { console.error('URL 1 Error:', e.message); }

  console.log('\\nTesting URL 2 (LinkShare):', url2);
  try {
    const r2 = await fetch(url2, { headers: { 'Authorization': `Bearer ${accessKey}` } });
    console.log('URL 2 Status:', r2.status);
    if (r2.ok) console.log('URL 2 Success:', (await r2.text()).substring(0, 200));
  } catch (e) { console.error('URL 2 Error:', e.message); }
}

testRakuten();
