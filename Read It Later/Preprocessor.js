var Preprocessor = function() {};

Preprocessor.prototype = {
    run: function(arguments) {
        arguments.completionFunction({"URL": document.URL, "title": document.title });
    }
};

var ExtensionPreprocessingJS = new Preprocessor;
