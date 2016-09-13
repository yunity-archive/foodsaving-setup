var http = require('http');
var httpProxy = require('http-proxy');
var connect = require('connect');
var fs = require('fs');
var tpl = require('./TemplateEngine.js');

var SOCKETIO_PATH_RE = /^\/socket\//;

var SWAGGER_PORT = 9000;
var DEV_PORT = 5000;

var DJANGO_BACKEND = 'http://localhost:8000';
var SOCKETIO_SERVER = 'http://localhost:8080';

var SOCKET_CONNECTION_VIEW_URL = ':9080/';
var ANGULAR_URL = 'http://localhost:3000';

var proxy = httpProxy.createProxyServer({});

/* these sites will be shown on the top bar of the admin/dev site */

var sites = [
  { name: 'angular frontend',      url: ANGULAR_URL },
  { name: 'socket connections',    url: SOCKET_CONNECTION_VIEW_URL },
  { name: 'angular material docs', url: 'https://material.angularjs.org/1.0.6/' },
  { name: 'swagger',               url: DJANGO_BACKEND + '/docs/', external: true }
];

/*

  little "admin/dev" homepage
  ---------------------------------------------------

*/

http.createServer(function(req, res){
  fs.readFile(__dirname + '/dev-view.tpl', 'utf8', function(err, data){
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
      processed = tpl(data, {
        sites: sites.map(function(site){
          site = clone(site);
          if (/^http/.test(site.url)) {
            site.href = site.url;
          } else {
            site.href = host + site.url;
          }
          if (site.external) {
            site.target = '_blank';
            site.name = site.name + ' (external)';
          } else {
            site.target = 'aniceiframe';
          }
          return site;
        })
      });
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

function clone(src) {
  var dst = {};
  Object.keys(src).forEach(function(key){
    dst[key] = src[key];
  });
  return dst;
}
