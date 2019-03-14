module View exposing (mainLayout, view)

import Helpers.Header exposing (navHeader)
import Html exposing (..)
import Html.Attributes exposing (..)
import Models exposing (AppModel)
import Routing.View
import Types exposing (AppHtml)
import User.View


view : AppModel -> AppHtml
view model =
    User.View.requireAuth model mainLayout


mainLayout : AppModel -> AppHtml
mainLayout model =
    div [ class "app no-touch dc-page" ]
        [ navHeader model
        , section [ class "dc-container" ]
            [ Routing.View.view model
            ]
        ]
