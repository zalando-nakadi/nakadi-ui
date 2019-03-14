module Main exposing (init, locationToMessage, main, subs)

import Helpers.Task exposing (dispatch)
import Messages exposing (Msg(..))
import Models
import Navigation
import Routing.Helpers exposing (locationToRoute)
import Routing.Messages exposing (Msg(..))
import Update
import User.Messages exposing (Msg(..))
import View


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
