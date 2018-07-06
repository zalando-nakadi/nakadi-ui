module MultiSearch.Update exposing (..)

import MultiSearch.Messages exposing (..)
import MultiSearch.Models exposing (..)
import Helpers.Task exposing (dispatch)
import Dom.Scroll
import Dom
import Task
import Keyboard.Extra exposing (Key(ArrowUp, ArrowDown, PageUp, PageDown, Enter, Escape))
import Helpers.Task exposing (dispatch)
import Constants exposing (emptyString)
import Routing.Models exposing (Route(..))
import Pages.EventTypeDetails.Models
import Helpers.Store as Store
import Helpers.StoreLocal as StoreLocal
import Models exposing (AppModel)


defaultConfig : AppModel -> Config
defaultConfig model =
    { searchFunc = search model
    , itemHeight = 50
    , dropdownHeight = 600
    , inputId = "multiSearch-input"
    , dropdownId = "multiSearch-dropdown"
    , hint = "Start typing to search event types or subscriptions"
    , placeholder = "Search all"
    }


update : Config -> Msg -> Model -> ( Model, Cmd Msg )
update config message state =
    case message of
        Refresh ->
            let
                filterSanitized =
                    state.filter |> String.trim |> String.toLower

                filtered =
                    config.searchFunc filterSanitized
            in
                ( { state | filtered = filtered, showAll = False }, Cmd.none )

        Selected item ->
            let
                redirectMessage =
                    item
                        |> itemToRoute
                        |> OutRedirect
                        |> dispatch
            in
                ( state, Cmd.batch [ removeFocus config, redirectMessage ] )

        FilterChanged filter ->
            ( { state | selected = 0, filter = filter |> String.trim }, dispatch Refresh )

        Key key ->
            onKeyDown config key state

        ClearInput ->
            ( state, clearInput config )

        ShowAll ->
            ( { state | showAll = True }, setFocus config )

        NoOp ->
            ( state, Cmd.none )

        OutRedirect route ->
            ( state, Cmd.none )


removeFocus : Config -> Cmd Msg
removeFocus config =
    Dom.blur config.inputId
        |> Task.attempt (always (FilterChanged emptyString))


setFocus : Config -> Cmd Msg
setFocus config =
    Dom.focus config.inputId
        |> Task.attempt (always NoOp)


clearInput : Config -> Cmd Msg
clearInput config =
    Dom.focus config.inputId
        |> Task.attempt (always (FilterChanged emptyString))


onKeyDown : Config -> Int -> Model -> ( Model, Cmd Msg )
onKeyDown config key state =
    let
        oneUp =
            -1

        oneDown =
            1

        pageSize =
            config.dropdownHeight // config.itemHeight

        pageUp =
            -pageSize

        pageDown =
            pageSize

        ( selected, cmd ) =
            case Keyboard.Extra.fromCode key of
                ArrowUp ->
                    moveSelected config oneUp state

                ArrowDown ->
                    moveSelected config oneDown state

                PageUp ->
                    moveSelected config pageUp state

                PageDown ->
                    moveSelected config pageDown state

                Enter ->
                    ( state.selected, onEnter state )

                Escape ->
                    ( 0, removeFocus config )

                _ ->
                    ( state.selected, Cmd.none )

        lastIndex =
            if state.showAll then
                (List.length state.filtered) - 1
            else
                (Basics.min (List.length state.filtered) maxResults) - 1

        newSelected =
            selected
                |> min lastIndex
                |> max 0
    in
        ( { state | selected = newSelected }, cmd )


moveSelected : Config -> Int -> Model -> ( Int, Cmd Msg )
moveSelected config delta state =
    let
        pos =
            state.selected + delta
    in
        ( pos, scrollToView config pos )


onEnter : Model -> Cmd Msg
onEnter state =
    let
        maybeItem =
            List.head (List.drop state.selected state.filtered)
    in
        case maybeItem of
            Just item ->
                dispatch (Selected item)

            Nothing ->
                Cmd.none


scrollToView : Config -> Int -> Cmd Msg
scrollToView config index =
    Dom.Scroll.y config.dropdownId
        |> Task.andThen (scrollTo config index)
        |> Task.attempt (always NoOp)


scrollTo : Config -> Int -> Float -> Task.Task Dom.Error ()
scrollTo config index scrollPosition =
    let
        currentScroll =
            floor scrollPosition

        itemPosition =
            config.itemHeight * index

        maxScroll =
            itemPosition - config.dropdownHeight + config.itemHeight

        newScroll =
            currentScroll
                |> min itemPosition
                |> max maxScroll
    in
        if (newScroll == currentScroll) then
            -- do nothing
            Task.succeed ()
        else
            Dom.Scroll.toY config.dropdownId (toFloat newScroll)


itemToRoute : SearchItem -> Route
itemToRoute item =
    case item of
        SearchItemEventType eventType starred ->
            EventTypeDetailsRoute { name = eventType.name }
                Pages.EventTypeDetails.Models.emptyQuery

        SearchItemSubscription subscription starred ->
            SubscriptionDetailsRoute { id = subscription.id }


search : AppModel -> String -> List SearchItem
search model filter =
    let
        relevancy points str =
            if String.contains filter (String.toLower str) then
                points
            else
                0

        starCoefficient =
            1000

        noneCoefficient =
            1

        getStarWeight isStarred =
            if isStarred then
                starCoefficient
            else
                noneCoefficient

        filterEventType eventType =
            let
                itemTypeCoefficient =
                    2

                nameWeight =
                    1000

                owningAppWeight =
                    10

                isStarred =
                    StoreLocal.has eventType.name model.starredEventTypesStore

                weight =
                    itemTypeCoefficient
                        * (getStarWeight isStarred)
                        * ((relevancy nameWeight eventType.name)
                            + (relevancy owningAppWeight
                                (eventType.owning_application
                                    |> Maybe.withDefault Constants.emptyString
                                )
                              )
                          )
            in
                if weight > 0 then
                    Just
                        { weight = -weight
                        , item = SearchItemEventType eventType isStarred
                        }
                else
                    Nothing

        filterSubscription subscription =
            let
                itemTypeCoefficient =
                    1

                idWeight =
                    1000

                consumerGroupWeight =
                    100

                owningAppWeight =
                    10

                isStarred =
                    StoreLocal.has subscription.id model.starredSubscriptionsStore

                weight =
                    itemTypeCoefficient
                        * (getStarWeight isStarred)
                        * ((relevancy idWeight subscription.id)
                            + (relevancy consumerGroupWeight subscription.consumer_group)
                            + (relevancy owningAppWeight subscription.owning_application)
                          )
            in
                if weight > 0 then
                    Just
                        { weight = -weight
                        , item = SearchItemSubscription subscription isStarred
                        }
                else
                    Nothing

        foundEventTypes =
            model.eventTypeStore
                |> Store.items
                |> List.filterMap filterEventType

        foundSubscriptions =
            model.subscriptionStore
                |> Store.items
                |> List.filterMap filterSubscription

        unsortedResults =
            List.concat
                [ foundEventTypes
                , foundSubscriptions
                ]

        results =
            unsortedResults |> List.sortBy .weight |> List.map .item
    in
        if String.isEmpty filter then
            []
        else
            results
