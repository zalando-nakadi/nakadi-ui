module Pages.QueryDetails.Update exposing (update)

--import Pages.QueryDetails.QueryTab exposing (deleteQuery, loadQuery)

import Config
import Constants
import Helpers.Http exposing (postString)
import Helpers.Store as Store
import Helpers.Task exposing (dispatch)
import Http
import Pages.QueryDetails.Messages exposing (Msg(..))
import Pages.QueryDetails.Models exposing (Model, Tabs(..), initialModel)
import RemoteData exposing (RemoteData(..), isFailure, isSuccess)
import Routing.Models exposing (Route(..))
import Url exposing (percentEncode)
import User.Commands exposing (logoutIfExpired)
import User.Models exposing (Settings)


update : Settings -> Msg -> Model -> ( Model, Cmd Msg, Route )
update settings message model =
    let
        -- deletePopup =
        --     model.deletePopup
        ( resultModel, resultCmd ) =
            case message of
                OnRouteChange route ->
                    let
                        updatedModel =
                            routeToModel route model

                        cmd =
                            if updatedModel.id == model.id then
                                Cmd.none

                            else
                                Cmd.batch
                                    [ --dispatch CloseDeletePopup
                                      --,
                                      dispatch Reload
                                    ]
                    in
                    ( updatedModel, cmd )

                Reload ->
                    ( model
                    , Cmd.batch
                        [ dispatch (TabChange model.tab)
                        ]
                    )

                CopyToClipboard content ->
                    ( model, postString CopyToClipboardDone "elm:copyToClipboard" content )

                CopyToClipboardDone _ ->
                    ( model, Cmd.none )

                TabChange tab ->
                    ( { model | tab = tab }
                    , case tab of
                        QueryTab ->
                            Cmd.none

                        --
                        -- TODO: reuse for input/output event types
                        --
                        -- ConsumerTab ->
                        --     Cmd.batch
                        --         [ dispatch LoadConsumers
                        --         , dispatch LoadConsumingQueries
                        --         ]
                        AuthTab ->
                            Cmd.none
                    )

        -- OpenDeletePopup ->
        --     let
        --         newDeletePopup =
        --             initialModel.deletePopup
        --         openedDeletePopup =
        --             { newDeletePopup | isOpen = True }
        --     in
        --     ( { model | deletePopup = openedDeletePopup }
        --     , Cmd.batch [ dispatch LoadConsumers, dispatch LoadConsumingQueries ]
        --     )
        -- CloseDeletePopup ->
        --     ( { model | deletePopup = initialModel.deletePopup }, Cmd.none )
        -- ConfirmDelete ->
        --     let
        --         newPopup =
        --             { deletePopup | deleteCheckbox = not deletePopup.deleteCheckbox }
        --     in
        --     ( { model | deletePopup = newPopup }, Cmd.none )
        -- Delete ->
        --     ( { model | deletePopup = Store.onFetchStart deletePopup }, callDelete model.name )
        -- DeleteDone result ->
        --     case result of
        --         Ok () ->
        --             ( { model | deletePopup = Store.onFetchStart deletePopup }
        --             , Cmd.batch
        --                 [ dispatch OutOnQueryDeleted
        --                 , dispatch CloseDeletePopup
        --                 ]
        --             )
        --         Err error ->
        --             ( { model | deletePopup = Store.onFetchErr deletePopup error }, logoutIfExpired error )
    in
    ( resultModel, resultCmd, modelToRoute resultModel )


modelToRoute : Model -> Route
modelToRoute model =
    QueryDetailsRoute
        { id = model.id }
        { tab =
            if model.tab == QueryTab then
                Nothing

            else
                Just model.tab
        }


routeToModel : Route -> Model -> Model
routeToModel route model =
    case route of
        QueryDetailsRoute params query ->
            { model
                | id = params.id
                , tab = query.tab |> Maybe.withDefault initialModel.tab
            }

        _ ->
            model
