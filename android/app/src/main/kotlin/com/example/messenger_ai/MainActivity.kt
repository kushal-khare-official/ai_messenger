package com.example.messenger_ai

import android.content.Intent
import android.os.Bundle
import android.provider.Telephony
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.messenger_ai/sms"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isDefaultSmsApp" -> {
                    val isDefault = isDefaultSmsApp()
                    result.success(isDefault)
                }
                "requestDefaultSmsApp" -> {
                    requestDefaultSmsApp()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun isDefaultSmsApp(): Boolean {
        val packageName = applicationContext.packageName
        val defaultSmsPackage = Telephony.Sms.getDefaultSmsPackage(applicationContext)
        return packageName == defaultSmsPackage
    }

    private fun requestDefaultSmsApp() {
        val intent = Intent(Telephony.Sms.Intents.ACTION_CHANGE_DEFAULT)
        intent.putExtra(Telephony.Sms.Intents.EXTRA_PACKAGE_NAME, packageName)
        startActivity(intent)
    }
}
