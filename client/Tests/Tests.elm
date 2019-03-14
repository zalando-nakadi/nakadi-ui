module Tests.Tests exposing (all)

import Test exposing (Test, describe)
import Tests.EventTypeStore
import Tests.Helpers
import Tests.Routes
import Tests.Update


all : Test
all =
    describe "Main Test Suite"
        [ Tests.Routes.all
        , Tests.Update.all
        , Tests.Helpers.all
        , Tests.EventTypeStore.all
        ]
