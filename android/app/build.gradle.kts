import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Firma de release local: lee android/key.properties si existe. Este archivo y
// el .jks NO se versionan (ver .gitignore). En CI se usan variables de entorno.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}

android {
    namespace = "es.itsjhonalex.billetera"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Requerido por flutter_local_notifications (usa java.time en APIs viejas).
        isCoreLibraryDesugaringEnabled = true
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
            manifestPlaceholders["appName"] = "Billetera Dev"
        }
        create("prod") {
            dimension = "env"
            manifestPlaceholders["appName"] = "Billetera"
        }
    }

    // Resuelve el keystore: primero variables de entorno (CI), luego
    // key.properties (local). Si ninguno existe, se firma con clave debug.
    // En CI la variable se pasa como cadena vacía cuando no hay secrets.
    val envKeystore = System.getenv("BILLETERA_KEYSTORE")
    val keystorePath = if (!envKeystore.isNullOrBlank()) {
        envKeystore
    } else {
        keystoreProperties.getProperty("storeFile")
    }
    val hasReleaseKeystore = !keystorePath.isNullOrBlank()

    signingConfigs {
        create("release") {
            if (hasReleaseKeystore) {
                storeFile = file(keystorePath!!)
                storePassword = System.getenv("BILLETERA_STORE_PASSWORD")
                    ?: keystoreProperties.getProperty("storePassword")
                keyAlias = System.getenv("BILLETERA_KEY_ALIAS")
                    ?: keystoreProperties.getProperty("keyAlias")
                keyPassword = System.getenv("BILLETERA_KEY_PASSWORD")
                    ?: keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // Firma release si hay keystore configurado; si no, firma debug para
            // que `flutter build/run --release` funcione sin configuración extra.
            signingConfig = if (hasReleaseKeystore) {
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

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
