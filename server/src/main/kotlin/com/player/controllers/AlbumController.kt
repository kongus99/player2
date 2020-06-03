package com.player.controllers

import common.Album
import org.jooq.DSLContext
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.security.core.annotation.AuthenticationPrincipal
import org.springframework.web.bind.annotation.*
import java.util.concurrent.atomic.AtomicInteger
import javax.validation.Valid

@RestController
class AlbumController {

    private var albums: MutableMap<Int, Album.Album> = mutableMapOf()

    private var idGenerator = AtomicInteger(0)

    @Autowired
    private val dsl: DSLContext? = null

    @CrossOrigin
    @GetMapping("/api/video/{videoId}/album")
    fun get(@PathVariable videoId: Int): List<Album.Album> {
        return albums[videoId]?.let { listOf(it) } ?: listOf()
    }

    @CrossOrigin
    @PostMapping("/api/video/{videoId}/album")
    fun post(@PathVariable videoId: String, @AuthenticationPrincipal principal: String, @Valid @RequestBody album: Album.AlbumToCreate): Int {
        val id = idGenerator.incrementAndGet()
        albums[id] = Album.Album(id, 1, id, album.tracks)
        return id
    }
}
