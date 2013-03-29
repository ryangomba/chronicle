var opengraph = require('fbgraph');

var ryan_token = 'CAAGzbH5rsiQBAPTOuf8GGYCkUZAPVnqSmZC6Qm7vPbeTQjswc9z6JPUsa3XKqtjeg6QBZCZCT08aXDoT4MBXhz36OnHG7m25UdHthDUjsAaIFXOpofMwIGF3fTO9Q202KOxQhYDZCQtACZBqHxBueZCGc5TvOZCZBg4N0zpAzIeI6iOvdwoJSwkGcQ73mZC6JnsmEZD';
var graham_token = 'CAAGzbH5rsiQBAFuD5tNQcWoMFDwDuQce0ZChGno6ZBlGFTDhSfkuH78DJYtcCiEU2U5s3iFVy0sx0OGfKw24e1YqLZAXqr8kZCkUesRMZAL9LlP6jBcxBdaXeyJjEz7Qf3JbyKWUIz2VBOHUWBoxOkaXrOVYtnB4lR7ZCY7vQzMALubLQwjffcQw68LQPZAxd4ZD';

opengraph.setAccessToken(graham_token);

function postNormalTestStory(callback) {
	var url = 'me' + "/feed";
	var post = {
		'link': 'http://secret-fjord-9154.herokuapp.com/stories/4D03DA86-60B7-4DF9-9619-B05CA9643C0D',
		'tags': '100004090626921',
		'privacy': {
			'value': 'SELF',
		},
		'place': '140616852679676',
		'message': 'Testing!',
	}
	opengraph.post(url, post, function(error, response) {
        console.log(error, response);
        callback(error, response);
    });
}

function postOpenGraphTestStory(callback) {
	var ryan_id = '779018113';
	var graham_id = '100004090626921';
	var url = 'me' + "/chroniclestories:create";
	var post = {
		'fb:explicitly_shared': true,
		'story': 'http://secret-fjord-9154.herokuapp.com/stories/0D49CAB7-04E1-40DF-AD99-3039AC71D70B',
		'tags': ryan_id,
		'privacy': {
			'value': 'SELF',
			// 'value': 'ALL_FRIENDS',
		},
		// 'place': '140616852679676',
		// 'message': 'Testing!',
	}
	opengraph.post(url, post, function(error, response) {
        console.log(error, response);
        callback(error, response);
    });
}

exports.postTestStory = function(callback) {
	// postNormalTestStory(callback);
	postOpenGraphTestStory(callback);
};
