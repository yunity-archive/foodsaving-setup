var DJANGO_BACKEND = 'http://localhost:8000';
var SOCKETIO_SERVER = 'http://localhost:8080';
var SOCKETIO_PATH_RE = /^\/socket\//;

var SWAGGER_PORT = 9000;
var WEBSITE_PORT = 8090;
var MOBILE_PORT = 8091;

var WEBAPP_SERVER = 'http://localhost:8083';
var MOBILE_SERVER = 'http://localhost:8084';

var SWAGGER_SERVER = 'http://localhost:' + SWAGGER_PORT;

var SWAGGER_PATH = '/swagger/dist/index.html';
var SWAGGER_URL = 'http://localhost:' + SWAGGER_PORT + SWAGGER_PATH;
var WEBSITE_URL = 'http://localhost:' + WEBSITE_PORT;
var MOBILE_URL = 'http://localhost:' + MOBILE_PORT;

var http = require('http');
var httpProxy = require('http-proxy');
var connect = require('connect');
var serveStatic = require('serve-static');

var proxy = httpProxy.createProxyServer({});

var sites = [
  { name: 'web app',        url: WEBSITE_URL },
  { name: 'mobile web app', url: MOBILE_URL },
  { name: 'swagger docs',   url: SWAGGER_URL },
];

http.createServer(function(req, res){
  res.writeHead(200, {
    'Content-Type': 'text/html'
  });
  res.end([
    '<h2>yunity sites</h2>',
    '<ul>',
    sites.map(function(site){
      return '<li><a href="' + site.url + '">' + site.name + '</a></li>';
    }).join(''),
    '</ul>'
  ].join(''));
}).listen(5000);

/*

  proxy server for website

*/

var httpWeb = http.createServer(function(req, res) {
  console.log('proxy web req from', req.url);

  if (/^\/api/.test(req.url)) {
    // django backend api
    proxy.web(req, res, { target: DJANGO_BACKEND });
  } else if (SOCKETIO_PATH_RE.test(req.url)) {
    // socket.io
    proxy.web(req, res, { target: SOCKETIO_SERVER });
  } else if (req.url === '/swagger') {
    redirect(res, SWAGGER_PATH);
  } else if (/^\/swagger\//.test(req.url)) {
    proxy.web(req, res, { target: SWAGGER_SERVER });
  } else {
    // web
    proxy.web(req, res, { target: WEBAPP_SERVER });
  }

});

httpWeb.on('upgrade', function (req, socket, head) {
  console.log('ws upgrade web', req.url);
  if (SOCKETIO_PATH_RE.test(req.url)) {
    proxy.ws(req, socket, head, { target: SOCKETIO_SERVER });
  } else {
    proxy.ws(req, socket, head, { target: WEBAPP_SERVER });
  }
});

httpWeb.listen(WEBSITE_PORT);

/*

  proxy server for mobile website

*/

var httpMobile = http.createServer(function(req, res) {
  console.log('proxy mobile req from', req.url);
  if (/^\/api/.test(req.url)) {
    // django backend api
    proxy.web(req, res, { target: DJANGO_BACKEND });
  } else if (SOCKETIO_PATH_RE.test(req.url)) {
    // socket.io
    proxy.web(req, res, { target: SOCKETIO_SERVER });
  } else if (req.url === '/swagger') {
    redirect(res, SWAGGER_PATH);
  } else if (/^\/swagger\//.test(req.url)) {
    proxy.web(req, res, { target: SWAGGER_SERVER });
  } else {
    // mobile
    proxy.web(req, res, { target: MOBILE_SERVER });
  }
});

httpMobile.on('upgrade', function (req, socket, head) {
  console.log('ws upgrade mobile', req.url);
  if (SOCKETIO_PATH_RE.test(req.url)) {
    proxy.ws(req, socket, head, { target: SOCKETIO_SERVER });
  } else {
    proxy.ws(req, socket, head, { target: MOBILE_SERVER });
  }
});

httpMobile.listen(MOBILE_PORT);

/*

  swagger ui

*/

var swagger = connect();
var swaggerBase = __dirname + '/swagger-ui/';
console.log('serving swagger files from', swaggerBase);
swagger.use(serveStatic(swaggerBase));
swagger.listen(SWAGGER_PORT);

/*

  handle errors

*/

proxy.on('error', function(err, req, res){
  res.writeHead(500, {
    'Content-Type': 'text/plain'
  });
  res.end('error during proxy call - ' + err);
});

/*

  utility functions

*/

function redirect(res, url) {
  res.writeHead(302, {
    'Location': url
  });
  res.end();
}