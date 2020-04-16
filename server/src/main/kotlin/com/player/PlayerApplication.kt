package com.player

import org.springframework.boot.SpringApplication
import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.http.client.SimpleClientHttpRequestFactory
import org.springframework.web.client.RestTemplate
import java.net.InetSocketAddress
import java.net.Proxy


@Configuration
@SpringBootApplication(scanBasePackages = ["common", "com.player.controllers", "com.player.security"])
class PlayerApplication {
    val host = System.getenv()["http.proxyHost"] ?: System.getenv()["https.proxyHost"]
    val port = System.getenv()["http.proxyPort"] ?: System.getenv()["https.proxyPort"]


    @get:Bean
    val restTemplate: RestTemplate
        get() {
            val template = RestTemplate()
            if (host != null) {
                val factory = SimpleClientHttpRequestFactory()
                factory.setProxy(Proxy(Proxy.Type.HTTP, InetSocketAddress(host!!, Integer.parseInt(port!!))))
                template.requestFactory = factory
            }
            return template
        }


    companion object {
        @JvmStatic
        fun main(args: Array<String>) {
            SpringApplication.run(PlayerApplication::class.java, *args)
        }
    }
}

