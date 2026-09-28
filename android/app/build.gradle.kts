plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.silatar_v2"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.example.silatar_v2"
        // flutter_patcher requires minSdk 24
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Enable multidex for large apps
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            signingConfig = signingConfigs.getByName("debug")

            // Enable code shrinking with R8
            isMinifyEnabled = true

            // Enable obfuscation
            isShrinkResources = true

            // Remove debug symbols to reduce size
            ndk {
                debugSymbolLevel = DebugSymbolLevel.NONE
            }
        }

        // Debug build type for smaller test builds
        debug {
            isMinifyEnabled = false
            isDebuggable = true
        }
    }

    // Split APKs by ABI for smaller individual APKs
    splits {
        abi {
            isEnable = true
            reset()
            // Build for specific ABIs only
            include("armeabi-v7a", "arm64-v8a")
            isUniversalApk = true
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
