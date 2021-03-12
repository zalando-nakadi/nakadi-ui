module Pages.QueryDetails.View exposing (view)

--import Pages.QueryList.Models

import Config
import Constants
import Helpers.AccessEditor as AccessEditor
import Helpers.Panel exposing (loadingStatus, renderError, warningMessage)
import Helpers.Store as Store exposing (Id, Status(..), errorToViewRecord)
import Helpers.String exposing (boolToString, formatDateTime, periodToString, pluralCount)
import Helpers.UI exposing (PopupPosition(..), externalLink, grid, helpIcon, linkToApp, linkToAppOrUser, none, onChange, popup, refreshButton, starIcon, tabs)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Models exposing (AppModel)
import Pages.QueryDetails.Help as Help
import Pages.QueryDetails.Messages exposing (..)
import Pages.QueryDetails.Models exposing (Model, Tabs(..))
import RemoteData exposing (WebData)
import Routing.Helpers exposing (internalLink)
import Routing.Models exposing (Route(..), routeToUrl)
import Stores.Query exposing (Query)
import String exposing (replace)
import Url exposing (percentEncode)


view : AppModel -> Html Msg
view model =
    let
        id =
            model.queryDetailsPage.id

        list =
            Store.items model.queryStore

        foundList =
            Store.get id model.queryStore

        mainView =
            case foundList of
                Nothing ->
                    Helpers.Panel.errorMessage "SQL Query not found" ("SQL Query with this id not found:" ++ id)

                Just query ->
                    detailsLayout
                        id
                        query
                        model
    in
    Helpers.Panel.loadingStatus model.queryStore mainView


detailsLayout : Id -> Query -> AppModel -> Html Msg
detailsLayout queryId query model =
    let
        pageState =
            model.queryDetailsPage

        deleteQueryButton =
            span
                [ onClick OpenDeleteQueryPopup
                , class "icon-link dc-icon--trash dc-btn--destroy dc-icon dc-icon--interactive"
                , title "Delete SQL Query"
                ]
                []

        settings =
            model.userStore.user.settings

        appsInfoUrl =
            settings.appsInfoUrl

        usersInfoUrl =
            settings.usersInfoUrl

        monitoringLink =
            replace "{query}" queryId settings.queryMonitoringUrl

        tab =
            pageState.tab

        tabOptions =
            { onChange = \aTab -> TabChange aTab
            , notSelectedView = Just (div [] [ text "No tab selected" ])
            , class = Just "dc-column"
            , containerClass = Nothing
            , tabClass = Nothing
            , activeTabClass = Nothing
            , pageClass = Nothing
            }
    in
    div []
        [ div [ class "dc-card" ]
            [ div [ class "dc-row dc-row--collapse" ]
                [ ul [ class "dc-breadcrumb" ]
                    [ li [ class "dc-breadcrumb__item" ]
                        [ text "SQL Queries"

                        -- internalLink "SQL Queries" (EventTypeListRoute Pages.EventTypeList.Models.emptyQuery)
                        ]
                    , li [ class "dc-breadcrumb__item" ]
                        [ span [] [ text queryId, helpIcon "SQL Query id" Help.query BottomRight ]
                        ]
                    ]
                , span [ class "toolbar" ]
                    [ -- a
                      --    [ title "Update SQL Query"
                      --    , class "icon-link dc-icon dc-icon--interactive"
                      --    , href <|
                      --        routeToUrl <|
                      --            EventTypeUpdateRoute { id = query.id }
                      --    ]
                      --    [ i [ class "icon icon--edit" ] [] ]
                      --,
                      a
                        [ title "View as raw JSON"
                        , class "icon-link dc-icon dc-icon--interactive"
                        , target "_blank"
                        , href <| Config.urlNakadiSqlApi ++ "queries/" ++ query.id
                        ]
                        [ i [ class "icon icon--source" ] [] ]
                    , a
                        [ title "Monitoring Graphs"
                        , class "icon-link dc-icon dc-icon--interactive"
                        , target "_blank"
                        , href <| monitoringLink
                        ]
                        [ i [ class "icon icon--chart" ] [] ]
                    , button
                        [ onClick (CopyToClipboard query.sql)
                        , class "icon-link dc-icon dc-icon--interactive"
                        , title "Copy To Clipboard"
                        ]
                        [ i [ class "icon icon--clipboard" ] [] ]

                    --, starIcon OutAddToFavorite OutRemoveFromFavorite model.starredEventTypesStore eventType.name

                    , deleteQueryButton
                    ]

                --, span [ class "flex-col--stretched" ] [ refreshButton OutRefreshEventTypes ]
                ]
            , div [ class "dc-row dc-row--collapse" ]
                [ div [ class "dc-column dc-column--shrink" ]
                    [ div [ class "query-details__info-form" ]
                        [ infoField "Envelope " Help.envelope BottomRight <|
                            text (boolToString query.envelope)
                        , infoField "Created " Help.createdAt BottomRight <|
                            infoDateToText query.created
                        , infoField "Updated " Help.updatedAt BottomRight <|
                            infoDateToText query.updated
                        ]
                    ]
                , tabs tabOptions (Just tab) <|
                    [ ( QueryTab
                      , "SQL Query"
                      , queryTab
                            settings.queryMonitoringUrl
                                pageState
                                    query
                      )
                    , ( AuthTab
                      , "Authorization"
                      , authTab
                            appsInfoUrl
                            usersInfoUrl
                            query
                      )
                    ]
                ]
            ]
        ]


