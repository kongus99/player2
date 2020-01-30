const compile = require("node-elm-compiler").compile;

compile(["./src/Main.elm"], {
    output: "./lib/compiled.js",
    optimize : true
}).on('close', function(exitCode) {
    console.log("Finished with exit code", exitCode);
});



