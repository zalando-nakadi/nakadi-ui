module Pages.Partition.Help exposing (offset)

import Helpers.UI exposing (..)
import Html exposing (..)


offset : List (Html msg)
offset =
    [ text "The "
    , mono "offset"
    , text " value of the cursor allows you select where in the stream partition you want to "
    , text "consume from. This can be any known offset value, or the dedicated value "
    , mono "BEGIN"
    , text " which will start the stream from the beginning."
    , newline
    , man "#cursors-and-offsets"
    , newline
    , text "The first loaded Event is the "
    , bold "first one after"
    , text " the one pointed to in the cursor."
    , newline
    , spec "#/event-types/name/events_get*x-nakadi-cursors"
    ]
