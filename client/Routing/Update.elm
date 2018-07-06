port module Routing.Update exposing (..)

import Models exposing (AppModel)
import Routing.Messages exposing (Msg(..))
import Routing.Helpers exposing (routeToUrl, locationToRoute)
import Routing.Models exposing (Route, routeToTitle)
import Helpers.Task exposing (dispatch)
import Helpers.Browser as Browser
import Task
import Constants exposing (emptyString)


port title : String -> Cmd a


update : Msg -> AppModel -> ( AppModel, Cmd Msg )
update message model =
    case message of
        Redirect route ->
            ( { model | newRoute = route }, Cmd.none )

        SetLocation route ->
            let
                cmd =
                    makeCmdForNewRoute model.route route
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
            let
                updateTitle =
                    title (routeToTitle route)
            in
                ( model, updateTitle )


makeCmdForNewRoute : Route -> Route -> Cmd Msg
makeCmdForNewRoute oldRoute newRoute =
    let
        extractPath route =
            route
                |> routeToUrl
                |> String.split "?"
                |> List.head
                |> Maybe.withDefault emptyString

        cmdPushHistory route =
            toCmd Browser.pushState route

        cmdReplaceHistory route =
            toCmd Browser.replaceState route

        toCmd task route =
            task (routeToUrl route)
                |> Task.perform (always (RouteChanged route))

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
