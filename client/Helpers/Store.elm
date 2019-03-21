module Helpers.Store exposing (Config, ErrorMessage, Id, Model, Msg(..), Status(..), cmdIfDone, decodeError, empty, errorDecoder, errorToViewRecord, fetchAll, get, has, initialModel, isLoading, items, loadStore, onFetchErr, onFetchOk, onFetchReset, onFetchStart, responseToString, size, update)

import Constants exposing (emptyString)
import Dict
import Http exposing (Error(..))
import Json.Decode as Decode exposing (..)
import User.Commands exposing (logoutIfExpired)


type alias Id =
    String


type Msg entity
    = FetchAllDone (Result Http.Error (List entity))
    | FetchData
    | SetParams (List ( String, String ))


type Status
    = Unknown
    | Loading
    | Error
    | Loaded


type alias Config entity =
    { getKey : Int -> entity -> Id
    , url : String
    , decoder : Decoder (List entity)
    , headers : List ( String, String )
    }


type alias Model entity =
    { dict : Dict.Dict String entity
    , status : Status
    , params : Dict.Dict String String
    , error : Maybe ErrorMessage
    }


initialModel : Model entity
initialModel =
    { dict = Dict.empty
    , status = Unknown
    , params = Dict.empty
    , error = Nothing
    }


fetchAll : (Result Http.Error (List entity) -> msg) -> Config entity -> Cmd msg
fetchAll tagger config =
    let
        headers =
            List.map (\( key, val ) -> Http.header key val) config.headers
    in
    Http.request
        { method = "GET"
        , headers = headers
        , url = config.url
        , body = Http.emptyBody
        , expect = Http.expectJson config.decoder
        , timeout = Nothing
        , withCredentials = False
        }
        |> Http.send tagger


loadStore : Config entity -> List entity -> Model entity -> Model entity
loadStore config list store =
    let
        toKeyVal index item =
            ( config.getKey index item, item )

        keyValueList =
            List.indexedMap toKeyVal list

        listSorted =
            List.sortBy (\( key, val ) -> key) keyValueList

        newDict =
            Dict.fromList listSorted
    in
    { store | dict = newDict }


empty : Model entity -> Model entity
empty store =
    { store | dict = Dict.empty }


items : Model entity -> List entity
items store =
    Dict.values store.dict


get : Id -> Model entity -> Maybe entity
get key store =
    Dict.get key store.dict


has : Id -> Model entity -> Bool
has key store =
    case Dict.get key store.dict of
        Just value ->
            True

        Nothing ->
            False


size : Model entity -> Int
size store =
    Dict.size store.dict


isLoading : Model entity -> Bool
isLoading store =
    store.status == Loading


update :
    (Dict.Dict String String -> Config entity)
    -> Msg entity
    -> Model entity
    -> ( Model entity, Cmd (Msg entity) )
update config message store =
    case message of
        FetchData ->
            ( store |> empty |> onFetchStart, fetchAll FetchAllDone (config store.params) )

        FetchAllDone (Ok decodedItems) ->
            let
                storeLoaded =
                    loadStore (config store.params) decodedItems store
            in
            ( onFetchOk storeLoaded, Cmd.none )

        FetchAllDone (Err error) ->
            ( onFetchErr store error, logoutIfExpired error )

        SetParams params ->
            let
                newParams =
                    Dict.fromList params
            in
            update config FetchData { store | params = newParams }


onFetchReset :
    { a | error : Maybe ErrorMessage, status : Status }
    -> { a | error : Maybe ErrorMessage, status : Status }
onFetchReset store =
    { store | status = Unknown, error = Nothing }


onFetchStart :
    { a | error : Maybe ErrorMessage, status : Status }
    -> { a | error : Maybe ErrorMessage, status : Status }
onFetchStart store =
    { store | status = Loading, error = Nothing }


onFetchOk :
    { a | error : Maybe ErrorMessage, status : Status }
    -> { a | error : Maybe ErrorMessage, status : Status }
onFetchOk store =
    { store | status = Loaded, error = Nothing }


onFetchErr :
    { a | error : Maybe ErrorMessage, status : Status }
    -> Http.Error
    -> { a | error : Maybe ErrorMessage, status : Status }
onFetchErr store error =
    { store
        | status = Error
        , error = Just (errorToViewRecord error)
    }


cmdIfDone : Msg entity -> Cmd a -> Cmd a
cmdIfDone subMsg cmd =
    case subMsg of
        FetchAllDone result ->
            cmd

        _ ->
            Cmd.none


errorToViewRecord : Http.Error -> ErrorMessage
errorToViewRecord error =
    case error of
        BadUrl string ->
            ErrorMessage
                1
                "Malformed url"
                string
                emptyString

        Timeout ->
            ErrorMessage
                2
                "Timeout loading data"
                "Timeout loading data"
                emptyString

        NetworkError ->
            ErrorMessage
                3
                "Network error"
                "Network error"
                emptyString

        BadStatus response ->
            let
                defaultMessage =
                    ErrorMessage
                        response.status.code
                        "Bad response status"
                        "Bad response status"
                        (responseToString response)
            in
            decodeError defaultMessage response.body

        BadPayload string response ->
            ErrorMessage
                response.status.code
                "Error decoding server response"
                string
                (responseToString response)


type alias ErrorMessage =
    { code : Int
    , title : String
    , message : String
    , details : String
    }


decodeError : ErrorMessage -> String -> ErrorMessage
decodeError defaultError jsonString =
    decodeString (errorDecoder defaultError) jsonString
        |> Result.withDefault defaultError


errorDecoder : ErrorMessage -> Decoder ErrorMessage
errorDecoder defaultError =
    map4 ErrorMessage
        (succeed defaultError.code)
        (oneOf [ field "title" string, succeed defaultError.title ])
        (oneOf [ field "detail" string, field "error_description" string, succeed defaultError.message ])
        (succeed defaultError.details)


responseToString : Http.Response String -> String
responseToString response =
    "\nURL: "
        ++ response.url
        ++ "\nResponse headers:"
        ++ (response.headers
                |> Dict.foldl (\k v str -> str ++ "\n    \"" ++ k ++ "\" : \"" ++ v ++ "\"") emptyString
           )
        ++ "\nBody: "
        ++ response.body
