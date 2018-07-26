module Tests.EventTypeStore exposing (..)

import Test exposing (Test, describe, test)
import Expect
import Stores.EventType exposing (..)
import Stores.EventTypeAuthorization exposing (Key(..))
import Json.Decode


testJson =
    """
    [
    {

        "name": "eventlog.e68109_receive_wmo_item_arrived_on_yard",
        "owning_application": "eventlog-dispatcher-test",
        "category": "business",
        "enrichment_strategies": [
          "metadata_enrichment"
        ],
        "partition_strategy": "hash",
        "partition_key_fields": [
          "metadata.eid"
        ],
        "schema": {
          "type": "json_schema",
          "schema": "",
          "version": "0.1.0",
          "created_at": "2016-11-09T19:32:00.000Z"
        },
        "default_statistic": {
            "messages_per_minute":2400,
            "message_size":20240,
            "read_parallelism":4,
            "write_parallelism":4
            },
        "options": {
          "retention_time": 123456789
        },
        "compatibility_mode": "fixed",
        "updated_at": "2016-11-09T19:32:00.000Z",
        "created_at": "2016-11-09T19:32:00.000Z"
      },
      {
        "name": "eventlog.e6810a_generic_time_allocation",
        "owning_application": "eventlog-dispatcher-test",
        "category": "business",
        "enrichment_strategies": [
          "metadata_enrichment"
        ],
        "partition_strategy": "hash",
        "partition_key_fields": [
          "metadata.eid"
        ],
        "ordering_key_fields": [
          "data.order_index"
        ],
        "schema": {
          "type": "json_schema",
          "schema": "",
          "version": "0.1.0",
          "created_at": "2016-11-09T19:32:00.000Z"
        },
        "default_statistic": null,
        "options": {
          "retention_time": null
        },
        "compatibility_mode": "fixed",
        "audience": "company-internal",
        "cleanup_policy": "compact",
        "updated_at": "2016-11-09T19:32:00.000Z",
        "created_at": "2016-11-09T19:32:00.000Z",
        "authorization": {
            "admins" :
                [ { "data_type" : "user" , "value" : "myname"}],
            "readers" :
                [ { "data_type": "user" , "value": "myname"},
                 { "data_type": "*" , "value": "*"},
                 { "data_type": "service", "value": "stups_myapp"}
                ],
            "writers":
                [ { "data_type": "user", "value": "myname"},
                 { "data_type": "crazy", "value": "crazyname"}
                ]
        }
      }
    ]
    """


all : Test
all =
    describe "Test MultiSearch"
        [ jsonLoadTest testJson
            (Ok
                ([ { category = "business"
                   , name = "eventlog.e68109_receive_wmo_item_arrived_on_yard"
                   , owning_application = Just "eventlog-dispatcher-test"
                   , schema =
                        { schema = ""
                        , version = Just "0.1.0"
                        , created_at = Just "2016-11-09T19:32:00.000Z"
                        }
                   , enrichment_strategies = Just [ "metadata_enrichment" ]
                   , partition_strategy = Just "hash"
                   , compatibility_mode = Just "fixed"
                   , partition_key_fields = Just [ "metadata.eid" ]
                   , ordering_key_fields = Nothing
                   , default_statistic =
                        Just
                            { messages_per_minute = 2400
                            , message_size = 20240
                            , read_parallelism = 4
                            , write_parallelism = 4
                            }
                   , options = Just { retention_time = Just 123456789 }
                   , created_at = Just "2016-11-09T19:32:00.000Z"
                   , updated_at = Just "2016-11-09T19:32:00.000Z"
                   , authorization = Nothing
                   , cleanup_policy = "delete"
                   , audience = Nothing
                   }
                 , { category = "business"
                   , name = "eventlog.e6810a_generic_time_allocation"
                   , owning_application = Just "eventlog-dispatcher-test"
                   , schema =
                        { schema = ""
                        , version = Just "0.1.0"
                        , created_at = Just "2016-11-09T19:32:00.000Z"
                        }
                   , enrichment_strategies = Just [ "metadata_enrichment" ]
                   , partition_strategy = Just "hash"
                   , compatibility_mode = Just "fixed"
                   , partition_key_fields = Just [ "metadata.eid" ]
                   , ordering_key_fields = Just ["data.order_index"]
                   , default_statistic = Nothing
                   , options =
                        Just
                            { retention_time = Nothing }
                   , created_at = Just "2016-11-09T19:32:00.000Z"
                   , updated_at = Just "2016-11-09T19:32:00.000Z"
                   , authorization =
                        Just
                            { readers =
                                [ { key = User
                                  , data_type = "user"
                                  , value = "myname"
                                  , permission = { read = True, write = False, admin = False }
                                  }
                                , { key = All
                                  , data_type = "*"
                                  , value = "*"
                                  , permission = { read = True, write = False, admin = False }
                                  }
                                , { key = Service
                                  , data_type = "service"
                                  , value = "stups_myapp"
                                  , permission = { read = True, write = False, admin = False }
                                  }
                                ]
                            , writers =
                                [ { key = User
                                  , data_type = "user"
                                  , value = "myname"
                                  , permission = { read = False, write = True, admin = False }
                                  }
                                , { key = Unknown
                                  , data_type = "crazy"
                                  , value = "crazyname"
                                  , permission = { read = False, write = True, admin = False }
                                  }
                                ]
                            , admins =
                                [ { key = User
                                  , data_type = "user"
                                  , value = "myname"
                                  , permission = { read = False, write = False, admin = True }
                                  }
                                ]
                            }
                   , cleanup_policy = "compact"
                   , audience = Just "company-internal"
                   }
                 ]
                )
            )
        ]


jsonLoadTest raw expected =
    test "JsonDecoder returns right object"
        (\() ->
            Expect.equal expected <| Json.Decode.decodeString collectionDecoder raw
        )
