module Tests.Tests exposing (..)

import Test exposing (Test, describe)
import Tests.Routes
import Tests.Update
import Tests.Helpers
import Tests.EventTypeStore
all : Test
all =
    describe "Main Test Suite"
        [ Tests.Routes.all
        , Tests.Update.all
        , Tests.Helpers.all
        , Tests.EventTypeStore.all
        ]
