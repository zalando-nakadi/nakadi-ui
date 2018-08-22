module Pages.SubscriptionCreate.Messages exposing (..)

import Http
import Pages.SubscriptionCreate.Models exposing (Field)
import Dom
import MultiSearch.Messages
import Helpers.FileReader as FileReader
import Stores.SubscriptionCursors
import Helpers.AccessEditor as AccessEditor

type Msg
    = OnInput Field String
    | AddEventTypeWidgetMsg MultiSearch.Messages.Msg
    | Validate
    | SubmitCreate
    | Reset
    | FormatEventTypes
    | ClearEventTypes
    | FileSelected (List FileReader.NativeFile)
    | FileLoaded (Result FileReader.Error String)
    | OnRouteChange (Maybe String)
    | FocusResult (Result Dom.Error ())
    | SubmitResponse (Result Http.Error String)
    | OutSubscriptionCreated String
    | CursorsStoreMsg Stores.SubscriptionCursors.Msg
    | AccessEditorMsg AccessEditor.Msg
