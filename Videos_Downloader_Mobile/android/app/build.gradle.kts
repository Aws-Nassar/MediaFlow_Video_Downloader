plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.chaquo.python") version "17.0.0"
}

android {
    namespace = "com.mediaflow.android"
    compileSdk = 36

    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.mediaflow.android"
        minSdk = 24
        targetSdk = 35
        versionCode = 1
        versionName = "1.0.0"

        ndk {
            abiFilters.clear()
            abiFilters.addAll(listOf("arm64-v8a", "x86_64"))
        }
    }

    buildTypes {
        debug {
        }
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

chaquopy {
    defaultConfig {
        version = "3.14"
        buildPython = listOf(System.getenv("CHAQUOPY_BUILD_PYTHON") ?: "C:/Users/coldw/AppData/Local/Python/bin/python.exe")
        pip {
            install("yt-dlp>=2024.12.0")
        }
    }
}

flutter {
    source = "../.."
}
