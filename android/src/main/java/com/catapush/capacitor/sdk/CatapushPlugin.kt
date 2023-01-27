package com.catapush.capacitor.sdk

import android.annotation.SuppressLint
import android.app.Activity
import android.content.Context
import android.net.Uri
import android.util.Log
import com.catapush.library.Catapush
import com.catapush.library.exceptions.CatapushAuthenticationError
import com.catapush.library.exceptions.CatapushConnectionError
import com.catapush.library.exceptions.PushServicesException
import com.catapush.library.interfaces.Callback
import com.catapush.library.interfaces.ICatapushEventDelegate
import com.catapush.library.interfaces.RecoverableErrorCallback
import com.catapush.library.messages.CatapushMessage
import com.catapush.library.push.models.PushPlatformType
import com.catapush.library.push.models.PushPluginType
import com.getcapacitor.JSObject
import com.getcapacitor.Plugin
import com.getcapacitor.PluginCall
import com.getcapacitor.PluginMethod
import com.getcapacitor.annotation.CapacitorPlugin
import com.google.android.gms.common.GoogleApiAvailability
import org.json.JSONArray
import java.io.File
import java.io.FileOutputStream
import java.lang.ref.WeakReference
import java.lang.reflect.Modifier

@CapacitorPlugin(name = "CatapushPlugin")
class CatapushPlugin : Plugin(), IMessagesDispatchDelegate, IStatusDispatchDelegate {

    private var inited = false

    init {
        try {
            val pluginType = Catapush::class.java.getDeclaredField("pluginType")
            pluginType.isAccessible = true
            pluginType[Catapush.getInstance() as Catapush] = PushPluginType.Capacitor
        } catch (e: Exception) {
            Log.e("CatapushPlugin", "Can't initialize plugin instance", e)
        }

        instanceRef = WeakReference(this)
    }

    companion object {
        private val tappedMessagesQueue = ArrayList<CatapushMessage>()
        private var instanceRef: WeakReference<CatapushPlugin>? = null
            set(value) {
                field = value
                value?.get()?.tryDispatchQueuedEvents()
            }

        fun handleNotificationTapped(message: CatapushMessage) {
            val instance = instanceRef?.get()
            if (instance?.isChannelReady() == true) {
                instance.dispatchNotificationTapped(message)
            } else {
                tappedMessagesQueue.add(message)
            }
        }

        private lateinit var companionContext: WeakReference<Context>
        private var messageDispatchDelegate: IMessagesDispatchDelegate? = null
        private var statusDispatchDelegate: IStatusDispatchDelegate? = null

        val eventDelegate = object : ICatapushEventDelegate {

            override fun onDisconnected(e: CatapushConnectionError) {
                statusDispatchDelegate?.dispatchConnectionStatus("disconnected")
            }

            override fun onMessageOpened(message: CatapushMessage) {
                // TODO
            }

            override fun onMessageOpenedConfirmed(message: CatapushMessage) {
                // TODO
            }

            override fun onMessageSent(message: CatapushMessage) {
                messageDispatchDelegate?.dispatchMessageSent(message)
            }

            override fun onMessageSentConfirmed(message: CatapushMessage) {
                // TODO
            }

            override fun onMessageReceived(message: CatapushMessage) {
                messageDispatchDelegate?.dispatchMessageReceived(message)
            }

            override fun onMessageReceivedConfirmed(message: CatapushMessage) {
                // TODO
            }

            override fun onRegistrationFailed(error: CatapushAuthenticationError) {
                CatapushAuthenticationError::class.java.declaredFields.firstOrNull {
                    Modifier.isStatic(it.modifiers)
                            && it.type == Integer::class
                            && it.getInt(error) == error.reasonCode
                }?.also { statusDispatchDelegate?.dispatchError(it.name, error.reasonCode) }
            }

            override fun onConnecting() {
                statusDispatchDelegate?.dispatchConnectionStatus("connecting")
            }

            override fun onConnected() {
                statusDispatchDelegate?.dispatchConnectionStatus("connected")
            }

            override fun onPushServicesError(e: PushServicesException) {
                // TODO
                if (PushPlatformType.GMS.name == e.platform && e.isUserResolvable) {
                    // It's a GMS error and it's user resolvable: show a notification to the user
                    val gmsAvailability = GoogleApiAvailability.getInstance()
                    /*gmsAvailability.setDefaultNotificationChannelId(
                    context, brandSupport.getNotificationChannelId(context)
                )*/
                    gmsAvailability.showErrorNotification(companionContext.get()!!, e.errorCode)
                }
            }

        }
    }

