const fs = require('fs-extra');

const filesToCopy = [
    {src: "./node_modules/bootstrap/dist/css", dest: "./lib/bootstrap/dist/css"},
    {src: "./node_modules/video.js/dist/video-js.min.css", dest: "./lib/video.js/dist/video-js.min.css"},
    {src: "./node_modules/video.js/dist/video.min.js", dest: "./lib/video.js/dist/video.min.js"},
    {src: "./node_modules/videojs-youtube/dist/Youtube.min.js", dest: "./lib/videojs-youtube/dist/Youtube.min.js"},
    // {src: "./lib/compiled.js/compiled.js", dest: "./lib/compiled.js"}
];

const copySingle = file => fs.copy(file.src, file.dest, (err) => {
    if (err) throw err;
    console.log(file.src + ' was copied to ' + file.dest);
});

const copier = (files) => files.forEach(copySingle);

fs.emptyDirSync('./lib');

copier(filesToCopy);
