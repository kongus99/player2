package com.player.controllers

import common.Album
import org.jooq.DSLContext
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.security.core.annotation.AuthenticationPrincipal
import org.springframework.web.bind.annotation.*
import javax.validation.Valid

@RestController
class AlbumController {

    private var tracks: List<Album.Track> = listOf()

    @Autowired
    private val dsl: DSLContext? = null

    @CrossOrigin
    @GetMapping("/api/video/{videoId}/album")
    fun get(@PathVariable videoId: String): List<Album.Album> {
        return listOf(Album.Album(1, 1, 127, tracks))
    }

    @CrossOrigin
    @PostMapping("/api/video/{videoId}/album")
    fun post(@PathVariable videoId: String, @AuthenticationPrincipal principal: String, @Valid @RequestBody album: Album.AlbumToCreate): Int {
        this.tracks = album.tracks
        return 1
    }
}
