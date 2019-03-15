module User.Messages exposing (Msg(..))

import Http
import User.Models exposing (User)


type Msg
    = FetchAllDone (Result Http.Error (Maybe User))
    | FetchData
    | LoginDone
