package common

data class Video(val id: Int?, val title: String, val videoId: String) {
    companion object Parser {
        const val idPattern = "^[\\w-]+$"
        private val videoIdRegex = Regex(idPattern)

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


