module Pages.Partition.Update exposing (distanceFromBegin, modelToRoute, normalizeOffset, routeToModel, update)

import Constants
import Dict
import Helpers.Http exposing (postString)
import Helpers.JsonEditor as JsonEditor
import Helpers.Store as Store exposing (onFetchErr, onFetchOk, onFetchStart)
import Helpers.Task exposing (dispatch)
import Http
import Json.Decode
import Keyboard
import Pages.Partition.Messages exposing (Msg(..))
import Pages.Partition.Models
    exposing
        ( Model
        , UrlParams
        , UrlQuery
        , getOldestNewestOffsets
        , initialModel
        , initialPageSize
        , isPartitionEmpty
        )
import Routing.Models exposing (Route(..))
import Stores.Cursor
import Stores.CursorDistance
import Stores.Events exposing (fetchEvents)
import Stores.Partition exposing (Partition, fetchPartitions)
import Stores.ShiftedCursor
import Url exposing (percentEncode)
import User.Commands exposing (logoutIfExpired)


update : Msg -> Model -> ( Model, Cmd Msg, Route )
update message model =
    let
        ( resultModel, resultCmd ) =
            case message of
                OnRouteChange route ->
                    let
                        newModel =
                            routeToModel route model

                        cmd =
                            if
                                (newModel.name == model.name)
                                    && (newModel.partition == model.partition)
                                    && (newModel.offset == model.offset)
                                    && (newModel.size == model.size)
                            then
                                Cmd.none

                            else
                                dispatch LoadPartitions
                    in
                    ( newModel, cmd )

                SetFormatted enable ->
                    ( { model | formatted = enable }, Cmd.none )

                CopyToClipboard str ->
                    ( model, postString CopyToClipboardDone "elm:copyToClipboard" str )

                CopyToClipboardDone _ ->
                    ( model, Cmd.none )

                LoadPartitions ->
                    let
                        partitionsStoreTmp =
                            onFetchStart model.partitionsStore

                        partitionsStore =
                            { partitionsStoreTmp
                                | params = Dict.singleton Constants.eventTypeName model.name
                            }
                    in
                    ( { model | partitionsStore = partitionsStore }, fetchPartitions PartitionsLoaded model.name )

                PartitionsLoaded result ->
                    case result of
                        Ok list ->
                            let
                                dict =
                                    list
                                        |> List.map (\item -> ( item.partition, item ))
                                        |> Dict.fromList

                                store =
                                    model.partitionsStore

                                newStore =
                                    { store | dict = dict }

                                newModel =
                                    { model
                                        | partitionsStore = onFetchOk newStore
                                        , eventsStore = Stores.Events.initialModel
                                        , totalStore = Store.initialModel
                                    }

                                justCalculateTotalCmd partition =
                                    partition.newest_available_offset
                                        |> distanceFromBegin model.partition
                                        |> List.singleton
                                        |> Stores.CursorDistance.fetchDistance Store.FetchAllDone model.name

                                calculateTotalCmd =
                                    newStore
                                        |> Store.get model.partition
                                        |> Maybe.map justCalculateTotalCmd
                                        |> Maybe.withDefault Cmd.none
                                        |> Cmd.map TotalStoreMsg

                                cmd =
                                    if isPartitionEmpty newModel then
                                        Cmd.none

                                    else
                                        calculateTotalCmd
                            in
                            if isPartitionEmpty newModel then
                                ( newModel, Cmd.none )

                            else
                                ( newModel, calculateTotalCmd )

                        Err error ->
                            ( { model | partitionsStore = onFetchErr model.partitionsStore error }
                            , logoutIfExpired error
                            )

                TotalStoreMsg subMsg ->
                    let
                        ( newStore, newSubMsg ) =
                            Stores.CursorDistance.update subMsg model.totalStore

                        --Update time line navigator
                        justDistanceCmd partition =
                            model.offset
                                |> distanceFromBegin model.partition
                                |> List.singleton
                                |> Stores.CursorDistance.fetchDistance Store.FetchAllDone model.name
                                |> Cmd.map DistanceStoreMsg

                        distanceToCursorCmd =
                            model.partitionsStore
                                |> Store.get model.partition
                                |> Maybe.map justDistanceCmd
                                |> Maybe.withDefault Cmd.none

                        total =
                            newStore
                                |> Store.get "0"
                                |> Maybe.map .distance
                                |> Maybe.withDefault 0

                        --we cannot ask nakadi to return offset before BEGIN
                        lastPageSize =
                            min total (model.size // 2)

                        lastPageCursor partition =
                            Stores.ShiftedCursor.ShiftedCursor
                                model.partition
                                partition.newest_available_offset
                                -lastPageSize

                        -- Update link to the "Last page" by calling Nakadi shifted cursor endpoint
                        -- (First offset of the last pag = lastOffset - PageSize/2)
                        lastPageCmd =
                            model.partitionsStore
                                |> Store.get model.partition
                                |> Maybe.map lastPageCursor
                                |> Maybe.map (Stores.ShiftedCursor.fetchShiftedCursors Store.FetchAllDone model.name)
                                |> Maybe.withDefault Cmd.none
                                |> Cmd.map PageNewestCursorStoreMsg

                        backOffsetSize =
                            min total model.size

                        backOffsetCmd =
                            Stores.ShiftedCursor.ShiftedCursor
                                model.partition
                                model.offset
                                -backOffsetSize
                                |> Stores.ShiftedCursor.fetchShiftedCursors Store.FetchAllDone model.name
                                |> Cmd.map PageBackCursorStoreMsg

                        nextCmd =
                            -- if offset is virtual "END"
                            -- we try to calculate the last page and
                            -- when we receive the offset of the last page we will set it
                            -- instead of END. It will start the circle of loading page from
                            -- the beginning (load partitions stats)
                            if model.offset == "END" then
                                lastPageCmd
                                -- finally loading events and all navigation info

                            else
                                Cmd.batch
                                    [ lastPageCmd
                                    , distanceToCursorCmd
                                    , backOffsetCmd
                                    , dispatch LoadEvents
                                    ]
                    in
                    ( { model | totalStore = newStore }
                    , Cmd.batch
                        [ Cmd.map TotalStoreMsg newSubMsg
                        , Store.cmdIfDone subMsg nextCmd
                        ]
                    )

                SetOffset offset ->
                    ( { model | offset = normalizeOffset model offset }
                    , dispatch LoadPartitions
                    )

                LoadEvents ->
                    let
                        eventsStoreTmp =
                            onFetchStart model.eventsStore

                        eventsStore =
                            { eventsStoreTmp
                                | name = model.name
                                , partition = model.partition
                            }

                        offset =
                            normalizeOffset model model.offset

                        cmd =
                            fetchEvents EventsLoaded
                                model.name
                                model.partition
                                offset
                                model.size
                    in
                    ( { model | eventsStore = eventsStore, offset = offset }, cmd )

                EventsLoaded result ->
                    case result of
                        Ok response ->
                            let
                                store =
                                    model.eventsStore

                                newStore =
                                    onFetchOk { store | response = response }
                            in
                            ( { model | eventsStore = newStore, showAll = False }, Cmd.none )

                        Err error ->
                            ( { model | eventsStore = onFetchErr model.eventsStore error }
                            , logoutIfExpired error
                            )

                DistanceStoreMsg subMsg ->
                    let
                        ( newStore, newSubMsg ) =
                            Stores.CursorDistance.update subMsg model.distanceStore
                    in
                    ( { model | distanceStore = newStore }, Cmd.map DistanceStoreMsg newSubMsg )

                NavigatorClicked pos width ->
                    let
                        total =
                            model.totalStore
                                |> Store.get "0"
                                |> Maybe.map .distance
                                |> Maybe.withDefault 0

                        numberOfEventsFromBegin =
                            total * pos // width

                        cmd =
                            Stores.ShiftedCursor.ShiftedCursor
                                model.partition
                                "BEGIN"
                                numberOfEventsFromBegin
                                |> Stores.ShiftedCursor.fetchShiftedCursors Store.FetchAllDone model.name
                                |> Cmd.map NavigatorJumpStoreMsg
                    in
                    ( model, cmd )

                NavigatorJumpStoreMsg subMsg ->
                    let
                        ( newStore, newSubMsg ) =
                            Stores.ShiftedCursor.update subMsg model.navigatorJumpStore

                        cmdOut =
                            newStore
                                |> Store.get "0"
                                |> Maybe.map .offset
                                |> Maybe.withDefault "BEGIN"
                                |> SetOffset
                                |> dispatch
                                |> Store.cmdIfDone subMsg
                    in
                    ( { model | navigatorJumpStore = newStore }
                    , Cmd.batch [ cmdOut, Cmd.map NavigatorJumpStoreMsg newSubMsg ]
                    )

                PageNewestCursorStoreMsg subMsg ->
                    let
                        ( newStore, newSubMsg ) =
                            Stores.ShiftedCursor.update subMsg model.pageNewestCursorStore

                        cmdOut =
                            if model.offset == "END" then
                                newStore
                                    |> Store.get "0"
                                    |> Maybe.map .offset
                                    |> Maybe.withDefault "BEGIN"
                                    |> SetOffset
                                    |> dispatch
                                    |> Store.cmdIfDone subMsg

                            else
                                Cmd.none
                    in
                    ( { model | pageNewestCursorStore = newStore }
                    , Cmd.batch [ cmdOut, Cmd.map PageNewestCursorStoreMsg newSubMsg ]
                    )

                PageBackCursorStoreMsg subMsg ->
                    let
                        ( newStore, newSubMsg ) =
                            Stores.ShiftedCursor.update subMsg model.pageBackCursorStore
                    in
                    ( { model | pageBackCursorStore = newStore }, Cmd.map PageBackCursorStoreMsg newSubMsg )

                InputOffset offset ->
                    ( { model | offset = offset }, Cmd.none )

                OffsetKeyUp key ->
                    let
                        cmd =
                            case Keyboard.whitespaceKey key of
                                Just Keyboard.Enter ->
                                    dispatch (SetOffset model.offset)

                                _ ->
                                    Cmd.none
                    in
                    ( model, cmd )

                InputSize value ->
                    let
                        size =
                            value |> String.toInt |> Maybe.withDefault initialModel.size
                    in
                    ( { model | size = size }, dispatch LoadPartitions )

                InputFilter keyword ->
                    ( { model | filter = keyword, showAll = False }, Cmd.none )

                SelectEvent offset ->
                    ( { model | selected = Just offset }, Cmd.none )

                UnSelectEvent ->
                    ( { model | selected = Nothing }, Cmd.none )

                ShowAll ->
                    ( { model | showAll = True }, Cmd.none )

                OldFirst val ->
                    ( { model | oldFirst = val }, Cmd.none )

                Download ->
                    let
                        filename =
                            model.name ++ "#" ++ model.partition ++ "-" ++ model.offset ++ ".json"

                        filterKey =
                            model.filter |> String.trim

                        events =
                            model.eventsStore.response

                        filteredList =
                            if filterKey |> String.isEmpty then
                                events

                            else
                                List.filter (\item -> item.body |> String.contains filterKey) events

                        reverse list =
                            if model.oldFirst then
                                List.reverse list

                            else
                                list

                        eventToString event =
                            "{\"offset\":\"" ++ event.cursor.offset ++ "\",\"body\":" ++ event.body ++ "}"

                        rows =
                            reverse filteredList |> List.map eventToString |> String.join ",\n"

                        body =
                            Http.stringBody "" ("[" ++ rows ++ "]")

                        url =
                            "elm:downloadAs?format=application/json&filename=" ++ percentEncode filename

                        startDownload =
                            Http.post url body Json.Decode.string
                                |> Http.send DownloadStarted
                    in
                    ( model, startDownload )

                DownloadStarted _ ->
                    ( model, Cmd.none )

                JsonEditorMsg subMsg ->
                    let
                        ( newSubModel, newSubMsg ) =
                            JsonEditor.update subMsg model.jsonEditorState
                    in
                    ( { model | jsonEditorState = newSubModel }, Cmd.map JsonEditorMsg newSubMsg )
    in
    ( resultModel, resultCmd, modelToRoute resultModel )


normalizeOffset : Model -> String -> String
normalizeOffset model offset =
    case getOldestNewestOffsets model of
        Nothing ->
            offset

        Just ( minOffset, maxOffset ) ->
            if offset == "BEGIN" then
                "BEGIN"

            else if offset < minOffset then
                "BEGIN"

            else if offset > maxOffset then
                maxOffset

            else
                offset


modelToRoute : Model -> Route
modelToRoute model =
    PartitionRoute
        (UrlParams
            model.name
            model.partition
        )
        (UrlQuery
            (if model.formatted then
                Nothing

             else
                Just model.formatted
            )
            (Just model.offset)
            (Just model.size)
            (if String.isEmpty model.filter then
                Nothing

             else
                Just model.filter
            )
            model.selected
        )


routeToModel : Route -> Model -> Model
routeToModel route model =
    case route of
        PartitionRoute params query ->
            { model
                | name = params.name
                , partition = params.partition
                , formatted = query.formatted |> Maybe.withDefault initialModel.formatted
                , offset = query.offset |> Maybe.withDefault initialModel.offset
                , size = query.size |> Maybe.withDefault initialModel.size
                , filter = query.filter |> Maybe.withDefault initialModel.filter
                , selected = query.selected
            }

        _ ->
            model


distanceFromBegin : String -> String -> Stores.CursorDistance.CursorDistanceQuery
distanceFromBegin partition offset =
    Stores.CursorDistance.CursorDistanceQuery
        (Stores.Cursor.Cursor partition "BEGIN")
        (Stores.Cursor.Cursor partition offset)
