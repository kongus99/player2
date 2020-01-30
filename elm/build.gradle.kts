import com.moowork.gradle.node.yarn.YarnTask

plugins {
    java
    id("com.github.node-gradle.node") version "2.2.0"
}


node {
    // Version of node to use.
    version = "12.13.1"

    // Version of npm to use.
    npmVersion = "6.13.3"

    // Version of Yarn to use.
    yarnVersion = "1.19.1"

    // Base URL for fetching node distributions (change if you have a mirror).
    // Or set to null if you want to add the repository on your own.
    distBaseUrl = "https://nodejs.org/dist"

    // If true, it will download node using above parameters.
    // If false, it will try to use globally installed node.
    download = true

    // Set the work directory for unpacking node
    workDir = file("${project.buildDir}/nodejs")

    // Set the work directory for NPM
    npmWorkDir = file("${project.buildDir}/npm")

    // Set the work directory for Yarn
    yarnWorkDir = file("${project.buildDir}/yarn")

    // Set the work directory where node_modules should be located
    nodeModulesDir = file("${project.projectDir}")
}

tasks.register<YarnTask>("prepare_libs") {
    args = listOf("run", "prepare_libs")
    dependsOn("yarn_install")
}

tasks.register<YarnTask>("compile_elm") {
    args = listOf("run", "compile_elm")
    dependsOn("prepare_libs")
}
tasks.register<YarnTask>("uglify") {
    args = listOf("run", "uglify")
    dependsOn("compile_elm")
}

tasks.clean<Delete>{
    doFirst{
        delete("./node_modules/")
        delete("./elm-stuff/")
        delete("./lib/")
    }
}


