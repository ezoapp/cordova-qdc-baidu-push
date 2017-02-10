package com.qdc.plugins.baidu;

import android.content.Context;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Iterator;
import java.util.List;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaWebView;
import org.apache.cordova.LOG;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import com.baidu.android.pushservice.PushConstants;
import com.baidu.android.pushservice.PushManager;

/**
 * 百度云推送插件
 * 
 * @author NCIT
 *
 */
public class BaiduPush extends CordovaPlugin {
    /** LOG TAG */
    private static final String LOG_TAG = BaiduPush.class.getSimpleName();

    private static CordovaWebView cachedWebView = null;

	/** JS回调接口对象 */
    private static CallbackContext onbindContext = null;
    private static CallbackContext cachedContext = null;

    private static List<JSONObject> cachedMessages = Collections.synchronizedList(new ArrayList<JSONObject>());
  
    /**
     * 插件初始化
     */
    @Override
    public void initialize(CordovaInterface cordova, CordovaWebView webView) {
    	LOG.d(LOG_TAG, "BaiduPush#initialize");
        super.initialize(cordova, webView);
    }

    /**
     * 插件主入口
     */
    @Override
    public boolean execute(final String action, final JSONArray args, final CallbackContext callbackContext) throws JSONException {
    	LOG.d(LOG_TAG, "BaiduPush#execute");
        cachedWebView = this.webView;

    	boolean ret = false;
    	
        if ("startWork".equalsIgnoreCase(action)) {

            onbindContext = callbackContext;
            sendNoResult(callbackContext);
            final String apiKey = args.getString(0);

            cordova.getThreadPool().execute(new Runnable() {
                public void run() {
                    LOG.d(LOG_TAG, "PushManager#startWork");
                    PushManager.startWork(getApplicationContext(), PushConstants.LOGIN_TYPE_API_KEY, apiKey);

                    if (!cachedMessages.isEmpty()) {
                        LOG.v(LOG_TAG, "sending cached messages");
                        synchronized(cachedMessages) {
                            Iterator<JSONObject> cachedMessagesIterator = cachedMessages.iterator();
                            while (cachedMessagesIterator.hasNext()) {
                                sendBindEvent(cachedMessagesIterator.next());
                            }
                        }
                        cachedMessages.clear();
                    }
                }
            });
            ret =  true;

        } else if ("stopWork".equalsIgnoreCase(action)) {

            cachedContext = callbackContext;
            sendNoResult(callbackContext);
            cordova.getThreadPool().execute(new Runnable() {
                public void run() {
                    LOG.d(LOG_TAG, "PushManager#stopWork");
                    PushManager.stopWork(getApplicationContext());
                }
            });
            ret =  true;

        } else if ("resumeWork".equalsIgnoreCase(action)) {

            cachedContext = callbackContext;
            sendNoResult(callbackContext);
            cordova.getThreadPool().execute(new Runnable() {
                public void run() {
                    LOG.d(LOG_TAG, "PushManager#resumeWork");
                    PushManager.resumeWork(getApplicationContext());
                }
            });
            ret = true;

        } else if ("setTags".equalsIgnoreCase(action)) {

            cachedContext = callbackContext;
            sendNoResult(callbackContext);
            cordova.getThreadPool().execute(new Runnable() {
                public void run() {
                    LOG.d(LOG_TAG, "PushManager#setTags");
                    List<String> tags = getTagArgs(args);
                    if (!tags.isEmpty()) {
                        PushManager.setTags(getApplicationContext(), tags);
                    }
                }
            });
            ret = true;

        } else if ("delTags".equalsIgnoreCase(action)) {

        	cachedContext = callbackContext;
            sendNoResult(callbackContext);
            cordova.getThreadPool().execute(new Runnable() {
                public void run() {
                    LOG.d(LOG_TAG, "PushManager#delTags");
                    List<String> tags = getTagArgs(args);
                    if (!tags.isEmpty()) {
                        PushManager.delTags(getApplicationContext(), tags);
                    }
                }
            });
            ret = true;

        } else if ("listTags".equalsIgnoreCase(action)) {

        	cachedContext = callbackContext;
            sendNoResult(callbackContext);
            cordova.getThreadPool().execute(new Runnable() {
                public void run() {
                    LOG.d(LOG_TAG, "PushManager#listTags");
                    PushManager.listTags(getApplicationContext());
                }
            });                        
            ret = true;

        }    

        return ret;
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        cachedWebView = null;
        onbindContext = null;
        cachedContext = null;
    }

    private List<String> getTagArgs(JSONArray args) {
        List<String> tags = new ArrayList<String>();

        if (args != null) {
            for (int i = 0; i < args.length(); i++) {
                try {
                    tags.add(args.getString(i));
                } catch (JSONException e) {
                    LOG.e(LOG_TAG, e.getMessage(), e);
                }
            }
        }

        return tags;
    }

    private Context getApplicationContext() {
        return cordova.getActivity().getApplicationContext();
    }

    private void sendNoResult(CallbackContext callbackContext) {
        PluginResult pluginResult = new PluginResult(PluginResult.Status.NO_RESULT);
        pluginResult.setKeepCallback(true);
        callbackContext.sendPluginResult(pluginResult);
    }

    public static void sendBindEvent(JSONObject messages) {
        if (messages != null) {
            if (cachedWebView != null && onbindContext != null) {
                PluginResult pluginResult = new PluginResult(PluginResult.Status.OK, messages);
                pluginResult.setKeepCallback(true);
                onbindContext.sendPluginResult(pluginResult);
            } else {
                LOG.v(LOG_TAG, "sendBindEvent: caching messages to send at a later time.");
                cachedMessages.add(messages);
            }
        }
    }

    public static void sendBindError(String message) {
        if (cachedWebView != null && onbindContext != null) {
            PluginResult pluginResult = new PluginResult(PluginResult.Status.ERROR, message);
            pluginResult.setKeepCallback(true);
            onbindContext.sendPluginResult(pluginResult);
        }
    }

    public static void sendEvent(JSONObject message) {
        if (cachedContext != null) {
            PluginResult pluginResult = new PluginResult(PluginResult.Status.OK, message);
            pluginResult.setKeepCallback(true);
            cachedContext.sendPluginResult(pluginResult);
        }
    }

    public static void sendError(String message) {
        if (cachedContext != null) {
            PluginResult pluginResult = new PluginResult(PluginResult.Status.ERROR, message);
            pluginResult.setKeepCallback(true);
            cachedContext.sendPluginResult(pluginResult);
        }
    }

}
