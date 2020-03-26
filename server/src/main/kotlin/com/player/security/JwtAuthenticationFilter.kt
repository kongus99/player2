package com.player.security

import com.fasterxml.jackson.databind.ObjectMapper
import com.player.security.SecurityConstants.Companion.TOKEN_EXPIRATION
import com.player.security.SecurityConstants.Companion.TOKEN_HEADER
import com.player.security.SecurityConstants.Companion.TOKEN_PREFIX
import io.jsonwebtoken.Jwts
import io.jsonwebtoken.SignatureAlgorithm
import io.jsonwebtoken.security.Keys
import org.springframework.security.authentication.AuthenticationManager
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken
import org.springframework.security.core.Authentication
import org.springframework.security.core.GrantedAuthority
import org.springframework.security.core.userdetails.User
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter
import java.time.Instant
import java.util.*
import javax.servlet.FilterChain
import javax.servlet.http.Cookie
import javax.servlet.http.HttpServletRequest
import javax.servlet.http.HttpServletResponse


class JwtAuthenticationFilter(private val authentication: AuthenticationManager) : UsernamePasswordAuthenticationFilter() {
    companion object JwtAuthenticationFilter {
        const val SEQ = "seq"

        var validTokens = mutableMapOf<String, Int>().withDefault { 0 }

        fun isValidToken(username: String, token: Int): Boolean {
            return validTokens.getValue(username) == token
        }

        fun invalidate(username: String) {
            validTokens[username] = validTokens.getValue(username) + 1
        }

        fun getToken(username: String): Int {
            return validTokens.getValue(username)
        }
    }

    init {
        setFilterProcessesUrl(SecurityConstants.AUTH_LOGIN_URL)
    }

    override fun attemptAuthentication(request: HttpServletRequest, response: HttpServletResponse): Authentication {
        val tree = ObjectMapper().readTree(request.reader)
        val username = tree.get("username").asText()
        val password = tree.get("password").asText()
        return authentication.authenticate(UsernamePasswordAuthenticationToken(username, password))
    }

    override fun successfulAuthentication(request: HttpServletRequest, response: HttpServletResponse,
                                          filterChain: FilterChain, authentication: Authentication) {
        val user = authentication.principal as User
        val seq = getToken(user.username)
        val roles = user.authorities.map { obj: GrantedAuthority -> obj.authority }
        val signingKey = SecurityConstants.JWT_SECRET.toByteArray()
        val token = Jwts.builder()
                .signWith(Keys.hmacShaKeyFor(signingKey), SignatureAlgorithm.HS512)
                .setHeaderParam("typ", SecurityConstants.TOKEN_TYPE)
                .setIssuer(SecurityConstants.TOKEN_ISSUER)
                .setAudience(SecurityConstants.TOKEN_AUDIENCE)
                .setSubject(user.username)
                .setExpiration(Date(Instant.now().plus(TOKEN_EXPIRATION).toEpochMilli()))
                .claim("rol", roles)
                .claim(SEQ, seq)
                .compact()
        val cookie = Cookie(TOKEN_HEADER, TOKEN_PREFIX + token)
        cookie.path = "/"
        cookie.maxAge = TOKEN_EXPIRATION.seconds.toInt()
        response.addCookie(cookie)
    }

}

