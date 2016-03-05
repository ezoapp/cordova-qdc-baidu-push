package com.qdc.plugins.baidu;

import java.util.List;

import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.content.Context;
import android.content.Intent;
import android.util.Log;

import com.baidu.android.pushservice.PushConstants;
import com.baidu.android.pushservice.PushMessageReceiver;
import __PACKAGE_NAME__;

/**
 * 百度云推送Service
 * 
 * @author NCIT
 *
 */
public class BaiduPushReceiver extends PushMessageReceiver {

	/** LOG TAG */
    private static final String LOG_TAG = BaiduPushReceiver.class.getSimpleName();
    
    /** 回调类型 */
    private enum CBType {
    	onbind,
    	onunbind,
    	onsettags,
    	ondeltags,
    	onlisttags,
    	onmessage,
    	onnotificationclicked,
    	onnotificationarrived
    };
    
    private enum ResultKey {
        type,
        appId,
        userId,
        channelId,
        requestId,
        successTags,
        failTags,
        tags,
        payload        
    };

    /**
     * 百度云推送绑定回调
     */
    @Override
    public void onBind(Context context, int errorCode, String appId, String userId, String channelId, String requestId) {
        Log.d(LOG_TAG, "BaiduPushReceiver#onBind");

        if (BaiduPush.onbindContext != null) {
            PluginResult result;
            if (checkBaiduResult(errorCode)) {
                JSONObject message = new JSONObject();
                try {
                    message.put(ResultKey.type + "", CBType.onbind);
                    message.put(ResultKey.appId + "", appId);
                    message.put(ResultKey.userId + "", userId);
                    message.put(ResultKey.channelId + "", channelId);
                    message.put(ResultKey.requestId + "", requestId);
                } catch (JSONException e) {
                    Log.e(LOG_TAG, e.getMessage(), e);
                }                
                result = new PluginResult(PluginResult.Status.OK, message);
                result.setKeepCallback(true);
            } else {
                result = new PluginResult(PluginResult.Status.ERROR, PushConstants.a(errorCode));
            }
            BaiduPush.onbindContext.sendPluginResult(result);                
        } 
    }

    /**
     * 百度云推送解除绑定回调
     */
    @Override
    public void onUnbind(Context context, int errorCode, String requestId) {
    	Log.d(LOG_TAG, "BaiduPushReceiver#onUnbind");

        if (BaiduPush.cachedContext != null) {
            PluginResult result;
            if (checkBaiduResult(errorCode)) {
                JSONObject message = new JSONObject();
                try {
                    message.put(ResultKey.type + "", CBType.onunbind);
                    message.put(ResultKey.requestId + "", requestId);
                } catch (JSONException e) {
                    Log.e(LOG_TAG, e.getMessage(), e);
                }                
                result = new PluginResult(PluginResult.Status.OK, message);
                result.setKeepCallback(true);
            } else {
                result = new PluginResult(PluginResult.Status.ERROR, PushConstants.a(errorCode));
            }
            BaiduPush.cachedContext.sendPluginResult(result);                
        }        
    }

    /**
     * 百度云推送TAG绑定回调
     */
    @Override
    public void onSetTags(Context context, int errorCode, List<String> successTags, List<String> failTags, String requestId) {
    	Log.d(LOG_TAG, "BaiduPushReceiver#onSetTags");

        if (BaiduPush.cachedContext != null) {
            PluginResult result;
            if (checkBaiduResult(errorCode)) {
                JSONObject message = new JSONObject();
                try {
                    message.put(ResultKey.type + "", CBType.onsettags);
                    message.put(ResultKey.successTags + "", new JSONArray(successTags));
                    message.put(ResultKey.failTags + "", new JSONArray(failTags));
                    message.put(ResultKey.requestId + "", requestId);
                } catch (JSONException e) {
                    Log.e(LOG_TAG, e.getMessage(), e);
                }                
                result = new PluginResult(PluginResult.Status.OK, message);
                result.setKeepCallback(true);
            } else {
                result = new PluginResult(PluginResult.Status.ERROR, PushConstants.a(errorCode));
            }
            BaiduPush.cachedContext.sendPluginResult(result);                
        }        
    }

    /**
     * 百度云推送解除TAG绑定回调
     */
    @Override
    public void onDelTags(Context context, int errorCode, List<String> successTags, List<String> failTags, String requestId) {
    	Log.d(LOG_TAG, "BaiduPushReceiver#onDelTags");

        if (BaiduPush.cachedContext != null) {
            PluginResult result;
            if (checkBaiduResult(errorCode)) {
                JSONObject message = new JSONObject();
                try {
                    message.put(ResultKey.type + "", CBType.ondeltags);
                    message.put(ResultKey.successTags + "", new JSONArray(successTags));
                    message.put(ResultKey.failTags + "", new JSONArray(failTags));
                    message.put(ResultKey.requestId + "", requestId);
                } catch (JSONException e) {
                    Log.e(LOG_TAG, e.getMessage(), e);
                }                
                result = new PluginResult(PluginResult.Status.OK, message);
                result.setKeepCallback(true);
            } else {
                result = new PluginResult(PluginResult.Status.ERROR, PushConstants.a(errorCode));
            }
            BaiduPush.cachedContext.sendPluginResult(result);                
        }  
    }

