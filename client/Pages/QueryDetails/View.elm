module Pages.QueryDetails.View exposing (view)

--import Pages.EventTypeDetails.Help as Help
--import Pages.QueryList.Models

import Config
import Constants
import Helpers.AccessEditor as AccessEditor
import Helpers.Panel exposing (loadingStatus, warningMessage)
import Helpers.Store as Store exposing (Id, Status(..))
import Helpers.String exposing (formatDateTime, periodToString, pluralCount)
import Helpers.UI exposing (PopupPosition(..), externalLink, grid, helpIcon, linkToApp, linkToAppOrUser, none, onChange, popup, refreshButton, starIcon, tabs)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Models exposing (AppModel)
import Pages.QueryDetails.Help as Help
import Pages.QueryDetails.Messages exposing (..)
import Pages.QueryDetails.Models exposing (Model, Tabs(..))
import Pages.QueryDetails.QueryTab exposing (queryTab)
import RemoteData exposing (isSuccess)
import Routing.Helpers exposing (internalLink)
import Routing.Models exposing (Route(..), routeToUrl)
import Stores.Query exposing (Query)
import String exposing (replace)


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

        -- deleteQueryButton =
        --     span
        --         [ onClick OpenDeletePopup
        --         , class "icon-link dc-icon--trash dc-btn--destroy dc-icon dc-icon--interactive"
        --         , title "Delete SQL Query"
        --         ]
        --         []

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
                    [
                     -- a
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
                    --, starIcon OutAddToFavorite OutRemoveFromFavorite model.starredEventTypesStore eventType.name
                    --, deleteQueryButton
                    ]
                --, span [ class "flex-col--stretched" ] [ refreshButton OutRefreshEventTypes ]
                ]
            , div [ class "dc-row dc-row--collapse" ]
                [ div [ class "dc-column dc-column--shrink" ]
                    [ div [ class "event-type-details__info-form" ]
                        [ infoField "Created " Help.createdAt TopRight <|
                            infoDateToText query.created
                        , infoField "Updated " Help.updatedAt TopRight <|
                            infoDateToText query.updated
                        ]
                    ]
                , tabs tabOptions (Just tab) <|
                    [ ( QueryTab
                      , "SQL Query"
                      , queryTab settings pageState
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
            -- , deletePopup model
            --     eventType
            --     pageState.consumersStore
            --     model.subscriptionStore
            --     pageState.consumingQueriesStore
            --     appsInfoUrl
            --     usersInfoUrl
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


infoStringToText : Maybe String -> Html msg
infoStringToText maybeInfo =
    case maybeInfo of
        Just info ->
            text info

        Nothing ->
            infoEmpty


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
