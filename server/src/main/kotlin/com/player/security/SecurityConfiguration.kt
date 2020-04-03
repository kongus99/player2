package com.player.security

import org.springframework.beans.factory.annotation.Autowired
import org.springframework.context.annotation.Bean
import org.springframework.core.env.Environment
import org.springframework.core.env.get
import org.springframework.http.HttpMethod.GET
import org.springframework.http.HttpMethod.POST
import org.springframework.security.config.annotation.method.configuration.EnableGlobalMethodSecurity
import org.springframework.security.config.annotation.web.builders.HttpSecurity
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity
import org.springframework.security.config.annotation.web.configuration.WebSecurityConfigurerAdapter
import org.springframework.security.config.http.SessionCreationPolicy
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder
import org.springframework.security.crypto.password.PasswordEncoder
import org.springframework.security.web.util.matcher.AntPathRequestMatcher
import org.springframework.web.cors.CorsConfiguration
import org.springframework.web.cors.CorsConfigurationSource
import org.springframework.web.cors.UrlBasedCorsConfigurationSource


@EnableWebSecurity
@EnableGlobalMethodSecurity(securedEnabled = true)
class SecurityConfiguration : WebSecurityConfigurerAdapter() {
    @Autowired
    private val env: Environment? = null


    @Throws(Exception::class)
    override fun configure(http: HttpSecurity) {
        val secureCookie = env?.get("cookie.secure")?.toBoolean() ?: false
        //fix for JWT
        http.csrf().disable()
        //paths
        http.authorizeRequests()
                .antMatchers(GET, "/api/user").authenticated()
                .antMatchers(POST, "/api/user").permitAll()
                .antMatchers(GET, "/api/**").permitAll()
                .anyRequest().authenticated()
        //filters
        http.addFilter(JwtAuthenticationFilter(authenticationManager(), secureCookie))
                .addFilter(JwtAuthorizationFilter(authenticationManager()))
        //session
        http.sessionManagement().sessionCreationPolicy(SessionCreationPolicy.STATELESS)
        //log out
        http.logout()
                .permitAll(false)
                .logoutRequestMatcher(AntPathRequestMatcher("/api/logout", "POST"))
                .logoutSuccessHandler { req, _, _ ->
                    val authentication = JwtAuthorizationFilter.getAuthentication(req)
                    authentication?.name?.let { JwtAuthenticationFilter.invalidate(it) }
                }
                .deleteCookies(SecurityConstants.TOKEN_HEADER)
                .clearAuthentication(true)
    }

    @Bean
    fun passwordEncoder(): PasswordEncoder {
        return BCryptPasswordEncoder()
    }

    @Bean
    fun corsConfigurationSource(): CorsConfigurationSource {
        val source = UrlBasedCorsConfigurationSource()
        source.registerCorsConfiguration("/**", CorsConfiguration().applyPermitDefaultValues())
        return source
    }
}
