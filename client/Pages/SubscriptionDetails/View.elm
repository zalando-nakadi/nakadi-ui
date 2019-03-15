module Pages.SubscriptionDetails.View exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import String.Extra exposing (replace)
import Models exposing (AppModel)
import Helpers.Store exposing (Id, Status(..), get)
import Helpers.Panel exposing (warningMessage)
import Helpers.UI
    exposing
        ( linkToApp
        , starIcon
        , helpIcon
        , grid
        , tabs
        , refreshButton
        , PopupPosition(..)
        , none
        )
import Helpers.Panel exposing (loadingStatus)
import Helpers.String exposing (formatDateTime, periodToShortString)
import Pages.SubscriptionDetails.Models exposing (Model, Tabs(..))
import Pages.SubscriptionDetails.Messages exposing (..)
import Pages.SubscriptionDetails.Help as Help
import Pages.SubscriptionList.Models
import Pages.EventTypeDetails.Models as EventTypeDetailPage
import Stores.Subscription exposing (Subscription)
import Stores.SubscriptionStats
import Stores.Partition
import Pages.Partition.Models
import Routing.Models exposing (routeToUrl, Route(..))
import Routing.Helpers exposing (internalLink)
import Config
import Constants
import Helpers.AccessEditor as AccessEditor


view : AppModel -> Html Msg
view model =
    let
        id =
            model.subscriptionDetailsPage.id

        foundList =
            Helpers.Store.get id model.subscriptionStore

        mainView =
            case foundList of
                Nothing ->
                    Helpers.Panel.errorMessage "Subscription not found" ("Subscription with this ID not found:" ++ id)

                Just subscription ->
                    detailsLayout
                        id
                        subscription
                        model
    in
        Helpers.Panel.loadingStatus model.subscriptionStore mainView


detailsLayout :
    Id
    -> Subscription
    -> AppModel
    -> Html Msg
detailsLayout id subscription model =
    let
        pageState =
            model.subscriptionDetailsPage

        starredStore =
            model.starredSubscriptionsStore

        appsInfoUrl =
            model.userStore.user.settings.appsInfoUrl

        usersInfoUrl =
            model.userStore.user.settings.usersInfoUrl

        tabOptions =
            { onChange = (\tab -> TabChange tab)
            , notSelectedView = Just (div [] [ text "No tab selected" ])
            , class = Just "dc-column"
            , containerClass = Nothing
            , tabClass = Nothing
            , activeTabClass = Nothing
            , pageClass = Nothing
            }
    in
        div []
            [ noAuthMessage subscription
            , div [ class "dc-card" ]
                [ div [ class "dc-row dc-row--collapse" ]
                    [ ul [ class "dc-breadcrumb" ]
                        [ li [ class "dc-breadcrumb__item" ]
                            [ internalLink "Subscriptions" (SubscriptionListRoute Pages.SubscriptionList.Models.emptyQuery)
                            ]
                        , li [ class "dc-breadcrumb__item" ]
                            [ span [] [ text id, helpIcon "Subscription" Help.subscription BottomRight ]
                            ]
                        ]
                    , span [ class "toolbar" ]
                        [ a
                            [ title "Update Subscription"
                            , class "icon-link dc-icon dc-icon--interactive"
                            , href <|
                                routeToUrl <|
                                    SubscriptionUpdateRoute { id = subscription.id }
                            ]
                            [ i [ class "far fa-edit" ] [] ]
                        , a
                            [ title "Clone Subscription"
                            , class "icon-link dc-icon dc-icon--interactive"
                            , href <|
                                routeToUrl <|
                                    SubscriptionCloneRoute { id = subscription.id }
                            ]
                            [ i [ class "far fa-clone" ] [] ]
                        , a
                            [ title "View as raw JSON"
                            , class "icon-link dc-icon dc-icon--interactive"
                            , target "_blank"
                            , href <| Config.urlNakadiApi ++ "subscriptions/" ++ subscription.id
                            ]
                            [ i [ class "far fa-file-code" ] [] ]
                        , a
                            [ title "Monitoring Graphs"
                            , class "icon-link dc-icon dc-icon--interactive"
                            , target "_blank"
                            , href <| replace "{id}" subscription.id model.userStore.user.settings.subscriptionMonitoringUrl
                            ]
                            [ i [ class "fas fa-chart-line" ] [] ]
                        , starIcon OutAddToFavorite OutRemoveFromFavorite starredStore id
                        , span
                            [ onClick OpenDeletePopup
                            , class "icon-link dc-icon--trash dc-btn--destroy dc-icon dc-icon--interactive"
                            , title "Delete Subscription"
                            ]
                            []
                        ]
                    , span [ class "flex-col--stretched" ] [ refreshButton OutRefreshSubscriptions ]
                    ]
                , div [ class "dc-row dc-row--collapse" ]
                    [ div [ class "dc-column dc-column--shrink" ]
                        [ div [ class "subscription-details__info-form" ]
                            [ infoField "Owning application " Help.owningApplication BottomRight <|
                                linkToApp appsInfoUrl subscription.owning_application
                            , infoField "Consumer group " Help.consumerGroup BottomRight <|
                                text subscription.consumer_group
                            , infoField "Read from " Help.readFrom BottomRight <|
                                text subscription.read_from
                            , infoField "Created " Help.createdAt TopRight <|
                                infoDateToText subscription.created_at
                            , infoField "Event types " Help.eventTypes TopRight <|
                                infoListToText subscription.event_types
                            ]
                        ]
                    , div [ class "dc-column" ]
                        [ tabs tabOptions
                            (Just pageState.tab)
                            [ ( StatsTab
                              , "Stats"
                              , statsPanel pageState
                              )
                            , ( AuthTab
                              , "Authorization"
                              , authTab
                                    appsInfoUrl
                                    usersInfoUrl
                                    subscription
                              )
                            ]
                        ]
                    ]
                , deletePopup model subscription appsInfoUrl
                ]
            ]


