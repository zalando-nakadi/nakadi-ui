module Stores.SubscriptionCursors exposing (Model, Msg, collectionDecoder, config, fetchCursors, initialModel, update)

import Config
import Constants exposing (emptyString)
import Dict
import Helpers.Store
import Http
import Json.Decode exposing (Decoder, field, list)
import Stores.Cursor exposing (SubscriptionCursor, subscriptionCursorDecoder)


type alias Model =
    Helpers.Store.Model SubscriptionCursor


type alias Msg =
    Helpers.Store.Msg SubscriptionCursor


config : Dict.Dict String String -> Helpers.Store.Config SubscriptionCursor
config params =
    let
        id =
            Dict.get Constants.id params |> Maybe.withDefault emptyString
    in
    { getKey = \index item -> item.event_type ++ "#" ++ item.partition
    , url = Config.urlNakadiApi ++ "subscriptions/" ++ id ++ "/cursors"
    , decoder = collectionDecoder
    , headers = []
    }


initialModel : Model
initialModel =
    Helpers.Store.initialModel


update : Msg -> Model -> ( Model, Cmd Msg )
update =
    Helpers.Store.update config


fetchCursors : (Result Http.Error (List SubscriptionCursor) -> msg) -> String -> Cmd msg
fetchCursors tagger id =
    Helpers.Store.fetchAll tagger (config (Dict.singleton Constants.id id))



-- Decoders


collectionDecoder : Decoder (List SubscriptionCursor)
collectionDecoder =
    field "items" (list subscriptionCursorDecoder)
