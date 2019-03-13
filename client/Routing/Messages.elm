module Routing.Messages exposing (..)

import Navigation exposing (Location)
import Routing.Models exposing (Route)
import Helpers.Http exposing (HttpStringResult)
import Result
type Msg
    = OnLocationChange Location
    | RouteChanged Route
    | SetLocation Route
    | Redirect Route
    | TitleChanged HttpStringResult
