module Pages.EventTypeDetails.Help exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Helpers.UI exposing (..)
import Config


eventType : List (Html msg)
eventType =
    [ text "Name of this EventType. The name is constrained by a regular expression."
    , newline
    , bold "Note: "
    , i []
        [ text <|
            "the name can encode the owner/responsible for this EventType and ideally"
                ++ " should follow a common pattern that makes it easy to read and understand, but this level"
                ++ " of structure is not enforced."
                ++ "For example a team name and data type can be used such as 'acme-team.price-change'.\n"
        ]
    , bold "Pattern: "
    , mono "'[a-zA-Z][-0-9a-zA-Z_]*(\\.[a-zA-Z][-0-9a-zA-Z_]*)*'\n"
    , bold "Example: "
    , mono "order.order_cancelled, acme-platform.users"
    , newline
    , man "#definition_EventType*name"
    ]


owningApplication : List (Html msg)
owningApplication =
    [ text "Indicator of the (Stups) Application owning this EventType."
    , newline
    , bold "Example"
    , text ": "
    , mono "\"stups_price-service\""
    , newline
    , bold "Key: "
    , mono "owning_application"
    , bold "required"
    , newline
    , man "#definition_EventType*owning_application"
    ]


category : List (Html msg)
category =
    [ text "Defines the category of this EventType."
    , newline
    , text "The value set will influence, if not set otherwise, the default set of "
    , text "validations, enrichment-strategies, and the effective schema for validation in "
    , text "the following way:"
    , newline
    , newline
    , text "- "
    , mono "undefined"
    , text ": No predefined changes apply. The effective schema for the validation is "
    , text "exactly the same as the "
    , mono "EventTypeSchema"
    , newline
    , bold "Note:"
    , text " It is NOT validated by Nakadi"
    , newline
    , newline
    , text "- "
    , mono "data"
    , text ": Events of this category will be DataChangeEvents. The effective schema during"
    , text " the validation contains "
    , mono "metadata"
    , text ", and adds fields "
    , mono "data_op"
    , text "and "
    , mono "data_type"
    , text ". The passed EventTypeSchema defines the schema of "
    , mono "data"
    , text "."
    , newline
    , newline
    , text "- "
    , mono "business"
    , text ": Events of this category will be BusinessEvents. The effective schema for validation contains "
    , mono "metadata"
    , text "and any additionally defined properties passed in the"
    , mono "EventTypeSchema"
    , text "directly on top level of the Event. If name conflicts arise, creation "
    , text "of this EventType will be rejected."
    , newline
    , man "#event-types-and-categories"
    , newline
    , newline
    , bold "Key: "
    , mono "category"
    , bold "required"
    , newline
    , man "#definition_EventType*category"
    ]


enrichmentStrategies : List (Html msg)
enrichmentStrategies =
    [ text "Determines the enrichment to be performed on an Event upon\nreception."
    , newline
    , text "Enrichment is performed once upon reception (and after validation) of "
    , text "an Event and is only possible on fields that are not defined on the incoming Event."
    , newline
    , text "For event types in categories "
    , mono "business"
    , text " or"
    , mono "data"
    , text "it's mandatory to use"
    , mono "metadata_enrichment"
    , text "strategy. For "
    , mono "undefined"
    , text "event types it's not possible to use this strategy, since metadata field is not required."
    , newline
    , text "See documentation for the write operation for details on behaviour in case of unsuccessful enrichment."
    , newline
    , bold "Key: "
    , mono "enrichment_strategies"
    , bold "optional"
    , newline
    , man "#definition_EventType*enrichment_strategies"
    ]


partitionStrategy : List (Html msg)
partitionStrategy =
    [ text "Determines how the assignment of the event to a partition should be handled."
    , newline
    , text "For details of possible values, see "
    , man "#partitions"
    , newline
    , text "To get the list of strategies supported by this server, call this endpoint"
    , newline
    , mono "GET /registry/partition-strategies"
    , newline
    , text "Or "
    , a [ class "dc-link", href "/api/nakadi/registry/partition-strategies", target "_blank" ]
        [ text "Open the list of strategies supported by this server" ]
    , text ". "
    , newline
    , bold "Key: "
    , mono "partition_strategy"
    , bold "optional"
    , newline
    , bold "Default: "
    , mono "random"
    , newline
    , man "#definition_EventType*partition_strategy"
    ]


compatibilityMode : List (Html msg)
compatibilityMode =
    [ text "Compatibility modes are used to control schema changes."
    , newline
    , text "Each mode solves a specific problem and thus presents different constraints."
    , text " It ranges from being very constraining, allowing just some minor changes,"
    , text " to allowing everything."
    , newline
    , bold "Possible compatibility modes are:"
    , newline
    , text "- "
    , mono "compatible"
    , newline
    , text "- "
    , mono "forward"
    , newline
    , text "- "
    , mono "none"
    , newline
    , man "#compatibility-modes"
    , newline
    , newline
    , bold "Key: "
    , mono "compatibility_mode"
    , bold "optional"
    , newline
    , bold "Default: "
    , mono "forward"
    , newline
    , man "#definition_EventType*compatibility_mode"
    ]


