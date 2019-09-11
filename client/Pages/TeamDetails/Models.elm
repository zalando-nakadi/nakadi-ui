module Pages.TeamDetails.Models exposing (Model, UrlParams, dictToParams, initialModel)

import Constants
import Dict exposing (get)
import Helpers.String exposing (justOrCrash)
import Stores.TeamDetails


type alias Model =
    Stores.TeamDetails.Model


initialModel =
    Stores.TeamDetails.initialModel


type alias UrlParams =
    { id : String
    }


dictToParams : Dict.Dict String String -> UrlParams
dictToParams dict =
    { id =
        get Constants.id dict |> justOrCrash "Incorrect url template. Missing /:id/"
    }
