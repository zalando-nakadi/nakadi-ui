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


{-| Getting the  real client width of the element (without borders)
example:
    w =
        getElementWidth "header"
-}
getElementWidth : String -> Int
getElementWidth =
    Native.Browser.getElementWidth


{-| Getting the real client height of the element (without borders)
example:
    h =
        getElementHeight "header"
-}
getElementHeight : String -> Int
getElementHeight =
    Native.Browser.getElementHeight


copyToClipboard : String -> a
copyToClipboard =
    Native.Browser.copyToClipboard
