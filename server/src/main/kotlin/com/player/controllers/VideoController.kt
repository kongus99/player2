package com.player.controllers

import com.jooq.generated.tables.Video.VIDEO
import com.player.dto.Video
import org.jooq.DSLContext
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.transaction.annotation.Transactional
import org.springframework.ui.ModelMap
import org.springframework.web.bind.annotation.*
import java.util.stream.Collectors


@RestController
class VideoController {
    @Autowired
    private val dsl: DSLContext? = null

    @CrossOrigin
    @GetMapping("/video")
    fun videos(): MutableList<Video>? {
        return dsl?.selectFrom(VIDEO)?.stream()?.map { r -> Video(r) }?.collect(Collectors.toList())
    }

    @CrossOrigin
    @GetMapping("/video", params = ["id"])
    fun video(@RequestParam("id") id: Long): Video? {
        return dsl?.selectFrom(VIDEO)?.where(VIDEO.ID.eq(id.toInt()))?.first()?.map { r -> Video(r) }
    }

    @CrossOrigin
    @Transactional
    @PostMapping("/video", params = ["title", "url"])
    fun createVideo(model: ModelMap, @RequestParam("title") title: String, @RequestParam("url") url: String): Video? {
        return dsl?.insertInto(VIDEO, VIDEO.TITLE, VIDEO.VIDEOURL)
                ?.values(title, url)?.returning()
                ?.fetchOptional()?.map { r -> Video(r) }?.orElse(null)
    }

}
