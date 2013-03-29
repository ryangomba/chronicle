/** @jsx React.DOM */

var React = require('react');
var superagent  = require('superagent');
var Moment  = require('moment');

var BitType = {
    PHOTO: 1,
    VIDEO: 2,
    TEXT: 3,
}

var TextBitType = {
    TITLE: 0,
    PARAGRAPH: 1,
}

function titleForStory(story) {
    var title = 'Ryan Gomba\'s Story';
    for (var i in story.bits) {
        var bit = story.bits[i];
        if (bit.type == BitType.TEXT) {
            if (bit.textType == TextBitType.TITLE) {
                title = bit.text;
                break;
            }
        }
    }
    return title;
}

function descriptionForStory(story) {
	var description = '';
	for (var i in story.bits) {
		var bit = story.bits[i];
		if (bit.type == BitType.TEXT) {
            if (bit.textType == TextBitType.PARAGRAPH) {
    			description = bit.text;
    			break;
            }
		}
	}
	return description;
}

var bucket_url = 'http://chronicle-scratch.s3.amazonaws.com/media/';

function imageURLForBit(bit) {
	return bucket_url + bit.pk +'.jpg';
}

function videoURLForBit(bit) {
    return bucket_url + bit.pk +'.mp4';
}

function imageURLForStory(story) {
	var image_url = null;
	for (var i in story.bits) {
		var bit = story.bits[i];
		if (bit.type == BitType.PHOTO) {
			image_url = imageURLForBit(bit);
			break;
		}
	}
	return image_url;
}

var FacebookMeta = React.createClass({
	render: function() {
		var og_site_name = 'Chronicle';
		var og_type = 'chroniclestories:story';
		var og_title = titleForStory(this.props.story);
		var og_image = imageURLForStory(this.props.story);
		var og_description = descriptionForStory(this.props.story);

        return (
        	<head>
                <title>Ryan Gomba</title>
					
                <script type="text/javascript" src="//use.typekit.net/jee0oti.js"></script>
				<script type="text/javascript">Typekit.load();</script>
                <meta name="viewport" content="initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
                <link rel="stylesheet" href="/assets/style.css" />
                <script type="text/javascript" src="/assets/analytics.js"></script>
                
	            <meta property="og:title" content={og_title} />
	            <meta property="og:description" content={og_description} />
				<meta property="og:type" content={og_type} />
				<meta property="og:image" content={og_image} />
				<meta property="og:site_name" content={og_site_name} />
			</head>
        );
    }
});

var Avatar = React.createClass({
    render: function() {
        var size = 120;
        var image_url = 'https://graph.facebook.com/' + this.props.person_pk + '/picture?width=' + size + '&height=' + size;
        return (
            <img key={this.props.person_pk} src={image_url} />
        );
    }
});

var AvatarList = React.createClass({
    render: function() {
        var people_pks = this.props.people_pks;
        var createAvatar = function(person_pk) {
            return <Avatar person_pk={person_pk} />
        }
        return (
            <div className="participants">
            	{createAvatar('779018113')}
                {people_pks ? people_pks.map(createAvatar): null}
            </div>
        );
    }
});

var format_date_string = function(date_string) {
    var date = Moment(date_string);
    return date.format('dddd MMMM Do YYYY');
}

var ContextElement = React.createClass({
    render: function() {
        var date_string = format_date_string(this.props.story.date);
        return (
            <div className="context">{date_string}</div>
        );
    }
});

var PhotoBit = React.createClass({
    render: function() {
        var heightPercent = (1.0 / this.props.bit.aspectRatio) * 100.0;
        var img_wrapper_style = {
            'padding-bottom': parseFloat(heightPercent) + '%'
        }
        var remote_url = imageURLForBit(this.props.bit);
        return (
            <figure key={this.props.bit.pk}>
                <div className="img-wrapper" style={img_wrapper_style}>
                    <img src={remote_url} />
                </div>
            </figure>
        );
    }
});

var VideoBit = React.createClass({
    render: function() {
        var heightPercent = (1.0 / this.props.bit.aspectRatio) * 100.0;
        var img_wrapper_style = {
            'padding-bottom': parseFloat(heightPercent) + '%'
        }
        var remote_url = videoURLForBit(this.props.bit);
        return (
            <figure key={this.props.bit.pk}>
                <div className="img-wrapper" style={img_wrapper_style}>
                    <video controls="controls" preload="auto" webkit-playsinline="webkit-playsinline">
                        <source src={remote_url} type="video/mp4" />
                    </video>
                </div>
            </figure>
        );
    }
});

var TextBit = React.createClass({
    render: function() {
        var text_type = this.props.bit.textType;
        var createParagraph = function(paragraph) {
            if (text_type == TextBitType.TITLE) {
                return <h1>{paragraph}</h1>
            } else {
                return <p>{paragraph}</p>
            }
        }
        var paragraphs = this.props.bit.text.split('\n');
        return (
            <div className='p-group'>
                {paragraphs.map(createParagraph)}
            </div>
        );
    }
});

var StoryPage = React.createClass({
    render: function() {
        var createBit = function(bit) {
            if (bit.type == BitType.PHOTO) {
                return <PhotoBit bit={bit} />
            } else if (bit.type == BitType.TEXT) {
                return <TextBit bit={bit} />
            } else if (bit.type == BitType.VIDEO) {
                return <VideoBit bit={bit} />
            } else {
            	return <div>Unknown bit type: {String(bit.type)}</div>
            }
        }
        var createTestUserElement = function(user) {
        	if (user) {
        		return (
        			<div>
						<div>Current user is {user.name}</div>
	        			<a href="/auth/logout">Log Out</a>
	        		</div>
        		)
        	}
        	return null;
        }
        return (
        	<div className="wrapper">
        		{ createTestUserElement(this.props.user) }
				<section className="post">
		            <article>
                        <AvatarList people_pks={this.props.story.peoplePKs} />
                        <ContextElement story={this.props.story} />
		            	{this.props.story.bits ? this.props.story.bits.map(createBit) : null}
		            </article>
	            </section>
            </div>
        );
    }
});

var WebApp = React.createClass({
    render: function() {
        return (
            <html>
            	<FacebookMeta story={this.props.story}></FacebookMeta>
                <StoryPage story={this.props.story} user={this.props.user}></StoryPage>
            </html>
      );
}
});

module.exports = WebApp;

if (typeof window !== 'undefined') {
    window.onload = function() {
        React.renderComponent(WebApp(), document);
    }
}
