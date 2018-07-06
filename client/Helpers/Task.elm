module Helpers.Task exposing (..)

import Time
import Task
import Process


delay : Time.Time -> msg -> Cmd msg
delay time msg =
    Task.perform identity (Task.andThen (always (Task.succeed msg)) (Process.sleep time))


dispatch : msg -> Cmd msg
dispatch msg =
    Task.perform identity (Task.succeed msg)

