package com.player

import org.springframework.boot.SpringApplication
import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.context.annotation.Bean
import org.springframework.http.client.SimpleClientHttpRequestFactory
import org.springframework.web.client.RestTemplate
import java.net.InetSocketAddress
import java.net.Proxy


@SpringBootApplication
class PlayerApplication {
    @get:Bean
    val restTemplate: RestTemplate
        get() {
            val template = RestTemplate()
            val factory = SimpleClientHttpRequestFactory()
            val address = InetSocketAddress("10.144.1.10", 8080)
//            val proxy = Proxy(Proxy.Type.HTTP, address)
//            factory.setProxy(proxy)
            template.requestFactory = factory
            return template
        }

    companion object {
        @JvmStatic
        fun main(args: Array<String>) {
            SpringApplication.run(PlayerApplication::class.java, *args)
        }
    }
}

