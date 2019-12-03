package common

data class Video(val id: Long, val title: String, val speaker: String, val videoUrl: String) {
    constructor(id: Long, title: String, videoUrl: String)
            : this(id, title, "speaker", videoUrl)

}
