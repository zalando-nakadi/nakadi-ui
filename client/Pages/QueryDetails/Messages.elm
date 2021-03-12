module Pages.QueryDetails.Messages exposing (Msg(..))

import Helpers.Http exposing (HttpStringResult)
import Pages.QueryDetails.Models exposing (Tabs)
import RemoteData exposing (WebData)
import Routing.Models exposing (Route(..))
import Stores.Query


type Msg
    = OnRouteChange Route
    | Reload
    | CopyToClipboard String
    | CopyToClipboardDone HttpStringResult
    | TabChange Tabs
    | OpenDeleteQueryPopup
    | CloseDeleteQueryPopup
    | ConfirmQueryDelete
    | QueryDelete
    | QueryDeleteResponse (WebData ())
