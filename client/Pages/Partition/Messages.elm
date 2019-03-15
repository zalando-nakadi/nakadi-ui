module Pages.Partition.Messages exposing (Msg(..))

import Helpers.Http exposing (HttpStringResult)
import Helpers.JsonEditor as JsonEditor
import Http
import Keyboard exposing (RawKey)
import Routing.Models exposing (Route(..))
import Stores.CursorDistance
import Stores.Events exposing (Event, EventsResponse)
import Stores.Partition exposing (Partition)
import Stores.ShiftedCursor


type Msg
    = OnRouteChange Route
    | SetFormatted Bool
    | CopyToClipboard String
    | CopyToClipboardDone HttpStringResult
    | LoadPartitions
    | PartitionsLoaded (Result Http.Error (List Partition))
    | LoadEvents
    | SetOffset String
    | EventsLoaded (Result Http.Error EventsResponse)
    | InputOffset String
    | OffsetKeyUp RawKey
    | InputSize String
    | InputFilter String
    | SelectEvent String
    | UnSelectEvent
    | JsonEditorMsg JsonEditor.Msg
    | ShowAll
    | TotalStoreMsg Stores.CursorDistance.Msg
    | DistanceStoreMsg Stores.CursorDistance.Msg
    | NavigatorJumpStoreMsg Stores.ShiftedCursor.Msg
    | PageBackCursorStoreMsg Stores.ShiftedCursor.Msg
    | PageNewestCursorStoreMsg Stores.ShiftedCursor.Msg
    | NavigatorClicked Int Int
    | OldFirst Bool
    | Download
    | DownloadStarted (Result Http.Error String)
