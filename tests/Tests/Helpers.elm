module Tests.Helpers exposing (suite)

import Expect
import Helpers.JsonEditor exposing (JsonValue(..), jsonValueToPrettyString, jsonValueToString, stringToJsonValue)
import Helpers.JsonPrettyPrint exposing (prettyPrintJson)
import Helpers.Pagination exposing (Buttons(..), paginationButtons)
import Helpers.String exposing (periodToString, pseudoIntSort, splitFound)
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Test Helpers"
        [ viewSplitFoundTest "Case insensitive search" "bbb" "Bla bla bBblllaaa" ( "Bla bla ", "bBb", "lllaaa" )
        , viewSplitFoundTest "Find at the begin" "Bla" "Bla bla bBblllaaa" ( "", "Bla", " bla bBblllaaa" )
        , viewSplitFoundTest "Find at the end" "aaa" "Bla bla bBblllaaa" ( "Bla bla bBblll", "aaa", "" )
        , viewSplitFoundTest "Empty search key" "" "Bla bla bBblllaaa" ( "Bla bla bBblllaaa", "", "" )
        , viewSplitFoundTest "empty result" "a b" "" ( "", "", "" )
        , paginationTest "Begin"
            100
            0
            1
            1
            [ Previous Nothing
            , Current 0
            , Page 1
            , Page 2
            , Page 3
            , Page 4
            , More
            , Page 99
            , Next (Just 1)
            ]
        , paginationTest "Page 3"
            100
            3
            1
            1
            [ Previous (Just 2)
            , Page 0
            , Page 1
            , Page 2
            , Current 3
            , Page 4
            , More
            , Page 99
            , Next (Just 4)
            ]
        , paginationTest "Page 4"
            100
            4
            1
            1
            [ Previous (Just 3)
            , Page 0
            , More
            , Page 3
            , Current 4
            , Page 5
            , More
            , Page 99
            , Next (Just 5)
            ]
        , paginationTest "Middle"
            100
            95
            1
            1
            [ Previous (Just 94)
            , Page 0
            , More
            , Page 94
            , Current 95
            , Page 96
            , More
            , Page 99
            , Next (Just 96)
            ]
        , paginationTest "Close to end"
            100
            96
            1
            1
            [ Previous (Just 95)
            , Page 0
            , More
            , Page 95
            , Current 96
            , Page 97
            , Page 98
            , Page 99
            , Next (Just 97)
            ]
        , paginationTest "The end"
            100
            99
            1
            1
            [ Previous (Just 98)
            , Page 0
            , More
            , Page 95
            , Page 96
            , Page 97
            , Page 98
            , Current 99
            , Next Nothing
            ]
        , paginationTest "No pages"
            0
            0
            1
            1
            [ Previous Nothing
            , Next Nothing
            ]
        , paginationTest "Few pages"
            5
            3
            1
            1
            [ Previous (Just 2)
            , Page 0
            , Page 1
            , Page 2
            , Current 3
            , Page 4
            , Next (Just 4)
            ]
        , paginationTest "Max fit"
            7
            6
            1
            1
            [ Previous (Just 5)
            , Page 0
            , Page 1
            , Page 2
            , Page 3
            , Page 4
            , Page 5
            , Current 6
            , Next Nothing
            ]
        , prettyPrintJsonTest "empty" "{}" "{}"
        , prettyPrintJsonTest "all"
            "{ \"a\":   {\"b\":  [ \"key\", 1, false]}}"
            "{\n    \"a\": {\n        \"b\": [\n            \"key\",\n            1,\n            false\n        ]\n    }\n}"
        , parseJsonTest "All"
            "{\"a\":1,\"c\":2,\"b\":3,\"keystring\":\"astring\",\"keyint\":123,\"keyobj\":{\"subkeyint\":1,\"subarraykey\":[1,\"str\",3.14,null,true, false, [{}] ]}}"
            (Ok
                (ValueObject
                    [ ( "a", ValueInt 1 )
                    , ( "c", ValueInt 2 )
                    , ( "b", ValueInt 3 )
                    , ( "keystring", ValueString "astring" )
                    , ( "keyint", ValueInt 123 )
                    , ( "keyobj"
                      , ValueObject
                            [ ( "subkeyint", ValueInt 1 )
                            , ( "subarraykey"
                              , ValueArray
                                    [ ValueInt 1
                                    , ValueString "str"
                                    , ValueFloat 3.14
                                    , ValueNull
                                    , ValueBool True
                                    , ValueBool False
                                    , ValueArray [ ValueObject [] ]
                                    ]
                              )
                            ]
                      )
                    ]
                )
            )
        , jsonValueToStringTest "all"
            (ValueObject
                [ ( "a", ValueInt 1 )
                , ( "c", ValueInt 2 )
                , ( "b", ValueInt 3 )
                , ( "keys\"tring", ValueString "astr\"ing" )
                , ( "keyint", ValueInt 123 )
                , ( "keyobj"
                  , ValueObject
                        [ ( "subkeyint", ValueInt 1 )
                        , ( "subarraykey"
                          , ValueArray
                                [ ValueInt 1
                                , ValueString "str"
                                , ValueFloat 3.14
                                , ValueNull
                                , ValueBool True
                                , ValueBool False
                                , ValueArray [ ValueObject [] ]
                                ]
                          )
                        ]
                  )
                ]
            )
            "{\"a\":1,\"c\":2,\"b\":3,\"keys\\\"tring\":\"astr\\\"ing\",\"keyint\":123,\"keyobj\":{\"subkeyint\":1,\"subarraykey\":[1,\"str\",3.14,null,true,false,[{}]]}}"
        , jsonValueToPrettyStringTest "all"
            (ValueObject
                [ ( "a", ValueInt 1 )
                , ( "c", ValueInt 2 )
                , ( "b", ValueInt 3 )
                , ( "keystring", ValueString "astring" )
                , ( "keyint", ValueInt 123 )
                , ( "emptyObj", ValueObject [] )
                , ( "emptyArr", ValueArray [] )
                , ( "keyobj"
                  , ValueObject
                        [ ( "subkeyint", ValueInt 1 )
                        , ( "subarraykey"
                          , ValueArray
                                [ ValueInt 1
                                , ValueString "str"
                                , ValueFloat 3.14
                                , ValueNull
                                , ValueBool True
                                , ValueBool False
                                , ValueArray [ ValueObject [] ]
                                , ValueObject [ ( "key", ValueArray [] ) ]
                                ]
                          )
                        ]
                  )
                , ( "keyint2", ValueInt 123 )
                ]
            )
            "{\n    \"a\": 1,\n    \"c\": 2,\n    \"b\": 3,\n    \"keystring\": \"astring\",\n    \"keyint\": 123,\n    \"emptyObj\": {},\n    \"emptyArr\": [],\n    \"keyobj\": {\n        \"subkeyint\": 1,\n        \"subarraykey\": [\n            1,\n            \"str\",\n            3.14,\n            null,\n            true,\n            false,\n            [\n                {}\n            ],\n            {\n                \"key\": []\n            }\n        ]\n    },\n    \"keyint2\": 123\n}"
        , periodToStringTest "None" 0 ""
        , periodToStringTest "A second" 1000 "1 second"
        , periodToStringTest "A day" ((24 * 60 * 60 * 1000) + 2000) "1 day 2 seconds"
        , pseudoIntSortTest "10 to end" [ "1", "10", "2" ] [ "1", "2", "10" ]
        , pseudoIntSortTest "Mixed with non-numeric" [ "1", "10", "b", "2", "a" ] [ "1", "2", "10", "a", "b" ]
        ]


