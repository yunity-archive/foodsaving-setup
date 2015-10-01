var autobahn = require('autobahn');

var topic = process.argv[2] || 'yunity.public.hello';
var msg = process.argv[3] || 'Hello!';

var connection = new autobahn.Connection({
   url: 'ws://localhost:8090/ws',
   realm: 'realm1'
});

connection.onopen = function (session) {

  console.log('connected!');

  session.publish(topic, [msg], {}, {
      acknowledge: true
    }).then(function(publication){
      console.log('published', publication);
      connection.close();
    }, function(error) {
      console.log('publish error', error);
    });

};

connection.open();
