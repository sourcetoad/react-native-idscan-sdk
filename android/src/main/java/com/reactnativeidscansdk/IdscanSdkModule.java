package com.reactnativeidscansdk;

import androidx.annotation.NonNull;

import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.module.annotations.ReactModule;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.Arguments;

@ReactModule(name = IdscanSdkModule.NAME)
public class IdscanSdkModule extends ReactContextBaseJavaModule {
    public static final String NAME = "IdscanSdk";

    public IdscanSdkModule(ReactApplicationContext reactContext) {
        super(reactContext);
    }

    @Override
    @NonNull
    public String getName() {
        return NAME;
    }

    // TODO: trigger license scanner
    @ReactMethod
    public void scan(String cameraKey, String parserKey, Callback callback) {
        WritableMap scanResult = Arguments.createMap();

        scanResult.putString('name', 'John Doe')

        callback.invoke(null, scanResult)
    }

    public static native int nativeMultiply(int a, int b);
}
