module Stores.CursorDistance exposing (CursorDistance, CursorDistanceQuery, Model, Msg, collectionDecoder, config, cursorDistanceDecoder, cursorDistanceQueryEncoder, fetchDistance, initialModel, update)

import Config
import Constants exposing (emptyString)
import Dict
import Helpers.Store
import Http
import Json.Decode exposing (Decoder, int, list)
import Json.Decode.Pipeline exposing (decode, required)
import Json.Encode
import Stores.Cursor exposing (Cursor, cursorEncoder)


type alias CursorDistanceQuery =
    { initial_cursor : Cursor
    , final_cursor : Cursor
    }


type alias CursorDistance =
    { initial_cursor : Cursor
    , final_cursor : Cursor
    , distance : Int
    }


cursorDistanceQueryEncoder : CursorDistanceQuery -> Json.Encode.Value
cursorDistanceQueryEncoder cursorDistanceQuery =
    Json.Encode.object
        [ ( "initial_cursor", cursorEncoder cursorDistanceQuery.initial_cursor )
        , ( "final_cursor", cursorEncoder cursorDistanceQuery.final_cursor )
        ]


type alias Model =
    Helpers.Store.Model CursorDistance


type alias Msg =
    Helpers.Store.Msg CursorDistance


config : Dict.Dict String String -> Helpers.Store.Config CursorDistance
config params =
    let
        eventType =
            Dict.get Constants.eventTypeName params |> Maybe.withDefault emptyString
    in
    { getKey = \index item -> String.fromInt index
    , url = Config.urlNakadiApi ++ "event-types/" ++ eventType ++ "/cursor-distances"
    , decoder = collectionDecoder
    , headers = []
    }


initialModel : Model
initialModel =
    Helpers.Store.initialModel


update : Msg -> Model -> ( Model, Cmd Msg )
update =
    Helpers.Store.update config


fetchDistance : (Result Http.Error (List CursorDistance) -> msg) -> String -> List CursorDistanceQuery -> Cmd msg
fetchDistance tagger name cursorDistanceQueryList =
    let
        conf =
            config (Dict.singleton Constants.eventTypeName name)

        body =
            cursorDistanceQueryList
                |> List.map cursorDistanceQueryEncoder
                |> Json.Encode.list
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


collectionDecoder : Decoder (List CursorDistance)
collectionDecoder =
    list cursorDistanceDecoder


cursorDistanceDecoder : Decoder CursorDistance
cursorDistanceDecoder =
    decode CursorDistance
        |> required "initial_cursor" Stores.Cursor.cursorDecoder
        |> required "final_cursor" Stores.Cursor.cursorDecoder
        |> required "distance" int
