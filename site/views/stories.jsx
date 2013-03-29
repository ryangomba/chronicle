/** @jsx React.DOM */

var React = require('react');

var StoriesPage = React.createClass({
    render: function() {
        var createStoryLink = function(story) {
            var hostname = 'http://chronicle.appthat.com';
            var url = hostname + '/stories/' + story.pk;
            return <li><a href={url}>{story.pk}</a></li>
        }
        return (
            <ul>
                {this.props.stories.map(createStoryLink)}
            </ul>
        );
    }
});

var WebApp = React.createClass({
    render: function() {
        return (
            <html>
                <StoriesPage stories={this.props.stories} user={this.props.user}></StoriesPage>
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
