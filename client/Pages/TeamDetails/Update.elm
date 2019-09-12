module Pages.TeamDetails.Update exposing (update)

import Helpers.Store as Stores
import Helpers.Task exposing (dispatch)
import Pages.TeamDetails.Messages exposing (Msg(..))
import Pages.TeamDetails.Models exposing (Model)
import Routing.Models exposing (Route(..))
import Stores.TeamDetails


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
                    Stores.TeamDetails.update subMsg model.store
            in
            ( { model | store = newModel }, Cmd.map TeamDetailStoreMsg msg )

        PageChange int ->
            ( { model | page = int }, Cmd.none )

        Refresh ->
            ( model, dispatch (TeamDetailStoreMsg Stores.FetchData) )

        FilterChange string ->
            ( { model | filter = string }, Cmd.none )

        SortBy maybe bool ->
            ( { model | sortBy = maybe, sortReverse = bool }, Cmd.none )


loadTeamDetails : String -> Cmd Msg
loadTeamDetails id =
    dispatch (TeamDetailStoreMsg (Stores.SetParams [ ( "id", id ) ]))
