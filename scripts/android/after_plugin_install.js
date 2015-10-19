#!/usr/bin/env node

module.exports = function (context) {
    var path = context.requireCordovaModule('path'),
        fs = context.requireCordovaModule('fs'),
        projectRoot = context.opts.projectRoot,
        hook = context.hook,
        platforms = context.opts.cordova.platforms,
        ConfigParser = context.requireCordovaModule('cordova-lib/src/configparser/ConfigParser'),
        config = new ConfigParser(path.join(projectRoot, "config.xml")),
        packageName = config.android_packageName() || config.packageName();

    if (!packageName) {
        console.error("Package name could not be found!");
        return ;
    }

    // android platform available?
    if (platforms.indexOf("android") === -1) {
        console.info("Android platform has not been added.");
        return ;
    }

    if (hook === 'after_plugin_install') {
        console.info("Running Hook: " + hook + ", Package: " + packageName + ", Path: " + projectRoot);
        
        var targetDir = path.join(projectRoot, "platforms", "android", "src", "com.qdc.plugins.baidu".replace(/\./g, path.sep)),
            targetFile = path.join(targetDir, "BaiduPushReceiver.java");
        
        // replace keyword
        fs.readFile(targetFile, {encoding: 'utf-8'}, function (err, data) {
            if (err) {
                return err;
            }
            data = data.replace(/^import __PACKAGE_NAME__;/m, 'import ' + packageName + '.MainActivity;');
            fs.writeFileSync(targetFile, data);
        });
    }
};
