module Pages.TeamDetails.Models exposing (Model, UrlParams, dictToParams, initialModel)

import Constants
import Dict exposing (get)
import Helpers.String exposing (justOrCrash)


type alias Model =
    { id : String
    , member : List String
    , result : String
    }


type alias UrlParams =
    { id : String
    }


dictToParams : Dict.Dict String String -> UrlParams
dictToParams dict =
    { id =
        get Constants.id dict |> justOrCrash "Incorrect url template. Missing /:id/"
    }


initialModel : Model
initialModel =
    { id = ""
    , member = []
    , result = ""
    }
