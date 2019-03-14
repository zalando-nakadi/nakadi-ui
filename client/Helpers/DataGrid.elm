module Helpers.DataGrid exposing (Column, Config, FilterType(..), SortType(..), ViewType(..), filtering, renderHeader, renderRow, sorting, view, viewLayout)

import Constants
import Helpers.Pagination exposing (listToPage)
import Helpers.Panel exposing (infoMessage, loadingStatus)
import Helpers.Store
import Helpers.String exposing (toPx)
import Helpers.UI exposing (highlightFound, linkHtmlToApp, refreshButton)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Routing.Helpers exposing (internalHtmlLink)
import Routing.Models exposing (Route)


type ViewType object msg
    = ViewCustom (object -> List (Html msg))
    | ViewString (object -> String)
    | ViewMaybeString (object -> Maybe String)
    | ViewInternalLink (object -> ( String, Route ))
    | ViewAppLink String (object -> Maybe String)
    | ViewInt (object -> Int)


type FilterType object
    = FilterNone
    | FilterString (object -> String)
    | FilterMaybeString (object -> Maybe String)


type SortType object
    = SortNone
    | SortString (object -> String)
    | SortMaybeString (object -> Maybe String)


type alias Column object msg =
    { id : String
    , label : Html msg
    , view : ViewType object msg
    , filter : FilterType object
    , sort : SortType object
    , width : Maybe Int
    }


type alias Config object msg =
    { columns : List (Column object msg)
    , pageSize : Int
    , page : Int
    , changePageTagger : Int -> msg
    , refreshTagger : msg
    , filterChangeTagger : String -> msg
    , filter : String
    , sortTagger : Maybe String -> Bool -> msg
    , sortBy : Maybe String
    , sortReverse : Bool
    }


{-| Render the sortable, filtered, paged data grid.

@example
DataGrid.view
{ columns =
[ { id = "star"
, label = text " "
, view = DataGrid.ViewCustom starRender
, filter = DataGrid.FilterNone
, sort = DataGrid.SortNone
, width = Just 10
}
, { id = "name"
, label = text "Event type name"
, view = DataGrid.ViewInternalLink typeLink
, filter = DataGrid.FilterString .name
, sort = DataGrid.SortString .name
, width = Just 2000
}
, { id = "updated_at"
, label = text "Updated"
, view = DataGrid.ViewMaybeString (.updated_at >> Maybe.map cleanDateTime)
, filter = DataGrid.FilterMaybeString (.updated_at >> Maybe.map cleanDateTime)
, sort = DataGrid.SortMaybeString (.updated_at >> Maybe.map cleanDateTime)
, width = Nothing
}
]
, pageSize = 20
, page = model.eventTypeListPage.page
, changePageTagger = PagingSetPage
, refreshTagger = Refresh
, filterChangeTagger = NameFilterChanged
, filter = model.eventTypeListPage.filter
, sortTagger = SortBy
, sortBy = model.eventTypeListPage.sortBy
, sortReverse = model.eventTypeListPage.sortReverse
}
model.eventTypeStore

-}
view : Config object msg -> Helpers.Store.Model object -> Html msg
view config model =
    viewLayout config model
        |> loadingStatus model


viewLayout : Config object msg -> Helpers.Store.Model object -> Html msg
viewLayout config model =
    let
        list =
            Helpers.Store.items model

        sortCol =
            config.columns
                |> List.filter (\col -> config.sortBy == Just col.id)
                |> List.head

        { paging, status, rows } =
            listToPage
                config.changePageTagger
                (Just (filtering config))
                (sorting config sortCol)
                (renderRow config)
                config.page
                config.pageSize
                list

        eventTypeTable =
            if List.isEmpty rows then
                infoMessage "Empty result" "No records found" Nothing

            else
                table [ class "dc-table" ]
                    [ renderHeader config
                    , tbody
                        [ class "dc-table__tbody" ]
                        rows
                    ]
    in
    div []
        [ div []
            [ refreshButton config.refreshTagger
            , div []
                [ div
                    [ class "dc-search-form" ]
                    [ input
                        [ class "dc-input dc-search-form__input"
                        , id "gridFilterSearch"
                        , placeholder "Filter all..."
                        , onInput config.filterChangeTagger
                        , value config.filter
                        ]
                        []
                    , button
                        [ class "dc-btn dc-search-form__btn" ]
                        [ i
                            [ class "dc-icon dc-icon--search dc-icon--interactive" ]
                            []
                        ]
                    ]
                , paging
                ]
            ]
        , div [ class "grid__table-container" ] [ eventTypeTable ]
        , div [ class "grid__paging-status" ] [ text status ]
        ]


