module Stores.Consumer exposing (Consumer, Model, Msg, collectionDecoder, config, fetchConsumers, initialModel, memberDecoder, update)

import Config
import Constants exposing (emptyString)
import Dict
import Helpers.Store
import Http
import Json.Decode exposing (Decoder, field, float, int, list, nullable, string)
import Json.Decode.Pipeline exposing (decode, hardcoded, optional, required)


type alias Consumer =
    { name : String
    , count : Int
    }


type alias Model =
    Helpers.Store.Model Consumer


type alias Msg =
    Helpers.Store.Msg Consumer


config : Dict.Dict String String -> Helpers.Store.Config Consumer
config params =
    let
        eventType =
            Dict.get Constants.eventTypeName params |> Maybe.withDefault emptyString
    in
    { getKey = \index item -> item.name
    , url = Config.urlLogsApi ++ "event/" ++ eventType ++ "/consumers"
    , decoder = collectionDecoder
    , headers = []
    }


initialModel : Model
initialModel =
    Helpers.Store.initialModel


update : Msg -> Model -> ( Model, Cmd Msg )
update =
    Helpers.Store.update config


fetchConsumers : (Result Http.Error (List Consumer) -> msg) -> String -> Cmd msg
fetchConsumers tagger name =
    Helpers.Store.fetchAll tagger (config (Dict.singleton Constants.eventTypeName name))



-- Decoders


collectionDecoder : Decoder (List Consumer)
collectionDecoder =
    field "values" (list memberDecoder)


memberDecoder : Decoder Consumer
memberDecoder =
    decode Consumer
        |> required "value" string
        |> required "count" int
