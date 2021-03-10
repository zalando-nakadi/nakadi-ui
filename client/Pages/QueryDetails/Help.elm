module Pages.QueryDetails.Help exposing (authorization, query, createdAt, updatedAt, envelope)

import Config exposing (appPreffix)
import Helpers.UI exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)


query : List (Html msg)
query =
    [ text "Id of this SQL Query."
    ]


authorization : List (Html msg)
authorization =
    [ text "Authorization section for the SQL Query. This section defines two access control lists:"
    , newline
    , mono "readers"
    , text " - for consuming events from the output event type"
    , newline
    , text "An array of subject attributes that are required for reading events from the output event type of the SQL Query. Any one of the "
    , text "attributes defined in this array is sufficient to be authorized. The wildcard item takes precedence over "
    , text "all others, i.e., if it is present, all users are authorized."
    , newline
    , newline
    , mono "admins"
    , text " - for administering the SQL Query"
    , newline
    , text "An array of subject attributes that are required for updating the SQL Query. Any one of the attributes "
    , text "defined in this array is sufficient to be authorized. The wildcard item takes precedence over all others, "
    , text "i.e. if it is present, all users are authorized."
    , newline
    , newline
    , text "An attribute for authorization. This object includes a data type, which represents the type of the attribute "
    , text "attribute (which data types are allowed depends on which authorization plugin is deployed, and how it is "
    , text "configured), and a value. Wildcards are not allowed for admins of event types and subscriptions."
    , newline
    , newline
    , bold "Key: "
    , mono "authorization"
    , bold "optional"
    , newline
    , man "#using_authorization"
    ]


createdAt : List (Html msg)
createdAt =
    [ text "Date and time when this SQL Query was created."
    , newline
    , newline
    , bold "Key: "
    , mono "created"
    , bold "readonly"
    --, newline
    --, man "#definition_EventType*created_at"
    ]


updatedAt : List (Html msg)
updatedAt =
    [ text "Date and time when this SQL Query was last updated."
    , newline
    , newline
    , bold "Key: "
    , mono "updated_at"
    , bold "readonly"
    --, newline
    --, man "#definition_EventType*updated_at"
    ]


envelope : List (Html msg)
envelope =
    [ text "This field is which allows user to choose if the output event-type’s schema is enveloped within the table"
    , text "alias name. If set to false, the schema of the output event types is same as the input event type and"
    , text "the events present in the input event type are published/filtered to the output event type without"
    , text " any modification."
    , newline
    , bold "This field is by default set to True "
    , newline
    , newline
    , bold "Key: "
    , mono "envelope"
    , bold "optional"
    ]
