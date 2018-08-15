module Pages.EventTypeCreate.Models exposing (..)

import Stores.EventType
    exposing
        ( EventType
        , categories
        , allCategories
        , compatibilityModes
        , allModes
        , partitionStrategies
        , cleanupPolicies
        , audiences
        )
import Stores.Partition
import Helpers.Store exposing (Status(Unknown), ErrorMessage)
import Helpers.AccessEditor as AccessEditor
import Constants exposing (emptyString)
import Dict


type Operation
    = Create
    | Update String
    | Clone String


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
    | FieldAccess
    | FieldAudience
    | FieldCleanupPolicy


type alias ValuesDict =
    Dict.Dict String String


type alias ErrorsDict =
    Dict.Dict String String


type alias Model =
    { operation : Operation
    , values : ValuesDict
    , validationErrors : ErrorsDict
    , status : Status
    , error : Maybe ErrorMessage
    , accessEditor : AccessEditor.Model
    , partitionsStore : Stores.Partition.Model
    }


initialModel : Model
initialModel =
    { operation = Create
    , values = Dict.fromList defaultValues
    , validationErrors = Dict.empty
    , status = Unknown
    , error = Nothing
    , accessEditor = AccessEditor.initialModel
    , partitionsStore = Stores.Partition.initialModel
    }


defaultRetentionDays : Int
defaultRetentionDays =
    4


defaultApplication : String
defaultApplication =
    "stups_nakadi-ui-elm"


defaultValues : List ( String, String )
defaultValues =
    [ ( FieldName, emptyString )
    , ( FieldOwningApplication, defaultApplication )
    , ( FieldCategory, categories.business )
    , ( FieldPartitionStrategy, partitionStrategies.random )
    , ( FieldPartitionsNumber, "1" )
    , ( FieldPartitionKeyFields, emptyString )
    , ( FieldOrderingKeyFields, emptyString )
    , ( FieldRetentionTime, toString defaultRetentionDays )
    , ( FieldSchema, defaultSchema )
    , ( FieldCompatibilityMode, compatibilityModes.forward )
    , ( FieldAudience, "" )
    , ( FieldCleanupPolicy, cleanupPolicies.delete )
    ]
        |> List.map (\( field, value ) -> ( toString field, value ))


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
                |> Basics.clamp 2 4
                |> toString
    in
        defaultValues
            |> Dict.fromList
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


getValue : Field -> ValuesDict -> String
getValue field values =
    Dict.get (toString field) values |> Maybe.withDefault emptyString


setValue : Field -> String -> ValuesDict -> ValuesDict
setValue field value values =
    Dict.insert (toString field) value values


maybeSetValue : Field -> Maybe String -> ValuesDict -> ValuesDict
maybeSetValue field maybeValue values =
    case maybeValue of
        Just value ->
            setValue field value values

        Nothing ->
            values


maybeSetListValue : Field -> Maybe (List String) -> ValuesDict -> ValuesDict
maybeSetListValue field maybeValue values =
    case maybeValue of
        Just value ->
            setValue field (String.join ", " value) values

        Nothing ->
            values
