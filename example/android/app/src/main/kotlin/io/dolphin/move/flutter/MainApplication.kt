package io.dolphin.move.flutter

import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import androidx.core.app.NotificationCompat
import io.dolphin.move.MoveSdk
import io.dolphin.move.MoveNotification

class MainApplication : Application() {

    override fun onCreate() {
        super.onCreate()
        val sdk = MoveSdk.init(this)
        initNotifications(sdk)

        sdk.allowMockLocations(true)
    }

    private fun initNotifications(sdk: MoveSdk) {
        sdk.setNotificationText(
            MoveNotification(
                recognitionTitle = "Recognition Title",
                recognitionText = "Recognition Text",
                drivingTitle = "Driving Title",
                drivingText = "Driving Text",
                walkingTitle = "Walking Title",
                walkingText = "Walking Text"
            )
        )
    }
}
