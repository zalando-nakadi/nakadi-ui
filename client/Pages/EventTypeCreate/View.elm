module Pages.EventTypeCreate.View exposing (FormSetup, accessEditor, schemaEditor, view, viewForm, viewFormClone, viewFormCreate, viewFormUpdate)

import Config exposing (appPreffix)
import Constants exposing (emptyString)
import Helpers.AccessEditor as AccessEditor
import Helpers.Forms exposing (..)
import Helpers.Panel
import Helpers.Store as Store exposing (Status(..))
import Helpers.UI exposing (PopupPosition(..), externalLink, none, onChange)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Models exposing (AppModel)
import Pages.EventTypeCreate.Messages exposing (..)
import Pages.EventTypeCreate.Models exposing (..)
import Pages.EventTypeCreate.Query exposing (viewQueryForm)
import Pages.EventTypeDetails.Help as Help
import Stores.EventType
    exposing
        ( EventType
        , allAudiences
        , allCategories
        , allCleanupPolicies
        , allModes
        , allOwnerSelectorTypes
        , categories
        , cleanupPolicies
        , compatibilityModes
        , partitionStrategies
        )


view : AppModel -> Html Msg
view model =
    let
        formModel =
            model.eventTypeCreatePage

        findEventType name form =
            case Store.get name model.eventTypeStore of
                Nothing ->
                    div []
                        [ Helpers.Panel.errorMessage "Event type not found"
                            ("Event type with the name \"" ++ name ++ "\" not found.")
                        ]

                Just eventType ->
                    container <| form model eventType

        container form =
            div [ class "form-create__form dc-card dc-row dc-row--align--center" ]
                [ form ]
    in
    Helpers.Panel.loadingStatus model.eventTypeStore <|
        case formModel.operation of
            Create ->
                container <|
                    viewFormCreate model

            Update name ->
                findEventType name viewFormUpdate

            Clone name ->
                Helpers.Panel.loadingStatus formModel.partitionsStore <|
                    findEventType name viewFormClone

            CreateQuery ->
                container <|
                    viewQueryForm model


viewFormCreate : AppModel -> Html Msg
viewFormCreate model =
    viewForm model
        { nameEditing = Enabled
        , formTitle = "Create Event Type"
        , successMessage = "Event Type Created!"
        , categoriesOptions = allCategories
        , compatibilityModeOptions = allModes
        , cleanupPoliciesOptions = allCleanupPolicies
        , partitionStrategyEditing = Enabled
        , partitionNumberEditing = Enabled
        }


viewFormUpdate : AppModel -> EventType -> Html Msg
viewFormUpdate model originalEventType =
    let
        originalMode =
            originalEventType.compatibility_mode |> Maybe.withDefault emptyString

        compatibilityModeOptions =
            if originalMode == compatibilityModes.none then
                allModes

            else if originalMode == compatibilityModes.forward then
                [ compatibilityModes.forward
                , compatibilityModes.compatible
                ]

            else
                [ compatibilityModes.compatible ]

        partitionStrategyEditing =
            if
                (originalEventType.partition_strategy |> Maybe.withDefault emptyString)
                    == partitionStrategies.random
            then
                Enabled

            else
                Disabled

        categoriesOptions =
            if originalEventType.category == categories.undefined then
                [ categories.undefined
                , categories.business
                ]

            else
                [ originalEventType.category ]

        cleanupPoliciesOptions =
            [ originalEventType.cleanup_policy ]
    in
    viewForm model
        { nameEditing = Disabled
        , formTitle = "Update Event Type"
        , successMessage = "Event Type Updated!"
        , categoriesOptions = categoriesOptions
        , compatibilityModeOptions = compatibilityModeOptions
        , cleanupPoliciesOptions = cleanupPoliciesOptions
        , partitionStrategyEditing = partitionStrategyEditing
        , partitionNumberEditing = Disabled
        }


viewFormClone : AppModel -> EventType -> Html Msg
viewFormClone model originalEventType =
    viewForm model
        { nameEditing = Enabled
        , formTitle = "Clone Event Type"
        , successMessage = "Event Type Cloned!"
        , categoriesOptions = allCategories
        , compatibilityModeOptions = allModes
        , cleanupPoliciesOptions = allCleanupPolicies
        , partitionStrategyEditing = Enabled
        , partitionNumberEditing = Enabled
        }


type alias FormSetup =
    { nameEditing : Locking
    , formTitle : String
    , successMessage : String
    , categoriesOptions : List String
    , compatibilityModeOptions : List String
    , cleanupPoliciesOptions : List String
    , partitionStrategyEditing : Locking
    , partitionNumberEditing : Locking
    }