infoField : String -> List (Html Msg) -> PopupPosition -> Html Msg -> Html Msg
infoField name hint position content =
    div []
        [ label [ class "info-label" ]
            [ text name
            , helpIcon name hint position
            ]
        , div [ class "info-field" ] [ content ]
        ]


infoEmpty : Html Msg
infoEmpty =
    span [ class "info-field--no-value" ] [ text Constants.noneLabel ]


infoDateToText : String -> Html Msg
infoDateToText info =
    span [ title info ] [ text (formatDateTime info) ]


infoListToText : List String -> Html Msg
infoListToText info =
    if List.isEmpty info then
        infoEmpty
    else
        div [] <|
            List.map
                (\value ->
                    div [] [ linkToType value ]
                )
                info


linkToType : String -> Html Msg
linkToType name =
    a
        [ class "dc-link"
        , href <|
            routeToUrl
                (EventTypeDetailsRoute { name = name } EventTypeDetailPage.emptyQuery)
        ]
        [ text name ]


statsPanel : Model -> Html Msg
statsPanel model =
    let
        statsStore =
            model.statsStore

        list =
            Helpers.Store.items statsStore

        tableLayout =
            grid [ "Partition ID", "State", "Unconsumed", "Stream ID", "Committed Offset", "" ]
                (list
                    |> List.map (renderType model)
                    |> List.concat
                )
    in
        div [ class "dc-card panel--expanded" ]
            [ refreshButton Refresh
            , h3 [ class "dc-h3" ]
                [ text "Subscription stats"
                , helpIcon "Subscription stats" Help.subscriptionStats BottomRight
                ]
            , Helpers.Panel.loadingStatus statsStore tableLayout
            ]


renderType : Model -> Stores.SubscriptionStats.SubscriptionStats -> List (Html Msg)
renderType model stat =
    (tr [ class "dc-table__tr" ]
        [ td [ class "dc-table__td", colspan 5 ] [ linkToType stat.event_type ]
        ]
    )
        :: (stat.partitions
                |> Stores.Partition.sortPartitionsList
                |> List.map (renderPartition model stat.event_type)
           )


renderPartition : Model -> String -> Stores.SubscriptionStats.SubscriptionStatsPartition -> Html Msg
renderPartition model eventTypeName partition =
    let
        lag =
            case partition.consumer_lag_seconds of
                Nothing ->
                    "-"

                Just lag ->
                    if lag == 0 then
                        if (partition.unconsumed_events |> Maybe.withDefault 0) == 0 then
                            ""
                        else
                            " (<1s)"
                    else
                        " (" ++ periodToShortString (lag * 1000) ++ ")"

        events =
            case partition.unconsumed_events of
                Just events ->
                    toString events ++ lag

                Nothing ->
                    "-"

        partitionKey =
            (eventTypeName ++ "#" ++ partition.partition)

        offset =
            model.cursorsStore
                |> get partitionKey
                |> Maybe.map .offset
                |> Maybe.withDefault "-"

        linkToPartition partitionId =
            a
                [ href <|
                    routeToUrl
                        (PartitionRoute
                            { name = eventTypeName
                            , partition = partitionId
                            }
                            Pages.Partition.Models.emptyQuery
                        )
                , class "dc-link"
                ]
                [ text " Inspect events" ]

        offsetEditor =
            if model.editOffsetInput.editPartition == Just partitionKey then
                Helpers.Panel.submitStatus model.editOffsetInput <|
                    div []
                        [ input
                            [ id "subscriptionEditOffset"
                            , class "dc-input dc-input--small"
                            , value model.editOffsetInput.editPartitionValue
                            , onInput EditOffsetChange
                            , Helpers.UI.onKeyDown OffsetKeyDown
                            ]
                            []
                        , div []
                            [ button [ class "dc-btn dc-btn--primary dc-btn--small", onClick EditOffsetSubmit ] [ text "Set offset" ]
                            , text " "
                            , button [ class "dc-btn dc-btn--small", onClick EditOffsetCancel ] [ text "Cancel" ]
                            ]
                        ]
            else
                span []
                    [ span [] [ text offset, text " " ]
                    , a [ onClick (EditOffset partitionKey offset), class "dc-link", href "javascript:undefined" ]
                        [ text "Change" ]
                    ]
    in
        tr [ class "dc-table__tr" ]
            [ td [ class "dc-table__td" ]
                [ text partition.partition ]
            , td
                [ class "dc-table__td" ]
                [ text (partition.state ++ " " ++ (partition.assignment_type |> Maybe.withDefault "")) ]
            , td
                [ class "dc-table__td" ]
                [ text events ]
            , td
                [ class "dc-table__td" ]
                [ text (partition.stream_id |> Maybe.withDefault "-") ]
            , td
                [ class "dc-table__td" ]
                [ offsetEditor ]
            , td [ class "dc-table__td" ]
                [ linkToPartition partition.partition ]
            ]


