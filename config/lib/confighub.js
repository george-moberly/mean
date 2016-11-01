'use strict';

var config = require('../config'),
  fetch = require('node-fetch');

module.exports.getMongoMaster = function(cb) {
  var fn = function() {};
  fetch('https://api.confighub.com/rest/pull', { method: 'GET', headers: { 'Client-Token': 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJyaWQiOjQ1MiwidHMiOjE0Nzc5Njg5NDg1NzN9.y3-LATwYKtY8Hg43VYLHDeQyH374Gs_1O31jTkDAdfg', 'Context': 'SalesDemos;DEV;MEAN-AWS;MongoReplicaMaster', 'Application-Name': 'MEAN', 'Client-Version': 'v1.5'} })
    .then(function(res) {
      return (res.json());
    }).then(function(json) {
      console.log(json);
      config.db.uri = json.properties.MongoHost.val;
      console.log(config.db.uri);
      if (cb) cb(fn);
      //return (json);
    });
};
