module TextFilter exposing (..)

import Bootstrap.Form.Input as Input
import Bootstrap.Form.InputGroup as InputGroup
import Bootstrap.Utilities.Spacing as Spacing
import Html exposing (text)


type Filter
    = Include String
    | Exclude String
    | Ignore


type alias TextFilter =
    { original : String, parsed : List Filter }


parse : String -> TextFilter
parse text =
    let
        trimLength s =
            String.trim s |> String.length
    in
    if trimLength text > 2 then
        String.split "&" text
            |> List.map
                (\t ->
                    if String.startsWith "!" t then
                        if trimLength (String.dropLeft 1 t) > 0 then
                            Exclude <| String.trim <| String.dropLeft 1 t

                        else
                            Ignore

                    else if trimLength t > 0 then
                        Include <| String.trim t

                    else
                        Ignore
                )
            |> TextFilter text
        --|> Debug.log "filters"

    else
        TextFilter text []


evaluate : Filter -> String -> Bool
evaluate f text =
    case f of
        Include t ->
            String.contains (String.toLower t) (String.toLower text)

        Exclude t ->
            not <| String.contains (String.toLower t) (String.toLower text)

        Ignore ->
            True


apply : TextFilter -> String -> Bool
apply filter text =
    List.foldl (\f -> \acc -> acc && evaluate f text) True filter.parsed


empty =
    TextFilter "" []


input msg filter =
    InputGroup.config
        (InputGroup.text [ Input.placeholder "Enter filter - alphanumerical values separated by &, possibly negated by !", Input.value filter.original, Input.onInput msg ])
        |> InputGroup.predecessors
            [ InputGroup.span [] [ text "Filter" ] ]
        |> InputGroup.attrs [ Spacing.mt1 ]
        |> InputGroup.view
