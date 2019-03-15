module Pages.EventTypeCreate.Query exposing (daysToRetentionTimeJson, helpSql, post, sqlAccessEditor, sqlEditor, stringToJsonList, submitQueryCreate, viewQueryForm)

{--------------- View -----------------}

import Config
import Constants
import Helpers.AccessEditor as AccessEditor
import Helpers.Forms exposing (..)
import Helpers.Panel
import Helpers.UI exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Json.Encode as Json
import Models exposing (AppModel)
import Pages.EventTypeCreate.Messages exposing (..)
import Pages.EventTypeCreate.Models exposing (..)
import Pages.EventTypeDetails.Help as Help
import Stores.Authorization exposing (Authorization)
import Stores.EventType exposing (allAudiences, categories, cleanupPolicies)


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
                "Example: stups_price-updater"
                "App name registered in YourTurn with 'stups_' prefix"
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
                ]
            , if getValue FieldCleanupPolicy formModel.values == cleanupPolicies.compact then
                textInput formModel
                    FieldPartitionCompactionKeyField
                    OnInput
                    "Partition Compaction Key Field"
                    "Example: metadata.partition_compaction_key"
                    "Field to be used as partition_compaction_key"
                    Help.partitionCompactionKeyField
                    Required
                    Enabled

              else
                none
            , if getValue FieldCleanupPolicy formModel.values == cleanupPolicies.delete then
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
            ]


sqlAccessEditor : String -> String -> Model -> Html Msg
sqlAccessEditor appsInfoUrl usersInfoUrl formModel =
    AccessEditor.view
        { appsInfoUrl = appsInfoUrl
        , usersInfoUrl = usersInfoUrl
        , showWrite = False
        , showAnyToken = False
        , help = Help.authorization
        }
        AccessEditorMsg
        formModel.accessEditor



{-------------- Update ----------------}


submitQueryCreate : Model -> Cmd Msg
submitQueryCreate model =
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
            ]

        body =
            Json.object fields
    in
    post body


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


stringToJsonList : String -> Json.Value
stringToJsonList str =
    str
        |> String.split ","
        |> List.map String.trim
        |> List.filter (String.isEmpty >> not)
        |> List.map Json.string
        |> Json.list


daysToRetentionTimeJson : ValuesDict -> Json.Value
daysToRetentionTimeJson values =
    values
        |> getValue FieldRetentionTime
        |> String.toInt
        |> Result.withDefault defaultRetentionDays
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
