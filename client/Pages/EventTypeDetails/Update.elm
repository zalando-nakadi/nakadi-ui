module Pages.EventTypeDetails.Update exposing (..)

import Pages.EventTypeDetails.Messages exposing (Msg(..))
import Pages.EventTypeDetails.Models exposing (Model, initialModel, Tabs(..))
import Routing.Models exposing (Route(EventTypeDetailsRoute))
import Helpers.Task exposing (dispatch)
import Helpers.JsonEditor
import Helpers.Browser exposing (copyToClipboard)
import Helpers.Store as Store
import Stores.Partition
import Stores.Publisher
import Stores.Consumer
import Stores.Cursor
import Stores.CursorDistance
import Stores.EventTypeSchema
import Stores.EventTypeValidation
import User.Commands exposing (logoutIfExpired)
import Json.Encode
import Json.Decode
import Constants
import Http
import Config
import RemoteData exposing (WebData)
import HttpBuilder exposing (..)


update : Msg -> Model -> ( Model, Cmd Msg, Route )
update message model =
    let
        deletePopup =
            model.deletePopup

        ( newModel, cmd ) =
            case message of
                OnRouteChange route ->
                    let
                        updatedModel =
                            routeToModel route model

                        cmd =
                            if updatedModel.name == model.name then
                                Cmd.none
                            else
                                Cmd.batch
                                    [ dispatch CloseDeletePopup
                                    , dispatch Reload
                                    ]
                    in
                        ( updatedModel, cmd )

                Reload ->
                    ( model
                    , Cmd.batch
                        [ dispatch (TabChange model.tab)
                        , dispatch (ValidationStoreMsg (loadSubStoreMsg model.name))
                        ]
                    )

                FormatSchema enable ->
                    ( { model | formatted = enable }, Cmd.none )

                EffectiveSchema enable ->
                    ( { model | effective = enable }, Cmd.none )

                CopyToClipboard content ->
                    ( model, copyToClipboard content )

                SchemaVersionChange version ->
                    ( { model | version = Just version }, Cmd.none )

                TabChange tab ->
                    ( { model | tab = tab }
                    , case tab of
                        SchemaTab ->
                            dispatch (EventTypeSchemasStoreMsg (loadSubStoreMsg model.name))

                        PartitionsTab ->
                            dispatch (PartitionsStoreMsg (loadSubStoreMsg model.name))

                        PublisherTab ->
                            dispatch LoadPublishers

                        ConsumerTab ->
                            dispatch LoadConsumers

                        PublishTab ->
                            Cmd.none

                        AuthTab ->
                            Cmd.none
                    )

                JsonEditorMsg subMsg ->
                    let
                        ( newSubModel, newSubMsg ) =
                            Helpers.JsonEditor.update subMsg model.jsonEditor
                    in
                        ( { model | jsonEditor = newSubModel }, Cmd.map JsonEditorMsg newSubMsg )

                PartitionsStoreMsg subMsg ->
                    let
                        ( subModel, msCmd ) =
                            Stores.Partition.update subMsg model.partitionsStore

                        cmd =
                            case subMsg of
                                Store.FetchAllDone result ->
                                    dispatch LoadTotals

                                _ ->
                                    Cmd.none
                    in
                        ( { model | partitionsStore = subModel }
                        , Cmd.batch
                            [ Cmd.map PartitionsStoreMsg msCmd
                            , cmd
                            ]
                        )

                EventTypeSchemasStoreMsg subMsg ->
                    let
                        ( subModel, msCmd ) =
                            Stores.EventTypeSchema.update subMsg model.eventTypeSchemasStore
                    in
                        ( { model | eventTypeSchemasStore = subModel }, Cmd.map EventTypeSchemasStoreMsg msCmd )

                LoadPublishers ->
                    ( model, dispatch (PublishersStoreMsg (loadSubStoreMsg model.name)) )

                PublishersStoreMsg subMsg ->
                    let
                        ( newSubModel, newSubMsg ) =
                            Stores.Publisher.update subMsg model.publishersStore
                    in
                        ( { model | publishersStore = newSubModel }, Cmd.map PublishersStoreMsg newSubMsg )

                LoadConsumers ->
                    ( model, dispatch (ConsumersStoreMsg (loadSubStoreMsg model.name)) )

                ConsumersStoreMsg subMsg ->
                    let
                        ( newSubModel, newSubMsg ) =
                            Stores.Consumer.update subMsg model.consumersStore
                    in
                        ( { model | consumersStore = newSubModel }, Cmd.map ConsumersStoreMsg newSubMsg )

                LoadTotals ->
                    let
                        totalsStore =
                            model.totalsStore
                                |> Store.onFetchStart
                                |> Store.empty

                        partitionToDistanceQuery partition =
                            { initial_cursor =
                                Stores.Cursor.Cursor
                                    partition.partition
                                    partition.oldest_available_offset
                            , final_cursor =
                                Stores.Cursor.Cursor
                                    partition.partition
                                    partition.newest_available_offset
                            }

                        cmd =
                            model.partitionsStore
                                |> Store.items
                                |> List.map partitionToDistanceQuery
                                |> Stores.CursorDistance.fetchDistance TotalsLoaded model.name
                    in
                        ( { model | totalsStore = totalsStore }, cmd )

                TotalsLoaded result ->
                    case result of
                        Ok distanceResponse ->
                            let
                                config =
                                    { getKey = (\index item -> item.initial_cursor.partition)
                                    , url = Constants.emptyString
                                    , decoder = Stores.CursorDistance.collectionDecoder
                                    , headers = []
                                    }

                                store =
                                    Store.loadStore config distanceResponse model.totalsStore
                            in
                                ( { model | totalsStore = Store.onFetchOk store }, Cmd.none )

                        Err error ->
                            ( { model | totalsStore = Store.onFetchErr model.totalsStore error }
                            , logoutIfExpired error
                            )

                ValidationStoreMsg subMsg ->
                    let
                        ( newSubModel, newSubMsg ) =
                            Stores.EventTypeValidation.update subMsg model.validationIssuesStore
                    in
                        ( { model | validationIssuesStore = newSubModel }, Cmd.map ValidationStoreMsg newSubMsg )

                EditEvent value ->
                    ( { model | editEvent = value }, Cmd.none )

                SendEvent ->
                    ( model, sendEvent SendEventResponse model.name model.editEvent )

                SendEventResponse value ->
                    ( { model | sendEventResponse = value }, Cmd.none )

                OpenDeletePopup ->
                    let
                        newDeletePopup =
                            initialModel.deletePopup

                        openedDeletePopup =
                            { newDeletePopup | isOpen = True }
                    in
                        ( { model | deletePopup = openedDeletePopup }, dispatch LoadConsumers )

                CloseDeletePopup ->
                    ( { model | deletePopup = initialModel.deletePopup }, Cmd.none )

                ConfirmDelete ->
                    let
                        newPopup =
                            { deletePopup | deleteCheckbox = not deletePopup.deleteCheckbox }
                    in
                        ( { model | deletePopup = newPopup }, Cmd.none )

                Delete ->
                    ( { model | deletePopup = Store.onFetchStart deletePopup }, callDelete model.name )

                DeleteDone result ->
                    case result of
                        Ok () ->
                            ( { model | deletePopup = Store.onFetchStart deletePopup }
                            , Cmd.batch
                                [ dispatch OutOnEventTypeDeleted
                                , dispatch CloseDeletePopup
                                ]
                            )

                        Err error ->
                            ( { model | deletePopup = Store.onFetchErr deletePopup error }, logoutIfExpired error )

                OutOnEventTypeDeleted ->
                    ( model, Cmd.none )

                OutRefreshEventTypes ->
                    ( model, Cmd.none )

                OutLoadSubscription ->
                    ( model, Cmd.none )

                OutAddToFavorite typeName ->
                    ( model, Cmd.none )

                OutRemoveFromFavorite typeName ->
                    ( model, Cmd.none )
    in
        ( newModel, cmd, modelToRoute newModel )


