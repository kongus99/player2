
package com.player

import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.runApplication
import org.springframework.transaction.annotation.EnableTransactionManagement

@SpringBootApplication
@EnableTransactionManagement
class PlayerApplication

fun main(args: Array<String>) {
	runApplication<PlayerApplication>(*args)
}
