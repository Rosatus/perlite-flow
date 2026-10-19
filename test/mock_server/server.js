const http = require('http');
const url = require('url');

let hitCount = 0;
const log = (msg) => {
  hitCount++;
  console.log(`[${new Date().toISOString()}] #${hitCount} ${msg}`);
};

const tree = `
<div class="nav-files-container">
  <div class="tree-item nav-folder">
    <div class="tree-item-inner nav-folder-title-content">Daily</div>
    <div class="tree-item-children nav-folder-children">
      <div class="tree-item nav-file">
        <div class="tree-item-inner nav-file-title-content">2026-10-19</div>
        <div class="tree-item-flair-outer"><span class="nav-file-tag"></span></div>
        <a onclick="getContent('%2FDaily%2F2026-10-19')" href="#">open</a>
      </div>
    </div>
  </div>
  <div class="tree-item nav-file">
    <div class="tree-item-inner nav-file-title-content">Welcome</div>
    <a onclick="getContent('%2FWelcome')" href="#">open</a>
  </div>
  <div class="tree-item nav-file">
    <div class="tree-item-inner nav-file-title-content">Canvas</div>
    <div class="tree-item-flair-outer"><span class="nav-file-tag">canvas</span></div>
    <a onclick="getContent('%2FCanvas')" href="#">open</a>
  </div>
</div>`;

const notes = {
  '/Welcome': `<div class="mdTitleHide">Welcome</div>
    <h1>Welcome to Perlite Flow</h1>
    <p>This is a demo note. Tap <a class="internal-link" href="/Daily/2026-10-19">today's note</a> or visit <a href="https://example.com">external</a>.</p>
    <ul><li>Item one</li><li>Item two</li></ul>
    <pre><code>const x = 42;</code></pre>`,
  '/Daily/2026-10-19': `<div class="mdTitleHide">2026-10-19</div>
    <h1>Daily note</h1><p>Long content. ${'Lorem ipsum dolor sit amet. '.repeat(80)}</p>`,
  '/Canvas': `<div class="mdTitleHide">Canvas</div><p>Canvas placeholder.</p>`,
};

const home = `<div class="mdTitleHide">Home</div><h1>Vault index</h1><p>This is the home note.</p>`;

const server = http.createServer((req, res) => {
  const u = url.parse(req.url, true);
  log(`${req.method} ${req.url} from ${req.socket.remoteAddress}`);
  res.setHeader('Content-Type', 'text/html; charset=utf-8');

  if (u.pathname === '/content.php') {
    if ('mdfile' in u.query) {
      res.end(notes[u.query.mdfile] ?? `<p>not found: ${u.query.mdfile}</p>`);
      return;
    }
    if ('home' in u.query) { res.end(home); return; }
    if ('about' in u.query) { res.end('<p>perlite v0</p>'); return; }
    if ('search' in u.query) {
      const q = (u.query.search || '').toLowerCase();
      const results = [];
      if ('welcome'.includes(q) || 'perlite'.includes(q)) {
        results.push(`<div class="tree-item search-result"><div class="tree-item-inner">/Welcome</div><a onclick="getContent('%2FWelcome')"></a><div class="search-result-file-match">...a demo <span class="search-result-file-matched-text">${q}</span>. Tap tod...</div></div>`);
      }
      if ('daily'.includes(q) || 'lorem'.includes(q) || '2026'.includes(q)) {
        results.push(`<div class="tree-item search-result"><div class="tree-item-inner">/Daily/2026-10-19</div><a onclick="getContent('%2FDaily%2F2026-10-19')"></a><div class="search-result-file-match">...psum <span class="search-result-file-matched-text">${q}</span> dolor si...</div></div>`);
      }
      res.end(results.join(''));
      return;
    }
  }
  if (u.pathname === '/index.php' || u.pathname === '/') {
    res.end(`<html><body>${tree}</body></html>`);
    return;
  }
  res.statusCode = 404;
  res.end('not found');
});

server.listen(8080, '0.0.0.0', () => {
  console.log('mock perlite listening on :8080');
});
