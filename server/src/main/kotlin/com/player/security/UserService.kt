package com.player.security

import com.jooq.generated.Tables.USER
import com.jooq.generated.tables.records.UserRecord
import org.jooq.DSLContext
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.security.core.GrantedAuthority
import org.springframework.security.core.authority.SimpleGrantedAuthority
import org.springframework.security.core.userdetails.UserDetails
import org.springframework.security.core.userdetails.UserDetailsService
import org.springframework.security.core.userdetails.UsernameNotFoundException
import org.springframework.stereotype.Service

@Service
class UserService : UserDetailsService {

    data class MyUserPrincipal(private val user: UserRecord) : UserDetails {
        override fun getUsername(): String = user.name
        override fun getPassword(): String = user.hash
        override fun getAuthorities(): Collection<GrantedAuthority> = listOf(SimpleGrantedAuthority("ROLE_USER"))

        override fun isEnabled(): Boolean = true
        override fun isCredentialsNonExpired(): Boolean = true
        override fun isAccountNonExpired(): Boolean = true
        override fun isAccountNonLocked(): Boolean = true
    }


    @Autowired
    private val dsl: DSLContext? = null

    override fun loadUserByUsername(username: String): UserDetails {
        return dsl?.selectFrom(USER)?.where(USER.NAME.eq(username))?.firstOrNull()?.let { MyUserPrincipal(it) }
                ?: throw UsernameNotFoundException(username)
    }

}
