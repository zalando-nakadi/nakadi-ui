module Pages.EventTypeList.View exposing (view)

import Helpers.DataGrid as DataGrid
import Helpers.String exposing (cleanDateTime, splitFound)
import Helpers.UI exposing (starIcon)
import Html exposing (Html, b, div, span, text)
import Html.Attributes exposing (class)
import Models exposing (AppModel)
import Pages.EventTypeDetails.Models
import Pages.EventTypeList.Messages exposing (Msg(..))
import Routing.Models exposing (Route(..))


view : AppModel -> Html Msg
view model =
    let
        starRender eventType =
            [ starIcon OutAddToFavorite
                OutRemoveFromFavorite
                model.starredEventTypesStore
                eventType.name
            ]

        typeLink eventType =
            ( eventType.name
            , EventTypeDetailsRoute
                { name = eventType.name }
                Pages.EventTypeDetails.Models.emptyQuery
            )

        appsInfoUrl =
            model.userStore.user.settings.appsInfoUrl

        maxWidth =
            30

        toLongHtml str =
            let
                ( before, it, after ) =
                    splitFound model.eventTypeListPage.filter str
            in
            if String.isEmpty it then
                [ text (str |> String.left maxWidth) ]

            else
                let
                    len =
                        String.length it

                    rest =
                        (maxWidth - len) // 2
                in
                [ span [] [ text (before |> String.right rest) ]
                , b [] [ text it ]
                , span [] [ text (after |> String.left rest) ]
                ]
    in
    div [ class "dc-card main-content" ]
        [ DataGrid.view
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
                , { id = "owning_application"
                  , label = text "Owning application"
                  , view = DataGrid.ViewAppLink appsInfoUrl .owning_application
                  , filter = DataGrid.FilterMaybeString .owning_application
                  , sort = DataGrid.SortMaybeString .owning_application
                  , width = Nothing
                  }
                , { id = "category"
                  , label = text "Category"
                  , view = DataGrid.ViewString .category
                  , filter = DataGrid.FilterString .category
                  , sort = DataGrid.SortString .category
                  , width = Nothing
                  }
                , { id = "compatibility_mode"
                  , label = text "Compatibility"
                  , view = DataGrid.ViewMaybeString .compatibility_mode
                  , filter = DataGrid.FilterMaybeString .compatibility_mode
                  , sort = DataGrid.SortMaybeString .compatibility_mode
                  , width = Nothing
                  }
                , { id = "version"
                  , label = text "Version"
                  , view = DataGrid.ViewMaybeString (.schema >> .version)
                  , filter = DataGrid.FilterMaybeString (.schema >> .version)
                  , sort = DataGrid.SortMaybeString (.schema >> .version)
                  , width = Nothing
                  }
                , { id = "updated_at"
                  , label = text "Updated"
                  , view = DataGrid.ViewMaybeString (.updated_at >> Maybe.map cleanDateTime)
                  , filter = DataGrid.FilterMaybeString (.updated_at >> Maybe.map cleanDateTime)
                  , sort = DataGrid.SortMaybeString (.updated_at >> Maybe.map cleanDateTime)
                  , width = Nothing
                  }
                , { id = "schema"
                  , label = text "Schema"
                  , view = DataGrid.ViewCustom (.schema >> .schema >> toLongHtml)
                  , filter = DataGrid.FilterString (.schema >> .schema)
                  , sort = DataGrid.SortString (.schema >> .schema)
                  , width = Just 300
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
        ]
