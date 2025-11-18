plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android") // forma recomendada en Kotlin DSL
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // ✅ NECESARIO para Firebase
}

android {
    namespace = "com.example.jojeproyecto"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.jojeproyecto"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

// ✅ Dependencias para Firebase (Firestore, Auth, etc.)
dependencies {
    implementation(platform("com.google.firebase:firebase-bom:33.3.0")) // versión recomendada 2025
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-firestore")
}
