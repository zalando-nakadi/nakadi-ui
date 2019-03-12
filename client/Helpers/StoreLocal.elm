module Helpers.StoreLocal exposing (Model, Msg(..), collectionDecoder, config, fetchAll, has, initialModel, saveAll, update, updateWithConfig)

import Dict
import Helpers.Store as Store exposing (ErrorMessage, Status(..), onFetchErr)
import Helpers.Task exposing (dispatch)
import Http exposing (Error)
import Json.Decode as Json exposing (..)
import Json.Encode


type alias Model =
    Store.Model String


type Msg
    = FetchData
    | FetchAllDone (Result Error String)
    | Add String
    | Remove String
    | SaveData
    | SaveAllDone (Result Error String)
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


fetchAll : (Result Error String -> Msg) -> Store.Config String -> Cmd Msg
fetchAll tagger config =
    Http.send tagger <|
        Http.getString config.url


saveAll : (Result Error String -> Msg) -> Store.Config String -> String -> Cmd Msg
saveAll tagger config data =
    Http.send tagger <|
        Http.post config.url (Http.stringBody "" data) string


update : Msg -> Model -> ( Model, Cmd Msg )
update message store =
    updateWithConfig config message store


updateWithConfig : (Dict.Dict String String -> Store.Config String) -> Msg -> Model -> ( Model, Cmd Msg )
updateWithConfig config message store =
    case message of
        FetchData ->
            ( Store.onFetchStart store, fetchAll (\result -> FetchAllDone result) (config store.params) )

        FetchAllDone (Ok jsonStr) ->
            let
                decodedResult =
                    jsonStr
                        |> decodeString (config store.params).decoder

                newModel =
                    case decodedResult of
                        Ok decodedItems ->
                            Store.onFetchOk <|
                                Store.loadStore (config store.params) decodedItems store

                        Err error ->
                            { store
                                | status = Error
                                , error =
                                    Just
                                        (ErrorMessage
                                            0
                                            "LocalStore parsing error"
                                            (toString error)
                                            (toString jsonStr)
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
                        |> List.map Json.Encode.string
                        |> Json.Encode.list
                        |> Json.Encode.encode 0
            in
            ( store, saveAll SaveAllDone (config store.params) dataStr )

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
            updateWithConfig config FetchData { store | params = newParams }


collectionDecoder : Decoder (List String)
collectionDecoder =
    list string
