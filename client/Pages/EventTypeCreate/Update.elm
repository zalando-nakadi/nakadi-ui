module Pages.EventTypeCreate.Update exposing (authorizationFromEventType, checkNameFormat, checkNameUnique, checkPartitionKeys, checkPartitionStrategy, checkSchemaFormat, daysToRetentionTimeJson, formValuesFromEventType, isNotEmpty, post, put, stringToJsonList, submitCreate, submitUpdate, update, validate)

import Config
import Constants exposing (emptyString)
import Dict
import Dom
import Helpers.AccessEditor as AccessEditor
import Helpers.Forms exposing (..)
import Helpers.JsonPrettyPrint exposing (prettyPrintJson)
import Helpers.Store as Store
import Helpers.Task exposing (dispatch)
import Http
import Json.Decode
import Json.Encode as Json
import Pages.EventTypeCreate.Messages exposing (..)
import Pages.EventTypeCreate.Models exposing (..)
import Pages.EventTypeCreate.Query exposing (submitQueryCreate)
import Regex
import Stores.Authorization exposing (Authorization, userAuthorization)
import Stores.EventType exposing (categories, partitionStrategies)
import Stores.Partition
import Task
import User.Models exposing (User)


update : Msg -> Model -> Stores.EventType.Model -> User -> ( Model, Cmd Msg )
update message model eventTypeStore user =
    case message of
        OnInput field value ->
            let
                values =
                    setValue field value model.values
            in
            ( { model | values = values }, dispatch Validate )

        AccessEditorMsg subMsg ->
            let
                ( newSubModel, newSubMsg ) =
                    AccessEditor.update subMsg model.accessEditor
            in
            ( { model | accessEditor = newSubModel }, Cmd.map AccessEditorMsg newSubMsg )

        SchemaFormat ->
            let
                schema =
                    model.values |> getValue FieldSchema |> prettyPrintJson

                values =
                    setValue FieldSchema schema model.values
            in
            ( { model | values = values }, dispatch Validate )

        SchemaClear ->
            let
                values =
                    setValue FieldSchema emptyString model.values
            in
            ( { model | values = values }, dispatch Validate )

        Validate ->
            ( validate model eventTypeStore, Cmd.none )

        Submit ->
            case model.operation of
                Create ->
                    ( Store.onFetchStart model, submitCreate model )

                Clone name ->
                    ( Store.onFetchStart model, submitCreate model )

                Update name ->
                    ( Store.onFetchStart model, submitUpdate model )

                CreateQuery ->
                    ( Store.onFetchStart model, submitQueryCreate model )

        Reset ->
            let
                newModel =
                    case model.operation of
                        Create ->
                            initialModel

                        Update name ->
                            { initialModel
                                | operation = model.operation
                                , values = formValuesFromEventType name eventTypeStore
                            }

                        Clone name ->
                            { initialModel
                                | operation = model.operation
                                , values =
                                    formValuesFromEventType name eventTypeStore
                                        |> setValue FieldName ("clone_of_" ++ name)
                            }

                        CreateQuery ->
                            { initialModel | operation = model.operation }

                authorization =
                    case model.operation of
                        Create ->
                            authorizationFromEventType Nothing eventTypeStore user.id

                        Update name ->
                            authorizationFromEventType (Just name) eventTypeStore user.id

                        Clone name ->
                            authorizationFromEventType (Just name) eventTypeStore user.id

                        CreateQuery ->
                            authorizationFromEventType Nothing eventTypeStore user.id

                loadPartitionsCmd =
                    case model.operation of
                        Create ->
                            Cmd.none

                        Update name ->
                            Cmd.none

                        Clone name ->
                            Store.SetParams [ ( Constants.eventTypeName, name ) ]
                                |> PartitionsStoreMsg
                                |> dispatch

                        CreateQuery ->
                            Cmd.none

                cmd =
                    Cmd.batch
                        [ Dom.focus "eventTypeCreateFormFieldName" |> Task.attempt FocusResult
                        , dispatch (AccessEditorMsg (AccessEditor.Set authorization))
                        , loadPartitionsCmd
                        ]
            in
            ( newModel, cmd )

        FocusResult result ->
            ( model, Cmd.none )

        PartitionsStoreMsg subCmd ->
            let
                ( partitionsStore, newMsg ) =
                    Stores.Partition.update subCmd model.partitionsStore

                {--| Set the partitions number when partitions are loaded.
                     Set the number within the allowed range (1-max).-}
                values =
                    if partitionsStore.status == Store.Loaded then
                        model.values
                            |> setValue FieldPartitionsNumber
                                (partitionsStore
                                    |> Store.size
                                    |> Basics.clamp 1 Config.maxPartitionNumber
                                    |> String.fromInt
                                )

                    else
                        model.values
            in
            ( { model | partitionsStore = partitionsStore, values = values }, Cmd.map PartitionsStoreMsg newMsg )

        SubmitResponse result ->
            case result of
                Ok str ->
                    ( Store.onFetchOk model, dispatch (OutEventTypeCreated (getValue FieldName model.values)) )

                Err error ->
                    ( Store.onFetchErr model error, Cmd.none )

        OnRouteChange operation ->
            ( { model | operation = operation }, dispatch Reset )

        OutEventTypeCreated name ->
            ( model, Cmd.none )


