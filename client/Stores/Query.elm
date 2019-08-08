module Stores.Query exposing (Query, boolToString, queryDecoder)

import Json.Decode exposing (Decoder, bool, string, succeed)
import Json.Decode.Pipeline exposing (required)


type alias Query =
    { id : String
    , sql : String
    , envelope : Bool
    }


queryDecoder : Decoder Query
queryDecoder =
    succeed Query
        |> required "id" string
        |> required "sql" string
        |> required "envelope" bool


boolToString : Bool -> String
boolToString bool =
    if not bool then
        "false"

    else
        "true"
