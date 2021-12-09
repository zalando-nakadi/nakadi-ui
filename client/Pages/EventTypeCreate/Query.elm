module Pages.EventTypeCreate.Query exposing (daysToRetentionTimeJson, helpSql, post, sqlAccessEditor, sqlEditor, stringToJsonList, submitQueryCreate, submitTestQuery, viewQueryForm)

{--------------- View -----------------}

import Config exposing (appPreffix)
import Constants
import Dict
import Helpers.AccessEditor as AccessEditor
import Helpers.Forms exposing (..)
import Helpers.JsonPrettyPrint exposing (prettyPrintJson)
import Helpers.Panel
import Helpers.String exposing (stringToBool)
import Helpers.UI exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Http
import Json.Decode exposing (Decoder, field)
import Json.Encode as Json
import Models exposing (AppModel)
import Pages.EventTypeCreate.Messages exposing (..)
import Pages.EventTypeCreate.Models exposing (..)
import Pages.EventTypeDetails.Help as Help
import Pages.SubscriptionCreate.Models exposing (readFrom)
import Stores.Authorization exposing (Authorization)
import Stores.EventType exposing (EventType, allAudiences, categories, cleanupPolicies)


viewQueryForm : AppModel -> Html Msg
viewQueryForm model =
    let
        formModel =
            model.eventTypeCreatePage

        { appsInfoUrl, usersInfoUrl, supportUrl } =
            model.userStore.user.settings

        formTitle =
            "Create SQL Query"
    in
    div [ class "dc-column form-create__form-container" ]
        [ div []
            [ h4 [ class "dc-h4 dc--text-center" ] [ text formTitle ]
            , textInput formModel
                FieldName
                OnInput
                "Output Event Type Name"
                "Example: bazar.price-updater.price_changed"
                "Should be several words (with '_', '-') separated by dot."
                Help.eventType
                Required
                Enabled
            , textInput formModel
                FieldOwningApplication
                OnInput
                "Owning Application"
                ("Example: " ++ appPreffix ++ "price-updater")
                ("App name registered in YourTurn with '" ++ appPreffix ++ "' prefix")
                Help.owningApplication
                Required
                Enabled
            , selectInput formModel
                FieldCleanupPolicy
                OnInput
                "Cleanup policy"
                ""
                Help.cleanupPolicy
                Required
                Enabled
                [ cleanupPolicies.compact
                , cleanupPolicies.delete
                , cleanupPolicies.compact_delete
                ]
            , selectInput formModel
                FieldReadFrom
                OnInput
                "Read from"
                ""
                Help.readFrom
                Required
                Enabled
                [ readFrom.end
                , readFrom.begin
                ]
            , selectInput formModel
                FieldEnvelope
                OnInput
                "Envelope"
                ""
                Help.envelope
                Required
                Enabled
                [ "true", "false" ]
            , if
                getValue FieldCleanupPolicy formModel.values
                    == cleanupPolicies.compact
                    || getValue FieldCleanupPolicy formModel.values
                    == cleanupPolicies.compact_delete
              then
                textInput formModel
                    FieldPartitionCompactionKeyField
                    OnInput
                    "Partition Compaction Key Field"
                    "Example: payload.metadata.partition_compaction_key"
                    "Field to be used as partition_compaction_key"
                    Help.partitionCompactionKeyField
                    Required
                    Enabled

              else
                none
            , if
                getValue FieldCleanupPolicy formModel.values
                    == cleanupPolicies.delete
                    || getValue FieldCleanupPolicy formModel.values
                    == cleanupPolicies.compact_delete
              then
                selectInput formModel
                    FieldRetentionTime
                    OnInput
                    "Retention Time (Days)"
                    ""
                    Help.options
                    Optional
                    Enabled
                    [ "2", "3", "4" ]

              else
                none
            , selectInput
                formModel
                FieldCategory
                OnInput
                "Category"
                ""
                Help.category
                Optional
                Enabled
                [ categories.business
                , categories.data
                ]
            , textInput formModel
                FieldOrderingKeyFields
                OnInput
                "Ordering Key Fields"
                "Example: order.day, order.index"
                "Comma-separated list of keys."
                Help.orderingKeyFields
                Optional
                Enabled
            , selectInput formModel
                FieldAudience
                OnInput
                "Audience"
                ""
                Help.audience
                Required
                Enabled
                ("" :: allAudiences)
            , sqlEditor formModel
            , hr [ class "dc-divider" ] []
            , sqlAccessEditor appsInfoUrl usersInfoUrl formModel
            ]
        , hr [ class "dc-divider" ]
            []
        , div
            [ class "dc-toast__content dc-toast__content--success" ]
            [ text "Nakady SQL Query Created!" ]
            |> Helpers.Panel.loadingStatus formModel
        , buttonPanel formTitle Submit Reset FieldName formModel
        ]


sqlEditor : Model -> Html Msg
sqlEditor formModel =
    let
        isDisabled =
            not (Dict.isEmpty formModel.validationErrors)
    in
    inputFrame FieldSql "SQL Query" "" helpSql Required formModel <|
        div []
            [ div [ class "dc-btn-group" ] []
            , pre
                [ class "ace-edit" ]
                [ node "ace-editor"
                    [ value (getValue FieldSql formModel.values)
                    , onChange (OnInput FieldSql)
                    , attribute "theme" "ace/theme/dawn"
                    , attribute "mode" "ace/mode/sql"
                    ]
                    []
                ]
            , if isDisabled then
                none

              else
                div []
                    [ button [ class "dc-btn", disabled isDisabled, onClick TestQuery ] [ text "Validate SQL Query" ]
                    , Helpers.Panel.loadingStatus formModel.testQuery <|
                        eventTypePreview formModel.testQuery.eventType
                    ]
            ]


