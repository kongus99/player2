package common

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

    class TracksValidator : ConstraintValidator<TracksValid, List<Track>> {
        override fun initialize(contactNumber: TracksValid) {}

        override fun isValid(tracks: List<Track>, cxt: ConstraintValidatorContext): Boolean {
            val inNaturalOrder =
                    { list: List<Track> ->
                        list.flatMap { listOf(it.start, it.end) }
                                .fold(0, { prev, d -> d?.let { if (prev <= d) d else Int.MAX_VALUE } ?: prev })
                                .let { it < Int.MAX_VALUE }
                    }
            val uniqueNames =
                    { list: List<Track> ->
                        list.size == list.map { it.title }.toSet().size
                    }
            return uniqueNames(tracks)
                    && inNaturalOrder(tracks)
        }

    }

    data class Track(val start: Int, val end: Int?,
                     @get:Pattern(regexp = "^\\w{3,50}.*$",
                             message = "Lower and upper case letters, numbers, - and _, min 3 and max 50 chars.")
                     val title: String)

    data class Album(val id: Int, val userId: Int, val videoId: Int, val tracks: List<Track>)

    private val trackPattern =
            compile("^(?:(?:([01]?\\d|2[0-3]):)?([0-5]?\\d):)?([0-5]?\\d)[_\\-\\s]+(\\S.*)\$")!!


    data class AlbumToCreate(val tracksString: String) {
        @get:TracksValid
        @Valid
        val tracks: List<Track> = parse(URLDecoder.decode(tracksString, UTF_8))

        private fun parse(s: String): List<Track> {
            val starts = s.lines().mapNotNull { line ->
                val matcher = trackPattern.matcher(line.trim())
                if (matcher.find()) {
                    val parsed = 1.rangeTo(matcher.groupCount()).mapNotNull { matcher.group(it) }
                    val seconds = parsed.mapNotNull { it.toIntOrNull() }
                            .reversed()
                            .zip(listOf(1, 60, 3600))
                            .map { it.first * it.second }
                            .fold(0, { a, b -> a + b })
                    if (seconds >= 0) Pair(parsed.last(), seconds)
                    else null
                } else null
            }
            return when {
                starts.isEmpty() -> emptyList()
                starts.size == 1 -> listOf(Track(starts[0].second, null, starts[0].first))
                else -> starts.zipWithNext()
                        .map { (p1, p2) -> Track(p1.second, p2.second, p1.first) }
                        .plus(Track(starts.last().second, null, starts.last().first))
            }
        }
    }


}


