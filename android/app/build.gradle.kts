plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}



android {
    namespace = "com.trakex.trakex"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"


    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_1_8.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.trakex.trakex"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Enable core library desugaring for flutter_local_notifications
        multiDexEnabled = true
    }



    buildFeatures {
        buildConfig = true
    }

    compileOptions {
        // Flag to enable support for the new language APIs
        isCoreLibraryDesugaringEnabled = true
        // Sets Java compatibility to Java 8
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    buildTypes {
        release {
            // Signing with the debug keys for now
            signingConfig = signingConfigs.getByName("debug")

            // Enable minification with R8
            isMinifyEnabled = true
            proguardFiles(getDefaultProguardFile("proguard-android.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Add the desugaring dependency
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:1.2.2")

    // Add Play Core dependency for split install support
    implementation("com.google.android.play:core:1.10.3")
}
