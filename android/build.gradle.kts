// BU KODU OLDUĞU GİBİ KOPYALA VE android/build.gradle.kts DOSYASINA YAPIŞTIR
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Firebase için gerekli olan satır burasıdır:
        classpath("com.google.gms:google-services:4.4.2")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}