module Pages.EventTypeCreate.Messages exposing (Msg(..))

import Dom
import Helpers.AccessEditor as AccessEditor
import Http
import Pages.EventTypeCreate.Models exposing (Field, Operation)
import Stores.Partition


type Msg
    = OnInput Field String
    | AccessEditorMsg AccessEditor.Msg
    | SchemaFormat
    | SchemaClear
    | Validate
    | Submit
    | Reset
    | OnRouteChange Operation
    | FocusResult (Result Dom.Error ())
    | SubmitResponse (Result Http.Error ())
    | OutEventTypeCreated String
    | PartitionsStoreMsg Stores.Partition.Msg
