plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.srit.skolaro"
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
        applicationId = "com.srit.skolaro"
        minSdk = maxOf(flutter.minSdkVersion, 23)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            val signingPropertiesFile = rootProject.file("key.properties")
            if (signingPropertiesFile.exists()) {
                val signingProperties = java.util.Properties().apply {
                    signingPropertiesFile.inputStream().use(::load)
                }
                signingConfig = signingConfigs.create("release") {
                    keyAlias = signingProperties.getProperty("keyAlias")
                    keyPassword = signingProperties.getProperty("keyPassword")
                    storeFile = signingProperties.getProperty("storeFile")?.let(::file)
                    storePassword = signingProperties.getProperty("storePassword")
                }
            }
        }
    }
}

flutter {
    source = "../.."
}
