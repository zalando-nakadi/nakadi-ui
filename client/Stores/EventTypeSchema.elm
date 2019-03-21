module Stores.EventTypeSchema exposing (EventTypeSchema, Model, Msg, collectionDecoder, config, initialModel, memberDecoder, update)

import Config
import Constants exposing (emptyString)
import Dict
import Helpers.Store
import Json.Decode exposing (Decoder, field, list, nullable, string, succeed)
import Json.Decode.Pipeline exposing (optional, required)


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
            Dict.get Constants.eventTypeName params |> Maybe.withDefault emptyString
    in
    { getKey = \index schema -> schema.version |> Maybe.withDefault emptyString
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
    succeed EventTypeSchema
        |> required "schema" string
        |> optional "version" (nullable string) Nothing
        |> optional "created_at" (nullable string) Nothing
