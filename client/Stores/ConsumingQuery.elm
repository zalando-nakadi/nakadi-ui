module Stores.ConsumingQuery exposing (ConsumingQuery, Model, Msg, initialModel, update)

import Config
import Constants
import Dict
import Helpers.Store as Store
import Json.Decode exposing (Decoder, bool, field, list, string, succeed)
import Json.Decode.Pipeline exposing (required)


type alias ConsumingQuery =
    { id : String
    , sql : String
    , envelope : Bool
    , outputEventType : OutputEventType
    }


type alias OutputEventType =
    { name : String
    }


type alias Model =
    Store.Model ConsumingQuery


type alias Msg =
    Store.Msg ConsumingQuery


config : Dict.Dict String String -> Store.Config ConsumingQuery
config params =
    let
        eventType =
            Dict.get Constants.eventTypeName params |> Maybe.withDefault Constants.emptyString
    in
    { getKey = \index item -> item.id
    , url = Config.urlNakadiSqlApi ++ "event-types/" ++ eventType ++ "/queries"
    , decoder = collectionDecoder
    , headers = []
    }


initialModel : Model
initialModel =
    Store.initialModel


update : Msg -> Model -> ( Model, Cmd Msg )
update =
    Store.update config



-- Decoders


collectionDecoder : Decoder (List ConsumingQuery)
collectionDecoder =
    field "items" (list queryDecoder)


queryDecoder : Decoder ConsumingQuery
queryDecoder =
    succeed ConsumingQuery
        |> required "id" string
        |> required "sql" string
        |> required "envelope" bool
        |> required "output_event_type" outputEventTypeDecoder


outputEventTypeDecoder : Decoder OutputEventType
outputEventTypeDecoder =
    succeed OutputEventType
        |> required "name" string
