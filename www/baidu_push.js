var exec = require('cordova/exec');

var baidu_push = {
  registered: false,
  startWork: function(api_key, successCallback) {
    exec(successCallback, baidu_push.failureFn, 'BaiduPush', 'startWork', [api_key]);
  },
  stopWork: function(successCallback) {
    exec(successCallback, baidu_push.failureFn, 'BaiduPush', 'stopWork', []);
  },
  resumeWork: function(successCallback) {
    exec(successCallback, baidu_push.failureFn, 'BaiduPush', 'resumeWork', []);
  },
  setTags: function(tags, successCallback) {
    exec(successCallback, baidu_push.failureFn, 'BaiduPush', 'setTags', tags);
  },
  delTags: function(tags, successCallback) {
    exec(successCallback, baidu_push.failureFn, 'BaiduPush', 'delTags', tags);
  },
  failureFn: function() {
    console.log('fail to register push');
  }
};

module.exports = baidu_push;
