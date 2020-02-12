package common

import java.lang.IllegalArgumentException

data class Video(val id: Int, val title: String, val videoId: String) {
    companion object Parser {
        private val videoIdRegex = Regex("^[\\w-]+$")

        fun verifyId(videoId: String): String {
            if (videoIdRegex.matches(videoId))
                return videoId
            else throw IllegalArgumentException("Incorrect id $videoId")
        }

        fun metaUrl(videoId: String): String {
            return "https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=$videoId&format=json"
        }
    }
}


