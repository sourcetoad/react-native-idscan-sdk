package com.reactnativeidscansdk

import android.Manifest
import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.modules.core.PermissionListener
import android.app.Activity
import android.content.Intent
import net.idscan.components.android.multiscan.MultiScanActivity
import net.idscan.components.android.multiscan.common.DocumentData
import net.idscan.components.android.multiscan.components.mrz.MRZComponent
import net.idscan.components.android.multiscan.components.pdf417.PDF417Component
import android.content.pm.PackageManager
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.facebook.react.bridge.*
import java.util.HashMap

@ReactModule(name = IdscanSdkModule.NAME)
class IdscanSdkModule(reactContext: ReactApplicationContext) :
  ReactContextBaseJavaModule(reactContext), PermissionListener {
  private var callback: Callback? = null
  private var scannerType: String? = null
  private var scannerPDFKey: String? = null
  private var scannerMRZKey: String? = null
  private var parserKey: String? = null
  private val mActivityEventListener: ActivityEventListener =
    object : BaseActivityEventListener() {
      override fun onActivityResult(
        activity: Activity,
        requestCode: Int,
        resultCode: Int,
        data: Intent
      ) {
        super.onActivityResult(activity, requestCode, resultCode, data)
        if (requestCode == SCAN_ACTIVITY_CODE) {
          var errorMessage = ""
          val scanResult = Arguments.createMap()
          when (resultCode) {
            MultiScanActivity.RESULT_OK -> if (data != null) {
              val document =
                data.getSerializableExtra(MultiScanActivity.DOCUMENT_DATA) as DocumentData
              if (document != null) {
                val mrzData = MRZComponent.extractDataFromDocument(document)
                val pdf417Data = PDF417Component.extractDataFromDocument(document)
                if (mrzData != null) {
                  Log.d(NAME, "TODO: parse MRZ Data")
                }
                if (pdf417Data != null) {
                  Log.d(NAME, "TODO: parse PDF Data")
                }
              }
            }
            MultiScanActivity.ERROR_RECOGNITION -> errorMessage =
              data.getStringExtra(MultiScanActivity.ERROR_DESCRIPTION).toString()
            MultiScanActivity.ERROR_INVALID_CAMERA_NUMBER -> errorMessage =
              "Invalid camera number."
            MultiScanActivity.ERROR_CAMERA_NOT_AVAILABLE -> errorMessage =
              "Camera not available."
            MultiScanActivity.ERROR_INVALID_CAMERA_ACCESS -> errorMessage =
              "Invalid camera access."
            MultiScanActivity.RESULT_CANCELED -> {
              Log.d(NAME, "Cancelled IdScanner")
              val emptyData = Arguments.createMap() as ReadableMap
              scanResult.putBoolean("success", false)
              scanResult.putMap("data", emptyData)
            }
            else -> errorMessage = "Undefined error."
          }
          Log.d(NAME, errorMessage)
          if (errorMessage.length > 1) {
            scanResult.putString("success", "false")
            callback!!.invoke(errorMessage, scanResult)
          } else {
            callback!!.invoke(null, scanResult)
          }
        }
      }
    }

  override fun getName(): String {
    return NAME
  }

  @ReactMethod
  fun scan(type: String?, apiKeys: ReadableMap, callback: Callback) {
    Log.d(NAME, "React Native IDScanner starting")

    if (apiKeys.isNull(KEY_MRZ_KEY) || apiKeys.isNull(KEY_PDF_KEY) || apiKeys.isNull(KEY_PARSER_KEY)) {
      val scanResult = Arguments.createMap()
      scanResult.putString("success", "false")
      callback.invoke("Must provide activation keys for IDScan.net's camera scanner and id parser SDKs")
      return
    }

    scannerType = type
    scannerMRZKey = apiKeys.getString(KEY_MRZ_KEY)
    scannerPDFKey = apiKeys.getString(KEY_PDF_KEY)
    parserKey = apiKeys.getString(KEY_PARSER_KEY)

    this.callback = callback
    showDefaultScanView()
  }

  override fun onRequestPermissionsResult(
    requestCode: Int,
    permissions: Array<String>,
    grantResults: IntArray
  ): Boolean {
    when (requestCode) {
      REQUEST_CAMERA_PERMISSIONS_DEFAULT -> if (checkCameraPermissions()) {
        showDefaultScanView()
      }
    }
    return true
  }

  private fun showDefaultScanView() {
    if (checkCameraPermissions()) {
      MultiScanActivity.build(currentActivity!!)
        .withComponent(
          PDF417Component.build()
            .withLicenseKey(scannerPDFKey!!)
            .complete()
        )
        .withComponent(
          MRZComponent.build()
            .withLicenseKey(scannerMRZKey!!)
            .complete()
        )
        .start(SCAN_ACTIVITY_CODE)
    } else {
      requestCameraPermissions(REQUEST_CAMERA_PERMISSIONS_DEFAULT)
    }
  }

  private fun checkCameraPermissions(): Boolean {
    val status =
      ContextCompat.checkSelfPermission(currentActivity!!, Manifest.permission.CAMERA)
    return status == PackageManager.PERMISSION_GRANTED
  }

  private fun requestCameraPermissions(requestCode: Int) {
    ActivityCompat.requestPermissions(
      currentActivity!!, arrayOf(Manifest.permission.CAMERA),
      requestCode
    )
  }

  override fun getConstants(): Map<String, Any> {
    val constants: MutableMap<String, Any> = HashMap()
    constants["TYPE_COMBINED"] = typeCombined
    constants["TYPE_MRZ"] = typeMRZ
    constants["TYPE_PDF"] = typePDF
    return constants
  }

  companion object {
    const val typeCombined = "combined"
    const val typeMRZ = "mrz"
    const val typePDF = "pdf"

    private const val SCAN_ACTIVITY_CODE = 0x001
    private const val REQUEST_CAMERA_PERMISSIONS_DEFAULT = 0x100

    private const val KEY_PDF_KEY = "androidDetectorPDFLicenseKey"
    private const val KEY_MRZ_KEY = "androidDetectorMRZLicenseKey"
    private const val KEY_PARSER_KEY = "androidParserPDFLicenseKey"

    private val permissions =
      arrayOf(Manifest.permission.CAMERA, Manifest.permission.READ_EXTERNAL_STORAGE)

    const val NAME = "IdscanSdk"
  }

  init {

    // Add the listener for `onActivityResult`
    reactContext.addActivityEventListener(mActivityEventListener)
  }
}