deletePopup :
    AppModel
    -> Subscription
    -> String
    -> Html Msg
deletePopup model subscription appsInfoUrl =
    let
        deleteButton =
            if model.subscriptionDetailsPage.deletePopup.deleteCheckbox then
                button
                    [ onClick Delete
                    , class "dc-btn dc-btn--destroy"
                    ]
                    [ text "Delete Subscription" ]
            else
                button [ disabled True, class "dc-btn dc-btn--disabled" ]
                    [ text "Delete Subscription" ]

        dialog =
            div []
                [ div [ class "dc-overlay" ] []
                , div [ class "dc-dialog" ]
                    [ div [ class "dc-dialog__content", style [ ( "min-width", "600px" ) ] ]
                        [ div [ class "dc-dialog__body" ]
                            [ div [ class "dc-dialog__close" ]
                                [ i
                                    [ onClick CloseDeletePopup
                                    , class "dc-icon dc-icon--close dc-icon--interactive dc-dialog__close__icon"
                                    ]
                                    []
                                ]
                            , h3 [ class "dc-dialog__title" ]
                                [ text "Delete Subscription" ]
                            , div [ class "dc-msg dc-msg--error" ]
                                [ div [ class "dc-msg__inner" ]
                                    [ div [ class "dc-msg__icon-frame" ]
                                        [ i [ class "dc-icon dc-msg__icon dc-icon--warning" ] []
                                        ]
                                    , div [ class "dc-msg__bd" ]
                                        [ h1 [ class "dc-msg__title blinking" ] [ text "Warning! Dangerous Action!" ]
                                        , p [ class "dc-msg__text" ]
                                            [ text "You are about to completely delete this subscription."
                                            , text " This action cannot be undone."
                                            ]
                                        ]
                                    ]
                                ]
                            , h1 [ class "dc-h1 dc--is-important" ] [ text subscription.id ]
                            , p [ class "dc-p" ] [ text "Owned by: ", linkToApp appsInfoUrl subscription.owning_application ]
                            , p [ class "dc-p" ] [ text "Consumer group: ", b [] [ text subscription.consumer_group ] ]
                            , p [ class "dc-p" ]
                                [ text "Think twice, notify all consumers."
                                , text " The information about last consumed offsets will be lost."
                                ]
                            , none |> loadingStatus model.subscriptionDetailsPage.deletePopup
                            ]
                        , div [ class "dc-dialog__actions" ]
                            [ input
                                [ onClick ConfirmDelete
                                , type_ "checkbox"
                                , class "dc-checkbox"
                                , id "confirmDeleteSubscription"
                                , checked model.subscriptionDetailsPage.deletePopup.deleteCheckbox
                                ]
                                []
                            , label
                                [ for "confirmDeleteSubscription", class "dc-label" ]
                                [ text "Yes, delete "
                                , b [] [ text subscription.id ]
                                ]
                            , deleteButton
                            ]
                        ]
                    ]
                ]
    in
        if model.subscriptionDetailsPage.deletePopup.isOpen then
            dialog
        else
            none


authTab : String -> String -> Subscription -> Html Msg
authTab appsInfoUrl usersInfoUrl subscription =
    div [ class "dc-card auth-tab" ] <|
        case subscription.authorization of
            Nothing ->
                [ noAuthMessage subscription
                ]

            Just authorization ->
                [ div [ class "auth-tab__content" ]
                    [ AccessEditor.viewReadOnly
                        { appsInfoUrl = appsInfoUrl
                        , usersInfoUrl = usersInfoUrl
                        , showWrite = False
                        , showAnyToken = True
                        , help = Help.authorization
                        }
                        (always Refresh)
                        authorization
                    ]
                ]


noAuthMessage : Subscription -> Html Msg
noAuthMessage subscription =
    let
        updateLink =
            internalLink "update subscription" (SubscriptionUpdateRoute { id = subscription.id })
    in
        if subscription.authorization == Nothing then
            warningMessage
                "This Subscription is NOT protected!"
                "It is open for modification, and statistics reading by everyone in the company."
                (Just updateLink)
        else
            none
