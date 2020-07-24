import com.moowork.gradle.node.yarn.YarnTask

plugins {
    java
    id("com.github.node-gradle.node") version "2.2.4"
}


node {
    // Version of node to use.
    version = "12.18.2"

    // Version of npm to use.
    npmVersion = "6.14.7"

    // Version of Yarn to use.
    yarnVersion = "1.22.4"

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

tasks.register<YarnTask>("parcel") {
    args = listOf("run", "package")
    dependsOn("yarn_install")
}

tasks.clean<Delete> {
    doFirst {
        delete("./node_modules/")
        delete("./lib/")
    }
}


