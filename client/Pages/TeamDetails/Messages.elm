module Pages.TeamDetails.Messages exposing (Msg(..))

import Helpers.Store as Store
import Routing.Models exposing (Route)
import Stores.TeamDetails exposing (TeamDetail)


type Msg
    = OnRouteChange Route
    | TeamDetailStoreMsg (Store.Msg TeamDetail)
    | PageChange Int
    | Refresh
    | FilterChange String
    | SortBy (Maybe String) Bool
