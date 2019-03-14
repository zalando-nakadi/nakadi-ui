module Routing.Messages exposing (Msg(..))

import Helpers.Http exposing (HttpStringResult)
import Navigation exposing (Location)
import Result
import Routing.Models exposing (Route)


type Msg
    = OnLocationChange Location
    | RouteChanged Route
    | SetLocation Route
    | Redirect Route
    | TitleChanged HttpStringResult
