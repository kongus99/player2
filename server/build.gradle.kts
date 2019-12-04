import org.jetbrains.kotlin.gradle.tasks.KotlinCompile
import org.jooq.meta.jaxb.*
import org.jooq.meta.jaxb.Configuration
import org.jooq.meta.jaxb.Target

val jooqDir = "${buildDir}/generated-sources/java"

val commonSourcesDir = "${projectDir}/../client/src/app/common"

plugins {
    id("org.springframework.boot") version "2.2.1.RELEASE"
    id("io.spring.dependency-management") version "1.0.8.RELEASE"
    id("org.jetbrains.kotlin.jvm") version "1.3.61"
    id("org.jetbrains.kotlin.plugin.spring") version "1.3.61"
}

group = "com.player"
version = "0.0.1-SNAPSHOT"
java.sourceCompatibility = JavaVersion.VERSION_1_8

repositories {
    mavenCentral()
}

buildscript {
    repositories {
        mavenCentral()
    }
    dependencies {
        classpath(group = "org.jooq", name = "jooq", version = "3.11.11")
        classpath(group = "org.jooq", name = "jooq-meta", version = "3.11.11")
        classpath(group = "org.jooq", name = "jooq-codegen", version = "3.11.11")
        classpath(group = "org.postgresql", name = "postgresql", version = "42.2.5")
    }
}

tasks.register("buildMapping") {
    doLast {
        val withGenerator = Configuration()
                .withJdbc(Jdbc()
                        .withDriver("org.postgresql.Driver")
                        .withUrl("jdbc:postgresql://localhost:5432/player")
                        .withUser("postgres")
                        .withPassword("postgres"))
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
    sourceSets {
        main {
            java {
                srcDirs(commonSourcesDir)
            }
        }
    }
    runtimeOnly("org.postgresql:postgresql")
    testImplementation("org.springframework.boot:spring-boot-starter-test") {
        exclude(group = "org.junit.vintage", module = "junit-vintage-engine")
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
}