    override fun dispatchMessageReceived(message: CatapushMessage) {
        val params = JSObject()
        params.put("message", message.toJsonObject())
        notifyListeners("Catapush#catapushMessageReceived", params)
    }

    override fun dispatchMessageSent(message: CatapushMessage) {
        val params = JSObject()
        params.put("message",  message.toJsonObject())
        notifyListeners("Catapush#catapushMessageSent", params)
    }

    override fun dispatchNotificationTapped(message: CatapushMessage) {
        val params = JSObject()
        params.put("message",  message.toJsonObject())
        notifyListeners("Catapush#catapushNotificationTapped", params)
    }

    override fun dispatchConnectionStatus(status: String) {
        val params = JSObject()
        params.put("status", status)
        notifyListeners("Catapush#catapushStateChanged", params)
    }

    override fun dispatchError(event: String, code: Int) {
        val params = JSObject()
        params.put("event", event)
        params.put("code", code)
        notifyListeners("Catapush#catapushHandleError", params)
    }

    @PluginMethod
    @SuppressLint("RestrictedApi")
    fun init(call: PluginCall) {
        messageDispatchDelegate = this
        statusDispatchDelegate = this
        companionContext = WeakReference(context)

        inited = (Catapush.getInstance() as Catapush).waitInitialization()
        if (inited) {
            tryDispatchQueuedEvents()
            call.resolve()
        } else {
            call.reject("Please invoke Catapush.getInstance().init(...) in the Application.onCreate(...) callback of your Android native app")
        }
    }

    @PluginMethod
    fun setUser(call: PluginCall) {
        val identifier = call.getString("identifier")
        val password = call.getString("password")
        if (identifier?.isNotBlank() == true && password?.isNotBlank() == true) {
            Catapush.getInstance().setUser(identifier, password)
            call.resolve()
        } else {
            call.reject("Arguments: identifier=$identifier password=$password")
        }
    }

    @PluginMethod
    @SuppressLint("MissingPermission")
    fun start(call: PluginCall) {
        Catapush.getInstance().start(object : RecoverableErrorCallback<Boolean> {
            override fun success(response: Boolean) {
                call.resolve()
            }
            override fun warning(recoverableError: Throwable) {
                Log.w("CatapushPlugin", "Recoverable error", recoverableError)
            }
            override fun failure(irrecoverableError: Throwable) {
                call.reject(irrecoverableError.localizedMessage)
            }
        })
    }

    @PluginMethod
    fun allMessages(call: PluginCall) {
        Catapush.getInstance().getMessagesAsList(object : Callback<List<CatapushMessage>> {
            override fun success(response: List<CatapushMessage>) {
                call.resolve(response.toJsonArray())
            }
            override fun failure(irrecoverableError: Throwable) {
                call.reject(irrecoverableError.localizedMessage)
            }
        })
    }

    @PluginMethod
    fun enableLog(call: PluginCall) {
        val enabled = call.getBoolean("enabled")
        if (enabled == true)
            Catapush.getInstance().enableLog()
        else
            Catapush.getInstance().disableLog()
        call.resolve()
    }

    @SuppressLint("MissingPermission")
    @PluginMethod
    fun sendMessage(call: PluginCall) {
        val body = if (call.hasOption("body")) call.getString("body") else null
        val channel = if (call.hasOption("channel")) call.getString("channel") else null
        val replyTo = if (call.hasOption("replyTo")) call.getString("replyTo") else null
        val file = if (call.hasOption("file")) call.getObject("file") else null
        val fileUrl = if (file?.has("url") == true) file.getString("url") else null

        @SuppressLint("MissingPermission")
        if (!fileUrl.isNullOrBlank()) {
            val uri = fileUrl.let {
                if (it.startsWith("/")) {
                    Uri.parse("file://${it}")
                } else {
                    Uri.parse(it)
                }
            }
            //val mimeType = file["mimeType"] as String?
            Catapush.getInstance().sendFile(uri, body ?: "", channel, replyTo, object : Callback<Boolean> {
                override fun success(response: Boolean) {
                    call.resolve()
                }
                override fun failure(irrecoverableError: Throwable) {
                    call.reject(irrecoverableError.localizedMessage)
                }
            })
        } else if (!body.isNullOrBlank()) {
            Catapush.getInstance().sendMessage(body, channel, replyTo, object : Callback<Boolean> {
                override fun success(response: Boolean) {
                    call.resolve()
                }
                override fun failure(irrecoverableError: Throwable) {
                    call.reject(irrecoverableError.localizedMessage)
                }
            })
        } else {
            call.reject("Please provide a body or an attachment (or both). Arguments: options=${call.data}")
        }
    }

