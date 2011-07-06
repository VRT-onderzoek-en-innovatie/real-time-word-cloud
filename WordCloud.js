function rect_intersect (ax,ay,aw,ah, bx,by,bw,bh) {
	/* Do the rectangles A and B intersect?
	 * Each are specified by their left-top corner {a,b}{x,y}
	 * and their width and hight {a,b}{w,h} (exclusive)
	 * This function returns either false if the rectangles
	 * do not overlap, or a vector [x,y] to move A away from B
	 */
	
	// Make sure {a,b}{w,h} are positive
	if( aw < 0 ) { ax = ax + aw; aw = -aw; }
	if( ah < 0 ) { ay = ay + ah; ah = -ah; }
	if( bw < 0 ) { bx = bx + bw; bw = -bw; }
	if( bh < 0 ) { by = by + bh; bh = -bh; }

	if( ax+aw <= bx /* A left of B */ ) return false;
	if( bx+bw <= ax /* A right of B */ ) return false;
	if( ay+ah <= by /* A above B */ ) return false;
	if( by+bh <= ay /* A below B */ ) return false;

	// OK, they overlap; Move away in this direction
	var mv = [ (ax+aw/2) - (bx+bw/2) , (ay+ah/2) - (by+bh/2) ];
	{
		var length = Math.sqrt( Math.pow(mv[0],2) + Math.pow(mv[1],2) );
		mv[0] /= length; mv[1] /= length;
	}

	{ // Now find the intersection area to scale that vector
		var ix = Math.max(ax,bx);
		var iy = Math.max(ay,by);
		var ix2 = Math.min(ax+aw, bx+bw);
		var iy2 = Math.min(ay+ah, by+bh);
		var iw = ix2-ix;
		var ih = iy2-iy;
		var area = iw*ih;
		area /= aw*ah;
		mv[0] *= area; mv[1] *= area;
	}

	return mv;
}

Math.round_away_from_zero = function (x) { return (x >= 0 ? Math.ceil(x) : Math.floor(x) ); }

WordCloudAnchor = function(jqelement) {
	this.jqe = jqelement;
	this.cache = {};
};
WordCloudAnchor.prototype.width = function() {
	if( this.cache.width == undefined ) {
		this.cache.width = this.jqe.width();
	}
	return this.cache.width;
};
WordCloudAnchor.prototype.height = function() {
	if( this.cache.height == undefined ) {
		this.cache.height = this.jqe.height();
	}
	return this.cache.height;
};
WordCloudAnchor.prototype.flushCache = function() {
	this.cache = {};
};

WordCloudItem = function(jqelement) {
	this.jqe = jqelement;
	this.cache = {};
};
WordCloudItem.prototype.x = function() {
	if( this.cache.x == undefined ) {
		this.cache.x = this.jqe.position().left;
	}
	return this.cache.x;
};
WordCloudItem.prototype.y = function() {
	if( this.cache.y == undefined ) {
		this.cache.y = this.jqe.position().top;
	}
	return this.cache.y;
};
WordCloudItem.prototype.width = function() {
	if( this.cache.width == undefined ) {
		this.cache.width = this.jqe.width();
	}
	return this.cache.width;
};
WordCloudItem.prototype.height = function() {
	if( this.cache.height == undefined ) {
		this.cache.height = this.jqe.height();
	}
	return this.cache.height;
};
WordCloudItem.prototype.flushCache = function() {
	this.cache = {};
};
WordCloudItem.prototype.move = function (newX, newY) {
	this.jqe.css('left', newX + 'px');
	this.jqe.css('top' , newY + 'px');
	delete this.cache.x; // Flush cache
	delete this.cache.y;
};
WordCloudItem.prototype.moveRel = function (deltaX, deltaY) {
	this.jqe.css('left', this.x() + deltaX + 'px');
	this.jqe.css('top' , this.y() + deltaY + 'px');
	delete this.cache.x; // Flush cache
	delete this.cache.y;
};
WordCloudItem.prototype.resize = function (newSize) {
	this.jqe.css('font-size', Math.pow(newSize,.5)*100 + '%');
	delete this.cache.width; // Flush cache
	delete this.cache.height;
};

WordCloud = function(wordfreq, anchor, template) {
	this.wordfreq = wordfreq;
	this.anchor = new WordCloudAnchor(anchor);
	this.template = template;

	var that = this;
	this.wordfreq.cb.newWord.push( function(newWord) { that.newWord(newWord); } );
	this.wordfreq.cb.updatedWord.push( function(word, count) { that.updateWord(word,count); } );
	this.words = {};
};

WordCloud.prototype.newWord = function (newWord) {
	var jqitem = this.template.clone().text(newWord);
	// Instantiate randomly
	jqitem.css('left', Math.random()*(this.anchor.width()-100) + 'px')
	      .css('top', Math.random()*(this.anchor.height()-50) + 'px')
	this.anchor.jqe.append(jqitem);
	this.words[newWord] = new WordCloudItem(jqitem);
};
WordCloud.prototype.updateWord = function (word, count) {
	if( count < 0.3 ) { // FIXME make parameter
		// Element is too small, remove from DOM
		if( this.words[ word ] != undefined ) {
			this.words[ word ].jqe.remove();
			delete this.words[ word ];
		}
	} else {
		// Make sure this element exists in the DOM
		if( this.words[ word ] == undefined ) { this.newWord(word); }
		this.words[ word ].resize(count);
	}
};
WordCloud.prototype.removedWord = function (word) {
	this.words[ word ].jqe.remove();
	delete this.words[ word ];
}

WordCloud.prototype.redraw = function() {
	for( var word in this.words ) {
		var wordObj = this.words[ word ];
		var mvx = 0, mvy = 0;
		{ // Go to center
			var mv = [ this.anchor.width()/2
			                      - (wordObj.x()+wordObj.width()/2),
			           this.anchor.height()/2
			                      - (wordObj.y()+wordObj.height()/2) ];
			var length = Math.sqrt( Math.pow(mv[0],2) + Math.pow(mv[1],2) );
			mv[0] /= length; mv[1] /= length;
			mvx += mv[0]; mvy += mv[1];
		}
		// repulse from others
		for( var otherWord in this.words ) {
			if( word == otherWord ) continue;
			var otherWordObj = this.words[ otherWord ];
			/* Check if the rectangles overlap */
			var mv = rect_intersect(
			    wordObj.x(), wordObj.y(), wordObj.width(), wordObj.height(),
			    otherWordObj.x(), otherWordObj.y(), otherWordObj.width(), otherWordObj.height()
				);
			if( mv != false ) { mvx += 50*mv[0]; mvy += 50*mv[1]; }
		}
		wordObj.moveRel( Math.round_away_from_zero(mvx),
		                 Math.round_away_from_zero(mvy) );
	}
};
