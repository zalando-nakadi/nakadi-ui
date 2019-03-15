module Tests.Routes exposing (all, parseLocationTest, routeTest)

import Expect
import Pages.EventTypeDetails.Models exposing (Tabs(..))
import Routing.Helpers exposing (locationToRoute, routeToUrl)
import Routing.Models exposing (Route(..))
import Test exposing (Test, describe, test)


all : Test
all =
    describe "Test routes"
        [ routeTest HomeRoute "#"
        , routeTest (EventTypeListRoute { filter = Nothing, page = Nothing, sortBy = Nothing, sortReverse = Nothing })
            "#types"
        , routeTest (EventTypeListRoute { filter = Just "som/e", page = Nothing, sortBy = Nothing, sortReverse = Nothing })
            "#types?filter=som%2Fe"
        , routeTest (EventTypeListRoute { filter = Just "some", page = Just 1, sortBy = Just "name", sortReverse = Just True })
            "#types?filter=some&page=1&reverse=True&sortBy=name"
        , routeTest (EventTypeDetailsRoute { name = "some/id" } { tab = Just PartitionsTab, formatted = Just True, version = Just "1.1.1", effective = Nothing })
            "#types/some%2Fid?formatted=True&tab=PartitionsTab&version=1.1.1"
        , routeTest NotFoundRoute "#notfound"
        , parseLocationTest "#"
            HomeRoute
        , parseLocationTest "#?some=some"
            HomeRoute
        , parseLocationTest "#types"
            (EventTypeListRoute { filter = Nothing, page = Nothing, sortBy = Nothing, sortReverse = Nothing })
        , parseLocationTest "#types?filter=some"
            (EventTypeListRoute { filter = Just "some", page = Nothing, sortBy = Nothing, sortReverse = Nothing })
        , parseLocationTest "#types?page=1&filter=some"
            (EventTypeListRoute { filter = Just "some", page = Just 1, sortBy = Nothing, sortReverse = Nothing })
        , parseLocationTest "#types?page=1&filter=some&sortBy=name"
            (EventTypeListRoute { filter = Just "some", page = Just 1, sortBy = Just "name", sortReverse = Nothing })
        , parseLocationTest "#types?page=1&filter=some&sortBy=name&reverse=True"
            (EventTypeListRoute { filter = Just "some", page = Just 1, sortBy = Just "name", sortReverse = Just True })
        , parseLocationTest "#types/someid"
            (EventTypeDetailsRoute { name = "someid" } { tab = Nothing, formatted = Nothing, version = Nothing, effective = Nothing })
        , parseLocationTest "#types/someid?tab=aaa&formatted=1"
            (EventTypeDetailsRoute { name = "someid" } { tab = Nothing, formatted = Nothing, version = Nothing, effective = Nothing })
        , parseLocationTest "#types/someid?tab=PartitionsTab&formatted=True"
            (EventTypeDetailsRoute { name = "someid" } { tab = Just PartitionsTab, formatted = Just True, version = Nothing, effective = Nothing })
        , parseLocationTest "#notfound"
            NotFoundRoute
        , parseLocationTest "#SomeThingCrazy"
            NotFoundRoute
        ]


routeTest route url =
    test ("Expected  routeToUrl route " ++ url)
        (\() ->
            Expect.equal (routeToUrl route) url
        )



-- TODO test Url


parseLocationTest url expectedRoute =
    test ("Loaction given " ++ url)
        (\() ->
            let
                location =
                    { href = ""
                    , host = ""
                    , hostname = ""
                    , protocol = ""
                    , origin = ""
                    , port_ = ""
                    , pathname = ""
                    , search = ""
                    , hash = url
                    , username = ""
                    , password = ""
                    }

                route =
                    locationToRoute location
            in
            Expect.equal route expectedRoute
        )
