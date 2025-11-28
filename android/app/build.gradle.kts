plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.arunika"

    // ✅ Gunakan SDK 36 untuk kompatibilitas plugin modern
    compileSdk = 36

    ndkVersion = flutter.ndkVersion

    compileOptions {
        // ✅ Setting Java 11 untuk menghilangkan peringatan obsolete
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        // Menghilangkan masalah desugaring untuk Geolocation/Notifikasi
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
        // Opsi ini akan menekan peringatan Java 8/obsolete dari log
        freeCompilerArgs += listOf("-Xlint:all,-warnings") 
    }

    defaultConfig {
        applicationId = "com.example.arunika"

        // ✅ Pastikan minSdk minimal 21 (syarat desugaring) atau lebih tinggi
        minSdk = maxOf(21, flutter.minSdkVersion.toInt())

        // ✅ Samakan targetSdk dengan compileSdk untuk stabilitas
        targetSdk = 36

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Pengaturan untuk Build Release (produksi)
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = signingConfigs.getByName("debug")
        }
        debug {
            // Tambahkan ini untuk Build Debug (optional, agar seragam)
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // ✅ Library desugaring agar fungsi modern Java bisa jalan di semua versi Android
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
