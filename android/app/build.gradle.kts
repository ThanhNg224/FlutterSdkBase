import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keyProperties = Properties()
val keyPropertiesFile = rootProject.file("key.properties")

android {
    val releaseSigningConfig = if (keyPropertiesFile.exists()) {
        keyPropertiesFile.inputStream().use(keyProperties::load)
        signingConfigs.create("release") {
            keyAlias = keyProperties["keyAlias"] as String
            keyPassword = keyProperties["keyPassword"] as String
            storeFile = rootProject.file(keyProperties["storeFile"] as String)
            storePassword = keyProperties["storePassword"] as String
        }
    } else {
        null
    }

    namespace = "com.thanhng224.fluttersdkbase"
    // flutter_secure_storage currently requires Android SDK 37; keep the base
    // compatible with older Flutter defaults while honoring that dependency.
    compileSdk = maxOf(flutter.compileSdkVersion, 37)
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }

    kotlin {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_21)
        }
    }

    defaultConfig {
        applicationId = "com.thanhng224.fluttersdkbase"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Modern 64-bit mobile targets only (arm64-v8a real devices, x86_64 desktop emulators)
        ndk {
            abiFilters.addAll(listOf("arm64-v8a", "x86_64"))
        }
    }

    flavorDimensions += "environment"
    productFlavors {
        create("dev") {
            dimension = "environment"
            applicationIdSuffix = ".dev"
            resValue("string", "app_name", "Flutter SDK Base Dev")
        }
        create("prod") {
            dimension = "environment"
            resValue("string", "app_name", "Flutter SDK Base")
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = releaseSigningConfig ?: signingConfigs.getByName("debug")
            if (releaseSigningConfig == null) {
                logger.warn("android/key.properties is missing; using the debug signing key for local release builds.")
            }
        }
    }
}

flutter {
    source = "../.."
}
