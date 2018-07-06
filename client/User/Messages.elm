module User.Messages exposing (..)

import Http
import User.Models exposing (User)

type Msg
    = FetchAllDone (Result Http.Error (Maybe User))
    | FetchData
    | LoginDone
