module Pages.SubscriptionCreate.Messages exposing (Msg(..))

import Dom
import Helpers.AccessEditor as AccessEditor
import Http
import MultiSearch.Messages
import Pages.SubscriptionCreate.Models exposing (Field, Operation)
import Stores.SubscriptionCursors


type Msg
    = OnInput Field String
    | AddEventTypeWidgetMsg MultiSearch.Messages.Msg
    | Validate
    | Submit
    | Reset
    | FormatEventTypes
    | ClearEventTypes
    | FileSelected String String
    | FileLoaded (Result Http.Error String)
    | OnRouteChange Operation
    | FocusResult (Result Dom.Error ())
    | SubmitResponse (Result Http.Error String)
    | OutSubscriptionCreated String
    | CursorsStoreMsg Stores.SubscriptionCursors.Msg
    | AccessEditorMsg AccessEditor.Msg
