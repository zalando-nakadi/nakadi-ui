module MultiSearch.Messages exposing (..)

import MultiSearch.Models exposing (SearchItem)
import Routing.Models exposing (Route)
import Char exposing (..)


type Msg
    = Selected SearchItem
    | FilterChanged String
    | Key KeyCode
    | Refresh
    | ClearInput
    | ShowAll
    | OutRedirect Route
    | NoOp