    @PluginMethod
    fun getAttachmentUrlForMessage(call: PluginCall) {
        val id = if (call.hasOption("id")) call.getString("id") else null
        if (id != null) {
            Catapush.getInstance().getMessageById(id, object : Callback<CatapushMessage> {
                override fun success(response: CatapushMessage) {
                    response.file().also { file ->
                        when {
                            file != null && response.isIn -> {
                                call.resolve(JSObject().apply {
                                    put("url", file.remoteUri())
                                    put("mimeType", file.type())
                                })
                            }
                            file != null && !response.isIn -> {
                                call.resolve(JSObject().apply {
                                    val localUri = if (file.localUri()?.startsWith("content://") == true) {
                                        val cacheDir = bridge.context.cacheDir
                                        val fileName = "attachment_$id.tmp"
                                        val tempFile = File(cacheDir, fileName)
                                        if (!tempFile.exists()) {
                                            try {
                                                val newTempFile = File.createTempFile(fileName, null, cacheDir)
                                                val uri = Uri.parse(file.localUri()!!)
                                                val inStream = bridge.context.contentResolver.openInputStream(uri)
                                                val outStream = FileOutputStream(newTempFile)
                                                val buffer = ByteArray(8 * 1024)
                                                var bytesRead: Int
                                                while (inStream!!.read(buffer)
                                                        .also { bytesRead = it } != -1
                                                ) {
                                                    outStream.write(buffer, 0, bytesRead)
                                                }
                                                inStream.close()
                                                outStream.close()
                                                newTempFile.absolutePath
                                            } catch (e: Exception) {
                                                // Fallback to remote file
                                                file.remoteUri()
                                            }
                                        } else {
                                            tempFile.absolutePath
                                        }
                                    } else {
                                        file.localUri()
                                    }
                                    put("url", localUri)
                                    put("mimeType", file.type())
                                })
                            }
                            else -> {
                                call.reject("getAttachmentUrlForMessage unexpected CatapushMessage state or format")
                            }
                        }
                    }
                }
                override fun failure(irrecoverableError: Throwable) {
                    call.reject(irrecoverableError.localizedMessage)
                }
            })
        } else {
            call.reject("Id cannot be empty. Arguments: options=${call.data}")
        }
    }

    @PluginMethod
    fun resumeNotifications(call: PluginCall) {
        Catapush.getInstance().resumeNotifications()
        call.resolve()
    }

    @PluginMethod
    fun pauseNotifications(call: PluginCall) {
        Catapush.getInstance().pauseNotifications()
        call.resolve()
    }

    @PluginMethod
    fun enableNotifications(call: PluginCall) {
        Catapush.getInstance().enableNotifications()
        call.resolve()
    }

    @PluginMethod
    fun disableNotifications(call: PluginCall) {
        Catapush.getInstance().disableNotifications()
        call.resolve()
    }

    @PluginMethod
    fun sendMessageReadNotificationWithId(call: PluginCall) {
        val id = call.getString("id")
        Catapush.getInstance().notifyMessageOpened(id)
        call.resolve()
    }

    private fun isChannelReady() : Boolean {
        return inited && instanceRef?.get() != null
    }

    private fun tryDispatchQueuedEvents() {
        if (isChannelReady() && tappedMessagesQueue.isNotEmpty()) {
            tappedMessagesQueue.forEach { dispatchNotificationTapped(it) }
            tappedMessagesQueue.clear()
        }
    }

    private fun List<CatapushMessage>.toJsonArray() : JSObject {
        val array = JSONArray()
        forEach { array.put(it.toJsonObject()) }
        return JSObject().also { it.put("messages", array) }
    }

    private fun CatapushMessage.toJsonObject() : JSObject {
        val obj = JSObject()
        obj.put("id", this.id())
        obj.put("body", this.body())
        obj.put("subject", this.subject())
        obj.put("previewText", this.previewText())
        obj.put("sender", this.sender())
        obj.put("channel", this.channel())
        obj.put("optionalData", this.data()?.run {
            val data = JSObject()
            forEach { (key, value) -> data.put(key, value) }
            return@run data
        })
        obj.put("replyToId", this.originalMessageId())
        obj.put("state", this.state())
        obj.put("receivedTime", this.receivedTime())
        obj.put("readTime", this.readTime())
        obj.put("sentTime", this.sentTime())
        obj.put("hasAttachment", this.file() != null)
        return obj
    }
}