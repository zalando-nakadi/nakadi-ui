module MultiSearch.Models exposing (Config, Model, SearchItem(..), initialModel, maxResults)

import Constants exposing (emptyString)
import Stores.EventType exposing (EventType)
import Stores.Subscription exposing (Subscription)


type SearchItem
    = SearchItemEventType EventType Bool
    | SearchItemSubscription Subscription Bool


type alias Model =
    { filter : String
    , filtered : List SearchItem
    , selected : Int
    , showAll : Bool
    }


initialModel : Model
initialModel =
    { filter = emptyString
    , filtered = []
    , selected = 0
    , showAll = False
    }


maxResults : Int
maxResults =
    100


type alias Config =
    { searchFunc : String -> List SearchItem
    , itemHeight : Int
    , dropdownHeight : Int
    , inputId : String
    , dropdownId : String
    , hint : String
    , placeholder : String
    }
