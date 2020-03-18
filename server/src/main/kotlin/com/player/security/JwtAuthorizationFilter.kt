package com.player.security

import io.jsonwebtoken.*
import io.jsonwebtoken.security.SignatureException
import org.slf4j.LoggerFactory
import org.springframework.security.authentication.AuthenticationManager
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken
import org.springframework.security.core.authority.SimpleGrantedAuthority
import org.springframework.security.core.context.SecurityContextHolder
import org.springframework.security.web.authentication.www.BasicAuthenticationFilter
import java.io.IOException
import javax.servlet.FilterChain
import javax.servlet.ServletException
import javax.servlet.http.HttpServletRequest
import javax.servlet.http.HttpServletResponse


class JwtAuthorizationFilter(authenticationManager: AuthenticationManager?) : BasicAuthenticationFilter(authenticationManager) {

    @Throws(IOException::class, ServletException::class)
    override fun doFilterInternal(request: HttpServletRequest, response: HttpServletResponse,
                                  filterChain: FilterChain) {
        getAuthentication(request)?.run { SecurityContextHolder.getContext().authentication = this }
        filterChain.doFilter(request, response)
    }

    private fun getAuthentication(request: HttpServletRequest): UsernamePasswordAuthenticationToken? {
        request.cookies?.find { it.name == SecurityConstants.TOKEN_HEADER }?.let { cookie ->
            if (cookie.value.isNotEmpty() && cookie.value.startsWith(SecurityConstants.TOKEN_PREFIX)) {
                try {
                    val parsedToken = parse(cookie.value)
                    val username = parsedToken.body.subject
                    if (username != null && username.isNotEmpty()) {
                        val authorities = (parsedToken.body["rol"] as List<*>)
                                .map { SimpleGrantedAuthority(it as String?)}
                        return UsernamePasswordAuthenticationToken(username, null, authorities)
                    }
                } catch (exception: ExpiredJwtException) {
                    log.warn("Request to parse expired JWT : {} failed : {}", cookie, exception.message)
                } catch (exception: UnsupportedJwtException) {
                    log.warn("Request to parse unsupported JWT : {} failed : {}", cookie, exception.message)
                } catch (exception: MalformedJwtException) {
                    log.warn("Request to parse invalid JWT : {} failed : {}", cookie, exception.message)
                } catch (exception: SignatureException) {
                    log.warn("Request to parse JWT with invalid signature : {} failed : {}", cookie, exception.message)
                } catch (exception: IllegalArgumentException) {
                    log.warn("Request to parse empty or null JWT : {} failed : {}", cookie, exception.message)
                }
            }
        }
        return null
    }

    private fun parse(token: String): Jws<Claims> {
        return Jwts.parserBuilder()
                .setSigningKey(SecurityConstants.JWT_SECRET.toByteArray())
                .build()
                .parseClaimsJws(token.replace(SecurityConstants.TOKEN_PREFIX, ""))
    }

    companion object {
        private val log = LoggerFactory.getLogger(JwtAuthorizationFilter::class.java)
    }
}
