package com.player.controllers

import com.jooq.generated.tables.Video.VIDEO
import com.player.dto.Video.fromRecord
import com.player.dto.Video.fromVideoRecord
import common.Video
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
    @GetMapping("/")
    fun root(): List<String>? {
        return listOf("a", "b", "c")
    }

    @CrossOrigin
    @GetMapping("/video")
    fun videos(): List<Video>? {
        return dsl?.selectFrom(VIDEO)?.map { r -> fromVideoRecord(r) }
    }

    @CrossOrigin
    @GetMapping("/video", params = ["id"])
    fun video(@RequestParam("id") id: Long): Video? {
        return dsl?.selectFrom(VIDEO)?.where(VIDEO.ID.eq(id.toInt()))?.first()?.map { r -> fromRecord(r) }
    }

    @CrossOrigin
    @Transactional
    @PostMapping("/video", params = ["title", "url"])
    fun createVideo(model: ModelMap, @RequestParam("title") title: String, @RequestParam("url") url: String): Video? {
        return dsl?.insertInto(VIDEO, VIDEO.TITLE, VIDEO.VIDEOURL)
                ?.values(title, url)?.returning()
                ?.fetchOptional()?.map { r -> fromVideoRecord(r) }?.orElse(null)
    }

}
