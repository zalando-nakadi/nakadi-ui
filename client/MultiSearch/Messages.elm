module MultiSearch.Messages exposing (Msg(..))

import Char exposing (..)
import MultiSearch.Models exposing (SearchItem)
import Routing.Models exposing (Route)


type Msg
    = Selected SearchItem
    | FilterChanged String
    | Key KeyCode
    | Refresh
    | ClearInput
    | ShowAll
    | OutRedirect Route
    | NoOp
