var autobahn = require('autobahn');

var topic = process.argv[2] || 'yunity.public.hello';

var connection = new autobahn.Connection({
   url: 'ws://localhost:8090/ws',
   realm: 'realm1'
});

connection.onopen = function (session) {

  console.log('connected!');

  function onevent(args) {
    console.log("recv:", args[0]);
  }

  session.subscribe(topic, onevent)
    .then(function(subscription){
      console.log('subscribed to', subscription.topic);
    }, function(error){
      console.log('subscription error :(', error);
    });

};

connection.open();
