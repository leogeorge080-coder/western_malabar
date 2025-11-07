plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android") // <- use the official Kotlin plugin id
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.westernmalabar.western_malabar"

    // Compile against the latest required by your plugins
    compileSdk = 36

    // If Flutter injected NDK/SDK via `flutter {}` we still prefer explicit SDK here.
    // (No need to set ndkVersion unless you actually use the NDK.)

    defaultConfig {
        applicationId = "com.westernmalabar.western_malabar"
        minSdk = flutter.minSdkVersion
        targetSdk = 36

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Make Java/Kotlin targets consistent (fixes “Inconsistent JVM-target” error)
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }

    // You can enable shrinking safely in release only
    buildTypes {
        debug {
            isMinifyEnabled = false
            isShrinkResources = false
        }
        release {
            // Toggle these on when you’re ready to ship smaller APKs
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            // Temporary signing so `flutter run --release` works
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // (Optional) if you hit duplicate file issues later:
    // packaging {
    //   resources.excludes.add("META-INF/*")
    // }
}

flutter {
    source = "../.."
}
