var http = require('http');
var httpProxy = require('http-proxy');
var connect = require('connect');
var serveStatic = require('serve-static');
var fs = require('fs');
var tpl = require('./TemplateEngine.js');

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

var WEBAPP_URL = ':' + WEBAPP_PORT + '/';
var MOBILE_URL = ':' + MOBILE_PORT + '/';
var SOCKET_CONNECTION_VIEW_URL = ':9080/';

var proxy = httpProxy.createProxyServer({});

/* these sites will be shown on the top bar of the admin/dev site */

var sites = [
  { name: 'web app',            url: WEBAPP_URL },
  { name: 'mobile web app',     url: MOBILE_URL },
  { name: 'swagger',            url: WEBAPP_URL + 'swagger' },
  { name: 'socket connections', url: SOCKET_CONNECTION_VIEW_URL }
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
  fs.readFile('res/dev-view.tpl', 'utf8', function(err, data){
    if(err) {
      console.log('error reading dev view template');
      res.writeHead(500);
      res.end('Could not read template');
    } else {
      var host = req.headers['host'];
      host = 'http://' + host.split(':')[0];
      res.writeHead(200, {
        'Content-Type': 'text/html'
      });
      processed = tpl(data, {sites : sites, host: host});
      res.write(processed, 'utf8');
      res.end();
    }
  });
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
