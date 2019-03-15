module Helpers.Task exposing (dispatch)

import Task


dispatch : msg -> Cmd msg
dispatch msg =
    Task.perform identity (Task.succeed msg)
