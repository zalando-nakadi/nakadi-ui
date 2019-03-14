module Pages.SubscriptionCreate.Update exposing (authorizationFromSubscription, checkConsumerGroupFormat, checkCursors, checkEventTypesExist, cloneSubscription, formToRequestBody, isNotEmpty, post, put, searchConfig, searchEvenType, stringToJsonList, stringToList, update, updateSubscription, validate)

import Config
import Constants exposing (emptyString)
import Debug exposing (toString)
import Dict
import Dom
import Helpers.AccessEditor as AccessEditor
import Helpers.Forms exposing (..)
import Helpers.Http exposing (getString)
import Helpers.Store as Store
import Helpers.Task exposing (dispatch)
import Http
import Json.Decode
import Json.Encode as Json
import List.Extra
import MultiSearch.Messages
import MultiSearch.Models exposing (Config, SearchItem(..))
import MultiSearch.Update
import Pages.SubscriptionCreate.Messages exposing (..)
import Pages.SubscriptionCreate.Models exposing (..)
import Regex
import Stores.Authorization exposing (Authorization, userAuthorization)
import Stores.Cursor
import Stores.EventType
import Stores.Subscription
import Stores.SubscriptionCursors
import Task
import User.Models exposing (User)


searchConfig : Stores.EventType.Model -> Config
searchConfig eventTypeStore =
    { searchFunc = searchEvenType eventTypeStore
    , itemHeight = 50
    , dropdownHeight = 300
    , inputId = "addEventType-input"
    , dropdownId = "addEventType-dropdown"
    , hint = "Start typing to search event types to add"
    , placeholder = "Add event type"
    }


update : Msg -> Model -> Stores.EventType.Model -> Stores.Subscription.Model -> User -> ( Model, Cmd Msg )
update message model eventTypeStore subscriptionStore user =
    case message of
        OnInput field value ->
            let
                values =
                    setValue field value model.values
            in
            ( { model | values = values }, dispatch Validate )

        Validate ->
            ( validate model eventTypeStore, Cmd.none )

        Submit ->
            case model.operation of
                Create ->
                    ( Store.onFetchStart model, model |> formToRequestBody |> post )

                Clone id ->
                    ( Store.onFetchStart model, model |> formToRequestBody |> post )

                Update id ->
                    ( Store.onFetchStart model, model |> formToRequestBody |> put id )

        Reset ->
            let
                focus =
                    Dom.focus "subscriptionCreateFormFieldConsumerGroup"
                        |> Task.attempt FocusResult

                authorization maybeId =
                    authorizationFromSubscription maybeId subscriptionStore user.id

                setAuthEditorCmd maybeId =
                    dispatch (AccessEditorMsg (AccessEditor.Set (authorization maybeId)))

                loadCursorsCmd id =
                    dispatch (CursorsStoreMsg (Store.SetParams [ ( Constants.id, id ) ]))

                ( newModel, cmds ) =
                    case model.operation of
                        Create ->
                            ( initialModel
                            , [ focus, setAuthEditorCmd Nothing ]
                            )

                        Update id ->
                            ( updateSubscription subscriptionStore id model
                            , [ setAuthEditorCmd (Just id) ]
                            )

                        Clone id ->
                            ( cloneSubscription subscriptionStore id model
                            , [ focus
                              , setAuthEditorCmd (Just id)
                              , loadCursorsCmd id
                              ]
                            )
            in
            ( newModel, Cmd.batch cmds )

        FocusResult result ->
            ( model, Cmd.none )

        ClearEventTypes ->
            let
                values =
                    setValue FieldEventTypes emptyString model.values
            in
            ( { model | values = values }, dispatch Validate )

        FormatEventTypes ->
            let
                types =
                    model.values
                        |> getValue FieldEventTypes
                        |> stringToList
                        |> String.join ",\n"

                values =
                    setValue FieldEventTypes types model.values
            in
            ( { model | values = values }, dispatch Validate )

        SubmitResponse result ->
            case result of
                Ok id ->
                    ( Store.onFetchOk model, dispatch (OutSubscriptionCreated id) )

                Err error ->
                    ( Store.onFetchErr model error, Cmd.none )

        AddEventTypeWidgetMsg subMsg ->
            let
                ( subModel, cmd ) =
                    MultiSearch.Update.update (searchConfig eventTypeStore) subMsg model.addEventTypeWidget
            in
            case subMsg of
                MultiSearch.Messages.Selected (SearchItemEventType eventType starred) ->
                    let
                        eventTypes =
                            model.values
                                |> getValue FieldEventTypes
                                |> String.trim

                        updatedEventTypes =
                            if eventTypes |> String.isEmpty then
                                eventType.name

                            else
                                eventTypes ++ "\n" ++ eventType.name
                    in
                    ( model
                    , Cmd.batch
                        [ dispatch (AddEventTypeWidgetMsg MultiSearch.Messages.ClearInput)
                        , dispatch (OnInput FieldEventTypes updatedEventTypes)
                        ]
                    )

                _ ->
                    ( { model | addEventTypeWidget = subModel }, Cmd.map AddEventTypeWidgetMsg cmd )

        FileSelected id _ ->
            ( model, getString FileLoaded ("elm:loadFileFromInput?id=" ++ id) )

        FileLoaded result ->
            case result of
                Ok str ->
                    ( { model | fileLoaderError = Nothing }, dispatch (OnInput FieldCursors str) )

                Err error ->
                    ( { model | fileLoaderError = Just error }, Cmd.none )

        AccessEditorMsg subMsg ->
            let
                ( newSubModel, newSubMsg ) =
                    AccessEditor.update subMsg model.accessEditor
            in
            ( { model | accessEditor = newSubModel }, Cmd.map AccessEditorMsg newSubMsg )

        OnRouteChange operation ->
            ( { model | operation = operation }, dispatch Reset )

        OutSubscriptionCreated name ->
            ( model, Cmd.none )

        CursorsStoreMsg subMsg ->
            let
                ( subModel, msCmd ) =
                    Stores.SubscriptionCursors.update subMsg model.cursorsStore

                cursors =
                    subModel
                        |> Store.items
                        |> List.map Stores.Cursor.subscriptionCursorEncoder
                        |> Json.list
                        |> Json.encode 1

                values =
                    if subModel.status == Store.Loaded then
                        model.values
                            |> setValue FieldCursors cursors

                    else
                        model.values
            in
            ( { model | cursorsStore = subModel, values = values }
            , Cmd.map CursorsStoreMsg msCmd
            )


