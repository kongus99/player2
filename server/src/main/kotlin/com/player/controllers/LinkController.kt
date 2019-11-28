package com.player.controllers

import com.jooq.generated.Tables.LINK
import com.player.dto.LinkDto
import org.jooq.DSLContext
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.transaction.annotation.Transactional
import org.springframework.ui.ModelMap
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.RestController
import java.sql.Timestamp
import java.time.Instant
import java.util.stream.Collectors


@RestController
class LinkController {
    @Autowired
    private val dsl: DSLContext? = null

    @GetMapping("/link")
    fun links(): MutableList<LinkDto>? {
        return dsl?.selectFrom(LINK)?.stream()?.map { r -> LinkDto(r) }?.collect(Collectors.toList())
    }

    @GetMapping("/link", params = ["id"])
    fun link(@RequestParam("id") id: Long): LinkDto? {
        return dsl?.selectFrom(LINK)?.where(LINK.ID.eq(id.toInt()))?.first()?.map { r -> LinkDto(r) }
    }

    @Transactional
    @PostMapping("/link", params = ["target"])
    fun createLink(model: ModelMap, @RequestParam("target") target: String): LinkDto? {
        return dsl?.insertInto(LINK, LINK.TARGET, LINK.DATE)
                ?.values(target, Timestamp.from(Instant.now()))?.returning()
                ?.fetchOptional()?.map { r -> LinkDto(r) }?.orElse(null)
    }

}
