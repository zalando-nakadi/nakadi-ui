module Stores.EventTypeSchema exposing (..)

import Helpers.Store
import Config
import Json.Decode exposing (int, string, float, Decoder, list, nullable, field)
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Dict
import Constants exposing (emptyString)


type alias EventTypeSchema =
    { --enum json_schema type_ : String
      schema : String
    , version : Maybe String
    , created_at : Maybe String
    }


type alias Model =
    Helpers.Store.Model EventTypeSchema


type alias Msg =
    Helpers.Store.Msg EventTypeSchema


config : Dict.Dict String String -> Helpers.Store.Config EventTypeSchema
config params =
    let
        eventType =
            (Dict.get Constants.eventTypeName params) |> Maybe.withDefault emptyString
    in
        { getKey = (\index schema -> schema.version |> Maybe.withDefault emptyString)
        , url = Config.urlNakadiApi ++ "event-types/" ++ eventType ++ "/schemas"
        , decoder = collectionDecoder
        , headers = []
        }


initialModel : Model
initialModel =
    Helpers.Store.initialModel


update : Msg -> Model -> ( Model, Cmd Msg )
update =
    Helpers.Store.update config



-- Decoders


collectionDecoder : Decoder (List EventTypeSchema)
collectionDecoder =
    field "items" (list memberDecoder)


memberDecoder : Decoder EventTypeSchema
memberDecoder =
    decode EventTypeSchema
        |> required "schema" string
        |> optional "version" (nullable string) Nothing
        |> optional "created_at" (nullable string) Nothing
