const express = require('express');
const http = require('http');
const app = express();
const query = require('./data/sqlquery');

app.get('/queries/ad.nakadi.sql.demo.et', (req, res, done) =>{
    res.status(404).json({})
});

app.get('/queries/:id', (req, res, done) =>{
       res.json(query)
});

app.delete('/queries/:id', (req, res, done) =>{
    res.json({})
});

app.post('/queries', (req, res, done) => {
       res.json({})
});

module.exports = http.createServer(app);
