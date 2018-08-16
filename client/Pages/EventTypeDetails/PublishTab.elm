module Pages.EventTypeDetails.PublishTab exposing (..)

import Pages.EventTypeDetails.Models exposing (Model)
import Pages.EventTypeDetails.Messages exposing (..)
import RemoteData
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Helpers.UI exposing (..)
import Helpers.Panel exposing (renderError, warningMessage)
import Helpers.Store exposing (errorToViewRecord)
import Helpers.JsonPrettyPrint exposing (prettyPrintJson)
import RemoteData exposing (WebData, isLoading)
import Http
import Json.Decode
import Config
import Result


publishTab : Model -> Html Msg
publishTab pageState =
    let
        jsonParsed =
            (Json.Decode.decodeString Json.Decode.value pageState.editEvent)

        jsonError =
            if String.isEmpty pageState.editEvent then
                ""
            else
                case jsonParsed of
                    Ok _ ->
                        ""

                    Err err ->
                        err

        isDisabled =
            (isLoading pageState.sendEventResponse)
                || (Result.toMaybe jsonParsed == Nothing)
                || (String.isEmpty pageState.editEvent)

        classDisabled =
            if isDisabled then
                "dc-btn--disabled"
            else
                ""

        aPlaceholder =
            """
Example:
[
  {
      "metadata":{
        "occurred_at":"2018-08-11T16:39:57+02:00",
        "eid":"77669179-ef95-41b8-9c04-ee84685e0f21",
      },
      "business_id":"ABC-1"
  }
]
"""
    in
        div [ class "dc-card" ]
            [ h3 [ class "dc-h3" ] [ text "Publish event to this Event Type" ]
            , p [ class "dc--text-less-important" ] [ text "Expectd JSON array of events. Example: [{\"order_id\": \"1052\"}, {\"order_id\": \"8364\"}]" ]
            , div []
                [ textarea
                    [ onInput EditEvent
                    , placeholder aPlaceholder
                    , value pageState.editEvent
                    , rows 15
                    , class "dc-textarea"
                    ]
                    []
                ]
            , div [ class "dc--text-error" ] [ text jsonError ]
            , showRemoteDataStatus pageState.sendEventResponse
            , div []
                [ button [ onClick SendEvent, disabled isDisabled, class ("dc-btn dc-btn--primary " ++ classDisabled) ] [ text "Send" ]
                , span [ class "dc--island-100" ] []
                , button [ onClick SendEventReset, class "dc-btn " ] [ text "Reset" ]
                ]
            ]


sendEvent : (WebData String -> msg) -> String -> String -> Cmd msg
sendEvent tagger name event =
    case (Json.Decode.decodeString Json.Decode.value event) of
        Ok val ->
            Http.request
                { method = "POST"
                , headers = []
                , url = Config.urlNakadiApi ++ "event-types/" ++ (Http.encodeUri name) ++ "/events"
                , body = Http.jsonBody val
                , expect = Http.expectString
                , timeout = Nothing
                , withCredentials = False
                }
                |> RemoteData.sendRequest
                |> Cmd.map tagger

        Err err ->
            Debug.log ("event JSON decode error:" ++ err) Cmd.none


showRemoteDataStatus : WebData String -> Html Msg
showRemoteDataStatus state =
    case state of
        RemoteData.NotAsked ->
            div [] [ none ]

        RemoteData.Loading ->
            div [] [ text "Publishing..." ]

        RemoteData.Success resp ->
            if String.isEmpty resp then
                div [ class "dc--text-success" ] [ text ("Event(s) succsessfuly published!") ]
            else
                warningMessage
                    "Unexpected server response"
                    "Probably not all events are published successfuly"
                    (Just
                        (pre [ class "dc-pre" ] [ text (prettyPrintJson resp) ])
                    )

        RemoteData.Failure resp ->
            resp |> errorToViewRecord |> renderError