formValuesFromEventType : String -> Stores.EventType.Model -> ValuesDict
formValuesFromEventType name eventTypeStore =
    let
        maybeEventType =
            Store.get name eventTypeStore
    in
    case maybeEventType of
        Nothing ->
            setValue FieldName name initialModel.values

        Just eventType ->
            loadValues eventType


authorizationFromEventType : Maybe String -> Stores.EventType.Model -> String -> Authorization
authorizationFromEventType maybeName eventTypeStore userId =
    maybeName
        |> Maybe.andThen (\name -> Store.get name eventTypeStore)
        |> Maybe.andThen .authorization
        |> Maybe.withDefault (userAuthorization userId)


validate : Model -> Stores.EventType.Model -> Model
validate model eventTypeStore =
    let
        checkAll =
            Dict.empty
                |> checkNameUnique model eventTypeStore
                |> checkNameFormat model
                |> checkPartitionStrategy model
                |> checkPartitionKeys model
                |> checkSchemaFormat model
                |> isNotEmpty FieldName model
                |> isNotEmpty FieldOwningApplication model
                |> isNotEmpty FieldSchema model
                |> isNotEmpty FieldAudience model

        errors =
            case model.operation of
                Create ->
                    checkAll

                Clone name ->
                    checkAll

                Update name ->
                    Dict.empty
                        |> checkPartitionStrategy model
                        |> checkPartitionKeys model
                        |> checkSchemaFormat model
                        |> isNotEmpty FieldSchema model
                        |> isNotEmpty FieldOwningApplication model
                        |> isNotEmpty FieldAudience model

                CreateQuery ->
                    Dict.empty
                        |> checkNameUnique model eventTypeStore
                        |> checkNameFormat model
                        |> isNotEmpty FieldName model
                        |> isNotEmpty FieldSql model
                        |> isNotEmpty FieldOwningApplication model
                        |> isNotEmpty FieldAudience model
    in
    { model | validationErrors = errors }


isNotEmpty : Field -> Model -> ErrorsDict -> ErrorsDict
isNotEmpty field model dict =
    if String.isEmpty (String.trim (getValue field model.values)) then
        Dict.insert (Debug.toString field) "This field is required" dict

    else
        dict


checkNameUnique : Model -> Stores.EventType.Model -> ErrorsDict -> ErrorsDict
checkNameUnique model eventTypeStore dict =
    if Store.has (String.trim (getValue FieldName model.values)) eventTypeStore then
        Dict.insert (Debug.toString FieldName) "Name is already used." dict

    else
        dict


checkNameFormat : Model -> ErrorsDict -> ErrorsDict
checkNameFormat model dict =
    let
        name =
            model.values |> getValue FieldName |> String.trim

        pattern =
            Regex.regex "^[a-zA-Z][-0-9a-zA-Z_]*(\\.[a-zA-Z][-0-9a-zA-Z_]*)*$"
    in
    if Regex.contains pattern name then
        dict

    else
        Dict.insert (Debug.toString FieldName) "Wrong format." dict


checkPartitionStrategy : Model -> ErrorsDict -> ErrorsDict
checkPartitionStrategy model dict =
    if
        (getValue FieldCategory model.values == categories.undefined)
            && (getValue FieldPartitionStrategy model.values == partitionStrategies.user_defined)
    then
        Dict.insert (Debug.toString FieldPartitionStrategy)
            "The 'user_defined' partitioning strategy cannot be used with event types of category 'undefined'"
            dict

    else
        dict


checkPartitionKeys : Model -> ErrorsDict -> ErrorsDict
checkPartitionKeys model dict =
    if getValue FieldPartitionStrategy model.values == partitionStrategies.hash then
        isNotEmpty FieldPartitionKeyFields model dict

    else
        dict


