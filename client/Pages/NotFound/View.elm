module Pages.NotFound.View exposing (..)

import Models exposing (AppModel)
import Types exposing (AppHtml)
import Helpers.Panel exposing (page, panelWithButton)
import Html exposing (text, Html)
import Routing.Models exposing (Route(HomeRoute))



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
