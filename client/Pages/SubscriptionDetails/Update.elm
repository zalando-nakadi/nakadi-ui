module Pages.SubscriptionDetails.Update exposing (callDelete, modelToRoute, routeToModel, setInputKey, setInputValue, submitOffset, update)

import Config
import Constants
import Dict
import Dom
import Helpers.Store as Store exposing (loadStore, onFetchErr, onFetchOk, onFetchStart)
import Helpers.Task exposing (dispatch)
import Http
import Json.Encode
import Keyboard.Extra
import Pages.SubscriptionDetails.Messages exposing (Msg(..))
import Pages.SubscriptionDetails.Models exposing (Model, Tabs(..), initialModel)
import Routing.Models exposing (Route(..))
import Stores.Cursor
import Stores.SubscriptionCursors exposing (fetchCursors)
import Stores.SubscriptionStats exposing (config, fetchStats)
import Task
import User.Commands exposing (logoutIfExpired)


update : Msg -> Model -> ( Model, Cmd Msg, Route )
update message model =
    let
        ( newModel, cmd ) =
            case message of
                OnRouteChange route ->
                    let
                        newModel =
                            routeToModel route model

                        cmd =
                            if newModel.id == model.id then
                                Cmd.none

                            else
                                Cmd.batch
                                    [ dispatch LoadStats
                                    , dispatch LoadCursors
                                    ]
                    in
                    ( newModel, cmd )

                LoadStats ->
                    let
                        statsStoreTmp =
                            onFetchStart model.statsStore

                        statsStore =
                            { statsStoreTmp
                                | params = Dict.singleton Constants.id model.id
                            }
                    in
                    ( { model | statsStore = statsStore }, fetchStats StatsLoaded model.id )

                StatsLoaded result ->
                    case result of
                        Ok list ->
                            let
                                newStore =
                                    loadStore (Stores.SubscriptionStats.config Dict.empty) list model.statsStore

                                newModel =
                                    { model
                                        | statsStore = onFetchOk newStore
                                    }
                            in
                            ( newModel, Cmd.none )

                        Err error ->
                            ( { model | statsStore = onFetchErr model.statsStore error }
                            , logoutIfExpired error
                            )

                OpenDeletePopup ->
                    let
                        newDeletePopup =
                            initialModel.deletePopup

                        openedDeletePopup =
                            { newDeletePopup | isOpen = True }
                    in
                    ( { model | deletePopup = openedDeletePopup }, Cmd.none )

                CloseDeletePopup ->
                    ( { model | deletePopup = initialModel.deletePopup }, Cmd.none )

                ConfirmDelete ->
                    let
                        deletePopup =
                            model.deletePopup

                        newPopup =
                            { deletePopup | deleteCheckbox = not model.deletePopup.deleteCheckbox }
                    in
                    ( { model | deletePopup = newPopup }, Cmd.none )

                Delete ->
                    ( { model | deletePopup = Store.onFetchStart model.deletePopup }, callDelete model.id )

                DeleteDone result ->
                    case result of
                        Ok () ->
                            ( { model | deletePopup = Store.onFetchStart model.deletePopup }
                            , Cmd.batch
                                [ dispatch OutOnSubscriptionDeleted
                                , dispatch CloseDeletePopup
                                ]
                            )

                        Err error ->
                            ( { model | deletePopup = Store.onFetchErr model.deletePopup error }, logoutIfExpired error )

                TabChange tab ->
                    ( { model | tab = tab }, Cmd.none )

                OutOnSubscriptionDeleted ->
                    ( model, Cmd.none )

                LoadCursors ->
                    let
                        cursorsStoreTmp =
                            onFetchStart model.cursorsStore

                        cursorsStore =
                            { cursorsStoreTmp
                                | params = Dict.singleton Constants.id model.id
                            }
                    in
                    ( { model | cursorsStore = cursorsStore }, fetchCursors CursorsLoaded model.id )

                CursorsLoaded result ->
                    case result of
                        Ok list ->
                            let
                                newStore =
                                    loadStore (Stores.SubscriptionCursors.config Dict.empty) list model.cursorsStore

                                newModel =
                                    { model
                                        | cursorsStore = onFetchOk newStore
                                    }
                            in
                            ( newModel, Cmd.none )

                        Err error ->
                            ( { model | cursorsStore = onFetchErr model.cursorsStore error }
                            , logoutIfExpired error
                            )

                EditOffset partition offset ->
                    ( { model | editOffsetInput = Store.onFetchReset model.editOffsetInput }
                        |> setInputKey (Just partition)
                    , Dom.focus "subscriptionEditOffset"
                        |> Task.attempt (always (EditOffsetChange offset))
                    )

                EditOffsetChange value ->
                    ( setInputValue value model, Cmd.none )

                EditOffsetCancel ->
                    ( setInputKey Nothing model, Cmd.none )

                EditOffsetSubmit ->
                    ( { model | editOffsetInput = Store.onFetchStart model.editOffsetInput }, submitOffset model )

                OffsetKeyDown key ->
                    let
                        cmd =
                            case Keyboard.Extra.fromCode key of
                                Keyboard.Extra.Enter ->
                                    dispatch EditOffsetSubmit

                                Keyboard.Extra.Escape ->
                                    dispatch EditOffsetCancel

                                _ ->
                                    Cmd.none
                    in
                    ( model, cmd )

                ResetOffsetDone result ->
                    case result of
                        Ok () ->
                            ( { model | editOffsetInput = Store.onFetchOk model.editOffsetInput }
                            , Cmd.batch
                                [ dispatch Refresh
                                , dispatch EditOffsetCancel
                                ]
                            )

                        Err error ->
                            ( { model | editOffsetInput = Store.onFetchErr model.editOffsetInput error }, logoutIfExpired error )

                Refresh ->
                    ( model
                    , Cmd.batch
                        [ dispatch LoadStats
                        , dispatch LoadCursors
                        ]
                    )

                OutRefreshSubscriptions ->
                    ( model, dispatch LoadStats )

                OutAddToFavorite str ->
                    ( model, Cmd.none )

                OutRemoveFromFavorite str ->
                    ( model, Cmd.none )
    in
    ( newModel, cmd, modelToRoute newModel )


