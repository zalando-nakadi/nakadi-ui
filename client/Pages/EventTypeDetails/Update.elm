module Pages.EventTypeDetails.Update exposing (callDelete, loadSubStoreMsg, modelToRoute, routeToModel, update)

import Config
import Constants
import Helpers.Http exposing (postString)
import Helpers.JsonEditor
import Helpers.Store as Store
import Helpers.Task exposing (dispatch)
import Http
import Pages.EventTypeDetails.Messages exposing (Msg(..))
import Pages.EventTypeDetails.Models exposing (Model, Tabs(..), initialModel)
import Pages.EventTypeDetails.PublishTab
import Pages.EventTypeDetails.QueryTab exposing (deleteQuery, loadQuery)
import RemoteData exposing (RemoteData(..), isFailure, isSuccess)
import Routing.Models exposing (Route(..))
import Stores.Consumer
import Stores.ConsumingQuery
import Stores.Cursor
import Stores.CursorDistance
import Stores.EventTypeSchema
import Stores.EventTypeValidation
import Stores.Partition
import Url exposing (percentEncode)
import User.Commands exposing (logoutIfExpired)
import User.Models exposing (Settings)


update : Settings -> Msg -> Model -> ( Model, Cmd Msg, Route )
update settings message model =
    let
        deletePopup =
            model.deletePopup

        ( resultModel, resultCmd ) =
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
                        , dispatch (LoadQuery model.name)
                        ]
                    )

                FormatSchema enable ->
                    ( { model | formatted = enable }, Cmd.none )

                EffectiveSchema enable ->
                    ( { model | effective = enable }, Cmd.none )

                CopyToClipboard content ->
                    ( model, postString CopyToClipboardDone "elm:copyToClipboard" content )

                CopyToClipboardDone _ ->
                    ( model, Cmd.none )

                SchemaVersionChange version ->
                    ( { model | version = Just version }, Cmd.none )

                TabChange tab ->
                    ( { model | tab = tab }
                    , case tab of
                        QueryTab ->
                            Cmd.none

                        SchemaTab ->
                            dispatch (EventTypeSchemasStoreMsg (loadSubStoreMsg model.name))

                        PartitionsTab ->
                            dispatch (PartitionsStoreMsg (loadSubStoreMsg model.name))

                        ConsumerTab ->
                            Cmd.batch
                                [ dispatch LoadConsumers
                                , dispatch LoadConsumingQueries
                                ]

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

                LoadQuery id ->
                    let
                        startLoadingQuery =
                            ( { model | loadQueryResponse = Loading }
                            , loadQuery LoadQueryResponse id
                            )

                        switchTab =
                            ( { model | loadQueryResponse = Failure Http.NetworkError }
                            , if model.tab == QueryTab then
                                dispatch (TabChange SchemaTab)

                              else
                                Cmd.none
                            )
                    in
                    if settings.showNakadiSql then
                        startLoadingQuery

                    else
                        switchTab

                LoadQueryResponse resp ->
                    let
                        switchTabOnFailure =
                            if isFailure resp && model.tab == QueryTab then
                                dispatch (TabChange SchemaTab)

                            else
                                Cmd.none
                    in
                    ( { model | loadQueryResponse = resp }, switchTabOnFailure )

                LoadConsumingQueries ->
                    ( model, dispatch (ConsumingQueriesStoreMsg (loadSubStoreMsg model.name)) )

                ConsumingQueriesStoreMsg subMsg ->
                    let
                        ( newSubModel, newSubMsg ) =
                            Stores.ConsumingQuery.update subMsg model.consumingQueriesStore
                    in
                    ( { model | consumingQueriesStore = newSubModel }, Cmd.map ConsumingQueriesStoreMsg newSubMsg )

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
                                    { getKey = \index item -> item.initial_cursor.partition
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

                PublishTabMsg subMsg ->
                    let
                        ( newSubModel, newSubMsg ) =
                            Pages.EventTypeDetails.PublishTab.update subMsg model.publishTab model.name
                    in
                    ( { model | publishTab = newSubModel }, Cmd.map PublishTabMsg newSubMsg )

                OpenDeletePopup ->
                    let
                        newDeletePopup =
                            initialModel.deletePopup

                        openedDeletePopup =
                            { newDeletePopup | isOpen = True }
                    in
                    ( { model | deletePopup = openedDeletePopup }
                    , Cmd.batch [ dispatch LoadConsumers, dispatch LoadConsumingQueries ]
                    )

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

                OpenDeleteQueryPopup ->
                    ( { model
                        | deleteQueryResponse = NotAsked
                        , deleteQueryPopupCheck = False
                        , deleteQueryPopupOpen = True
                      }
                    , Cmd.none
                    )

                CloseDeleteQueryPopup ->
                    ( { model | deleteQueryPopupOpen = False }, Cmd.none )

                ConfirmQueryDelete ->
                    ( { model | deleteQueryPopupCheck = not model.deleteQueryPopupCheck }, Cmd.none )

                QueryDelete ->
                    ( model, deleteQuery QueryDeleteResponse model.name )

                QueryDeleteResponse response ->
                    let
                        cmd =
                            if response |> isSuccess then
                                Cmd.batch
                                    [ dispatch CloseDeleteQueryPopup
                                    , dispatch (LoadQuery model.name)
                                    ]

                            else
                                Cmd.none
                    in
                    ( { model | deleteQueryResponse = response }, cmd )

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
    ( resultModel, resultCmd, modelToRoute resultModel )


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
        , url = Config.urlNakadiApi ++ "event-types/" ++ percentEncode name
        , body = Http.emptyBody
        , expect = Http.expectStringResponse (always (Ok ()))
        , timeout = Nothing
        , withCredentials = False
        }
        |> Http.send DeleteDone


loadSubStoreMsg : String -> Store.Msg entity
loadSubStoreMsg name =
    Store.SetParams [ ( Constants.eventTypeName, name ) ]
