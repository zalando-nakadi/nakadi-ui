module Pages.SubscriptionCreate.Models exposing (..)

import Helpers.Store exposing (Status(Unknown), ErrorMessage)
import Stores.SubscriptionCursors
import Stores.Subscription
import Constants exposing (emptyString)
import Dict
import MultiSearch.Models


type Field
    = FieldConsumerGroup
    | FieldOwningApplication
    | FieldReadFrom
    | FieldEventTypes
    | FieldCursors


type alias ValuesDict =
    Dict.Dict String String


type alias ErrorsDict =
    Dict.Dict String String


type alias Model =
    { values : ValuesDict
    , validationErrors : ErrorsDict
    , addEventTypeWidget : MultiSearch.Models.Model
    , status : Status
    , error : Maybe ErrorMessage
    , fileLoaderError : Maybe String
    , cursorsStore : Stores.SubscriptionCursors.Model
    , cloneId : Maybe String
    }


initialModel : Model
initialModel =
    { values = defaultValues
    , validationErrors = Dict.empty
    , addEventTypeWidget = MultiSearch.Models.initialModel
    , status = Unknown
    , error = Nothing
    , fileLoaderError = Nothing
    , cursorsStore = Stores.SubscriptionCursors.initialModel
    , cloneId = Nothing
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
    "stups_nakadi-ui-elm"


defaultValues : ValuesDict
defaultValues =
    [ ( FieldConsumerGroup, emptyString )
    , ( FieldOwningApplication, defaultApplication )
    , ( FieldReadFrom, readFrom.end )
    , ( FieldEventTypes, emptyString )
    ]
        |> toValuesDict


copyValues : String -> Stores.Subscription.Subscription -> ValuesDict
copyValues cursors subscription =
    [ ( FieldConsumerGroup, "clone_of_" ++ subscription.consumer_group )
    , ( FieldOwningApplication, subscription.owning_application )
    , ( FieldReadFrom, readFrom.cursors )
    , ( FieldEventTypes, subscription.event_types |> String.join "\n" )
    , ( FieldCursors, cursors )
    ]
        |> toValuesDict


toValuesDict : List ( Field, String ) -> ValuesDict
toValuesDict list =
    list
        |> List.map (\( field, value ) -> ( toString field, value ))
        |> Dict.fromList


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
