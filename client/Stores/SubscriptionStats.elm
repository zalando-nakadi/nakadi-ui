module Stores.SubscriptionStats exposing (Model, Msg, SubscriptionStats, SubscriptionStatsPartition, collectionDecoder, config, fetchStats, initialModel, memberDecoder, partitionDecoder, update)

import Config
import Constants exposing (emptyString)
import Dict
import Helpers.Store
import Http
import Json.Decode exposing (Decoder, field, int, list, map6, maybe, nullable, string, succeed)
import Json.Decode.Pipeline exposing (optional, required)


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
    succeed SubscriptionStats
        |> required "event_type" string
        |> required "partitions" (list partitionDecoder)


partitionDecoder : Decoder SubscriptionStatsPartition
partitionDecoder =
    succeed SubscriptionStatsPartition
        |> required "partition" string
        |> required "state" string
        |> optional "unconsumed_events" (nullable int) Nothing
        |> optional "consumer_lag_seconds" (nullable int) Nothing
        |> optional "assignment_type" (nullable string) Nothing
        |> optional "stream_id" (nullable string) Nothing