infoField : String -> List (Html msg) -> PopupPosition -> Html msg -> Html msg
infoField name hint position content =
    div []
        [ label [ class "info-label" ]
            [ text name
            , helpIcon name hint position
            ]
        , div [ class "info-field" ] [ content ]
        ]


infoSubField : String -> String -> Html msg
infoSubField name content =
    div []
        [ label [ class "info-label" ] [ text name ]
        , span [ class "info-field" ] [ text content ]
        ]


infoEmpty : Html msg
infoEmpty =
    span [ class "info-field--no-value" ] [ text Constants.noneLabel ]


infoDateToText : String -> Html msg
infoDateToText info =
    span [ title info ] [ text (formatDateTime info) ]


infoListToText : Maybe (List String) -> Html msg
infoListToText maybeInfo =
    case maybeInfo of
        Just info ->
            if List.isEmpty info then
                infoEmpty

            else
                div [] <| List.map (\value -> div [] [ text value ]) info

        Nothing ->
            infoEmpty


infoAnyToText : Maybe a -> Html msg
infoAnyToText maybeInfo =
    case maybeInfo of
        Just info ->
            text (Debug.toString info)

        Nothing ->
            infoEmpty


queryTab : String -> Model -> Query -> Html Msg
queryTab monitoringUrl model query =
    div [ class "dc-card" ]
        [ --showRemoteDataStatus
          --pageState.loadQueryResponse
          --   (queryTabHeader setting pageState)
          div []
            [ span [] [ text "SQL Query" ]
            , helpIcon "Nakadi SQL" Help.sqlQuery BottomRight
            , label [ class "query-tab__label" ] [ text " Status: " ]
            , span [ class "query-tab__value dc-status dc-status--active" ] [ text query.status ]
            , sqlView query.sql
            , deleteQueryPopup model query
            ]
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


authTab : String -> String -> Query -> Html Msg
authTab appsInfoUrl usersInfoUrl query =
    case query.authorization of
        Nothing ->
            div [ class "dc-card auth-tab" ]
                [ warningMessage
                    "This SQL Query is NOT protected!"
                    "It is open for modification, publication, and consumption by everyone in the company."
                    Nothing
                ]

        Just authorization ->
            div [ class "dc-card auth-tab" ]
                [ div [ class "auth-tab__content" ]
                    [ AccessEditor.viewReadOnly
                        { appsInfoUrl = appsInfoUrl
                        , usersInfoUrl = usersInfoUrl
                        , showWrite = True
                        , showAnyToken = True
                        , help = Help.authorization
                        }
                        (always Reload)
                        authorization
                    ]
                ]


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
                    [ div [ class "dc-dialog__content", style "min-width" "600px" ]
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