viewForm : AppModel -> FormSetup -> Html Msg
viewForm model setup =
    let
        { nameEditing, formTitle, successMessage, categoriesOptions, compatibilityModeOptions, cleanupPoliciesOptions, partitionStrategyEditing, partitionNumberEditing } =
            setup

        formModel =
            model.eventTypeCreatePage

        appsInfoUrl =
            model.userStore.user.settings.appsInfoUrl

        usersInfoUrl =
            model.userStore.user.settings.usersInfoUrl

        supportUrl =
            model.userStore.user.settings.supportUrl

        retentionTimeDaysValues =
            model.userStore.user.settings.retentionTimeDaysValues |> String.split " "

    in
    div [ class "dc-column form-create__form-container" ]
        [ div []
            [ h4 [ class "dc-h4 dc--text-center" ] [ text formTitle ]
            , textInput formModel
                FieldName
                OnInput
                "Event Type Name"
                "Example: bazar.price-updater.price_changed"
                "Should be several words (with '_', '-') separated by dot."
                Help.eventType
                Required
                nameEditing
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
                FieldCategory
                OnInput
                "Category"
                ""
                Help.category
                Optional
                Enabled
                categoriesOptions
            , div [ class "dc-row form-create__input-row" ]
                [ selectInput formModel
                    FieldPartitionStrategy
                    OnInput
                    "Partition Strategy"
                    ""
                    Help.partitionStrategy
                    Optional
                    partitionStrategyEditing
                    [ partitionStrategies.random
                    , partitionStrategies.hash
                    , partitionStrategies.user_defined
                    ]
                , div
                    [ class "dc-column" ]
                    [ if getValue FieldPartitionStrategy formModel.values == partitionStrategies.hash then
                        textInput formModel
                            FieldPartitionKeyFields
                            OnInput
                            "Partition Key Fields"
                            "Example: order.user_id, order.item_id"
                            "Comma-separated list of keys."
                            Help.partitionKeyFields
                            Required
                            partitionStrategyEditing

                      else
                        none
                    ]
                ]
            , selectInput formModel
                FieldPartitionsNumber
                OnInput
                "Number of Partitions"
                ""
                Help.defaultStatistic
                Optional
                partitionNumberEditing
                (List.range 1 Config.maxPartitionNumber |> List.map String.fromInt)
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
            , div [ class "dc-row form-create__input-row" ]
                [ selectInput formModel
                    FieldEventOwnerSelectorType
                    OnInput
                    "Event Owner Selector Type"
                    ""
                    Help.eventOwnerSelector
                    Optional
                    Enabled
                    ("" :: allOwnerSelectorTypes)
                , div
                    [ class "dc-column" ]
                    [ textInput formModel
                        FieldEventOwnerSelectorName
                        OnInput
                        "Event Owner Selector Name"
                        "Example: retailer_id"
                        ""
                        Help.eventOwnerSelector
                        Optional
                        Enabled
                    ]
                , div
                    [ class "dc-column" ]
                    [ textInput formModel
                        FieldEventOwnerSelectorValue
                        OnInput
                        "Event Owner Selector Value"
                        "Example: security.owners"
                        ""
                        Help.eventOwnerSelector
                        Optional
                        Enabled
                    ]
                ]
            , selectInput formModel
                FieldCleanupPolicy
                OnInput
                "Cleanup policy"
                ""
                Help.cleanupPolicy
                Optional
                Enabled
                cleanupPoliciesOptions
            , if getValue FieldCleanupPolicy formModel.values == cleanupPolicies.compact then
                p [ class "dc-p" ]
                    [ text "Log compacted event types MUST NOT contain personal identifiable"
                    , text " information in accordance to GDPR. If you plan to store user"
                    , text " data permanently in Log compacted event types, then please contact "
                    , externalLink "support" supportUrl
                    , text " to get a custom GDPR compliant solution built for your use case."
                    ]

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
                    retentionTimeDaysValues

              else
                none
            , selectInput formModel
                FieldCompatibilityMode
                OnInput
                "Schema Compatibility Mode"
                ""
                Help.compatibilityMode
                Optional
                Enabled
                compatibilityModeOptions
            , schemaEditor formModel
            , hr [ class "dc-divider" ] []
            , accessEditor appsInfoUrl usersInfoUrl formModel
            ]
        , hr [ class "dc-divider" ]
            []
        , div
            [ class "dc-toast__content dc-toast__content--success" ]
            [ text successMessage ]
            |> Helpers.Panel.loadingStatus formModel
        , buttonPanel formTitle Submit Reset FieldName formModel
        ]


accessEditor : String -> String -> Model -> Html Msg
accessEditor appsInfoUrl usersInfoUrl formModel =
    AccessEditor.view
        { appsInfoUrl = appsInfoUrl
        , usersInfoUrl = usersInfoUrl
        , showWrite = True
        , showAnyToken = True
        , help = Help.authorization
        }
        AccessEditorMsg
        formModel.accessEditor


schemaEditor : Model -> Html Msg
schemaEditor formModel =
    inputFrame FieldSchema "Schema" "" Help.schema Required formModel <|
        div []
            [ div [ class "dc-btn-group" ]
                [ button
                    [ onClick SchemaFormat
                    , class "dc-btn dc-btn--in-btn-group"
                    ]
                    [ text "Format JSON" ]
                , button
                    [ onClick SchemaClear
                    , class "dc-btn dc-btn--in-btn-group"
                    ]
                    [ text "Clear" ]
                ]
            , pre
                [ class "ace-edit" ]
                [ node "ace-editor"
                    [ value (getValue FieldSchema formModel.values)
                    , onChange (OnInput FieldSchema)
                    , attribute "theme" "ace/theme/dawn"
                    , attribute "mode" "ace/mode/json"
                    ]
                    []
                ]
            ]
