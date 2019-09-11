module Pages.TeamDetails.View exposing (view)

import Html exposing (Html, div, text)
import Models exposing (AppModel)
import Pages.TeamDetails.Messages exposing (Msg)


view : AppModel -> Html Msg
view model =
    div [] [ text model.teamDetailsPage.result ]