modelToRoute : Model -> Route
modelToRoute model =
    SubscriptionDetailsRoute { id = model.id }
        { tab =
            if model.tab == StatsTab then
                Nothing

            else
                Just model.tab
        }


routeToModel : Route -> Model -> Model
routeToModel route model =
    case route of
        SubscriptionDetailsRoute params query ->
            { model
                | id = params.id
                , tab = query.tab |> Maybe.withDefault initialModel.tab
            }

        _ ->
            model


callDelete : String -> Cmd Msg
callDelete name =
    Http.request
        { method = "DELETE"
        , headers = []
        , url = Config.urlNakadiApi ++ "subscriptions/" ++ Http.encodeUri name
        , body = Http.emptyBody
        , expect = Http.expectStringResponse (always (Ok ()))
        , timeout = Nothing
        , withCredentials = False
        }
        |> Http.send DeleteDone


submitOffset : Model -> Cmd Msg
submitOffset model =
    let
        id =
            model.id

        eventTypeName =
            case model.editOffsetInput.editPartition of
                Nothing ->
                    Constants.emptyString

                Just key ->
                    key |> String.split "#" |> List.head |> Maybe.withDefault Constants.emptyString

        partition =
            case model.editOffsetInput.editPartition of
                Nothing ->
                    Constants.emptyString

                Just key ->
                    key |> String.split "#" |> List.reverse |> List.head |> Maybe.withDefault Constants.emptyString

        offset =
            model.editOffsetInput.editPartitionValue

        cursor =
            Stores.Cursor.SubscriptionCursor eventTypeName partition offset

        body =
            Http.jsonBody <|
                Json.Encode.object
                    [ ( "items"
                      , Json.Encode.list
                            [ Stores.Cursor.subscriptionCursorEncoder cursor ]
                      )
                    ]
    in
    Http.request
        { method = "PATCH"
        , headers = []
        , url = Config.urlNakadiApi ++ "subscriptions/" ++ Http.encodeUri id ++ "/cursors"
        , body = body
        , expect = Http.expectStringResponse (always (Ok ()))
        , timeout = Nothing
        , withCredentials = False
        }
        |> Http.send ResetOffsetDone


setInputKey : Maybe String -> Model -> Model
setInputKey key model =
    let
        editOffsetInput =
            model.editOffsetInput

        newEditOffsetInput =
            { editOffsetInput | editPartition = key }
    in
    { model | editOffsetInput = newEditOffsetInput }


setInputValue : String -> Model -> Model
setInputValue val model =
    let
        editOffsetInput =
            model.editOffsetInput

        newEditOffsetInput =
            { editOffsetInput | editPartitionValue = val }
    in
    { model | editOffsetInput = newEditOffsetInput }