    /**
     * 百度云推送LISTTAG绑定回调
     */
    @Override
    public void onListTags(Context context, int errorCode, List<String> tags, String requestId) {
    	Log.d(LOG_TAG, "BaiduPushReceiver#onListTags");

        if (BaiduPush.cachedContext != null) {
            PluginResult result;
            if (checkBaiduResult(errorCode)) {
                JSONObject message = new JSONObject();
                try {
                    message.put(ResultKey.type + "", CBType.onlisttags);
                    message.put(ResultKey.tags + "", new JSONArray(tags));
                    message.put(ResultKey.requestId + "", requestId);
                } catch (JSONException e) {
                    Log.e(LOG_TAG, e.getMessage(), e);
                }                
                result = new PluginResult(PluginResult.Status.OK, message);
                result.setKeepCallback(true);
            } else {
                result = new PluginResult(PluginResult.Status.ERROR, PushConstants.a(errorCode));
            }
            BaiduPush.cachedContext.sendPluginResult(result);                
        }  
    }

    /**
     * 百度云推送透传消息回调
     */
    @Override
    public void onMessage(Context context, String messageString, String customContentString) {
        Log.d(LOG_TAG, "BaiduPushReceiver#onMessage");

        if (BaiduPush.onbindContext != null) {
            JSONObject message = new JSONObject();
            try {
                JSONObject payload = (customContentString != null && !"".equals(customContentString)) 
                    ? new JSONObject(customContentString): new JSONObject();
                payload.put("message", messageString);
                
                message.put(ResultKey.type + "", CBType.onmessage);
                message.put(ResultKey.payload + "", payload);
            } catch (JSONException e) {
                Log.e(LOG_TAG, e.getMessage(), e);
            }                
            PluginResult result = new PluginResult(PluginResult.Status.OK, message);
            result.setKeepCallback(true);
            BaiduPush.onbindContext.sendPluginResult(result);                
        }        
    }

    /**
     * 百度云推送通知点击回调
     */
    @Override
    public void onNotificationClicked(Context context, String title, String description, String customContentString) {
        Log.d(LOG_TAG, "BaiduPushReceiver#onNotificationClicked");

        if (BaiduPush.onbindContext != null) {
            JSONObject message = new JSONObject();
            try {
                JSONObject payload = (customContentString != null && !"".equals(customContentString)) 
                    ? new JSONObject(customContentString): new JSONObject();
                payload.put("title", title);
                payload.put("description", description);
                
                message.put(ResultKey.type + "", CBType.onnotificationclicked);
                message.put(ResultKey.payload + "", payload);
            } catch (JSONException e) {
                Log.e(LOG_TAG, e.getMessage(), e);
            }                
            PluginResult result = new PluginResult(PluginResult.Status.OK, message);
            result.setKeepCallback(true);
            BaiduPush.onbindContext.sendPluginResult(result);                
        }        

        Intent intent = new Intent();
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        intent.addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT);
        intent.setClass(context, MainActivity.class);
        // intent.putExtra(PushConstants.EXTRA_NOTIFICATION_TITLE, title);
        // intent.putExtra(PushConstants.EXTRA_NOTIFICATION_CONTENT, customContentString);
        context.startActivity(intent);
    }

    /**
     * 百度云推送通知接收回调
     */
    @Override
    public void onNotificationArrived(Context context, String title, String description, String customContentString) {
        Log.d(LOG_TAG, "BaiduPushReceiver#onNotificationArrived");

        if (BaiduPush.onbindContext != null) {
            JSONObject message = new JSONObject();
            try {
                JSONObject payload = (customContentString != null && !"".equals(customContentString)) 
                    ? new JSONObject(customContentString): new JSONObject();
                payload.put("title", title);
                payload.put("description", description);
                
                message.put(ResultKey.type + "", CBType.onnotificationarrived);
                message.put(ResultKey.payload + "", payload);
            } catch (JSONException e) {
                Log.e(LOG_TAG, e.getMessage(), e);
            }                
            PluginResult result = new PluginResult(PluginResult.Status.OK, message);
            result.setKeepCallback(true);
            BaiduPush.onbindContext.sendPluginResult(result);                
        }        
    }
    
    private boolean checkBaiduResult(int errorCode) {
        if (errorCode == 0) {
            return true;
        }
        return false;
    }
    
}