validate : Model -> Stores.EventType.Model -> Model
validate model eventTypeStore =
    let
        errors =
            Dict.empty
                |> checkConsumerGroupFormat model
                |> checkEventTypesExist model eventTypeStore
                |> checkCursors model
                |> isNotEmpty FieldEventTypes model
                |> isNotEmpty FieldOwningApplication model
    in
    { model | validationErrors = errors }


isNotEmpty : Field -> Model -> ErrorsDict -> ErrorsDict
isNotEmpty field model dict =
    if String.isEmpty (String.trim (getValue field model.values)) then
        Dict.insert (toString field) "This field is required" dict

    else
        dict


checkConsumerGroupFormat : Model -> ErrorsDict -> ErrorsDict
checkConsumerGroupFormat model dict =
    let
        name =
            model.values |> getValue FieldConsumerGroup |> String.trim

        pattern =
            Regex.regex "^[-0-9a-zA-Z_]*$"
    in
    if Regex.contains pattern name then
        dict

    else
        Dict.insert (toString FieldConsumerGroup) "Wrong format." dict


checkEventTypesExist : Model -> Stores.EventType.Model -> ErrorsDict -> ErrorsDict
checkEventTypesExist model eventTypeStore dict =
    let
        notFoundTypes =
            model.values
                |> getValue FieldEventTypes
                |> stringToList
                |> List.filter (\name -> not (Store.has name eventTypeStore))
                |> String.join ", "
    in
    if String.isEmpty notFoundTypes then
        dict

    else
        Dict.insert (toString FieldEventTypes) ("Event Type(s) not found: " ++ notFoundTypes) dict


checkCursors : Model -> ErrorsDict -> ErrorsDict
checkCursors model dict =
    let
        cursors =
            model.values
                |> getValue FieldCursors
                |> String.trim

        decodedCursors =
            cursors
                |> Json.Decode.decodeString
                    (Json.Decode.list Stores.Cursor.subscriptionCursorDecoder)

        errorMessage =
            if String.isEmpty cursors then
                "This field is required if \"Read From\" field is set to \"cursors\""

            else
                case decodedCursors of
                    Err error ->
                        error

                    Ok parsedCursors ->
                        emptyString
    in
    if
        (getValue FieldReadFrom model.values == readFrom.cursors)
            && not (String.isEmpty errorMessage)
    then
        Dict.insert (toString FieldCursors) errorMessage dict

    else
        dict


