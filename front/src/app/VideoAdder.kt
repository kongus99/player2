package app

import common.Video
import kotlinx.coroutines.await
import kotlinx.html.FormMethod
import kotlinx.html.InputType
import kotlinx.html.js.onSubmitFunction
import org.w3c.fetch.RequestInit
import react.*
import react.dom.form
import react.dom.input
import kotlin.browser.window

class VideoAdder(props: RProps) : RComponent<RProps, RState>(props) {
    suspend fun postVideo(v: Video): Video =
            window.fetch("http://localhost:8080/video?title=${v.title}&url=${v.videoUrl}",
                    RequestInit("POST"))
                    .await()
                    .json()
                    .await()
                    .unsafeCast<Video>()

    override fun RBuilder.render() {
        form {
            attrs {
                name = "Add video"
                action = "http://localhost:8080/video"
                onSubmitFunction = {

                }
                method = FormMethod.post
            }
            +"Title"
            input {
                attrs {
                    type = InputType.text
                    name = "title"
                }
            }
            +"Url"
            input {
                attrs {
                    type = InputType.text
                    name = "url"
                }
            }
            input {
                attrs {
                    type = InputType.submit
                    value = "Submit"
                }
            }
        }
    }
}

fun RBuilder.videoAdder(handler: RProps.() -> Unit): ReactElement {
    return child(VideoAdder::class) {
        this.attrs(handler)
    }
}

