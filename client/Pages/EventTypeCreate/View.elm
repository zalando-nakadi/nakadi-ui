module Pages.EventTypeCreate.View exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Pages.EventTypeCreate.Messages exposing (..)
import Pages.EventTypeCreate.Models exposing (..)
import Helpers.UI exposing (helpIcon, PopupPosition(..), onSelect)
import Pages.EventTypeDetails.Help as Help
import Models exposing (AppModel)
import Helpers.Panel
import Dict
import Helpers.Store exposing (Status(Loading))
import Constants exposing (emptyString)
import Helpers.Store as Store
import Stores.EventType
    exposing
        ( EventType
        , categories
        , allCategories
        , compatibilityModes
        , allModes
        , partitionStrategies
        , allAudiences
        , cleanupPolicies
        , allCleanupPolicies
        )
import Helpers.AccessEditor as AccessEditor
import Config


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


viewFormCreate : AppModel -> Html Msg
viewFormCreate model =
    viewForm model
        { updateMode = False
        , formTitle = "Create Event Type"
        , successMessage = "Event Type Created!"
        , categoriesOptions = allCategories
        , compatibilityModeOptions = allModes
        , cleanupPoliciesOptions = allCleanupPolicies
        , blockPartitionStrategy = False
        }


viewFormUpdate : AppModel -> EventType -> Html Msg
viewFormUpdate model originalEventType =
    let
        originalMode =
            (originalEventType.compatibility_mode |> Maybe.withDefault emptyString)

        compatibilityModeOptions =
            if originalMode == compatibilityModes.none then
                allModes
            else if originalMode == compatibilityModes.forward then
                [ compatibilityModes.forward
                , compatibilityModes.compatible
                ]
            else
                [ compatibilityModes.compatible ]

        blockPartitionStrategy =
            (originalEventType.partition_strategy |> Maybe.withDefault emptyString)
                /= partitionStrategies.random

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
            { updateMode = True
            , formTitle = "Update Event Type"
            , successMessage = "Event Type Updated!"
            , categoriesOptions = categoriesOptions
            , compatibilityModeOptions = compatibilityModeOptions
            , cleanupPoliciesOptions = cleanupPoliciesOptions
            , blockPartitionStrategy = blockPartitionStrategy
            }


viewFormClone : AppModel -> EventType -> Html Msg
viewFormClone model originalEventType =
    viewForm model
        { updateMode = False
        , formTitle = "Clone Event Type"
        , successMessage = "Event Type Cloned!"
        , categoriesOptions = allCategories
        , compatibilityModeOptions = allModes
        , cleanupPoliciesOptions = allCleanupPolicies
        , blockPartitionStrategy = False
        }


type alias FormSetup =
    { updateMode : Bool
    , formTitle : String
    , successMessage : String
    , categoriesOptions : List String
    , compatibilityModeOptions : List String
    , cleanupPoliciesOptions : List String
    , blockPartitionStrategy : Bool
    }


