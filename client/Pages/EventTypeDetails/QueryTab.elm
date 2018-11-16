module Pages.EventTypeDetails.QueryTab exposing (..)

import Pages.EventTypeDetails.Models exposing (Model)
import Pages.EventTypeDetails.Messages exposing (..)
import Stores.Query exposing (Query, queryDecoder)
import RemoteData
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Helpers.UI exposing (..)
import Helpers.Panel exposing (renderError, warningMessage)
import Helpers.Store exposing (errorToViewRecord)
import RemoteData exposing (WebData, isLoading)
import Http
import Json.Decode
import Config
import User.Models exposing (Settings)
import String.Extra exposing (replace)
import Helpers.Ace as Ace


queryTab : Settings -> Model -> Html Msg
queryTab setting pageState =
    div [ class "dc-card" ]
        [ showRemoteDataStatus
            pageState.loadQueryResponse
            (queryTabHeader setting pageState)
        ]


queryTabHeader : Settings -> Model -> Query -> Html Msg
queryTabHeader settings model query =
    let
        statClass =
            case query.status of
                "active" ->
                    "schema-tab__value dc-status dc-status--active"

                "inactive" ->
                    "schema-tab__value dc-status dc-status--error"

                _ ->
                    "schema-tab__value dc-status dc-status--inactive"

        terminate =
            if query.status == "active" then
                span
                    [ onClick OpenDeleteQueryPopup
                    , class "icon-link dc-icon--trash dc-btn--destroy dc-icon dc-icon--interactive"
                    , title "Terminate Query"
                    ]
                    []
            else
                none
    in
        div []
            [ span [] [ text "SQL Query" ]
            , helpIcon "Nakadi SQL" queryHelp BottomRight
            , label [ class "query-tab__label" ] [ text " Status: " ]
            , span [ class (statClass) ] [ text query.status ]
            , span [ class "query-tab__value toolbar" ]
                [ a
                    [ title "View Query as raw JSON"
                    , class "icon-link dc-icon dc-icon--interactive"
                    , target "_blank"
                    , href <| Config.urlNakadiSqlApi ++ "queries/" ++ query.id
                    ]
                    [ i [ class "far fa-file-code" ] [] ]
                , a
                    [ title "Query Monitoring Graphs"
                    , class "icon-link dc-icon dc-icon--interactive"
                    , target "_blank"
                    , href <| replace "{query}" query.id settings.queryMonitoringUrl
                    ]
                    [ i [ class "fas fa-chart-line" ] [] ]
                , a
                    [ onClick (CopyToClipboard query.sql)
                    , class "icon-link dc-icon dc-icon--interactive"
                    , title "Copy To Clipboard"
                    ]
                    [ i [ class "far fa-clipboard" ] [] ]
                , terminate
                ]
            , sqlView query.sql
            , deleteQueryPopup model query
            ]


queryHelp : List (Html msg)
queryHelp =
    [ text "Nakadi SQL API provides a self-serviceable SQL interface for stream processing Nakadi event"
    , text " types. By expressing transformations as SQL, this service enables a broader audience to analyse"
    , text " and process streaming data in real-time. Nakadi SQL is scalable, elastic and fault-tolerant."
    , text " It is planned to support a wide range of streaming operations, including data filtering,"
    , text " transformations, aggregations, joins, windowing, and sessionization."
    , newline
    , text "A query describes a set of operations to be performed on one or more EventTypes."
    , newline
    , text "The output events are written to an output EventType, which can be accessed via Nakadi."
    , newline
    , link "More in the API Manual" "https://apis.zalando.net/apis/3d932e38-b9db-42cf-84bb-0898a72895fb/ui"
    ]


sqlView : String -> Html msg
sqlView sql =
    pre [ class "sql-view" ]
        [ Ace.toHtml
            [ Ace.value sql
            , Ace.mode "sql"
            , Ace.theme "dawn"
            , Ace.tabSize 4
            , Ace.useSoftTabs False
            , Ace.extensions [ "language_tools" ]
            , Ace.readOnly True
            ]
            []
        ]


