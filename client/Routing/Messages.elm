module Routing.Messages exposing (Msg(..))

import Browser exposing (UrlRequest)
import Routing.Models exposing (Route)
import Url exposing (Url)


type Msg
    = OnLocationChange Url
    | UrlChangeRequested UrlRequest
    | OutRouteChanged Route
    | SetLocation Route
    | Redirect Route
