package com.flix.flix_inpage

import android.util.Log
import com.flixmedia.flixmediasdk.FlixMedia
import com.flixmedia.flixmediasdk.WebViewConfiguration
import com.flixmedia.flixmediasdk.content.FlixMediaError
import com.flixmedia.flixmediasdk.models.ProductRequestParameters
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

class FlixInpagePlugin : FlutterPlugin, MethodCallHandler {
    companion object {
        private const val TAG = "FlixInpagePlugin"
    }

    private lateinit var channel: MethodChannel
    private lateinit var appContext: android.content.Context
    private val scope: CoroutineScope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        appContext = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flix_media/methods")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "initialize" -> handleInitialize(call, result)
            "initializeWithToken" -> handleInitializeWithToken(call, result)
            "updateToken" -> handleUpdateToken(call, result)
            "getInpageHtml" -> handleGetInpageHtml(call, result)
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        scope.cancel()
    }

    private fun handleInitialize(call: MethodCall, result: Result) {
        val args = call.arguments as? Map<*, *>
        val username = args?.get("username") as? String
        val password = args?.get("password") as? String
        val useSandbox = args?.get("useSandbox") as? Boolean ?: false

        if (username.isNullOrBlank() || password.isNullOrBlank()) {
            Log.e(TAG, "initialize: missing credentials (usernameBlank=${username.isNullOrBlank()}, passwordBlank=${password.isNullOrBlank()})")
            result.error("ARG", "Missing credentials", null)
            return
        }

        Log.d(
            TAG,
            "initialize: start useSandbox=$useSandbox usernameLength=${username.length} passwordLength=${password.length}"
        )

        scope.launch {
            try {
                FlixMedia.initialize(
                    context = appContext,
                    username = username,
                    password = password,
                    useSandbox = useSandbox,
                )
                result.success(null)
            } catch (error: Throwable) {
                Log.e(
                    TAG,
                    "initialize: failed type=${error::class.java.name} message=${error.message}",
                    error
                )
                result.error("INIT", error.message ?: "Initialization failed", null)
            }
        }
    }

    private fun handleInitializeWithToken(call: MethodCall, result: Result) {
        val args = call.arguments as? Map<*, *>
        val idToken = args?.get("idToken") as? String
        val useSandbox = args?.get("useSandbox") as? Boolean ?: false

        if (idToken.isNullOrBlank()) {
            result.error("ARG", "Missing idToken", null)
            return
        }

        scope.launch {
            try {
                FlixMedia.initialize(
                    context = appContext,
                    idToken = idToken,
                    expiresAt = args.normalizedExpiresAt(),
                    useSandbox = useSandbox,
                )
                result.success(null)
            } catch (error: Throwable) {
                Log.e(
                    TAG,
                    "initializeWithToken: failed type=${error::class.java.name} message=${error.message}",
                    error
                )
                result.error("INIT_TOKEN", error.message ?: "Token initialization failed", null)
            }
        }
    }

    private fun handleUpdateToken(call: MethodCall, result: Result) {
        val args = call.arguments as? Map<*, *>
        val idToken = args?.get("idToken") as? String

        if (idToken.isNullOrBlank()) {
            result.error("ARG", "Missing idToken", null)
            return
        }

        scope.launch {
            try {
                FlixMedia.updateToken(
                    context = appContext,
                    idToken = idToken,
                    expiresAt = args.normalizedExpiresAt(),
                )
                result.success(null)
            } catch (error: Throwable) {
                Log.e(
                    TAG,
                    "updateToken: failed type=${error::class.java.name} message=${error.message}",
                    error
                )
                result.error("UPDATE_TOKEN", error.message ?: "Token update failed", null)
            }
        }
    }

    suspend fun requestTokenUpdate() {
        suspendCancellableCoroutine<Unit> { continuation ->
            channel.invokeMethod("requestTokenUpdate", null, object : Result {
                override fun success(result: Any?) {
                    continuation.resume(Unit)
                }

                override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                    continuation.resumeWithException(
                        IllegalStateException(errorMessage ?: errorCode)
                    )
                }

                override fun notImplemented() {
                    continuation.resumeWithException(
                        NotImplementedError("requestTokenUpdate is not implemented")
                    )
                }
            })
        }
    }

    private fun handleGetInpageHtml(call: MethodCall, result: Result) {
        val args = call.arguments as? Map<*, *>
        val productParamsRaw = args?.get("productParams") as? Map<*, *>
        if (productParamsRaw == null) {
            result.error("ARG", "Missing productParams", null)
            return
        }

        val baseURL = (args["baseURL"] as? String)?.trim().takeUnless { it.isNullOrEmpty() }
            ?: "https://www.example.com"

        val productParams = ProductRequestParameters(
            mpn = productParamsRaw.stringOrEmpty("mpn"),
            ean = productParamsRaw.stringOrEmpty("ean"),
            distId = productParamsRaw.stringOrEmpty("distId", "distributorId"),
            isoCode = productParamsRaw.stringOrEmpty("isoCode"),
            flIsoCode = productParamsRaw.stringOrEmpty("flIsoCode"),
            brand = productParamsRaw.stringOrEmpty("brand"),
            title = productParamsRaw.stringOrEmpty("title"),
            price = productParamsRaw.stringOrEmpty("price"),
            currency = productParamsRaw.stringOrEmpty("currency"),
        )

        val configuration = WebViewConfiguration(
            params = productParams,
            baseURL = baseURL,
        )

        scope.launch {
            try {
                val html = loadHtmlWithTokenRefresh(configuration)
                result.success(html)
            } catch (error: Throwable) {
                Log.e(
                    TAG,
                    "getInpageHtml: failed type=${error::class.java.name} message=${error.message}",
                    error
                )
                result.error("HTML", error.message ?: "Failed to load HTML", null)
            }
        }
    }

    private suspend fun loadHtmlWithTokenRefresh(configuration: WebViewConfiguration): String {
        return try {
            FlixMedia.loadHTML(appContext, configuration)
        } catch (error: FlixMediaError.TokenExpired) {
            requestTokenUpdate()
            FlixMedia.loadHTML(appContext, configuration)
        }
    }

    private fun Map<*, *>.stringOrEmpty(vararg keys: String): String {
        for (key in keys) {
            val value = this[key] ?: continue
            return when (value) {
                is String -> value
                is Number, is Boolean -> value.toString()
                else -> ""
            }
        }
        return ""
    }

    private fun Map<*, *>?.normalizedExpiresAt(): Long? {
        val value = this?.get("expiresAt") ?: return null
        return when (value) {
            is Number -> value.toLong()
            is String -> value.toLongOrNull()
            else -> null
        }
    }
}
