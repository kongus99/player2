package com.player.controllers

import com.jooq.generated.Tables.USER
import common.User.UserData
import common.User.UserToCreate
import common.User.fromRecord
import org.jooq.DSLContext
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder
import org.springframework.transaction.annotation.Transactional
import org.springframework.web.bind.annotation.*
import java.security.Principal
import java.sql.Timestamp
import java.time.Instant
import javax.validation.Valid


@RestController

class UserController {

    @Autowired
    private val dsl: DSLContext? = null

    @CrossOrigin
    @GetMapping("/api/user")
    fun get(principal: Principal): UserData? {
        return dsl?.selectFrom(USER)
                ?.where(USER.NAME.eq(principal.name))
                ?.firstOrNull()
                ?.let { fromRecord(it) }
    }

    @CrossOrigin
    @PostMapping("/api/user")
    @Transactional
    fun create(@Valid @RequestBody user: UserToCreate): ResponseEntity<UserData> {
        return try {
            ResponseEntity.ok(dsl?.insertInto(USER, USER.NAME, USER.EMAIL, USER.HASH, USER.LAST_LOGIN)
                    ?.values(user.username, user.email, BCryptPasswordEncoder().encode(user.password), Timestamp.from(Instant.now()))
                    ?.returning()
                    ?.fetchOne()
            !!.let { fromRecord(it) }
            )

        } catch (ex: Exception) {
            ResponseEntity.status(HttpStatus.FORBIDDEN).body(null)
        }
    }
}
