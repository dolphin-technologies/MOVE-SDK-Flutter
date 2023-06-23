package com.movesdk

import io.dolphin.move.MoveServiceFailure
import io.dolphin.move.MoveServiceWarning

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