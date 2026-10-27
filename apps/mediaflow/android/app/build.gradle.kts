plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.mediaflow.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.mediaflow.app"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // youtubedl-android ships the Python/yt-dlp runtime and FFmpeg as
        // native libraries. Flutter has no x86 engine, so x86 is omitted.
        ndk {
            abiFilters.addAll(listOf("x86_64", "armeabi-v7a", "arm64-v8a"))
        }
    }

    packaging {
        jniLibs {
            // The engine's .so files include zipped Python/FFmpeg payloads and
            // must be extracted before the runtime initializes.
            useLegacyPackaging = true
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
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

dependencies {
    // Pinned Android engine. The library is GPL-3.0; confirm distribution
    // licensing before publishing a release build.
    implementation("io.github.junkfood02.youtubedl-android:library:0.18.1")
    implementation("io.github.junkfood02.youtubedl-android:ffmpeg:0.18.1")
}
