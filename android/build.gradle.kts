allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    
    // Automatically create missing intermediate directories for AGP 9 / Gradle subprojects
    tasks.configureEach {
        doFirst {
            val aarDir = File(newSubprojectBuildDir.asFile, "intermediates/aar_metadata_check/debug/checkDebugAarMetadata")
            val aarRelDir = File(newSubprojectBuildDir.asFile, "intermediates/aar_metadata_check/release/checkReleaseAarMetadata")
            if (!aarDir.exists()) aarDir.mkdirs()
            if (!aarRelDir.exists()) aarRelDir.mkdirs()
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
