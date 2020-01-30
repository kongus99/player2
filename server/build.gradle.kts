import org.jetbrains.kotlin.gradle.tasks.KotlinCompile
import org.jooq.meta.jaxb.*
import org.jooq.meta.jaxb.Configuration
import org.jooq.meta.jaxb.Target
import org.springframework.boot.gradle.tasks.bundling.BootJar

val jooqDir = "${buildDir}/generated-sources/java"

val jooqUrl = System.getenv("JDBC_DATABASE_URL")
val jooqUser = System.getenv("JDBC_DATABASE_USERNAME")
val jooqPswd = System.getenv("JDBC_DATABASE_PASSWORD")


plugins {
    java
    id("org.springframework.boot") version "2.2.1.RELEASE"
    id("io.spring.dependency-management") version "1.0.8.RELEASE"
    kotlin("jvm") version "1.3.61"
    kotlin("plugin.spring") version "1.3.61"
}

java.sourceCompatibility = JavaVersion.VERSION_1_8

buildscript {
    dependencies {
        classpath(group = "org.jooq", name = "jooq", version = "3.11.11")
        classpath(group = "org.jooq", name = "jooq-meta", version = "3.11.11")
        classpath(group = "org.jooq", name = "jooq-codegen", version = "3.11.11")
        classpath(group = "org.postgresql", name = "postgresql", version = "42.2.5")
    }
}

dependencies {
    implementation("org.springframework.boot:spring-boot-starter-jooq")
    implementation("org.springframework.boot:spring-boot-starter-web")
    implementation("com.fasterxml.jackson.module:jackson-module-kotlin")
    implementation("org.jetbrains.kotlin:kotlin-reflect")
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8")
    implementation("org.flywaydb:flyway-core")
    sourceSets {
        main {
            java {
                srcDirs(jooqDir)
            }
        }
    }
    runtimeOnly("org.postgresql:postgresql")
    testImplementation("org.springframework.boot:spring-boot-starter-test") {
        exclude(group = "org.junit.vintage", module = "junit-vintage-engine")
    }
}

tasks.register("buildMapping") {
    doLast {
        println(jooqUrl)
        val withGenerator = Configuration()
                .withJdbc(Jdbc()
                        .withDriver("org.postgresql.Driver")
                        .withUrl(jooqUrl)
                        .withUser(jooqUser)
                        .withPassword(jooqPswd))
                .withGenerator(Generator()
                        .withDatabase(Database()
                                .withName("org.jooq.meta.postgres.PostgresDatabase")
                                .withIncludes(".*")
                                .withExcludes("")
                                .withInputSchema("public"))
                        .withTarget(Target()
                                .withPackageName("com.jooq.generated")
                                .withDirectory(jooqDir)))
        org.jooq.codegen.GenerationTool().run(withGenerator)
    }
}



tasks.withType<Test> {
    useJUnitPlatform()
}

tasks.withType<KotlinCompile> {
    kotlinOptions {
        freeCompilerArgs = listOf("-Xjsr305=strict")
        jvmTarget = "1.8"
    }
    dependsOn("buildMapping")
}
tasks.getByName<BootJar>("bootJar") {
    dependsOn(":elm:uglify")
    from("../elm/index.html") {
        into("static")
    }
    from("../elm/lib") {
        into("static/lib")
    }
}
