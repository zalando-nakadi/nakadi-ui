module Routing.Messages exposing (..)

import Navigation exposing (Location)
import Routing.Models exposing (Route)


type Msg
    = OnLocationChange Location
    | RouteChanged Route
    | SetLocation Route
    | Redirect Route
