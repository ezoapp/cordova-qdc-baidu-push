package com.qdc.plugins.baidu;

import java.util.ArrayList;
import java.util.List;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaWebView;
import org.apache.cordova.LOG;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;

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

	/** JS回调接口对象 */
    public static CallbackContext onbindContext = null;
    public static CallbackContext cachedContext = null;
  
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
    public boolean execute(String action, final JSONArray args, CallbackContext callbackContext) throws JSONException {
    	LOG.d(LOG_TAG, "BaiduPush#execute");

    	boolean ret = false;
    	
        if ("startWork".equalsIgnoreCase(action)) {
            this.onbindContext = callbackContext;

            final String apiKey = args.getString(0);

            PluginResult pluginResult = new PluginResult(PluginResult.Status.NO_RESULT);
            pluginResult.setKeepCallback(true);
            callbackContext.sendPluginResult(pluginResult);

            cordova.getThreadPool().execute(new Runnable() {
                public void run() {
                	LOG.d(LOG_TAG, "PushManager#startWork");
                    PushManager.startWork(cordova.getActivity().getApplicationContext(),
                            PushConstants.LOGIN_TYPE_API_KEY, apiKey);
                }
            });
            ret =  true;
        } else if ("stopWork".equalsIgnoreCase(action)) {
            this.cachedContext = callbackContext;

            PluginResult pluginResult = new PluginResult(PluginResult.Status.NO_RESULT);
            pluginResult.setKeepCallback(true);
            callbackContext.sendPluginResult(pluginResult);

            cordova.getThreadPool().execute(new Runnable() {
                public void run() {
                	LOG.d(LOG_TAG, "PushManager#stopWork");
                    PushManager.stopWork(cordova.getActivity().getApplicationContext());
                }
            });
            ret =  true;
        } else if ("resumeWork".equalsIgnoreCase(action)) {
            this.cachedContext = callbackContext;

            PluginResult pluginResult = new PluginResult(PluginResult.Status.NO_RESULT);
            pluginResult.setKeepCallback(true);
            callbackContext.sendPluginResult(pluginResult);

            cordova.getThreadPool().execute(new Runnable() {
                public void run() {
                	LOG.d(LOG_TAG, "PushManager#resumeWork");
                    PushManager.resumeWork(cordova.getActivity().getApplicationContext());
                }
            });
            ret = true;
        } else if ("setTags".equalsIgnoreCase(action)) {
            this.cachedContext = callbackContext;

            PluginResult pluginResult = new PluginResult(PluginResult.Status.NO_RESULT);
            pluginResult.setKeepCallback(true);
            callbackContext.sendPluginResult(pluginResult);

            cordova.getThreadPool().execute(new Runnable() {
                public void run() {
                	LOG.d(LOG_TAG, "PushManager#setTags");
                	
                	List<String> tags = null;
                	if (args != null && args.length() > 0) {
                		int len = args.length();
                		tags = new ArrayList<String>(len);
                		
                		for (int inx = 0; inx < len; inx++) {
                			try {
								tags.add(args.getString(inx));
							} catch (JSONException e) {
								LOG.e(LOG_TAG, e.getMessage(), e);
							}
                		}

                		PushManager.setTags(cordova.getActivity().getApplicationContext(), tags);
                	}
                	
                }
            });
            ret = true;
        } else if ("delTags".equalsIgnoreCase(action)) {
        	this.cachedContext = callbackContext;

            PluginResult pluginResult = new PluginResult(PluginResult.Status.NO_RESULT);
            pluginResult.setKeepCallback(true);
            callbackContext.sendPluginResult(pluginResult);

            cordova.getThreadPool().execute(new Runnable() {
                public void run() {
                	LOG.d(LOG_TAG, "PushManager#delTags");
                	
                	List<String> tags = null;
                	if (args != null && args.length() > 0) {
                		int len = args.length();
                		tags = new ArrayList<String>(len);
                		
                		for (int inx = 0; inx < len; inx++) {
                			try {
								tags.add(args.getString(inx));
							} catch (JSONException e) {
								LOG.e(LOG_TAG, e.getMessage(), e);
							}
                		}

                		PushManager.delTags(cordova.getActivity().getApplicationContext(), tags);
                	}
                	
                }
            });
            ret = true;
        } else if ("listTags".equalsIgnoreCase(action)) {
        	this.cachedContext = callbackContext;

            PluginResult pluginResult = new PluginResult(PluginResult.Status.NO_RESULT);
            pluginResult.setKeepCallback(true);
            callbackContext.sendPluginResult(pluginResult);
            
            cordova.getThreadPool().execute(new Runnable() {
                public void run() {
                	LOG.d(LOG_TAG, "PushManager#listTags");
                    PushManager.listTags(cordova.getActivity().getApplicationContext());
                }
            });                        
            ret = true;
        }    

        return ret;
    }
}
