module Stores.Publisher exposing (..)

import Helpers.Store
import Config
import Json.Decode exposing (field, int, string, float, Decoder, list, nullable)
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Dict
import Http
import Constants exposing (emptyString)


type alias Publisher =
    { name : String
    , count : Int
    }


type alias Model =
    Helpers.Store.Model Publisher


type alias Msg =
    Helpers.Store.Msg Publisher


config : Dict.Dict String String -> Helpers.Store.Config Publisher
config params =
    let
        eventType =
            (Dict.get Constants.eventTypeName params) |> Maybe.withDefault emptyString
    in
        { getKey = (\index item -> item.name)
        , url = Config.urlLogsApi ++ "event/" ++ eventType ++ "/publishers"
        , decoder = collectionDecoder
        , headers = []
        }


initialModel : Model
initialModel =
    Helpers.Store.initialModel


update : Msg -> Model -> ( Model, Cmd Msg )
update =
    Helpers.Store.update config


fetchPublishers : (Result Http.Error (List Publisher) -> msg) -> String -> Cmd msg
fetchPublishers tagger name =
    Helpers.Store.fetchAll tagger (config (Dict.singleton Constants.eventTypeName name))



-- Decoders


collectionDecoder : Decoder (List Publisher)
collectionDecoder =
    field "values" (list memberDecoder)


memberDecoder : Decoder Publisher
memberDecoder =
    decode Publisher
        |> required "value" string
        |> required "count" int

