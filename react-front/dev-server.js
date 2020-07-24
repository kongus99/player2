const {createProxyMiddleware} = require('http-proxy-middleware');
const Bundler = require('parcel-bundler');
const express = require('express');


const bundler = new Bundler('index.html', {
    cache: true,
    outDir: './lib',
});

const app = express();

app.use('/api', createProxyMiddleware({target: 'http://localhost:8080', changeOrigin: true}));
app.use(bundler.middleware());
app.listen(3000);
