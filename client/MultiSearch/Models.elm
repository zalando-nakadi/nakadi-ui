module MultiSearch.Models exposing (..)

import Stores.EventType exposing (EventType)
import Stores.Subscription exposing (Subscription)
import Constants exposing (emptyString)


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
    , hint: String
    , placeholder: String
    }
