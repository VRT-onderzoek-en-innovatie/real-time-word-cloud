function WordFreq() {
	this.dictionary = {};
	this.stopwords = [];
	this.ewma = 1;
	this.ewma_timer = null;
	this.remove_threshold = 0;

	this.callOnUpdate = [];
}

WordFreq.prototype.registerCallback = function (func) {
	this.callOnUpdate.push(func);
};

WordFreq.prototype.addWords = function (words) {
	if( typeof(words) == 'string' ) words = [ words ];
	for(var i in words) {
		var word = words[i];
		if( $.inArray(word.toLowerCase(), this.stopwords) > -1 ) continue;

		var old = this.dictionary[word.toLowerCase()];
		if( old == undefined ) {
			old = {count: 0, caps: {}};
		}
		if( old.caps[word] == undefined ) old.caps[word] = 0;

		old.count++;
		old.caps[word]++;

		this.dictionary[word.toLowerCase()] = old;
	}
	for(var f in this.callOnUpdate) {
		this.callOnUpdate[f]();
	}
};

WordFreq.prototype.tick = function () {
	var that = this;
	var reduce = function (input) { return input * that.ewma; };
	$.each(this.dictionary, function (index, value) {
		$.each(value.caps, function(index, value) {
			value = reduce(value);
		});
		value.count = reduce(value.count);
	});
	this.cleanup();
	for(var f in this.callOnUpdate) {
		this.callOnUpdate[f]();
	}
};

WordFreq.prototype.cleanup = function () {
	var that = this;
	$.each(this.dictionary, function (index, value) {
		if( value.count < that.remove_threshold ) {
			delete that.dictionary[index];
		}
	});
}
WordFreq.prototype.setEwma = function (halftime) {
	var delta = 0.95; // Allow for performance tuning here
	if( this.ewma_timer != null ) {
		clearTimeout(this.ewma_timer);
		this.ewma_timer = null;
	}
	var ticktime = halftime*1000 / (Math.log(.5)/Math.log(delta));
	this.ewma = delta;

	var that = this; var closure = function () { var that2 = that; that2.tick(); };
	this.ewma_timer = setInterval(closure, ticktime);
};

WordFreq.prototype.addStopWords = function (words) {
	if( typeof(words) == 'string' ) words = [ words ];

	// Add them to the stopword list
	this.stopwords = this.stopwords.concat(words);

	// And remove the new stopwords from the dictionary
	var that = this;
	$.each(words, function (index, value) {
		if( that.dictionary[value] != undefined ) {
			delete that.dictionary[value];
		}
	});
	for(var f in this.callOnUpdate) {
		this.callOnUpdate[f]();
	}
};

WordFreq.prototype.wipe = function () {
	this.dictionary = {};
	for(var f in this.callOnUpdate) {
		this.callOnUpdate[f]();
	}
};

WordFreq.prototype.getWords = function () {
	keys = [];
	for(var i in this.dictionary) { keys.push(i); }
	return keys;
}

WordFreq.prototype.getOccurences = function (word) {
	item = this.dictionary[word.toLowerCase()];
	if( item == undefined ) return [0, '', null]
	highscore = 0;
	for(var i in item.caps) {
		if( item.caps[i] > highscore ) {
			word = i;
			highscore = item.caps[i];
		}
	}
	return [item.count, word, item];
};
