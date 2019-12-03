plugins {
    id("org.jetbrains.kotlin.jvm")
}

val commonSrc = "${projectDir}/src/common"

repositories {
    mavenCentral()
}
dependencies {
    implementation(kotlin("stdlib"))
}

tasks {
    compileKotlin {
        kotlinOptions.jvmTarget = "1.8"
        sourceSets {
            main {
                java {
                    srcDir(commonSrc)
                }
            }
        }
        println(commonSrc)

    }
    compileTestKotlin {
        kotlinOptions.jvmTarget = "1.8"
    }
}