formToRequestBody : Model -> Json.Value
formToRequestBody model =
    let
        eventTypes =
            model.values
                |> getValue FieldEventTypes
                |> stringToJsonList

        asString field =
            model.values
                |> getValue field
                |> String.trim
                |> Json.string

        cursors =
            model.values
                |> getValue FieldCursors
                |> String.trim
                |> Json.Decode.decodeString
                    (Json.Decode.list Stores.Cursor.subscriptionCursorDecoder)
                |> Result.withDefault []
                |> List.map Stores.Cursor.subscriptionCursorEncoder
                |> Json.list

        auth =
            AccessEditor.unflatten model.accessEditor.authorization
                |> Stores.Authorization.encoder

        fields =
            [ ( "owning_application", asString FieldOwningApplication )
            , ( "read_from", asString FieldReadFrom )
            , ( "event_types", eventTypes )
            , ( "authorization", auth )
            ]

        enrichment =
            if getValue FieldReadFrom model.values /= readFrom.cursors then
                []

            else
                [ ( "initial_cursors", cursors ) ]

        consumerGroupValue =
            model.values
                |> getValue FieldConsumerGroup
                |> String.trim

        -- Do not send "consumer_group" key at all if its value is empty string
        consumerGroup =
            if String.isEmpty consumerGroupValue then
                []

            else
                [ ( "consumer_group", Json.string consumerGroupValue ) ]
    in
    Json.object (List.concat [ consumerGroup, fields, enrichment ])


post : Json.Value -> Cmd Msg
post body =
    Http.request
        { method = "POST"
        , headers = []
        , url = Config.urlNakadiApi ++ "subscriptions"
        , body = Http.jsonBody body
        , expect = Http.expectJson (Json.Decode.field "id" Json.Decode.string)
        , timeout = Nothing
        , withCredentials = False
        }
        |> Http.send SubmitResponse


put : String -> Json.Value -> Cmd Msg
put id body =
    Http.request
        { method = "PUT"
        , headers = []
        , url = Config.urlNakadiApi ++ "subscriptions/" ++ id
        , body = Http.jsonBody body
        , expect = Http.expectStringResponse (\response -> Ok id)
        , timeout = Nothing
        , withCredentials = False
        }
        |> Http.send SubmitResponse


stringToList : String -> List String
stringToList str =
    str
        |> Regex.split Regex.All (Regex.regex "[\\s\\n\\,]")
        |> List.map (Regex.replace Regex.All (Regex.regex "['\"]") (\_ -> ""))
        |> List.map String.trim
        |> List.filter (String.isEmpty >> not)
        |> List.Extra.unique


stringToJsonList : String -> Json.Value
stringToJsonList str =
    str
        |> stringToList
        |> List.map Json.string
        |> Json.list


searchEvenType : Stores.EventType.Model -> String -> List SearchItem
searchEvenType eventTypeStore filter =
    let
        results =
            eventTypeStore
                |> Store.items
                |> List.filter (\et -> String.contains filter (String.toLower et.name))
                |> List.map (\et -> SearchItemEventType et False)
    in
    if String.isEmpty filter then
        []

    else
        results


updateSubscription : Stores.Subscription.Model -> String -> Model -> Model
updateSubscription subscriptionStore id model =
    let
        maybeSubscription =
            Store.get id subscriptionStore

        values =
            case maybeSubscription of
                Just subscription ->
                    copyValues subscription

                Nothing ->
                    initialModel.values
    in
    { initialModel | values = values, cursorsStore = model.cursorsStore, operation = model.operation }


cloneSubscription : Stores.Subscription.Model -> String -> Model -> Model
cloneSubscription subscriptionStore id model =
    let
        maybeSubscription =
            Store.get id subscriptionStore

        values =
            case maybeSubscription of
                Just subscription ->
                    cloneValues subscription

                Nothing ->
                    initialModel.values
    in
    { initialModel | values = values, cursorsStore = model.cursorsStore, operation = model.operation }


authorizationFromSubscription : Maybe String -> Stores.Subscription.Model -> String -> Authorization
authorizationFromSubscription maybeId subscriptionsStore userId =
    maybeId
        |> Maybe.andThen (\id -> Store.get id subscriptionsStore)
        |> Maybe.andThen .authorization
        |> Maybe.withDefault (userAuthorization userId)
