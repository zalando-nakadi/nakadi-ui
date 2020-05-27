module User.Commands exposing (fetchAll, logout, logoutIfExpired, memberDecoder, settingsDecoder)

import Config
import Constants exposing (emptyString)
import Helpers.Http exposing (postString)
import Http exposing (Error(..))
import Json.Decode as Decode exposing (Decoder, bool, maybe, string, succeed)
import Json.Decode.Pipeline exposing (optional, required)
import User.Messages exposing (Msg(..))
import User.Models exposing (Settings, User)


fetchAll : Cmd User.Messages.Msg
fetchAll =
    Http.send FetchAllDone <| Http.get Config.urlUser memberDecoder


memberDecoder : Decode.Decoder (Maybe User)
memberDecoder =
    succeed User
        |> required Constants.id string
        |> required Constants.name string
        |> required "settings" settingsDecoder
        |> maybe


settingsDecoder : Decoder Settings
settingsDecoder =
    succeed Settings
        |> required "nakadiApiUrl" string
        |> optional "appsInfoUrl" string emptyString
        |> optional "usersInfoUrl" string emptyString
        |> optional "monitoringUrl" string emptyString
        |> optional "sloMonitoringUrl" string emptyString
        |> optional "eventTypeMonitoringUrl" string emptyString
        |> optional "subscriptionMonitoringUrl" string emptyString
        |> optional "docsUrl" string emptyString
        |> optional "schemaEvolutionDocs" string emptyString
        |> optional "supportUrl" string emptyString
        |> optional "forbidDeleteUrl" string emptyString
        |> optional "allowDeleteEvenType" bool False
        |> optional "deleteSubscriptionWarning" string emptyString
        |> optional "showNakadiSql" bool False
        |> optional "queryMonitoringUrl" string emptyString
        |> optional "retentionTimeDaysDefault" string emptyString
        |> optional "retentionTimeDaysValues" string emptyString


{-| Redirect browser to logout
This function never actually returns
-}
logout : Cmd msg
logout =
    postString (\_ -> Debug.todo "Logout never returns") "elm:forceReLogin" Config.urlLogout


{-| Check the response from the server and if return is not recoverable
(like expired credentials) redirect browser to logout.
This way it's cleaning all cached data and redirects the user back to the login page.
-}
logoutIfExpired : Http.Error -> Cmd msg
logoutIfExpired error =
    case error of
        BadStatus response ->
            case response.status.code of
                401 ->
                    logout

                _ ->
                    Cmd.none

        _ ->
            Cmd.none
