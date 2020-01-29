package com.player.controllers

import com.jooq.generated.tables.Video.VIDEO
import com.player.dto.Video.fromRecord
import com.player.dto.Video.fromVideoRecord
import common.Video
import org.jooq.DSLContext
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.transaction.annotation.Transactional
import org.springframework.web.bind.annotation.*
import org.springframework.web.client.RestTemplate


@RestController
class VideoController {
    @Autowired
    private val restTemplate: RestTemplate? = null
    @Autowired
    private val dsl: DSLContext? = null

    @CrossOrigin
    @GetMapping("/api/video")
    fun videos(): List<Video>? {
        return dsl?.selectFrom(VIDEO)?.orderBy(VIDEO.ID.asc())?.map { r -> fromVideoRecord(r) }
    }

    @CrossOrigin
    @GetMapping("/api/video/{id}")
    fun video(@PathVariable("id") id: Long): Video? {
        return dsl?.selectFrom(VIDEO)?.where(VIDEO.ID.eq(id.toInt()))?.first()?.map { r -> fromRecord(r) }
    }

    @CrossOrigin
    @Transactional
    @PostMapping("/api/video")
    fun createVideo(@RequestBody video: Video): Int? {
        return dsl?.insertInto(VIDEO, VIDEO.TITLE, VIDEO.VIDEOURL)
                ?.values(video.title, video.videoUrl)?.returning()
                ?.fetchOptional()?.map { r -> r.id }?.orElse(null)
    }

    @CrossOrigin
    @Transactional
    @PutMapping("/api/video")
    fun editVideo(@RequestBody video: Video): Int? {
        return dsl?.update(VIDEO)
                ?.set(VIDEO.TITLE, video.title)?.set(VIDEO.VIDEOURL, video.videoUrl)
                ?.where(VIDEO.ID.eq(video.id))
                ?.returning()
                ?.fetchOptional()?.map { r -> r.id }?.orElse(null)
    }

    @CrossOrigin
    @Transactional
    @DeleteMapping("/api/video/{id}")
    fun deleteVideo(@PathVariable("id") id: Int): Int? {
        return dsl?.deleteFrom(VIDEO)?.where(VIDEO.ID.eq(id))?.returningResult(VIDEO.ID)?.fetchOne()?.component1()
    }

    @CrossOrigin
    @RequestMapping("/api/meta", params = ["url"])
    fun proxy2(@RequestParam("url") videoUrl: String): String {
        // https://www.youtube.com/get_video_info?video_id=B4CRkpBGQzU
        val url = "https://www.youtube.com/oembed?url=$videoUrl&format=json"
        return restTemplate?.getForObject(url, String::class.java)!!
    }
}
