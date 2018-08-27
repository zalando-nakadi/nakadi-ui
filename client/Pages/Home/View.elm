module Pages.Home.View exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Types exposing (AppHtml)
import Models exposing (AppModel)
import Helpers.Store exposing (Status(..))
import Helpers.UI as UI
import Routing.Models exposing (Route(..))
import Pages.EventTypeList.Models
import Pages.EventTypeDetails.Models
import Pages.SubscriptionList.Models
import Messages exposing (Msg(StarredEventTypesStoreMsg, StarredSubscriptionsStoreMsg))
import Helpers.StoreLocal exposing (Msg(Add, Remove))
import Helpers.String exposing (formatDateTime)
import Constants
import Config


view : AppModel -> AppHtml
view model =
    div []
        [ div [ class "dc-row", style [ ( "margin-bottom", "16px" ) ] ]
            [ div [ class "dc-column " ]
                [ div [ class "dc-card" ]
                    [ h4 [ class "dc-h4 dc--text-center" ]
                        [ text "Welcome to Nakadi, a distributed, open-source event messaging service!" ]
                    , p []
                        [ text "The goal of Nakadi is to enable convenient development of event-driven "
                        , text "applications and asynchronous microservices by allowing producers to "
                        , text "publish streams of event data to multiple consumers, without direct "
                        , text "integration. It does this by exposing an "
                        , UI.externalLink "HTTP API" (Config.urlManual ++ "#nakadi-event-bus-api")
                        , text " to let microservices "
                        , text "maintain their boundaries and not force a particular technology dependency "
                        , text "on producers and consumers. If you can speak HTTP, you can use Nakadi. "
                        , UI.externalLink " Learn More! >> " model.userStore.user.settings.docsUrl
                        ]
                    , div []
                        [ UI.externalLink "Service status: " model.userStore.user.settings.sloMonitoringUrl
                        , getStatus model
                        , text " | "
                        , text " API URL:"
                        , span [ class "help-code" ] [ text model.userStore.user.settings.nakadiApiUrl ]
                        , text " | "
                        , text "Event types: "
                        , span [ class "help-code" ]
                            [ text (model.eventTypeStore |> Helpers.Store.size |> toString) ]
                        , text " | "
                        , text "Subscriptions: "
                        , span [ class "help-code" ]
                            [ text (model.subscriptionStore |> Helpers.Store.size |> toString) ]
                        , text " | "
                        , UI.externalLink " Monitoring " model.userStore.user.settings.monitoringUrl
                        , text " | "
                        , UI.externalLink " Support " model.userStore.user.settings.supportUrl
                        ]
                    ]
                ]
            ]
        , div
            [ class "dc-row dc-row--align--justify dc-block-grid--small-1 dc-block-grid--medium-1 dc-block-grid--large-2" ]
            [ card "Starred Event Types: "
                (starredTypesList model)
            , card "Starred Subscriptions"
                (starredSubscriptions model)
            , card "Last updated Event Types: "
                [ ul [ class "home__list-with-date dc-list dc-list--is-scrollable" ]
                    (lastUpdatedTypes model)
                ]
            , card "Last updated Subscriptions: "
                [ ul [ class "home__list-with-date dc-list dc-list--is-scrollable" ]
                    (lastUpdatedSubscriptions model)
                ]
            ]
        ]


card : String -> List (Html msg) -> Html msg
card name content =
    div [ class "home-panel dc-column" ]
        [ div
            [ class "dc-card dc-column__content panel--expanded" ]
            [ b [] [ text name ]
            , br [] []
            , div [] content
            ]
        ]


starredTypesList : AppModel -> List (Html Messages.Msg)
starredTypesList model =
    let
        isEmpty =
            0 == Helpers.Store.size model.starredEventTypesStore

        row eventTypeName =
            li [ class "dc-list__item" ]
                [ Html.map StarredEventTypesStoreMsg <|
                    UI.starIcon Add
                        Remove
                        model.starredEventTypesStore
                        eventTypeName
                , UI.internalLink eventTypeName
                    (EventTypeDetailsRoute
                        { name = eventTypeName }
                        Pages.EventTypeDetails.Models.emptyQuery
                    )
                ]

        rows =
            model.starredEventTypesStore
                |> Helpers.Store.items
                |> List.map row
    in
        if isEmpty then
            [ text "No starred Events Types yet"
            , br [] []
            , UI.internalLink "Search for Event Types" <|
                EventTypeListRoute Pages.EventTypeList.Models.emptyQuery
            ]
        else
            [ ul [ class "home__list-with-star dc-list dc-list--is-scrollable" ]
                rows
            ]


starredSubscriptions : AppModel -> List (Html Messages.Msg)
starredSubscriptions model =
    let
        isEmpty =
            0 == Helpers.Store.size model.starredSubscriptionsStore

        row subscriptionId =
            li [ class "dc-list__item" ]
                [ Html.map StarredSubscriptionsStoreMsg <|
                    UI.starIcon Add
                        Remove
                        model.starredSubscriptionsStore
                        subscriptionId
                , UI.internalLink subscriptionId
                    (SubscriptionDetailsRoute
                        { id = subscriptionId }
                        { tab = Nothing }
                    )
                ]

        rows =
            model.starredSubscriptionsStore
                |> Helpers.Store.items
                |> List.map row
    in
        if isEmpty then
            [ text "No starred Subscriptions yet"
            , br [] []
            , UI.internalLink "Search for Subscription" <|
                SubscriptionListRoute Pages.SubscriptionList.Models.emptyQuery
            ]
        else
            [ ul [ class "home__list-with-star dc-list dc-list--is-scrollable" ]
                rows
            ]


lastUpdatedTypes : AppModel -> List (Html msg)
lastUpdatedTypes model =
    model.eventTypeStore
        |> Helpers.Store.items
        |> List.sortBy (\item -> item.updated_at |> Maybe.withDefault "")
        |> List.reverse
        |> List.take 10
        |> List.map
            (\eventType ->
                li [ class "dc-list__item" ]
                    [ UI.internalLink eventType.name
                        (EventTypeDetailsRoute
                            { name = eventType.name }
                            Pages.EventTypeDetails.Models.emptyQuery
                        )
                    , span [ class "panel--right-float", title (eventType.updated_at |> Maybe.withDefault Constants.emptyString) ]
                        [ text (eventType.updated_at |> Maybe.withDefault Constants.emptyString |> formatDateTime) ]
                    ]
            )


lastUpdatedSubscriptions : AppModel -> List (Html msg)
lastUpdatedSubscriptions model =
    model.subscriptionStore
        |> Helpers.Store.items
        |> List.sortBy .created_at
        |> List.reverse
        |> List.take 10
        |> List.map
            (\subscription ->
                li [ class "dc-list__item" ]
                    [ UI.internalLink subscription.id (SubscriptionDetailsRoute { id = subscription.id } { tab = Nothing })
                    , span [ class "panel--right-float", title subscription.created_at ]
                        [ text (formatDateTime subscription.created_at) ]
                    ]
            )


getStatus : AppModel -> Html msg
getStatus model =
    case model.eventTypeStore.status of
        Unknown ->
            span [ class "dc-status dc-status--inactive" ] [ text "Unknown" ]

        Loading ->
            span [ class "dc-status dc-status--new" ] [ text "Loading" ]

        Error ->
            span [ class "dc-status dc-status--error" ] [ text "Offline" ]

        Loaded ->
            span [ class "dc-status dc-status--active" ] [ text "Online" ]
