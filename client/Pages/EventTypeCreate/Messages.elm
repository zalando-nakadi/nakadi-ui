module Pages.EventTypeCreate.Messages exposing (..)

import Http
import Pages.EventTypeCreate.Models exposing (Field, Operation)
import Helpers.AccessEditor as AccessEditor
import Dom
import Stores.Partition


type Msg
    = OnInput Field String
    | AccessEditorMsg AccessEditor.Msg
    | SchemaFormat
    | SchemaClear
    | Validate
    | SubmitCreate
    | SubmitUpdate
    | Reset
    | OnRouteChange Operation
    | FocusResult (Result Dom.Error ())
    | SubmitResponse (Result Http.Error ())
    | OutEventTypeCreated String
    | PartitionsStoreMsg Stores.Partition.Msg
