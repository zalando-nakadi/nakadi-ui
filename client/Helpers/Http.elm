module Helpers.Http exposing (HttpStringResult, getString, httpErrorToString, postString)

import Http exposing (..)
import Json.Decode


type alias HttpStringResult =
    Result Error String


httpErrorToString : Error -> String
httpErrorToString error =
    case error of
        BadUrl string ->
            "Malformed url " ++ string

        Timeout ->
            "Timeout loading data"

        NetworkError ->
            "Network error"

        BadStatus response ->
            "code: " ++ toString response.status.code ++ ", " ++ response.body

        BadPayload string response ->
            "Error decoding server response" ++ string


getString : (HttpStringResult -> msg) -> String -> Cmd msg
getString tagger url =
    Http.send tagger <|
        Http.getString url


postString : (HttpStringResult -> msg) -> String -> String -> Cmd msg
postString tagger url data =
    Http.send tagger <|
        Http.post url (Http.stringBody "" data) Json.Decode.string