sqlAccessEditor : String -> String -> Model -> Html Msg
sqlAccessEditor appsInfoUrl usersInfoUrl formModel =
    AccessEditor.view
        { appsInfoUrl = appsInfoUrl
        , usersInfoUrl = usersInfoUrl
        , teamsInfoUrl = ""
        , showWrite = False
        , showAnyToken = False
        , help = Help.authorization
        }
        AccessEditorMsg
        formModel.accessEditor


eventTypePreview : Maybe EventType -> Html Msg
eventTypePreview maybeEventType =
    case maybeEventType of
        Nothing ->
            none

        Just eventType ->
            div []
                [ div [ class "dc--island-100" ] []
                , span [ class "dc--text-success" ]
                    [ text "SQL Query is valid. Resulting schema:" ]
                , pre
                    [ class "ace-edit" ]
                    [ node "ace-editor"
                        [ value (eventType.schema.schema |> prettyPrintJson)
                        , attribute "theme" "ace/theme/dawn"
                        , attribute "mode" "ace/mode/json"
                        , attribute "readonly" "true"
                        ]
                        []
                    ]
                ]



{-------------- Update ----------------}


submitQueryCreate : Model -> Cmd Msg
submitQueryCreate model =
    model |> encodeQuery |> post


submitTestQuery : Model -> Cmd Msg
submitTestQuery model =
    model |> encodeQuery |> postTest


encodeQuery : Model -> Json.Value
encodeQuery model =
    let
        orderingKeyFields =
            model.values
                |> getValue FieldOrderingKeyFields
                |> stringToJsonList

        asString field =
            model.values
                |> getValue field
                |> String.trim
                |> Json.string

        asBool field =
            model.values
                |> getValue field
                |> stringToBoolValue

        auth =
            AccessEditor.unflatten model.accessEditor.authorization
                |> Stores.Authorization.encoderReadAdmin

        fields =
            [ ( "output_event_type"
              , Json.object
                    [ ( "name", asString FieldName )
                    , ( "owning_application", asString FieldOwningApplication )
                    , ( "category", asString FieldCategory )
                    , ( "cleanup_policy", asString FieldCleanupPolicy )
                    , ( "retention_time", daysToRetentionTimeJson model.values )
                    , ( "partition_compaction_key_field", asString FieldPartitionCompactionKeyField )
                    , ( "ordering_key_fields", orderingKeyFields )
                    , ( "audience", asString FieldAudience )
                    ]
              )
            , ( "sql", asString FieldSql )
            , ( "authorization", auth )
            , ( "envelope", asBool FieldEnvelope )
            , ( "read_from", asString FieldReadFrom )
            ]
    in
    Json.object fields


post : Json.Value -> Cmd Msg
post body =
    Http.request
        { method = "POST"
        , headers = []
        , url = Config.urlNakadiSqlApi ++ "queries"
        , body = Http.jsonBody body
        , expect = Http.expectStringResponse (always (Ok ()))
        , timeout = Nothing
        , withCredentials = False
        }
        |> Http.send SubmitResponse


postTest : Json.Value -> Cmd Msg
postTest body =
    Http.request
        { method = "POST"
        , headers = []
        , url = Config.urlNakadiSqlApi ++ "test-queries"
        , body = Http.jsonBody body
        , expect = Http.expectJson testResultDecoder
        , timeout = Nothing
        , withCredentials = False
        }
        |> Http.send TestQueryResponse


testResultDecoder : Decoder EventType
testResultDecoder =
    field "output_event_request" Stores.EventType.memberDecoder


stringToBoolValue : String -> Json.Value
stringToBoolValue str =
    str
        |> String.trim
        |> stringToBool
        |> Json.bool


stringToJsonList : String -> Json.Value
stringToJsonList str =
    str
        |> String.split ","
        |> List.map String.trim
        |> List.filter (String.isEmpty >> not)
        |> Json.list Json.string


daysToRetentionTimeJson : ValuesDict -> Json.Value
daysToRetentionTimeJson values =
    values
        |> getValue FieldRetentionTime
        |> String.toInt
        |> Maybe.withDefault defaultRetentionDays
        |> (*) Constants.msInDay
        |> Json.int


helpSql : List (Html msg)
helpSql =
    [ text "The SQL query to be run by the executor."
    , newline
    , text "The SQL statements supported are a subset of ANSI SQL."
    , newline
    , text "The operations supported are joining two or more EventTypes and filtering"
    , text " EventTypes to an output EventType. The EventTypes on which these queries are run MUST"
    , text " be log-compacted EventTypes. The EventTypes that are used for join queries MUST have the"
    , text " equal number of partitions and the EventTypes are joined on their compaction keys. Also,"
    , text " the join is done on per partition basis. The output EventType has the same number of"
    , text " partitions as the input EventType(s)."
    , newline
    , link "More in the API Manual" "https://apis.zalando.net/apis/3d932e38-b9db-42cf-84bb-0898a72895fb/ui"
    ]
