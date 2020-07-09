package com.player.controllers

import com.fasterxml.jackson.databind.ObjectMapper
import com.jooq.generated.Tables
import common.Album
import org.jooq.DSLContext
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.http.MediaType
import org.springframework.http.ResponseEntity
import org.springframework.security.core.annotation.AuthenticationPrincipal
import org.springframework.web.bind.annotation.*
import javax.validation.Valid
import com.jooq.generated.tables.Album as AlbumTable

@RestController
class AlbumController {

    @Autowired
    private val dsl: DSLContext? = null

    @CrossOrigin
    @GetMapping("/api/video/{videoId}/album")
    fun get(@PathVariable videoId: Int): ResponseEntity<String> {
        val albums = dsl?.selectFrom(AlbumTable.ALBUM)
                ?.where(AlbumTable.ALBUM.VIDEOID.eq(videoId))
                ?.firstOrNull()
                ?.let { ObjectMapper().writeValueAsString(Album.Album(it)) }
                ?: "null"
        return ResponseEntity
                .ok()
                .contentType(MediaType.APPLICATION_JSON)
                .body(albums)
    }

    @CrossOrigin
    @PostMapping("/api/video/{videoId}/album")
    fun post(@PathVariable videoId: Int, @AuthenticationPrincipal principal: String, @Valid @RequestBody album: Album.AlbumToCreate): Int? {
        val userId = dsl?.selectFrom(Tables.USER)
                ?.where(Tables.USER.NAME.eq(principal))
                ?.first()!!.id
        return if (album.tracks.isNotEmpty()) {
            dsl.insertInto(AlbumTable.ALBUM, AlbumTable.ALBUM.VIDEOID, AlbumTable.ALBUM.USERID, AlbumTable.ALBUM.TRACKS)
                    ?.values(videoId, userId, album.saveTracks)
                    ?.onConflict(AlbumTable.ALBUM.VIDEOID)
                    ?.doUpdate()
                    ?.set(AlbumTable.ALBUM.TRACKS, album.saveTracks)
                    ?.set(AlbumTable.ALBUM.USERID, userId)
                    ?.returning()
                    ?.fetchOne()!!.id
        } else null;
    }
}
