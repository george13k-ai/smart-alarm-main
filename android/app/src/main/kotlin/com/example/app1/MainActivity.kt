package com.example.app1

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.PermissionController
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.HeartRateRecord
import androidx.health.connect.client.records.SleepSessionRecord
import androidx.health.connect.client.records.StepsRecord
import androidx.health.connect.client.request.ReadRecordsRequest
import androidx.health.connect.client.time.TimeRangeFilter
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.time.Instant
import java.time.ZoneId
import java.time.temporal.ChronoUnit

class MainActivity : FlutterFragmentActivity() {

    private val channelName = "com.example.app1/health"
    private lateinit var healthClient: HealthConnectClient
    private var pendingPermissionsResult: MethodChannel.Result? = null

    private val sleepPermissions = setOf(
        HealthPermission.getReadPermission(SleepSessionRecord::class),
    )

    private val activityPermissions = setOf(
        HealthPermission.getReadPermission(StepsRecord::class),
        HealthPermission.getReadPermission(HeartRateRecord::class),
    )

    private val allReadPermissions = sleepPermissions + activityPermissions

    private val requestPermissionsLauncher =
        registerForActivityResult(
            PermissionController.createRequestPermissionResultContract(),
        ) { granted: Set<String> ->
            val callback = pendingPermissionsResult
            pendingPermissionsResult = null
            callback?.success(allReadPermissions.all { it in granted })
        }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isAvailable" -> {
                        result.success(isHealthConnectAvailable())
                    }

                    "requestPermissions" -> {
                        if (!isHealthConnectAvailable()) {
                            maybeOpenHealthConnectListing()
                            result.success(false)
                            return@setMethodCallHandler
                        }

                        healthClient = HealthConnectClient.getOrCreate(this)
                        CoroutineScope(Dispatchers.IO).launch {
                            try {
                                val granted = healthClient.permissionController
                                    .getGrantedPermissions()
                                val allGranted = allReadPermissions.all { it in granted }

                                withContext(Dispatchers.Main) {
                                    if (allGranted) {
                                        result.success(true)
                                    } else if (pendingPermissionsResult == null) {
                                        pendingPermissionsResult = result
                                        requestPermissionsLauncher.launch(allReadPermissions)
                                    } else {
                                        result.error(
                                            "PERMISSION_FLOW_BUSY",
                                            "Permission request is already in progress",
                                            null,
                                        )
                                    }
                                }
                            } catch (e: Exception) {
                                withContext(Dispatchers.Main) {
                                    result.error("PERMISSION_ERROR", e.message, null)
                                }
                            }
                        }
                    }

                    "getSleepData" -> {
                        val days = call.argument<Int>("days") ?: 7
                        CoroutineScope(Dispatchers.IO).launch {
                            try {
                                if (!isHealthConnectAvailable()) {
                                    withContext(Dispatchers.Main) {
                                        result.error(
                                            "HC_UNAVAILABLE",
                                            "Health Connect is unavailable",
                                            null,
                                        )
                                    }
                                    return@launch
                                }

                                val client = HealthConnectClient.getOrCreate(this@MainActivity)
                                val granted = client.permissionController.getGrantedPermissions()
                                if (!sleepPermissions.all { it in granted }) {
                                    withContext(Dispatchers.Main) {
                                        result.error(
                                            "PERMISSION_REQUIRED",
                                            "Sleep permissions are not granted",
                                            null,
                                        )
                                    }
                                    return@launch
                                }

                                val end = Instant.now()
                                val start = end.minus(days.toLong(), ChronoUnit.DAYS)
                                val request = ReadRecordsRequest(
                                    SleepSessionRecord::class,
                                    TimeRangeFilter.between(start, end),
                                )
                                val response = client.readRecords(request)
                                val list = response.records.map { record ->
                                    val durationMinutes = ChronoUnit.MINUTES.between(
                                        record.startTime,
                                        record.endTime,
                                    ).toInt()
                                    mapOf(
                                        "dateMs" to floorToLocalDay(record.endTime.toEpochMilli()),
                                        "durationMinutes" to durationMinutes,
                                        "source" to (record.metadata.dataOrigin.packageName ?: "health_connect"),
                                    )
                                }

                                withContext(Dispatchers.Main) {
                                    result.success(list)
                                }
                            } catch (e: Exception) {
                                withContext(Dispatchers.Main) {
                                    result.error("SLEEP_ERROR", e.message, null)
                                }
                            }
                        }
                    }

                    "getActivityData" -> {
                        val days = call.argument<Int>("days") ?: 7
                        CoroutineScope(Dispatchers.IO).launch {
                            try {
                                if (!isHealthConnectAvailable()) {
                                    withContext(Dispatchers.Main) {
                                        result.error(
                                            "HC_UNAVAILABLE",
                                            "Health Connect is unavailable",
                                            null,
                                        )
                                    }
                                    return@launch
                                }

                                val client = HealthConnectClient.getOrCreate(this@MainActivity)
                                val granted = client.permissionController.getGrantedPermissions()
                                if (!activityPermissions.all { it in granted }) {
                                    withContext(Dispatchers.Main) {
                                        result.error(
                                            "PERMISSION_REQUIRED",
                                            "Activity permissions are not granted",
                                            null,
                                        )
                                    }
                                    return@launch
                                }

                                val end = Instant.now()
                                val start = end.minus(days.toLong(), ChronoUnit.DAYS)

                                val stepsRequest = ReadRecordsRequest(
                                    StepsRecord::class,
                                    TimeRangeFilter.between(start, end),
                                )
                                val stepsResponse = client.readRecords(stepsRequest)

                                val stepsByPackage = mutableMapOf<String, MutableMap<Long, Long>>()
                                for (record in stepsResponse.records) {
                                    val packageName = record.metadata.dataOrigin.packageName ?: "unknown"
                                    val dayMs = floorToLocalDay(record.endTime.toEpochMilli())
                                    val perDay = stepsByPackage.getOrPut(packageName) { mutableMapOf() }
                                    perDay[dayMs] = (perDay[dayMs] ?: 0L) + record.count
                                }

                                val selectedPackage = selectPreferredStepsPackage(stepsByPackage)
                                val stepsByDay = stepsByPackage[selectedPackage] ?: emptyMap()

                                val hrRequest = ReadRecordsRequest(
                                    HeartRateRecord::class,
                                    TimeRangeFilter.between(start, end),
                                )
                                val hrResponse = client.readRecords(hrRequest)
                                val hrByDay = mutableMapOf<Long, MutableList<Double>>()
                                for (record in hrResponse.records) {
                                    val dayMs = floorToLocalDay(record.startTime.toEpochMilli())
                                    val list = hrByDay.getOrPut(dayMs) { mutableListOf() }
                                    record.samples.forEach { sample ->
                                        list.add(sample.beatsPerMinute.toDouble())
                                    }
                                }

                                val allDays = (stepsByDay.keys + hrByDay.keys).toSet().sorted()
                                val activity = allDays.map { dayMs ->
                                    val hrList = hrByDay[dayMs]
                                    val avgHr = if (!hrList.isNullOrEmpty()) {
                                        hrList.average()
                                    } else {
                                        null
                                    }

                                    mapOf(
                                        "dateMs" to dayMs,
                                        "steps" to (stepsByDay[dayMs] ?: 0L).toInt(),
                                        "heartRate" to avgHr,
                                    )
                                }

                                withContext(Dispatchers.Main) {
                                    result.success(activity)
                                }
                            } catch (e: Exception) {
                                withContext(Dispatchers.Main) {
                                    result.error("ACTIVITY_ERROR", e.message, null)
                                }
                            }
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun isHealthConnectAvailable(): Boolean {
        return getHealthSdkStatus() == HealthConnectClient.SDK_AVAILABLE
    }

    private fun getHealthSdkStatus(): Int {
        return try {
            val method = HealthConnectClient::class.java.getMethod(
                "getSdkStatus",
                Context::class.java,
                String::class.java,
            )
            method.invoke(null, this, HEALTH_CONNECT_PACKAGE) as Int
        } catch (_: Throwable) {
            HealthConnectClient.getSdkStatus(this)
        }
    }

    private fun maybeOpenHealthConnectListing() {
        if (getHealthSdkStatus() != HealthConnectClient.SDK_UNAVAILABLE_PROVIDER_UPDATE_REQUIRED) {
            return
        }

        val marketUri = Uri.parse(
            "market://details?id=$HEALTH_CONNECT_PACKAGE&url=healthconnect%3A%2F%2Fonboarding",
        )
        val webUri = Uri.parse(
            "https://play.google.com/store/apps/details?id=$HEALTH_CONNECT_PACKAGE&url=healthconnect%3A%2F%2Fonboarding",
        )

        try {
            startActivity(
                Intent(Intent.ACTION_VIEW, marketUri).setPackage("com.android.vending"),
            )
        } catch (_: Exception) {
            startActivity(Intent(Intent.ACTION_VIEW, webUri))
        }
    }

    private fun selectPreferredStepsPackage(
        stepsByPackage: Map<String, Map<Long, Long>>,
    ): String {
        if (stepsByPackage.isEmpty()) return "unknown"

        // Prefer Google Fit if present because user usually verifies numbers there.
        val googleFit = "com.google.android.apps.fitness"
        if (stepsByPackage.containsKey(googleFit)) return googleFit

        // Otherwise choose the package with largest total over the selected period.
        return stepsByPackage.maxByOrNull { (_, perDay) -> perDay.values.sumOf { it } }?.key
            ?: "unknown"
    }

    private fun floorToLocalDay(epochMs: Long): Long {
        val zone = ZoneId.systemDefault()
        val localDate = Instant.ofEpochMilli(epochMs).atZone(zone).toLocalDate()
        return localDate.atStartOfDay(zone).toInstant().toEpochMilli()
    }

    companion object {
        private const val HEALTH_CONNECT_PACKAGE = "com.google.android.apps.healthdata"
    }
}
