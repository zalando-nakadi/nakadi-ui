module Types exposing (AppHtml)

import Html
import Messages


type alias AppHtml =
    Html.Html Messages.Msg
