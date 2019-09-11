module Stores.TeamDetails exposing (Model, Msg, TeamDetail, initialModel, update)

import Config
import Constants
import Dict
import Helpers.Store as Store
import Json.Decode exposing (Decoder, list, string, succeed)
import Json.Decode.Pipeline exposing (optional, required)


type alias Msg =
    Store.Msg TeamDetail


type alias Model =
    Store.Model TeamDetail


type alias TeamDetail =
    { id : String
    , member : List String
    }


initialModel : Model
initialModel =
    Store.initialModel


update : Msg -> Model -> ( Model, Cmd Msg )
update =
    Store.update config


config : Dict.Dict String String -> Store.Config TeamDetail
config params =
    { getKey = \index team -> team.id
    , url = Config.urlTeamApi ++ "/" ++ (Dict.get "id" params |> Maybe.withDefault "")
    , decoder = collectionDecoder
    , headers = []
    }


collectionDecoder : Decoder (List TeamDetail)
collectionDecoder =
    Json.Decode.map (\a -> [ a ]) memberDecoder


memberDecoder : Decoder TeamDetail
memberDecoder =
    succeed TeamDetail
        |> required Constants.id string
        |> optional "member" (list string) []
