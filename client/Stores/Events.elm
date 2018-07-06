module Stores.Events exposing (..)

import Http
import Json.Decode as Json exposing (..)
import Json.Encode
import Config
import Helpers.Store exposing (Status, ErrorMessage)
import Constants exposing (emptyString)
import Stores.Cursor exposing (Cursor, cursorHeader, cursorDecoder)


{-|
    Consumer stream endpoint
     batch_limit=1 - is the best way how to get offset for every event,
     stream_keep_alive_limit=1 - finishes request if user asks more
                                    events than currently present in partition.
     batch_flush_timeout=1 - needed to prevent a 30 sec delay(default batch_flush_timeout)
                                    if an event received at the moment of the request.
-}
url : String -> Int -> String
url typeName maxCount =
    Config.urlNakadiApi
        ++ "event-types/"
        ++ typeName
        ++ "/events?stream_limit="
        ++ toString maxCount
        ++ "&batch_limit=1&stream_keep_alive_limit=1&batch_flush_timeout=1"


type alias Event =
    { cursor : Cursor
    , body : String
    }


type alias EventsResponse =
    List Event


type alias Model =
    { response : EventsResponse
    , status : Status
    , error : Maybe ErrorMessage
    , name : String
    , partition : String
    }


initialModel : Model
initialModel =
    { response = []
    , status = Helpers.Store.Unknown
    , error = Nothing
    , name = emptyString
    , partition = "0"
    }


fetchEvents : (Result Http.Error EventsResponse -> msg) -> String -> String -> String -> Int -> Cmd msg
fetchEvents message typeName partition offset maxCount =
    Http.request
        { method = "GET"
        , headers = [ Http.header "X-Nakadi-Cursors" (cursorHeader partition offset) ]
        , url = (url typeName maxCount)
        , body = Http.emptyBody
        , expect = batchToResult
        , timeout = Nothing
        , withCredentials = False
        }
        |> Http.send message


{-|
    Parse the Nakadi event stream.
    It splits the received text in to lines containing batch
    (works only with batch_limit=1 with i.e. only one event in a batch)
    and decode them line by line. This way we can get offsets for all individual events.
    It ignores lines that cannot be parsed (like empty "keep-alive")
-}
batchToResult : Http.Expect EventsResponse
batchToResult =
    Http.expectStringResponse
        (\response ->
            response.body
                |> String.split "\n"
                |> List.filterMap ((Json.decodeString eventDecoder) >> Result.toMaybe)
                |> List.reverse
                |> Ok
        )


{-|
    Parse and transform this json to Event structure.
    Example event:
    {"cursor":{"partition":"0","offset":"..."},  "events":[{...}]}

    This works only with batch_limit=1
-}
eventDecoder : Decoder Event
eventDecoder =
    map2 Event
        (field "cursor" cursorDecoder)
        (field "events" (at [ "0" ] jsonStringsDecoder))


{-|
    Convert an event body back to a string
-}
jsonStringsDecoder : Decoder String
jsonStringsDecoder =
    map (Json.Encode.encode 0) value
