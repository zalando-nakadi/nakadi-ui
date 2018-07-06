module Helpers.Header exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Messages exposing (..)
import Types exposing (AppHtml)
import Models exposing (AppModel)
import User.View
import Routing.Models exposing (..)
import MultiSearch.View
import Pages.EventTypeList.Models
import Pages.SubscriptionList.Models
import Helpers.UI as UI
import MultiSearch.Update


navHeader : AppModel -> AppHtml
navHeader model =
    header [ class "header" ]
        ((navLinks model) ++ (rightPanel model))


logo : AppHtml
logo =
    div [ class "header__link" ]
        [ UI.internalHtmlLink HomeRoute
            [ div [ class "header__logo" ] [] ]
        ]


navLinks : AppModel -> List (AppHtml)
navLinks model =
    [ div [ class "header__panel--menu" ]
        [ logo
        , tab (EventTypeListRoute Pages.EventTypeList.Models.emptyQuery) "Event Types"
        , tab (SubscriptionListRoute Pages.SubscriptionList.Models.emptyQuery) "Subscriptions"
        , span [ class "header__link" ]
            [ UI.externalLink "Documentation" model.userStore.user.settings.docsUrl ]
        , buttonCreate
        ]
    ]


tab : Route -> String -> AppHtml
tab route name =
    span [ class "header__link" ]
        [ UI.internalLink name route ]


rightPanel : AppModel -> List (AppHtml)
rightPanel model =
    [ div
        [ class "header__panel--right dc-row--align--middle" ]
        [ Html.map MultiSearchMsg <|
            MultiSearch.View.view (MultiSearch.Update.defaultConfig model) model.multiSearch
        , User.View.userMenu model
        ]
    ]


buttonCreate : AppHtml
buttonCreate =
    div [ class "dropdown-menu" ]
        [ button [ class "dc-btn dc-btn--primary" ]
            [ text "Create"
            , span [ class "dc-btn-dropdown__arrow dc-btn-dropdown__arrow--down" ] []
            ]
        , div [ class "dropdown-menu__popup" ]
            [ a
                [ class "dropdown-menu__item dc-link"
                , href (routeToUrl EventTypeCreateRoute)
                ]
                [ text "Event Type" ]
            , a
                [ class "dropdown-menu__item dc-link"
                , href (routeToUrl SubscriptionCreateRoute)
                ]
                [ text "Subscription" ]
            ]
        ]
