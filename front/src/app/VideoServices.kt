package app

import common.Video
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.await
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.withContext
import org.w3c.fetch.RequestInit
import kotlin.browser.window

object VideoServices {

    private suspend fun <T> executeSingle(toExecute: suspend () -> T): T =
            coroutineScope {
                withContext(Dispatchers.Default) {
                    toExecute()
                }
            }

    suspend fun post(v: Video): Video =
            executeSingle {
                window.fetch("http://localhost:8080/video?title=${v.title}&url=${v.videoUrl}",
                        RequestInit("POST"))
                        .await()
                        .json()
                        .await()
                        .unsafeCast<Video>()
            }

    suspend fun get(): List<Video> =
            executeSingle {
                window.fetch("http://localhost:8080/video")
                        .await()
                        .json()
                        .await()
                        .unsafeCast<Array<Video>>()
                        .toList()
            }


//suspend fun fetchVideos(): List<Video> = coroutineScope {
//    (1..2).map { id ->
//        async {
//            fetchVideo(id)
//        }
//    }.awaitAll()
//}

}
