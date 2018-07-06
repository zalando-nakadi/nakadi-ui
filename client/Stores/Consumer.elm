module Stores.Consumer exposing (..)

import Helpers.Store
import Config
import Json.Decode exposing (field, int, string, float, Decoder, list, nullable)
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Dict
import Http
import Constants exposing (emptyString)


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
            (Dict.get Constants.eventTypeName params) |> Maybe.withDefault emptyString
    in
        { getKey = (\index item -> item.name)
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
