module Pages.SubscriptionDetails.Messages exposing (..)

import Routing.Models exposing (Route(..))
import Stores.SubscriptionStats exposing (SubscriptionStats)
import Stores.Cursor exposing (SubscriptionCursor)
import Http
import Char exposing (KeyCode)
import Pages.SubscriptionDetails.Models exposing (Tabs)

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
    | OffsetKeyDown KeyCode
    | OutAddToFavorite String
    | OutRemoveFromFavorite String
