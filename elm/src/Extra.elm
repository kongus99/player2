module Extra exposing (..)

--List


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
