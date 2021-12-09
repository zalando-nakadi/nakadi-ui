module Pages.SubscriptionCreate.View exposing (FormSetup, accessEditor, eventTypesEditor, view, viewForm, viewFormClone, viewFormCreate, viewFormUpdate)

import Config exposing (appPreffix)
import Helpers.AccessEditor as AccessEditor
import Helpers.Forms exposing (..)
import Helpers.Http exposing (httpErrorToString)
import Helpers.Panel
import Helpers.Store as Store exposing (Status(..))
import Helpers.UI exposing (none)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Models exposing (AppModel)
import MultiSearch.View
import Pages.SubscriptionCreate.Messages exposing (..)
import Pages.SubscriptionCreate.Models exposing (..)
import Pages.SubscriptionCreate.Update exposing (searchConfig)
import Pages.SubscriptionDetails.Help as Help


view : AppModel -> Html Msg
view model =
    let
        formModel =
            model.subscriptionCreatePage

        notFound id =
            div []
                [ Helpers.Panel.errorMessage
                    "Subscription not found"
                    ("Subscription with id \"" ++ id ++ "\" not found.")
                ]

        findSubscription id content =
            case Store.get id model.subscriptionStore of
                Nothing ->
                    notFound id

                Just subscription ->
                    content

        formContainer content =
            div [ class "form-create__form dc-card dc-row dc-row--align--center" ]
                [ content ]
    in
    Helpers.Panel.loadingStatus model.eventTypeStore <|
        Helpers.Panel.loadingStatus model.subscriptionStore <|
            case formModel.operation of
                Create ->
                    formContainer <|
                        viewFormCreate model

                Update id ->
                    findSubscription id <|
                        formContainer <|
                            viewFormUpdate model

                Clone id ->
                    findSubscription id <|
                        formContainer <|
                            viewFormClone model


viewFormCreate : AppModel -> Html Msg
viewFormCreate model =
    viewForm model
        { formTitle = "Create Subscription"
        , successMessage = "Subscription Created!"
        , updateMode = False
        }


viewFormUpdate : AppModel -> Html Msg
viewFormUpdate model =
    viewForm model
        { formTitle = "Update Subscription"
        , successMessage = "Subscription Updated!"
        , updateMode = True
        }


viewFormClone : AppModel -> Html Msg
viewFormClone model =
    viewForm model
        { formTitle = "Clone Subscription"
        , successMessage = "Subscription Cloned!"
        , updateMode = False
        }


type alias FormSetup =
    { formTitle : String
    , successMessage : String
    , updateMode : Bool
    }


viewForm : AppModel -> FormSetup -> Html Msg
viewForm model setup =
    let
        { formTitle, successMessage, updateMode } =
            setup

        formModel =
            model.subscriptionCreatePage

        appsInfoUrl =
            model.userStore.user.settings.appsInfoUrl

        usersInfoUrl =
            model.userStore.user.settings.usersInfoUrl

        teamsInfoUrl =
            model.userStore.user.settings.teamsInfoUrl

        cursosId =
            "subscriptionCursorFileSelector"
    in
    div [ class "dc-column form-create__form-container" ]
        [ div []
            [ h4 [ class "dc-h4 dc--text-center" ] [ text formTitle ]
            , textInput formModel
                FieldConsumerGroup
                OnInput
                "Consumer Group"
                "Example: staging-1"
                ""
                Help.consumerGroup
                Optional
                (if updateMode then
                    Disabled

                 else
                    Enabled
                )
            , textInput formModel
                FieldOwningApplication
                OnInput
                "Owning Application"
                ("Example: " ++ appPreffix ++ "price-updater")
                ("App name registered in YourTurn with '" ++ appPreffix ++ "' prefix")
                Help.owningApplication
                Required
                (if updateMode then
                    Disabled

                 else
                    Enabled
                )
            , if updateMode then
                none

              else
                selectInput formModel
                    FieldReadFrom
                    OnInput
                    "Read from"
                    ""
                    Help.readFrom
                    Required
                    Enabled
                    allReadFrom
            , if
                not updateMode
                    && getValue FieldReadFrom formModel.values
                    == readFrom.cursors
              then
                div []
                    [ areaInput formModel
                        FieldCursors
                        OnInput
                        "Initial cursors"
                        "Example:\n[{\n\"event_type\":\"shop.updater.changed\",\n\"partition\":\"0\",\n\"offset\":\"00000000000123456\"\n},{\n...\n}]"
                        "Upload JSON or input cursors in this format: [{\"event_type\":\"shop.updater.changed\", \"partition\":\"0\", \"offset\":\"00000000000123456\"},{...}]"
                        Help.cursors
                        Required
                        (if updateMode then
                            Disabled

                         else
                            Enabled
                        )
                    , if updateMode then
                        none

                      else
                        div [ class "form-create__input-block" ]
                            [ input
                                [ class "dc-input"
                                , type_ "file"
                                , id cursosId
                                , onInput (FileSelected cursosId)
                                , accept ".json"
                                ]
                                []
                            ]
                    , case formModel.fileLoaderError of
                        Nothing ->
                            none

                        Just err ->
                            span [ class "dc--text-error" ] [ text (httpErrorToString err) ]
                    ]

              else
                none
            , eventTypesEditor updateMode model
            , accessEditor appsInfoUrl usersInfoUrl teamsInfoUrl formModel
            , hr [ class "dc-divider" ] []
            , div [ class "dc-toast__content dc-toast__content--success" ]
                [ text successMessage ]
                |> Helpers.Panel.loadingStatus formModel
            , buttonPanel formTitle Submit Reset FieldEventTypes formModel
            ]
        ]


accessEditor : String -> String -> String -> Model -> Html Msg
accessEditor appsInfoUrl usersInfoUrl teamsInfoUrl formModel =
    AccessEditor.view
        { appsInfoUrl = appsInfoUrl
        , usersInfoUrl = usersInfoUrl
        , teamsInfoUrl = teamsInfoUrl
        , showWrite = False
        , showAnyToken = True
        , help = Help.authorization
        }
        AccessEditorMsg
        formModel.accessEditor


eventTypesEditor : Bool -> AppModel -> Html Msg
eventTypesEditor isDisabled model =
    let
        formModel =
            model.subscriptionCreatePage

        eventTypeList =
            model.eventTypeStore
                |> Store.items
                |> List.map (\et -> option [ value et.name ] [])
    in
    inputFrame FieldEventTypes
        "Event Types"
        "List of Event Type names separated by space, new line, or comma."
        Help.eventTypes
        Required
        formModel
    <|
        if isDisabled then
            textarea
                [ value (getValue FieldEventTypes formModel.values)
                , id (inputId formModel.formId FieldEventTypes)
                , validationClass FieldEventTypes "dc-textarea dc-textarea--disabled" formModel
                , disabled True
                , tabindex 2
                ]
                []

        else
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
                    , id (inputId formModel.formId FieldEventTypes)
                    , validationClass FieldEventTypes "dc-textarea" formModel
                    , tabindex 2
                    ]
                    []
                ]
