module Helpers.Task exposing (delay, dispatch)

import Process
import Task
import Time


delay : Time.Time -> msg -> Cmd msg
delay time msg =
    Task.perform identity (Task.andThen (always (Task.succeed msg)) (Process.sleep time))


dispatch : msg -> Cmd msg
dispatch msg =
    Task.perform identity (Task.succeed msg)
