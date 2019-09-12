module Pages.TeamDetails.View exposing (view)

import Dict exposing (insert)
import Helpers.DataGrid as DataGrid
import Helpers.Panel
import Html exposing (Html, div, text)
import Html.Attributes exposing (class)
import Models exposing (AppModel)
import Pages.TeamDetails.Messages exposing (Msg(..))
import Pages.TeamDetails.Models


view : AppModel -> Html Msg
view model =
    dataGrid model.teamDetailsPage


dataGrid : Pages.TeamDetails.Models.Model -> Html Msg
dataGrid model =
    div [ class "dc-card main-content" ]
        [ DataGrid.view
            { columns =
                [ { id = "name"
                  , label = text "Name"
                  , view = DataGrid.ViewString .name
                  , filter = DataGrid.FilterString .name
                  , sort = DataGrid.SortString .name
                  , width = Just 10
                  }
                ]
            , pageSize = 20
            , page = model.page
            , changePageTagger = PageChange
            , refreshTagger = Refresh
            , filterChangeTagger = FilterChange
            , filter = model.filter
            , sortTagger = SortBy
            , sortBy = model.sortBy
            , sortReverse = model.sortReverse
            }
            { dict =
                model.store.dict
                    |> Dict.values
                    |> List.head
                    |> Maybe.withDefault { id = "", member = [] }
                    |> .member
                    |> List.foldl (\key dict -> insert key { name = key } dict) Dict.empty
            , status = model.store.status
            , params = model.store.params
            , error = model.store.error
            }
        ]
