package com.player.controllers

import com.fasterxml.jackson.databind.ObjectMapper
import common.Album
import org.jooq.DSLContext
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.http.MediaType
import org.springframework.http.ResponseEntity
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
    fun get(@PathVariable videoId: Int): ResponseEntity<String> {
        return ResponseEntity
                .ok()
                .contentType(MediaType.APPLICATION_JSON)
                .body(albums[videoId]?.let { ObjectMapper().writeValueAsString(it) } ?: "null")
    }

    @CrossOrigin
    @PostMapping("/api/video/{videoId}/album")
    fun post(@PathVariable videoId: Int, @AuthenticationPrincipal principal: String, @Valid @RequestBody album: Album.AlbumToCreate): Int {
        val id = idGenerator.incrementAndGet()
        albums[videoId] = Album.Album(id, 1, videoId, album.tracks)
        return id
    }
}
