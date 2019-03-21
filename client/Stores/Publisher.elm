module Stores.Publisher exposing (Model, Msg, Publisher, collectionDecoder, config, initialModel, memberDecoder, update)

import Config
import Constants exposing (emptyString)
import Dict
import Helpers.Store
import Json.Decode exposing (Decoder, field, int, list, string, succeed)
import Json.Decode.Pipeline exposing (required)


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
            Dict.get Constants.eventTypeName params |> Maybe.withDefault emptyString
    in
    { getKey = \index item -> item.name
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



-- Decoders


collectionDecoder : Decoder (List Publisher)
collectionDecoder =
    field "values" (list memberDecoder)


memberDecoder : Decoder Publisher
memberDecoder =
    succeed Publisher
        |> required "value" string
        |> required "count" int
