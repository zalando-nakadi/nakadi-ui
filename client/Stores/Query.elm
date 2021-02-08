module Stores.Query exposing (Query, queryDecoder)

import Json.Decode exposing (Decoder, bool, string, succeed)
import Json.Decode.Pipeline exposing (required)


type alias Query =
    { id : String
    , sql : String
    , envelope : Bool
    , status : String
    }


queryDecoder : Decoder Query
queryDecoder =
    succeed Query
        |> required "id" string
        |> required "sql" string
        |> required "envelope" bool
        |> required "status" string