loadQuery : (WebData Query -> msg) -> String -> Cmd msg
loadQuery tagger id =
    Http.get (Config.urlNakadiSqlApi ++ "queries/" ++ (Http.encodeUri id)) queryDecoder
        |> RemoteData.sendRequest
        |> Cmd.map tagger


showRemoteDataStatus : WebData a -> (a -> Html Msg) -> Html Msg
showRemoteDataStatus state content =
    case state of
        RemoteData.NotAsked ->
            div [] [ none ]

        RemoteData.Loading ->
            div [] [ text "Loading..." ]

        RemoteData.Success resp ->
            content resp

        RemoteData.Failure resp ->
            resp |> errorToViewRecord |> renderError


deleteQueryPopup : Model -> Query -> Html Msg
deleteQueryPopup model query =
    let
        deleteButton =
            if model.deleteQueryPopupCheck then
                button
                    [ onClick QueryDelete
                    , class "dc-btn dc-btn--destroy"
                    ]
                    [ text "Delete Query" ]
            else
                button [ disabled True, class "dc-btn dc-btn--disabled" ]
                    [ text "Delete Query" ]

        dialog =
            div []
                [ div [ class "dc-overlay" ] []
                , div [ class "dc-dialog" ]
                    [ div [ class "dc-dialog__content", style [ ( "min-width", "600px" ) ] ]
                        [ div [ class "dc-dialog__body" ]
                            [ div [ class "dc-dialog__close" ]
                                [ i
                                    [ onClick CloseDeleteQueryPopup
                                    , class "dc-icon dc-icon--close dc-icon--interactive dc-dialog__close__icon"
                                    ]
                                    []
                                ]
                            , h3 [ class "dc-dialog__title" ]
                                [ text "Delete/Terminate Query" ]
                            , div [ class "dc-msg dc-msg--error" ]
                                [ div [ class "dc-msg__inner" ]
                                    [ div [ class "dc-msg__icon-frame" ]
                                        [ i [ class "dc-icon dc-msg__icon dc-icon--warning" ] []
                                        ]
                                    , div [ class "dc-msg__bd" ]
                                        [ h1 [ class "dc-msg__title blinking" ] [ text "Warning! Dangerous Action!" ]
                                        , p [ class "dc-msg__text" ]
                                            [ text "You are about to completely delete this query forever."
                                            , text " This action cannot be undone."
                                            ]
                                        ]
                                    ]
                                ]
                            , h1 [ class "dc-h1 dc--is-important" ] [ text query.id ]
                            , p [ class "dc-p" ]
                                [ text "Think twice, notify all consumers and producers."
                                ]
                            , showRemoteDataStatus model.deleteQueryResponse (always none)
                            ]
                        , div [ class "dc-dialog__actions" ]
                            [ input
                                [ onClick ConfirmQueryDelete
                                , type_ "checkbox"
                                , class "dc-checkbox"
                                , id "confirmDeleteQuery"
                                , checked model.deleteQueryPopupCheck
                                ]
                                []
                            , label
                                [ for "confirmDeleteQuery", class "dc-label" ]
                                [ text "Yes, delete "
                                , b [] [ text query.id ]
                                ]
                            , deleteButton
                            ]
                        ]
                    ]
                ]
    in
        if model.deleteQueryPopupOpen then
            dialog
        else
            none


deleteQuery : (WebData () -> msg) -> String -> Cmd msg
deleteQuery tagger id =
    Http.request
        { method = "DELETE"
        , headers = []
        , url = Config.urlNakadiSqlApi ++ "queries/" ++ (Http.encodeUri id)
        , body = Http.emptyBody
        , expect = Http.expectStringResponse (always (Ok ()))
        , timeout = Nothing
        , withCredentials = False
        }
        |> RemoteData.sendRequest
        |> Cmd.map tagger
