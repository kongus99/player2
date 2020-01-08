package com.player.dto

import com.jooq.generated.tables.Video.VIDEO
import com.jooq.generated.tables.records.VideoRecord
import org.jooq.Record

object Video {

    fun fromVideoRecord(r: VideoRecord) =
            common.Video(r.id, r.title, r.videourl)

    fun fromRecord(r: Record) =
            common.Video(r.get(VIDEO.ID), r.get(VIDEO.TITLE), r.get(VIDEO.VIDEOURL))

}
