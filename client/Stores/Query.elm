module Stores.Query exposing (Query, queryDecoder)

import Json.Decode exposing (Decoder, string)
import Json.Decode.Pipeline exposing (decode, required)


type alias Query =
    { id : String
    , sql : String
    }


queryDecoder : Decoder Query
queryDecoder =
    decode Query
        |> required "id" string
        |> required "sql" string
