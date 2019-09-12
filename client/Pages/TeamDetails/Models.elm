module Pages.TeamDetails.Models exposing (Model, UrlParams, dictToParams, initialModel)

import Constants
import Dict exposing (get)
import Helpers.String exposing (justOrCrash)
import Stores.TeamDetails


type alias Model =
    { store : Stores.TeamDetails.Model
    , filter : String
    , sortBy : Maybe String
    , sortReverse : Bool
    , page : Int
    }


initialModel =
    { page = 0
    , filter = ""
    , sortBy = Nothing
    , sortReverse = False
    , store = Stores.TeamDetails.initialModel
    }


type alias UrlParams =
    { id : String
    }


dictToParams : Dict.Dict String String -> UrlParams
dictToParams dict =
    { id =
        get Constants.id dict |> justOrCrash "Incorrect url template. Missing /:id/"
    }
