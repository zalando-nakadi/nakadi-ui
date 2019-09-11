module Pages.TeamDetails.Update exposing (update)

import Config
import Http
import Pages.TeamDetails.Messages exposing (Msg(..))
import Pages.TeamDetails.Models exposing (Model)
import Routing.Models exposing (Route(..))


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    case message of
        OnRouteChange route ->
            case route of
                TeamDetailsRoute params ->
                    ( { model | id = params.id }, loadTeamDetails params.id )

                _ ->
                    ( model, Cmd.none )

        Done result ->
            case result of
                Ok value ->
                    ( { model | result = value }, Cmd.none )

                Err error ->
                    ( { model | result = Debug.toString error }, Cmd.none )


loadTeamDetails : String -> Cmd Msg
loadTeamDetails id =
    Http.send Done <|
        Http.getString
            (Config.urlTeamApi
                ++ id
            )
