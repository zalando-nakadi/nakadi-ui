module Pages.SubscriptionCreate.View exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Pages.SubscriptionCreate.Messages exposing (..)
import Pages.SubscriptionCreate.Models exposing (..)
import Helpers.UI exposing (helpIcon, PopupPosition(..), onSelect)
import Pages.SubscriptionDetails.Help as Help
import Models exposing (AppModel)
import Helpers.Panel
import Dict
import Helpers.Store exposing (Status(Loading))
import Constants exposing (emptyString)
import Helpers.Store as Store
import MultiSearch.View
import Pages.SubscriptionCreate.Update exposing (searchConfig)
import Json.Decode
import Helpers.FileReader as FileReader
import Helpers.AccessEditor as AccessEditor


view : AppModel -> Html Msg
view model =
    let
        formModel =
            model.subscriptionCreatePage

        findSubscription id =
            Store.get id model.subscriptionStore
    in
        Helpers.Panel.loadingStatus model.eventTypeStore <|
            Helpers.Panel.loadingStatus model.subscriptionStore <|
                case formModel.cloneId of
                    Nothing ->
                        div [ class "form-create__form dc-card dc-row dc-row--align--center" ]
                            [ viewFormCreate model ]

                    Just id ->
                        case findSubscription id of
                            Nothing ->
                                div []
                                    [ Helpers.Panel.errorMessage
                                        "Subscription not found"
                                        ("Subscription with id \"" ++ id ++ "\" not found.")
                                    ]

                            Just subscription ->
                                div [ class "form-create__form dc-card dc-row dc-row--align--center" ]
                                    [ viewFormClone model ]


viewFormCreate : AppModel -> Html Msg
viewFormCreate model =
    viewForm model
        { formTitle = "Create Subscription"
        , successMessage = "Subscription Created!"
        }


viewFormClone : AppModel -> Html Msg
viewFormClone model =
    viewForm model
        { formTitle = "Clone Subscription"
        , successMessage = "Subscription Cloned!"
        }


type alias FormSetup =
    { formTitle : String
    , successMessage : String
    }


viewForm : AppModel -> FormSetup -> Html Msg
viewForm model setup =
    let
        { formTitle, successMessage } =
            setup

        formModel =
            model.subscriptionCreatePage

        appsInfoUrl =
            model.userStore.user.settings.appsInfoUrl

        usersInfoUrl =
            model.userStore.user.settings.usersInfoUrl
    in
        div [ class "dc-column form-create__form-container" ]
            [ div []
                [ h4 [ class "dc-h4 dc--text-center" ] [ text formTitle ]
                , textInput formModel
                    FieldConsumerGroup
                    "Consumer Group"
                    "Example: staging-1"
                    ""
                    Help.consumerGroup
                    False
                    False
                , textInput formModel
                    FieldOwningApplication
                    "Owning Application"
                    "Example: stups_price-updater"
                    "App name registered in YourTurn with 'stups_' prefix"
                    Help.owningApplication
                    True
                    False
                , selectInput formModel
                    FieldReadFrom
                    "Read from"
                    ""
                    Help.readFrom
                    False
                    allReadFrom
                , if (getValue FieldReadFrom formModel.values) == readFrom.cursors then
                    div []
                        [ areaInput formModel
                            FieldCursors
                            "Initial cursors"
                            "Example: [{\"event_type\":\"shop.updater.changed\", \"partition\":\"0\", \"offset\":\"00000000000123456\"}]"
                            "Example: [{\"event_type\":\"shop.updater.changed\", \"partition\":\"0\", \"offset\":\"00000000000123456\"},{...}]"
                            Help.cursors
                            True
                            False
                        , input [ type_ "file", onFileChange FileSelected ] []
                        , case formModel.fileLoaderError of
                            Nothing ->
                                none

                            Just err ->
                                span [ class "dc--text-error" ] [ text err ]
                        ]
                  else
                    none
                , eventTypesEditor model
                , accessEditor appsInfoUrl usersInfoUrl formModel
                , hr [ class "dc-divider" ] []
                , div [ class "dc-toast__content dc-toast__content--success" ]
                    [ text successMessage ]
                    |> Helpers.Panel.loadingStatus formModel
                , buttonPanel formModel
                ]
            ]


accessEditor : String -> String -> Model -> Html Msg
accessEditor appsInfoUrl usersInfoUrl formModel =
    AccessEditor.view
        { appsInfoUrl = appsInfoUrl
        , usersInfoUrl = usersInfoUrl
        , showWrite = False
        }
        AccessEditorMsg
        formModel.accessEditor


onFileChange : (List FileReader.NativeFile -> Msg) -> Attribute Msg
onFileChange action =
    on "change" (Json.Decode.map action FileReader.parseSelectedFiles)


baseId : String
baseId =
    "subscriptionCreateForm"


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


areaInput :
    Model
    -> Field
    -> String
    -> String
    -> String
    -> List (Html Msg)
    -> Bool
    -> Bool
    -> Html Msg
areaInput formModel field inputLabel inputPlaceholder hint help isRequired isDisabled =
    inputFrame field inputLabel hint help isRequired formModel <|
        textarea
            [ onInput (OnInput field)
            , value (getValue field formModel.values)
            , validationClass field "dc-textarea" formModel
            , id (inputId field)
            , placeholder inputPlaceholder
            , tabindex 1
            , disabled isDisabled
            , rows 10
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
    in
        inputFrame field inputLabel hint help False formModel <|
            select
                [ onSelect (OnInput field)
                , validationClass field "dc-select" formModel
                , id (inputId field)
                , tabindex 1
                , disabled isDisabled
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


eventTypesEditor : AppModel -> Html Msg
eventTypesEditor model =
    let
        formModel =
            model.subscriptionCreatePage

        eventTypeList =
            model.eventTypeStore
                |> Helpers.Store.items
                |> List.map (\et -> option [ value et.name ] [])
    in
        inputFrame FieldEventTypes
            "Event Types"
            "List of Event Type names separated by space, new line, or comma."
            Help.eventTypes
            True
            formModel
        <|
            div [ class "dc-btn-group-row" ]
                [ div [ class "dc-btn-group" ]
                    [ MultiSearch.View.view (searchConfig model.eventTypeStore) formModel.addEventTypeWidget
                        |> Html.map AddEventTypeWidgetMsg
                    , div [ class "dc-btn-group" ]
                        [ button
                            [ onClick FormatEventTypes
                            , class "dc-btn dc-btn--in-btn-group"
                            ]
                            [ text "Reformat" ]
                        , button
                            [ onClick ClearEventTypes
                            , class "dc-btn dc-btn--in-btn-group"
                            ]
                            [ text "Clear All" ]
                        ]
                    ]
                , textarea
                    [ onInput (OnInput FieldEventTypes)
                    , value (getValue FieldEventTypes formModel.values)
                    , id (inputId FieldEventTypes)
                    , validationClass FieldEventTypes "dc-textarea" formModel
                    , tabindex 2
                    ]
                    []
                ]


buttonPanel : Model -> Html Msg
buttonPanel model =
    let
        submitLabel =
            "Create Subscription"

        submitBtn =
            if
                not (String.isEmpty (getValue FieldEventTypes model.values))
                    && Dict.isEmpty model.validationErrors
                    && (model.status /= Loading)
            then
                button [ onClick SubmitCreate, class "dc-btn dc-btn--primary", tabindex 3 ] [ text submitLabel ]
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
