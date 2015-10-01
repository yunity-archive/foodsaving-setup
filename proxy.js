var http = require('http'),
    httpProxy = require('http-proxy');

var proxy = httpProxy.createProxyServer({});

// proxy server for website http://localhost:8090

var httpWeb = http.createServer(function(req, res) {
  console.log('proxy web req from', req.url);

  if (/^\/api/.test(req.url)) {
    // django backend api
    proxy.web(req, res, { target: 'http://localhost:8000' });
  } else {
    // web
    proxy.web(req, res, { target: 'http://localhost:8083' });
  }

});

httpWeb.on('upgrade', function (req, socket, head) {
  console.log('ws upgrade web');
  proxy.ws(req, socket, head, { target: 'http://localhost:8080' });
});

httpWeb.listen(8090);

// proxy server for mobile site http://localhost:8091

var httpMobile = http.createServer(function(req, res) {
  console.log('proxy mobile req from', req.url);
  if (/^\/api/.test(req.url)) {
    // django backend api
    proxy.web(req, res, { target: 'http://localhost:8000' });
  } else {
    // mobile
    proxy.web(req, res, { target: 'http://localhost:8084' });
  }
});

httpMobile.on('upgrade', function (req, socket, head) {
  console.log('ws upgrade mobile');
  proxy.ws(req, socket, head, { target: 'http://localhost:8080' });
});

httpMobile.listen(8091);

