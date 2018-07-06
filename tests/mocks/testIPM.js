const express = require('express');
const http = require('http');
const app = express();

app.get('/', (req, res, done) =>{
    const url = req.query.callbackURL+'?code=123';
    res.redirect(url);
});

app.post('/', (req, res, done) => {
       res.json({
           "access_token": "fake-access-token12345",
           "refresh_token": "fake-refresh-token12345",
           "id": "testuser",
           "name": "TestUserName"
       })
});

module.exports = http.createServer(app);

