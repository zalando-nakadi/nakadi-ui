module Pages.QueryDetails.QueryTab exposing (queryTab)

import Config
import Helpers.Panel exposing (renderError)
import Helpers.Store exposing (errorToViewRecord)
import Helpers.String exposing (boolToString)
import Helpers.UI exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Pages.QueryDetails.Help as Help
import Pages.QueryDetails.Messages exposing (..)
import Pages.QueryDetails.Models exposing (Model)
import RemoteData exposing (WebData)
import Stores.Query exposing (Query)
import String exposing (replace)
import Url exposing (percentEncode)
import User.Models exposing (Settings)


queryTab : Settings -> Model -> Html Msg
queryTab setting pageState =
    div [ class "dc-card" ]
        [
         --showRemoteDataStatus
         --pageState.loadQueryResponse
         --   (queryTabHeader setting pageState)
        ]


queryTabHeader : Settings -> Model -> Query -> Html Msg
queryTabHeader settings model query =
    let
        statClass =
            "schema-tab__value dc-status dc-status--active"
    in
    div []
        [ span [] [ text "SQL Query" ]
        , helpIcon "Nakadi SQL" queryHelp BottomRight
        , label [ class "query-tab__label" ] [ text " Status: " ]
        , span [ class statClass ] [ text query.status ]
        , helpIcon "Envelope" Help.envelope BottomRight
        , label [ class "query-tab__label" ] [ text " Envelope: " ]
        , span [] [ text (boolToString query.envelope) ]
        , span [ class "query-tab__value toolbar" ]
            [ a
                [ title "View Query as raw JSON"
                , class "icon-link dc-icon dc-icon--interactive"
                , target "_blank"
                , href <| Config.urlNakadiSqlApi ++ "queries/" ++ query.id
                ]
                [ i [ class "icon icon--source" ] [] ]
            , a
                [ title "Query Monitoring Graphs"
                , class "icon-link dc-icon dc-icon--interactive"
                , target "_blank"
                , href <| replace "{query}" query.id settings.queryMonitoringUrl
                ]
                [ i [ class "icon icon--chart" ] [] ]
            , button
                [ onClick (CopyToClipboard query.sql)
                , class "icon-link dc-icon dc-icon--interactive"
                , title "Copy To Clipboard"
                ]
                [ i [ class "icon icon--clipboard" ] [] ]
            ]
        , sqlView query.sql
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
        [ node "ace-editor"
            [ value sql
            , attribute "theme" "ace/theme/dawn"
            , attribute "mode" "ace/mode/sql"
            , readonly True
            ]
            []
        ]
