module Stores.StarredSubscriptions exposing (config, update)

import Dict
import Helpers.Store as Store
import Helpers.StoreLocal as StoreLocal


config : Dict.Dict String String -> Store.Config String
config params =
    { getKey = \index name -> name
    , url = "elm:localStorage?key=starred.subscriptions"
    , decoder = StoreLocal.collectionDecoder
    , headers = []
    }


update : StoreLocal.Msg -> StoreLocal.Model -> ( StoreLocal.Model, Cmd StoreLocal.Msg )
update message store =
    StoreLocal.updateWithConfig config message store
