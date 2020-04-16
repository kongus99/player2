package com.player.security

import java.time.Duration

class SecurityConstants private constructor() {
    companion object {
        const val AUTH_LOGIN_URL = "/api/authenticate"

        // JWT token defaults
        const val TOKEN_HEADER = "Authorization"
        const val TOKEN_PREFIX = "Bearer-"
        const val TOKEN_TYPE = "JWT"
        const val TOKEN_ISSUER = "secure-api"
        const val TOKEN_AUDIENCE = "secure-app"
        const val ROLE = "rol"
        const val TYPE = "typ"
        const val SEQ = "seq"
        val TOKEN_EXPIRATION: Duration = Duration.ofDays(30)
    }

    init {
        throw IllegalStateException("Cannot create instance of static util class")
    }
}

