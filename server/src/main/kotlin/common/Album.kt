package common

import com.fasterxml.jackson.core.type.TypeReference
import com.fasterxml.jackson.databind.ObjectMapper
import com.fasterxml.jackson.module.kotlin.jacksonObjectMapper
import com.jooq.generated.tables.records.AlbumRecord
import java.net.URLDecoder
import java.nio.charset.StandardCharsets.UTF_8
import java.util.regex.Pattern.compile
import javax.validation.*
import javax.validation.constraints.Pattern
import kotlin.annotation.AnnotationRetention.RUNTIME
import kotlin.annotation.AnnotationTarget.*
import kotlin.reflect.KClass


object Album {

    @MustBeDocumented
    @Constraint(validatedBy = [TracksValidator::class])
    @Target(FUNCTION, FIELD, PROPERTY_GETTER)
    @Retention(RUNTIME)
    annotation class TracksValid(val message: String = "Tracks should be correct",
                                 val groups: Array<KClass<*>> = [],
                                 val payload: Array<KClass<out Payload>> = [])

    class TracksValidator : ConstraintValidator<TracksValid, List<OrderedTrack>> {
        override fun initialize(contactNumber: TracksValid) {}

        override fun isValid(tracks: List<OrderedTrack>, cxt: ConstraintValidatorContext): Boolean {
            val startsWithZero =
                    { list: List<OrderedTrack> ->
                        list.getOrNull(0)?.start ?: 0 == 0
                    }
            val isSorted =
                    { list: List<OrderedTrack> ->
                        list.zipWithNext()
                                .map { it.first.start < it.second.start }
                                .fold(true, { x, y -> x && y })
                    }
            val uniqueNames =
                    { list: List<OrderedTrack> ->
                        list.size == list.map { it.title.trim() }.toSet().size
                    }
            return tracks.isNotEmpty()
                    && uniqueNames(tracks)
                    && isSorted(tracks)
                    && startsWithZero(tracks)
        }

    }

    data class OrderedTrack(val start: Int,
                            @get:Pattern(regexp = "^\\w{3,50}.*$",
                                    message = "Lower and upper case letters, numbers, - and _, min 3 and max 50 chars.")
                            val title: String) {
        fun track(next: OrderedTrack?): Track =
                Track(start, next?.start, title)

    }

    private val trackPattern =
            compile("^(?:(?:([01]?\\d|2[0-3]):)?([0-5]?\\d):)?([0-5]?\\d)[_\\-\\s]+(\\S.*)\$")!!

    data class AlbumToCreate(val tracksString: String) {
        @get:TracksValid
        @Valid
        val tracks: List<OrderedTrack> = parse(URLDecoder.decode(tracksString, UTF_8.toString()))

        private fun parse(s: String): List<OrderedTrack> =
                s.lines().mapNotNull { line ->
                    val matcher = trackPattern.matcher(line.trim())
                    if (matcher.find()) {
                        val parsed = 1.rangeTo(matcher.groupCount()).mapNotNull { matcher.group(it) }
                        val seconds = parsed.take(parsed.size - 1).map { it.toInt() }
                                .reversed()
                                .zip(listOf(1, 60, 3600))
                                .map { it.first * it.second }
                                .fold(0, { a, b -> a + b })
                        if (seconds >= 0) OrderedTrack(seconds, parsed.last())
                        else null
                    } else null
                }.sortedBy { it.start }

        val saveTracks: String by lazy {
            val x = when {
                tracks.isEmpty() -> listOf()
                tracks.size == 1 -> listOf(tracks[0].track(null))
                else -> tracks.zipWithNext().map { it.first.track(it.second) }
            }
            ObjectMapper().writeValueAsString(x)
        }
    }

    data class Track(val start: Int, val end: Int?, val title: String)

    data class Album(val id: Int, val userId: Int, val videoId: Int, val tracks: List<Track>) {
        constructor(record: AlbumRecord) : this(record.id, record.userid, record.videoid,
                jacksonObjectMapper().readValue(record.tracks, object : TypeReference<List<Track>>() {}))
    }
}
