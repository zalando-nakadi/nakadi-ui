module Stores.EventTypeValidation exposing (..)

import Helpers.Store
import Config
import Json.Decode exposing (int, string, float, Decoder, list, nullable, field)
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Dict
import Constants exposing (emptyString)


type alias EventTypeValidationIssue =
    { id : Int
    , title : String
    , message : String
    , link : String
    , group : String
    , severity : Int
    }


type alias Model =
    Helpers.Store.Model EventTypeValidationIssue


type alias Msg =
    Helpers.Store.Msg EventTypeValidationIssue


config : Dict.Dict String String -> Helpers.Store.Config EventTypeValidationIssue
config params =
    let
        eventType =
            (Dict.get Constants.eventTypeName params) |> Maybe.withDefault emptyString
    in
        { getKey = (\index issue -> issue.group ++ ":" ++ (toString index))
        , url = Config.urlValidationApi ++ eventType
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


collectionDecoder : Decoder (List EventTypeValidationIssue)
collectionDecoder =
    field "issues" (list memberDecoder)



{-
   example:{
            id: issueType.SCHEMA_COMBINED,
            title: "The schema is too complex",
            message: "Please update the schema without usage of disjunctive formats (anyOf,oneOf,allOf,not)."+
            " It is easier to understand, and helps the services as the data lake to flatten the data of an event.",
            group: "schema",
            severity: 10}
-}


memberDecoder : Decoder EventTypeValidationIssue
memberDecoder =
    decode EventTypeValidationIssue
        |> required "id" int
        |> required "title" string
        |> required "message" string
        |> optional "link" string emptyString
        |> required "group" string
        |> required "severity" int