viewSplitFoundTest name needle heap expected =
    test ("Expected split string by the search word:" ++ name)
        (\() ->
            Expect.equal expected <| splitFound needle heap
        )


paginationTest name total index left right expected =
    test ("Pagination returns right set of buttons:" ++ name)
        (\() ->
            Expect.equal expected <| paginationButtons total index left right
        )


prettyPrintJsonTest name raw expected =
    test ("prettyPrintJson returns right format:" ++ name)
        (\() ->
            Expect.equal expected <| prettyPrintJson raw
        )


parseJsonTest name raw expected =
    test ("parseJson returns right format:" ++ name)
        (\() ->
            Expect.equal expected <| stringToJsonValue raw
        )


jsonValueToStringTest name raw expected =
    test ("jsonValueToStringTest returns right format:" ++ name)
        (\() ->
            Expect.equal expected <| jsonValueToString raw
        )


jsonValueToPrettyStringTest name raw expected =
    test ("jsonValueToPrettyStringTest returns right format:" ++ name)
        (\() ->
            Expect.equal expected <| jsonValueToPrettyString raw
        )


periodToStringTest name raw expected =
    test ("periodToString returns right format:" ++ name)
        (\() ->
            Expect.equal expected <| periodToString raw
        )


pseudoIntSortTest name raw expected =
    test ("pseudoIntSort returns right format:" ++ name)
        (\() ->
            Expect.equal expected <| pseudoIntSort raw
        )