partitionKeyFields : List (Html msg)
partitionKeyFields =
    [ text "Required when "
    , mono "partition_resolution_strategy"
    , text " is set to "
    , mono "hash"
    , text ". Must be absent otherwise."
    , newline
    , text "Indicates the fields used for evaluation the partition of Events of this type."
    , text "In practice this means events that are about the same logical entity and which have"
    , text " the same values for the partition key will be sent to the same partition."
    , newline
    , text "If set it MUST be a valid required field as defined in the schema."
    , newline
    , bold "Example: "
    , mono "[\"user_id\", \"order.order_id\"]"
    , newline
    , newline
    , bold "Key: "
    , mono "partition_key_fields"
    , bold "optional"
    , newline
    , man "#definition_EventType*partition_key_fields"
    ]


defaultStatistic : List (Html msg)
defaultStatistic =
    [ text "Statistics of this EventType used for optimization purposes."
    , text "Used primarily to calculate the number of partitions."
    , text " Internal use of these values might change over time."
    , newline
    , text "The statistic object must contain next fields:"
    , newline
    , text "- "
    , mono "message_size"
    , text " : Average message size in bytes."
    , newline
    , text "- "
    , mono "messages_per_minute"
    , text " : Write rate for events of this EventType in event count per minute."
    , newline
    , text "- "
    , mono "read_parallelism"
    , text " : Amount of parallel readers to this EventType."
    , newline
    , text "- "
    , mono "write_parallelism"
    , text " : Amount of parallel writers to this EventType."
    , newline
    , man "#definition_EventTypeStatistics"
    , newline
    , newline
    , bold "Key: "
    , mono "default_statistics"
    , bold "optional"
    , newline
    , man "#definition_EventType*default_statistic"
    ]


options : List (Html msg)
options =
    [ text "Additional parameters for tuning internal behavior of Nakadi."
    , newline
    , text "Supported options are:"
    , newline
    , text "- "
    , mono "retention_time"
    , text ": Number of milliseconds that Nakadi stores events published to this event type."
    , newline
    , spec "#definition_EventTypeOptions"
    , newline
    , newline
    , bold "Key: "
    , mono "options"
    , bold "optional"
    , newline
    , man "#definition_EventType*options"
    ]


createdAt : List (Html msg)
createdAt =
    [ text "Date and time when this event type was created."
    , newline
    , newline
    , bold "Key: "
    , mono "created_at"
    , bold "readonly"
    , newline
    , man "#definition_EventType*created_at"
    ]


updatedAt : List (Html msg)
updatedAt =
    [ text "Date and time when this event type was last updated."
    , newline
    , newline
    , bold "Key: "
    , mono "updated_at"
    , bold "readonly"
    , newline
    , man "#definition_EventType*updated_at"
    ]


schema : List (Html msg)
schema =
    [ text "The events for the "
    , mono "business"
    , text " and "
    , mono "data"
    , text " categories"
    , text " have their own pre-defined schema structures, based on "
    , link "JSON Schema" "http://json-schema.org/"
    , text ", as well as a schema that is defined custom to the event type when it is created."
    , text " The pre-defined structures describe common fields for an event and the"
    , text " custom schema for the event is defined when the event type is created."
    , newline
    , newline
    , text "When an event for one of these categories is posted to the server, it is expected"
    , text " to conform to the combination of the pre-defined schema and to the custom schema defined "
    , text "for the event type, and not just the custom part of the event."
    , newline
    , text " This combination is called the "
    , link "effective schema" (Config.urlManual ++ "#what-s-an-effective-schema-")
    , text " and is validated by Nakadi for the 'business' and 'data' types."
    , newline
    , text "Submitted events will be validated against it."
    , newline
    , text "For "
    , mono "undefined"
    , text " category, effective schema is exactly the same"
    , text " as the one created with its event type definition."
    , newline
    , newline
    , bold "Key: "
    , mono "schema"
    , bold "required"
    , newline
    , man "#definition_EventType*schema"
    ]


partitions : List (Html msg)
partitions =
    [ text "An event type's stream is divided into one or more partitions and each event is "
    , text "placed into exactly one partition."
    , newline
    , text " Dividing a stream this way allows the overall system to be scaled."
    , newline
    , text " Partitions preserve the order of events."
    , text " Each partition is a fully ordered log, and there is no global ordering across partitions."
    , man "#partitions"
    , newline
    , spec "#/event-types/name/partitions_get"
    ]


publishers : List (Html msg)
publishers =
    [ text "The list of publishers to this Event Type."
    , newline
    , text "This list contains only publishers who posted events in the last four days."
    , newline
    , man "#using_producing-events"
    ]


consumers : List (Html msg)
consumers =
    [ text "The list of low-level consumers for this Event Type."
    , newline
    , text "This list contains only consumers who were (re)conecting to read events in the last four days."
    , newline
    , man "#using_consuming-events-lola"
    ]


