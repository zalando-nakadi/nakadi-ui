module Pages.TeamDetails.Messages exposing (Msg(..))

import Helpers.Store as Store
import Routing.Models exposing (Route)
import Stores.TeamDetails exposing (TeamDetail)


type Msg
    = OnRouteChange Route
    | TeamDetailStoreMsg (Store.Msg TeamDetail)
