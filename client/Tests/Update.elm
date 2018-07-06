module Tests.Update exposing (..)

import Test exposing (Test, describe, test)
import Expect
import Messages exposing (..)
import Update
import Models
import Routing.Models exposing (..)
import Routing.Messages exposing (Msg(..))
import Routing.Models exposing (Model)


all : Test
all =
    describe "Test mainUpdate"
        [ routingNavigateToTest
        , routingOnLocationChangeTest
        ]



-- Testing main to submodule delegation and newRoute


routingNavigateToTest =
    test "Expected the new route in model no cmd on Redirect"
        (\() ->
            let
                testModel =
                    Models.initialModel

                expectedModel =
                    { testModel | newRoute = EventTypeCreateRoute }

                ( resultModel, cmd ) =
                    Update.update (RoutingMsg (Redirect EventTypeCreateRoute)) expectedModel

                isNone =
                    cmd == Cmd.map RoutingMsg Cmd.none
            in
                Expect.equal ( expectedModel, False ) ( resultModel, isNone )
        )


routingOnLocationChangeTest =
    test "Expected updated newRoute model and no cmd on OnLocationChange"
        (\() ->
            let
                testModel =
                    Models.initialModel

                newRouting =
                    EventTypeCreateRoute

                expectedModel =
                    { testModel | newRoute = newRouting, route = newRouting }

                location =
                    { href = "https://some/#createtype"
                    , host = ""
                    , hostname = ""
                    , protocol = ""
                    , origin = ""
                    , port_ = ""
                    , pathname = ""
                    , search = ""
                    , hash = "#createtype"
                    , username = ""
                    , password = ""
                    }

                ( model, cmd ) =
                    Update.update (RoutingMsg (OnLocationChange location)) testModel
            in
                Expect.equal (expectedModel) (model)
        )
