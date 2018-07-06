module Pages.EventTypeDetails.Messages exposing (..)

import Routing.Models exposing (Route(..))
import Pages.EventTypeDetails.Models exposing (Tabs)
import Helpers.JsonEditor
import Stores.Publisher
import Stores.Consumer
import Stores.CursorDistance
import Stores.Partition
import Stores.EventTypeSchema
import Stores.EventTypeValidation
import Http


type Msg
    = OnRouteChange Route
    | Reload
    | FormatSchema Bool
    | EffectiveSchema Bool
    | CopyToClipboard String
    | TabChange Tabs
    | SchemaVersionChange String
    | JsonEditorMsg Helpers.JsonEditor.Msg
    | LoadPublishers
    | PublishersStoreMsg Stores.Publisher.Msg
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
