module View exposing (mainLayout, view)

import Browser exposing (Document)
import Helpers.Header exposing (navHeader)
import Html exposing (..)
import Html.Attributes exposing (..)
import Messages exposing (Msg)
import Models exposing (AppModel)
import Routing.Models exposing (routeToTitle)
import Routing.View
import Types exposing (AppHtml)
import User.View


view : AppModel -> Document Msg
view model =
    { title = model.route |> routeToTitle
    , body = [ User.View.requireAuth model mainLayout ]
    }


mainLayout : AppModel -> AppHtml
mainLayout model =
    div [ class "app no-touch dc-page" ]
        [ navHeader model
        , section [ class "dc-container" ]
            [ Routing.View.view model
            ]
        ]
