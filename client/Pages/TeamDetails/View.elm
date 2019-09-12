module Pages.TeamDetails.View exposing (view)

import Dict exposing (insert)
import Helpers.DataGrid as DataGrid
import Helpers.Forms exposing (Locking(..), Requirement(..), buttonPanel, textInput)
import Helpers.Panel exposing (successMessage)
import Html exposing (Html, div, h4, hr, text)
import Html.Attributes exposing (class)
import Models exposing (AppModel)
import Pages.TeamDetails.Messages exposing (Msg(..))
import Pages.TeamDetails.Models exposing (Field(..), Model)


view : AppModel -> Html Msg
view model =
    div []
        [ dataGrid model.teamDetailsPage
        , div [] [ form model.teamDetailsPage ]
        ]


form : Model -> Html Msg
form model =
    div [ class "form-create__form dc-card dc-row dc-row--align--center" ]
        [ div [ class "dc-column form-create__form-container" ]
            [ div []
                [ h4 [ class "dc-h4 dc--text-center" ] [ text "Add new user" ]
                , textInput model
                    FieldLdap
                    OnInput
                    "Ldap"
                    "Example: staging-1"
                    ""
                    [ text "I don't know" ]
                    Required
                    Enabled
                , textInput model
                    FieldName
                    OnInput
                    "Name"
                    "Example: staging-1"
                    ""
                    [ text "I don't know" ]
                    Required
                    Enabled
                , div [ class "dc-toast__content dc-toast__content--success" ]
                    [ text "Created" ]
                    |> Helpers.Panel.loadingStatus model
                , buttonPanel "Submit" Submit Reset FieldLdap model
                ]
            ]
        ]


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
