module Pages.Partition.View exposing (eventsView, navigation, offsetButton, pager, stringClamp, view, viewEventDetails, viewEventRow)

import Browser.Events exposing (onKeyUp)
import Constants exposing (emptyString)
import Helpers.JsonEditor as JsonEditor
import Helpers.JsonPrettyPrint exposing (prettyPrintJson)
import Helpers.Panel exposing (infoMessage, loadingStatus)
import Helpers.Store as Store
import Helpers.UI as UI exposing (helpIcon, searchInput)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Lazy
import Json.Decode as Decode
import List.Extra
import Models exposing (AppModel)
import Pages.EventTypeDetails.Models exposing (Tabs(..))
import Pages.EventTypeList.Models
import Pages.Partition.Help as Help
import Pages.Partition.Messages exposing (..)
import Pages.Partition.Models exposing (Model, getOldestNewestOffsets, isPartitionEmpty)
import Routing.Helpers exposing (internalLink)
import Routing.Models exposing (Route(..))
import Stores.Events


view : AppModel -> Html Msg
view model =
    let
        name =
            model.partitionPage.name

        partition =
            model.partitionPage.partition
    in
    div [ class "main-content dc-card" ]
        [ div [ class "dc-row" ]
            [ ul [ class "dc-breadcrumb" ]
                [ li [ class "dc-breadcrumb__item" ]
                    [ internalLink "Event Types"
                        (EventTypeListRoute Pages.EventTypeList.Models.emptyQuery)
                    ]
                , li [ class "dc-breadcrumb__item" ]
                    [ internalLink name
                        (EventTypeDetailsRoute { name = name }
                            { tab = Just PartitionsTab
                            , formatted = Nothing
                            , effective = Nothing
                            , version = Nothing
                            }
                        )
                    ]
                , li [ class "dc-breadcrumb__item" ]
                    [ span [] [ text ("partition #" ++ partition) ]
                    ]
                ]
            ]
        , div [ class "dc-row dc-row--align--justify" ]
            [ eventsView model.partitionPage
            ]
        ]


eventsView : Model -> Html Msg
eventsView partitionPage =
    let
        loadedPageSize =
            partitionPage.size

        filterKey =
            partitionPage.filter |> String.trim

        events =
            partitionPage.eventsStore.response

        filteredList =
            if filterKey |> String.isEmpty then
                events

            else
                List.filter (\item -> item.body |> String.contains filterKey) events

        filteredListLength =
            List.length filteredList

        --This depends on the browser performance and event sizes.
        maxVisiblePageSize =
            1000

        --This is how many events we can ad to the maxVisiblePageSize number.
        tolerance =
            1000

        --We don't want to show "Show 2 more events".
        --Lets just show them all
        tolerantPageSize =
            if
                not partitionPage.showAll
                    && (filteredListLength > maxVisiblePageSize + tolerance)
            then
                maxVisiblePageSize

            else
                filteredListLength

        selectedIndex =
            partitionPage.selected |> Maybe.withDefault Constants.emptyString

        reverse list =
            if partitionPage.oldFirst then
                List.reverse list

            else
                list

        rows =
            filteredList
                |> reverse
                |> List.take tolerantPageSize
                |> List.map (Html.Lazy.lazy (viewEventRow selectedIndex))

        more =
            if filteredListLength > tolerantPageSize then
                [ div [ class "dc-link", onClick ShowAll ]
                    [ text <|
                        "Show "
                            ++ String.fromInt (filteredListLength - tolerantPageSize)
                            ++ " more events"
                    ]
                ]

            else
                [ UI.none ]

        rowsList =
            if List.isEmpty rows then
                [ infoMessage "Empty result" "No events found in the loaded part" Nothing ]

            else
                List.concat [ rows, more ]

        maybeSelectedEvent =
            partitionPage.selected
                |> Maybe.andThen
                    (\selectedOffset ->
                        partitionPage.eventsStore.response
                            |> List.filter (\event -> event.cursor.offset == selectedOffset)
                            |> List.head
                    )

        first =
            events
                |> List.head
                |> Maybe.map (.cursor >> .offset)
                |> Maybe.withDefault emptyString

        last =
            events
                |> List.Extra.last
                |> Maybe.map (.cursor >> .offset)
                |> Maybe.withDefault emptyString

        status =
            "Showing "
                ++ String.fromInt filteredListLength
                ++ " of "
                ++ String.fromInt (List.length events)
                ++ " from "
                ++ first
                ++ " to "
                ++ last
    in
    div [ class "dc-column event-list__container" ]
        [ div [ class "event-list__container" ]
            [ div [ class "dc-row" ]
                [ pager partitionPage
                , navigation partitionPage
                ]
            , div [ class "dc-row" ]
                [ searchInput InputFilter "Filter events. Example: \"eid\":\"555-49-54\"" filterKey
                , select
                    [ value (Debug.toString partitionPage.oldFirst)
                    , onInput (\v -> OldFirst (v == "True"))
                    , class "dc-select"
                    ]
                    [ option [ value "False" ] [ text "New events first" ]
                    , option [ value "True" ] [ text "Old events first" ]
                    ]
                , button
                    [ onClick Download
                    , class "dc-btn"
                    , style "height" "3.6rem"
                    , title "Download loaded and filtered set of events as a JSON file."
                    ]
                    [ text "Download" ]
                ]
            , loadingStatus partitionPage.partitionsStore <|
                if isPartitionEmpty partitionPage then
                    infoMessage "This partition is empty" "This partition has no events." Nothing

                else
                    loadingStatus partitionPage.eventsStore <|
                        div [ class "dc-row" ]
                            [ div [ class "event-list dc-column " ]
                                [ div [ class "event-list__content dc-column__contents--left dc-column__content" ]
                                    [ ul
                                        [ class "event-list__list dc-list" ]
                                        rowsList
                                    ]
                                , div [ class "grid__paging-status dc-column__contents--left dc-column__content" ]
                                    [ text status ]
                                ]
                            , viewEventDetails
                                maybeSelectedEvent
                                partitionPage.formatted
                                partitionPage.jsonEditorState
                            ]
            ]
        ]


