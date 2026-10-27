package com.suryaprakash.honeyyyb.honeyyyb

import android.app.Notification
import android.content.Context
import android.content.Intent
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import java.util.concurrent.CopyOnWriteArrayList

class HoneyNotificationListenerService : NotificationListenerService() {

    companion object {
        val capturedNotifications = CopyOnWriteArrayList<Map<String, Any?>>()
        var notificationCallback: ((Map<String, Any?>) -> Unit)? = null

        // Financial & UPI package names in India & worldwide
        val FINANCIAL_PACKAGES = setOf(
            "com.google.android.apps.nbu.paisa.user", // Google Pay India
            "com.phonepe.app",                       // PhonePe
            "net.one97.paytm",                       // Paytm
            "com.dreamplug.androidapp",              // CRED
            "in.org.npci.upiapp",                    // BHIM
            "com.csam.icici.bank.imobile",           // ICICI iMobile
            "com.hdfc.mbanking",                     // HDFC Bank
            "com.axis.mobile",                       // Axis Mobile
            "com.msf.kopl",                          // Kotak 811
            "com.sbi.lotusintouch",                  // YONO SBI
            "com.truecaller"                         // Truecaller Pay
        )
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        if (sbn == null) return

        val pkgName = sbn.packageName ?: ""
        val extras = sbn.notification?.extras ?: return

        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: ""
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""
        val bigText = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString() ?: ""
        val subText = extras.getCharSequence(Notification.EXTRA_SUB_TEXT)?.toString() ?: ""

        val fullBody = if (bigText.isNotEmpty()) bigText else text
        if (title.isEmpty() && fullBody.isEmpty()) return

        // Filter financial payment notifications
        val lowerText = (title + " " + fullBody).lowercase()
        val isFinancialKeyword = lowerText.contains("paid") ||
                lowerText.contains("sent") ||
                lowerText.contains("debited") ||
                lowerText.contains("credited") ||
                lowerText.contains("received") ||
                lowerText.contains("spent") ||
                lowerText.contains("transferred") ||
                lowerText.contains("upi") ||
                lowerText.contains("₹") ||
                lowerText.contains("rs.") ||
                lowerText.contains("inr")

        val isTargetApp = FINANCIAL_PACKAGES.contains(pkgName)

        if (isTargetApp || isFinancialKeyword) {
            val notifData = mapOf(
                "packageName" to pkgName,
                "title" to title,
                "body" to fullBody,
                "subText" to subText,
                "timestamp" to sbn.postTime
            )

            capturedNotifications.add(notifData)
            notificationCallback?.invoke(notifData)

            // Also broadcast locally for Flutter EventChannel/MethodChannel
            val intent = Intent("com.suryaprakash.honeyyyb.NOTIFICATION_RECEIVED")
            intent.putExtra("packageName", pkgName)
            intent.putExtra("title", title)
            intent.putExtra("body", fullBody)
            intent.putExtra("timestamp", sbn.postTime)
            sendBroadcast(intent)
        }
    }
}
