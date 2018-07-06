module Helpers.StoreLocal exposing (..)

import Helpers.LocalStorage as LocalStorage exposing (Error(..))
import Json.Decode as Json exposing (..)
import Json.Encode
import Helpers.Store as Store exposing (Status(..), ErrorMessage)
import Constants exposing (emptyString)
import Dict
import Task
import Helpers.Task exposing (dispatch)


type alias Model =
    Store.Model String


type Msg
    = FetchData
    | FetchAllDone (Result LocalStorage.Error (Maybe String))
    | Add String
    | Remove String
    | SaveData
    | SaveAllDone (Result LocalStorage.Error ())
    | SetParams (List ( String, String ))


initialModel : Model
initialModel =
    Store.initialModel


config : Dict.Dict String String -> Store.Config String
config params =
    { getKey = (\index eventTypeName -> eventTypeName)
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


fetchAll : (Result Error (Maybe String) -> Msg) -> Store.Config String -> Cmd Msg
fetchAll tagger config =
    Task.attempt tagger <|
        LocalStorage.get config.url


saveAll : (Result Error () -> Msg) -> Store.Config String -> String -> Cmd Msg
saveAll tagger config data =
    Task.attempt tagger <|
        LocalStorage.set config.url data


update : Msg -> Model -> ( Model, Cmd Msg )
update message store =
    updateWithConfig config message store


updateWithConfig : (Dict.Dict String String -> Store.Config String) -> Msg -> Model -> ( Model, Cmd Msg )
updateWithConfig config message store =
    case message of
        FetchData ->
            ( Store.onFetchStart store, fetchAll (\result -> FetchAllDone result) (config store.params) )

        FetchAllDone (Ok maybeJsonStr) ->
            let
                decodedResult =
                    maybeJsonStr
                        |> Maybe.withDefault "[]"
                        |> decodeString (config store.params).decoder

                newModel =
                    case decodedResult of
                        Ok decodedItems ->
                            Store.onFetchOk <|
                                Store.loadStore (config store.params) decodedItems store

                        Err error ->
                            onFetchErr store
                                (ErrorMessage
                                    0
                                    "LocalStore parsing error"
                                    (toString error)
                                    (toString maybeJsonStr)
                                )
            in
                ( newModel, Cmd.none )

        FetchAllDone (Err error) ->
            ( onFetchErr store (localStoreErrorToViewRecord error), Cmd.none )

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

        SaveAllDone (Ok ()) ->
            ( store, Cmd.none )

        SaveAllDone (Err error) ->
            ( onFetchErr store (localStoreErrorToViewRecord error), Cmd.none )

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


onFetchErr :
    { a | error : Maybe ErrorMessage, status : Status }
    -> ErrorMessage
    -> { a | error : Maybe ErrorMessage, status : Status }
onFetchErr store error =
    { store
        | status = Error
        , error = Just error
    }


localStoreErrorToViewRecord : LocalStorage.Error -> ErrorMessage
localStoreErrorToViewRecord error =
    case error of
        QuotaExceeded ->
            ErrorMessage
                0
                "LocalStorage quota exceeded"
                "Browser LocalStorage quota exceeded."
                emptyString

        Disabled ->
            ErrorMessage
                1
                "LocalStorage unavailable"
                "LocalStorage not supported or disabled in this browser."
                emptyString
