module Pages.TeamDetails.View exposing (view)

import Helpers.Panel
import Html exposing (Html, div, text)
import Models exposing (AppModel)
import Pages.TeamDetails.Messages exposing (Msg)


view : AppModel -> Html Msg
view model =
    Helpers.Panel.loadingStatus model.teamDetailsPage (div [] [ text (Debug.toString model.teamDetailsPage) ])
