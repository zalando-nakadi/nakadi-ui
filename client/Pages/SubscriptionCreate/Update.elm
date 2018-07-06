module Pages.SubscriptionCreate.Update exposing (..)

import Pages.SubscriptionCreate.Messages exposing (..)
import Pages.SubscriptionCreate.Models exposing (..)
import Http
import Dict
import Json.Encode as Json
import Helpers.Store as Store
import Config
import Helpers.Task exposing (dispatch)
import Json.Decode
import Stores.EventType
import Stores.Subscription
import Stores.SubscriptionCursors
import Stores.Cursor
import Dom
import Task
import Regex
import Constants exposing (emptyString)
import MultiSearch.Messages
import MultiSearch.Update
import MultiSearch.Models exposing (SearchItem(SearchItemEventType), Config)
import List.Extra
import Helpers.FileReader as FileReader


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


update : Msg -> Model -> Stores.EventType.Model -> Stores.Subscription.Model -> ( Model, Cmd Msg )
update message model eventTypeStore subscriptionStore =
    case message of
        OnInput field value ->
            let
                values =
                    setValue field value model.values
            in
                ( { model | values = values }, dispatch Validate )

        Validate ->
            ( validate model eventTypeStore, Cmd.none )

        SubmitCreate ->
            ( Store.onFetchStart model, submitCreate model )

        Reset ->
            let
                newModel =
                    case model.cloneId of
                        Nothing ->
                            initialModel

                        Just id ->
                            cloneSubscription subscriptionStore id model
            in
                ( newModel
                , Dom.focus "subscriptionCreateFormFieldConsumerGroup"
                    |> Task.attempt FocusResult
                )

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

        FileSelected files ->
            case List.head files of
                Nothing ->
                    ( model, Cmd.none )

                Just file ->
                    ( model, Task.attempt FileLoaded <| FileReader.readAsTextFile file.blob )

        FileLoaded result ->
            case result of
                Ok str ->
                    ( { model | fileLoaderError = Nothing }, dispatch (OnInput FieldCursors str) )

                Err error ->
                    ( { model | fileLoaderError = Just (FileReader.prettyPrint error) }, Cmd.none )

        OnRouteChange maybeId ->
            let
                cmd =
                    case maybeId of
                        Nothing ->
                            dispatch Reset

                        Just id ->
                            dispatch (CursorsStoreMsg (((Store.SetParams [ ( Constants.id, id ) ]))))
            in
                ( { model | cloneId = maybeId }, cmd )

        OutSubscriptionCreated name ->
            ( model, Cmd.none )

        CursorsStoreMsg subMsg ->
            let
                ( subModel, msCmd ) =
                    Stores.SubscriptionCursors.update subMsg model.cursorsStore

                cmd =
                    dispatch Reset
                        |> Store.cmdIfDone subMsg
            in
                ( { model | cursorsStore = subModel }
                , Cmd.batch [ Cmd.map CursorsStoreMsg msCmd, cmd ]
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


submitCreate : Model -> Cmd Msg
submitCreate model =
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

        fields =
            [ ( "owning_application", asString FieldOwningApplication )
            , ( "read_from", asString FieldReadFrom )
            , ( "event_types", eventTypes )
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

        body =
            Json.object (List.concat [ consumerGroup, fields, enrichment ])
    in
        post body


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


cloneSubscription : Stores.Subscription.Model -> String -> Model -> Model
cloneSubscription subscriptionStore id model =
    let
        maybeSubscription =
            Store.get id subscriptionStore

        cursors =
            model.cursorsStore
                |> Store.items
                |> List.map Stores.Cursor.subscriptionCursorEncoder
                |> Json.list
                |> Json.encode 1

        values =
            case maybeSubscription of
                Just subscription ->
                    copyValues cursors subscription

                Nothing ->
                    initialModel.values
    in
        { initialModel | values = values, cursorsStore = model.cursorsStore, cloneId = model.cloneId }
