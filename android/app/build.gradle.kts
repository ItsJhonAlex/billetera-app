plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "es.itsjhonalex.billetera"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "es.itsjhonalex.billetera"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Flavors: `dev` y `prod` conviven en el mismo dispositivo (distinto applicationId).
    flavorDimensions += "env"
    productFlavors {
        create("dev") {
            dimension = "env"
            applicationIdSuffix = ".dev"
            resValue("string", "app_name", "Billetera Dev")
        }
        create("prod") {
            dimension = "env"
            resValue("string", "app_name", "Billetera")
        }
    }

    signingConfigs {
        create("release") {
            // Credenciales de firma desde variables de entorno (GitHub Actions)
            // o un keystore local. Si no existen, se usa la firma debug (abajo).
            val storeFilePath = System.getenv("BILLETERA_KEYSTORE")
            if (storeFilePath != null) {
                storeFile = file(storeFilePath)
                storePassword = System.getenv("BILLETERA_STORE_PASSWORD")
                keyAlias = System.getenv("BILLETERA_KEY_ALIAS")
                keyPassword = System.getenv("BILLETERA_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            // Firma release si hay keystore configurado; si no, firma debug para
            // que `flutter build/run --release` funcione sin configuración extra.
            signingConfig = if (System.getenv("BILLETERA_KEYSTORE") != null) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
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
