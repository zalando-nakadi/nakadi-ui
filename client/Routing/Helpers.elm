module Routing.Helpers exposing (..)

import Navigation
import Routing.Models
    exposing
        ( routingConfig
        , routeToUrl
        , Route(NotFoundRoute)
        , PageLoader
        , ParsedUrl
        , RouteConfig
        )
import Navigation exposing (Location)
import Helpers.String exposing (parseUrl)
import Dict
import Html exposing (Html, a, text)
import Html.Attributes exposing (href, class)


routeToUrl : Route -> String
routeToUrl =
    Routing.Models.routeToUrl


{-| Create Html link to internal page using Route type
-}
link : Route -> String -> Html msg
link route name =
    a
        [ href (routeToUrl route)
        , class "dc-link"
        ]
        [ text name ]


locationToRoute : Location -> Route
locationToRoute location =
    let
        parsedUrl =
            location.hash
                --drop #
                |>
                    String.dropLeft 1
                |> parseUrl
    in
        routingConfig
            |> List.filterMap (testRoute parsedUrl)
            |> List.head
            |> Maybe.withDefault NotFoundRoute


{-| Match the parsed url against the url template and maybe return Constructed route type.
   Example:
       testRoute (["types","sales-event"],{"formatted":"true"} ) ("types/:name", makeRoute)
   Returns:
       Just EventTypesDetailsRoute {name: "sales-event"} {formatted: Just True, }
-}
testRoute : ParsedUrl -> RouteConfig -> Maybe Route
testRoute ( path, query ) ( pattern, toRoute ) =
    let
        -- Folds the template path to true/false collecting params on the way
        isMatch templateFolder result =
            let
                fullStop =
                    { match = False, params = Dict.empty, rest = [] }

                next =
                    { result | rest = (List.drop 1 result.rest) }

                key =
                    (String.dropLeft 1 templateFolder)
            in
                case List.head result.rest of
                    Just folderName ->
                        if templateFolder |> String.startsWith ":" then
                            { next
                                | params = Dict.insert key folderName result.params
                            }
                        else if folderName == templateFolder then
                            next
                        else
                            fullStop

                    Nothing ->
                        fullStop

        result =
            pattern
                |> String.split "/"
                |> List.foldl isMatch
                    { params = Dict.empty
                    , match = True
                    , rest = path
                    }
    in
        if result.match && (List.isEmpty result.rest) then
            Just (toRoute ( result.params, query ))
        else
            Nothing
