module Pages.SubscriptionCreate.Models exposing (Field(..), Model, Operation(..), allReadFrom, cloneValues, copyValues, defaultApplication, defaultValues, initialModel, readFrom)

import Config exposing (appPreffix)
import Constants exposing (emptyString)
import Dict
import Helpers.AccessEditor as AccessEditor
import Helpers.Forms exposing (..)
import Helpers.Store exposing (ErrorMessage, Status(..))
import Http
import MultiSearch.Models
import Stores.Subscription
import Stores.SubscriptionCursors


type Operation
    = Create
    | Update String
    | Clone String


type Field
    = FieldConsumerGroup
    | FieldOwningApplication
    | FieldReadFrom
    | FieldEventTypes
    | FieldCursors
    | FieldAccess


type alias Model =
    FormModel
        { addEventTypeWidget : MultiSearch.Models.Model
        , status : Status
        , error : Maybe ErrorMessage
        , fileLoaderError : Maybe Http.Error
        , cursorsStore : Stores.SubscriptionCursors.Model
        , operation : Operation
        , accessEditor : AccessEditor.Model
        }


initialModel : Model
initialModel =
    { values = defaultValues
    , validationErrors = Dict.empty
    , formId = "subscriptionCreateForm"
    , addEventTypeWidget = MultiSearch.Models.initialModel
    , status = Unknown
    , error = Nothing
    , fileLoaderError = Nothing
    , cursorsStore = Stores.SubscriptionCursors.initialModel
    , operation = Create
    , accessEditor = AccessEditor.initialModel
    }


readFrom :
    { begin : String
    , end : String
    , cursors : String
    }
readFrom =
    { begin = "begin"
    , end = "end"
    , cursors = "cursors"
    }


allReadFrom : List String
allReadFrom =
    [ readFrom.end
    , readFrom.begin
    , readFrom.cursors
    ]


defaultApplication : String
defaultApplication =
    appPreffix ++ "nakadi-ui-elm"


defaultValues : ValuesDict
defaultValues =
    [ ( FieldConsumerGroup, emptyString )
    , ( FieldOwningApplication, defaultApplication )
    , ( FieldReadFrom, readFrom.end )
    , ( FieldEventTypes, emptyString )
    ]
        |> toValuesDict


copyValues : Stores.Subscription.Subscription -> ValuesDict
copyValues subscription =
    [ ( FieldConsumerGroup, subscription.consumer_group )
    , ( FieldOwningApplication, subscription.owning_application )
    , ( FieldReadFrom, subscription.read_from )
    , ( FieldEventTypes, subscription.event_types |> String.join "\n" )
    ]
        |> toValuesDict


cloneValues : Stores.Subscription.Subscription -> ValuesDict
cloneValues subscription =
    copyValues subscription
        |> setValue FieldConsumerGroup ("clone_of_" ++ subscription.consumer_group)
        |> setValue FieldReadFrom readFrom.cursors
