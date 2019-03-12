module Routing.Messages exposing (..)

import Navigation exposing (Location)
import Routing.Models exposing (Route)
import Http
import Result
type Msg
    = OnLocationChange Location
    | RouteChanged Route
    | SetLocation Route
    | Redirect Route
    | TitleChanged (Result.Result Http.Error String)
