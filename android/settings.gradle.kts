import java.util.Properties
import java.io.File

pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        val propertiesFile = file("local.properties")
        if (propertiesFile.exists()) {
            propertiesFile.inputStream().use { properties.load(it) }
        }
        val flutterSdk = properties.getProperty("flutter.sdk")
        require(flutterSdk != null) { "flutter.sdk not set in local.properties" }
        flutterSdk
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    // Version Android Gradle Plugin Jdida
    id("com.android.application") version "8.7.0" apply false
    // Version Kotlin Jdida (2.1.0) - Darouriya bash tkhdm m3a Firebase jdid
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
    id("com.google.gms.google-services") version "4.4.0" apply false
}

include(":app")