pager : Model -> Html Msg
pager partitionPage =
    let
        ( minOffset, maxOffset ) =
            getOldestNewestOffsets partitionPage
                |> Maybe.withDefault ( emptyString, emptyString )

        maybeOldest =
            if partitionPage.offset == "BEGIN" then
                Nothing

            else
                Just "BEGIN"

        maybePageBackOffset =
            if partitionPage.offset == "BEGIN" then
                Nothing

            else
                partitionPage.pageBackCursorStore
                    |> Store.get "0"
                    |> Maybe.map .offset
                    |> Maybe.map (stringClamp minOffset maxOffset)

        maybeLatestLoadedOffset =
            partitionPage.eventsStore.response
                |> List.head
                |> Maybe.map (.cursor >> .offset)

        maybeNewestOffset =
            if maxOffset > minOffset then
                partitionPage.pageNewestCursorStore
                    |> Store.get "0"
                    |> Maybe.map .offset

            else
                Nothing

        offsetHint =
            "Load events after this offset (i.e. excluding the event with this offset)."
    in
    div
        []
        [ offsetButton "fa fa-step-backward" "Load oldest posible events i.e. BEGIN" maybeOldest
        , offsetButton "fa fa-backward" "Load one page back in time" maybePageBackOffset
        , input
            [ onInput InputOffset
            , UI.onKeyUp OffsetKeyUp
            , id "inputOffset"
            , class "dc-input"
            , value partitionPage.offset
            , title offsetHint
            , style "width" "250px"
            ]
            []
        , span [ style "margin-left" "-20px" ]
            [ helpIcon "Offset" Help.offset UI.BottomRight
            ]
        , select
            [ onInput InputSize
            , value (String.fromInt partitionPage.size)
            , class "dc-select"
            , title "Page size"
            ]
            [ option [ value "100", class "dc-option" ] [ text "100 Events" ]
            , option [ value "1000", class "dc-option" ] [ text "1000 Events" ]
            , option [ value "10000", class "dc-option" ] [ text "10,000 Events" ]
            , option [ value "100000", class "dc-option" ] [ text "100,000 Events" ]
            ]
        , button [ onClick LoadEvents, class "event-list__pager-btn dc-btn" ] [ i [ class "fa fa-sync" ] [] ]
        , offsetButton "fa fa-forward" "Load one page forward in time" maybeLatestLoadedOffset
        , offsetButton "fa fa-step-forward" "Load newest events" maybeNewestOffset
        ]


offsetButton : String -> String -> Maybe String -> Html Msg
offsetButton label hint maybeOffset =
    case maybeOffset of
        Just offset ->
            a [ onClick (SetOffset offset), class "event-list__pager-btn dc-btn ", title hint ] [ i [ class label ] [] ]

        Nothing ->
            button [ disabled True, class "event-list__pager-btn dc-btn dc-btn--disabled ", title hint ] [ i [ class label ] [] ]