checkSchemaFormat : Model -> ErrorsDict -> ErrorsDict
checkSchemaFormat model dict =
    let
        schema =
            model.values |> getValue FieldSchema |> String.trim

        result =
            Json.Decode.decodeString (Json.Decode.dict Json.Decode.value) schema
    in
    case result of
        Ok value ->
            dict

        Err err ->
            Dict.insert (Debug.toString FieldSchema) ("JSON expected. " ++ Debug.toString err) dict


submitCreate : Model -> Cmd Msg
submitCreate model =
    let
        partitionKeyFields =
            model.values
                |> getValue FieldPartitionKeyFields
                |> stringToJsonList

        orderingKeyFields =
            model.values
                |> getValue FieldOrderingKeyFields
                |> stringToJsonList

        partitionsNumber =
            model.values
                |> getValue FieldPartitionsNumber
                |> String.toInt
                |> Maybe.withDefault 1
                |> Json.int

        asString field =
            model.values
                |> getValue field
                |> String.trim
                |> Json.string

        auth =
            AccessEditor.unflatten model.accessEditor.authorization
                |> Stores.Authorization.encoder

        fields =
            [ ( "name", asString FieldName )
            , ( "owning_application", asString FieldOwningApplication )
            , ( "category", asString FieldCategory )
            , ( "partition_strategy", asString FieldPartitionStrategy )
            , ( "partition_key_fields", partitionKeyFields )
            , ( "ordering_key_fields", orderingKeyFields )
            , ( "compatibility_mode", asString FieldCompatibilityMode )
            , ( "audience", asString FieldAudience )
            , ( "cleanup_policy", asString FieldCleanupPolicy )
            , ( "schema"
              , Json.object
                    [ ( "type", Json.string "json_schema" )
                    , ( "schema", asString FieldSchema )
                    ]
              )
            , ( "default_statistic"
              , Json.object
                    [ ( "messages_per_minute", Json.int 100 )
                    , ( "message_size", Json.int 100 )
                    , ( "read_parallelism", partitionsNumber )
                    , ( "write_parallelism", partitionsNumber )
                    ]
              )
            , ( "options"
              , Json.object
                    [ ( "retention_time", daysToRetentionTimeJson model.values )
                    ]
              )
            , ( "authorization", auth )
            ]

        enrichment =
            if getValue FieldCategory model.values == categories.undefined then
                []

            else
                [ ( "enrichment_strategies"
                  , Json.list
                        [ Json.string "metadata_enrichment"
                        ]
                  )
                ]

        body =
            Json.object (List.concat [ fields, enrichment ])
    in
    post body


post : Json.Value -> Cmd Msg
post body =
    Http.request
        { method = "POST"
        , headers = []
        , url = Config.urlNakadiApi ++ "event-types"
        , body = Http.jsonBody body
        , expect = Http.expectStringResponse (always (Ok ()))
        , timeout = Nothing
        , withCredentials = False
        }
        |> Http.send SubmitResponse


submitUpdate : Model -> Cmd Msg
submitUpdate model =
    let
        partitionKeyFields =
            model.values
                |> getValue FieldPartitionKeyFields
                |> stringToJsonList

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
                |> Stores.Authorization.encoder

        fields =
            [ ( "name", asString FieldName )
            , ( "owning_application", asString FieldOwningApplication )
            , ( "category", asString FieldCategory )
            , ( "partition_strategy", asString FieldPartitionStrategy )
            , ( "partition_key_fields", partitionKeyFields )
            , ( "ordering_key_fields", orderingKeyFields )
            , ( "compatibility_mode", asString FieldCompatibilityMode )
            , ( "audience", asString FieldAudience )
            , ( "cleanup_policy", asString FieldCleanupPolicy )
            , ( "schema"
              , Json.object
                    [ ( "type", Json.string "json_schema" )
                    , ( "schema", asString FieldSchema )
                    ]
              )
            , ( "options"
              , Json.object
                    [ ( "retention_time", daysToRetentionTimeJson model.values )
                    ]
              )
            , ( "authorization", auth )
            ]

        enrichment =
            if getValue FieldCategory model.values == categories.undefined then
                []

            else
                [ ( "enrichment_strategies"
                  , Json.list
                        [ Json.string "metadata_enrichment"
                        ]
                  )
                ]

        body =
            Json.object (List.concat [ fields, enrichment ])
    in
    put body (getValue FieldName model.values)


put : Json.Value -> String -> Cmd Msg
put body name =
    Http.request
        { method = "PUT"
        , headers = []
        , url = Config.urlNakadiApi ++ "event-types/" ++ Http.encodeUri name
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
        |> Maybe.withDefault defaultRetentionDays
        |> (*) Constants.msInDay
        |> Json.int
