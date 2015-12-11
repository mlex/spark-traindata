var AWS = require('aws-sdk')
  , async = require('async')
  , requestPromise = require('request-promise')
  , http = require('http')
  , strftime = require('strftime');

var ZUGSONAR_INDEX = 'http://download.odcdn.de/zugsonar/'
// var ZUGSONAR_INDEX  = 'http://localhost:8000/zugsonar.html';

var MAX_PARALLEL_REQUESTS = 5;

var S3 = new AWS.S3({region:'eu-west-1', endpoint:'s3-eu-west-1.amazonaws.com'});

function extractUrls(baseUrl) {
  baseUrl = baseUrl.replace(/\/[^\/]*$/,'') + '/';
  return function(html) {
    var urlmatcher = /href="([^"]*)"/g
    var match;
    var matches = new Array();
    while (match = urlmatcher.exec(html)) {
      var href = match[1];
      if (! href.startsWith('http')) {
        href = baseUrl + href;
      }
      matches.push(href);
    }
    return matches;
  };
}

function print(obj) {
  console.log(obj);
  return obj;
}

requestPromise(ZUGSONAR_INDEX).
  then(print).
  then(extractUrls(ZUGSONAR_INDEX)).
  then(print).
  then(function(data) {
    return data.filter(function(url) {
      return url.match(/\.tsv\.7z$/);
    })
  }).
  then(print).
  then(function(data) {
    async.forEachOfLimit(data, MAX_PARALLEL_REQUESTS, function(url, idx, finishedCallback) {
      var filename = url.substring(url.lastIndexOf('/')+1);
      console.log('Downloading ' + url);
      http.
        get(url).
        on('error', function(error) {
          console.log('ERROR: Error downloading ' + url + '. ' + error);
          finishedCallback();
        }).
        on('response', function(response) {
          console.log('Starting S3 upload of ' + filename);
          var size = parseFloat(response.headers['content-length'], 10);
          var sizePercent = 0;
          S3.upload({
            Bucket: 'traindata.datalab',
            Key: filename,
            Body: response
          }).
          on('httpUploadProgress', function(evt) {
            if (size && size != 0 && evt.loaded && evt.loaded != 0) {
              var newPercent = Math.round(evt.loaded / size * 10) * 10;
              if (sizePercent != newPercent) {
                sizePercent = newPercent;
                console.log(strftime("%H:%M:%S") + ' Upload status for ' + filename  + ': ' + sizePercent + '%');
              }
            }
          }).
          send(function(err, data) {
            if (err) {
              console.log('ERROR: Upload of ' + filename + ' failed. ' + err);
            } else {
              console.log('Uploaded ' + filename + ' to ' + data.Location);
            }
            finishedCallback();
          });
        });
    });
  });
