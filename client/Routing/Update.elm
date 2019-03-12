module Routing.Update exposing (makeCmdForNewRoute, setTitle, update)

import Constants exposing (emptyString)
import Helpers.Browser as Browser
import Helpers.Task exposing (dispatch)
import Http
import Json.Decode
import Models exposing (AppModel)
import Routing.Helpers exposing (locationToRoute, routeToUrl)
import Routing.Messages exposing (Msg(..))
import Routing.Models exposing (Route, routeToTitle)
import Task


setTitle : (Result Http.Error String -> Msg) -> String -> Cmd Msg
setTitle tagger str =
    Http.post "elm:title" (Http.stringBody "" str) Json.Decode.string
        |> Http.send tagger


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
                    setTitle TitleChanged (routeToTitle route)
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
