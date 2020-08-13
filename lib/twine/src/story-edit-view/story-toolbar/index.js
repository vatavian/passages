// The toolbar at the bottom of the screen with editing controls.

const Vue = require('vue');
const zoomMappings = require('../zoom-settings');
const {playStory, testStory} = require('../../common/launch-story');
const {updateStory} = require('../../data/actions/story');
const {publishStory} = require('../../data/publish');

require('./index.less');

module.exports = Vue.extend({
	template: require('./index.html'),

	props: {
		story: {
			type: Object,
			required: true
		},

		zoomDesc: {
			type: String,
			required: true
		}
	},

	components: {
		'story-menu': require('./story-menu'),
		'story-search': require('./story-search')
	},

	methods: {
		setZoom(description) {
			this.updateStory(this.story.id, {zoom: zoomMappings[description]});
		},

		test() {
			testStory(this.$store, this.story.id);
		},

		play() {
			playStory(this.$store, this.story.id);
		},

		push() {
			story_html = publishStory(this.$store, this.story, null, null, true);
      var xhr = new XMLHttpRequest();
      xhr.open("POST", "/import", true);
      var token = document.getElementsByName("csrf-token")[0].content;
      xhr.setRequestHeader('Content-Type', 'application/json');
      const body = { authenticity_token: token, html_body: story_html }
      xhr.send(JSON.stringify(body));
		},

		addPassage() {
			this.$dispatch('passage-create');
		}
	},

	vuex: {
		actions: {
			updateStory
		}
	}
});
