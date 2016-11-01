'use strict';

/**
 * Module dependencies.
 */
var config = require('../config'),
  chalk = require('chalk'),
  path = require('path'),
  request = require('request'),
  deasync = require('deasync'),
  mongoose = require('mongoose');

// Load the mongoose models
module.exports.loadModels = function (callback) {
  // Globbing model files
  config.files.server.models.forEach(function (modelPath) {
    require(path.resolve(modelPath));
  });

  if (callback) callback();
};

// Initialize Mongoose
module.exports.connect = function (cb) {
  var _this = this;

  var thisEnv = 'DEV';
  // var thisEnv = 'TEST';

  var getVar = deasync(function (url, cb) {
    var userAgent = { 'Client-Token': 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJyaWQiOjQ1MiwidHMiOjE0Nzc5Njg5NDg1NzN9.y3-LATwYKtY8Hg43VYLHDeQyH374Gs_1O31jTkDAdfg', 'Context': 'SalesDemos;' + thisEnv + ';MEAN-AWS;MongoReplicaMaster', 'Application-Name': 'MEAN', 'Client-Version': 'v1.5' };
    request({ url: url, headers: userAgent },
      function (err, resp, body) {
        if (err) { cb(err, null); }
        cb(null, body);
      });
  });

  var myVar = getVar('https://api.confighub.com/rest/pull');
  var chProp = JSON.parse(myVar);
  config.db.uri = chProp.properties.MongoHost.val;
  console.log(myVar);
  console.log('the mongo master will be connected at: ' + config.db.uri.toString());

  var db = mongoose.connect(config.db.uri, config.db.options, function (err) {
    // Log Error
    if (err) {
      console.error(chalk.red('Could not connect to MongoDB!'));
      console.log(err);
    } else {

      mongoose.Promise = config.db.promise;

      // Enabling mongoose debug mode if required
      mongoose.set('debug', config.db.debug);

      // Call callback FN
      if (cb) cb(db);
    }
  });
};

module.exports.disconnect = function (cb) {
  mongoose.disconnect(function (err) {
    console.info(chalk.yellow('Disconnected from MongoDB.'));
    cb(err);
  });
};
