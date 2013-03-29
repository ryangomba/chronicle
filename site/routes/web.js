var express = require('express');
var router = express.Router();

var passport = require('passport');
var kjsdjnsk = require('./auth'); // HACK

var Stories = require('../models/stories');

var isLoggedIn = function(request, response, next) {
	if (request.isAuthenticated()) {
		return next();
	}
	response.redirect('/auth/login');
}

// get a story
router.get('/stories/:story_pk', function(request, response) {
	var story_pk = request.params['story_pk'];
	Stories.getStoryWithBits(story_pk, function(error, story) {
		if (error) {
			response.send(500, error);
		} else {
	    	response.render('story', {
				story: story,
				user: request.user,
			});
		}
	});
});

// get all stories shared by a particular user
router.get('/:user_pk', function(request, response) {
	var user_pk = request.params['user_pk'];
	Stories.getStoriesForUser(user_pk, function(error, stories) {
		if (error) {
			response.send(500, error);
		} else {
	    	response.render('stories', {
				stories: stories,
				user: request.user,
			});
		}
	});
});

module.exports = router;
