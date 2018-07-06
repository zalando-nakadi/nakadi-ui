module Main exposing (..)

import Navigation
import Models
import Update
import View
import Routing.Messages exposing (Msg(..))
import Routing.Helpers exposing (locationToRoute)
import Messages exposing (Msg(..))
import User.Messages exposing (Msg(..))
import Helpers.Task exposing (dispatch)


main : Program Never Models.AppModel Messages.Msg
main =
    Navigation.program locationToMessage
        { init = init
        , view = View.view
        , update = Update.update
        , subscriptions = subs
        }


locationToMessage : Navigation.Location -> Messages.Msg
locationToMessage location =
    RoutingMsg (OnLocationChange location)


init : Navigation.Location -> ( Models.AppModel, Cmd Messages.Msg )
init location =
    let
        model =
            Models.initialModel

        loadUser =
            dispatch (UserMsg FetchData)

        initRoute =
            locationToRoute location
    in
        ( { model | newRoute = initRoute, route = initRoute }, loadUser )


subs : Models.AppModel -> Sub Messages.Msg
subs model =
    Sub.none
