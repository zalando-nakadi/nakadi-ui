module Helpers.Regex exposing (fromString)

import Regex exposing (Regex)


fromString : String -> Regex
fromString string =
    case Regex.fromString string of
        Just regex ->
            regex

        Nothing ->
            Regex.never |> Debug.log ("ERROR: Invalid regexp:" ++ string)
