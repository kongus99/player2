plugins {
    java
}

subprojects {

    group = "com.player"
    version = "0.0.1-SNAPSHOT"

    repositories {
        mavenCentral()
    }
}

tasks.register<Copy>("copy_artifact") {
    into("./build/libs")
    from("./server/build/libs")
    dependsOn(":server:bootJar")
}

tasks.register("stage") {
    dependsOn("clean", "copy_artifact")
}


tasks.getByPath("copy_artifact").mustRunAfter("clean")
