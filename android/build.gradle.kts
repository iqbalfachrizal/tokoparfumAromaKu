// --- Import diperlukan untuk akses ke CommonExtension ---
import com.android.build.api.dsl.CommonExtension

plugins {
    // Flutter otomatis mengatur plugin Android & Kotlin di level app.
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Atur ulang direktori build agar sesuai dengan struktur Flutter
val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    val newSubprojectBuildDir = newBuildDir.dir(project.name)
    project.layout.buildDirectory.set(newSubprojectBuildDir)
    project.evaluationDependsOn(":app")
}

// Task clean standar Flutter
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// --- Konfigurasi global Gradle modern untuk semua modul Android ---
gradle.projectsEvaluated {
    subprojects {
        project.extensions.findByType<CommonExtension<*, *, *, *, *, *>>()?.let { android ->

            // ✅ Paksa compileSdk ke 36 biar cocok sama plugin baru
            android.compileSdk = 36

            android.compileOptions {
                sourceCompatibility = JavaVersion.VERSION_11
                targetCompatibility = JavaVersion.VERSION_11
                isCoreLibraryDesugaringEnabled = true
            }

            // ✅ Pastikan Java 11 untuk semua modul
            project.plugins.withId("kotlin-android") {
                project.extensions.findByName("kotlinOptions")?.let { opts ->
                    if (opts is org.jetbrains.kotlin.gradle.dsl.KotlinJvmOptions) {
                        opts.jvmTarget = "11"
                    }
                }
            }

            // ✅ Tambahkan library desugaring ke semua modul Android
            project.dependencies.add(
                "coreLibraryDesugaring",
                "com.android.tools:desugar_jdk_libs:2.0.4"
            )
        }
    }
}
