package io.dolphin.move.flutter

import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import androidx.core.app.NotificationCompat
import io.dolphin.move.MoveSdk

class MainApplication : Application() {

    override fun onCreate() {
        super.onCreate()
        val sdk = MoveSdk.init(this)
        initNotifications(sdk)

        sdk.allowMockLocations(true)
    }

    private fun initNotifications(sdk: MoveSdk) {
        val recognitionChannel = "recognition"
        createChannel(this, recognitionChannel, "recognition", "description")
        sdk.recognitionNotification(
            NotificationCompat.Builder(this, recognitionChannel)
                .setSmallIcon(R.drawable.ic_notification)
                .setContentTitle("MOVE SDK")
                .setContentText("Trip detection")
                .setChannelId(recognitionChannel)
                .setSound(null)
                .setSilent(true)
                .setPriority(NotificationCompat.PRIORITY_MAX)
        )
        val tripChannel = "trip"
        createChannel(this, tripChannel, "trip", "description")
        sdk.tripNotification(
            NotificationCompat.Builder(this, tripChannel)
                .setSmallIcon(R.drawable.ic_notification)
                .setContentTitle("MOVE SDK")
                .setContentText("Driving")
                .setChannelId(tripChannel)
                .setSound(null)
                .setSilent(true)
                .setPriority(NotificationCompat.PRIORITY_MAX)
        )
    }

    private fun createChannel(
        context: Context,
        channelId: String,
        channelName: String,
        channelDescription: String
    ) {
        // Create the NotificationChannel
        val importance = NotificationManager.IMPORTANCE_DEFAULT
        val channel = NotificationChannel(channelId, channelName, importance)
        channel.description = channelDescription
        val notificationManager =
            context.getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.createNotificationChannel(channel)
    }
}
