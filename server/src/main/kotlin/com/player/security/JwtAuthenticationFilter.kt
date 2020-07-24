package com.player.security

import com.fasterxml.jackson.databind.ObjectMapper
import com.player.security.SecurityConstants.Companion.ROLE
import com.player.security.SecurityConstants.Companion.SEQ
import com.player.security.SecurityConstants.Companion.TOKEN_AUDIENCE
import com.player.security.SecurityConstants.Companion.TOKEN_EXPIRATION
import com.player.security.SecurityConstants.Companion.TOKEN_HEADER
import com.player.security.SecurityConstants.Companion.TOKEN_ISSUER
import com.player.security.SecurityConstants.Companion.TOKEN_PREFIX
import com.player.security.SecurityConstants.Companion.TOKEN_TYPE
import com.player.security.SecurityConstants.Companion.TYPE
import com.player.security.UserService.MyUserPrincipal
import io.jsonwebtoken.Jwts
import io.jsonwebtoken.SignatureAlgorithm
import io.jsonwebtoken.security.Keys
import org.springframework.security.authentication.AuthenticationManager
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken
import org.springframework.security.core.Authentication
import org.springframework.security.core.GrantedAuthority
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter
import org.springframework.security.web.authentication.logout.CookieClearingLogoutHandler
import java.time.Instant
import java.util.*
import javax.servlet.FilterChain
import javax.servlet.http.Cookie
import javax.servlet.http.HttpServletRequest
import javax.servlet.http.HttpServletResponse


class JwtAuthenticationFilter(private val authentication: AuthenticationManager, private val secureCookie: Boolean, private val jwtSecret: String) : UsernamePasswordAuthenticationFilter() {


    companion object JwtAuthenticationFilter {


        private var validTokens = mutableMapOf<String, Int>().withDefault { 0 }

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
        if (request.cookies?.find { it.name == TOKEN_HEADER } != null) {
            CookieClearingLogoutHandler(TOKEN_HEADER).logout(request, response, authentication)
        } else {
            val user = authentication.principal as MyUserPrincipal
            val seq = getToken(user.username)
            val roles = user.authorities.map { obj: GrantedAuthority -> obj.authority }
            val signingKey = jwtSecret.toByteArray()
            val token = Jwts.builder()
                    .signWith(Keys.hmacShaKeyFor(signingKey), SignatureAlgorithm.HS512)
                    .setHeaderParam(TYPE, TOKEN_TYPE)
                    .setIssuer(TOKEN_ISSUER)
                    .setAudience(TOKEN_AUDIENCE)
                    .setSubject(user.username)
                    .setExpiration(Date(Instant.now().plus(TOKEN_EXPIRATION).toEpochMilli()))
                    .claim(ROLE, roles)
                    .claim(SEQ, seq)
                    .compact()
            val cookie = Cookie(TOKEN_HEADER, TOKEN_PREFIX + token)
            cookie.path = "/"
            cookie.maxAge = TOKEN_EXPIRATION.seconds.toInt()
            cookie.isHttpOnly = true
            cookie.secure = secureCookie
            response.addCookie(cookie)
        }
    }

}

