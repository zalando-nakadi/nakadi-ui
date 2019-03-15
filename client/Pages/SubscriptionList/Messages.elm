module Pages.SubscriptionList.Messages exposing (Msg(..))

import Helpers.Store exposing (Id)
import Routing.Models exposing (Route)


type Msg
    = NameFilterChanged String
    | SelectSubscription Id
    | PagingSetPage Int
    | Refresh
    | SortBy (Maybe String) Bool
    | OnRouteChange Route
    | OutAddToFavorite String
    | OutRemoveFromFavorite String
