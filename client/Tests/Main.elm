port module Tests.Main exposing (..)

import Tests.Tests as Tests
import Test.Runner.Node exposing (run)
import Json.Encode exposing (Value)


main =
    run emit Tests.all


port emit : ( String, Value ) -> Cmd msg
