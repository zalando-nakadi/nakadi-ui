module MultiSearch.Messages exposing (Msg(..))

import Keyboard exposing (Key)
import MultiSearch.Models exposing (SearchItem)
import Routing.Models exposing (Route)


type Msg
    = Selected SearchItem
    | FilterChanged String
    | KeyPress Key
    | Refresh
    | ClearInput
    | ShowAll
    | OutRedirect Route
    | NoOp
