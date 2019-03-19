module Tests.Update exposing (all, routingNavigateToTest, routingOnLocationChangeTest)

import Expect
import Messages exposing (..)
import Models
import Routing.Messages exposing (Msg(..))
import Routing.Models exposing (..)
import Test exposing (Test, describe, test)
import Update
import Url


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
                    Models.initialModel Nothing

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
                    Models.initialModel Nothing

                newRouting =
                    EventTypeCreateRoute

                expectedModel =
                    { testModel | newRoute = newRouting, route = newRouting }

                location =
                    { protocol = Url.Https
                    , host = "localhost"
                    , port_ = Nothing
                    , path = ""
                    , query = Nothing
                    , fragment = Just "createtype"
                    }

                ( model, cmd ) =
                    Update.update (RoutingMsg (OnLocationChange location)) testModel
            in
            Expect.equal expectedModel model
        )
