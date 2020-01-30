import com.moowork.gradle.node.yarn.YarnTask

plugins {
    java
    id("com.github.node-gradle.node") version "2.2.0"
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


