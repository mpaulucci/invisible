var express = require('express');
var path = require('path');
var bodyParser = require('body-parser');
var invisible = require('../');

var app = express();
app.use(bodyParser());

var config = {
  rootFolder : path.join(__dirname, 'models')
};

app.use(invisible.router(config));
app.use(express.static(__dirname + '/public'));

app.listen(3000);
