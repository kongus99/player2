package common

import org.springframework.web.util.UriComponentsBuilder

data class Video(val id: Int, val title: String, val videoUrl: String) {
    companion object Parser {

        fun parseId(url: String): String? {
            return try {
                val videoIds = UriComponentsBuilder.fromUriString(url).build().queryParams["v"]?.toSet() ?: HashSet()
                if (videoIds.isNotEmpty())
                    videoIds.first()
                else null
            } catch (e: IllegalArgumentException) {
                null
            }
        }
    }
}


