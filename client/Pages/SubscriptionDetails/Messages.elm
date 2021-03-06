module Pages.SubscriptionDetails.Messages exposing (Msg(..))

import Http
import Keyboard exposing (RawKey)
import Pages.SubscriptionDetails.Models exposing (Tabs)
import Routing.Models exposing (Route(..))
import Stores.Cursor exposing (SubscriptionCursor)
import Stores.SubscriptionStats exposing (SubscriptionStats)


type Msg
    = OnRouteChange Route
    | Refresh
    | LoadStats
    | StatsLoaded (Result Http.Error (List SubscriptionStats))
    | OpenDeletePopup
    | CloseDeletePopup
    | ConfirmDelete
    | Delete
    | DeleteDone (Result Http.Error ())
    | TabChange Tabs
    | OutOnSubscriptionDeleted
    | LoadCursors
    | CursorsLoaded (Result Http.Error (List SubscriptionCursor))
    | EditOffset String String
    | EditOffsetChange String
    | EditOffsetCancel
    | EditOffsetSubmit
    | ResetOffsetDone (Result Http.Error ())
    | OutRefreshSubscriptions
    | OffsetKeyDown RawKey
    | OutAddToFavorite String
    | OutRemoveFromFavorite String
