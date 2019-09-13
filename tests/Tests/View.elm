module Tests.View exposing (all)

import Expect
import Html exposing (div)
import Messages exposing (Msg(..))
import Models exposing (initialModel)
import Routing.Models exposing (Route(..))
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector exposing (text)
import Update exposing (update)
import User.Messages exposing (Msg(..))
import User.Models exposing (Status(..), initialUser)
import View exposing (view)


all : Test
all =
    describe "Test main Model, Update, View combination"
        [ test "the home screen is rendered"
            (\() ->
                let
                    initModel =
                        initialModel Nothing

                    model =
                        { initModel | route = HomeRoute }

                    msg =
                        UserMsg <| FetchAllDone <| Ok <| Just initialUser

                    ( newModel, cmd ) =
                        update msg model

                    html =
                        view newModel
                in
                html.body
                    |> List.head
                    |> Maybe.withDefault (div [] [])
                    |> Query.fromHtml
                    |> Query.has [ text "Starred Event Types:" ]
            )
        ]
