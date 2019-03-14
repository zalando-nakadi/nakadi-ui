module Helpers.JsonPrettyPrint exposing (prettyPrintJson)

import Json.Decode
import Json.Encode


prettyPrintJson : String -> String
prettyPrintJson json =
    case Json.Decode.decodeString Json.Decode.value json of
        Ok val ->
            Json.Encode.encode 4 val

        Err err ->
            json
