module Pages.EventTypeDetails.PublishTab exposing (Model, Msg(..), eventsTemplate, initialModel, publishTab, sendEvent, showRemoteDataStatus, update)

import Config
import Helpers.JsonPrettyPrint exposing (prettyPrintJson)
import Helpers.Panel exposing (renderError, warningMessage)
import Helpers.Store exposing (errorToViewRecord)
import Helpers.UI exposing (onChange)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import ISO8601 exposing (fromPosix)
import Json.Decode
import RemoteData exposing (RemoteData(..), WebData, isLoading)
import Result
import Task
import Time exposing (Posix, toMillis, utc)
import Url exposing (percentEncode)


type Msg
    = EditEvent String
    | SendEvent
    | SendEventResponse (WebData String)
    | SendEventReset
    | SetPublishTemplate
    | SetPublishTemplateWithTime Posix


type alias Model =
    { editEvent : String
    , sendEventResponse : WebData String
    }


initialModel : Model
initialModel =
    { editEvent = ""
    , sendEventResponse = NotAsked
    }


update : Msg -> Model -> String -> ( Model, Cmd Msg )
update message model name =
    case message of
        EditEvent value ->
            ( { model | editEvent = value }, Cmd.none )

        SendEvent ->
            ( { model | sendEventResponse = Loading }, sendEvent SendEventResponse name model.editEvent )

        SendEventResponse value ->
            ( { model | sendEventResponse = value }, Cmd.none )

        SendEventReset ->
            ( { model | sendEventResponse = NotAsked, editEvent = "" }, Cmd.none )

        SetPublishTemplateWithTime posix ->
            let
                editEvent =
                    eventsTemplate posix
            in
            ( { model | editEvent = editEvent }, Cmd.none )

        SetPublishTemplate ->
            ( model, Time.now |> Task.perform SetPublishTemplateWithTime )


publishTab : Model -> Html Msg
publishTab model =
    let
        jsonParsed =
            Json.Decode.decodeString Json.Decode.value model.editEvent

        jsonError =
            if String.isEmpty model.editEvent then
                ""

            else
                case jsonParsed of
                    Ok _ ->
                        ""

                    Err err ->
                        err

        isDisabled =
            isLoading model.sendEventResponse
                || (Result.toMaybe jsonParsed == Nothing)
                || String.isEmpty model.editEvent

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
        [ div []
            [ button
                [ class "dc-btn dc-btn--small"
                , onClick SetPublishTemplate
                ]
                [ text "Insert template" ]
            ]
        , p [ class "dc--text-less-important" ] [ text "Expectd JSON array of events. Example: [{\"order_id\": \"1052\"}, {\"order_id\": \"8364\"}]" ]
        , div []
            [ pre
                [ class "ace-edit", style "height" "400px" ]
                [ node "ace-editor"
                    [ value model.editEvent
                    , onChange EditEvent
                    , attribute "theme" "ace/theme/dawn"
                    , attribute "mode" "ace/mode/json"
                    ]
                    []
                ]
            ]
        , div [ class "dc--text-error" ] [ text jsonError ]
        , showRemoteDataStatus model.sendEventResponse
        , div []
            [ button [ onClick SendEvent, disabled isDisabled, class ("dc-btn dc-btn--primary " ++ classDisabled) ] [ text "Send" ]
            , span [ class "dc--island-100" ] []
            , button [ onClick SendEventReset, class "dc-btn " ] [ text "Reset" ]
            ]
        ]


eventsTemplate : Posix -> String
eventsTemplate posix =
    let
        timeStr =
            posix
                |> fromPosix
                |> ISO8601.toString

        eid =
            String.fromInt (9000 - toMillis utc posix)
    in
    """
[
    {
        "metadata": {
          "occurred_at":"{timeStr}",
          "eid":"{eid}9179-ef95-41b8-9c04-ee84685e5555"
        },
        "your_field":"ABC-1"
    }
]
"""
        |> String.replace "{timeStr}" timeStr
        |> String.replace "{eid}" eid


sendEvent : (WebData String -> msg) -> String -> String -> Cmd msg
sendEvent tagger name event =
    case Json.Decode.decodeString Json.Decode.value event of
        Ok val ->
            Http.request
                { method = "POST"
                , headers = []
                , url = Config.urlNakadiApi ++ "event-types/" ++ percentEncode name ++ "/events"
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
        NotAsked ->
            div [] [ text "" ]

        Loading ->
            div [] [ text "Publishing..." ]

        Success resp ->
            if String.isEmpty resp then
                div [ class "dc--text-success flash-msg" ] [ text "Event(s) succsessfuly published!" ]

            else
                warningMessage
                    "Unexpected server response"
                    "Probably not all events are published successfuly"
                    (Just
                        (pre [ class "dc-pre" ] [ text (prettyPrintJson resp) ])
                    )

        Failure resp ->
            resp |> errorToViewRecord |> renderError
