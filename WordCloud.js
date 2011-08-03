Math.round_toward_zero = function (x) { return (x >= 0 ? Math.floor(x) : Math.ceil(x) ); }

WordCloudAnchor = function(jqelement) {
	this.jqe = jqelement;
	this.cache = {};
};
WordCloudAnchor.prototype.flushCache = function() {
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
WordCloudAnchor.prototype.conePotentialField = function () {
	if( this.cache.pf == undefined ) {
		var cx = this.width()/2;
		var cy = this.height()/2;

		this.cache.pf = new Array( this.width() * this.height() );
		for( y=this.height()-1; y>=0; y-- ) {
		for( x=this.width()-1; x>=0; x-- ) {
			var dx = x-cx;
			var dy = y-cy;
			this.cache.pf[ y*this.width() + x ] = (dx*dx + dy*dy)/(this.width()+this.height());
		}}
	}
	return this.cache.pf.slice(); // Copy the array
}

WordCloudItem = function(jqelement, anchor) {
	this.jqe = jqelement;
	this.anchor = anchor;
	this.hideThreshold = 0.1;
	this.acc = {x:0, y:0}; // Error accumulator
	// set the color
	switch (Math.floor ( Math.random ( ) * 5 + 1 )) {
		case 1: this.color = "#8dc3f2"; break;
		case 2: this.color = "#cbe4f8"; break;
		case 3: this.color = "#f2f2f2"; break;
		case 4: this.color = "#8cbf1f"; break;
		default: this.color = "#7aa61b"; break;
	}
	this.cache = {};
};
WordCloudItem.prototype.destroy = function () {
	this.jqe.remove();
};
WordCloudItem.prototype.x = function() {
	if( this.cache.x == undefined ) {
		var pos = this.jqe.position();
		this.cache.x = pos.left;
		this.cache.y = pos.top; // If we called position() anyway, update y as well
	}
	return this.cache.x;
};
WordCloudItem.prototype.y = function() {
	if( this.cache.y == undefined ) {
		var pos = this.jqe.position();
		this.cache.y = pos.top;
		this.cache.x = pos.left; // If we called position() anyway, update x as well
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
WordCloudItem.prototype.attached = function() {
	if( this.cache.attached == undefined ) {
		this.cache.attached = ( this.jqe.parent().length != 0 );
	}
	return this.cache.attached;
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
	deltaX += this.acc.x; // Apply accumulated error
	deltaY += this.acc.y;

	var dx = Math.round_toward_zero(deltaX);
	var dy = Math.round_toward_zero(deltaY);

	this.acc.x = deltaX-dx;
	this.acc.y = deltaY-dy;

	this.jqe.css('left', this.x() + dx + 'px')
	        .css('top' , this.y() + dy + 'px');
	delete this.cache.x; // Flush cache
	delete this.cache.y;
};
WordCloudItem.prototype.redraw = function () {
	if( this.size < this.hideThreshold ) { // Remove from DOM
		if( this.attached() ) {
			this.prevpos = { x: this.x(), y: this.y() };
			this.jqe.detach();
			delete this.cache.attached;
		}
	} else { // Make sure it's in the DOM
		if( ! this.attached() ) {
			if(this.prevpos == undefined) {
				this.prevpos = {x: Math.random()*(this.anchor.width()-100), y: Math.random()*(this.anchor.height()-50) };
			}
			this.move( this.prevpos.x, this.prevpos.y );
			this.anchor.jqe.append(this.jqe);
			delete this.cache.attached;
		}
	}
	this.jqe.css('font-size', Math.pow(this.size,.5)*100 + '%');
	this.jqe.css('color', this.color); // set the color
	delete this.cache.width; // Flush cache
	delete this.cache.height;
};
WordCloudItem.prototype.weight = function () {
	if( this.attached() ) return 50 + this.width()*this.height();
	return 0;
}

FeedBackLoop = function (tooLow, low, high, tooHigh, ewma) {
	if( tooLow == undefined ) tooLow = 0;
	if( low == undefined ) low = 0;
	if( high == undefined ) high = 1E99;
	if( tooHigh == undefined ) tooHigh = 1E99;
	if( ewma == undefined ) ewma = 0;

	// There are 5 zones, devided by 4 threshold:
	//            value < tooLow  : take action to increase value
	//  tooLow <= value < low     : prevent action to decrease value
	//     low <= value < high    : don't interfere
	//    high <= value < tooHigh : prevent action to increase value
	// tooHigh <= value           : take action to decrease value
	this.tooLow = tooLow;
	this.low = low;
	this.high = high;
	this.tooHigh = tooHigh;
	this.register = 0;
	this.ewma = ewma; // = Math.pow( .5, 1/HalfTime )
};
FeedBackLoop.prototype.value = function() {
	return this.register*(1-this.ewma);
};
FeedBackLoop.prototype.newData = function (value) {
	this.register *= this.ewma;
	this.register += value;

	var value = this.value();
	if( value < this.tooLow ) return "inc";
	if( value < this.low ) return "inh dec";
	if( value < this.high ) return "free";
	if( value < this.tooHigh) return "inh inc";
	return "dec";
};

/* static */ FeedBackLoop.prototype.combine = function (/* … */) {
	var result = "free";
	for( var i=0; i < arguments.length; i++ ) {
		var add = arguments[i];
		if( result == "free" ) result = add;
		else if( add == "free" ) result = result;
		else if( add == "inc" || add == "dec" ) result = add;
		else if( result == "inc" && add == "inh inc" ) result = "free";
		else if( result == "inc" && add == "inh dec" ) result = result;
		else if( result == "dec" && add == "inh dec" ) result = "free";
		else if( result == "dec" && add == "inh inc" ) result = result;
		else console.log("FeedBackLoop.combine("+result+","+add+") undefined\n");

		if( result == "inh inc" || result == "inh dec" ) result = "free";
	}
	return result;
}

WordCloud = function(wordfreq, anchor, template) {
	this.wordfreq = wordfreq;
	this.anchor = new WordCloudAnchor(anchor);
	this.template = template;

	this.hideThreshold = 0.1;

	// Keep fill-grade between 20% and 50%
	this.fill_feedback = new FeedBackLoop(.2, .2, .4, .4, 0);

	// Prevent increase if CPU is >50%; decrease if >80%
	this.cpu_feedback = new FeedBackLoop(0, 0, 50, 80, .90);

	var that = this;
	this.wordfreq.cb.newWord.push( function(newWord) { that.newWord(newWord); } );
	this.wordfreq.cb.updatedWord.push( function(word, count) { that.updateWord(word,count); } );
	this.wordfreq.cb.removedWord.push( function(word) { that.removeWord(word); } );
	this.wordfreq.cb.tick.push( function(reduce) {
			that.hideThreshold = Math.max(0.1,reduce(that.hideThreshold));
		} );
	this.words = {};
};

WordCloud.prototype.newWord = function (newWord) {
	var jqitem = this.template.clone().text(newWord);
	this.words[newWord] = new WordCloudItem(jqitem, this.anchor);
};
WordCloud.prototype.updateWord = function (word, count) {
	var wordObj = this.words[ word ];
	this.fill_feedback.weight -= wordObj.weight();
	wordObj.size = count;
	wordObj.redraw();
	this.fill_feedback.weight += wordObj.weight();
};
WordCloud.prototype.removedWord = function (word) {
	if( this.words[ word ] != undefined ) {
		this.fill_feedback.weight -= wordObj.weight();;
		this.words[ word ].destroy(); // manually call destructor FIXME (if possible in JS)
		delete this.words[ word ];
	}
}

WordCloud.prototype.redraw = function() {
	var startTime = +new Date();

	var that = this; // Prepare closure

	var pf; // Use direct array access; using an object for abstraction causes performance issues...
	var pfw = that.anchor.width(); // potential field width
	{ // Create potentialField
		pf = that.anchor.conePotentialField();
		//var pf = this.anchor.conePotentialField();
		for( var word in that.words) {
			var wordObj = that.words[ word ];
			if( ! wordObj.attached() ) continue;

			var factor = 2; // Steepness of the potential
			var border = 5; // border pixels to include

			// This ruins the caching abstraction layer
			// But gives a performance boost
			var wx=wordObj.x(), wy=wordObj.y(),
			    ww=wordObj.width(), wh=wordObj.height();

			var l = wx - border,
			    t = wy - border,
			    r = wx + ww + border,
			    b = wy + wh + border;
			if( l < 0 ) l = 0;
			if( t < 0 ) t = 0;
			if( r > that.anchor.width() ) r = that.anchor.width();
			if( b > that.anchor.height() ) b = that.anchor.height();

			var d = 1; // How far are we from the border (i.e. how high is the potential)
			while(t<=b && l<=r) {
				// Iterate over the full area, starting with the outer border
				// and working our way inwards
				for(var x=l; x<r; x++) {
					pf[ t*pfw + x ] += factor*d; // top row
					if( t != b ) // check that we don't run over the same row twice
						pf[ b*pfw + x ] += factor*d; // bottom row
				}
				for(var y=t+1; y<b-1; y++) { // Exclude first & last row (already done above)
					pf[ y*pfw + l ] += factor*d; // left column
					if( l != r )
						pf[ y*pfw + r ] += factor*d; // right column
				}
				l++; r--; t++; b--; // Shrink box by 1 pixel
				d++; // increment distance
			}
		}
	};

	{ // Apply potfield
		for( var word in that.words ) {
			var wordObj = that.words[ word ];
			if( ! wordObj.attached() ) continue;

			// This ruins the caching abstraction layer
			// But gives a performance boost
			var wx=wordObj.x(), wy=wordObj.y(),
			    ww=wordObj.width(), wh=wordObj.height();

			// Sense potential {top,bottom,left,right}
			var pt=0,pb=0,pl=0,pr=0;
			for( x=ww; x>=0; x-- ) {
				pt += pf[ (wy)*pfw + wx + x ];
				pb += pf[ (wy + wh)*pfw + wx + x ];
			}
			for( y=wh; y>=0; y-- ) {
				pl += pf[ (wy + y)*pfw + wx ];
				pr += pf[ (wy + y)*pfw + wx + ww ];
			}

			// Extend the potfield outside the bounds to
			// something higher than whatever (pf[0]*2)
			if( isNaN(pt) ) pt = pf[0]*2 * ww;
			if( isNaN(pb) ) pb = pf[0]*2 * ww;
			if( isNaN(pl) ) pl = pf[0]*2 * wh;
			if( isNaN(pr) ) pr = pf[0]*2 * wh;

			var area = ww*wh;
			var mvx = (pl - pr) / area * 2;
			var mvy = (pt - pb) / area * 2;

			wordObj.moveRel( mvx, mvy );
		}
	}

	{ // Feedback loops
		// Fill
		var filled = 0;
		for( var word in that.words ) {
			var wordObj = that.words[ word ];
			filled += wordObj.weight();
		}
		filled /= that.anchor.width() * that.anchor.height();

		// CPU
		var dt = ((+new Date())-startTime);


		var action =
			that.cpu_feedback.combine( that.fill_feedback.newData(filled),
			                           that.cpu_feedback.newData(dt) );

		if( action != "free" ) {
			var changed = false;
			if( action == "inc" && that.hideThreshold > 0.1 ) {
				that.hideThreshold /= 1.05;
				changed = true;
			} else if( action == "dec" ) {
				that.hideThreshold *= 1.05;
				changed = true;
			}
			if( changed ) {
				console.log("Feedback loop: Fill("+that.fill_feedback.value()+") "+
				            "CPU("+that.cpu_feedback.value()+") "+
							"=> "+action+" to "+that.hideThreshold+"\n");
				for( var word in that.words ) {
					var wordObj = that.words[ word ];
					wordObj.hideThreshold = that.hideThreshold;
					wordObj.redraw();
				}
			}
		}
	}
};

function DEBUG_display_pf(pf) {
	var debug_ctx = $("#debug")[0].getContext("2d");
	var image = debug_ctx.createImageData( $("#debug").width(), $("#debug").height() );

	var min=pf[0], max=pf[0];
	for( var i=0; i < pf.length; i++ ) {
		if( pf[i] < min ) min = pf[i];
		if( pf[i] > max ) max = pf[i];
	}
	for( var i=0; i < pf.length; i++ ) {
		image.data[ i*4 + 0 ] = (pf[i] - min)*255/(max-min); // R
		image.data[ i*4 + 1 ] = (pf[i] - min)*255/(max-min); // G
		image.data[ i*4 + 2 ] = (pf[i] - min)*255/(max-min); // B
		image.data[ i*4 + 3 ] = 255; // A
	}

	debug_ctx.putImageData(image, 0, 0);
}
function DEBUG_clear_pf() {
	var debug_ctx = $("#debug")[0].getContext("2d");
	var image = debug_ctx.createImageData( pf.width, pf.height );
	debug_ctx.putImageData(image, 0, 0);
}
