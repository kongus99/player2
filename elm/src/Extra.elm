module Extra exposing (..)

--List

import Html exposing (Attribute)
import Html.Attributes exposing (attribute)
import Http
import RemoteData exposing (WebData)


cyclicNext : a -> List a -> Maybe a
cyclicNext e lst =
    next e lst |> otherwise (List.head lst)


next : a -> List a -> Maybe a
next e lst =
    split e lst |> List.head


split : a -> List a -> List a
split e lst =
    case lst of
        x :: xs ->
            if x == e then
                xs

            else
                split e xs

        [] ->
            []



--Maybe


otherwise : Maybe a -> Maybe a -> Maybe a
otherwise other maybe =
    case maybe of
        Nothing ->
            other

        x ->
            x


isJust : Maybe a -> Bool
isJust maybe =
    case maybe of
        Nothing ->
            False

        Just _ ->
            True



-- model update


chain : (msg -> model -> ( model, Cmd msg )) -> model -> List msg -> ( model, Cmd msg )
chain update model messages =
    messages
        |> List.foldl
            (\message ->
                \( m, c ) ->
                    let
                        ( updatedModel, updatedCmd ) =
                            update message m
                    in
                    ( updatedModel, Cmd.batch [ c, updatedCmd ] )
            )
            ( model, Cmd.none )



-- view


bottomTooltip : String -> List (Attribute msg)
bottomTooltip msg =
    [ attribute "data-toggle" "tooltip"
    , attribute "data-placement" "bottom"
    , attribute "title" msg
    ]



-- Backend


resolveFetch : WebData a -> a -> a
resolveFetch response default =
    let
        resolveError : Http.Error -> String
        resolveError httpError =
            case httpError of
                Http.BadUrl message ->
                    message

                Http.Timeout ->
                    "Server is taking too long to respond. Please try again later."

                Http.NetworkError ->
                    "Unable to reach server."

                Http.BadStatus statusCode ->
                    "Request failed with status code: " ++ String.fromInt statusCode

                Http.BadBody message ->
                    message
    in
    case response of
        RemoteData.NotAsked ->
            default

        RemoteData.Loading ->
            default

        RemoteData.Success videos ->
            videos

        RemoteData.Failure httpError ->
            --let
            --    _ =
            --        Debug.log "Received error" (resolveError httpError)
            --in
            default
