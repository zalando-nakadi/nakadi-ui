module Stores.StarredEventTypes exposing (..)

import Helpers.Store as Store
import Helpers.StoreLocal as StoreLocal
import Dict


config : Dict.Dict String String -> Store.Config String
config params =
    { getKey = (\index name -> name)
    , url = "elm:localStorage?key=starred.eventTypes"
    , decoder = StoreLocal.collectionDecoder
    , headers = []
    }


update : StoreLocal.Msg -> StoreLocal.Model -> ( StoreLocal.Model, Cmd StoreLocal.Msg )
update message store =
    StoreLocal.updateWithConfig config message store
