module View exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Routing.View exposing (view)
import Types exposing (AppHtml)
import Models exposing (AppModel)
import Helpers.Header exposing (navHeader)
import User.View

view : AppModel -> AppHtml
view model =
    User.View.requireAuth model mainLayout


mainLayout : AppModel -> AppHtml
mainLayout model =
    div [ class "app no-touch dc-page" ]
        [ navHeader model
        , section [class "dc-container"]
            [ Routing.View.view model
            ]
        ]

