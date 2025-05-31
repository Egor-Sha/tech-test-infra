import { createServer } from 'http';

const server = createServer((req, res) => {
  if (req.url === '/clock') {
    const epochSeconds = Date.now() / 1000;
    res.writeHead(200, { 'Content-Type': 'text/plain' });
    res.end(epochSeconds.toString());
  } else {
    res.writeHead(404);
    res.end('Not Found');
  }
});

const PORT = process.env.PORT || 8000;
server.listen(PORT, () => {
  console.log(`Server running at http://localhost:${PORT}`);
});
