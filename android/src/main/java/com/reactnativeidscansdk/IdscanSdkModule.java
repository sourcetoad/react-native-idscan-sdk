package com.reactnativeidscansdk;

import android.Manifest;
import android.app.Activity;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import com.facebook.react.bridge.ActivityEventListener;
import com.facebook.react.bridge.BaseActivityEventListener;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.module.annotations.ReactModule;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Callback;
import com.facebook.react.modules.core.PermissionListener;

import java.util.Map;
import java.util.HashMap;

import net.idscan.components.android.multiscan.MultiScanActivity;
import net.idscan.components.android.multiscan.common.DocumentData;
import net.idscan.components.android.multiscan.components.mrz.MRZComponent;
import net.idscan.components.android.multiscan.components.mrz.MRZData;
import net.idscan.components.android.multiscan.components.pdf417.PDF417Component;
import net.idscan.components.android.multiscan.components.pdf417.PDF417Data;

@ReactModule(name = IdscanSdkModule.NAME)
public class IdscanSdkModule extends ReactContextBaseJavaModule implements PermissionListener {
    static final String typeCombined = "combined";
    static final String typeMRZ = "mrz";
    static final String typePDF = "pdf";

    private final static int SCAN_ACTIVITY_CODE = 0x001;
    private final static int REQUEST_CAMERA_PERMISSIONS_DEFAULT = 0x100;
    private Callback callback;
    private String scannerType, scannerPDFKey, scannerMRZKey, parserKey;

    protected final static String[] permissions = { Manifest.permission.CAMERA, Manifest.permission.READ_EXTERNAL_STORAGE};

    public static final String NAME = "IdscanSdk";

    private final ActivityEventListener mActivityEventListener = new BaseActivityEventListener() {
      @Override
      public void onActivityResult(Activity activity, int requestCode, int resultCode, Intent data) {
        super.onActivityResult(activity, requestCode, resultCode, data);

        if (requestCode == SCAN_ACTIVITY_CODE) {
          switch (resultCode) {
            case MultiScanActivity.RESULT_OK:
              if (data != null) {
                DocumentData document = (DocumentData) data.getSerializableExtra(MultiScanActivity.DOCUMENT_DATA);
                if (document != null) {
                  MRZData mrzData = MRZComponent.extractDataFromDocument(document);
                  PDF417Data pdf417Data = PDF417Component.extractDataFromDocument(document);

                  if (mrzData != null) {
                    Log.d(NAME, "TODO: parse MRZ Data");
                  }

                  if (pdf417Data != null) {
                    Log.d(NAME, "TODO: parse PDF Data");
                  }
                }
              }
              break;

            case MultiScanActivity.ERROR_RECOGNITION:
              Log.d(NAME, data.getStringExtra(MultiScanActivity.ERROR_DESCRIPTION));
              break;

            case MultiScanActivity.ERROR_INVALID_CAMERA_NUMBER:
              Log.d(NAME, "Invalid camera number.");
              break;

            case MultiScanActivity.ERROR_CAMERA_NOT_AVAILABLE:
              Log.d(NAME, "Camera not available.");
              break;

            case MultiScanActivity.ERROR_INVALID_CAMERA_ACCESS:
              Log.d(NAME, "Invalid camera access.");
              break;

            case MultiScanActivity.RESULT_CANCELED:
              break;

            default:
              Log.d(NAME, "Undefined error.");
              break;
          }
        }
      }
    };

    public IdscanSdkModule(ReactApplicationContext reactContext) {
      super(reactContext);

      // Add the listener for `onActivityResult`
      reactContext.addActivityEventListener(mActivityEventListener);
    }

    @Override
    @NonNull
    public String getName() {
        return NAME;
    }

    @ReactMethod
    public void scan(String type, ReadableMap apiKeys, Callback callback) {
        Log.d(NAME, "React Native IDScanner starting");

        if (apiKeys.hasKey("androidDetectorPDFLicenseKey") && apiKeys.hasKey("androidDetectorMRZLicenseKey") && apiKeys.hasKey("androidParserPDFLicenseKey")) {
          this.scannerType = type;
          this.scannerMRZKey = apiKeys.getString("androidDetectorMRZLicenseKey");
          this.scannerPDFKey = apiKeys.getString("androidDetectorPDFLicenseKey");
          this.parserKey = apiKeys.getString("androidParserPDFLicenseKey");
        } else {
          WritableMap scanResult = Arguments.createMap();
          scanResult.putString("success", "false");
          callback.invoke("Must provide activation keys for IDScan.net's camera scanner and id parser SDKs");

          return;
        }

        this.callback = callback;
        showDefaultScanView();
    }

    @Override
    public boolean onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
      switch (requestCode) {
        case REQUEST_CAMERA_PERMISSIONS_DEFAULT:
          if (checkCameraPermissions()) {
            showDefaultScanView();
          }
          break;
      }

      return true;
    }

    private void showDefaultScanView() {
      if (checkCameraPermissions()) {
        MultiScanActivity.build(getCurrentActivity())
          .withComponent(PDF417Component.build()
            .withLicenseKey(this.scannerPDFKey)
            .complete())
          .withComponent(MRZComponent.build()
            .withLicenseKey(this.scannerMRZKey)
            .complete())
          .start(SCAN_ACTIVITY_CODE);
      } else {
        requestCameraPermissions(REQUEST_CAMERA_PERMISSIONS_DEFAULT);
      }
    }

    private boolean checkCameraPermissions() {
      int status = ContextCompat.checkSelfPermission(getCurrentActivity(), Manifest.permission.CAMERA);
      return (status == PackageManager.PERMISSION_GRANTED);
    }

    private void requestCameraPermissions(int requestCode) {
      ActivityCompat.requestPermissions(
        getCurrentActivity(),
        new String[]{Manifest.permission.CAMERA},
        requestCode);
    }

    @Override
    public Map<String, Object> getConstants() {
      final Map<String, Object> constants = new HashMap<>();

      constants.put("TYPE_COMBINED", "combined");
      constants.put("TYPE_MRZ", "mrz");
      constants.put("TYPE_PDF", "pdf");

      return constants;
    }
}
