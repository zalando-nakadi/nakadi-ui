const express = require('express');
const http = require('http');
const app = express();
const query = require('./data/sqlquery');
app.get('/queries/:id', (req, res, done) =>{
       res.json(query)
});

app.post('/queries', (req, res, done) => {
       res.json({})
});

http.createServer(app).listen(6341);
