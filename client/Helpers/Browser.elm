module Helpers.Browser exposing (..)

import Task exposing (Task)
import Native.Browser


{-| Redirect current window to new url using
    window.location.href = url
-}
setLocation : String -> a
setLocation url =
    Native.Browser.setLocation url


{-| Get current window location
    dummy param is required to make it a function for Elm
-}
getLocation : a -> String
getLocation dummy =
    Native.Browser.getLocation dummy


{-| Show the value in debug console with the time metric
-}
log : b -> a -> a
log =
    Native.Browser.log


{-| Start browser debugger
-}
startDebugger : a -> a
startDebugger any =
    Native.Browser.startDebugger any


pushState : String -> Task x String
pushState =
    Native.Browser.pushState


replaceState : String -> Task x String
replaceState =
    Native.Browser.replaceState

