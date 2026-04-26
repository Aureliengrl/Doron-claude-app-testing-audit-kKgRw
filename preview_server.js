const http = require('http');
const fs = require('fs');
const path = require('path');

http.createServer((req, res) => {
  const file = path.join('scripts', req.url === '/' ? 'navbar_preview.html' : req.url);
  try {
    const data = fs.readFileSync(file);
    const ext = path.extname(file);
    const ct = ext === '.html' ? 'text/html' : ext === '.css' ? 'text/css' : 'text/plain';
    res.writeHead(200, { 'Content-Type': ct + ';charset=utf-8' });
    res.end(data);
  } catch (e) {
    res.writeHead(404);
    res.end('Not found');
  }
}).listen(5501, () => console.log('Navbar preview running on http://localhost:5501'));
