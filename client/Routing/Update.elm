module Routing.Update exposing (makeCmdForNewRoute, update)

import Browser exposing (UrlRequest(..))
import Browser.Navigation as Nav exposing (Key)
import Constants exposing (emptyString)
import Helpers.Task exposing (dispatch)
import Models exposing (AppModel)
import Routing.Helpers exposing (locationToRoute, routeToUrl)
import Routing.Messages exposing (Msg(..))
import Routing.Models exposing (Route)
import Url


update : Msg -> AppModel -> ( AppModel, Cmd Msg )
update message model =
    case message of
        UrlChangeRequested request ->
            case request of
                Internal url ->
                    ( model
                    , Nav.pushUrl model.routerKey (Url.toString url)
                    )

                External url ->
                    ( model
                    , Nav.load url
                    )

        Redirect route ->
            ( { model | newRoute = route }, Cmd.none )

        SetLocation route ->
            let
                cmd =
                    makeCmdForNewRoute model.routerKey model.route route
            in
            ( { model | route = route }, cmd )

        OnLocationChange location ->
            let
                realUrlRoute =
                    locationToRoute location

                changeRoute =
                    if realUrlRoute == model.route then
                        Cmd.none

                    else
                        dispatch (RouteChanged realUrlRoute)
            in
            ( { model | route = realUrlRoute, newRoute = realUrlRoute }
            , changeRoute
            )

        RouteChanged route ->
            ( model, Cmd.none )


makeCmdForNewRoute : Key -> Route -> Route -> Cmd Msg
makeCmdForNewRoute routerKey oldRoute newRoute =
    let
        extractPath route =
            route
                |> routeToUrl
                |> String.split "?"
                |> List.head
                |> Maybe.withDefault emptyString

        cmdPushHistory route =
            Nav.pushUrl routerKey (routeToUrl route)

        cmdReplaceHistory route =
            Nav.replaceUrl routerKey (routeToUrl route)

        oldPath =
            extractPath oldRoute

        newPath =
            extractPath newRoute
    in
    if oldRoute == newRoute then
        Cmd.none

    else if oldPath == newPath then
        cmdReplaceHistory newRoute

    else
        cmdPushHistory newRoute
