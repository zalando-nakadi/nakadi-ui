module Pages.EventTypeCreate.Models exposing (Field(..), Model, Operation(..), defaultRetentionDays, defaultSchema, defaultSql, defaultValues, initialModel, loadValues)

import Config exposing (appPreffix)
import Constants exposing (emptyString)
import Dict
import Helpers.AccessEditor as AccessEditor
import Helpers.Forms exposing (..)
import Helpers.Store exposing (ErrorMessage, Status(..))
import Helpers.String exposing (boolToString)
import Stores.EventType
    exposing
        ( EventType
        , categories
        , cleanupPolicies
        , compatibilityModes
        , emptyEventOwnerSelector
        , partitionStrategies
        )
import Stores.Partition


type Operation
    = Create
    | Update String
    | Clone String
    | CreateQuery
    | UpdateConfirm String


type Field
    = FieldName
    | FieldOwningApplication
    | FieldCategory
    | FieldPartitionStrategy
    | FieldPartitionKeyFields
    | FieldOrderingKeyFields
    | FieldPartitionsNumber
    | FieldRetentionTime
    | FieldCompatibilityMode
    | FieldSchema
    | FieldEnvelope
    | FieldAudience
    | FieldEventOwnerSelectorType
    | FieldEventOwnerSelectorName
    | FieldEventOwnerSelectorValue
    | FieldCleanupPolicy
    | FieldReadFrom
    | FieldSql
    | FieldPartitionCompactionKeyField


type alias Model =
    FormModel
        { operation : Operation
        , error : Maybe ErrorMessage
        , accessEditor : AccessEditor.Model
        , partitionsStore : Stores.Partition.Model
        , testQuery :
            { status : Status
            , error : Maybe ErrorMessage
            , eventType : Maybe EventType
            }
        }


initialModel : Model
initialModel =
    { operation = Create
    , values = defaultValues
    , validationErrors = Dict.empty
    , formId = "eventTypeCreateForm"
    , status = Unknown
    , error = Nothing
    , accessEditor = AccessEditor.initialModel
    , partitionsStore = Stores.Partition.initialModel
    , testQuery =
        { status = Unknown
        , error = Nothing
        , eventType = Nothing
        }
    }


defaultRetentionDays : Int
defaultRetentionDays =
    1


defaultValues : ValuesDict
defaultValues =
    [ ( FieldName, emptyString )
    , ( FieldOwningApplication, "" )
    , ( FieldCategory, categories.business )
    , ( FieldPartitionStrategy, partitionStrategies.random )
    , ( FieldPartitionsNumber, "1" )
    , ( FieldPartitionKeyFields, emptyString )
    , ( FieldOrderingKeyFields, emptyString )
    , ( FieldRetentionTime, String.fromInt defaultRetentionDays )
    , ( FieldSchema, defaultSchema )
    , ( FieldSql, defaultSql )
    , ( FieldEnvelope, boolToString True )
    , ( FieldCompatibilityMode, compatibilityModes.forward )
    , ( FieldAudience, "" )
    , ( FieldEventOwnerSelectorType, "" )
    , ( FieldEventOwnerSelectorName, "" )
    , ( FieldEventOwnerSelectorValue, "" )
    , ( FieldCleanupPolicy, cleanupPolicies.delete )
    , ( FieldPartitionCompactionKeyField, emptyString )
    , ( FieldReadFrom, "end" )
    ]
        |> toValuesDict


loadValues : EventType -> ValuesDict
loadValues eventType =
    let
        {--We take milliseconds and round them up to the upper number fo days. 3 day and 1 sec => 4 days
        if options or retention_time not set then we use the default number of days.-}
        retentionTime =
            eventType.options
                |> Maybe.andThen .retention_time
                |> Maybe.withDefault (defaultRetentionDays * Constants.msInDay)
                |> toFloat
                |> (*) (1 / toFloat Constants.msInDay)
                |> Basics.ceiling
                |> String.fromInt

        ownerField =
            eventType.event_owner_selector
                |> Maybe.withDefault emptyEventOwnerSelector
    in
    defaultValues
        |> setValue FieldName eventType.name
        |> maybeSetValue FieldOwningApplication eventType.owning_application
        |> setValue FieldCategory eventType.category
        |> maybeSetValue FieldPartitionStrategy eventType.partition_strategy
        |> maybeSetListValue FieldPartitionKeyFields eventType.partition_key_fields
        |> maybeSetListValue FieldOrderingKeyFields eventType.ordering_key_fields
        |> maybeSetValue FieldCompatibilityMode eventType.compatibility_mode
        |> setValue FieldSchema eventType.schema.schema
        |> setValue FieldRetentionTime retentionTime
        |> maybeSetValue FieldAudience eventType.audience
        |> setValue FieldEventOwnerSelectorType ownerField.type_
        |> setValue FieldEventOwnerSelectorName ownerField.name
        |> setValue FieldEventOwnerSelectorValue ownerField.value
        |> setValue FieldCleanupPolicy eventType.cleanup_policy


defaultSchema : String
defaultSchema =
    """{
    "description": "Sample event type schema. It accepts any event.",
    "type": "object",
    "properties": {
        "example_item": {
            "type": "string"
        },
        "example_money": {
            "$ref": "#/definitions/Money"
        }
    },
    "required": [],
    "definitions": {
        "Money": {
            "type": "object",
            "properties": {
                "amount": {
                    "type": "number",
                    "format": "decimal"
                },
                "currency": {
                    "type": "string",
                    "format": "iso-4217"
                }
            },
            "required": [
                "amount",
                "currency"
            ]
        }
    }
}
"""


defaultSql : String
defaultSql =
    """SELECT *
    FROM "my-source-event-type" as payload
"""
