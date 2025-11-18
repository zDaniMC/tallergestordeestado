// build.gradle.kts (nivel de proyecto)

plugins {
    id("com.android.application") apply false
    id("org.jetbrains.kotlin.android") apply false

    // ✅ Este SÍ necesita versión explícita:
    id("com.google.gms.google-services") version "4.4.2" apply false

    // ✅ Flutter plugin
    id("dev.flutter.flutter-gradle-plugin") apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// ✅ Ajuste opcional de rutas de build
val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    val newSubprojectBuildDir = newBuildDir.dir(project.name)
    layout.buildDirectory.set(newSubprojectBuildDir)
    evaluationDependsOn(":app")
}

// ✅ Limpieza de builds
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

