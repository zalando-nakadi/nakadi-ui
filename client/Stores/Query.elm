module Stores.Query exposing (..)
import Json.Decode exposing (Decoder,string)
import Json.Decode.Pipeline exposing (decode, required)


type alias Query =
    {
     id : String,
     sql : String,
     created: String,
     modified: String,
     status: String
    }


queryDecoder : Decoder Query
queryDecoder =
    decode Query
        |> required "id" string
        |> required "sql" string
        |> required "created" string
        |> required "modified" string
        |> required "status" string
