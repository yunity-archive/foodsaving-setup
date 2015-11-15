var http = require('http');
var httpProxy = require('http-proxy');
var connect = require('connect');
var serveStatic = require('serve-static');

var SOCKETIO_PATH_RE = /^\/socket\//;

var SWAGGER_PORT = 9000;
var WEBAPP_PORT = 8090;
var MOBILE_PORT = 8091;
var DEV_PORT = 5000;

var DJANGO_BACKEND = 'http://localhost:8000';
var SOCKETIO_SERVER = 'http://localhost:8080';
var WEBAPP_SERVER = 'http://localhost:8083';
var MOBILE_SERVER = 'http://localhost:8084';
var SWAGGER_SERVER = 'http://localhost:' + SWAGGER_PORT;

var SWAGGER_PATH = '/swagger/dist/index-yunity.html';

var WEBAPP_URL = 'http://localhost:' + WEBAPP_PORT;
var MOBILE_URL = 'http://localhost:' + MOBILE_PORT;

var proxy = httpProxy.createProxyServer({});

/* these sites will be shown on the top bar of the admin/dev site */

var sites = [
  { name: 'web app',            url: WEBAPP_URL },
  { name: 'mobile web app',     url: MOBILE_URL },
  { name: 'swagger docs',       url: WEBAPP_URL + '/swagger' },
  { name: 'socket connections', url: 'http://localhost:9080/' }
];

/*

  proxy server for website
  ---------------------------------------------------

*/

createHttpServerFor(WEBAPP_SERVER).listen(WEBAPP_PORT);

/*

  proxy server for mobile website
  ---------------------------------------------------

*/

createHttpServerFor(MOBILE_SERVER).listen(MOBILE_PORT);

/*

  swagger ui
  ---------------------------------------------------

*/

var swagger = connect();
var swaggerBase = __dirname + '/swagger-ui/';
console.log('serving swagger files from', swaggerBase);
swagger.use(serveStatic(swaggerBase));
swagger.listen(SWAGGER_PORT);

/*

  little "admin/dev" homepage
  ---------------------------------------------------

*/

http.createServer(function(req, res){
  res.writeHead(200, {
    'Content-Type': 'text/html'
  });
  res.end([
    '<style type="text/css">li { display: inline; padding: 5px 10px; } iframe { position: absolute; bottom: 0; left: 0; right: 0; width: 100%; height: calc(100% - 50px); }</style>',
    '<ul>',
    '<li>yunity sites</li>',
    sites.map(function(site){
      return '<li><a href="' + site.url + '" target="aniceiframe">' + site.name + '</a></li>';
    }).join(''),
    '</ul>',
    '<iframe name="aniceiframe"></iframe>'
  ].join(''));
}).listen(DEV_PORT);

/*

  handle errors
  ---------------------------------------------------

*/

proxy.on('error', function(err, req, res){
  res.writeHead(500, {
    'Content-Type': 'text/plain'
  });
  res.end('error during proxy call - ' + err);
});

/*

  utility functions
  ---------------------------------------------------

*/

function redirect(res, url) {
  res.writeHead(302, {
    'Location': url
  });
  res.end();
}

function createHttpServerFor(backendServer) {

  var server = http.createServer(function(req, res) {
    console.log('proxy req from', req.url);
    if (/^\/api/.test(req.url) || /^\/doc/.test(req.url)) {
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
      proxy.web(req, res, { target: backendServer });
    }
  });

  server.on('upgrade', function (req, socket, head) {
    console.log('ws upgrade', req.url);
    if (SOCKETIO_PATH_RE.test(req.url)) {
      proxy.ws(req, socket, head, { target: SOCKETIO_SERVER });
    } else {
      proxy.ws(req, socket, head, { target: backendServer });
    }
  });

  return server;
}