var db = require('../database/db');

var Moment  = require('moment');

exports.getStoriesForUser = function(user_pk, callback) {
	db.getAllModelsInCollection('story', user_pk, function(error, stories) {
		if (error) {
			callback(error, null);
		} else {
			stories.sort(function(story1, story2) {
				var date1 = Moment(story1.date);
				var date2 = Moment(story2.date);
				return date1 - date2;
			});
	    	callback(null, stories);
		}
	});
}

exports.getStoryWithBits = function(user_pk, story_pk, callback) {
	db.getModel('story', user_pk, story_pk, function(error, story) {
		db.getAllModelsInCollection('bit', story_pk, function(error, bits) {
			if (error) {
				callback(error, null);
			} else {
				var bitMap = {};
				for (var i in bits) {
					var bit = bits[i];
					bitMap[bit.pk] = bit;
				}
				story.bits = [];
				for (var i in story.bitPKs) {
					var bitPK = story.bitPKs[i];
					var bit = bitMap[bitPK];
					if (bit) {
						story.bits.push(bit);
					}
				}
		    	callback(null, story);
			}
		});
	})
}
