var express = require('express');
var http = require('http');
var app = express();

// body parsing
var bodyParser = require('body-parser');
app.use(bodyParser.urlencoded({extended: true}));
app.use(bodyParser.json());

// logging
var logger = require('morgan');
app.use(logger('dev'));

// auth
var passport = require('passport');
var cookieParser = require('cookie-parser');
var session = require('cookie-session');
var methodOverride = require('method-override');
app.use(cookieParser());
app.use(methodOverride());
app.use(session({
	secret: '783ygb39fg9g492bfvopskdnf',
	cookie : {
    	maxAge : 604800 // one week
  	},
}));
app.use(passport.initialize());
app.use(passport.session());

// sass
var sass = require('node-sass');
app.use(
	sass.middleware({
		src: __dirname + '/', 
		dest: __dirname + '/',
		debug: true
	})
);

// assets
var path = require('path');

// web
app.set('view engine', 'jsx');
app.engine('jsx', require('express-react-views').createEngine());

// var url         = require('url');
// var ReactAsync  = require('react-async');
// var nodejsx     = require('node-jsx').install();
// var WebApp	    = require('./web');
// function renderWebApp(request, response, next) {
// 	var api_hostname = 'http://secret-fjord-9154.herokuapp.com';
// 	if (process.env.NODE_ENV == 'development') {
// 		api_hostname = 'http://localhost:' + process.env.PORT;
// 	}
// 	var app = WebApp({
// 		api_hostname: api_hostname,
// 		path: url.parse(request.url).pathname,
// 	});
// 	ReactAsync.renderComponentToStringWithAsyncState(app, function(error, markup) {
// 		if (error) {
// 			return next(error);
// 		}
// 		response.send('<!doctype html>\n' + markup);
// 	});
// }

// routing
var routes_api = require('./routes/api');
var routes_model = require('./routes/model');
var routes_web = require('./routes/web');
var routes_auth = require('./routes/auth');
app.use('/assets', express.static(path.join(__dirname, 'assets')));
app.use('/api/model', routes_model);
app.use('/api', routes_api);
app.use('/auth', routes_auth);
app.use(routes_web);

// run
var server = http.createServer(app).listen(process.env.PORT || 3000, function() {
    console.log('Listening on port %d', server.address().port);
});

