port module Tests.Main exposing (emit, main)

import Json.Encode exposing (Value)
import Test.Runner.Node exposing (run)
import Tests.Tests as Tests


main =
    run emit Tests.all


port emit : ( String, Value ) -> Cmd msg
