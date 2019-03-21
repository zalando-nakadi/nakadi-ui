module Stores.Partition exposing (Model, Msg, Partition, collectionDecoder, config, fetchPartitions, initialModel, memberDecoder, sortPartitionsList, update)

import Config
import Constants exposing (emptyString)
import Dict
import Helpers.Store
import Helpers.String exposing (compareAsInt)
import Http
import Json.Decode exposing (Decoder, list, string, succeed)
import Json.Decode.Pipeline exposing (required)


type alias Partition =
    { oldest_available_offset : String
    , newest_available_offset : String
    , partition : String
    }


type alias Model =
    Helpers.Store.Model Partition


type alias Msg =
    Helpers.Store.Msg Partition


config : Dict.Dict String String -> Helpers.Store.Config Partition
config params =
    let
        eventType =
            Dict.get Constants.eventTypeName params |> Maybe.withDefault emptyString
    in
    { getKey = \index item -> item.partition
    , url = Config.urlNakadiApi ++ "event-types/" ++ eventType ++ "/partitions"
    , decoder = collectionDecoder
    , headers = []
    }


initialModel : Model
initialModel =
    Helpers.Store.initialModel


update : Msg -> Model -> ( Model, Cmd Msg )
update =
    Helpers.Store.update config


fetchPartitions : (Result Http.Error (List Partition) -> msg) -> String -> Cmd msg
fetchPartitions tagger name =
    Helpers.Store.fetchAll tagger (config (Dict.singleton Constants.eventTypeName name))


sortPartitionsList : List { a | partition : String } -> List { a | partition : String }
sortPartitionsList list =
    list |> List.sortWith (\a b -> compareAsInt a.partition b.partition)



-- Decoders


collectionDecoder : Decoder (List Partition)
collectionDecoder =
    list memberDecoder


memberDecoder : Decoder Partition
memberDecoder =
    succeed Partition
        |> required "oldest_available_offset" string
        |> required "newest_available_offset" string
        |> required "partition" string
