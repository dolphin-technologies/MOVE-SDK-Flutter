package com.movesdk

import com.google.gson.Gson
import io.dolphin.move.MoveConfig
import io.dolphin.move.MoveDetectionService
import io.dolphin.move.MoveDevice
import io.dolphin.move.MoveScanResult
import io.dolphin.move.MoveServiceFailure
import io.dolphin.move.MoveServiceWarning
import io.dolphin.move.WalkingService

fun List<MoveServiceWarning>.toWarningObject(): List<Map<String, Any>> {
    val errors = mutableListOf<Map<String, Any>>()
    for (serviceWarning in this) {
        errors.add(
            mapOf(
                "service" to (serviceWarning.service?.name() ?: ""),
                "reasons" to serviceWarning.warnings.map { it.name }.toList(),
            )
        )
    }
    return errors
}

fun List<MoveServiceFailure>.toErrorObject(): List<Map<String, Any>> {
    val errors = mutableListOf<Map<String, Any>>()
    for (serviceError in this) {
        errors.add(
            mapOf(
                "service" to serviceError.service.name(),
                "reasons" to serviceError.reasons.map { it.name }.toList(),
            )
        )
    }
    return errors
}

inline fun <reified T> T.toJsonString(): String {
    return try {
        Gson().toJson(this)
    } catch (e: Exception) {
        ""
    }
}

fun List<MoveScanResult>.toScanResultObjectList(): List<Map<String, Any>> {
    return map { result ->
        mapOf(
            "isDiscovered" to result.isDiscovered,
            "device" to result.device.toJsonString(),
            "name" to result.device.name,
        )
    }
}

fun List<MoveDevice>.toMoveDeviceObjectList(): List<Map<String, String>> {
    return map { device ->
        mapOf(
            "name" to device.name,
            "data" to device.toJsonString(),
            "isConnected" to device.isConnected.toString(),
        )
    }
}

fun MoveConfig.toMoveConfigList(): List<String> {
    val config = mutableListOf<String>()
    for (service in this.moveDetectionServices) {
        when (service) {
            is MoveDetectionService.Driving -> {
                config.add(service.javaClass.simpleName.firstCharToLowerCase())
                service.drivingServices?.forEach {
                    config.add(it.name.firstCharToLowerCase())
                }
            }

            is MoveDetectionService.Walking -> {
                config.add(service.javaClass.simpleName.firstCharToLowerCase())
                service.walkingServices?.forEach {
                    if (it == WalkingService.Location) {
                        config.add("walkingLocation")
                    } else {
                        config.add(it.name.firstCharToLowerCase())
                    }
                }
            }

            else -> config.add(service.name().firstCharToLowerCase())
        }
    }
    return config
}

private fun String.firstCharToLowerCase(): String {
    return this.replaceFirstChar { it.lowercaseChar() }
}
