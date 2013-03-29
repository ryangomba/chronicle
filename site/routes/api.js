var express = require('express');
var router = express.Router();

var Stories = require('../models/stories');
var Facebook = require('../sharing/facebook');

// get all stories shared by a particular user
router.get('/users/:user_pk/stories', function(request, response) {
	var user_pk = request.params['user_pk'];
	Stories.getStoriesForUser(user_pk, function(error, stories) {
		if (error) {
			response.send(500, error);
		} else {
	    	response.send(200, stories);
		}
	});
});

// get a story with all its bits
router.get('/stories/:story_pk', function(request, response) {
	var story_pk = request.params['story_pk'];
	Stories.getStoryWithBits(story_pk, function(error, story) {
		if (error) {
			response.send(500, error);
		} else {
			response.send(200, story);
		}
	});
});

// publish a story to facebook
// router.get('/stories/:story_pk/publish', function(request, response) {
// 	Facebook.postTestStory(function(error, fb_response) {
// 		if (error) {
// 			response.send(500, error);
// 		} else {
// 	    	response.send(200, fb_response);
// 		}
// 	});
// });

module.exports = router;
