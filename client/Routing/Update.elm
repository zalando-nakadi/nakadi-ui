module Routing.Update exposing (makeCmdForNewRoute, update)

import Browser exposing (UrlRequest(..))
import Browser.Navigation as Nav exposing (Key)
import Config
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
                Internal location ->
                    let
                        -- Checking pseudo-external urls (like /api/*, /auth/*, etc)
                        cmd =
                            if location.path == Config.urlBase then
                                location
                                    |> locationToRoute
                                    |> Redirect
                                    |> dispatch

                            else
                                location
                                    |> Url.toString
                                    |> External
                                    |> UrlChangeRequested
                                    |> dispatch
                    in
                    ( model, cmd )

                External url ->
                    ( model, Nav.load url )

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
            in
            ( { model | route = realUrlRoute, newRoute = realUrlRoute }
            , dispatch (OutRouteChanged realUrlRoute)
            )

        OutRouteChanged route ->
            ( model, Cmd.none )


makeCmdForNewRoute : Maybe Key -> Route -> Route -> Cmd Msg
makeCmdForNewRoute routerKey oldRoute newRoute =
    let
        extractPath route =
            route
                |> routeToUrl
                |> String.split "?"
                |> List.head
                |> Maybe.withDefault emptyString

        cmdPushHistory route =
            case routerKey of
                Just key ->
                    Nav.pushUrl key (routeToUrl route)

                Nothing ->
                    Cmd.none

        cmdReplaceHistory route =
            case routerKey of
                Just key ->
                    Nav.replaceUrl key (routeToUrl route)

                Nothing ->
                    Cmd.none

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
