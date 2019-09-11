module Pages.TeamDetails.Messages exposing (Msg(..))

import Http
import Routing.Models exposing (Route)


type Msg
    = OnRouteChange Route
    | Done (Result Http.Error String)
