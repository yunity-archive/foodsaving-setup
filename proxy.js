var DJANGO_BACKEND = 'http://localhost:8000';
var SOCKETIO_SERVER = 'http://localhost:8080';
var SOCKETIO_PATH_RE = /^\/socket\.io/;
var WEBAPP_SERVER = 'http://localhost:8083';
var MOBILE_SERVER = 'http://localhost:8084';

var http = require('http');
var httpProxy = require('http-proxy');

var proxy = httpProxy.createProxyServer({});

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
  } else {
    // web
    proxy.web(req, res, { target: WEBAPP_SERVER });
  }

});

httpWeb.on('upgrade', function (req, socket, head) {
  console.log('ws upgrade web');
  proxy.ws(req, socket, head, { target: SOCKETIO_SERVER });
});

httpWeb.listen(8090);

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
  } else {
    // mobile
    proxy.web(req, res, { target: MOBILE_SERVER });
  }
});

httpMobile.on('upgrade', function (req, socket, head) {
  console.log('ws upgrade mobile');
  proxy.ws(req, socket, head, { target: SOCKETIO_SERVER });
});

httpMobile.listen(8091);

