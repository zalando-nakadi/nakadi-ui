module Routing.Update exposing (makeCmdForNewRoute, update)

import Constants exposing (emptyString)
import Helpers.Task exposing (dispatch)
import Helpers.Http exposing (postString)
import Models exposing (AppModel)
import Routing.Helpers exposing (locationToRoute, routeToUrl)
import Routing.Messages exposing (Msg(..))
import Routing.Models exposing (Route, routeToTitle)


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
                    postString TitleChanged "elm:title" (routeToTitle route)
            in
            ( model, updateTitle )

        TitleChanged _ ->
            ( model, Cmd.none )


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
            postString (always (RouteChanged route)) "elm:pushState" (routeToUrl route)


        cmdReplaceHistory route =
            postString (always (RouteChanged route)) "elm:replaceState" (routeToUrl route)

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
