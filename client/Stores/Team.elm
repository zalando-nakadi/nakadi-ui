module Stores.Team exposing (Model, Team, Page, Msg, initialModel, update)

import Helpers.Store as Store
import Config
import Dict
import Constants
import Json.Decode exposing (Decoder, list, string, succeed)
import Json.Decode.Pipeline exposing (optional, required)

type alias Team =
    { dn : String
    , id : String
    , id_name : String
    , team_id : String
    , type_ : String
    , name : String
    , mail : List String
    }

type alias Page =
    { items : List Team
    }

type alias Msg = Store.Msg Team

type alias Model = Store.Model Team


initialModel : Model
initialModel = Store.initialModel


update : Msg -> Model -> ( Model, Cmd Msg )
update =
    Store.update config

config : Dict.Dict String String -> Store.Config Team
config params =
    { getKey = \index team -> team.id
    , url = Config.urlTeamApi
    , decoder = collectionDecoder
    , headers = []
    }

collectionDecoder : Decoder (List Team)
collectionDecoder =
    (list memberDecoder)


memberDecoder : Decoder Team
memberDecoder =
    succeed Team
        |> required "dn" string
        |> required Constants.id string
        |> required "id_name" string
        |> required "team_id" string
        |> required "type" string
        |> required "name" string
        |> optional "mail" (list string) []
