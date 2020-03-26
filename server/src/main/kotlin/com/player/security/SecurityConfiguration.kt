package com.player.security

import org.springframework.context.annotation.Bean
import org.springframework.http.HttpMethod.GET
import org.springframework.security.config.annotation.authentication.builders.AuthenticationManagerBuilder
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
    @Throws(Exception::class)
    override fun configure(http: HttpSecurity) {
        http.csrf().disable()
                .authorizeRequests()
                .antMatchers(GET, "/api/user/**").authenticated()
                .antMatchers(GET, "/api/**").permitAll()
                .anyRequest().authenticated()
                .and()
                .addFilter(JwtAuthenticationFilter(authenticationManager()))
                .addFilter(JwtAuthorizationFilter(authenticationManager()))
                .sessionManagement()
                .sessionCreationPolicy(SessionCreationPolicy.STATELESS)
                .and()
                .logout()
                .permitAll(false)
                .logoutRequestMatcher(AntPathRequestMatcher("/api/logout", "POST"))
                .logoutSuccessHandler { req, _, _ ->
                    val authentication = JwtAuthorizationFilter.getAuthentication(req)
                    authentication?.name?.let { JwtAuthenticationFilter.invalidate(it) }
                }
                .deleteCookies(SecurityConstants.TOKEN_HEADER)
                .clearAuthentication(true)
    }

    @Throws(Exception::class)
    public override fun configure(auth: AuthenticationManagerBuilder) {
        auth.inMemoryAuthentication()
                .withUser("user")
                .password(passwordEncoder().encode("password"))
                .authorities("ROLE_USER")
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
