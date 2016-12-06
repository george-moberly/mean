'use strict';

/**
 * Module dependencies.
 */
var config = require('../config'),
  chalk = require('chalk'),
  os = require('os'),
  path = require('path'),
  fs = require('fs'),
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

  var thisEnv = '';
  var CH_API_Token = '';

  var getVar = deasync(function (url, cb) {
    CH_API_Token = fs.readFileSync('/opt/ch/ch_token.txt', 'utf8');
    console.log('ConfigHub API token is ' + CH_API_Token);
    var osPlatform = os.type();
    if (osPlatform === 'Darwin') {
      thisEnv = 'DEV';
    } else {
      thisEnv = 'TEST';
    }

    console.log('this environment is ' + thisEnv);

    var userAgent = {
      'Client-Token': CH_API_Token, 'Context': 'SalesDemos;' + thisEnv + ';MEAN-AWS;AWS-us-east-1', 'Application-Name': 'MEAN', 'Client-Version': 'v1.5' };
    console.log('userAgent: ' + JSON.stringify(userAgent));
    request({ url: url, headers: userAgent },
      function (err, resp, body) {
        if (err) { cb(err, null); }
        cb(null, body);
      });
  });

  console.log('mongo URI was: ' + config.db.uri.toString());
  // expected return...
  // mongodb://localhost/mean-dev

  // get the mongo host value from ConfigHub
  //
  var myVar = getVar('https://api.confighub.com/rest/pull');
  var chProp = JSON.parse(myVar);
  console.log('got this value from ConfigHub: ' + myVar);

  config.db.uri = 'mongodb://' + chProp.properties.MongoHost.val + '/mean-dev';
  console.log('mongo URI is now: ' + config.db.uri.toString());

  if (thisEnv === "TEST") {
    config.db.options.user = chProp.properties.MongoMEAN_User.val;
    config.db.options.pass = chProp.properties.MongoMEAN_Password.val;

    console.log('mongo username: ' + config.db.options.user.toString());
    console.log('mongo password: ' + config.db.options.pass.toString());
  } else {
    console.log('mongo username/password unauthenticated in DEV');
  }

  console.log("mongoose params: " + config.db.uri.toString() + " : " + config.db.options.toString())
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
