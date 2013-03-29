var express = require('express');
var router = express.Router();

var User = require('../models/users');

var passport = require('passport');
passport.serializeUser(function(user, done) {
    done(null, user.pk);
});
passport.deserializeUser(function(user_pk, done) {
    User.getUser(user_pk, function(error, user) {
        done(error, user);
    });
});
var FacebookStrategy = require('passport-facebook').Strategy;
var facebookStategy = new FacebookStrategy({
	clientID: '478753535537700',
	clientSecret: '605ddf52e61fcd0645bf0eb38de291bc',
	callbackURL: 'http://localhost:5000/auth/facebook/callback',
}, function(accessToken, refreshToken, profile, done) {
	var user_pk = profile['id'];
	var user = {
		'pk': user_pk,
		'name': profile['displayName'],
		'fist_name': profile['name']['givenName'],
		'last_name': profile['name']['familyName'],
		'accessToken': accessToken,
	};
	User.saveUser(user, function(error, user) {
		done(error, user);
	});

});
passport.use('facebook', facebookStategy);

var default_scope = ['user_friends', 'email', 'publish_stream', 'publish_actions'];

router.get('/login', passport.authorize('facebook', {
	failureRedirect: '/',
	successRedirect: '/logged-in',
}));

router.get('/logout', function(request, response) {
	request.logOut();
  	response.redirect('/');
});

router.get('/facebook', function(request, response) {
 	passport.authenticate('facebook', {
 		scope: default_scope,
 	});
});

router.get('/facebook/callback', passport.authenticate('facebook', {
	successRedirect: '/success',
	failureRedirect: '/login',
}));

module.exports = router;
