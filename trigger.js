fetch('https://us-central1-doron-b3011.cloudfunctions.net/cleanAmazonDB', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({ data: {} }),
})
.then(res => res.json())
.then(json => console.log('Result:', json))
.catch(err => console.error('Error:', err));
