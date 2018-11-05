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
import Helpers.JsonPrettyPrint exposing (prettyPrintJson)
import RemoteData exposing (WebData, isLoading)
import Http
import Json.Decode
import Config
import Result


queryTab : Model -> Html Msg
queryTab pageState =
    div [ class "dc-card" ]
        [ showRemoteDataStatus
            pageState.loadQueryResponse
          <|
            (\query ->
                div []
                    [ h3 [ class "dc-h3" ] [ text query.status ]
                    , pre [ class "sql-box" ] [ text query.sql ]
                    ]
            )
        ]


loadQuery : (WebData Query -> msg) -> String -> Cmd msg
loadQuery tagger id =
    Http.get (Config.urlNakadiSqlApi ++ "queries/" ++ (Http.encodeUri id)) queryDecoder
        |> RemoteData.sendRequest
        |> Cmd.map tagger


showRemoteDataStatus : WebData Query -> (Query -> Html Msg) -> Html Msg
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
