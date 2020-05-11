module Pages.EventTypeDetails.Messages exposing (Msg(..))

import Helpers.Http exposing (HttpStringResult)
import Helpers.JsonEditor
import Http
import Pages.EventTypeDetails.Models exposing (Tabs)
import Pages.EventTypeDetails.PublishTab
import RemoteData exposing (WebData)
import Routing.Models exposing (Route(..))
import Stores.Consumer
import Stores.ConsumingQuery
import Stores.CursorDistance
import Stores.EventTypeSchema
import Stores.EventTypeValidation
import Stores.Partition
import Stores.Query


type Msg
    = OnRouteChange Route
    | Reload
    | FormatSchema Bool
    | EffectiveSchema Bool
    | CopyToClipboard String
    | CopyToClipboardDone HttpStringResult
    | TabChange Tabs
    | SchemaVersionChange String
    | JsonEditorMsg Helpers.JsonEditor.Msg
    | LoadConsumingQueries
    | ConsumingQueriesStoreMsg Stores.ConsumingQuery.Msg
    | LoadConsumers
    | ConsumersStoreMsg Stores.Consumer.Msg
    | LoadTotals
    | TotalsLoaded (Result Http.Error (List Stores.CursorDistance.CursorDistance))
    | OpenDeletePopup
    | CloseDeletePopup
    | ConfirmDelete
    | Delete
    | DeleteDone (Result Http.Error ())
    | OutOnEventTypeDeleted
    | OutRefreshEventTypes
    | PartitionsStoreMsg Stores.Partition.Msg
    | EventTypeSchemasStoreMsg Stores.EventTypeSchema.Msg
    | OutLoadSubscription
    | OutAddToFavorite String
    | OutRemoveFromFavorite String
    | ValidationStoreMsg Stores.EventTypeValidation.Msg
    | LoadQuery String
    | LoadQueryResponse (WebData Stores.Query.Query)
    | OpenDeleteQueryPopup
    | CloseDeleteQueryPopup
    | ConfirmQueryDelete
    | QueryDelete
    | QueryDeleteResponse (WebData ())
    | PublishTabMsg Pages.EventTypeDetails.PublishTab.Msg
