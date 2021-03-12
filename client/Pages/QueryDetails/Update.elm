module Pages.QueryDetails.Update exposing (update)

import Config
import Constants
import Helpers.Http exposing (postString)
import Helpers.Store as Store
import Helpers.Task exposing (dispatch)
import Http
import Pages.QueryDetails.Messages exposing (Msg(..))
import Pages.QueryDetails.Models exposing (Model, Tabs(..), initialModel)
import RemoteData exposing (RemoteData(..), WebData, isFailure, isSuccess)
import Routing.Models exposing (Route(..))
import Url exposing (percentEncode)
import User.Commands exposing (logoutIfExpired)
import User.Models exposing (Settings)


update : Settings -> Msg -> Model -> ( Model, Cmd Msg, Route )
update settings message model =
    let
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
                                    [ dispatch CloseDeleteQueryPopup
                                    , dispatch Reload
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

                OpenDeleteQueryPopup ->
                    ( { model
                        | deleteQueryResponse = NotAsked
                        , deleteQueryPopupCheck = False
                        , deleteQueryPopupOpen = True
                      }
                    , Cmd.none
                    )

                CloseDeleteQueryPopup ->
                    ( { model | deleteQueryPopupOpen = False }, Cmd.none )

                ConfirmQueryDelete ->
                    ( { model | deleteQueryPopupCheck = not model.deleteQueryPopupCheck }, Cmd.none )

                QueryDelete ->
                    ( model, deleteQuery QueryDeleteResponse model.id )

                QueryDeleteResponse response ->
                    let
                        cmd =
                            if response |> isSuccess then
                                Cmd.batch
                                    [ dispatch OutOnQueryDeleted
                                    , dispatch CloseDeleteQueryPopup
                                    ]

                            else
                                Cmd.none
                    in
                    ( { model | deleteQueryResponse = response }, cmd )

                OutOnQueryDeleted ->
                    ( model, Cmd.none )
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


deleteQuery : (WebData () -> msg) -> String -> Cmd msg
deleteQuery tagger id =
    Http.request
        { method = "DELETE"
        , headers = []
        , url = Config.urlNakadiSqlApi ++ "queries/" ++ percentEncode id
        , body = Http.emptyBody
        , expect = Http.expectStringResponse (always (Ok ()))
        , timeout = Nothing
        , withCredentials = False
        }
        |> RemoteData.sendRequest
        |> Cmd.map tagger
