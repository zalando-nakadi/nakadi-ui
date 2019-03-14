module Stores.ShiftedCursor exposing (Model, Msg, ShiftedCursor, collectionDecoder, config, fetchShiftedCursors, initialModel, shiftedCursorEncoder, update)

import Config
import Constants exposing (emptyString)
import Dict
import Helpers.Store
import Http
import Json.Decode exposing (Decoder, float, int, list, nullable, string)
import Json.Encode
import Stores.Cursor exposing (Cursor)


type alias ShiftedCursor =
    { partition : String
    , offset : String
    , shift : Int
    }


shiftedCursorEncoder : ShiftedCursor -> Json.Encode.Value
shiftedCursorEncoder cursor =
    Json.Encode.object
        [ ( "partition", Json.Encode.string cursor.partition )
        , ( "offset", Json.Encode.string cursor.offset )
        , ( "shift", Json.Encode.int cursor.shift )
        ]


type alias Model =
    Helpers.Store.Model Cursor


type alias Msg =
    Helpers.Store.Msg Cursor


config : Dict.Dict String String -> Helpers.Store.Config Cursor
config params =
    let
        eventType =
            Dict.get Constants.eventTypeName params |> Maybe.withDefault emptyString
    in
    { getKey = \index item -> toString index
    , url = Config.urlNakadiApi ++ "event-types/" ++ eventType ++ "/shifted-cursors"
    , decoder = collectionDecoder
    , headers = []
    }


initialModel : Model
initialModel =
    Helpers.Store.initialModel


update : Msg -> Model -> ( Model, Cmd Msg )
update =
    Helpers.Store.update config


fetchShiftedCursors : (Result Http.Error (List Cursor) -> msg) -> String -> ShiftedCursor -> Cmd msg
fetchShiftedCursors tagger name shiftedCursor =
    let
        conf =
            config (Dict.singleton Constants.eventTypeName name)

        body =
            Json.Encode.list [ shiftedCursorEncoder shiftedCursor ]
    in
    Http.request
        { method = "POST"
        , headers = []
        , url = conf.url
        , body = Http.jsonBody body
        , expect = Http.expectJson conf.decoder
        , timeout = Nothing
        , withCredentials = False
        }
        |> Http.send tagger



-- Decoders


collectionDecoder : Decoder (List Cursor)
collectionDecoder =
    list Stores.Cursor.cursorDecoder
