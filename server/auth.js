const express = require('express');
const passport = require('passport');

passport.serializeUser(pass);
passport.deserializeUser(pass);

/**
 * @module
 * This is an auth related login/logout endpoints
 * It uses passport framework fro user authentication
 *
 * @param {object} authConf
 * @param {string} authConf.strategy Name of the passport auth Strategy
 * @param {object} authConf.options list of options for the given Strategy
 * @returns {function[]}
 */
module.exports = (authConf, settings) => {
    const Strategy = require(authConf.strategy).Strategy;

    passport.use('oauth', new Strategy(authConf.options, profileToUser));

    const router = express();
    router.get('/auth/user', getUser(settings));
    router.get('/auth/logout', logout);
    router.get('/auth/login', saveReturnTo, passport.authenticate('oauth'));
    router.get('/auth/callback', passport.authenticate('oauth', {successReturnToOrRedirect: '/'}));

    return [
        passport.initialize(),
        passport.session(),
        router];
};

/**
 * Do nothing
 * this stab for serialise the user to/from session one to one
 *
 * @param {object} obj
 * @param {function} done
 */
function pass(obj, done) {
    done(null, obj)
}

/**
 *  Convert received profile to the user data  object stored in session
 *
 * @param {string} accessToken
 * @param {string} refreshToken
 * @param {object} profile
 * @param {function} done
 */
function profileToUser(accessToken, refreshToken, profile, done) {
    const user = {
        id: profile.id,
        name: profile.displayName || profile.name,
        accessToken,
        refreshToken
    };
    return done(null, user);
}

/**
 * Generate middleware function that
 * Read user date from the session and convert it to response for /auth/user
 * @param {Object} settings
 * @returns {function(Request, Response, Callback)}
 */
function getUser(settings) {
    /**
     * Read user date from the session and convert it to response for /auth/user
     * @param {Request} req
     * @param {Response} res
     */
    return function(req, res) {
        const userResponse = req.user ? {
                id: req.user.id,
                name: req.user.name,
                settings: settings
            } :
            {};


        res.json(userResponse);
    };
}

/**
 * Save the last page to the session so user can return back
 * after authentication redirect
 *
 * @param {Request} req
 * @param {Response} res
 * @param {Function} next
 */
function saveReturnTo(req, res, next) {
    req.session.returnTo = req.query.returnTo || '';
    next();
}

/**
 * Do logout and redirect to previous page
 * Unusually it removes user data from the session
 *
 * @param {Request} req
 * @param {Response} res
 */
function logout(req, res) {
    const returnTo = req.query.returnTo || '/';
    req.logout();
    res.redirect(returnTo);
}

/*unit-test*/
module.exports.__private = {
    pass, profileToUser, getUser, saveReturnTo, logout
};
