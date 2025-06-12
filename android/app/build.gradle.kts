plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    id("dev.flutter.flutter-gradle-plugin") 
}

android {
    namespace = "com.example.hangout_planner"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "29.0.13599879"

    defaultConfig {
        applicationId = "com.example.hangout_planner"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug") 
        }
    }
}

flutter {
    source = "../.."
}
