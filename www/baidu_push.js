var exec = require('cordova/exec');

var baidu_push = {
    startWork: function() {
        var args = Array.prototype.slice.call(arguments);
        var apiKey = args[0];
        var mode = (typeof args[1] === 'string') ? args[1] : null;
        var successCallback = getSuccessCallback(args);
        var failureCallback = getFailureCallback(args);
        exec(successCallback, failureCallback, 'BaiduPush', 'startWork', [apiKey, mode]);
    },
    stopWork: function() {
        var args = Array.prototype.slice.call(arguments);
        var successCallback = getSuccessCallback(args);
        var failureCallback = getFailureCallback(args);        
        exec(successCallback, failureCallback, 'BaiduPush', 'stopWork', []);
    },
    resumeWork: function() {
        var args = Array.prototype.slice.call(arguments);
        var successCallback = getSuccessCallback(args);
        var failureCallback = getFailureCallback(args);        
        exec(successCallback, failureCallback, 'BaiduPush', 'resumeWork', []);
    },
    setTags: function() {
        var args = Array.prototype.slice.call(arguments);
        var tags = (isArray(args[0])) ? args[0] : [];
        var successCallback = getSuccessCallback(args);
        var failureCallback = getFailureCallback(args);
        exec(successCallback, failureCallback, 'BaiduPush', 'setTags', tags);
    },
    delTags: function() {
        var args = Array.prototype.slice.call(arguments);
        var tags = (isArray(args[0])) ? args[0] : [];
        var successCallback = getSuccessCallback(args);
        var failureCallback = getFailureCallback(args);        
        exec(successCallback, failureCallback, 'BaiduPush', 'delTags', tags);
    },
    listTags: function() {
        var args = Array.prototype.slice.call(arguments);
        var successCallback = getSuccessCallback(args);
        var failureCallback = getFailureCallback(args);        
        exec(successCallback, failureCallback, 'BaiduPush', 'listTags', []);
    },    
    successCallback: function (data) {
        console.log('baidu_push success. ', data);
    },
    failureCallback: function (err) {
        console.log('baidu_push failure. ',  err);
    }
};

function getSuccessCallback(args) {
    var lastOneArg = args[args.length - 1];
    var lastTwoArg = args[args.length - 2];
    if (typeof lastTwoArg === 'function' && typeof lastOneArg === 'function') {
        return lastTwoArg;
    }
    if (typeof lastTwoArg !== 'function' && typeof lastOneArg === 'function') {
        return lastOneArg;
    }
    return baidu_push.successCallback;
}

function getFailureCallback(args) {
    var lastOneArg = args[args.length - 1];
    var lastTwoArg = args[args.length - 2];
    if (typeof lastTwoArg === 'function' && typeof lastOneArg === 'function') {
        return lastOneArg;
    }
    return baidu_push.failureCallback;
}

function isArray(obj) {
    if (Object.prototype.toString.call(obj) === '[object Array]') {
        return true;
    }
    return false;
}

module.exports = baidu_push;
