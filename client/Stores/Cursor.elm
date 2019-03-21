module Stores.Cursor exposing (Cursor, SubscriptionCursor, cursorDecoder, cursorEncoder, cursorHeader, subscriptionCursorDecoder, subscriptionCursorEncoder)

import Json.Decode as Json exposing (..)
import Json.Decode.Pipeline exposing (required)
import Json.Encode


type alias Cursor =
    { partition : String
    , offset : String
    }


type alias SubscriptionCursor =
    { event_type : String
    , partition : String
    , offset : String
    }


cursorDecoder : Decoder Cursor
cursorDecoder =
    succeed Cursor
        |> required "partition" string
        |> required "offset" string


cursorEncoder : Cursor -> Json.Encode.Value
cursorEncoder cursor =
    Json.Encode.object
        [ ( "partition", Json.Encode.string cursor.partition )
        , ( "offset", Json.Encode.string cursor.offset )
        ]


subscriptionCursorDecoder : Decoder SubscriptionCursor
subscriptionCursorDecoder =
    succeed SubscriptionCursor
        |> required "event_type" string
        |> required "partition" string
        |> required "offset" string


subscriptionCursorEncoder : SubscriptionCursor -> Json.Encode.Value
subscriptionCursorEncoder cursor =
    Json.Encode.object
        [ ( "event_type", Json.Encode.string cursor.event_type )
        , ( "partition", Json.Encode.string cursor.partition )
        , ( "offset", Json.Encode.string cursor.offset )
        ]


cursorHeader : String -> String -> String
cursorHeader partition offset =
    "[{\"partition\":\"" ++ partition ++ "\",\"offset\":\"" ++ offset ++ "\"}]"
