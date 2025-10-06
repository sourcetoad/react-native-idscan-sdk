package com.sourcetoad.idscanreactnative

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.facebook.react.bridge.*
import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.modules.core.PermissionListener
import net.idscan.android.dlparser.DLParser
import net.idscan.android.dlparser.DLParser.DLParserException
import net.idscan.components.android.multiscan.MultiScanActivity
import net.idscan.components.android.multiscan.common.DocumentData
import net.idscan.components.android.multiscan.components.mrz.MRZComponent
import net.idscan.components.android.multiscan.components.mrz.MRZData
import net.idscan.components.android.multiscan.components.pdf417.PDF417Component
import net.idscan.components.android.multiscan.components.pdf417.PDF417Data
import kotlin.collections.HashMap

@ReactModule(name = IdscanSdkModule.NAME)
class IdscanSdkModule(reactContext: ReactApplicationContext) :
  ReactContextBaseJavaModule(reactContext), PermissionListener {
  private var callback: Callback? = null
  private var scannerType: String? = null
  private var scannerPDFKey: String? = null
  private var scannerMRZKey: String? = null
  private var parserKey: String? = null
  private var callbackCalled: Boolean = false;

  private val mActivityEventListener: ActivityEventListener =
    object : BaseActivityEventListener() {
      override fun onActivityResult(
        activity: Activity,
        requestCode: Int,
        resultCode: Int,
        data: Intent?
      ) {
        super.onActivityResult(activity, requestCode, resultCode, data)
        if (requestCode == SCAN_ACTIVITY_CODE) {
          var errorMessage = ""
          val scanResult = Arguments.createMap()

          when (resultCode) {
            MultiScanActivity.RESULT_OK -> if (data != null) {
              val document =
                data.getSerializableExtra(MultiScanActivity.DOCUMENT_DATA) as DocumentData?

              if (document != null) {
                val mrzData = MRZComponent.extractDataFromDocument(document)
                val pdf417Data = PDF417Component.extractDataFromDocument(document)

                when {
                  mrzData != null -> {
                    scanResult.putBoolean("success", true)
                    scanResult.putMap("data", parseMrzData(mrzData))
                  }
                  pdf417Data != null -> {
                    try {
                      scanResult.putBoolean("success", true)
                      scanResult.putMap("data", parsePdfData(pdf417Data))
                    } catch (e: DLParserException) {
                      errorMessage = e.message!!
                    }
                  }
                  else -> scanResult.putBoolean("success", false)
                }
              }
            }
            MultiScanActivity.ERROR_RECOGNITION -> errorMessage =
              data?.getStringExtra(MultiScanActivity.ERROR_DESCRIPTION).toString()
            MultiScanActivity.ERROR_INVALID_CAMERA_NUMBER -> errorMessage = "Invalid camera number."
            MultiScanActivity.ERROR_CAMERA_NOT_AVAILABLE -> errorMessage = "Camera not available."
            MultiScanActivity.ERROR_INVALID_CAMERA_ACCESS -> errorMessage = "Invalid camera access."
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
            executeCallback(errorMessage, scanResult)
          } else {
            executeCallback(null, scanResult)
          }
        }
      }
    }

  override fun getName(): String {
    return NAME
  }

  private fun parseMrzData(mrzData: MRZData): WritableNativeMap {
    val mappedResult = WritableNativeMap()
    for (field in mrzData.fields) {
      mappedResult.putString(field.key.name, field.value.value)
    }
    return mappedResult
  }

  private fun executeCallback(vararg args: Any?) {
    if (callbackCalled) {
      return
    }

    callback!!.invoke(*args)
    callbackCalled = true
  }

  private fun parsePdfData(pdfData: PDF417Data): WritableNativeMap {
    val parser = DLParser()
    parser.setup(reactApplicationContext, parserKey)
    val res = parser.parse(pdfData.barcodeData)
    val mappedResult = WritableNativeMap()

    for (field in res.javaClass.declaredFields) {
      mappedResult.putString(field.name, field.get(res)?.toString())
    }

    return mappedResult
  }

  @ReactMethod
  fun scan(type: String?, apiKeys: ReadableMap, callback: Callback) {
    Log.d(NAME, "React Native IDScanner starting")

    val hasMRZKey = apiKeys.hasKey(KEY_MRZ_KEY) && !apiKeys.isNull(KEY_MRZ_KEY)
    val hasPDFKey = apiKeys.hasKey(KEY_PDF_KEY) && !apiKeys.isNull(KEY_PDF_KEY)
    val hasParserKey = apiKeys.hasKey(KEY_PARSER_KEY) && !apiKeys.isNull(KEY_PARSER_KEY)

    if ((!hasMRZKey && !hasPDFKey) || !hasParserKey) {
      val scanResult = Arguments.createMap()
      scanResult.putString("success", "false")
      callback.invoke("Must provide activation keys for IDScan.net's Camera Scanner and ID Parser SDKs")
      return
    }

    scannerType = type
    scannerMRZKey = if (hasMRZKey) apiKeys.getString(KEY_MRZ_KEY) else ""
    scannerPDFKey = if (hasPDFKey) apiKeys.getString(KEY_PDF_KEY) else ""
    parserKey = apiKeys.getString(KEY_PARSER_KEY)

    this.callback = callback
    this.callbackCalled = false
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
      val multiScanActivity = MultiScanActivity.build(reactApplicationContext.currentActivity!!)

      if (!(scannerMRZKey!!).isNullOrEmpty()){
        multiScanActivity.withComponent(
          MRZComponent.build()
            .withLicenseKey(scannerMRZKey!!)
            .complete()
        )
      }

      if (!(scannerPDFKey!!).isNullOrEmpty()) {
        multiScanActivity.withComponent(
          PDF417Component.build()
            .withLicenseKey(scannerPDFKey!!)
            .complete()
        )
      }

      multiScanActivity.start(SCAN_ACTIVITY_CODE)
    } else {
      requestCameraPermissions(REQUEST_CAMERA_PERMISSIONS_DEFAULT)
    }
  }

  private fun checkCameraPermissions(): Boolean {
    val status =
      ContextCompat.checkSelfPermission(reactApplicationContext.currentActivity!!, Manifest.permission.CAMERA)
    return status == PackageManager.PERMISSION_GRANTED
  }

  private fun requestCameraPermissions(requestCode: Int) {
    ActivityCompat.requestPermissions(
      reactApplicationContext.currentActivity!!, arrayOf(Manifest.permission.CAMERA),
      requestCode
    )
  }

  override fun getConstants(): Map<String, Any> {
    val constants: MutableMap<String, Any> = HashMap()
    constants["TYPE_COMBINED"] = TYPE_COMBINED
    constants["TYPE_MRZ"] = TYPE_MRZ
    constants["TYPE_PDF"] = TYPE_PDF
    return constants
  }

  companion object {
    private const val TYPE_COMBINED = "combined"
    private const val TYPE_MRZ = "mrz"
    private const val TYPE_PDF = "pdf"

    private const val SCAN_ACTIVITY_CODE = 0x001
    private const val REQUEST_CAMERA_PERMISSIONS_DEFAULT = 0x100

    private const val KEY_PDF_KEY = "androidDetectorPDFLicenseKey"
    private const val KEY_MRZ_KEY = "androidDetectorMRZLicenseKey"
    private const val KEY_PARSER_KEY = "androidParserPDFLicenseKey"

    const val NAME = "IdscanSdk"
  }

  init {

    // Add the listener for `onActivityResult`
    reactContext.addActivityEventListener(mActivityEventListener)
  }
}
