module Stores.Subscription exposing (Links, Model, Msg(..), Page, Subscription, addPageToStore, fetchNext, initialModel, linksDecoder, memberDecoder, pageDecoder, startUrl, update)

import Config
import Constants
import Dict
import Helpers.Store as Store
import Helpers.Task exposing (dispatch)
import Http
import Json.Decode exposing (..)
import Json.Decode.Pipeline exposing (..)
import Stores.Authorization exposing (Authorization)
import User.Commands exposing (logoutIfExpired)


type alias Subscription =
    { id : String
    , owning_application : String
    , event_types : List String
    , consumer_group : String
    , created_at : String
    , -- enum "begin", "end"
      read_from : String
    , authorization : Maybe Authorization
    }


type alias Page =
    { items : List Subscription
    , links : Links
    }


type alias Links =
    { next : Maybe String
    }


type alias Model =
    Store.Model Subscription


type Msg
    = FetchDone (Result Http.Error Page)
    | FetchData
    | OutFetchAllDone


initialModel : Model
initialModel =
    Store.initialModel


startUrl : String
startUrl =
    "/subscriptions?limit=1000"


update : Msg -> Model -> ( Model, Cmd Msg )
update message store =
    case message of
        FetchData ->
            ( Store.onFetchStart initialModel, fetchNext startUrl )

        FetchDone (Ok page) ->
            let
                newStore =
                    addPageToStore store page.items
            in
            case page.links.next of
                Just url ->
                    ( newStore, fetchNext url )

                Nothing ->
                    ( Store.onFetchOk newStore, dispatch OutFetchAllDone )

        FetchDone (Err error) ->
            ( Store.onFetchErr store error, logoutIfExpired error )

        OutFetchAllDone ->
            ( store, Cmd.none )


addPageToStore : Model -> List Subscription -> Model
addPageToStore store list =
    let
        newDict =
            list
                |> List.map (\subscription -> ( subscription.id, subscription ))
                |> Dict.fromList
                |> Dict.union store.dict
    in
    { store | dict = newDict }


fetchNext : String -> Cmd Msg
fetchNext next =
    let
        url =
            String.dropRight 1 Config.urlNakadiApi ++ next
    in
    Http.get url pageDecoder |> Http.send FetchDone



-- Decoders


pageDecoder : Decoder Page
pageDecoder =
    decode Page
        |> required "items" (list memberDecoder)
        |> required "_links" linksDecoder


linksDecoder : Decoder Links
linksDecoder =
    map Links <| maybe (at [ "next", "href" ] string)


memberDecoder : Decoder Subscription
memberDecoder =
    decode Subscription
        |> required Constants.id string
        |> required "owning_application" string
        |> required "event_types" (list string)
        |> optional "consumer_group" string "default"
        |> required "created_at" string
        |> optional "read_from" string "end"
        |> optional "authorization" (nullable Stores.Authorization.collectionDecoder) Nothing
