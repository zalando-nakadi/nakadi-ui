module Pages.SubscriptionList.View exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Pages.SubscriptionList.Messages exposing (Msg(..))
import Models exposing (AppModel)
import Helpers.String
import Helpers.UI exposing (refreshButton, starIcon, internalHtmlLink, linkHtmlToApp, highlightFound)
import Routing.Models exposing (Route(..))
import Pages.EventTypeDetails.Models
import Helpers.DataGrid as DataGrid
import Helpers.String exposing (cleanDateTime)


view : AppModel -> Html Msg
view model =
    let
        starRender subscription =
            [ starIcon OutAddToFavorite
                OutRemoveFromFavorite
                model.starredSubscriptionsStore
                subscription.id
            ]

        subscriptionLink subscription =
            ( subscription.id
            , SubscriptionDetailsRoute
                { id = subscription.id }
                { tab = Nothing }
            )

        typeLink name =
            EventTypeDetailsRoute
                { name = name }
                Pages.EventTypeDetails.Models.emptyQuery

        typeLinks record =
            (record.event_types
                |> List.map
                    (\name ->
                        internalHtmlLink
                            (typeLink name)
                            (highlightFound model.subscriptionListPage.filter name)
                    )
                |> List.intersperse (br [] [])
            )

        appsInfoUrl =
            model.userStore.user.settings.appsInfoUrl
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
                    , { id = "id"
                      , label = text "Subscription Id"
                      , view = DataGrid.ViewInternalLink subscriptionLink
                      , filter = DataGrid.FilterString .id
                      , sort = DataGrid.SortString .id
                      , width = Just 200
                      }
                    , { id = "event_types"
                      , label = text "Event types"
                      , view = DataGrid.ViewCustom typeLinks
                      , filter = DataGrid.FilterString (.event_types >> String.join ",")
                      , sort = DataGrid.SortString (.event_types >> String.join ",")
                      , width = Just 200
                      }
                    , { id = "owning_application"
                      , label = text "Owning application"
                      , view = DataGrid.ViewAppLink appsInfoUrl (Just << .owning_application)
                      , filter = DataGrid.FilterString .owning_application
                      , sort = DataGrid.SortString .owning_application
                      , width = Nothing
                      }
                    , { id = "consumer_group"
                      , label = text "Consumer group"
                      , view = DataGrid.ViewString .consumer_group
                      , filter = DataGrid.FilterString .consumer_group
                      , sort = DataGrid.SortString .consumer_group
                      , width = Nothing
                      }
                    , { id = "created_at"
                      , label = text "Created"
                      , view = DataGrid.ViewString (.created_at >> cleanDateTime)
                      , filter = DataGrid.FilterString (.created_at >> cleanDateTime)
                      , sort = DataGrid.SortString (.created_at >> cleanDateTime)
                      , width = Nothing
                      }
                    ]
                , pageSize = 20
                , page = model.subscriptionListPage.page
                , changePageTagger = PagingSetPage
                , refreshTagger = Refresh
                , filterChangeTagger = NameFilterChanged
                , filter = model.subscriptionListPage.filter
                , sortTagger = SortBy
                , sortBy = model.subscriptionListPage.sortBy
                , sortReverse = model.subscriptionListPage.sortReverse
                }
                model.subscriptionStore
            ]
