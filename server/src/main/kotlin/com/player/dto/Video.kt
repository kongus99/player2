package com.player.dto

import com.jooq.generated.tables.Video.VIDEO
import com.jooq.generated.tables.records.VideoRecord
import org.jooq.Record

data class Video(val id: Long, val title: String, val speaker: String, val videoUrl: String) {
    constructor(id: Long, title: String, videoUrl: String)
            : this(id, title, "speaker", videoUrl)

    constructor(r: VideoRecord) : this(r.id.toLong(), r.title, r.videourl)

    constructor(r: Record) : this(r.get(VIDEO.ID).toLong(), r.get(VIDEO.TITLE), r.get(VIDEO.VIDEOURL))
}
