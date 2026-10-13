import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// --- Signing release ------------------------------------------------------
// Le credenziali NON sono versionate. Fonti, in ordine di priorità:
//   1. android/key.properties (ignorato da Git, vedi key.properties.example);
//   2. variabili d'ambiente INTONIA_UPLOAD_* (es. per una CI privata).
// Senza credenziali le build debug/profile funzionano normalmente, mentre una
// build release fallisce con un messaggio esplicito invece di essere firmata
// con la chiave debug. Solo per prove locali si può forzare la firma debug con
// INTONIA_ALLOW_DEBUG_SIGNED_RELEASE=true (artefatto NON pubblicabile).
val keystoreProperties =
    Properties().apply {
        val file = rootProject.file("key.properties")
        if (file.exists()) {
            file.inputStream().use { load(it) }
        }
    }

fun signingValue(propertyKey: String, envKey: String): String? =
    (keystoreProperties.getProperty(propertyKey) ?: System.getenv(envKey))?.takeIf { it.isNotBlank() }

val releaseStoreFile = signingValue("storeFile", "INTONIA_UPLOAD_STORE_FILE")
val releaseStorePassword = signingValue("storePassword", "INTONIA_UPLOAD_STORE_PASSWORD")
val releaseKeyAlias = signingValue("keyAlias", "INTONIA_UPLOAD_KEY_ALIAS")
val releaseKeyPassword = signingValue("keyPassword", "INTONIA_UPLOAD_KEY_PASSWORD")
val hasReleaseSigning =
    listOf(releaseStoreFile, releaseStorePassword, releaseKeyAlias, releaseKeyPassword).all { it != null }
val allowDebugSignedRelease = System.getenv("INTONIA_ALLOW_DEBUG_SIGNED_RELEASE") == "true"

android {
    // Stesso identificativo del Bundle ID iOS. Dopo il primo upload su Google Play
    // l'applicationId non può più essere cambiato.
    namespace = "io.github.davedegrado.intonia"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "io.github.davedegrado.intonia"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                // Percorso relativo a android/app/ oppure assoluto.
                storeFile = file(releaseStoreFile!!)
                storePassword = releaseStorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
            }
        }
    }

    buildTypes {
        release {
            signingConfig =
                when {
                    hasReleaseSigning -> signingConfigs.getByName("release")
                    allowDebugSignedRelease -> signingConfigs.getByName("debug")
                    else -> null
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

val releaseSigningAvailable = hasReleaseSigning || allowDebugSignedRelease
val checkReleaseSigning =
    tasks.register("checkReleaseSigning") {
        doLast {
            if (!releaseSigningAvailable) {
                throw GradleException(
                    "Signing release non configurato: crea android/key.properties " +
                        "(vedi android/key.properties.example) oppure imposta le variabili " +
                        "INTONIA_UPLOAD_STORE_FILE, INTONIA_UPLOAD_STORE_PASSWORD, " +
                        "INTONIA_UPLOAD_KEY_ALIAS e INTONIA_UPLOAD_KEY_PASSWORD. " +
                        "Vedi docs/BUILD_AND_RELEASE.md.",
                )
            }
        }
    }

tasks.matching { it.name == "preReleaseBuild" }.configureEach {
    dependsOn(checkReleaseSigning)
}
