module Pages.Partition.Messages exposing (..)

import Routing.Models exposing (Route(..))
import Stores.Events exposing (Event, EventsResponse)
import Stores.Partition exposing (Partition)
import Stores.ShiftedCursor
import Stores.CursorDistance
import Http
import Helpers.JsonEditor as JsonEditor
import Char exposing (KeyCode)
import Helpers.Http exposing (HttpStringResult)

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
    | OffsetKeyUp KeyCode
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
    | NavigatorClicked Int
    | OldFirst Bool
    | Download
    | DownloadStarted (Result Http.Error String)