viewForm : AppModel -> FormSetup -> Html Msg
viewForm model setup =
    let
        { updateMode, formTitle, successMessage, categoriesOptions, compatibilityModeOptions, cleanupPoliciesOptions, blockPartitionStrategy } =
            setup

        formModel =
            model.eventTypeCreatePage

        appsInfoUrl =
            model.userStore.user.settings.appsInfoUrl

        usersInfoUrl =
            model.userStore.user.settings.usersInfoUrl
    in
        div [ class "dc-column form-create__form-container" ]
            [ div [ class "" ]
                [ h4 [ class "dc-h4 dc--text-center" ] [ text formTitle ]
                , textInput formModel
                    FieldName
                    "Event Type Name"
                    "Example: bazar.price-updater.price_changed"
                    "Should be several words (with '_', '-') separated by dot."
                    Help.eventType
                    True
                    updateMode
                , textInput formModel
                    FieldOwningApplication
                    "Owning Application"
                    "Example: stups_price-updater"
                    "App name registered in YourTurn with 'stups_' prefix"
                    Help.owningApplication
                    True
                    False
                , selectInput formModel
                    FieldCategory
                    "Category"
                    ""
                    Help.category
                    False
                    categoriesOptions
                , div [ class "dc-row form-create__input-row" ]
                    [ selectInput formModel
                        FieldPartitionStrategy
                        "Partition Strategy"
                        ""
                        Help.partitionStrategy
                        blockPartitionStrategy
                        [ partitionStrategies.random
                        , partitionStrategies.hash
                        , partitionStrategies.user_defined
                        ]
                    , div
                        [ class "dc-column" ]
                        [ (if (getValue FieldPartitionStrategy formModel.values) == partitionStrategies.hash then
                            textInput formModel
                                FieldPartitionKeyFields
                                "Partition Key Fields"
                                "Example: order.user_id, order.item_id"
                                "Comma-separated list of keys."
                                Help.partitionKeyFields
                                False
                                blockPartitionStrategy
                           else
                            none
                          )
                        ]
                    ]
                , if updateMode then
                    none
                  else
                    selectInput formModel
                        FieldPartitionsNumber
                        "Number of Partitions"
                        ""
                        Help.defaultStatistic
                        False
                        (List.range 1 Config.maxPartitionNumber |> List.map toString)
                , textInput formModel
                    FieldOrderingKeyFields
                    "Ordering Key Fields"
                    "Example: order.day, order.index"
                    "Comma-separated list of keys."
                    Help.orderingKeyFields
                    False
                    False
                , selectInput formModel
                    FieldAudience
                    "Audience"
                    ""
                    Help.audience
                    False
                    allAudiences
                , selectInput formModel
                    FieldCleanupPolicy
                    "Cleanup policy"
                    (if (getValue FieldCleanupPolicy formModel.values) == cleanupPolicies.compact then
                        "Log compacted event types MUST NOT contain personal identifiable"
                            ++ " information in accordance to GDPR. If you plan to store user"
                            ++ " data permanently, check the legal department of your organization"
                     else
                        ""
                    )
                    Help.cleanupPolicy
                    False
                    cleanupPoliciesOptions
                , if (getValue FieldCleanupPolicy formModel.values) == cleanupPolicies.delete then
                    selectInput formModel
                        FieldRetentionTime
                        "Retention Time (Days)"
                        ""
                        Help.options
                        False
                        [ "2", "3", "4" ]
                  else
                    none
                , selectInput formModel
                    FieldCompatibilityMode
                    "Schema Compatibility Mode"
                    ""
                    Help.compatibilityMode
                    False
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
            , buttonPanel formModel updateMode
            ]


baseId : String
baseId =
    "eventTypeCreateForm"


inputId : Field -> String
inputId field =
    baseId ++ (toString field)


getError : Field -> Model -> Maybe String
getError field formModel =
    formModel.validationErrors
        |> Dict.get (toString field)


validationMessage : Field -> Model -> Html Msg
validationMessage field formModel =
    case getError field formModel of
        Just error ->
            div [ class "dc--text-error" ] [ text " ", text error ]

        Nothing ->
            none


validationClass : Field -> String -> Model -> Attribute Msg
validationClass field base formModel =
    case getError field formModel of
        Just error ->
            class (base ++ " dc-input--is-error dc-textarea--is-error dc-select--is-error")

        Nothing ->
            class base


inputFrame :
    Field
    -> String
    -> String
    -> List (Html Msg)
    -> Bool
    -> Model
    -> Html Msg
    -> Html Msg
inputFrame field inputLabel hint help isRequired formModel input =
    let
        fieldClass =
            "form-create__input-block form-create__field-"
                ++ (field |> toString |> String.toLower)

        requiredMark =
            if isRequired then
                span [ class "dc-label__sub" ] [ text "required" ]
            else
                none
    in
        div
            [ class fieldClass ]
            [ label [ class "dc-label" ]
                [ text inputLabel
                , helpIcon inputLabel help BottomRight
                , requiredMark
                ]
            , input
            , validationMessage field formModel
            , p [ class "dc--text-less-important" ] [ text hint ]
            ]


textInput :
    Model
    -> Field
    -> String
    -> String
    -> String
    -> List (Html Msg)
    -> Bool
    -> Bool
    -> Html Msg
textInput formModel field inputLabel inputPlaceholder hint help isRequired isDisabled =
    inputFrame field inputLabel hint help isRequired formModel <|
        input
            [ onInput (OnInput field)
            , value (getValue field formModel.values)
            , type_ "text"
            , validationClass field "dc-input" formModel
            , id (inputId field)
            , placeholder inputPlaceholder
            , tabindex 1
            , disabled isDisabled
            ]
            []


selectInput :
    Model
    -> Field
    -> String
    -> String
    -> List (Html Msg)
    -> Bool
    -> List String
    -> Html Msg
selectInput formModel field inputLabel hint help isDisabled options =
    let
        selectedValue =
            (getValue field formModel.values)

        isDisabledOrOne =
            if (List.length options) <= 1 then
                True
            else
                isDisabled
    in
        inputFrame field inputLabel hint help False formModel <|
            select
                [ onSelect (OnInput field)
                , validationClass field "dc-select" formModel
                , id (inputId field)
                , tabindex 1
                , disabled isDisabledOrOne
                ]
                (options
                    |> List.map
                        (\optionName ->
                            option
                                [ selected (selectedValue == optionName)
                                , value optionName
                                ]
                                [ text optionName ]
                        )
                )


accessEditor : String -> String -> Model -> Html Msg
accessEditor appsInfoUrl usersInfoUrl formModel =
    AccessEditor.view appsInfoUrl usersInfoUrl AccessEditorMsg formModel.accessEditor


schemaEditor : Model -> Html Msg
schemaEditor formModel =
    inputFrame FieldSchema "Schema" "" Help.schema True formModel <|
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
            , textarea
                [ onInput (OnInput FieldSchema)
                , value (getValue FieldSchema formModel.values)
                , id (inputId FieldSchema)
                , validationClass FieldSchema "dc-textarea" formModel
                , tabindex 2
                ]
                []
            ]


buttonPanel : Model -> Bool -> Html Msg
buttonPanel model updateMode =
    let
        ( submitLabel, action ) =
            if updateMode then
                ( "Update Event Type", SubmitUpdate )
            else
                ( "Create Event Type", SubmitCreate )

        submitBtn =
            if
                not (String.isEmpty (getValue FieldName model.values))
                    && Dict.isEmpty model.validationErrors
                    && (model.status /= Loading)
            then
                button [ onClick action, class "dc-btn dc-btn--primary", tabindex 3 ] [ text submitLabel ]
            else
                button [ disabled True, class "dc-btn dc-btn--disabled" ] [ text submitLabel ]
    in
        div []
            [ submitBtn
            , button [ onClick Reset, class "dc-btn panel--right-float", tabindex 4 ] [ text "Reset" ]
            ]


none : Html Msg
none =
    text emptyString
