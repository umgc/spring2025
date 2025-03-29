// server.js
const express = require('express');
const request = require('request'); // or 'node-fetch'
const cors = require('cors');
const app = express();

// Use CORS middleware to allow cross-origin requests
app.use(cors());

// Replace with your actual Google Directions API key
const API_KEY = 'AIzaSyB2q51jhoYsBNMa1MSOrSCj08mDXuSGUN0';

// Endpoint to proxy requests to the Google Directions API
app.get('/directions', (req, res) => {
  // Query params: ?origin=lat,lng&destination=lat,lng
  const origin = req.query.origin;
  const destination = req.query.destination;

  const googleUrl = `https://maps.googleapis.com/maps/api/directions/json?origin=${origin}&destination=${destination}&mode=walking&key=${API_KEY}`;

  request(googleUrl, (error, response, body) => {
    if (!error && response.statusCode === 200) {
      res.send(body); // Return the JSON from Google
    } else {
      res.status(500).send({ error: 'Something went wrong with Directions API' });
    }
  });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Proxy server running on port ${PORT}`);
});
