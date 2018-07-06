module Stores.EventType exposing (..)

import Helpers.Store
import Config
import Json.Decode exposing (int, string, float, Decoder, list, nullable)
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Stores.EventTypeSchema as Schema exposing (EventTypeSchema)
import Stores.EventTypeAuthorization exposing (Authorization)
import Dict
import Constants


type alias EventType =
    { category : String
    , name : String
    , owning_application : Maybe String
    , schema : EventTypeSchema
    , --enum: metadata_enrichment
      enrichment_strategies : Maybe (List String)
    , --enum from /registry/partition-strategies ["hash","user_defined","random"]
      partition_strategy : Maybe String
    , --enum fixed,none,compatible
      compatibility_mode : Maybe String
    , partition_key_fields : Maybe (List String)
    , default_statistic : Maybe EventTypeStatistics
    , options : Maybe EventTypeOptions
    , authorization : Maybe Authorization
    , created_at : Maybe String
    , updated_at : Maybe String
    }


type alias EventTypeStatistics =
    { messages_per_minute : Int
    , message_size : Int
    , read_parallelism : Int
    , write_parallelism : Int
    }


type alias EventTypeOptions =
    { retention_time : Maybe Int
    }


type alias Model =
    Helpers.Store.Model EventType


type alias Msg =
    Helpers.Store.Msg EventType


categories :
    { undefined : String
    , data : String
    , business : String
    }
categories =
    { undefined = "undefined"
    , data = "data"
    , business = "business"
    }


allCategories : List String
allCategories =
    [ categories.undefined
    , categories.business
    , categories.data
    ]


partitionStrategies :
    { random : String
    , hash : String
    , user_defined : String
    }
partitionStrategies =
    { random = "random"
    , hash = "hash"
    , user_defined = "user_defined"
    }


compatibilityModes :
    { forward : String
    , compatible : String
    , none : String
    }
compatibilityModes =
    { forward = "forward"
    , compatible = "compatible"
    , none = "none"
    }


allModes : List String
allModes =
    [ compatibilityModes.forward
    , compatibilityModes.compatible
    , compatibilityModes.none
    ]


config : Dict.Dict String String -> Helpers.Store.Config EventType
config params =
    { getKey = (\index eventType -> eventType.name)
    , url = Config.urlNakadiApi ++ "event-types"
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


collectionDecoder : Decoder (List EventType)
collectionDecoder =
    list memberDecoder


memberDecoder : Decoder EventType
memberDecoder =
    decode EventType
        |> required "category" string
        |> required Constants.name string
        |> required "owning_application" (nullable string)
        |> required "schema" Schema.memberDecoder
        |> optional "enrichment_strategies" (nullable (list string)) Nothing
        |> optional "partition_strategy" (nullable string) Nothing
        |> optional "compatibility_mode" (nullable string) Nothing
        |> optional "partition_key_fields" (nullable (list string)) Nothing
        |> optional "default_statistic" (nullable defaultStatisticDecoder) Nothing
        |> optional "options" (nullable optionsDecoder) Nothing
        |> optional "authorization" (nullable Stores.EventTypeAuthorization.collectionDecoder) Nothing
        |> optional "created_at" (nullable string) Nothing
        |> optional "updated_at" (nullable string) Nothing


defaultStatisticDecoder : Decoder EventTypeStatistics
defaultStatisticDecoder =
    decode EventTypeStatistics
        |> required "messages_per_minute" int
        |> required "message_size" int
        |> required "read_parallelism" int
        |> required "write_parallelism" int


optionsDecoder : Decoder EventTypeOptions
optionsDecoder =
    decode EventTypeOptions
        |> optional "retention_time" (nullable int) Nothing
