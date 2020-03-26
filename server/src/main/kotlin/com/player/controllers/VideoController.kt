package com.player.controllers

import com.jooq.generated.tables.Video.VIDEO
import com.jooq.generated.tables.records.VideoRecord
import com.player.dto.Video.fromRecord
import com.player.dto.Video.fromVideoRecord
import common.Video
import common.Video.Parser.metaUrl
import common.Video.Parser.verifyId
import org.jooq.DSLContext
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.json.JacksonJsonParser
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.http.ResponseEntity.ok
import org.springframework.http.ResponseEntity.status
import org.springframework.transaction.annotation.Transactional
import org.springframework.web.bind.annotation.*
import org.springframework.web.client.RestTemplate


@RestController
class VideoController {
    data class User(val name: String)

    @Autowired
    private val restTemplate: RestTemplate? = null

    @Autowired
    private val dsl: DSLContext? = null

    @CrossOrigin
    @GetMapping("/api/user")
    fun user(): User? {
        return User("user")
    }

    @CrossOrigin
    @GetMapping("/api/video")
    fun videos(): List<Video>? {
        return dsl?.selectFrom(VIDEO)?.orderBy(VIDEO.ID.asc())?.map { fromVideoRecord(it) }
    }

    @CrossOrigin
    @GetMapping("/api/video/{id}")
    fun video(@PathVariable("id") id: Long): Video? {
        return dsl?.selectFrom(VIDEO)?.where(VIDEO.ID.eq(id.toInt()))?.first()?.map { fromRecord(it) }
    }

    @CrossOrigin
    @Transactional
    @PostMapping("/api/video")
    fun createVideo(@RequestBody video: Video): ResponseEntity<Int> {
        return change(video) {
            dsl?.insertInto(VIDEO, VIDEO.TITLE, VIDEO.VIDEO_URL_ID)
                    ?.values(video.title, it)?.returning()
                    ?.fetchOne()
        }
    }

    @CrossOrigin
    @Transactional
    @PutMapping("/api/video")
    fun editVideo(@RequestBody video: Video): ResponseEntity<Int> {
        return change(video) {
            dsl?.update(VIDEO)?.set(VIDEO.TITLE, video.title)?.set(VIDEO.VIDEO_URL_ID, it)?.where(VIDEO.ID.eq(video.id))
                    ?.returning()
                    ?.fetchOne()
        }
    }

    private fun change(video: Video, query: (String?) -> VideoRecord?): ResponseEntity<Int> {
        val result = query(verifyId(video.videoId))?.id ?: -1
        return if (result > 0)
            ok(result)
        else
            status(HttpStatus.BAD_REQUEST).body(result)

    }


    @CrossOrigin
    @Transactional
    @DeleteMapping("/api/video/{id}")
    fun deleteVideo(@PathVariable("id") id: Int): Int? {
        return dsl?.deleteFrom(VIDEO)?.where(VIDEO.ID.eq(id))?.returningResult(VIDEO.ID)?.fetchOne()?.component1()
    }

    // https://www.youtube.com/get_video_info?video_id=B4CRkpBGQzU
    @CrossOrigin
    @RequestMapping("/api/verify", params = ["videoId"])
    fun verify(@RequestParam("videoId") videoId: String): ResponseEntity<Video> {
        val verified = verifyId(videoId)
        return try {
            ok(dsl?.selectFrom(VIDEO)?.where(VIDEO.VIDEO_URL_ID.eq(verified))?.first()?.map { r -> fromRecord(r) }!!)
        } catch (e: NoSuchElementException) {
            val meta = restTemplate?.getForObject(metaUrl(verified), String::class.java)
            if (meta != null) {
                val mapped = JacksonJsonParser().parseMap(meta)
                val title = mapped["title"]?.toString()
                val author = mapped["author_name"]?.toString()
                ok(Video(null, title!!, verified))
            } else status(HttpStatus.BAD_REQUEST).body(null)
        }
    }
}
