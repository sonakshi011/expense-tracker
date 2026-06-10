plugins {
    id("com.google.gms.google-services") version "4.3.15" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

//subprojects {
//    configurations.configureEach {
//        resolutionStrategy {
//            force("org.jetbrains.kotlin:kotlin-stdlib:1.9.25")
//            force("org.jetbrains.kotlin:kotlin-stdlib-jdk7:1.9.25")
//            force("org.jetbrains.kotlin:kotlin-stdlib-jdk8:1.9.25")
//        }
//    }
//}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
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
