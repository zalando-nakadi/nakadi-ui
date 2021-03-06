module Helpers.StoreLocal exposing (Model, Msg(..), collectionDecoder, config, has, initialModel, update, updateWithConfig)

import Dict
import Helpers.Http exposing (HttpStringResult, getString, postString)
import Helpers.Store as Store exposing (ErrorMessage, Status(..), onFetchErr)
import Helpers.Task exposing (dispatch)
import Json.Decode as Json exposing (..)
import Json.Encode


type alias Model =
    Store.Model String


type Msg
    = FetchData
    | FetchAllDone HttpStringResult
    | Add String
    | Remove String
    | SaveData
    | SaveAllDone HttpStringResult
    | SetParams (List ( String, String ))


initialModel : Model
initialModel =
    Store.initialModel


config : Dict.Dict String String -> Store.Config String
config params =
    { getKey = \index eventTypeName -> eventTypeName
    , url = "event-types"
    , decoder = collectionDecoder
    , headers = []
    }


has : String -> Model -> Bool
has name store =
    case Dict.get name store.dict of
        Just value ->
            True

        Nothing ->
            False


update : Msg -> Model -> ( Model, Cmd Msg )
update message store =
    updateWithConfig config message store


updateWithConfig : (Dict.Dict String String -> Store.Config String) -> Msg -> Model -> ( Model, Cmd Msg )
updateWithConfig conf message store =
    case message of
        FetchData ->
            ( Store.onFetchStart store, getString FetchAllDone (conf store.params).url )

        FetchAllDone (Ok jsonStr) ->
            let
                decodedResult =
                    jsonStr
                        |> decodeString (conf store.params).decoder

                newModel =
                    case decodedResult of
                        Ok decodedItems ->
                            Store.onFetchOk <|
                                Store.loadStore (conf store.params) decodedItems store

                        Err error ->
                            { store
                                | status = Error
                                , error =
                                    Just
                                        (ErrorMessage
                                            0
                                            "LocalStore parsing error"
                                            (Debug.toString error)
                                            (Debug.toString jsonStr)
                                        )
                            }
            in
            ( newModel, Cmd.none )

        FetchAllDone (Err error) ->
            ( onFetchErr store error, Cmd.none )

        SaveData ->
            let
                dataStr =
                    store
                        |> Store.items
                        |> Json.Encode.list Json.Encode.string
                        |> Json.Encode.encode 0
            in
            ( store, postString SaveAllDone (conf store.params).url dataStr )

        SaveAllDone (Ok _) ->
            ( store, Cmd.none )

        SaveAllDone (Err error) ->
            ( onFetchErr store error, Cmd.none )

        Add name ->
            let
                newDict =
                    Dict.insert name name store.dict
            in
            ( { store | dict = newDict }, dispatch SaveData )

        Remove name ->
            let
                newDict =
                    Dict.remove name store.dict
            in
            ( { store | dict = newDict }, dispatch SaveData )

        SetParams params ->
            let
                newParams =
                    Dict.fromList params
            in
            updateWithConfig conf FetchData { store | params = newParams }


collectionDecoder : Decoder (List String)
collectionDecoder =
    list string
