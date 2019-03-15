module Main exposing (init, locationToMessage, main, subs)

import Browser
import Browser.Navigation exposing (Key)
import Helpers.Task exposing (dispatch)
import Json.Decode exposing (Value)
import Messages exposing (Msg(..))
import Models
import Routing.Helpers exposing (locationToRoute)
import Routing.Messages exposing (Msg(..))
import Update
import Url exposing (Url)
import User.Messages exposing (Msg(..))
import View


main : Program Value Models.AppModel Messages.Msg
main =
    Browser.application
        { init = init
        , view = View.view
        , update = Update.update
        , subscriptions = subs
        , onUrlRequest = \request -> RoutingMsg (UrlChangeRequested request)
        , onUrlChange = locationToMessage
        }


locationToMessage : Url -> Messages.Msg
locationToMessage location =
    RoutingMsg (OnLocationChange location)


init : Value -> Url -> Key -> ( Models.AppModel, Cmd Messages.Msg )
init flags location key =
    let
        model =
            Models.initialModel key

        loadUser =
            dispatch (UserMsg FetchData)

        initRoute =
            locationToRoute location
    in
    ( { model | newRoute = initRoute, route = initRoute }, loadUser )


subs : Models.AppModel -> Sub Messages.Msg
subs model =
    Sub.none