filtering : Config obj msg -> obj -> Bool
filtering config rowData =
    let
        filter =
            String.toLower config.filter

        filterCol col =
            case col.filter of
                FilterNone ->
                    False

                FilterString getVal ->
                    rowData
                        |> getVal
                        |> String.toLower
                        |> String.contains filter

                FilterMaybeString getVal ->
                    rowData
                        |> getVal
                        |> Maybe.withDefault Constants.emptyString
                        |> String.toLower
                        |> String.contains filter
    in
    config.columns
        |> List.filter filterCol
        |> List.isEmpty
        |> not


{-| Return comparator function to compare two given object(row) with respect of the grid config and
the selected column configuration.
If no column was selected, it returns Nothing to skip sorting (for the optimisation).
-}
sorting : Config obj msg -> Maybe (Column obj msg) -> Maybe (obj -> obj -> Order)
sorting config sortCol =
    let
        reverse order =
            if order == EQ then
                EQ

            else if order == GT then
                LT

            else
                GT

        setOrder order =
            if config.sortReverse then
                reverse order

            else
                order

        comparator sortColumn data1 data2 =
            setOrder <|
                case sortColumn.sort of
                    SortNone ->
                        EQ

                    SortString getVal ->
                        Basics.compare
                            (getVal data1)
                            (getVal data2)

                    SortMaybeString getVal ->
                        Basics.compare
                            (data1 |> getVal |> Maybe.withDefault Constants.emptyString)
                            (data2 |> getVal |> Maybe.withDefault Constants.emptyString)
    in
    sortCol |> Maybe.map comparator


renderHeader : Config obj msg -> Html msg
renderHeader config =
    let
        renderCol col =
            let
                colStyle =
                    case col.width of
                        Nothing ->
                            []

                        Just width ->
                            [ ( "width", toPx width ) ]

                sortClass =
                    if config.sortBy /= Just col.id then
                        Constants.emptyString

                    else if config.sortReverse then
                        "dc-table__sorter--descending"

                    else
                        "dc-table__sorter--ascending"

                sortMessage =
                    if config.sortBy == Just col.id then
                        config.sortTagger (Just col.id) (not config.sortReverse)

                    else
                        config.sortTagger (Just col.id) False
            in
            if col.sort /= SortNone then
                th
                    [ class "dc-table__th dc-table__th--sortable"
                    , style colStyle
                    , onClick sortMessage
                    ]
                    [ col.label
                    , span [ class ("dc-table__sorter " ++ sortClass) ] []
                    ]

            else
                th
                    [ class "dc-table__th", style colStyle ]
                    [ col.label ]
    in
    thead
        [ class "dc-table__thead" ]
        [ tr
            [ class "dc-table__tr" ]
            (config.columns
                |> List.map renderCol
            )
        ]


renderRow : Config object msg -> Int -> object -> Html msg
renderRow config index rowData =
    let
        renderCol col =
            td [ class "dc-table__td" ] <|
                case col.view of
                    ViewString getVal ->
                        rowData
                            |> getVal
                            |> highlightFound config.filter

                    ViewMaybeString getVal ->
                        rowData
                            |> getVal
                            |> Maybe.withDefault Constants.noneLabel
                            |> highlightFound config.filter

                    ViewInternalLink getVal ->
                        let
                            ( name, route ) =
                                getVal rowData
                        in
                        [ internalHtmlLink route
                            (highlightFound config.filter name)
                        ]

                    ViewAppLink appsInfoUrl getVal ->
                        case getVal rowData of
                            Just app ->
                                [ linkHtmlToApp
                                    appsInfoUrl
                                    app
                                    (highlightFound config.filter app)
                                ]

                            Nothing ->
                                [ text Constants.noneLabel ]

                    ViewInt getVal ->
                        rowData
                            |> getVal
                            |> toString
                            |> highlightFound config.filter

                    ViewCustom getVal ->
                        getVal rowData
    in
    tr
        [ class "grid dc-table__tr dc-table__tr--tight dc-table__tr--interactive" ]
        (config.columns
            |> List.map renderCol
        )