subscription : List (Html msg)
subscription =
    [ text "Subscriptions (also knows as the high-level API) allow clients to consume "
    , text "events, where the Nakadi server stores offsets and automatically manages "
    , text "reblancing of partitions across consumer clients. This allows clients to avoid "
    , text "managing stream state locally"
    , newline
    , man "#using_consuming-events-hila"
    , newline
    , newline
    , text "Id of subscription that was created. Generated by Nakadi, should not be specified when"
    , text " creating subscription."
    , newline
    , bold "Note: "
    , i []
        [ text "The subscription is identified by its key parameters (owning_application, event_types, consumer_group). If "
        , text "this endpoint is invoked several times with the same key subscription properties in body (order of even_types is "
        , text "not important) - the subscription will be created only once and for all other calls it will just return "
        , text "the subscription that was already created."
        ]
    , newline
    , spec "#/subscriptions_get"
    ]


audience : List (Html msg)
audience =
    [ text "Intended target audience of the event type."
    , newline
    , text "Relevant for standards around quality of design and documentation,"
    , text " reviews, discoverability, changeability, and permission granting."
    , newline
    , newline
    , link "See the guidelines" "https://opensource.zalando.com/restful-api-guidelines/#219"
    , newline
    , newline
    , bold "Key: "
    , mono "audience"
    , newline
    , bold "optional"
    , newline
    , man "#definition_EventType*audience"
    ]


cleanupPolicy : List (Html msg)
cleanupPolicy =
    [ text "Event type cleanup policy."
    , newline
    , bold "Possible cleanup policies are:"
    , newline
    , text "- "
    , mono "delete"
    , text " will delete old events after retention time expires."
    , newline
    , text "- "
    , mono "compact"
    , text " will keep only the latest event for each event key."
    , text " The key that will be used as a compaction key should be"
    , text " specified in "
    , link "partition_compaction_key" (Config.urlManual ++ "#definition_EventMetadata*partition_compaction_key")
    , text " field of "
    , link "event metadata." (Config.urlManual ++ "#definition_EventMetadata")
    , newline
    , newline
    , bold "Key: "
    , mono "cleanup_policy"
    , bold "optional"
    , newline
    , bold "Default: "
    , mono "delete"
    , newline
    , man "#definition_EventType*cleanup_policy"
    ]


orderingKeyFields : List (Html msg)
orderingKeyFields =
    [ text "This field is useful in case the producer wants to communicate the complete"
     , text "order accross all the events published to all partitions."
     , text " This is the case when there is an incremental generator on the producer side."
    , newline
    , bold "This is only an informational field. No reordering is done by Nakadi."
    , newline
    , newline
    , bold "Key: "
    , mono "ordering_key_fields"
    , bold "optional"
    , newline
    , man "#definition_EventType*ordering_key_fields"
    ]

authorization : List (Html msg)
authorization =
    [ text "Authorization section for an event type. This section defines three access control lists:"
    , newline
    , mono "writers"
    , text " - for producing events "
    , newline
    , text "An array of subject attributes that are required for writing events to the event type. Any one of the "
    , text "attributes defined in this array is sufficient to be authorized."
    , newline
    , newline
    , mono "readers"
    , text " - for consuming events"
    , newline
    , text "An array of subject attributes that are required for reading events from the event type. Any one of the "
    , text "attributes defined in this array is sufficient to be authorized. The wildcard item takes precedence over "
    , text "all others, i.e., if it is present, all users are authorized."
    , newline
    , newline
    , mono "admins"
    , text " - for administering an event type"
    , newline
    , text "An array of subject attributes that are required for updating the event type. Any one of the attributes "
    , text "defined in this array is sufficient to be authorized. The wildcard item takes precedence over all others, "
    , text "i.e. if it is present, all users are authorized."
    , newline
    , newline
    , text "An attribute for authorization. This object includes a data type, which represents the type of the attribute "
    , text "attribute (which data types are allowed depends on which authorization plugin is deployed, and how it is "
    , text "configured), and a value. A wildcard can be represented with data type '*', and value '*'. It means that all "
    , text "authenticated users are allowed to perform an operation."
    , newline
    , newline
    , bold "Key: "
    , mono "authorization"
    , bold "optional"
    , newline
    , man "#using_authorization"
    ]

partitionCompactionKeyField : List (Html msg)
partitionCompactionKeyField =
    [ text "This field is useful & necessary in case the input event type is non log-compacted"
     , text " and the output event type is required to be log-compacted. The user then needs to specify"
     , text " the field to be used as the partition_compaction_key for the output event type"
     , text " using the path of a non-nullable string field. If the output and the input event type"
     , text " are both log-compacted, then the compaction key of input is used as the compaction key"
     , text " for the output."
    , newline
    , bold "This field is mandatory only if input event type is non log-compacted and output event type is compacted"
    , newline
    , newline
    , bold "Key: "
    , mono "partion_compaction_key_field"
    , bold "optional"
    ]