package app

import kotlinx.html.FormMethod
import kotlinx.html.InputType
import kotlinx.html.js.onChangeFunction
import kotlinx.html.js.onSubmitFunction
import react.*
import react.dom.form
import react.dom.input

interface VideoAdderState : RState {
    var title: String?
    var videoUrl: String?
}

class VideoAdder(props: RProps) : RComponent<RProps, VideoAdderState>(props) {
    override fun VideoAdderState.init() {
        title = ""
        videoUrl = ""
    }


    override fun RBuilder.render() {
        form {
            attrs {
                name = "Add video"
                action = "http://localhost:8080/video"
                onSubmitFunction = {
                    it.preventDefault()
                    println(state.title)
                    println(state.videoUrl)
//                    VideoServices.post(state.video)
                }
                method = FormMethod.post
            }
            +"Title"
            input {
                attrs {
                    type = InputType.text
                    name = "title"
                    value = state.title.orEmpty()
                    onChangeFunction = {
                        val newValue = js("it.target.value") as String;
                        setState {
                            title = newValue
                        }
                    }
                }
            }
            +"Url"
            input {
                attrs {
                    type = InputType.text
                    name = "url"
                    value = state.videoUrl.orEmpty()
                    onChangeFunction = {
                        val newValue = js("it.target.value") as String;
                        setState {
                            videoUrl = newValue
                        }
                    }
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

