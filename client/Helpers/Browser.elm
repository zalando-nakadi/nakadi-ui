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

pushState : String -> Task x String
pushState =
    Native.Browser.pushState


replaceState : String -> Task x String
replaceState =
    Native.Browser.replaceState

