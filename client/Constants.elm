module Constants exposing (..)


msInDay : Int
msInDay =
    24 * 60 * 60 * 1000


userDateTimeFormat : String
userDateTimeFormat =
    "%b %d %Y, %-I:%M %p"


emptyString : String
emptyString =
    ""


filter : String
filter =
    "filter"


page : String
page =
    "page"


name : String
name =
    "name"


id : String
id =
    "id"


eventTypeName : String
eventTypeName =
    "eventTypeName"


sortBy : String
sortBy =
    "sortBy"


reverse : String
reverse =
    "reverse"


noneLabel : String
noneLabel =
    "(none)"


starOn : String
starOn =
    " ★ "


starOff : String
starOff =
    " ☆ "
