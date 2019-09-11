module Pages.TeamDetails.Update exposing (update)

import Helpers.Store as Store
import Helpers.Task exposing (dispatch)
import Pages.TeamDetails.Messages exposing (Msg(..))
import Routing.Models exposing (Route(..))
import Stores.TeamDetails exposing (Model)


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    case message of
        OnRouteChange route ->
            case route of
                TeamDetailsRoute params ->
                    ( model, loadTeamDetails params.id )

                _ ->
                    ( model, Cmd.none )

        TeamDetailStoreMsg subMsg ->
            let
                ( newModel, msg ) =
                    Stores.TeamDetails.update subMsg model
            in
            ( newModel, Cmd.map TeamDetailStoreMsg msg )



--        Done result ->
--            case result of
--                Ok value ->
--                    ( { model | result = value }, Cmd.none )
--
--                Err error ->
--                    ( { model | result = Debug.toString error }, Cmd.none )


loadTeamDetails : String -> Cmd Msg
loadTeamDetails id =
    dispatch (TeamDetailStoreMsg (Store.SetParams [ ( "id", id ) ]))



--    Http.send Done <|
--        Http.getString
--            (Config.urlTeamApi
--                ++ id
--            )
