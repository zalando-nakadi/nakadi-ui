module Pages.EventTypeList.Messages exposing (..)

import Helpers.Store exposing (Id)
import Routing.Models exposing (Route)


type Msg
    = NameFilterChanged String
    | SelectEventType Id
    | PagingSetPage Int
    | Refresh
    | SortBy (Maybe String) Bool
    | OnRouteChange Route
    | OutAddToFavorite String
    | OutRemoveFromFavorite String
