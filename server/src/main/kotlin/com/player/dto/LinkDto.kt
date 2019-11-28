package com.player.dto

import com.jooq.generated.tables.Link
import com.jooq.generated.tables.records.LinkRecord
import org.jooq.Record
import java.sql.Timestamp
import java.time.Instant

data class LinkDto(val id: Long, val timestamp: Instant, val target: String) {
    constructor(id: Long, timestamp: Timestamp, target: String)
            : this(id, timestamp.toInstant(), target)

    constructor(id: Long, target: String)
            : this(id, Instant.now(), target)

    constructor(r: LinkRecord) : this(r.id.toLong(), r.date, r.target)

    constructor(r: Record) : this(r.get(Link.LINK.ID).toLong(), r.get(Link.LINK.DATE), r.get(Link.LINK.TARGET))
}