modelToRoute : Model -> Route
modelToRoute model =
    EventTypeDetailsRoute
        { name = model.name }
        { formatted =
            if model.formatted then
                Nothing
            else
                Just model.formatted
        , effective =
            if model.effective then
                Just model.effective
            else
                Nothing
        , tab =
            if model.tab == SchemaTab then
                Nothing
            else
                Just model.tab
        , version = model.version
        }


routeToModel : Route -> Model -> Model
routeToModel route model =
    case route of
        EventTypeDetailsRoute params query ->
            { model
                | name = params.name
                , formatted = query.formatted |> Maybe.withDefault initialModel.formatted
                , effective = query.effective |> Maybe.withDefault initialModel.effective
                , tab = query.tab |> Maybe.withDefault initialModel.tab
                , version = query.version
            }

        _ ->
            model


callDelete : String -> Cmd Msg
callDelete name =
    Http.request
        { method = "DELETE"
        , headers = []
        , url = Config.urlNakadiApi ++ "event-types/" ++ (Http.encodeUri name)
        , body = Http.emptyBody
        , expect = Http.expectStringResponse (always (Ok ()))
        , timeout = Nothing
        , withCredentials = False
        }
        |> Http.send DeleteDone


loadSubStoreMsg : String -> Store.Msg entity
loadSubStoreMsg name =
    Store.SetParams [ ( Constants.eventTypeName, name ) ]


sendEvent : (WebData String -> msg) -> String -> String -> Cmd msg
sendEvent tagger name event =
    case (Json.Decode.decodeString Json.Decode.value event) of
        Ok val ->
            Http.request
                { method = "POST"
                , headers = []
                , url = Config.urlNakadiApi ++ "event-types/" ++ (Http.encodeUri name) ++ "/events"
                , body = Http.jsonBody val
                , expect = Http.expectString
                , timeout = Nothing
                , withCredentials = False
                }
                |> RemoteData.sendRequest
                |> Cmd.map tagger

        Err err ->
            Debug.log ("event JSON decode error:" ++ err) Cmd.none
