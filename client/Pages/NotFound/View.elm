module Pages.NotFound.View exposing (panelWithButton, view)

import Helpers.Panel exposing (page, panel)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Messages exposing (Msg(RoutingMsg))
import Models exposing (AppModel)
import Routing.Messages exposing (Msg(Redirect))
import Routing.Models exposing (Route(HomeRoute))
import Types exposing (AppHtml)


view : AppModel -> AppHtml
view model =
    page []
        [ panelWithButton
            4
            "404 Not found"
            [ text "Oops! Sorry, but the page you are looking for doesn't exist here." ]
            "Go to Home page"
            HomeRoute
        ]


panelWithButton : Int -> String -> List (Html Messages.Msg) -> String -> Route -> Html Messages.Msg
panelWithButton gridSize title desc btnText route =
    panel gridSize
        title
        [ p [] desc
        , div [ class "dc--text-center" ]
            [ button [ class "dc-btn dc-btn--primary dc--text-center", onClick (RoutingMsg (Redirect route)) ] [ text btnText ]
            ]
        ]