navigation : Model -> Html Msg
navigation partitionPage =
    let
        maybeDistance =
            partitionPage.totalStore
                |> Store.get "0"
                |> Maybe.map .distance

        total =
            maybeDistance
                |> Maybe.map ((+) 1)
                |> Maybe.map String.fromInt
                |> Maybe.withDefault "Loading..."

        percentage size =
            case maybeDistance of
                Just distance ->
                    toFloat (Basics.round (toFloat size * 10000.0 / toFloat (distance + 1))) / 100.0

                Nothing ->
                    0.0

        start =
            partitionPage.distanceStore
                |> Store.get "0"
                |> Maybe.map .distance
                |> Maybe.withDefault 0

        loadedStart =
            start
                |> percentage
                |> String.fromFloat

        loaded =
            partitionPage.eventsStore.response
                |> List.length

        loadedWidth =
            loaded
                |> percentage
                |> String.fromFloat

        titleText =
            "Total "
                ++ total
                ++ " events in this partition. Loaded "
                ++ String.fromInt loaded
                ++ " ("
                ++ loadedWidth
                ++ "%)"
                ++ " starting from "
                ++ String.fromInt start
                ++ " ("
                ++ loadedStart
                ++ "%)"

        ( minOffset, maxOffset ) =
            getOldestNewestOffsets partitionPage
                |> Maybe.withDefault ( emptyString, emptyString )

        onClickPos =
            Decode.map2 NavigatorClicked
                (Decode.field "offsetX" Decode.int)
                (Decode.at [ "target", "clientWidth" ] Decode.int)
    in
    div [ class "event-list__navigator" ]
        [ div []
            [ small [ class "event-list__navigator-min-offset" ] [ text minOffset ]
            , small [ class "event-list__navigator-total" ] [ text ("Total: " ++ total) ]
            , small [ class "event-list__navigator-max-offset" ] [ text maxOffset ]
            ]
        , div
            [ on "click" onClickPos
            , id "navigator-bar-total"
            , class "event-list__navigator-bar-total"
            , title titleText
            ]
            []
        , div
            [ style "left" (loadedStart ++ "%")
            , style "width" (loadedWidth ++ "%")
            , class "event-list__navigator-bar-loaded"
            , title titleText
            ]
            []
        ]


viewEventRow : String -> Stores.Events.Event -> Html Msg
viewEventRow selected event =
    let
        offset =
            event.cursor.offset

        length =
            String.length event.body

        className =
            if offset == selected then
                "dc-list__item list__item--is-selected"

            else
                "dc-list__item dc-list__item--is-interactive"
    in
    li
        [ class className
        , onClick (SelectEvent offset)
        ]
        [ div [ class "dc-list__inner" ]
            [ div [ class "dc-list__body dc--island-50" ]
                [ span [ class "dc--text-less-important dc--text-success dc--text-small" ]
                    [ text ("Offset: " ++ offset)
                    , text (String.repeat 10 UI.nbsp)
                    , text ("Length: " ++ (length |> String.fromInt))
                    ]
                , code
                    [ class "dc-list__title dc--no-wrap" ]
                    [ text (String.left 200 event.body) ]
                ]
            ]
        ]


viewEventDetails : Maybe Stores.Events.Event -> Bool -> JsonEditor.Model -> Html Msg
viewEventDetails maybeSelectedEvent formatted jsonEditorState =
    let
        jsonEditorView jsonString =
            case JsonEditor.stringToJsonValue jsonString of
                Ok result ->
                    Html.map JsonEditorMsg <| JsonEditor.view jsonEditorState result

                Err error ->
                    div []
                        [ Helpers.Panel.errorMessage "Json parsing error" (Debug.toString error)
                        , text jsonString
                        ]
    in
    case maybeSelectedEvent of
        Nothing ->
            div [ class "dc-column dc-column--shrink" ] []

        Just event ->
            div
                [ class "dc-column  dc-card", style "margin-right" "2.4rem" ]
                [ div [ class "dc-dialog__close" ]
                    [ i [ class "dc-icon dc-icon--close dc-icon--interactive", onClick UnSelectEvent, title "Close" ]
                        []
                    ]
                , div [ class "dc-row" ]
                    [ span []
                        [ label [ class "info-label" ] [ text "Offset:" ]
                        , span [ class "info-field" ] [ text event.cursor.offset ]
                        ]
                    , span [ class "dc-column" ]
                        [ input
                            [ onCheck SetFormatted
                            , checked formatted
                            , class "dc-checkbox dc-checkbox--alt"
                            , id "prettyprint"
                            , type_ "checkbox"
                            ]
                            []
                        , label [ class "dc-label", for "prettyprint" ]
                            [ text "Formatted" ]
                        ]
                    , span [ class "toolbar" ]
                        [ a
                            [ onClick
                                (CopyToClipboard
                                    (if formatted then
                                        prettyPrintJson event.body

                                     else
                                        event.body
                                    )
                                )
                            , class "icon-link dc-icon dc-icon--interactive"
                            , title "Copy To Clipboard"
                            ]
                            [ i [ class "far fa-clipboard" ] [] ]
                        ]
                    ]
                , pre [ class "event-details__json-view" ]
                    [ if formatted then
                        jsonEditorView event.body

                      else
                        text event.body
                    ]
                ]


stringClamp : String -> String -> String -> String
stringClamp lowest highest str =
    if str < lowest then
        lowest

    else if str > highest then
        highest

    else
        str
