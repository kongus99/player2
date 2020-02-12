package com.player.controllers

import com.jooq.generated.tables.Video.VIDEO
import com.jooq.generated.tables.records.VideoRecord
import com.player.dto.Video.fromRecord
import com.player.dto.Video.fromVideoRecord
import common.Video
import org.jooq.DSLContext
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.http.ResponseEntity.ok
import org.springframework.http.ResponseEntity.status
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
    fun createVideo(@RequestBody video: Video): ResponseEntity<Int> {
        return change(video) { id: String? ->
            dsl?.insertInto(VIDEO, VIDEO.TITLE, VIDEO.VIDEO_URL_ID)
                    ?.values(video.title, id)?.returning()
                    ?.fetchOne()
        }
    }

    @CrossOrigin
    @Transactional
    @PutMapping("/api/video")
    fun editVideo(@RequestBody video: Video): ResponseEntity<Int> {
        return change(video) { id: String? ->
            dsl?.update(VIDEO)?.set(VIDEO.TITLE, video.title)?.set(VIDEO.VIDEO_URL_ID, id)?.where(VIDEO.ID.eq(video.id))
                    ?.returning()
                    ?.fetchOne()
        }
    }

    private fun change(video: Video, query: (String?) -> VideoRecord?): ResponseEntity<Int> {
        val id = Video.parseId(video.videoUrl)
        return if (id != null) {
            val result = query(id)?.id ?: -1
            if (result > 0)
                ok(result)
            else
                status(HttpStatus.BAD_REQUEST).body(result)
        } else
            status(HttpStatus.BAD_REQUEST).body(-1)
    }


    @CrossOrigin
    @Transactional
    @DeleteMapping("/api/video/{id}")
    fun deleteVideo(@PathVariable("id") id: Int): Int? {
        return dsl?.deleteFrom(VIDEO)?.where(VIDEO.ID.eq(id))?.returningResult(VIDEO.ID)?.fetchOne()?.component1()
    }

    @CrossOrigin
    @RequestMapping("/api/meta", params = ["url"])
    fun proxy2(@RequestParam("url") videoUrl: String): ResponseEntity<String> {
        // https://www.youtube.com/get_video_info?video_id=B4CRkpBGQzU
        val id = Video.parseId(videoUrl)
        return if (id != null) {
            val url = "https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=$id&format=json"
            ok(restTemplate?.getForObject(url, String::class.java)!!)
        } else status(HttpStatus.BAD_REQUEST).body("Incorrect uri")
    }
}
