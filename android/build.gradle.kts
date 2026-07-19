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
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Align every subproject (including plugin modules) to JVM 17. The :app module
// already targets 17, but plugin subprojects default lower, which breaks on a
// clean checkout in two ways:
//   1. home_widget: Kotlin cannot inline JVM-11 bytecode into a 1.8 target
//      (":home_widget:compileDebugKotlin" fails).
//   2. flutter_foreground_task: hard-codes Java 11 in its own build.gradle, so
//      once Kotlin is bumped to 17 the Java and Kotlin targets disagree
//      ("Inconsistent JVM-target compatibility").
// This must run in gradle.projectsEvaluated so our task overrides are registered
// AFTER AGP/the plugin has configured its own compile tasks — otherwise the
// plugin's lower target is applied last and wins. (afterEvaluate can't be used
// because the evaluationDependsOn block above evaluates subprojects early.)
gradle.projectsEvaluated {
    subprojects {
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            compilerOptions {
                jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
            }
        }
        tasks.withType<JavaCompile>().configureEach {
            sourceCompatibility = JavaVersion.VERSION_17.toString()
            targetCompatibility = JavaVersion.VERSION_17.toString()
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
