module Helpers.Header exposing (buttonCreate, logo, navHeader, navLinks, rightPanel, tab)

import Helpers.UI as UI
import Html exposing (..)
import Html.Attributes exposing (..)
import Messages exposing (..)
import Models exposing (AppModel)
import MultiSearch.Update
import MultiSearch.View
import Pages.EventTypeList.Models
import Pages.SubscriptionList.Models
import Routing.Helpers exposing (internalHtmlLink, internalLink)
import Routing.Models exposing (..)
import Types exposing (AppHtml)
import User.View


navHeader : AppModel -> AppHtml
navHeader model =
    header [ class "header" ]
        (navLinks model ++ rightPanel model)


logo : AppHtml
logo =
    div [ class "header__link" ]
        [ internalHtmlLink HomeRoute
            [ div [ class "header__logo" ] [] ]
        ]


navLinks : AppModel -> List AppHtml
navLinks model =
    [ div [ class "header__panel--menu" ]
        [ logo
        , tab (EventTypeListRoute Pages.EventTypeList.Models.emptyQuery) "Event Types"
        , tab (SubscriptionListRoute Pages.SubscriptionList.Models.emptyQuery) "Subscriptions"
        , span [ class "header__link" ]
            [ UI.externalLink "Documentation" model.userStore.user.settings.docsUrl ]
        , buttonCreate model.userStore.user.settings.showNakadiSql
        ]
    ]


tab : Route -> String -> AppHtml
tab route name =
    span [ class "header__link" ]
        [ internalLink name route ]


rightPanel : AppModel -> List AppHtml
rightPanel model =
    [ div
        [ class "header__panel--right dc-row--align--middle" ]
        [ Html.map MultiSearchMsg <|
            MultiSearch.View.view (MultiSearch.Update.defaultConfig model) model.multiSearch
        , User.View.userMenu model
        ]
    ]


buttonCreate : Bool -> AppHtml
buttonCreate showNakadiSql =
    let
        className =
            if showNakadiSql then
                "show-sql-feature dropdown-menu"

            else
                "dropdown-menu"
    in
    div [ class className ]
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
            , if showNakadiSql then
                a
                    [ class "dropdown-menu__item dc-link"
                    , href (routeToUrl QueryCreateRoute)
                    ]
                    [ text "SQL Query" ]

              else
                UI.none
            , a
                [ class "dropdown-menu__item dc-link"
                , href (routeToUrl SubscriptionCreateRoute)
                ]
                [ text "Subscription" ]
            ]
        ]
