module Stores.SubscriptionStats exposing (Model, Msg, SubscriptionStats, SubscriptionStatsPartition, collectionDecoder, config, fetchStats, initialModel, memberDecoder, partitionDecoder, update)

import Config
import Constants exposing (emptyString)
import Dict
import Helpers.Store
import Http
import Json.Decode exposing (Decoder, field, float, int, list, map6, maybe, nullable, string)
import Json.Decode.Pipeline exposing (decode, hardcoded, optional, required)


type alias SubscriptionStats =
    { event_type : String
    , partitions : List SubscriptionStatsPartition
    }


type alias SubscriptionStatsPartition =
    { partition : String
    , -- enum 'unassigned', 'reassigning', 'assigned':
      state : String
    , unconsumed_events : Maybe Int
    , consumer_lag_seconds : Maybe Int
    , assignment_type : Maybe String
    , stream_id : Maybe String
    }


type alias Model =
    Helpers.Store.Model SubscriptionStats


type alias Msg =
    Helpers.Store.Msg SubscriptionStats


config : Dict.Dict String String -> Helpers.Store.Config SubscriptionStats
config params =
    let
        id =
            Dict.get Constants.id params |> Maybe.withDefault emptyString
    in
    { getKey = \index item -> item.event_type
    , url = Config.urlNakadiApi ++ "subscriptions/" ++ id ++ "/stats?show_time_lag=true"
    , decoder = collectionDecoder
    , headers = []
    }


initialModel : Model
initialModel =
    Helpers.Store.initialModel


update : Msg -> Model -> ( Model, Cmd Msg )
update =
    Helpers.Store.update config


fetchStats : (Result Http.Error (List SubscriptionStats) -> msg) -> String -> Cmd msg
fetchStats tagger id =
    Helpers.Store.fetchAll tagger (config (Dict.singleton Constants.id id))



-- Decoders


collectionDecoder : Decoder (List SubscriptionStats)
collectionDecoder =
    field "items" (list memberDecoder)


memberDecoder : Decoder SubscriptionStats
memberDecoder =
    decode SubscriptionStats
        |> required "event_type" string
        |> required "partitions" (list partitionDecoder)


partitionDecoder : Decoder SubscriptionStatsPartition
partitionDecoder =
    map6 SubscriptionStatsPartition
        (field "partition" string)
        (field "state" string)
        (maybe (field "unconsumed_events" int))
        (maybe (field "consumer_lag_seconds" int))
        (maybe (field "assignment_type" string))
        (maybe (field "stream_id" string))
