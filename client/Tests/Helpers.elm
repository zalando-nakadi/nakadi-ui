module Tests.Helpers exposing (..)

import Test exposing (Test, describe, test)
import Expect
import Helpers.String exposing (splitFound, periodToString, pseudoIntSort)
import Helpers.Pagination exposing (paginationButtons, Buttons(Page, More, Current, Previous, Next))
import Helpers.JsonPrettyPrint exposing (prettyPrintJson)
import Helpers.JsonEditor exposing (JsonValue(..), stringToJsonValue, jsonValueToString, jsonValueToPrettyString)
import Dict


all : Test
all =
    describe "Test MultiSearch"
        [ viewSplitFoundTest "bbb" "Bla bla bBblllaaa" ( "Bla bla ", "bBb", "lllaaa" )
        , viewSplitFoundTest "Bla" "Bla bla bBblllaaa" ( "", "Bla", " bla bBblllaaa" )
        , viewSplitFoundTest "aaa" "Bla bla bBblllaaa" ( "Bla bla bBblll", "aaa", "" )
        , viewSplitFoundTest "" "Bla bla bBblllaaa" ( "Bla bla bBblllaaa", "", "" )
        , viewSplitFoundTest "a b" "" ( "", "", "" )
        , paginationTest 100
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
        , paginationTest 100
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
        , paginationTest 100
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
        , paginationTest 100
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
        , paginationTest 100
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
        , paginationTest 100
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
        , paginationTest 0
            0
            1
            1
            [ Previous Nothing
            , Next Nothing
            ]
        , paginationTest 5
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
        , paginationTest 7
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
        , prettyPrintJsonTest "{}" "{}"
        , prettyPrintJsonTest
            "{ \"a\":   {\"b\":  [ \"key\", 1, false]}}"
            "{\n    \"a\": {\n        \"b\": [\n            \"key\",\n            1,\n            false\n        ]\n    }\n}"
        , parseJsonTest
            "{\"a\":1,\"c\":2,\"b\":3,\"keystring\":\"astring\",\"keyint\":123,\"keyobj\":{\"subkeyint\":1,\"subarraykey\":[1,\"str\",3.14,null,true, false, [{}] ]}}"
            (Ok
                (ValueObject
                    ([ ( "a", ValueInt 1 )
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
            )
        , jsonValueToStringTest
            (ValueObject
                ([ ( "a", ValueInt 1 )
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
            )
            "{\"a\":1,\"c\":2,\"b\":3,\"keys\\\"tring\":\"astr\\\"ing\",\"keyint\":123,\"keyobj\":{\"subkeyint\":1,\"subarraykey\":[1,\"str\",3.14,null,true,false,[{}]]}}"
        , jsonValueToPrettyStringTest
            (ValueObject
                ([ ( "a", ValueInt 1 )
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
            )
            "{\n    \"a\": 1,\n    \"c\": 2,\n    \"b\": 3,\n    \"keystring\": \"astring\",\n    \"keyint\": 123,\n    \"emptyObj\": {},\n    \"emptyArr\": [],\n    \"keyobj\": {\n        \"subkeyint\": 1,\n        \"subarraykey\": [\n            1,\n            \"str\",\n            3.14,\n            null,\n            true,\n            false,\n            [\n                {}\n            ],\n            {\n                \"key\": []\n            }\n        ]\n    },\n    \"keyint2\": 123\n}"
        , periodToStringTest 0 ""
        , periodToStringTest 1000 "1 second"
        , periodToStringTest ((24 * 60 * 60 * 1000) + 2000) "1 day 2 seconds"
        , pseudoIntSortTest ["1","10","2"]  ["1","2","10"]
        , pseudoIntSortTest ["1","10","b","2", "a"]  ["1","2","10","a","b"]
        ]


viewSplitFoundTest needle heap expected =
    test "Expected splited string by the search word"
        (\() ->
            Expect.equal expected <| splitFound needle heap
        )


paginationTest total index left right expected =
    test "Pagination returns right set of buttons"
        (\() ->
            Expect.equal expected <| paginationButtons total index left right
        )


prettyPrintJsonTest raw expected =
    test "prettyPrintJson returns right format"
        (\() ->
            Expect.equal expected <| prettyPrintJson raw
        )


parseJsonTest raw expected =
    test "parseJson returns right format"
        (\() ->
            Expect.equal expected <| stringToJsonValue raw
        )


jsonValueToStringTest raw expected =
    test "jsonValueToStringTest returns right format"
        (\() ->
            Expect.equal expected <| jsonValueToString raw
        )


jsonValueToPrettyStringTest raw expected =
    test "jsonValueToPrettyStringTest returns right format"
        (\() ->
            Expect.equal expected <| jsonValueToPrettyString raw
        )


periodToStringTest raw expected =
    test "periodToString returns right format"
        (\() ->
            Expect.equal expected <| periodToString raw
        )


pseudoIntSortTest raw expected =
    test "pseudoIntSort returns right format"
        (\() ->
            Expect.equal expected <| pseudoIntSort raw
        )
